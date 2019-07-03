# Hack and Slash Adventure for the HP-35s

This program is by Paul Dale and is used here by permission.

Please visit [hpmuseum.org](https://www.hpmuseum.org/software/35hacksl.htm) for more information.

The original listing is stored in the file `D.raw`

## Assembler

There are a few language differences

```
-D043  X<>Y
+D043  x<>y
-D097  x<=0
+D097  x<=0?
-D456  x<>0?
+D456  x!=0?
-D641  SQRT
+D641  sqrt
```

Command line options

```
asm2hpc.pl --jumpmark --shortcut --unicode --file=../other/D/D.asm > ../other/D/D.txt
```
