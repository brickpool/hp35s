100 DISPLAY AT(6)"* JIVE TURKEY GAME *":PAUSE 2
110 SCORE=0:FIB=0:RANDOMIZE:SECRET=INTRND(100)
120 DISPLAY ERASE ALL"PROBABILITY OF TRUTH? 0-100";
130 ACCEPT AT(29)BEEP VALIDATE(DIGIT);PROB
140 ROLL=INTRND(100):SCORE=SCORE+1:DISPLAY"YOUR GUES? 0-100";
150 ACCEPT AT(20)BEEP VALIDATE(DIGIT);GUESS:IF GUESS=SECRET THEN 190
160 IF PROB>ROLL THEN FLAG=1 ELSE FLAG=0:IF FLAG=0 THEN FIB=FIB+1
170 IF GUESS<SECRET THEN IF FLAG=1 THEN 240 ELSE 230
180 IF GUESS>SECRET THEN IF FLAG=1 THEN 230 ELSE 240
190 PRINT"CONGRATULATIONS! YOU DID IT!":PAUSE 3
200 DISPLAY AT (3)"SCORE=";SCORE,"# OF FIBS=";FIB:PAUSE
210 DISPLAY"SAME GAME AGAIN? Y/N";:ACCEPT AT(22)BEEP VALIDATE("YNyn"),ANSWERS
220 IF ANSWERS="Y" OR ANSWERS="y" THEN 110 ELSE 250
230 PRINT"GUESS TOO HIGH":PAUSE 1:G0T0 140
240 PRINT"GUESS TOO LOW":PAUSE 1:G0T0 140
250 DISPLAY AT(5)ERASE ALL"BYE, HAVE A NICE DAY!":PAUSE 3:END
