Y001	LBL Y		; &rsh; LBL Y
Y002	RPN		; MODE 5
Y003	SF 10		; &lsh; FLAGS 1 . 0
; EQN 1 RCL T &rsh; &rarr;l > &#x21E6; &#x21E6; &#x21E6; &lsh; &pi; &rsh; SPACE 2 &lsh; &pi; &rsh; &rarr;l > &#x21E6; &#x21E6; &#x21E6; RCL T &rsh; SPACE 3 RCL S &rsh; &rarr;l > &#x21E6; &#x21E6; &#x21E6; RCL D &rsh; SPACE 4 RCL D &rsh; &rarr;l > &#x21E6; &#x21E6; &#x21E6; RCL S ENTER
Y004	1T&rarr;&pi; 2&pi;&rarr;T 3S&rarr;D 4D&rarr;S
Y005	CF 10		; &lsh; FLAGS 2 . 0
Y006	1		; 1 ENTER
Y007	x=y?		; &lsh; x?y 6
Y008	GTO Y023	; GTO Y 0 2 3
Y009	R&darr;		; R&darr;
Y010	2		; 2 ENTER
Y011	x=y?		; &lsh; x?y 6
Y012	GTO Y058	; GTO Y 0 5 8
Y013	R&darr;		; R&darr;
Y014	3		; 3 ENTER
Y015	x=y?		; &lsh; x?y 6
Y016	GTO Y023	; GTO Y 0 2 3
Y017	R&darr;		; R&darr;
Y018	4		; 4 ENTER
Y019	x=y?		; &lsh; x?y 6
Y020	GTO Y058	; GTO Y 0 5 8
Y021	R&darr;		; R&darr;
Y022	STOP		; R/S
Y023*	INPUT P		; &lsh; INPUT P
Y024	INPUT Q		; &lsh; INPUT Q
Y025	INPUT R		; &lsh; INPUT R
Y026	&times;		; &times;
Y027	&times;		; &times;
Y028	x=0?		; &rsh; x?0 6
Y029	GTO Y023	; GTO Y 0 2 3
Y030	RCL P		; RCL P
Y031	RCL Q		; RCL Q
Y032	&times;		; &times;
Y033	RCL Q		; RCL Q
Y034	RCL R		; RCL R
Y035	&times;		; &times;
Y036	RCL R		; RCL R
Y037	RCL P		; RCL P
Y038	&times;		; &times;
Y039	+		; +
Y040	+		; +
Y041	STO A		; &rsh; STO A
Y042	STO B		; &rsh; STO B
Y043	STO C		; &rsh; STO C
Y044	RCL R		; RCL R
Y045	STO&divide; A		; &rsh; STO &divide; A
Y046	RCL Q		; RCL Q
Y047	STO&divide; B		; &rsh; STO &divide; B
Y048	RCL P		; RCL P
Y049	STO&divide; C		; &rsh; STO &divide; C
Y050	0		; 0 ENTER
Y051	RCL A		; RCL A
Y052	RCL B		; RCL B
Y053	RCL C		; RCL C
Y054	VIEW A		; &lsh; VIEW A
Y055	VIEW B		; &lsh; VIEW B
Y056	VIEW C		; &lsh; VIEW C
Y057	RTN		; &lsh; RTN
Y058*	INPUT A		; &lsh; INPUT A
Y059	INPUT B		; &lsh; INPUT B
Y060	INPUT C		; &lsh; INPUT C
Y061	+		; +
Y062	+		; +
Y063	x=0?		; &rsh; x?0 6
Y064	GTO Y058	; GTO Y 0 5 8
Y065	1/x		; 1/x
Y066	STO P		; &rsh; STO P
Y067	STO Q		; &rsh; STO Q
Y068	STO R		; &rsh; STO R
Y069	RCL A		; RCL A
Y070	RCL B		; RCL B
Y071	&times;		; &times;
Y072	STO&times; P		; &rsh; STO &times; P
Y073	RCL A		; RCL A
Y074	RCL C		; RCL C
Y075	&times;		; &times;
Y076	STO&times; Q		; &rsh; STO &times; Q
Y077	RCL B		; RCL B
Y078	RCL C		; RCL C
Y079	&times;		; &times;
Y080	STO&times; R		; &rsh; STO &times; R
Y081	0		; 0 ENTER
Y082	RCL P		; RCL P
Y083	RCL Q		; RCL Q
Y084	RCL R		; RCL R
Y085	VIEW P		; &lsh; VIEW P
Y086	VIEW Q		; &lsh; VIEW Q
Y087	VIEW R		; &lsh; VIEW R
Y088	RTN		; &lsh; RTN
