extends SceneTree
# Kitchen Gadgets: effects, counter order, shop/sell/reroll, reorder, tally feedback.
var fails := 0
var rs

func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond: fails += 1

func g(id: StringName) -> Gadget:
	for gadget in rs.data.gadgets:
		if gadget.id == id: return gadget
	return null

func counter_of(ids: Array) -> Array[Gadget]:
	var c: Array[Gadget] = []
	for id in ids: c.append(g(id))
	return c

## spec: ids or [id, amount], bottom to top.
func dish(spec: Array, station := Dish.Station.BURGER) -> Dish:
	var d := Dish.new(station)
	for s in spec:
		var id: StringName = s if s is StringName else s[0]
		d.layers.append(DishLayer.new(rs.get_ingredient(id), 1.0, 1 if s is StringName else s[1]))
	return d

func score(spec: Array, ids: Array, station := Dish.Station.BURGER) -> ScoreResult:
	return Scoring.score_dish(dish(spec, station), rs.data, counter_of(ids))

func gadget_lines(r: ScoreResult) -> Array:
	return r.lines.filter(func(l): return l.source != &"")

func frames(n: int) -> void:
	for i in n: await process_frame

func _initialize() -> void:
	await process_frame
	rs = root.get_node("RunState")
	var b: Balance = rs.balance
	check(rs.data.gadgets.size() == 8, "8 gadgets in the data")

	print("[effects]")
	var bpb := [&"bun", &"patty", &"bun"]
	var r := score(bpb, [&"cast_iron_griddle"])
	check(is_equal_approx(r.mult, 2.5) and gadget_lines(r).size() == 1, "Griddle: +0.5 per patty (mult %.1f)" % r.mult)
	check(score([&"bun", &"patty", &"cheese", &"patty", &"bun"], [&"cast_iron_griddle"]).lines.back().value == 1.0, "Griddle: two patties give +1")
	r = score([&"bun", &"patty", &"cheese", &"bun"], [&"cheese_grater"])
	check(gadget_lines(r).size() == 1 and is_equal_approx(gadget_lines(r)[0].value, 0.5), "Cheese Grater: +0.5 per melt")
	r = score(bpb, [&"sesame_seeds"])
	check(gadget_lines(r)[0].kind == ScoreResult.Kind.X_MULT and is_equal_approx(r.mult, 2.4), "Sesame Seeds: ×1.2 with bun ends (mult %.1f)" % r.mult)
	check(gadget_lines(score([&"patty", &"bun"], [&"sesame_seeds"])).is_empty(), "Sesame Seeds: nothing without bun ends")
	r = score([&"bun", &"patty", &"cheese", &"lettuce", &"tomato", &"onion", &"bun"], [&"tower_mold"])
	check(gadget_lines(r).size() == 1 and is_equal_approx(gadget_lines(r)[0].value, 1.0), "Tower Mold: 7 solids give +1.0")
	check(gadget_lines(score(bpb, [&"tower_mold"])).is_empty(), "Tower Mold: nothing for short burgers")
	r = score([&"bun", &"patty", [&"ketchup", 20], &"bun"], [&"pro_squeeze_bottle"])
	check(gadget_lines(r).size() == 1 and is_equal_approx(gadget_lines(r)[0].value, 2.0), "Pro Squeeze Bottle: 2-chip sauce adds 2 chips (got %.1f)" % gadget_lines(r)[0].value)
	r = score([&"strawberry", &"blueberry", &"banana", &"banana", &"milk"], [&"fruit_basket"], Dish.Station.SMOOTHIE)
	check(gadget_lines(r).size() == 1 and is_equal_approx(gadget_lines(r)[0].value, 3.0), "Fruit Basket: +1 per different fruit (3)")
	check(gadget_lines(score([&"strawberry", &"milk"], [&"cast_iron_griddle", &"sesame_seeds"], Dish.Station.SMOOTHIE)).is_empty(), "burger gadgets do nothing on smoothies")

	print("[counter order]")
	var a := score(bpb, [&"cast_iron_griddle", &"sesame_seeds"])
	var c := score(bpb, [&"sesame_seeds", &"cast_iron_griddle"])
	check(is_equal_approx(a.mult, 3.0) and is_equal_approx(c.mult, 2.9), "Griddle→Sesame = 3.0, Sesame→Griddle = 2.9 (got %.2f, %.2f)" % [a.mult, c.mult])
	var with_gap: Array[Gadget] = [null, g(&"cast_iron_griddle"), null]
	check(is_equal_approx(Scoring.score_dish(dish(bpb), rs.data, with_gap).mult, 2.5), "empty slots are skipped")

	print("[economy gadgets]")
	rs.new_run(400)
	check(rs.counter.size() == b.counter_slots and rs.counter.all(func(x): return x == null), "new run: empty counter of %d" % b.counter_slots)
	rs.counter[0] = g(&"tip_jar")
	var money0: int = rs.money
	var res: ScoreResult = rs.serve(dish(bpb))
	check(rs.money == money0 + rs.money_for(res.score) + 2 and res.money == rs.money_for(res.score) + 2, "Tip Jar: payout + $2")
	check(res.lines.back().kind == ScoreResult.Kind.MONEY and res.lines.back().source == &"tip_jar", "tip shows as a money line")
	rs.counter[0] = g(&"lucky_coin")
	rs.close_day()
	rs.money = 50
	check(rs.reroll_cost() == 0, "Lucky Coin: first reroll free")
	rs.reroll_shop()
	check(rs.money == 50 and rs.reroll_cost() == b.reroll_base_cost + b.reroll_cost_step, "...then the normal second-reroll price (%d)" % rs.reroll_cost())

	print("[shop]")
	rs.new_run(401)
	rs.counter[0] = g(&"tip_jar")
	rs.counter[1] = g(&"lucky_coin")
	rs.close_day()
	var offered = rs.gadget_offers.map(func(o): return o.gadget)
	check(rs.gadget_offers.size() == b.gadget_offer_slots, "%d gadget offers" % rs.gadget_offers.size())
	check(not offered.has(g(&"tip_jar")) and not offered.has(g(&"lucky_coin")), "owned gadgets aren't offered")
	check(offered[0] != offered[1], "offers are different gadgets")
	rs.money = 100
	var first: GadgetOffer = rs.gadget_offers[0]
	check(rs.buy_gadget(first) and rs.counter[2] == first.gadget and first.sold and rs.money == 100 - first.gadget.price, "buy into the leftmost free slot")
	check(not rs.buy_gadget(rs.gadget_offers[1]), "counter full: can't buy")
	var sold_price: int = rs.sell_price(rs.counter[0])
	var m: int = rs.money
	check(rs.sell_gadget(0) and rs.counter[0] == null and rs.money == m + sold_price and sold_price == floori(g(&"tip_jar").price / 2.0), "sell for half, rounded down")
	var unsold: GadgetOffer = rs.gadget_offers[1]
	rs.reroll_shop()
	check(rs.gadget_offers.size() == b.gadget_offer_slots and not rs.gadget_offers.has(first) and not rs.gadget_offers.has(unsold), "a reroll replaces every gadget offer, the bought one included")
	check(rs.gadget_offers.all(func(o): return not o.sold) and rs.gadget_offers[0].gadget != rs.gadget_offers[1].gadget, "fresh offers are for sale and different")
	check(not rs.counter.has(rs.gadget_offers[1].gadget), "rerolled offer isn't owned")
	check(rs.buy_gadget(rs.gadget_offers[1]) and rs.counter[0] != null, "a freed slot can be bought into")
	rs.end_night()
	check(not rs.sell_gadget(0), "can't sell in the kitchen")

	print("[reorder]")
	rs.counter[0] = g(&"cast_iron_griddle"); rs.counter[1] = g(&"sesame_seeds"); rs.counter[2] = g(&"tip_jar")
	rs.move_gadget(2, 0)
	check(rs.counter == counter_of([&"tip_jar", &"cast_iron_griddle", &"sesame_seeds"]), "drag rightmost onto leftmost: others shift right")

	print("[ui]")
	rs.new_run(402)
	rs.counter[0] = g(&"cast_iron_griddle"); rs.counter[1] = g(&"sesame_seeds")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	var kitchen = main.current_scene()
	var row = kitchen.get_node("%CounterRow")
	check(row.get_child_count() == b.counter_slots, "kitchen counter shows %d slots" % row.get_child_count())
	check(row.get_child(2).gadget == null, "third slot shows empty")
	row.get_child(0)._drop_data(Vector2.ZERO, row.get_child(1)._get_drag_data(Vector2.ZERO))
	await frames(1)
	check(rs.counter[0] == g(&"sesame_seeds"), "dragging a card onto another reorders the counter")
	var tally = kitchen.get_node("%Tally")
	var seen := []
	tally.line_played.connect(func(line): seen.append(line.source))
	rs.serve(dish(bpb))
	var done := [false]
	tally.finished.connect(func(): done[0] = true)
	var t := 0
	var wiggled := false
	while not done[0] and t < 600:
		await process_frame
		t += 1
		if absf(kitchen.get_node("%CounterRow").get_child(0).rotation) > 0.01: wiggled = true
	check(seen.has(&"sesame_seeds") and seen.has(&"cast_iron_griddle"), "tally plays gadget lines")
	check(wiggled, "the gadget card wiggles during the tally")
	check(tally.get_children().any(func(l): return l.text.begins_with("×1.20  Sesame Seeds")), "×mult line reads '×1.20  Sesame Seeds'")
	rs.money = 100
	kitchen.get_node("%CloseButton").pressed.emit()
	await frames(2)
	var night = main.current_scene()
	var night_row = night.get_node("%CounterRow")
	check(night_row.get_child(0).get_child(0).get_child_count() == 3, "night cards have a Sell button")
	check(night.get_node("%GadgetOffers").get_child_count() == b.gadget_offer_slots, "night shows gadget offers")

	print("RESULT: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
