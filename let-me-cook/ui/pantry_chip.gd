class_name PantryChip
extends Control
## One owned unit in the pantry, showing its freshness. Solids are dragged onto a
## station; pressing a sauce bottle starts pouring (hold over the burger).

signal pour_started(unit: IngredientUnit)

const CHIP_SIZE := Vector2(58, 30)
const BOTTLE_CHIP_SIZE := Vector2(96, 30)

var unit: IngredientUnit


func _init(p_unit: IngredientUnit) -> void:
	unit = p_unit
	var fresh := roundi(unit.freshness * 100)
	if unit.ingredient.is_sauce():
		custom_minimum_size = BOTTLE_CHIP_SIZE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = "%s · %d/%d doses · %d%% fresh\nHold and move over the burger to pour" % [
			unit.ingredient.display_name, unit.doses_left, unit.ingredient.doses, fresh]
	else:
		custom_minimum_size = CHIP_SIZE
		mouse_default_cursor_shape = Control.CURSOR_DRAG
		tooltip_text = "%s · %d%% fresh" % [unit.ingredient.display_name, fresh]


## A translucent rectangle of the ingredient, centered on the cursor.
static func make_drag_preview(ingredient: Ingredient) -> Control:
	var swatch := ColorRect.new()
	swatch.color = ingredient.color
	swatch.size = ingredient.size
	swatch.position = -ingredient.size * 0.5
	var preview := Control.new()
	preview.modulate.a = 0.8
	preview.add_child(swatch)
	return preview


func _get_drag_data(_at_position: Vector2) -> Variant:
	if unit.ingredient.is_sauce():
		return null
	set_drag_preview(make_drag_preview(unit.ingredient))
	return {"unit": unit}


func _gui_input(event: InputEvent) -> void:
	if unit.ingredient.is_sauce() and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pour_started.emit(unit)
		accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, unit.ingredient.color)
	draw_rect(rect, Color(0, 0, 0, 0.4), false, 1.0)
	var text_color := Color.BLACK if unit.ingredient.color.get_luminance() > 0.5 else Color.WHITE
	var text := "%d%%" % roundi(unit.freshness * 100)
	if unit.ingredient.is_sauce():
		text = "%d/%d · %s" % [unit.doses_left, unit.ingredient.doses, text]
	draw_string(ThemeDB.fallback_font, Vector2(0, size.y * 0.5 + 5), text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, text_color)
