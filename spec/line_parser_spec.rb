require 'spec_helper'

class LineParserChild < RefParsers::LineParser
  def initialize(type_key = "0", line_regex = /\d/, terminator_key = nil, regex_match_length = 3, missing_type_key_action=:raise_exception, footer_regex = nil)
    @type_key = type_key
    @terminator_key = terminator_key
    @line_regex = line_regex
    @footer_regex = footer_regex
    @key_regex_order = 1
    @value_regex_order = 2
    @regex_match_length = regex_match_length
    @missing_type_key_action = missing_type_key_action
    super()
  end
end

class LineParserEmptyChild < RefParsers::LineParser
  def initialize
    super
  end
end

include RefParsers

describe LineParser do
  let(:parser) { LineParserChild.new }

  describe '.initialize' do
    context "when the required values aren't specified" do
      it "should raise an error stating which ones aren't there" do
        expect{LineParserEmptyChild.new}.to raise_error(RuntimeError, "@type_key, @key_regex_order, @line_regex, @value_regex_order, @regex_match_length are missing")
      end
    end

    context "when the values are all specified" do
      it "should not raise an error" do
        expect{LineParserChild.new}.not_to raise_error
      end
    end

    context "when calling friendly_name" do
      it "should return the name of the calss by default" do
        expect(LineParserChild.new().friendly_name()).to eq("LineParserChild")
      end
    end
  end

  describe '#open' do
    #A little bit testing the framework rather than this library code, but this is useful for documentation and making sure no regressions.
    context "when opening a UTF-8 file that has a BOM bytes" do
      let(:filename) { 'spec/support/example_utf8_with_bom.txt' }
      let(:body) { "مثال لمحتوى - Example content\n" } #UTF-8 Text 

      it 'calls parse with the contents of the input file' do
        expect(parser).to receive(:parse).with(body)
        parser.open(filename)
      end
    end

    context "when opening a file with UTF-8 format" do
      let(:filename) { 'spec/support/example_utf8_without_bom.txt' }
      let(:body) { "مثال لمحتوى - Example content\n" } #UTF-8 Text 

      it 'calls parse with the contents of the input file in utf-8' do
        expect(parser).to receive(:parse).with(body)
        parser.open(filename)
      end
    end
  end

  describe '#parse' do
    let(:body){double("body")}
    let(:lines){double("line")}
    let(:next_line){double("next_line")}
    let(:log){double("log")}
    let(:empty_ret) {double("empty_ret", :next_line => nil, :is_empty => true, :is_terminator_found => false)}

    before{
      allow(body).to receive(:split) {lines}
      allow(parser).to receive(:skip_header).with(lines) {next_line}
    }

    context "when parse entry doesn't yield" do
      before {
        allow(parser).to receive(:parse_entry).with(lines, next_line, nil).and_return(empty_ret) 
      }

      it "should return an empty array" do
        expect(parser.parse(body)).to eq([])
      end
    end

    context "when parse entry have a problem with first line" do
      before {
        allow(parser).to receive(:parse_first_line).with("line").and_raise("SOME_ERROR")
        allow(parser).to receive(:is_valid_line) {true}
      }

      it "should throw an exception of type RefParsers::LineParsingException" do
        expect{parser.send(:parse_entry, %w(line line2), 0, nil)}.to raise_error RefParsers::LineParsingException
      end
    end

    context "when parse entry yields once" do
      let(:new_next_line) {double("new_next_line", :next_line => 1, :is_empty => false, :is_terminator_found => false)}
      let(:entry) {double("entry")}

      before {
        allow(parser).to receive(:parse_entry).with(lines, next_line, nil).and_yield(entry).and_return(new_next_line)
        allow(parser).to receive(:parse_entry).with(lines, 1, nil).and_return(empty_ret) 
      }

      it "should return an array consisting of one entry" do
        expect(parser.parse(body)).to eq([entry])
      end

      context "when parse entry yields twice" do
        let(:final_next_line) {double("final_next_line", :next_line => 2, :is_empty => false, :is_terminator_found => false)}
        before {
          allow(parser).to receive(:parse_entry).with(lines, 1, nil).and_yield(entry).and_return(final_next_line)
          allow(parser).to receive(:parse_entry).with(lines, 2, nil).and_return(empty_ret) 
        }

        it "should return an array consisting of one entry" do
          expect(parser.parse(body)).to eq([entry, entry])
        end
      end
    end

    context "when passing summary block" do
      let(:parser) { LineParserChild.new("TK", /(TK) =(.*)/) }
      let(:lines){["TK =TEST"]}
      let(:next_line){0}
      before {
        parser.parse(body) do |s|
          @summary = s
        end
      }
      it "should call the summary block with summary info" do
        expect(@summary).to be_kind_of(RefParsers::ParsingLogSummary)
      end

      it "should have not empty to_s" do
        expect(@summary.to_s()).not_to be_empty()
      end

      it "should have correct number of returned entries" do
        expect(@summary.number_of_entries).to eq(1)
      end
    end

    context "when type_key is at the same line of end token" do
      let(:parser) { LineParserChild.new("TK", /(TK|EN) =(.*)/, "EN") }
      let(:lines){["TK =TEST", "EN =      \t      TK =TEST2"]}
      let(:next_line){0}
       it "should have correct number of returned entries" do
         expect(parser.parse(body).entries.length).to eq(2)
      end
    end

    context "when type_key is not present but the terminator is there if :missing_type_key_action is set to :import_entry" do
      let(:parser) { LineParserChild.new("TK", /(TK|EN|AF) =(.*)/, "EN", 3, :import_entry) }
      let(:lines){["AF = TEST TEXT", "EN =", "TK =TEST2", "EN ="]}
      let(:next_line){0}
       it "should have correct number of returned entries" do
         expect(parser.parse(body).entries.length).to eq(2)
      end
    end

    context "when type_key is not present but the terminator is there if :missing_type_key_action is set to :import_entry and eof was found" do
      let(:parser) { LineParserChild.new("TK", /(TK|EN|AF) =(.*)/, "EN", 3, :import_entry) }
      let(:lines){["AF = TEST TEXT", "EN =", "TK =TEST2"]}
      let(:next_line){0}
       it "should have correct number of returned entries" do
         expect(parser.parse(body).entries.length).to eq(2)
      end
    end

    context "when type_key is not present but the terminator is there if :missing_type_key_action is set to :ignore_entry and eof was found" do
      let(:parser) { LineParserChild.new("TK", /(TK|EN|AF) =(.*)/, "EN", 3, :ignore_entry) }
      let(:lines){["TK =TEST", "AF = TEST TEXT", "EN =", "AF = TEST2"]}
      let(:next_line){0}
       it "should have correct number of returned entries" do
         expect(parser.parse(body).entries.length).to eq(1)
      end
    end

    context "when type_key is not present but the terminator is there if :missing_type_key_action is set to :ignore_entry" do
      let(:parser) { LineParserChild.new("TK", /(TK|EN|AF) =(.*)/, "EN", 3, :ignore_entry) }
      let(:lines){["AF =TEST TEXT", "EN =", "TK =TEST2", "EN ="]}
      let(:next_line){0}
       it "should have correct number of returned entries" do
         expect(parser.parse(body).entries.length).to eq(1)
      end
    end

    context "when type_key is not present but the terminator is there if :missing_type_key_action is set to :ignore_entry and footer was found" do
      let(:parser) { LineParserChild.new("TK", /(TK|EN|AF|AF2) =(.*)/, "EN", 3, :ignore_entry, /^FT$/) }
      let(:lines){["AF = TEST2", "AF2 = TEST2","FT"]}
      let(:next_line){0}
       it "should have correct number of returned entries" do
         expect(parser.parse(body).entries.length).to eq(0)
      end
    end

    context "when type_key is not present but the terminator is there if :missing_type_key_action is set to :raise_exception" do
      let(:parser) { LineParserChild.new("TK", /(TK|EN|AF) =(.*)/, "EN", 3, :raise_exception) }
      let(:lines){["AF =TEST TEXT", "EN =", "TK =TEST2", "EN ="]}
      let(:next_line){0}
      it "it should throw exception" do
         expect{parser.parse(body)}.to raise_error RefParsers::LineParsingException
      end
    end

    context "when there are info between last tag and " do
      let(:parser) { LineParserChild.new("TK", /(TK|EN|AF) =(.*)/, "EN") }
      let(:lines){["TK =TEST", "EN =", "  ", "Ss", "", "TK =TEST2"]}
      let(:next_line){0}
       it "should have correct number of returned entries" do
         expect(parser.parse(body).entries.length).to eq(2)
      end
    end
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
    context "if the length of the lines are greater than next line" do
      let(:lines){double("lines")}
      let(:next_line){1}

      before {
        allow(lines).to receive(:length) {0}
      }

      it "should return next line" do
        expect(parser.send(:parse_entry, lines, next_line).current_line).to eq(next_line)
      end
    end

    context "if the length of the lines isn't greater than next line" do
      let(:lines){[double("lines"), double("lines2")]}
      let(:next_line){0}

      # testing the initial loop element
      context "if parse_first_line(lines[next_line]) (next_line is 2) is not nil" do
        let(:lines){[double("lines"), double("lines2")]}
        let(:hash_entry){double("terminator_key")}

        before {
          allow(parser).to receive(:parse_first_line).with(lines[next_line]) {nil}
          allow(parser).to receive(:parse_first_line).with(lines[next_line + 1]) {{}}
          allow(parser).to receive(:parse_line).with(lines[next_line + 2]) {nil}
          allow(parser).to receive(:hash_entry).with([{}]) {hash_entry}
          allow(parser).to receive(:is_valid_line) {true}
        }

        it "should return next_line + 2 and yield hash_entry(fields)" do
          expect { |b|
            detail = parser.send(:parse_entry, lines, next_line, &b)
            expect(detail.next_line).to eq(next_line + 3)
          }.to yield_with_args(hash_entry)
        end
      end

      context "if parse_first_line(lines[next_line]) (next line is 1) is not nil" do
        before {
          allow(parser).to receive(:hash_entry).with([first]) {hash_entry}
          allow(parser).to receive(:parse_first_line).with(lines[next_line]) {first}
          allow(parser).to receive(:is_valid_line) {true}
        }

        context "if first[:footer] is not nil or false" do
          let(:first){{footer: true}}

          it "should return is_empty" do
            expect(parser.send(:parse_entry, lines, next_line).is_empty{}).to eq(true)
          end
        end

        context "if first[:footer] is nil or false" do
          let(:first){{}}
          let(:terminator_key){double("fake_terminator_key")}

          shared_examples "yield and return next_line" do
            it "should yield hash_entry(fields) and return next line" do
              expect { |b|
                detail = parser.send(:parse_entry, lines, next_line, &b)
                expect(detail.next_line).to eq(next_line + 2)
              }.to yield_with_args(hash_entry)
            end
          end

          context "if parsed is not nil or false" do
            before {
              allow(parser).to receive(:parse_line).with(lines[next_line + 1]) {parsed}
              allow(parser).to receive(:parse_line).with(nil) {nil}
              allow(parser).to receive(:is_valid_line) {true}
            }

            context "if parsed[:footer] is not nil or false" do
              let(:parsed){{footer: true}}
              it "should return parsed" do
                expect(parser.send(:parse_entry, lines, next_line).is_empty(){}).to eq(true)
              end
            end

            context "if parsed[:footer] is nil or false" do
              context "if parsed[:key] = '1'" do
                let(:parsed){{key: "-1"}}
                let(:hash_entry){double("terminator_key")}

                before {
                  allow(parser).to receive(:hash_entry).with([{:key=>nil, :value=>"     "}]) {hash_entry}
                  allow(parser).to receive(:is_valid_line) {true}
                }

                it "should return next + 2 and yield hash_entry(fields)" do
                  expect { |b|
                    detail = parser.send(:parse_entry, lines, next_line, &b)
                    expect(detail.next_line).to eq(next_line + 3)
                  }.to yield_with_args(hash_entry)
                end
              end

              context "if @terminator_key is not nil or false and parsed[:key] == @terminator_key" do
                let(:hash_entry){double("terminator_key and parsed[:key]")}
                let(:parsed){{key: terminator_key}}

                before {
                  parser.instance_variable_set('@terminator_key',terminator_key)
                }

                it_behaves_like "yield and return next_line"
              end
            end
          end

          context "if the parsed is false or nil" do
            before {
              allow(parser).to receive(:parse_line).with(lines[(next_line + 1)]) {nil}
              allow(parser).to receive(:parse_line).with(lines[(next_line + 2)]) {nil}
              allow(parser).to receive(:is_valid_line) {true}
            }

            context "if the terminator key is nil" do
              let(:hash_entry){double("terminator_key")}
              it_behaves_like "yield and return next_line"
            end

            context "if the next_line >= lines.length" do
              before {
                parser.instance_variable_set('@terminator_key', terminator_key)
              }

              let(:hash_entry){"line_length"}
              it_behaves_like "yield and return next_line"
            end

            context "if it doesn't satisfy any of the if statement conditions (else)" do
              let(:lines){[double("lines"), double("lines2"), double("lines3")]}
              let(:hash_entry){"line_length"}
              let(:terminator_key){double("fake_terminator_key")}

              before {
                parser.instance_variable_set('@terminator_key', terminator_key)
              }

              it "should yield hash_entry(fields) and return next line" do
                expect { |b|
                  detail = parser.send(:parse_entry, lines, next_line, &b)
                  expect(detail.next_line).to eq(next_line + 3)
                }.to yield_with_args(hash_entry)
              end
            end
          end
        end
      end
    end
  end

  describe '#parse_first_line' do
    context "when the line is nil" do
      let(:answer) {nil}

      before {
        allow(parser).to receive(:parse_line).with(nil, /^\d+/) {answer}
      }

      it "return nils, when the line entered is nil" do
        expect(parser.send(:parse_first_line,answer)[0]).to eq(answer)
      end
    end

    context "when the first[:footer] is true" do
      let(:answer){{footer: true}}
      let(:line) {"valid footer"}

      before {
        allow(parser).to receive(:is_valid_line) {true}
        allow(parser).to receive(:parse_line).with(line, /^\d+/) {answer}
      }

      it "returns first, which is {footer: true}" do
        expect(parser.send(:parse_first_line, line)[0]).to eq(answer)
      end
    end

    context "when the line is valid" do
      before {
        allow(parser).to receive(:parse_line).with(line,/^\d+/) {answer}
      }

      let(:line){"valid line"}

      context "when the value for the key :key in first isn't the type key" do
        let(:answer){{key: "1"}}

        before {
          allow(parser).to receive(:parse_line).with(line, /^\d+/) {answer}
        }

        #type_key is "0"
        it "should raise an error with the error message First line should start with #{@type_key}" do
          expect{parser.send(:parse_first_line,line)[0]}.to raise_error(RuntimeError, "First line should start with 0")
        end
      end

      context "when the line first[:key] is type_key" do
        let(:answer){{key: "0"}}

        it "should return the variable first which is parse_line(line, /^\d+/)" do
          expect(parser.send(:parse_first_line,line)[0]).to eq(answer)
        end
      end
    end
  end

  describe '#parse_line' do
    it "returns nil, when line is nil" do
      expect(parser.send(:parse_line, nil)).to eq(nil)
    end

    shared_examples "white space" do
      it "returns nil, when line contains white space character at the end or the start of the line" do
        expect(parser.send(:parse_line,line)).to eq(nil)
      end
    end

    context "when the line is a space" do
      let(:line){" "}
      it_behaves_like "white space"
    end

    context "when the line is three spaces" do
      let(:line){"   "}
      it_behaves_like "white space"
    end

    context "whe the line is empty" do
      let(:line){""}
      it_behaves_like "white space"
    end

    context "when the line is a tab and a newline character" do
      let(:line){"\t\n"}
      it_behaves_like "white space"
    end

    context "when the line is tab" do
      let(:line){"\t"}
      it_behaves_like "white space"
    end

    context "when the line is newline character" do
      let(:line){"\n"}
      it_behaves_like "white space"
    end

    context "when the line is return character" do
      let(:line){"\r"}
      it_behaves_like "white space"
    end

    context "when an ignore is inputted" do
      it "returns nil, if the line matches the ignore inputted" do
        expect(parser.send(:parse_line,"9",/\d/)).to eq(nil)
      end

      it "does not return nil, if the line doesn't match ignore inputted" do
        expect(parser.send(:parse_line,"a",/\d/)).not_to eq(nil)
      end

      it "returns nil, the line matches preset ignore" do
        expect(parser.send(:parse_line," ",/\d/)).to eq(nil)
      end
    end

    context "if the line matches the footer"  do
      let(:line) {'valid_footer'}
      let(:answer) {double}

      before {
        allow(line).to receive(:match).with(/^\s*$/) {false}
        allow(parser).to receive(:detect_footer).with(line) {answer}
      }

      it "delegate return value to detect_footer" do
        expect(parser.send(:parse_line, line)).to eq(answer)
      end
    end

    context "when the line doesn't match the footer" do
      let(:line){"valid line"}
      let(:continue_result){{key: "-1", value: line}}

      before {
        allow(parser).to receive(:detect_footer).with(line) {nil}
        allow(line).to receive(:match).with(/^\s*$/) {false}
      }

      context "when the line matches the line regex" do
        context "when the match line matches regex match length" do
          context "when the value regex order is within the array" do
            before {
              allow(line).to receive(:match).with(/\d/) {["1", "2", "3"]}
            }

            it "will return {key: m[@key_regex_order], value: value} with value equalling m[@value_regex_order].strip" do
              expect(parser.send(:parse_line, line)).to eq({key: "2", value: "3"})
            end
          end

          context "when the value regex order is outside the array" do
            let(:match_result){[1, 2]}
            before {
              allow(line).to receive(:match).with(/\d/) {match_result}
              allow(match_result).to receive(:length) {3}
            }

            it "will return {key: m[@key_regex_order, value: nil}" do
              expect(parser.send(:parse_line, line)).to eq({key: 2, value: nil})
            end
          end
        end

        context "when the line matchdata doesn't match regex match length" do
          before {
            allow(line).to receive(:match).with(/\d/) {[1, 2, 3, 4]}
          }

          it "will return {key: '-1', value: line} where line is the inputted line" do
            expect(parser.send(:parse_line, line)).to eq(continue_result)
          end
        end
      end

      context "when the line doesn't match the line regex" do
        before {
          allow(line).to receive(:match).with(/\d/) {nil}
        }

        it "will return {key: '-1', value: line} where line is the inputted line" do
          expect(parser.send(:parse_line, line)).to eq(continue_result)
          #todo: put a let
        end
      end
    end
  end

  describe '#hash_entry' do
    let(:value){double}
    let(:key){double}
    let(:key_value){double}
    let(:key_hash){{:key => key, :value => key_value}}

    context "if fields only contains the type" do
      let(:fields){[{:value => value}]}

      it "should return an hash with just the type" do
        expect(parser.send(:hash_entry,fields)).to eq({'type' => value})
      end
    end

    context "if the fields contatin the type and just a single key" do
      let(:fields){[{:value => value}, key_hash]}

      it "should return an hash with the with the type and the key" do
        expect(parser.send(:hash_entry, fields)).to eq('type' => value, key => key_value)
      end
    end

    context "if the fields contain the type and two hashes which repeat a key" do
      let(:fields){[{:value => value}, key_hash, key_hash]}

      it "should return an hash with the type and the repeated key contains an array" do
        expect(parser.send(:hash_entry, fields)).to eq({'type' => value, key => [key_value, key_value]})
      end
    end

    context "if the fields contain the type along with two hashes which repeat a key (one of the values is an array)" do
      let(:fields){[{:value => value}, {:key => key, :value => [key_value]}, key_hash]}

      it "should return an hash with the type and the repeated key's value should be an array" do
        expect(parser.send(:hash_entry, fields)).to eq({'type' => value, key => [key_value, key_value]})
      end
    end

    context "if the field contains three repeated keys along with the type" do
      let(:fields){[{:value => value}, key_hash, key_hash, key_hash]}

      it "should return an hash with the type and the repeated key's value should be an array" do
        expect(parser.send(:hash_entry, fields)).to eq({'type' => value, key => [key_value, key_value, key_value]})
      end
    end
  end
end
