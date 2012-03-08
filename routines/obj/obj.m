obj ; Object Management Routines
 Q
 ;
glvn(class,prefix) ; Convert class name to global variable name.
 Q "^"_prefix_$ZCONVERT($E(class,1),"U")_$E(class,2,$L(class))
 ;
alloc(class) ; Allocate new object node.
 Q $I(@$$glvn(class,"o"))
 ;
set(class,id,data) ; Set an object.
 N field,glvn,newFieldNumber,schema,temp
 S glvn=$$glvn(class,"o"),schema=$$glvn(class,"d"),schemaX=$$glvn(class,"dx")
 M temp=data
 ;
 ; Populate object data structures.
 ;
 S offset="" F  S offset=$O(@schema@(offset)) Q:offset=""  D
 . S $P(@glvn@(id),$C(30),offset)=temp(@schema@(offset))
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
 . S $P(@glvn@(id),$C(30),newFieldNumber)=temp(field)
 . Q
 ;
 Q
 ;
setExactObject(class,id,src) ; Set an object whose offsets correspond to schema
 ; src      Array of offset -> value
 N glvn,offset
 S glvn=$$glvn(class,"o")
 ;
 S offset="" F  S offset=$O(src(offset)) Q:offset=""  D
 . S $P(@glvn@(id),$C(30),offset)=src(offset)
 . Q
 ;
 Q
 ;
setPackedObject(class,id,packedString) ; Set an object from an object's string.
 N glvn
 S glvn=$$glvn(class,"o")
 S @glvn@(id)=packedString
 Q
 ;
setSchema(class,src) ; Set the schema if we're sure of what it is.
 N sch,schema,schemaX
 S schema=$$glvn(class,"d"),schemaX=$$glvn(class,"dx")
 M @schema=src
 S sch="" F  S sch=$O(@schema@(sch)) Q:sch=""  S @schemaX@(@schema@(sch))=sch
 Q
 ;
get(class,id,data) ; Copy an object into `data` array.
 N field,glvn,offset,schema
 S glvn=$$glvn(class,"o"),schema=$$glvn(class,"d")
 ;
 F offset=1:1:$L(@glvn@(id),$C(30)) D
 . S data(@schema@(offset))=$P(@glvn@(id),$C(30),offset)
 . Q
 ;
 Q
 ;
getField(class,id,field) ; Get an object field's value.
 S glvn=$$glvn(class,"o"),schema=$$glvn(class,"d"),schemaX=$$glvn(class,"dx")
 ;
 Q $P(@glvn@(id),$C(30),@schemaX@(field))
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
 D get("Address",1,.b)
 ZWR b
 W $$getSchema("address"),!
 ;
 Q
 ;
