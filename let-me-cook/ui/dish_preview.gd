class_name DishPreview
extends Control
## A miniature of a served dish.

const PREVIEW_SIZE := Vector2(200, 110)
const MINI_SCALE := 0.45
## Height kept clear for the title at the top.
const TITLE_SPACE := 26.0

var dish: Dish


func _init(p_dish: Dish) -> void:
	dish = p_dish
	custom_minimum_size = PREVIEW_SIZE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.24, 0.24, 0.28))
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.15), false, 1.0)
	var title := dish.display_name()
	if dish.result != null:
		title = "%s · %d" % [title, dish.result.score]
	draw_string(ThemeDB.fallback_font, Vector2(8, 18), title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	if dish.station == Dish.Station.SMOOTHIE:
		var ingredients: Array[Ingredient] = []
		for layer in dish.layers:
			ingredients.append(layer.ingredient)
		var cup := Rect2(size.x * 0.5 - 22, size.y - 78, 44, 70)
		draw_rect(cup, Smoothie.blend_color(ingredients))
		draw_rect(cup, Color(1, 1, 1, 0.4), false, 1.0)
		return

	var minis: Array[Vector2] = []
	var width := 0.0
	var height := 0.0
	for layer in dish.layers:
		var mini: Vector2
		if layer.ingredient.is_sauce():
			# Sauce: a band under the next layer, thicker with more doses.
			mini = Vector2(maxf(width, 60.0) * 0.9, minf(2.0 + layer.amount * 0.1, 5.0))
		else:
			mini = layer.ingredient.size * MINI_SCALE
			width = mini.x
		minis.append(mini)
		height += mini.y
	# Tall burgers shrink to fit below the title.
	var fit := minf(1.0, (size.y - TITLE_SPACE - 8) / maxf(height, 1.0))
	var y := size.y - 8
	for i in minis.size():
		var mini := minis[i] * fit
		y -= mini.y
		draw_rect(Rect2(Vector2(size.x * 0.5 - mini.x * 0.5, y), mini), dish.layers[i].ingredient.color)
