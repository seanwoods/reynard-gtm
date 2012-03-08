zqSystemViews ; 62524,15953
 Q
 ;
do(%rs,%sort) ; 
 N %i1,%ok
 S %i1="" F  S %i1=$O(^oSysView(%i1)) Q:%i1=""  D
 . S description=$P(^oSysView(%i1),$C(31),$G(^dxSysView("description"),0))
 . S name=$P(^oSysView(%i1),$C(31),$G(^dxSysView("name"),0))
 . S %rs(%i1)=%i1
 . S %rs(%i1)=%rs(%i1)_$C(31)_name
 . S %rs(%i1)=%rs(%i1)_$C(31)_description
 . S %sort(description,%i1)=1
 . Q
 Q
 ;
