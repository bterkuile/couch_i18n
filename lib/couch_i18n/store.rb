module CouchI18n
  class Store

    def available_locales
      CouchI18n::Translation.get_keys_by_level(0)
    end

    # Now the store features
    def []=(key, value, options = {})
      key = key.to_s.gsub('/', '.')
      existing = CouchI18n::Translation.find_by_key(key) rescue nil
      translation = existing || CouchI18n::Translation.new(:key => key)
      translation.value = value
      translation.save
    end

    # alias for read
    def [](key, options = {})
      key = key.to_s.gsub('/', '.')
      Rails.cache.fetch("couch_i18n-#{key}") do
        old_database_name = get_couchrest_name
        begin
          set_couchrest_name CouchPotato::Config.database_name # Set database to original configured name
          translation = CouchI18n::Translation.find_by_key(key.to_s)
          translation ||= CouchI18n::Translation.create(:key => key, :value => options[:default].presence || key.to_s.split('.').last, :translated => false)
        ensure
          set_couchrest_name old_database_name
        end
        translation.value
      end
    end

    def set_couchrest_name(name)
      d = CouchPotato.database.couchrest_database
      d.instance_variable_set('@name', name)
      d.instance_variable_set('@uri', "/#{name.gsub('/', '%2F')}")
      d.instance_variable_set('@bulk_save_cache', [])
      d.instance_variable_set('@root', d.host + d.uri)
    end

    def get_couchrest_name
      CouchPotato.database.couchrest_database.name
    end

    def keys
      CouchI18n::Translation.all.map(&:key)
    end
  end
end
