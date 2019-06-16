#!/usr/bin/env ruby

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'ref_parsers'

dir_path = ARGV[0]
raise "USAGE: #{__FILE__} <input-directory-path>" if dir_path.nil?
raise "Directory '#{dir_path}' is not valid" if not File.directory?(dir_path)

parsers = {
  '.ris' => lambda {RefParsers::RISParser.new(:import_entry)},
  '.enw' => lambda {RefParsers::EndNoteParser.new()},
  '.nbib' => lambda {RefParsers::PubMedParser.new()},
  '.ciw' => lambda {RefParsers::CIWParser.new(:import_entry)}
}

Dir.entries(dir_path).select {|f| !File.directory? f}.each do |cur_file|
	parser_fac = parsers[File.extname(cur_file)]
    full_path = File.join(dir_path, cur_file)
	if parser_fac
      puts "Parsing file #{full_path}"
      begin
          entries = parser_fac.call().open(full_path) do |summary|
            puts summary
          end
      rescue => ex
        puts "Error parsing file #{full_path}. #{ex}"
      end
	else
	  puts "Could not identify the type of file #{full_path}"
	end
end
