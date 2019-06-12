C001	LBL C		; &rsh; LBL C
C002	RPN		; MODE 5
C003	CF 0		; &lsh; FLAGS 2 0
C004	CL&Sigma;		; &rsh; CLEAR 4
C005	SF 10		; &lsh; FLAGS 1 . 0
; EQN 1 RCL P RCL A RCL R &rsh; SPACE 2 RCL S RCL E RCL R ENTER
C006	1PAR 2SER
C007	CF 10		; &lsh; FLAGS 2 . 0
C008	1		; 1 ENTER
C009	x=y?		; &lsh; x?y 6
C010	GTO C017	; GTO C 0 1 7
C011	R&darr;		; R&darr;
C012	2		; 2 ENTER
C013	x=y?		; &lsh; x?y 6
C014	GTO C038	; GTO C 0 3 8
C015	R&darr;		; R&darr;
C016	STOP		; R/S
C017*	SF 10		; &lsh; FLAGS 1 . 0
; EQN 1 RCL R &rsh; SPACE 2 RCL C &rsh; SPACE 3 RCL L &rsh; SPACE 4 RCL P &rsh; SPACE 5 RCL I &rsh; SPACE 6 RCL G &rsh; SPACE 7 RCL Z ENTER
C018	1R 2C 3L 4P 5I 6G 7Z
C019	CF 10		; &lsh; FLAGS 2 . 0
C020	x&le;0?		; &rsh; x?0 2
C021	GTO C017	; GTO C 0 1 7
C022	7		; 7 ENTER
C023	x<y?		; &lsh; x?y 3
C024	GTO C017	; GTO C 0 1 7
C025	R&darr;		; R&darr;
C026	1		; 1 ENTER
C027	x=y?		; &lsh; x?y 6
C028	SF 0		; &lsh; FLAGS 1 0
C029	R&darr;		; R&darr;
C030	3		; 3 ENTER
C031	x=y?		; &lsh; x?y 6
C032	SF 0		; &lsh; FLAGS 1 0
C033	R&darr;		; R&darr;
C034	7		; 7 ENTER
C035	x=y?		; &lsh; x?y 6
C036	SF 0		; &lsh; FLAGS 1 0
C037	GTO C054	; GTO C 0 5 4
C038*	SF 10		; &lsh; FLAGS 1 . 0
; EQN 1 RCL R &rsh; SPACE 2 RCL C &rsh; SPACE 3 RCL L &rsh; SPACE 4 RCL P &rsh; SPACE 5 RCL V &rsh; SPACE 6 RCL G ENTER
C039	1R 2C 3L 4P 5V 6G
C040	CF 10		; &lsh; FLAGS 2 . 0
C041	x&le;0?		; &rsh; x?0 2
C042	GTO C038	; GTO C 0 3 8
C043	6		; 6 ENTER
C044	x<y?		; &lsh; x?y 3
C045	GTO C038	; GTO C 0 3 8
C046	R&darr;		; R&darr;
C047	2		; 2 ENTER
C048	x=y?		; &lsh; x?y 6
C049	SF 0		; &lsh; FLAGS 1 0
C050	R&darr;		; R&darr;
C051	6		; 6 ENTER
C052	x=y?		; &lsh; x?y 6
C053	SF 0		; &lsh; FLAGS 1 0
C054*	SF 10		; &lsh; FLAGS 1 . 0
; EQN STO &#x1F132; RCL 0 ENTER
C055	&#x25BA;(I)
C056	CF 10		; &lsh; FLAGS 2 . 0
C057	x=0?		; &rsh; x?0 6
C058	GTO C067	; GTO C 0 6 7
C059	ENTER		; ENTER
C060	1/x		; 1/x
C061	&Sigma;+		; &Sigma;+
C062	STO I		; &rsh; STO I
C063	R&darr;		; R&darr;
C064	STO(I)		; &rsh; STO (I)
C065	VIEW(I)		; &lsh; VIEW (I)
C066	GTO C054	; GTO C 0 5 4
C067*	&Sigma;x		; &rsh; SUMS 2
C068	x&ne;0?		; &rsh; x?0 1
C069	1/x		; 1/x
C070	&Sigma;y		; &rsh; SUMS 3
C071	FS? 0		; &lsh; FLAGS 3 0
C072	x<>y		; x<>y
C073	CF 0		; &lsh; FLAGS 2 0
C074	STO V		; &rsh; STO V
C075	VIEW V		; &lsh; VIEW V
C076	RTN		; &lsh; RTN
