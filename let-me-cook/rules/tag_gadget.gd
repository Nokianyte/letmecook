class_name TagGadget
extends Gadget
## Data-driven scoring gadget: count something in the dish, then add chips, add mult,
## or multiply mult by `amount` per count. Edit in the inspector.

enum Station { ANY, BURGER, SMOOTHIE }
enum Condition {
	NONE,
	## Burger with a bun-tagged layer at the bottom and the top.
	BUN_ENDS,
}
enum Count {
	## 1 when the condition holds.
	ONCE,
	## Layers with `tag`.
	LAYERS_WITH_TAG,
	## Different ingredients with `tag`.
	DISTINCT_WITH_TAG,
	## Cheese–patty layers touching each other.
	MELTS,
	## Solid layers beyond `threshold`.
	SOLIDS_BEYOND,
	## Total chips of sauce layers (use ADD_CHIPS: amount is a multiplier of those chips).
	SAUCE_CHIPS,
}
enum Effect { ADD_CHIPS, ADD_MULT, X_MULT }

@export var station: Station = Station.BURGER
@export var condition: Condition = Condition.NONE
@export var count: Count = Count.ONCE
@export var tag: StringName
@export var threshold: int = 0
@export var effect: Effect = Effect.ADD_MULT
@export var amount: float = 1.0


func modify_score(dish: Dish, result: ScoreResult) -> void:
	if station == Station.BURGER and dish.station != Dish.Station.BURGER:
		return
	if station == Station.SMOOTHIE and dish.station != Dish.Station.SMOOTHIE:
		return
	if condition == Condition.BUN_ENDS and not Scoring.has_bun_ends(dish):
		return
	var n := _count(dish)
	if n <= 0.0:
		return
	match effect:
		Effect.ADD_CHIPS:
			result.add_chips(display_name, amount * n, id)
		Effect.ADD_MULT:
			result.add_mult(display_name, amount * n, id)
		Effect.X_MULT:
			result.add_x_mult(display_name, pow(amount, n), id)


func _count(dish: Dish) -> float:
	match count:
		Count.ONCE:
			return 1.0
		Count.LAYERS_WITH_TAG:
			return dish.layers.filter(func(l: DishLayer) -> bool: return l.ingredient.has_tag(tag)).size()
		Count.DISTINCT_WITH_TAG:
			var ids := {}
			for layer in dish.layers:
				if layer.ingredient.has_tag(tag):
					ids[layer.ingredient.id] = true
			return ids.size()
		Count.MELTS:
			return Scoring.melt_count(dish)
		Count.SOLIDS_BEYOND:
			var solids := dish.layers.filter(func(l: DishLayer) -> bool: return not l.ingredient.is_sauce()).size()
			return maxi(solids - threshold, 0)
		Count.SAUCE_CHIPS:
			var chips := 0.0
			for layer in dish.layers:
				if layer.ingredient.is_sauce():
					chips += layer.chips()
			return chips
	return 0.0
