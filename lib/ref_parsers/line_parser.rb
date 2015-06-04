module RefParsers
  NEWLINE_MERGER = '     '

  class LineParser
    def open(filename)
      parse File.read(filename, encoding: 'UTF-8')
    end

    def parse(body)
      lines = body.split(/\n\r|\r\n|\n|\r/)
      entries = []
      next_line = 0
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

    def parse_entry(lines, next_line)
      begin
        return next_line if next_line >= lines.length
        first = parse_first_line(lines[next_line])
        next_line = next_line + 1
      end while first.nil?

      fields = [first]

      last_parsed = {}
      begin
        parsed = parse_line(lines[next_line])
        next_line = next_line + 1
        if parsed
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
        elsif @terminator_key.nil?
          stop = true
          yield hash_entry(fields)
          return next_line
        else
          stop = false
        end
      end until stop
    end

    def parse_first_line(line)
      first = parse_line(line)
      return nil if first.nil?
      raise "First line should start with #{@type_key}" if first[:key] != @type_key
      # lets not check for semantics here, leave it for the library client
      # raise "#{line}: Reference type should be one of #{@types.inspect}" unless @types.include? first[:value]
      first
    end

    def parse_line(line)
      return nil if line.nil? || line.match(/^\s*$/)
      m = line.match(@line_regex)
      if m && m.length == @regex_match_length
        {key: m[@key_regex_order], value: m[@value_regex_order].try(:strip)}
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