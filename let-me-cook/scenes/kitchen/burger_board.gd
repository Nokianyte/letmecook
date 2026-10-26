class_name BurgerBoard
extends Control
## Burger station. Solid ingredients are dropped from the pantry and fall with
## physics; the newest one stays live (adjustable) until the player picks up the
## next ingredient, pours sauce, or serves. Sauce is poured from bottles as a
## stream that spreads on the top layer (SauceSmear); it has no physics.

signal state_changed

const PLATE_SIZE := Vector2(340, 14)
## How far above the stack something may start falling.
const MAX_FALL := 220.0
const DROP_CLEARANCE := 24.0
const COLLAPSE_DURATION := 1.2
const SHAKE_STRENGTH := 10.0
const SHAKE_STEPS := 8
const SHAKE_STEP_TIME := 0.04
const BOTTLE_SIZE := Vector2(26, 54)
const NOZZLE_SIZE := Vector2(8, 10)
## Distance between a layer's edge and its chips callout.
const CALLOUT_GAP := 12.0
const STREAM_WIDTH := 3.0

## Stability of the locked stack, or of the stack plus the live layer while one is resting.
var stability: float = 1.0
var ruined: bool = false

var _stage: Node2D
var _plate: StaticBody2D
## Drawn above everything on the board: live-layer outline, bottle, stream.
var _overlay: Node2D
## Locked stack, bottom to top: BurgerLayer or SauceSmear entries.
var _entries: Array = []
var _live: BurgerLayer = null
var _lock_pending := false
var _collapsing := false
## Unit picked up from the board via drag-and-drop, until the drag ends.
var _dragged_live_unit: IngredientUnit = null
var _pouring: IngredientUnit = null
var _pour_timer := 0.0


func _ready() -> void:
	clip_contents = true
	_stage = Node2D.new()
	add_child(_stage)
	_plate = _make_plate()
	_stage.add_child(_plate)
	_overlay = Node2D.new()
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	resized.connect(_place_stage)
	state_changed.connect(_overlay.queue_redraw)
	_place_stage()


## True while something is in motion that must finish before the next action.
func is_busy() -> bool:
	return _collapsing or (_live != null and not _live.is_resting())


func is_pouring() -> bool:
	return _pouring != null


func pouring_unit() -> IngredientUnit:
	return _pouring


## Solid layers on the board, including the live one.
func solid_count() -> int:
	var count := 1 if _live != null else 0
	for entry in _entries:
		if entry is BurgerLayer:
			count += 1
	return count


func is_empty() -> bool:
	return _entries.is_empty() and _live == null


# --- Dropping solids --------------------------------------------------------

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if is_busy() or ruined or is_pouring():
		return false
	if not (data is Dictionary and data.get("unit") is IngredientUnit):
		return false
	var unit: IngredientUnit = data.unit
	if not unit.ingredient.fits_burger():
		return false
	if data.get("from_board", false):
		return unit == _dragged_live_unit
	return RunState.pantry.has(unit)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var from_board: bool = data.get("from_board", false)
	if from_board:
		_dragged_live_unit = null
	drop_unit(data.unit, at_position, not from_board)


## Drops `unit` at `at_position` (board-local) as the new live layer.
## Takes it out of the pantry unless it is the live layer being re-dropped.
func drop_unit(unit: IngredientUnit, at_position: Vector2, from_pantry: bool = true) -> void:
	_lock_live()
	if ruined or _live != null:
		return
	if from_pantry:
		RunState.remove_unit(unit)
	var layer := BurgerLayer.new(unit)
	layer.position = _clamp_drop(at_position, unit.ingredient.size.y * 0.5 + DROP_CLEARANCE)
	layer.settled.connect(_on_live_settled)
	_stage.add_child(layer)
	_live = layer
	state_changed.emit()


# --- Picking the live layer back up ----------------------------------------

func _get_drag_data(at_position: Vector2) -> Variant:
	if is_busy() or ruined or is_pouring() or _live == null:
		return null
	if not _live.contains_point(at_position - _stage.position):
		return null
	var unit := _live.unit
	_live.queue_free()
	_live = null
	_dragged_live_unit = unit
	set_drag_preview(PantryChip.make_drag_preview(unit.ingredient))
	_update_stability()
	state_changed.emit()
	return {"unit": unit, "from_board": true}


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			var data: Variant = get_viewport().gui_get_drag_data()
			# Picking up the next ingredient from the pantry locks the live layer.
			if data is Dictionary and not data.get("from_board", false) 					and data.get("unit") is IngredientUnit and data.unit.ingredient.burger_ok:
				_lock_live()
		NOTIFICATION_DRAG_END:
			# The live layer was released somewhere other than the board: back to the pantry.
			if _dragged_live_unit != null:
				RunState.return_unit(_dragged_live_unit)
				_dragged_live_unit = null
				state_changed.emit()


# --- Pouring sauce -----------------------------------------------------------

## Starts pouring from a sauce bottle; continues while the left button is held.
func start_pour(unit: IngredientUnit) -> void:
	if is_busy() or ruined or not unit.ingredient.is_sauce() or unit.doses_left <= 0:
		return
	_lock_live()
	if ruined:
		return
	_pouring = unit
	_pour_timer = RunState.balance.pour_interval  # first dose comes out right away
	state_changed.emit()


func _process(delta: float) -> void:
	if _pouring == null:
		return
	_overlay.queue_redraw()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _pouring.doses_left <= 0:
		_stop_pour()
		return
	if not is_over_pour_target(get_local_mouse_position()):
		# Ready to pour the moment the bottle reaches the burger.
		_pour_timer = RunState.balance.pour_interval
		return
	_pour_timer += delta
	if _pour_timer >= RunState.balance.pour_interval:
		_pour_timer = 0.0
		pour_dose(get_local_mouse_position())


## True when `at_position` (board-local) is over the board and above the top solid
## layer (or the plate when there is none), so poured sauce lands on the burger.
func is_over_pour_target(at_position: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(at_position):
		return false
	var x := at_position.x - _stage.position.x
	var top := _top_solid()
	var half_width := top.unit.ingredient.size.x * 0.5 if top != null else PLATE_SIZE.x * 0.5
	var center := top.position.x if top != null else 0.0
	return absf(x - center) <= half_width


## Pours one dose from the current bottle; the stream lands straight below `at_position` (board-local).
func pour_dose(at_position: Vector2) -> void:
	var unit := _pouring
	var smear: SauceSmear = _entries.back() if not _entries.is_empty() and _entries.back() is SauceSmear else null
	if smear == null or smear.unit.ingredient != unit.ingredient:
		smear = _new_smear(unit)
	var local_x := clampf(at_position.x - _stage.position.x - smear.position.x, -smear.width * 0.5, smear.width * 0.5)
	smear.add_dose(local_x)

	unit.doses_left -= 1
	if unit.doses_left <= 0:
		RunState.remove_unit(unit)
		_stop_pour()
	else:
		RunState.changed.emit()
	state_changed.emit()


## Starts a new sauce layer on top of the top solid (or the plate).
func _new_smear(unit: IngredientUnit) -> SauceSmear:
	var top := _top_solid()
	var width := top.unit.ingredient.size.x if top != null else PLATE_SIZE.x
	var smear := SauceSmear.new(unit, width)
	if top != null:
		smear.position = top.position - Vector2(0, top.unit.ingredient.size.y * 0.5)
	_stage.add_child(smear)
	_entries.append(smear)
	return smear


## Where the stream at board-local `x` hits the burger, in board-local y.
func _stream_end_y(x: float) -> float:
	var local_x := x - _stage.position.x
	var surface_y := 0.0
	var top := _top_solid()
	if top != null:
		surface_y = top.position.y - top.unit.ingredient.size.y * 0.5
	var smear: SauceSmear = _entries.back() if not _entries.is_empty() and _entries.back() is SauceSmear else null
	if smear != null:
		surface_y -= smear.height_at(local_x - smear.position.x)
	return _stage.position.y + surface_y


func _stop_pour() -> void:
	_pouring = null
	_overlay.queue_redraw()
	state_changed.emit()


# --- Clearing and serving ------------------------------------------------------

## Returns every solid layer to the pantry (sauce is lost), or throws a ruined burger away.
func clear() -> void:
	if is_busy() or is_pouring():
		return
	if not ruined:
		for entry in _entries:
			if entry is BurgerLayer:
				RunState.return_unit(entry.unit)
		if _live != null:
			RunState.return_unit(_live.unit)
	_reset()


## Locks the live layer and, if the burger survives, removes it from the board as a Dish.
## Null if there is nothing to serve or it collapsed.
func take_dish() -> Dish:
	if is_busy() or is_pouring() or ruined or solid_count() == 0:
		return null
	_lock_live()
	if ruined:
		return null
	var dish := _dish_from(_entries)
	_reset()
	return dish


## The dish in progress as it would be served right now (the live layer counts once it
## rests), without changing the board. Null when there's nothing to score: empty, ruined,
## sauce only, or a layer still falling.
func preview_dish() -> Dish:
	if ruined or _collapsing or (_live != null and not _live.is_resting()):
		return null
	var entries := _preview_entries()
	var dish := _dish_from(entries)
	return dish if dish.layers.any(func(l: DishLayer) -> bool: return not l.ingredient.is_sauce()) else null


## Screen positions just right of each of the preview's layers (vertically centered), in
## the same order as its layers.
func preview_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for entry in _preview_entries():
		var point: Vector2 = entry.position
		if entry is BurgerLayer:
			point.x += entry.unit.ingredient.size.x * 0.5 + CALLOUT_GAP
		else:
			point += Vector2(entry.width * 0.5 + CALLOUT_GAP, -entry.max_height() * 0.5)
		positions.append(_stage.get_global_transform() * point)
	return positions


## Screen position just above the top of the dish in progress.
func top_position() -> Vector2:
	return _stage.get_global_transform() * Vector2(0, _stack_top() - 10)


## Ids of the solid ingredients on the board (live one included), bottom to top.
func solid_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry in _entries:
		if entry is BurgerLayer:
			ids.append(entry.unit.ingredient.id)
	if _live != null:
		ids.append(_live.unit.ingredient.id)
	return ids


## Total doses of sauce on the board.
func sauce_doses() -> int:
	var doses := 0
	for entry in _entries:
		if entry is SauceSmear:
			doses += entry.amount
	return doses


func _preview_entries() -> Array:
	var entries := _entries.duplicate()
	if _live != null:
		entries.append(_live)
	return entries


func _dish_from(entries: Array) -> Dish:
	var dish := Dish.new(Dish.Station.BURGER)
	for entry in entries:
		if entry is BurgerLayer:
			dish.layers.append(DishLayer.new(entry.unit.ingredient, entry.unit.freshness))
		else:
			dish.layers.append(DishLayer.new(entry.unit.ingredient, entry.unit.freshness, entry.amount))
	return dish


# --- Internals -----------------------------------------------------------------

func _lock_live() -> void:
	if _live == null:
		return
	if not _live.is_resting():
		_lock_pending = true
		return
	_live.lock()
	_entries.append(_live)
	_live = null
	_lock_pending = false
	_update_stability()
	if stability < RunState.balance.stability_threshold:
		_collapse()
	state_changed.emit()


func _on_live_settled() -> void:
	# A solid resting on sauce squashes it into a flat layer between the two.
	if not _entries.is_empty() and _entries.back() is SauceSmear:
		_entries.back().squash()
	if _lock_pending:
		_lock_live()
	else:
		_update_stability()
	state_changed.emit()


func _update_stability() -> void:
	var input: Array[Dictionary] = []
	for entry in _entries:
		if entry is BurgerLayer:
			input.append({"x": entry.position.x, "width": entry.unit.ingredient.size.x})
	if _live != null and _live.is_resting():
		input.append({"x": _live.position.x, "width": _live.unit.ingredient.size.x})
	stability = Stability.compute(input, RunState.balance)


func _collapse() -> void:
	ruined = true
	_collapsing = true
	# Drop the plate's collision so the whole burger falls out of view.
	_plate.collision_layer = 0
	_shake()
	for entry in _entries:
		if entry is BurgerLayer:
			entry.tumble(Vector2(randf_range(-260, 260), randf_range(-240, -60)), randf_range(-8, 8))
		else:
			entry.set_cushion_enabled(false)
			var tween: Tween = entry.create_tween().set_parallel()
			tween.tween_property(entry, "position:y", entry.position.y + 600.0, COLLAPSE_DURATION).set_ease(Tween.EASE_IN)
			tween.tween_property(entry, "modulate:a", 0.0, COLLAPSE_DURATION)
	await get_tree().create_timer(COLLAPSE_DURATION).timeout
	_collapsing = false
	state_changed.emit()


func _shake() -> void:
	var tween := create_tween()
	for i in SHAKE_STEPS:
		var strength := SHAKE_STRENGTH * (1.0 - float(i) / SHAKE_STEPS)
		tween.tween_property(_stage, "position", _stage_home() + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength, SHAKE_STEP_TIME)
	tween.tween_property(_stage, "position", _stage_home(), SHAKE_STEP_TIME)


func _reset() -> void:
	for entry in _entries:
		entry.queue_free()
	_entries.clear()
	if _live != null:
		_live.queue_free()
		_live = null
	_lock_pending = false
	ruined = false
	stability = 1.0
	_plate.collision_layer = 1
	_place_stage()  # catch up on any resize that happened while the board was busy
	state_changed.emit()


## Converts a board-local point to a stage position above the current stack.
func _clamp_drop(at_position: Vector2, clearance: float) -> Vector2:
	var local := at_position - _stage.position
	var top := _stack_top()
	local.x = clampf(local.x, -PLATE_SIZE.x * 0.5, PLATE_SIZE.x * 0.5)
	local.y = clampf(local.y, top - MAX_FALL, top - clearance)
	return local


## The topmost solid layer (live or locked), or null.
func _top_solid() -> BurgerLayer:
	if _live != null:
		return _live
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i] is BurgerLayer:
			return _entries[i]
	return null


func _stack_top() -> float:
	var top := 0.0
	for entry in _entries:
		if entry is BurgerLayer:
			top = minf(top, entry.position.y - entry.unit.ingredient.size.y * 0.5)
		else:
			top = minf(top, entry.position.y - entry.max_height())
	if _live != null:
		top = minf(top, _live.position.y - _live.unit.ingredient.size.y * 0.5)
	return top


func _place_stage() -> void:
	# Never move the stage under a burger: locked layers would move with it while the
	# live layer (owned by the physics engine) stayed put, and they'd drift apart.
	if not is_empty():
		return
	_stage.position = _stage_home()


func _stage_home() -> Vector2:
	return Vector2(size.x * 0.5, size.y - 48)


func _make_plate() -> StaticBody2D:
	var body := StaticBody2D.new()
	var rect := RectangleShape2D.new()
	rect.size = PLATE_SIZE
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0, PLATE_SIZE.y * 0.5)
	body.add_child(shape)

	var visual := ColorRect.new()
	visual.color = Color(0.85, 0.85, 0.88)
	visual.size = PLATE_SIZE
	visual.position = Vector2(-PLATE_SIZE.x * 0.5, 0)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)
	return body


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.21, 0.21, 0.24))


func _draw_overlay() -> void:
	if _live != null and _live.is_resting() and not is_pouring():
		# Outline the live layer so the player knows it can still be moved.
		var s := _live.unit.ingredient.size + Vector2(6, 6)
		_overlay.draw_rect(Rect2(_stage.position + _live.position - s * 0.5, s), Color(1, 1, 1, 0.5), false, 2.0)
	if _pouring == null:
		return
	# Bottle held upside down; the nozzle tip is at the cursor.
	var nozzle := get_local_mouse_position()
	var color := _pouring.ingredient.color
	if is_over_pour_target(nozzle):
		var end := Vector2(nozzle.x, _stream_end_y(nozzle.x))
		if end.y > nozzle.y:
			_overlay.draw_line(nozzle, end, color, STREAM_WIDTH)
	var tip := Rect2(nozzle - Vector2(NOZZLE_SIZE.x * 0.5, NOZZLE_SIZE.y), NOZZLE_SIZE)
	var bottle := Rect2(tip.position - Vector2((BOTTLE_SIZE.x - NOZZLE_SIZE.x) * 0.5, BOTTLE_SIZE.y), BOTTLE_SIZE)
	for rect in [tip, bottle]:
		_overlay.draw_rect(rect, color)
		_overlay.draw_rect(rect, Color(0, 0, 0, 0.5), false, 1.0)
	_overlay.draw_string(ThemeDB.fallback_font, bottle.position + Vector2(0, BOTTLE_SIZE.y * 0.5 + 5),
			str(_pouring.doses_left), HORIZONTAL_ALIGNMENT_CENTER, BOTTLE_SIZE.x, 14, Color.WHITE)
