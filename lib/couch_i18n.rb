require "couch_i18n/engine"
require 'couch_i18n/store'
require 'couch_i18n/backend'
require 'couch_i18n/active_model_errors'
module CouchI18n
  # This method imports yaml translations to the couchdb version. When run again new ones will
  # be added. Translations already stored in the couchdb database are not overwritten
  def self.import_from_yaml
    raise "I18.backend not a I18n::Backend::Chain" unless I18n.backend.is_a?(I18n::Backend::Chain)
    # 
    yml_backend = I18n.backend.backends.last

    raise "Last backend not a I18n::Backend::Simple" unless yml_backend.is_a?(I18n::Backend::Simple)
    yml_backend.load_translations
    flattened_hash = traverse_flatten_keys(yml_backend.send(:translations))
    flattened_hash.each do |key, value|
      CouchI18n::Translation.create :key => key, :value => value
    end
  end

  # Recursive flattening.
  def self.traverse_flatten_keys(obj, store = {}, path = nil)
    case obj
    when Hash
     obj.each{|k, v| traverse_flatten_keys(v, store, [path, k].compact.join('.'))}
    when Array
      # Do not store array for now. There is no good solution yet
      store[path] = obj # Keeyp arrays intact
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
  def self.indent_keys(selection = CouchI18n::Translation.all)
    traverse_indent_keys(selection.map{|kv| [kv.key.split('.'), kv.value]})
  end

  # Traversing helper for indent_keys
  def self.traverse_indent_keys(ary, h = {})
    for pair in ary
      if pair.first.size == 1
        h[pair.first.first] = pair.last
      else
        h[pair.first.first] ||= {}
        next unless h[pair.first.first].is_a?(Hash) # In case there is a translation en.a: A, en.a.b: B this is invalid
        traverse_indent_keys([[pair.first[1..-1], pair.last]], h[pair.first.first])
      end
    end
    h
  end

  # Add all translations to the cache to avoid one by one loading and caching
  def self.cache_all
    CouchI18n::Translation.all.each do |t|
      Rails.cache.write(t.key, t.value)
    end
  end
end
# Now extend the I18n backend
I18n.backend = I18n::Backend::Chain.new(CouchI18n::Backend.new(CouchI18n::Store.new), I18n.backend) unless Rails.env == 'test'
