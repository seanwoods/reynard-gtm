objDump ; Dump all object globals to $IO using ZWRite
 N glvn
 F pre="^o","^d","^dx" D
 . S glvn=pre F  S glvn=$O(@glvn) Q:'$$sw^%str(glvn,pre)  D
 . . Q:'$$isUpper^%str($E(glvn,$L(pre)+1))
 . . ZWR @glvn
 . . Q
 . Q
 Q
 ;
