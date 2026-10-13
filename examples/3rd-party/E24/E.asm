; Find the nearest fraction in the E24 numbers for the HP-35s
; This program is by Takayuki Hosoda and is used here by permission.
; http://www.finetune.co.jp/~lyuka/technote/e24/e24-35s.html
MACRO PUSH value
  value
  STO(I)
  DSE I
ENDM

MODEL P35S

SEGMENT E24 CODE

@001:

LBL E
  STO X         ; X = REGX
  ; I = 23
  23
  STO I

  PUSH 9.1      ; R23 = 9.1
  PUSH 8.2      ; R22 = 8.2
  PUSH 7.5      ; R21 = ..
  PUSH 6.8
  PUSH 6.2
  PUSH 5.6
  PUSH 5.1
  PUSH 4.7
  PUSH 4.3
  PUSH 3.9
  PUSH 3.6
  PUSH 3.3
  PUSH 3.0
  PUSH 2.7
  PUSH 2.4
  PUSH 2.2
  PUSH 2.0
  PUSH 1.8
  PUSH 1.6
  PUSH 1.5
  PUSH 1.3      ; ..
  PUSH 1.2      ; R02 = 1.2
  PUSH 1.1      ; R01 = 1.1
  2007.0810     ; NOP, V2007-08-10
  ; R00 = 1.0
  1.0           ; R00 = 1.0
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
  DSE I
    GTO @092

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
