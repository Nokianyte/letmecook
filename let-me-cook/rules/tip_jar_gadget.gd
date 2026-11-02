class_name TipJarGadget
extends Gadget
## Extra money for every dish served.

@export var tip: int = 1


func on_dish_served(_dish: Dish) -> int:
	return tip
