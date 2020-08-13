# Triangle

This program calculates the sides, angles and area of a triangle

```
      A3
      /'.
  S2 /   '. S1
    /      '.
A1 '---------' A2
       S3
```

Of the 6 sizes of a triangle (3 sides and 3 angles) are sufficient generally 3
independent quantities to determine it clearly. The case of 3 angles is ruled
out as they are not independent of one another. There are therefore 5 cases that
can be calculated by this program.

1. [SSA](#case-ssa): Two sides and the angle opposite one side.
2. [SAA](#case-saa): One side, an adjoining angle and the opposite angle.
3. [ASA](#case-asa): One side and the two adjacent angles.
4. [SAS](#case-sas): Two sides and the angle they enclose.
5. [SSS](#case-sss): Three sides.

The results and the input values are saved in the following registers:

- Side 1: X
- Side 2: Y
- Side 3: Z
- Angle 1: U
- Angle 2: V
- Angle 3: W

The area is not stored in any data register. The area is always shown in the
display at the end of the calculation (X register).

### Notes:

- Any angle mode can be used.
- Angles must be entered in decimal form.
- The accuracy of the results decreases at very small angles.
- In the case of SSA, the program does not determine whether 2 solutions are
possible.


## Case SSA

Input S<sub>1</sub>, S<sub>3</sub>, A<sub>1</sub>

```assembly
; Side 1
STO 1
```
```assembly
; Side 3
STO 2
```
```assembly
; Angle 1
STO 4
```
```assembly
; GSB 01
XEQ T002
R/S
```

[Output...](#output)

This case can have two solutions if the angle is smaller than 90° and the side
adjacent to this angle is larger than the opposite side.

```assembly
+/-
R/S
```

[Output...](#output)

## Case SAA

Input S<sub>3</sub>, A<sub>1</sub>, A<sub>3</sub>

```assembly
; Side 3
STO 3
```
```assembly
; Angle 1
STO 4
```
```assembly
; Angle 3
STO 6
```
```assembly
; GSB 10
XEQ T011
```

[Output...](#output)


## Case ASA

Input A<sub>1</sub>, S<sub>3</sub>, A<sub>2</sub>

```assembly
; Angle 1
STO 4
```
```assembly
; Side 3
STO 3
```
```assembly
; Angle 2
STO 5
```
```assembly
; GSB 16
XEQ T011
```

[Output...](#output)

## Case SAS

Input S<sub>2</sub>, A<sub>1</sub>, S<sub>3</sub>

```assembly
; Side 2
STO 2
```
```assembly
; Angle 1
STO 4
```
```assembly
; Side 3
STO 3
```
```assembly
; GSB 27
XEQ T028
```

[Output...](#output)

## Case SSS

Input S<sub>1</sub>, S<sub>2</sub>, S<sub>3</sub>

```assembly
; Side 1
STO 1
```
```assembly
; Side 2
STO 2
```
```assembly
; Side 3
STO 3
```
```assembly
; GSB 01
XEQ T051
```

[Output...](#output)

## Output 

Show register contents for solution

```assembly
; Area
XX.XX
```
```assembly
; Side 1
RCL 1
```
```assembly
; Side 2
RCL 2
```
```assembly
; Side 3
RCL 3
```
```assembly
; Angle 1
RCL 4
```
```assembly
; Angle 2
RCL 5
```
```assembly
; Angle 3
RCL 6
```


# Links

- [HP-33E/C Application Book, S. 47, 00033-90070](https://www.hpmuseum.org/software/swcdp.htm#fl)
