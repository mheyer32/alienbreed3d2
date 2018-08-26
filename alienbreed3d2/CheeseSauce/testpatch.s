START:
 move.l 4.w,a6
 move.l #doslibname,a1
 moveq #0,d0
 jsr -552(a6)
 move.l d0,doslib


 move.l doslib,a6
 move.l #LLname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LLhandle

 rts

; move.l doslib,a6
; move.l d0,d1
; move.l #LINKS,d2
; move.l #10000,d3
; jsr -42(a6)

 move.l doslib,a6
 move.l LLhandle,d1
 jsr -36(a6)



doslib: dc.l 0
doslibname: dc.b 'dos.library',0
 even
LLhandle: dc.l 0 
LLname: dc.b "bill:twiddle",0
 even

 include "ab3:source_4000/ab3diipatchidr.s"
 