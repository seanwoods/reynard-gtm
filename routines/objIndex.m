objIndex ;
 Q
 ;
index(class,id) ;
 N field,phys,val
 Q:$G(class)=""
 Q:$G(id)=""
 S phys="^x"_$$canonical^%obj2(class)
 S field="" F  S field=$O(@phys@("def","simple",field)) Q:field=""  D
 . S val=$$getField^%obj2(class,id,field)
 . S:val="" val=$C(1)
 . S @phys@("simple",val,id)=1
 . Q
 Q
 ;
deindex(class,id) ;
 N field,phys,val
 Q:$G(class)=""
 Q:$G(id)=""
 S phys="^x"_$$canonical^%obj2(class)
 S field="" F  S field=$O(@phys@("def","simple",field)) Q:field=""  D
 . S val=$$getField^%obj2(class,id,field)
 . S:val="" val=$C(1)
 . Q:$G(@phys@("simple",val,id))=""
 . K @phys@("simple",val,id)
 . Q
 Q
 ;
add(class,field) ;
 N phys
 Q:$G(class)=""
 Q:$G(field)=""
 S phys="^x"_$$canonical^%obj2(class)
 S @phys@("def","simple",field)=1
 Q
 ;
del(class,field) ;
 N phys
 Q:$G(class)=""
 Q:$G(field)=""
 S phys="^x"_$$canonical^%obj2(class)
 K @phys@("def","simple",field)
 Q
 ;
