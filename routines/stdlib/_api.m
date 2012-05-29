%api ; C to MUMPS API
 Q
 ;
set(key,value) ;
 S @(key_"="""_value_"""")
 Q
 ;
get(key) ;
 Q @key
 ;
do(cmd) ;
 D @cmd
 Q
 ;
