# Sound effects

From Nir's `audio.zip` (tools/ and effects/), prepared with:

```bash
python3 tools/prepare_sfx.py PATH/TO/audio     # run from the repo root
```

The script cuts each tool recording to one use, evens out the loudness and
writes the files here. Don't edit them by hand; rerun the script on new
recordings.

- `tools/<item id>.wav`: played when that tool is used (found by item id, like
  item icons, so a new tool only needs a file with the right name).
- `ui/`: `click` (any button), `hover` (button focus), `select` (hotbar),
  `confirm` (buy, sell, ship), `error` (an action that failed), `pickup`
  (harvest, catch, beach finds), `cancel` (not used yet).
