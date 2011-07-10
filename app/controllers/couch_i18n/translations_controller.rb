module CouchI18n
  class TranslationsController < CouchI18n::ApplicationController
    def index
      @available_higher_offsets = []
      if params[:offset].present?
        @levels = params[:offset].split('.')
        # Add higher levels. Do not add the last level, since it is the current one => 0..-2
        @levels[0..-2].each_with_index do |level_name, i|
          @available_higher_offsets << {
            :name => level_name,
            :offset => @levels[0..i].join('.')
          }
        end
        @translations = CouchI18n::Translation.with_offset(params[:offset], :page => params[:page], :per_page => 30)
        @available_deeper_offsets = CouchI18n::Translation.get_keys_by_level(@levels.size, :startkey => @levels, :endkey => @levels + [{}]).
          map{|dl| {:name => dl, :offset => [params[:offset], dl].join('.')}}
      else
        @translations = CouchI18n::Translation.all(:page => params[:page], :per_page => 30)
        @available_deeper_offsets = CouchI18n::Translation.get_keys_by_level(0).
          map{|dl| {:name => dl, :offset => dl}}
      end
    end

    def show
      @translation = CouchI18n::Translation.find(params[:id])
    end

    def new
      @translation = CouchI18n::Translation.new :key => params[:offset]
    end

    def create
      @translation = CouchI18n::Translation.new params[:translation]
      if @translation.value.present? && params[:is_json].present?
        @translation.value = JSON.parse(@translation.value)
      end
      if @translation.save
        redirect_to({:action => :index, :offset => @translation.key.to_s.sub(/\.[\w\s-]+$/, '')}, :notice => I18n.t('action.create.successful', :model => CouchI18n::Translation.model_name.human))
      else
        render :action => :new
      end
    end

    # GET /couch_i18n/translations/:id/edit
    def edit
      @translation = CouchI18n::Translation.find(params[:id])
    end

    # PUT /couch_i18n/translations/:id
    def update
      @translation = CouchI18n::Translation.find(params[:id])
      @translation.translated = true
      if params[:translation]["value"].present? && params[:is_json].present?
        params[:translation]["value"] = JSON.parse(params[:translation]["value"])
      end
      if @translation.update_attributes(params[:translation])
        redirect_to({:action => :index, :offset => @translation.key.to_s.sub(/\.[\w\s-]+$/, '')}, :notice => I18n.t('action.update.successful', :model => CouchI18n::Translation.model_name.human))
      else
        render :action => :edit
      end
    end

    def destroy
      @translation = CouchI18n::Translation.find(params[:id])
      if @translation.destroy
        flash[:notice] = I18n.t('action.destroy.successful', :model => CouchI18n::Translation.model_name.human)
      end
      redirect_to({:action => :index, :offset => @translation.key.to_s.sub(/\.\w+$/, '')})
    end

    # POST /couch_i18n/translations/export
    # Export to yml, csv or json
    def export
      if params[:offset].present?
        if params[:untranslated].present?
          @translations = CouchI18n::Translation.unstranslated_with_offset(params[:offset])
        else
          @translations = CouchI18n::Translation.with_offset(params[:offset])
        end
      else
        if params[:untranslated].present?
          @translations = CouchI18n::Translation.untranslated
        else
          @translations = CouchI18n::Translation.all
        end
      end
      base_filename = "export#{Time.now.strftime('%Y%m%d%H%M')}"
      if params[:exportformat] == 'csv'
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = %{attachment; filename="#{base_filename}.csv"}
        render :text => @translations.map{|s| [s.key, s.value.to_json].join(',')}.join("\n")
      elsif params[:exportformat] == 'json'
        response.headers['Content-Type'] = 'application/json'
        response.headers['Content-Disposition'] = %{attachment; filename="#{base_filename}.json"}
        # render :text => CouchI18n.indent_keys(@translations).to_json # for indented json
        render :json => @translations.map{|s| {s.key => s.value}}.to_json
      else #yaml
        response.headers['Content-Type'] = 'application/x-yaml'
        response.headers['Content-Disposition'] = %{attachment; filename="#{base_filename}.yml"}
        render :text => CouchI18n.indent_keys(@translations).to_yaml
      end
    end

    # POST /couch_i18n/translations/import
    # Import yml files
    def import
      redirect_to({:action => :index, :offset => params[:offset]}, :alert => I18n.t('couch_i18n.translation.no import file given')) and return unless params[:importfile].present?
      filename = params[:importfile].original_filename
      extension = filename.sub(/.*\./, '')
      if extension == 'yml'
        hash = YAML.load_file(params[:importfile].tempfile.path) rescue nil
        redirect_to({:action => :index, :offset => params[:offset]}, :alert => I18n.t('couch_i18n.translation.cannot parse yaml')) and return unless hash
        CouchI18n.traverse_flatten_keys(hash).each do |key, value|
          existing = CouchI18n::Translation.find_by_key(key)
          if existing
            if existing.value != value
              existing.value = value
              existing.translated = true
              existing.save
            end
          else
            CouchI18n::Translation.create :key => key, :value => value
          end
        end 
      else
        redirect_to({:action => :index, :offset => params[:offset]}, :alert => I18n.t('couch_i18n.translation.no proper import extension', :extension => extension)) and return 
      end
      redirect_to({:action => :index, :offset => params[:offset]}, :notice => I18n.t('couch_i18n.translation.file imported', :filename => filename))
    end

    # Very dangarous action, please handle this with care, large removals are supported!
    # DELETE /couch_i18n/translations/destroy_offset?...
    def destroy_offset
      if params[:offset].present?
        @translations = CouchI18n::Translation.with_offset(params[:offset])
      else
        @translations = CouchI18n::Translation.all
      end
      @translations.map(&:destroy)
      redirect_to({:action => :index}, :notice => I18n.t('couch_i18n.translation.offset deleted', :count => @translations.size, :offset => params[:offset]))
    end
  end
end