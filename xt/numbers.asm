MODEL P35S

SEGMENT numbers CODE

LBL A
  ; -27
  pi
  ->°C
  ->°C
  INTG
  XEQ VIEW_X

  ; -26
  pi
  ->°C
  ->°C
  IP
  XEQ VIEW_X

  ; -25
  g             ; Standard acceleration of gravity
  ->CM
  +/-
  INTG
  XEQ VIEW_X

  ; -24
  g             ; Standard acceleration of gravity
  ->CM
  +/-
  IP
  XEQ VIEW_X

  ; -23
  pi
  e^x
  +/-
  IP
  XEQ VIEW_X

  ; 22
  g             ; Standard acceleration of gravity
  ->LB
  +/-
  INTG
  XEQ VIEW_X

  ; -21
  g             ; Standard acceleration of gravity
  ->LB
  +/-
  IP
  XEQ VIEW_X

  ; -20
  pi
  +/-
  ->°C
  INTG
  XEQ VIEW_X

  ; -19
  pi
  +/-
  ->°C
  IP
  XEQ VIEW_X

  ; -18
  Vm            ; Molar volume of ideal gas
  ->°C
  INTG
  XEQ VIEW_X

  ; -17
  Vm            ; Molar volume of ideal gas
  ->°C
  IP
  XEQ VIEW_X

  ; -16
  pi
  ->°C
  IP
  XEQ VIEW_X

  ; -15
  g             ; Standard acceleration of gravity
  ->KM
  +/-
  IP
  XEQ VIEW_X

  ; -14
  R             ; Molar gas constant
  ->°C
  INTG
  XEQ VIEW_X

  ; -13
  R             ; Molar gas constant
  ->°C
  IP
  XEQ VIEW_X

  ; -12
  g             ; Standard acceleration of gravity
  ->°C
  IP
  XEQ VIEW_X

  ; -11
  pi
  ->L
  +/-
  IP
  XEQ VIEW_X

  ; -10
  g             ; Standard acceleration of gravity
  +/-
  INTG
  XEQ VIEW_X

  ; -9
  g             ; Standard acceleration of gravity
  +/-
  IP
  XEQ VIEW_X

  ; -8
  R             ; Molar gas constant
  +/-
  IP
  XEQ VIEW_X
  
  ; -7
  pi
  !
  +/-
  IP
  XEQ VIEW_X

  ; -6
  pi
  ->LB
  +/-
  IP
  XEQ VIEW_X
  
  ; -5
  pi
  ->KM
  +/-
  IP
  XEQ VIEW_X

  ; -4
  pi
  +/-
  INTG
  XEQ VIEW_X
  
  ; -3
  pi
  +/-
  IP
  XEQ VIEW_X

  ; -2
  pi
  SGN
  NOT
  XEQ VIEW_X

  ; -1
  ue            ; Electron magnetic moment
  SGN
  XEQ VIEW_X

  ; 0
  ENTER
  CLx
  XEQ VIEW_X
  
  ; 1
  pi
  SGN
  XEQ VIEW_X
  
  ; 2
  e             ; natural constant
  IP
  XEQ VIEW_X
  
  ; 3
  pi
  IP
  XEQ VIEW_X
  
  ; 4
  e             ; natural constant
  ->KM
  IP
  XEQ VIEW_X
  
  ; 5
  pi
  ->KM
  IP
  XEQ VIEW_X
  
  ; 6
  pi
  ->LB
  IP
  XEQ VIEW_X
  
  ; 7
  pi
  !
  IP
  XEQ VIEW_X
  
  ; 8
  R             ; Molar gas constant
  IP
  XEQ VIEW_X
  
  ; 9
  g             ; Standard acceleration of gravity
  IP
  XEQ VIEW_X
  
  ; 10
  pi
  SGN
  10^x
  XEQ VIEW_X

  ; 11
  pi
  ->L
  IP
  XEQ VIEW_X

  ; 12
  pi
  ->CM
  ->KM
  IP
  XEQ VIEW_X

  ; 13
  R             ; Molar gas constant
  ->KM
  IP
  XEQ VIEW_X

  ; 14
  g             ; Standard acceleration of gravity
  +/-
  ->°F
  IP
  XEQ VIEW_X

  ; 15
  g             ; Standard acceleration of gravity
  ->KM
  IP
  XEQ VIEW_X

  ; 16
  t             ; Celsius temperature
  sqrt
  IP
  XEQ VIEW_X

  ; 17
  e             ; natural constant
  ->CM
  ->CM
  IP
  XEQ VIEW_X

  ; 18
  R             ; Molar gas constant
  ->LB
  IP
  XEQ VIEW_X

  ; 19
  Z0            ; Characteristic impendence of vacuum
  sqrt
  IP
  XEQ VIEW_X

  ; 20
  pi
  ->CM
  ->CM
  IP
  XEQ VIEW_X

  ; 21
  g             ; Standard acceleration of gravity
  ->LB
  IP
  XEQ VIEW_X

  ; 22
  pi
  ATAN
  ->°C
  IP
  XEQ VIEW_X

  ; 23
  pi
  e^x
  IP
  XEQ VIEW_X

  ; 24
  g             ; Standard acceleration of gravity
  ->CM
  IP
  XEQ VIEW_X

  ; 25
  pi
  ->KM
  x^2
  IP
  XEQ VIEW_X

  ; 26
  pi
  +/-
  ->°F
  IP
  XEQ VIEW_X

  ; 27
  C2            ; Second radiation constant
  1/x
  ->IN
  IP
  XEQ VIEW_X

  ; 0.1
  pi
  SGN
  10^x
  1/x
  XEQ VIEW_X

  ; 0.01
  e
  IP
  10^x
  1/x
  XEQ VIEW_X

  ; 0.001
  pi
  IP
  10^x
  1/x
  XEQ VIEW_X

  ; 0.0001
  pi
  SGN
  ENTER
  %
  %
  XEQ VIEW_X
RTN

VIEW_X:
  STO X
  VIEW X
RTN

ENDS numbers

END
