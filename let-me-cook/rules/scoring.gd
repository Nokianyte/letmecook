class_name Scoring
## Balatro-style dish scoring: score = chips × mult.
## Chips come from ingredient quality (base × freshness × amount); mult from combos,
## the arrangements listed in data/combos (structure, adjacency, sets).


## `counter` is the run's gadgets in counter order (empty slots are null).
static func score_dish(dish: Dish, data: GameData, counter: Array[Gadget] = []) -> ScoreResult:
	var balance := data.balance
	var result := ScoreResult.new()

	for layer in dish.layers:
		result.add_chips(_chips_label(layer), layer.chips())

	for combo in data.combos:
		if combo.station == dish.station:
			_apply_combo(combo, dish, balance, result)

	for gadget in counter:
		if gadget != null:
			gadget.modify_score(dish, result)

	result.min_mult = balance.min_mult
	result.mult = maxf(result.mult, balance.min_mult)
	result.score = roundi(result.chips * result.mult)
	return result


## Combo id -> how many of its lines `result` has.
static func combo_counts(result: ScoreResult) -> Dictionary:
	var counts := {}
	if result == null:
		return counts
	for line in result.lines:
		var id: StringName = line.get("combo", &"")
		if id != &"":
			counts[id] = counts.get(id, 0) + 1
	return counts


## Money a dish with this score would pay, tips included.
static func expected_money(score: int, dish: Dish, balance: Balance, counter: Array[Gadget]) -> int:
	var money := floori(score * balance.score_to_money)
	for gadget in counter:
		if gadget != null:
			money += gadget.on_dish_served(dish)
	return money


static func _apply_combo(combo: Combo, dish: Dish, balance: Balance, result: ScoreResult) -> void:
	var ingredients: Array[Ingredient] = []
	for layer in dish.layers:
		ingredients.append(layer.ingredient)
	match combo.kind:
		Combo.Kind.SEQUENCE:
			for i in sequence_count(combo, ingredients):
				result.add_mult(combo.display_name, combo.mult, &"", combo.id)
		Combo.Kind.SET:
			if _has_set(combo, ingredients):
				result.add_mult(combo.display_name, combo.mult, &"", combo.id)
		Combo.Kind.THICKNESS:
			var ratio := Smoothie.liquid_ratio(ingredients)
			if ratio >= balance.ratio_min and ratio <= balance.ratio_max:
				result.add_mult(combo.display_name, combo.mult, &"", combo.id)
		Combo.Kind.FLAVOR_PAIR:
			for pair in Smoothie.flavor_pairs(ingredients):
				result.add_mult("%s: %s" % [combo.display_name, pair], combo.mult, &"", combo.id)
		Combo.Kind.MUDDY:
			if Smoothie.is_muddy(ingredients, balance):
				result.add_mult(combo.display_name, combo.mult, &"", combo.id)


## How many times a SEQUENCE combo occurs in these layers (bottom to top); at most 1
## unless the combo counts each occurrence.
static func sequence_count(combo: Combo, layers: Array[Ingredient]) -> int:
	if combo.solids_only:
		var solids: Array[Ingredient] = []
		for ingredient in layers:
			if not ingredient.is_sauce():
				solids.append(ingredient)
		layers = solids
	var pattern := combo.pattern
	var n := layers.size()
	var length := pattern.size()
	if length == 0 or n < length:
		return 0
	var count := 0
	match combo.anchor:
		Combo.Anchor.ANYWHERE:
			for i in n - length + 1:
				if _matches_at(combo, layers, i):
					count += 1
		Combo.Anchor.BOTTOM:
			count = 1 if _matches_at(combo, layers, 0) else 0
		Combo.Anchor.TOP:
			count = 1 if _matches_at(combo, layers, n - length) else 0
		Combo.Anchor.WHOLE:
			count = 1 if n == length and _matches_at(combo, layers, 0) else 0
		Combo.Anchor.ENDS:
			var forward := Combo.entry_matches(pattern.front(), layers.front()) and Combo.entry_matches(pattern.back(), layers.back())
			var backward := combo.either_order and Combo.entry_matches(pattern.back(), layers.front()) and Combo.entry_matches(pattern.front(), layers.back())
			count = 1 if n >= 2 and (forward or backward) else 0
	return count if combo.each else mini(count, 1)


static func _matches_at(combo: Combo, layers: Array[Ingredient], start: int) -> bool:
	var length := combo.pattern.size()
	var forward := true
	var backward := combo.either_order
	for j in length:
		var layer := layers[start + j]
		forward = forward and Combo.entry_matches(combo.pattern[j], layer)
		backward = backward and Combo.entry_matches(combo.pattern[length - 1 - j], layer)
	return forward or backward


static func _has_set(combo: Combo, ingredients: Array[Ingredient]) -> bool:
	for entry in combo.pattern:
		if not ingredients.any(func(i: Ingredient) -> bool: return Combo.entry_matches(entry, i)):
			return false
	return true


## A burger with a bun-tagged solid at the bottom and at the top.
static func has_bun_ends(dish: Dish) -> bool:
	if dish.station != Dish.Station.BURGER:
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


static func _chips_label(layer: DishLayer) -> String:
	var fresh := roundi(layer.freshness * 100)
	if layer.ingredient.is_sauce():
		return "%s ×%d (%d%%)" % [layer.ingredient.display_name, layer.amount, fresh]
	return "%s (%d%%)" % [layer.ingredient.display_name, fresh]

