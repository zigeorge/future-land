# Asset checklist

Art that replaces the current placeholders. Paths are relative to `future-land/assets/`. **Use exactly these file names**: the step-by-step guide below expects them.

Tick an item (`- [x]`) when its file is committed **and** hooked up in Godot.

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
| Godot resources made from an image: `<name>_frames.tres`, `<name>_tileset.tres` | `npc_guide_frames.tres` | |

## Checklist

### 1. Characters
- [ ] **Player:** `art/characters/player.png`, an 80×128 sprite sheet of 16×32 frames.
  Columns: idle, walk 1, walk 2, walk 3, walk 4. Rows: down, up, left, right. Feet touch the bottom of each frame.
- [ ] **Guide NPC:** `art/characters/npc_guide.png`, 16×32 (one front-facing frame), or 32×32 for a 2-frame idle.
- [ ] **Shopkeeper NPC:** `art/characters/npc_shopkeeper.png`, same as the Guide.

### 2. Ground and farming
- [ ] **Grass:** `art/tilesets/grass.png`, 16×16 tiles: 3–4 grass variants plus edges, any sheet size in multiples of 16 (e.g. 64×64).
- [ ] **Town paving:** `art/tilesets/town_paving.png`, 16×16 tiles.
- [ ] **Dirt path:** `art/tilesets/dirt_path.png`, 16×16 tiles. Leads to the map exits (right edge of the farm, left edge of town).
- [ ] **Tilled soil, dry:** `art/tilesets/soil_dry.png`, 16×16.
- [ ] **Tilled soil, watered:** `art/tilesets/soil_wet.png`, 16×16.
- [ ] **Carrot stages:** `art/crops/carrot_0.png`, `carrot_1.png`, `carrot_2.png` (growing) and `carrot_3.png` (ripe), each 16×16.

### 3. Item icons (all 16×16)
- [ ] `art/items/hoe.png`
- [ ] `art/items/watering_can.png`
- [ ] `art/items/carrot_seeds.png` (a seed packet)
- [ ] `art/items/carrot.png`

### 4. Objects
- [ ] **Bed:** `art/environment/bed.png`, 32×16 (seen from above).

### 5. Interface
- [ ] **Panel frame:** `art/ui/panel.png`, 24×24 with 8 px borders (the centre stretches). Used for the dialogue box and the clock/money box.
- [ ] **Hotbar slot:** `art/ui/hotbar_slot.png`, 26×26.
- [ ] **Hotbar slot, selected:** `art/ui/hotbar_slot_selected.png`, 26×26.
- [ ] **Energy bar frame:** `art/ui/energy_bar_frame.png`, 10×80.
- [ ] **Energy bar fill:** `art/ui/energy_bar_fill.png`, 10×80.
- [ ] **Pixel font:** `fonts/<font_name>.ttf` (or `.otf`), free for commercial use, with its license as `fonts/<font_name>_license.txt`.

### 6. Web page branding
- [ ] **Loading screen:** `branding/boot_splash.png`, 640×360 (or a logo on a transparent background).
- [ ] **Game icon:** `branding/icon.png`, 128×128. Used for the browser tab and the window.

### 7. Decoration (optional)
- [ ] `art/environment/tree_oak.png`: 32×48
- [ ] `art/environment/bush.png`: 16×16
- [ ] `art/environment/rock_small.png`: 16×16
- [ ] `art/environment/fence.png`: 16×16
- [ ] `art/environment/house_farm.png`: about 80×64 (farmhouse exterior)
- [ ] `art/environment/house_shop.png`: about 64×64 (shop exterior, in town)
- [ ] Futuristic props for the 2070 setting, e.g. `art/environment/solar_panel.png`, `art/environment/robot_scarecrow.png`

---

## How to add an asset

### Every asset
1. Create a branch, e.g. `art/player-sprites`.
2. Copy the file into its exact path above (inside `future-land/assets/`).
3. Switch to Godot. It imports the file automatically and creates a `.import` file next to it.
4. Hook it up using the matching step below.
5. Press **F5** and check that it looks right in the game.
6. Commit the PNG, its `.import` file, and any `.tscn` or `.tres` files Godot changed. Then open a pull request.

Pixel-art filtering (no blur) is already set for the whole project, so you don't need to change any import settings for images.

### Item icons
In the FileSystem dock, open `data/items/<id>.tres` (e.g. `hoe.tres`) and drag the PNG into the **Icon** property in the Inspector. The hotbar shows it automatically.

### Carrot stages
Open `data/crops/carrot.tres`. Set **Stage Textures** to size 4, then drag in `carrot_0.png` to `carrot_3.png` in order.

### Tilled soil
Open `src/world/farm/farm.tscn`, select **FarmGrid**, and drag `soil_dry.png` and `soil_wet.png` into **Dry Soil Texture** and **Wet Soil Texture**.

### Player
1. Open `src/entities/player/player.tscn` and select the **Sprite** node.
2. In the Inspector, set **Sprite Frames** to **New SpriteFrames**, then click it to open the SpriteFrames panel at the bottom.
3. Create these 8 animations: `idle_down`, `idle_up`, `idle_left`, `idle_right`, `walk_down`, `walk_up`, `walk_left`, `walk_right`.
4. For each animation, click **Add frames from sprite sheet** (the grid icon), choose `player.png`, and set **Horizontal 5, Vertical 4**. Then pick the frames:
   - `idle_<dir>`: column 1 of that direction's row
   - `walk_<dir>`: columns 2–5 of that row. Turn on loop and use about 8 FPS.
   - Rows, top to bottom: down, up, left, right.
5. Save. The blue placeholder hides itself once frames are set.

### NPCs (Guide, Shopkeeper)
1. In the FileSystem dock, right-click `art/characters/` → **New Resource** → **SpriteFrames** → save as `npc_guide_frames.tres`.
2. Double-click it, rename the `default` animation to `idle_down`, and add the frame(s) from `npc_guide.png`.
3. Open `src/world/farm/farm.tscn`, select **Guide**, and drag `npc_guide_frames.tres` into **Sprite Frames**.
4. Do the same for the Shopkeeper (`npc_shopkeeper_frames.tres` → **Shopkeeper** in `src/world/town/town.tscn`).

### Bed
Open `farm.tscn` and drag `bed.png` onto the **Entities → Bed** node. This creates a Sprite2D child; set its **Position** to `(0, 0)`. Then delete the Bed's **Placeholder** and **Label** nodes.

### Ground tiles (grass, paving, path)
1. In the FileSystem dock, right-click `art/tilesets/` → **New Resource** → **TileSet** → save as `world_tileset.tres`. Both maps will share it.
2. Open `farm.tscn`, add a **TileMapLayer** child to the root node, name it `GroundTiles`, and drag it directly below **Ground** in the scene tree. This draws it above the plain background and below everything else.
3. Set its **Tile Set** to `world_tileset.tres`.
4. In the **TileSet** panel at the bottom, click **+** → **Atlas** → pick `grass.png`, and answer **Yes** to create tiles automatically. Repeat for `town_paving.png` and `dirt_path.png`.
5. In the **TileMap** panel, paint the map. The farm is 50×30 tiles (800×480 px). Paint a path to the exit on the right edge.
6. Repeat steps 2, 3 and 5 for `town.tscn` (40×25 tiles, exit on the left edge).

### Panels (dialogue box, clock box)
1. Open `assets/themes/main_theme.tres`. The Theme editor opens at the bottom.
2. Click **+** (Add Type) → `PanelContainer`. On the **Styles** tab, set **panel** to **New StyleBoxTexture**.
3. Click the StyleBoxTexture, set **Texture** to `panel.png`, and set all four **Texture Margins** to `8`.

### Hotbar slots
Open `src/ui/hud/hud.tscn`, select the **HUD** root node, and drag the PNGs into **Slot Texture** and **Selected Slot Texture**.

### Energy bar
In `main_theme.tres`, add the type `ProgressBar`. Set the **background** style to a StyleBoxTexture with `energy_bar_frame.png` and the **fill** style to one with `energy_bar_fill.png`.

### Font
1. Select the font file in the FileSystem dock. On the **Import** tab, set **Antialiasing** to *None*, **Hinting** to *None* and **Subpixel Positioning** to *Disabled*, then click **Reimport**.
2. In `main_theme.tres`, set **Default Font** to the font and **Default Font Size** to the size the font was designed for (usually 8 or 16).
3. If some text ends up too small or too large, tell the programmer: a few labels have fixed sizes.

### Loading screen and icon
1. **Project → Project Settings → Application → Boot Splash:** set **Image** to `branding/boot_splash.png` and **Bg Color** to match it.
2. **Project → Project Settings → Application → Config:** set **Icon** to `branding/icon.png`.

The web build uses both, so they appear on the GitHub Pages loading screen.

### Decoration
- **Walk-around decoration (flowers, small rocks):** drag the PNG onto the level's **Entities** node, then move it into place.
- **Solid objects the player can't walk through (trees, houses, fences):**
  1. Add a **StaticBody2D** under **Entities**.
  2. Put a **Sprite2D** with the PNG inside it, with its **Offset** Y set to minus half the image height, so the bottom of the image sits on the node's position.
  3. Add a **CollisionShape2D** with a small rectangle covering only the base (e.g. the tree trunk), so the player can walk behind the top.

Always put objects under **Entities**. That node sorts by height, so the player correctly appears in front of or behind them.
