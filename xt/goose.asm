IDEAL
P35S
MODEL TINY

CODESEG
LBL A
  SF 10

FOR:
  1.01
  STO I
  CLx
DO:
    eqn ')-'
    PSE
    eqn ' )-'
    PSE
    eqn '  )-'
    PSE
    eqn '   )-'
    PSE
    eqn '    )-'
    PSE
    eqn '     )-'
    PSE
    eqn '      )-'
    PSE
    eqn '       )-'
    PSE
    eqn '        )-'
    PSE
    eqn '         )-'
    PSE
    eqn '          )-'
    PSE
    eqn '           )-'
    PSE
    eqn '            )-'
    PSE
  ISG I
    GTO DO
NEXT:
    
  CF 10

END
