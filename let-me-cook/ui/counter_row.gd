extends Container
## The Kitchen Gadgets counter: one card per slot, in counter order.
## Works on an HBoxContainer (kitchen) or HFlowContainer (night, wraps).

const GadgetCard := preload("res://ui/gadget_card.gd")

## Show Sell buttons (night only).
@export var sellable := false


func _ready() -> void:
	RunState.changed.connect(_rebuild)
	_rebuild()


## Wiggles the card of the gadget with this id, if it's on the counter.
func react(source: StringName) -> void:
	if source == &"":
		return
	for card in get_children():
		if card.gadget != null and card.gadget.id == source:
			card.wiggle()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for i in RunState.counter.size():
		add_child(GadgetCard.new(i, RunState.counter[i], sellable))
