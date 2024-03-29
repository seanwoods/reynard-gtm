objSetup ; Set up supporting object structures.
 N id,o,qu
 ;
 ; Set up field queries.
 K qu
 S qu("name")="SystemFields"
 S qu("class")="sysSchema"
 S qu("crit")="object = $class"
 S qu("fields")="short_name caption datatype extra"
 S qu("indexBy")="short_name"
 S qu("sort")="short_name"
 ZL $$translate^objQuery(.qu)
 ;
 ; Query all pointer objects
 K qu
 S qu("name")="SystemPointers"
 S qu("class")="sysSchema"
 S qu("crit")="datatype = ""P"" OR datatype = ""PM"" AND object = $class"
 S qu("fields")="short_name extra"
 S qu("indexBy")="short_name"
 ZL $$translate^objQuery(.qu)
 ;
 ; Query all views
 K qu
 S qu("name")="SystemViews"
 S qu("class")="sysView"
 S qu("fields")="name description"
 S qu("sort")="description"
 ZL $$translate^objQuery(.qu)
 ;
 ; Define indexes
 S ^sIndex("SysUser","Username","username")=1
 S ^sIndex("SysView","Name","name")=1
 ;
 ; Setup initial user
 D:'$O(^xSysUser("Username","root",""))
 . K o
 . S o("username")="root"
 . S o("password")=""
 . S o("fullname")="Root User"
 . S o("changepw")="Y"
 . S id=$O(^xSysUser("root",""))
 . S:id="" id=$$alloc^%obj("SysUser")
 . D set^%obj("SysUser",id,.o)
 . Q
 ;
 S ^sHooks("OnFile","*","onFile^objSchema")=1
 ;
 Q
