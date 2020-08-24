# Cows and Bulls (Mastermind) for the HP-35s

This program is by Bill Harrington and is used here by permission.

Please visit the [Museum of HP Calculators Website](https://www.hpmuseum.org/software/35cowbul.htm) for more information.

## Overview
_Cows and Bulls_ is a games where the player trys to guess an _x_ digit random integer with feedback for each guess indicting how many correct digits in the correct location (_Bulls_) and correct digits in the wrong location (_Cows_). The score is given as `<bulls>.<cows>`, eg. if the secret number is `12325`, a guess of `43321` would score `2.1`

To play, enter the length of the number `L` in digits and then successive guesses `G`. Your score `S` is calculated for each guess.

### Load Prg C
```
XEQ C ENTER
```

### Example

enter the length for the number, eg. 4 digits
```
L?
  4 R/S
```

enter your guess for the number
```
G? 
  1234 R/S
```

your score `<bulls>.<cows>`, eg `1.2` means one digit in the correct location and 2 digits in the wrong location.
```
S=1.2
  R/S
```
enter you next guess
```
G? 
  2345 R/S
```

## Listing

The following variables are used:

- Number = N (eg. 0.nnnn), M, V, A
- Length = L (eg. 4)
- Guess = G, U, B
- Score = S

The original listing is stored in the file `C.raw`.

There are a few language differences to the original listing

```
-C001  Lbl C
+C001  LBL C

-C003  RAND
+C003  RANDOM

-C008  10x
-C009  STO / G
+C008  10^x
+C009  STO/ G

-C018  STO * M
+C018  STO* M
-C019  STO * G
+C019  STO* G

-C034  X=Y
+C034  x=y?

-C036  STO + U
+C036  STO+ U

-C038  STO + V
+C038  STO+ V

-C040  STO / V
-C041  STO / U
+C040  STO/ V
+C041  STO/ U

-C044  STO + S
-C045  Dse X
+C044  STO+ S
+C045  DSE X

-C053  X=0
+C053  x=0?

-C060  STO * G
+C060  STO* G

-C074  STO * M
+C074  STO* M

-C085  STO + V
+C085  STO+ V

-C087  STO / V
+C087  STO/ V

-C090  STO + T
-C091  -/+
+C090  STO+ T
+C091  +/-

-C093  Dse Y
+C093  DSE Y

-C095  Dse X
+C095  DSE X

-C100  STO + S
+C100  STO+ S
```

Command line options

```
perl -Ilib asm2hpc.pl --jumpmark --plain --file=examples/3rd-party/CowsAndBulls/C.asm > examples/3rd-party/CowsAndBulls/C.txt
perl -Ilib asm2hpc.pl --jumpmark --shortcut --unicode --file=examples/3rd-party/CowsAndBulls/C.asm > examples/3rd-party/CowsAndBulls/C.35s
```
