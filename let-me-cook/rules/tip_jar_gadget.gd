class_name TipJarGadget
extends Gadget
## Extra money for every dish served.

## In cents.
@export var tip: int = 10


func on_dish_served(_dish: Dish) -> int:
	return tip
