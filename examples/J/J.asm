; Current density J
IDEAL
P35S
MODEL TINY
CODESEG
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

END
; CK=A84A
; LN=24
