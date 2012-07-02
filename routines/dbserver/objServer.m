objServer ; handler for external program calls to object server.
 Q
 ;
multiPartCharSeq() Q $C(2,6,3,7)
 ;
 ; @ci alloc: gtm_char_t* alloc^objServer()
alloc() ; allocate a new message.
 Q $I(^objServerMsg)
 ;
 ; @ci exec: gtm_char_t* exec^objServer(I:gtm_char_t*, I:gtm_char_t*)
setrec(msg,segment,record,data) ;
 S ^objServerMsg(msg,segment,record)=data
 Q 1
 ;
 ; @ci handleMsg: gtm_char_t* handleMsg^objServer(I:gtm_int_t)
handleMsg(msgID) ; handle the given message
 N code,done,len,seg,%zzzt
 K out
 ;
 ; TODO - this error handling is really kludgy.  there must be a better way
 ;
 S %zzzt="TRO:$TL>0  S err=$I(^sErr) ZSHOW ""*"":^sErr(err) "
 S %zzzt=%zzzt_"S ^sErr(err)=$H_"" ""_$J_"" ""_$EC "
 S $ZT=%zzzt_"S $EC="",U999-Error info available in #""_err_"","""
 K %zzzt
 ;
 D:$G(^sParam("Debug")) refresh
 ;
 S out="OK"
 ;
 TS
 S seg=0,done=0 F  Q:done  D
 . S len=^objServerMsg(msgID,seg,1)
 . S code=$G(^sObjDest(^objServerMsg(msgID,seg,0)))
 . S:code="" out="NOK"
 . D:code'=""
 . . S code=code_"(msgID,.seg,.out)"
 . . I code'="" D @code
 . . Q
 . ;
 . ; Reset seg and len to process next logical message.
 . ;
 . I $D(^objServerMsg(msgID,seg+len+1))=0 S done=1 Q
 . S seg=seg+len+1,len=^objServerMsg(msgID,seg,1)
 . Q
 ;
 TC
 ;
 Q:$$hasChildren^%var($NA(out)) $$multiPartCharSeq()_$NA(out)
 Q out
 ;
 ; @ci next: gtm_char_t* next^objServer(I:gtm_char_t*, IO:gtm_char_t*)
next(vn,sub) ; retrieve next value from database, incrementing `sub`.
 ;
 ; useful for one-dimensional arrays, e.g. sending multi-part output.
 ;
 N val
 S:sub="" sub=$O(@vn@(sub)) ; initial increment
 S val=@vn@(sub)
 S sub=$o(@vn@(sub))
 Q val
 ;
initObjDest ; initialize verb destination table.
 K ^sObjDest
 S ^sObjDest("SETOBJ")="set^objNet"
 S ^sObjDest("GETOBJ")="get^objNet"
 S ^sObjDest("DELOBJ")="del^objNet"
 S ^sObjDest("DELCRIT")="delCrit^objNet"
 S ^sObjDest("QUERY")="query^objNet"
 S ^sObjDest("VIEW")="view^objNet"
 S ^sObjDest("FINDOBJ")="find^objNet"
 S ^sObjDest("LISTOBJ")="list^objNet"
 S ^sObjDest("LISTOBJS")="listObjects^objNet"
 S ^sObjDest("LISTVIEWS")="listViews^objNet"
 S ^sObjDest("ENHSCHEMA")="enhancedSchema^objNet"
 S ^sObjDest("POINTERS")="pointers^objNet"
 Q
 ;
refresh ; zlink current routines
 N rtn
 S rtn="" F  S rtn=$V("RTNNEXT",rtn) Q:rtn=""  D
 . I rtn'["$DMOD",rtn'["$CI",rtn'=$T(+0) ZL $TR(rtn,"%","_")
 . Q
 Q
 ;
