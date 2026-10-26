extends VBoxContainer
## Today's specials: recipe cards with their value (with the player's gadgets) and
## progress ticks for the dish in progress.

const CARD_SIZE := Vector2(214, 0)
const DONE_COLOR := "#7ee07e"
const TODO_COLOR := "#ffffff8c"
const NAME_COLOR := Color(1.0, 0.85, 0.35)
## Fixed height: the strip must never resize while a burger is being built, or the board
## (and its physics stage) below it would shift.
const STRIP_HEIGHT := 78.0
const INGREDIENTS_HEIGHT := 34.0

var _cards: Array[PanelContainer] = []
var _ingredient_labels: Array[RichTextLabel] = []
var _normal_style := StyleBoxFlat.new()
var _matched_style := StyleBoxFlat.new()
var _last_dish: Dish = null
## What the cards were built from (specials and gadget order); rebuild only when it changes.
var _built_for := ""


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	_normal_style.bg_color = Color(0.13, 0.13, 0.16)
	_normal_style.set_content_margin_all(6)
	_matched_style.bg_color = Color(0.2, 0.18, 0.1)
	_matched_style.set_border_width_all(2)
	_matched_style.border_color = NAME_COLOR
	_matched_style.set_content_margin_all(6)
	custom_minimum_size.y = STRIP_HEIGHT
	RunState.changed.connect(_rebuild_if_changed)
	_rebuild()


func _rebuild_if_changed() -> void:
	if _signature() != _built_for:
		_rebuild()


func _signature() -> String:
	var parts: Array[String] = []
	for recipe in RunState.specials:
		parts.append(recipe.display_name)
	for gadget in RunState.counter:
		parts.append(str(gadget.id) if gadget != null else "-")
	return "|".join(parts)


## Ticks the ingredients `dish` already has and highlights specials it matches.
func show_progress(dish: Dish) -> void:
	_last_dish = dish
	var specials := RunState.specials
	for i in mini(specials.size(), _cards.size()):
		var recipe := specials[i]
		var done := Specials.progress(recipe, dish)
		var parts: Array[String] = []
		for j in recipe.example.size():
			var name := RunState.get_ingredient(recipe.example[j]).display_name
			parts.append("[color=%s]%s[/color]" % [DONE_COLOR if done[j] else TODO_COLOR, name])
		_ingredient_labels[i].text = " · ".join(parts)
		var matched := dish != null and Scoring.matches(recipe, dish, RunState.data)
		_cards[i].add_theme_stylebox_override("panel", _matched_style if matched else _normal_style)


func _rebuild() -> void:
	_built_for = _signature()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_cards.clear()
	_ingredient_labels.clear()

	var title := Label.new()
	title.text = "Today's specials"
	title.add_theme_font_size_override("font_size", 14)
	title.modulate.a = 0.75
	add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

	for recipe in RunState.specials:
		var value := Specials.value(recipe, RunState.data, RunState.counter)
		var money := Specials.expected_money(value.score, Specials.example_dish(recipe, RunState.data), RunState.balance, RunState.counter)
		var card := PanelContainer.new()
		card.custom_minimum_size = CARD_SIZE
		card.tooltip_text = "%s: +%.1f mult. Worth about %d pts ($%d) built fresh, with your gadgets." % [
			recipe.display_name, recipe.mult_bonus, value.score, money]
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		card.add_child(box)
		var header := HBoxContainer.new()
		box.add_child(header)
		var name_label := Label.new()
		name_label.text = recipe.display_name
		name_label.add_theme_color_override("font_color", NAME_COLOR)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(name_label)
		var value_label := Label.new()
		value_label.text = "%d pts · $%d" % [value.score, money]
		value_label.add_theme_font_size_override("font_size", 13)
		header.add_child(value_label)
		var ingredients := RichTextLabel.new()
		ingredients.bbcode_enabled = true
		# Fixed height (two lines), not fit_content: re-fitting new text collapses the label
		# for a frame, which would shift the board below mid-build.
		ingredients.custom_minimum_size.y = INGREDIENTS_HEIGHT
		ingredients.scroll_active = false
		ingredients.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ingredients.add_theme_font_size_override("normal_font_size", 12)
		box.add_child(ingredients)
		row.add_child(card)
		_cards.append(card)
		_ingredient_labels.append(ingredients)
	show_progress(_last_dish)
