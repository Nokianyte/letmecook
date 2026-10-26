extends SceneTree
# Edge cases from the ship bug pass: drops during settle, empty bottles, sauce-only
# plates, gadget self-drops, closing mid-tally, skipping a day with food on the board.
var fails := 0
var rs
var main
var kitchen
var board

func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond: fails += 1

func unit_of(id: StringName):
	for u in rs.pantry:
		if u.ingredient.id == id: return u
	return null

func frames(n: int) -> void:
	for i in n: await process_frame

func physics(n: int) -> void:
	for i in n: await physics_frame

func center() -> Vector2:
	return Vector2(board.size.x / 2, 50)

func open_kitchen() -> void:
	kitchen = main.current_scene()
	board = kitchen.get_node("%BurgerBoard")

func _initialize() -> void:
	OS.set_environment("LETMECOOK_SETTINGS", "user://test_edge_settings.cfg")
	await process_frame
	rs = root.get_node("RunState")
	rs.new_run(500)
	rs.add_units(&"bun", 6); rs.add_units(&"patty", 2)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	open_kitchen()

	print("[drop while a layer is falling]")
	board.drop_unit(unit_of(&"bun"), center())
	var patty = unit_of(&"patty")
	check(not board._can_drop_data(center(), {"unit": patty}), "a second drop is refused while the first layer falls")
	check(rs.pantry.has(patty), "the refused unit stays in the pantry")
	await physics(120)
	check(board._can_drop_data(center(), {"unit": patty}), "accepted once the layer has landed")

	print("[empty bottle]")
	var bottle = unit_of(&"ketchup")
	var doses: int = bottle.doses_left
	bottle.doses_left = 0
	board.start_pour(bottle)
	check(not board.is_pouring(), "an empty bottle doesn't start pouring")
	bottle.doses_left = doses

	print("[sauce-only plate]")
	board.clear()
	await frames(1)
	board.start_pour(bottle)
	board.set_process(false)
	board.pour_dose(center())
	board._stop_pour()
	board.set_process(true)
	await frames(1)
	check(board.solid_count() == 0 and kitchen.get_node("%ServeButton").disabled, "serve is disabled with only sauce on the plate")
	check(board.take_dish() == null, "...and nothing can be served")
	board.clear()

	print("[gadget dropped on its own slot]")
	rs.counter[0] = rs.data.gadgets[0]
	rs.changed.emit()
	await frames(1)
	var card = kitchen.get_node("%CounterRow").get_child(0)
	check(not card._can_drop_data(Vector2.ZERO, {"gadget_slot": 0}), "a card doesn't accept itself")

	print("[close the day while the tally plays]")
	board.drop_unit(unit_of(&"bun"), center()); await physics(100)
	board.drop_unit(unit_of(&"bun"), center()); await physics(100)
	kitchen.get_node("%ServeButton").pressed.emit()
	await frames(2)
	kitchen.get_node("%CloseButton").pressed.emit()
	await frames(120)
	check(rs.phase == rs.Phase.NIGHT and is_instance_valid(main.current_scene()), "closing mid-tally goes to the night cleanly")

	print("[debug skip day with food on the board]")
	main.current_scene().get_node("%OpenButton").pressed.emit()
	await frames(2)
	open_kitchen()
	var buns: int = rs.count_of(&"bun")
	board.drop_unit(unit_of(&"bun"), center())
	await physics(100)
	check(rs.count_of(&"bun") == buns - 1, "bun is on the board")
	main.debug_overlay._skip_day()
	await frames(2)
	check(rs.count_of(&"bun") == buns, "skipping the day returns the board's bun to the pantry")

	print("[layout change mid-build]")
	main.debug_overlay._skip_day()  # night -> kitchen
	await frames(2)
	open_kitchen()
	board.drop_unit(unit_of(&"bun"), center()); await physics(100)
	board.drop_unit(unit_of(&"patty"), center()); await physics(100)
	var live = board._live
	var before: Vector2 = live.global_position
	var stage_before: Vector2 = board._stage.position
	board.size.y -= 42.0  # e.g. a panel above the board grows for a moment
	await frames(2)
	board.size.y += 42.0
	await frames(2)
	check(board._stage.position == stage_before, "the stage doesn't move under a burger")
	board.drop_unit(unit_of(&"bun"), center())  # locks the patty
	await physics(5)
	check(live.global_position.distance_to(before) < 0.5, "locking doesn't teleport the layer (moved %.1f px)" % live.global_position.distance_to(before))
	# Godot can re-apply a stale transform to a body frozen right after landing (seen in a
	# real window only); a locked layer must undo any move that isn't the board's.
	var locked_at: Vector2 = live.global_position
	live.global_position += Vector2(0, -42)
	await physics(2)  # transform-change notifications arrive later in the frame
	check(live.global_position.distance_to(locked_at) < 0.01, "a locked layer snaps back if something moves it")
	board.clear()
	await physics(100)
	board.clear()
	await frames(2)

	print("[help menu]")
	main.current_scene().get_node("%HelpButton").pressed.emit()
	check(main.tutorial._menu.visible, "the ? button opens the help menu")
	main.tutorial._menu.visible = false

	print("RESULT: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
