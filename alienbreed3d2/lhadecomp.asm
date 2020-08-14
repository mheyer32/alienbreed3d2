;-------------------------------------------------------------------------
;        D0 = Source pointer
;        A0 = Destination memory pointer
;        A1 = 16K Workspace
;        A2 = 65K Workspace
;        D1 = Pointer to list of the form:
;        
;           LONG <offset>
;           LONG <length>
;
;        NB: Terminated by _two_ zero longwords.
;
;        (If D1 = 0 then the entire source file is decompressed).
;-------------------------------------------------------------------------

UnLhA:
	IFNE	AGA
	incbin	"abinc:Decomp4_030.raw"
	ELSE
	incbin	"abinc:Decomp4.raw"
	ENDC
