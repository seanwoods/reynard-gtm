sqlParse ;
 Q
 ;
transition(c) ;
 Q:$$isAlpha^%str(c) 2
 Q:$$isNumeric^%str(c) 3
 Q:$$isSymbol^%str(c) 4
 Q:c="'" 5
 Q:c="""" 6
 Q 1
 ;
flush ; IMPURE
 ; Expects `out` and `buf` to be defined.
 S out($I(out))=buf
 S buf=""
 Q
 ;
feed(self,text) ;
 N buf,c,i,len
 S buf="",len=$L(text)
 F i=1:1:len D
 . S c=$E(text,i)
 . I self("state")=0 D  Q  ; Initial
 . . S self("state")=$$transition(c)
 . . I " 2 3 4 "[(" "_self("state")_" ") S buf=buf_c
 . . Q
 . ;
 . I self("state")=1 D  Q  ; Error
 . . S $EC=",U999-Parser Error,"
 . . Q
 . ;
 . I self("state")=2 D  Q  ; In Alnum Sequence
 . . I $$ws^%str(c) S self("state")=7 D flush Q
 . . I $$isSymbol^%str(c) S self("state")=4 D flush S buf=buf_c Q
 . . S buf=buf_c
 . . Q:$$isAlnum^%str(c)
 . . S self("state")=1
 . . Q
 . ;
 . I self("state")=3 D  Q  ; In Numeric Sequence
 . . I $$ws^%str(c) S self("state")=7 D flush Q
 . . S buf=buf_c
 . . Q:$$isNumeric^%str(c)
 . . Q:c="."  ; decimal numbers
 . . S self("state")=1
 . . Q
 . ;
 . I self("state")=4 D  Q  ; In Symbol Sequence
 . . I $$ws^%str(c) S self("state")=7 D flush Q
 . . S buf=buf_c
 . . Q:$$isSymbol^%str(c)
 . . S self("state")=1
 . . Q
 . ;
 . I self("state")=5 D  Q  ; In Single Quote
 . . S self("state")=1
 . . Q
 . ;
 . I self("state")=6 D  Q  ; In Double Quote
 . . S self("state")=1
 . . Q
 . ;
 . I self("state")=7 D  Q  ; In Whitespace
 . . Q:$$ws^%str(c)
 . . S self("state")=$$transition(c)
 . . I " 2 3 4 "[(" "_self("state")_" ") S buf=buf_c
 . . Q
 . ;
 . ; Fall through to error state if the current state can't be recognized.
 . S self("state")=1
 . ;
 . Q
 Q
 ;
test ;
 N parser,sql
 R sql
 S parser("state")=0
 D feed(.parser,sql)
 ZWR parser
 Q
 ;
