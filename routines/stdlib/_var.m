%var ; Variable routines.
 Q
hasChildren(ref) ; Return true if variable reference has subnodes.
 Q $D(@ref)>9
 ;
hasValue(ref) ; Return true if variable reference has a value.
 Q $D(@ref)#2
 ;
sameRoot(vn1,vn2) ; Determine whether two variable names share a "root."
 Q:(vn1="")!(vn2="") vn1=vn2
 Q:$QL(vn1)'=$QL(vn2) 0
 ;
 N eq,i
 S eq=1
 ;
 F i=0:1:$QL(vn1)-1 Q:eq=0  S:$QS(vn1,i)'=$QS(vn2,i) eq=0
 Q eq
 ;
reprEncode(str) ; Generate string representation and encode special chars.
 Q $$repr^%str($$encode^%str(str,"|"_$C(4)))
 ;
vnEncode(vn) ; Encode variable name.
 N i,out
 S out=""
 ;
 F i=1:1:$QL(vn) S out=out_$$reprEncode($QS(vn,i))_"|"
 ;
 Q $E(out,1,$L(out)-1)
 ;
serialize(root) ; Convert a tree of variables to MNP message representation.
 ;; @root Name of root variable.
 ;
 N out,prev,ref,same
 S out="# ",prev=""
 I $$hasValue(root) S out=out_"!="_$$repr^%str(@root)_" "
 S ref=root F  S ref=$Q(@ref) Q:ref=""  D
 . S same=$$sameRoot(prev,ref)
 . S:same out=out_":"_$$reprEncode($QS(ref,$QL(ref)))
 . S:'same out=out_$$vnEncode(ref)
 . S out=out_"="_$$repr^%str(@ref)_" "
 . S prev=ref
 . Q
 Q out
 ;
deserialize(string,%zzout) ; Convert an MNP message to a tree of variables.
 ;; string      Variable containing MNP message.
 ;; @%zzout     Destination of output structure.
 N i,j,key,keys,piece,prev,temp,value
 F i=2:1:$$qlen^%str(string," ") D
 . S piece=$$qpiece^%str(string," ",i)
 . S keys=$$decode^%str($$qpiece^%str(piece,"=",1),"|"_$C(4))
 . S value=$$qpiece^%str(piece,"=",2)
 . ; Assign the current value to the "leaf" of this node.
 . I keys="!" S key=%zzout
 . ; Assemble full key from "continued" key.
 . D:$E(keys,1)=":"
 . . S:key="" $EC=",U101,"
 . . S key=$NA(@$$destack(key)@($$indirect($E(keys,2,$L(keys)))))
 . . Q
 . ; Assemble full key from output representation.
 . D:":!"'[$E(keys,1)
 . . F j=1:1:$$qlen^%str(keys,"|") D
 . . . S temp=$$qpiece^%str(keys,"|",j)
 . . . I j=1 S key=%zzout
 . . . S key=$NA(@key@($$indirect(temp)))
 . . . Q
 . . Q
 . S @key=$$indirect(value)
 . Q
 Q
indirect(expr) ; Evaluate argument using indirection.
 Q:expr="" ""
 Q @expr
 ;
destack(vn) ; Remove last subscript from variable name.
 ; TODO Error checking.
 I $QL(vn)=0 Q vn ; Nothing can be removed.
 ;
 N out,sub
 S out=""
 F sub=0:1:$QL(vn)-1 D
 . I sub=0 S out=$QS(vn,0) Q
 . I sub=1 D  Q
 . . S out=out_"("_$$repr^%str($QS(vn,1))
 . . I $QL(vn)-1=1 S out=out_")"
 . . Q
 . ;
 . S out=out_","_$$repr^%str($QS(vn,sub))
 . ;
 . I sub=$QL(vn)-1 S out=out_")"
 . ;
 . Q
 ;
 Q out
 ;
enlist(vn) ;
 N fsub,out,sub
 S out="[ "
 S sub="" F  S sub=$O(@vn@(sub)) Q:sub=""  D
 . S fsub=$NA(@vn@(sub))
 . ; Note: For now, assume leaf nodes are irrelevant.
 . S:($$hasValue(fsub)&'$$hasChildren(fsub)) out=out_$$repr^%str(@fsub)_" "
 . S:$$hasChildren(fsub) out=out_$$enlist(fsub)_" "
 . Q
 Q out_"]"
 ;
delist(string,%zzout) ; Parse a multi-dimensional structured string.
 N cur,i,tok
 ;
 S string=$$condense^%str(string)
 S cur=0
 F i=1:1:$$qlen^%str(string," ") D
 . S tok=$$qpiece^%str(string," ",i)
 . I tok="[" S cur=cur+1,%zzout=$NA(@%zzout@(cur)),cur=0 Q
 . I tok="]" S cur=$QS(%zzout,$QL(%zzout)),%zzout=$$destack(%zzout) Q
 . S cur=cur+1
 . S @%zzout@(cur)=$$indirect(tok)
 . Q
 Q
 ;
parse(input) ;
 N buf,c,len,s
 ; States:
 ;  0 = Init
 ;  1 = Err
 ;  2 = After 1st char in $QS(0)
 ;  3 = After 2nd char in $QS(0)
 ;  4 = Inside first paren, not inside expression
 ;  5 = Inside subscript string
 ;  6 = Inside subscript number
 ;  7 = xx After subscript, before comma
 ;  8 = xx Between subscripts (after first paren)
 ;  9 = After last paren

 S buf="",len=$L(input),s=0
 F i=1:1:len D
 . S c=$E(input,i)
 . ;
 . ; Initial: Char must be "%" or Alpha
 . ; 
 . I s=0 D  Q
 . . I c="^" Q
 . . I (c="%")!$$isAlpha^%str(c) S s=2,buf=buf_c Q
 . . S s=1 Q
 . . Q
 . ;
 . ; Error Handler
 . ;
 . I s=1 D  Q
 . . S $EC=",U1,"
 . . Q
 . I s=2 D  Q
 . . I c="(",buf="%" S s=1 Q                        ; Invalid GLVN
 . . I c="(" S s=4,buf=buf_"|" Q                    ; One-letter GLVN
 . . I $$isAlnum^%str(c) S s=3,buf=buf_c Q          ; Continue GLVN
 . . S s=1 Q                                        ; Catch-all
 . . Q
 . I s=3 D  Q
 . . I c="(" S s=4,buf=buf_"|" Q
 . . I $$isAlnum^%str(c) S buf=buf_c Q
 . . S s=1 Q
 . . Q
 . I s=4 D  Q  ; 
 . . I $$isNumeric^%str(c) S s=6,buf=buf_c Q
 . . I c="""" S s=5 Q
 . . I c=")" S s=9 Q
 . . S s=1 Q
 . . Q
 . I s=5 D  Q  ; Inside subscript string
 . . I c="""",$E(input,i+1)="""" S i=i+1,buf=buf_"""" Q
 . . I c="""" S s=7,buf=buf_"|" Q
 . . S buf=buf_c
 . . Q
 . I s=6 D  Q  ; Inside subscript number
 . . I c="," S s=4,buf=buf_"|" Q
 . . I $$isNumeric^%str(c) S buf=buf_c Q
 . . I c=")" S s=9 Q
 . . S s=1 Q
 . . Q
 . I s=7 D  Q  ; After string, before comma
 . . I c="," S s=4 Q
 . . S s=1 Q
 . . Q
 . I s=8 D  Q
 . . Q
 . I s=9 D  Q
 . . Q
 . Q
 ;
 Q:$E(buf,$L(buf))="|" $E(buf,1,$L(buf)-1)
 ;
 Q buf
 ;
