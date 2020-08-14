_LVOOpenIntuition	EQU	-30
_LVOIntuition	EQU	-36
_LVOAddGadget	EQU	-42
_LVOClearDMRequest	EQU	-48
_LVOClearMenuStrip	EQU	-54
_LVOClearPointer	EQU	-60
_LVOCloseScreen	EQU	-66
_LVOCloseWindow	EQU	-72
_LVOCloseWorkBench	EQU	-78
_LVOCurrentTime	EQU	-84
_LVODisplayAlert	EQU	-90
_LVODisplayBeep	EQU	-96
_LVODoubleClick	EQU	-102
_LVODrawBorder	EQU	-108
_LVODrawImage	EQU	-114
_LVOEndRequest	EQU	-120
_LVOGetDefPrefs	EQU	-126
_LVOGetPrefs	EQU	-132
_LVOInitRequester	EQU	-138
_LVOItemAddress	EQU	-144
_LVOModifyIDCMP	EQU	-150
_LVOModifyProp	EQU	-156
_LVOMoveScreen	EQU	-162
_LVOMoveWindow	EQU	-168
_LVOOffGadget	EQU	-174
_LVOOffMenu	EQU	-180
_LVOOnGadget	EQU	-186
_LVOOnMenu	EQU	-192
_LVOOpenScreen	EQU	-198
_LVOOpenWindow	EQU	-204
_LVOOpenWorkBench	EQU	-210
_LVOPrintIText	EQU	-216
_LVORefreshGadgets	EQU	-222
_LVORemoveGadget	EQU	-228
_LVOReportMouse	EQU	-234
_LVORequest	EQU	-240
_LVOScreenToBack	EQU	-246
_LVOScreenToFront	EQU	-252
_LVOSetDMRequest	EQU	-258
_LVOSetMenuStrip	EQU	-264
_LVOSetPointer	EQU	-270
_LVOSetWindowTitles	EQU	-276
_LVOShowTitle	EQU	-282
_LVOSizeWindow	EQU	-288
_LVOViewAddress	EQU	-294
_LVOViewPortAddress	EQU	-300
_LVOWindowToBack	EQU	-306
_LVOWindowToFront	EQU	-312
_LVOWindowLimits	EQU	-318
_LVOSetPrefs	EQU	-324
_LVOIntuiTextLength	EQU	-330
_LVOWBenchToBack	EQU	-336
_LVOWBenchToFront	EQU	-342
_LVOAutoRequest	EQU	-348
_LVOBeginRefresh	EQU	-354
_LVOBuildSysRequest	EQU	-360
_LVOEndRefresh	EQU	-366
_LVOFreeSysRequest	EQU	-372
_LVOMakeScreen	EQU	-378
_LVORemakeDisplay	EQU	-384
_LVORethinkDisplay	EQU	-390
_LVOAllocRemember	EQU	-396
_LVOAlohaWorkbench	EQU	-402
_LVOFreeRemember	EQU	-408
_LVOLockIBase	EQU	-414
_LVOUnlockIBase	EQU	-420
_LVOGetScreenData	EQU	-426
_LVORefreshGList	EQU	-432
_LVOAddGList	EQU	-438
_LVORemoveGList	EQU	-444
_LVOActivateWindow	EQU	-450
_LVORefreshWindowFrame	EQU	-456
_LVOActivateGadget	EQU	-462
_LVONewModifyProp	EQU	-468

CALLINT	MACRO
	move.l	_IntuitionBase,a6
	jsr	_LVO\1(a6)
	ENDM

INTNAME	MACRO
	dc.b	'intuition.library',0
	ENDM
