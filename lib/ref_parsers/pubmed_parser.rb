module RefParsers
  class PubMedParser < LineParser

    def initialize()
      @type_key = "PMID"
      @terminator_key = nil
      @line_regex = /^(\w{1,4})\s{0,3}- (.*)$/
      @key_regex_order = 1
      @value_regex_order = 2
      @regex_match_length = 3
      super()
    end
    
    def friendly_name()
      "PubMed/NBIB Parser"
    end	 
  end
end
