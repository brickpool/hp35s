# Wye-Delta or Star-delta Transformation Y

http://www.electronics-tutorials.ws/dccircuits/dcp_10.html
```
T-Network       Star-Network
1-[P]-.-[Q]-2         1
      |               |
     [R]             [P]
      |               |
 -----+-----         / \
      3         3 [R]   [Q] 2

Pi-Network      Delta-Network
1--.-[A]-.--2        1
   |     |          / \
  [B]   [C]        B   A
   |     |        /     \
 --'--.--'--   3 '---C---' 2
      3
```

# Example
```
P = ? Ohm, Q = ? Ohm, R = ? Ohm
A = 20 Ohm, B = 30 Ohm, C = 80 Ohm
```

## Load Prg Y
```
XEQ Y ENTER
```
```
1T->pi 2pi->T 3S->D 4D->S
  4 R/S
```
```
A?
  20 R/S
```
```
B?
  30 R/S
```
```
C?
  80 R/S
```
```
P=
  4.61
```
```
Q=
  12.31
```
```
R=
  18.46
```
