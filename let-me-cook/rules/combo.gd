class_name Combo
extends Resource
## A rule that adds (or, with a negative `mult`, removes) mult when a dish has a
## certain arrangement of ingredients. Several combos can apply to one dish.

enum Kind {
	## `pattern` matches consecutive layers, bottom to top (burgers).
	SEQUENCE,
	## Every `pattern` entry is somewhere in the dish, in any amount (smoothies).
	SET,
	## Liquid share of liquid + thick ingredients within the balance's ratio range.
	THICKNESS,
	## One line per pair of ingredients that go together (`Ingredient.pairs_with`).
	FLAVOR_PAIR,
	## The blended color is muddy (see `Smoothie.is_muddy`).
	MUDDY,
}
## Where a SEQUENCE has to be.
enum Anchor {
	ANYWHERE,
	## Starts at the bottom layer.
	BOTTOM,
	## Ends at the top layer.
	TOP,
	## The whole dish, nothing else.
	WHOLE,
	## First entry is the bottom layer, last entry the top layer (at least two layers).
	ENDS,
}

@export var id: StringName
@export var display_name: String
## Short rule shown on the combo board, e.g. "cheese touching patty".
@export var rule: String
@export var station: Dish.Station = Dish.Station.BURGER
@export var mult: float = 0.5
## Shown on the combo board before it's discovered.
@export var starter: bool = false

@export_group("Match")
@export var kind: Kind = Kind.SEQUENCE
## Ingredient ids or tags (an entry matches an ingredient with that id or tag).
@export var pattern: Array[StringName] = []
@export var anchor: Anchor = Anchor.ANYWHERE
## Also match the pattern reversed.
@export var either_order: bool = false
## Count every occurrence (one breakdown line each) instead of once.
@export var each: bool = false
## Skip sauce layers before matching.
@export var solids_only: bool = false


static func entry_matches(entry: StringName, ingredient: Ingredient) -> bool:
	return ingredient.id == entry or ingredient.has_tag(entry)


func is_penalty() -> bool:
	return mult < 0.0
