%err ; Standard error handling routines.
 ; To use standard error trapping, Set $ZT="G ^%err"
 S $ZT="Q"
 TRO:$TL>0
 N %zerr
 S %zerr=$I(^sErr)
 ZSH "*":^sErr(%zerr)
 S ^sErr(%zerr)=$H_" "_$J_" "_$EC
 S $EC=",U999-Error info available in "_$NA(^sErr(%zerr))_","
 Q
 N T
 S T="TRO:$TL>0  S err=$I(^sErr) ZSHOW ""*"":^sErr(err) "
 S T=T_"S ^sErr(err)=$H_"" ""_$J_"" ""_$EC "
 S T=T_"S $EC="",U999-Error info available in #""_err_"","""
 S $ZT=T
 Q
 ;
ci() ; Save error from call-in
 D ^%err
 Q err
 ;
err() Q err
 ;
bail ; Process error and stop processing.
 N err
 S $ZT="H" ; Halt the current process if there's an error.
 D ^%err
 W "ERROR"_$C(29)_$EC_$C(29)_err_$C(29)_$ZSTATUS_$C(4)
 H
 ;
msg(msg) ; Display a message with lines under it.
 W !,msg,!
 F i=1:1:$L(msg) W "-"
 W !
 Q
 ;
displayLast ; Display last error.
 D display($O(^sErr(""),-1))
 Q
 ;
display(errno) ; Display human-readable error info to $Io
 ; errno is either:
 ; - a name that points to the output of the ZSHOW command OR
 ; - a number referring to the first subscript of ^Err
 S:errno?.N errno="^sErr("_errno_")"
 ;
 N sub
 D msg("Error information for "_errno_":")
 S sub=$P(@errno," ",1)
 W "Error logged "_$ZD(sub)_" "_$ZD(sub,"12")_$ZD(sub,":60 AM"),!,!
 ;
 S sub="" F  S sub=$O(@errno@("I",sub)) Q:sub=""  D
 . N val
 . S val=@errno@("I",sub)
 . D:$P(val,"=",1)="$ZSTATUS"
 . . W "Crashed at "_$P(val,",",2),!
 . . W $T(@$P(val,",",2)),!
 . . W $P(val,",",3)_" "_$P(val,",",4),!
 . . Q
 . W:$P(val,"=",1)="$ECODE" "$ECODE is "_$P(val,"=",2),!
 . Q
 ;
 D msg("In-memory variables:")
 S sub="" F  S sub=$O(@errno@("V",sub)) Q:sub=""  D
 . N val
 . S val=@errno@("V",sub)
 . W val,!
 . Q
 ;
 D msg("Stack trace:")
 S sub="" F  S sub=$O(@errno@("S",sub)) Q:sub=""  D
 . N val
 . S val=@errno@("S",sub)
 . I val["$ZTRAP" W "$ZTrap Error Handler:",!?5,"(see "_errno_")",! Q
 . S:val[" " val=$E(val,1,$F(val," ")-2)
 . I val["$DMOD" W val,!?5,"Direct Mode",!  Q
 . I val["$CI" W val,!?5,"Call-In",! Q
 . W val_": ",!,?5,$T(@val),!
 . Q
 ;
 Q
 ;
