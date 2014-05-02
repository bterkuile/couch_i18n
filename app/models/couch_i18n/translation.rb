module CouchI18n
  class Translation
    include SimplyStored::Couch
    per_page_method :limit_value

    property :translation_value
    property :translated, type: :boolean, default: true

    after_save :reload_i18n

    def translation_key
      id.present? ? id[3..-1] : nil
    end

    def key
      translation_key
    end

    view :all_documents, map_function: %|function(doc){
      if(doc.ruby_class && doc.ruby_class == 'CouchI18n::Translation') {
        emit(doc._id.substr(3), 1);
      }
    }|, type: :custom, reduce_function: '_sum'
    #view :by_key, :key => :key

    view :with_key_array, map_function: %|function(doc){
      if(doc.ruby_class && doc.ruby_class == 'CouchI18n::Translation') {
        emit(doc._id.substr(3).split('.').slice(0, -1), 1);
      }
    }|, type: :raw, reduce_function: '_sum'

    view :untranslated_view, map_function: %|function(doc){
      if(doc.ruby_class && doc.ruby_class == 'CouchI18n::Translation' && !doc.translated) {
        emit(doc._id.substr(3), 1);
      }
    }|, type: :custom, reduce_function: '_sum'
    view :by_translation_value, key: :translation_value
    view :untranslated_by_translation_value, key: :translation_value, conditions: "!doc['translated']"
    view :by_translation_key_part, type: :custom, map_function: %|function(doc){
      if(doc.ruby_class && doc.ruby_class == 'CouchI18n::Translation') {
        doc._id.substr(3).split('.').forEach(function(key_part){
          emit(key_part, 1)
        })
      }
    }|, reduce_function: '_count'

    view :untranslated_by_translation_key_part, type: :custom, map_function: %|function(doc){
      if(doc.ruby_class && doc.ruby_class == 'CouchI18n::Translation' && !doc.translated) {
        doc._id.substr(3).split('.').forEach(function(key_part){
          emit(key_part, 1)
        })
      }
    }|, reduce_function: '_count'

    def self.get_translation_keys_by_level(level = 0, options = {})
      data = database.view(with_key_array(options.merge(group_level: level.succ)))["rows"]
      # data = data.select{|h| h["key"].size > level } # Only select ones that have a deeper nesting
      data.map{|h| h['key'][level].try(:to_sym)}.compact
    end

    def translation_key=(val)
      self.id = "t::#{val}"
    end

    # Shorthand for selecting all stored with a given offset
    def self.with_offset(offset, options = {})
      key = "#{offset}.".."#{offset}.ZZZZZZZZZ"
      total_entries = database.view(all_documents(key: key, reduce: true))
      with_pagination_options options.merge(total_entries: total_entries) do |options|
        database.view(all_documents(options.merge(key: key, reduce: false, include_docs: true)))
      end
    end

    def self.all(options = {})
      total_entries = database.view(all_documents(reduce: true))
      with_pagination_options options.merge(total_entries: total_entries) do |options|
        database.view(all_documents(options.merge(reduce: false, include_docs: true)))
      end
    end

    def self.find_by_translation_key(key)
      find("t::#{key}")
    end

    # Find all records having the term part in their key
    #   nl.action.one
    #   en.action.two
    #   en.activemodel.plural.models.user
    # and using
    #   find_all_by_part('action')
    # will return the first two since they have action as key part
    def self.find_all_by_key_part(part, options = {})
      total_entries = database.view(by_translation_key_part(key: part, reduce: true))
      with_pagination_options options.merge(total_entries: total_entries) do |options|
        database.view(by_translation_key_part(options.merge(key: part, reduce: false, include_docs: true)))
      end
    end

    # Find all untranslated records having the term part in their key
    #   nl.action.one
    #   en.action.two
    #   en.activemodel.plural.models.user
    # and using
    #   find_all_by_part('action')
    # will return the first two since they have action as key part
    def self.find_all_untranslated_by_key_part(part, options = {})
      total_entries = database.view(untranslated_by_translation_key_part(key: part, reduce: true))
      with_pagination_options options.merge(total_entries: total_entries) do |options|
        database.view(untranslated_by_translation_key_part(options.merge(key: part, reduce: false, include_docs: true)))
      end
    end

    # Find all untranslated records having the term part as value
    #   nl.action.one: 'Value', translated: true
    #   en.action.two: 'Value', translated: false
    #   en.activemodel.plural.models.user: 'Other Value', translated: false
    # and using
    #   find_all_untranslated_by_value('Value')
    # will return en.action.two
    def self.find_all_untranslated_by_value(part, options = {})
      total_entries = database.view(untranslated_by_translation_value(key: part, reduce: true))
      with_pagination_options options.merge(total_entries: total_entries) do |options|
        database.view(untranslated_by_translation_value(options.merge(key: part, reduce: false, include_docs: true)))
      end
    end

    # Find all untranslated records having the term part as value
    #   nl.action.one: 'Value', translated: true
    #   en.action.two: 'Value', translated: false
    #   en.activemodel.plural.models.user: 'Other Value', translated: false
    # and using
    #   find_all_untranslated_by_value('Value')
    # will return en.action.two
    def self.find_all_by_value(part, options = {})
      total_entries = database.view(by_translation_value(key: part, reduce: true))
      with_pagination_options options.merge(total_entries: total_entries) do |options|
        database.view(by_translation_value(options.merge(key: part, reduce: false, include_docs: true)))
      end
    end


    def self.untranslated(options = {})
      total_entries = database.view(untranslated_view(options.slice(:key, :keys, :startkey, :endkey).merge(reduce: true)))
      with_pagination_options options.merge(total_entries: total_entries) do |options|
        database.view(untranslated_view(options.merge(reduce: false, include_docs: true)))
      end
    end

    def self.untranslated_with_offset(offset, options = {})
      CouchI18n::Translation.untranslated(options.merge(key: "#{offset}.".."#{offset}.ZZZZZZZZZ"))
    end

    # Expire I18n when record is update
    def reload_i18n
      Rails.cache.write("couch_i18n-#{key}", value)
      #I18n.reload!
      #I18n.cache_store.clear if I18n.respond_to?(:cache_store) && I18n.cache_store.respond_to?(:clear)
    end

    def self.get_keys_by_level(level = 0, options = {})
      data = database.view(with_key_array(options.merge(group_level: level.succ)))["rows"]
      # data = data.select{|h| h["key"].size > level } # Only select ones that have a deeper nesting
      data.map{|h| h['key'][level].try(:to_sym)}.compact
    end

    def self.deeper_keys_for_offset( offset )
      return get_keys_by_level(0).map{|dl| {:name => dl, :offset => dl}} unless offset.present?
      levels = offset.split('.')
      get_keys_by_level(levels.size, :startkey => levels, :endkey => levels + [{}]).
            map{|dl| {:name => dl, :offset => [offset, dl].join('.')}}
    end

    def self.higher_keys_for_offset( offset )
      return [] unless offset.present?
      higher_keys = []
      levels = offset.split('.')
      return [] unless levels.size > 1
      # Add higher levels. Do not add the last level, since it is the current one => 0..-2
      levels[0..-2].each_with_index do |level_name, i|
        higher_keys<< {
          :name => level_name,
          :offset => levels[0..i].join('.')
        }
      end
      higher_keys
    end
  end
end
