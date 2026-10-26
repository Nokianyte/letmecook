extends Node
## Scores the dish in progress as if served now: pops callouts for what it gains or
## loses, keeps the "if served now" list in the serving window, and feeds the specials
## board's progress ticks.

const Callout := preload("res://ui/callout.gd")
const STAGGER := 0.12
const LOST_COLOR := Color(0.7, 0.7, 0.75)
## Callouts above the dish stack upward by this much so they don't cover each other.
const LINE_SPACING := 22.0

var _board: BurgerBoard
var _jar: SmoothieJar
var _tally: ScoreTally
var _overlay: Control
var _specials: Control
## Last preview lines per station, keyed (see _keyed).
var _previous := {Recipe.Station.BURGER: {}, Recipe.Station.SMOOTHIE: {}}
## The station whose preview the list shows (the one changed most recently).
var _shown := Recipe.Station.BURGER


func setup(board: BurgerBoard, jar: SmoothieJar, tally: ScoreTally, overlay: Control, specials: Control) -> void:
	_board = board
	_jar = jar
	_tally = tally
	_overlay = overlay
	_specials = specials
	board.state_changed.connect(refresh.bind(Recipe.Station.BURGER, true))
	jar.state_changed.connect(refresh.bind(Recipe.Station.SMOOTHIE, true))
	# Gadgets bought, sold or reordered change the numbers, without anything to announce.
	RunState.changed.connect(_refresh_both)
	tally.finished.connect(_refresh_both)


## Recalculates one station's preview; `announce` pops callouts for what changed.
func refresh(station: Recipe.Station, announce: bool = true) -> void:
	# Mid-pour and mid-fall are in-between states: wait for the dish to settle.
	if station == Recipe.Station.BURGER and (_board.is_pouring() or _board.is_busy()):
		return
	var dish := _dish(station)
	var result := score(dish)
	if announce and result != null:
		_announce(station, result)
	_previous[station] = _keyed(result)
	if dish != null:
		_shown = station
	_show_list()


## The score the dish would get if served now (null for no dish).
func score(dish: Dish) -> ScoreResult:
	return Scoring.score_dish(dish, RunState.data, RunState.counter) if dish != null else null


func _refresh_both() -> void:
	refresh(Recipe.Station.SMOOTHIE, false)
	refresh(Recipe.Station.BURGER, false)


func _dish(station: Recipe.Station) -> Dish:
	return _board.preview_dish() if station == Recipe.Station.BURGER else _jar.preview_dish()


func _show_list() -> void:
	var station := _shown
	var dish := _dish(station)
	if dish == null:
		station = Recipe.Station.SMOOTHIE if _shown == Recipe.Station.BURGER else Recipe.Station.BURGER
		dish = _dish(station)
	var result := score(dish)
	var money := Specials.expected_money(result.score, dish, RunState.balance, RunState.counter) if result != null else 0
	_tally.show_preview(result, money)
	if _specials != null:
		_specials.show_progress(dish)


## Pops a callout for every line that's new since the last preview of this station, and a
## "lost" callout for every bonus that no longer applies.
func _announce(station: Recipe.Station, result: ScoreResult) -> void:
	var old: Dictionary = _previous[station]
	var keys := _keys(result)
	var current := _keyed(result)
	var layer_positions: Array[Vector2] = []
	if station == Recipe.Station.BURGER:
		layer_positions = _board.preview_positions()
	var top := _board.top_position() if station == Recipe.Station.BURGER else _jar.top_position()
	var delay := 0.0
	var layer_index := 0
	var above := 0  # callouts already placed above the dish
	for i in result.lines.size():
		var line: Dictionary = result.lines[i]
		var beside: bool = line.kind == ScoreResult.Kind.CHIPS and line.source == &"" and station == Recipe.Station.BURGER
		var at := top
		if line.kind == ScoreResult.Kind.CHIPS and line.source == &"":
			if beside and layer_index < layer_positions.size():
				at = layer_positions[layer_index]
			layer_index += 1
		if old.has(keys[i]):
			continue
		if not beside:
			at.y -= LINE_SPACING * above
			above += 1
		_pop(ScoreTally.line_text(line), ScoreTally.line_color(line), at, delay, beside)
		delay += STAGGER
	for key in old:
		var line: Dictionary = old[key]
		if not current.has(key) and line.kind != ScoreResult.Kind.CHIPS and line.value > 0:
			_pop("lost: %s" % line.label, LOST_COLOR, top - Vector2(0, LINE_SPACING * above), delay)
			above += 1
			delay += STAGGER


func _pop(text: String, color: Color, at: Vector2, delay: float, beside: bool = false) -> void:
	var callout := Callout.new(text, color)
	_overlay.add_child(callout)
	callout.pop(at, delay, beside)


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
