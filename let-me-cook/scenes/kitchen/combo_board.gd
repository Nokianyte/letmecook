extends Control
## The combo board: a grid of every discovered combo of the station being built (name,
## mult, rule), lit up while the dish in progress has it, plus a cell counting the combos
## left to discover.

const NAME_COLOR := Color(1.0, 0.85, 0.35)
const SECRET_COLOR := Color(0.85, 0.6, 1.0)
const PENALTY_COLOR := Color(1.0, 0.4, 0.4)
const RULE_COLOR := Color(1, 1, 1, 0.6)
const ACTIVE_BORDER := Color(1.0, 0.85, 0.35)
## Fixed height: the board must never resize while a burger is being built, or the plate
## (and its physics stage) below it would shift. Fits all 14 burger combos (3 rows of 5) at 1280 px.
const BOARD_HEIGHT := 118.0
const COLUMNS := 5
const NAME_SIZE := 12
const RULE_SIZE := 11

## The station whose combos are shown.
var station := Dish.Station.BURGER

var _grid: GridContainer
## The "N more to discover" cell's text, or null when everything is discovered.
var _hidden_label: Label
## Combo id -> {"panel": PanelContainer, "count": Label}
var _chips: Dictionary = {}
var _counts: Dictionary = {}
var _normal_style := StyleBoxFlat.new()
var _active_style := StyleBoxFlat.new()
## What the chips were built from (station and discoveries); rebuild only when it changes.
var _built_for := ""


func _ready() -> void:
	custom_minimum_size.y = BOARD_HEIGHT
	clip_contents = true
	_normal_style.bg_color = Color(0.13, 0.13, 0.16)
	_normal_style.set_content_margin_all(2)
	_normal_style.content_margin_left = 5
	_normal_style.content_margin_right = 5
	_normal_style.set_border_width_all(2)
	_normal_style.border_color = Color(0, 0, 0, 0)
	_active_style = _normal_style.duplicate()
	_active_style.bg_color = Color(0.24, 0.2, 0.08)
	_active_style.border_color = ACTIVE_BORDER

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grid.add_theme_constant_override("h_separation", 3)
	_grid.add_theme_constant_override("v_separation", 4)
	add_child(_grid)

	RunState.changed.connect(_rebuild_if_changed)
	RunState.combo_discovered.connect(_on_discovered)
	_rebuild()


## Shows `dish_station`'s combos, lighting up those `result` (the dish in progress) earns.
func show_dish(dish_station: Dish.Station, result: ScoreResult) -> void:
	station = dish_station
	_counts = Scoring.combo_counts(result)
	_rebuild_if_changed()
	_show_counts()


func shown_combos() -> Array[Combo]:
	var shown: Array[Combo] = []
	for combo in RunState.data.combos:
		if combo.station == station and RunState.is_discovered(combo):
			shown.append(combo)
	return shown


## Regular (non-secret) combos of the shown station not discovered yet.
func hidden_count() -> int:
	var hidden := 0
	for combo in RunState.data.combos:
		if combo.station == station and not combo.secret and not RunState.is_discovered(combo):
			hidden += 1
	return hidden


## Whether the shown station still has undiscovered secret combos.
func secrets_left() -> bool:
	for combo in RunState.data.combos:
		if combo.station == station and combo.secret and not RunState.is_discovered(combo):
			return true
	return false


## Chips currently lit up: combo id -> count.
func active() -> Dictionary:
	var lit := {}
	for id in _chips:
		if _counts.has(id):
			lit[id] = _counts[id]
	return lit


func _signature() -> String:
	var parts: Array[String] = [str(station)]
	for combo in shown_combos():
		parts.append(str(combo.id))
	return "|".join(parts)


func _rebuild_if_changed() -> void:
	# Smoothie combos only once the blender is owned.
	if station == Dish.Station.SMOOTHIE and not RunState.has_blender:
		station = Dish.Station.BURGER
		_counts = {}
	if _signature() != _built_for:
		_rebuild()


func _rebuild() -> void:
	_built_for = _signature()
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_chips.clear()
	_hidden_label = null

	for combo in shown_combos():
		_chips[combo.id] = _make_chip(combo)
	var hidden := hidden_count()
	if hidden > 0 or secrets_left():
		var panel := _panel()
		panel.modulate.a = 0.6
		var text := "? %d more combo%s" % [hidden, "s" if hidden > 1 else ""] if hidden > 0 else "? secret combos"
		text += "\n+ secret ones" if hidden > 0 and secrets_left() else "\nto discover"
		_hidden_label = _label(text, Color.WHITE, RULE_SIZE)
		panel.add_child(_hidden_label)
		_grid.add_child(panel)
	_show_counts()


func _make_chip(combo: Combo) -> Dictionary:
	var panel := _panel()
	panel.tooltip_text = "%s%s: %s, %s mult%s" % ["Secret combo " if combo.secret else "", combo.display_name, combo.rule, _value_text(combo),
			" each time" if combo.each else ""]
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -2)
	panel.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	box.add_child(row)
	var color := PENALTY_COLOR if combo.is_penalty() else SECRET_COLOR if combo.secret else NAME_COLOR
	var name_label := _label(combo.display_name, color, NAME_SIZE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Clips instead of widening the chip when a count appears (the grid must not grow).
	name_label.clip_text = true
	row.add_child(name_label)
	var count := _label("", Color.WHITE, NAME_SIZE)
	row.add_child(count)
	row.add_child(_label(_value_text(combo), color, NAME_SIZE))
	box.add_child(_label(combo.rule, RULE_COLOR, RULE_SIZE))
	_grid.add_child(panel)
	return {"panel": panel, "count": count}


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _normal_style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel


func _show_counts() -> void:
	for id in _chips:
		var chip: Dictionary = _chips[id]
		var n: int = _counts.get(id, 0)
		chip.panel.add_theme_stylebox_override("panel", _active_style if n > 0 else _normal_style)
		chip.count.text = "×%d" % n if n > 1 else ""
		chip.count.visible = n > 1


func _on_discovered(combo: Combo) -> void:
	if combo.station != station:
		return
	_rebuild_if_changed()
	if _chips.has(combo.id):
		var panel: PanelContainer = _chips[combo.id].panel
		var tween := panel.create_tween().set_loops(3)
		tween.tween_property(panel, "modulate", Color(1.6, 1.4, 0.6), 0.15)
		tween.tween_property(panel, "modulate", Color.WHITE, 0.25)


func _label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label


static func _value_text(combo: Combo) -> String:
	return "%s%.1f" % ["+" if combo.mult >= 0 else "−", absf(combo.mult)]
