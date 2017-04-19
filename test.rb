#!/usr/bin/env ruby

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'ref_parsers'

filename = ARGV[0]
raise "USAGE: #{__FILE__} <input-file>" if filename.nil?
parsers = {
  '.ris' => RefParsers::RISParser,
  '.enw' => RefParsers::EndNoteParser,
  '.nbib' => RefParsers::PubMedParser,
  '.ciw' => RefParsers::CIWParser
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
  raise "Please specify a file with a valid extension: #{parsers.keys.inspect}"
end

