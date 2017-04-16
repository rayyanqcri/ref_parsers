require 'spec_helper'

include RefParsers

describe LineParser do
  let(:parser) { LineParser.new }

  describe '#open' do
    let(:filename) { 'spec/support/example.txt' }
    let(:body) { "example content\n" }

    it 'calls parse with the contents of the input file' do
      expect(parser).to receive(:parse).with(body)
      parser.open(filename)
    end
  end

  describe '#parse' do
  end

  describe '#skip_header' do
    it "returns 0 when no header regexes specified" do
      expect(parser.send(:skip_header, %w(1 2 3))).to eq(0)
    end

    context "when header regexes are specified" do
      before {
        parser.instance_variable_set('@header_regexes', [/h1/, /h2/])        
      }

      it "raises an error if anything is preceding header lines" do
        expect{parser.send(:skip_header, %w(x h1 h2))}.to raise_error RuntimeError, /Header line/
      end

      it "raises an error if header lines are not in order" do
        expect{parser.send(:skip_header, %w(h2 h1))}.to raise_error RuntimeError, /Header line/
      end

      it "raises an error if header lines are not present" do
        expect{parser.send(:skip_header, %w(x1 x2))}.to raise_error RuntimeError, /Header line/
      end

      it "raises an error if header lines are not successive" do
        expect{parser.send(:skip_header, %w(h1 x h2))}.to raise_error RuntimeError, /Header line/
      end

      it "returns the next line after header lines when they are matching" do
        expect(parser.send(:skip_header, %w(h1 h2 c1 c2))).to eq(2)
      end
    end
  end

  describe '#detect_footer' do
    it "returns nil when no footer regex specified" do
      expect(parser.send(:detect_footer, "l")).to eq(nil)
    end

    context "when footer regex is specified" do
      before {
        parser.instance_variable_set('@footer_regex', /footer/)        
      }

      it "returns nil if line does not match footer" do
        expect(parser.send(:detect_footer, "l")).to eq(nil)
      end

      it "returns {footer: true} if line matches footer" do
        expect(parser.send(:detect_footer, "footer")).to eq({footer: true})
      end
    end
  end

  describe '#parse_entry' do
  end

  describe '#parse_first_line' do
  end

  describe '#parse_line' do
  end

  describe '#hash_entry' do
  end
end