O001	LBL O		; &rsh; LBL O
O002	RPN		; MODE 5
O003	INPUT R		; &lsh; INPUT R
O004	x=0?		; &rsh; x?0 6
O005	GTO O013	; GTO O 0 1 3
O006	INPUT V		; &lsh; INPUT V
O007	x=0?		; &rsh; x?0 6
O008	GTO O019	; GTO O 0 1 9
O009	RCL&divide; R		; RCL &divide; R
O010	STO I		; &rsh; STO I
O011	VIEW I		; &lsh; VIEW I
O012	RTN		; &lsh; RTN
O013*	INPUT V		; &lsh; INPUT V
O014	INPUT I		; &lsh; INPUT I
O015	&divide;		; &divide;
O016	STO R		; &rsh; STO R
O017	VIEW R		; &lsh; VIEW R
O018	RTN		; &lsh; RTN
O019*	INPUT I		; &lsh; INPUT I
O020	RCL&times; R		; RCL &times; R
O021	STO V		; &rsh; STO V
O022	VIEW V		; &lsh; VIEW V
O023	RTN		; &lsh; RTN
