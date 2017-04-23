
module RefParsers
 

 class CIWParser < LineParser


    def initialize
     @footer_regex = "EF"
	 @header_regexes =["FN","VR"]
     @type_key = "PT"
     @terminator_key = "ER"
     @line_regex =  /^(AB|AF|AP|AR|AU|BE|BN|BP|C1|CA|CL|CR|CY|CT|DE|DI|DT|ED|EM|EP|ER|EF|EI|FN|FU|FX|GA|HO|ID|IS|J9|JI|LA|NR|OI|PD|PA|PG|PI|PN|PT|PU|PY|PM|RP|RI|SC|SE|SI|SN|SO|SP|SU|TC|TI|UT|U1|U2|UR|VL|VR|WC|WP|Z9|ZB|Z8|ZS)(\s*(.*))?$/
     @key_regex_order = 1
     @value_regex_order = 2
     @regex_match_length = 4
 
  
    end
    

 end

end