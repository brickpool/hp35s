# Mancala for the HP-35s

This program is by Dan B. and is used here by permission.

Please visit [Dan's GitHub Pages](https://brianddk.github.io/2016/05/hp-42s-mancala/) for more information.

## Header

```
; https://brianddk.github.io/prog/mancala/mancala.asm

; [rights]  Copyright Dan B. (brianddk) 2016 https://github.com/brianddk
; [license] Licensed under Apache 2.0 https://www.apache.org/licenses/LICENSE-2.0
; [repo]    https://github.com/brianddk/brianddk.github.io/blob/master/prog/mancala/mancala.asm
;
; Mancala game written for the hp 41s scientific calculator, with port to 35s.
;
; Version: 0.1
;
; Rules: https://en.wikipedia.org/wiki/Kalah#Kalah(6,4)
;
; Build:
;   asm2hpc.pl  - by J. Schneider, a assembler to 35s native converter
;       http://github.com/brickpool/hp35s
;
; Bugs:
;   - Display is base 10, so more than 9 beans in a pit is a problem.
;   - When a player empties all thier pits the game is supposed to end... it doesn't.
;
; Layout
;
; R00       - P2 'Home' pit
; R01       - P1 pit #1
; R02       - P1 pit #2
; R03       - P1 pit #3
; R04       - P1 pit #4
; R05       - P1 pit #5
; R06       - P1 pit #6
; R07       - P1 'Home' pit
; R08       - P2 pit #6
; R09       - P2 pit #5
; R10       - P2 pit #4
; R11       - P2 pit #3
; R12       - P2 pit #2
; R13       - P2 pit #1
; R14       - P1 Display Vector
; R15       - P2 Display Vector
; R16       - Virtual 'I' register
; R17       - Virtual 'J' register
; FLAG1     - Player 1 turn flag
; FLAG2     - Player 2 turn flag
; FLAG3     - Winner found flag
; FLAG4     - Bad 'pick' choice flag
;
; Game board (to imagine)
;
; R00-R13 R12 R11-R10 R09 R08
;     R01 R02 R03-R04 R05 R06-R07
;
; Game Display
;
; x: Z,DCB,A98.P2
; y: Z,123,456.P1
;
; Where,
;   'Z,'    - Ignore the 'millionth' place, its a place holder, nothing more
;   'P1'    - The score for Player 1 (in the X vector)
;   'P2'    - The score for Player 2 (in the Y vector)
;   '1|D'   - # of beans in 'pit #1' for P1 and P2
;   '2|C'   - # of beans in 'pit #2' for P1 and P2
;   '3|B'   - # of beans in 'pit #3' for P1 and P2
;   '4|A'   - # of beans in 'pit #4' for P1 and P2
;   '5|9'   - # of beans in 'pit #5' for P1 and P2
;   '6|8'   - # of beans in 'pit #6' for P1 and P2
;
; Indicators
;   'GRAD'  - Player1's turn when 'GRAD' is displayed
;   'RAD'   - Player2's turn when 'RAD' is displayed
```

## Listing

The original listing is stored in the file `mancala.asm`.

There are a few language differences to the original listing

```
- LBL [LABEL-TEXT]
+ label_text:

- XEQ [CALL]
+ XEQ call

- GTO [JUMPTO]
+ GTO jumpto

- "TEXT"
+ eqn 'text'

- X>Y?
+ x>y?

- X<Y?
+ x<y?

- X<=Y?
+ x<=y?

- X<>Y
+ x<>y

- X<> (I)
+ x<> (I)

- X=0?
+ x=0?

- x
+ *

- Y^X
+ y^x

- MOD
+ RMDR

- CLX
+ CLx
```

Command line options

```
perl -Ilib asm2hpc.pl --jumpmark --file=examples/3rd-party/Mancala/M.asm > examples/3rd-party/Mancala/M.txt
perl -Ilib asm2hpc.pl --jumpmark --shortcut --unicode --file=examples/3rd-party/Mancala/M.asm > examples/3rd-party/Mancala/M.35s
```
