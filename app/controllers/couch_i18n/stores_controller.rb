module CouchI18n
  class StoresController < ApplicationController
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
        @couch_i18n_stores = CouchI18n::Store.with_offset(params[:offset], :page => params[:page], :per_page => 30)
        @available_deeper_offsets = CouchI18n::Store.get_keys_by_level(@levels.size, :startkey => @levels, :endkey => @levels + [{}]).
          map{|dl| {:name => dl, :offset => [params[:offset], dl].join('.')}}
      else
        @couch_i18n_stores = CouchI18n::Store.all(:page => params[:page], :per_page => 30)
        @available_deeper_offsets = CouchI18n::Store.get_keys_by_level(0).
          map{|dl| {:name => dl, :offset => dl}}
      end
    end

    def show
      @couch_i18n_store = CouchI18n::Store.find(params[:id])
    end

    def new
      @couch_i18n_store = CouchI18n::Store.new :key => params[:offset]
    end

    def create
      @couch_i18n_store = CouchI18n::Store.new params[:couch_i18n_store]
      if @couch_i18n_store.save
        redirect_to({:action => :index, :offset => @couch_i18n_store.key.to_s.sub(/\.[\w\s-]+$/, '')}, :notice => I18n.t('action.create.successful', :model => CouchI18n::Store.model_name.human))
      else
        render :action => :new
      end
    end

    # GET /couch_i18n/stores/:id/edit
    def edit
      @couch_i18n_store = CouchI18n::Store.find(params[:id])
    end

    # PUT /couch_i18n/stores/:id
    def update
      @couch_i18n_store = CouchI18n::Store.find(params[:id])
      if @couch_i18n_store.update_attributes(params[:couch_i18n_store])
        redirect_to({:action => :index, :offset => @couch_i18n_store.key.to_s.sub(/\.[\w\s-]+$/, '')}, :notice => I18n.t('action.update.successful', :model => CouchI18n::Store.model_name.human))
      else
        render :action => :edit
      end
    end

    def destroy
      @couch_i18n_store = CouchI18n::Store.find(params[:id])
      if @couch_i18n_store.destroy
        flash[:notice] = I18n.t('action.destroy.successful', :model => CouchI18n::Store.model_name.human)
      end
      redirect_to({:action => :index, :offset => @couch_i18n_store.key.to_s.sub(/\.\w+$/, '')})
    end

    # POST /couch_i18n/stores/export
    # Export to yml, csv or json
    def export
      if params[:offset].present?
        @couch_i18n_stores = CouchI18n::Store.with_offset(params[:offset])
      else
        @couch_i18n_stores = CouchI18n::Store.all
      end
      base_filename = "export#{Time.now.strftime('%Y%m%d%H%M')}"
      if params[:exportformat] == 'csv'
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = %{attachment; filename="#{base_filename}.csv"}
        render :text => @couch_i18n_stores.map{|s| [s.key, s.value.to_json].join(',')}.join("\n")
      elsif params[:exportformat] == 'json'
        response.headers['Content-Type'] = 'application/json'
        response.headers['Content-Disposition'] = %{attachment; filename="#{base_filename}.json"}
        # render :text => CouchI18n.indent_keys(@couch_i18n_stores).to_json # for indented json
        render :json => @couch_i18n_stores.map{|s| {s.key => s.value}}.to_json
      else #yaml
        response.headers['Content-Type'] = 'application/x-yaml'
        response.headers['Content-Disposition'] = %{attachment; filename="#{base_filename}.yml"}
        render :text => CouchI18n.indent_keys(@couch_i18n_stores).to_yaml
      end
    end

    # POST /couch_i18n/stores/import
    # Import yml files
    def import
      redirect_to({:action => :index, :offset => params[:offset]}, :alert => I18n.t('couch_i18n.store.no import file given')) and return unless params[:importfile].present?
      filename = params[:importfile].original_filename
      extension = filename.sub(/.*\./, '')
      if extension == 'yml'
        hash = YAML.load_file(params[:importfile].tempfile.path) rescue nil
        redirect_to({:action => :index, :offset => params[:offset]}, :alert => I18n.t('couch_i18n.store.cannot parse yaml')) and return unless hash
        CouchI18n.traverse_flatten_keys(hash).each do |key, value|
          existing = CouchI18n::Store.find_by_key(key)
          if existing
            if existing.value != value
              existing.value = value
              existing.save
            end
          else
            CouchI18n::Store.create :key => key, :value => value
          end
        end 
      else
        redirect_to({:action => :index, :offset => params[:offset]}, :alert => I18n.t('couch_i18n.store.no proper import extension', :extension => extension)) and return 
      end
      redirect_to({:action => :index, :offset => params[:offset]}, :notice => I18n.t('couch_i18n.store.file imported', :filename => filename))
    end

    # Very dangarous action, please handle this with care, large removals are supported!
    # DELETE /couch_i18n/stores/destroy_offset?...
    def destroy_offset
      if params[:offset].present?
        @couch_i18n_stores = CouchI18n::Store.with_offset(params[:offset])
      else
        @couch_i18n_stores = CouchI18n::Store.all
      end
      @couch_i18n_stores.map(&:destroy)
      redirect_to({:action => :index}, :notice => I18n.t('couch_i18n.store.offset deleted', :count => @couch_i18n_stores, :offset => params[:offset]))
    end
  end
end
