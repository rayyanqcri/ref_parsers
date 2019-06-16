module RefParsers
  class RISParser < LineParser

    def initialize(missing_type_key_action=:raise_exception)
      @type_key = "TY"
      @types = %w(ABST ADVS ART BILL BOOK CASE CHAP COMP CONF CTLG DATA ELEC GEN HEAR ICOMM INPR JFULL JOUR EJOUR MAP MGZN MPCT MUSIC NEWS PAMP PAT PCOMM RPRT SER SLIDE SOUND STAT THES UNBILl UNPB VIDEO)
      @terminator_key = "ER"
      @line_regex = /^(A1|A2|A3|A4|AB|AD|AN|AU|AV|BT|C1|C2|C3|C4|C5|C6|C7|C8|CA|CN|CP|CT|CY|DA|DB|DO|DP|ED|EP|ER|ET|ID|IS|J1|J2|JA|JF|JO|KW|L1|L2|L3|L4|LA|LB|M1|M2|M3|N1|N2|NV|OP|PB|PY|RI|RN|RP|SE|SN|SP|ST|SV|T1|T2|T3|TA|TI|TT|TY|U1|U5|UR|VL|Y1|Y2|Y3)  -(\s*(.*))?$/
      @key_regex_order = 1
      @value_regex_order = 3
      @regex_match_length = 4
      @missing_type_key_action = missing_type_key_action
      super()
    end
    
    def friendly_name()
      "Refman/RIS Parser"
    end	
  end
end
