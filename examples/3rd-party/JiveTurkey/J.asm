; Jive Turkey for the HP-35s
; This program is from Maurice E.T. Suinnen and is used here by permission.
; http://ftp.whtech.com/hexbus_cc40_ti74/a-collection-of-information-on-the-ti-cc40-computer.pdf
MODEL   P35S
SEGMENT JiveTurkey CODE
        LBL     J
        ;100 DISPLAY AT(6)"* JIVE TURKEY GAME *":PAUSE 2
        SF      10
        eqn     'JIVE TURKEY'
        PSE
        CF      10
@110:
        ;110 SCORE=0:FIB=0:RANDOMIZE:SECRET=INTRND(100)
        CLx
        STO     S       ; SCORE
        STO     F       ; FIB
        SEED
        100
        XEQ     INTRND
        STO     X       ; SECRET
@120:
        ;120 DISPLAY ERASE ALL"PROBABILITY OF TRUTH? 0-100";
        SF      10
        eqn     'PROB 0-100'
        PSE
        CF      10
@130:
        ;130 ACCEPT AT(29)BEEP VALIDATE(DIGIT);PROB
        INPUT   P       ; PROB
        x<0?
        GTO     @120
        100
        x<y?
        GTO     @120
@140:
        ;140 ROLL=INTRND(100):SCORE=SCORE+1:DISPLAY"YOUR GUES? 0-100";
        100
        XEQ     INTRND
        STO     R       ; ROLL
        1
        STO+    S       ; SCORE
@142:
        SF      10
        eqn     'GUESS 0-100'
        PSE
        CF      10
        ;150 ACCEPT AT(20)BEEP VALIDATE(DIGIT);GUESS:IF GUESS=SECRET THEN 190
        INPUT   G       ; GUESS
        x<0?
        GTO     @142
        100
        x<y?
        GTO     @142
        RCL     X
        x=y?
        GTO     @190
        ;160 IF PROB>ROLL THEN FLAG=1 ELSE FLAG=0:IF FLAG=0 THEN FIB=FIB+1
        RCL     R
        RCL     P
        CF      1
        x>y?
        SF      1
        1
        FS?     1
        CLx
        STO+    F
        ;170 IF GUESS<SECRET THEN IF FLAG=1 THEN 240 ELSE 230
        RCL     X
        RCL     G
        x>=y?
        GTO     @180
        FS?     1
        GTO     @240
        GTO     @230
@180:
        ;180 IF GUESS>SECRET THEN IF FLAG=1 THEN 230 ELSE 240
        x<=y?
        GTO     @190
        FS?     1
        GTO     @230
        GTO     @240
@190:
        ;190 PRINT"CONGRATULATIONS! YOU DID IT!":PAUSE 3
        SF      10
        eqn     'YOU DID IT!'
        PSE
        ;200 DISPLAY AT (3)"SCORE=";SCORE,"# OF FIBS=";FIB:PAUSE
        eqn     'SCORE='
        PSE
        VIEW    S
        eqn     'FIBS='
        PSE
        VIEW    F
        ;210 DISPLAY"SAME GAME AGAIN? Y/N";:ACCEPT AT(22)BEEP VALIDATE("YNyn"),ANSWERS
        CLx
        eqn     'AGAIN Y=2 N=1'
        CF      10
        ;220 IF ANSWERS="Y" OR ANSWERS="y" THEN 110 ELSE 250
        2
        x=y?
        GTO     @110
        GTO     @250
@230:
        ;230 PRINT"GUESS TOO HIGH":PAUSE 1:G0T0 140
        SF      10
        eqn     'GUESS TOO HIGH'
        PSE
        CF      10
        GTO     @140
@240:
        ;240 PRINT"GUESS TOO LOW":PAUSE 1:G0T0 140
        SF      10
        eqn     'GUESS TOO LOW'
        PSE
        CF      10
        GTO     @140
@250:
        ;250 DISPLAY AT(5)ERASE ALL"BYE, HAVE A NICE DAY!":PAUSE 3:END
        SF      10
        eqn     'BYE, HAND'
        PSE
        CF      10
        CF      1
        RTN
INTRND:
        eqn     'IP(RAND*IP(REGX+1/2))+1'
        RTN
ENDS JiveTurkey

END
