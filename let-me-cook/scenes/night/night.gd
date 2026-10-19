extends Control
## Night phase: shop the market, buy staples and tools, choose what goes in the fridge,
## then open the kitchen for the next day.

const CARD_SIZE := Vector2(150, 0)
const SWATCH_SIZE := Vector2(0, 22)
const UNIT_BUTTON_SIZE := Vector2(132, 34)

@onready var _title_label: Label = %TitleLabel
@onready var _money_label: Label = %MoneyLabel
@onready var _next_rent_label: Label = %NextRentLabel
@onready var _open_button: Button = %OpenButton
@onready var _summary_label: Label = %SummaryLabel
@onready var _reroll_button: Button = %RerollButton
@onready var _stock: HFlowContainer = %Stock
@onready var _gadget_offers: HFlowContainer = %GadgetOffers
@onready var _smoothie_title: Label = %SmoothieTitle
@onready var _smoothie_stock: HFlowContainer = %SmoothieStock
@onready var _staples: HFlowContainer = %Staples
@onready var _tools: HFlowContainer = %Tools
@onready var _fridge_title: Label = %FridgeTitle
@onready var _fridge: HFlowContainer = %Fridge
@onready var _pantry_units: HFlowContainer = %PantryUnits


func _ready() -> void:
	RunState.changed.connect(_refresh)
	_open_button.pressed.connect(RunState.end_night)
	_reroll_button.pressed.connect(RunState.reroll_shop)
	_refresh()


func _refresh() -> void:
	if RunState.phase != RunState.Phase.NIGHT:
		return
	var day: int = RunState.last_day.get("day", RunState.day)
	_title_label.text = "Night %d" % day
	_money_label.text = "$%d" % RunState.money
	_next_rent_label.text = "Tomorrow's rent: $%d" % RunState.balance.rent_for_day(RunState.day + 1)
	_open_button.text = "Open the kitchen (day %d)" % (RunState.day + 1)
	_summary_label.text = "Day %d: %d pts, rent $%d paid. Anything outside the fridge loses freshness overnight." % [
		day, RunState.last_day.get("score", 0), RunState.last_day.get("rent", 0)]

	var cost := RunState.reroll_cost()
	_reroll_button.text = "Reroll $%d" % cost
	_reroll_button.disabled = RunState.money < cost

	_clear(_stock)
	for offer in RunState.shop_stock:
		_stock.add_child(_offer_card(offer))

	_clear(_gadget_offers)
	for offer in RunState.gadget_offers:
		_gadget_offers.add_child(_gadget_card(offer))
	if RunState.gadget_offers.is_empty():
		_gadget_offers.add_child(_dim_label("You own every gadget"))

	_smoothie_title.visible = RunState.has_blender
	_smoothie_stock.visible = RunState.has_blender
	_clear(_smoothie_stock)
	for offer in RunState.smoothie_stock:
		_smoothie_stock.add_child(_offer_card(offer))

	_clear(_staples)
	for id in RunState.balance.staple_ids:
		_staples.add_child(_staple_card(RunState.get_ingredient(id)))

	_clear(_tools)
	if RunState.blender_on_sale():
		_tools.add_child(_card("Blender", "Unlocks smoothies", Color(0.6, 0.75, 0.9),
				"Buy $%d" % RunState.balance.blender_price, RunState.money >= RunState.balance.blender_price,
				RunState.buy_blender))
	if RunState.fridge_upgrade_on_sale():
		_tools.add_child(_card("Bigger fridge", "+%d slots (max %d)" % [RunState.balance.fridge_upgrade_slots, RunState.balance.fridge_max_slots],
				Color(0.8, 0.85, 0.9), "Buy $%d" % RunState.balance.fridge_upgrade_price,
				RunState.money >= RunState.balance.fridge_upgrade_price, RunState.buy_fridge_upgrade))
	if _tools.get_child_count() == 0:
		_tools.add_child(_dim_label("Nothing left to buy"))

	_fridge_title.text = "Fridge %d/%d (click to take out)" % [RunState.fridge_used(), RunState.fridge_slots]
	_clear(_fridge)
	_clear(_pantry_units)
	var fridge_full := RunState.fridge_used() >= RunState.fridge_slots
	for unit in _sorted_units():
		if unit.in_fridge:
			_fridge.add_child(_unit_button(unit, false))
		else:
			_pantry_units.add_child(_unit_button(unit, fridge_full))
	if _fridge.get_child_count() == 0:
		_fridge.add_child(_dim_label("Empty"))
	if _pantry_units.get_child_count() == 0:
		_pantry_units.add_child(_dim_label("Nothing outside the fridge"))


func _offer_card(offer: ShopOffer) -> Control:
	var ingredient := offer.ingredient
	var name := ingredient.display_name if offer.quantity == 1 else "%s ×%d" % [ingredient.display_name, offer.quantity]
	var detail := "%d%% fresh" % roundi(offer.freshness * 100)
	if ingredient.is_sauce():
		detail = "bottle, %d doses · %s" % [ingredient.doses, detail]
	if offer.sold:
		return _card(name, detail, ingredient.color, "Sold", false, Callable())
	var buy := "Buy $%d" % offer.price
	if offer.full_price > offer.price:
		buy += " (save $%d)" % (offer.full_price - offer.price)
	return _card(name, detail, ingredient.color, buy, RunState.money >= offer.price,
			RunState.buy_offer.bind(offer))


func _gadget_card(offer: GadgetOffer) -> Control:
	var gadget := offer.gadget
	var color := Color(0.85, 0.65, 1.0)
	if offer.sold:
		return _card(gadget.display_name, gadget.description, color, "Sold", false, Callable())
	if RunState.free_slot() < 0:
		return _card(gadget.display_name, gadget.description, color, "Counter full", false, Callable())
	return _card(gadget.display_name, gadget.description, color, "Buy $%d" % gadget.price,
			RunState.money >= gadget.price, RunState.buy_gadget.bind(offer))


func _staple_card(ingredient: Ingredient) -> Control:
	var left: int = RunState.staples_left.get(ingredient.id, 0)
	var detail := "never spoils"
	if ingredient.is_sauce():
		detail = "bottle, %d doses" % ingredient.doses
	detail += " · %d left tonight" % left
	if left <= 0:
		return _card(ingredient.display_name, detail, ingredient.color, "Sold out", false, Callable())
	return _card(ingredient.display_name, detail, ingredient.color, "Buy $%d" % ingredient.price,
			RunState.money >= ingredient.price, RunState.buy_staple.bind(ingredient.id))


func _card(title: String, detail: String, color: Color, button_text: String, enabled: bool, on_buy: Callable) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	var box := VBoxContainer.new()
	panel.add_child(box)

	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = SWATCH_SIZE
	box.add_child(swatch)

	var title_label := Label.new()
	title_label.text = title
	box.add_child(title_label)
	var detail_label := _dim_label(detail)
	detail_label.add_theme_font_size_override("font_size", 12)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail_label)

	var button := Button.new()
	button.text = button_text
	button.disabled = not enabled
	if on_buy.is_valid():
		button.pressed.connect(on_buy)
	box.add_child(button)
	return panel


## Button for one owned unit; clicking moves it into or out of the fridge.
## Shows tomorrow's freshness where it currently is.
func _unit_button(unit: IngredientUnit, fridge_full: bool) -> Button:
	var now := roundi(unit.freshness * 100)
	var tomorrow := roundi(Freshness.forecast(unit, unit.in_fridge, RunState.balance) * 100)
	var button := Button.new()
	button.custom_minimum_size = UNIT_BUTTON_SIZE
	button.text = "%s %d%%" % [unit.ingredient.display_name, now]
	if tomorrow != now:
		button.text += " → %d%%" % tomorrow
	if unit.ingredient.is_sauce():
		button.tooltip_text = "%d/%d doses" % [unit.doses_left, unit.ingredient.doses]
	button.add_theme_color_override("font_color", unit.ingredient.color.lightened(0.3))
	button.disabled = fridge_full and not unit.in_fridge
	button.pressed.connect(RunState.set_in_fridge.bind(unit, not unit.in_fridge))
	return button


## Pantry units grouped by ingredient (data order), freshest first.
func _sorted_units() -> Array[IngredientUnit]:
	var units: Array[IngredientUnit] = []
	for ingredient in RunState.data.ingredients:
		var group := RunState.pantry.filter(func(u: IngredientUnit) -> bool: return u.ingredient == ingredient)
		group.sort_custom(func(a: IngredientUnit, b: IngredientUnit) -> bool: return a.freshness > b.freshness)
		units.append_array(group)
	return units


func _dim_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate.a = 0.6
	return label


## Removes children immediately (not just queued), so emptiness checks right after are correct.
func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
