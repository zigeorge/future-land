class_name ItemSlot
extends PanelContainer
## One inventory slot: frame, item icon (or its name while there's no art),
## and the stack size. Used by the hotbar, the backpack and the shop.

signal pressed

const SIZE := Vector2(40, 40)
## Item icons are shown in a 32x32 square (16x16 pixel art at exactly 2x).
const ICON_SIZE := Vector2(32, 32)
const FRAME := preload("res://assets/art/ui/hotbar_frame.png")
const SELECTED_FRAME := preload("res://assets/art/ui/hotbar_frame_selected.png")
## Solid backing inside the frame, so the map never shows through the slot.
const BACKING_COLOR := Color(0.07, 0.1, 0.16, 0.94)

## Clickable slots emit `pressed`; the hotbar's slots let clicks through.
var interactive := false:
	set(value):
		interactive = value
		mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE

var _backing := ColorRect.new()
var _icon := TextureRect.new()
var _label := Label.new()
var _selected := false


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backing.color = BACKING_COLOR
	_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backing)
	_icon.custom_minimum_size = ICON_SIZE
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_constant_override("outline_size", 3)
	_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	add_child(_label)
	_apply_frame()


func show_item(item: ItemData, count: int) -> void:
	_icon.texture = item.icon if item else null
	_icon.texture_filter = Art.filter_for(_icon.texture, 16)
	if item == null:
		_label.text = ""
	elif item.icon == null:
		# No art yet: show a short name instead of an icon; seeds are tagged so
		# they don't look like the crop they grow.
		var short_name := item.display_name.trim_suffix(" Seeds").trim_suffix(" Seed").left(6)
		if item.category == ItemData.Category.SEED:
			short_name += "\nseeds"
		_label.text = short_name + ("\n%d" % count if count > 1 else "")
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		# Stack size in the bottom-right corner.
		_label.text = str(count) if count > 1 else ""
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM


func set_selected(selected: bool) -> void:
	if selected != _selected:
		_selected = selected
		_apply_frame()


func _gui_input(event: InputEvent) -> void:
	if interactive and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _apply_frame() -> void:
	var texture := SELECTED_FRAME if _selected else FRAME
	var style := StyleBoxTexture.new()
	style.texture = texture
	# Small pixel-art frames are 9-sliced; large HD frames are scaled whole.
	style.set_texture_margin_all(5 if texture.get_width() <= 32 else 0)
	style.set_content_margin_all(4)
	texture_filter = Art.filter_for(texture, SIZE.x)
	add_theme_stylebox_override("panel", style)
