module RefParsers
  NEWLINE_MERGER = '     '

  class ParsingLogSummary
    attr_reader :number_of_entries
    attr_reader :number_of_keys
    attr_reader :number_of_terminators
    attr_reader :number_of_ignored_entries
    attr_reader :number_of_imported_entries_without_type
    
    def initialize(parser_friendly_name)
      @number_of_entries = 0
      @number_of_keys = 0
      @number_of_terminators = 0
      @number_of_ignored_entries = 0
      @number_of_imported_entries_without_type = 0
      @parser_friendly_name = parser_friendly_name
    end

    def report_entries(entries)
      @number_of_entries = entries.length
    end

    def detail_found(detail)
      @number_of_keys += 1 if detail.is_type_found
      @number_of_terminators += 1 if detail.is_terminator_found
      @number_of_ignored_entries += 1 if detail.action == :ignore_entry
      @number_of_imported_entries_without_type += 1 if detail.action == :import_entry
    end

    def to_s
      "Parser: #{@parser_friendly_name} Number of returned entries: #{@number_of_entries} | Number of keys: #{@number_of_keys} | Number of terminators: #{@number_of_terminators} | Ignored entries: #{@number_of_ignored_entries} | Entries without type key but still imported: #{@number_of_imported_entries_without_type}"
    end
  end

  class LineParser
    module MissingTypeKeyWithTerminatorAction
      :raise_exception #fail the entire file. This is the default behavior for backward compatibility
      :ignore_entry #ignore that entry but import other entries with a type_key in the file
      :import_entry #will import the entry anyway. and will report it in the ParsingLogSummary.
    end

    def initialize
      hash = {"@type_key" => @type_key, "@key_regex_order" => @key_regex_order, "@line_regex" => @line_regex,
              "@value_regex_order" => @value_regex_order, "@regex_match_length" => @regex_match_length}

      missing = hash.select{|k, v| v.nil?}
      @missing_type_key_action = :raise_exception if !@missing_type_key_action
      raise "#{missing.keys.join(", ")} are missing" unless missing.empty?    
    end

    def open(filename, &summary_handler)
      parse(File.read(filename, mode: 'r:bom|UTF-8'), &summary_handler)
    end

    def parse(body, &summary_handler)
      lines = body.split(/\n\r|\r\n|\n|\r/)
      entries = []
      first_tag_override = nil
      if summary_handler
        summary = ParsingLogSummary.new(self.friendly_name)
      end
      next_line = skip_header(lines)
      begin
        entry_found = false
        entry_is_null = false
        detail = parse_entry(lines, next_line, first_tag_override) do |entry|
          if entry
            entries << entry
          end
          entry_found = true
        end
        if summary_handler
          summary.detail_found(detail)
        end
        first_tag_override = nil
        next_line = detail.next_line if detail.next_line

        if detail.is_empty 
          break
        elsif detail.is_terminator_found #terminator same line as the same line as the beginning of next segment. I would have prefered to have a pass for fixing text before going through lines. But, The current version just loads the entire file into memory, that can be a potential performance problem and will be replaced by streaming the file instead and then the text fixing pass won't work 
          full_line_text = lines[detail.current_line]
          if detail.parsed and detail.parsed[:value]
            trimed = detail.parsed[:value].strip
            has_first, first = try_get_first_line(trimed)
            if has_first and first
              first_tag_override = first
            end
          end
        end
      end while entry_found
      if summary_handler
        summary.report_entries(entries)
        summary_handler.call(summary)
      end
      entries
    end

    def friendly_name()
      self.class.name
    end
protected
    class ParsingInfoDetail
      attr_accessor :first_line
      attr_accessor :is_type_found
      attr_accessor :is_empty
      attr_accessor :is_terminator_found
      attr_accessor :is_eof_found
      attr_accessor :current_line
      attr_accessor :parsed
      attr_accessor :action

      def next_line
        return @current_line + 1 
      end

      def initialize()
        @current_line = 0
        @first_line = 0
        @is_type_found = false
        @is_empty = false
        @is_terminator_found = false
        @is_eof_found = false
        @action = nil
      end
    end

    def skip_header(lines)
      return 0 unless @header_regexes
      next_line = 0
      @header_regexes.each do |regex|
        line = lines[next_line]
        raise "Header line #{next_line} missing" unless line.match(regex)
        next_line += 1
      end
      next_line
    end

    def detect_footer(line)
      return nil unless @footer_regex
      return {footer: true} if line.match(@footer_regex)
    end

    def parse_entry(lines, next_line, first_line_override = nil)
      begin
        detail = ParsingInfoDetail.new()
        detail.current_line = next_line
        action = nil
        if !first_line_override
          begin
            if detail.current_line >= lines.length
              detail.is_eof_found = true
              return detail 
            end
            line_text = lines[detail.current_line]
            begin
              if !is_valid_line(line_text)
                first = nil
              else
                first, action = parse_first_line(line_text)
              end
            rescue => ex
              raise RefParsers::LineParsingException.new("Error parsing first line", detail.current_line, line_text, ex)
            end
            detail.current_line = detail.current_line + 1
          end while first.nil?
        else
          first = first_line_override
        end

        detail.action = action

        if action.nil?
          detail.is_type_found = true
          detail.first_line = detail.current_line
        end

        if first[:footer]
          detail.is_empty = true 
          return detail
        end

        fields = [first]

        last_parsed = {}
        begin
          parsed = parse_line(lines[detail.current_line])
          if parsed
            detail.parsed = parsed
            if parsed[:footer]
              if fields and fields.length > 1
                if action != :ignore_entry
                  yield hash_entry(fields)
                else
                  yield nil
                end
              else
                detail.is_empty = true
              end
              return detail
            end
            stop = false
            if parsed[:key] == "-1"
              parsed[:key] = last_parsed[:key]
              parsed[:value] = "#{last_parsed[:value]}#{NEWLINE_MERGER}#{parsed[:value]}"
              fields.delete_at fields.length - 1
            elsif @terminator_key && parsed[:key] == @terminator_key
              detail.is_terminator_found = true
              if action != :ignore_entry
                yield hash_entry(fields)
              else
                yield nil
              end
              return detail
            end
            last_parsed = parsed
            fields << parsed
          elsif @terminator_key.nil? || detail.next_line >= lines.length
            stop = true
            detail.is_eof_found = true
            if action != :ignore_entry
              yield hash_entry(fields)
            else
              yield nil
            end
            return detail
          else
            stop = false
          end
          detail.current_line += 1
        end until stop
      end
    end
    
    def try_get_first_line(line)
      first = parse_line(line, /^\d+/) # skip leading entry numbers
      return  (first and first[:key] == @type_key), first
    end

    def parse_first_line(line)
      action = nil
      has_first, first = try_get_first_line(line) 

      return first, nil  if first.nil? || first[:footer] 
      
      if !has_first
        fail_first_line = lambda {
            raise "First line should start with #{@type_key}" 
        }
        if @terminator_key.nil?
          fail_first_line.call()
        elsif @missing_type_key_action == :ignore_entry
          action = :ignore_entry
        elsif @missing_type_key_action == :import_entry
          action = :import_entry
        else
          fail_first_line.call()
        end
      end
      # lets not check for semantics here, leave it for the library client
      # raise "#{line}: Reference type should be one of #{@types.inspect}" unless @types.include? first[:value]
      return first, action, has_first
    end

    def is_valid_line(line)
      ignores = []
      ignores << /^\s*$/
      ignores << /^\d+/
      return false if line.nil? || ignores.any?{|e| line.match(e)}
       m = line.match(@line_regex)
       return !m.nil?
    end

    def parse_line(line, *ignores)
      ignores << /^\s*$/
      return nil if line.nil? || ignores.any?{|e| line.match(e)}
      footer = detect_footer(line)
      return footer if footer
      m = line.match(@line_regex)
      if m && m.length == @regex_match_length
        value = m[@value_regex_order].strip rescue nil
        {key: m[@key_regex_order], value: value}
      else
        {key: "-1", value: line}
      end
    end

    def hash_entry(fields)
      entry = {'type' => fields.first[:value]}
      fields.drop(1).each do |field| #skip type field
        if entry[field[:key]].nil? # empty value
          entry[field[:key]] = field[:value]
        elsif entry[field[:key]].instance_of? Array # array of values
          entry[field[:key]] << field[:value]
        else # value
          entry[field[:key]] = [entry[field[:key]], field[:value]]
        end
      end
      entry
    end
  end
end
