%test ; Test routines
 Q
 ;
assertEq(l,r,verbose) ; Raise an error if two values are unequal.
 Q:l=r
 I $G(verbose)=1 W "Expected "_$$repr^%str(r)_", got "_$$repr^%str(l)_" .",!
 S $EC=",U01-Assertion Failed,"
 Q
 ;
