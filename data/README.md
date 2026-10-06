# Game data

Content lives here as data files, so most content can be added without writing code.

## Dialogue (`dialogue/*.json`)

Each conversation is one JSON file. The **file name is the dialogue id**, which an NPC uses in its `dialogue_id` property.

```json
{
  "lines": [
    { "speaker": "Guide", "text": "Welcome to Future Land!" },
    { "speaker": "", "text": "Narration has an empty speaker." },
    { "speaker": "Guide", "text": "See you around.", "set_flag": "met_guide" }
  ]
}
```

| Field | Required | Meaning |
|---|---|---|
| `speaker` | no | Name shown above the text |
| `text` | yes | The line |
| `set_flag` | no | Marks a story event as done when this line is shown (e.g. `met_guide`). Code can check it with `GameState.has_story_flag(&"met_guide")` |

Tips:
- Keep lines under about 120 characters so they fit the box.
- Check your JSON with any JSON validator. A missing comma breaks the whole file, and Godot's Output panel will show the error.
- Planned: choices, conditions on flags, and per-day greetings. Tell the programmer what you need.

## Items (`items/*.tres`) and crops (`crops/*.tres`)

Create these in the Godot editor: right-click the folder → **New Resource** → `ItemData` / `CropData`. The file name **must** match the `id` field. Step-by-step instructions are in [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md#how-to).
