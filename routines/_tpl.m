tpl ; Template Transformation Library
 ;
 ; Templates are text files that are translated to M code.
 ; 
 ; Rules
 ; -----
 ;  * Execution begins at the top of the file.  Use '%mumps' directives
 ;    (see below) to insert subroutines, functions, etc.
 ;  * `New (vars)` is inserted before any commands to control local variables.
 ;  * Each non-M line is translated into an expression that outputs the
 ;    current line to the HTTP response.
 ;  * Insert variables with ${var} syntax.  These will be translated to
 ;    `$Get(var,"??")`, so if you see "??" in your output, you'll know why.
 ;  * If a line starts with '%', the line is treated as M code and copied
 ;    into the output at the proper indentation level.
 ;  * If a line begins with a '%' as above and ends with a do command, another
 ;    level of indentation gets triggered (leading dots).
 ;  * If a line begins with '%mumps', that line is translated into a blank
 ;    comment in the output and all subsequent lines up to an '%end' line
 ;    (see below) are copied verbatim to the translated result.
 ;  * If a line starts with '%end' and the generator is in "M Mode" from a
 ;    previous '%mumps', the '%mumps' action is undone and the generator goes
 ;    back to its default behavior.
 ;  * If a line starts with '%end' and the generator is NOT in "M Mode",
 ;    the indentation level is reduced and the generator inserts a quit
 ;    command to terminate the current syntactic block.
 ; 
 Q
 ;
escape(str) ; Return quoted version of string with internal quotes escaped.
 N loc
 S loc=1
 F  S loc=$F(str,"""",loc) Q:loc=0  S $E(str,loc-1)="""""",loc=loc+1
 Q """"_str_""""
 ;
wsSw(str,searchFor) ;
 N i,ws
 S ws=" "_$C(9,10,13)
 F i=1:1:$L(str) Q:ws'[$E(str,i)
 Q $E(str,i,i+$L(searchFor)-1)=searchFor
 ;
wsEw(str,searchFor) ;
 Q $$wsSw($RE(str),$RE(searchFor))
 ;
ltrim(str) ;
 N i,ws S ws=" "_$C(9,10,13)
 F i=1:1:$L(str) Q:ws'[$E(str,i)
 Q:i=$L(str) str
 Q $E(str,i,$L(str))
 ;
lev(level) ; Write out prefix characters corresponding to current DO level.
 N i,out
 S out=" "
 F i=1:1:level S out=out_". "
 Q out
 ;
log(message,to,from) ;
 U to
 W message,!
 U from
 Q
 ;
cmd ;
 D translate($P($ZCMDLINE," ",1))
 Q
 ;
translate(sourcePath) ;
 N destPath
 I $G(^sParam("tplc"))'="" D
 . S destPath=^sParam("tplc")_"/"_$$mkOutputName(sourcePath)_".m"
 . O destPath:NEWFILE U destPath
 . Q
 D translateToIo(sourcePath)
 C destPath
 Q
 ;
mkOutputName(sourcePath) ;
 N name
 S name=$ZParse(sourcePath,"NAME")
 S $E(name,1)=$ZCONVERT($E(name,1),"U")
 Q "tpl"_name
 ;
translateToIo(src) ;
 N io,line,level,mumpsMode,out
 S io=$Io,mumpsMode=0
 ;
 W $$mkOutputName(src),!
 W " N (%req,%resp,vars)",!
 ;
 O src U src
 F  R line Q:$ZEOF  D
 . S out=$$parseLine(line,.level,.mumpsMode)
 . D log(out,io,src)
 . Q
 U io C src
 W " Q",!
 W " ;"
 Q
 ;
parseLine(line,level,mumpsMode) ; Convert one line of template input.
 ; Arguments
 ; ---------
 ;  line          Input line to be converted.
 ;  .level        Current level of indentation.  Default = 0
 ;
 ; The following variables are needed when $Io '= $Principal (aka when
 ; NOT testing from the command line).
 ; ---------------------------------------------- 
 ;  io            Established output device.
 ;  filename      File device containing template.
 ;
 N debug,left,name,out,rest,right
 ;
 S debug=0,out=""
 S:($G(level)<0)!($G(level)="") level=0
 ;
 ; Use sensible defaults for the common scenario of command-line testing.
 I $P=$I N io,filename S (io,filename)=$P
 ;
 I line["${" D  Q $$lev(level)_out
 . F i=1:1:$L(line,"${") D
 . . S part=$P(line,"${",i)
 . . ;
 . . I i=1 S out=out_$$escape(part) Q  ; This will never have a variable.
 . . D:debug log("1: "_part_"~"_out,io,filename)
 . . ;
 . . ; Extract variable name.
 . . S left=1,right=$F(part,"}",left)-2
 . . S name=$$trim^%str($E(part,left,right))
 . . S rest=$E(part,right+2,$L(part))
 . . ;
 . . ; Global variable.
 . . I $E(name,1)="^" S out=out_"_$G("_name_",""??"")_"_$$escape(rest) Q
 . . ;
 . . ; Function call.
 . . I $E(name,1,2)="$$" S out=out_"_"_name_"_"_$$escape(rest) Q
 . . ;
 . . ; Fall back if variable name isn't valid.
 . . I name'?.A.N S out=out_$$escape(part) Q
 . . D:debug log("2: "_name_"~"_part_"~"_out,io,filename)
 . . ;
 . . S out=out_"_$G("_name_",""??"")"_"_"_$$escape(rest)
 . . D:debug log("3: "_name_"~"_rest_"~"_out,io,filename)
 . . Q
 . S out="D send^%web("_out_")"
 . Q
 ;
 I $$wsSw(line,"%end"),mumpsMode=1 S mumpsMode=0 Q $$lev(level)_";"
 I $$wsSw(line,"%end") S out=$$lev(level)_"Q",level=level-1  Q out
 ;
 I mumpsMode=1 Q line
 ;
 I $$wsSw(line,"%mumps") S mumpsMode=1 Q $$lev(level)_";"
 ;
 I $$wsSw(line,"%") D  Q out
 . S out=$$lev(level)_$$trim^%str($E(line,2,$L(line)))
 . I $$wsEw(line," D") S level=level+1 Q
 . I $$wsEw(line," DO") S level=level+1 Q
 . I $$wsEw(line," Do") S level=level+1 Q
 . I $$wsEw(line," do") S level=level+1 Q
 . Q
 ;
 S out=$$lev(level)_"D send^%web("_$$escape(line)_")"
 ;
 Q out
 ;
