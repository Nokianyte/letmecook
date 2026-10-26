class_name Shop
## Nightly market rules: random stock (from the run's seeded RNG) and rerolls.
## Two sections: the market (burger ingredients) and, once the blender is owned,
## the smoothie bar (smoothie ingredients).

const MAX_SOLID_QUANTITY := 3


## Ingredients a section can roll. Staples are never rolled: they are always on sale.
static func pool(data: GameData, station: Dish.Station) -> Array[Ingredient]:
	var result: Array[Ingredient] = []
	for ingredient in data.ingredients:
		if data.balance.staple_ids.has(ingredient.id):
			continue
		var fits := ingredient.burger_ok if station == Dish.Station.BURGER else ingredient.smoothie_ok
		if fits:
			result.append(ingredient)
	return result


## The pool for the guaranteed first slot; falls back to the whole pool if nothing has the tag.
static func guaranteed_pool(ingredients: Array[Ingredient], tag: StringName) -> Array[Ingredient]:
	if tag == &"":
		return ingredients
	var tagged: Array[Ingredient] = []
	for ingredient in ingredients:
		if ingredient.has_tag(tag):
			tagged.append(ingredient)
	return tagged if not tagged.is_empty() else ingredients


## Sauces come as one full bottle; solids in batches of 1..max_quantity.
static func roll_offer(rng: RandomNumberGenerator, ingredients: Array[Ingredient], bulk_discount: float, max_quantity: int = MAX_SOLID_QUANTITY) -> ShopOffer:
	var ingredient := ingredients[rng.randi_range(0, ingredients.size() - 1)]
	var quantity := 1 if ingredient.is_sauce() else rng.randi_range(1, max_quantity)
	return ShopOffer.new(ingredient, quantity, 1.0, bulk_discount)


## The market. Its first slot is the guarantee: always a single unit with the
## guaranteed tag (meat), so it stays affordable.
static func roll_stock(rng: RandomNumberGenerator, data: GameData) -> Array[ShopOffer]:
	var stock: Array[ShopOffer] = []
	for i in data.balance.shop_stock_slots:
		stock.append(_roll_market_slot(i, rng, data))
	return stock


static func roll_smoothie_stock(rng: RandomNumberGenerator, data: GameData) -> Array[ShopOffer]:
	var ingredients := pool(data, Dish.Station.SMOOTHIE)
	var stock: Array[ShopOffer] = []
	for i in data.balance.smoothie_stock_slots:
		stock.append(roll_offer(rng, ingredients, data.balance.bulk_discount_per_extra_unit))
	return stock


## Restocks every market slot, sold ones included (bought items stay with the player).
static func reroll(stock: Array[ShopOffer], rng: RandomNumberGenerator, data: GameData) -> void:
	for i in stock.size():
		stock[i] = _roll_market_slot(i, rng, data)


static func reroll_smoothie(stock: Array[ShopOffer], rng: RandomNumberGenerator, data: GameData) -> void:
	var ingredients := pool(data, Dish.Station.SMOOTHIE)
	for i in stock.size():
		stock[i] = roll_offer(rng, ingredients, data.balance.bulk_discount_per_extra_unit)


## Tonight's gadget offers: different gadgets the player doesn't own.
static func roll_gadget_offers(rng: RandomNumberGenerator, data: GameData, counter: Array[Gadget]) -> Array[GadgetOffer]:
	var available := data.gadgets.filter(func(g: Gadget) -> bool: return not counter.has(g))
	var offers: Array[GadgetOffer] = []
	for i in mini(data.balance.gadget_offer_slots, available.size()):
		var pick: int = rng.randi_range(0, available.size() - 1)
		offers.append(GadgetOffer.new(available[pick]))
		available.remove_at(pick)
	return offers


## Replaces every gadget offer, sold ones included, with a fresh draw of unowned gadgets.
static func reroll_gadget_offers(offers: Array[GadgetOffer], rng: RandomNumberGenerator, data: GameData, counter: Array[Gadget]) -> void:
	var fresh := roll_gadget_offers(rng, data, counter)
	offers.clear()
	offers.append_array(fresh)


static func reroll_cost(balance: Balance, rerolls_tonight: int) -> int:
	return balance.reroll_base_cost + balance.reroll_cost_step * rerolls_tonight


static func _roll_market_slot(slot: int, rng: RandomNumberGenerator, data: GameData) -> ShopOffer:
	var ingredients := pool(data, Dish.Station.BURGER)
	if slot == 0:
		return roll_offer(rng, guaranteed_pool(ingredients, data.balance.guaranteed_slot_tag), data.balance.bulk_discount_per_extra_unit, 1)
	return roll_offer(rng, ingredients, data.balance.bulk_discount_per_extra_unit)
