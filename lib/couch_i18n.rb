require "couch_i18n/engine"
require 'couch_i18n/store'
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
  private

  # Recursive flattening.
  def self.traverse_flatten_keys(store, obj, path = nil)
    case obj
    when Hash
     obj.each{|k, v| traverse_flatten_keys(store, v, [path, k].compact.join('.'))}
    when Array
      store[path.underscore.tr(' ', '_')] = obj.to_json
      #obj.each_with_index{|v, i| traverse_flatten_keys(store, v, [path, i].compact.join('.'))}
    else
      store[path.underscore.tr(' ', '_')] = obj
    end
    return store
  end
end
