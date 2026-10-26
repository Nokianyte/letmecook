extends Node
## Scores the dish in progress as if served now: pops callouts for what it gains or
## loses, keeps the "if served now" list in the serving window, discovers combos and
## lights them up on the combo board.

const Callout := preload("res://ui/callout.gd")
const STAGGER := 0.12
const LOST_COLOR := Color(0.7, 0.7, 0.75)
const NEW_COMBO_COLOR := Color(1.0, 0.85, 0.35)
## Font sizes: chips and lost bonuses stay small, mult is big, new combos bigger still.
const SMALL_SIZE := 16
const MULT_SIZE := 26
const NEW_COMBO_SIZE := 28
## Gap between callouts stacked above the dish.
const STACK_GAP := 2.0

var _board: BurgerBoard
var _jar: SmoothieJar
var _tally: ScoreTally
var _overlay: Control
var _combo_board: Control
## Last preview lines per station, keyed (see _keyed).
var _previous := {Dish.Station.BURGER: {}, Dish.Station.SMOOTHIE: {}}
## The station whose preview the list shows (the one changed most recently).
var _shown := Dish.Station.BURGER


func setup(board: BurgerBoard, jar: SmoothieJar, tally: ScoreTally, overlay: Control, combo_board: Control) -> void:
	_board = board
	_jar = jar
	_tally = tally
	_overlay = overlay
	_combo_board = combo_board
	board.state_changed.connect(refresh.bind(Dish.Station.BURGER, true))
	jar.state_changed.connect(refresh.bind(Dish.Station.SMOOTHIE, true))
	# Gadgets bought, sold or reordered change the numbers, without anything to announce.
	RunState.changed.connect(_refresh_both)
	tally.finished.connect(_refresh_both)


## Recalculates one station's preview; `announce` pops callouts for what changed.
func refresh(station: Dish.Station, announce: bool = true) -> void:
	# Mid-pour and mid-fall are in-between states: wait for the dish to settle.
	if station == Dish.Station.BURGER and (_board.is_pouring() or _board.is_busy()):
		return
	var dish := _dish(station)
	var result := score(dish)
	var discovered := _discover(result)
	if announce and result != null:
		_announce(station, result, discovered)
	_previous[station] = _keyed(result)
	if dish != null:
		_shown = station
	_show_list()


## The score the dish would get if served now (null for no dish).
func score(dish: Dish) -> ScoreResult:
	return Scoring.score_dish(dish, RunState.data, RunState.counter) if dish != null else null


func _refresh_both() -> void:
	refresh(Dish.Station.SMOOTHIE, false)
	refresh(Dish.Station.BURGER, false)


func _dish(station: Dish.Station) -> Dish:
	return _board.preview_dish() if station == Dish.Station.BURGER else _jar.preview_dish()


func _show_list() -> void:
	var station := _shown
	var dish := _dish(station)
	if dish == null:
		station = Dish.Station.SMOOTHIE if _shown == Dish.Station.BURGER else Dish.Station.BURGER
		dish = _dish(station)
	var result := score(dish)
	var money := Scoring.expected_money(result.score, dish, RunState.balance, RunState.counter) if result != null else 0
	_tally.show_preview(result, money)
	if _combo_board != null:
		_combo_board.show_dish(station, result)


## Marks the combos in `result` that the player hadn't built before; returns them.
func _discover(result: ScoreResult) -> Array[Combo]:
	var found: Array[Combo] = []
	for id in Scoring.combo_counts(result):
		var combo := RunState.get_combo(id)
		if combo != null and RunState.discover(combo):
			found.append(combo)
	return found


## Pops a callout for every line that's new since the last preview of this station, and a
## "lost" callout for every bonus that no longer applies, then "New combo!" for each
## combo built for the first time.
func _announce(station: Dish.Station, result: ScoreResult, discovered: Array[Combo]) -> void:
	var old: Dictionary = _previous[station]
	var keys := _keys(result)
	var current := _keyed(result)
	var layer_positions: Array[Vector2] = []
	if station == Dish.Station.BURGER:
		layer_positions = _board.preview_positions()
	var top := _board.top_position() if station == Dish.Station.BURGER else _jar.top_position()
	var delay := 0.0
	var layer_index := 0
	var above := 0.0  # height of the callouts already stacked above the dish
	for i in result.lines.size():
		var line: Dictionary = result.lines[i]
		var beside: bool = line.kind == ScoreResult.Kind.CHIPS and line.source == &"" and station == Dish.Station.BURGER
		var at := top
		if line.kind == ScoreResult.Kind.CHIPS and line.source == &"":
			if beside and layer_index < layer_positions.size():
				at = layer_positions[layer_index]
			layer_index += 1
		if old.has(keys[i]):
			continue
		var big: bool = line.kind == ScoreResult.Kind.MULT or line.kind == ScoreResult.Kind.X_MULT
		var callout := _make(ScoreTally.line_text(line), ScoreTally.line_color(line), MULT_SIZE if big else SMALL_SIZE)
		if not beside:
			at.y -= above
			above += callout.get_minimum_size().y + STACK_GAP
		callout.pop(at, delay, beside, big)
		delay += STAGGER
	for key in old:
		var line: Dictionary = old[key]
		if not current.has(key) and line.kind != ScoreResult.Kind.CHIPS and line.value > 0:
			var callout := _make("lost: %s" % line.label, LOST_COLOR, SMALL_SIZE)
			callout.pop(top - Vector2(0, above), delay)
			above += callout.get_minimum_size().y + STACK_GAP
			delay += STAGGER
	for combo in discovered:
		var callout := _make("New combo! %s %s" % [combo.display_name, _value(combo.mult)], NEW_COMBO_COLOR, NEW_COMBO_SIZE)
		callout.pop(top - Vector2(0, above), delay + STAGGER, false, true)
		above += callout.get_minimum_size().y + STACK_GAP
		delay += STAGGER


func _make(text: String, color: Color, font_size: int) -> Callout:
	var callout := Callout.new(text, color, font_size)
	_overlay.add_child(callout)
	return callout


static func _value(mult: float) -> String:
	return "%s%.1f" % ["+" if mult >= 0 else "−", absf(mult)]


## Lines keyed by kind, label and value, numbered when repeated (two patties are two keys).
func _keyed(result: ScoreResult) -> Dictionary:
	var keyed := {}
	if result == null:
		return keyed
	var keys := _keys(result)
	for i in keys.size():
		keyed[keys[i]] = result.lines[i]
	return keyed


func _keys(result: ScoreResult) -> Array[String]:
	var keys: Array[String] = []
	var seen := {}
	for line in result.lines:
		var base := "%d|%s|%.3f" % [line.kind, line.label, line.value]
		seen[base] = seen.get(base, -1) + 1
		keys.append("%s#%d" % [base, seen[base]])
	return keys
