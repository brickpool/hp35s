# Hack and Slash Adventure for the HP-35s

This program is by Paul Dale and is used here by permission.

Please visit the [Museum of HP Calculators Website](https://www.hpmuseum.org/software/35hacksl.htm) for more information.

## Listing

The original listing is stored in the file `D.raw`.

There are a few language differences to the original listing

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
perl -Ilib asm2hpc.pl --jumpmark --shortcut --unicode --file=examples/3rd-party/D/D.asm > examples/3rd-party/D/D.35s
```
