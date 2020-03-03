rem Output with HP character set
asm2hpc.pl --file=C/C.asm > C/C.txt
asm2hpc.pl --file=J/J.asm > J/J.txt
asm2hpc.pl --file=N/NE555.asm > N/NE555.txt
asm2hpc.pl --file=O/O.asm > O/O.txt
asm2hpc.pl --file=P/P.asm > P/P.txt
asm2hpc.pl --file=Y/Y.asm > Y/Y.txt

rem Output as Plain text (7-bit ASCII) with an asterisk at the jump target
asm2hpc.pl --jumpmark --plain --file=C/C.asm > C/C.raw
asm2hpc.pl --jumpmark --plain --file=J/J.asm > J/J.raw
asm2hpc.pl --jumpmark --plain --file=N/NE555.asm > N/NE555.raw
asm2hpc.pl --jumpmark --plain --file=O/O.asm > O/O.raw
asm2hpc.pl --jumpmark --plain --file=P/P.asm > P/P.raw
asm2hpc.pl --jumpmark --plain --file=Y/Y.asm > Y/Y.raw

rem Output as Markdown (inline HTML 5) with an asterisk at the jump target
asm2hpc.pl --jumpmark --markdown --file=C/C.asm > C/C.md
asm2hpc.pl --jumpmark --markdown --file=J/J.asm > J/J.md
asm2hpc.pl --jumpmark --markdown --file=N/NE555.asm > N/NE555.md
asm2hpc.pl --jumpmark --markdown --file=O/O.asm > O/O.md
asm2hpc.pl --jumpmark --markdown --file=P/P.asm > P/P.md
asm2hpc.pl --jumpmark --markdown --file=Y/Y.asm > Y/Y.md

rem Output as Unicode (UTF-8) with shortcut keys and an asterisk at the jump target
asm2hpc.pl --jumpmark --shortcut --unicode --file=C/C.asm > C/C.35s
asm2hpc.pl --jumpmark --shortcut --unicode --file=J/J.asm > J/J.35s
asm2hpc.pl --jumpmark --shortcut --unicode --file=N/NE555.asm > N/NE555.35s
asm2hpc.pl --jumpmark --shortcut --unicode --file=O/O.asm > O/O.35s
asm2hpc.pl --jumpmark --shortcut --unicode --file=P/P.asm > P/P.35s
asm2hpc.pl --jumpmark --shortcut --unicode --file=Y/Y.asm > Y/Y.35s

rem Output keystrokes as ASCII encoded string. Uu decode to target *.mac
asm2hpc.pl -e -f C/C.asm | tools\uudecode.pl
asm2hpc.pl -e -f J/J.asm | tools\uudecode.pl
asm2hpc.pl -e -f N/NE555.asm | tools\uudecode.pl
asm2hpc.pl -e -f O/O.asm | tools\uudecode.pl
asm2hpc.pl -e -f P/P.asm | tools\uudecode.pl
asm2hpc.pl -e -f Y/Y.asm | tools\uudecode.pl
xcopy *.mac %APPDATA%\Hewlett-Packard\hp35s\Macros\ /Y
move *.mac ../macros
