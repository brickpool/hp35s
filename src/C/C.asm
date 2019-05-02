; Series and Parallel circuits
MODEL P35S
SEGMENT DATA
  ; 1 RCL P RCL A RCL R \Rsh 0 2 RCL S RCL E RCL R
  eqnMain EQU '1PAR 2SER'
  ; 1 RCL R \Rsh 0 2 RCL C \Rsh 0 3 RCL L \Rsh 0
  ; 4 RCL P \Rsh 0 5 RCL I \Rsh 0 6 RCL G \Rsh 0
  ; 7 RCL Z
  eqnPar  EQU '1R 2C 3L 4P 5I 6G 7Z'
  ; 1 RCL R \Rsh 0 2 RCL C \Rsh 0 3 RCL L \Rsh 0
  ; 4 RCL P \Rsh 0 5 RCL V \Rsh 0 5 RCL G 
  eqnSer  EQU '1R 2C 3L 4P 5V 6G'
  ; ->(I)
  ; \Lsh 6 RCL I < < \Leftarrow \Leftarrow
  eqnToI  EQU '|>(I)'
ENDS

SEGMENT CODE
start:
LBL C               ; \Rsh LBL C

init:
  RPN               ; MODE 5RPN
  CF 0              ; \Lsh \wedge 2 0
  CLZ               ; \Rsh CLEAR 4

mainmenu:
  SF 10             ; \Lsh \wedge 1 . 0
    EQN eqnMain     ; EQN [eqnMain] ENTER
  CF 10             ; \Lsh \wedge 2 . 0
  ; IF y=1 THEN GOTO 'parmenu'
  1                 ; 1 ENTER
  x=y?              ; \Lsh x?y 6
    GTO parmenu     ; GTO label 'parmenu'
  Rv                ; R\downarrow
  ; IF y=2 THEN GOTO 'sermenu'
  2                 ; 2 ENTER
  x=y?              ; \Lsh x?y 6
    GTO sermenu     ; GTO label 'sermenu'
  Rv                ; R\downarrow
STOP                ; R/S

parmenu:
  SF 10             ; \Lsh \wedge 1 . 0
    EQN eqnPar      ; EQN [eqnPar] ENTER
  CF 10             ; \Lsh \wedge 2 . 0
  ; IF x<=0 THEN GOTO 'parmenu'
  x<=0?             ; \Rsh x?0 2
    GTO parmenu     ; GTO 'parmenu'
  ; IF y>7 THEN GOTO 'parmenu'
  7                 ; 7 ENTER
  x<y?              ; \Lsh x<0 3
    GTO parmenu     ; GTO 'parmenu'
  Rv                ; R\downarrow
  ; IF y=1 THEN SF(0)
  1                 ; 1 ENTER
  x=y?              ; \Lsh x?y 6
    SF 0            ; \Lsh \wedge 1 0       
  Rv                ; R\downarrow
  ; IF y=3 THEN SF(0)
  3                 ; 3 ENTER
  x=y?              ; \Lsh x?y 6
    SF 0            ; \Lsh \wedge 1 0       
  Rv                ; R\downarrow
  ; IF y=7 THEN SF(0)
  7                 ; 7 ENTER
  x=y?              ; \Lsh x?y 6
  SF 0              ; \Lsh \wedge 1 0       
GTO read            ; GTO label 'read'

sermenu:
  SF 10             ; \Lsh \wedge 1 . 0
    EQN eqnSer      ; EQN [eqnSer] ENTER
  CF 10             ; \Lsh \wedge 2 . 0
  ; IF x<=0 THEN GOTO sermenu
  x<=0?             ; \Rsh x?0 2
    GTO sermenu     ; GTO label 'sermenu'
  ; IF y>6 THEN GOTO 'sermenu'
  6                 ; 6 ENTER
  x<y?              ; \Lsh x?y 3
    GTO sermenu     ; GTO label 'sermenu'
  Rv                ; R\downarrow
  ; IF y=2 THEN SF(0)
  2                 ; 2 ENTER
  x=y?              ; \Lsh x?y 6
    SF 0            ; \Lsh \wedge 1 0       
  Rv                ; R\downarrow
  ; IF y=6 THEN SF(0)
  6                 ; 6 ENTER
  x=y?              ; \Lsh x?y 6
    SF 0            ; \Lsh \wedge 1 0       

read:
  SF 10             ; \Lsh \wedge 1 . 0
    EQN eqnToI      ; EQN [eqnToI]
  CF 10             ; \Lsh \wedge 2 . 0
  ; IF x=0 THEN GOTO 'done'
  x=0?              ; \Rsh x?0 6
    GTO done        ; GTO label 'done'
  ENTER             ; ENTER
  1/x               ; 1/X
  Z+                ; \sum{+}
  STO I             ; \Rsh STO I
  Rv                ; R\downarrow
  STO(I)            ; \Rsh STO 0
  VIEW(I)           ; \Lsh VIEW 0
GTO read            ; GTO label 'read'

done:
  Zx                ; \Rsh SUM 2
  ; IF x<>0 THEN x=1/x
  x!=0?             ; \Rsh x?0 1
    1/x             ; 1/X
  Zy                ; \Rsh SUM 3
  ; IF SF=0 THEN SWAP(x,y)
  FS? 0             ; \Lsh \wedge 3 0
    x<>y            ; x<>y                  
  CF 0              ; \Lsh \wedge 2 0

print:
  STO V             ; \Rsh STO V
  VIEW V            ; \Lsh VIEW V

RTN                 ; \Lsh RTN
ENDS

END start           ; \C
; CK=15F4
; LN=287
