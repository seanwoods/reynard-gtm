%tpl ;
 Q
 ;
findNonWs(line,dir) ;
 S:$G(dir)="" dir=1
 S:$G(dir)=0 dir=1
 N i,pos
 S pos=0
 I dir>0 F i=1:1:$L(line) Q:pos>0  I '$$ws^%str($E(line,i)) S pos=i Q
 I dir<0 F i=$L(line):-1:1 Q:pos>0  I '$$ws^%str($E(line,i)) S pos=i Q
 Q pos
 ;
lev(lev) ;
 N i,out
 S out=" "
 F i=1:1:lev S out=out_". "
 Q out
 ;
translate(inFile,outDir) ; Translate a template.
 N outFile
 S:$E(outDir,$L(outDir))'="/" outDir=outDir_"/"
 S outFile=outDir_$ZPARSE(inFile,"NAME")_".m"
 O outFile:NEWVERSION U outFile
 D processFile(inFile)
 C outFile
 ZL $ZPARSE(inFile,"NAME")
 Q
 ;
translateAll ;
 N file,pattern
 S pattern=$ZTRNLNM("mumps_root")_"/etc/templates/*"
 S:$G(^sParam("tplc"))="" $EC=",U01-Output directory blank.,"
 F  S file=$ZSEARCH(pattern) Q:file=""  D
 . Q:$E($ZPARSE(file,"NAME"),1)="."
 . D translate(file,^sParam("tplc"))
 . Q
 Q
 ;
processFile(filename) ; Translate template from file to $IO
 N io,mumpsMode,lev
 S io=$I,mumpsMode=0,lev=0
 W $ZPARSE(filename,"NAME")_" ;",!
 ;
 O filename U filename
 F  R line Q:$ZEOF  U io D processLine(line,.mumpsMode,.lev) U filename
 U io C filename
 ;
 W " Q",!
 Q
 ;
processLine(line,mumpsMode,lev) ;
 N fc,lc
 S fc=$$findNonWs(line),lc=$$findNonWs(line,-1)
 ;
 I mumpsMode D  Q
 . I $E(line,lc-1,lc)="%>" S mumpsMode=0 Q
 . W $$qreplace^%str(line,"~","'"),!
 . Q
 ;
 I $E(line,fc,fc+1)="<%",$E(line,lc-1,lc)="%>" D  Q  ; Single-line MUMPS
 . S line=$$trim^%str($E(line,fc+2,$L(line)-2))
 . I line="end" W $$lev(lev)_"Q",! S lev=lev-1 Q
 . W $$lev(lev)_$$qreplace^%str(line,"~","'"),!
 . S:" D DO "[$$uc^%str($P(line," ",$L(line," "))) lev=lev+1
 . Q
 ;
 I $E(line,fc,fc+1)="<%" S mumpsMode=1 Q
 ;
 I line["<%" D  Q  ; Contains expression within text.
 . N left,right,out
 . S left=1,out=""
 . S right=0 F  S right=$F(line,"<%",left) Q:right=0  D
 . . S out=out_$$repr^%str($E(line,left,right-3))_"_"
 . . S left=right,right=$F(line,"%>",left)
 . . S out=out_$$trim^%str($E(line,left,$S(right=0:$L(line),1:right-3)))_"_"
 . . S left=right
 . . Q
 . S out=out_$$repr^%str($E(line,left,$L(line)))
 . I $E(out,$L(out))="_" S out=$E(out,1,$L(out)-1)
 . W $$lev(lev)_"D send^%web("_$$qreplace^%str(out,"~","'")_")",!
 . Q
 ;
 W $$lev(lev)_"D send^%web("_$$repr^%str(line)_")",!
 ;
 Q
 ;
