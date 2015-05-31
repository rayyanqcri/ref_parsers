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

    # creates a new parser of type RIS
    parser = RefParsers::RISParser.new

    # creates a new parser of type EndNote
    parser = RefParsers::EndNoteParser.new

    # opens filename and parses it
    parser.open(filename)

    # parses a string containing the reference source
    parser.parse(string)

The `parse` method returns an array of entries, each is a Hash of fields -> values.
For formats that enable multiline values, the parser will merge these lines in a single line
separating them with an amount of spaces defined in `RefParsers::NEWLINE_MERGER`.
This allows the value to be displayed normally in HTML elements because multiple spaces are collapsed,
and also allows you to split back the lines, if needed. Example:

    parser.parse(string).each do |entry|
      article['KW'].split(/#{RefParsers::NEWLINE_MERGER}/)
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
