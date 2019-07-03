# The Assembler

The perl script `asm2hcp.pl` converts an assembler program to HP35s native program code.

The assembler _directives_, _symbols_ and _error messages_ are described in the [wiki](http://github.com/brickpool/hp35s/wiki).

## Usage
```
asm2hpc.pl --help
USAGE:
  c:> type <asm-file> | perl asm2hpc.pl [options] 1> outfile.35s 2> outfile.err

VERSION: 0.3.7
  Web: http://www.brickpool.de/

OPTIONS:
  -h, --help          Print this text
  -v, --version       Prints version
  -j, --jumpmark      Prints an asterisk (*) at the jump target
  -p, --plain         Output as Plain text (7-bit ASCII)
  -m, --markdown      Output as Markdown (inline HTML 5)
  -u, --unicode       Output as Unicode (UTF-8)
  -s, --shortcut      Output shortcut keys as comment
  --debug             Show debug information on STDERR

  --file=<asm-file>:
    Location of asm-file (Default is STDIN)

This script converts an assembler program to HP35s native program code
The output will be sent to STDOUT
```

## Example
```
asm2hpc.pl --file=C/C.asm > C/C.txt
asm2hpc.pl --plain --shortcut --file=C/C.asm > C/C.raw
asm2hpc.pl --unicode --shortcut --file=C/C.asm > C/C.35s
```
