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

In priority order. Sizes are **file sizes** (already 8×). Keep the file names, so each new file replaces the current pixel-art version. Tick a box (`- [x]`) when the file is pushed.

Map tiles are the one exception: new files in `art/tilesets/` (ground, path, soil, paving, water, grass tufts, bushes) need a small switch in the maps, which the programmer does when they arrive. Everything else shows up in the game by itself.

### 1. Reference set (do this first)
- [ ] One character, one tree and one grass tile in the final anime style, so the team can agree on the look before the rest is drawn.

### 2. Portraits: 512×512, head and shoulders (`art/portraits/`)
Shown on the avatar selection screen and next to the speaker in conversations.
- [ ] Avatars: `avatar_1.png` (Farmer), `avatar_2.png` (Builder), `avatar_3.png` (Nova), `avatar_4.png` (Pilot)
- [ ] NPCs: `government_official.png`, `village_chief.png`, `merchant.png`, `technological_inventor.png` (the speaker's name from the dialogue sheet, lowercase with underscores)
- [ ] Later: a few expressions per NPC, e.g. `village_chief_happy.png`

### 3. Player characters: 640×1024 sheets (`art/characters/player1.png`–`player4.png`)
5 columns (idle, walk 1–4) × 4 rows of 128×256 frames.
- [ ] Rows in this order: facing down, up, left, right. Each direction drawn separately (currently `player1` has two left-facing rows and `player3` two right-facing ones).
- [ ] A real 4-frame walk: right foot forward, passing, left foot forward, passing. In the current sheets only one foot moves.
- [ ] Feet on the bottom edge of every frame, character centred.

### 4. Grass ground tile: 128×128, seamless (`art/tilesets/grass_ground.png`)
- [ ] 3–4 variants side by side (e.g. 512×128), fully opaque, tiling on all four sides. The ground is still a flat colour.

### 5. NPCs: 128×256 per idle frame, frames side by side (`art/characters/`)
- [ ] `government_official1.png`, `village_chief.png`, `shopkeeper1.png` (merchant), `inventor.png`
- Not used yet: `banker.png`, `futuristic_chief.png`, `guide1.png`, `nova.png`, `woman_player4.png`

### 6. Buildings: 640×512 (`art/environment/`)
- [ ] `house_chief.png`: larger traditional cottage, porch, flag or community emblem (design doc Map 03). Currently a recoloured farmhouse (`house_chief_placeholder.png`).
- [ ] `house_workshop.png`: workshop with metal roof, gears, pipes, solar panel prototype. Currently only solar panels.
- [ ] `house_farm.png`: the player's farmhouse, in the new style
- [ ] `house_shop.png`: the merchant's shop, 512×512, in the new style

### 7. Tiles: 128×128 (`art/tilesets/`)
- [ ] `dirt_path.png`, plus a version without grass in the corners for the inside of wide paths
- [ ] `soil_dry.png`, `soil_wet.png`: tilled soil filling the whole tile (currently a small blob)
- [ ] `town_paving.png`: filling the whole tile
- [ ] `water.png`: same layout as now (8 × 6 tiles = 1024×768)

### 8. Trees and props (`art/environment/`)
- [ ] Trees, 256×384: `tree_oak.png`, `tree_pine.png`, `tree_maple_spring.png` / `_summer` / `_fall` / `_winter`
- [ ] 128×128: `fence.png`, `rock_small.png` (filling most of the tile), `sign.png` (signpost)
- [ ] `solar_panel.png` 128×256, `robot_scarecrow.png` 128×192
- [ ] Grass tufts and bushes for decoration, 128×128 each: `tilesets/environment/grass.png`, `bush.png` (4 × 4 = 512×512)

### 9. Crops: strip of 4 stages, 512×128 (`art/tilesets/crops/`)
- [ ] `carrot.png` (3 growing stages + ripe)
- [ ] Later: `onion.png`, `cabbage.png`, `broccoli.png`

### 10. Item icons: 128×128 (`art/items/`)
- [ ] `hoe.png`, `watering_can.png`, `carrot_seeds.png` (seed packet), `carrot.png`
- [ ] `axe.png`, `chainsaw.png`, `rock_hammer.png` (as PNG; `axe2.jpeg` and `rock_hammer.jpeg` can't be used)

### 11. Interface (`art/ui/`)
- [ ] Energy bar: frame and fill (the current ones can't be used)
- [ ] Panel and hotbar slot frames in the new style (the current ones work for now)
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
