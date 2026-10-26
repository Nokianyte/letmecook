class_name Specials
## Today's specials: a few recipes to aim for, drawn per day, valued with the player's gadgets.

## Doses of sauce in a recipe's example build.
const EXAMPLE_SAUCE_DOSES := 10


## Recipes for the day: different ones, from a generator seeded by run seed and day (so
## the shop's random sequence is untouched). Smoothie recipes only with a blender.
static func draw(data: GameData, run_seed: int, day: int, has_blender: bool) -> Array[Recipe]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, day])
	var pool := data.recipes.filter(func(r: Recipe) -> bool:
		return r.station == Recipe.Station.BURGER or has_blender)
	var picked: Array[Recipe] = []
	for i in mini(data.balance.specials_count, pool.size()):
		var index := rng.randi_range(0, pool.size() - 1)
		picked.append(pool[index])
		pool.remove_at(index)
	return picked


## The recipe's example build as a fresh dish.
static func example_dish(recipe: Recipe, data: GameData) -> Dish:
	var dish := Dish.new(recipe.station)
	for id in recipe.example:
		var ingredient := _ingredient(data, id)
		dish.layers.append(DishLayer.new(ingredient, 1.0, EXAMPLE_SAUCE_DOSES if ingredient.is_sauce() else 1))
	return dish


## What the example build scores with these gadgets.
static func value(recipe: Recipe, data: GameData, counter: Array[Gadget]) -> ScoreResult:
	return Scoring.score_dish(example_dish(recipe, data), data, counter)


## Money a dish with this score would pay, tips included.
static func expected_money(score: int, dish: Dish, balance: Balance, counter: Array[Gadget]) -> int:
	var money := floori(score * balance.score_to_money)
	for gadget in counter:
		if gadget != null:
			money += gadget.on_dish_served(dish)
	return money


## For each ingredient of the example build: is it already in `dish`? Each layer of the
## dish counts once (two buns are needed for two bun ticks). Empty dish: all false.
static func progress(recipe: Recipe, dish: Dish) -> Array[bool]:
	var available: Array[StringName] = []
	if dish != null:
		for layer in dish.layers:
			available.append(layer.ingredient.id)
	var done: Array[bool] = []
	for id in recipe.example:
		var index := available.find(id)
		done.append(index >= 0)
		if index >= 0:
			available.remove_at(index)
	return done


static func _ingredient(data: GameData, id: StringName) -> Ingredient:
	for ingredient in data.ingredients:
		if ingredient.id == id:
			return ingredient
	assert(false, "Unknown ingredient in a recipe example: %s" % id)
	return null
