TITLE Current density J
MODEL 35S
CODESEG

start:
LBL J               ; \Rsh LBL J

init:
  RPN               ; MODE 5RPN

input:
  ; input I and A
  INPUT I           ; \Lsh INPUT I
  INPUT A           ; \Lsh INPUT A

calc:
  ; J=I/A
  /                 ; \div

display:
  STO J             ; \Rsh STO J
  VIEW J            ; \Lsh VIEW J

RTN                 ; \Lsh RTN
end start           ; \C
; CK=A84A
; LN=24
