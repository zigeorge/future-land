# Future Land

A farming and life-sim game in the spirit of *Stardew Valley*, built with **Godot 4.7** and **GDScript** for the MS course *Advanced Game Design*.

## Team

| Role | Owns |
|---|---|
| Lead & story teller | Story, characters, dialogue (`data/dialogue/`), game direction |
| Programmer | Code and architecture (`src/`) |
| Aesthetic manager | Graphics, audio, UI look (`assets/`) |
| Tester | Test plans, bug reports, automated tests (`tests/`) |

Ownership means "reviews changes to", not "only person allowed to touch". See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

## Getting started

1. Install **Godot 4.7.2 (standard, not .NET)** from <https://godotengine.org/download>. Everyone must use the same minor version.
2. Clone the repo, open Godot, choose **Import** and select `future-land/project.godot`.
3. Press **F5** to run.

### Play in the browser

**Play it: https://zigeorge.github.io/future-land/**

Development happens in the team repo (`hzyu-hub/Advance-Game`). The `future-land/` folder is also mirrored to a separate public repo, [zigeorge/future-land](https://github.com/zigeorge/future-land), where GitHub Actions runs the tests and publishes the web build to GitHub Pages on every push to `main`. The workflows are in `future-land/.github/workflows/`. They only run in the mirror (GitHub ignores workflows outside the repo root), so they use none of the team repo's Actions minutes. **Don't commit directly to the mirror**: it is overwritten from the team repo.

To test a web build locally: **Project → Export → Web → Export Project** into `build/web/` at the repo root (git ignores that folder), then run `python3 -m http.server -d build/web` and open <http://localhost:8000>. Opening `index.html` directly from disk does not work.

The web build is single-threaded (`export_presets.cfg`), because GitHub Pages can't send the special headers Godot's multi-threaded build needs. Saves are stored in the browser.

### Controls

| Action | Keys |
|---|---|
| Move | WASD / arrow keys |
| Use selected tool or seed | C / left mouse |
| Interact (talk, sleep, harvest) | E / right mouse |
| Advance dialogue | E / Space / left mouse |
| Select hotbar slot | 1–0 / mouse wheel |
| Quick save / load | F5 / F9 |
| Skip to next day (debug builds only) | F6 |

Try this: select the hoe (1), till a tile with C, plant carrot seeds (3), water them (2), sleep in the bed, and repeat. After 3 watered days, press E to harvest.

## Project layout

All paths below are inside `future-land/` (the Godot project root).

```
assets/        Art, audio, fonts, UI theme          (aesthetic manager)
data/          Game content: items, crops, dialogue (story lead + programmer)
docs/          Architecture and team workflow (team docs are in the repo-level docs/)
src/           All code and scenes                  (programmer)
  autoload/    Global singletons (EventBus, TimeManager, GameState, ...)
  core/        Shared classes: Registry, resource definitions
  components/  Reusable building blocks (Interactable, LevelWarp, Bed)
  entities/    Player, NPCs
  systems/     Gameplay logic (farming, inventory)
  world/       Levels / maps (farm, town)
  ui/          HUD, dialogue box, menus
  main.tscn    Entry scene
tests/         Automated tests + test plan          (tester)
```

## Further reading

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): how the code fits together and how to add content
- [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md): git workflow, conventions, avoiding merge conflicts
- [assets/README.md](assets/README.md): art and audio specs
- [data/README.md](data/README.md): writing dialogue, adding items and crops
- [tests/README.md](tests/README.md): running tests and reporting bugs
