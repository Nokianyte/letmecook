extends PanelContainer
## One counter slot: a gadget (or empty). Drag onto another slot to reorder;
## at night it can also be sold.

const CARD_SIZE := Vector2(180, 52)
const GADGET_COLOR := Color(0.85, 0.65, 1.0)
const WIGGLE_ANGLE := 0.12
const WIGGLE_STEP := 0.06

var slot: int
var gadget: Gadget
var sellable: bool


func _init(p_slot: int, p_gadget: Gadget, p_sellable: bool) -> void:
	slot = p_slot
	gadget = p_gadget
	sellable = p_sellable
	custom_minimum_size = CARD_SIZE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	add_child(box)

	var title := Label.new()
	title.clip_text = true
	box.add_child(title)
	if gadget == null:
		title.text = "empty slot"
		modulate.a = 0.45
		return

	title.text = gadget.display_name
	title.add_theme_color_override("font_color", GADGET_COLOR)
	tooltip_text = "%s\n%s\n(drag to reorder)" % [gadget.display_name, gadget.description]
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	var effect := Label.new()
	effect.text = gadget.description
	effect.clip_text = true
	effect.add_theme_font_size_override("font_size", 11)
	effect.modulate.a = 0.75
	box.add_child(effect)
	if sellable:
		var sell := Button.new()
		sell.text = "Sell $%d" % RunState.sell_price(gadget)
		sell.pressed.connect(RunState.sell_gadget.bind(slot))
		box.add_child(sell)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if gadget == null:
		return null
	var preview := Label.new()
	preview.text = gadget.display_name
	preview.add_theme_color_override("font_color", GADGET_COLOR)
	set_drag_preview(preview)
	return {"gadget_slot": slot}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("gadget_slot") and data.gadget_slot != slot


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	RunState.move_gadget(data.gadget_slot, slot)


## A quick shake, played when this gadget's line shows up in the tally.
func wiggle() -> void:
	pivot_offset = size * 0.5
	var tween := create_tween()
	for angle in [WIGGLE_ANGLE, -WIGGLE_ANGLE, WIGGLE_ANGLE * 0.5, 0.0]:
		tween.tween_property(self, "rotation", angle, WIGGLE_STEP)
