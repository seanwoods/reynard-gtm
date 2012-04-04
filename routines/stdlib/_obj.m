obj ; Object Management Routines
 Q
 ;
norm(class) ; Normalize class name
 Q $ZCONVERT($E(class,1),"U")_$E(class,2,$L(class))
 ;
glvn(class,prefix) ; Convert class name to global variable name.
 Q "^"_prefix_$$norm(class)
 ;
alloc(class) ; Allocate new object node.
 N id,glvn,meta
 S class=$$norm(class),glvn=$$glvn(class,"o")
 S id=$I(@glvn)
 ; Make sure we have the latest number.
 F  Q:($O(@glvn@(id))="")&($D(@glvn@(id))=0)  S id=$I(@glvn)
 S ^sMeta("num",class)=$G(^sMeta("num",class))+1
 Q id
 ;
set(class,id,data,setOnly) ; Set an object.
 N field,glvn,newFieldNumber,schema,temp
 S:$G(id)="" id=$$alloc(class)
 S glvn=$$glvn(class,"o"),schema=$$glvn(class,"d"),schemaX=$$glvn(class,"dx")
 M temp=data
 D:'$G(setOnly) deindex(class,id)
 ;
 ; Populate object data structures.
 ;
 S offset="" F  S offset=$O(@schema@(offset)) Q:offset=""  D
 . S $P(@glvn@(id),$C(31),offset)=$G(temp(@schema@(offset)))
 . K temp(@schema@(offset))
 . Q
 ;
 ; Look for unrecognized fields and update schema.
 ;   TODO - Add parameter to turn this off.
 ;
 S field="" F  S field=$O(temp(field)) Q:field=""  D
 . S newFieldNumber=$I(@schema)
 . S @schema@(newFieldNumber)=field
 . S @schemaX@(field)=newFieldNumber
 . S $P(@glvn@(id),$C(31),newFieldNumber)=temp(field)
 . Q
 ;
 D:'$G(setOnly) index(class,id)
 D:'$G(setOnly) fileEvents(class,id)
 ;
 Q
 ;
setExactObject(class,id,src) ; Set an object whose offsets correspond to schema
 ; src      Array of offset -> value
 N glvn,offset
 S glvn=$$glvn(class,"o")
 ;
 D deindex(class,id)
 ;
 S offset="" F  S offset=$O(src(offset)) Q:offset=""  D
 . S $P(@glvn@(id),$C(31),offset)=src(offset)
 . Q
 ;
 D index(class,id)
 D fileEvents(class,id)
 ;
 Q
 ;
setPackedObject(class,id,packedString) ; Set an object from an object's string.
 N glvn
 S glvn=$$glvn(class,"o")
 D deindex(class,id)
 S @glvn@(id)=packedString
 D index(class,id)
 D fileEvents(class,id)
 Q
 ;
setSchema(class,src) ; Set the schema if we're sure of what it is.
 N sch,schema,schemaX
 S schema=$$glvn(class,"d"),schemaX=$$glvn(class,"dx")
 M @schema=src
 S sch="" F  S sch=$O(@schema@(sch)) Q:sch=""  S @schemaX@(@schema@(sch))=sch
 Q
 ;
evalSchema(class,schemaSrc,maptable) ; \
 ; Evaluate schema string against existing schema, creating new files if needed.
 N field,inSchema,len,notInSchema,offset,schema,schemaX
 ;
 S (inSchema,notInSchema)=0
 S schema=$$glvn(class,"d"),schemaX=$$glvn(class,"dx")
 ;
 S len=$L(schemaSrc," ") F offset=1:1:len D
 . S field=$P(schemaSrc," ",offset)
 . I $G(@schemaX@(field))="" S notInSchema(offset)=field Q
 . S inSchema(offset)=field,maptable(offset)=@schemaX@(field)
 . Q
 ;
 ; Loop through all fields that we didn't recognize.
 ;
 S offset="" F  S offset=$O(notInSchema(offset)) Q:offset=""  D
 . S @schema@($I(@schema))=notInSchema(offset)
 . S maptable(offset)=@schema
 . S @schemaX@(notInSchema(offset))=@schema
 . Q
 ;
 Q
 ;
xformVal(maptable,srcData) ; Transform packed value according to maptable.
 N destData,src
 S src="" F  S src=$O(maptable(src)) Q:src=""  D
 . S $P(destData,$C(31),maptable(src))=$P(srcData,$C(31),src)
 . Q
 Q destData
 ;
indexName(class,id) ; Populate indexes for an object.
 ; Indexes are ^sIndex(class,"fields.to.index")="target"
 N done,i,idxStruct,val
 S idxStruct=$NA(@$$glvn(class,"x")@(idxName))
 S done=0 F i=1:1:$L(fields,".") Q:done  D
 . S val=$$getField(class,id,$P(fields,".",i))
 . I val="" S done=1 Q
 . S idxStruct=$NA(@idxStruct@(val))
 . Q
 Q:done ""
 Q $NA(@idxStruct@(id))
 ;
index(class,id) ; Create index for object.
 N fields,idx,idxName
 S class=$$norm(class)
 S idxName="" F  S idxName=$O(^sIndex(class,idxName)) Q:idxName=""  D
 . S fields="" F  S fields=$O(^sIndex(class,idxName,fields)) Q:fields=""  D
 . . S idx=$$indexName(class,id)
 . . S:idx'="" @idx=1
 . . Q
 . Q
 Q
 ;
deindex(class,id) ; Remove indexes for object.
 N fields,idx
 S class=$$norm(class)
 S idxName="" F  S idxName=$O(^sIndex(class,idxName)) Q:idxName=""  D
 . S fields="" F  S fields=$O(^sIndex(class,idxName,fields)) Q:fields=""  D
 . . S idx=$$indexName(class,id)
 . . K:idx'="" @idx
 . . Q
 . Q
 Q
 ;
rebuildIndexes(class) ; Rebuild an object's indexes.
 N glvn,id,idxStruct
 S glvn=$$glvn(class,"o"),idxStruct=$$glvn(class,"x")
 K @idxStruct
 S id="" F  S id=$O(@glvn@(id)) Q:id=""  D
 . D index(class,id)
 . Q
 Q
 ;
fileEvents(class,id) ; Application-level events.
 N code,i
 F i="*",class D
 . S code="" F  S code=$O(^sHooks("OnFile",i,code)) Q:code=""  D
 . . Q:$T(@code)=""
 . . S code=code_"(class,id)"
 . . D @code
 . . Q
 . Q 
 Q
 ;
get(class,id,data) ; Copy an object into `data` array.
 N field,glvn,offset,schema
 S glvn=$$glvn(class,"o"),schema=$$glvn(class,"d")
 ;
 F offset=1:1:$L(@glvn@(id),$C(31)) D
 . S data(@schema@(offset))=$P(@glvn@(id),$C(31),offset)
 . Q
 ;
 Q
 ;
getField(class,id,field) ; Get an object field's value.
 S glvn=$$glvn(class,"o"),schema=$$glvn(class,"d"),schemaX=$$glvn(class,"dx")
 ;
 Q:$G(@glvn@(id))="" ""
 Q $P(@glvn@(id),$C(31),@schemaX@(field))
 ;
getRaw(class,id) ; Get the object's raw representation.
 S glvn=$$glvn(class,"o")
 Q @glvn@(id)
 ;
getSchema(class) ; Get a class's schema.
 N offset,out,schema
 S schema=$$glvn(class,"d")
 S offset="" F  S offset=$O(@schema@(offset)) Q:offset=""  D
 . S $P(out,$C(31),offset)=@schema@(offset)
 . Q
 Q out
 ;
getEnhSchema(class) ; Get id, caption, and type for class fields.
 N schema,f,i,x
 S schema=$$getSchema(class)
 F i=1:1:$L(schema,$C(31)) D
 . S f=$P(schema,$C(31),i)
 . S x=f_"^"_$$caption(class,f)_"^"_$$type(class,f)_"^"_$$extra(class,f)
 . S $P(schema,$C(31),i)=x
 . Q
 Q schema
 ;
caption(class,field) ;
 Q $$uc^%str($E(field,1))_$E(field,2,$L(field))
 ;
type(class,field) ;
 Q:field="id" "id"
 Q "text"
 ;
extra(class,field) ;
 Q ""
 ;
del(class,id) ;
 S glvn=$$glvn(class,"o")
 K @glvn@(id)
 Q:$G(^sMeta("num",class))=""
 Q:$G(^sMeta("num",class))=0
 S ^sMeta("num",class)=$G(^sMeta("num",class))-1
 Q
 ;
list(list) ;
 ; pass `list` by reference
 ; TODO - replace with some kind of object registry
 N class
 S class="^o" F  S class=$O(@class) Q:$E(class,1,2)'="^o"  D
 . Q:'$$isUpper^%str($E(class,3))
 . S list($$lc^%str($E(class,3))_$E(class,4,$L(class)))=1
 . Q
 Q
 ;
next(class,id) ;
 Q $O(@$$glvn(class,"o")@(id))
 ;
recount(class) ;
 N count,id
 S count=0,class=$$norm(class)
 S id="" F  S id=$$next(class,id) Q:id=""  S count=count+1
 S ^sMeta("num",class)=count
 Q
 ;
nuke(class,noconfirm) ; Wipe out all data for a class.
 N glvn,i,sure
 S sure=1
 D:$G(noconfirm)'=1
 . W !,"WARNING: You're about to completely obliterate all data related to"
 . W !,"         class `"_class_"`!!"
 . W !
 . R !,"Are you SURE you want to continue?  If so, type ""yes"": ",sure
 . I $ZCONVERT(sure,"U")'="YES" S sure=0 Q
 . S sure=1
 . Q
 ;
 Q:'sure
 ;
 F i="d","dx","o" S glvn=$$glvn(class,i) K @glvn
 Q
 ;
bench(class,cycles) ; Run during mass import to get average new objects/second.
 N avg,glvn,new,i,old,stats
 S glvn=$$glvn(class,"o")
 S old=$O(@glvn@(""),-1) F i=1:1:cycles D
 . H 1
 . S new=$O(@glvn@(""),-1)
 . S stats(i)=new-old
 . S old=new
 . W stats(i),!
 . Q
 W "------------",!
 S avg=0
 S stats="" F  S stats=$O(stats(stats)) Q:stats=""  S avg=avg+stats(stats)
 W "Average: "_(avg\$O(stats(""),-1)),!
 Q
 ;
%test ;
 N a
 k ^dAddress,^oAddress,^dxAddress
 ;
 ;S ^dAddress=5
 ;S ^dAddress(1)="address1"
 ;S ^dAddress(2)="address2"
 ;S ^dAddress(3)="city"
 ;S ^dAddress(4)="state"
 ;S ^dAddress(5)="zip"
 ;
 ;S ^dxAddress("address1")=1
 ;S ^dxAddress("address2")=2
 ;S ^dxAddress("city")=3
 ;S ^dxAddress("state")=4
 ;S ^dxAddress("zip")=5
 ;
 S a("address1")="123 Fake Street"
 S a("address2")="Apt. 2B"
 S a("city")="West Mohegan"
 S a("state")="MA"
 S a("zip")=01209
 S a("country")="US"
 S a("timezone")="EST"
 ;
 D set("Address",1,.a)
 ;
 ;D get("Address",1,.b)
 ;
 S x="address1 city zip state country timezone dog cat"
 D evalSchema("Address",.x,.zz)
 S y="101 Fake St"_$C(31)_"Anytown"_$C(31)_"02991"_$C(31)_"MA"
 S y=y_$C(31)_"USA"_$C(31)_"EST"_$C(31)_"Y"_$C(31)_"N"
 W $L(y,$C(31)),!,!
 W x,!,!
 ZWR zz
 W !
 W $$repr^%str($$xformVal(.zz,.y)),!,!
 ;
 Q
 ;
