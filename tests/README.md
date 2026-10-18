# Testing

## Automated tests

Run these from the `future-land/` folder (the Godot project root):

```bash
godot --headless --import            # first time only (builds the class cache)
godot --headless -s tests/run_tests.gd
```

GitHub Actions also runs the tests on every push to the public mirror repo, [zigeorge/future-land](https://github.com/zigeorge/future-land/actions) (`.github/workflows/tests.yml`). It doesn't run in the team repo.

### Writing a test

Create `tests/test_<thing>.gd`:

```gdscript
extends TestCase

func test_something_specific() -> void:
	var inventory := Inventory.new(5)
	assert_eq(inventory.add_item(Registry.get_item(&"hoe")), 0)
	assert_true(inventory.count_item(&"hoe") == 1, "hoe was added")
```

Every method that starts with `test_` runs on a fresh object. The available assertions are `assert_eq`, `assert_true` and `assert_false`. Pure logic (`FarmState`, `Inventory`, `CropData`) is easiest to test. Autoloads are not loaded in this runner.

## Manual testing

Debug builds have shortcuts that make playtesting faster:

| Key | Effect |
|---|---|
| F5 / F9 | Quick save / quick load |
| F6 | Skip to the next day (crops grow, energy refills) |

### Smoke test checklist (run before merging into `main`)

- [ ] The title screen shows *New Game*, and *Continue* only when a save exists
- [ ] The avatar screen appears, all four looks can be picked (keys and mouse), and the game waits until one is chosen
- [ ] The chosen avatar walks correctly in all 4 directions (faces the way it moves, feet alternate), and can't leave the map or walk through houses, trees, fences or the pond
- [ ] The Government Official starts talking right away; the choice ("I need time to think.") works with E, Space and a mouse click, even after clicking elsewhere first; afterwards he is gone, "Start main quest" appears, and the HUD shows "365 days left" and "Buy back: 100,000 g"
- [ ] Game starts with a hoe, a watering can and 15 carrot seeds; hotbar selection works with 1–0 and the mouse wheel
- [ ] Hoe (C) tills any open grass on the farm, not paths, water or under objects; the white square shows where. Watering can waters (soil darkens), seeds plant (seed count goes down), energy goes down
- [ ] Reading the signpost by the farm shows the farming tips
- [ ] Sleeping at the farmhouse door advances the day, refills energy, lowers the days left, and watered crops grow (carrot art changes per stage)
- [ ] A crop is harvestable (E) after 3 watered days, and a carrot appears in the hotbar
- [ ] The path off the right edge of the farm leads to the village, and the left edge of the village returns to the farm
- [ ] Village Chief: full introduction the first time, a short line after that. Same for the Merchant
- [ ] On day 4 (F6 three times) the Inventor is on the farm and starts talking; after the deal he is at the workshop in the village
- [ ] Esc opens the pause menu; Save, then Quit to Title, then Continue restores money, inventory, farm, date, story progress, the avatar, the name, the map and the position
- [ ] NPCs show their names (Alexander, Arthur, Marcus, Ethan) and the player's lines show the typed name

## Reporting bugs

Open a GitHub issue using the **Bug report** template: steps to reproduce, expected result, actual result, and a screenshot or the Output panel log.
