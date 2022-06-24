TITLEPAL:
 incbin "titlescrnpal"

titlecop:
 dc.w intreq,$8010

 dc.w $10c,$0088

 dc.w $1fc,$f
 dc.w diwstart,$2c81    ; Top left corner of screen.
 dc.w diwstop,$2cc1     ; Bottom right corner of screen.
 dc.w ddfstart,$38      ; Data fetch start.
 dc.w ddfstop,$b8       ; Data fetch stop.

 dc.w bplcon0
titleplanes: dc.w $7201
 dc.w bplcon1
 dc.w $0
 
 dc.w $106,$c40

 dc.w spr0ptl
tsp0l:
 dc.w 0
 dc.w spr0pth
tsp0h:
 dc.w 0
 dc.w spr1ptl
tsp1l:
 dc.w 0
 dc.w spr1pth
tsp1h:
 dc.w 0
 dc.w spr2ptl
tsp2l:
 dc.w 0
 dc.w spr2pth
tsp2h:
 dc.w 0
 dc.w spr3ptl
tsp3l:
 dc.w 0
 dc.w spr3pth
tsp3h:
 dc.w 0
 dc.w spr4ptl
tsp4l:
 dc.w 0
 dc.w spr4pth
tsp4h:
 dc.w 0
 dc.w spr5ptl
tsp5l:
 dc.w 0
 dc.w spr5pth
tsp5h:
 dc.w 0
 dc.w spr6ptl
tsp6l:
 dc.w 0
 dc.w spr6pth
tsp6h:
 dc.w 0
 dc.w spr7ptl
tsp7l:
 dc.w 0
 dc.w spr7pth
tsp7h:
 dc.w 0

 dc.w $106,$c40
 
TITLEPALCOP:
val SET $180
 REPT 32
 dc.w val,0
val SET val+2
 ENDR 
 
 dc.w $106,$2c40
val SET $180
 REPT 32
 dc.w val,0
val SET val+2
 ENDR
 
 dc.w $106,$4c40
val SET $180
 REPT 32
 dc.w val,0
val SET val+2
 ENDR 
 
 dc.w $106,$6c40
val SET $180
 REPT 32
 dc.w val,0
val SET val+2
 ENDR

val SET $180
 dc.w $106,$e40
 REPT 32
 dc.w val,0
val SET val+2
 ENDR 
 
 dc.w $106,$2e40
val SET $180
 REPT 32
 dc.w val,0
val SET val+2
 ENDR
 
 dc.w $106,$4e40
val SET $180
 REPT 32
 dc.w val,0
val SET val+2
 ENDR 
 
 dc.w $106,$6e40
val SET $180
 REPT 32
 dc.w val,0
val SET val+2
 ENDR

 
 dc.w $106,$8c40
OPTSCRNCOP:
val SET $180
 REPT 8
 dc.w val,$fff
val SET val+2
 dc.w val,$fff
val SET val+2
 dc.w val,$500
val SET val+2
 dc.w val,$fff
val SET val+2

 ENDR 
 dc.w $106,$ac40
val SET $180
 REPT 32
 dc.w val,$fff
val SET val+2
 ENDR

 dc.w $108,0
 dc.w $10a,0

 dc.w bpl1ptl
ts1l:
 dc.w 0
 dc.w bpl1pth
ts1h:
 dc.w 0

 dc.w bpl2ptl
ts2l:
 dc.w 0
 dc.w bpl2pth
ts2h:
 dc.w 0
 
 dc.w bpl3ptl
ts3l:
 dc.w 0
 dc.w bpl3pth
ts3h:
 dc.w 0
 
 dc.w bpl4ptl
ts4l:
 dc.w 0
 dc.w bpl4pth
ts4h:
 dc.w 0
 
 dc.w bpl5ptl
ts5l:
 dc.w 0
 dc.w bpl5pth
ts5h:
 dc.w 0

 dc.w bpl6ptl
ts6l:
 dc.w 0
 dc.w bpl6pth
ts6h:
 dc.w 0

 dc.w bpl7ptl
ts7l:
 dc.w 0
 dc.w bpl7pth
ts7h:
 dc.w 0
 
 dc.w $106,$8c40
 
OPTCOP:
 
val SET $2c
 REPT 32
 dc.b val,$01,$ff,$00
 dc.w col1,$f00
 dc.w col5,$f00
 dc.w col9,$f00
 dc.w col13,$f00
 
 dc.w col3,$448
 dc.w col7,$448
 dc.w col11,$448
 dc.w col13+4,$448
 
 dc.w col2,$200
 dc.w col6,$200
 dc.w col10,$200
 dc.w col13+2,$200
 
 dc.b val,$df,$ff,$fe
val SET val+1
val SET val&255

 dc.b val,$01,$ff,$00
 dc.w col1,$f00
 dc.w col5,$f00
 dc.w col9,$f00
 dc.w col13,$f00
 
 dc.w col3,$77a
 dc.w col7,$77a
 dc.w col11,$77a
 dc.w col13+4,$77a

 dc.w col2,$400
 dc.w col6,$400
 dc.w col10,$400
 dc.w col13+2,$400

 
 dc.b val,$df,$ff,$fe
val SET val+1
val SET val&255

 dc.b val,$01,$ff,$00
 dc.w col1,$f00
 dc.w col5,$f00
 dc.w col9,$f00
 dc.w col13,$f00

 dc.w col3,$aac
 dc.w col7,$aac
 dc.w col11,$aac
 dc.w col13+4,$aac
 
 dc.w col2,$600
 dc.w col6,$600
 dc.w col10,$600
 dc.w col13+2,$600


 dc.b val,$df,$ff,$fe
val SET val+1
val SET val&255

 dc.b val,$01,$ff,$00
 dc.w col1,$f00
 dc.w col5,$f00
 dc.w col9,$f00
 dc.w col13,$f00

 dc.w col3,$ccf
 dc.w col7,$ccf
 dc.w col11,$ccf
 dc.w col13+4,$ccf

 dc.w col2,$800
 dc.w col6,$800
 dc.w col10,$800
 dc.w col13+2,$800
 
  dc.b val,$df,$ff,$fe
val SET val+1
val SET val&255

 dc.b val,$01,$ff,$00
 dc.w col1,$f00
 dc.w col5,$f00
 dc.w col9,$f00
 dc.w col13,$f00

 dc.w col3,$ccf
 dc.w col7,$ccf
 dc.w col11,$ccf
 dc.w col13+4,$ccf
 
  dc.w col2,$800
 dc.w col6,$800
 dc.w col10,$800
 dc.w col13+2,$800

 
 dc.b val,$df,$ff,$fe
val SET val+1
val SET val&255

 dc.b val,$01,$ff,$00
 dc.w col1,$f00
 dc.w col5,$f00
 dc.w col9,$f00
 dc.w col13,$f00
 
 dc.w col3,$aac
 dc.w col7,$aac
 dc.w col11,$aac
 dc.w col13+4,$aac
 
  dc.w col2,$600
 dc.w col6,$600
 dc.w col10,$600
 dc.w col13+2,$600


 dc.b val,$df,$ff,$fe
val SET val+1
val SET val&255

 dc.b val,$01,$ff,$00
 dc.w col1,$f00
 dc.w col5,$f00
 dc.w col9,$f00
 dc.w col13,$f00

 dc.w col2,$400
 dc.w col6,$400
 dc.w col10,$400
 dc.w col13+2,$400


 dc.w col3,$77a
 dc.w col7,$77a
 dc.w col11,$77a
 dc.w col13+4,$77a

 dc.b val,$df,$ff,$fe
val SET val+1
val SET val&255

 dc.b val,$01,$ff,$00
 dc.w col1,$f00
 dc.w col5,$f00
 dc.w col9,$f00
 dc.w col13,$f00

 dc.w col3,$448
 dc.w col7,$448
 dc.w col11,$448
 dc.w col13+4,$448

 dc.w col2,$200
 dc.w col6,$200
 dc.w col10,$200
 dc.w col13+2,$200

 dc.b val,$df,$ff,$fe
val SET val+1
val SET val&255

 ENDR

 dc.w $ffff,$fffe