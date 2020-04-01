; Find the nearest fraction in the E24 numbers for the HP-35s
; This program is by Takayuki Hosoda and is used here by permission.
; http://www.finetune.co.jp/~lyuka/technote/e24/e24-35s.html
MODEL P35S

SEGMENT E24 CODE

@001:

LBL E
  STO X         ; X = REGX
  ; I = 23
  23
  STO I
  ; R23 = 9.1
  9.1
  STO(I)
  DSE I
  ; R22 = 8.2
  8.2
  STO(I)
  DSE I
  7.5
  STO(I)
  DSE I
  6.8
  STO(I)
  DSE I
  6.2
  STO(I)
  DSE I
  5.6
  STO(I)
  DSE I
  5.1
  STO(I)
  DSE I
  4.7
  STO(I)
  DSE I
  4.3
  STO(I)
  DSE I
  3.9
  STO(I)
  DSE I
  3.6
  STO(I)
  DSE I
  3.3
  STO(I)
  DSE I
  3.0
  STO(I)
  DSE I
  2.7
  STO(I)
  DSE I
  2.4
  STO(I)
  DSE I
  2.2
  STO(I)
  DSE I
  2.0
  STO(I)
  DSE I
  1.8
  STO(I)
  DSE I
  1.6
  STO(I)
  DSE I
  1.5
  STO(I)
  DSE I
  1.3
  STO(I)
  DSE I
  1.2
  STO(I)
  DSE I
  ; R01 = 1.1
  1.1
  STO(I)
  DSE I
  2007.0810     ; NOP, V2007-08-10
  ; R00 = 1.0
  1.0
  STO(I)
  ; P = 0.05
  0.05
  STO P
  ; Q = K = 0
  CLx
  STO Q
  STO K

@082:
  RCL X
  ENTER
  LOG
  INTG
  10^x
  STO X
  /
  STO N

  ; DO I = 23, 0, -1
  23
  STO I
  @092:
    RCL N
    RCL(I)
    x<y?
      GTO @098
  ; CONTINUE
  DSE I
    GTO @092
  ; END

@098:
  ; K = I
  RCL I
  STO K

  ; DO J = 23, 0, -1
  23
  STO J
  @102:
    1
    XEQ @118    ; CALL E118
    CLx
    XEQ @118    ; CALL E118
  ; CONTINUE
  DSE J
    GTO @102
  ; END

  1
  XEQ @118      ; CALL E118
  CLx
  XEQ @118      ; CALL E118
  RCL N
  RCL* X
  RCL Q
  RCL R
  <-ENG
RTN

; SUBROUTINE E118
@118:
  RCL+ J
  RCL+ K

  ; IF (24 > REGY)
  24
  x<=y?
    GTO @124
  ; THEN
  GTO @128

    @124:
    -
    STO I
    10
    GTO @131
  ; ELSE
  @128:
    Rv
    STO I
    1
  @131:
  ; END IF

  RCL*(I)
  STO S
  1/x
  RCL*(J)
  RCL* N
  1
  -
  ABS
  RCL P
  x<y?
    RTN
  
  Rv
  STO P
  RCL R
  STO Q
  eqn '[S*X,(J),P]'
  STO R
  PSE
RTN

ENDS E24

END
; CK=8B33
; LN=557
