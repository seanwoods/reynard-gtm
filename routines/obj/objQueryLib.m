objQuery ; Object query routines
 Q
 ;
sortToExternal(sort) ;
 N i,out,s
 S out=""
 S s="sort" F  S s=$Q(@s) Q:s=""  D
 . S out=out_$QS(s,$QL(s))
 . S:$Q(@s)'="" out=out_$C(31)
 . Q
 Q out
 ;
opbuild(op1,op2) ;
 ; $E(,1)="`" Switch operands
 ; $E(,1)="$" Call function
 S op1("=")="="
 S op1("eq")="="
 S op1("!=")="'="
 S op1("neq")="'="
 S op1("<>")="'="
 S op1(">")=">"
 S op1("gt")=">"
 S op1("<")="<"
 S op1("lt")="<"
 S op1(">=")="'<"
 S op1("gte")="'<"
 S op1("<=")="'>"
 S op1("lte")="'>"
 S op1("^")="$$sw^%str"
 S op1("sw")="$$sw^%str"
 S op1("$")="$$ew^%str"
 S op1("ew")="$$ew^%str"
 S op1("in")="`["
 S op1("nin")="`'["
 S op1("inl")="$$inList^%op"
 S op1("ninl")="$$notInList^%op"
 ;
 S op2("AND")="&"
 S op2("OR")="!"
 ;
 Q
 ;
inArray(sub,var) ;
 Q $G(var(sub))'=""
 ;
isIdent(str) ; TODO make more robust
 Q:$E(str,1)="$" 0
 Q:$E(str,1)=$C(34) 0
 Q:str?.N 0
 Q 1
 ;
cvtId(str) ; Convert identifier to canonical representation.
 Q $TR(str,"_","")
 ;
mkLoop(ivar,class) ; Make a "standard" loop around a variable.
 N glvn,out
 S glvn=$$glvn^%obj(class,"o")
 S out=" S "_ivar_"="_$C(34,34)_" F  S "_ivar_"=$O("_glvn_"("_ivar_")) "
 S out=out_"Q:"_ivar_"="_$C(34,34)_"  D"
 Q out
 ;
convertOp(l,op,r,op1,op2) ;
 S op=$G(op1(op))
 S:op="" op=$G(op2(op))
 S:op="" $EC=",U96-Invalid operator"
 I $E(l,1)="$" S l=$E(l,2,$L(l))
 I $E(r,1)="$" S r=$E(r,2,$L(r))
 S l=$$cvtId(l),r=$$cvtId(r)
 Q:$E(op,1)="`" r_$E(op,2,$L(op))_l
 Q:$E(op,1)="$" op_"("_l_","_r_")"
 Q l_op_r
 ;
critFlushBuf(buf) ;
 N i,left,len,op,out,part,state
 S buf=$$trim^%str(.buf),len=$$qlen^%str(buf," "),state="t1"
 S out=""
 F i=1:1:len S part=$$qpiece^%str(buf," ",i) D
 . I state="t1" S left=part S state="op1" Q
 . I state="op1" S op=part S state="t2" Q
 . I state="t2" D  Q
 . . S out=out_"("_$$convertOp(left,op,part,.op1,.op2)_")"
 . . S state="op2"
 . . Q
 . I state="op2" S out=out_op2(part) S state="t1" Q
 . Q
 S buf=""
 Q:$Q=1 out
 ;
 W out
 Q
 ;
mkCrit(query,names) ;
 Q:$G(query("crit"))="" ""
 ;
 N buf,crit,expect,len,op1,op2,out,part
 S buf=""
 S crit=$$condense^%str(query("crit")),len=$$qlen^%str(crit," "),expect="t1"
 D opbuild(.op1,.op2)
 ; expect = {"t","op1","op2"}
 ;
 F i=1:1:len S part=$$qpiece^%str(crit," ",i) D
 . I expect["t",$$inArray(.part,.op1) S $EC=",U99-Term Expected," Q
 . I expect["t",$$inArray(.part,.op2) S $EC=",U99-Term Expected," Q
 . I expect="op1",'$$inArray(.part,.op1) S $EC=",U98-Op1 Expected," Q
 . I expect="op2",'$$inArray(.part,.op2) S $EC=",U97-Op2 Expected," Q
 . I " t1 t2 "[(" "_expect_" "),$$isIdent(part) S names("C",part)=1
 . I expect="t1"  D  Q
 . . I $E(part,1)="$" S part=$E(part,2,$L(part)),names("V",part)=1
 . . S buf=buf_" "_part,expect="op1"
 . . Q
 . I expect="t2" D  Q
 . . I $E(part,1)="$" S part=$E(part,2,$L(part)),names("V",part)=1
 . . S buf=buf_" "_part,expect="op2"
 . . Q
 . S buf=buf_" "_part
 . S expect=$S(expect="op1":"t2",1:"t1")
 . Q
 ;
 S:buf'="" out=$$critFlushBuf(.buf)
 ;
 Q out
 ;
analyzeFields(fields,names) ;
 N i
 F i=1:1:$L(fields," ") S names("F",$P(fields," ",i))=1
 Q
 ;
analyzeSorts(sorts,names) ;
 Q:sorts=""
 D analyzeFields(sorts,.names)
 Q
 ;
fref(schemaX,fname) ;
 Q "$G("_schemaX_"("_$C(34)_fname_$C(34)_"),0)"
 ;
fpref(glvn,fref) ;
 Q "$P("_glvn_"(%i1),$C(31),"_fref_")" 
 ;
routineNm(name) ;
 Q:name="" ""
 Q "zq"_name
 ;
gen(query) ;
 N codeCrit,dir,file,glvn,i,io,len,lev,name,names,routineNm,schemaX,sortNum,var
 Q:$G(query("name"))="" ""
 S dir=$G(^sParam("QueryDir"),"")
 S:dir="" $EC=",U95-Query directory not specified.,"
 ; TODO - check if directory is writable
 ; TODO - check if in $ZROU
 ;
 S lev=0
 ;
 S glvn=$$glvn^%obj(query("class"),"o"),schemaX=$$glvn^%obj(query("class"),"dx")
 ;
 S routineNm=$$routineNm(query("name"))
 S file=dir_"/"_routineNm_".m"
 S io=$Io O file:NEWVERSION U file
 ; Analyze various names we need so that we can cache fields.
 D analyzeFields(query("fields"),.names)
 S codeCrit=$$mkCrit(.query,.names)
 D analyzeSorts($G(query("sort")),.names)
 ;
 W routineNm_" ; "_$H,!
 ;
 W " Q",!
 W " ;",!
 ; Generate function signature.
 W "do(%rs,%sort,%count"
 S var="" F  S var=$O(names("V",var)) Q:var=""  D
 . W ","_$$cvtId(var)
 . Q
 W ") ; ",!
 ;
 W " N %i1,%ok",!
 D:$D(names)
 . N hit
 . S hit=0
 . W " N " ; NEW command
 . ; Don't loop over "V" because that's handled by the formal list.
 . F i="C","F" S var="" F  S var=$O(names(i,var)) Q:var=""  D
 . . I $G(hit(var))="" W:hit "," W $$cvtId(var)
 . . S hit=1,hit(var)=1
 . . Q
 . W !
 . Q
 ;
 W " S %count=0",!
 ;
 D:$G(query("emitFields"))
 . W " S rs=""id""",!
 . F i=1:1:$L(query("fields")," ") D
 . . W " S rs=rs_$C(31)_"_$$repr^%str($P(query("fields")," ",i)),!
 . . Q
 . Q
 ;
 ; Write the outer loop.
 ;
 W $$mkLoop($NA(%i1),query("class")),! S lev=lev+1
 ;
 ; Retrieve values we will need in criteria section.
 ;
 S name="" F  S name=$O(names("C",name)) Q:name=""  D
 . Q:$E(name,1)="$"
 . W " . S "_$$cvtId(name)_"="_$$fpref(glvn,$$fref(schemaX,name)),!
 . Q
 ;
 ; Write the criteria code.  If this returns a false value at runtime, we'll
 ; quit out of the do-level.  This is why the names are divided between
 ; criteria, fields, and sorts (to avoid unnecessary copying).
 ;
 D:codeCrit'=""
 . W " . S %ok="_codeCrit,!
 . W " . Q:'%ok",!
 . Q
 ;
 ; Retrieve values we will need in fields section.
 ;
 S name="" F  S name=$O(names("F",name)) Q:name=""  D
 . Q:$G(names("C",name))
 . W " . S "_$$cvtId(name)_"="_$$fpref(glvn,$$fref(schemaX,name)),!
 . Q
 ;
 ; Set result set variable, %rs, with data to extract.
 ;
 W " . S %count=%count+1",!  ; This is the "record count."
 S var=$S($G(query("indexBy"))'="":$$cvtId(query("indexBy")),1:"%i1")
 W " . S %rs("_var_")=%i1",!
 F i=1:1:$L(query("fields")," ") D
 . ;
 . ; Selection
 . ;
 . W " . S %rs("_var_")=%rs("_var_")_$C(31)_"
 . W $$cvtId($P(query("fields")," ",i)),!
 . Q
 ;
 ; Retrieve values we will need in sort section.
 ;
 S name="" F  S name=$O(names("S",name)) Q:name=""  D
 . Q:$G(names("C",name))
 . Q:$G(names("F",name))
 . W " . S "_$$cvtId(name)_"="_$$fpref(glvn,$$fref(schemaX,name)),!
 . Q
 ;
 ; Sort
 ;
 D:$G(query("sort"))'=""
 . W " . S %sort("
 . S len=$L(query("sort")," ")
 . F sortNum=1:1:len W $$cvtId($P(query("sort")," ",sortNum))_","
 . W "%i1)=1",!
 . Q
 ; 
 W " . Q",!
 W " Q",!
 W " ;",!
 U io C file
 Q routineNm
 ;
