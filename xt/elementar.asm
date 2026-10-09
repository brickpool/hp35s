; Ported to HP-35s
;
; Tricks, tips, and routines for HP-41 series calculators
; Chapter 1
; Elementary functions and operations
MODEL P35S

SEGMENT elementar CODE

; 1-1 Displaying standard characters
; ---------------------------------------
; Setting flag 10 is required. Create the desired string with the 'EQN' command.
; Numbers, parentheses, and operators can be selected directly. For alpha
; characters, first execute `RCL`, then press an alpha key (red label). Other
; mathematical or special characters can be generated using functions or
; constants, then edited with the arrow and backspace keys ('\BS') as needed.
; See the character table:
; Character set:
; https://github.com/brickpool/hp35s/wiki/Character-Set#equation-character


; 1-2 Positioning
; ------------------
; In RUN or PRGM mode, 'GTO.' followed by a "global label" (e.g. "A") and
; 'ENTER' positions the HP-35s at that label in program memory. The '.' is not
; needed in RUN mode. 'GTO.' followed by a letter and a 3-digit number moves
; the pointer to that line number in the program, which must be present in the
; calculator. Programs can have no more than 999 lines. Line numbers without
; a global label (4 digits) cannot be addressed.
;
; ### Lost pending returns
; All returns that would be triggered by 'RTN' commands are lost if a
; subroutine is called manually with 'XEQ' or if 'SHIFT RTN' is pressed.
;
; ### Decimal points and exponents
; In PRGM mode, when entering a number with more than 12 characters (including
; the exponent), an arrow indicates that more characters are present.
; The HP-35s allows any number of characters, as long as enough memory remains.
;
; ### 'R/S' compared with 'STOP'
; A running program can be stopped with 'R/S'. If no program is running,
; 'R/S' starts the program at the line where the calculator is positioned.
;
; - Source: HP User's Guide, part number F2215AA-90002
; - Source: Character code chart:
; https://github.com/brickpool/hp35s/wiki/Character-Set#character-code-chart
; - Source: HP 35s Calculator - Programming:
; https://support.hp.com/us-en/document/c01747644


; 1-3 Symbol names
; -----------------------
; Symbols commonly used on the HP-41 are not available on the HP-35s.
LBL A
  SF 10

  ; 'Gray goose': not available as a character; the equivalent follows.
  eqn ')-'

  ; 'Inverted gray goose': not available as a character; the equivalent follows.
  eqn '-('

  ; 'Text-T' or superscript T:
  ; Exists as the character '\^T', but cannot be entered on the HP-35s.
  ; The equivalent follows.
  eqn '\^t'

  ; Text-string character or 'lazy T': not available as a character;
  ; the equivalent follows.
  eqn '[-'

  ; 'Full character': exists as the character '\[]', but cannot be entered
  ; on the HP-35s.

  ; Useful HP-35s symbols
  ; 'Right arrow':
  eqn '\->'

  ; 'STO symbol':
  eqn '\|>'

  CF 10
RTN


; 1-5 Using alpha labels
; ------------------------------
; Programs or routines should begin with a label. To add a program label, give
; the 'LBL' command a name consisting of one alpha character (a program label
; uses 3 bytes). The alpha character is a single letter from A to Z. A label
; can only be assigned once; an attempt to reuse one produces the
; 'DUPLICAT.LBL' message. This limits the HP-35s to 26 labels.
; - Source: Program boundaries:
; https://support.hp.com/us-en/document/c01747644#boundary


; 1-6 Missing conditional branches
; -----------------------------------
; Unlike the HP-41, the HP-35s provides the x>=0?, x>=y?, x<=0?, and x<=y?
; commands. To test 'x>0?', you can still use 'x!=0?' followed by 'x>0?'; to
; test 'x>=y?', you can use 'x!=y?' followed by 'x>y?'. Each alternative
; requires 3 additional bytes.


; 1-7 Showing final digits in 'SCI' display mode
; --------------------------------------------------------
; Select SCI 11 to display the maximum number of digits.
; The arrow keys can also show an exponent with multiple digits.


; 1-9 Full memory clear
; -----------------
; To clear all memory, hold down the clear/cancel key ('\CC'), then hold down
; 'R/S' and also press 'i' ('\im'). Release all three keys; if successful,
; the message "MEMORY CLEAR" appears.
; - Source: HP User's Guide, part number F2215AA-90002


; 1-10 Bytes
; ----------
; HP-35s commands use only 3 bytes each, while numbers (e.g. '0') and
; equations ('EQN') use at least 38 bytes (35 + 3 for the command). If a
; program contains repeated numbers, equations, or text, 33 bytes can be
; saved for each occurrence by calling a subroutine. This assumes the
; subroutine consists of one line followed by 'RTN'.


; 1-20 Entering exponents
; -----------------------------
; There is no need to enter more digits after 'E' than are necessary.
; - Source: Bill Kolb (265).


; 1-23 Unresponsive keys
; ---------
; Unresponsive keys can feel like a disaster to the user. Before resetting the
; calculator, check whether only one or a few keys have failed, since the
; HP-35s can only be programmed using its keyboard.
;
; Some users have had success (and it may be worth trying) "repairing" a key
; by flushing it with alcohol (pure isopropanol). Use a syringe to apply the
; liquid several times between the key cap and faceplate. Shake off excess
; alcohol and let the calculator dry.
;
; If this does not work and the only alternative is to buy another calculator,
; the following repair attempt may be its last chance. The procedure is:
;
; 1.
;   Remove the rubber plugs in the four corners of the battery compartment,
;   then peel off the rubber strip on the bottom of the calculator and remove
;   the six screws. The front and rear case halves are also held together by
;   five plastic clips: one at the center of the top edge, one in the middle
;   of each side, and one near the bottom of each side.
;
; 2.
;   Gently pull and carefully pry the case halves apart. Remove the 25 small
;   screws holding the circuit board, but note that the board is still not
;   free. On closer inspection, you will see the posts into which the screws
;   were threaded. Cut the posts flush with the circuit board, then carefully
;   pry the board free. Once the board is removed, a thin rubber membrane is
;   exposed, followed by the keys themselves. The keys are attached in two
;   groups to a plastic frame; the four arrow keys are attached to a separate
;   rubber membrane.
;
; 3.
;   The front of the main board is covered with a thin sheet of white plastic.
;   Small bumps visible through the plastic are the contacts. The white sheet
;   is bonded across the circuit board, with metal domes between the sheet and
;   the board. Peel off the sheet to clean any troublesome bumps on the board.
;   Reassemble in reverse order, reattaching the plastic sheet.
;
; - Source: MoHPC - (HP-35s) Are bad keys fixable?
; https://www.hpmuseum.org/forum/thread-6722.html


; 1-25 SGN
; --------
; Unlike on the HP-41, the 'SGN' function works on the HP-35s. It returns 0
; for an argument of 0, -1 for negative numbers, and 1 for positive numbers.
; - Source: HP User's Guide, part number F2215AA-90002




ENDS elementar

END
