objView ;
 Q
 ;
translateAll ;
 N id,obj,rtnName
 S id="" F  S id=$$next^%obj("sysView",id) Q:id=""  D
 . D get^%obj("sysView",id,.obj)
 . S rtnName=$$gen^objQuery(.obj)
 . Q:rtnName=""
 . ZL rtnName
 . Q
 Q
 ;
