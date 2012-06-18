%web ; High-level Web API
 ; This file provides high-level functions for interfacing with the
 ; World Wide Web.  It provides many "framework" type functions
 ; without getting in the programmer's way.  It also abstracts away
 ; interface-specific details (FastCGI vs. CGI).
 ;
 ; The system reserves `%req` and `%resp` as non-persistent global variables.
 ; As the system expects complete control over these variables, changing
 ; them in user code is not recommended.
 ;
 ; Life Cycle of a Reynard Web Request
 ; ===================================
 ;  1. Browser sends an HTTP request to a web server.
 ;  2. Web server identifies the request as one that Reynard will handle.
 ;  3. Request is forwarded to Reynard via one of many interfaces:
 ;     * CGI
 ;     * FastCGI
 ;     * Mongrel2 (planned)
 ;     * InterSystems Caché Server Pages (planned)
 ;  4. Interface-specific middleware (e.g. `^%FastCGI` or `^%cgi`) prepares
 ;     data for `^%web` and implements any interface-specific library
 ;     functions.
 ;     * `%req` and `%resp` are killed (deleted).
 ;     * `%req("transport")` is set to an interface identifer string.
 ;  5. Middleware calls `^%web`.
 ;  6. `^%web` resolves URL using routes.  If a route is not found, a 404
 ;     page is returned to the server.
 ;     * A route is a pattern that is matched against the `PATH_INFO`
 ;       variable.
 ;     * The simplest routes are straightforward matches. For example, 
 ;       `/catalog/chairs` could resolve to the chairs section of a
 ;       product catalog.
 ;     * You can also put variables in routes.  For example, in the route
 ;       `/catalog/:section/:identifier`, `:section` and `:identifier` can
 ;       be any values
 ;  7. If a route match is found, the data associated to the request is
 ;     parsed.  This data includes variables from the route, query-string
 ;     variables (like `$_GET` in PHP), and content variables (like
 ;     `$_POST` in PHP) - parsed in this order.  This information is
 ;     stored in `%req("data")`. If there is a variable name collision,
 ;     the system stores all values in `%req("data")` in the order they
 ;     were encountered.  `$$data^%web` (see below) retrieves the most
 ;     recently encountered value.
 ;  8. When a route match is found, `^%web` launches the entry point using
 ;     indirection (`Do @code`).
 ;  9. User code utilizes `^%web` interface to interact with web server.
 ;     * `$$env^%web` - Access server environment variables.
 ;     * `$$data^%web` - Access request data from GET, POST, and the URL.
 ;     * `$$getHeader^%web` - Retrieve a header value.
 ;     * `setHeader^%web` - Set a header value.
 ;     * `send^%web` - Send one line of response.
 ;
 N contentTypeSent,header
 ;
 S code=$$resolveRoute($$env("PATH_INFO"))
 I code="" D  Q
 . D send("Status: 404 Not Found")
 . D send("Content-type: text/html")
 . D send("")
 . D send("<!doctype html>")
 . D send("<h1>Object Not Found</h1>")
 . Q
 ;
 D parseData
 ;
 I $T(@("beforeHeader"_code))'="" D @("beforeHeader"_code)
 ;
 S header="" F  S header=$O(%resp("headers",header)) Q:header=""  D
 . S:$$uc^%str(header)="CONTENT-TYPE" contentTypeSent=1
 . D send(header_": "_%resp("headers",header))
 . Q
 ;
 D:$G(contentTypeSent)'=1 send("Content-type: text/html")
 D send("")
 ;
 I $T(@code)="" D  Q
 . D send("<!doctype html>")
 . D send("<h1>Routine "_code_" Not Found</h1>")
 . D showEnvironment
 . Q
 ;
 S tag="on"_$$env("REQUEST_METHOD")
 I $$hasTag^%rou(code,tag) D @(tag_code) Q
 ;
 D @code
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
data(name,num) ; Read a request variable (from query string, content, URL, etc)
 Q:$D(%req("data",name))'=11 ""
 I $G(num)="" S num=%req("data",name)
 Q %req("data",name,num)
 ;
getHeader(header) ; Retrieve a header value.
 Q $$env($TR($$uc^%str(header),"-","_"))
 ;
setHeader(header,value) ; Set a header in the response.
 S:$G(%resp("dirty"))=1 $EC=",U04-Headers already sent.,"
 S %resp("headers",header)=value
 Q
 ;
send(data,noNewLine,escape) ; Send data to client.
 S:$G(escape)=1 data=$$HTMLout^%cgi(data)
 S:$G(noNewLine)'=1 data=data_$C(13,10)
 ;
 S %resp("dirty")=1
 ;
 I $G(%req("transport"))="FastCGI" D &fastcgi.send(data) Q
 I $G(%req("transport"))="CGI" W data Q
 S $EC=",U03-Unknown transport type.,"
 Q
 ;
url(url) ;
 Q $$env("SCRIPT_NAME")_url
 ;
resolveRoute(path) ;
 N i,s,pc,target,var,v
 S s=$NA(^sWebRoute),target=""
 F i=1:1:$L(path,"/") D
 . S pc=$P(path,"/",i)
 . Q:pc=""
 . S s=$NA(@s@(pc))
 . Q:$D(@s)=0  ; Not worth looking down the whole tree.
 . I i=$L(path,"/") S target=$P(@s,"|",2) Q  ; Match
 . D:$P($G(@s),"|",1)=2
 . . ; A variable is coming.  Keep progressing down the path until we get
 . . ; to the end, or until we get to a non-variable piece.
 . . F  D  Q:(i>$L(path,"/"))!($P($G(@s),"|",1)'=2)
 . . . S var=$O(@s@("")),v=$E(var,2,$L(var))
 . . . S %req("data",v,$I(%req("data",v)))=$P(path,"/",i+1)
 . . . S i=i+1,pc=$P(path,"/",i),s=$NA(@s@(var))
 . . . I i=$L(path,"/") S target=$P($G(@s),"|",2)
 . . . Q
 . . Q
 . Q
 Q target
 ;
addRoute(pattern,entry) ; Add a URL pattern to the list of routes.
 N i,s,pc
 S s=$NA(^sWebRoute)
 F i=1:1:$L(pattern,"/") D
 . S pc=$P(pattern,"/",i)
 . Q:pc=""
 . I $E(pc,1)=":" S $P(@s,"|",1)=2 ; Clue that this part is a variable.
 . S s=$NA(@s@(pc))
 . I i=$L(pattern,"/") S $P(@s,"|",2)=entry
 . Q
 Q
 ;
testRoute ;
 TS
 D addRoute("/system/setup","^SystemSetup")
 D addRoute("/system/errors","^SysErrors")
 D addRoute("/system/errors/:errno","^SysErrNum")
 D addRoute("/system/errors/:errno/list","^SysErrNumList")
 D addRoute("/system/routines/:routine/:action","^SysRoutines")
 ;
 K %req
 W "Test fake route.",!
 D assertEq^%test($$resolveRoute("/phony"),"",1)
 ;
 K %req
 W "Test valid route, no variables.",!
 D assertEq^%test($$resolveRoute("/system/setup"),"^SystemSetup",1)
 ;
 K %req
 W "Test valid route, no variables.  Sub-urls have variables.",!
 D assertEq^%test($$resolveRoute("/system/errors"),"^SysErrors",1)
 ;
 K %req
 W "Test valid route, variable at the end.",!
 D assertEq^%test($$resolveRoute("/system/errors/200"),"^SysErrNum",1)
 D assertEq^%test($$data("errno"),200,1)
 ;
 K %req
 W "Test valid route, variable within items.",!
 D assertEq^%test($$resolveRoute("/system/errors/200/list"),"^SysErrNumList",1)
 D assertEq^%test($$data("errno"),200,1)
 ;
 K %req
 W "Test valid route, adjacent variables.",!
 D assertEq^%test($$resolveRoute("/system/routines/_str/list"),"^SysRoutines",1)
 D assertEq^%test($$data("routine"),"_str",1)
 D assertEq^%test($$data("action"),"list",1)
 ;
 TRO
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
 D send("<table class=""gtm-show-info"">")
 ;
 D send("<tr><th colspan=2>CGI Environment</th></tr>");
 S p="" F  S p=$O(param(p)) Q:p=""  D
 . D send("<tr><td>"_p_"</td><td>"_param(p)_"</td></tr>")
 . Q
 ;
 N sec,num,gtm
 ZSH "*":gtm
 F sec="D","G","I","S","V" D
 . D:sec="D" send("<tr><th colspan=2>GT.M Devices</th></tr>")
 . ;Q:sec="G"  ; send("<tr><th>GT.M Global Info</th></tr>")
 . D:sec="I" send("<tr><th colspan=2>GT.M Internal Variables</th></tr>")
 . D:sec="S" send("<tr><th colspan=2>GT.M Stack</th></tr>")
 . D:sec="V" send("<tr><th colspan=2>GT.M Variables</th></tr>")
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
