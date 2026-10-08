# Assets

Everything players see or hear goes here. Code never needs to change for you to replace a placeholder. Swap the texture or stream in the Inspector.

**Graphics to-do list, file names and step-by-step setup: [ASSET_CHECKLIST.md](ASSET_CHECKLIST.md).**

## Folders

```
art/characters/   player & NPC sprite sheets
art/tilesets/     ground, paths, buildings (16×16 tiles)
art/items/        inventory icons (16×16)
art/crops/        crop growth stages (16×16)
art/environment/  trees, rocks, buildings, furniture, props
art/ui/           panels, buttons, hotbar frames
audio/music/      background music loops
audio/sfx/        sound effects
fonts/            pixel fonts (+ license)
branding/         loading screen, game icon
themes/           main_theme.tres (UI look, applied project-wide)
```

## Specs

| Thing | Spec |
|---|---|
| Tile size | **16×16 px** |
| Character frame | 16×32 px (feet at the bottom centre) |
| Item icon | 16×16 px |
| Game resolution | 640×360, scaled up with nearest-neighbour, so draw at 1× |
| Image format | PNG (source files like `.aseprite` can be committed too) |
| Music | `.ogg`, looping enabled in the Import dock |
| Sound effects | `.wav` (short) or `.ogg` |
| Naming | `snake_case`, e.g. `player.png`, `carrot_2.png`, `hoe_swing.wav`. Full rules in [ASSET_CHECKLIST.md](ASSET_CHECKLIST.md#naming-rules) |

## Hooking assets up

- **Graphics:** see [How to add an asset](ASSET_CHECKLIST.md#how-to-add-an-asset).
- **Music:** set the `music` property on a level's root node (e.g. `farm.tscn`).
- **Audio buses:** `audio/default_bus_layout.tres` has `Music` and `SFX` buses for the volume sliders.

Commit the `.import` file that Godot creates next to each asset.
