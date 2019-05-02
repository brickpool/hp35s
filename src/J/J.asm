; Current density J
MODEL P35S
SEGMENT CODE

LBL J               ; \Rsh LBL J

init:
  RPN               ; MODE 5RPN

read:
  ; input I and A
  INPUT I           ; \Lsh INPUT I
  INPUT A           ; \Lsh INPUT A

calc:
  ; J=I/A
  /                 ; \div

print:
  STO J             ; \Rsh STO J
  VIEW J            ; \Lsh VIEW J

RTN                 ; \Lsh RTN
ENDS
END                 ; \C
; CK=A84A
; LN=24
