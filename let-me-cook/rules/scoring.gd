class_name Scoring
## Balatro-style dish scoring: score = chips × mult.
## Chips come from ingredient quality (base × freshness × amount); mult from how
## cleverly they were combined (structure, adjacency, named recipes).


## `counter` is the run's gadgets in counter order (empty slots are null).
static func score_dish(dish: Dish, data: GameData, counter: Array[Gadget] = []) -> ScoreResult:
	var balance := data.balance
	var result := ScoreResult.new()

	for layer in dish.layers:
		result.add_chips(_chips_label(layer), layer.chips())

	if dish.station == Recipe.Station.BURGER:
		_burger_rules(dish, balance, result)
	else:
		_smoothie_rules(dish, balance, result)

	var recipe := best_recipe(dish, data)
	if recipe != null:
		result.recipe_name = recipe.display_name
		result.add_mult(recipe.display_name, recipe.mult_bonus)

	for gadget in counter:
		if gadget != null:
			gadget.modify_score(dish, result)

	result.min_mult = balance.min_mult
	result.mult = maxf(result.mult, balance.min_mult)
	result.score = roundi(result.chips * result.mult)
	return result


## The matching recipe with the biggest bonus, or null. Only one recipe counts per dish.
static func best_recipe(dish: Dish, data: GameData) -> Recipe:
	var best: Recipe = null
	for recipe in data.recipes:
		if matches(recipe, dish, data) and (best == null or recipe.mult_bonus > best.mult_bonus):
			best = recipe
	return best


static func matches(recipe: Recipe, dish: Dish, data: GameData) -> bool:
	if recipe.station != dish.station:
		return false
	var lists_sauce := false
	for ingredient in data.ingredients:
		if ingredient.is_sauce() and recipe.ingredients.has(ingredient.id):
			lists_sauce = true
	# Sauce layers are ignored unless the recipe asks for a sauce.
	var ids: Array[StringName] = []
	for layer in dish.layers:
		if lists_sauce or not layer.ingredient.is_sauce():
			ids.append(layer.ingredient.id)

	match recipe.match_mode:
		Recipe.MatchMode.ORDERED_EXACT:
			return ids == recipe.ingredients
		Recipe.MatchMode.ONLY_THESE:
			for id in ids:
				if not recipe.ingredients.has(id):
					return false
			for id in recipe.ingredients:
				if not ids.has(id):
					return false
			return true
		Recipe.MatchMode.CONTAINS:
			for id in recipe.ingredients:
				if not ids.has(id):
					return false
			return true
	return false


static func _burger_rules(dish: Dish, balance: Balance, result: ScoreResult) -> void:
	var layers := dish.layers
	if layers.is_empty():
		return
	if has_bun_ends(dish):
		result.add_mult("Bun on both ends", balance.structure_bonus)

	for i in melt_count(dish):
		result.add_mult("Melt: cheese on patty", balance.melt_bonus)

	if layers.size() >= 2 and layers[0].ingredient.has_tag(&"bun") and layers[1].ingredient.is_sauce():
		result.add_mult("Soggy bottom", -balance.soggy_penalty)


## A burger with a bun-tagged solid at the bottom and at the top.
static func has_bun_ends(dish: Dish) -> bool:
	if dish.station != Recipe.Station.BURGER:
		return false
	var solids := dish.layers.filter(func(l: DishLayer) -> bool: return not l.ingredient.is_sauce())
	return solids.size() >= 2 and solids.front().ingredient.has_tag(&"bun") and solids.back().ingredient.has_tag(&"bun")


## Cheese and patty layers directly touching (sauce between them breaks the melt).
static func melt_count(dish: Dish) -> int:
	var n := 0
	for i in range(1, dish.layers.size()):
		var below := dish.layers[i - 1].ingredient
		var above := dish.layers[i].ingredient
		if (below.has_tag(&"cheese") and above.has_tag(&"patty")) or (below.has_tag(&"patty") and above.has_tag(&"cheese")):
			n += 1
	return n


static func _smoothie_rules(dish: Dish, balance: Balance, result: ScoreResult) -> void:
	var ingredients: Array[Ingredient] = []
	for layer in dish.layers:
		ingredients.append(layer.ingredient)
	var ratio := Smoothie.liquid_ratio(ingredients)
	if ratio >= balance.ratio_min and ratio <= balance.ratio_max:
		result.add_mult("Good thickness", balance.ratio_bonus)
	for pair in Smoothie.flavor_pairs(ingredients):
		result.add_mult("Pair: %s" % pair, balance.flavor_pair_bonus)
	if Smoothie.is_muddy(ingredients, balance):
		result.add_mult("Muddy color", -balance.muddy_penalty)


static func _chips_label(layer: DishLayer) -> String:
	var fresh := roundi(layer.freshness * 100)
	if layer.ingredient.is_sauce():
		return "%s ×%d (%d%%)" % [layer.ingredient.display_name, layer.amount, fresh]
	return "%s (%d%%)" % [layer.ingredient.display_name, fresh]

