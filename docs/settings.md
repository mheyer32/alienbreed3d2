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
gfx.simple_walls           false
gfx.reduced_quality        false
gfx.disable_dynamic_lights false
misc.original_mouse        false
misc.always_run            false
misc.disable_auto_aim      false
misc.crosshair_colour      0
misc.disable_messages      false
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

