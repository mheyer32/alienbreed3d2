 move.l 4.w,a6
 move.l #doslibname,a1
 moveq #0,d0
 jsr -552(a6)
 move.l d0,doslib

 move.l doslib,a6
 move.l #conny,d1
 move.l #1006,d2
 jsr -30(a6)
 move.l d0,LLhandle

 move.l doslib,a6
 move.l #thingy,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,LLhandle

 rts

doslib: dc.l 0
LLhandle: dc.l 0

thingy: dc.b "faff:splib",0

conny: dc.b "CON:",0

doslibname: dc.b 'dos.library',0
 even
