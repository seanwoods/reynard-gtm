zqTestView ; 62524,26220
 Q
 ;
do(%rs,%sort) ; 
 N %i1,%ok
 S rs="id"_$C(31)_"name"_$C(31)_"breed"
 S %i1="" F  S %i1=$O(^oPets(%i1)) Q:%i1=""  D
 . S name=$P(^oPets(%i1),$C(31),$G(^dxPets("name"),0))
 . S %ok=($$sw^%str(name,"Tr"))
 . Q:'%ok
 . S breed=$P(^oPets(%i1),$C(31),$G(^dxPets("breed"),0))
 . S %rs(%i1)=%i1
 . S %rs(%i1)=%rs(%i1)_$C(31)_name
 . S %rs(%i1)=%rs(%i1)_$C(31)_breed
 . S %sort(breed,name,%i1)=1
 . Q
 Q
 ;
