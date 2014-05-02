module CouchI18n
  class TranslationsController < CouchI18n::ApplicationController
    def index
      @available_higher_offsets = []
      @available_deeper_offsets = []
      per_page = params[:per_page].presence.try(:to_i) || 30
      if params[:partfinder].present?
        if untranslated?
          @translations = CouchI18n::Translation.find_all_untranslated_by_key_part(params[:offset], page: params[:page], per_page: per_page)
        else
          @translations = CouchI18n::Translation.find_all_by_key_part(params[:offset], page: params[:page], per_page: per_page)
        end
      elsif params[:valuefinder].present?
        if untranslated?
          @translations = CouchI18n::Translation.find_all_untranslated_by_value(params[:offset], page: params[:page], per_page: per_page)
        else
          @translations = CouchI18n::Translation.find_all_by_value(params[:offset], page: params[:page], per_page: per_page)
        end
      else
        if params[:offset].present?
          if untranslated?
            @translations = CouchI18n::Translation.untranslated_with_offset(params[:offset], :page => params[:page], :per_page => per_page)
          else
            @translations = CouchI18n::Translation.with_offset(params[:offset], :page => params[:page], :per_page => per_page)
          end
        else
          if untranslated?
            @translations = CouchI18n::Translation.untranslated(:page => params[:page], :per_page => per_page)
          else
            @translations = CouchI18n::Translation.all(:page => params[:page], :per_page => per_page)
          end
        end
        @available_higher_offsets = CouchI18n::Translation.higher_keys_for_offset(params[:offset])
        @available_deeper_offsets = CouchI18n::Translation.deeper_keys_for_offset(params[:offset])
      end
    end

    def show
      redirect_to action: :edit
    end

    def new
      @translation = CouchI18n::Translation.new translation_key: params[:offset]
    end

    def create
      @translation = CouchI18n::Translation.new translation_params
      if @translation.value.present? && params[:is_json].present?
        @translation.value = JSON.parse(@translation.value)
      end
      if @translation.save
        redirect_to({:action => :index, :offset => @translation.translation_key.to_s.sub(/\.[\w\s-]+$/, '')}, :notice => I18n.t('couch_i18n.action.create.successful', :model => CouchI18n::Translation.model_name.human))
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
      tparams = translation_params
      if tparams["value"].present? && params[:is_json].present?
        tparams["value"] = JSON.parse(tparams["value"])
      end
      if @translation.update_attributes(tparams)
        redirect_to({:action => :index, :offset => @translation.translation_key.to_s.sub(/\.[\w\s-]+$/, '')}, :notice => I18n.t('couch_i18n.action.update.successful', :model => CouchI18n::Translation.model_name.human))
      else
        render :action => :edit
      end
    end

    def destroy
      @translation = CouchI18n::Translation.find(params[:id])
      if @translation.destroy
        flash[:notice] = I18n.t('couch_i18n.action.destroy.successful', :model => CouchI18n::Translation.model_name.human)
      end
      redirect_to({:action => :index, :offset => @translation.translation_key.to_s.sub(/\.\w+$/, '')})
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
        render :text => @translations.map{|s| [s.translation_key, s.translation_value.to_json].join(',')}.join("\n")
      elsif params[:exportformat] == 'json'
        response.headers['Content-Type'] = 'application/json'
        response.headers['Content-Disposition'] = %{attachment; filename="#{base_filename}.json"}
        # render :text => CouchI18n.indent_keys(@translations).to_json # for indented json
        render :json => @translations.map{|s| {s.translation_key => s.translation_value}}.to_json
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
          existing = CouchI18n::Translation.find_by_translation_key(key)
          if existing
            if existing.value != value
              existing.value = value
              existing.translated = true
              existing.save
            end
          else
            CouchI18n::Translation.create translation_key: key, translation_value: value
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

    private

    def untranslated?
      params[:untranslated].presence
    end
    helper_method :untranslated?

    def translation_params
      params.require(:translation).permit(:translation_key, :translation_value, :translated)
    end
  end
end
