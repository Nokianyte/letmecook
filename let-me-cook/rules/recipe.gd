class_name Recipe
extends Resource
## A named dish that grants a mult bonus when a finished dish matches it.

enum Station { BURGER, SMOOTHIE }
enum MatchMode {
	## Layers equal `ingredients` exactly, bottom to top (burgers).
	ORDERED_EXACT,
	## Every ingredient in `ingredients` is present and nothing else is (counts don't matter).
	ONLY_THESE,
	## Every ingredient in `ingredients` is present; other ingredients are allowed.
	CONTAINS,
}

@export var display_name: String
@export var station: Station = Station.BURGER
@export var match_mode: MatchMode = MatchMode.ORDERED_EXACT
@export var ingredients: Array[StringName] = []
@export var mult_bonus: float = 1.0
