; Hack and Slash Adventure for the HP-35s
; This program is by Paul Dale and is used here by permission.
; https://www.hpmuseum.org/software/35hacksl.htm
MODEL P35S
SEGMENT HackAndSlash CODE
        LBL     D
        ALL
        XEQ     @702
        SF      10
        XEQ     @639
        STO     M
        XEQ     @639
        STO     N
        XEQ     @639
        STO     O
@011:
        XEQ     @063
        RCL     H
        x>=y?
        GTO     @110
        XEQ     @057
        x<=y?
        GTO     @081
        RCL     K
        XEQ     @057
        XEQ     @069
        RCL     H
        y^x
        *
        XEQ     @063
        -
        x>=y?
        GTO     @110
        GTO     @088
@029:
        RANDOM
        *
        INTG
        XEQ     @071
        +
        RTN
@035:
        STO     A
        CF      10
@037:
        eqn     'REGY*RAND'
        INTG
        +
        DSE     A
        GTO     @037
        SF 10
        x<>y
        Rv
        RTN
@046:
        XEQ     @633
        XEQ     @035
        +
        RTN
@050:
        XEQ     @069
        XEQ     @029
        XEQ     @071
        -
        RTN
@055:
        XEQ     @063
        GTO     @029
@057:
        10
        RTN
@059:
        3
        RTN
@061:
        100
        RTN
@063:
        20
        RTN
@065:
        8
        RTN
@067:
        4
        RTN
@069:
        2
        RTN
@071:
        1
        RTN
@073:
        0.5
        RTN
@075:
        XEQ     @069
        +
        RTN
@078:
        XEQ     @069
        -
        RTN
@081:
        RCL     K
        -9
        RCL+    H
        10220
        *
        x>=y?
        GTO     @110
@088:
        XEQ     @067
        XEQ     @029
        XEQ     @065
        +
        RCL     O
        XEQ     @059
        /
        +
        IP
        x<=0?
        XEQ     @071
        STO+    I
        STO+    J
        XEQ     @071
        STO+    H
        STO+    L
        XEQ     @050
        STO+    M
        XEQ     @050
        STO+    N
        XEQ     @050
        STO+    O
@110:
        RCL     H
        XEQ     @623
        RCL     K
        XEQ     @608
        RCL     J
        XEQ     @613
        RCL     L
        XEQ     @628
        FS?     4
        GTO     @693
        XEQ     @065
        XEQ     @067
        *
        XEQ     @059
        XEQ     @071
        RCL+    H
        *
        x>y?
        x<>y
        XEQ     @029
        STO     E
        XEQ     @067
        x^2
        x<y?
        GTO     @199
        x=y?
        GTO     @369
        XEQ     @065
        -
        x<y?
        GTO     @171
        x=y?
        GTO     @357
        XEQ     @067
        -
        x<y?
        GTO     @160
        x=y?
        GTO     @267
        XEQ     @078
        x<y?
        GTO     @279
        x>y?
        GTO     @261
        eqn     'KOBOLD'
        PSE
        [1,4,1]
        [1,6,-1]
        [1,0,13]
        GTO     @399
@160:
        XEQ     @075
        x<y?
        GTO     @285
        x>y?
        GTO     @273
        eqn     'ORC'
        PSE
        [1,12,4]
        [1,8,3]
        [1,3,17]
        GTO     @399
@171:
        XEQ     @067
        +
        x>y?
        GTO     @188
        x=y?
        GTO     @315
        XEQ     @075
        x<y?
        GTO     @339
        x>y?
        GTO     @327
        eqn     'GNOLL'
        PSE
        [4,10,4]
        [1,10,1]
        [1,6,17]
        GTO     @399
@188:
        XEQ     @078
        x<y?
        GTO     @297
        x>y?
        GTO     @291
        eqn     'GIANT LEECH'
        PSE
        [2,8,4]
        [1,8,4]
        [1,6,11]
        GTO     @399
@199:
        XEQ     @065
        +
        x<y?
        GTO     @233
        x=y?
        GTO     @321
        XEQ     @067
        -
        x<y?
        GTO     @222
        x=y?
        GTO     @375
        XEQ     @078
        x<y?
        GTO     @363
        x>y?
        GTO     @351
        eqn     'BUGBEAR'
        PSE
        [6,8,15]
        [1,6,4]
        [4,9,20]
        GTO     @399
@222:
        XEQ     @075
        x<y?
        GTO     @309
        x>y?
        GTO     @303
        eqn     'GIANT'
        PSE
        [6,12,30]
        [2,10,12]
        [1,12,23]
        GTO     @399
@233:
        XEQ     @067
        +
        x>y?
        GTO     @250
        x=y?
        GTO     @381
        XEQ     @075
        x<y?
        GTO     @393
        x>y?
        GTO     @345
        eqn     'TITAN'
        PSE
        [16,10,50]
        [2,16,20]
        [1,22,25]
        GTO     @399
@250:
        XEQ     @078
        x<y?
        GTO     @333
        x>y?
        GTO     @387
        eqn     'ENT'
        PSE
        [9,10,40]
        [2,6,10]
        [2,15,25]
        GTO     @399
@261:
        eqn     'GIANT BAT'
        PSE
        [1,2,0]
        [1,4,0]
        [1,0,12]
        GTO     @399
@267:
        eqn     'GOBLIN'
        PSE
        [1,8,0]
        [1,8,0]
        [1,2,15]
        GTO     @399
@273:
        eqn     'SKELETON'
        PSE
        [1,8,2]
        [1,8,0]
        [2,1,18]
        GTO     @399
@279:
        eqn     'GIANT RAT'
        PSE
        [1,6,0]
        [1,6,0]
        [1,1,13]
        GTO     @399
@285:
        eqn     'DWARF'
        PSE
        [2,8,0]
        [1,10,1]
        [1,2,20]
        GTO     @399
@291:
        eqn     'GIANT SPIDER'
        PSE
        [2,8,4]
        [1,10,8]
        [1,4,17]
        GTO     @399
@297:
        eqn     'ZOMBIE'
        PSE
        [3,8,0]
        [1,6,2]
        [2,5,8]
        GTO     @399
@303:
        eqn     'GHOST'
        PSE
        [10,8,50]
        [2,4,-1]
        [2,16,30]
        GTO     @399
@309:
        eqn     'DAEMON'
        PSE
        [8,8,20]
        [1,8,2]
        [2,11,26]
        GTO     @399
@315:
        eqn     'GNOME'
        PSE
        [3,10,0]
        [1,8,1]
        [1,7,18]
        GTO     @399
@321:
        eqn     'BASILISK'
        PSE
        [6,8,4]
        [2,10,10]
        [1,13,24]
        GTO     @399
@327:
        eqn     'SLIME'
        PSE
        [5,10,20]
        [1,4,0]
        [4,8,12]
        GTO     @399
@333:
        eqn     'DEVIL'
        PSE
        [10,8,30]
        [1,10,5]
        [2,14,24]
        GTO     @399
@339:
        eqn     'BARBARIAN'
        PSE
        [4,12,16]
        [1,10,2]
        [1,7,13]
        GTO     @399
@345:
        eqn     'VAMPIRE'
        PSE
        [8,10,10]
        [2,12,8]
        [1,15,24]
        GTO     @399
@351:
        eqn     'OOZE'
        PSE
        [12,10,30]
        [1,6,0]
        [5,9,14]
        GTO     @399
@357:
        eqn     'MOLD MONSTER'
        PSE
        [2,8,0]
        [1,2,0]
        [3,3,10]
        GTO @399
@363:
        eqn     'OGRE'
        PSE
        [5,12,10]
        [2,8,8]
        [1,10,21]
        GTO     @399
@369:
        eqn     'GIANT SNAKE'
        PSE
        [4,8,8]
        [2,8,4]
        [1,5,15]
        GTO     @399
@375:
        eqn     'TROLL'
        PSE
        [6,10,40]
        [1,6,6]
        [2,9,22]
        GTO     @399
@381:
        eqn     'ELEMENTAL'
        PSE
        [10,12,30]
        [1,12,10]
        [2,16,17]
        GTO     @399
@387:
        eqn     'WYVERN'
        PSE
        [7,12,16]
        [1,8,8]
        [2,14,28]
        GTO     @399
@393:
        eqn     'DRAGON'
        PSE
        [24,20,100]
        [1,20,30]
        [2,30,29]
        SF      4
@399:
        STO     B
        Rv
        STO     C
        Rv
        XEQ     @046
        STO     D
        STO     P
        RCL     E
        XEQ     @059
        /
        +/-
        INTG
        ABS
        STO     E
        RCL     B
        XEQ     @633
        STO     B
        Rv
        STO     F
        Rv
        STO     G
        GTO     @428
@421:
        CF      4
@422:
        eqn     'GOT AWAY'
        PSE
        GTO     @593
@425:
        RCL     J
        x<=0?
        GTO     @690
@428:
        eqn     '0=ATK 1=FLEE'
        PSE
        CLSTK
        STOP
        x=0?
        GTO     @449
        FS?     4
        GTO     @421
        XEQ     @057
        RCL*    E
        XEQ     @069
        RCL*    N
        -
        RCL+    H
        XEQ     @061
        /
        RANDOM
        x>=y?
        GTO     @422
        eqn     'CAUGHT YOU!'
        PSE
@449:
        RCL     L
        x=0?
        GTO     @458
        eqn     '0=SWD 1=SPELL'
        PSE
        CLSTK
        STOP
        x!=0?
        GTO     @524
@458:
        XEQ     @055
        RCL     H
        XEQ     @069
        /
        +
        RCL     M
        XEQ     @067
        /
        +
        IP
        FS?     1
        XEQ     @506
        RCL     G
        x>y?
        GTO     @489
        eqn     'HIT'
        PSE
        XEQ     @065
        XEQ     @029
        RCL     M
        XEQ     @067
        /
        +
        2.5
        -
        IP
        FS?     1
        XEQ     @509
        x<=0?
        XEQ     @071
        GTO     @533
@489:
        eqn     'MISSED'
        PSE
        GTO     @535
@492:
        XEQ     @069
        /
        XEQ     @073
        +
        IP
        x<=0?
        GTO     @071
        RTN
@500:
        0.9
        *
        RTN
@503:
        XEQ     @067
        -
        RTN
@506:
        XEQ     @067
        +
        RTN
@509:
        XEQ     @057
        XEQ     @029
        +
        XEQ     @065
        +
        FS?     4
        GTO     @517
        RTN
@517:
        XEQ     @063
        XEQ     @069
        XEQ     @029
        +
        XEQ     @057
        +
        RTN
@524:
        XEQ     @071
        STO-    L
        eqn     'ZOT!'
        PSE
        XEQ     @067
        XEQ     @069
        +
        RCL     H
        XEQ     @035
@533:
        STO-    D
        XEQ     @613
@535:
        RCL     D
        x<=0?
        GTO     @568
        RCL     B
        FS?     3
        XEQ     @492
        STO     Q
@542:
        XEQ     @055
        RCL+    F
        RCL     N
        XEQ      @067
        /
        -
        XEQ     @057
        -
        FS?     2
        XEQ     @503
        x<0?
        GTO     @565
        RCL     C
        XEQ     @046
        FS?     0
        XEQ     @500
        INTG
        x<=0?
        XEQ     @071
        STO-    J
        eqn     'OUCH!'
        PSE
        XEQ     @613
@565:
        DSE     Q
        GTO     @542
        GTO     @425
@568:
        eqn     'KILLED!'
        PSE
        XEQ     @067
        XEQ     @069
        RCL     E
        y^x
        RCL*    P
        RCL*    B
        STO+    K
        XEQ     @608
        XEQ     @059
        RCL     E
        y^x
        XEQ     @029
        STO+    R
        XEQ     @057
        /
        IP
        STO+    K
        XEQ     @618
        RANDOM
        0.1
        RCL*    E
        x>y?
        XEQ     @645
@593:
        XEQ     @057
        1/x
        RANDOM
        x>=y?
        GTO     @011
        eqn     'HEAL'
        PSE
        RCL     I
        STO     J
        RANDOM
        0.3
        +
        IP
        STO+    L
        GTO     @011
@608:
        x<>     E
        VIEW    E
        PSE
        x<>     E
        RTN
@613:
        x<>     H
        VIEW    H
        PSE
        x<>     H
        RTN
@618:
        x<>     G
        VIEW    G
        PSE
        x<>     G
        RTN
@623:
        x<>     L
        VIEW    L
        PSE
        x<>     L
        RTN
@628:
        x<>     S
        VIEW    S
        PSE
        x<>     S
        RTN
@633:
        CF      10
        eqn     '[0,0,1]*REGX'
        eqn     '[0,1,0]*REGY'
        eqn     '[1,0,0]*REGZ'
        SF      10
        RTN
@639:
        XEQ     @063
        RANDOM
        sqrt
        *
        IP
        RTN
@645:
        XEQ     @069
        XEQ     @067
        XEQ     @029
        XEQ     @071
        -
        x=0?
        GTO     @666
        x<y?
        GTO     @673
        x=y?
        GTO     @680
        FS?     3
        RTN
        SF      3
        eqn     'MAGIC HELMET'
        PSE
        XEQ     @071
@662:
        1e3
        *
        STO+    R
        RTN
@666:
        FS?     0
        RTN
        SF      0
        eqn     'MAGIC SHIELD'
        PSE
        XEQ     @069
        GTO     @662
@673:
        FS?     1
        RTN
        SF      1
        eqn     'MAGIC SWORD'
        PSE
        XEQ     @057
        GTO     @662
@680:
        FS?     2
        RTN
        SF      2
        eqn     'MAGIC ARMOUR'
        PSE
        XEQ     @067
        GTO     @662
@687:
        eqn     'MARRY PRINCESS'
        PSE
        RTN
@690:
        eqn     'YOU DIED!'
        PSE
        GTO     @702
@693:
        eqn     'BEAT DRAGON'
        PSE
        XEQ     @061
        x^2
        RCL     R
        x>=y?
        XEQ     @687
        eqn     'YOU WIN!'
        PSE
@702:
        CLVARS
        CLSTK
        CF 0
        CF 1
        CF 2
        CF 3
        CF 4
        CF 10
        RTN
ENDS    HackAndSlash
END
