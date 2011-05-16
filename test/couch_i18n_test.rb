require 'test_helper'

class CouchI18nTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, CouchI18n
  end

  test "flatten and indenting reversibility" do
    assert_equal CouchI18n::Store.count, CouchI18n.traverse_flatten_keys({}, CouchI18n.indent_keys).size
    # And a lot more
  end
end
