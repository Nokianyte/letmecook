class_name ShopOffer
extends RefCounted
## One market slot for the night: some units of one ingredient at a price.

var ingredient: Ingredient
var quantity: int
var freshness: float
## Total price for all units, after the bulk discount.
var price: int
## Total price without the discount (unit price × quantity).
var full_price: int
var sold: bool = false


func _init(p_ingredient: Ingredient, p_quantity: int, p_freshness: float = 1.0, bulk_discount: float = 0.0) -> void:
	ingredient = p_ingredient
	quantity = p_quantity
	freshness = p_freshness
	full_price = ingredient.price * quantity
	price = bulk_price(ingredient.price, quantity, bulk_discount)


## Bundles are cheaper: `discount` off per extra unit, rounded to the nearest dollar.
## E.g. 10%: 2 patties at $0.40 cost $0.72, 3 cost $0.96 (prices in cents).
static func bulk_price(unit_price: int, quantity: int, discount: float) -> int:
	return roundi(unit_price * quantity * (1.0 - discount * (quantity - 1)))
