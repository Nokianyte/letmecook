extends CanvasLayer
## Playtest helpers, toggled with F1: add money, skip a day, give the blender,
## start a run with a given seed.

const TOGGLE_KEY := KEY_F1

var _panel: PanelContainer
var _seed_edit: LineEdit


func _ready() -> void:
	layer = 100
	_panel = PanelContainer.new()
	_panel.position = Vector2(16, 60)
	_panel.visible = false
	add_child(_panel)

	var box := VBoxContainer.new()
	_panel.add_child(box)
	var title := Label.new()
	title.text = "Debug (F1)"
	box.add_child(title)
	box.add_child(_button("+$50", _add_money))
	box.add_child(_button("Give blender", _give_blender))
	box.add_child(_button("Skip day", _skip_day))

	var seed_row := HBoxContainer.new()
	_seed_edit = LineEdit.new()
	_seed_edit.placeholder_text = "seed"
	_seed_edit.custom_minimum_size = Vector2(110, 0)
	seed_row.add_child(_seed_edit)
	seed_row.add_child(_button("New run", _new_run))
	box.add_child(seed_row)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == TOGGLE_KEY:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	_panel.visible = not _panel.visible
	if _panel.visible:
		_seed_edit.text = str(RunState.run_seed)


func _add_money() -> void:
	RunState.money += 50
	RunState.changed.emit()


func _give_blender() -> void:
	RunState.has_blender = true
	RunState.changed.emit()


## Kitchen: pays today's rent for you and closes. Night: opens the next day.
func _skip_day() -> void:
	match RunState.phase:
		RunState.Phase.KITCHEN:
			RunState.money += RunState.rent_today()
			RunState.close_day()
		RunState.Phase.NIGHT:
			RunState.end_night()


## Starts a run with the typed seed, or a random one if the field isn't a number.
func _new_run() -> void:
	var text := _seed_edit.text.strip_edges()
	RunState.new_run(text.to_int() if text.is_valid_int() and text.to_int() >= 0 else -1)


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(on_pressed)
	return button
