sqlValidator ;
 Q
 ;
fail(reason);
 S $EC=",U999-"_reason_","
 Q
 ;
reset(self) ; Reset current pointer to nil.
 S self("cur")="",self("EndOfStream")=0
 Q
 ;
nextPart(self,cap) ; Return next part.
 N next
 S next=$O(self("parsed",self("cur")))
 s x=self("cur")
 S self("cur")=next
 I next="" S self("EndOfStream")=1 Q ""
 Q:$G(cap)'="" $$uc^%str(self("parsed",next))
 Q self("parsed",next)
 ;
peekPart(self,cap) ; Peek to next part but don't increment current pointer.
 N next
 S next=$O(self("parsed",self("cur")))
 I next="" Q ""
 Q:$G(cap)'="" $$uc^%str(self("parsed",next))
 Q self("parsed",next)
 ;
killPart(self) ; Discard current part and increment pointer.
 N next S next=$O(self("parsed",self("cur")))
 I next="" S self("EndOfStream")=1 Q ""
 Q
 ;
whereClause(self) ; Parse a WHERE clause.
 N names,phrase,s,tok,x
 S phrase="",s=""
 F  S tok=$$nextPart(.self) Q:tok=""  D
 . ; End of WHERE clause.
 . I $$uc^%str(tok)="ORDER",$$peekPart(.self,1)="BY" S x=$$nextPart(.self),s=1 Q
 . Q:s'=""
 . ; Add token to string for later processing.
 . S phrase=phrase_" "_tok
 . Q
 S phrase=$E(phrase,2,$L(phrase))
 ;
 ; Create MUMPS code to deal with the criteria.
 S self("mumps")=$$mkCritFromString^objQueryLib(phrase,.names)
 M self("names")=names
 ;
 Q $S(s=1:"ORDER",1:"")
 ;
parse(self) ; Entry point for parsing. 
 I $$uc^%str(self("parsed",1))="SELECT" D select(.self) Q
 I $$uc^%str(self("parsed",1))="INSERT" D insert(.self) Q
 I $$uc^%str(self("parsed",1))="UPDATE" D update(.self) Q
 I $$uc^%str(self("parsed",1))="DELETE" D delete(.self) Q
 S $EC=",U999-SQL statement not recognized.,"
 Q
 ;
select(self) ;
 N expectComma,state
 ;
 ; SELECT  FIELDREFS         TABLE          WHERE             ORDER
 ; SELECT  *            FROM coord   WHERE  x > 100  ORDER BY name, date ASC
 ;
 S expectComma=0,state="FIELDREFS"
 D reset(.self)
 F  S part=$$nextPart(.self) Q:self("EndOfStream")  D
 . I state="FIELDREFS" D  Q
 . . I part="FROM" S state="TABLE" Q
 . . I part="*" S state="TABLE" Q  ; TODO
 . . ;
 . . ; Expect an identifier
 . . I 'expectComma,$$isValidIdentifier^%str(part) S expectComma=1 Q
 . . ;
 . . ; Expect a comma or period.
 . . I expectComma,part="." S expectComma=0 Q  ; Within a reference.
 . . I expectComma,part="," S expectComma=0 Q  ; Between references.
 . . ;
 . . ; No other valid combination.
 . . D fail("Unexpected token: "_part)
 . . Q
 . I state="TABLE" D  Q
 . . I '$$isValidIdentifier^%str(part) D fail("Expected identifier here.")
 . . S state="WHERE"
 . . Q
 . I state="WHERE" D  Q
 . . ; Remove WHERE at the beginning of phrase.
 . . I $$peekPart(.self)="WHERE" D killPart(.self) Q
 . . ; Check for state change.
 . . I $$uc^%str(part)="ORDER",$$uc^%str($$peekPart(.self))="BY" D
 . . . N x S x=$$nextPart(.self) ; Discard "BY"
 . . . S state="ORDER"
 . . . Q
 . . ; In a WHERE clause.
 . . ; This is what's going to set the state transition, for example to an
 . . ; ORDER BY clause.
 . . S state=$$whereClause(.self)
 . . Q
 . I state="ORDER" D  Q
 . . ;
 . . ; e.g. ORDER BY name, date ASC
 . . ;
 . . N curId,expectComma,expectAscDesc,sort
 . . S expectComma=0,expectAscDesc=0
 . . ;
 . . N A,B,C
 . . S A="Expected identifier here."
 . . S B="Expected comma, ""ASC"", or ""DESC"" here."
 . . S C="Expected comma here."
 . . ;
 . . F  S part=$$nextPart(.self)  Q:self("EndOfStream")  D
 . . . ; Expecting a valid identifier.
 . . . I 'expectComma,'$$isValidIdentifier^%str(part) D fail(A)
 . . . ;
 . . . ; Expecting either a comma, "ASC", or "DESC".
 . . . I expectComma,expectAscDesc,part'="ASC",part'="DESC",part'="," D fail(B)
 . . . ;
 . . . ; Expecting a comma.
 . . . I expectComma,'expectAscDesc,part'="," D fail(C)
 . . . ;
 . . . ; Passed all validation, now do some work.
 . . . I 'expectComma S curId=part 
 . . . I expectComma S sort=$S(expectAscDesc:$S(part="DESC":"-",1:"+"),1:"+")
 . . . S self("order",$I(self("order")))=sort_curId
 . . . ; 
 . . . ; Now reset parser state appropriately.
 . . . ; 
 . . . I expectComma,expectAscDesc,part="," S expectComma=0,expectAscDesc=0 Q
 . . . I expectComma,expectAscDesc,part'="," S expectAscDesc=0 Q
 . . . I expectComma,'expectAscDesc S expectComma=0
 . . . I 'expectComma S expectComma=1
 . . . Q
 . . Q
 . Q
 Q
 ;
insert(self) ;
 N expectComma,parenlevel,part,state
 I self("parsed",2)'="INTO" D fail("Expected INTO here.")
 ;
 ; States:
 ;
 ; INSERT       TABLE      FIELDREFS            VALUES
 ; INSERT INTO  coord      (x, y)      VALUES   (14, 10)
 ;
 S expectComma=0,parenlevel=0,state="TABLE",self("cur")=2
 F  S part=$$nextPart(.self) Q:part=""  D
 . I state="TABLE" D  Q
 . . I '$$isValidIdentifier^%str(part) D fail("Expected identifier here.")
 . . S state="FIELDREFS"
 . . Q
 . I state="FIELDREFS" D  Q
 . . I part="(",parenlevel=0 S expectComma=0,parenlevel=1 Q
 . . I part=")",parenlevel=1,expectComma S parenlevel=0,state="VALUES" Q
 . . ;
 . . ; Expect an identifier.
 . . I 'expectComma,$$isValidIdentifier^%str(part) S expectComma=1 Q
 . . ;
 . . ; Expect a comma or a period.
 . . I expectComma,part="." S expectComma=0 Q  ; Within a reference
 . . I expectComma,part="," S expectComma=0 Q  ; Between references
 . . ; 
 . . ; No other valid combination
 . . D fail("Unexpected token: "_part)
 . . Q
 . I state="VALUES" D  Q
 . . Q:$$uc^%str(part)="VALUES"
 . . I part="(",parenlevel=0 S expectComma=0,parenlevel=1 Q
 . . I part=")",parenlevel=1,expectComma S parenlevel=0 Q
 . . ;
 . . ; Expect a string or number.
 . . I 'expectComma,$E(part,1)="""" S expectComma=1 Q
 . . I 'expectComma,$$isValidNumber^%str(part) S expectComma=1 Q
 . . ;
 . . ; Expect a comma.
 . . I expectComma,part="," S expectComma=0 Q
 . . ;
 . . ; No other valid combination.
 . . D fail("Unexpected token: "_part)
 . . Q
 . Q
 ;
 Q
 ;
update(self) ;
 ;
 ; UPDATE   TABLE         VALUES               WHERE
 ; UPDATE   coord   SET   x = 1, z = 5 WHERE   y > 2
 ;
delete(self) ;
 ;
isValidRef(ref) ; A reference e.g. user.location
 N i,o
 S o=1 ; If set to zero, will terminate loop and quit.
 F i=1:1:$L(ref) Q:o=0  D
 . S c=$E(ref,i)
 . ;
 . ; Must begin with an alpha.
 . I i=1,'$$isAlpha^%str(c) S o=0 Q
 . ;
 . ; Dot must be followed by an alpha.
 . I c=".",'$$isAlpha^%str($E(ref,i+1)) S o=0 Q
 . ; 
 . ; A reference can contain a dot.
 . Q:c="."
 . I '$$isAlnum^%str(c) S o=0 Q
 . Q
 Q o
 ;
test ;
 W $$isValidRef("user")=1,!
 W $$isValidRef("user.location")=1,!
 W $$isValidRef("user..location")=0,!
 W $$isValidRef("user$location")=0,!
 Q
 ;
