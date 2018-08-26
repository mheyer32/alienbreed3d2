******************************************************

ENDOFQUEUE: dc.l 0

INITQUEUE:

 move.l #WorkSpace,ENDOFQUEUE

 rts

QUEUEFILE:
; On entry:
; a0=Pointer to filename
; d0=Ptr to dest. of addr
; d1=ptr to dest. of len.
; typeofmem=type of memory

 movem.l d0-d7/a0-a6,-(a7)
 
 move.l ENDOFQUEUE,a1
 
 move.l d0,(a1)+
 move.l d1,(a1)+
 move.l TYPEOFMEM,(a1)+
 move.w #79,d0
.copyname:
 move.b (a0)+,(a1)+
 dbra d0,.copyname
 
 add.l #100,ENDOFQUEUE
 
 movem.l (a7)+,d0-d7/a0-a6
 
 rts

FLUSHQUEUE:

 bsr FLUSHPASS
 
tryagain
 tst.b d6
 beq .loadedall

* Find first unloaded file and prompt for disk.
 move.l #WorkSpace,a2
.findfind:
 tst.l (a2)
 bne.s .foundunloaded
 add.l #100,a2
 bra.s .findfind
.foundunloaded:

* A2 points at an unloaded file thingy.
* Prompt for the disk.

 move.l #mnu_diskline,a3
 move.l #$20202020,(a3)+
 move.l #$20202020,(a3)+
 move.l #$20202020,(a3)+
 move.l #$20202020,(a3)+
 move.l #$20202020,(a3)+
 
; move.l #VOLLINE,a3
 move.l #mnu_diskline+10,a3

 moveq #-1,d0
 move.l a2,a4
 add.l #12,a4
.notfoundyet:
 addq #1,d0
 cmp.b #':',(a4)+
 bne.s .notfoundyet

 move.w d0,d1
 asr.w #1,d1
 sub.w d1,a3

 move.l a2,a4
 add.l #12,a4

; move.w #79,d0
.putinvol:
 move.b (a4)+,(a3)+
 dbra d0,.putinvol

 movem.l d0-d7/a0-a6,-(a7)
 
; move.w #23,FADEAMOUNT
; jsr FADEDOWNTITLE 
 
; move.w #3,OptScrn
; move.w #0,OPTNUM
; jsr DRAWOPTSCRN

 jsr mnu_GETBLITINT

 jsr mnu_setscreen

 lea mnu_askfordisk,a0
 jsr mnu_domenu
 
 jsr mnu_clearscreen
 
 jsr mnu_DROPBLITINT

;.wtrel:
; btst #7,$bfe001
; beq.s .wtrel
;
;.wtclick:
; btst #6,$bfe001
; bne.s .wtclick

; jsr CLROPTSCRN
 
; move.w #23,FADEAMOUNT
; jsr FADEUPTITLE 
 
 movem.l (a7)+,d0-d7/a0-a6

 bsr FLUSHPASS
 
 bra tryagain

.loadedall
 rts

FLUSHPASS:
 move.l #WorkSpace,a2
 moveq #0,d7	; loaded a file
 moveq #0,d6	; tried+failed
 
.flushit
 move.l a2,d0
 cmp.l ENDOFQUEUE,d0
 bge.s FLUSHED

 tst.l (a2)
 beq.s .donethisone

 lea 12(a2),a0	; ptr to name
 
 move.l 8(a2),TYPEOFMEM
 
 jsr TRYTOOPEN
 tst.l d0
 beq.s .failtoload
 
 move.l d0,handle
 jsr DEFLOADFILE 
 st d7

 move.l (a2),a3
 move.l d0,(a3)
 
 move.l 4(a2),d0
 beq.s .nolenstore
 
 move.l d0,a3
 move.l d1,(a3)
 
.nolenstore:
 move.l #0,(a2)
 bra.s .donethisone
 
.failtoload
 st d6

.donethisone:
 add.l #100,a2
 bra .flushit

FLUSHED:
 rts


TRYTOOPEN:
 movem.l d1-d7/a0-a6,-(a7)
 move.l a0,d1
 move.l doslib,a6
 move.l #1005,d2
 jsr -30(a6)
 movem.l (a7)+,d1-d7/a0-a6
 rts

***************************************************

SFX_NAMES:
 dc.l ScreamName,4400
 dc.l ShootName,7200
 dc.l 0,0
; dc.l MunchName,5400
 dc.l PooGunName,4600
 dc.l CollectName,3400
;5
 dc.l DoorNoiseName,8400
 dc.l BassName,8000
 dc.l StompName,4000
 dc.l LowScreamName,8600
 dc.l BaddieGunName,6200
;10
; dc.l 0,0
 dc.l SwitchNoiseName,1200
 dc.l ReloadName,4000
 dc.l NoAmmoName,2200
 dc.l SplotchName,3000
 dc.l SplatPopName,5600
;15 
 dc.l BoomName,11600
 dc.l HissName,7200
 dc.l Howl1Name,7400
 dc.l Howl2Name,9200
 dc.l PantName,5000
;20
 dc.l WhooshName,4000
 dc.l ShotGunName,8800
; dc.l 0,0
 dc.l FlameName,9000
 dc.l MuffledName,1800
 dc.l ClopName,3400
;25 
 dc.l ClankName,1600
 dc.l TeleportName,11000
 dc.l HALFWORMPAINNAME,8400
 dc.l -1
 
ScreamName:	dc.b 'AB3D2:sounds/scream',0
 even
ShootName:	dc.b 'AB3D2:sounds/fire!',0
 even
*
*
PooGunName:	dc.b 'AB3D2:sounds/shoot.dm',0
 even
CollectName:	dc.b 'AB3D2:sounds/collect',0
 even
DoorNoiseName:	dc.b 'AB3D2:sounds/newdoor',0
 even
BassName:	dc.b 'AB3D2:sounds/splash',0
 even
StompName:	dc.b 'AB3D2:sounds/footstep3',0
 even
LowScreamName:	dc.b 'AB3D2:sounds/lowscream',0
 even
BaddieGunName:	dc.b 'AB3D2:sounds/baddiegun',0
 even
SwitchNoiseName:dc.b 'AB3D2:sounds/switch',0
 even
ReloadName:	dc.b 'AB3D2:sounds/switch1.sfx',0
 even
NoAmmoName:	dc.b 'AB3D2:sounds/noammo',0
 even
SplotchName:	dc.b 'AB3D2:sounds/splotch',0
 even
SplatPopName:	dc.b 'AB3D2:sounds/splatpop',0
 even
BoomName:	dc.b 'AB3D2:sounds/boom',0
 even
HissName:	dc.b 'AB3D2:sounds/newhiss',0
 even
Howl1Name:	dc.b 'AB3D2:sounds/howl1',0
 even
Howl2Name:	dc.b 'AB3D2:sounds/howl2',0
 even
PantName:	dc.b 'AB3D2:sounds/pant',0
 even
WhooshName:	dc.b 'AB3D2:sounds/whoosh',0
 even
ShotGunName:	dc.b 'AB3D2:sounds/shotgun',0
 even
FlameName:	dc.b 'AB3D2:sounds/flame',0 
 even
MuffledName:	dc.b 'AB3D2:sounds/MuffledFoot',0
 even
ClopName:	dc.b 'AB3D2:sounds/footclop',0
 even
ClankName:	dc.b 'AB3D2:sounds/footclank',0
 even
TeleportName:	dc.b 'AB3D2:sounds/teleport',0
 even
HALFWORMPAINNAME: dc.b 'AB3D2:sounds/HALFWORMPAIN',0
 even
  
MunchName:	dc.b 'AB3D2:sounds/munch',0
 even
RoarName:	dc.b 'AB3D2:sounds/bigscream',0
 even
 
;-102
;7c
 
OBJNAME: ds.w 80
 
OBJ_NAMES:
 dc.l wad1n
 dc.l ptr1n
 
 dc.l wad2n
 dc.l ptr2n
 
; dc.l wad3n
; dc.l ptr3n
 
 dc.l wad4n
 dc.l ptr4n
 
 dc.l wad5n
 dc.l ptr5n
 
 dc.l wad6n
 dc.l ptr6n
 
 dc.l wad7n
 dc.l ptr7n
 
 dc.l wad8n
 dc.l ptr8n
 
 dc.l wad9n
 dc.l ptr9n
 
 dc.l wadan
 dc.l ptran
 
 dc.l wadbn
 dc.l ptrbn
 
 dc.l wadcn
 dc.l ptrcn
 
 dc.l waddn
 dc.l ptrdn

 dc.l waden
 dc.l ptren
 
 dc.l wadfn
 dc.l ptrfn

 dc.l wadgn
 dc.l ptrgn

 
 dc.l -1,-1
 
wad1n:
 dc.b 'AB3D1:includes/ALIEN2.wad',0
 even
ptr1n:
 dc.b 'AB3D1:includes/ALIEN2.ptr',0
 even
wad2n:
 dc.b 'AB3D1:includes/PICKUPS.wad',0
 even
ptr2n:
 dc.b 'AB3D1:includes/PICKUPS.ptr',0
 even
wad3n:
 dc.b 'AB3D1:includes/uglymonster.wad',0
 even
ptr3n:
 dc.b 'AB3D1:includes/uglymonster.ptr',0
 even
wad4n:
 dc.b 'AB3D1:includes/flyingalien.wad',0
 even
ptr4n:
 dc.b 'AB3D1:includes/flyingalien.ptr',0
 even
wad5n:
 dc.b 'AB3D1:includes/keys.wad',0
 even
ptr5n:
 dc.b 'AB3D1:includes/keys.ptr',0
 even
wad6n:
 dc.b 'AB3D1:includes/rockets.wad',0
 even
ptr6n:
 dc.b 'AB3D1:includes/rockets.ptr',0
 even
wad7n:
 dc.b 'AB3D1:includes/barrel.wad',0
 even
ptr7n:
 dc.b 'AB3D1:includes/barrel.ptr',0
 even
wad8n:
 dc.b 'AB3D1:includes/bigbullet.wad',0
 even
ptr8n:
 dc.b 'AB3D1:includes/bigbullet.ptr',0
 even
wad9n:
 dc.b 'AB3D1:includes/newgunsinhand.wad',0
 even
ptr9n:
 dc.b 'AB3D1:includes/newgunsinhand.ptr',0
 even
wadan:
 dc.b 'AB3D1:includes/newmarine.wad',0
 even
ptran:
 dc.b 'AB3D1:includes/newmarine.ptr',0
 even
wadbn:
 dc.b 'AB3D1:includes/lamps.wad',0
 even
ptrbn:
 dc.b 'AB3D1:includes/lamps.ptr',0
 even
wadcn:
 dc.b 'AB3D1:includes/worm.wad',0
 even
ptrcn:
 dc.b 'AB3D1:includes/worm.ptr',0
 even
waddn:
 dc.b 'AB3D1:includes/explosion.wad',0
 even
ptrdn:
 dc.b 'AB3D1:includes/explosion.ptr',0
 even
waden:
 dc.b 'AB3D1:includes/bigclaws.wad',0
 even
ptren:
 dc.b 'AB3D1:includes/bigclaws.ptr',0
 even
wadfn:
 dc.b 'AB3D1:includes/tree.wad',0
 even
ptrfn:
 dc.b 'AB3D1:includes/tree.ptr',0
 even
wadgn:
 dc.b 'AB3D1:includes/glare.wad',0
 even
ptrgn:
 dc.b 'AB3D1:includes/glare.ptr',0
 even
 
OBJ_ADDRS: ds.l 160
 
blocklen: dc.l 0
blockname: dc.l 0
blockstart: dc.l 0
 
BOTPICNAME: dc.b 'AB3:includes/panelraw',0
 even
PanelLen: dc.l 0
 
FREEBOTMEM:
 move.l Panel,d1
 move.l d1,a1
 move.l PanelLen,d0
 move.l 4.w,a6
 jsr -210(a6)

 rts
 
LOADBOTPIC:

 PRSDb

 move.l #BOTPICNAME,blockname

 move.l doslib,a6
 move.l blockname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,handle
 
 lea fib,a5
 move.l handle,d1
 move.l a5,d2
 jsr -390(a6)
 
 move.l $7c(a5),blocklen
 move.l #30720,PanelLen
 
 move.l #2,d1
 move.l 4.w,a6
 move.l PanelLen,d0
 jsr -198(a6)
 move.l d0,blockstart
; move.l doslib,a6
; move.l blockname,d1
; move.l #1005,d2
; jsr -30(a6)
 move.l doslib,a6
; move.l d0,handle

 move.l handle,d1
 move.l LEVELDATA,d2
 move.l blocklen,d3
 jsr -42(a6)
 move.l doslib,a6
 move.l handle,d1
 jsr -36(a6)
 
 move.l blockstart,Panel
 
 move.l LEVELDATA,d0
 moveq #0,d1
 move.l Panel,a0
 lea WorkSpace,a1
 lea $0,a2
 jsr unLHA

 rts
 
LOADOBS:

 PRSDG

 move.l #OBJ_ADDRS,a2
 move.l LINKFILE,a0
 lea ObjectGfxNames(a0),a0
 
 move.l #0,TYPEOFMEM
 
 move.l #Objects,a1
 
LOADMOREOBS:
 move.l a0,a4
 move.l #OBJNAME,a3
fillinname:
 move.b (a4)+,d0
 beq.s donename
 move.b d0,(a3)+
 bra.s fillinname

donename:

 move.l a0,-(a7)

 move.l a3,DOTPTR
 move.b #'.',(a3)+
 move.b #'W',(a3)+
 move.b #'A',(a3)+
 move.b #'D',(a3)+
 move.b #0,(a3)+

 move.l #OBJNAME,a0
 move.l a1,d0
 moveq #0,d1
 bsr QUEUEFILE
 
 move.l DOTPTR,a3
 move.b #'.',(a3)+
 move.b #'P',(a3)+
 move.b #'T',(a3)+
 move.b #'R',(a3)+
 move.b #0,(a3)+
 
 
 move.l #OBJNAME,a0
 move.l a1,d0
 add.l #4,d0
 moveq #0,d1
 bsr QUEUEFILE

 move.l DOTPTR,a3
 move.b #'.',(a3)+
 move.b #'2',(a3)+
 move.b #'5',(a3)+
 move.b #'6',(a3)+
 move.b #'P',(a3)+
 move.b #'A',(a3)+
 move.b #'L',(a3)+
 move.b #0,(a3)+

 move.l #OBJNAME,a0
 move.l a1,d0
 add.l #12,d0
 moveq #0,d1
 bsr QUEUEFILE
 
 move.l (a7)+,a0

 add.l #64,a0
 add.l #16,a1
 tst.b (a0)
 bne LOADMOREOBS

 move.l #POLYOBJECTS,a2
 move.l LINKFILE,a0
 add.l #VectorGfxNames,a0

LOADMOREVECTORS
 tst.b (a0)
 beq.s NOMOREVECTORS
 
 move.l a2,d0
 moveq #0,d1
 jsr QUEUEFILE
 addq #4,a2

 adda.w #64,a0
 bra.s LOADMOREVECTORS
 
NOMOREVECTORS:

 rts
 
DOTPTR: dc.l 0
 
LOAD_A_PALETTE
 movem.l d0-a7/a0-a6,-(a7)
 
 move.l #OBJNAME,blockname
 move.l doslib,a6
 move.l blockname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,handle
 
 move.l #2048,blocklen
 
 move.l #1,d1
 move.l 4.w,a6
 move.l blocklen,d0
 jsr -198(a6)
 move.l d0,blockstart
; move.l doslib,a6
; move.l blockname,d1
; move.l #1005,d2
; jsr -30(a6)
 move.l doslib,a6
; move.l d0,handle

 move.l handle,d1
 move.l blockstart,d2
 move.l blocklen,d3
 jsr -42(a6)
 move.l doslib,a6
 move.l handle,d1
 jsr -36(a6)

 movem.l (a7)+,d0-a7/a0-a6
 
 move.l blockstart,(a2)+
 move.l blocklen,(a2)+
 
 rts
 CNOP 0,4
fib: ds.l 75

LOAD_AN_OBJ:
 movem.l a0/a1/a2/a3/a4,-(a7)
 
 move.l #OBJNAME,blockname
 
 move.l doslib,a6
 move.l blockname,d1
 move.l #1005,d2
 jsr -30(a6)
 move.l d0,handle
 
 lea fib,a5
 move.l handle,d1
 move.l a5,d2
 jsr -390(a6)
 
 move.l $7c(a5),blocklen
 
 move.l #1,d1
 move.l 4.w,a6
 move.l blocklen,d0
 jsr -198(a6)
 move.l d0,blockstart
; move.l doslib,a6
; move.l blockname,d1
; move.l #1005,d2
; jsr -30(a6)
 move.l doslib,a6
; move.l d0,handle

 move.l handle,d1
 move.l blockstart,d2
 move.l blocklen,d3
 jsr -42(a6)
 move.l doslib,a6
 move.l handle,d1
 jsr -36(a6)

 movem.l (a7)+,a0/a1/a2/a3/a4
 
 move.l blockstart,(a2)+
 move.l blocklen,(a2)+

 rts
 
RELEASEOBJMEM:


 move.l #OBJ_NAMES,a0
 move.l #OBJ_ADDRS,a2

relobjlop
 move.l (a2)+,blockstart
 move.l (a2)+,blocklen
 addq #8,a0
 tst.l blockstart
 ble.s nomoreovj
 
 movem.l a0/a2,-(a7)
 
 move.l blockstart,d1
 move.l d1,a1
 move.l blocklen,d0
 move.l 4.w,a6
 jsr -210(a6)
 
 movem.l (a7)+,a0/a2
 bra.s relobjlop
 
nomoreovj:

 rts



TYPEOFMEM: dc.l 0
 
LOAD_SFX:

 move.l LINKFILE,a0
 lea SFXFilenames(a0),a0

 move.l #SampleList,a1
 
 
 move.w #58,d7
 
LOADSAMPS:
 tst.b (a0)
 bne.s oktoload

 add.w #64,a0
 addq #8,a1
 dbra d7,LOADSAMPS
 move.l #-1,(a1)+
 rts

oktoload:

 move.l #MEMF_CHIP,TYPEOFMEM
 move.l a1,d0
 move.l d0,d1
 add.l #4,d1
 jsr QUEUEFILE
 addq #8,a1
; move.l d0,(a1)+
; add.l d1,d0
; move.l d0,(a1)+
 adda.w #64,a0
 dbra d7,LOADSAMPS
 rts

PATCHSFX:

 move.w #58,d7
 move.l #SampleList,a1
.patch
 move.l (a1)+,d0
 add.l d0,(a1)+
 dbra d7,.patch

 rts

; PRSDJ
;
; move.l #SFX_NAMES,a0
; move.l #SampleList,a1
;LOADSAMPS
; move.l (a0)+,a2
; move.l a2,d0
; tst.l d0
; bgt.s oktoload
; blt.s doneload
;
; addq #4,a0
; addq #8,a1
; bra LOADSAMPS
;
;doneload:
; 
; move.l #-1,(a1)+
; rts
;oktoload:
; move.l (a0)+,blocklen
; move.l a2,blockname
; movem.l a0/a1,-(a7)
; move.l #2,d1
; move.l 4.w,a6
; move.l blocklen,d0
; jsr -198(a6)
; move.l d0,blockstart
; move.l doslib,a6
; move.l blockname,d1
; move.l #1005,d2
; jsr -30(a6)
; move.l doslib,a6
; move.l d0,handle
; move.l d0,d1
; move.l blockstart,d2
; move.l blocklen,d3
; jsr -42(a6)
; move.l doslib,a6
; move.l handle,d1
; jsr -36(a6)
; movem.l (a7)+,a0/a1
; move.l blockstart,d0
; move.l d0,(a1)+
; add.l blocklen,d0
; move.l d0,(a1)+
; bra LOADSAMPS
 
 
 
LOADFLOOR
; PRSDK
; move.l #65536,d0
; move.l #1,d1
; move.l 4.w,a6
; jsr -198(a6)
; move.l d0,floortile
;
; move.l #floortilename,d1
; move.l #1005,d2
; move.l doslib,a6
; jsr -30(a6)
; move.l doslib,a6
; move.l d0,handle
; move.l d0,d1
; move.l floortile,d2
; move.l #65536,d3
; jsr -42(a6)
; move.l doslib,a6
; move.l handle,d1
; jsr -36(a6)

 move.l LINKFILE,a0
 add.l #FloorTileFilename,a0
 move.l #floortile,d0
 move.l #0,d1
 jsr QUEUEFILE
; move.l d0,floortile
 
 move.l LINKFILE,a0
 add.l #TextureFilename,a0
 move.l #BUFFE,a1
 
.copy:
 move.b (a0)+,(a1)+
 beq.s .copied
 bra.s .copy
.copied:

 subq #1,a1
 move.l a1,dotty
 
 move.l #BUFFE,a0
 move.l #TextureMaps,d0
 move.l #0,d1
 jsr QUEUEFILE
; move.l d0,TextureMaps
 
 move.l dotty,a1
 move.l #".pal",(a1)

 move.l #BUFFE,a0
 move.l #TexturePal,d0
 move.l #0,d1
 jsr QUEUEFILE
; move.l d0,TexturePal
 
 rts

dotty: dc.l 0
BUFFE: ds.b 80

 
 
floortilename:
 ifeq CHEESEY
 dc.b 'AB3:includes/floortile'
 endc
 ifne CHEESEY
 dc.b 'AB3:includes/SMALLfloortile'
 endc
 dc.b 0
 
 even

RELEASESAMPMEM:
 move.l #SampleList,a0
.relmem:
 move.l (a0)+,d1
 bge.s .okrel
 rts
.okrel:
 move.l (a0)+,d0
 sub.l d1,d0
 move.l d1,a1
 move.l 4.w,a6
 move.l a0,-(a7)
 jsr -210(a6)
 move.l (a7)+,a0
 bra .relmem



RELEASELEVELMEM:

 move.l LINKS,d1
 move.l d1,a1
 move.l #10000,d0
 move.l 4.w,a6
 jsr -210(a6)


 move.l FLYLINKS,d1
 move.l d1,a1
 move.l #10000,d0
 move.l 4.w,a6
 jsr -210(a6)

 
 move.l LEVELGRAPHICS,d1
 move.l d1,a1
 move.l #40000,d0
 move.l 4.w,a6
 jsr -210(a6)
 
 move.l LEVELCLIPS,d1
 move.l d1,a1
 move.l #40000,d0
 move.l 4.w,a6
 jsr -210(a6)
 move.l LEVELMUSIC,d1
 move.l d1,a1
 move.l #70000,d0
 move.l 4.w,a6
 jsr -210(a6)
 rts
 
RELEASEFLOORMEM:

 move.l floortile,d1
 move.l d1,a1
 move.l #65536,d0
 move.l 4.w,a6
 jsr -210(a6)
 rts
 
COPSCR1: dc.l 0
COPSCN2: dc.l 0
 
RELEASESCRNMEM:

 rts 

unLHA:	incbin	"ab3:Decomp4.raw"


