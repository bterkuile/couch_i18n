require "couch_i18n/engine"
require 'couch_i18n/store'
require 'couch_i18n/backend'
require 'couch_i18n/active_model_errors'

# Ugly fix for the updated json gem changes
#module JSON
#  class << self
#    alias :old_parse :parse
#    def parse(json, args = {})
#      args[:create_additions] = true
#      old_parse(json, args)
#    end
#  end
#end

module CouchI18n
  @@__missing_key_handler = nil
  # This method imports yaml translations to the couchdb version. When run again new ones will
  # be added. Translations already stored in the couchdb database are not overwritten if true or ovveride_existing: true is given
  def self.import_from_yaml(options = {})
    options = {:override_existing => true} if options.is_a?(TrueClass)
    options = {:override_existing => false} if options.is_a?(FalseClass)
    options = {:override_existing => false}.merge!(options)
    raise "I18.backend not a I18n::Backend::Chain" unless I18n.backend.is_a?(I18n::Backend::Chain)
    # 
    yml_backend = I18n.backend.backends.last

    raise "Last backend not a I18n::Backend::Simple" unless yml_backend.is_a?(I18n::Backend::Simple)
    yml_backend.load_translations
    flattened_hash = traverse_flatten_keys(yml_backend.send(:translations))
    available_translations = CouchI18n::Translation.all
    flattened_hash.each do |key, value|
      available_translation = available_translations.find{|t| t.translation_key == key}
      if available_translation && options[:override_existing]
        available_translation.translation_value = value
        available_translation.translated = true
        available_translation.save
      else
        available_translation = CouchI18n::Translation.create translation_key: key, translation_value: value
      end
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
    traverse_indent_keys(selection.map{|kv| [kv.translation_key.split('.'), kv.translation_value]})
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

  def self.handle_missing_key(key)
    missing_key_handler.call(key) if missing_key_handler
  end

  def self.missing_key_handler
    @@__missing_key_handler
  end

  def self.missing_key(&blk)
    raise "Assign a block to handle a missing key" unless blk.present?
    raise "The missing key proc should handle the key as argument CouchI18n.missing_key{ |key| .... }" unless blk.arity == 1
    @@__missing_key_handler = blk
  end
end

# Now extend the I18n backend
I18n.backend = I18n::Backend::Chain.new(CouchI18n::Backend.new(CouchI18n::Store.new), I18n.backend) unless Rails.env == 'test'
I18n.load_path += Dir.glob(File.join(File.dirname(__FILE__), '..', 'config', 'locales', '*'))
