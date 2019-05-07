# Series and parallel circuits C
This program calculates a fairly simple serial or parallel circuit with just a few components.

- R: Resistance
- C: Capacitor
- L: Inductor
- P: Power
- I: Current
- V: Voltage
- G: Conductance
- Z: Electrical impedance

## Example
```
R = ? Ohm
R1 = 1000 Ohm, R2 = 1200 Ohm
```

### Load Prg C
```
XEQ C ENTER
```

### Start Solving
The first choice is whether the calculation should be done for parallel or serial circuits

```
1PAR 2SER
  1 R/S
```

Next comes the unit to be calculated
```
1R 2C 3L 4P 5I 6G 7Z
  1 R/S
```

Subsequently, any number of values are read in until the value 0 is entered
```
\>(I)
  1000 R/S
```
```
\>(I)
  1200 R/S
```
```
\>(I)
  0 R/S
```

Output as value V
```
V=
  545.4545
```
