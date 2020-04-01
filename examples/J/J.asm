; Current density J
MODEL P35S
SEGMENT CODE
start:
LBL J               ; program J

init:
  RPN               ; mode 5RPN

read:
  ; input I and A
  INPUT I
  INPUT A

calc:
  ; J=I/A
  /                 ; \:-

print:
  STO J
  VIEW J

RTN
ENDS

END
; CK=A84A
; LN=24
