# Contributing

## Git workflow

- `main` must always open and run without errors.
- Do work on a branch: `feature/farming-sprinklers`, `art/player-sprites`, `story/chapter-1`, `fix/hotbar-crash`.
- Open a pull request into `main` and ask one teammate to review it. The tester checks gameplay changes.
- Pull often (`git pull origin main`). Small, frequent PRs cause fewer conflicts than big ones.
- Write commit messages in the imperative: "Add carrot sprites", "Fix crash when inventory is full".

## Avoiding merge conflicts in Godot

`.tscn` and `.tres` files are text, but merging them by hand is painful.

1. **Only one person edits a given scene at a time.** Say so in the group chat before editing a shared scene (`farm.tscn`, `main.tscn`, `hud.tscn`).
2. **Prefer small scenes.** Build things as their own scenes and instance them, rather than adding many nodes to a level.
3. **Commit the `.import` and `.uid` files** that Godot creates next to assets and scripts. They are needed.
4. **Never commit `.godot/`.** It is a local cache and is already in `.gitignore`.
5. **If a scene conflicts,** don't hand-merge it. Keep one version (`git checkout --theirs` / `--ours`) and redo the other change in the editor.

## Who works where

| Folder | Main owner | Others may… |
|---|---|---|
| `src/` | Programmer | tweak exported values in the Inspector; ask before changing scripts |
| `assets/` | Aesthetic manager | add placeholders (mark them `_placeholder`) |
| `data/dialogue/` | Story lead | fix typos |
| `data/items/`, `data/crops/` | Programmer + story lead | add content following [ARCHITECTURE.md](ARCHITECTURE.md) |
| `tests/` | Tester | anyone can add tests |
| `docs/` | Everyone | keep it up to date |

## GDScript style

Follow the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). In summary:

- **Files and folders:** `snake_case` (`farm_grid.gd`, `player.tscn`)
- **Classes and nodes:** `PascalCase` (`class_name FarmGrid`, node `InteractArea`)
- **Functions and variables:** `snake_case`; private ones start with `_` (`_update_hotbar`)
- **Constants and enum values:** `CONSTANT_CASE`
- **Signals:** past tense (`crop_harvested`, `day_started`)
- Indent with **tabs**.
- Use **static typing** everywhere it's practical (`var speed := 90.0`, `func get_item(id: StringName) -> ItemData`).
- Start each script with a `##` doc comment that says what it is for.
- Put a scene and its script side by side (`player.tscn` + `player.gd`).
- Reach nodes that the aesthetic manager may move around through `%UniqueName`, not long `$Path/To/Node` paths.
- Order of a script: `class_name`, `extends`, doc comment, signals, enums, constants, `@export` vars, vars, `@onready` vars, `_ready`/`_process`, public functions, private functions.

## Definition of done for a feature

- [ ] Runs without errors or warnings in the Output panel
- [ ] `godot --headless -s tests/run_tests.gd` (run inside `future-land/`) passes (the mirror repo's CI also runs it on every push)
- [ ] New logic in `systems/` or `core/` has a test, where practical
- [ ] Docs updated if you added a system, autoload, input action or folder
