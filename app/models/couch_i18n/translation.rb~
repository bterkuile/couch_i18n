module CouchI18n
  class Translation
    include SimplyStored::Couch
    per_page_method :limit_value

    property :key
    property :value
    property :translated, type: :boolean, default: true

    validates_uniqueness_of :key

    after_save :reload_i18n

    view :all_documents, :key => :key
    view :by_key, :key => :key

    view :with_key_array, map_function: %|function(doc){
      if(doc.ruby_class && doc.ruby_class == 'CouchI18n::Translation') {
        emit(doc.key.split('.').slice(0, -1), 1);
      }
    }|, type: :raw, reduce_function: '_sum'

    view :untranslated_view, key: :key, conditions: "!doc['translated']"
    view :by_value, key: :value
    view :by_key_part, type: :custom, map_function: %|function(doc){
      if(doc.ruby_class && doc.ruby_class == 'CouchI18n::Translation') {
        var parts = doc.key.split('.');
        for(var i = 0; i < parts.length; i++){
          emit(parts[i], 1);
        }
      }
    }|, reduce_function: '_count'

    def self.get_keys_by_level(level = 0, options = {})
      data = database.view(with_key_array(options.merge(:group_level => level.succ)))["rows"]
      # data = data.select{|h| h["key"].size > level } # Only select ones that have a deeper nesting
      data.map{|h| h['key'][level].try(:to_sym)}.compact
    end

    # Shorthand for selecting all stored with a given offset
    def self.with_offset(offset, options = {})
      CouchI18n::Translation.find_all_by_key("#{offset}.".."#{offset}.ZZZZZZZZZ", options)
    end

    # Find all records having the term part in their key
    #   nl.action.one
    #   en.action.two
    #   en.activemodel.plural.models.user
    # and using
    #   find_all_by_part('action')
    # will return the first two since they have action as key part
    def self.find_all_by_key_part(part, options = {})
      total_entries = database.view(by_key_part(key: part, reduce: true))
      with_pagination_options options.merge(total_entries: total_entries) do |options|
        database.view(by_key_part(options.merge(key: part, reduce: false, include_docs: true)))
      end
    end

    def self.untranslated(options = {})
      total_entries = database.view(untranslated_view(options.select{|k,v| [:key, :keys, :startkey, :endkey].include?(k)}.merge(reduce: true)))
      with_pagination_options options.merge(total_entries: total_entries) do |options|
        database.view(untranslated_view(options))
      end
    end

    def self.untranslated_with_offset(offset, options = {})
      CouchI18n::Translation.untranslated(options.merge(key: "#{offset}.".."#{offset}.ZZZZZZZZZ"))
    end

    # Expire I18n when record is update
    def reload_i18n
      Rails.cache.write(key, value)
      I18n.reload!
      I18n.cache_store.clear if I18n.respond_to?(:cache_store) && I18n.cache_store.respond_to?(:clear)
    end
  end
end
