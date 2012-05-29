%web ; High-level Web API
 ; This file provides high-level functions for interfacing with the
 ; World Wide Web.  It provides many of the "framework" type functions
 ; without getting in the programmer's way.  It also abstracts away
 ; interface-specific details (FastCGI vs. CGI).
 ;
 ; Important Note: Request state is stored in the `%req` variable, which
 ; should always be available when these functions are called.  You can
 ; modify `%req` directly, but make sure you know what you are doing.
 ; If there is a function in this file to do what you want, use that before
 ; resorting to modifying `%req`.
 ;
 Q
 ;
env(name) ; Read a server environment variable.
 N val
 I $G(%req("transport"))="FastCGI" Q $$getParam^%FastCGI(name)
 I $G(%req("transport"))="CGI" Q $ZTRNLNM(name)
 S $EC=",U01-Unknown transport type.,"
 Q
 ;
data(name,num) ; Read a request variable (from GET and POST).
 Q:$D(%req("data",name))'=11 ""
 I $G(num)="" S num=%req("data",name)
 Q %req("data",name,num)
 ;
header(header) ; Retrieve a header value.
 Q $$env($TR($$uc^%str(header),"-","_"))
 ;
send(data,noNewLine,escape) ; Send data to client.
 S:$G(escape)=1 data=$$HTMLout^%cgi(data)
 S:$G(noNewLine)'=1 data=data_$C(13,10)
 ;
 I $G(%req("transport"))="FastCGI" D &fastcgi.send(data) Q
 I $G(%req("transport"))="CGI" W data Q
 S $EC=",U03-Unknown transport type.,"
 Q
 ;
showEnvironment ; Show the current environment as a series of HTML tables.
 N p,param,paramNum
 ;
 S paramNum=-1 F  S paramNum=$&fastcgi.nextParam(paramNum) Q:paramNum<0  D
 . S p=$&fastcgi.getParamByNum(paramNum)
 . S param($E(p,0,$F(p,"=")-2))=$E(p,$F(p,"="),$L(p))
 . Q
 ;
 D send("<table>")
 ;
 D send("<tr><th>CGI Environment</th></tr>");
 S p="" F  S p=$O(param(p)) Q:p=""  D
 . D send("<tr><td>"_p_"</td><td>"_param(p)_"</td></tr>")
 . Q
 ;
 N sec,num,gtm
 ZSH "*":gtm
 F sec="D","G","I","S","V" D
 . D:sec="D" send("<tr><th>GT.M Devices</th></tr>")
 . ;Q:sec="G"  ; send("<tr><th>GT.M Global Info</th></tr>")
 . D:sec="I" send("<tr><th>GT.M Internal Variables</th></tr>")
 . D:sec="S" send("<tr><th>GT.M Stack</th></tr>")
 . D:sec="V" send("<tr><th>GT.M Variables</th></tr>")
 . S num="" F  S num=$O(gtm(sec,num)) Q:num=""  D
 . . D:sec="D"
 . . . N dev,state
 . . . S dev=$P(gtm(sec,num)," ",1),state=$P(gtm(sec,num)," ",2,$L(gtm(sec,num)," "))
 . . . D send("<tr><td>"_dev_"</td><td>"_state_"</td></tr>")
 . . . Q
 . . D:sec="G"
 . . . ; To be implemented TODO
 . . . Q
 . . D:sec="I"
 . . . N var,val
 . . . S var=$P(gtm(sec,num),"=",1)
 . . . S val=$E(gtm(sec,num),$F(gtm(sec,num),"="),$L(gtm(sec,num)))
 . . . D send("<tr><td>"_var_"</td><td>"_$$indirect^%var(val)_"</td></tr>")
 . . . Q
 . . D:sec="S"
 . . . N continue S continue=1
 . . . D send("<tr>")
 . . . D send("<td>"_$$HTMLout^%cgi(gtm(sec,num))_"</td>")
 . . . I gtm(sec,num)["$DMOD" D send("<td>Direct Mode</td>") S continue=0
 . . . I gtm(sec,num)["$CI" D send("<td>Call-In</td>") S continue=0
 . . . D:continue send("<td>"_$T(@gtm(sec,num))_"</td>")
 . . . D send("</tr>")
 . . . Q
 . . D:sec="V"
 . . . Q:$$sw^%str(gtm(sec,num),"gtm(")
 . . . D send("<tr><td colspan=""2"">"_$$HTMLout^%cgi(gtm(sec,num))_"</td></tr>")
 . . . Q
 . . Q
 . Q
 ;
 Q
 ;
parseData ; Parse data from query string and request body.
 N d,data,i
 S data=""
 ;
 I $L($$env("QUERY_STRING"))>0 D processData($$env("QUERY_STRING"))
 ;
 D:+$$env("CONTENT_LENGTH")>0
 . I $G(%req("transport"))="FastCGI" D  Q
 . . ; TODO need to ensure this handles UTF-8 properly.
 . . F i=1:1:$$env("CONTENT_LENGTH") S data=data_$C($&fastcgi.getChar())
 . . D processData(data)
 . . Q
 . ;
 . I $G(%req("transport"))="CGI" D  Q
 . . R data#$$env("CONTENT_LENGTH")
 . . D processData(data)
 . . Q
 . ;
 . S $EC=",U02-Unknown transport type.,"
 . Q
 ;
 Q
 ;
processData(data) ; Parse an argument string and populate `%req`.
 F i=1:1:$L(data,"&") D
 . N ind,pc,val
 . S pc=$P(data,"&",i)
 . S ind=$$URLin^%cgi($P(pc,"=",1)),val=$$URLin^%cgi($P(pc,"=",2))
 . S:ind'="" %req("data",ind,$I(%req("data",ind)))=val
 . Q
 ;
 Q
 ;
