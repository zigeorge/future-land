# Asset checklist

Art for the game, with its status. Paths are relative to `future-land/assets/`.

`[x]` = in the game. `[ ]` = still needed or needs a fix (the reason is given).

## Art direction: HD anime 2D

Stardew Valley gameplay and camera (top-down, slightly from the front), with **clean anime-style art**: crisp line art, cel shading (2–3 flat tones per colour), bright readable colours, light coming from the top-left in every asset.

**Draw at 8× the world size.** The game works in a grid of 16 units per tile; art is delivered 8× bigger and the game scales it down smoothly, so it stays sharp on any screen. Every size in the checklist below is a *world* size: multiply by 8 for the file.

| Asset | World size | **File size (8×)** | Notes |
|---|---|---|---|
| Ground tile | 16×16 | **128×128** | Seamless on all four sides |
| Character frame | 16×32 | **128×256** | Sheet: 5 columns × 4 rows = **640×1024** |
| NPC idle strip | 16×32 per frame | **128×256** per frame | 1–4 frames side by side, e.g. 256×256 for 2 |
| Tree | 32×48 | **256×384** | |
| House / building | 80×64 | **640×512** | Shop: 64×64 → 512×512 |
| Fence, small prop | 16×16 | **128×128** | |
| Crop stages | 16×16 per stage | **128×128** per stage | Strip of 4: **512×128** |
| Item icon | 16×16 | **128×128** | |
| Portrait | — | **512×512** | Shown on the selection screen and in dialogue |

Rules for every file:
- **PNG with real transparency** (no white or checkerboard background), never JPG.
- **Exactly the file size in the table**, with the object filling its frame (feet on the bottom edge for characters, base on the bottom edge for trees and buildings).
- **Sharp at its own size.** Look at it at 100% zoom: line art should be crisp. Don't draw small and enlarge, or generate large and shrink until it blurs.
- **One consistent style** across all assets: same line thickness, shading, palette and light direction. Make one reference sheet (a character, a tree, a tile) first and match everything to it.

Current art is 1× pixel art. It keeps working, and each file can be replaced with its 8× version at any time: same name, same place. The game detects the bigger size by itself.

## Naming rules

| Rule | Good | Bad |
|---|---|---|
| lowercase `snake_case`, no spaces | `watering_can.png` | `Watering Can.png` |
| The name says *what* it is; the folder says *what kind* | `art/items/hoe.png` | `art/hoe_icon_item.png` |
| Item icon name = item id (`data/items/<id>.tres`) | `art/items/carrot_seeds.png` | `art/items/seeds.png` |
| Variants get a suffix | `soil_dry.png`, `soil_wet.png` | `soil2.png` |
| Frames and stages are numbered from 0 | `carrot_0.png` … `carrot_3.png` | `carrot_a.png` |
| NPCs start with `npc_` | `npc_guide.png` | `guide_sprite.png` |
| No versions or dates (git keeps history) | `bed.png` | `bed_final_v2.png` |
| Temporary art ends in `_placeholder` | `tree_oak_placeholder.png` | |
| Source files sit next to the PNG with the same name | `player.aseprite` | |
| Godot resources made from an image: `<name>_frames.tres`, `<name>_tileset.tres` | `world_tileset.tres` | |

## Checklist

In priority order. Sizes are **file sizes** (already 8×). `[x]` = in the game. Keep the file names, so each new file replaces the old one.

Map tiles (ground, path, soil, paving, water, tufts, bushes) live in one tileset, `art/tilesets/world_tileset.tres`; a new tile image needs a small change there, which the programmer does. Everything else shows up in the game by itself.

### 1. Reference set
- [x] Character, tree and grass tile approved: anime style, sharp at 8×.

### 2. Portraits: 512×512, head and shoulders (`art/portraits/`)
Shown on the avatar selection screen and next to the speaker in conversations.
- [x] Players: `player1.png`–`player4.png` (same names as the player sheets)
- [x] NPCs: `government_official.png`, `village_chief.png`, `merchant.png`, `technological_inventor.png`, `banker.png`, `guide1.png`
- [x] Expressions, 6 per character (neutral, happy, sad, angry, tired, surprised), 3072×512 strips in `art/portraits/expressions/` (ready; the dialogue will use them once the sheet says which face each line has)
- [ ] Fisherman (Jack): sprite and portrait

### 3. Player characters: `art/characters/player1.png`–`player4.png`
- [x] In the game. Nir's sheets (3 rows: down, up, side, with grid lines) are converted with `tools/pack_character_sheet.py` (repo root) into the game format: 640×1024, 5 columns × 4 rows of 128×256 frames, same scale, feet on one line, side view mirrored for the other direction. To update a character, run e.g. `python3 tools/pack_character_sheet.py new_player1.png future-land/assets/art/characters/player1.png`.

### 4. Grass ground tile (`art/tilesets/environment/grass_ground.png`)
- [x] In the game: covers both maps (4 variants mixed).
- [ ] Small fix: each tile is darker along its left and right edges, so faint vertical stripes show across the ground. The edges should be as bright as the middle.
- [ ] Optional: one set per season.

### 5. NPCs: 128×256 per idle frame (`art/characters/`)
- [x] `government_official.png`, `village_chief.png`, `merchant.png`, `technological_inventor.png`
- [x] `banker.png`, `guide1.png` (not placed in a map yet)
- [ ] Optional: a 2–4 frame idle animation (frames side by side)

### 6. Buildings: 640×512 (`art/environment/`)
- [x] `house_farm.png` (the player's farmhouse), `house_chief.png`, `house_shop.png` (512×512), `house_workshop.png`
- [x] `house_farm_2.png` (variant, not used yet)

### 7. Tiles: 128×128 (`art/tilesets/environment/`)
- [x] `dirt_path.png` (3×3 set)
- [x] `water.png`; `water_grass.png` and `water_grass_corner.png` give the pond a grass shore (rotated for every side)
- [ ] A plain water tile in the same deep blue as the shore tiles (the pond's middle uses the closest tiles from `water.png`, which are a little lighter and wavier)
- [x] `pond.png`: generated from `water_grass(_corner).png` (plain water, every edge and corner) so the whole pond uses one water texture
- [ ] 4 inside-corner tiles for paths and the shore (grass in just one corner, with a curved bank); until then the pond has to stay rectangular
- [x] `soil_dry.png`, `soil_wet.png` (in `tilesets/environment/`): currently made from the dirt path's centre tile with furrows, so tilled fields join seamlessly. Nir may replace them with drawn versions (128×128, seamless on all sides, wet = darker).
- [x] Stored for later: `dirt_path_grass(_corner).png`, `paved_path_grass(_corner).png`; a plain paving centre tile is still needed for paved areas

### 8. Trees and props (`art/environment/`)
- [x] Trees: `tree_oak.png`, `tree_oak_2.png`, `tree_pine.png`, `tree_maple_spring.png` / `_summer` / `_fall` / `_winter`. (Small fix for later: the bases end 15–25 px above the bottom edge, so trees float slightly.)
- [x] `fence.png`, `rock_small.png`, `sign.png`, `solar_panel.png`, `robot_scarecrow.png`
- [x] Decoration: `tilesets/environment/grass_tufts.png`, `bushes.png`

### 9. Crops: strip of 4 stages, 512×128 (`art/tilesets/crops/`)
- [x] `carrot.png` (in the game)
- [x] `broccoli.png`, `cabbage.png`, `garlic.png`, `onion.png`, `potato.png` (ready for when these crops are added)

### 10. Item icons: 128×128 (`art/items/`)
- [x] `hoe.png`, `watering_can.png` (in the hotbar)
- [x] `axe.png`, `chainsaw.png`, `pick_axe.png`, `pitchfork.png`, `rake.png`, `rock_hammer.png`, `scythe.png`, `sickle.png` (for upcoming tools)
- [ ] `carrot_seeds.png` (seed packet) and `carrot.png` (the harvested carrot); the hotbar shows their names as text until then

### 11. Interface (`art/ui/`)
- [x] Energy bar: `energy_bar.png` (frame) and `energy_bar_fill.png`; the game draws the level inside the frame
- [x] Hotbar: `hotbar_frame.png`, `hotbar_frame_selected.png`
- [ ] Dialogue box and panel frame in the same blue sci-fi style (the current ones are brown wood)
- [ ] Simpler game icon `branding/icon.png` (the poster is hard to read at browser-tab size)

### 12. Later
- [ ] Beach (Map 02): sand, wet sand, cliffs, pier, shells, driftwood
- [ ] Farmhouse interior (`bed.png` is waiting for it), notice board, well
- [ ] Weather effects: rain, snow (`rainfall.png`, `snowfall.png`, `snow.png` exist as pixel art)

---

## How to add an asset

### Every asset
1. Create a branch, e.g. `art/player-sprites`.
2. Copy the file into its folder inside `future-land/assets/`, following the naming rules.
3. Switch to Godot. It imports the file automatically and creates a `.import` file next to it.
4. Hook it up using the matching step below.
5. Press **F5** and check that it looks right in the game.
6. Commit the PNG, its `.import` file, and any `.tscn` or `.tres` files Godot changed. Then open a pull request.

Pixel-art filtering (no blur) is already set for the whole project, so you don't need to change any import settings for images.

### Item icons
Open `data/items/<id>.tres` (e.g. `carrot_seeds.tres`) and drag the PNG into the **Icon** property in the Inspector. The hotbar shows it automatically.

### Crop stages
Replacing a strip like `carrot.png` with a bigger version needs nothing else: the game splits it into equal squares. For a new crop, open `data/crops/<crop>.tres` and drag the strip into **Stage Strip**.

### Tilled soil
Open `src/world/farm/farm.tscn`, select **FarmGrid**, and drag the PNGs into **Dry Soil Texture** and **Wet Soil Texture**.

### Player avatars
Replace the sheet in `assets/art/characters/` (same name, same 80×128 layout). If the rows are in a different order, open `data/avatars/avatar_<n>.tres` and set **Row Down/Up/Left/Right**; use **Mirror Left/Right** if a sheet has only one side-facing row. To add a fifth look, duplicate an avatar `.tres` and add its id to `Registry.AVATAR_IDS` (ask the programmer).

### NPCs
Select the NPC in the level (e.g. **Merchant** in `src/world/village/village.tscn`) and drag the PNG into **Sprite → Sprite Texture**. It should be a horizontal strip of 16×32 frames, which play as an idle animation.

### Ground tiles and decoration
Both maps share `assets/art/tilesets/world_tileset.tres`.
1. Open the map, select the **GroundTiles** (paths, water) or **Decor** (tufts, bushes) layer.
2. To add a new tile image: in the **TileSet** panel at the bottom, click **+** → **Atlas**, pick the PNG, and answer **Yes** to create tiles automatically.
3. Paint in the **TileMap** panel.

For the grass ground: paint it on a new TileMapLayer named `GrassTiles`, placed directly below **Ground** in the scene tree, then the flat **Ground** colour can be hidden.

### Panels, energy bar and font
These are in `assets/themes/main_theme.tres` (open it to get the Theme editor at the bottom):
- **Panels:** `PanelContainer` → Styles → panel is a StyleBoxTexture using `panel.png` with 5 px texture margins.
- **Energy bar:** add the type `ProgressBar` and set the **background** and **fill** styles to StyleBoxTextures with the new images.
- **Font:** **Default Font** and **Default Font Size**.

### Hotbar slots
Open `src/ui/hud/hud.tscn`, select the **HUD** root node, and drag the PNGs into **Slot Texture** and **Selected Slot Texture**.

### Loading screen and icon
**Project → Project Settings → Application → Boot Splash → Image**, and **Application → Config → Icon**. The web build uses both.

### Buildings, trees and other props
Ready-made scenes are in `src/world/props/`. Drag one under a map's **Entities** node, which sorts by height so the player appears in front of or behind it. To make a new one, duplicate a similar prop scene (e.g. `house_shop.tscn`), change the **Sprite2D** texture, and resize the **CollisionShape2D** to cover only the base.
