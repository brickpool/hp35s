; Mancala for the HP-35s
; This program is by Dan B. (brianddk) and is used here by permission.
; https://brianddk.github.io/prog/mancala/mancala.asm
MODEL P35S
SEGMENT MANCA CODE
;Main Mancala program
LBL M
  XEQ init                          ; Init the game registers
  main:                             ; Main game loop
    XEQ check_winner                ; Check for a winner
    FS? 3                           ; Flag3 = Winner Found!
      GTO done                      ; Finished when a winner is found
    redisplay:                      ; Come here if we pick bad
    XEQ display_board               ; Display the game board
    XEQ pick                        ; Pick a move
    FS? 4                           ; Invalid move?
      GTO redisplay                 ; .. Redisplay
    XEQ move                        ; Move the beans
    XEQ switch                      ; Swithch players
  GTO main                          ; Loop for next move
  done:                             ; This is where we finish
  XEQ cleanup                       ; Cleanup we are done
RTN
;
; .Init registers
init:                               ; Init the game registers
  CF 1                              ; Clear our flag regs
  CF 2
  CF 3
  CF 4
  13                                ; For i in 13..1
  STO I                             ; i
  4                                 ; st-x = 4
  init_loop:
    STO (I)                         ; 4->(i)
    DSE I                           ; DSE i
  GTO init_loop
  0                                 ; i now equals zero
  STO (I)                           ; 0->(i), i = 0
  7
  STO I
  x<>y
  STO (I)                           ; 0->(i), i = 7
  SF 1                              ; P1'S Turn
  ; GRAD                            ; 42s Only, P1 indicator
RTN
;                                   ; This routine will check for
; Check for winner                  ; .. the winner by looking at
check_winner:                       ; .. the 'home pits'
  SF 10                             ; For 35s prompting
  CF 3                              ; Clear winner found flag
  0                                 ; i = P1-home
  STO J                             ; j = P2-home
  7                                 ; Compare P1-home to 24
  STO I                             ; .. if it is .gte. then won!
  RCL (I)                           ; p1-home,7,0
  24                                ; 24,p1h,7,0
  x<=y?
    GTO p1_winner
  RCL (J)                           ; p2h,24,p1h,7
  x<>y                              ; 24,p2h,p1h,7
  x<=y?
    GTO p2_winner
  GTO winner_rtn
  p1_winner:
    eqn 'PLAYER 1 WON'
    GTO winner_done
  p2_winner:
    eqn 'PLAYER 2 WON'
  winner_done:
    SF 3                            ; Set winner found flag
    ; PROMPT                        ; The 41c or 42s uses prompt command
  winner_rtn:                       ; .. But the 35s uses Flag 10
  CF 10                             ; Restore (35s) default
RTN
;
; Display the board
display_board:
  1.006
  STO I                             ; i
  14
  STO J                             ; "$(j)" == "$(14)"
  1000000
  STO (J)                           ; (j)=1,000,000
  p1_board:                         ; 1m,14,1..
    ;STOP
    10                              ; WARN Base 10 for now
    6                               ; 6,10,1m,14
    RCL I                           ; i,6,10,1m
    IP
    -                               ; 6-ip,10,1m,1m
    y^x                             ; 10^(6-ip(i)),1m,1m,1m
    RCL (I)                         ; Ri,10^6-i,1m,1m
    *                               ; 10^(6-ip(i)) * $(i)
    STO+ (J)                        ; @(j) += i^(6-ip(i)) + $(i)
    ISG I                           ; loop
  GTO p1_board
  15
  STO J                             ; j = P2-vector
  2000000
  STO (J)
  13.007
  STO I
  p2_board:
    ;STOP
    10                              ; WARN Base 10 for now
    RCL I                           ; i,10,13.,2m
    IP
    8                               ; 8,i,10,13.
    -                               ; i-8,10,13.,13.
    y^x                             ; 10^(i-8),13.,13.
    RCL (I)                         ; Ri, 10^..,13,13
    *                               ; Ri*10^..13,13,13
    STO+ (J)
    DSE I
  GTO p2_board
  7                                 ; Now we get the score and tack
  STO I                             ;.. it to the end of the number
  0                                 ;.. as the FP
  STO J                             ; i = p1-home, j=p2-home
  0.01                              ; .01,0,7
  RCL (J)                           ; R0,.01,0,7
  *                                 ; R0%,0,7,7
  0.01                              ; .01,R0%,0,7
  RCL (I)                           ; R7,.01,R0%,0
  *                                 ; R7%,R0%,0,0
  14                                ; .. st-y = p2-score/100
  STO I
  15
  STO J                             ; i = p1 vector, j=p2-vector
  Rv                                ; st-x = p1-score/100
  Rv                                ; .. st-y = p2-score/100
  STO+ (I)
  x<>y
  STO+ (J)
  RCL (J)                           ; P2
  RCL (I)                           ; P1
  ; FS? 2                           ; 41c Only
  ;   x<>y                          ; 41c Only
  FIX 2
  STOP
RTN
;
; Pick a pit to move
pick:
  CF 4
  IP                                ; INT
  1
  x<>y
  x<y?
    SF 4
  6
  x<>y
  x>y?
    SF 4
  FS? 4
    GTO pick_done
  STO I                             ; i=PICK
  FS? 1
    GTO check_pick
  14
  x<>y
  -
  STO I                             ; i
  check_pick:
  RCL (I)                           ; (i)
  x=0?
    SF 4
  pick_done:
  RCL I                             ; i
RTN
;
; Move beans from selected pit
move:
  0
  x<> (I)                           ; (i)= 0 (MOVE BEANS OUT)
  STO J                             ; j=VALUE PREVIOUSLY IN (i)
  move_loop:
    ; INCI SUBROUTINE-INLINE
    1
    RCL I                           ; i++ (MOVE REGISTER FORWARD)
    +
    14
    RMDR                            ; MOD
    STO I                           ; i=(i+1)MOD(14)
    FS? 1                           ; P1?
      GTO skip0                     ; SKIP0 IF P1
    FS? 2
      GTO skip7                     ; SKIP7 IF P2
    ; INCI END-SUBROUTINE-INLINE
    1
    STO+ (I)                        ; (i)=(i)+1
    DSE J                           ; j--
  GTO move_loop
  1
  RCL (I)
  x=y?
    GTO win_beans
RTN
;
; SKIP0
skip0:
  x=0?
    ISG I
  CF 0                              ; NOP
RTN
;
; SKIP7
skip7:
  7
  x<>y
  x=y?
    ISG I
  CF 0                              ; NOP
RTN
;
; WIN-BEANS
win_beans:
  ;STOP
  RCL I
  x=0?
    RTN
  7
  x=y?
    RTN
  FS? 1
    GTO p1_winbeans
  FS? 2
    GTO p2_winbeans
  RTN
  p1_winbeans:
  STO J
  x<y?                              ; 7 < I ?
    RTN
  GTO done_winbeans
  p2_winbeans:
  0
  STO J
  Rv
  x>y?
    RTN
  done_winbeans:
  CLx
  x<> (I)
  STO+ (J)
  CLx
  14
  x<>y
  -
  STO I
  0
  x<> (I)
  STO+ (J)
RTN
;
; Switch to other players turn
switch:
  7
  RCL I                             ; i contains the final register of move
  x=y?                              ; if i=7, landed in a bank, free move
    RTN
  x=0?                              ; if i=0, landed in a bank, free move
    RTN
  FS? 1
  GTO switchto_p2
    CF 2
    SF 1
    ; GRAD
    GTO switch_done
  switchto_p2:
    CF 1
    SF 2
    RAD
switch_done:
RTN
;
; Clean up after game
cleanup:
  CF 1
  CF 2
  CF 3
  CF 4
  FIX 4
  DEG
RTN

ENDS MANCA
END
