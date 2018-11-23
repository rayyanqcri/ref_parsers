module RefParsers
  NEWLINE_MERGER = '     '

  class LineParsingException < StandardError
    attr_reader :line_number
    attr_reader :line_string

    def initialize(message, line_number, line_string, innerException = nil)
      super("#{message} #{'(See inner exception for details)' if innerException} | Line# #{line_number} | Line Text: #{line_string}")
      self.set_backtrace(innerException.backtrace) if innerException
      @line_number = line_number
      @line_string = line_string
    end
  end

  class LineParser
    def initialize
      hash = {"@type_key" => @type_key, "@key_regex_order" => @key_regex_order, "@line_regex" => @line_regex,
              "@value_regex_order" => @value_regex_order, "@regex_match_length" => @regex_match_length}

      missing = hash.select{|k, v| v.nil?}
      raise "#{missing.keys.join(", ")} are missing" unless missing.empty?    
    end

    def open(filename)
      parse File.read(filename, encoding: 'UTF-8')
    end

    def parse(body)
      lines = body.split(/\n\r|\r\n|\n|\r/)
      entries = []
      next_line = skip_header(lines)
      begin
        entry_found = false
        next_line = parse_entry(lines, next_line) do |entry|
          entries << entry
          entry_found = true
        end
      end while entry_found
      entries
    end

protected
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

    def parse_entry(lines, next_line)
      begin
        return next_line if next_line >= lines.length
        line_text = lines[next_line]
        begin
          first = parse_first_line(line_text)
        rescue => ex
          raise LineParsingException.new("Error parsing first line", next_line, line_text, ex)
        end
        next_line = next_line + 1
      end while first.nil?

      return if first[:footer]

      fields = [first]

      last_parsed = {}
      begin
        parsed = parse_line(lines[next_line])
        next_line = next_line + 1
        if parsed
          return if parsed[:footer]
          stop = false
          if parsed[:key] == "-1"
            parsed[:key] = last_parsed[:key]
            parsed[:value] = "#{last_parsed[:value]}#{NEWLINE_MERGER}#{parsed[:value]}"
            fields.delete_at fields.length - 1
          elsif @terminator_key && parsed[:key] == @terminator_key
            yield hash_entry(fields)
            return next_line
          end
          last_parsed = parsed
          fields << parsed
        elsif @terminator_key.nil? || next_line >= lines.length
          stop = true
          yield hash_entry(fields)
          return next_line
        else
          stop = false
        end
      end until stop
    end

    def parse_first_line(line)
      first = parse_line(line, /^\d+/)  # skip leading entry numbers
      return first if first.nil? || first[:footer]
      raise "First line should start with #{@type_key}" if first[:key] != @type_key
      # lets not check for semantics here, leave it for the library client
      # raise "#{line}: Reference type should be one of #{@types.inspect}" unless @types.include? first[:value]
      first
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
      fields.delete_at 0
      fields.each do |field|
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
