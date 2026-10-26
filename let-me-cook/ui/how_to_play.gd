extends CanvasLayer
## Rules reference card: every rule on one page. Opened from the "?" menu
## (anything can open it with get_tree().call_group("how_to_play", "open")).

const TEXT := """[font_size=28][b]Let me cook![/b][/font_size]
You're broke. Build dishes from what you can afford, serve them, and make rent for 7 days.

[b]Building a burger[/b]
• Drag ingredients from the pantry onto the plate. The newest layer has a white outline: drag it again to adjust it, or off the board to take it back. It locks once you pick up the next thing.
• Off-center layers lower [b]stability[/b]. Below 0% the burger collapses and the food is lost.
• Hold a sauce bottle over the burger to pour. The next layer squashes the sauce into its own layer.
• [b]Serve[/b] sends the dish out and scores it right away.

[b]Scoring: chips × mult[/b]
• [color=#8cc7ff]Chips[/color]: each ingredient's value × its freshness.
• [color=#ff8c73]Mult[/color]: combos, ways of stacking ingredients (bun at bottom and top, cheese touching patty, sauce on a patty…). Several combos add up. The combo board above the plate lists the ones you know; build new arrangements to discover more. Some combos are penalties, like sauce right on the bottom bun.
• Every point pays money.

[b]Kitchen Gadgets[/b]
Bought at night, kept on a counter with 3 slots. They apply [b]left to right[/b], so order matters: add mult first, then ×mult. Drag cards to reorder; sell at night for half price.

[b]Rent and nights[/b]
• [b]Close for the day[/b] pays rent. Can't pay? Evicted.
• At night: buy ingredients (bundles are cheaper), staples (restocked nightly), tools and gadgets; reroll the market for new stock.
• Anything outside the fridge loses freshness overnight; at 0% it spoils.

[b]Smoothies[/b] (after buying the blender)
Drop ingredients in the jar. Aim for 30–60% liquid, pair flavors that go together, and avoid clashing colors that turn muddy. Smoothies have their own combos.

[color=#ffffff80]F1: debug panel (money, skip day, seed).[/color]"""

var _root: Control


func _ready() -> void:
	layer = 50
	add_to_group("how_to_play")
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.08, 0.1, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 600)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.text = TEXT
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("normal_font_size", 16)
	text.add_theme_font_size_override("bold_font_size", 16)
	box.add_child(text)

	var close := Button.new()
	close.text = "Close"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(close_screen)
	box.add_child(close)
	close_screen()


func open() -> void:
	_root.visible = true


func close_screen() -> void:
	_root.visible = false


func is_open() -> bool:
	return _root.visible
