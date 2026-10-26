class_name Balance
extends Resource
## Every tuning number in one place. Edit data/balance.tres in the inspector.

@export_group("Run")
@export var days_per_run: int = 7
## Rent due at the end of each day; index 0 is day 1. Extra days reuse the last value.
@export var rent_curve: PackedInt32Array = PackedInt32Array([5, 10, 20, 32, 46, 62, 80])
## Money earned per point of score.
@export var score_to_money: float = 0.5

@export_group("Scoring")
## Mult never goes below this, however many penalties apply. Combo values live in data/combos.
@export var min_mult: float = 1.0

@export_group("Smoothies")
## Units the jar holds.
@export var jar_capacity: int = 8
## Liquid share of (liquid + thick) units that counts as a good thickness.
@export var ratio_min: float = 0.3
@export var ratio_max: float = 0.6
## Colorful ingredients whose hues agree less than this (0..1) blend into a muddy color.
@export var muddy_hue_coherence: float = 0.45

@export_group("Burger stability")
## The burger collapses when stability drops below this.
@export var stability_threshold: float = 0.0
## Stability lost by a layer offset by half the narrower layer's width.
@export var offset_penalty: float = 0.5
## Layers beyond this count each cost height_penalty.
@export var height_free_layers: int = 6
@export var height_penalty: float = 0.06

@export_group("Sauce")
## Seconds between sauce doses while pouring.
@export var pour_interval: float = 0.05

@export_group("Starting state")
@export var starting_money: int = 10
## Ingredient id -> count of units in the pantry at the start of a run (all at 100% freshness).
@export var starting_pantry: Dictionary = {}
@export var starting_fridge_slots: int = 3

@export_group("Kitchen Gadgets")
@export var counter_slots: int = 3
@export var gadget_offer_slots: int = 2

@export_group("Shop")
@export var shop_stock_slots: int = 5
## Bundles of 2-3 are cheaper: this much off per extra unit (0.1: ×2 is 10% off, ×3 is 20% off).
@export var bulk_discount_per_extra_unit: float = 0.1
## Smoothie bar slots, shown once the blender is owned.
@export var smoothie_stock_slots: int = 4
## The first market slot always offers one unit of an ingredient with this tag (empty: no guarantee).
@export var guaranteed_slot_tag: StringName = &"meat"
@export var reroll_base_cost: int = 1
@export var reroll_cost_step: int = 1
## Ingredient ids always offered at their own (low) price, unaffected by rerolls.
@export var staple_ids: Array[StringName] = []
## Staple id -> units for sale each night (restocked every night). Keeps the
## struggle-meal floor without making it an unlimited money loop.
@export var staple_stock: Dictionary = {}
@export var blender_price: int = 12
@export var fridge_upgrade_price: int = 8
@export var fridge_upgrade_slots: int = 2
@export var fridge_max_slots: int = 9

@export_group("Freshness decay per night (0..1)")
@export var shelf_stable_decay_outside: float = 0.10
@export var shelf_stable_decay_inside: float = 0.0
@export var perishable_decay_outside: float = 0.30
@export var perishable_decay_inside: float = 0.05


func rent_for_day(day: int) -> int:
	if rent_curve.is_empty():
		return 0
	return rent_curve[clampi(day - 1, 0, rent_curve.size() - 1)]


## Freshness lost overnight for an ingredient category. Staples never decay.
func decay_for(category: Ingredient.Category, in_fridge: bool) -> float:
	match category:
		Ingredient.Category.SHELF_STABLE:
			return shelf_stable_decay_inside if in_fridge else shelf_stable_decay_outside
		Ingredient.Category.PERISHABLE:
			return perishable_decay_inside if in_fridge else perishable_decay_outside
	return 0.0
