# pushy

A [norns](https://monome.org/docs/norns/) library for using an **Ableton Push 1** as a
control + display surface. It mirrors a script's `params` onto the Push's segment LCD and
drives them from the Push's encoders, so you can browse and edit parameters off-device.

The Push 1 talks MIDI/SysEx; pushy connects to it over norns MIDI, renders sliders and text
to the four LCD rows, and routes the top-row encoders (CC 71–79) and the two small encoders
(CC 14–15) to parameter edits.

## Layout

| Path | What |
|------|------|
| `pushy.lua` | example script — sets up demo params, then starts the library |
| `lib/pushyINC.lua` | the library itself; `include("lib/pushyINC")` and call `.init()` |
| `setupDemoParams.lua` | demo params for the example (adapted from the [monome params docs](https://monome.org/docs/norns/reference/params#example)) |

## Install

Clone into the norns scripts directory (on the norns device, or via the device's web/SSH access):

```sh
git clone https://github.com/ericmoderbacher/pushy.git ~/dust/code/pushy
```

Connect the Push 1 and make sure norns sees it as MIDI ports 1 (out) and 2 (in).

## Use

Run `pushy` from the norns SELECT menu to see the example, or pull the library into your own
script:

```lua
local pushyLib = include("lib/pushyINC")

function init()
  -- add all of your params first
  pushyLib.init()
end
```

`pushyLib.init()` expects every parameter to be added before it is called.

## Controls

- **Top encoders (CC 71–79)** — edit the on-screen slider.
- **Small encoders (CC 14–15)** — step through the parameter list.
- **K2 / K3** — clear the screen / draw the full character set (display test).

## Status

Hardware-targeted; runs on a norns + Push 1 (there is no host build or test harness).
Early/experimental — a single slider and text fields are wired up as a proof of concept.
