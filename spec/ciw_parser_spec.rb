require 'spec_helper'

include RefParsers

describe CIWParser do
  let(:parser) { CIWParser.new(:import_entry) }

  describe '.initialize' do
    it 'parses the input file correctly' do
      entries = parser.open 'spec/support/example.ciw'
      expect(entries.length).to eq(3)
    end
    it 'should have the friendly_name' do
      expect(parser.friendly_name()).to eq("Web of Science/CIW Parser")
    end
  end
end
