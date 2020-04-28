# Program to convert a Complex number to polar and then Rectangular parts

This program is by Barry More and is used here by permission.

Please visit the [HP-35s article](http://www.stefanv.com/calculators/hp35s.html#programming)
from Stefan Vorkoetter and read the comment from Barry More for more
information.

## Obtaining the angle and magnitude of a complex value
 
Use the `ARG` function (`\<+`, `i`) and then `LASTx` and `ABS` (`\+>`, `+/-`)
function. This leaves _R_ (radial coordinate _r_) in the `REGX` register and
_T_ (angular coordinate _theta_) in the `REGY` register.

To obtain the _iY_ (imaginary value) and the _X_ (real value), you then need to
use `R*COS(T)` for _X_ and `R*SIN(T)` for _Y_.

A simple program of 18 lines (`R.asm`) can do this both these conversions on a
complex number placed in the `REGX` register. The program stops to show _T_ in
the `REGY` register, _R_ in the `REGX` register, then pressing `R/S` to then get
imaginary part of _Y_ in `REGY` register and real part of _X_ in the `REGX`
register.

## Converting X and Y to a complex number

Converting the _X_ and _Y_ to a complex number is trivial:

```assembly
<Y> ENTER ; enter Y
\im       ; press i (imaginary)
*         ; multiply
<X> ENTER ; enter X
+         ; summate
```

## Converting R and T to a complex number

Converting _R_ and _T_ to a complex number is bit more effort and used
[de Moivre's theorem](https://en.wikipedia.org/wiki/De_Moivre's_formula):

```assembly
DEG       ; Set degree mode
<T> ENTER ; enter Theta (in degrees)
->RAD     ; convert to Radian
\im       ; press i (imaginary number)
*         ; multiply
e^x       ; EXP(REGX)
<R> ENTER ; enter R
*         ; multiply
```

## Listing

The original listing is stored in the file `R.raw`.

There are a few language differences to the original listing

```
-R006  xy
+R006  x<>y

-R010  Rdown
-R011  Rdown
-R012  xy
-R013  Rdown
-R014  X
-R015  xy
+R010  Rv
+R011  Rv
+R012  x<>y
+R013  Rv
+R014  *
+R015  x<>y

-R017  xy
+R017  x<>y
```

## Command line options

```
perl -Ilib asm2hpc.pl --jumpmark --file=examples/3rd-party/R/R.asm > examples/3rd-party/R/R.txt
perl -Ilib asm2hpc.pl --jumpmark --shortcut --unicode --file=examples/3rd-party/R/R.asm > examples/3rd-party/R/R.35s
```
