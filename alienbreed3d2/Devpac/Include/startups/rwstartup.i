
*------ Conditional assembly flags
*------ ASTART:   1=Standard Globals Defined    0=Reentrant Only
*------ WINDOW:   1=AppWindow for WB startup    0=No AppWindow code
*------ XNIL:     1=Remove Rstartup NIL: init   0=Default Nil: WB Output
*------ NARGS:    1=Argv[0] only                0=Normal cmd line arg parse
*------ DEBUG:    1=Set up old statics for Wack 0=No extra statics
*------ QARG:     1=Do not provide argc,argv   0=Standard argc,argv

* Flags for  [A]start  AWstart  Rstart  RWstart  RXstart  QStart
* ASTART         1        1       0        0        0       0
* WINDOW         0        1       0        1        0       0
* XNIL           0        0       0        0        1       1
* NARGS          0        0       0        0        0       0
* DEBUG          0        0       0        0        0       0
* QARG           0        0       0        0        0       1

ASTART    SET   0
WINDOW    SET   1
XNIL      SET   0
NARGS     SET   0
DEBUG     SET   0
QARG      SET   0

