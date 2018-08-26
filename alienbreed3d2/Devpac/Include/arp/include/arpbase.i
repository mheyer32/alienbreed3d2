	IFND LIBRARIES_ARPBASE_I
LIBRARIES_ARPBASE_I	SET	1
***********************************************************************
*
*	AmigaDOS Replacement Project -- Library Include File (Assembler)
*
***********************************************************************
*
*	History:
*
*	Version:	arpbase.i,v 34.00 02/27/88
*
*	Created by:	SDB
*	Revised:	SDB (v 5.00 05/31/87)
*			*---- Added meaningful alert numbers, revised macros,
*			*---- updated ArpBase structure to reflect current state.
*			*---- Added cheath's ASSIGN return codes as equates.
*			*---- plus usual grunt work (revisions, lvo's, etc.)
*			SDB (v6.04)
*			cdh V7.0
*			*---- added IntuiBase and GfxBase to ArpBase
*			sdb V7.2
*			*---- rearranged for more efficient lib code (ouch).
*			*---- DosBase IntuiBase and GfxBase have *all* changed!
*			*---- Few more alert #'s now get returned,
*			*---- new GURU macro replaces provincial MYALERT.
*			sdb v12 newstuff, see docs
*			cdh V14	Added dos.library offsets, everybody moves!
*			cdh V15 Added (volatile!) FindFirst etc offsets
*			cdh V19 Added structs and constants for wildcards
*			cdh V31 Final edit for V1.0 ARP 10/7/87
*			sdb V31.00
*				Final edits for release of developers materials.
*				Massive changes to make this file correspond
*				more closely with 'C' File.
*
*			SDB V32.00 Add Stuff for version 32, ASyncRun()
*				Returns and data structures.
*			SDB V32.01 Add ERROR_NO_CLI
*			SDB V32.3 Add ResidentPrg stuff
*			SDB V33.4 Final edits for release.
***********************************************************************
*
*	Copyright (c) 1987, by Scott Ballantyne
*
*	The arp.library, and related code and files may be freely used
*	by supporters of ARP.  Modules in the arp.library may not be
*	extracted for use in independent code, but you are welcome to
*	provide the arp.library with your work and call on it freely.
*
*	You are equally welcome to add new functions, improve the ones
*	within, or suggest additions.
*
*	BCPL programs are not welcome to call on the arp.library.
*	The welcome mat is out to all others.
***********************************************************************

	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"
	ENDC !EXEC_TYPES_I

	IFND EXEC_LIBRARIES_I
	INCLUDE "exec/libraries.i"
	ENDC !EXEC_LIBRARIES_I

	IFND EXEC_LISTS_I
	INCLUDE "exec/lists.i"
	ENDC !EXEC_LISTS_I

	IFND EXEC_SEMAPHORES_I
	INCLUDE	"exec/semaphores.i"
	ENDC !EXEC_SEMAPHORES_I

	IFND LIBRARIES_DOS_I
	INCLUDE "libraries/dos.i"
	ENDC !LIBRARIES_DOS_I

	IFND LIBRARIES_DOS_LIB_I
	INCLUDE "libraries/dos_lib.i"
	ENDC !LIBRARIES_DOS_LIB_I


	STRUCTURE ArpBase,LIB_SIZE	; Standard library node
		ULONG	SegList		; Pointer to loaded libcode (a BPTR).
		UBYTE	Flags		; Not used, yet!
		UBYTE	ESCChar		; Character to be used for escaping
		LONG	ArpReserved1	; ArpLib's use only!!
		CPTR	EnvBase		; Dummy library for MANX compatibility
		CPTR	DosBase		; Cached DosBase
		CPTR	GfxBase		; Cached GfxBase
		CPTR	IntuiBase	; Cached IntuitionBase
		STRUCT	ResLists,MLH_SIZE ; Resource trackers
		ULONG	ResidentPrgList	; Resident Programs.
		STRUCT	ResPrgProtection,SS_SIZE	; protection for above
		LABEL	ArpLib_Sizeof

*--------------- Following is here only for compatibility with MANX,
*--------------- don't use in new code!

	STRUCTURE EnvLib,LIB_SIZE	; fake library for MANX
		CPTR	EnvSpace	; access only when Forbidden!
		ULONG	EnvSize		; size of environment
		ULONG	EnvArpBase	; for EXPUNGE
		LABEL	EnvLib_Sizeof

*---------- Flags bit definitions
*
* These are used in release 33.4, but not by the library code, instead,
* individual programs which are affected check for these. Not ideal, but
* such is life.
*
*-------------------------------------------------------

	BITDEF	ARP,WILD_WORLD,0	; Mixed BCPL/Normal wildcards.
	BITDEF	ARP,WILD_BCPL,1		; Pure bcpl.

*----------- Rest of library style stuff

ArpName	MACRO
	dc.b	'arp.library',0
	ds.w	0
	ENDM

*---------- Current arp.library version.

ArpVersion EQU	34

*-------- Alert Object
* The alert object is what you use if you really must return an alert
* to the user.  You would normally OR this with another alert number from
* the alerts.h file.  Generally, these should be NON deadend alerts.
*
* For example, if you can't open ArpLibrary:
*
*	GURU	AG_OpenLib!AO_ArpLib
*----------------------------------------

AO_ArpLib	EQU	$00008036	; alert object

*-------- Specific Alerts you can get from ArpLib. -----------*

AN_ArpLib	EQU	$03600000	; alert number
AN_ArpNoMem	EQU	$03610000	; Arplibrary out of memory.
AN_ArpInputMem	EQU	$03610002	; No memory for input buffer.
AN_ArpNoMakeEnv	EQU	$83610003	; No memory to make EnvLib

AN_ArpNoDOS	EQU	$83630001	; Can't open DOS library
AN_ArpNoGfx	EQU	$83630002	; Can't open graphics
AN_ArpNoIntuit	EQU	$83630003	; Can't open intuition
AN_BadPackBlues	EQU	$83640000	; Bad packet returned to SendPacket()

AN_Zombie	EQU	$83600003	; AsyncRun() Exit code didn't.

AN_ArpScattered	EQU	$83600002	; Scatter loading not allowed for lib.

*---------- Tiny ALERT macro, assumes ExecBase is already in A6, also that you
*---------- have nothing important in d7, also that you want to return immediately.

GURU	MACRO	* optional alert number
	IFNC	'\1',''
	move.l	#\1,D7
	ENDC
	jmp	_LVOAlert(a6)
	ENDM

MYALERT	MACRO * ancient compatibility
	GURU	\1
	ENDM

*------------- Library Vector Offsets.


*
* This macro is used to define the DOS offsets without redefining the symbols-
*	To get the DOS symbols, INCLUDE dos_lib.i
*
LIBSKP	MACRO
COUNT_LIB   SET     COUNT_LIB-LIB_VECTSIZE
	ENDM

	LIBINIT

	LIBSKP	_LVOOpen
	LIBSKP	_LVOClose
	LIBSKP	_LVORead
	LIBSKP	_LVOWrite
	LIBSKP	_LVOInput
	LIBSKP	_LVOOutput
	LIBSKP	_LVOSeek
	LIBSKP	_LVODeleteFile
	LIBSKP	_LVORename
	LIBSKP	_LVOLock
	LIBSKP	_LVOUnLock
	LIBSKP	_LVODupLock
	LIBSKP	_LVOExamine
	LIBSKP	_LVOExNext
	LIBSKP	_LVOInfo
	LIBSKP	_LVOCreateDir
	LIBSKP	_LVOCurrentDir
	LIBSKP	_LVOIoErr
	LIBSKP	_LVOCreateProc
	LIBSKP	_LVOExit
	LIBSKP	_LVOLoadSeg
	LIBSKP	_LVOUnLoadSeg
	LIBSKP	_LVOGetPacket
	LIBSKP	_LVOQueuePacket
	LIBSKP	_LVODeviceProc
	LIBSKP	_LVOSetComment
	LIBSKP	_LVOSetProtection
	LIBSKP	_LVODateStamp
	LIBSKP	_LVODelay
	LIBSKP	_LVOWaitForChar
	LIBSKP	_LVOParentDir
	LIBSKP	_LVOIsInteractive
	LIBSKP	_LVOExecute
***
	LIBDEF	_LVOPrintf		; Print formatted data on current output.
	LIBDEF	_LVOFPrintf		; Print formatted data on file.
	LIBDEF	_LVOPuts		; Print string\n on stdout.
	LIBDEF	_LVOReadLine		; Get a line from stdin.
	LIBDEF	_LVOGADS		; Get args using template
	LIBDEF	_LVOAtol		; Convert Ascii to long int.
	LIBDEF	_LVOEscapeString	; Handle escapes in string.
	LIBDEF	_LVOCheckAbort		; Check for CNTRL-C
	LIBDEF	_LVOCheckBreak		; Check for CNTRL c d e or f
	LIBDEF	_LVOGetenv		; Get value of environment variable
	LIBDEF	_LVOSetenv		; Set value of environment variable
	LIBDEF	_LVOFileRequest		; Filename Requester
	LIBDEF	_LVOCloseWindowSafely	; Closes shared IDCMP window w/o GURU
	LIBDEF	_LVOCreatePort		; Create a message port
	LIBDEF	_LVODeletePort		; Delete a message port
	LIBDEF	_LVOSendPacket		; Send a dos packet
	LIBDEF	_LVOInitStdPacket	; initialize a standard packet
	LIBDEF	_LVOPathName		; Return Complete pathname of file/directory.
	LIBDEF	_LVOAssign		; Assign a logical device name
	LIBDEF	_LVODosAllocMem		; DOS compatible memory allocator
	LIBDEF	_LVODosFreeMem		; DOS compatible memory free-er
	LIBDEF	_LVOBtoCStr		; Copy a BCPL string to C string
	LIBDEF	_LVOCtoBStr		; Copy a C string to BCPL string
	LIBDEF	_LVOGetDevInfo		; Get pointer to head of DevInfo
	LIBDEF	_LVOFreeTaskResList	; Free Tracked resources for this task
	LIBDEF	_LVOArpExit		; Exit, freeing tracked resources.
	LIBDEF	_LVOArpAlloc		; Allocate memory with tracking
	LIBDEF	_LVOArpAllocMem		; Track AllocMem allocation
	LIBDEF	_LVOArpOpen		; Track open files
	LIBDEF	_LVOArpDupLock		; Track duped locks
	LIBDEF	_LVOArpLock		; Track allocated locks
	LIBDEF	_LVORListAlloc		; Like ArpAlloc for free reslist
	LIBDEF	_LVOFindCLI		; Get a process given a task number
	LIBDEF	_LVOQSort		; Quick Sort

	LIBDEF	_LVOPatternMatch	; Match a string with a pattern (wildcards!)
	LIBDEF	_LVOFindFirst		; Search directory w/wildcards
	LIBDEF	_LVOFindNext		; Continue search w/wildcards
	LIBDEF	_LVOFreeAnchorChain	; Free mem from FindFirst/Next

	LIBDEF	_LVOCompareLock		; Compare two disk locks

	LIBDEF	_LVOFindTaskResList	; Find resource list for this task
	LIBDEF	_LVOCreateTaskResList 	; Create a new nested task reslist
	LIBDEF	_LVOFreeResList		; Free an un-attached reslist
	LIBDEF	_LVOFreeTrackedItem	; Free a tracked item
	LIBDEF	_LVOGetTracker		; Get a tracker node

	LIBDEF	_LVOGetAccess		; Lock access to a node
	LIBDEF	_LVOFreeAccess		; Allow resource to flush if lowmem

	LIBDEF	_LVOFreeDAList		; Free a DosAllocmem list
	LIBDEF	_LVOAddDANode		; Add a node to a DA list
	LIBDEF	_LVOAddDADevs		; Add devices to a DA list

	LIBDEF	_LVOStrcmp		; Compare two null-terminated strs
	LIBDEF	_LVOStrncmp		; Compare up to N chars
	LIBDEF	_LVOToupper		; Convert to UC
	LIBDEF	_LVOSyncRun		; Run program as subroutine
* Added V32 of arp.library
	LIBDEF	_LVOASyncRun		; Run program in background
	LIBDEF	_LVOLoadPrg		; As for LoadSeg(), but searches Res&Path
	LIBDEF	_LVOPreParse		; Create tokenized PatternMatch string
* V33
	LIBDEF	_LVOStamptoStr		; Date stamp to string
	LIBDEF	_LVOStrtoStamp		; Date string to stamp

	LIBDEF	_LVOObtainResidentPrg	; Get a resident program
	LIBDEF	_LVOAddResidentPrg	; Add it
	LIBDEF	_LVORemResidentPrg	; Remove it
	LIBDEF	_LVOUnLoadPrg		; Check Sum code
	LIBDEF	_LVOLMult		; long mult
	LIBDEF	_LVOLDiv		; long division, signed
	LIBDEF	_LVOLMod		; long %

	LIBDEF	_LVOCheckSumPrg		; Refresh checksum for resident code
	LIBDEF	_LVOTackOn		; Add A1 onto directory string A0
	LIBDEF	_LVOBaseName		; Get Filename from complete dir string
	LIBDEF	_LVOReleaseResidentPrg	; True if code is resident and was released.
***

*---------- Return codes you can get from calling Assign:

ASSIGN_OK	EQU	0	; Everything is cool and groovey
ASSIGN_NODEV	EQU	1	; "Physical" is not valid for assignment
ASSIGN_FATAL	EQU	2	; Something really icky happened
ASSIGN_CANCEL	EQU	3	; Tried to cancel something that won't cancel.

*--------- Size of buffer you need for ReadLine

MaxInputBuf	EQU	256

* Macro to declare things as unions:

UNION	MACRO	*name,maxsize
UOFFSET	SET	SOFFSET
\1	EQU	SOFFSET
SOFFSET	SET	SOFFSET+\2
	ENDM
* member of union

UMEMB MACRO	* name
\1	EQU	UOFFSET
	ENDM

******************************* File Requester *******************************
********************** Submit the following to FileRequest() *****************
******************************************************************************

	STRUCTURE FileRequester,0
		CPTR	fr_Hail			; Hailing text
		CPTR	fr_File			; *Filename array (FCHARS+1)
		CPTR	fr_Dir			; *Directory array (DSIZE+1)
		CPTR	fr_Window		; Window requesting or NULL
		UBYTE	fr_FuncFlags		; Set bitdef's below
		UBYTE	fr_reserved1		; Set to NULL
		APTR	fr_Function		; Func to call for wildcards
		LONG	fr_reserved2		; RESERVED
		LABEL	fr_SIZEOF

*****************************************************************
* The following are the equates for fr_FuncFlags. These bits tell
* FileRequest() what your fr_UserFunc is expecting, and what FileRequest()
* should call it for.
*
* You are called like so
* fr_Function(Mask, Object)
* ULONG	Mask
* CPTR	*Object
*
* The Mask is a copy of the flag value that caused FileRequest() to call
* your function. You can use this to determine what action you need to
* perform, and exactly what Object is, so you know what to do and
* what to return.
*
	BITDEF	FR,DoWildFunc,7	; Call me with a FIB and a name, ZERO return accepts.
	BITDEF	FR,DoMsgFunc,6	; You get all IDCMP message not for FileRequest()
	BITDEF	FR,DoColor,5	; Set this bit for that new and differnt look
	BITDEF	FR,NewIDCMP,4	; Force a new IDCMP (only if fr_Window != NULL)
	BITDEF	FR,NewWindFunc,3 ; You get to modify the NewWindow struct.
	BITDEF	FR,AddGadFunc,2	; You get to add gadgets
	BITDEF	FR,GEventFunc,1	; Function to call if one of your gads is selected
	BITDEF	FR,ListFunc,0	; not implemented.

FCHARS	EQU	32			; Directory name sizes
DSIZE	EQU	33

FR_FIRST_GADGET	EQU	$7680		; User gadgetID's must be less than this.
************************************************************************
************************ PATTERN MATCHING ******************************
************************************************************************

* structure expected by FindFirst, FindNext.
* Allocate this structure and initialize it as follows:
*
* Set ap_BreakBits to the signal bits (CDEF) that you want to take a
* break on, or NULL, if you don't want to convenience the user.
*
* If you want to have the FULL PATH NAME of the files you found,
* allocate a buffer at the END of this structure, and put the size of
* it into ap_Length.  If you don't want the full path name, make sure
* you set ap_Length to zero.  In this case, the name of the file, and stats
* are available in the ap_Info, as per usual.
*
* Then call FindFirst() and then afterwards, FindNext() with this structure.
* You should check the return value each time (see below) and take the
* appropriate action, ultimately calling FreeAnchorChain() when there are
* no more files and you are done.  You can tell when you are done by
* checking for the normal AmigaDOS return code ERROR_NO_MORE_ENTRIES.
*

	STRUCTURE AnchorPath,0
		CPTR	ap_Base		; pointer to first anchor
		CPTR	ap_Last		; pointer to last anchor
		LONG	ap_BreakBits	; Bits we want to break on
		LONG	ap_FoundBreak	; Bits we broke on. Also returns ERROR_BREAK
		ULONG	ap_Length	; Actual size of ap_Buf, set to 0 if none.
		STRUCT	ap_Info,fib_SIZEOF	; FileInfoBlock
		LABEL   ap_Buf		; Buffer for path name, allocated by user
		LABEL   ap_SIZEOF

*
* Structure used by the pattern matching functions, no need to obtain, diddle
* or allocate this yourself
*
	STRUCTURE Anchor,0
		CPTR    an_Next		; next anchor
		CPTR    an_Pred		; previous
		LONG	an_Lock		; a FileLock pointer (BPTR)
		CPTR    an_Info		; pointer to a FileInfoBlock
		LONG    an_Status	; type of this anchor node
		UNION	an_BSTR,2	; more memory allocated as needed
		    UMEMB an_Text	; actual instance of a BSTRing 
		    UMEMB an_Actual	; bytes 1 and 2
		LABEL   an_SIZEOF

* Constants used by wildcard routines, these are the pre-parsed tokens
* referred to by pattern match.  It is not necessary for you to do
* anything about these, FindFirst() FindNext() handle all these for you.

P_ANY		EQU	$80	; Token for '*' or '#?
P_SINGLE	EQU	$81	; Token for '?'
P_ORSTART	EQU	$82	; Token for '('
P_ORNEXT	EQU	$83	; Token for '|'
P_OREND		EQU	$84	; Token for ')'
P_TAG		EQU	$85	; Token for '{'
P_TAGEND	EQU	$86	; Token for '}'
P_NOTCLASS	EQU	$87	; Token for '^'
P_CLASS		EQU	$88	; Token for '[]'
P_REPBEG	EQU	$89	; Token for '['
P_REPEND	EQU	$8A	; Token for ']'

* Values for an_Status, NOTE: These are the actual bit numbers

COMPLEX_BIT	EQU	1	; Parsing complex pattern
EXAMINE_BIT	EQU	2	; Searching directory

* Returns from FindFirst(), FindNext()
* You can also get dos error returns, such as ERROR_NO_MORE_ENTRIES,
* these are in the dos.h file.
*
ERROR_BUFFER_OVERFLOW	EQU	303	; User or internal buffer overflow
ERROR_BREAK		EQU	304	; A break character was received


* Structure used by AddDANode, AddDADevs, FreeDAList
*
* This structure is used to create lists of names,
* which normally are devices, assigns, volumes, files, or directories.

	STRUCTURE DirectoryEntry,0
		CPTR	de_Next			; Next in list
		BYTE	de_Type			; DLX_mumble
		BYTE	de_Flags		; For future expansion, do not use!
		LABEL	de_Name			; name of thing found
		LABEL	de_SIZEOF

* Defines you use to get a list of the devices you want to look at.
* For example, to get a list of all directories and volumes, do
*
*	move.l	#DLF_DIRS!DLF_VOLUMES,d0
*	move.l	myDalist(pc),a0
*	SYSCALL	AddDADevs		; ArpBase already in A6, of course
*
* After this, you can examine the de_Type field of the elements added
* to your list (if any) to discover specifics about the objects added.
*
* Note that if you want only devices which are also disks, you must
* request DLF_DEVICES!DLF_DISKONLY
*

	BITDEF	DL,DEVICES,0	; Return devices
	BITDEF	DL,DISKONLY,1	; Modifier for above: Return disk devices only
	BITDEF	DL,VOLUMES,2	; Return volumes only
	BITDEF	DL,DIRS,3	; Return assigned devices only

* Legal de_Type values, check for these after a call to AddDADevs(), or
* use on your own as the ID values in AddDANode()

DLX_FILE	EQU	0	; AddDADevs() can't determine this
DLX_DIR		EQU	8	; AddDADevs() can't determine this
DLX_DEVICE	EQU	16	; It's a resident device

DLX_VOLUME	EQU	24	; Device is a volume
DLX_UNMOUNTED	EQU	32	; Device is not resident

DLX_ASSIGN	EQU	40	; Device is a logical assignment

************************************************************************
************************** RESOURCE TRACKING ***************************
************************************************************************

*
* NOTE: This is a DosAllocMem'd list, this is done for you when you
* call CreateTaskResList(), typically, you won't need to access/allocate
* this structure.
*
	STRUCTURE ResList,0
		STRUCT	rl_Node,MLN_SIZE  ; Used by arplib to link reslist's
		CPTR	rl_TaskID	   ; Owner of this list
		STRUCT	rl_FirstItem,MLH_SIZE	; List of TrackedResource's
		CPTR	rl_Link		; For temp removal from task rlist
		LABEL	RL_SIZEOF

* The rl_FirstItem list (above) is a list of TrackedResource (below).
* It is very important that nothing in this list depend on the task
* existing at resource freeing time (i.e., RemTask(0L) type stuff,
* DeletePort() and the rest).
*
* The tracking functions return a struct Tracker *Tracker to you, this
* is a pointer to whatever follows the tr_ID variable.
* The default case is reflected below, and you get it if you call
* GetTracker() ( see DefaultTracker below).
*
* NOTE: The two user variables mentioned in an earlier version don't
* exist, and never did. Sorry about that (SDB).
* 
* However, you can still use ArpAlloc to allocate your own tracking
* nodes and they can be any size or shape you like, as long as the
* base structure is preserved.  They will be freed automagically
* just like the default trackers.

	STRUCTURE TrackedResource,0
		STRUCT	tr_Node,MLN_SIZE	; Double linked pointer
		BYTE	tr_Flags		; Don't touch
		BYTE	tr_Lock			; Don't touch, for Get/FreeAcess
		SHORT	tr_ID			; ID for this item class
* The struct DefaultTrackter portion of the structure
* The stuff below this point can conceivably vary, depending
* on user needs, etc.  This reflects the default.
		UNION	tr_Object,4		; The thing being tracked
		    UMEMB tr_Object_tg_Verify	; for use during TRAK_GENERIC
		    UMEMB tr_Object_tr_Resource ; whatever
		UNION	tr_Extra,4		; only needed sometimes
		    UMEMB tr_Extra_tg_Function	; function to call for TRAK_GENERIC
		    UMEMB tr_Extra_tr_Window2	; for TRAK_WINDOW
		LABEL	trk_SIZEOF		; trk_ fixes COLLISION WITH TMPRAS...

tr_Object_tg_Value EQU tr_Object_tg_Verify

* You get a pointer to a struct of the following type when you call
* GetTracker().  You can change this, and use ArpAlloc() instead of
* GetTracker() to do tracking. Of course, you have to take a wee bit
* more responsibility if you do, as well as if you use TRAK_GENERIC
* stuff.
*
* TRAK_GENERIC folks need to set up a task function to be called when an
* item is freed.  Some care is required to set this up properly.
*
* Some special cases are indicated by the unions below, for TRAK_WINDOW,
* if you have more than one window opened, and don't want the IDCMP closed
* particularly, you need to set a ptr to the other window in dt_Window2.
* See CloseWindowSafely() for more info.  If only one window, set this to NULL.

	STRUCTURE DefaultTracker,-2
		SHORT	dt_ID		; Different from C file, but it's ok.
		UNION	dt_Object,4	; the object being tracked
		    UMEMB dt_Resource	; Whatever
		    UMEMB tg_Verify	; whatever
		UNION	dt_Extra,4
		    UMEMB tg_Function	; function to call for TRAK_GENERIC
		    UMEMB dt_Window2
		LABEL	dt_SIZEOF

tg_Value EQU tg_Verify	; ancient compatibility
* Tracked Item Types
*	The id types below show the types of resources which may
* be tracked in a resource list.
*
TRAK_AAMEM	EQU	0		; Default generic (ArpAlloc) element
TRAK_LOCK	EQU	1		; File Lock
TRAK_FILE	EQU	2		; Opened File
TRAK_WINDOW	EQU	3		; Window (see discussion)
TRAK_SCREEN	EQU	4		; Screen
TRAK_LIBRARY	EQU	5		; Opened library
TRAK_DAMEM	EQU	6		; Pointer to DosAllocMem block
TRAK_MEMNODE	EQU	7		; AllocEntry() node.
TRAK_SEGLIST	EQU	8		; Program Segment List
TRAK_RESLIST	EQU	9		; ARP (nested) ResList
TRAK_MEM	EQU	10		; Memory ptr/length
TRAK_GENERIC	EQU	11		; Generic Element
TRAK_DALIST	EQU	12		; DAlist ( as used by file request )
TRAK_ANCHOR	EQU	13		; Anchor chain
TRACK_MAX	EQU	13		; Anything else is tossed.

	BITDEF	TR,UNLINK,7		; Bit for freeing the node
	BITDEF	TR,RELOC,6		; This element may be relocated (not used yet
	BITDEF	TR,MOVED,5		; Item moved

*--- Returns from CompareLock()

LCK_EQUAL	EQU	0	; Locks refer to the same object
LCK_VOLUME	EQU	1	; Locks are on the same volume
LCK_DIFVOL1	EQU	2	; Locks are on different volumes
LCK_DIFVOL2	EQU	3	; Locks are on different volumes

*----------- Stuff For ASyncRun() and friends
*---------- Message sent back on request by an exiting process.
*---------- You request this by putting the address of your
*---------- message in pcb_LastGasp, and initializing the
*---------- ReplyPort variable of the zombiemsg to the port you wish
*---------- the message posted to.

	STRUCTURE ZombieMsg,MN_SIZE
		ULONG	zm_TaskNum		; task ID
		ULONG	zm_ReturnCode		; Process's return code 
		ULONG	zm_Result2		; System return
		STRUCT	zm_ExitTime,ds_SIZEOF	; Date stamp at time of exit
		ULONG	zm_UserInfo		; for whatever you like
		LABEL	zm_SIZEOF
		
*------------ Structure required by ASyncRun() -- see docs for more info.
*------------
	STRUCTURE ProcessControlBlock,0
		ULONG	pcb_StackSize	; Stacksize for new process
		BYTE	pcb_Pri		; Priority of new process 
		BYTE	pcb_Control	; Control bits, see BITDEF's below.
		APTR	pcb_TrapCode	; Optional trapcode vector
		ULONG	pcb_Input	; Optional default input
		ULONG	pcb_Output	; Optional default output
		UNION	pcb_Console,4
		    UMEMB pcb_Splatfile ; file to use for Open("*")
		    UMEMB pcb_ConName	; CON: filename 
		ULONG	pcb_LoadedCode	; If not null, use this code
		CPTR	pcb_LastGasp	; ReplyMsg to be filled in by exit code
		CPTR	pcb_WBProcess	; Valid only when PRB_NOCLI.
		LABEL	pcb_Sizeof

*---- bits to set in pcb_Control

	BITDEF	PR,SAVEIO,0		; don't release/check file handles
	BITDEF	PR,CLOSESPLAT,1		; close splat, must request explicitly
	BITDEF	PR,NOCLI,2		; Don't want a CLI
	BITDEF	PR,INTERACTIVE,3	; Set interactive flag = TRUE. Cli's only.
	BITDEF	PR,CODE,4		; Actual code address. Be Careful!
	BITDEF	PR,STDIO,5		; Do the stdio thing, splat = CON:filename

*----- Error returns

PR_NOFILE	EQU	-1		; Can't find or LoadSeg file.
PR_NOMEM	EQU	-2		; No memory for one thing or another
PR_NOCLI	EQU	-3		; Caller must be CLI (SyncRun() only).

PR_NOSLOT	EQU	-4	; No slot in task array
PR_NOINPUT	EQU	-5	; Can't get input file
PR_NOOUTPUT	EQU	-6	; Can't get output file
PR_NOLOCK	EQU	-7	; Problem obtaining locks
PR_ARGERR	EQU	-8	; Bad Argument
PR_NOBCPL	EQU	-9	; Bad program passed to ASyncRun
PR_BADLIB	EQU	-10	; Bad library version
PR_NOSTDIO	EQU	-11	; Couldn't get stdio handles.

*---------- Programs should return this as result2 if no CLI:

ERROR_NOT_CLI	EQU	400	; Program/function needed a CLI

*-------------------------------- Resident Program support -------*
*--- This node is allocated for you when you AddResidentPrg() a segment.
*--- They are stored as a single linked list with the root in ArpBase,
*--- if you absolutely *must* wander through this list instead of
*--- using the supplied functions, then you must first obtain the
*--- the semaphore which protects this list, and then release it afterwards.
*--- Do not use Forbid() and Permit() to gain exclusive access!
*------------------------------------------------------------------*

	STRUCTURE ResidentProgramNode,0
		CPTR	rpn_Next		; next node, or NULL
		LONG	rpn_Usage		; Number of times this code is used
		ULONG	rpn_CheckSum		; checksum for this code
		BPTR	rpn_Segment		; the segment
		LABEL	rpn_Name		; the name of the program.
		LABEL	rpn_SIZEOF

*--- If your program starts with this structure, ASyncRun() and SyncRun()
*--- will override a users stack request with the value in rpt_StackSize.
*--- Furthermore, if you are actually attached to the resident list,
*--- a memory block of size rpt_DataSize will be allocated for you, and
*--- a pointer to this data passed to you in register A4.  You may use this
*--- block to clone the data segment of programs, thus resulting in
*--- one copy of text, but multiple copies of data/bss for each process
*--- invocation.  If you are resident, your program will start at rpt_Instruction,
*--- otherwise, it will be launched from the initial branch.


	STRUCTURE	ResidentProgramTag,0
		BPTR	rpt_NextSeg	; provided by DOS at LoadSeg time.
		UWORD	rpt_BRA		; Short branch to executable
		UWORD	rpt_Magic	; resident majik value
		ULONG	rpt_StackSize	; min stack for this process
		ULONG	rpt_DataSize	; Size of data allocation (may be zero)
		LABEL	rpt_Instruction	; start here if resident

************* The form of the ARP allocated node in your tasks memlist when
************* launched as a resident program, note that the data portion
************* of the node will only exist if you have specified a nonzero
************* value for rpt_DataSize. Note also that this structure is READ ONLY,
************* modify values in this at your own risk. The stack stuff is for
************* tracking, if you need actual addresses or stacksize, check the
************* normal places for it in your process/task structure.

	STRUCTURE ProcessMemory,LN_SIZE
		UWORD	pm_Num		; number of entries, 1 if no data 2 if data
		CPTR	pm_Stack
		ULONG	pm_StackSize
		CPTR	pm_Data		; pointer to data
		ULONG	pm_DataSize
		LABEL	pm_Sizeof
* Search for the name below on your TC_MEMENTRY list if you need to
* get the above node.  Remember, you modify the above at your own
* risk!
*
PMEM_NAME	MACRO
	dc.b	'ARP_PMEM',0	; memlist node for stack and/or data
	ds.w	0
	ENDM

RESIDENT_MAGIC		EQU	$4AFC		; same as RTC_MATCHWORD (trapf)

********** Note that the initial branch and the rpt_Instruction do not
********** have to be the same.  This allows different actions to be taken
********** if you are diskloaded or resident.  DataSize memory will be allocated
********** only if you are resident, but stacksize will override all user
********** stack requests.
**********
********** Macro to facilitate initialization of this structure, place at start
********** of code.
********** Usage is RESIDENT STACKSIZE [ optional  DATASIZE LABEL ]

RESIDENT MACRO
 IFEQ NARG
	FAIL
 ENDC
 IFC '\3',''
	bra.s	resident_start\@	; branch to rp_instruction
 ENDC
 IFNC '\3',''
	bra.s	\3		; branch to user label
 ENDC
	dc.w	RESIDENT_MAGIC		; our magic value
	dc.l	\1			; stacksize
 IFNC '\2',''
	dc.l	\2			; datasize
 ENDC
 IFC '\2',''
	dc.l	0			; of zero
 ENDC
resident_start\@
	ENDM

*--------- String/Date structures etc
    STRUCTURE	DateTime,0
	STRUCT	dat_Stamp,ds_SIZEOF	;DOS DateStamp
	UBYTE	dat_Format		;controls appearance of dat_StrDate
	UBYTE	dat_Flags		;see BITDEF's below
	CPTR	dat_StrDay		;day of the week string
	CPTR	dat_StrDate		;date string
	CPTR	dat_StrTime		;time string
	LABEL	dat_SIZEOF
*
* You need this much room for each of the DateTime strings:
LEN_DATSTRING	EQU	10

*	flags for dat_Flags
*
	BITDEF	DT,SUBST,0		;substitute Today, Tomorrow, etc.
	BITDEF	DT,FUTURE,1		;day of the week is in future
*
*	date format values
*
FORMAT_DOS	equ	0
FORMAT_INT	equ	1
FORMAT_USA	equ	2
FORMAT_CDN	equ	3
FORMAT_MAX	equ	FORMAT_CDN

*---------- handy macros

LINKEXE	MACRO
	LINKLIB	_LVO\1,4
	ENDM

* LINKDOS now uses ArpBase
* CALLDOS was nuked, to reduce confusion

LINKDOS	MACRO
	jsr	_LVO\1(a6)
	ENDM


CALLEXE	MACRO
	move.l	4,a6
	jsr	_LVO\1(a6)
	ENDM

* SYSCALL re-revised for only one arg
*	DosBase should always use ArpBase, or DosBase, in A6

SYSCALL	MACRO
	jsr	_LVO\1(A6)
	ENDM

* Use this macro if arp.library can't be found.
*	Note the assumption that stack is offset by 8 from return addr.
*	After the macro, register A6 is ARPBASE
*
	IFD	MANX
ALIBLNG	EQU	28
	ENDC

* Use this macro to open arp.library and avoid recoverable alerts.
* Saves D0/A0 on stack.
* After executing, A6 = ARPBASE and stack points at D0/A0
*
OPENARP	MACRO
	IFC	'\1',''
	RESIDENT	4000,0
	ENDC
	movem.l	d0/a0,-(sp)
	move.l	4,A6
	lea.l	ARPNAME,a1		; Get ArpBase
	moveq.l	#ArpVersion,d0
	SYSCALL	OpenLibrary
	tst.l	d0
	bne.s	okgo

	lea	dname,A1
	SYSCALL	OpenLibrary
	tst.l	D0
	beq.s	1$
	move.l	D0,A6
	SYSCALL	Output			;standard output file handle
	move.l	d0,d1
	beq.s	1$			; No output. Phoey.
	move.l	#alibmsg,d2		;tell user he needs to find library
	IFND	MANX
	move.l	#aliblng,d3
	ENDC
	IFD	MANX
	moveq	#ALIBLNG,d3
	ENDC
	SYSCALL	Write
1$:	addq	#8,sp
	rts

dname	dc.b	'dos.library',0
alibmsg	dc.b	'you need '
ARPNAME:	ArpName
	dc.b	' V33+',$a
aliblng	equ	*-alibmsg
	ds.w	0
okgo:	move.l	D0,A6
	ENDM


	INCLUDE	"libraries/arpcompat.i"

	ENDC	!LIBRARIES_ARPBASE_I
