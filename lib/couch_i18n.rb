require "i18n/backend/cache"
require "couch_i18n/engine"
require 'couch_i18n/store'
I18n::Backend::KeyValue.send(:include, I18n::Backend::Cache)
module CouchI18n
  # This method imports yaml translations to the couchdb version. When run again new ones will
  # be added. Translations already stored in the couchdb database are not overwritten
  def self.import_from_yaml
    raise "I18.backend not a I18n::Backend::Chain" unless I18n.backend.is_a?(I18n::Backend::Chain)
    # 
    yml_backend = I18n.backend.backends.last

    raise "Last backend not a I18n::Backend::Simple" unless yml_backend.is_a?(I18n::Backend::Simple)
    yml_backend.load_translations
    flattened_hash = traverse_flatten_keys({}, yml_backend.send(:translations))
    flattened_hash.each do |key, value|
      CouchI18n::Store.create :key => key, :value => value
    end
  end

  # Recursive flattening.
  def self.traverse_flatten_keys(store, obj, path = nil)
    case obj
    when Hash
     obj.each{|k, v| traverse_flatten_keys(store, v, [path, k].compact.join('.'))}
    when Array
      # Do not store array for now. There is no good solution yet
      # store[path] = obj # Keeyp arrays intact
      # store[path] = obj.to_json
      # obj.each_with_index{|v, i| traverse_flatten_keys(store, v, [path, i].compact.join('.'))}
    else
      store[path] = obj
    end
    return store
  end

  # This will return an indented strucutre of a collection of stores. If no argument is given
  # by default all the translations are indented. So a command:
  #   CouchI18n.indent_keys.to_yaml will return one big yaml string of the translations
  def self.indent_keys(selection = Store.all)
    traverse_indent_keys({}, selection.map{|kv| [kv.key.split('.'), kv.value]})
  end

  # Traversing helper for indent_keys
  def self.traverse_indent_keys(h, ary)
    for pair in ary
      if pair.first.size == 1
        h[pair.first.first] = pair.last
      else
        h[pair.first.first] ||= {}
        traverse_indent_keys(h[pair.first.first], [[pair.first[1..-1], pair.last]])
      end
    end
    h
  end
end

# Now extend the I18n backend
I18n.backend = I18n::Backend::Chain.new(I18n::Backend::KeyValue.new(CouchI18n::Store), I18n.backend)
I18n.cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
