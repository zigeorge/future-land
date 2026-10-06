# Testing

## Automated tests

Run these from the `future-land/` folder (the Godot project root):

```bash
godot --headless --import            # first time only (builds the class cache)
godot --headless -s tests/run_tests.gd
```

GitHub Actions also runs the tests on every push and pull request (`.github/workflows/tests.yml`).

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

- [ ] Game starts on the farm with a hoe, a watering can and 15 carrot seeds
- [ ] Movement works in all 4 directions, and the player can't leave the map
- [ ] Hotbar selection works with 1–0 and the mouse wheel
- [ ] Hoe tills, watering can waters, seeds plant (seed count goes down), energy goes down
- [ ] Talking to the Guide shows all lines, and the player can't move during dialogue
- [ ] Sleeping in the bed advances the day, refills energy, and watered crops grow
- [ ] A crop is harvestable (E) after 3 watered days, and a carrot appears in the hotbar
- [ ] Walking off the right edge goes to town, and the left edge of town returns to the farm
- [ ] F5 then F9 restores money, inventory, farm and date

## Reporting bugs

Open a GitHub issue using the **Bug report** template: steps to reproduce, expected result, actual result, and a screenshot or the Output panel log.
