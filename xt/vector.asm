MODEL P35S

SEGMENT CODE

LBL G
  ABS
  CLx
  eqn 'ACOS(LASTx*REGY/ABS(LASTx)/ABS(REGY))'
RTN

LBL X
  ABS
  CLx
  eqn 'LASTx*[1,0,0]\|>C'
  CLx
  eqn 'LASTx*[0,1,0]\|>D'
  CLx
  eqn 'LASTx*[0,0,1]\|>Y'
  CLx
  eqn 'REGY*[1,0,0]\|>A'
  CLx
  eqn 'REGY*[0,1,0]\|>B'
  CLx
  eqn 'REGY*[0,0,1]\|>X'
  CLx
  eqn '[B*Y-X*D,X*C-A*Y,A*D-B*C]'
RTN

ENDS

END