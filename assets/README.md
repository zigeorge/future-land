# Assets

Everything players see or hear goes here. Code never needs to change for you to replace a placeholder. Swap the texture or stream in the Inspector.

## Folders

```
art/characters/   player & NPC sprite sheets
art/tilesets/     ground, paths, buildings (16×16 tiles)
art/items/        inventory icons (16×16)
art/environment/  trees, rocks, props, crops
art/ui/           panels, buttons, hotbar frames
audio/music/      background music loops
audio/sfx/        sound effects
fonts/            pixel fonts
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
| Naming | `snake_case`, e.g. `player_walk.png`, `carrot_stage_2.png`, `hoe_swing.wav` |

## Hooking art up

- **Player / NPCs:** select the `Sprite` (AnimatedSprite2D) node in `player.tscn` or `npc.tscn`, create a SpriteFrames, and add animations named `idle_down`, `idle_up`, `idle_left`, `idle_right`, `walk_down`, `walk_up`, `walk_left` and `walk_right`. Then delete the coloured `Placeholder` node.
- **Item icons:** open `data/items/<item>.tres` and set `icon`.
- **Crops:** open `data/crops/<crop>.tres` and fill `stage_textures`, one per growth stage plus a final "ready" texture.
- **UI:** edit `themes/main_theme.tres` (fonts, panel styles, colours). It applies to every menu.
- **Music:** set the `music` property on a level's root node (e.g. `farm.tscn`).
- **Audio buses:** `audio/default_bus_layout.tres` has `Music` and `SFX` buses for the volume sliders.

Commit the `.import` file that Godot creates next to each asset.
