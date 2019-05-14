; Ohms Law
MODEL P35S
SEGMENT CODE
start:
LBL O           ; program O

init:
  RPN           ; mode RPN

read:
  ; input R, V and I
  INPUT R
  ; IF R=0 THEN GOTO 'R=V/I'
  x=0?
    GTO calcR
  INPUT V
  ; IF V=0 THEN GOTO 'V=R*I'
  x=0?
    GTO calcV

calcI:
  ; I=V/R
  RCL/ R
  ; display I
  STO I
  VIEW I
RTN

calcR:
  ; R=V/I
  INPUT V
  INPUT I
  /             ; \:-
  ; display R
  STO R
  VIEW R
RTN

calcV:
  ; V=R*I
  INPUT I
  RCL* R
  ; display V
  STO V
  VIEW V
RTN
ENDS

END
; CK=9CCF
; LN=69
