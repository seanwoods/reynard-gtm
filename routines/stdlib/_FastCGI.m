%FastCGI ; FastCGI to GT.M Web Bridge
 n %zzzt
 S %zzzt="TRO:$TL>0  S err=$I(^sErr) ZSHOW ""*"":^sErr(err) "
 S %zzzt=%zzzt_"S ^sErr(err)=$H_"" ""_$J_"" ""_$EC "
 S $ZT=%zzzt_"S $EC="",U999-Error info available in #""_err_"","""
 K %zzzt
 N rtn
 S rtn="" F  S rtn=$V("RTNNEXT",rtn) Q:rtn=""  D
 . I rtn'["$DMOD",rtn'["$CI",rtn'=$T(+0),rtn'="%api" ZL $TR(rtn,"%","_")
 . Q
 ;
 K %req
 ;
 S %req("transport")="FastCGI"
 D parseData^%web
 D &fastcgi.send("Content-Type: text/html"_$C(13,10,13,10))
 D showEnvironment^%web
 ;
 Q
 ;
getParam(name) ;
 Q:$&fastcgi.paramExists(name)=0 ""
 Q $&fastcgi.getParam(name)
 ;
