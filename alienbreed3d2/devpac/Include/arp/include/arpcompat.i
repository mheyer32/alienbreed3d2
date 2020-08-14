* This header file, arpcomp.i, has symbolic equates
* allowing you to use source code with the V1.0 ARP
* release of symbols

FR_Hail		equ	fr_Hail
FR_Ddef		equ	fr_File
FR_Ddir		equ	fr_Dir
fr_Wind		equ	fr_Window	; Fixed, sdb.
FR_Wind		equ	fr_Wind
fr_Flags	equ	fr_FuncFlags	; for V33
FR_Flags	equ	fr_Flags
***************** Changed for V33
*FR_WildFunc	equ	fr_WildFunc
*FR_MsgFunc	equ	fr_MsgFunc
FR_WildFunc	equ	fr_Function
fr_WildFunc	equ	fr_Function
fr_reserved	equ	fr_reserved2
FR_MsgFunc	equ	fr_reserved2

AP_BASE		equ	ap_Base
AP_LAST		equ	ap_Last
AP_BREAKBITS	equ	ap_BreakBits
AP_FOUNDBREAK	equ	ap_FoundBreak
AP_LENGTH	equ	ap_Length
AP_INFO		equ	ap_Info
AP_BUF		equ	ap_Buf
AP_SIZEOF	equ	ap_SIZEOF

AN_NEXT		equ	an_Next
AN_PRED		equ	an_Pred
AN_LOCK		equ	an_Lock
AN_INFO		equ	an_Info
AN_STATUS	equ	an_Status
AN_TEXT		equ	an_Text
AN_SIZEOF	equ	an_SIZEOF

DA_Next		equ	de_Next
DA_Type		equ	de_Type
DA_Flags	equ	de_Flags
DA_Stuff	equ	de_Name
DE_SIZEOF	equ	de_SIZEOF

ARL_node	equ	rl_Node
TaskID		equ	rl_TaskID
FirstItem	equ	rl_FirstItem
ARL_link	equ	rl_Link
*RL_SIZEOF	equ	rl_SIZEOF

TR_Node		equ	tr_Node
TR_Flags	equ	tr_Flags
TR_Lock		equ	tr_Lock
TR_ID		equ	tr_ID
TR_Stuff	equ	tr_Object
TR_Extra	equ	tr_Extra
TR_SIZEOF	equ	trk_SIZEOF

TRU_ID		equ	dt_ID
TRU_Stuff	equ	dt_Resource
TRU_Extra	equ	dt_Window2

TG_FuncAddr	equ	TR_Extra
TG_VALUE	equ	TR_Stuff
TW_WINDOW	equ	TR_Extra
