require 'spec_helper'

include RefParsers

describe CIWParser do
  let(:parser) { CIWParser.new }

  describe '.initialize' do
    it 'parses the input file correctly' do
      parser.open 'spec/support/example.ciw'
    end
  end
end