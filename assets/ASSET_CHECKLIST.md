# Asset checklist

Art for the game, with its status. Paths are relative to `future-land/assets/`.

`[x]` = in the game. `[ ]` = still needed or needs a fix (the reason is given).

## Format rules (all images)

- **PNG with transparency.** Not JPG: it has no transparency and its compression blurs pixel art.
- **Draw at 1× size.** The game is 640×360 and scales itself up, so a 16×16 tile is 16×16 pixels in the file.
- **16×16 grid.** Tiles are 16×16, characters 16×32. Larger objects should be multiples of 16.
- **Hard pixel edges.** No anti-aliasing or soft brushes, and no semi-transparent edges except deliberate shadows.
- Leave the background transparent, not white.

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

### 1. Characters
- [x] **Player avatars:** `art/characters/player1.png`–`player4.png`, 80×128 sheets of 16×32 frames (columns: idle, walk 1–4). The player picks one at the start. See `data/avatars/`.
  - `player1`–`player3` were re-aligned so each frame sits in its 16×32 cell with the feet on the bottom row. Please draw future sheets that way.
  - [ ] `player1`: both side rows face **left**. The game mirrors one for now; a real right-facing row would be better.
  - [ ] `player3` (Nova): both side rows face **right**. The game mirrors one for now.
  - `player4`: rows are right, left, down, up (others are down, up, left, right). Fine, the avatar data handles it.
- [x] **Government Official:** `art/characters/government_official1.png`
- [x] **Village Chief:** `art/characters/village_chief.png`
- [x] **Merchant:** `art/characters/shopkeeper1.png` (2-frame idle)
- [x] **Inventor:** `art/characters/inventor.png`
- [ ] Not used yet: `banker.png`, `futuristic_chief.png`, `guide1.png`, `nova.png`, `woman_player4.png`

### 2. Ground and farming
- [ ] **Grass ground tile (most needed):** `art/tilesets/grass_ground.png`: seamless, fully opaque 16×16 grass tiles (3–4 variants). The ground is still a flat colour. *(`tilesets/environment/grass.png` and `bush.png` are tufts; they're used as decoration.)*
- [x] **Dirt path:** `art/tilesets/dirt_path.png`. Each tile has grass in its corners, so a wide path looks checkered; a variant without corners for the inside of paths would help.
- [x] **Water:** `art/tilesets/water.png` (pond on the farm).
- [ ] **Tilled soil, dry / watered:** `art/tilesets/soil_dry.png`, `soil_wet.png`. Currently a small blob in a mostly transparent tile; they need to fill the whole 16×16 tile.
- [ ] **Town paving:** `art/tilesets/town_paving.png`. Same problem: needs to fill the whole tile.
- [x] **Carrot stages:** `art/tilesets/crops/carrot.png` (64×16 strip: 3 growing stages + ripe).
- [ ] Not used yet (no such crops in the game): `onion.png`, `cabbage.png`, `broccoli.png`; weather `rainfall.png`, `snowfall.png`, `snow.png`.

### 3. Item icons (all 16×16)
- [x] `art/items/hoe.png`
- [x] `art/items/watering_can.png`
- [ ] `art/items/carrot_seeds.png` (a seed packet)
- [ ] `art/items/carrot.png`
- [ ] `art/items/axe2.jpeg`, `rock_hammer.jpeg`: need to be PNG with a transparent background. `axe1.png` and `chainsaw1.png` are fine and will be used when those tools exist.

### 4. Buildings and objects
- [x] `art/environment/house_farm.png`: player's farmhouse and the chief's house
- [x] `art/environment/house_shop.png`: merchant's shop
- [ ] **Chief's house** and **inventor's workshop** (design doc Map 03): the chief currently reuses the farmhouse, and the workshop is solar panels and a scarecrow.
- [ ] **Signpost:** `art/environment/sign.png`, about 16×16. Currently drawn with rectangles.
- [ ] `art/environment/bed.png`: not used yet (sleeping happens at the farmhouse door until there's an interior).

### 5. Interface
- [x] **Panel frame:** `art/ui/panel.png`, used by every box
- [x] **Hotbar slots:** `art/ui/hotbar_slot.png`, `hotbar_slot_selected.png`
- [ ] **Energy bar:** `energy_bar_frame.png` is fully semi-transparent and `energy_bar_fill.png` is a 2 px line. Needed: a frame and a fill about 10×80 px.
- [x] **Font:** `fonts/PixelifySans-Regular.ttf` (Press Start 2P and Silkscreen are also available)

### 6. Web page branding
- [x] **Loading screen:** `branding/boot_splash.png`
- [x] **Game icon:** `branding/icon.png`. It works, but at browser-tab size the detailed poster is hard to read; a simpler icon would be better.

### 7. Decoration
- [x] Trees: `tree_oak.png`, `tree_pine.png`, `tree_maple_<season>.png` (the maple changes with the season)
- [x] `fence.png`, `solar_panel.png`, `robot_scarecrow.png`
- [x] Grass tufts and bushes: `tilesets/environment/grass.png`, `bush.png`
- [ ] `rock_small.png`: the rock is only about 3 px; it should fill most of the 16×16 tile.
- [ ] For the next maps: beach (sand, wet sand, cliffs, pier, shells, driftwood), farmhouse interior, notice board, well.

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
Open `data/crops/<crop>.tres`. **Stage Textures** needs one texture per growth stage plus one for "ripe". For a strip image like `carrot.png`, each entry is an **AtlasTexture**: set its Atlas to the strip and its Region to the 16×16 square (x = 0, 16, 32, 48).

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
