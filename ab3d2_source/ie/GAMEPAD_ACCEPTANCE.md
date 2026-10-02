# AB3D2 IE gamepad acceptance

## Test environment

- Controller model: USB gamepad (`0810:e501`), two axes (`ABS_X`, `ABS_Y`)
- Host platform: Linux 7.1.3-1-default x86_64
- Source revision: `6a5fd41` plus the uncommitted gamepad worktree changes
- Binary: `ie/bin/ab3d2_ie68.ie68`
- Result: available controls passed; separate left/right-stick paths require a standard-layout pad

## Acceptance checklist

- [x] Start without a controller and confirm keyboard and relative-mouse control.
- [x] Connect the available controller; controller input remains active alongside keyboard and mouse.
- [x] Verify D-pad menu/gameplay movement and A to select.
- [ ] Verify separate left- and right-stick paths with a standard-layout controller.
- [x] Verify every action supported by the available controller during a level.
- [x] Hold use, duck, next weapon and pause; confirm one action per press.
- [x] Release and press each edge action again; confirm a second action.
- [x] Disconnect while holding movement and fire; confirm both stop.
- [x] Confirm captured relative-mouse control resumes after reconnecting.

Record the controller model and mark each item only after observing it on the
non-headless Intuition Engine build.
