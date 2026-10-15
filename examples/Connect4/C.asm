%TITLE "Connect Four for the HP-35s -- by J. Schneider"

        MODEL P35S
        LOCALS

SEGMENT DATA

;-----  Insert EOU and = equates here

        columnFullMsg   EQU 'COLUMN FULL'
        playerWinsMsg   EQU 'YOU WIN'
        cpuWinsMsg      EQU 'I WIN'
        noWinnerMsg     EQU 'NO WINNER'
        playerPromptMsg EQU '\|>COL'
        cpuPromptMsg    EQU 'SET='

;---------------------------------------------------------------
; Board rows are stored in indirect registers I1..I6 as 
; seven-digit values.
;---------------------------------------------------------------

ENDS

;---------------------------------------------------------------
; print         Macro for printing messages
;---------------------------------------------------------------
; Input:
;       msg = message to print
; Output:
;       none
; Notes:
;       set/reset flag 10 for equation mode
;---------------------------------------------------------------
MACRO   print   msg
        SF 10                   ; Begin equation mode
        eqn msg                 ; display equation text
        CF 10                   ; End equation mode
ENDM

SEGMENT CODE
start:
        LBL C
        RPN
        FIX 7
        GTO play

;---------------------------------------------------------------
; play          Run the game until a win or no-winner result
;---------------------------------------------------------------
; Input:
;       none
; Output:
;       none
;---------------------------------------------------------------
play:
        ; Clear the six board rows.
        6
        STO I                   ; Start with bottom board row I6.
@@loop:
        0
        STO(I)                  ; Clear current board row.
        DSE I
            GTO @@loop

        ; Randomly choose which side starts (0=player, 1=CPU).
        RANDOM
        2
        *
        IP
        x=0?
            GTO @player_turn
        GTO @cpu_turn

@player_turn:
        XEQ input_col
        1
        STO B
        XEQ drop
        RCL D
        x=0?
            GTO @column_full
        XEQ display_board
        XEQ won                 ; Test PLAYER currently stored in B.
        FS? 0
            GTO @player_wins
        GTO @cpu_turn

@cpu_turn:
        XEQ cpu_move            ; A = best CPU column, or 0 if board full.
        RCL A
        x=0?
            GTO @no_winner
        2
        STO B                   ; CPU is player 2.
        XEQ drop
        print cpuPromptMsg
        FIX 0                   ; Integer display.
        RCL A                   ; X = CPU column.
        PSE                     ; Show both lines.
        FIX 7
        XEQ display_board
        XEQ won
        FS? 0
            GTO @cpu_wins
        XEQ board_full
        RCL A
        x=0?
            GTO @player_turn
        GTO @no_winner

;---------------------------------------------------------------
; input_col     Read and validate the player's column selection
;---------------------------------------------------------------
; Input:
;       none
; Output: 
;       A=column (1..7)
;---------------------------------------------------------------
input_col:
@@retry:
        print playerPromptMsg
        PSE
        INPUT C
        7
        RCL C
        x>y?
            GTO @@retry
        RCL C
        IP                      ; Truncate input.
        x<=0?
            GTO @@retry
        STO A
        RTN

@column_full:
        print columnFullMsg
        PSE
        GTO @player_turn

@player_wins:
        print playerWinsMsg
        PSE
        STOP

@cpu_wins:
        print cpuWinsMsg
        PSE
        STOP

@no_winner:
        print noWinnerMsg
        PSE
        STOP

;---------------------------------------------------------------
; drop          Drop player B into column A
;---------------------------------------------------------------
; Input:
;       A=column
;       B=player
; Output:
;       D=row (1..6), or 0 if full
; Notes:
;       updates the selected board row in I1..I6
;---------------------------------------------------------------
drop:
        ; Search from the bottom row upward; D=0 means the column is full.
        6
        STO D
@@loop:
        XEQ get_cell
        x=0?
            GTO @@place_piece
        DSE D                   ; Next row up.
            GTO @@loop
        CLx
        STO D
        RTN
@@place_piece:
        XEQ set_cell
        RTN

;---------------------------------------------------------------
; set_cell      Set one board cell
;---------------------------------------------------------------
; Input:
;       A=column
;       D=row
;       B=value
; Output:
;       none
; Notes:
;       updates I1..I6
;---------------------------------------------------------------
set_cell:
        XEQ get_cell
        ; Apply only the digit difference at this column's decimal place.
        RCL B                   ; New value.
        RCL K                   ; Old value.
        -                       ; Digit delta.
        RCL E                   ; Column place.
        *                       ; Scale delta.
        STO+(I)                 ; Updated row.
        RTN

;---------------------------------------------------------------
; display_board         Display all six board rows as row 
;                       number plus board fraction
;---------------------------------------------------------------
; Input:
;       board in I1..I6
; Output:
;       none
; Notes:
;       pauses after each row
;---------------------------------------------------------------
display_board:
        1.006
        STO J                   ; ISG counter for rows 1..6.
@@loop:
        RCL J
        IP                      ; Extract current row from ISG counter.
        STO I
        eqn 'I+(I)/1e7'
        PSE
        ISG J
            GTO @@loop
        RTN

;---------------------------------------------------------------
; board_full    Check whether every column is full
;---------------------------------------------------------------
; Input:
;       board in I1..I6
; Output:
;       A=1 if full, otherwise A=0
;---------------------------------------------------------------
board_full:
        1
        STO D                   ; Check the top row.
        1.007
        STO Q                   ; Examine columns 1..7.
@@loop:
        RCL Q
        IP
        STO A
        XEQ get_cell
        RCL K
        x=0?
            GTO @@not_full
        ISG Q
            GTO @@loop
        1
        STO A
        RTN
@@not_full:
        CLx
        STO A
        RTN

;---------------------------------------------------------------
; won           Check whether player B has four connected pieces
;---------------------------------------------------------------
; Input:
;       B=player
; Output:
;       flag 0 is set on a win, cleared otherwise
;---------------------------------------------------------------
won:
        CF 0                    ; Assume no win until test_four succeeds.

        ; Horizontal: rows 1..6, columns 1..4, step (0,1).
        1.006
        ; L = row loop, M = column loop.
        STO L                   ; Rows 1-6. 
@@horizontal_row:
        1.004
        STO M                   ; Columns 1-4.
@@horizontal_col:
        RCL L
        IP
        STO D
        RCL M
        IP
        STO A
        CLx
        STO N
        1
        STO O
        XEQ test_four
        FS? 0
            RTN
        ISG M
            GTO @@horizontal_col
        ISG L
            GTO @@horizontal_row

        ; Vertical: rows 1..3, columns 1..7, step (1,0).
        1.003
        STO L                   ; Rows 1-3.
@@vertical_row:
        1.007
        STO M                   ; Columns 1-7.
@@vertical_col:
        RCL L
        IP
        STO D
        RCL M
        IP
        STO A
        SGN                     ; Positive A produces +1 compactly.
        STO N
        CLx
        STO O
        XEQ test_four
        FS? 0
            RTN
        ISG M
            GTO @@vertical_col
        ISG L
            GTO @@vertical_row

        ; Diagonal down-right: rows 1..3, columns 1..4, step (1,1).
        1.003
        STO L                   ; Rows 1-3.
@@diagonal_down_row:
        1.004
        STO M                   ; Columns 1-4.
@@diagonal_down_col:
        RCL L
        IP
        STO D
        RCL M
        IP
        STO A
        SGN
        STO N
        STO O
        XEQ test_four
        FS? 0
            RTN
        ISG M
            GTO @@diagonal_down_col
        ISG L
            GTO @@diagonal_down_row

        ; Diagonal up-right: rows 1..3, columns 4..7, step (1,-1).
        1.003
        STO L                   ; Rows 1-3.
@@diagonal_up_row:
        4.007
        STO M                   ; Columns 4-7.
@@diagonal_up_col:
        RCL L
        IP
        STO D
        RCL M
        IP
        STO A
        SGN
        STO N
        +/-
        STO O
        XEQ test_four
        FS? 0
            RTN
        ISG M
            GTO @@diagonal_up_col
        ISG L
            GTO @@diagonal_up_row
        RTN

;---------------------------------------------------------------
; test_four     Test four cells from (D,A), stepping by (N,O)
;---------------------------------------------------------------
; Input:
;       A=column
;       D=row
;       B=player
;       N=row step
;       O=column step
; Output:
;       flag 0 is set when all four cells match
;---------------------------------------------------------------
test_four:
        4
        STO P                   ; P = number of cells still to test.
@@loop:
        XEQ get_cell
        RCL K
        RCL B
        x!=y?
            GTO @@done
        RCL N
        STO+ D                  ; Advance to next row.
        RCL O
        STO+ A                  ; Advance to next column.
        DSE P
            GTO @@loop
        SF 0                    ; All four cells matched.
@@done:
        RTN

;---------------------------------------------------------------
; get_cell      Read one board cell
;---------------------------------------------------------------
; Input:
;       A=column
;       D=row
; Output:
;       K=cell value
; Notes:
;       I and E are scratch
;---------------------------------------------------------------
get_cell:
        RCL D
        STO I                   ; I = indirect board-row register.
        ; E is the decimal place value for column A.
        7
        RCL A
        -
        10^x
        STO E                   ; E = 10^(7-column).
        RCL(I)
        RCL E
        /
        IP                      ; Drop lower digits.
        STO K
        ; Keep only the selected digit.
        RCL K
        10
        RMDR
        STO K
        RTN

;---------------------------------------------------------------
; cpu_move      Choose the highest-scoring CPU column
;---------------------------------------------------------------
; Input:
;       current board in I1..I6
; Output:
;       A=column (1..7), or 0 if full
; Note:
;       Simulated moves are undone before returning
;---------------------------------------------------------------
cpu_move:
        -9999
        STO G                   ; G = best score.
        CLx
        STO H                   ; H = best column, initially none.
        1.007
        STO Q                   ; Q = candidate columns 1..7.
@@loop:
        RCL Q
        IP
        STO A
        CLx
        STO F                   ; F = score of current candidate.
        ; Prefer the center (+4), then its neighbors (+2).
        RCL A
        4
        x=y?
            GTO @@center
        RCL A
        3
        x=y?
            GTO @@side
        RCL A
        5
        x=y?
            GTO @@side
        GTO @@try_move
@@center:
        4
        STO+ F
        GTO @@try_move
@@side:
        2
        STO+ F
@@try_move:
        2
        STO B
        XEQ drop
        RCL D
        x=0?
            GTO @@next
        RCL A
        STO S                   ; S = simulated column for undo.
        RCL D
        STO T                   ; T = simulated row for undo.
        ; Score an immediate CPU win at +1000.
        XEQ won
        FS? 0
            GTO @@win_score
        ; Undo CPU simulation before testing the player's response.
        XEQ undo
        GTO @@try_block
@@win_score:
        1000
        STO+ F
        ; Undo CPU simulation after recording its winning score.
        XEQ undo
@@try_block:
        ; Simulate the player's move in this candidate column.
        1
        STO B
        RCL S
        STO A
        XEQ drop
        RCL D
        STO T
        ; Score a move that blocks the player's win at +500.
        XEQ won
        FS? 0
            GTO @@block_score
        ; Undo player simulation when it does not block a win.
        XEQ undo
        GTO @@score_move
@@block_score:
        500
        STO+ F
        ; Undo player simulation after recording the block score.
        XEQ undo
@@score_move:
        RCL S
        STO A
        RCL G                   ; Y = current best score.
        RCL F                   ; X = candidate score.
        ; Replace the current best only when this score is higher.
        x>y?
            GTO @@best
        GTO @@next
@@best:
        RCL F
        STO G
        RCL A
        STO H
@@next:
        ISG Q
            GTO @@loop
        RCL H
        STO A                   ; Return selected column in A.
        RTN

;---------------------------------------------------------------
; undo          Undo a simulated move
;---------------------------------------------------------------
; Input:
;       S=column
;       T=row
; Output:
;       none
; Notes:
;       clears that cell
;---------------------------------------------------------------
undo:
        RCL S
        STO A
        RCL T
        STO D
        CLx
        STO B
        XEQ set_cell
        RTN

ENDS
END start
