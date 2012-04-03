%op ; Operators
 Q
 ;
inList(needle,haystack,delim) ;
 S:$G(delim)="" delim=" "
 Q haystack[(delim_needle_delim)
 ;
notInList(needle,haystack,delim) ;
 Q '$$inList(needle,haystack,delim)
 ;
