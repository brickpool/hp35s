; Day of the week for any date since September 14, 1752
MODEL P35S

SEGMENT CODE
LBL W           ; program W
  ; REGZ = dd
  ; REGY = mm
  ; REGX = yyyy

  STO A         ; A = y
  Rv

  ; f = IP(1/REGX+0.5)
  ENTER         
  1/x
  0.5
  +
  IP            ; REGX is 1 if January or February, otherwise 0
  
  STO- A        ; A = y - REGX
  12
  *
  +             ; if January or February then REGX = m+12 else REGX = m+0

  ; n1 = IP(13/5*(m+1))
  1
  +             ; REGX = m + 1
  ; 
  2.6
  *
  IP            ; REGY = d, REGX = n1

  +
  x<> A         ; A = d + n1, REGX = y

  ; n2 = IP(5/4*y)
  ENTER
  ENTER
  ENTER
  1.25
  *
  IP            ; REGX = n2
  STO+ A        ; A = d + n1 + n2

  ; n3 = IP(y/100)
  Rv
  100
  /
  IP            ; REGX = n3
  STO- A        ; A = d + n1 + n2 - n3

  ; n4 = IP(y/400)
  Rv
  400
  /
  IP            ; REGX = n4

  RCL+ A        ; REGX = d + n1 + n2 - n3 + n4
  7
  RMDR          ; REGX = (d + n1 + n2 - n3 + n4) mod 7
  ; REGX = w
RTN

ENDS

END
