class_name Ingredient
extends Resource
## Static definition of one ingredient type. Owned copies are IngredientUnit.

enum Category { STAPLE, SHELF_STABLE, PERISHABLE }
## SOLID ingredients are dragged as single pieces; SAUCE ingredients are bottles poured in doses.
enum Kind { SOLID, SAUCE }
enum SmoothieRole { NONE, LIQUID, THICK }

@export var id: StringName
@export var display_name: String
@export var kind: Kind = Kind.SOLID

@export_group("Gray box")
@export var color: Color = Color.GRAY
## Size of the ingredient's rectangle when stacked on a burger, in pixels (solids only).
@export var size: Vector2 = Vector2(160, 24)

@export_group("Economy")
@export var category: Category = Category.PERISHABLE
## In cents.
@export var price: int = 10
## Doses in one bottle (sauces only).
@export var doses: int = 0

@export_group("Scoring")
## Chips at 100% freshness: per piece for solids, per dose for sauces.
@export var base_chips: float = 1.0
## Free-form tags used by scoring rules and recipes, e.g. &"bun", &"sauce", &"cheese".
@export var tags: Array[StringName] = []

@export_group("Stations")
## Home station: decides which shop sells it (market or smoothie bar).
@export var burger_ok: bool = true

@export var smoothie_ok: bool = false
## Can also go into the other station (a burger solid in the jar, fruit on a burger).
@export var crossover: bool = false

@export_group("Smoothie")
@export var smoothie_role: SmoothieRole = SmoothieRole.NONE
## Ingredients that taste good with this one in a smoothie (checked both ways).
@export var pairs_with: Array[StringName] = []


func is_sauce() -> bool:
	return kind == Kind.SAUCE


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func fits_burger() -> bool:
	return not is_sauce() and (burger_ok or crossover)


func fits_jar() -> bool:
	return not is_sauce() and (smoothie_ok or crossover)
