extends Control
## Kitchen phase: build dishes from the pantry and serve them through the window.

@onready var _day_label: Label = %DayLabel
@onready var _money_label: Label = %MoneyLabel
@onready var _rent_label: Label = %RentLabel
@onready var _day_score_label: Label = %DayScoreLabel
@onready var _tally: ScoreTally = %Tally
@onready var _close_button: Button = %CloseButton
@onready var _pantry: PanelContainer = %Pantry
@onready var _board: BurgerBoard = %BurgerBoard
@onready var _clear_button: Button = %ClearButton
@onready var _serve_button: Button = %ServeButton
@onready var _status_label: Label = %StatusLabel
@onready var _spoiled_notice: Label = %SpoiledNotice
@onready var _jar_column: Control = %JarColumn
@onready var _jar: SmoothieJar = %SmoothieJar
@onready var _jar_status: Label = %JarStatus
@onready var _empty_jar_button: Button = %EmptyJarButton
@onready var _blend_button: Button = %BlendButton
@onready var _counter_row: HBoxContainer = %CounterRow
@onready var _specials: VBoxContainer = %SpecialsStrip

var live_preview: Node = preload("res://scenes/kitchen/live_preview.gd").new()


func _ready() -> void:
	RunState.changed.connect(_refresh)
	_board.state_changed.connect(_refresh)
	_pantry.pour_requested.connect(_board.start_pour)
	_clear_button.pressed.connect(_board.clear)
	_serve_button.pressed.connect(_on_serve_pressed)
	_close_button.pressed.connect(_on_close_pressed)
	%HelpButton.pressed.connect(func() -> void: get_tree().call_group("tutorial", "open_help_menu"))
	_jar.state_changed.connect(_refresh)
	_empty_jar_button.pressed.connect(_jar.clear)
	_blend_button.pressed.connect(_on_blend_pressed)
	# The day total catches up once the tally has played.
	_tally.finished.connect(_show_day_score)
	_tally.line_played.connect(func(line: Dictionary) -> void: _counter_row.react(line.source))
	RunState.day_closed.connect(_show_day_score)
	# However the day ends (button or debug skip), food in progress goes back to the pantry.
	RunState.day_closed.connect(_return_unfinished_food)
	_show_day_score()
	_show_spoiled_notice()
	_setup_live_preview()
	_refresh()


func _setup_live_preview() -> void:
	# Callouts float above everything in the kitchen and never take the mouse.
	var overlay := Control.new()
	overlay.name = "Callouts"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	add_child(live_preview)
	live_preview.setup(_board, _jar, _tally, overlay, _specials)


func _show_spoiled_notice() -> void:
	var counts := {}
	for unit in RunState.spoiled_overnight:
		counts[unit.ingredient.display_name] = counts.get(unit.ingredient.display_name, 0) + 1
	var names: Array[String] = []
	for name in counts:
		names.append(name if counts[name] == 1 else "%s ×%d" % [name, counts[name]])
	_spoiled_notice.visible = not names.is_empty()
	_spoiled_notice.text = "Spoiled overnight: %s" % ", ".join(names)


func _jar_status_text() -> String:
	var ingredients := _jar.ingredients()
	var text := "Jar %d/%d" % [ingredients.size(), RunState.balance.jar_capacity]
	var ratio := Smoothie.liquid_ratio(ingredients)
	if ratio >= 0.0:
		text += " · %d%% liquid" % roundi(ratio * 100)
	if Smoothie.is_muddy(ingredients, RunState.balance):
		text += " · muddy!"
	return text


func _show_day_score() -> void:
	_day_score_label.text = "Today: %d pts" % RunState.day_score


func _on_serve_pressed() -> void:
	var dish := _board.take_dish()
	if dish != null:
		RunState.serve(dish)


func _on_blend_pressed() -> void:
	var dish := _jar.take_dish()
	if dish != null:
		RunState.serve(dish)


func _on_close_pressed() -> void:
	RunState.close_day()


func _return_unfinished_food() -> void:
	_board.clear()
	_jar.clear()


func _refresh() -> void:
	_day_label.text = "Day %d/%d" % [RunState.day, RunState.balance.days_per_run]
	_money_label.text = "$%d" % RunState.money
	_rent_label.text = "Rent today: $%d" % RunState.rent_today()
	_close_button.text = "Close for the day (pay $%d)" % RunState.rent_today()

	var busy := _board.is_busy() or _board.is_pouring()
	_clear_button.text = "Discard" if _board.ruined else "Clear"
	_clear_button.disabled = busy or _board.is_empty()
	_serve_button.disabled = busy or _board.ruined or _board.solid_count() == 0
	_close_button.disabled = busy

	_jar_column.visible = RunState.has_blender
	_empty_jar_button.disabled = _jar.is_empty()
	_blend_button.disabled = _jar.is_empty()
	_jar_status.text = _jar_status_text()

	if _board.ruined:
		_status_label.text = "It collapsed! Discard it."
	elif _board.is_pouring():
		var bottle := _board.pouring_unit()
		_status_label.text = "Pouring %s: %d left" % [bottle.ingredient.display_name, bottle.doses_left]
	elif _board.is_empty():
		_status_label.text = "Drag ingredients onto the plate"
	else:
		_status_label.text = "Stability %d%%" % roundi(maxf(_board.stability, 0.0) * 100)
