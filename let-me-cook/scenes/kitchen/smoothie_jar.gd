class_name SmoothieJar
extends Control
## Smoothie station (needs the blender). Ingredients dropped in tumble into the jar for
## feel; what counts is only which units are inside. The liquid level shows the blended
## color of everything in it.

signal state_changed

const JAR_SIZE := Vector2(170, 240)
const WALL := 8.0
const CHUNK_SIZE := Vector2(26, 20)
const DROP_HEIGHT := 40.0
const GLASS_COLOR := Color(1, 1, 1, 0.06)
const OUTLINE_COLOR := Color(1, 1, 1, 0.35)

var contents: Array[IngredientUnit] = []

var _stage: Node2D
var _chunks: Array[RigidBody2D] = []


func _ready() -> void:
	clip_contents = true
	_stage = Node2D.new()
	add_child(_stage)
	_stage.add_child(_wall(Vector2(JAR_SIZE.x + WALL * 2, WALL), Vector2(0, WALL * 0.5)))
	for side in [-1, 1]:
		_stage.add_child(_wall(Vector2(WALL, JAR_SIZE.y), Vector2(side * (JAR_SIZE.x + WALL) * 0.5, -JAR_SIZE.y * 0.5)))
	resized.connect(_place_stage)
	state_changed.connect(queue_redraw)
	_place_stage()


func is_full() -> bool:
	return contents.size() >= RunState.balance.jar_capacity


func is_empty() -> bool:
	return contents.is_empty()


func ingredients() -> Array[Ingredient]:
	var result: Array[Ingredient] = []
	for unit in contents:
		result.append(unit.ingredient)
	return result


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if is_full() or not (data is Dictionary and data.get("unit") is IngredientUnit):
		return false
	var unit: IngredientUnit = data.unit
	return unit.ingredient.fits_jar() and RunState.pantry.has(unit)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	add_unit(data.unit, at_position)


## Takes `unit` out of the pantry and drops it into the jar near `at_position` (jar-local).
func add_unit(unit: IngredientUnit, at_position: Vector2) -> void:
	if unit == null or is_full():
		return
	RunState.remove_unit(unit)
	contents.append(unit)

	var chunk := RigidBody2D.new()
	var rect := RectangleShape2D.new()
	rect.size = CHUNK_SIZE
	var shape := CollisionShape2D.new()
	shape.shape = rect
	chunk.add_child(shape)
	var visual := ColorRect.new()
	visual.color = unit.ingredient.color
	visual.size = CHUNK_SIZE
	visual.position = -CHUNK_SIZE * 0.5
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chunk.add_child(visual)
	var half := (JAR_SIZE.x - CHUNK_SIZE.x) * 0.5
	chunk.position = Vector2(clampf(at_position.x - _stage.position.x, -half, half), -JAR_SIZE.y - DROP_HEIGHT)
	chunk.angular_velocity = randf_range(-4, 4)
	_stage.add_child(chunk)
	_chunks.append(chunk)
	state_changed.emit()


## Empties the jar back into the pantry, unchanged.
func clear() -> void:
	for unit in contents:
		RunState.return_unit(unit)
	_reset()


## Blends the contents into a Dish and empties the jar. Null if the jar is empty.
func take_dish() -> Dish:
	var dish := preview_dish()
	if dish != null:
		_reset()
	return dish


## The smoothie as it would be served right now, without changing the jar. Null if empty.
func preview_dish() -> Dish:
	if contents.is_empty():
		return null
	var dish := Dish.new(Dish.Station.SMOOTHIE)
	for unit in contents:
		dish.layers.append(DishLayer.new(unit.ingredient, unit.freshness))
	return dish


## Screen position just above the liquid.
func top_position() -> Vector2:
	var level := JAR_SIZE.y * 0.9 * contents.size() / RunState.balance.jar_capacity
	return get_global_transform() * (_stage.position - Vector2(0, level + 12))


func _reset() -> void:
	contents.clear()
	for chunk in _chunks:
		chunk.queue_free()
	_chunks.clear()
	state_changed.emit()


func _place_stage() -> void:
	_stage.position = Vector2(size.x * 0.5, size.y - WALL - 8)
	queue_redraw()


func _wall(wall_size: Vector2, at: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var rect := RectangleShape2D.new()
	rect.size = wall_size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	body.add_child(shape)
	body.position = at
	return body


func _draw() -> void:
	var bottom := _stage.position
	var glass := Rect2(bottom - Vector2(JAR_SIZE.x * 0.5, JAR_SIZE.y), JAR_SIZE)
	draw_rect(glass, GLASS_COLOR)
	if not contents.is_empty():
		var level := JAR_SIZE.y * 0.9 * contents.size() / RunState.balance.jar_capacity
		var fill_color := Smoothie.blend_color(ingredients())
		fill_color.a = 0.85
		draw_rect(Rect2(bottom - Vector2(JAR_SIZE.x * 0.5, level), Vector2(JAR_SIZE.x, level)), fill_color)
	draw_rect(glass.grow(WALL * 0.5), OUTLINE_COLOR, false, 2.0)
