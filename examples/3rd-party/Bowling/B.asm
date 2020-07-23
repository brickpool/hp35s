; Bowling for the HP-35s
; This program is from Paul Peraino and is used here by permission.
; http://www.vintage-basic.net/bcg/bowling.bas
MODEL   P35S
SEGMENT Bowling CODE
        LBL     B
        ;10 PRINT TAB(34);"BOWL"
        SF      10
        eqn     'BOWL'
        PSE
        CF      10
;-------------------------------------------
;
; CREATIVE COMPUTING  MORRISTOWN, NEW JERSEY
;
;-------------------------------------------
        ;30 PRINT:PRINT:PRINT
        ALL
        ;270 DIM C(15),A(100,6)
        100
        STO     A
        3               ;6
        *
        STO     C
        15
        +
        STO     I
        1
        STO+    I
        +/-             ;-1
        STO     (I)
;-------------------------------------------------------------
;
; WELCOME TO THE ALLEY
; BRING YOUR FRIENDS
; OKAY LET'S FIRST GET ACQUAINTED
;
; THE INSTRUCTIONS
; THE GAME OF BOWLING TAKES MIND AND SKILL.DURING THE GAME
; THE COMPUTER WILL KEEP SCORE.YOU MAY COMPETE WITH
; OTHER PLAYERS[UP TO FOUR].YOU WILL BE PLAYING TEN FRAMES
; ON THE PIN DIAGRAM 'O' MEANS THE PIN IS DOWN...'+' MEANS THE
; PIN IS STANDING.AFTER THE GAME THE COMPUTER WILL SHOW YOUR
; SCORES.
;
;-------------------------------------------------------------
        ;1530 PRINT "FIRST OF ALL...HOW MANY ARE PLAYING";
        SF      10
        eqn     'NUM OF PLAYERS'
        PSE
        CF      10
        ;1620 INPUT R
        INPUT   R
        ;1710 PRINT 
        ;1800 PRINT "VERY GOOD..."
        SF      10
        eqn     'ONE MOMENT'
        PSE
        CF      10
        ;1890 FOR I=1 TO 100: FOR J=1 TO 6: A(I,J)=0: NEXT J: NEXT I
        1.3             ;1.6
        STO     I
        CLx
@1900:
        STO     (I)
        ISG     I
        GTO     @1900

        ;1980 F=1
        1
        STO     F
@2070:
        ;2070 FOR P=1 TO R
        1
        STO     P
        0.001
        RCL*    R
        STO+    P
@2250:
        ;2160 M=0
        ;2250 B=1
        ;2340 M=0: Q=0
        CLx
        STO     M
        STO     B       ;!B=0
        STO     Q
        ;2430 FOR I=1 TO 15: C(I)=0: NEXT I
        1.015
        STO     I
@2440:
        RCL     C
        RCL+    I
        STO     J
        CLx
        STO     (J)
        ISG     I
        GTO     @2440

;----------------------------------------------------
@2520:  ; REMARK BALL GENERATOR USING MOD '15' SYSTEM
;----------------------------------------------------
@2610:
        ;2610 PRINT "TYPE ROLL TO GET THE BALL GOING."
        ;2700 INPUT N$
        SF      10
        eqn     '[RS] TO ROLL'
        CF      10
        ;2790 K=0: D=0
        CLx
        STO     K
        STO     D
        ;2880 FOR I=1 TO 20
        1.02
        STO     I
@2970:
        ;2970 X=INT(RND(1)*100)
        RANDOM
        100
        *
        IP
        STO     X
        ;3060 FOR J=1 TO 10
        1.01
        STO     L       ;J
@3150:
        ;3150 IF X<15*J THEN 3330
        15
        RCL*    L
        IP
        RCL     X
        x<y?
        GTO     @3330
        ;3240 NEXT J
        ISG     L
        GTO     @3150
@3330:
        ;3330 C(15*J-X)=1
        15
        RCL*    L       ;J
        IP
        RCL-    X
        RCL+    C
        STO     J
        1
        STO     (J)
        ;3420 NEXT I
        ISG     I
        GTO     @2970

;---------------------------
@3510:  ; REMARK PIN DIAGRAM
;---------------------------
        ;3600 PRINT "PLAYER:"P;"FRAME:";F"BALL:"B
        SF      10
        ALG
        eqn     'PLAYER'
        PSE
        RCL     P
        IP
        PSE
        eqn     'FRAME'
        PSE
        RCL     F
        PSE
        eqn     'BALL'
        PSE
        1
        RCL+    B       ;B+1
        PSE
        RPN
        CF      10
        ;3690 FOR I=0 TO 3
        0.003
        STO     I
@3780:
        ;3780 PRINT
        ;3870 FOR J=1 TO 4-I
        1.004
        STO     L       ;J
        RCL     I
        IP
        1e3
        /
        STO-    L
        ;... ROW=0
        CLx
        STO     T
@3960:
        ;3960 K=K+1
        1
        STO+    K
        ;4050 IF C(K)=1 THEN 4320
        RCL     C
        RCL+    K
        STO     J
        RCL     (J)
        x!=0?           ;x=1
        GTO     @4320
        ;4140 PRINT TAB(I);"+ ";
        ;.... ROW=ROW+(2^(J-1))
        2
        RCL     L       ;J
        IP
        1
        -
        y^x
        STO+    T       ;ROW
        ;4230 GOTO 4410
        GTO     @4410
@4320:
        ;4320 PRINT TAB(I);"O ";
        ;.... ROW=ROW+0
@4410:
        ;4410 NEXT J
        ISG     L
        GTO     @3960
        ;.... PRINT ROW T,Z,Y and X
        SF      10
        XEQ     PRT_ROW
        CF      10
        ;4500 NEXT I
        ISG     I
        GTO     @3780
        ;4590 PRINT ""

;-----------------------------
@4680:  ; REMARK ROLL ANALYSIS
;-----------------------------
        ;4770 FOR I=1 TO 10
        1.01
        STO     I
@4860:
        ;4860 D=D+C(I)
        RCL     C
        RCL+    I
        STO     J
        RCL     (J)
        STO+    D
        ;4950 NEXT I
        ISG     I
        GTO     @4860
        ;5040 IF D-M <> 0 THEN 5220
        RCL     D
        RCL-    M
        x!=0?
        GTO     @5220
        ;5130 PRINT "GUTTER!!"
        SF      10
        eqn     'GUTTER!!'
        PSE
        CF      10
@5220:
        ;5220 IF B<>1 OR D<>10 THEN 5490
        RCL     B
        x!=0?           ;x!=1?
        GTO     @5490
        10
        RCL     D
        x!=y?
        GTO     @5490
        ;5310 PRINT "STRIKE!!!!!"
        SF      10
        eqn     'STRIKE!!!!!'
        PSE
        CF      10
        ;5400 Q=3
        3
        STO     Q
@5490:
        ;5490 IF B<>2 OR D<>10 THEN 5760
        1               ;2
        RCL     B
        x!=y?
        GTO     @5760
        10
        RCL     D
        x!=y?
        GTO     @5760
        ;5580 PRINT "SPARE!!!!"
        SF      10
        eqn     'SPARE!!!!'
        PSE
        CF      10
        ;5670 Q=2
        2
        STO     Q
@5760:
        ;5760 IF B<>2 OR D>=10 THEN 6030
        1               ;2
        RCL     B
        x!=y?
        GTO     @6030
        10
        RCL     D
        x>=y?
        GTO     @6030
        ;5850 PRINT "ERROR!!!"
        SF      10
        eqn     'ERROR!!!'
        PSE
        CF      10
        ;5940 Q=1
        1
        STO     Q
@6030:
        ;6030 IF B<>1 OR D>=10 THEN 6210
        RCL     B
        x!=0?           ;x!=1?
        GTO     @6210
        10
        RCL     D
        x>=y?
        GTO     @6210
        ;6120 PRINT "ROLL YOUR 2ND BALL"
        SF      10
        eqn     'ROLL 2ND BALL'
        PSE
        CF      10

;-------------------------------------
@6210:  ; REMARK STORAGE OF THE SCORES
;-------------------------------------
        ;6300 PRINT 
        ;6390 A(F*P,B)=D
        RCL     A
        RCL*    B       ;A(,B-1)
        RCL     F
        RCL*    P
        +
        STO     J
        RCL     D        
        STO     (J)
        ;6480 IF B=2 THEN 7020
        1               ;2
        RCL     B
        x=y?
        GTO     @7020
        ;6570 B=2
        1               ;2
        STO     B
        ;6660 M=D
        RCL     D
        STO     M
        ;6750 IF Q=3 THEN 6210
        3
        RCL     Q
        x=y?
        GTO     @6210
        ;6840 A(F*P,B)=D-M
        RCL     A
        RCL*    B       ;A(,B-1)
        RCL     F
        RCL*    P
        +
        STO     J
        RCL     D
        RCL-    M
        STO     (J)
        ;6930 IF Q=0 THEN 2520
        RCL     Q
        x=0?
        GTO     @2520
@7020:
        ;7020 A(F*P,3)=Q
        RCL     A
        ENTER
        +               ;A(,2)
        RCL     F
        RCL*    P
        +
        STO     J
        RCL     Q
        STO     (J)
        ;7110 NEXT P
        ISG     P
        GTO     @2250
        ;7200 F=F+1
        1
        STO+    F
        ;7290 IF F<11 THEN 2070
        10
        RCL     F
        x<=y?
        GTO     @2070
        ;7295 PRINT "FRAMES"
        ;7380 FOR I=1 TO 10
        ;7470 PRINT I;
        ;7560 NEXT I
        ;7740 FOR P=1 TO R
        1
        STO     P
        0.001
        RCL*    R
        STO+    P
@7830:
        ;.... PRINT "PLAYER:"P
        SF      10
        eqn     'PLAYER'
        PSE
        RCL     P
        IP
        PSE
        CF      10
        ;7830 FOR I=1 TO 3
        ;7920 FOR J=1 TO 10
        1.01
        STO     J
@8010:
        ;8010 PRINT A(J*P,I);
        RCL     J
        RCL*    P
        STO     I
        RCL     A
        STO+    I       ;I=1
        Rv
        RCL     (I)     ;A(,I-1)
        RCL     A
        STO+    I       ;I=2
        Rv
        RCL     (I)     ;A(,I-1)
        RCL     A
        STO+    I       ;I=3
        Rv
        RCL     (I)     ;A(,I-1)
        RCL     (J)
        eqn     '[REGT,REGZ,REGY]\|>(J)'
        VIEW    (J)
        Rv
        STO     (J)
        ;8100 NEXT J
        ;8105 PRINT 
        ;8190 NEXT I
        ;8280 PRINT 
        ISG     J
        GTO     @8010
        ;8370 NEXT P
        ISG     P
        GTO     @7830
        ;8460 PRINT "DO YOU WANT ANOTHER GAME"
        CLx
        SF      10
        eqn     'PLAY AGAIN Y=2'
        CF      10
        2
        x=y?
        GTO     @2610
        FIX     4
        RTN

;-------------------------------------------------
PRT_ROW:        ; DISPLAY PIN'S ROW FOR ONE SECOND
;-------------------------------------------------
        RCL     I
        IP
        ENTER
        CLZ
        x=0?
        GTO     TROW
        Z+
        x=y?
        GTO     ZROW
        Z+
        x=y?
        GTO     YROW
XROW:
        RCL     T       ;ROW
        ENTER
        CLZ
        x=0?
        eqn     '   0'
        Z+
        x=y?
        eqn     '   +'
        RTN
YROW:
        RCL     T       ;ROW
        ENTER
        CLZ
        x=0?
        eqn     '  0 0'
        Z+
        x=y?
        eqn     '  0 +'
        Z+
        x=y?
        eqn     '  + 0'
        Z+
        x=y?
        eqn     '  + +'
        RTN
ZROW:
        RCL     T       ;ROW
        ENTER
        CLZ
        x=0?
        eqn     ' 0 0 0'
        Z+
        x=y?
        eqn     ' 0 0 +'
        Z+
        x=y?
        eqn     ' 0 + 0'
        Z+
        x=y?
        eqn     ' 0 + +'
        Z+
        x=y?
        eqn     ' + 0 0'
        Z+
        x=y?
        eqn     ' + 0 +'
        Z+
        x=y?
        eqn     ' + + 0'
        Z+
        x=y?
        eqn     ' + + +'
        RTN
TROW:
        RCL     T       ;ROW
        ENTER
        CLZ
        x=0?
        eqn     '0 0 0 0'
        Z+
        x=y?
        eqn     '0 0 0 +'
        Z+
        x=y?
        eqn     '0 0 + 0'
        Z+
        x=y?
        eqn     '0 0 + +'
        Z+
        x=y?
        eqn     '0 + 0 0'
        Z+
        x=y?
        eqn     '0 + 0 +'
        Z+
        x=y?
        eqn     '0 + + 0'
        Z+
        x=y?
        eqn     '0 + + +'
        Z+
        x=y?
        eqn     '+ 0 0 0'
        Z+
        x=y?
        eqn     '+ 0 0 +'
        Z+
        x=y?
        eqn     '+ 0 + 0'
        Z+
        x=y?
        eqn     '+ 0 + +'
        Z+
        x=y?
        eqn     '+ + 0 0'
        Z+
        x=y?
        eqn     '+ + 0 +'
        Z+
        x=y?
        eqn     '+ + + 0'
        Z+
        x=y?
        eqn     '+ + + +'
        RTN
        
ENDS Bowling

END
