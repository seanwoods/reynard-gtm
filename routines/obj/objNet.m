objNet ; Routines for exposing objects via ^objServer
 Q
 ;
set(msgID,seg,out) ;
 ; 0        Command
 ; 1        Classes                 {0, 1, 2, 3, .. n}
 ; 2..n     Data Records            2 + class#
 ;
 ; First line = descriptions
 ; Each additional line = data
 ; $P(line,$C(30),1) is the ID
 ; 
 N cl,class,data,id,maptable,rec,tempSeg,x
 S cl="" F  S cl=$O(^objServerMsg(msgID,seg+1,cl)) Q:cl=""  D
 . S class=^objServerMsg(msgID,seg+1,cl)
 . S rec="" F  S rec=$O(^objServerMsg(msgID,2+seg+cl,rec)) Q:rec=""  D
 . . S x=$TR(^objServerMsg(msgID,2+seg+cl,0),$C(31)," ")
 . . S x=$E(x,$F(x," "),$L(x)) ; Remove ID
 . . I rec=0 K maptable D evalSchema^%obj(class,x,.maptable) Q
 . . S data=^objServerMsg(msgID,2+seg+cl,rec)
 . . S id=$P(data,$C(31),1)
 . . S data=$E(data,$F(data,$C(31)),$L(data)) ; Remove ID
 . . I id="" S id=$$alloc^%obj(class)
 . . S data=$$xformVal^%obj(.maptable,data)
 . . D setPackedObject^%obj(class,id,.data)
 . . Q
 . Q
 ;
 Q
 ;
get(msgID,seg,out) ;
 N cl,class,id,rec
 S cl="" F  S cl=$O(^objServerMsg(msgID,seg+1,cl)) Q:cl=""  D
 . S class=^objServerMsg(msgID,seg+1,cl)
 . S out($I(out))="id"_$C(31)_$$getSchema^%obj(class)
 . S rec="" F  S rec=$O(^objServerMsg(msgID,2+seg+cl,rec)) Q:rec=""  D
 . . S id=^objServerMsg(msgID,2+seg+cl,rec)
 . . S out($I(out))=id_$C(31)_$$getRaw^%obj(class,id)
 . . Q
 . Q
 Q
 ;
del(msgID,seg,out) ;
 N cl,class,i,id,rec
 S cl="" F  S cl=$O(^objServerMsg(msgID,seg+1,cl)) Q:cl=""  D
 . S class=^objServerMsg(msgID,seg+1,cl)
 . S rec="" F  S rec=$O(^objServerMsg(msgID,2+seg+cl,rec)) Q:rec=""  D
 . . S id=^objServerMsg(msgID,2+seg+cl,rec)
 . . F i=1:1:$L(id,$C(31)) D del^%obj(class,$P(id,$C(31),i))
 . . Q
 . Q
 Q
 ;
list(msgID,seg,out) ;
 N cl,class,done,id,glvn,recNum,slice
 S out=0
 S cl="" F  S cl=$O(^objServerMsg(msgID,seg+1,cl)) Q:cl=""  D
 . S class=$P(^objServerMsg(msgID,seg+1,cl),$C(31),1)
 . ; Slice in the form of one integer (top x) or x:y
 . S slice=$P(^objServerMsg(msgID,seg+1,cl),$C(31),2)
 . ; TODO validate `slice`
 . S glvn=$$glvn^%obj(class,"o")
 . S:$O(^objServerMsg(msgID,seg+1,cl),-1)'="" out($I(out))=$C(29)
 . S out($I(out))=class_$C(31)_$G(^sMeta("num",$$norm^%obj(class)),-1)
 . S out($I(out))="id"_$C(31)_$$getSchema^%obj(class)
 . S done=0,recNum=0
 . S id="" F  S id=$O(@glvn@(id)) Q:done!(id="")  D
 . . S recNum=recNum+1
 . . I slice'="",$L(slice,":")=1,recNum>slice S done=1 Q
 . . I slice'="",$L(slice,":")=2,recNum<$P(slice,":",1) Q
 . . I slice'="",$L(slice,":")=2,recNum>$P(slice,":",2) S done=1 Q
 . . S out($I(out))=id_$C(31)_$$getRaw^%obj(class,id)
 . . Q
 . Q
 Q
 ;
enhancedSchema(msgID,seg,out) ;
 N cl,class,count,field,id,meta,rec,rs,schemaX,sort
 S cl="" F  S cl=$O(^objServerMsg(msgID,seg+1,cl)) Q:cl=""  D
 . S class=^objServerMsg(msgID,seg+1,cl)
 . S schemaX=$$glvn^%obj(class,"dx")
 . D do^zqSystemFields(.rs,.sort,.count,class)
 . S out($I(out))=class
 . S field="" F  S field=$O(@schemaX@(field)) Q:field=""  D
 . . S meta=$TR($G(rs(field)),$C(31),"^")
 . . S:meta="" meta="^"_field_"^^^"
 . . S out(out)=out(out)_$C(31)_@schemaX@(field)_"^"_meta
 . . Q
 . Q
 Q
 ;
listObjects(msgID,seg,out) ;
 ; TODO - replace with some kind of object registry
 N class,oname,onames
 S class="^o" F  S class=$O(@class) Q:$E(class,1,2)'="^o"  D
 . Q:'$$isUpper^%str($E(class,3))
 . ; TODO - this oname stuff is kinda bad
 . S oname=$$lc^%str($E(class,3))_$E(class,4,$L(class))_"^"
 . S oname=oname_$$uc^%str($E(class,3))_$E(class,4,$L(class))
 . S out($I(out))=oname
 . Q
 Q
 ;
view(msgID,seg,out) ;
 N argList,argNames,argValues,arg,args,c,code,i
 N len,recNum,rs,s,slice,sExternal,viewName
 S viewName=$P(^objServerMsg(msgID,seg+1,0),$C(31),1)
 S slice=$P(^objServerMsg(msgID,seg+1,0),$C(31),2)
 S argNames=^objServerMsg(msgID,seg+1,1)
 S argValues=^objServerMsg(msgID,seg+1,2)
 ;
 F i=1:1:$L(argNames," ") S args($P(argNames," ",i))=$P(argValues," ",i)
 ;
 D:$G(^sParam("UseTranslatedViews"),0)=1
 . S code="do^zq"_viewName
 . Q:$T(@code)=""
 . S argList=$$arglist^%rou($T(@code))
 . S code=code_"(.rs,.s,.c"
 . ;
 . F i=1:1:$L(argList,",") D
 . . S arg=$G(args($P(argList,",",i)))
 . . S:arg'="" code=code_","_arg
 . . Q
 . ;
 . S code=code_")"
 . ;
 . D @code
 . Q
 ;
 D:$G(^sParam("UseTranslatedViews"),0)=0
 . D execFromDB^objQuery(viewName,.rs,.s,.c,.args)
 . Q
 ;
 S out($I(out))=c
 S:$G(rs)'="" out($I(out))=rs
 S (done,recNum)=0
 S sExternal=$$sortToExternal^objQueryLib(.s),len=$L(sExternal,$C(31))
 I sExternal="" D  Q
 . S i="" F  S i=$O(rs(i)) Q:done!(i="")  D
 . . S recNum=recNum+1
 . . I slice'="",$L(slice,":")=1,recNum>slice S done=1 Q
 . . I slice'="",$L(slice,":")=2,recNum<$P(slice,":",1) Q
 . . I slice'="",$L(slice,":")=2,recNum>$P(slice,":",2) S done=1 Q
 . . S out($I(out))=rs(i)
 . . Q
 . Q
 ; Use sort order specified.
 F i=1:1:len Q:done  D
 . S recNum=recNum+1
 . I slice'="",$L(slice,":")=1,recNum>slice S done=1 Q
 . I slice'="",$L(slice,":")=2,recNum<$P(slice,":",1) Q
 . I slice'="",$L(slice,":")=2,recNum>$P(slice,":",2) S done=1 Q
 . S out($I(out))=rs($P(sExternal,$C(31),i))
 . Q
 Q
 ;
find(msgID,seg,out) ;
 N argNames,argValues,args,id,nok,objClass
 S objClass=^objServerMsg(msgID,seg+1,0)
 S argNames=^objServerMsg(msgID,seg+1,1)
 S argValues=^objServerMsg(msgID,seg+1,2)
 ;
 F i=1:1:$L(argNames," ") S args($P(argNames," ",i))=$P(argValues," ",i)
 ;
 S out($I(out))="id"_$C(31)_$$getSchema^%obj(objClass)
 ;
 S id="" F  S id=$$next^%obj(objClass,id) Q:id=""  D
 . S arg="",nok=0 F  S arg=$O(args(arg)) Q:arg=""  Q:nok  D
 . . I arg="id",id'=$$indirect^%var(args(arg)) S nok=1 Q
 . . Q:arg="id"
 . . S:$$getField^%obj(objClass,id,arg)'=$$indirect^%var(args(arg)) nok=1
 . . Q
 . S:'nok out($I(out))=id_$C(31)_$$getRaw^%obj(objClass,id)
 . Q
 ;
 Q
 ;
listViews(msgID,seg,out) ;
 N i,len,rs,s,sExternal
 D do^zqSystemViews(.rs,.s)
 Q:$D(rs)=0
 S sExternal=$$sortToExternal^objQueryLib(.s),len=$L(sExternal,$C(31))
 F i=1:1:len S out($I(out))=rs($P(sExternal,$C(31),i))
 Q
 ;
query(msgID,seg,out) ;
 ; Request:     name | class | fields | crit | sort | force-recompile
 ;              +1     +2      +3       +4     +5
 ; Response:    class-pattern | sort-order | data-cl1 | ... | data-cln
 N query,rs,sort
 ; TODO data validation for ALL of this
 ; Unique identifier for query (usually a mnemonic).
 S query("name")=^objServerMsg(msgID,seg+1,0)
 ;
 ; Class from which we're writing the query.
 S query("class")=^objServerMsg(msgID,seg+2,0)
 ; 
 ; Space-separated list of query fields.
 S query("fields")=^objServerMsg(msgID,seg+3,0)
 ; 
 ; Criteria string e.g. age > 18 AND age < 65 AND active = 1
 S query("crit")=^objServerMsg(msgID,seg+4,0)
 ; 
 ; Sort order e.g. age last_name
 S query("sort")=^objServerMsg(msgID,seg+5,0)
 ;
 S code=$$translate^objQuery(.query)
 S code="do^"_code_"(.out,.sort)"
 D @code
 ;
 S out("-99")=query("class")
 S out("-98")=$$sortToExternal^objQueryLib(.sort)
 ;
 Q
 ;
pointers(msgID,seg,out) ;
 N c,class,dx,extra,fld,hit,obj,objClass,objID,rs,s
 S class=^objServerMsg(msgID,seg+1,0)
 D do^zqSystemPointers(.rs,.s,.c,class)
 S rs="" F  S rs=$O(rs(rs)) Q:rs=""  D
 . ; format is id, short_name, extra
 . S extra=$P(rs(rs),$C(31),3)
 . Q:$G(hit(extra))
 . S hit(extra)=1
 . S obj=$P(extra," ",1)
 . S fld=$P(extra," ",2)
 . S out($I(out))=extra
 . S objClass=$$glvn^%obj(obj,"o"),dx=$$glvn^%obj(obj,"dx")
 . ;
 . S objID="" F  S objID=$O(@objClass@(objID)) Q:objID=""  D
 . . S out($I(out))=objID_$C(31)_$P(@objClass@(objID),$C(31),$G(@dx@(fld)))
 . . Q
 . Q
 . S:$O(rs(rs))'="" out($I(out))=$C(29)
 Q
 ;
