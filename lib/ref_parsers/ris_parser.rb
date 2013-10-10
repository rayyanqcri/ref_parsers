module RefParsers
  class RISParser < LineParser

    def initialize
      @type_key = "TY"
      @types = %w(ABST ADVS ART BILL BOOK CASE CHAP COMP CONF CTLG DATA ELEC GEN HEAR ICOMM INPR JFULL JOUR MAP MGZN MPCT MUSIC NEWS PAMP PAT PCOMM RPRT SER SLIDE SOUND STAT THES UNBILl UNPB VIDEO)
      @terminator_key = "ER"
      @line_regex = /^(TY|ID|T1|TI|CT|A1|A2|AU|Y1|PY|N1|KW|RP|SP|EP|JF|JO|JA|J1|J2|VL|IS|T2|CY|PB|U1|U5|T3|N2|SN|AV|M1|M3|AD|UR|L1|L2|L3|L4|ER)  -( (.*))?$/
      @key_regex_order = 1
      @value_regex_order = 3
      @regex_match_length = 4
    end
    
  end
end