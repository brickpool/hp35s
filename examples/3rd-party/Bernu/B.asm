; Bernoulli Numbers for the HP-35s
; This program is Copyright 2004, 2006 by Jean-Marc Baillard and is used here by permission.
; https://www.hpmuseum.org/software/41/41bernu.htm
; https://www.hpmuseum.org/software/41/41rizeta.htm
MODEL   P35S
SEGMENT BERN    CODE
        LBL     B
        STO     C
        1
        x>y?
        RTN
        STO     X
        RCL+    X
        x<=y?
        GTO     @12
        1/x
        +/-
        RTN
@12:
        x!=y?
        GTO     @18
        6
        1/x
        RTN
@18:
        RMDR
        0
        x!=y?
        RTN
        4
        RCL     C
        x!=y?
        GTO     @31
        30
        1/x
        +/-
        RTN
@31:
        6
        x!=y?
        GTO     @38
        42
        1/x
        RTN
@38:
        x<>y
        FIX     9
        XEQ     ZETA
        STO     X
        RCL+    X
        1
        +/-
        RCL     C
        2
        /
        y^x
        *
        +/-
        pi
        STO     X
        RCL+    X
        1e-9
        -
        RCL     C
        y^x
        /
@58:
        RCL     C
        *
        DSE     C
        GTO     @58
        RTN
ZETA:
        +/-
        STO     B
        1
        STO     A
        ENTER
@07:
        CLx
        !               ; REGX = 1
        RCL     A
        +
        STO     A
        RCL     B
        y^x
        -
        +/-
        LASTx
        RND             ; the accuracy is determined by the display format.
        x!=0?
        GTO     @07
        !               ; REGX = 1
        2
        RCL     B
        y^x
        STO     X
        RCL+    X
        -
        /
        ABS
        RTN
ENDS    BERN
END
