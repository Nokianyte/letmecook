extends PanelContainer
## Lists every owned ingredient unit, grouped by ingredient, freshest first.

signal pour_requested(unit: IngredientUnit)

@onready var _rows: VBoxContainer = %Rows


func _ready() -> void:
	RunState.changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	for child in _rows.get_children():
		child.queue_free()

	var any := false
	for ingredient in RunState.data.ingredients:
		var units := RunState.pantry.filter(func(u: IngredientUnit) -> bool: return u.ingredient == ingredient)
		if units.is_empty():
			continue
		any = true
		units.sort_custom(func(a: IngredientUnit, b: IngredientUnit) -> bool: return a.freshness > b.freshness)

		var title := Label.new()
		title.text = "%s ×%d" % [ingredient.display_name, units.size()]
		_rows.add_child(title)

		var flow := HFlowContainer.new()
		for unit in units:
			var chip := PantryChip.new(unit)
			chip.pour_started.connect(pour_requested.emit)
			flow.add_child(chip)
		_rows.add_child(flow)

	if not any:
		var empty := Label.new()
		empty.text = "Pantry is empty"
		empty.modulate.a = 0.6
		_rows.add_child(empty)
