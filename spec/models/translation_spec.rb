require 'spec_helper'

describe CouchI18n::Translation do
  describe "find by part" do
    before :each do

      @t1 = CouchI18n::Translation.create(key: 'nl.prefix.partfinder.suffix', value: 'Value')
      @t2 = CouchI18n::Translation.create(key: 'nl.prefix.partfinder disabled.suffix', value: 'Value')
      @t3 = CouchI18n::Translation.create(key: 'en.prefix.partfinder.suffix', value: 'Value')
    end
    it "should find all by part independent of locale" do
      CouchI18n::Translation.find_all_by_key_part('partfinder').should =~ [@t1, @t3]
    end
  end


end
