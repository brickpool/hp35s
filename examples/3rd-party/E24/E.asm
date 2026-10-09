; Find the nearest fraction in the E24 numbers for the HP-35s
; This program is by Takayuki Hosoda and is used here by permission.
; http://www.finetune.co.jp/~lyuka/technote/e24/e24-35s.html
MACRO E24ENTRY value
  value
  STO(I)
  DSE I
ENDM

MACRO E24SCAN found
  LOCAL again
  23
  STO I
again:
  RCL N
  RCL(I)
  x<y?
    GTO found
  DSE I
    GTO again
ENDM

MODEL P35S

SEGMENT E24 CODE

@001:

LBL E
  STO X         ; X = REGX
  ; I = 23
  23
  STO I
  ; R23 = 9.1
  E24ENTRY 9.1
  ; R22 = 8.2
  E24ENTRY 8.2
  E24ENTRY 7.5
  E24ENTRY 6.8
  E24ENTRY 6.2
  E24ENTRY 5.6
  E24ENTRY 5.1
  E24ENTRY 4.7
  E24ENTRY 4.3
  E24ENTRY 3.9
  E24ENTRY 3.6
  E24ENTRY 3.3
  E24ENTRY 3.0
  E24ENTRY 2.7
  E24ENTRY 2.4
  E24ENTRY 2.2
  E24ENTRY 2.0
  E24ENTRY 1.8
  E24ENTRY 1.6
  E24ENTRY 1.5
  E24ENTRY 1.3
  E24ENTRY 1.2
  ; R01 = 1.1
  E24ENTRY 1.1
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
  E24SCAN @098

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
