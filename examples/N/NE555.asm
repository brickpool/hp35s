; General purpose single bipolar timer IC NE555
MODEL P35S

SEGMENT NE555 CODE
start:
LBL N           ; program N

;
; main
;
init:
  RPN           ; mode RPN

  ; STO (1) = 0.693
  CLZ           ; n = 0
  Z+            ; n = 1; LET REGX = n
  STO I         ; LET I = 1
  Z+            ; n = 2; LET REGX = n
  LN            ; LET REGX = ln(2)
  STO (I)       ; LET (1) = 0.693

  ; STO (0) = 1.099
  CLx
  STO I         ; LET I = 0
  Z+            ; n = 3; LET REGX = n
  LN            ; LET REGX = ln(3)
  STO (I)       ; LET (0) = 1.099

  ; STO I = 1
  CLZ           ; n = 0
  Z+            ; n = 1; LET REGX = n
  STO I         ; LET I = 1

  FS? 0         ; IF (NOT "XEQ I001") THEN RTN
    RTN
  
; display main menu
menu:
  SF 10
    eqn '1MONO 2ASTABLE'
  CF 10
  ; IF (REGY = 1) THEN GOTO 'MONO'
  RCL I
  x=y?
    GTO MONO
  ; IF (REGY = 2) THEN GOTO 'ASTABLE'
  RCL+ I
  x=y?
    GTO ASTABLE
  STOP
GTO MONO

;
; sub INPUT ...
;
INPUT_R1:
  SF 10
    eqn 'R1\|>A'
    PSE
  CF 10
  INPUT A
RTN

INPUT_R2:
  SF 10
    eqn 'R2\|>B'
    PSE
  CF 10
  INPUT B
RTN

INPUT_T1:
  SF 10
    eqn 'T+\|>P'
    PSE
  CF 10
  INPUT P
RTN

INPUT_T2:
  SF 10
    eqn 'T-\|>M'
    PSE
  CF 10
  INPUT M
RTN

INPUT_D:
  SF 10
    eqn 'R2+D PUSH Y'
  CF 10
  ; IF (REGY = 2) THEN LET FLAG4 = 1
  RCL I
  RCL+ I
  x=y?
    SF 4
  ; IF (FLAG4 <> 0) THEN Rv
  FS? 4
    Rv
  Rv
RTN

;
; sub VIEW ...
;
VIEW_R:
  SF 10
    eqn '[R1,R2]'
    PSE
  CF 10
  eqn '[A,B]'
  x<> R
  VIEW R
  x<> R
RTN

VIEW_T:
  SF 10
    eqn '[T+,T-]'
    PSE
  CF 10
  eqn '[P,M]'
  x<> T
  VIEW T
  x<> T
RTN

VIEW_D:
  SF 10
    eqn 'R2+DIODE'
    PSE
  CF 10
RTN

;
; monostable operation
;
LBL A           ; program A
  SF 0
    XEQ init
  CF 0

MONO:
  CLx
  STO I         ; LET I = 0
  RCL (I)       ; LET REGX = 1.099

  INPUT T
  ; IF (T <= 0) THEN GOTO 'T='
  x<=0?
    GTO solveTM
  INPUT R
  ; IF (I <= 0) THEN GOTO 'R='
  x<=0?
    GTO solveRM

solveCM:
  ; C=T/(1.099*R)
  ;
  ; REGZ = 1.099
  ; REGY = T
  ; REGX = R
  /
  x<>y
  /
  STO C
  VIEW C
RTN

solveRM:
  ; R=T/(1.099*C)
  ;
  ; REGZ = 1.099
  ; REGY = T
  ; REGX = 0
  Rv
  INPUT C
  ; IF (C <= 0) THEN GOTO 'R='
  x<=0?
    GTO solveR
  /
  x<>y
  /
  STO R
  VIEW R
RTN

solveTM:
  ; T=1.099*R*C
  ;
  ; REGY = 1.099
  ; REGX = 0
  Rv
  INPUT R
  INPUT C
  *
  *
  STO T
  VIEW T
RTN

;
; astable operation
;
LBL B           ; program B
  SF 0
    XEQ init
  CF 0

ASTABLE:
  ; display astable operation menu
  SF 10
    eqn '1F 2T 3R 4C'
  CF 10
  ; IF (REGY = 1) THEN GOTO 'F='
  RCL I
  x=y?
    GTO solveF
  ; IF (REGY = 2) THEN GOTO 'T='
  RCL+ I
  x=y?
    GTO solveT
  ; IF (REGY = 3) THEN GOTO 'R='
  RCL+ I
  x=y?
    GTO solveR
  ; IF (REGY = 4) THEN GOTO 'C='
  RCL+ I
  x=y?
    GTO solveC
STOP

solveF:
  XEQ INPUT_R1
  XEQ INPUT_R2
  INPUT C
  ; F=1/(0.693*(R1+2*R2)*C1)
  ;
  ; REGZ = A
  ; REGY = B
  ; REGX = C
  RCL* (I)
  RCL B
  Rv
  Rv
  +
  +
  *
  ; IF (REGX = 0) THEN GOTO 'F='
  x=0?
    GTO solveF
  1/x
  STO F
  VIEW F
RTN

solveT:
  XEQ INPUT_R1
  XEQ INPUT_R2
  XEQ INPUT_D
  INPUT C
  ; P=0.693*(A+B)*C
  ; M=0.693*B*C
  ;
  ; REGZ = A
  ; REGY = B
  ; REGX = C
  RCL* (I)
  ENTER
  Rv
  Rv
  ; IF (FLAG4 <> 0)
  FS? 4
    GTO @THEN
    GTO @ELSE
  @THEN:
    Rv
    GTO @END_IF
  @ELSE:
    +
  @END_IF:
  *
  STO P
  x<>y
  RCL* B
  STO M
  XEQ VIEW_T
  FS? 4
    XEQ VIEW_D
  CF 4
  Rv
RTN

solveR:
  XEQ INPUT_T1
  XEQ INPUT_T2
  INPUT C
  ; A=(P-M)/(0.693*C)
  ; B=M/(0.693*C)
  ;
  ; REGZ = P
  ; REGY = M
  ; REGX = C
  RCL* (I)
  ENTER
  Rv
  Rv
  ; IF (t2 >= t1)
  x>=y?
    GTO @@THEN
    GTO @@ELSE
  @@THEN:
    SF 4
    Rv
    GTO @@END_IF
  @@ELSE:
    -
  @@END_IF:
  x<>y
  /
  STO A
  x<>y
  1/x
  RCL* M
  STO B
  XEQ VIEW_R
  FS? 4
    XEQ VIEW_D
  CF 4
  Rv
RTN

solveC:
  INPUT F
  XEQ INPUT_R1
  XEQ INPUT_R2
  ; C1=1/(0.693*(R1+2*R2)*F)
  ;
  ; REGZ = F
  ; REGY = A
  ; REGX = B
  ENTER
  +
  +
  *
  RCL* (I)
  ; IF (REGX = 0) THEN GOTO 'C='
  x=0?
    GTO solveC
  1/x
  STO C
  VIEW C
RTN

ENDS NE555

END
; LBL N: CK=1285, LN=334
; LBL A: CK=E0BD, LN=111
; LBL B: CK=5214, LN=317
