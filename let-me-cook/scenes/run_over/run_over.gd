extends Control
## End of a run: win or loss, how far it got, total score, and the seed to replay it.

@onready var _result_label: Label = %ResultLabel
@onready var _detail_label: Label = %DetailLabel
@onready var _seed_label: Label = %SeedLabel
@onready var _new_run_button: Button = %NewRunButton


func _ready() -> void:
	_new_run_button.pressed.connect(RunState.new_run.bind(-1))
	var day: int = RunState.last_day.get("day", RunState.day)
	if RunState.run_won:
		_result_label.text = "You made rent!"
		_detail_label.text = "Survived all %d days with %s left.\nTotal score: %d" % [
			RunState.balance.days_per_run, Money.text(RunState.money), RunState.total_score]
	else:
		_result_label.text = "Evicted"
		_detail_label.text = "Day %d: rent was %s, you had %s.\nTotal score: %d" % [
			day, Money.text(RunState.last_day.get("rent", 0)), Money.text(RunState.money), RunState.total_score]
	_seed_label.text = "Seed %d" % RunState.run_seed
