# Program to calculate Bernoulli Numbers

This program is by Jean-Marc Baillard and is used here by permission.

Please visit the [Museum of HP Calculators](https://www.hpmuseum.org/software/41/41bernu.htm)
and read the documentation from Jean-Marc Baillard for more information.

## Listing

The original listing is stored in the file `41bernu.raw`.
The original subroutine "ZETA" is stored in the file `41rzeta.raw`.

There are a few language differences to the original listing

```assembly
-01     LBL "BERN"
+B001   LBL B

-02     STO 02
+B002   STO C

-04     X>Y?
+B004   x>y?

-06     ST+ X
+B006   STO X
+B007   RCL+ X

-07     X<=Y?
+B008   x<=y?

-08     GTO 00
+B009   GTO B013

-09     1/X
+B010   1/x

-10     CHS
+B011   +/-

-12     LBL 00
+B013*  ...

-13     X#Y?
+B013   x!=y?

-19     MOD
+B018   RMDR

-24     RCL 02
+B023   RCL C

-39     X<>Y
+B036   x<>y

+41     XEQ "ZETA"
+B038   XEQ B062

-48     Y^X
+B046   y^x

-51     PI
+B049   pi

-53     E-9
+B052   1e-9

-61     DSE 02
+B059   DSE C

-63     END
+B061   RTN
```

```
-01     LBL "ZETA"
+B062*  ...

-03     STO 01
+B063   STO B

-05     STO 00
+B065   STO A

-06     ENTER^
+B066   ENTER

; register X = 1
-08     CLX
-09     SIGN
+B067   CLx
+B068   !

-10     RCL 00
+B069   RCL A

-13     RCL 01
+B072   RCL B

-17     LASTX
+B076   LASTx
```

## Command line options

```
perl -Ilib asm2hpc.pl --jumpmark --plain --file=examples/3rd-party/Bernu/B.asm > examples/3rd-party/Bernu/B.txt
perl -Ilib asm2hpc.pl --jumpmark --shortcut --unicode --file=examples/3rd-party/Bernu/B.asm > examples/3rd-party/Bernu/B.35s
```
