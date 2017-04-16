require 'spec_helper'

include RefParsers

describe EndNoteParser do
  let(:parser) { EndNoteParser.new }

  describe '.initialize' do
    it 'parses the input file correctly' do
      parser.open 'spec/support/example.enw'
    end
  end
end