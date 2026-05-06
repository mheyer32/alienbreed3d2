; IE fallback system definitions for bare-metal builds.

FAKE_LIB_BASE	equ		$6F0000

MEMF_ANY		equ		0
MEMF_CHIP		equ		0
MEMF_CLEAR		equ		0
IOTV_SIZE		equ		64
fib_SIZEOF		equ		260

CUSTOM			equ		0
cop1lc			equ		$080
intreq			equ		$09C
intreqr			equ		$01E
adkcon			equ		$09E
dmacon			equ		$096
potgo			equ		$034
potinp			equ		$016
joy1dat			equ		$00C
ciapra			equ		0
CIAB_GAMEPORT0	equ		6

DMAF_SETCLR		equ		$8000
DMAF_MASTER		equ		$0200
DMAF_AUDIO		equ		$000F
CACRF_EnableD		equ	$00000100
CACRF_WriteAllocate	equ	$00002000
CACRF_DBE			equ	$00001000

_LVOAllocMem		equ	-198
_LVOFreeMem			equ	-210
_LVOAllocVec		equ	-684
_LVOFreeVec			equ	-690
_LVORawDoFmt		equ	-522
_LVOAddIntServer	equ	-168
_LVORemIntServer	equ	-174
_LVOGetMsg			equ	-372
_LVOWaitPort		equ	-384
_LVOCloseLibrary	equ	-414
_LVOCacheControl	equ	-648
_LVOSuperState		equ	-150
_LVOUserState		equ	-156

_LVOOpen			equ	-30
_LVOClose			equ	-36
_LVORead			equ	-42
_LVOWrite			equ	-48
_LVODelay			equ	-198
_LVOExamineFH		equ	-426
_LVOExecute			equ	-222

_LVOWaitTOF		equ	-270
_LVOLoadRGB4		equ	-192
_LVOMove			equ	-240
_LVOText			equ	-60
_LVOUCopperListInit	equ	-516
_LVOCMove			equ	-522
_LVOCBump			equ	-528
_LVOCWait			equ	-534

_LVOChangeScreenBuffer	equ	-768
_LVODisplayAlert		equ	-90
_LVOWritePotgo			equ	-30
_LVOFreeMiscResource	equ	-12
_LVOFreePotBits		equ	-18
_LVODisable			equ	-120
_LVOEnable			equ	-126

MODE_OLDFILE		equ	1005
MODE_NEWFILE		equ	1006
fib_Size			equ	124

BMF_DISPLAYABLE	equ	1
TAG_END			equ	0
CUSTOMSCREEN	equ	15
PAL_MONITOR_ID	equ	0
SA_Width		equ	$80000066
SA_Height		equ	$80000067
SA_Depth		equ	$80000068
SA_BitMap		equ	$8000006A
SA_Type			equ	$8000006B
SA_Quiet		equ	$8000006C
SA_ShowTitle	equ	$8000006D
SA_DisplayID	equ	$80000032
WA_Left			equ	$80000064
WA_Top			equ	$80000065
WA_Width		equ	$80000066
WA_Height		equ	$80000067
WA_CustomScreen	equ	$8000006F
WA_Activate		equ	$80000070
WA_Borderless	equ	$80000071
WA_RMBTrap		equ	$80000072
WA_NoCareRefresh	equ	$80000073
WA_SimpleRefresh	equ	$80000074
WA_Backdrop		equ	$80000075

STRUCTURE		MACRO
\1				EQU		\2
SOFFSET			SET		\2
				ENDM

UBYTE			MACRO
\1				EQU		SOFFSET
SOFFSET			SET		SOFFSET+1
				ENDM

UWORD			MACRO
\1				EQU		SOFFSET
SOFFSET			SET		SOFFSET+2
				ENDM

WORD			MACRO
\1				EQU		SOFFSET
SOFFSET			SET		SOFFSET+2
				ENDM

ULONG			MACRO
\1				EQU		SOFFSET
SOFFSET			SET		SOFFSET+4
				ENDM

BYTE			MACRO
\1				EQU		SOFFSET
SOFFSET			SET		SOFFSET+1
				ENDM

STRUCT			MACRO
\1				EQU		SOFFSET
SOFFSET			SET		SOFFSET+\2
				ENDM

LABEL			MACRO
\1				EQU		SOFFSET
				ENDM
