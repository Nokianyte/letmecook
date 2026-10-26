extends SceneTree
# Day 5 check: guaranteed meat slot, smoothie rules and scoring, the jar, debug overlay.
var fails := 0
var rs

func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond: fails += 1

func ings(ids: Array) -> Array[Ingredient]:
	var result: Array[Ingredient] = []
	for id in ids:
		result.append(rs.get_ingredient(id))
	return result

func smoothie(ids: Array) -> ScoreResult:
	var d := Dish.new(Recipe.Station.SMOOTHIE)
	for id in ids:
		d.layers.append(DishLayer.new(rs.get_ingredient(id), 1.0))
	return Scoring.score_dish(d, rs.data)

func mult_labels(r: ScoreResult) -> Array:
	return r.lines.filter(func(l): return l.kind == ScoreResult.Kind.MULT).map(func(l): return l.label)

func unit_of(id: StringName):
	for u in rs.pantry:
		if u.ingredient.id == id: return u
	return null

func frames(n: int) -> void:
	for i in n: await process_frame

func _initialize() -> void:
	await process_frame
	rs = root.get_node("RunState")
	var b: Balance = rs.balance

	print("[guaranteed meat]")
	var all_meat := true
	for s in 40:
		rs.new_run(100 + s)
		rs.close_day()
		if not rs.shop_stock[0].ingredient.has_tag(&"meat") or rs.shop_stock[0].quantity != 1: all_meat = false
		rs.money = 100
		rs.reroll_shop()
		if not rs.shop_stock[0].ingredient.has_tag(&"meat") or rs.shop_stock[0].quantity != 1: all_meat = false
	check(all_meat, "first slot is one unit of meat on 40 seeds, before and after a reroll")

	print("[smoothie bar]")
	check(not Shop.pool(rs.data, Recipe.Station.BURGER).any(func(i): return i.smoothie_ok), "market pool has no smoothie ingredients")
	check(Shop.pool(rs.data, Recipe.Station.SMOOTHIE).all(func(i): return i.smoothie_ok), "smoothie pool is smoothie ingredients only")
	rs.new_run(300)
	rs.close_day()
	check(rs.smoothie_stock.is_empty(), "no smoothie bar without a blender")
	rs.money = 100
	rs.buy_blender()
	check(rs.smoothie_stock.size() == b.smoothie_stock_slots and rs.smoothie_stock.all(func(o): return o.ingredient.smoothie_ok), "buying the blender opens the smoothie bar (%d slots)" % rs.smoothie_stock.size())
	check(rs.shop_stock.all(func(o): return not o.ingredient.smoothie_ok), "the market keeps burger ingredients")
	var bar0 = rs.smoothie_stock[0]
	rs.buy_offer(rs.smoothie_stock[1])
	var bar1 = rs.smoothie_stock[1]
	rs.reroll_shop()
	check(rs.smoothie_stock[0] != bar0 and rs.smoothie_stock[1] != bar1 and rs.smoothie_stock.all(func(o): return not o.sold), "a reroll restocks every bar slot, the bought one included")
	rs.end_night()
	rs.close_day()
	check(rs.smoothie_stock.size() == b.smoothie_stock_slots, "the bar rolls every night once unlocked")

	print("[smoothie rules]")
	check(is_equal_approx(Smoothie.liquid_ratio(ings([&"milk", &"banana"])), 0.5), "liquid ratio counts liquid vs thick")
	check(Smoothie.liquid_ratio(ings([&"strawberry"])) < 0, "no liquid or thick: no ratio")
	check(not Smoothie.is_muddy(ings([&"banana", &"strawberry"]), b), "banana + strawberry is not muddy (%.2f)" % Smoothie.hue_coherence(ings([&"banana", &"strawberry"])))
	check(not Smoothie.is_muddy(ings([&"strawberry", &"blueberry", &"yogurt"]), b), "berries + yogurt is not muddy (%.2f)" % Smoothie.hue_coherence(ings([&"strawberry", &"blueberry"])))
	check(Smoothie.is_muddy(ings([&"banana", &"blueberry"]), b), "banana + blueberry is muddy (%.2f)" % Smoothie.hue_coherence(ings([&"banana", &"blueberry"])))
	check(Smoothie.is_muddy(ings([&"strawberry", &"spinach", &"blueberry"]), b), "three clashing colors are muddy")
	check(not Smoothie.is_muddy(ings([&"banana", &"milk", &"milk", &"yogurt"]), b), "milk and yogurt don't count as colors")
	check(Smoothie.flavor_pairs(ings([&"banana", &"strawberry", &"banana"])) == ["Banana + Strawberry"], "pairs count once")
	var c := Smoothie.blend_color(ings([&"milk", &"strawberry"]))
	check(c.is_equal_approx((rs.get_ingredient(&"milk").color + rs.get_ingredient(&"strawberry").color) / 2), "blend color is the average")

	print("[smoothie scoring]")
	var r := smoothie([&"spinach", &"banana", &"milk"])
	check(r.recipe_name == "Green Machine", "Green Machine matches")
	var labels = mult_labels(r)
	check(labels.has("Good thickness") and labels.filter(func(l): return l.begins_with("Pair:")).size() == 2, "ratio and two pair bonuses: %s" % [labels])
	check(is_equal_approx(r.chips, 12.0) and is_equal_approx(r.mult, 5.0) and r.score == 60, "Green Machine: 12 x 5 = 60 (got %.1f x %.1f = %d)" % [r.chips, r.mult, r.score])
	r = smoothie([&"banana", &"blueberry", &"milk"])
	check(mult_labels(r).has("Muddy color"), "muddy penalty applied")
	check(smoothie([&"strawberry", &"blueberry", &"yogurt"]).recipe_name == "Berry Blast", "Berry Blast matches")
	check(smoothie([&"banana", &"milk", &"milk"]).recipe_name == "Banana Shake", "Banana Shake matches (any amounts)")

	print("[jar in the kitchen]")
	rs.new_run(200)
	rs.add_units(&"banana", 3); rs.add_units(&"milk", 6); rs.add_units(&"spinach", 1)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	var kitchen = main.current_scene()
	var jar = kitchen.get_node("%SmoothieJar")
	check(not kitchen.get_node("%JarColumn").visible, "jar hidden without a blender")
	rs.has_blender = true
	rs.changed.emit()
	await frames(2)
	check(kitchen.get_node("%JarColumn").visible, "jar shown with a blender")
	check(not jar._can_drop_data(Vector2.ZERO, {"unit": unit_of(&"patty")}), "burger ingredients don't go in the jar")

	var board = kitchen.get_node("%BurgerBoard")
	board.drop_unit(unit_of(&"stale_bread"), Vector2(board.size.x / 2, 50))
	for i in 120: await physics_frame
	var live = board._live
	board.force_drag({"unit": unit_of(&"banana")}, null)
	await frames(1)
	check(board._live == live and not live.freeze, "dragging a smoothie ingredient doesn't lock the burger")
	root.gui_cancel_drag()
	await frames(1)

	var center := Vector2(jar.size.x / 2, 20)
	jar.add_unit(unit_of(&"spinach"), center)
	jar.add_unit(unit_of(&"banana"), center)
	jar.add_unit(unit_of(&"milk"), center)
	for i in 60: await physics_frame
	check(jar.contents.size() == 3 and rs.count_of(&"spinach") == 0, "units moved into the jar")
	check(kitchen.get_node("%JarStatus").text.begins_with("Jar 3/%d · 50%% liquid" % b.jar_capacity), "jar status: %s" % kitchen.get_node("%JarStatus").text)
	var money0: int = rs.money
	kitchen.get_node("%BlendButton").pressed.emit()
	await frames(1)
	var served = rs.served_today.back()
	check(served.station == Recipe.Station.SMOOTHIE and served.result.recipe_name == "Green Machine", "blend & serve scores a Green Machine")
	check(rs.money == money0 + served.result.money and jar.is_empty(), "paid, jar emptied")
	jar.add_unit(unit_of(&"banana"), center)
	jar.add_unit(unit_of(&"banana"), center)
	kitchen.get_node("%EmptyJarButton").pressed.emit()
	check(rs.count_of(&"banana") == 2 and jar.is_empty(), "empty returns units to the pantry")
	rs.add_units(&"milk", b.jar_capacity)
	for i in b.jar_capacity + 2:
		jar.add_unit(unit_of(&"milk"), center)
	check(jar.contents.size() == b.jar_capacity and jar.is_full(), "jar stops at capacity (%d)" % jar.contents.size())
	check(not jar._can_drop_data(Vector2.ZERO, {"unit": unit_of(&"milk")}), "full jar refuses more")
	jar.clear()

	print("[debug overlay]")
	var overlay = main.debug_overlay
	var money_before: int = rs.money
	overlay._add_money()
	check(rs.money == money_before + 50, "+$50")
	board.clear()
	overlay._skip_day()
	await frames(2)
	check(rs.phase == rs.Phase.NIGHT and rs.money == money_before + 50, "skip day pays the rent for you")
	overlay._skip_day()
	await frames(2)
	check(rs.phase == rs.Phase.KITCHEN and rs.day == 2, "skip day at night opens the next day")
	overlay._seed_edit.text = "777"
	overlay._new_run()
	await frames(2)
	check(rs.run_seed == 777 and rs.day == 1, "new run with a typed seed")

	print("RESULT: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
