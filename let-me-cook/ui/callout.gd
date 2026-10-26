extends Label
## A short floating text ("+8 Patty", "+0.5 Melt!") that rises and fades out.

const RISE := 42.0
const DURATION := 0.9
## Emphasized callouts (mult, new combos) pop in from this scale and stay a bit longer.
const POP_SCALE := 1.6
const EMPHASIS_DURATION := 1.4


func _init(text_value: String, color: Color, font_size: int = 16) -> void:
	text = text_value
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_color_override("font_color", color)
	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_theme_constant_override("outline_size", 5 if font_size < 22 else 8)


## Shows the callout after `delay` seconds: centered above `at`, or starting at `at` and
## vertically centered on it when `beside` (used for callouts next to a layer).
## `emphasis` pops it in from a bigger scale and keeps it up longer.
func pop(at: Vector2, delay: float, beside: bool = false, emphasis: bool = false) -> void:
	modulate.a = 0.0
	var size := get_minimum_size()
	global_position = at - (Vector2(0, size.y * 0.5) if beside else Vector2(size.x * 0.5, size.y))
	pivot_offset = size * 0.5
	var duration := EMPHASIS_DURATION if emphasis else DURATION
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(self, "position:y", position.y - RISE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if emphasis:
		scale = Vector2(POP_SCALE, POP_SCALE)
		tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
