; Ported to HP-35s
;
; Tricks, tips, and routines for HP-41 series calculators
; Chapter 6
; Flags
MODEL P35S

SEGMENT Flags CODE

; 6-1 Flag toggling "FT"
; ------------------------
; - Source: Ron Knapp (618) (PPC J, V6N5T6) & Jake Schwartz (1820)
;   (PPC J, V6N8P26).
; - Source: https://hpmuseum.org/forum/thread-10589-post-96201.html

LBL C
  ; The sequence 'FC?C nm, SF nm' sets a flag if it was clear and clears it
  ; if it was set. It is not efficient to use on the HP-35s.
  ; The implementation uses 'GOTO' (method 4) with the flag commands
  ; 'FS?, SF, CF'. It preserves other flags, the stack, and registers, and
  ; takes 5 steps on the HP-35s.

  @IF:
    FS? 0       ; (FLAG0 .EQ. 0)
    GTO @ELSE
  @THEN:
    SF 0
    GTO @END_IF
  @ELSE:
    CF 0
  @END_IF:
RTN

LBL T
  ; "FT" (called with 'XEQ T') toggles the flag whose number (0-5) is in
  ; REGX: 'LBL "FT", FC?C IND X, SF IND X, RTN'.
  ; A direct translation is not possible because HP-35s flag commands do not
  ; support indirect addressing. The "FT" implementation uses the stack
  ; (method 2), the statistics registers (counter 'n'), and variable T to
  ; preserve REGT.
  R^
  STO T
  CLZ
@0:
  CLx
  x!=y?
    GTO @1
  FS? 0
    !
  SF 0
  x!=0?
    CF 0
@1:
  Z+
  x!=y?
    GTO @2
  FS? 1
    CLx
  SF 1
  x=0?
    CF 1
@2:
  Z+
  x!=y?
    GTO @3
  FS? 2
    CLx
  SF 2
  x=0?
    CF 2
@3:
  Z+
  x!=y?
    GTO @4
  FS? 3
    CLx
  SF 3
  x=0?
    CF 3
@4:
  Z+
  x!=y?
    GTO @5
  FS? 4
    CLx
  SF 4
  x=0?
    CF 4
@5:
  ; ...
  CLx
  CLZ
  x<> T
  Rv
RTN


; 6-2 Set or clear a flag depending on the value in X
; ----------------------------------------------------------
; - Source: Bill Kalb (265) (BP 67/97).
LBL B
  SF 1
    x=0?
  CF 1
  ; ... 
RTN


; 6-3 Clearing multiple flags ("CFX" & "CFA")
; --------------------------------------------
; "CFX" clears the 'block' of flags specified by the control number 'abc.lmn'
; in X, e.g. flags 1-3 with '1.003, XEQ X'.
; "CFA" (called with 'XEQ A') prefixes 0.004 to clear flags 0-4.
; The contents of X and REGT are lost (and REGZ for "CFA").
;
; A direct translation of the HP-42 sequence
; 'LBL "CFA", .025, LBL "CFX", CF IND X, ISG X, GTO "CFX", RDN, RTN'
; is not possible on the HP-35s; using 'CF <n>' directly is more efficient.
LBL A
  0.004

LBL X
  STO X

  ; CONTINUE
  @10:
    CLx
    RCL X
    IP
    ENTER

    CLx
    CLZ
    x=y?
      CF 0
    Z+
    x=y?
      CF 1
    Z+
    x=y?
      CF 2
    Z+
    x=y?
      CF 3
    Z+
    x=y?
      CF 4
    Z+
    x=y?
      CF 5
    Z+
    x=y?
      CF 6
    Z+
    x=y?
      CF 7
    Z+
    x=y?
      CF 8
    Z+
    x=y?
      CF 9
    Z+
    x=y?
      CF 10
    Z+
    x=y?
      CF 11

    Rv
    ISG X       ; X=X+1
  GTO @10       ; IF (X .LT. REGX) GOTO ...

  CLZ
  Rv
RTN
; - Source: William Cheeseman (4381) (PPC CJ, V7N5P7).


; 6-4 Synthetic flag toggling ("IF")
; ---------------------------------------------
; Synthetic programming is not possible on the HP-35s.
; See 6-2.


; 6-5 Viewing the flags ("VF")
; ------------------------------
; 'XEQ F' shows which flags are set.
; Flags 0-4 are visible on the HP-35s display, so only flags 5-11 are shown.
; - Source: Roger Hill (4940) (PPC ROM).
LBL F
  ; J = 5.011
  ; I = J
  5.011
  STO J
  STO I

  ; REGX = 0
  CLx

  ; CONTINUE
  @20:
    STO (I)     ; REG(I) = REGX
    ISG I       ; I=I+1
  GTO @20       ; IF (I < 11) GOTO CONTINUE

  ; R(12) = -1
  NOT
  STO (I)

  ; I = J
  Rv
  RCL J
  STO I

  ; REGX = 1
  SGN           ; 1

  FS? 5
    STO (I)
  ISG I         ; I=I+1
  FS? 6
    STO (I)
  ISG I         ; I=I+1
  FS? 7
    STO (I)
  ISG I         ; I=I+1
  FS? 8
    STO (I)
  ISG I         ; I=I+1
  FS? 9
    STO (I)
  ISG I         ; I=I+1
  FS? 10
    STO (I)
  ISG I         ; I=I+1
  FS? 11
    STO (I)

  ; I = J
  Rv
  RCL J
  STO I

  ; CONTINUE
  @30:
    VIEW (I)    ; WRITE REG(I)
    PSE
    ISG I       ; I=I+1
  GTO @30       ; IF (I < 11) GOTO ...

  Rv
RTN
; LN=134 (164 Bytes)


; 6-6 Synthetic toggling of flag 55 ("55")
; -----------------------------------------------
; A printer cannot be connected to the HP-35s.


; 6-7 Resetting the flags ("RF")
; -------------------------------
; This routine sets the flags to the state they would have after a memory
; clear ("MEMORY CLEAR"). By default, all 12 flags are clear.
; 
; - Source: Valentin Albillo (4747) & Carter Buck (4783) (PPC ROM).
; - Source: HP User's Guide F2215AA-90002
LBL R
  CF 0
  CF 1
  CF 2
  CF 3
  CF 4
  CF 5
  CF 6
  CF 7
  CF 8
  CF 9
  CF 10
  CF 11
RTN


; 6-8 Bulk flag control
; -----------------------------
; An important use is to control all 12 flags at once, setting them to the
; desired state. The command sequence is '"XXXXXXX", XEQ X003', where
; "XXXXXXX" is the binary value used to set the flags. This sequence takes
; 40 bytes in the main program, the same as one number and one command.
; Bytes are saved whenever the binary value "XXXXXXX" is already in X
; (3 bytes) or in a variable (6 bytes).
; - To determine the binary value for the desired flag state, write the
;   positions of all 12 flags as a 12-bit binary number, using 1 for set and
;   0 for clear, then group the bits into bytes of 8. The following example
;   sets flags 1, 2, 3, and 10 (text line); all other flags are cleared.
;   Flag 12 is the leftmost bit, and flag 0 is the rightmost bit.
;
; 0000 0100 | 0000 1110
;   0    4  |   0    E
;  
; The required number is '040Eh', which is 1038 in decimal.
; - Source: William Wickes (3735). See also 25-6.
; - Source: "Advanced HP-41 Functions Made Easy" by Keith Jarett,
;   edited by Heinz Dalkowski.

; Hauptprogramm
LBL D
  ; ...
  XEQ RCLFLAGS  ; XEQ X003
  ; ...
  STOP
  ; ...
  XEQ STOFLAGS  ; XEQ X061
  ; ...
RTN

; Subroutines
LBL E
RTN             ; Abort on direct call
; LN=477

; Use 'RCLFLAG' to get the flag states as a binary number.
; Variable M reads the flags, and Z preserves REGZ.
RCLFLAGS:
  ;XYZT
  ENTER         ; LET Z = REGZ
  R^
  STO Z
  Rv
  
  CLx           ; LET M = 0
  STO M
  
  !             ; LET REGX = 1
  FS? 0
    STO+ M
  
  ENTER         ; LET REGX = 2
  +
  FS? 1
    STO+ M
  
  ENTER         ; LET REGX = 4
  +
  FS? 2
    STO+ M
  
  ENTER         ; LET REGX = 8
  +
  FS? 3
    STO+ M
  
  ENTER         ; LET REGX = 16
  +
  FS? 4
    STO+ M
  
  ENTER         ; LET REGX = 32
  +
  FS? 5
    STO+ M
  
  ENTER         ; LET REGX = 64
  +
  FS? 6
    STO+ M
  
  ENTER         ; LET REGX = 128
  +
  FS? 7
    STO+ M
  
  ENTER         ; LET REGX = 256
  +
  FS? 8
    STO+ M
  
  ENTER         ; LET REGX = 512
  +
  FS? 9
    STO+ M
  
  ENTER         ; LET REGX = 1024
  +
  FS? 10
    STO+ M
  
  ENTER         ; LET REGX = 2048
  +
  FS? 11
    STO+ M
  
  Rv            ; LET REGX = M
  RCL M
  
  RCL Z         ; LET REGT = Z
  Rv
  ;MXYZ
RTN

; Use 'STOFLAG' to restore the flag states.
; Variable M sets the flags, while Y, Z, and T preserve REGY, REGZ, and REGT.
STOFLAGS:
  ;XYZT
  Rv
  STO Y         ; LET Y = REGY
  Rv
  STO Z         ; LET Z = REGZ
  Rv
  STO T         ; LET T = REGX
  Rv
  ENTER
  ENTER
  ENTER

  ;XXXX
  CLx           ; LET REGX = 1
  !
  STO M
  STO+ M        ; LET M = 2
  AND
  CF 0
  x!=0?
    SF 0
  Rv

  RCL M
  STO+ M        ; LET M = 4
  AND
  CF 1
  x!=0?
    SF 1
  Rv

  RCL M
  STO+ M        ; LET M = 8
  AND
  CF 2
  x!=0?
    SF 2

  Rv
  RCL M
  STO+ M        ; LET M = 16
  AND
  CF 3
  x!=0?
    SF 3

  Rv
  RCL M
  STO+ M        ; LET M = 32
  AND
  CF 4
  x!=0?
    SF 4
  Rv

  RCL M
  STO+ M        ; LET M = 64
  AND
  CF 5
  x!=0?
    SF 5
  Rv

  RCL M
  STO+ M        ; LET M = 128
  AND
  CF 6
  x!=0?
    SF 6
  Rv

  RCL M
  STO+ M        ; LET M = 256
  AND
  CF 7
  x!=0?
    SF 7
  Rv

  RCL M
  STO+ M        ; LET M = 512
  AND
  CF 8
  x!=0?
    SF 8
  Rv

  RCL M
  STO+ M        ; LET M = 1024
  AND
  CF 9
  x!=0?
    SF 9
  Rv

  RCL M
  STO+ M        ; LET M = 2048
  AND
  x!=0?
    SF 10
  Rv

  RCL M
  AND
  CF 11
  x!=0?
    SF 11
  Rv

  RCL T         ; LET REGT = T
  RCL Z         ; LET REGZ = Z
  RCL Y         ; LET REGZ = Y
  R^
  ;XYZT
RTN


; 6-17 Logical AND/OR in conditional branches
; --------------------------------------------------------------------
; 1. When testing two conditions joined by logical AND, invert the second
;    test. For example, to execute "SUB" only when 'x=0' and flag 0 is set,
;    use this sequence:

LBL G
; x=0?
;   FC? 0       ; not supported on the HP-35s
;     GTO @50
; XEQ SUB
; @50:
  x=0?
    GTO @40
      GTO @50
    @40:
    FS? 0
  XEQ SUB
  @50:
RTN

; or use the logically equivalent sequence:

LBL H
  FS? 0
    x!=0?
      GTO @60
  XEQ SUB
  @60:
RTN

; Either sequence achieves this.

; 2. When testing two conditions joined by logical OR (non-exclusive OR, not
;    the colloquial "either-or" where one condition excludes the other),
;    invert the first test. For example, to execute "SUB" when at least one
;    condition is true, either 'x=0' or flag 0 is set, use this sequence:

LBL I
  x!=0?
    FS? 0
      XEQ SUB
RTN

; or use the logically equivalent sequence:

LBL J
; FC? 0         ; not supported on the HP-35s
;   x=0?
;     XEQ SUB
  FS? 0
    XEQ SUB
  x=0?
    XEQ SUB
RTN

; Either sequence achieves this.

SUB:
LBL K
  SF 10
  eqn 'SUB'
  CF 10
RTN


; HP-41 flag tests not available as HP-35s commands
; ------------------------------------------------------------------------
; The following three flag functions are not available on the HP-35s, but can
; be emulated with additional commands:
;
; 'FC?'   Test whether a flag is clear.
; 'FS?C'  Test whether a flag is set, then clear it.
; 'FC?C'  Test whether a flag is clear, then clear it.
;
; The latter two commands, 'FS?C' and 'FC?C', also perform an additional
; function: they clear the specified flag after testing it.
;
; - Source: HP-41 C/CV User Manual by Karl-Heinz Gosmann

;  FC? <n>
LBL J
  FS? 0
    GTO @70
    1
    GTO @80
  @70:
    0
  @80:
RTN

;  FS?C <n>
LBL K
  FS? 2
    GTO @90
  GTO @100
  @90:
    CF 2
    1
    GTO @110
  @100:
    CF 2
    0
  @110:
RTN

ENDS Flags

END
