rem Output with HP character set
asm2hpc.pl --file=C/C.asm > C/C.txt
asm2hpc.pl --file=J/J.asm > J/J.txt
asm2hpc.pl --file=O/O.asm > O/O.txt
asm2hpc.pl --file=P/P.asm > P/P.txt
asm2hpc.pl --file=Y/Y.asm > Y/Y.txt

rem Output as Plain text (7-bit ASCII) with shortcut keys as comment and an asterisk at the jump target
asm2hpc.pl --jumpmark --shortcut --plain --file=C/C.asm > C/C.asc
asm2hpc.pl --jumpmark --shortcut --plain --file=J/J.asm > J/J.asc
asm2hpc.pl --jumpmark --shortcut --plain --file=O/O.asm > O/O.asc
asm2hpc.pl --jumpmark --shortcut --plain --file=P/P.asm > P/P.asc
asm2hpc.pl --jumpmark --shortcut --plain --file=Y/Y.asm > Y/Y.asc

rem Output as Markdown (inline HTML 5) with shortcut keys and an asterisk at the jump target
asm2hpc.pl --jumpmark --shortcut --markdown --file=C/C.asm > C/C.md
asm2hpc.pl --jumpmark --shortcut --markdown --file=J/J.asm > J/J.md
asm2hpc.pl --jumpmark --shortcut --markdown --file=O/O.asm > O/O.md
asm2hpc.pl --jumpmark --shortcut --markdown --file=P/P.asm > P/P.md
asm2hpc.pl --jumpmark --shortcut --markdown --file=Y/Y.asm > Y/Y.md

rem Output as Unicode (UTF-8) with shortcut keys and an asterisk at the jump target
asm2hpc.pl --jumpmark --shortcut --unicode --file=C/C.asm > C/C.35s
asm2hpc.pl --jumpmark --shortcut --unicode --file=J/J.asm > J/J.35s
asm2hpc.pl --jumpmark --shortcut --unicode --file=O/O.asm > O/O.35s
asm2hpc.pl --jumpmark --shortcut --unicode --file=P/P.asm > P/P.35s
asm2hpc.pl --jumpmark --shortcut --unicode --file=Y/Y.asm > Y/Y.35s
