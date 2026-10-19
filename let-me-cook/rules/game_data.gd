class_name GameData
extends Resource
## Registry of all authored data. Listing resources here (instead of scanning
## folders) keeps lookups working in exported web builds.

@export var balance: Balance
@export var ingredients: Array[Ingredient] = []
@export var recipes: Array[Recipe] = []
@export var gadgets: Array[Gadget] = []
