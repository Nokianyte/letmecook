extends Label
## A short floating text ("+8 Patty", "+0.5 Melt!") that rises and fades out.

const RISE := 42.0
const DURATION := 0.9


func _init(text_value: String, color: Color, font_size: int = 16) -> void:
	text = text_value
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_color_override("font_color", color)
	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_theme_constant_override("outline_size", 5)


## Shows the callout after `delay` seconds: centered above `at`, or starting at `at` and
## vertically centered on it when `beside` (used for callouts next to a layer).
func pop(at: Vector2, delay: float, beside: bool = false) -> void:
	modulate.a = 0.0
	var size := get_minimum_size()
	global_position = at - (Vector2(0, size.y * 0.5) if beside else Vector2(size.x * 0.5, size.y))
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(self, "position:y", position.y - RISE, DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
