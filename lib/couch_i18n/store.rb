module CouchI18n
  class Store

    def available_locales
      CouchI18n::Translation.get_keys_by_level(0)
    end

    # Now the store features
    def []=(key, value, options = {})
      key = key.to_s
      existing = CouchI18n::Translation.find_by_key(key) rescue nil
      translation = existing || CouchI18n::Translation.new(:key => key)
      translation.value = value
      translation.save
    end

    # alias for read
    def [](key, options=nil)
      Rails.cache.fetch(key) do
        translation = CouchI18n::Translation.find_by_key(key.to_s)
        translation ||= CouchI18n::Translation.create(:key => key, :value => key.to_s.split('.').last, :translated => false)
        translation.value
      end
    end

    def keys
      CouchI18n::Translation.all.map(&:key)
    end
  end
end
