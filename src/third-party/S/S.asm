; Length of Sunlight During a Day
; This program is by Edward Shore and is used here by permission.
; http://edspi31415.blogspot.com/2013/05/hp-35s-approximate-length-of-sunlight.html
MODEL P35S

SEGMENT CODE
LBL S
  DEG
  INPUT D
  0.9856
  *
  SIN
  23.45
  *
  INPUT L
  HMS->
  TAN
  x<>y
  TAN
  *
  +/-
  ACOS
  ->RAD
  24
  *
  pi
  /
  ->HMS
RTN

ENDS

END
