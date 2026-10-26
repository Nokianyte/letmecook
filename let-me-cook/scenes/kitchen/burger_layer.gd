class_name BurgerLayer
extends RigidBody2D
## One solid ingredient on the burger. Stays dynamic while it is the live layer;
## the board locks (freezes) it when the player moves on.

signal settled

const SETTLE_SPEED := 4.0
const SETTLE_TIME := 0.12
const MAX_SETTLE_WAIT := 2.0
const LOST_BELOW_Y := 1500.0
## Landing squash, applied to the drawing only (scaling a physics body distorts its collider).
const SQUASH := Vector2(1.12, 0.75)
const SQUASH_TIME := 0.18

var unit: IngredientUnit

var _age := 0.0
var _still_time := 0.0
var _resting := false
var _draw_scale := Vector2.ONE
var _locked := false
var _lock_transform := Transform2D()


func _init(p_unit: IngredientUnit) -> void:
	unit = p_unit
	lock_rotation = true
	gravity_scale = 2.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC

	var material := PhysicsMaterial.new()
	material.friction = 1.0
	material.bounce = 0.0
	physics_material_override = material

	var rect := RectangleShape2D.new()
	rect.size = unit.ingredient.size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)


## True once the layer has come to rest after its drop.
func is_resting() -> bool:
	return _resting


func lock() -> void:
	# Lock where the physics engine has the layer. The node's transform can be stale for a
	# moment if the layout above the board shifted, and freezing would snap to it.
	global_transform = PhysicsServer2D.body_get_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM)
	freeze = true
	# Godot can re-apply a stale transform from the fall to a body frozen right after it
	# lands (seen with a real render loop: the layer jumped ~40 px). A locked layer holds
	# its place: any move that isn't ours is undone immediately.
	_lock_transform = global_transform
	_locked = true
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and _locked and not global_transform.is_equal_approx(_lock_transform):
		global_transform = _lock_transform
		PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM, _lock_transform)


func contains_point(local_point: Vector2) -> bool:
	return Rect2(position - unit.ingredient.size * 0.5, unit.ingredient.size).has_point(local_point)


func _physics_process(delta: float) -> void:
	if _resting:
		# Collapsed layers fall out of view; stop simulating them.
		if not freeze and position.y > LOST_BELOW_Y:
			set_deferred("freeze", true)
			hide()
		return

	_age += delta
	if _age > 0.1 and linear_velocity.length() < SETTLE_SPEED:
		_still_time += delta
	else:
		_still_time = 0.0

	if _still_time >= SETTLE_TIME or _age >= MAX_SETTLE_WAIT:
		_resting = true
		_squash()
		settled.emit()


## Unfreezes the layer and throws it, for the collapse animation.
func tumble(impulse: Vector2, spin: float) -> void:
	_locked = false
	lock_rotation = false
	freeze = false
	apply_central_impulse(impulse)
	angular_velocity = spin


func _squash() -> void:
	var tween := create_tween()
	tween.tween_method(_set_draw_scale, SQUASH, Vector2.ONE, SQUASH_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_draw_scale(value: Vector2) -> void:
	_draw_scale = value
	queue_redraw()


func _draw() -> void:
	# Squash around the bottom edge, so the layer stays on what it landed on.
	var bottom := Vector2(0, unit.ingredient.size.y * 0.5)
	draw_set_transform(bottom - bottom * _draw_scale, 0.0, _draw_scale)
	var size := unit.ingredient.size
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, unit.ingredient.color)
	draw_rect(rect, Color(0, 0, 0, 0.4), false, 1.0)
	var text_color := Color.BLACK if unit.ingredient.color.get_luminance() > 0.5 else Color.WHITE
	var font := ThemeDB.fallback_font
	var font_size := mini(14, int(size.y) - 2)
	draw_string(font, Vector2(-size.x * 0.5 + 6, font_size * 0.35), unit.ingredient.display_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
