; ie_fileio.s - Intuition Engine file I/O bridge stubs (WIP)

	xdef ie_fopen
	xdef ie_fread
	xdef ie_fclose

ie_fopen:
	; TODO: write FILE_NAME_PTR / FILE_CTRL open sequence
	rts

ie_fread:
	; TODO: write FILE_DATA_PTR / FILE_CTRL read sequence
	rts

ie_fclose:
	; TODO: write FILE_CTRL close sequence if required
	rts
