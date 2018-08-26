	IFND	MISC_COPPER_I
MISC_COPPER_I	SET	1
**
**	$Filename: misc/copper.i $
**	$Release: Devpac 3.02 $
**	$Date: 92/02/27 $
**
**	Macros to generate copper instruction lists.
**

CMOVE	MACRO	* value,register
	DC.W	(\2)&$FFFE,\1
	ENDM

CWAIT	MACRO	* x,y
	DC.W	((\2)&$FF)<<8|((\1)&$7F)<<1|1,$FFFE
	ENDM

CSKIP	MACRO	* x,y
	DC.W	((\2)&$FF)<<8|((\1)&$7F)<<1|1,$FFFF
	ENDM

CEND	MACRO
	DC.L	$FFFFFFFE
	ENDM
	ENDC
