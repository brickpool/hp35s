TITLE Electric power P
MODEL 35S
DATASEG
  ; 1 RCL P \Rsh 0 2 RCL V \Rsh 0 3 RCL I \Rsh 0 4 RCL R
  eqnMenu db  '1P 2V 3I 4R'

CODESEG
start:
LBL P                 ; \Rsh LBL P
init:
  RPN                 ; MODE 5RPN

menu:
  SF 10               ; \Lsh \wedge 1 . 0
    EQN [eqnMenu]     ; EQN [eqnMenu] ENTER
  CF 10               ; \Lsh \wedge 2 . 0
  ; IF y=1 THEN GOTO 'P='
  1                   ; 1 ENTER
  x=y?                ; \Lsh x?y 6
    GTO calcP         ; GTO RCL 'calcP'
  Rv                  ; R\downarrow
  ; IF y=2 THEN GOTO 'V='
  2                   ; 2 ENTER
  x=y?                ; \Lsh x?y 6
    GTO calcV         ; GTO RCL 'calcV'
  Rv                  ; R\downarrow
  ; IF y=3 THEN GOTO 'I='
  3                   ; 3 ENTER
  x=y?                ; \Lsh x?y 6
    GTO calcI         ; GTO RCL 'calcI'
  Rv                  ; R\downarrow
  ; IF y=4 THEN GOTO 'R='
  4                   ; 3 ENTER
  x=y?                ; \Lsh x?y 6
    GTO calcR         ; GTO RCL 'calcR'
  Rv                  ; R\downarrow
STOP                  ; R/S

; P=
calcP:
  INPUT V             ; \Lsh INPUT V
  ; IF V=0 THEN GOTO 'P=I^2*R'
  x=0?                ; \Rsh x?0 6
    GTO inputI4P      ; GTO RCL 'inputI4P'
  INPUT I             ; \Lsh INPUT I
  ; IF I=0 THEN GOTO 'P=V^2/R'
  x=0?                ; \Rsh x?0 6
    GTO inputR        ; GTO RCL 'inputR'
  ; P=V*I
  *                   ; \times
GTO displayP          ; GTO RCL 'displayP'

inputI4P:
  ; P=I^2*R
  INPUT I             ; \Lsh INPUT I
  x^2                 ; \Rsh x^{2}
  INPUT R             ; \Lsh INPUT R
  *                   ; \times
GTO displayP          ; GTO RCL 'displayP'

inputR:
  ; P=V^2/R
  INPUT R             ; \Lsh INPUT R
  x<=0?               ; \Rsh x?0 2
  ; IF R<=0 THEN GOTO 'P=V^2/R'
  GTO displayP        ; GTO RCL 'displayP'
  1/x                 ; 1/X
  RCL* V              ; RCL \times V
  RCL* V              ; RCL \times V

displayP:
  STO P               ; \Rsh STO P
  VIEW P              ; \Lsh VIEW P
RTN                   ; \Lsh RTN

; V=
calcV:
  INPUT P             ; \Lsh INPUT P
  INPUT R             ; \Lsh INPUT R
  ; V=SQRT(P*R)
  *                   ; \times
  SQRT                ; \sqrt{x}
  ; display V
  STO V               ; \Rsh STO V
  VIEW V              ; \Lsh VIEW V
RTN                   ; \Lsh RTN

; I=
calcI:
  INPUT P             ; \Lsh INPUT P
  ; input R
  INPUT R             ; \Lsh INPUT R
  ; IF R<=0 THEN GOTO 'input R'
  x<=0?               ; \Rsh x?0 2
    GTO calcV         ; GTO RCL 'calcV'
  ; I=SQRT(P/R)
  /                   ; \div
  SQRT                ; \sqrt{x}
  ; display I
  STO  I              ; \Rsh STO I
  VIEW I              ; \Lsh VIEW I
RTN                   ; \Lsh RTN

; R=
calcR:
  INPUT P             ; \Lsh INPUT P
  ; IF P<=0 THEN GOTO 'R='
  x<=0?               ; \Rsh x?0 2
    GTO calcR         ; GTO RCL 'calcR'
  INPUT V             ; \Lsh INPUT V
  ; IF V=0 THEN GOTO 'R=P/I^2'
  x=0?                ; \Rsh x?0 6
    GTO inputI4R      ; GTO RCL 'inputI4R'
  ; R=V^2/P
  x^2                 ; \Rsh x^{2}
  RCL/ P              ; RCL \div P
GTO displayR          ; GTO RCL 'displayR'

inputI4R:
  ; R=P/I^2
  INPUT I             ; \Lsh INPUT I
  ; IF I<=0 THEN GOTO 'R=P/I^2'
  x<=0?               ; \Rsh x?0 2=
    GTO inputI4R      ; GTO RCL 'inputI4R'
  x^2                 ; \Rsh x^{2}
  1/x                 ; 1/X
  RCL* P              ; RCL \times P

displayR:
  STO R               ; \Rsh STO R
  VIEW R              ; \Lsh VIEW R

RTN                   ; \Lsh RTN
end start             ; \C
; CK=1AAF
; LN=249
