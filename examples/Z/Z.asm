; Formulary for the exam of a german radio license
; 18. Characteristic impedance
;
MODEL P35S

SEGMENT DATA
  eqnMenu EQU '1HF 2SW 3CO 4\Gl4'
ENDS

SEGMENT CODE
start:
LBL Z       ; program Z

init:
  RPN       ; mode RPN

menu:
  ; display [eqnMenu]
  SF 10
    eqn eqnMenu
  CF 10
  ; IF y=1 THEN GOTO '1'
  1
  x=y?
    GTO read1
  Rv
  ; IF y=2 THEN GOTO '2'
  2
  x=y?
    GTO read2
  Rv
  ; IF y=3 THEN GOTO '3'
  3
  x=y?
    GTO read3
  Rv
  ; IF y=4 THEN GOTO '4'
  4
  x=y?
    GTO read4
  Rv
STOP

; 18.1. Higher frequencies on cables
;
; LINE | DATA | OPERATIONS  | DISPLAY | REMARKS
; -----+------+-------------+---------+-----------------------------
; 1    | L    | ENTER       |         | Inductance for short circuit
; 2    | C    | /           | L/C     | Capacity for open circuit
; 3    |      | \v/         | Z       | Characteristic impedance
;
read1:
  INPUT L   ; inductance L per unit length
  INPUT C   ; capacitance C per unit length
calc1:
  ; Z=SQRT(L/C)
  /
  sqrt
  GTO write

; 18.2. Coaxial cable
;
; LINE | DATA | OPERATIONS  | DISPLAY | REMARKS
; -----+------+-------------+---------+----------------------------
; 1    |      | 6 0         | 60      | Constant approximate value
; 2    | e    |             | e       | Relative permittivity
; 3    |      | \v/ /       |         | divide as square root value
; 4    | D    | ENTER       |         | Outer diameter ...
; 5    | d    | /           | D/d     | ... to inner diameter ratio
; 6    |      | \<+ LN *    | Z       | Characteristic impedance
read2:
  INPUT E   ; Relative permittivity e
  INPUT A   ; Outer diameter D
  INPUT D   ; Inner diameter d
calc2:
  ; Z=Z0/(2*PI*SQRT(E))*LN(A/D)
  /
  LN
  Z0
  *
  pi
  ENTER
  +
  /
  x<>y
  sqrt
  /
  GTO write

; 18.3. Symmetrical two-wire lines
;
; LINE | DATA | OPERATIONS         | DISPLAY | REMARKS
; -----+------+--------------------+---------+----------------------------
; 1    |      | 1 2 0              | 120     | Constant approximate value
; 2    | e    |                    | e       | Relative permittivity
; 3    |      | \v/ /              |         | divide as square root value
; 4    | a    | ENTER              |         | Distance ...
; 5    | d    | /                  | a/d     | ... to diameter ratio
; 6    |      | \<+ HYP \+> ACOS * | Z       | Characteristic impedance
;
read3:
  INPUT E   ; Relative permittivity e
  INPUT A   ; Center distance of the wires a
  INPUT D   ; Wire diameter d
calc3:
  ; Z=120/SQRT(E)*ACOSH(A/D)
  /
  ACOSH
  120
  *
  x<>y
  sqrt
  /
  GTO write

; 18.4. Quarter-wave transformer
;
; LINE | DATA | OPERATIONS  | DISPLAY | REMARKS
; -----+------+--------------------+---------+----------------------------
; 1    | E    | ENTER       |         | Inductance for short circuit
; 2    | A    | *           | E*A     | Geometric mean of ...
; 3    |      | \v/         | Z       | ... both measured values
read4:
  INPUT E   ; AC resistance of the short-circuited line
  INPUT A   ; AC resistance of the open line
calc4:
  ; Z=SQRT(E*A)
  *
  sqrt

print:
  STO   Z
  VIEW  Z   ; Show surge impedance Z

RTN
ENDS

END
