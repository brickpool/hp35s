# Find the nearest fraction in the E24 numbers

This program is by Takayuki Hosoda (alias Lyuka) and is used here by permission.

Please visit [_Lyuka's_ personal Website](http://www.finetune.co.jp/~lyuka/technote/e24/e24-35s.html)
and the Wikipedia Page [E series of preferred numbers](https://en.wikipedia.org/wiki/E_series_of_preferred_numbers#Overview)
for more information.

## Program usage

The input value must be in the REGX register.

The output values (Vector format) are in REGY and REGX.

- REGY = next candidate: [numerator, denominator, error]
- REGX = nearest E24 pair: [numerator, denominator, error]

### Load program 

```
XEQ E ENTER
```

### Example

```
9.6774
XEQ E ENTER
```
```
RUNNING
```
```
[16.000, 1.6000, 0.0323]
[15.e0, 1.6e0, 32.256e-3]
```

## Listing

The following variables are used:

- R00-23 = E24 series
- I = index I
- J = index J
- K = offset
- N = normalized value
- P = previous error
- Q = previous candidate
- R = answer
- S = scaled numerator
- X = scaling factor

Command line options

```
perl -Ilib asm2hpc.pl --jumpmark --plain --file=examples/3rd-party/E24/E.asm > examples/3rd-party\E24\E.txt
perl -Ilib asm2hpc.pl --jumpmark --shortcut --unicode --file=examples/3rd-party/E24/E.asm > examples/3rd-party/E24/E.35s
```
