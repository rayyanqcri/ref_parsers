module RefParsers
  class EndNoteParser < LineParser

    def initialize()
      @type_key = "0"
      @types = ["Generic", "Artwork", "Audiovisual Material", "Bill", "Book", "Book Section", "Case", "Chart or Table", "Classical Work", "Computer Program", "Conference Paper", "Conference Proceedings", "Edited Book", "Equation", "Electronic Article", "Electronic Book", "Electronic Source", "Figure", "Film or Broadcast", "Government Document", "Hearing", "Journal Article", "Legal Rule/Regulation", "Magazine Article", "Manuscript", "Map", "Newspaper Article", "Online Database", "Online Multimedia", "Patent", "Personal Communication", "Report", "Statute", "Thesis", "Unpublished Work", "Unused 1", "Unused 2", "Unused 3"]
      @terminator_key = nil
      @line_regex = /^%([A-NP-Z0-9\?\@\!\#\$\]\&\(\)\*\+\^\>\<\[\=\~])\s+(.*)$/
      @key_regex_order = 1
      @value_regex_order = 2
      @regex_match_length = 3
      super()
    end

    def friendly_name()
      "EndNote/ENW Parser"
    end	
  end
end
