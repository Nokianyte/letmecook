extends PanelContainer
## The serving window: the last dish's score tally, then today's served dishes, newest first.

const SHOWN_DISHES := 4

@onready var _title: Label = %WindowTitle
@onready var _dishes: VBoxContainer = %Dishes
@onready var _tally: ScoreTally = %Tally


func _ready() -> void:
	RunState.changed.connect(_rebuild)
	RunState.dish_served.connect(_tally.play)
	RunState.day_closed.connect(_tally.clear)
	_rebuild()


func _rebuild() -> void:
	for child in _dishes.get_children():
		child.queue_free()
	var served := RunState.served_today
	_title.text = "Served today: %d" % served.size()
	for i in range(served.size() - 1, maxi(served.size() - 1 - SHOWN_DISHES, -1), -1):
		_dishes.add_child(DishPreview.new(served[i]))
