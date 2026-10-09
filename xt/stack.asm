; Ported to HP-35s
;
; Tricks, tips, and routines for HP-41 series calculators
; Chapter 7
; Working with the stack
MODEL P35S

SEGMENT Stapel CODE


; 7-1 Using X to operate on REGX
; -----------------------
; Source: Valentin Albillo (4747).
; All tips below use variable 'X' as temporary storage for register REGX.
LBL B
  ; 'STO+ X' (with 'STO X, x<> X') doubles REGX. It is no faster on the
  ; HP-35s than '2, *', but uses 32 fewer bytes and leaves the rest of the
  ; stack unchanged.
  STO X
  STO+ X
  x<> X
RTN

LBL D
  ; 'STO- X' (with 'STO X, x<> X') acts like 'CLx', but causes a stack lift
  ; on the next entry; on the HP-35s, it uses 6 more bytes.
  STO X
  STO- X
  x<> X
RTN

LBL E
  ; 'STO* X' (with 'STO X, x<> X') acts like "eqn 'REGX^2'" and uses
  ; 29 fewer bytes on the HP-35s, but changes X.
  STO X
  STO* X
  x<> X
RTN

LBL F
  ; 'STO/ X' (with 'STO X, x<> X') replaces REGX with '1' (as long as
  ; REGX <> 0) and leaves the rest of the stack unchanged, but uses 6 more
  ; bytes on the HP-35s.
  STO X
  STO/ X
  x<> X
RTN


; 7-2 Multiply/divide X by a constant when a flag is clear
; -------------------------------------------------------
; Source: Joseph Horn (1537) (PPC CJ, V7N4P13).
LBL G
  ; Good solution:
  FS? 0
    GTO @14
  5
  *             ; oder /
@14:
RTN

LBL H
  ; Better solution:
  ; (For the HP-41, not the HP-35s: uses 3 more bytes.)
  5
  FS? 0         ; FC? 00, *
    GTO @00
    *           ; oder /
    @00:
  FS? 0
    Rv
RTN

LBL I
  ; Best solution:
  ; (The last solution, limited to positive constants.)
  5
  FS? 0
    SGN
  *             ; oder /
RTN


; 7-3 REGX-REGY in X without changing Y
; ---------------------------------------------------------
LBL J
  ; (a) '%CHG, %'; rounding errors are possible.
  %CHG
  %
RTN

LBL K
  ; (b) 'RCL Y, -'; the contents of REGT are lost.
  ; (This uses 35 more bytes on the HP-35s than variant a.)
  eqn 'REGY'
  -
RTN


; 7-4 eqn REGX, REGY, REGZ, or REGT
; ----------------------------------
; Each of the four functions uses 38 bytes on the HP-35s.
LBL L
  ; "eqn 'REGX'" acts like 'ENTER' (XYZT => XXYZ), but the stack lifts on
  ; the next entry.
  eqn 'REGX'
  STOP
  ; "eqn 'REGY'" acts like 'x<>y' (XYZT => YXYZ), but REGT is lost.
  eqn 'REGY'
  STOP
  ; "eqn 'REGZ'" (XYZT => ZXYZ) also clears REGT.
  eqn 'REGZ'
  STOP
  ; "eqn 'REGT'" acts like 'R^' (XYZT => TXYZ), except after 'ENTER' or
  ; 'CLx', which overwrite REGX. See also 7-11.
  eqn 'REGT'
RTN


; 7-5 Change REGX to '1' without affecting the stack
; ----------------------------------------------------------------------
; Source: PPC Melbourne Chapter.
LBL N
  ; 'STO X, STO/ X, x<> X' works for every number except '0', but replaces
  ; variable X with the result of 'STO/ X'. See also 7-1.
  STO X
  STO/ X
  x<> X
RTN

LBL O
  ; 'SGN, ABS' changes any nonzero number to '1', does not use X, and uses
  ; 3 fewer bytes on the HP-35s.
  SGN
  ABS
RTN

; Supplement: J. Schneider
LBL P
  ; 'CLx COS' generates '1' in REGX without affecting the rest of the stack.
  CLx
  COS
RTN


; 7-6 Divide REGX and REGY by 10
; -------------------------------------
LBL Q
  ; Ordinary:
  10
  /
  x<>y
  LASTx
  /
  x<>y
RTN

LBL U
  ; Elegant: (not for the HP-35s; uses 9 more bytes and the listing is longer.)
  10
  ; STO/ Z
    STO Z
    Rv
    Rv
    RCL/ Z
    STO Z
    Rv
    Rv
  /
RTN


; 7-7 Stack analysis ("SA")
; -------------------------
; The "SA" routine can show the effect of another routine on the stack.
; First run 'XEQ A', then execute the routine to test (e.g.
; 'LASTX, STO T, x<>y'). Then view the stack with 'VIEW X, Y, Z, T'.
; On the HP-35s, "SA" uses variables X, Y, Z, and T. See also 7-11.
LBL A
  R^
  STO T
  R^
  STO Z
  R^
  STO Y
  R^
  STO X
RTN
; LN=30


; 7-8 Automatically view the stack ("ST")
; --------------------------------------------
; Run 'XEQ T' at any time to view the contents of the stack.
; On the HP-35s, "ST" uses variables temporarily.
LBL T
  x<> X
  VIEW X
  PSE
  x<> X
  Rv
  x<> Y
  VIEW Y
  PSE
  x<> Y
  Rv
  x<> Z
  VIEW Z
  PSE
  x<> Z
  Rv
  x<> T
  VIEW T
  PSE
  x<> T
  Rv
RTN
; LN=66
;
; - Source: Bruce Clark (5795).


; 7-9 Stack exchange, store, and recall ("STX", "STS" & "STR")
; -----------------------------------------------------------------
; "STX" (called with 'XEQ X') swaps REGX, REGY, REGZ, and REGT with
; variables (-24)..(-26) and (-20).
; "STS" (called with 'XEQ S') stores REGX through REGT in (-24)..(-26)
; and (-20).
; "STR" (called with 'XEQ R') recalls values from those variables into
; REGX through REGT.
LBL X
  x<> X
  Rv
  x<> Y
  Rv
  x<> Z
  Rv
  x<> T
  Rv
RTN
; LN=30
LBL S
  STO X
  Rv
  STO Y
  Rv
  STO Z
  Rv
  STO T
  Rv
RTN
; LN=30
LBL R
  RCL T
  RCL Z
  RCL Y
  RCL X
RTN
; LN=18
;
; - Source: Bill Carter (2998) (PPC CJ, V7N7P15).


; 7-10 Indirectly store and recall the stack ("SM" & "MS")
; ----------------------------------------------------------------------
; "SM" (called with 'XEQ M') stores the stack contents (X, Y, Z, and T) in
; the four-variable block specified by the value in (1)..(4). The stack
; contents are lost, but can be restored by the following "MS" routine.
; "MS" (called with 'XEQ W') recalls the four-variable block specified by
; the value in (1)..(4) to the stack in X, Y, Z, T order. In particular,
; "MS" can be called after a preceding "SM".
LBL M
  STO I
  CLx
  !
  x<> I
  XEQ @C        ; REGX, STO (1)
  XEQ @C        ; REGY, STO (2)
  XEQ @C        ; REGZ, STO (3)
  XEQ @C        ; REGT, STO (4)
RTN
; LN=30
@C:
LBL C
  STO (I)
  CLx
  !
  STO+ I
  STO (I)
  Rv
RTN
; LN=24
LBL W
  pi
  ->KM
  IP
  STO I         ; I = 5.000
  DSE I
  RCL (I)       ; RCL (4), REGT
  DSE I
  RCL (I)       ; RCL (3), REGZ
  DSE I
  RCL (I)       ; RCL (2), REGY
  DSE I
  RCL (I)       ; RCL (1), REGX
RTN
; LN=42
;
; - Source: PPC CJ, V7N10P7 (PPC ROM).


; 7-11 Stack rearrangements ("STACK")
; ---------------------------------
; This routine can show the effect of different combinations of stack
; functions ('x<>y', 'ENTER', 'Rv', etc.). 'XEQ V' displays "X-Y-Z-T" and
; fills the stack registers with their names. Then call the stack functions.
; 'R/S' displays their effect (e.g. "YXZT" after 'x<>y'). Press 'R/S' to
; start over.
; - Source: John Dearing (2791). See also 7-7.
;
; "Mode 1": not possible on the HP-35s.
;
; "Mode 2": To trace the stack effect one step at a time, replace line V043
; ('RTN') with 'GTO V001'. After each command in a sequence of stack
; functions, press 'R/S' to view the new arrangement.
; The following table shows ways to rearrange the stack using 'R^', 'Rv',
; 'ENTER', and 'x<>y'. In most cases, several sequences are possible.
; Usually choose the one with the fewest keystrokes, e.g. 'Rv, Rv' (2 keys)
; instead of 'R^, R^' (4 keys).
;
; --------------------------------
; XYZT  (starting order)
; YXZT  x<>y
; ZYXT  x<>y, Rv, Rv, x<>y, Rv
; TXYZ  R^
; --------------------------------
; XYTZ  Rv, Rv, x<>y, Rv, Rv
; YXTZ  x<>y, Rv, Rv, x<>y, Rv, Rv
; ZXTY  x<>y, Rv, x<>y
; TXZY  Rv, x<>y, Rv, Rv
; --------------------------------
; XZYT  Rv, x<>y, R^
; YZXT  R^, x<>y, Rv, Rv
; ZXYT  Rv, Rv, x<>y, Rv
; TYXZ  x<>y, R^
; --------------------------------
; XZTY  x<>y, Rv
; YZTX  Rv
; ZYTX  Rv, x<>y
; TYZX  R^, x<>y, Rv
; --------------------------------
; XTYZ  R^, x<>y
; YTXZ  Rv, x<>y, Rv
; ZTXY  Rv, Rv
; XTZY  x<>y, Rv, Rv, x<>y, R^
; --------------------------------
; TZXY  Rv, Rv, x<>y
; YTZX  Rv, Rv, x<>y, R^
; ZTYX  x<>y, Rv, Rv
; TZYX  x<>y, Rv, Rv, x<>y
; --------------------------------

LBL V
  ; "X", ASTO X, "Y", ASTO Y, ..., ASTO T
  STO X
  Rv
  STO Y
  Rv
  STO Z
  Rv
  STO T
  Rv
  ; "X-Y-Z-T", PROMPT
  VIEW X
  PSE
  VIEW Y
  PSE
  VIEW Z
  PSE
  VIEW T
  PSE
  ; CLA
  -20
  -26
  -25
  -24
  STOP
  ; ARCL X, ..., AVIEW
  STO I
  VIEW (I)
  x<> (I)
  PSE
  Rv
  STO I
  VIEW (I)
  x<> (I)
  PSE
  Rv
  STO I
  VIEW (I)
  x<> (I)
  PSE
  Rv
  STO I
  VIEW (I)
  x<> (I)
  PSE
  Rv
RTN
; (269 Bytes)
; LN=141


; 7-12 REGX*REGY or REGX+REGY without changing 'REGX,REGZ,REGT'
; -------------------------------------------------------------------
; '* (or +) LASTx, Rv' multiplies (or adds) REGX and REGY without changing
; REGX, REGZ, or REGT. Of limited use compared with the HP-41, since the
; HP-35s has no L register, which the HP-41 can use for counters.
; - Source: Kiyoshi Akima (3456).
LBL Y
  *             ; +
  LASTx
  Rv
RTN
; without LBL and Y
; LN=9
; (9 Bytes)
;
; with LBL and RTN
; LN=15
; (15 Bytes)

ENDS Stapel

END
