module CouchI18n
  class Store
    include SimplyStored::Couch
    per_page_method :limit_value

    property :key
    property :value

    validates_uniqueness_of :key

    after_save :reload_i18n

    view :all_documents, :key => :key
    view :by_key, :key => :key

    view :with_key_array, :map => %|function(doc){
      if(doc.ruby_class && doc.ruby_class == 'CouchI18n::Store') {
        emit(doc.key.split('.').slice(0,-1), 1);
      }
    }|, :type => :raw, :reduce => '_sum'

    def self.available_locales
      get_keys_by_level
    end

    def self.get_keys_by_level(level = 0, options = {})
      data = database.view(with_key_array(options.merge(:group_level => level.succ)))["rows"]
      # data = data.select{|h| h["key"].size > level } # Only select ones that have a deeper nesting
      data.map{|h| h['key'][level].try(:to_sym)}.compact
    end

    # Now the store features
    def self.[]=(key, value, options = {})
      key = key.to_s
      existing = find_by_key(key) rescue nil
      translation = existing || new(:key => key)
      translation.value = value
      translation.save
    end

    # Expire I18n when record is updated
    after_save do
      I18n.reload!
      I18n.cache_store.clear if I18n.respond_to?(:cache_store) && I18n.cache_store.respond_to?(:clear)
    end

    # Shorthand for selecting all stored with a given offset
    def self.with_offset(offset, options = {})
      find_all_by_key("#{offset}.".."#{offset}.ZZZZZZZZZ", options)
    end

    # alias for read
    def self.[](key, options=nil)
      find_by_key(key.to_s).try(:value) rescue nil
    end

    def self.keys
      all.map(&:key)
    end
  end
end
