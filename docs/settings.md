## Settings file

The C builds of the game persist user settings in a plaintext format that can be edited by the user in any suitable text editor. This file is saved on clean exit with whatever persistable settings the user has configured during their session.

The file is a simple list of key/values. End of line comments are supported for reading but as the current version overwrites the file, these are not especially helpful for now.

The default configuration at the time of writing looks like this:

```
key.turn_left              LEFT
key.turn_right             RIGHT
key.forwards               W
key.backwards              S
key.fire                   CTRL
key.use                    F
key.run                    LSHIFT
key.side_step              LALT
key.step_left              A
key.step_right             D
key.duck                   C
key.look_behind            L
key.jump                   SPACE
key.look_up                =
key.look_down              _
key.centre_look            ;
key.next_weapon            \
vid.contrast.aga           256
vid.contrast.rtg           256
vid.brightness.aga         0
vid.brightness.rtg         0
vid.gamma.aga              0
vid.gamma.rtg              0
vid.fullscreen             true
vid.pixel1x2               false
vid.vert_margin            0
vid.frame_skip             0
vid.prefer_akiko           false
vid.akiko_mirror           false
vid.akiko_030_fix          false
gfx.simple_walls           false
gfx.reduced_quality        false
gfx.disable_dynamic_lights false
misc.show_fps              true
misc.original_mouse        false
misc.always_run            false
misc.disable_auto_aim      false
misc.crosshair_colour      0
misc.disable_messages      false
misc.show_weapon_model     false
misc.oz_sensitivity        4
misc.edge_pvs_fov          1800
map.transparent            false
map.zoom                   3
```

### Notes

- All setting names and values are case sensitive
- Boolean settings accept `true` for true, all other values will be interpreted as `false` 
- vid.fullscreen will be set to false initially if starting on an 020 or 030 machine.


### Keyboard

Valid names for key bindings are:

- Printable characters: A-Z ` _ = \ ; , . /
- SPACE
- BSPC (Backspace)
- ENT  (Enter)
- CTRL
- CAPS (Caps Lock)
- LSHIFT
- RSHIFT
- LALR
- RALT (currently the same as LALT)
- LAMIGA
- RAMIGA
- DEL
- HELP
- UP
- DOWN
- LEFT
- RIGHT
- L? (Left unmarked key on UK keyboard)
- R? (Right unmarked key on UK keyboard)

### Advanced options

The following options can only be set by editing the file manually. Of these only the Akiko settings should be modified 

- vid.prefer_akiko
    - Boolean.
    - When enabled, Akiko is preferred over CPU if the device is detected on 020/030 systems.

- vid.akiko_mirror
    - Boolean.
    - When enabled, mirror registers are used for Akiko write and read. This may help address issues with C2P on some systems.

- vid.akiko_030_fix
    - Boolean.
    - When enabled, attempts to disable the Write Allocation of the 68030 DataCache (if a 68030 is detected) during conversion. This may help address issues with C2P on some 68030 systems. This option is considered risky as it disables interrupts for the duration of C2P.

- misc.oz_sensitivity
    - Integer.
    - Defines how sensitive the engine is to changes of player position when evaluating the order in which the visible parts of the map should be drawn.
    - Higher values may improve peformance at the expense of occasional geometry glitches.

- misc.edge_pvs_fov
    - Sets the field of view used in early culling of zones in the PVS.
    - Units are 2048 per right angle.
    - Value should be even.
