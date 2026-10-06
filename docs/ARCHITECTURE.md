# Architecture

## Goals

1. **Teammates work in parallel.** Art, story and testing should not depend on code changes, and code changes should not break each other.
2. **Data-driven content.** Items, crops and dialogue are data files, so adding content doesn't need a programmer.
3. **Small, decoupled systems.** Systems communicate through signals, not direct references.

## Overview

```mermaid
flowchart TD
    subgraph Autoloads["Autoloads (global, always alive)"]
        EB[EventBus<br/>signals]
        TM[TimeManager<br/>clock & calendar]
        GS[GameState<br/>money, energy, inventory,<br/>farm, story flags]
        DM[DialogueManager]
        AM[AudioManager]
        SM[SaveManager]
    end

    subgraph Main["main.tscn"]
        W[World] --> L[Current Level<br/>farm.tscn / town.tscn]
        UI[UI layer] --> HUD
        UI --> DB[DialogueBox]
    end

    L --> P[Player]
    L --> N[NPCs]
    L --> FG[FarmGrid]

    P -- uses item --> FG
    FG -- reads/writes --> GS
    N -- start --> DM
    DM -- dialogue signals --> EB
    GS -- changes --> EB
    TM -- time signals --> EB
    EB --> HUD
    EB --> DB
    SM -- save/load --> GS
    SM -- save/load --> TM
    Data[(data/*.tres, *.json)] --> GS
    Data --> DM
```

## Key ideas

### 1. State lives in autoloads, scenes are views

`GameState` holds everything that must survive a level change or be saved: money, energy, inventory, the farm's soil and crops (`FarmState`), and story flags. Level scenes only **display** that state and turn player input into calls on it.

Example: when you leave the farm, the `FarmGrid` node is destroyed but the crops stay in `GameState.farm`. They keep growing overnight even if you are in town.

### 2. EventBus for cross-system communication

`src/autoload/event_bus.gd` declares the global signals. The HUD doesn't know about the farm; it listens to `EventBus.money_changed`, `EventBus.inventory_changed` and similar signals.

- Emit: `EventBus.crop_harvested.emit(cell, crop_id)`
- Listen: `EventBus.day_started.connect(_on_day_started)`

Use EventBus only between *unrelated* systems. Inside a scene, use normal signals and node references.

### 3. Main scene + swappable levels

`main.tscn` is always loaded. It contains `World` (holds the current level) and the `UI` canvas layer (HUD and dialogue box). A level change is a request: `EventBus.level_change_requested.emit(path, spawn)`. `main.gd` fades out, swaps the level, places the player at the spawn point, and fades back in.

### 4. Content by id

Each item or crop is a `.tres` resource whose **file name is its id** (`data/items/hoe.tres` → `&"hoe"`). `Registry.get_item(&"hoe")` loads it. Saves and dialogue refer to content by id.

## Autoloads

| Name | Responsibility |
|---|---|
| `EventBus` | Global signals only, no logic |
| `TimeManager` | 10-minute ticks, days, seasons, years; `start_next_day()` |
| `GameState` | Money, energy, inventory, farm, story flags; new game setup |
| `DialogueManager` | Loads `data/dialogue/<id>.json`, steps through lines, sets story flags |
| `AudioManager` | `play_music()` with crossfade, `play_sfx()`, bus volumes |
| `SaveManager` | JSON save in `user://savegame.json`; calls `get_save_data()` / `load_save_data()` on saved systems |

Order matters: `EventBus` must stay first because the others use it in `_ready()`.

## Day cycle

```
06:00 day starts ── time ticks every 7 real seconds (+10 min) ── 02:00 pass out
                                                                     │
            Bed.interact() ──► TimeManager.start_next_day() ◄────────┘
                                   │ emits day_started
                                   ▼
                     GameState: restore energy, farm.advance_day(season)
                                   │  (watered crops grow, soil dries,
                                   ▼   out-of-season crops die)
                              SaveManager.save_game()  (when sleeping)
```

## How to…

### Add an item
1. In the FileSystem dock, right-click `data/items/` → **New Resource** → `ItemData`.
2. Save as `<id>.tres` and set `id` to the same name.
3. Fill in name, icon, category, price. For tools set `tool_type`; for seeds set `crop_id`.

### Add a crop
1. Create a `CropData` resource in `data/crops/<id>.tres`.
2. Set `days_per_stage`, `harvest_item`, `seasons`, and (once art exists) `stage_textures`. Use one texture per stage plus one for "ready".
3. Create a seed item with `category = SEED` and `crop_id = <id>`.

### Add an NPC
Instance `src/entities/npcs/npc.tscn` under a level's `Entities` node and set `npc_name` and `dialogue_id`.

### Add a level
1. Duplicate `src/world/town/town.tscn` (it uses `level.gd`).
2. Keep the `Entities/Player`, `SpawnPoints/` and `Bounds` nodes. Set `bounds` to the map size.
3. Connect it to another level with a `LevelWarp` (set `target_level` and `target_spawn`).

### Add something interactable (sign, chest, shop counter…)
Add an `Area2D` with `interactable.gd` and a `CollisionShape2D`, then connect its `interacted` signal. You can also extend `Interactable` and override `interact()`, as `bed.gd` does.

### Save a new system
Give it `get_save_data() -> Dictionary` and `load_save_data(data: Dictionary)`, then add it to `_saved_systems()` in `save_manager.gd`.

## Physics layers

| # | Name | Used by |
|---|---|---|
| 1 | world | walls, map bounds, obstacles |
| 2 | player | Player body (LevelWarps detect it) |
| 3 | npc | NPC bodies |
| 4 | interactable | `Interactable` areas (Player's InteractArea detects them) |

## Display

The base resolution is 640×360, upscaled to the window (1280×720 by default) with the `canvas_items` stretch mode, nearest-neighbour filtering and pixel snapping, which suits pixel art. The tile size is **16×16**.

## Placeholders to replace

| Placeholder | Where | Replace with |
|---|---|---|
| Coloured rectangles for player/NPCs | `Placeholder` node in `player.tscn`, `npc.tscn` | `SpriteFrames` on the `Sprite` node (see `player.gd` header for animation names) |
| Solid-colour ground | `Ground` node in each level | `TileMapLayer`(s) with the tileset |
| Soil and crop circles | `FarmGrid._draw()` | crop `stage_textures` (automatic); soil tiles later |
| Text in hotbar slots | `hud.gd` | item `icon` textures (automatic) |

## Planned next systems

Inventory screen, shop and selling, NPC schedules and friendship, tool upgrades, weather, pause and settings menu, main menu with multiple save slots.
