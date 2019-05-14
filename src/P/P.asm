; Electric power P
MODEL P35S
SEGMENT DATA
  eqnMenu EQU '1P 2V 3I 4R'
ENDS

SEGMENT CODE
start:
LBL P                 ; program P

init:
  RPN                 ; mode RPN

menu:
  ; display [eqnMenu]
  SF 10
    EQN eqnMenu
  CF 10
  ; IF y=1 THEN GOTO 'P='
  1
  x=y?
    GTO calcP
  Rv
  ; IF y=2 THEN GOTO 'V='
  2
  x=y?
    GTO calcV
  Rv
  ; IF y=3 THEN GOTO 'I='
  3
  x=y?
    GTO calcI
  Rv
  ; IF y=4 THEN GOTO 'R='
  4
  x=y?
    GTO calcR
  Rv
STOP

; P=
calcP:
  INPUT V
  ; IF V=0 THEN GOTO 'P=I^2*R'
  x=0?
    GTO inputI4P
  INPUT I
  ; IF I=0 THEN GOTO 'P=V^2/R'
  x=0?
    GTO inputR
  ; P=V*I
  *
GTO displayP

inputI4P:
  ; P=I^2*R
  INPUT I
  x^2
  INPUT R
  *
GTO displayP

inputR:
  ; P=V^2/R
  INPUT R
  ; IF R<=0 THEN GOTO 'P=V^2/R'
  x<=0?
    GTO displayP
  1/x
  RCL* V
  RCL* V

displayP:
  STO P
  VIEW P
RTN

; V=
calcV:
  INPUT P
  INPUT R
  ; V=SQRT(P*R)
  *
  sqrt                ; \v/x
  ; display V
  STO V
  VIEW V
RTN

; I=
calcI:
  INPUT P
  INPUT R
  ; IF R<=0 THEN GOTO 'input I='
  x<=0?
    GTO calcI
  ; I=SQRT(P/R)
  /                   ; \:-
  sqrt                ; \v/x
  ; display I
  STO  I
  VIEW I
RTN

; R=
calcR:
  INPUT P
  ; IF P<=0 THEN GOTO 'R='
  x<=0?
    GTO calcR
  INPUT V
  ; IF V=0 THEN GOTO 'R=P/I^2'
  x=0?
    GTO inputI4R
  ; R=V^2/P
  x^2
  RCL/ P
GTO displayR

inputI4R:
  ; R=P/I^2
  INPUT I
  ; IF I<=0 THEN GOTO 'R=P/I^2'
  x<=0?
    GTO inputI4R
  x^2
  1/x
  RCL* P

displayR:
  STO R
  VIEW R

RTN
ENDS

END
; CK=1AAF
; LN=249
