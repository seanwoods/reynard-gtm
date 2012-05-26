%cgi ; CGI Handling Routines
 ; Adapted from similar routines by Ed de Moel.
 N i,data,entry
 W "Content-Type: text/html",!,!
 S $ZT="D err^"_$T(+0)_"($ZSTATUS)"
 ;
 I $ZTRNLNM("REQUEST_METHOD")="POST" D
 . R data#$ZTRNLNM("CONTENT_LENGTH"):5
 . Q
 E  D
 . S data=$ZTRNLNM("QUERY_STRING")
 . Q
 ;
 F i=1:1:$L(data,"&") D
 . N ind,pc,val
 . S pc=$P(data,"&",i)
 . S ind=$$URLin($P(pc,"=",1)),val=$$URLin($P(pc,"=",2))
 . S:ind'="" %request("data",ind)=val
 . Q
 ;
 W "Oh hai!",!
 Q
 ;
err(msg) ; Output error message
 W "<!doctype html>",!
 W "<html>",!
 W ?2,"<title>GT.M Web Error</title>",!
 W ?2,"<h3>Error: "_$$HTMLout(msg)_"</h3>",!
 W ?2,"<p><em>$ZV="_$ZV_"</em></p>",!
 W ?2,"<pre>",!
 ZSH "*"
 W ?2,"</pre>",!
 W ?2,"</html>",!
 H
 ;
URLin(url) ; Parse special characters from URL.
 N c,char,hex,i,p,r,z
 S hex="0123456789abcdef",z=$tr(url,"ABCDEF","abcdef")
 S r="" F i=1:1:$L(url) D
 . S char=$E(url,i)
 . I char="+" S r=r_" " Q
 . I char="%" D  Q
 . . S c=$F(hex,$E(z,i+1))-2*16+$F(hex,$E(z,i+2))-2
 . . S r=r_$C(c),i=i+2
 . . Q
 . S r=r_char
 . Q
 Q r
 ;
URLout(url) ; Escape special characters for URL.
 N e,i,hex,r
 S hex="0123456789abcdef"
 S r="" F i=1:1:$L(url) D
 . S e=$E(url,i)
 . I e?1AN S r=r_e Q
 . I e=" " S r=r_"+" Q
 . S e=$A(e),r=r_"%"_$E(hex,e\16+1)_$E(hex,e#16+1)
 . Q
 Q r
 ;
HTMLout(html) ; Escape special HTML characters.
 N e,i,r
 S r="" F i=1:1:$L(html) D
 . S e=$E(html,i)
 . I e="&" S r=r_"&amp;" Q
 . I e="<" S r=r_"&lt;" Q
 . I e=">" S r=r_"&gt;" Q
 . I $A(e)>126 S r=r_"&#"_$A(e)_";" Q
 . S r=r_e
 . Q
 Q r
 ;
