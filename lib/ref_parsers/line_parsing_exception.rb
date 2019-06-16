module RefParsers
  class LineParsingException < StandardError
    attr_reader :line_number
    attr_reader :line_string
    attr_reader :inner_exception

    def initialize(message, line_number, line_string, innerException = nil)
      super("#{message} #{'(See inner exception for details)' + innerException.message if innerException} | Line# #{line_number} | Line Text: #{line_string}")
      @line_number = line_number
      @line_string = line_string
      @inner_exception = inner_exception
    end
  end
end
