P001	LBL P		; &rsh; LBL P
P002	RPN		; MODE 5
P003	SF 10		; &lsh; FLAGS 1 . 0
; EQN 1 RCL P &rsh; SPACE 2 RCL V &rsh; SPACE 3 RCL I &rsh; SPACE 4 RCL R ENTER
P004	1P 2V 3I 4R
P005	CF 10		; &lsh; FLAGS 2 . 0
P006	1		; 1 ENTER
P007	x=y?		; &lsh; x?y 6
P008	GTO P023	; GTO P 0 2 3
P009	R&darr;		; R&darr;
P010	2		; 2 ENTER
P011	x=y?		; &lsh; x?y 6
P012	GTO P045	; GTO P 0 4 5
P013	R&darr;		; R&darr;
P014	3		; 3 ENTER
P015	x=y?		; &lsh; x?y 6
P016	GTO P052	; GTO P 0 5 2
P017	R&darr;		; R&darr;
P018	4		; 4 ENTER
P019	x=y?		; &lsh; x?y 6
P020	GTO P061	; GTO P 0 6 1
P021	R&darr;		; R&darr;
P022	STOP		; R/S
P023*	INPUT V		; &lsh; INPUT V
P024	x=0?		; &rsh; x?0 6
P025	GTO P031	; GTO P 0 3 1
P026	INPUT I		; &lsh; INPUT I
P027	x=0?		; &rsh; x?0 6
P028	GTO P036	; GTO P 0 3 6
P029	&times;		; &times;
P030	GTO P042	; GTO P 0 4 2
P031*	INPUT I		; &lsh; INPUT I
P032	x<sup>2</sup>		; &rsh; x<sup>2</sup>
P033	INPUT R		; &lsh; INPUT R
P034	&times;		; &times;
P035	GTO P042	; GTO P 0 4 2
P036*	INPUT R		; &lsh; INPUT R
P037	x&le;0?		; &rsh; x?0 2
P038	GTO P042	; GTO P 0 4 2
P039	1/x		; 1/x
P040	RCL&times; V		; RCL &times; V
P041	RCL&times; V		; RCL &times; V
P042*	STO P		; &rsh; STO P
P043	VIEW P		; &lsh; VIEW P
P044	RTN		; &lsh; RTN
P045*	INPUT P		; &lsh; INPUT P
P046	INPUT R		; &lsh; INPUT R
P047	&times;		; &times;
P048	&radic;x		; &radic;x
P049	STO V		; &rsh; STO V
P050	VIEW V		; &lsh; VIEW V
P051	RTN		; &lsh; RTN
P052*	INPUT P		; &lsh; INPUT P
P053	INPUT R		; &lsh; INPUT R
P054	x&le;0?		; &rsh; x?0 2
P055	GTO P052	; GTO P 0 5 2
P056	&divide;		; &divide;
P057	&radic;x		; &radic;x
P058	STO I		; &rsh; STO I
P059	VIEW I		; &lsh; VIEW I
P060	RTN		; &lsh; RTN
P061*	INPUT P		; &lsh; INPUT P
P062	x&le;0?		; &rsh; x?0 2
P063	GTO P061	; GTO P 0 6 1
P064	INPUT V		; &lsh; INPUT V
P065	x=0?		; &rsh; x?0 6
P066	GTO P070	; GTO P 0 7 0
P067	x<sup>2</sup>		; &rsh; x<sup>2</sup>
P068	RCL&divide; P		; RCL &divide; P
P069	GTO P076	; GTO P 0 7 6
P070*	INPUT I		; &lsh; INPUT I
P071	x&le;0?		; &rsh; x?0 2
P072	GTO P070	; GTO P 0 7 0
P073	x<sup>2</sup>		; &rsh; x<sup>2</sup>
P074	1/x		; 1/x
P075	RCL&times; P		; RCL &times; P
P076*	STO R		; &rsh; STO R
P077	VIEW R		; &lsh; VIEW R
P078	RTN		; &lsh; RTN
