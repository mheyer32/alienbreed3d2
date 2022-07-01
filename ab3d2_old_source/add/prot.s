Protection details:

Main program is called, and asks to
know how much memory is available
from the system. It stores this
someplace. Basically need a random
number to be generated somehow.

Lots of bullshit setup routines that
faff around with areas of memory and
don't do anything at all really.
Include lots of checksums for
unimportant bits of code. BUT put in
the odd instruction which decodes the
cache routine also

Decode cache routine from other part
of memory completely.

Set up null pointers etc for cache
code, and call it. Freeze cache and
erase all data again. REPLACE jump
to cache which has been removed.

Bugger off somewhere faffing about and
setting things up for the game.
Could do whole intro sequence at this
point! Generally wait for ages and do
loads of things (maybe generate
random number for something else to
use as well) before calling 
cache routine (jmp rather
than jsr).

NEED TO PASS:

Erase parent jump replacing with
something innocuous.

decode and move code calc routine.

Code calc routine called, returning
code,row,col,table in d0-d3.

Returns to code running in cache,
which stores values (encoded) in
bits of memory. Calls the 'enter
code' routine with row,col,table.

After code has been entered, returns
to code running in cache which
reloads the values from memory,
decodes and compares them. If
correct it sets up the hidden memory
locations with the correct values
derived from the random number
generated above. Otherwise it just
exits (jmp rather than rts).