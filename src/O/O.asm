TITLE Ohms Law
MODEL 35S
CODESEG
start:
LBL O           ; \Rsh LBL O

init:
  RPN           ; MODE 5RPN

input:
  ; input R, V and I
  INPUT R       ; \Lsh INPUT R
  ; IF R=0 THEN GOTO 'R=V/I'
  x=0?          ; \Rsh x?0 6
    GTO calcR   ; GTO RCL 'calcR'
  INPUT V       ; \Lsh INPUT V
  ; IF V=0 THEN GOTO 'V=R*I'
  x=0?          ; \Rsh x?0 6
    GTO calcV   ; GTO RCL 'calcV'

calcI:
  ; I=V/R
  RCL/ R        ; RCL \div R
  ; display I
  STO I         ; \Rsh STO I
  VIEW I        ; \Lsh VIEW I
RTN             ; \Lsh RTN

calcR:
  ; R=V/I
  INPUT V       ; \Lsh INPUT V
  INPUT I       ; \Lsh INPUT I
  /             ; \div
  ; display R
  STO R         ; \Rsh STO R
  VIEW R        ; \Lsh VIEW R
RTN             ; \Lsh RTN

calcV:
  ; V=R*I
  INPUT I       ; \Lsh INPUT I
  RCL* R        ; RCL \times R
  ; display V
  STO V         ; \Rsh STO V
  VIEW V        ; \Lsh VIEW V

RTN             ; \Lsh RTN 
end start       ; \C
; CK=9CCF
; LN=69
