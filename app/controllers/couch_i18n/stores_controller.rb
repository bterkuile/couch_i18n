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
        @couch_i18n_stores = CouchI18n::Store.find_all_by_key(params[:offset]..(params[:offset] + '\u9999'), :page => params[:page], :per_page => 30)
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
        redirect_to({:action => :index, :offset => @couch_i18n_store.key.to_s.sub(/\.\w+$/, '')}, :notice => I18n.t('action.create.successful', :model => CouchI18n::Store.model_name.human))
      else
        render :action => :new
      end
    end
    def edit
      @couch_i18n_store = CouchI18n::Store.find(params[:id])
    end
    def update
      @couch_i18n_store = CouchI18n::Store.find(params[:id])
      if @couch_i18n_store.update_attributes(params[:couch_i18n_store])
        redirect_to({:action => :index, :offset => @couch_i18n_store.key.to_s.sub(/\.\w+$/, '')}, :notice => I18n.t('action.update.successful', :model => CouchI18n::Store.model_name.human))
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
  end
end
