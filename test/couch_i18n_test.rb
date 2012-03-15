require 'test_helper'

class CouchI18nTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, CouchI18n
  end

  test "flatten and indenting reversibility" do
    assert_equal CouchI18n::Store.count, CouchI18n.traverse_flatten_keys({}, CouchI18n.indent_keys).size
    # And a lot more
  end

  test "finding by part" do
    t1 = CouchI18n::Translation.create(key: 'nl.prefix.partfinder.suffix', value: 'Value')
    t2 = CouchI18n::Translation.create(key: 'nl.prefix.partfinder disabled.suffix', value: 'Value')
    t3 = CouchI18n::Translation.create(key: 'en.prefix.partfinder.suffix', value: 'Value')
    assert_equal [t1, t3], CouchI18n::Translation.find_all_by_key_parth('partfinder')
  end
end
