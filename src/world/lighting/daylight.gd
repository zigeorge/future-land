class_name Daylight
extends CanvasModulate
## Tints the map by the time of day: sunrise, daylight, sunset, dusk and
## night. The sun rises later and sets earlier in winter. The HUD and menus
## are on their own layers, so they keep their colours.
## Also switches SeasonLook when the season changes.

const NIGHT := Color(0.32, 0.36, 0.6)
const DAWN := Color(0.86, 0.76, 0.82)
const DAY := Color.WHITE
const SUNSET := Color(1.0, 0.8, 0.62)
const DUSK := Color(0.62, 0.52, 0.74)
## Sunrise and sunset per season, in minutes after midnight.
const SUN_TIMES: Array[Vector2i] = [
	Vector2i(6 * 60, 19 * 60 + 30),       # spring
	Vector2i(5 * 60 + 30, 20 * 60 + 30),  # summer
	Vector2i(6 * 60 + 30, 18 * 60 + 30),  # autumn
	Vector2i(6 * 60 + 45, 17 * 60 + 30),  # winter
]

var _season := -1


## The map's tint at `minutes` after midnight (may go past 24 * 60).
static func color_at(minutes: float, season: int) -> Color:
	var sunrise := SUN_TIMES[season].x
	var sunset := SUN_TIMES[season].y
	var keys := [
		[sunrise - 60, NIGHT], [sunrise, DAWN], [sunrise + 60, DAY],
		[sunset - 90, DAY], [sunset, SUNSET], [sunset + 45, DUSK], [sunset + 120, NIGHT],
	]
	if minutes <= keys[0][0] or minutes >= keys[-1][0]:
		return NIGHT
	for i in range(1, keys.size()):
		if minutes <= keys[i][0]:
			var t := inverse_lerp(keys[i - 1][0], keys[i][0], minutes)
			return (keys[i - 1][1] as Color).lerp(keys[i][1], t)
	return NIGHT


func _process(_delta: float) -> void:
	if TimeManager.season != _season:
		_season = TimeManager.season
		SeasonLook.set_season(_season)
	color = color_at(TimeManager.get_exact_minutes(), _season)
