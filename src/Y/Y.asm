; Wye-Delta or Star-delta Transformation Y
MODEL P35S
SEGMENT DATA
  ; 1 RCL T \Lsh 2 > \Leftarrow \Leftarrow \Leftarrow \Lsh \pi \Rsh 0
  ; 2 \Lsh \pi \Lsh 2 > \Leftarrow \Leftarrow \Leftarrow RCL T \Rsh 0
  ; 3 RCL S \Lsh 2 > \Leftarrow \Leftarrow \Leftarrow RCL D \Rsh 0
  ; 4 RCL D \Lsh 2 > \Leftarrow \Leftarrow \Leftarrow RCL S
  eqnMenu EQU '1T->pi 2pi->T 3S->D 4D->S'
ENDS

SEGMENT CODE
start:
LBL Y                 ; \Rsh LBL Y

init:
  RPN                 ; MODE 5RPN

menu:
  SF 10               ; \Lsh \wedge 1 . 0
    EQN eqnMenu       ; EQN [eqnMenu] ENTER
  CF 10               ; \Lsh \wedge 2 . 0
  ; IF x=1 THEN GOTO 'S->D'
  1                   ; 1 ENTER
  x=y?                ; \Lsh x?y 6
    GTO star2delta    ; GTO label 'star2delta'
  Rv                  ; R\downarrow
  ; IF x=2 THEN GOTO 'D->S'
  2                   ; 2 ENTER
  x=y?                ; \Lsh x?y 6
    GTO delta2star    ; GTO label 'delta2star'
  Rv                  ; R\downarrow
  ; IF x=3 THEN GOTO 'S->D'
  3                   ; 2 ENTER
  x=y?                ; \Lsh x?y 6
    GTO star2delta    ; GTO label 'star2delta'
  Rv                  ; R\downarrow
  ; IF x=4 THEN GOTO 'D->S'
  4                   ; 2 ENTER
  x=y?                ; \Lsh x?y 6
    GTO delta2star    ; GTO label 'delta2star'
  Rv                  ; R\downarrow
STOP                  ; R/S

star2delta:
  ; S->D
  INPUT P             ; \Lsh INPUT P
  INPUT Q             ; \Lsh INPUT Q
  INPUT R             ; \Lsh INPUT R
  *                   ; \times
  *                   ; \times
  ; IF x=0 THEN GOTO 'S->D'
  x=0?                ; \Rsh x?0 6
    GTO star2delta    ; GTO label 'star2delta'
  ; x=P*Q+Q*R+R*P
  RCL P               ; RCL P
  RCL Q               ; RCL Q
  *                   ; \times 
  RCL Q               ; RCL Q
  RCL R               ; RCL R
  *                   ; \times
  RCL R               ; RCL R
  RCL P               ; RCL P
  *                   ; \times 
  +                   ; +
  +                   ; +
  STO A               ; \Rsh STO A
  STO B               ; \Rsh STO B
  STO C               ; \Rsh STO C
  ; A=x/R
  RCL R               ; RCL R
  STO/ A              ; \Rsh STO \div A
  ; B=x/Q
  RCL Q               ; RCL Q
  STO/ B              ; \Rsh STO \div B
  ; C=x/P
  RCL P               ; RCL P
  STO/ C              ; \Rsh STO \div C
  ; view ABC
  0                   ; 0 ENTER
  RCL A               ; RCL A
  RCL B               ; RCL B
  RCL C               ; RCL C
  VIEW A              ; \Lsh VIEW A
  VIEW B              ; \Lsh VIEW B
  VIEW C              ; \Lsh VIEW C
RTN

delta2star:
  ; D->S
  INPUT A             ; \Lsh INPUT A
  INPUT B             ; \Lsh INPUT B
  INPUT C             ; \Lsh INPUT C
  +                   ; +
  +                   ; +
  ; IF x=0 THEN GOTO 'D->S'
  x=0?                ; \Rsh x?0 6
    GTO delta2star    ; GTO label 'delta2star'
  ; x=1/(A+B+C)
  1/x                 ; 1/X
  STO P               ; \Rsh STO P
  STO Q               ; \Rsh STO Q
  STO R               ; \Rsh STO R
  ; P=A*B*x
  RCL A               ; RCL A
  RCL B               ; RCL B
  *                   ; \times
  STO* P              ; \Rsh STO \times P
  ; Q=A*C*x
  RCL A               ; RCL A
  RCL C               ; RCL C
  *                   ; \times
  STO* Q              ; \Rsh STO \times Q
  ; Q=B*C*x
  RCL B               ; RCL B
  RCL C               ; RCL C
  *                   ; \times
  STO* R              ; \Rsh STO \times R
  ; view PQR
  0                   ; 0 ENTER
  RCL P               ; RCL P
  RCL Q               ; RCL Q
  RCL R               ; RCL R
  VIEW P              ; \Lsh VIEW P
  VIEW Q              ; \Lsh VIEW Q
  VIEW R              ; \Lsh VIEW R

RTN                   ; \Lsh RTN \C
ENDS
END start             ; \C
; CK=9506
; LN=289
