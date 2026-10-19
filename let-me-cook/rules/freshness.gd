class_name Freshness
## Overnight decay and spoilage.

## Below this, a unit counts as 0% and spoils (avoids float leftovers like 0.0000001).
const SPOIL_EPSILON := 0.001


## Applies one night of decay to every unit in `pantry`, removes spoiled units from it,
## and returns them.
static func apply_night(pantry: Array[IngredientUnit], balance: Balance) -> Array[IngredientUnit]:
	var spoiled: Array[IngredientUnit] = []
	for unit in pantry:
		unit.freshness = maxf(0.0, unit.freshness - balance.decay_for(unit.ingredient.category, unit.in_fridge))
		if unit.freshness <= SPOIL_EPSILON:
			unit.freshness = 0.0
			spoiled.append(unit)
	for unit in spoiled:
		pantry.erase(unit)
	return spoiled


## Freshness a unit would have tomorrow, for previews in the fridge UI.
static func forecast(unit: IngredientUnit, in_fridge: bool, balance: Balance) -> float:
	return maxf(0.0, unit.freshness - balance.decay_for(unit.ingredient.category, in_fridge))
