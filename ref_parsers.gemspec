# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ref_parsers/version'

Gem::Specification.new do |spec|
  spec.name          = "ref_parsers"
  spec.version       = RefParsers::VERSION
  spec.authors       = ["Hossam Hammady"]
  spec.email         = ["github@hammady.net"]
  spec.description   = %q{Parser for various types of reference file formats. It currently supports RefMan (.ris) and EndNote (.enw)}
  spec.summary       = %q{Parser for reference file formats}
  spec.homepage      = "https://github.com/hammady/ref_parsers"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
