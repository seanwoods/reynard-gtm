objView ;
 Q
 ;
translate(shortName) ; Translate one view.
 N done,id,obj,rtnName
 S done=0,id="" F  S id=$$next^%obj("sysView",id) Q:done!(id="")  D
 . I $$getField^%obj("sysView",id,"name")=shortName S done=1 Q
 . Q
 D get^%obj("sysView",id,.obj)
 S rtnName=$$translate^objQuery(.obj)
 Q:rtnName=""
 ZL rtnName
 Q
 ;
translateAll ;
 N id,obj,rtnName
 S id="" F  S id=$$next^%obj("sysView",id) Q:id=""  D
 . D get^%obj("sysView",id,.obj)
 . S rtnName=$$translate^objQuery(.obj)
 . Q:rtnName=""
 . ZL rtnName
 . Q
 Q
 ;
