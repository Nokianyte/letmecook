extends Node
## Autoload "RunState": the single source of truth for the current run.
## Scenes read from it and change it through the rules functions.

signal changed
signal phase_changed
signal dish_served(dish: Dish)
signal day_closed

enum Phase { KITCHEN, NIGHT, RUN_OVER }

const GAME_DATA: GameData = preload("res://data/game_data.tres")

var data: GameData = GAME_DATA
var balance: Balance = GAME_DATA.balance

var rng := RandomNumberGenerator.new()
var run_seed: int = 0
var phase: Phase = Phase.KITCHEN

var day: int = 1
var money: int = 0
var pantry: Array[IngredientUnit] = []
var fridge_slots: int = 0
var has_blender: bool = false
## Dishes served during the current day, oldest first.
var served_today: Array[Dish] = []
var day_score: int = 0
var total_score: int = 0

## The day that just closed: {"day", "score", "rent"}; shown at night and on the run-over screen.
var last_day: Dictionary = {}
## Units that spoiled during the last night, for the next morning's notice.
var spoiled_overnight: Array[IngredientUnit] = []
var run_won: bool = false

## Tonight's market, and the smoothie bar (empty until the blender is owned).
var shop_stock: Array[ShopOffer] = []
var smoothie_stock: Array[ShopOffer] = []
var rerolls_tonight: int = 0
## Staple id -> units still for sale tonight.
var staples_left: Dictionary = {}

## Kitchen Gadgets in counter order; null is an empty slot.
var counter: Array[Gadget] = []
var gadget_offers: Array[GadgetOffer] = []

var _ingredients_by_id: Dictionary = {}


func _ready() -> void:
	for ingredient in data.ingredients:
		assert(not _ingredients_by_id.has(ingredient.id), "Duplicate ingredient id: %s" % ingredient.id)
		_ingredients_by_id[ingredient.id] = ingredient
	new_run()


## Starts a fresh run. Pass a seed to replay a specific run; omit it for a random one.
func new_run(p_seed: int = -1) -> void:
	run_seed = p_seed if p_seed >= 0 else randi()
	rng.seed = run_seed

	day = 1
	money = balance.starting_money
	fridge_slots = balance.starting_fridge_slots
	has_blender = false
	served_today.clear()
	day_score = 0
	total_score = 0
	last_day = {}
	spoiled_overnight.clear()
	run_won = false
	shop_stock.clear()
	smoothie_stock.clear()
	rerolls_tonight = 0
	staples_left = {}
	counter.clear()
	counter.resize(balance.counter_slots)
	gadget_offers.clear()
	pantry.clear()
	for id in balance.starting_pantry:
		add_units(id, balance.starting_pantry[id])
	_set_phase(Phase.KITCHEN)


func get_ingredient(id: StringName) -> Ingredient:
	assert(_ingredients_by_id.has(id), "Unknown ingredient id: %s" % id)
	return _ingredients_by_id[id]


func add_units(id: StringName, count: int, freshness: float = 1.0) -> void:
	var ingredient := get_ingredient(id)
	for i in count:
		pantry.append(IngredientUnit.new(ingredient, freshness))
	changed.emit()


func remove_unit(unit: IngredientUnit) -> void:
	pantry.erase(unit)
	changed.emit()


## Puts a unit taken out of the pantry back, unchanged (e.g. when clearing a container).
func return_unit(unit: IngredientUnit) -> void:
	assert(not pantry.has(unit))
	pantry.append(unit)
	changed.emit()


func count_of(id: StringName) -> int:
	return pantry.filter(func(u: IngredientUnit) -> bool: return u.ingredient.id == id).size()


func rent_today() -> int:
	return balance.rent_for_day(day)


func is_last_day() -> bool:
	return day >= balance.days_per_run


# --- Kitchen -------------------------------------------------------------------

## Serves a finished dish: scores it and pays for it right away.
func serve(dish: Dish) -> ScoreResult:
	dish.result = Scoring.score_dish(dish, data, counter)
	served_today.append(dish)
	day_score += dish.result.score
	total_score += dish.result.score
	dish.result.money = money_for(dish.result.score)
	for gadget in counter:
		if gadget != null:
			var tip := gadget.on_dish_served(dish)
			if tip > 0:
				dish.result.add_money(gadget.display_name, tip, gadget.id)
	money += dish.result.money
	dish_served.emit(dish)
	changed.emit()
	return dish.result


func money_for(score: int) -> int:
	return floori(score * balance.score_to_money)


## Ends the kitchen phase and settles rent: on to the night, or the run ends
## (missed rent, or rent paid on the last day).
func close_day() -> void:
	var rent := rent_today()
	last_day = {"day": day, "score": day_score, "rent": rent}
	served_today.clear()
	day_score = 0
	day_closed.emit()

	if money < rent:
		run_won = false
		_set_phase(Phase.RUN_OVER)
		return
	money -= rent
	if is_last_day():
		run_won = true
		_set_phase(Phase.RUN_OVER)
		return
	rerolls_tonight = 0
	staples_left = balance.staple_stock.duplicate()
	shop_stock = Shop.roll_stock(rng, data)
	gadget_offers = Shop.roll_gadget_offers(rng, data, counter)
	smoothie_stock.clear()
	if has_blender:
		smoothie_stock = Shop.roll_smoothie_stock(rng, data)
	_set_phase(Phase.NIGHT)


# --- Night ----------------------------------------------------------------------

func buy_offer(offer: ShopOffer) -> bool:
	if offer.sold or money < offer.price:
		return false
	money -= offer.price
	offer.sold = true
	add_units(offer.ingredient.id, offer.quantity, offer.freshness)
	return true


## Staples are on sale every night, one unit per purchase, up to the nightly stock.
func buy_staple(id: StringName) -> bool:
	var ingredient := get_ingredient(id)
	if not balance.staple_ids.has(id) or staples_left.get(id, 0) <= 0 or money < ingredient.price:
		return false
	money -= ingredient.price
	staples_left[id] -= 1
	add_units(id, 1)
	return true


func reroll_cost() -> int:
	var cost := Shop.reroll_cost(balance, rerolls_tonight)
	for gadget in counter:
		if gadget != null:
			cost = gadget.modify_reroll_cost(cost, rerolls_tonight)
	return cost


func reroll_shop() -> bool:
	var cost := reroll_cost()
	if money < cost:
		return false
	money -= cost
	rerolls_tonight += 1
	Shop.reroll(shop_stock, rng, data)
	Shop.reroll_smoothie(smoothie_stock, rng, data)
	Shop.reroll_gadget_offers(gadget_offers, rng, data, counter)
	changed.emit()
	return true


# --- Kitchen Gadgets ---------------------------------------------------------------

## Index of the leftmost empty counter slot, or -1 when the counter is full.
func free_slot() -> int:
	return counter.find(null)


func buy_gadget(offer: GadgetOffer) -> bool:
	var slot := free_slot()
	if offer.sold or slot < 0 or money < offer.gadget.price:
		return false
	money -= offer.gadget.price
	offer.sold = true
	counter[slot] = offer.gadget
	changed.emit()
	return true


func sell_price(gadget: Gadget) -> int:
	return floori(gadget.price / 2.0)


## Sells the gadget in `slot` for half its price (night only).
func sell_gadget(slot: int) -> bool:
	if phase != Phase.NIGHT or slot < 0 or slot >= counter.size() or counter[slot] == null:
		return false
	money += sell_price(counter[slot])
	counter[slot] = null
	changed.emit()
	return true


## Moves the gadget in slot `from` to slot `to`; the ones in between shift over.
func move_gadget(from: int, to: int) -> void:
	if from == to or from < 0 or to < 0 or from >= counter.size() or to >= counter.size():
		return
	var gadget := counter[from]
	counter.remove_at(from)
	counter.insert(to, gadget)
	changed.emit()


func blender_on_sale() -> bool:
	return not has_blender


func buy_blender() -> bool:
	if has_blender or money < balance.blender_price:
		return false
	money -= balance.blender_price
	has_blender = true
	# The smoothie bar opens right away.
	if phase == Phase.NIGHT:
		smoothie_stock = Shop.roll_smoothie_stock(rng, data)
	changed.emit()
	return true


func fridge_upgrade_on_sale() -> bool:
	return fridge_slots < balance.fridge_max_slots


func buy_fridge_upgrade() -> bool:
	if not fridge_upgrade_on_sale() or money < balance.fridge_upgrade_price:
		return false
	money -= balance.fridge_upgrade_price
	fridge_slots = mini(fridge_slots + balance.fridge_upgrade_slots, balance.fridge_max_slots)
	changed.emit()
	return true


func fridge_used() -> int:
	return pantry.filter(func(u: IngredientUnit) -> bool: return u.in_fridge).size()


## Moves a unit into or out of the fridge. False if the fridge is full.
func set_in_fridge(unit: IngredientUnit, in_fridge: bool) -> bool:
	if in_fridge and not unit.in_fridge and fridge_used() >= fridge_slots:
		return false
	unit.in_fridge = in_fridge
	changed.emit()
	return true


## Ends the night: everything decays (less in the fridge), spoiled units are thrown
## out, and the next day's kitchen opens.
func end_night() -> void:
	spoiled_overnight = Freshness.apply_night(pantry, balance)
	shop_stock.clear()
	smoothie_stock.clear()
	gadget_offers.clear()
	day += 1
	_set_phase(Phase.KITCHEN)


func _set_phase(p_phase: Phase) -> void:
	phase = p_phase
	changed.emit()
	phase_changed.emit()
