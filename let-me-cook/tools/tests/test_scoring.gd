extends SceneTree
# Day 3 check: scoring rules, recipes, serving, and the tally.
var fails := 0
var rs

func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond: fails += 1

## spec: Array of id or [id, amount] or [id, amount, freshness], bottom to top.
func dish(spec: Array) -> Dish:
	var d := Dish.new(Recipe.Station.BURGER)
	for s in spec:
		var id: StringName = s if s is StringName else s[0]
		var amount: int = 1 if s is StringName else s[1]
		var fresh: float = 1.0 if s is StringName or s.size() < 3 else s[2]
		d.layers.append(DishLayer.new(rs.get_ingredient(id), fresh, amount))
	return d

func score(spec: Array) -> ScoreResult:
	return Scoring.score_dish(dish(spec), rs.data)

func mult_labels(r: ScoreResult) -> Array:
	return r.lines.filter(func(l): return l.kind == ScoreResult.Kind.MULT).map(func(l): return l.label)

func _initialize() -> void:
	await process_frame
	rs = root.get_node("RunState")
	var r: ScoreResult

	print("[chips x mult]")
	r = score([&"patty", &"stale_bread"])
	check(is_equal_approx(r.chips, 10.0) and is_equal_approx(r.mult, 1.0) and r.score == 10, "plain dish: 10 chips x 1 = 10 (got %.1f x %.1f = %d)" % [r.chips, r.mult, r.score])
	r = score([[&"patty", 1, 0.5]])
	check(is_equal_approx(r.chips, 4.0), "patty at 50%% gives 4 chips (%.1f)" % r.chips)
	r = score([[&"ketchup", 4]])
	check(is_equal_approx(r.chips, 4 * rs.get_ingredient(&"ketchup").base_chips), "sauce chips = base per dose x 4 (%.2f)" % r.chips)
	check(r.lines[0].label.contains("×4"), "sauce line shows the dose count: %s" % r.lines[0].label)

	print("[burger rules]")
	r = score([&"bun", &"patty", &"bun"])
	check(is_equal_approx(r.mult, 2.0) and mult_labels(r) == ["Bun on both ends"], "structure bonus (mult %.1f)" % r.mult)
	r = score([&"bun", &"cheese", &"patty", &"bun"])
	check(mult_labels(r).has("Melt: cheese on patty") and is_equal_approx(r.mult, 2.5), "melt works both ways, no recipe out of order (mult %.1f)" % r.mult)
	r = score([&"bun", [&"ketchup", 5], &"patty", &"bun"])
	check(mult_labels(r).has("Soggy bottom") and is_equal_approx(r.mult, 1.5), "soggy bottom penalty (mult %.1f)" % r.mult)
	r = score([&"bun", [&"ketchup", 5]])
	check(is_equal_approx(r.mult, rs.balance.min_mult), "mult never below the minimum (%.1f)" % r.mult)

	print("[recipes]")
	r = score([&"bun", &"patty", &"cheese", &"bun"])
	check(r.recipe_name == "Classic Cheese", "Classic Cheese matches")
	check(is_equal_approx(r.chips, 18.0) and is_equal_approx(r.mult, 4.5) and r.score == 81, "Classic Cheese: 18 x 4.5 = 81 (got %.1f x %.1f = %d)" % [r.chips, r.mult, r.score])
	r = score([&"bun", &"patty", [&"ketchup", 3], &"cheese", &"bun"])
	check(r.recipe_name == "Classic Cheese", "sauce layers are ignored by recipes that list no sauce")
	check(not mult_labels(r).has("Melt: cheese on patty"), "...but sauce between cheese and patty blocks the melt")
	r = score([&"stale_bread", [&"ketchup", 20], &"stale_bread"])
	check(r.recipe_name == "Struggle Burger" and r.score == 15, "Struggle Burger: 6 chips x 2.5 = 15 (got %s, %d)" % [r.recipe_name, r.score])
	check(score([&"stale_bread", &"stale_bread"]).recipe_name == "", "Struggle Burger needs the ketchup")
	check(score([&"stale_bread", [&"ketchup", 2], &"patty", &"stale_bread"]).recipe_name == "", "...and nothing else")
	check(score([&"bun", &"patty", &"cheese", &"patty", &"cheese", &"bun"]).recipe_name == "Double Cheese", "Double Cheese matches")
	r = score([&"bun", &"lettuce", &"patty", &"onion", &"tomato", &"bun"])
	check(r.recipe_name == "Garden Stack", "Garden Stack: contains lettuce, tomato, onion in any order")
	check(mult_labels(r).filter(func(l): return l in ["Garden Stack", "Classic Cheese", "Double Cheese", "Struggle Burger"]).size() == 1, "only one recipe counts")

	print("[serving]")
	rs.new_run(5)
	var money0: int = rs.money
	var d := dish([&"bun", &"patty", &"cheese", &"bun"])
	var res: ScoreResult = rs.serve(d)
	check(d.result == res and res.score == 81, "serve scores the dish")
	check(rs.money == money0 + floori(81 * rs.balance.score_to_money), "money paid right away (%d -> %d)" % [money0, rs.money])
	check(rs.day_score == 81 and rs.total_score == 81, "day and run totals")
	rs.close_day()
	check(rs.day_score == 0 and rs.total_score == 81, "closing resets the day total only")

	print("[tally]")
	rs.new_run(6)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3: await process_frame
	var kitchen = main.current_scene()
	var tally: ScoreTally = kitchen.get_node("%Tally")
	var today: Label = kitchen.get_node("%DayScoreLabel")
	var done := [false]
	tally.finished.connect(func(): done[0] = true)
	rs.serve(dish([&"bun", &"patty", &"cheese", &"bun"]))
	await process_frame
	check(today.text == "Today: 0 pts", "day total waits for the tally (%s)" % today.text)
	var t := 0
	while not done[0] and t < 600:
		await process_frame; t += 1
	check(done[0], "tally finishes")
	var texts = tally.get_children().map(func(c): return c.text)
	check(texts[0] == "Classic Cheese", "tally title is the recipe")
	check(texts.any(func(x): return x.begins_with("+0.5  Melt")), "tally lists the melt bonus")
	check(texts.back().begins_with("= 81 pts"), "tally ends with the score: %s" % texts.back())
	check(today.text == "Today: 81 pts", "day total updates after the tally (%s)" % today.text)
	check(kitchen.get_node("%WindowTitle").text == "Served today: 1", "window counts the dish")

	print("RESULT: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
