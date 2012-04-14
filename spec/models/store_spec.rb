require 'spec_helper'

describe CouchI18n::Store do
  describe "yaml conversion" do
    before :each do
      
    end
    it "should flatten and indenting reversibility" do
      CouchI18n::Translation.count.should == CouchI18n.traverse_flatten_keys({}, CouchI18n.indent_keys).size
    end
  end
end
