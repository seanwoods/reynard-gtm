%cgi ; CGI Handling Routines
 ; This file implements all the basic RFC-related functionality for
 ; interaction with WWW services.
 Q
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
