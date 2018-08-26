
; Grab all available memory into a buffer:

 include workbench:sysinc/exec/exec_lib.i

 move.l #65536,d7
 move.l #tab,a0

getmemlop:
 movem.l d7/a0,-(a7)
 move.l d7,d0
 moveq.l #1,d1	; chipmem
 move.l 4.w,a6
 jsr -198(a6) 
 movem.l (a7)+,d7/a0

 tst.l d0
 beq.s gotitall
 move.l d0,(a0)+
 add.l d7,d0
 move.l d0,(a0)+
 bra.s getmemlop

gotitall:
 sub.l #1024,d7
 bgt.s getmemlop
 
 move.l #-1,(a0)+
 
; Group memory into large chunks

; bra nogroup

 move.l #tab,a0
group:
 move.l (a0),d0
 blt.s groupedall
 beq.s thisonedone
 move.l 4(a0),d1
 lea 8(a0),a1

findnext:
 move.l (a1),d2
 blt.s foundall
 beq.s notthisone
 cmp.l d1,d2
 bgt.s notthisone
 cmp.l 4(a1),d1
 bgt.s notthisone
 move.l 4(a1),d1
ignore:
 move.l #0,(a1)
 move.l #0,4(a1)
 lea 8(a0),a1
notthisone:
 addq #8,a1
 bra.s findnext
 
foundall:
 move.l d1,4(a0)

thisonedone:
 addq #8,a0
 bra.s group
 
groupedall:
 
; release memory to system

nogroup:

; btst #7,$bfe001
; bne.s nogroup

 move.l #tab,a0
rellop:
 move.l (a0),d1
 blt.s relall
 beq.s norelthis
 move.l 4(a0),d0
 move.l d1,a1
 sub.l d1,d0
 move.l a0,-(a7)
 CALLEXEC FreeMem
 move.l (a7)+,a0
norelthis:
 addq #8,a0
 bra.s rellop
 
relall:
 rts
 
tab:
 ds.l 2000


