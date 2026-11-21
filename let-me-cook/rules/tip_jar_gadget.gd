class_name TipJarGadget
extends Gadget
## Extra money for every dish served.

@export var tip_rate: float = 0.1


func on_dish_served(base_money: int) -> int:
	return roundi(base_money * tip_rate)
