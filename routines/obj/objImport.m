objImport ;
 Q
 ;
csv(filename,targetClass,firstRow,delim,quoted,hook) ; Import a delimeted file.
 S:$G(firstRow)="" firstRow=1
 S:$G(delim)="" delim=","
 S:$G(quoted)="" quoted=1
 ;
 N i,io,len,line,lineNumber,schema
 ;
 S io=$Io O filename:READONLY U filename
 S lineNumber=0
 ;
 F  R line Q:$ZEOF  D
 . S lineNumber=lineNumber+1
 . S len=$L(line,delim)
 . ;u io w $p(line,$C(9),16),! u filename
 . I firstRow,lineNumber=1 D  Q
 . . F i=1:1:len S schema(i)=$P(line,delim,i)
 . . Q
 . ;
 . F i=1:1:len D
 . . I $G(hook)'="" D @hook
 . . S obj($G(schema(i),"?"_i))=$P(line,delim,i)
 . . Q
 . D set^%obj(targetClass,,.obj)
 . Q
 U io C filename
 Q
 ;
%testHook ;
 D:i=16  ; Do for column 16 only.
 . N j,len
 . S len=$L($P(line,delim,i),",")
 . F j=1:1:len D
 . . S xyy($$trim^%str($P($P(line,delim,i),",",j)))=1
 . . Q
 . S $P(line,delim,i)=""
 . Q
 ;
 D:i=13  ;
 . N j,len
 . S len=$L($P(line,delim,i),";")
 . F j=1:1:len S xyz($$trim^%str($P($P(line,delim,i),";",j)))=1
 . S $P(line,delim,i)=""
 . Q
 Q
 ;
%test ;
 D nuke^%obj("NDCProduct",1)
 D csv("/home/swoods/tmp/product.txt","NDCProduct",1,$C(9),0,"%testHook")
 Q
 ;
