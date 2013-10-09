class RisParser
  def self.parse(filename)
    body = File.read(filename, encoding: 'UTF-8')
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

private

  def self.parse_entry(lines, next_line)
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
        if parsed[:key] == "-1"
          parsed[:key] = last_parsed[:key]
          parsed[:value] = "#{last_parsed[:value]} #{parsed[:value]}"
          fields.delete_at fields.length - 1
        elsif parsed[:key] == 'ER'
          yield hash_entry(fields)
          return next_line
        end
        last_parsed = parsed
        fields << parsed
      end
    end while parsed
  end

  def self.parse_line(line)
    return nil if line.nil? || line.match(/^\s*$/)
    m = line.match(/(TY|ID|T1|TI|CT|A1|A2|AU|Y1|PY|N1|KW|RP|SP|EP|JF|JO|JA|J1|J2|VL|IS|T2|CY|PB|U1|U5|T3|N2|SN|AV|M1|M3|AD|UR|L1|L2|L3|L4|ER)  -( (.*))?/)
    if m && m.length == 4
      {key: m[1], value: m[3]}
    else
      {key: "-1", value: line}
    end
  end

  def self.parse_first_line(line)
    first = parse_line(line)
    return nil if first.nil?
    raise 'First line should start with TY' if first[:key] != 'TY'
    types = %w(ABST ADVS ART BILL BOOK CASE CHAP COMP CONF CTLG DATA ELEC GEN HEAR ICOMM INPR JFULL JOUR MAP MGZN MPCT MUSIC NEWS PAMP PAT PCOMM RPRT SER SLIDE SOUND STAT THES UNBILl UNPB VIDEO)
    raise "#{line}: Reference type should be one of #{types.inspect}" unless types.include? first[:value]
    first
  end

  def self.hash_entry(fields)
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
