%rou ; Routine Introspection
 Q
 ;
arglist(tag) ;
 Q:tag="" ""
 S l=$F(tag,"(")
 Q:l=0 ""                       ; Doesn't have an argument list.
 S r=$F(tag,")",l)
 Q:r=0 ""                       ; Something is messed up here.
 Q $E(tag,l,r-2)
 ;
hasTag(code,tag) ;
 Q $T(@(tag_code))'=""
 ;
