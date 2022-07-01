*****************************
* Bullet object definitions *
*****************************

shotxvel EQU 18
shotzvel EQU 22


shotpower EQU 28
shotstatus EQU 30
shotsize EQU 31

shotyvel EQU 42
accypos EQU 44
shotanim EQU 52
shotgrav EQU 54
shotimpact EQU 56
shotlife EQU 58
shotflags EQU 60
worry EQU 62
ObjInTop EQU 63

*****************************
* Nasty definitions *********
*****************************

numlives equ 18
damagetaken equ 19
maxspd equ 20
currspd equ 22
targheight equ 24

GraphicRoom equ 26
CurrCPt Equ 28

Facing equ 30
Lead equ 32
ObjTimer equ 34
EnemyFlags equ 36 ;(lw)
SecTimer equ 40
ImpactX equ 42
ImpactZ equ 44
ImpactY equ 46
objyvel EQU 48
TurnSpeed EQU 50
ThirdTimer EQU 52
FourthTimer EQU 54

*****************************
* Door Definitions **********
*****************************

DR_Plr_SPC EQU 0
DR_Plr EQU 1
DR_Bul EQU 2
DR_Alien EQU 3
DR_Timeout EQU 4
DR_Never EQU 5

DL_Timeout EQU 0
DL_Never EQU 1

*****************************
* Data Offset Defs **********
*****************************

ToZoneFloor		EQU 2
ToZoneRoof 		EQU 6
ToUpperFloor		EQU 10
ToUpperRoof 		EQU 14

ToZoneWater		EQU 18

ToZoneBrightness	EQU 22
ToUpperBrightness	EQU 24
ToZoneCpt		EQU 26
ToWallList		EQU 28
ToExitList 		EQU 32
ToZonePts		EQU 34
ToBack			EQU 36
ToTelZone		EQU 38
ToTelX			EQU 40
ToTelZ			EQU 42
ToFloorNoise		EQU 44
ToUpperFloorNoise	EQU 46
ToListOfGraph		EQU 48

*****************************
* Graphics definitions ******
*****************************

KeyGraph0 EQU 256*65536*19
KeyGraph1 EQU 256*65536*19+32
KeyGraph2 EQU (256*19+128)*65536
KeyGraph3 EQU (256*19+128)*65536+32
Nas1ClosedMouth EQU 256*5*65536
MediKit_Graph EQU 256*10*65536
BigGun_Graph EQU 256*10*65536+32

* Object numbers:
* 0 = alien
* 1 = medikit
* 2 = bullet
* 3 = BigGun
* 4 = Key
* 5 = Marine
* 6 = Robot