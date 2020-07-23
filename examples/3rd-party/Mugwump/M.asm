; Mugwump for the HP-35s
; This program is from Bob Albrecht and is used here by permission.
; http://www.vintage-basic.net/bcg/mugwump.bas
MODEL   P35S
SEGMENT MUGWUMP CODE
        LBL     M
        ;1 PRINT TAB(33);"MUGWUMP"
        SF      10
        eqn     'MUGWUMP'
        PSE
        CF      10
;------------------------------------------------------
; CREATIVE COMPUTING  MORRISTOWN, NEW JERSEY
;
; COURTESY PEOPLE'S COMPUTER COMPANY
;------------------------------------------------------
        ;10 DIM P(4,2)
        4
        STO     P
        STO     I
        SGN
        STO+    I
        +/-
        STO     (I)
;------------------------------------------------------
; THE OBJECT OF THIS GAME IS TO FIND FOUR MUGWUMPS
; HIDDEN ON A 10 BY 10 GRID.  HOMEBASE IS POSITION 0,0.
; ANY GUESS YOU MAKE MUST BE TWO NUMBERS WITH EACH
; NUMBER BETWEEN 0 AND 9, INCLUSIVE.  FIRST NUMBER
; IS DISTANCE TO RIGHT OF HOMEBASE AND SECOND NUMBER
; IS DISTANCE ABOVE HOMEBASE.
;
; YOU GET 10 TRIES.  AFTER EACH TRY, I WILL TELL
; YOU HOW FAR YOU ARE FROM EACH MUGWUMP.
;------------------------------------------------------
@240:
        ;240 GOSUB 1000
        XEQ     @1000
        ;250 T=0
        CLx
        STO     T
@260:
        ;260 T=T+1
        1
        STO+    T
        ;270 PRINT
        ;275 PRINT
        ;290 PRINT "TURN NO.";T;"-- WHAT IS YOUR GUESS";
        SF      10
        eqn     'TURN NUM'
        PSE
        ALL
        ALG
        RCL     T
        PSE
        RPN
        eqn     'YOUR GUESS'
        PSE
        CF      10
        ;300 INPUT M,N
        INPUT   X
        INPUT   Y
        FIX     4
        ;310 FOR I=1 TO 4
        1.004
        STO     I
@320:
        ;320 IF P(I,1)=-1 THEN 400
        eqn     '(I)*[1,0]'
        x<0?
        GTO     @400
        ;330 IF P(I,1)<>M THEN 380
        RCL     X
        x!=y?
        GTO     @380
        ;340 IF P(I,2)<>N THEN 380
        eqn     '(I)*[0,1]'
        RCL     Y
        x!=y?
        GTO     @380
        ;350 P(I,1)=-1
        [-1,0]
        STO     (I)
        ;360 PRINT "YOU HAVE FOUND MUGWUMP";I
        SF      10
        eqn     'FOUND MUGWUMP'
        PSE
        CF      10
        ALL
        ALG
        RCL     I
        IP
        PSE
        RPN
        FIX     4
        ;370 GOTO 400
        GTO     @400
@380:
        ;380 D=SQR((P(I,1)-M)^2+(P(I,2)-N)^2)
        eqn     'ABS((I)-[X,Y])'
        ;390 PRINT "YOU ARE";(INT(D*10))/10;"UNITS FROM MUGWUMP";I
        x<>     (I)
        SF      10
        eqn     'UNITS'
        PSE
        eqn     'FROM MUGWUMP'
        PSE
        CF      10
        FIX     1
        VIEW    (I)
        PSE
        FIX     4
        x<>     (I)
@400:
        ;400 NEXT I
        ISG     I
        GTO     @320
        ;410 FOR J=1 TO 4
        1.004
        STO     J
@420:
        ;420 IF P(J,1)<>-1 THEN 470
        eqn     '(J)*[1,0]'
        x>=0?
        GTO     @470
        ;430 NEXT J
        ISG     J
        GTO     @420
        ;440 PRINT
        ;450 PRINT "YOU GOT THEM ALL IN";T;"TURNS!"
        SF      10
        eqn     'YOU GOT IT!'
        PSE
        eqn     'NUM ATTEMPTS'
        PSE
        CF      10
        ALL
        VIEW    T
        PSE
        FIX     4
        ;460 GOTO 580
        GTO     @580
@470:
        ;470 IF T<10 THEN 260
        10
        RCL     T
        x<y?
        GTO     @260
        ;480 PRINT
        ;490 PRINT "SORRY, THAT'S 10 TRIES.  HERE IS WHERE THEY'RE HIDING:"
        SF      10
        eqn     'SORRY,10 TRIES'
        PSE
        eqn     'HERE THEY ARE'
        PSE
        CF      10
        ;540 FOR I=1 TO 4
        1.004
        STO     I
@550:
        ;550 IF P(I,1)=-1 THEN 570
        eqn     '(I)*[1,0]'
        x<0?
        GTO     @570
        ;560 PRINT "MUGWUMP";I;"IS AT (";P(I,1);",";P(I,2);")"
        SF      10
        eqn     'MUGWUMP AT'
        PSE
        CF      10
        ALL
        VIEW    (I)
        PSE
        FIX     4
@570:
        ;570 NEXT I
        ISG     I
        GTO     @550
@580:
        ;580 PRINT
        ;600 PRINT "THAT WAS FUN! LET'S PLAY AGAIN......."
        ;610 PRINT "FOUR MORE MUGWUMPS ARE NOW IN HIDING."
        SF      10
        eqn     'PLAY AGAIN'
        PSE
        CF      10
        ;630 GOTO 240
        GTO     @240
@1000:
        ;1000 FOR J=1 TO 2
        ;1010 FOR I=1 TO 4
        1.004
        STO     I
@1020:
        ; 1020 P(I,J)=INT(10*RND(1))
        eqn     'IP(10*RAND)'
        eqn     'IP(10*RAND)'
        eqn     '[REGX,REGY]'
        STO     (I)
        ;1030 NEXT I
        ;1040 NEXT J
        ISG     I
        GTO     @1020
        RTN

ENDS MUGWUMP

END
