class_name Gadget
extends Resource
## A Kitchen Gadget: a build-shaping item on the counter (the run's jokers).
## Subclasses override the hooks they need; the defaults do nothing.

@export var id: StringName
@export var display_name: String
## Shown on the gadget's card and in tooltips.
@export_multiline var description: String
## In cents.
@export var price: int = 60


## Adds chips / mult / ×mult lines to a dish being scored. Runs in counter order,
## after the base rules and the recipe.
func modify_score(_dish: Dish, _result: ScoreResult) -> void:
	pass


## Extra money for a served dish (e.g. tips).
func on_dish_served(_dish: Dish) -> int:
	return 0


## Adjusts tonight's next reroll cost.
func modify_reroll_cost(cost: int, _rerolls_tonight: int) -> int:
	return cost
