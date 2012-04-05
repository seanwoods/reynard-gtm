objSchema ;
 Q
 ;
onFile(class,id) ;
 N dest,dx,glvn,fld,src,val
 S glvn=$$glvn^%obj(class,"o"),dx=$$glvn^%obj(class,"dx")
 S dest="" F  S dest=$O(^xSysSchema("ObjExtraX",class,"SL",dest)) Q:dest=""  D
 . S src=$P($O(^xSysSchema("ObjExtraX",class,"SL",dest,""))," ",1)
 . ; TODO hide this better.
 . S val=$$slug^%str($$getField^%obj(class,id,src))
 . S $P(@glvn@(id),$C(31),@dx@(dest))=val
 . Q
 Q
 ;
