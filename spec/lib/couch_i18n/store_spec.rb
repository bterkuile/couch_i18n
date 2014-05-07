require 'spec_helper'

describe CouchI18n::Store do
  subject { described_class.new }
  it 'finds by brackets' do
    @t1 = CouchI18n::Translation.create(translation_key: 'nl.prefix.partfinder.suffix', translation_value: 'Value', translated: true)
    subject['nl.prefix.partfinder.suffix'].should == 'Value'
  end

  it 'creates by bracket assignment' do
    subject['nl.prefix.partfinder.suffix'] = 'Assignment value'
    subject['nl.prefix.partfinder.suffix'].should == 'Assignment value'
  end
end
