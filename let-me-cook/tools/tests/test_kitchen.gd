extends SceneTree
# Day 2 playtest-changes check: drives the real kitchen scene headless.
var fails := 0
var rs
var board
var kitchen

func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond: fails += 1

func wait_frames(n: int) -> void:
	for i in n: await physics_frame

func wait_idle() -> void:
	var n := 0
	while board.is_busy() and n < 600:
		await physics_frame; n += 1
	await physics_frame

func unit_of(id: StringName):
	for u in rs.pantry:
		if u.ingredient.id == id: return u
	return null

func center(dx: float = 0.0) -> Vector2:
	return Vector2(board.size.x * 0.5 + dx, 50)

func drop(id: StringName, dx: float = 0.0) -> void:
	board.drop_unit(unit_of(id), center(dx))
	await wait_idle()

func live_point() -> Vector2:
	return board._stage.position + board._live.position

func ids(layers) -> Array:
	return layers.map(func(l): return l.ingredient.id)

func _initialize() -> void:
	await process_frame
	rs = root.get_node("RunState")
	rs.new_run(1)
	rs.add_units(&"bun", 12); rs.add_units(&"cheese", 4); rs.add_units(&"patty", 4); rs.add_units(&"ketchup", 1)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await wait_frames(3)
	kitchen = main.current_scene()
	board = kitchen.get_node("%BurgerBoard")

	print("[live layer]")
	await drop(&"bun")
	var bun_layer = board._live
	check(bun_layer != null and not bun_layer.freeze, "dropped layer is live (not frozen)")
	await drop(&"patty")
	check(bun_layer.freeze and board._entries.has(bun_layer), "next drop locks the previous layer")
	check(board._live != null and not board._live.freeze, "new layer is live")

	print("[pantry pickup locks the live layer]")
	var patty_layer = board._live
	var chip_unit = unit_of(&"cheese")
	board.force_drag({"unit": chip_unit}, null)
	await process_frame
	check(patty_layer.freeze and board._live == null, "starting a pantry drag locks the live layer")
	root.gui_cancel_drag()
	await process_frame
	check(rs.pantry.has(chip_unit), "cancelled pantry drag leaves the unit in the pantry")

	print("[re-drop the live layer]")
	await drop(&"cheese")
	var cheese_unit = board._live.unit
	var pantry_before: int = rs.pantry.size()
	var data = board._get_drag_data(live_point())
	check(data != null and data.from_board and board._live == null, "live layer can be picked up")
	check(board._can_drop_data(center(), data), "board accepts the picked-up live layer")
	board._drop_data(center(-30), data)
	await wait_idle()
	check(board._live != null and board._live.unit == cheese_unit, "re-dropped as the live layer")
	check(rs.pantry.size() == pantry_before, "re-drop does not touch the pantry")

	print("[return the live layer to the pantry]")
	data = board._get_drag_data(live_point())
	board.force_drag(data, null)
	await process_frame
	root.gui_cancel_drag()
	await process_frame
	check(rs.pantry.has(cheese_unit) and board._live == null, "releasing off the board returns it to the pantry")
	check(board.solid_count() == 2, "stack still has bun + patty")

	print("[sauce]")
	var bottle = unit_of(&"ketchup")
	var doses0: int = bottle.doses_left
	board.start_pour(bottle)
	board.set_process(false)  # headless has no held mouse button; drive doses by hand
	for dx in [0.0, 4.0, -4.0]:
		board.pour_dose(center(dx))
		await wait_frames(8)  # one dose per pour_interval, like a real pour
	board._stop_pour()
	board.set_process(true)
	check(not board.is_pouring(), "pour stopped")
	check(bottle.doses_left == doses0 - 3, "3 doses used (%d left)" % bottle.doses_left)
	await wait_frames(60)
	var smear = board._entries.back()
	check(smear is SauceSmear and smear.amount == 3, "3 doses in one sauce layer")
	check(smear.max_height() > 1.0, "sauce is visible (max height %.2f)" % smear.max_height())
	var patty_e = board._entries[1]
	check(absf(smear.position.y - (patty_e.position.y - patty_e.unit.ingredient.size.y * 0.5)) < 0.01, "sauce sits on the patty's top surface")
	var patty_top: float = board._entries[1].position.y - board._entries[1].unit.ingredient.size.y * 0.5
	var t0 := Time.get_ticks_msec()
	await drop(&"cheese")
	var cheese = board._live
	check(cheese.is_resting(), "layer on sauce comes to rest")
	var cheese_bottom: float = cheese.position.y + cheese.unit.ingredient.size.y * 0.5
	var cushion: float = smear.cushion_thickness()
	var gap: float = patty_top - cheese_bottom
	check(absf(gap - cushion) < 1.0, "cheese rests on the sauce cushion (gap %.2f, cushion %.2f)" % [gap, cushion])
	check(is_equal_approx(smear.max_height(), cushion), "covered sauce is squashed flat (%.2f)" % smear.max_height())
	var y0: float = cheese.position.y
	await wait_frames(60)
	check(absf(cheese.position.y - y0) < 0.05 and cheese.linear_velocity.length() < 0.5, "no jitter while live on sauce")
	var dish = board.take_dish()
	check(dish != null, "burger served")
	if dish:
		check(ids(dish.layers) == [&"bun", &"patty", &"ketchup", &"cheese"], "layers: %s" % [ids(dish.layers)])
		check(dish.layers[2].amount == 3, "ketchup layer amount 3")
		check(is_equal_approx(dish.layers[2].chips(), 0.3), "ketchup chips = 0.1 x 3")
		rs.serve(dish)
	check(rs.served_today.size() == 1 and kitchen.get_node("%WindowTitle").text == "Served today: 1", "serving window updated")
	check(board.is_empty(), "board empty after serve")

	print("[pour targeting and drizzle]")
	await drop(&"bun")
	check(board.is_over_pour_target(center()), "over the top layer is a pour target")
	check(not board.is_over_pour_target(center(150)), "beside the top layer is not")
	var drizzle_bottle = unit_of(&"ketchup")
	if drizzle_bottle == null:
		rs.add_units(&"ketchup", 1); drizzle_bottle = unit_of(&"ketchup")
	board.start_pour(drizzle_bottle)
	board.set_process(false)
	var bun_w: float = board._live.unit.ingredient.size.x if board._live else board._entries.back().unit.ingredient.size.x
	var steps := 20
	for k in steps + 1:
		board.pour_dose(center(-bun_w * 0.5 + bun_w * k / steps))
		await wait_frames(3)
	board._stop_pour()
	board.set_process(true)
	await wait_frames(30)
	var line = board._entries.back()
	var covered := true
	for k in 11:
		var x: float = -bun_w * 0.5 + 4.0 + (bun_w - 8.0) * k / 10.0
		if line.height_at(x) < SauceSmear.MIN_VISIBLE: covered = false
	check(covered, "moving pour draws a continuous line across the bun")
	var drizzled = board.take_dish()
	check(drizzled != null and drizzled.layers.size() == 2 and drizzled.layers[1].amount == steps + 1, "all %d doses counted" % (steps + 1))

	print("[bottle runs out]")
	await drop(&"bun")
	board.start_pour(bottle)
	var n := 0
	while board.is_pouring() and n < 100:
		board.pour_dose(center()); n += 1
	check(not rs.pantry.has(bottle) and bottle.doses_left == 0, "empty bottle removed from pantry")

	print("[clear: solids back, sauce lost]")
	await wait_frames(60)
	var buns: int = rs.count_of(&"bun")
	board.clear()
	check(rs.count_of(&"bun") == buns + 1 and board.is_empty(), "bun returned on clear")

	print("[collapse happens on lock, adjusting avoids it]")
	await drop(&"bun"); await drop(&"patty", 120.0)
	check(not board.ruined and board.stability < 0, "offset live layer: preview shows collapse, not yet ruined")
	data = board._get_drag_data(live_point())
	board._drop_data(center(), data)
	await wait_idle()
	await drop(&"cheese")
	check(not board.ruined, "re-centred before locking: no collapse")
	board.clear()
	await drop(&"bun"); await drop(&"patty", 120.0)
	check(board.take_dish() == null, "serving an unstable burger serves nothing")
	await wait_idle()
	check(board.ruined, "...and it collapses")
	check(kitchen.get_node("%ServeButton").disabled and kitchen.get_node("%ClearButton").text == "Discard", "serve disabled, Discard shown")
	board.clear()

	print("[close for the day]")
	await drop(&"bun")
	buns = rs.count_of(&"bun")
	kitchen.get_node("%CloseButton").pressed.emit()
	check(rs.count_of(&"bun") == buns + 1 and board.is_empty(), "closing clears the board back into the pantry")
	check(rs.phase == rs.Phase.NIGHT and rs.served_today.is_empty(), "closing leads to the night, served list reset")

	print("[stability math]")
	var b = rs.balance
	check(is_equal_approx(Stability.compute([{x=0.0,width=180.0},{x=0.0,width=160.0}], b), 1.0), "centered = 1.0")
	check(Stability.compute([{x=0.0,width=180.0},{x=95.0,width=160.0}], b) < 0, "center past edge = collapse")

	print("RESULT: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
