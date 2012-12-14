require 'spec_helper'

describe CouchI18n::Translation do
  before :each do
    @t1 = CouchI18n::Translation.create(key: 'nl.prefix.partfinder.suffix', value: 'Value', translated: true)
    @t2 = CouchI18n::Translation.create(key: 'nl.prefix.partfinder disabled.suffix', value: 'Value', translated: false)
    @t3 = CouchI18n::Translation.create(key: 'en.prefix.partfinder.suffix', value: 'Value', translated: false)
  end

  describe "find by part" do
    it "should find all by part independent of locale" do
      CouchI18n::Translation.find_all_by_key_part('partfinder').should =~ [@t1, @t3]
    end
    it "should find all by part independent of locale that are untranslated if required" do
      CouchI18n::Translation.find_all_untranslated_by_key_part('partfinder').should == [@t3]
    end
  end

  describe :untranslated do
    it "should return untranslated translations" do
      CouchI18n::Translation.untranslated.should =~ [@t2, @t3]
    end

    it "should return untranslated from an offset" do
      CouchI18n::Translation.untranslated_with_offset('en').should == [@t3]
    end
  end

  describe :deeper_keys_for_offset do
    it "should return the locales with proper key name when offset is an empty string" do
      CouchI18n::Translation.deeper_keys_for_offset('').map{|h| h[:name] }.should =~ [:nl, :en]
    end
    it "should return the locales with proper key name when offset is nil" do
      CouchI18n::Translation.deeper_keys_for_offset(nil).map{|h| h[:name]}.should =~ [:nl, :en]
    end
    it "should return the locales with proper offset when offset is an empty string" do
      CouchI18n::Translation.deeper_keys_for_offset('').map{|h| h[:offset] }.should =~ [:nl, :en]
    end
    it "should return the locales with proper offset when offset is nil" do
      CouchI18n::Translation.deeper_keys_for_offset(nil).map{|h| h[:offset]}.should =~ [:nl, :en]
    end

    it "should return the deeper offset key names when offset is given" do
      CouchI18n::Translation.deeper_keys_for_offset('nl.prefix').map{|h| h[:name]}.should =~ [:partfinder, :'partfinder disabled']
    end
    it "should return the deeper offset keys with proper offset when offset is given" do
      CouchI18n::Translation.deeper_keys_for_offset('nl.prefix').map{|h| h[:offset]}.should =~ ["nl.prefix.partfinder", "nl.prefix.partfinder disabled"]
    end
  end

  describe :higher_keys_for_offset do
    it "should return an empty array when offset is an empty string" do
      CouchI18n::Translation.higher_keys_for_offset('').should == []
    end
    it "should return an empty array when offset is nil" do
      CouchI18n::Translation.higher_keys_for_offset(nil).should == []
    end

    it "should return an empty array when the offset is one level deep" do
      CouchI18n::Translation.higher_keys_for_offset('nl').should == []
    end

    it "should return the proper names when three levels deep is given" do
      CouchI18n::Translation.higher_keys_for_offset('a.b.c').map{|h| h[:name] }.should == %w[a b]
    end

    it "should return the proper offsets when three levels deep is given" do
      CouchI18n::Translation.higher_keys_for_offset('a.b.c').map{|h| h[:offset] }.should == %w[a a.b]
    end

  end

  describe 'it should be able to return only exact the current level' do
    before :each do
      @t4 = CouchI18n::Translation.create(key: 'en.other.suffix', value: 'Value')
      @t5 = CouchI18n::Translation.create(key: 'en.other.suffix.deeper_suffix', value: 'Value')
    end

    it "should be implemented" do
      pending
    end
  end

  describe 'find by value' do
    before :each do
      @t4 = CouchI18n::Translation.create(key: 'en.other.suffix', value: 'Other Value')
      @t5 = CouchI18n::Translation.create(key: 'en.other.suffix.deeper_suffix', value: 'Other Value')
    end
    it "should return translations with the same value Value" do
      CouchI18n::Translation.find_all_by_value('Value').should =~ [@t1, @t2, @t3]
    end
    it "should return translations with the same value Other Value" do
      CouchI18n::Translation.find_all_by_value('Other Value').should =~ [@t4, @t5]
    end
  end
end
