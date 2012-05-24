%str ; String Handling Library
 Q

ws(char) ; Determine whether a character is whitespace.
 N ws
 S ws=$C(9,10,13)_" "
 I $TR(char,ws,"")="" Q 1
 Q 0

trim(str) ; Remove whitespace from both ends of a string.
 N lpos,rpos,ws
 S ws=$C(9,10,13)_" "
 I $TR(str,ws,"")="" Q ""
 F lpos=1:1:$L(str) Q:ws'[$E(str,lpos)
 F rpos=$L(str):-1:1 Q:ws'[$E(str,rpos)
 Q $E(str,lpos,rpos)
 
uc(str) ; Convert a string to upper case.
 Q $$case(str,1)

lc(str) ; Convert a string to lower case.
 Q $$case(str,0)

case(str,dir) ; Convert a string to the case specified by `dir`.
 N lc,out,uc
 S lc="abcdefghijklmnopqrstuvwxyz",uc="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
 Q:dir $TR(str,lc,uc)
 Q $TR(str,uc,lc)

sw(str,needle) ; Search for `needle` within `str`.
 Q $E(str,1,$L(needle))=needle

printing(c) ; Determine if character is printing ASCII.
 Q:($A(c)<32)!($A(c)>126) 0
 Q 1

isDigit(c) ;
 Q c?.N

isNumeric(c) ;
 I c?.N Q 1
 I c="." Q 1
 Q 0

isAlpha(c) Q $$isUpper(c)!$$isLower(c)

isAlnum(c) Q $$isAlpha(c)!$$isNumeric(c)

isUpper(c) Q ($A(c)>64)&($A(c)<90)

isLower(c) Q ($A(c)>96)&($A(c)<123)

isSymbol(c) ;
 S c=$A(c)
 Q ((c>32)&(c<48))!((c>57)&(c<65))!((c>90)&(c<97))!((c>122)&(c<127))

isIdentifier(c) ;
 Q:$$isUpper(c) 1
 Q:$$isLower(c) 1
 Q:c?.N 1
 Q:c="_" 1
 Q 0

isValidIdentifier(str) ;
 Q:'$$isAlpha($E(str,1)) 0
 N i,ok
 S ok=1
 F i=1:1:$L(str) D
 . Q:'ok
 . I '$$isIdentifier($E(str,i)) S ok=0
 . Q
 Q ok

isValidNumber(num) ;
 I $E(num,1)="-" S num=$E(num,2,$L(num))
 Q $TR(num,".","")?.N

repr(in) ; Printable representation of string, suitable for evaluation.
 N c,mode,out
 S mode=0 ; 0 = init, 1 = printing ASCII, 2 = non-printing ASCII
 S out=""
 ;
 Q:in="" """"""
 Q:in?.N in  ; numbers don't require double quotes, escaping, etc.
 ;
 F c=1:1:$L(in) D
 . N a S a=$A($E(in,c))
 . ;
 . D:$$printing($E(in,c))=0  ; fires when non-printing character is encountered
 . . I mode=0 D  Q
 . . . S out=out_"$C("_a,mode=2
 . . . Q
 . . I mode=1 D  Q  ; transition from printing to non-printing
 . . . S out=out_"""_$C("_a,mode=2
 . . . Q
 . . I mode=2 D  Q
 . . . S out=out_","_a
 . . . Q
 . . Q
 . ;
 . D:$$printing($E(in,c))=1  ; fires when printing character is encountered
 . . N char
 . . ;
 . . S char=$E(in,c)
 . . I $E(in,c)="""" S char=""""""
 . . ;
 . . I mode=0 D  Q
 . . . S out=""""_char,mode=1
 . . . Q
 . . I mode=1 D  Q
 . . . S out=out_char
 . . . Q
 . . ;
 . . I mode=2 D  Q  ; transition from non-printing to printing
 . . . S out=out_")_"""_char,mode=1
 . . . Q
 . . Q
 . ;
 . Q
 ;
 S:mode=1 out=out_""""
 S:mode=2 out=out_")"
 ;
 Q out

encode(in,from) ; Backslash-escape string according to `from` parameters.
 ;; Escape all characters in both input string `in` and from-string `from`
 ;; with backslash-enclosed numeric representation of the character.  For
 ;; example, \32\ would represent the space character.
 new char,i,out
 set out=""
 ;
 for i=1:1:$length(in) do
 . set char=$extract(in,i)
 . if from[char set out=out_"\"_$ascii(char)_"\" quit
 . if char="\" set out=out_"\92\" quit
 . set out=out_char quit
 . quit
 ;
 quit out
 
decode(in,include) ; Remove backslash escaping from $$encode.
 new char,i,inescape,out,tempchar
 set inescape=0,out="",tempchar=""
 ;
 set include=include_"\"
 ;
 for i=1:1:$length(in) do
 . set char=$extract(in,i)
 . ;
 . if inescape do  quit
 . . if char="\" do  set tempchar="",inescape=0 quit
 . . . if include[$char(tempchar) set out=out_$char(tempchar) quit
 . . . set out=out_"\"_tempchar_"\" quit
 . . . quit
 . . set tempchar=tempchar_char
 . . quit
 . ;
 . if 'inescape do  quit
 . . if char="\" set inescape=1 quit
 . . set out=out_char
 . . quit
 . quit
 ;
 quit out

condense(str) ; Condense multiple spaces into single spaces.
 ; This function is quotation-aware and will not condense spaces within
 ; double-quote marks.
 N char,i,inquote,inws,out
 ;
 S inquote=0,inws=0,out=""
 ;
 F i=1:1:$L(str) D
 . S char=$E(str,i)
 . I $$ws(char),'inquote S inws=1 Q
 . I char="""" D  Q
 . . I inquote S inquote=0,out=out_"""" Q
 . . S:inws inws=0,out=out_" "
 . . S inquote=1,out=out_""""
 . . Q
 . S:inws inws=0,out=out_" "
 . S out=out_char
 . Q
 ;
 S:inws inws=0,out=out_" "
 ;
 Q out
 ;
qindex(str,delim) ; Index delimeters in quoted string.
 ; Used internally for $$qlen and $$qpiece functions.
 Q:str="" ""
 ;
 N i,inquote,out
 S inquote=0,out="0"
 S:$G(delim)="" delim=" " ; default is space character
 ;
 F i=1:1:$L(str) D
 . I (inquote=0)&($E(str,i)="""") S inquote=1 Q
 . I (inquote=1)&($E(str,i)="""") S inquote=0 Q
 . I (inquote=0)&($E(str,i)=delim) S out=out_" "_i
 . Q
 ;
 Q out_" "_($L(str)+1)
 ;
qlen(str,delim) ; Quotation-aware $Length.
 Q $L($$qindex(str,delim)," ")-1
 ;
qpiece(str,delim,offset) ; Quotation-aware $Piece.
 N idx
 S idx=$$qindex(str,delim)
 Q $E(str,$P(idx," ",offset)+1,$P(idx," ",offset+1)-1)
 ;
slug(str) ; Transform a string into a URL-friendly "slug"
 N c,i,slug
 S slug=""
 ;
 F i=1:1:$L(str) D
 . S c=$E(str,i)
 . I $$isUpper(c)!$$isLower(c) S slug=slug_$$lc(c)
 . I ($$ws(c))!(c="-")!(c=","),$E(slug,$L(slug))'="-" S slug=slug_"-"
 . Q
 ;
 Q slug
 ;
