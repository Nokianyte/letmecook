class_name LuckyCoinGadget
extends Gadget
## The first reroll each night is free.


func modify_reroll_cost(cost: int, rerolls_tonight: int) -> int:
	return 0 if rerolls_tonight == 0 else cost
