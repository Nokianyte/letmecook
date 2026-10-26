extends Control
## Root scene. Shows the scene for the current phase of the run: kitchen, night, or run over.

const PHASE_SCENES := {
	RunState.Phase.KITCHEN: preload("res://scenes/kitchen/kitchen.tscn"),
	RunState.Phase.NIGHT: preload("res://scenes/night/night.tscn"),
	RunState.Phase.RUN_OVER: preload("res://scenes/run_over/run_over.tscn"),
}

var _current: Node = null
var debug_overlay: CanvasLayer = preload("res://ui/debug_overlay.gd").new()
var how_to_play: CanvasLayer = preload("res://ui/how_to_play.gd").new()
var tutorial: CanvasLayer = preload("res://ui/tutorial.gd").new()


func _ready() -> void:
	add_child(debug_overlay)
	add_child(how_to_play)
	tutorial.main = self
	add_child(tutorial)
	tutorial.offer_if_first_time()
	RunState.phase_changed.connect(_show_phase)
	_show_phase()


func _show_phase() -> void:
	if _current != null:
		_current.queue_free()
	_current = PHASE_SCENES[RunState.phase].instantiate()
	add_child(_current)


## The scene currently shown (for tests and debugging).
func current_scene() -> Node:
	return _current
