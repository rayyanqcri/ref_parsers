# coding: utf-8

# developemnt instructions:
# 1- Do your modifications
# 2- Increase version number in lib/ref_parsers/version.rb
# 3- gem build ref_parsers.gemspec
# 4a- test the code by pointing Gemfile entry to ref_parsers path
# 4b- test by: gem install ref_parsers-VERSION.gem then upgrade version in Gemfile
# 5- git add, commit and push
# 6- gem push ref_parsers-VERSION.gem


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
  spec.homepage      = "https://github.com/rayyanqcri/ref_parsers"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'simplecov', '~> 0.14'
  spec.add_development_dependency 'coderay', '~> 1.1'
end
