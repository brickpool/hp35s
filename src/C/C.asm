; Series and Parallel circuits
MODEL P35S
SEGMENT DATA
  eqnMain EQU '1PAR 2SER'
  eqnPar  EQU '1R 2C 3L 4P 5I 6G 7Z'
  eqnSer  EQU '1R 2C 3L 4P 5V 6G'
  eqnToI  EQU '\|>(I)'
ENDS

SEGMENT CODE
start:
LBL C               ; Program C

init:
  RPN               ; mode RPN
  CF 0              ; clear flag 0
  CLZ               ; clear statistic

mainmenu:
  ; display [eqnMain]
  SF 10
    eqn eqnMain
  CF 10
  ; IF y=1 THEN GOTO 'parmenu'
  1
  x=y?
    GTO parmenu
  Rv                ; y -> x
  ; IF x=2 THEN GOTO 'sermenu'
  2
  x=y?
    GTO sermenu
  Rv                ; y -> x
STOP                ; stop programm

parmenu:
  ; display [eqnPar]
  SF 10
    eqn eqnPar      
  CF 10
  ; IF x<=0 THEN GOTO 'parmenu'
  x<=0?
    GTO parmenu
  ; IF y>7 THEN GOTO 'parmenu'
  7
  x<y?
    GTO parmenu
  Rv                ; y -> x
  ; IF y=1 THEN SF(0)
  1
  x=y?
    SF 0            ; set flag 0
  Rv                ; y -> x
  ; IF y=3 THEN SF(0)
  3
  x=y?
    SF 0            ; set flag 0
  Rv                ; y -> x
  ; IF y=7 THEN SF(0)
  7
  x=y?
    SF 0            ; y -> x
GTO read            ; jump to 'read'

sermenu:
  ; display [eqnSer]
  SF 10
    eqn eqnSer
  CF 10
  ; IF x<=0 THEN GOTO sermenu
  x<=0?
    GTO sermenu
  ; IF y>6 THEN GOTO 'sermenu'
  6
  x<y?
    GTO sermenu
  Rv                ; y -> x
  ; IF y=2 THEN SF(0)
  2
  x=y?
    SF 0            ; set flag 0
  Rv                ; y -> x
  ; IF y=6 THEN SF(0)
  6
  x=y?
    SF 0            ; set flag 0

read:
  ; display [eqnToI]
  SF 10
    eqn eqnToI
  CF 10
  ; IF x=0 THEN GOTO 'done'
  x=0?
    GTO done
  ENTER             ; x -> y
  1/x               ; x = 1/x
  Z+                ; SUM (x,y)
  STO I             ; n -> I
  Rv                ; y -> x
  STO(I)
  VIEW(I)
GTO read            ; jump to 'read'

done:
  Zx                ; SUM x
  ; IF x<>0 THEN x=1/x
  x!=0?
    1/x
  Zy                ; SUM y (= 1/x)
  ; IF SF=0 THEN SWAP(x,y)
  FS? 0
    x<>y
  CF 0              ; clear flag 0

print:
  STO V
  VIEW V

RTN
ENDS

END start
; CK=15F4
; LN=287
