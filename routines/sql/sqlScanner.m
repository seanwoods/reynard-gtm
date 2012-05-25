sqlParse ;
 Q
 ;
transition(c) ;
 Q:$$isAlpha^%str(c) 2
 Q:c="_" 2
 Q:$$isNumeric^%str(c) 3
 Q:c="'" 5
 Q:c="""" 6
 Q:$$isSymbol^%str(c) 4
 Q:$$ws^%str(c) 7
 Q 1
 ;
flush ; IMPURE
 ; Expects `self` and `buf` to be defined.
 Q:buf=""
 S self("parsed",$I(self("parsed")))=buf
 S buf=""
 Q
 ;
feed(self,text) ;
 N buf,c,i,len
 S buf="",len=$L(text)
 I $G(self("state"))="" S self("state")=0
 F i=1:1:len D
 . S c=$E(text,i)
 . I self("state")=0 D  Q  ; Initial
 . . S self("state")=$$transition(c)
 . . I " 2 3 4 5 6 "[(" "_self("state")_" ") S buf=buf_c
 . . Q
 . ;
 . I self("state")=1 D  Q  ; Error
 . . S $EC=",U999-Parser Error,"
 . . Q
 . ;
 . I self("state")=2 D  Q  ; In Alnum Sequence
 . . I $$ws^%str(c) S self("state")=7 D flush Q
 . . I c="""" S self("state")=6 D flush S buf=buf_c Q
 . . I $TR(c,"()[]{}","")="" S self("state")=0 D flush S buf=buf_c D flush Q
 . . I $$isSymbol^%str(c),c'="_" S self("state")=4 D flush S buf=buf_c Q
 . . S buf=buf_c
 . . Q:$$isAlnum^%str(c)!(c="_")
 . . S self("state")=1
 . . Q
 . ;
 . I self("state")=3 D  Q  ; In Numeric Sequence
 . . I $$ws^%str(c) S self("state")=7 D flush Q
 . . I c="""" S self("state")=6 D flush S buf=buf_c Q
 . . I $TR(c,"()[]{}","")="" S self("state")=0 D flush S buf=buf_c D flush Q
 . . I $$isSymbol^%str(c),c'="_" S self("state")=4 D flush S buf=buf_c Q
 . . S buf=buf_c
 . . Q:$$isNumeric^%str(c)
 . . Q:c="."  ; decimal numbers
 . . S self("state")=1
 . . Q
 . ;
 . I self("state")=4 D  Q  ; In Symbol Sequence
 . . I $$ws^%str(c) S self("state")=7 D flush Q
 . . I $$isAlnum^%str(c) S self("state")=2 D flush S buf=buf_c Q
 . . I c="""" S self("state")=6 D flush S buf=buf_c Q
 . . I $TR(c,"()[]{}","")="" S self("state")=0 D flush S buf=buf_c D flush Q
 . . S buf=buf_c
 . . Q:$$isSymbol^%str(c)&(c'="_")
 . . S self("state")=1
 . . Q
 . ;
 . I self("state")=5 D  Q  ; In Single Quote
 . . S self("state")=1
 . . Q
 . ;
 . I self("state")=6 D  Q  ; In Double Quote
 . . I c="""",$E(text,i+1)="""" S buf=buf_"""""",i=i+1 Q
 . . I c="""" S self("state")=0 S buf=buf_c D flush Q
 . . S buf=buf_c
 . . Q
 . ;
 . I self("state")=7 D  Q  ; In Whitespace
 . . I c="""" S self("state")=6 D flush S buf=buf_c Q
 . . I $TR(c,"()[]{}","")="" S self("state")=0 D flush S buf=buf_c D flush Q
 . . I c="_" S self("state")=2
 . . I $$isSymbol^%str(c) S self("state")=4 D flush S buf=buf_c Q
 . . I $$isNumeric^%str(c) S self("state")=3 D flush S buf=buf_c Q
 . . Q:$$ws^%str(c)
 . . S self("state")=$$transition(c)
 . . I " 2 3 4 5 6 "[(" "_self("state")_" ") S buf=buf_c
 . . Q
 . ;
 . ; Fall through to error state if the current state can't be recognized.
 . S self("state")=1
 . ;
 . Q
 D flush
 Q
 ;
testSql(sql) ;
 N out,parser
 S parser("state")=0
 D feed(.parser,sql)
 W !,"---",!
 W "sql="_sql,!,!
 D query^%gs($NA(parser("parsed")))
 Q
 ;
test ;
 S $ZT="W ""Error!"",!,! ZWR  H"
 D testSql("SELECT name, date FROM transactions ORDER BY date ASC")
 D testSql("SELECT id, user.name, user.dob FROM transactions")
 D testSql("SELECT name, date FROM xact WHERE id > 102")
 D testSql("SELECT name, date FROM xact WHERE id >= 102")
 D testSql("SELECT"_$C(10)_"name, date"_$C(10)_"FROM xact"_$C(10)_"WHERE id >= 102")
 D testSql("SELECT name, date FROM xact WHERE id>=102")
 D testSql("select name, date FROM xact Where id>=102")
 D testSql("SELECT name, date FROM xact WHERE ""DAW"" IN name")
 D testSql("SELECT name, date FROM xact WHERE ""Horace """" P"" IN name")
 D testSql("INSERT INTO lakes (name, location) VALUES (""Watuppa Pond"",""Fall River"")")
 D testSql("UPDATE lakes SET location = ""Nowheresville"" WHERE id = 102")
 Q
 ;
test2 ;
 N tokens,sql
 S $ZT="W $EC,!,$ZSTATUS,! ZWR  zsh  H"
 ;S sql="INSERT INTO coord_plane (x, y) VALUES (1, 2), (20, 30) WHERE x = 110"
 S sql="SELECT * FROM names WHERE last_name ^ ""Mac"" ORDER BY id ASC"
 D feed(.tokens,sql)
 D parse^sqlParser(.tokens)
 ZWR tokens
 Q
 ;
