zqSystemPointers ; 62524,15953
 Q
 ;
do(%rs,%sort,class) ; 
 N %i1,%ok
 S %i1="" F  S %i1=$O(^oSysSchema(%i1)) Q:%i1=""  D
 . S datatype=$P(^oSysSchema(%i1),$C(31),$G(^dxSysSchema("datatype"),0))
 . S object=$P(^oSysSchema(%i1),$C(31),$G(^dxSysSchema("object"),0))
 . S %ok=(datatype="P")&(object=class)
 . Q:'%ok
 . S extra=$P(^oSysSchema(%i1),$C(31),$G(^dxSysSchema("extra"),0))
 . S shortname=$P(^oSysSchema(%i1),$C(31),$G(^dxSysSchema("short_name"),0))
 . S %rs(shortname)=%i1
 . S %rs(shortname)=%rs(shortname)_$C(31)_shortname
 . S %rs(shortname)=%rs(shortname)_$C(31)_extra
 . Q
 Q
 ;
