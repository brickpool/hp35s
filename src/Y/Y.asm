; Wye-Delta or Star-delta Transformation Y
MODEL P35S
SEGMENT DATA
  eqnMenu EQU '1T\->\pi 2\pi\->T 3S\->D 4D\->S'
ENDS

SEGMENT CODE
start:
LBL Y

init:
  RPN                 ; mode RPN

menu:
  ; Display Menue
  SF 10
    eqn eqnMenu
  CF 10
  ; IF x=1 THEN GOTO 'S->D'
  1
  x=y?
    GTO star2delta
  Rv
  ; IF x=2 THEN GOTO 'D->S'
  2
  x=y?
    GTO delta2star
  Rv
  ; IF x=3 THEN GOTO 'S->D'
  3
  x=y?
    GTO star2delta
  Rv
  ; IF x=4 THEN GOTO 'D->S'
  4
  x=y?
    GTO delta2star
  Rv
STOP

star2delta:
  ; S->D
  INPUT P
  INPUT Q
  INPUT R
  *
  *
  ; IF x=0 THEN GOTO 'S->D'
  x=0?
    GTO star2delta
  ; x=P*Q+Q*R+R*P
  RCL P
  RCL Q
  *
  RCL Q
  RCL R
  *
  RCL R
  RCL P
  *
  +
  +
  STO A
  STO B
  STO C
  ; A=x/R
  RCL R
  STO/ A
  ; B=x/Q
  RCL Q
  STO/ B
  ; C=x/P
  RCL P
  STO/ C
  ; view ABC
  0
  RCL A
  RCL B
  RCL C
  VIEW A
  VIEW B
  VIEW C
RTN

delta2star:
  ; D->S
  INPUT A
  INPUT B
  INPUT C
  +
  +
  ; IF x=0 THEN GOTO 'D->S'
  x=0?
    GTO delta2star
  ; x=1/(A+B+C)
  1/x
  STO P
  STO Q
  STO R
  ; P=A*B*x
  RCL A
  RCL B
  *
  STO* P
  ; Q=A*C*x
  RCL A
  RCL C
  *
  STO* Q
  ; Q=B*C*x
  RCL B
  RCL C
  *
  STO* R
  ; view PQR
  0
  RCL P
  RCL Q
  RCL R
  VIEW P
  VIEW Q
  VIEW R

RTN
ENDS

END start
; CK=9506
; LN=289
