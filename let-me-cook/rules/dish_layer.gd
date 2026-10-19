class_name DishLayer
extends RefCounted
## One layer of a served dish: a solid piece (amount 1) or a sauce layer (amount = doses).

var ingredient: Ingredient
var freshness: float
var amount: int


func _init(p_ingredient: Ingredient, p_freshness: float, p_amount: int = 1) -> void:
	ingredient = p_ingredient
	freshness = p_freshness
	amount = p_amount


func chips() -> float:
	return ingredient.base_chips * freshness * amount
