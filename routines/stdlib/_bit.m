%bit ; Bitwise operations
 Q
 ;
in(x,size) ;
 N j,out
 S out=$ZBITSTR(size,0)
 F j=1:1:size S b=x#2,x=x\2 I b S out=$zbitset(out,j,1)
 Q out
 ;
out(x,size,startat) ;
 N k,out
 ;S:$G(startat)="" startat=1
 S out=0
 F k=startat:1:(startat+size-1) I $zbitget(x,k) S out=out+(2**((k#8)-1))
 Q out
 ;
repr(x) ; Generate human-readable representation of bit string.
 N k,out
 F k=1:1:$ZBITLEN(x) S $E(out,($ZBITLEN(x)+1)-k)=$ZBITGET(x,k)
 Q out
 ;
wireEncode(x) ;
 N s,k,out
 W "Repr:",?20,$$repr(x),!
 W "ReprLen:",?20,$l($$repr(x)),!
 W "Len:",?20,$zbitlen(x),!
 F i=1:8:($ZBITLEN(x)+1) W:i<$zbitlen(x) i,?20,$$out(x,8,i),!
 Q
 ;
shiftLeft(x,size,p) ;
 N i,out
 S out=$ZBITSTR(size,0)
 F i=1:1:(size-p) S out=$ZBITSET(out,i+p,$ZBITGET(x,i))
 Q out
 ;
test(z) ;
 ;s $zt="g ^%err"
 ;D wireEncode($$in(z,16))
 s aa=$zbitstr(16)
 s aa=$zbitset(aa,4,1)
 w $$repr(aa),!
 s out=0 f i=1:1:7 s:$zbitget(aa,i) out=out+(2**((i#(7-1))
 w out,!
 ;w $$out(aa,8,9),!
 Q
 ;
