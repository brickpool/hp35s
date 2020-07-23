# Mugwump for the HP-35s

This program is from Bob Albrecht and is used here by permission.

Please visit [atariarchives.org](https://www.atariarchives.org/basicgames/showpage.php?page=114) or
[Wikipedia](https://en.wikipedia.org/wiki/Mugwump_(video_game)) for more information.

### Description

The object of this game is to find four Mugwumps hidden on a 10 by 10 grid.
Homebase is position 0,0. Any guess you make must be two numbers with each
number between 0 and 9, inclusive. First number is distance to right (X) of
homebase and second number is distance above homebase (Y).

You get 10 tries. After each try, the calculator will tell you how far you are
from each Mugwump.

```
 y 
 ^
10 _ _ _ _ _ _ _ _ _ _
 9|_|_|_|_|_|_|_|_|_|_|
 8|_|_|_|_|_|_|_|_|_|_|
 7|_|_|_|_|_|_|_|_|_|_|
 6|_|_|_|_|_|_|_|_|_|_|
 5|_|_|_|_|_|_|_|_|_|_|
 4|_|_|_|_|_|_|_|_|_|_|
 3|_|_|_|_|_|_|_|_|_|_|
 2|_|_|_|_|_|_|_|_|_|_|
 1|_|_|_|_|_|_|_|_|_|_|
 0|_|_|_|_|_|_|_|_|_|_|
  0 1 2 3 4 5 6 7 8 9 10 > x
```

### Example

Start
```
MUGWUMP
```

Display turn no.
```
TURN NUM
```
```
    1
```

Enter your guess (position) eg. [5,5]
```
YOUR GUESS
```
```
X?
    5 R/S
```
```
Y?
    5 R/S
```

Your distance to each mugwump
```
UNITS
```
```
FROM MUGWUMP
```
```
(1)=
    4.0
```
```
UNITS
```
```
FROM MUGWUMP
```
```
(2)=
    3.1
```
```
UNITS
```
```
FROM MUGWUMP
```
```
(3)=
    4.2
```
```
UNITS
```
```
FROM MUGWUMP
```
```
(4)=
  5.0
```

next turn no.
```
TURN NUM
```
```
    2
```

Enter your next guess
```
YOUR GUESS
```
```
X?
    0 R/S
```
```
Y?
    0 R/S
```

Your distance to the mugwumps
```
UNITS
```
```
FROM MUGWUMP
```
```
(1)=
    10.2
```
```
UNITS
```
```
FROM MUGWUMP
```
```
(2)=
    8.9
```
```
UNITS
```
```
FROM MUGWUMP
```
```
(3)=
    11.3
```
```
UNITS
```
```
FROM MUGWUMP
```
```
(4)=
    5.0
```


You get 10 tries
```
SORRY,10 TRIES
```
```
HERE THEY ARE
```
```
MUGWUMP AT
```
```
(1)=
    [9,5]
```
```
MUGWUMP AT
```
```
(2)=
    [8,4]
```
```
MUGWUMP AT
```
```
(4)=
    [5,0]
```
```
PLAY AGAIN
```

## Listing

The following variables are used:

- Mugwumps = Register (1)..(4)
- Index = I, J
- Guess = X, Y (0..9)
- Turns = T (1..10)
- Number of Mugwumps = P (4)

The following flags are used:

- SF 10 = Display Flag


The original listing is stored in the file `Mugwump.bas`.

Command line options

```
perl -Ilib asm2hpc.pl --jumpmark --plain --file=examples/3rd-party/Mugwump/M.asm > examples/3rd-party/Mugwump/M.txt
perl -Ilib asm2hpc.pl --jumpmark --shortcut --unicode --file=examples/3rd-party/Mugwump/M.asm > examples/3rd-party/Mugwump/M.35s
```
