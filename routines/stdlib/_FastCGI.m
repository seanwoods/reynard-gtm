%FastCGI ; FastCGI to GT.M Web Bridge
 S $ZT="G ^%err"
 D:$G(^sParam("debug"))
 . N rtn
 . S rtn="" F  S rtn=$V("RTNNEXT",rtn) Q:rtn=""  D
 . . I rtn'["$DMOD",rtn'["$CI",rtn'=$T(+0),rtn'="%api" ZL $TR(rtn,"%","_")
 . . Q
 . ;
 . Q
 ;
 K  ; Remove any existing process state.
 S $EC=""
 ;
 S %req("transport")="FastCGI"
 ;
 I $G(^sParam("tplc"))="" S $EC=",U01-No directory for compiled templates.,"
 ;
 D:$G(^sParam("debug"))=1 translateAll^%tpl
 D ^%web
 ;
 Q
 ;
getParam(name) ;
 Q:$&fastcgi.paramExists(name)=0 ""
 Q $&fastcgi.getParam(name)
 ;
