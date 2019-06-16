require 'spec_helper'

include RefParsers

describe RISParser do
  let(:parser) { RISParser.new }

  describe '.initialize' do
    it 'parses the input file correctly' do
      parser.open 'spec/support/example.ris'
    end

    it 'should have the friendly_name' do
      expect(parser.friendly_name()).to eq("Refman/RIS Parser")
    end
  end
end
