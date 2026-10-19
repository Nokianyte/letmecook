class_name IngredientUnit
extends RefCounted
## One owned unit of an ingredient (a piece, or a sauce bottle), with its own freshness.

var ingredient: Ingredient
## 0.0 .. 1.0
var freshness: float = 1.0
var in_fridge: bool = false
## Doses left in a sauce bottle; 0 for solids.
var doses_left: int = 0


func _init(p_ingredient: Ingredient, p_freshness: float = 1.0) -> void:
	ingredient = p_ingredient
	freshness = p_freshness
	if ingredient.is_sauce():
		doses_left = ingredient.doses
