; Cows and Bulls (Mastermind) for the HP-35s/33s
; This program is by Bill Harrington and is used here by permission.
; https://www.hpmuseum.org/software/35cowbul.htm
MODEL P35S

SEGMENT CowsAndBulls CODE
LBL C
  INPUT L
  RANDOM
  STO N
  @005:
    INPUT G
    RCL L
    STO X
    10^x
    STO/ G
    0
    STO S
    STO T
    STO U
    STO V
    RCL N
    STO M
    @017:
      10
      STO* M
      STO* G
      RCL M
      IP
      STO A
      RCL M
      FP
      STO M
      RCL G
      IP
      STO B
      RCL G
      FP
      STO G
      RCL A
      RCL B
      x=y?
        GTO @043
        STO+ U
        Rv
        STO+ V
        10
        STO/ V
        STO/ U
        GTO @045
      @043:
      1
      STO+ S
    @045:
    DSE X
    GTO @017
;
    RCL U
    STO G
    RCL L
    RCL S
    -
    STO X
    x=0?
      GTO @101
      @055:
        RCL V
        STO M
        0
        STO V
        10
        STO* G
        RCL G
        IP
        STO B
        RCL G
        FP
        STO G
        RCL L
        RCL S
        -
        RCL T
        -
        STO Y
        @073:
          10
          STO* M
          RCL M
          IP
          STO A
          RCL M
          FP
          STO M
          RCL B
          RCL A
          x=y?
            GTO @089
            STO+ V
            10
            STO/ V
            GTO @093
          @089:
          1
          STO+ T
          +/-
          STO B
        @093:
        DSE Y
        GTO @073
      DSE X
      GTO @055
      RCL T
      10
      /
      STO+ S
    @101:
    VIEW S
  GTO @005
ENDS CowsAndBulls

END
