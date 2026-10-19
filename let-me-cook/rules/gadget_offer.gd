class_name GadgetOffer
extends RefCounted
## A gadget on sale tonight.

var gadget: Gadget
var sold: bool = false


func _init(p_gadget: Gadget) -> void:
	gadget = p_gadget
