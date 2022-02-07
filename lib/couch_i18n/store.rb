module CouchI18n
  class Store
    KNOWN_DEFAULTS = {
      'support.array' => %({"words_connector":", ","two_words_connector":" and ","last_word_connector":", and "})
    }

    def available_locales
      CouchI18n::Translation.get_keys_by_level(0)
    end

    # Now the store features
    def []=(key, value, options = {})
      key = key.to_s.gsub('/', '.')
      existing = CouchI18n::Translation.find_by_translation_key(key) rescue nil
      translation = existing || CouchI18n::Translation.new(translation_key: key)
      translation.translation_value = value
      translation.save and Rails.cache.write("couch_i18n-#{key}", value)
      value
    end

    # alias for read
    def [](key, options = {})
      key = key.to_s.gsub('/', '.')
      key_without_locale = key.sub(/\w+\./, '')
      old_database_name = get_couchrest_name
      Rails.cache.fetch("couch_i18n-#{key}") do
        begin
          set_couchrest_name CouchPotato::Config.database_name # Set database to original configured name
          translation = CouchI18n::Translation.find_by_translation_key(key.to_s)
          translation ||= CouchI18n::Translation.create(translation_key: key, translation_value: options[:default].presence || KNOWN_DEFAULTS[key_without_locale].presence || key[/\w+$/].humanize, translated: false)
        rescue SimplyStored::RecordNotFound
          binding.pry
        ensure
          set_couchrest_name old_database_name
        end
        translation.translation_value
      end
    end

    def set_couchrest_name(full_database_namename)
      # we assume the database server is the same, just change the name
      name = full_database_namename[/\w+$/]
      d = CouchPotato.database.couchrest_database
      d.instance_variable_set('@name', name)
      #d.instance_variable_set('@uri', "/#{name.gsub('/', '%2F')}")
      d.instance_variable_set('@path', "/#{CGI.escape(name)}")
      d.instance_variable_set('@bulk_save_cache', [])
      #d.instance_variable_set('@root', d.host + d.uri)
      #CouchPotato.class_variable_set('@@__couchrest_database', CouchRest.database(CouchPotato.full_url_to_database(name, CouchPotato::Config.database_host)))
    end

    def get_couchrest_name
      CouchPotato.database.couchrest_database.name
    end

    #DISABLE THIS FUNCTIONALITY, IT KILLS PERFORMANCE
    def keys
      [] #@kyes ||= CouchI18n::Translation.all.map(&:translation_key)
    end
  end
end
