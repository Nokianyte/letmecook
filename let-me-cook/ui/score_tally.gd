class_name ScoreTally
extends VBoxContainer
## Plays a served dish's score breakdown back line by line, Balatro-style.

signal finished
## Emitted as each breakdown line appears (the counter wiggles the gadget that made it).
signal line_played(line: Dictionary)

const LINE_DELAY := 0.18
const RESULT_DELAY := 0.35
const CHIPS_COLOR := Color(0.55, 0.78, 1.0)
const MULT_COLOR := Color(1.0, 0.55, 0.45)
const SCORE_COLOR := Color(1.0, 0.85, 0.35)
const X_MULT_COLOR := Color(1.0, 0.45, 0.85)
const MONEY_COLOR := Color(0.55, 0.9, 0.5)
const PENALTY_COLOR := Color(1.0, 0.3, 0.3)
const POP_SCALE := 1.5
const POP_TIME := 0.3

const PREVIEW_COLOR := Color(1, 1, 1, 0.55)

## Bumped on every play so an older tally stops when a new dish is served.
var _generation := 0
var _playing := false
var _showing_preview := false


func is_playing() -> bool:
	return _playing


## Lists what the dish in progress would score if served now (no animation).
## `result` null clears a shown preview. Never interrupts a tally that is playing.
func show_preview(result: ScoreResult, money: int) -> void:
	if _playing:
		return
	if result == null:
		if _showing_preview:
			clear()
		return
	clear()
	_showing_preview = true
	_add_label("If served now", PREVIEW_COLOR, 14)
	for line in result.lines:
		_add_line(line)
	_add_label("%.1f chips × %.1f mult" % [result.chips, result.mult], Color(1, 1, 1, 0.7), 14)
	_add_label("≈ %d pts   +$%d" % [result.score, money], SCORE_COLOR, 18)


func play(dish: Dish) -> void:
	clear()
	_playing = true
	var generation := _generation
	var result := dish.result

	_add_label(result.recipe_name if result.recipe_name != "" else dish.display_name(), Color.WHITE, 18)
	var chips := 0.0
	var mult := 1.0
	var running := _add_label("", Color(1, 1, 1, 0.7), 14)
	for line in result.lines:
		if not await _wait(LINE_DELAY, generation):
			return
		match line.kind:
			ScoreResult.Kind.CHIPS:
				chips += line.value
			ScoreResult.Kind.MULT:
				mult += line.value
			ScoreResult.Kind.X_MULT:
				mult *= line.value
		_add_line(line)
		line_played.emit(line)
		move_child(running, get_child_count() - 1)
		running.text = "%.1f chips × %.1f mult" % [chips, maxf(mult, result.min_mult)]

	if not await _wait(RESULT_DELAY, generation):
		return
	var final := _add_label("= %d pts   +$%d" % [result.score, result.money], SCORE_COLOR, 20)
	_playing = false
	finished.emit()
	_pop(final)


## Scales a label up and back down around its center.
func _pop(label: Label) -> void:
	await get_tree().process_frame  # let the container size it first
	if not is_instance_valid(label):
		return
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2(POP_SCALE, POP_SCALE)
	label.create_tween().tween_property(label, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Text and color for one breakdown line (shared by the tally, the preview and callouts).
static func line_text(line: Dictionary) -> String:
	match line.kind:
		ScoreResult.Kind.CHIPS:
			return "+%.1f  %s" % [line.value, line.label]
		ScoreResult.Kind.MULT:
			return "%s%.1f  %s" % ["+" if line.value >= 0 else "−", absf(line.value), line.label]
		ScoreResult.Kind.X_MULT:
			return "×%.2f  %s" % [line.value, line.label]
		ScoreResult.Kind.MONEY:
			return "+$%d  %s" % [line.value, line.label]
	return line.label


static func line_color(line: Dictionary) -> Color:
	match line.kind:
		ScoreResult.Kind.CHIPS:
			return CHIPS_COLOR
		ScoreResult.Kind.MULT:
			return MULT_COLOR if line.value >= 0 else PENALTY_COLOR
		ScoreResult.Kind.X_MULT:
			return X_MULT_COLOR
		ScoreResult.Kind.MONEY:
			return MONEY_COLOR
	return Color.WHITE


func _add_line(line: Dictionary) -> Label:
	return _add_label(line_text(line), line_color(line))


func _wait(seconds: float, generation: int) -> bool:
	await get_tree().create_timer(seconds).timeout
	return generation == _generation and is_inside_tree()


func _add_label(text: String, color: Color, font_size: int = 13) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.clip_text = true
	add_child(label)
	return label


## Removes the tally and stops one that is still playing.
func clear() -> void:
	_generation += 1
	_playing = false
	_showing_preview = false
	for child in get_children():
		child.queue_free()
