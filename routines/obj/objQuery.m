objQuery
 Q
 ;
exec(%query,%rs,%sort,%count,%args) ;
 N %critCode,%glvn,%i,%id,%names,%nm
 ;
 S %count=0
 ; Analyze query so we know which names we'll need.
 D analyzeFields^objQueryLib(%query("fields"),.%names)
 S critCode=$$mkCrit^objQueryLib(.%query,.%names)
 D analyzeSorts^objQueryLib(%query("sort"),.%names)
 ;
 ; Set up global variable name for object.
 S:$G(%query("class"))="" $EC=",U96-Query class not specified.,"
 S %glvn=$$glvn^%obj(%query("class"),"o")
 ;
 ; If we want to output field names instead of just offsets, populate
 ; `%rs` with field names.
 D:$G(%query("emitFields"))
 . S %rs="id"
 . F %i=1:1:$L(%query("fields")," ") D
 . . S %rs=%rs_$C(31)_$P(%query("fields")," ",%i)
 . . Q
 . Q
 ;
 ; Outer loop over all objects of this class in database.
 S %id="" F  S %id=$O(@%glvn@(%id)) Q:%id=""  D
 . S %nm="" F  S %nm=$O(%names("C",%nm)) Q:%nm=""  D
 . . S @($$cvtId^objQueryLib(%nm)_"=$$getField^%obj(%query(""class""),%id,%nm)")
 . . Q
 . S %nm="" F  S %nm=$O(%names("V",%nm)) Q:%nm=""  D
 . . ; TODO find expected format for argument, i.e. should it have quotes?
 . . ; see db.py as well
 . . ;S @($$cvtId^objQueryLib(%nm)_"="_$$repr^%str($G(args(%nm))))
 . . S @($$cvtId^objQueryLib(%nm)_"="_$G(args(%nm),$C(34,34)))
 . . Q
 . I critCode'="" S @("%ok="_critCode) Q:'%ok
 . ;
 . ; Extract fields in query.
 . S %rs(%id)=%id,%count=%count+1
 . F i=1:1:$L(%query("fields")," ") D
 . . S %nm=$P(%query("fields")," ",i)
 . . S %rs(%id)=%rs(%id)_$C(31)_$$getField^%obj(%query("class"),%id,%nm)
 . . Q
 . ;
 . D:$G(%query("sort"))'=""
 . . N %ref
 . . S %ref="%sort("
 . . F %i=1:1:$L(%query("sort")," ") D
 . . . S %nm=$P(%query("sort")," ",%i)
 . . . S %ref=%ref_$$repr^%str($$getField^%obj(%query("class"),%id,%nm))_","
 . . . Q
 . . S %ref=%ref_%id_")=1"
 . . S @%ref
 . . Q
 . Q
 Q
 ;
execFromDB(viewName,resultSet,sort,count,args) ;
 N viewID,viewObj
 S viewID=$O(^xSysView("Name",viewName,""))
 Q:viewID=""
 D get^%obj("SysView",viewID,.viewObj)
 D exec(.viewObj,.resultSet,.sort,.count)
 Q
 ;
translate(query) ;
 Q $$gen^objQueryLib(.query)
 ;
