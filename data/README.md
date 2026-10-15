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
| Player_Choice | Makes the line a question. For several answers, separate them with ` / ` and list the same number of ids in Next_ID, also separated by ` / `. |
| Next_ID | The line that follows. `END` ends the conversation. |
| Quest_Flag | A story flag set when the line is shown, e.g. `main_quest_started`. |
| Effect | `some_flag = true` sets a flag. Any other text is shown to the player as a notification, e.g. "Start main quest: Save the Land". |
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

## Avatars (`avatars/*.tres`)

The four looks offered on the start screen, in the order of `Registry.AVATAR_IDS`. Each points at an 80×128 sheet in `assets/art/characters/` and says which sheet row holds each direction. If a sheet has only one side-facing row, `mirror_left` or `mirror_right` reuses it flipped. Rename them by changing `display_name`.

`auto_walk_cycle` (on by default) rebuilds the walk because the current sheets' walk frames don't alternate feet: front and back views alternate the step frame with its mirror image, and side views alternate the widest stride with the idle pose. Turn it off for a sheet that has a real 4-frame walk cycle.

## Portraits

Put a PNG in `assets/art/portraits/` named like the player's sprite sheet (`player1.png` for `characters/player1.png`) or like a speaker in the dialogue sheet (`Village Chief` → `village_chief.png`). The selection screen and dialogue box use it automatically; player lines ("You") use the chosen avatar's portrait.

## Items (`items/*.tres`) and crops (`crops/*.tres`)

Create these in the Godot editor: right-click the folder → **New Resource** → `ItemData` / `CropData`. The file name **must** match the `id` field. Step-by-step instructions are in [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md#how-to).

A crop's art is either `stage_strip` (one image with every stage as a square, side by side, at any resolution, as `carrot.tres` does with `assets/art/tilesets/crops/carrot.png`) or a list of `stage_textures`.
