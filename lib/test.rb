require 'ref_parsers'

filename = ARGV[0]
parsers = {
  '.ris' => RefParsers::RISParser,
  '.enw' => RefParsers::EndNoteParser
}
klass = parsers[File.extname(filename)]
if klass
  klass.new.open(ARGV[0]).each do |entry|
    puts "Entry"
    entry.each do |k, v|
      puts "  #{k}: #{v}"
    end
  end
else
  puts "Please specify a file with a valid extension: #{parsers.keys.inspect}"
end

