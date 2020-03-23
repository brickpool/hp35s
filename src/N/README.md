General purpose single bipolar timers
=====================================
This program is inspired by a third party program _"Peripherie-Bauteile des IC NE-555"_, which was design for the _HP41C_ by Burkhard Oerttel.

The _NE555_ monolithic timing circuit producing time delays or oscillation. Further information on component _NE555_ can be found in the [datasheet](https://www.st.com/resource/en/datasheet/CD00000479.pdf) or at [Wikipedia](https://en.wikipedia.org/wiki/555_timer_IC).

The following variables are used for both operating modes.

- I: Index
- (0): Constant ln(3)
- (1): Constant ln(2)

### Load Prg N

```
XEQ N ENTER
```

### Run
Choice operation mode monostable (timer) or astable (oscillator).

```
1MONO 2ASTABLE
  1 R/S
```


Monostable operation
--------------------

In the time delay mode of operation, the time `t` is controlled by one external resistor `R1` and capacitor `C1`.

The following flags and additional variables are used:

- 0: direct call of program `A`
- R: Resistance R1
- C: Capacitor C1
- T: Duration time t (output HIGH)


### Example:

```
t = ? sec
R1 = 1200 Ohm
C1 = 1 uF
```

### Load Prg A

```
XEQ A ENTER
```

### Run

```
T?
  0 R/S
```
```
R?
  1000 R/S
```
```
C?
  1E-6 R/S
```

### Output

```
T=
  0.0013
```


Astable operation
-----------------

For an oscillator, the frequency and the duty cycle are controlled with two external resistors and one capacitor. The external capacitor `C1` charges through `R1` and `R2` (if there is no Diode `D1`) and discharges through `R2` only.

The following flags and additional variables are used:

- 0: direct call of program `B`
- 4: Diode parallel R2
- F: Frequency oscillation f
- A: Resistance R1
- B: Resistance R2
- C: Capacitor C1
- P: Charge time T+ (output HIGH)
- M: Discharge time T- (output LOW)


### Example

```
f = ? Hz
R1 = 1000 Ohm
R2 = 1200 Ohm
C1 = 1 uF
```

### Load Prg B

```
XEQ B ENTER
```

### Run
Choice for which value the calculation should be carried out

```
1F 2T 3R 4C
  1 R/S
```

Then all necessary values are queried

```
R1>A
A?
  1000 R/S
```
```
R2>B
B?
  1200 R/S
```
```
C?
  1E-6 R/S
```

### Output
```
F=
  424.3221
```
