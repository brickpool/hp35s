; Barry Moore, April 10, 2016
; Program to convert a Complex number to polar and then Rectangular parts
; http://www.stefanv.com/calculators/hp35s.html#programming
MODEL P35S

SEGMENT CODE
LBL R
  ARG
  LASTx
  ABS
  STOP
  x<>y
  COS
  LASTx
  SIN
  Rv
  Rv
  x<>y
  Rv
  *
  x<>y
  LASTx
  *
RTN
ENDS

END
