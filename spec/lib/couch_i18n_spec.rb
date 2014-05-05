require 'spec_helper'

describe CouchI18n do
  let(:t1){ CouchI18n::Translation.create translation_key: 'nl.prefix.partfinder.suffix', translation_value: 'Value', translated: true }
  let(:t2){ CouchI18n::Translation.create translation_key: 'nl.prefix.partfinder_disabled.suffix', translation_value: 'Value', translated: false }
  let(:t3){ CouchI18n::Translation.create translation_key: 'en.prefix.partfinder.suffix', translation_value: 'Value', translated: false }
  let(:expected_object) do
    {
      "nl" => {
        "prefix" => {
          "partfinder" => {"suffix"=>"Value"},
          "partfinder_disabled" => {"suffix"=>"Value"}
        }
      }, "en" => {
        "prefix" => {
          "partfinder" => {"suffix"=>"Value"}
        }
      }
    }
  end

  describe '.indent_keys' do
    it 'creates a proper hash' do
      t1 && t2 && t3
      described_class.indent_keys([t1, t2, t3]).should == expected_object
    end
  end

  describe '.traverse_flatten_keys' do
    it 'flattens a hash' do
      described_class.traverse_flatten_keys(expected_object).should == {
        t1.translation_key => t1.translation_value,
        t2.translation_key => t2.translation_value,
        t3.translation_key => t3.translation_value
      }
    end

  end
end
