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
| Interact (talk, read, sleep at the farmhouse door, harvest) | E / right mouse |
| Advance dialogue | E / Space / left mouse |
| Select hotbar slot | 1–0 / mouse wheel |
| Pause menu (save, load, quit to title) | Esc |
| Quick save / load | F5 / F9 |
| Skip to next day (debug builds only) | F6 |

**How a new game starts:** on the title screen choose *New Game* (or *Continue* a saved game), pick one of four looks and type your name, then a government official at your door explains that the city will take the land unless you buy it back within a year (365 in-game days, 100,000 g). Walk east to the village to meet the chief and the merchant. On day 4 the inventor visits your farm.

**Farming:** select the hoe (1), face any open grass on the farm (a white square shows where the tool will act) and till it with C, plant carrot seeds (3), water them (2), sleep at the farmhouse door, and repeat. After 3 watered days, press E to harvest. The signpost next to the farm has these tips too.

## Project layout

All paths below are inside `future-land/` (the Godot project root).

```
assets/        Art, audio, fonts, UI theme          (aesthetic manager)
data/          Game content: items, crops, dialogue (story lead + programmer)
docs/          Architecture and team workflow (team docs are in the repo-level docs/)
src/           All code and scenes                  (programmer)
  autoload/    Global singletons (EventBus, TimeManager, GameState, ...)
  core/        Shared classes: Registry, resource definitions
  components/  Reusable building blocks (Interactable, DialogueSpot, LevelWarp, Bed)
  entities/    Player, NPCs
  systems/     Gameplay logic (farming, inventory, dialogue)
  world/       Maps (farm, village) and props (trees, houses, ...)
  ui/          HUD, dialogue box, avatar selection
  main.tscn    Entry scene
tests/         Automated tests + test plan          (tester)
```

## Further reading

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): how the code fits together and how to add content
- [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md): git workflow, conventions, avoiding merge conflicts
- [assets/README.md](assets/README.md): art and audio specs
- [data/README.md](data/README.md): writing dialogue, adding items and crops
- [tests/README.md](tests/README.md): running tests and reporting bugs
