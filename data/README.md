# Game data

Content lives here as data files, so most content can be added without writing code.

```
avatars/    the player looks offered at the start (AvatarData)
crops/      crop definitions (CropData)
dialogue/   conversations (JSON)
items/      item definitions (ItemData)
```

## Dialogue (`dialogue/*.json`)

### Story conversations come from the spreadsheet

The story conversations are written in **`docs/Future_Land_NPC_Dialogue.xlsx`** (repo root, sheet "Dialogue") and converted into game files:

```bash
python3 tools/dialogue_from_xlsx.py     # run from the repo root
```

This writes one file per value of the sheet's **Scene** column: "Land Requisition Notice" becomes `land_requisition_notice.json`. Files it generates say so in their `generated_from` field. **Don't edit those by hand**: change the spreadsheet and run the script again. It prints a `WARNING` for problems such as a repeated Dialogue_ID or a Next_ID that doesn't exist.

How the spreadsheet columns are used:

| Column | In the game |
|---|---|
| Dialogue_ID | Line id. Must be unique. |
| Speaker | Name shown above the line. `Player` is shown as "You". |
| Dialogue_Text | The line. |
| Player_Choice | The text on an answer button. A **choice menu** is a row whose Next_ID lists several ids separated by ` / `; each button shows the Player_Choice of the row it leads to (Animal Crossing style: answers that lead back to the menu let the player ask more questions). |
| Next_ID | The line that follows. `END` ends the conversation. |
| Quest_Flag | A story flag set when the line is shown, e.g. `main_quest_started`. |
| Effect | Parts separated by `;`: `set some_flag = true` sets a flag; `Open Merchant shop` (or Inventor / Fisherman) opens that shop when the conversation ends; text starting with "Start" or "Unlock" is shown to the player (e.g. "Start main quest: Save the Land"). Anything else is kept as a `todo` for the programmer and listed when the script runs. |
| Relationship_Change | Friendship points with the NPC_Name. |
| Scene, NPC_Name, Condition, Notes | For people. *When* a conversation plays is set on the NPC in Godot (see below). |

### Short hand-written conversations

For a sign or a single repeat line, write a list:

```json
{
  "lines": [
    { "speaker": "Merchant", "text": "My door is open." },
    { "speaker": "", "text": "Narration has an empty speaker.", "set_flag": "read_sign" }
  ]
}
```

Current hand-written files: `chief_repeat`, `merchant_repeat`, `inventor_repeat` (lines reused from the spreadsheet) and `farming_tips` (the signpost on the farm).

### Graph format (what the converter writes)

```json
{
  "start": "GOV_001",
  "nodes": {
    "GOV_001": { "speaker": "Government Official", "text": "...", "next": "GOV_002", "set_flag": "land_notice_received" },
    "GOV_006": { "speaker": "Government Official", "text": "...", "choices": [ { "text": "I need time to think.", "next": "PLAYER_001" } ] },
    "PLAYER_END_001": { "speaker": "{player}", "text": "...", "next": "END", "notify": "Start main quest: Save the Land" }
  }
}
```

Node fields: `speaker`, `text`, `next`, `choices`, `set_flag`, `relationship` (`{"Village Chief": 1}`), `notify`. The tests check every file: no links to missing lines, and every conversation can reach its end.

### When NPCs say what

Each NPC in a level has these Inspector properties:

| Property | Meaning |
|---|---|
| `dialogue_id` | First conversation. |
| `done_flag` | Flag that marks the first conversation as done (the conversation sets it). |
| `repeat_dialogue_id` | What the NPC says after that. |
| `auto_talk` | Starts the first conversation without the player pressing E. |
| `appear_from_day` | The NPC isn't there before this day (day 1 = Spring 1, Year 1). |
| `requires_flag` / `hidden_by_flag` | The NPC is only there while a flag is set, or until it is. |

The current story setup:

| NPC | Where | Conversation | Appears |
|---|---|---|---|
| Government Official | Farm, at the door | `land_requisition_notice` (auto) | Day 1, until `main_quest_started` |
| Village Chief | Village square | `village_introduction`, then `chief_repeat` | Always |
| Merchant | In front of the shop | `merchant_introduction`, then `merchant_repeat` | Always |
| Inventor | Farm, on the path | `inventor_visit` (auto) | From day 4, until `inventor_deal_accepted` |
| Inventor | Village workshop | `inventor_repeat` | After `inventor_deal_accepted` |

## Goals (`objectives.json`) and the opening (`dialogue/opening.json`)

`objectives.json` is the list of goals shown at the top left, in order: the first goal whose `done_flag` isn't set yet is shown, and a yellow arrow next to the player points to its `target` (an NPC role or a node name) in its `map`, or to the exit leading there. Flags come from the dialogue sheet (Quest_Flag / Effect) or from the game (`first_crop_planted`, `first_sleep`, `opening_seen`). Add, remove or reorder goals freely.

`dialogue/opening.json` is the short story shown when a new game starts. It's a placeholder written from `docs/Game story.docx`; the story lead can rewrite it.

## NPC names (`npcs.json`)

The names players see for each NPC role: `"Village Chief": "Arthur"`. The dialogue sheet keeps using roles in its Speaker and NPC_Name columns; the game shows the names above the NPCs and in the dialogue box. Portraits stay named by role (`village_chief.png`). Dialogue text can use `{player}` (the name the player typed), `{buyback_price}` and `{days_remaining}`.

## Avatars (`avatars/*.tres`)

The four looks offered on the start screen, in the order of `Registry.AVATAR_IDS`. Each points at an 80×128 sheet in `assets/art/characters/` and says which sheet row holds each direction. If a sheet has only one side-facing row, `mirror_left` or `mirror_right` reuses it flipped. Rename them by changing `display_name`.

`auto_walk_cycle` (on by default) rebuilds the walk because the current sheets' walk frames don't alternate feet: front and back views alternate the step frame with its mirror image, and side views alternate the widest stride with the idle pose. Turn it off for a sheet that has a real 4-frame walk cycle.

## Portraits

Put a PNG in `assets/art/portraits/` named like the player's sprite sheet (`player1.png` for `characters/player1.png`) or like a speaker in the dialogue sheet (`Village Chief` → `village_chief.png`). The selection screen and dialogue box use it automatically; player lines ("You") use the chosen avatar's portrait.

## Items (`items/*.tres`), crops (`crops/*.tres`) and shops (`shops.json`)

These are generated from **`docs/Future_Land_Item_List.xlsx`** (repo root):

```bash
python3 tools/items_from_xlsx.py     # run from the repo root
```

Every tool, seed and fish row becomes an item. Each seed also creates its crop (`data/crops/<crop>.tres`, growth days split over 3 stages, seasons) and the harvested crop item (sold for the row's Sell Price; the seed itself sells for half its Buy Price). `shops.json` lists what the Merchant, Inventor and Fisherman sell (the Location column). Ids come from names: "Carrot Seeds" → `carrot_seeds`, its crop → `carrot`. Art is picked up by the same names: `assets/art/items/<id>.png` for icons and `assets/art/tilesets/crops/<crop>.png` for crop stages, so a new icon only needs the right file name (then run the script again). **Don't edit the generated files by hand**; change the spreadsheet and rerun.

A crop's art is either `stage_strip` (one image with every stage as a square, side by side, at any resolution, as `carrot.tres` does with `assets/art/tilesets/crops/carrot.png`) or a list of `stage_textures`.
