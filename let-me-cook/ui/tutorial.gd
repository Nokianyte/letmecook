extends CanvasLayer
## Guided first day. A coach bubble and a pulsing highlight walk the player through a
## first burger, serving, closing the day and the night shop. Every step is a check on
## game state, re-evaluated each frame, so it can't miss an event or get stuck across
## scene changes. Also owns the first-launch offer and the "?" menu.

const BUBBLE_WIDTH := 330.0
const MARGIN := 14.0
const HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.35)
## Steps 0..3 build the first burger; they recover from a collapse or an emptied board.
const BURGER_STEPS := 4

## The scene host (scenes/main.gd): current_scene() and the rules card.
var main: Node
## Index of the current step, or -1 when the tutorial isn't running.
var step := -1

var _steps: Array[Dictionary] = []
var _highlight: Control
var _highlight_rect := Rect2()
var _bubble: PanelContainer
var _bubble_text: Label
var _next_button: Button
var _offer: Control
var _menu: Control


func _ready() -> void:
	layer = 40
	add_to_group("tutorial")
	_steps = _make_steps()
	_build_ui()


func is_running() -> bool:
	return step >= 0


## Shows the "first time?" offer unless the tutorial was already finished or skipped.
func offer_if_first_time() -> void:
	if not is_done():
		_offer.visible = true


func start() -> void:
	_offer.visible = false
	_menu.visible = false
	RunState.new_run()
	step = 0
	_bubble.visible = true
	_highlight.visible = true


func skip() -> void:
	_stop()


func open_help_menu() -> void:
	_menu.visible = true


func is_done() -> bool:
	return Settings.get_value("tutorial", "done", false)


func mark_done() -> void:
	Settings.set_value("tutorial", "done", true)


func _stop() -> void:
	step = -1
	_bubble.visible = false
	_highlight.visible = false
	_offer.visible = false
	mark_done()


func _advance() -> void:
	step += 1
	if step >= _steps.size():
		_stop()


# --- Every frame: check the step, then place the bubble and highlight ---------------

func _process(_delta: float) -> void:
	if step < 0:
		return
	if RunState.phase == RunState.Phase.RUN_OVER:
		_stop()
		return
	var current := _steps[step]
	var text: String = current.text
	var target: Rect2 = current.target.call()

	var board := _board()
	if step < BURGER_STEPS and board != null:
		if board.ruined:
			text = "It fell over! Press Discard and start again. Keep each layer centered on the one below."
			target = _rect(_kitchen_node("%ClearButton"))
		elif step > 0 and board.is_empty():
			step = 0
			return

	if current.has("done") and current.done.call():
		_advance()
		return

	_bubble_text.text = text
	_next_button.visible = not current.has("done")
	_next_button.text = "Finish" if step == _steps.size() - 1 else "Next"
	_place(target)


func _place(target: Rect2) -> void:
	_highlight_rect = target.grow(6) if target.has_area() else Rect2()
	_highlight.queue_redraw()
	var screen := get_viewport().get_visible_rect().size
	var size := _bubble.get_combined_minimum_size()
	size.x = BUBBLE_WIDTH
	var pos: Vector2
	if not target.has_area():
		pos = Vector2(screen.x - size.x - MARGIN, screen.y - size.y - MARGIN)
	elif target.end.x + MARGIN + size.x < screen.x:
		pos = Vector2(target.end.x + MARGIN, target.position.y)
	elif target.position.x - MARGIN - size.x > 0:
		pos = Vector2(target.position.x - MARGIN - size.x, target.position.y)
	else:
		pos = Vector2(target.position.x, target.end.y + MARGIN)
	pos.x = clampf(pos.x, MARGIN, screen.x - size.x - MARGIN)
	pos.y = clampf(pos.y, MARGIN, screen.y - size.y - MARGIN)
	_bubble.position = pos
	_bubble.size = size


# --- The steps -------------------------------------------------------------------------

func _make_steps() -> Array[Dictionary]:
	return [
		{"text": "Welcome to your kitchen! Drag a Stale Bread from your pantry onto the plate.",
			"target": _pantry_chip_rect.bind(&"stale_bread"),
			"done": func() -> bool: return _board() != null and _board().solid_ids().has(&"stale_bread")},
		{"text": "Now put the Patty on top of it.",
			"target": _pantry_chip_rect.bind(&"patty"),
			"done": func() -> bool: return _board() != null and _board().solid_ids().has(&"patty")},
		{"text": "Press and hold the Ketchup bottle, then move it over the patty to pour a little sauce.",
			"target": _pantry_chip_rect.bind(&"ketchup"),
			"done": func() -> bool: return _board() != null and _board().sauce_doses() >= 3 and not _board().is_pouring()},
		{"text": "Finish with another Stale Bread on top. Bread at both ends gives +1 mult!",
			"target": _pantry_chip_rect.bind(&"stale_bread"),
			"done": _has_bun_ends},
		{"text": "Watch the list on the right: it shows what this burger scores if you serve it now. Serve it!",
			"target": func() -> Rect2: return _rect(_kitchen_node("%ServeButton")),
			"done": func() -> bool: return not RunState.served_today.is_empty() or RunState.phase != RunState.Phase.KITCHEN},
		{"text": "Score = chips × mult. Chips come from each ingredient (fresher is worth more). Mult comes from combos and gadgets. Every point pays money.",
			"target": func() -> Rect2: return _rect(_kitchen_node("%Window"))},
		{"text": "These are combos: ways to stack ingredients that add mult. They light up when your burger has them. There are more to discover, so try different orders!",
			"target": func() -> Rect2: return _rect(_kitchen_node("%ComboBoard"))},
		{"text": "Cook more if you can. When you're done, close for the day to pay rent.",
			"target": func() -> Rect2: return _rect(_kitchen_node("%CloseButton")),
			"done": func() -> bool: return RunState.phase != RunState.Phase.KITCHEN},
		{"text": "Night time: this is the market. Bundles of 2–3 are cheaper per unit, but fresh food loses value overnight.",
			"target": func() -> Rect2: return _rect(_night_node("%Stock"))},
		{"text": "Anything outside the fridge loses freshness overnight. Click items in your pantry to move them into the fridge.",
			"target": func() -> Rect2: return _union(_rect(_night_node("%FridgeTitle")), _rect(_night_node("%Fridge")))},
		{"text": "Kitchen Gadgets change how dishes score. They apply left to right, so their order matters.",
			"target": func() -> Rect2: return _rect(_night_node("%GadgetOffers"))},
		{"text": "That's everything! Open the kitchen when you're ready. Good luck, chef.",
			"target": func() -> Rect2: return _rect(_night_node("%OpenButton"))},
	]


func _has_bun_ends() -> bool:
	var board := _board()
	if board == null:
		return false
	var dish := board.preview_dish()
	return dish != null and dish.layers.size() >= 3 and Scoring.has_bun_ends(dish)


func _kitchen_node(path: String) -> Control:
	if RunState.phase != RunState.Phase.KITCHEN or main == null or main.current_scene() == null:
		return null
	return main.current_scene().get_node_or_null(path)


func _night_node(path: String) -> Control:
	if RunState.phase != RunState.Phase.NIGHT or main == null or main.current_scene() == null:
		return null
	return main.current_scene().get_node_or_null(path)


func _board() -> BurgerBoard:
	return _kitchen_node("%BurgerBoard") as BurgerBoard


func _pantry_chip_rect(id: StringName) -> Rect2:
	var rows := _kitchen_node("%Rows")
	if rows == null:
		return Rect2()
	for row in rows.get_children():
		for chip in row.get_children():
			if chip is PantryChip and chip.unit.ingredient.id == id:
				return _rect(chip)
	return Rect2()


## Bounding box of two rectangles, ignoring empty ones (Rect2.merge would include the origin).
func _union(a: Rect2, b: Rect2) -> Rect2:
	if not a.has_area():
		return b
	if not b.has_area():
		return a
	return a.merge(b)


func _rect(control: Control) -> Rect2:
	return control.get_global_rect() if control != null and control.is_visible_in_tree() else Rect2()


# --- UI ----------------------------------------------------------------------------------

func _build_ui() -> void:
	_highlight = Control.new()
	_highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.draw.connect(_draw_highlight)
	_highlight.visible = false
	add_child(_highlight)

	_bubble = PanelContainer.new()
	_bubble.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.13, 0.96)
	style.border_color = HIGHLIGHT_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	_bubble.add_theme_stylebox_override("panel", style)
	add_child(_bubble)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_bubble.add_child(box)
	_bubble_text = Label.new()
	_bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text.custom_minimum_size = Vector2(BUBBLE_WIDTH - 24, 0)
	box.add_child(_bubble_text)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var skip_button := Button.new()
	skip_button.text = "Skip tutorial"
	skip_button.flat = true
	skip_button.pressed.connect(skip)
	buttons.add_child(skip_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.pressed.connect(_advance)
	buttons.add_child(_next_button)

	_offer = _dialog("First time cooking?", "A short guided first day shows you how to build, score and shop (about two minutes).", [
		["Play the tutorial", start],
		["Skip", _stop],
	])
	_menu = _dialog("Need a hand?", "", [
		["Replay the tutorial", start],
		["Rules reference", func() -> void:
			_menu.visible = false
			if main != null:
				main.how_to_play.open()],
		["Close", func() -> void: _menu.visible = false],
	])


## A centered modal panel with a title, an optional message and a column of buttons.
func _dialog(title: String, message: String, actions: Array) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 22)
	box.add_child(title_label)
	if message != "":
		var message_label := Label.new()
		message_label.text = message
		message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(message_label)
	for action in actions:
		var button := Button.new()
		button.text = action[0]
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(action[1])
		box.add_child(button)
	return root


func _draw_highlight() -> void:
	if not _highlight_rect.has_area():
		return
	var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 180.0)
	var color := HIGHLIGHT_COLOR
	color.a = pulse
	_highlight.draw_rect(_highlight_rect, color, false, 3.0)
