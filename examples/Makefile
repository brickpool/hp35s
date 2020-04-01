# Sources
SOURCE += C\C.asm
SOURCE += J\J.asm
SOURCE += N\NE555.asm
SOURCE += O\O.asm
SOURCE += P\P.asm
SOURCE += Y\Y.asm

# Targets
TEXT = ${SOURCE:.asm=.txt}
PLAIN = ${SOURCE:.asm=.raw}
MARKDOWN = ${SOURCE:.asm=.md}
UNICODE = ${SOURCE:.asm=.35s}
ENCODED = ${SOURCE:.asm=.uu}
MACRO = ${SOURCE:.asm=.mac}
MACRO_DIR = ..\AppData\Macros
TARGET_DIR := ${shell echo %APPDATA%}\Roaming\Hewlett-Packard\hp35s\Macros

# Tools
SH = +
PERL = $(SH)perl
ASM = $(PERL) -I..\lib ..\asm2hpc.pl
UUDECODE = $(PERL) ..\extras\tools\uudecode.pl
RM = $(SH)del /Q
MV = $(SH)move /Y
CP = $(SH)xcopy /M /I /Y

all: $(TEXT) $(PLAIN) $(MARKDOWN) $(UNICODE) $(MACRO)

.PHONY: all

# Output with HP character set
%.txt: %.asm
	$(ASM) -f $< > $@

# Output as Plain text (7-bit ASCII) with an asterisk at the jump target
%.raw: %.asm
	$(ASM) -j -p -f $< > $@

# Output as Markdown (inline HTML 5) with an asterisk at the jump target
%.md: %.asm
	$(ASM) -j -m -f $< > $@

# Output as Unicode (UTF-8) with shortcut keys and an asterisk at the jump target
%.35s: %.asm
	$(ASM) -j -s -u -f $< > $@

# Output keystrokes as ASCII encoded string.
%.uu: %.asm
	$(ASM) -e -f $< > $@

# Uu decode to target *.mac
%.mac: %.uu
	$(UUDECODE) $<
	$(CP) $(@F) $(MACRO_DIR)
	$(MV) $(@F) $(@D)

# Intall macro files
install:
	$(CP) $(MACRO_DIR) $(TARGET_DIR)

# Clean up
clean:
	$(RM) $(ENCODED)
	$(RM) $(MACRO)

realclean:
	$(RM) $(PLAIN)
	$(RM) $(TEXT)
	$(RM) $(MARKDOWN)
	$(RM) $(ENCODED)
	$(RM) $(MACRO)
