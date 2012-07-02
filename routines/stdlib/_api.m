%api ; C to MUMPS API
 Q
 ;
 ; @ci set: void set^%api(I:gtm_char_t*, I:gtm_char_t*)
set(key,value) ;
 S @(key_"="""_value_"""")
 Q
 ;
 ; @ci get: gtm_char_t* get^%api(I:gtm_char_t*)
get(key) ;
 Q @key
 ;
 ; @ci do: void do^%api(I:gtm_char_t*)
do(cmd) ;
 D @cmd
 Q
 ;
