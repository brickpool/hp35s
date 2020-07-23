# Bowling for the HP-35s

This program is from Paul Peraino and is used here by permission.

Please visit [atariarchives.org](https://www.atariarchives.org/basicgames/showpage.php?page=26)
for more information.

### Description

The game of bowling takes mind and skill. During the game the computer will keep
score. You may compete with other players (up to four). You will be playing ten
frames on the pin diagram 'o' means the pin is down... '+' means the pin is
standing. After the game the computer will show your scores.

## Listing

The following variables are used:

- Score = A, Register (1)..(300)
- Ball = (0..1)
- Pin = C, Register (301)..(315)
- Number of Pins = D (0..10)
- Frames = F (1..10)
- Index = I, J, K, L
- Number of Player = P, R (1..4)
- Row = T (0..15)
- Other = Q, M, X

The following flags are used:

- SF 10 = Display Flag

The original listing is stored in the file `Bowling.bas`.

Command line options

```
perl -Ilib asm2hpc.pl --jumpmark --plain --file=examples/3rd-party/Bowling/B.asm > examples/3rd-party/Bowling/B.txt
perl -Ilib asm2hpc.pl --jumpmark --shortcut --unicode --file=examples/3rd-party/Bowling/B.asm > examples/3rd-party/Bowling/B.35s
```
