class_name Smoothie
## Smoothie rules shared by the jar (live preview) and scoring.

## Below this saturation an ingredient doesn't count as colorful (milk, yogurt).
const COLORFUL_SATURATION := 0.25


## Color of the blended contents: plain average, one weight per unit.
static func blend_color(ingredients: Array[Ingredient]) -> Color:
	if ingredients.is_empty():
		return Color(0, 0, 0, 0)
	var sum := Color(0, 0, 0, 0)
	for ingredient in ingredients:
		sum += ingredient.color
	return sum / ingredients.size()


## Liquid share of liquid + thick units, or -1 when there are neither.
static func liquid_ratio(ingredients: Array[Ingredient]) -> float:
	var liquid := 0
	var thick := 0
	for ingredient in ingredients:
		match ingredient.smoothie_role:
			Ingredient.SmoothieRole.LIQUID:
				liquid += 1
			Ingredient.SmoothieRole.THICK:
				thick += 1
	if liquid + thick == 0:
		return -1.0
	return float(liquid) / (liquid + thick)


## How much the colorful, non-liquid ingredients' hues agree, 0..1 (1 when fewer than
## two different colorful ingredients). Each one is a point on the color wheel weighted
## by its saturation; clashing hues cancel out.
static func hue_coherence(ingredients: Array[Ingredient]) -> float:
	var ids := {}
	var sum := Vector2.ZERO
	var weight := 0.0
	for ingredient in ingredients:
		if ingredient.smoothie_role == Ingredient.SmoothieRole.LIQUID or ingredient.color.s < COLORFUL_SATURATION:
			continue
		ids[ingredient.id] = true
		sum += Vector2.from_angle(ingredient.color.h * TAU) * ingredient.color.s
		weight += ingredient.color.s
	if ids.size() < 2:
		return 1.0
	return sum.length() / weight


static func is_muddy(ingredients: Array[Ingredient], balance: Balance) -> bool:
	return hue_coherence(ingredients) < balance.muddy_hue_coherence


## Each unordered pair of different ingredients that go together, once.
static func flavor_pairs(ingredients: Array[Ingredient]) -> Array[String]:
	var unique: Array[Ingredient] = []
	for ingredient in ingredients:
		if not unique.has(ingredient):
			unique.append(ingredient)
	var pairs: Array[String] = []
	for i in unique.size():
		for j in range(i + 1, unique.size()):
			var a := unique[i]
			var b := unique[j]
			if a.pairs_with.has(b.id) or b.pairs_with.has(a.id):
				pairs.append("%s + %s" % [a.display_name, b.display_name])
	return pairs
