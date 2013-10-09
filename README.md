# RefParsers

Parser for various types of reference file formats. It currently supports RefMan (.ris) and EndNote (.enw)

## Installation

Add this line to your application's Gemfile:

    gem 'ref_parsers'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ref_parsers

## Usage

    RisParser.parse(filename)

This returns an array of entries read from that file. Each entry is a Hash of fields -> values.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
