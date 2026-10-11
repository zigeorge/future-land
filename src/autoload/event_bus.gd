extends Node
## Global signal hub.
##
## Systems talk to each other by emitting and connecting to these signals
## instead of holding direct references. This keeps scenes independent, so
## teammates can work on different systems without breaking each other.
##
## Rule of thumb: if two unrelated systems need to communicate, add a signal
## here. If a node only talks to its own children, use a local signal instead.

@warning_ignore_start("unused_signal")

# --- Time ---------------------------------------------------------------
signal time_ticked(day: int, hour: int, minute: int)
signal day_started(day: int, season: int, year: int)

# --- Player / economy ---------------------------------------------------
signal avatar_changed(avatar_id: StringName)
signal money_changed(amount: int)
signal energy_changed(current: int, maximum: int)

# --- Inventory ----------------------------------------------------------
signal inventory_changed
signal hotbar_selection_changed(index: int)

# --- Farming ------------------------------------------------------------
signal farm_changed(cell: Vector2i)
signal crop_harvested(cell: Vector2i, crop_id: StringName)

# --- Dialogue / story ---------------------------------------------------
signal dialogue_started(dialogue_id: StringName)
signal dialogue_line_shown(speaker: String, text: String)
## Shown after the current line; answer with DialogueManager.choose(index).
signal dialogue_choices_shown(choices: Array[String])
signal dialogue_finished(dialogue_id: StringName)
signal story_flag_changed(flag: StringName, value: Variant)

# --- Game flow ----------------------------------------------------------
signal level_change_requested(level_path: String, spawn_point: StringName)
signal game_saved
signal game_loaded
## Short on-screen message shown by the HUD ("Too tired", "Game saved" ...).
signal notification_requested(text: String)

@warning_ignore_restore("unused_signal")
