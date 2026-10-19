class_name SauceSmear
extends Node2D
## Consecutive doses of one sauce on one surface, drawn as liquid: a 1D heightfield
## across the surface. Each dose adds a soft bump where the stream lands; a short
## diffusion step afterwards lets bumps merge and flatten. The sauce itself has no
## physics; a flat "cushion" collider over the wet area lets the next solid rest on
## it, and once covered the sauce is squashed flat into a thin layer.
## The node's origin is the center of the surface it sits on.

const COLUMN_WIDTH := 2.0
## Sauce area added by one dose, in px² (bump height × width).
const DOSE_AREA := 60.0
## Width (standard deviation) of one dose's bump, in px.
const DOSE_SPREAD := 5.0
## Diffusion rate per step (stable below 0.5) and how long sauce keeps flowing after a dose.
const FLOW_RATE := 0.25
const FLOW_STEPS_PER_FRAME := 3
const FLOW_DURATION := 0.25
## Thinner than this is not drawn.
const MIN_VISIBLE := 0.3
## The cushion is never thinner than this, so a single dose still lifts the next layer.
const MIN_CUSHION := 1.0

var unit: IngredientUnit
var amount: int = 0
var width: float

var _heights := PackedFloat32Array()
var _flow_time := 0.0
var _cushion: StaticBody2D
var _cushion_shape: CollisionShape2D


func _init(p_unit: IngredientUnit, p_width: float) -> void:
	unit = p_unit
	width = p_width
	_heights.resize(maxi(1, ceili(width / COLUMN_WIDTH)))
	_heights.fill(0.0)

	_cushion = StaticBody2D.new()
	_cushion_shape = CollisionShape2D.new()
	_cushion_shape.shape = RectangleShape2D.new()
	_cushion_shape.disabled = true
	_cushion.add_child(_cushion_shape)
	add_child(_cushion)


## Adds one dose landing at `local_x` (relative to the surface center).
func add_dose(local_x: float) -> void:
	amount += 1
	var peak := DOSE_AREA / (DOSE_SPREAD * sqrt(TAU))
	for i in _heights.size():
		var dx := _column_x(i) - local_x
		_heights[i] += peak * exp(-dx * dx / (2.0 * DOSE_SPREAD * DOSE_SPREAD))
	_flow_time = FLOW_DURATION
	_update_cushion()
	queue_redraw()


## Flattens the sauce over its wet area to its average thickness (same amount of sauce).
## Called when a solid comes to rest on it.
func squash() -> void:
	var wet := _wet_range()
	if wet.x < 0:
		return
	var thickness := cushion_thickness()
	for i in _heights.size():
		_heights[i] = thickness if i >= wet.x and i <= wet.y else 0.0
	_flow_time = 0.0
	_update_cushion()
	queue_redraw()


## Average sauce thickness over the wet area, which is how thick the cushion is.
func cushion_thickness() -> float:
	var wet := _wet_range()
	if wet.x < 0:
		return 0.0
	var total := 0.0
	for i in range(wet.x, wet.y + 1):
		total += _heights[i]
	return maxf(total / (wet.y - wet.x + 1), MIN_CUSHION)


func set_cushion_enabled(enabled: bool) -> void:
	_cushion.collision_layer = 1 if enabled else 0


## Sauce thickness at `local_x`, in px.
func height_at(local_x: float) -> float:
	var i := clampi(int((local_x + width * 0.5) / COLUMN_WIDTH), 0, _heights.size() - 1)
	return _heights[i]


func max_height() -> float:
	var top := 0.0
	for h in _heights:
		top = maxf(top, h)
	return top


func _process(delta: float) -> void:
	if _flow_time <= 0.0:
		return
	_flow_time -= delta
	for step in FLOW_STEPS_PER_FRAME:
		_flow()
	if _flow_time <= 0.0:
		_update_cushion()
	queue_redraw()


## One diffusion step; edges reflect, so no sauce is lost.
func _flow() -> void:
	var n := _heights.size()
	if n < 2:
		return
	var next := _heights.duplicate()
	for i in n:
		var left := _heights[maxi(i - 1, 0)]
		var right := _heights[mini(i + 1, n - 1)]
		next[i] = _heights[i] + FLOW_RATE * (left + right - 2.0 * _heights[i])
	_heights = next


## First and last column with visible sauce, or (-1, -1).
func _wet_range() -> Vector2i:
	var first := -1
	var last := -1
	for i in _heights.size():
		if _heights[i] >= MIN_VISIBLE:
			if first < 0:
				first = i
			last = i
	return Vector2i(first, last)


func _update_cushion() -> void:
	var wet := _wet_range()
	_cushion_shape.disabled = wet.x < 0
	if wet.x < 0:
		return
	var size := Vector2((wet.y - wet.x + 1) * COLUMN_WIDTH, cushion_thickness())
	(_cushion_shape.shape as RectangleShape2D).size = size
	_cushion_shape.position = Vector2((_column_x(wet.x) + _column_x(wet.y)) * 0.5, -size.y * 0.5)


func _column_x(i: int) -> float:
	return -width * 0.5 + (i + 0.5) * COLUMN_WIDTH


func _draw() -> void:
	# One outline across all visible runs of sauce, drawn as filled polygons.
	var color := unit.ingredient.color
	var run := PackedVector2Array()
	for i in _heights.size() + 1:
		var h := _heights[i] if i < _heights.size() else 0.0
		if h >= MIN_VISIBLE:
			run.append(Vector2(_column_x(i), -h))
		elif not run.is_empty():
			_draw_run(run, color)
			run.clear()


func _draw_run(top: PackedVector2Array, color: Color) -> void:
	var half := COLUMN_WIDTH * 0.5
	var points := PackedVector2Array([Vector2(top[0].x - half, 0.5), Vector2(top[0].x - half, top[0].y)])
	points.append_array(top)
	points.append(Vector2(top[-1].x + half, top[-1].y))
	points.append(Vector2(top[-1].x + half, 0.5))
	draw_colored_polygon(points, color)
