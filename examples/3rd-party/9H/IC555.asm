; Titel: Peripherie-Bauteile des IC NE-555
; Quelle: Eine Programmsammlung fuer den HP-41
; Copyright: 1989, Heldermann Verlag
; Autor: Burkhard Oerttel
; Portierung: J. Schneider
MODEL P35S

SEGMENT IC555 CODE

@TM:            ; LBL "TM"
LBL A
  CF 1
  CF 2
  INPUT T       ; "ZEIT?"
  x=0?
    SF 1
  INPUT R       ; "R?"
  x=0?
    SF 2
  FS? 1
    GTO @18     ; GTO 00
  FS? 2
    GTO @16
  GTO @21       ; GTO 01
@16:
  CLx
@18:            ; LBL 00
  INPUT C       ; "C?"
@21:            ; LBL 01
  1.1
  *
  FS? 1
    GTO @32     ; GTO 01
  /
  FS? 2
    GTO @30
  -3            ; "C"
  GTO @36
@30:
  CF 2
  -18           ; "R"
  GTO @36       ; GTO 10
@32:            ; LBL 01
  CF 1
  *
  -20           ; "T"
@36:            ; LBL 03
  STO I
  Rv
  ENG 3
  STO (I)       ; STO 00
  VIEW (I)      ; ARCL 00
  ALL
  FIX 4
  CF 1
  CF 2
RTN

@OSZ:           ; LBL "OSZ"
LBL B
init:
  0
  STO F         ; frequence: f
  STO P         ; charge time: t1
  STO A         ; resistor Vcc-Pin7: R1
  STO C         ; C_from_fR Pin6-GND: C1
  STO D         ; diode Pin6-Pin7: D1
  CLx
  0.693
  STO T         ; temp. variable
  CF 0          ; charge equal discharge time: t1=t2 (R1=R2, D1||R2)
  CF 1          ; f?
  CF 2          ; T?
  CF 3          ; R?
  CF 4          ; diode Pin6-Pin7: D1

;
; Eingabe
;
input_F:
  ; print "FREQ?"
  SF 10
    eqn 'FREQ\|>F'
    PSE
  CF 10
  ; input "F?", F$
  INPUT F
  ; if (F$ = 0) then 1$ = 1
  x=0?
    SF 1        ; f?

input_T:
  ; print "T+?"
  SF 10
    eqn 'T+\|>P'
    PSE
  CF 10
  ; input "P?", P$
  INPUT P
  SF 2          ; T?
  ; if (P$ <> 0) then goto ...
  x=0?
    GTO input_R
  CF 2
  ; let M$ = P$
  STO M
  ; print "T-?"
  SF 10
    eqn 'T-\|>M'
    PSE
  CF 10
  ; input "M?", M$
  INPUT M
  ; if (P$ = M$) then 0$ = 1
  x=y?
    SF 0        ; t1 is equal t2!
  ; if (P$ > M$) then 4$ = 1
  x>=y?
    SF 4        ; with D1!
  ; if (1$ <> 0) then goto ...

input_R:
  ; print "R1?"
  SF 10
    eqn 'R1\|>A'
    PSE
  CF 10
  ; input "A?", A$
  INPUT A
  ; if (A$ = 0) then goto ...
  SF 3          ; R?
  x=0?          ; R1=0?
    GTO input_C
  CF 3
  ; let B$ = A$
  STO B
  ; if (0$ <> 0) then goto ...
  FS? 0         ; t1=t2?
    GTO input_C
  ; print "R2?"
  SF 10
    eqn 'R2\|>B'
    PSE
  CF 10
  ; input "B?", B$
  INPUT B
  ; if (4$ <> 0) then goto ...
  FS? 4         ; with D1?
    GTO input_C
  ; input "R2+D PUSH Y", REGX
  SF 10
    0
    eqn 'R2+D PUSH Y'
  CF 10
  ; if (REGX = ord(Y))
  2
  -
  x!=0?
    GTO @1_end_if
  ; then
    SF 4        ; with D1!
    Rv
  @1_end_if:
  Rv
    
input_C:
  ; input "C?", C$
  INPUT C
  ; if (C$ <> 0) then goto ...
  x=0?
    GTO C_from_fR
  ; if (3$ <> 0) then goto ...
  FS? 3         ; R=0?
    GTO R_from_TC
  ; if (2$ <> 0) then goto ...
  FS? 2         ; T=0?
    GTO T_from_RC
  ; if (1$ <> 0) then goto ...
  FS? 1         ; f=0?
    GTO f_from_RC

error:
  ; ,
  ; 1/x
  SF 10
    eqn 'DATA ERROR'
  CF 10
  STOP
  RTN

;
; Verarbeitung
;
LBL D
f_from_RC:
T_from_RC:
  ; t2=0.693*R2*C1
  ; t1=0.693*(R1+R2)*C1
  ; with D1: t1=0.693*R1*C1
  ; T=t1+t2
  ; f=1/T
  ;
  ; (REGX = C$)
  STO* T
  RCL T
  RCL* B
  ; let M$ = REGX
  STO M
  RCL T
  RCL A
  ; if (not 4$ <> 0) then let REGX = REGX + B$
  FS? 4
    GTO @2_end_if
    RCL+ B
  @2_end_if:
  *
  ; let P$ = REGX
  STO P
  ; let T$ = REGY + REGX
  +
  STO T
  ; let F$ = 1/T$
  1/x
  STO F
  GTO output_fT

R_from_TC:
  ; R2=t2/(C1*0.693)
  ; R1=(t1-t2)/(C1*0.693)
  ; with D1: R1=t1/(C1*0.693)
  ;
  ; (REGX = C$)
  STO* T
  RCL M
  RCL/ T
  STO B
  RCL P
  ; if (not 4$ <> 0) then let REGX = REGX - M$
  FS? 4
    GTO @3_end_if
    RCL- M
  @3_end_if:
  RCL/ T
  STO A
  GTO output_R

C_from_fR:
  ; C1=1/((R2+R2+R1)*0.693*f)
  ; with D1: C1=1/((R2+R1)*0.693*f)
  ;
  ; (REGY = B$)
  ; (REGX = 0)
  x<>y
  ; if (4$ <> 0) then let REGX = 0 else let REGX = B$
  FS? 4
    x<>y
  RCL+ B
  RCL+ A
  RCL* T
  ; if (1$ <> 0)
  ; then
    ; let F$ = P$ + M$
    RCL P
    RCL+ M
    1/x
    FS? 1
      STO F
    Rv
  ; end if
  RCL* F
  1/x
  STO C
  GTO output_C

;
; Ausgabe
;
output_fT:
  ENG 3
  ; if (1$ <> 0)
  FS? 1
  ; then
    ; print "f="
    VIEW F
  FS? 1
    GTO @5_end_if
  ; else
    ; print "T="
    VIEW T
    ; exit
    GTO done
  @5_end_if:
  ; print "T+="
  VIEW P
  ; print "T-="
  VIEW M
  GTO done
  
output_R:
  ENG 3
  ; print "R1="
  VIEW A
  ; print "R2="
  VIEW B
  GTO done

output_C:
  ENG 3
  ; print "C="
  VIEW C

done:
  ALL
  FIX 4
  CF 0
  CF 1
  CF 2
  CF 3
  CF 4

exit:
  RTN

ENDS IC555

END
