class_name ScoreResult
extends RefCounted
## A scored dish: the breakdown lines, in the order the tally plays them, and the totals.

enum Kind { CHIPS, MULT, X_MULT, MONEY }

## Each line: {"kind": Kind, "label": String, "value": float, "source": StringName}.
## CHIPS lines add to chips; MULT lines add to mult (negative for penalties);
## X_MULT lines multiply the mult so far; MONEY lines are extra payout (tips).
## `source` is the id of the gadget that made the line, or &"" for the base rules.
## Mult lines from combos also have "combo": the combo's id.
var lines: Array[Dictionary] = []
var chips: float = 0.0
var mult: float = 1.0
var score: int = 0
## Mult floor that was applied to `mult`.
var min_mult: float = 1.0
## Money paid for this dish, tips included; set when it is served.
var money: int = 0


func add_chips(label: String, value: float, source: StringName = &"") -> void:
	lines.append({"kind": Kind.CHIPS, "label": label, "value": value, "source": source})
	chips += value


func add_mult(label: String, value: float, source: StringName = &"", combo: StringName = &"") -> void:
	var line := {"kind": Kind.MULT, "label": label, "value": value, "source": source}
	if combo != &"":
		line["combo"] = combo
	lines.append(line)
	mult += value


func add_x_mult(label: String, value: float, source: StringName = &"") -> void:
	lines.append({"kind": Kind.X_MULT, "label": label, "value": value, "source": source})
	mult *= value


func add_money(label: String, value: int, source: StringName = &"") -> void:
	lines.append({"kind": Kind.MONEY, "label": label, "value": value, "source": source})
	money += value
