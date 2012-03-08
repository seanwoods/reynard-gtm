%gs ; global save and restore utility
 new glvn,io
 set io=$io
 use io:(EDITING)  ; Note: Only saves ONE line of history!
 set glvn="?"
 for  quit:glvn=""  do
 . write !,"Global ^"
 . read glvn
 . write !
 . if $get(glvn)="" quit
 . if glvn="*" do  quit
 . . new a
 . . do roots(.a)
 . . set a="" for  set a=$order(a(a)) quit:a=""  write a,!
 . . quit
 . if $extract(glvn,1)="-" do  quit
 . . write $order(@("^"_$extract(glvn,2,$length(glvn))_"("""")"),-1),!
 . . quit
 . if '$$hasValue^%var("^"_glvn),'$$hasChildren^%var("^"_glvn) write "Global variable '"_glvn_"' does not exist.",! quit
 . do query("^"_glvn)
 . quit
 use io
 quit
 ;
backup(filename) ; Dump entire global tree to file.
 new global,io
 ;
 set io=$io open filename:NEWVERSION use filename
 set global="^%" for  set global=$order(@global) quit:global=""  do
 . do query(global)
 . quit
 use io close filename
 ;
 quit
 ;
restore(filename) ; Restore ZWR-formatted file to global tree.
 new io,line
 ;
 set io=$io open filename use filename
 for  read line quit:$zeof  set:line'="" @line
 use io close filename
 quit
 ;
roots(array) ; Put a list of all global roots into `array`.
 new root
 ;
 set root="^%" for  set root=$order(@root) quit:root=""  do
 . set array(root)=1
 . quit
 ;
 quit
 ;
save(root,filename) ; Save specific global to file.
 new io
 ;
 set io=$io open filename:NEWVERSION use filename
 do query(root)
 use io close filename
 ;
 quit
 ;
cmderr ; command line error handler
 halt
 ;
cmd ; command line entry point
 set $ztrap="zgoto 1:cmderr^"_$text(+0)
 do query($zcmdline)
 quit
 ;
sameTree(left,right) ; Determine whether the two variables share a root.
 ; Note: This really looks at the smaller of the two variables and uses those
 ;       subscripts to figure out if there is a common 'denominator.'
 Q:left="" 0
 Q:right="" 0
 ;
 N longer,same,shorter
 ;
 I $QL(left)>$QL(right) S longer=left,shorter=right
 I $QL(left)<$QL(right) S longer=right,shorter=left
 I $QL(left)=$QL(right) S longer=left,shorter=right
 ;
 S same=1
 F i=0:1:$QL(shorter) Q:same=0  I $QS(longer,i)'=$QS(shorter,i) S same=0
 ;
 Q same
 ;
query(root) ; Loop through a global tree and write statements to $IO.
 ; Why is this necessary?  [ZWR]ite only works with the _root_ of a global
 ; node, not an arbitrary place in between.  This function takes all nodes
 ; from the current node to the last node within the subtree.
 new glvn
 ;
 write:$$hasValue^%var(root) root_"="_$$repr^%str(@root),!
 set glvn=root for  set glvn=$query(@glvn) quit:'$$sameTree(root,glvn)  do
 . write glvn_"="_$$repr^%str(@glvn),!
 . quit
 ;
 quit
 ;
