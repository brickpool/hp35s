# Approximate Length of Sunlight During a Day for the HP-35s

This program is by Edward Shore and is used here by permission.

Please visit [Edward Shore's Blog](http://edspi31415.blogspot.com/2013/05/hp-35s-approximate-length-of-sunlight.html) for more information.

The original listing is stored in the file `S.35s`

## Input

You are prompted for D and L where:

- D = the number of days from March 21, a 365 day year is assumed
- L = latitude (North as positive, South as negative), entered as D.MMSS (degrees-minutes-seconds) format

## Output

Approximate number of hours of sunlight, in hours, minutes, seconds

## Examples

[Hamburg](https://en.wikipedia.org/wiki/Hamburg), September 1: latitude 53°33' N, 164 days after March 21

```
D?
  164 R/S
```
```
L?
  53.33 R/S
```
```
13.2053
```
(13 hours, 20 minutes, 53 seconds)

## Command line options

```
perl -Ilib asm2hpc.pl --jumpmark --shortcut --file=examples/3rd-party/S/S.asm > examples/3rd-party/S/S.txt
perl -Ilib asm2hpc.pl --unicode --file=examples/3rd-party/S/S.asm > examples/3rd-party/S/S.35s
```
