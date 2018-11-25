require 'spec_helper'

include RefParsers

describe PubMedParser do
  let(:parser) { PubMedParser.new }

  describe '.initialize' do
    it 'parses the input file correctly' do
      parser.open 'spec/support/example.nbib'
    end
  end

  it 'should have the friendly_name' do
      expect(parser.friendly_name()).to eq("PubMed/NBIB Parser")
  end
end
