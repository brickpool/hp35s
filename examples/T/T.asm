; This program calculates the sides, angles and area of a triangle
MODEL P35S

SEGMENT CODE
        LBL     T
A01:
        RCL     U       ; RCL 4
        SIN
        RCL     Z       ; RCL 3
        *
        RCL     X       ; RCL 1
        /
        ASIN            ; SIN^-1
        STOP
        STO     W       ; STO 6
A10:
        RCL     W       ; RCL 6
        RCL     U       ; RCL 4
        +
        STO     V       ; STO 5
        GTO     A19
A15:
        RCL     V       ; RCL 5
        RCL     U       ; RCL 4
        +
        STO     W       ; STO 6
A19:
        RCL     V       ; RCL 5
        SIN
        RCL     W       ; RCL 6
        SIN
        /        
        RCL     Z       ; RCL 3
        *
        STO     Y       ; STO 2
A27:
B17:
        RCL     U       ; RCL 4
        RCL     Y       ; RCL 2
        XEQ     P2R     ; ->R
        RCL     Z       ; RCL 3
        x<>y
        -
        XEQ     R2P     ; ->P
        STO     X       ; STO 1
        x<>y
        STO     V       ; STO 5
        RCL     U       ; RCL 4
        +
        COS
        +/-
        ACOS
        STO     W       ; STO 6
        SIN
        *
        RCL     Y       ; RCL 2
        *
        2
        /
        RTN
B01:
        RCL     Y       ; RCL 2
        x^2
        RCL     Z       ; RCL 3
        x^2
        +
        RCL     X       ; RCL 1
        x^2
        -
        RCL     Y       ; RCL 2
        RCL     Z       ; RCL 3
        *
        2
        *
        /
        ACOS
        STO     U       ; STO 4
        GTO     B17
P2R:
        x<>y
        SIN
        LASTx
        COS
        Rv
        x<>y
        *
        R^
        LASTx
        *
        RTN
R2P:
        x<>y
        i
        *
        +
        ARG
        LASTx
        ABS
        RTN
ENDS

END
