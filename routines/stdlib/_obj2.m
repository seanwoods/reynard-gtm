%obj2 ;
 ; Physical Structures
 ; -------------------
 ;  ^o    Object Data
 ;  ^m    Metadata
 ;  ^x    Indexes
 ; 
 ; Object Management Subroutines
 ; -----------------------------
 ;  get^obj(class,id)
 ;  alloc^obj(class)
 ;  set^obj(class,id,data)
 ;  del^obj(class,id)
 ;  
 ;  nameToOffset^obj(class,name)
 ;  offsetToName^obj(class,offset)
 ; 
 ;  getField^obj(class,id,field)
 ;  setField^obj(class,id,field,value)
 ;
 ; Indexing
 ; --------
 ; 
 ;  index^objIndex(class,id)
 ;  deindex^objIndex(class,id)
 ;  add^objIndex(class,field)
 ;  del^objIndex(class,field)
 ; 
 ;  audit^obj(class,data)
 ; 
 ; Object Query Lightweight Object
 ; -------------------------------
 ;  init^objQuery(self)
 ;  find^objQuery(self,crit)
 ;  next^objQuery(self)
 ; 
setup ;
 N id,obj
 S id=$O(^xSysClass("FieldUpper","SYSCLASS",""))
 I id="" S id=$I(^oSysClass)
 S ^xSysClass("FieldUpper","SYSCLASS",id)=1
 S obj("canonical_name")="SysClass"
 D set("SysClass",id,.obj)
 Q
 ;
canonical(class) ;
 ;
 I class="SysClass" D:($D(^oSysClass)=0)&($TL=0) setup Q "SysClass"
 ;
 N classID
 S classID=$O(^xSysClass("FieldUpper",$ZCONVERT(class,"U"),""))
 Q:classID'="" $$getField("SysClass",classID,"canonical_name")
 ;
 ; Add new class definition to system.
 ;
 N obj
 S obj("canonical_name")=$ZCONVERT($E(class,1),"U")_$E(class,2,$L(class))
 S classID=$$alloc("SysClass")
 D set("SysClass",classID,.obj)
 S ^xSysClass("FieldUpper",$ZCONVERT(class,"U"),classID)=1
 ;
 Q $$getField("SysClass",classID,"canonical_name")
 ;
alloc(class) ;
 N phys
 S phys="^o"_$$canonical(class)
 Q $I(@phys)
 ;
exists(class,id) ;
 N phys
 S phys="^o"_$$canonical(class)
 Q ''$D(@phys@(id))
 ;
escape(v)
 Q $$encode^%str(v,$C(31))
 ;
descape(v)
 Q $$decode^%str(v,$C(31))
 ;
classToID(class) ;
 Q $O(^xSysClass("FieldUpper",$ZCONVERT(class,"U"),""))
 ;
nameToOffset(class,name) ;
 N meta 
 S meta="^m"_$$canonical(class)
 Q $O(@meta@("name.offset",name,""))
 ;
offsetToName(class,name) ;
 N meta
 S meta="^m"_$$canonical(class)
 Q $O(@meta@("offset.name",offset,""))
 ;
fieldExists(class,field) ;
 Q ''$$nameToOffset(class,field)
 ;
allocField(class,field) ;
 N last,meta,obj
 S meta="^m"_$$canonical(class)
 S last=$O(@meta@("offset.name",""),-1)
 S @meta@("offset.name",last+1,field)=1
 S @meta@("name.offset",field,last+1)=1
 S obj("classID")=$$classToID(class)
 S obj("field")=field
 D set("SysField",,.obj)
 Q
 ;
set(class,id,value) ;
 ; `value` is passed by reference
 N field,phys,val
 S phys="^o"_$$canonical(class)
 ;
 I $G(@phys)="" D  ; Counter not initialized.
 . N initVal
 . TS
 . S initVal=+$O(@phys@(""),-1)
 . S @phys=$S(initVal>+$G(id):initVal,$G(id)="":initVal,1:id)
 . TC
 . Q
 ;
 S:$G(id)="" id=$$alloc(class)
 S field="" F  S field=$O(value(field)) Q:field=""  D
 . I '$$fieldExists(class,field) D allocField(class,field)
 . S $P(val,$C(31),$$nameToOffset(class,field))=$$escape(value(field))
 . Q
 D deindex^objIndex(class,id)
 S @phys@(id)=val
 D index^objIndex(class,id)
 Q
 ;
get(class,id,value) ;
 ; `value` is passed by reference
 N offset,phys,val
 S phys="^o"_$$canonical(class)
 S val=@phys@(id)
 F offset=1:1:$L(val,$C(31)) D
 . S value($$offsetToName(class,offset))=$$descape($P(val,$C(31),offset))
 . Q
 Q
 ;
getField(class,id,field) ;
 N offset,phys
 S offset=$$nameToOffset(class,field)
 S phys="^o"_$$canonical(class)
 Q $$descape($P($G(@phys@(id)),$C(31),offset))
 ;
setField(class,id,field,value) ;
 N offset,phys
 S offset=$$nameToOffset(class,field)
 S phys="^o"_$$canonical(class)
 D deindex^objIndex(class,id)
 S $P(@phys@(id),$C(31),offset)=$$escape(value)
 D index^objIndex(class,id)
 Q
 ;
test ;
 N o 
 S o("name")="Troy",o("breed")="golden",o("species")="canine"
 D add^objIndex("Animal","breed")
 D set^%obj2("Animal",1,.o)
 Q
 ;
nuke ;
 N classID,class,classList
 S classID="" F  S classID=$O(^oSysClass(classID)) Q:classID=""  D
 . S classList($$getField("SysClass",classID,"canonical_name"))=1
 . Q
 S classList("SysClass")=1
 S class="" F  S class=$O(classList(class)) Q:class=""  D
 . K @("^m"_class),@("^o"_class),@("^x"_class)
 . Q
 Q
 ;
