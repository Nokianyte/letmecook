extends SceneTree
# Player guidance: live preview and callouts, the "if served now" list, today's specials,
# and the guided tutorial (including recovery, skip and the "?" menu).
var fails := 0
var rs
var main
var board
var kitchen

const SETTINGS := "user://test_tutorial_settings.cfg"


func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond: fails += 1


func frames(n: int) -> void:
	for i in n: await process_frame


func physics(n: int) -> void:
	for i in n: await physics_frame


func unit_of(id: StringName):
	for u in rs.pantry:
		if u.ingredient.id == id: return u
	return null


func g(id: StringName) -> Gadget:
	for x in rs.data.gadgets:
		if x.id == id: return x
	return null


func recipe(name: String) -> Recipe:
	for r in rs.data.recipes:
		if r.display_name == name: return r
	return null


func center(dx := 0.0) -> Vector2:
	return Vector2(board.size.x / 2 + dx, 50)


func drop(id: StringName, dx := 0.0) -> void:
	board.drop_unit(unit_of(id), center(dx))
	await physics(110)
	await frames(1)


## Every callout that appeared since the last clear_callouts() (they fade within ~1 s).
var seen_callouts: Array[String] = []


func callout_texts() -> Array[String]:
	return seen_callouts


func clear_callouts() -> void:
	seen_callouts.clear()


func _record_callout(node: Node) -> void:
	seen_callouts.append(node.text)


func open_kitchen() -> void:
	kitchen = main.current_scene()
	board = kitchen.get_node("%BurgerBoard")
	kitchen.get_node("Callouts").child_entered_tree.connect(_record_callout)


func _initialize() -> void:
	OS.set_environment("LETMECOOK_SETTINGS", SETTINGS)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	await process_frame
	rs = root.get_node("RunState")
	rs.new_run(600)
	rs.add_units(&"bun", 6); rs.add_units(&"cheese", 2); rs.add_units(&"lettuce", 1)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	main.tutorial._offer.visible = false
	open_kitchen()
	var tally = kitchen.get_node("%Tally")

	print("[live preview and callouts]")
	await drop(&"bun")
	clear_callouts()
	await drop(&"patty")
	check(callout_texts().any(func(t): return t.contains("Patty")), "patty lands: chips callout (%s)" % [callout_texts()])
	clear_callouts()
	await drop(&"cheese")
	var texts: Array[String] = callout_texts().duplicate()
	check(texts.any(func(t): return t.contains("Cheese")) and texts.any(func(t): return t.contains("Melt")), "cheese on patty: chips + melt callouts (%s)" % [texts])
	await drop(&"bun")
	check(tally.get_child(0).text == "If served now", "the window lists 'If served now'")
	var listed = tally.get_children().map(func(c): return c.text)
	check(listed.any(func(t): return t.contains("Classic Cheese")) and listed.back().begins_with("≈"), "list shows the recipe and the expected score")
	var preview: ScoreResult = kitchen.live_preview.score(board.preview_dish())
	clear_callouts()
	await drop(&"lettuce")
	check(callout_texts().any(func(t): return t == "lost: Bun on both ends") and callout_texts().any(func(t): return t == "lost: Classic Cheese"), "lettuce on top: lost callouts (%s)" % [callout_texts()])
	board._get_drag_data(board._stage.position + board._live.position)  # take the lettuce back
	rs.return_unit(board._dragged_live_unit); board._dragged_live_unit = null
	await frames(2)
	kitchen.get_node("%ServeButton").pressed.emit()
	await frames(1)
	check(rs.served_today.back().result.score == preview.score, "served score equals the preview (%d)" % preview.score)
	check(tally.is_playing(), "serving plays the tally instead of the list")

	print("[sauce: one callout per pour]")
	await frames(120)
	await drop(&"stale_bread")
	clear_callouts()
	board.start_pour(unit_of(&"ketchup"))
	board.set_process(false)
	for i in 12:
		board.pour_dose(center())
	board._stop_pour()
	board.set_process(true)
	await frames(2)
	var sauce_callouts: Array = callout_texts().filter(func(t): return t.contains("Ketchup"))
	check(sauce_callouts.size() == 1 and sauce_callouts[0].contains("×12"), "one ketchup callout for the pour (%s)" % [sauce_callouts])
	board.clear()
	await frames(2)

	print("[specials]")
	check(rs.specials.size() == rs.balance.specials_count, "%d specials" % rs.specials.size())
	var smoothies_without_blender := false
	var redraws := 0
	for s in 30:
		var a := Specials.draw(rs.data, 700 + s, 1, false)
		var b := Specials.draw(rs.data, 700 + s, 1, false)
		if a != b: fails += 1
		if a.any(func(r): return r.station == Recipe.Station.SMOOTHIE): smoothies_without_blender = true
		if Specials.draw(rs.data, 700 + s, 2, false) != a: redraws += 1
	check(not smoothies_without_blender, "no smoothie specials without a blender (30 seeds)")
	check(redraws > 15, "specials change from day to day (%d/30 seeds)" % redraws)
	check(Specials.draw(rs.data, 5, 1, true).size() == 3, "draws work with a blender too")
	var classic := recipe("Classic Cheese")
	var plain: Array[Gadget] = []
	var with_sesame: Array[Gadget] = [g(&"sesame_seeds")]
	check(Specials.value(classic, rs.data, plain).score == 81, "Classic Cheese is worth 81 fresh")
	check(Specials.value(classic, rs.data, with_sesame).score > 81, "...more with Sesame Seeds (%d)" % Specials.value(classic, rs.data, with_sesame).score)
	var partial := Dish.new(Recipe.Station.BURGER)
	partial.layers.append(DishLayer.new(rs.get_ingredient(&"bun"), 1.0))
	partial.layers.append(DishLayer.new(rs.get_ingredient(&"patty"), 1.0))
	check(Specials.progress(classic, partial) == [true, true, false, false], "progress ticks: bun, patty done; cheese, top bun to go")
	var board_specials: Array[Recipe] = [classic, recipe("Struggle Burger"), recipe("Garden Stack")]
	rs.specials = board_specials
	rs.changed.emit()
	await frames(1)
	await drop(&"bun"); await drop(&"patty"); await drop(&"cheese"); await drop(&"bun")
	var strip = kitchen.get_node("%SpecialsStrip")
	check(strip._cards[0].get_theme_stylebox("panel") == strip._matched_style, "a matched special is highlighted")
	check(strip._ingredient_labels[0].text.count("7ee07e") == 4, "all four Classic Cheese ingredients ticked")
	board.clear()
	await frames(2)
	var struggle := Dish.new(Recipe.Station.BURGER)
	for id in [&"stale_bread", &"ketchup", &"stale_bread"]:
		struggle.layers.append(DishLayer.new(rs.get_ingredient(id), 1.0, 10 if id == &"ketchup" else 1))
	var just_classic: Array[Recipe] = [classic]
	rs.specials = just_classic
	check(Scoring.score_dish(struggle, rs.data).recipe_name == "Struggle Burger", "off-board recipes still score")

	print("[tutorial]")
	var tutorial = main.tutorial
	check(not tutorial.is_done(), "fresh settings: tutorial not done")
	tutorial.start()
	await frames(3)
	open_kitchen()
	check(tutorial.step == 0 and tutorial._bubble.visible, "starts at step 1 with the coach visible")
	check(tutorial._highlight_rect.has_area(), "step 1 highlights the stale bread chip")
	await drop(&"stale_bread"); await frames(1)
	check(tutorial.step == 1, "bread on the plate: step 2")
	await drop(&"patty"); await frames(1)
	check(tutorial.step == 2, "patty on top: step 3")
	board.start_pour(unit_of(&"ketchup"))
	board.set_process(false)
	for i in 5: board.pour_dose(center())
	board._stop_pour()
	board.set_process(true)
	await frames(2)
	check(tutorial.step == 3, "ketchup poured: step 4")
	await drop(&"stale_bread"); await frames(2)
	check(tutorial.step == 4, "bread on top: step 5 (serve)")
	kitchen.get_node("%ServeButton").pressed.emit()
	await frames(2)
	check(tutorial.step == 5 and tutorial._next_button.visible, "served: explanation step with Next")
	tutorial._advance(); await frames(1)
	check(tutorial.step == 6, "Next: specials step")
	tutorial._advance(); await frames(1)
	kitchen.get_node("%CloseButton").pressed.emit()
	await frames(3)
	check(tutorial.step == 8 and rs.phase == rs.Phase.NIGHT, "closed the day: night steps")
	check(tutorial._highlight_rect.has_area(), "night step highlights the market")
	for i in 4:
		tutorial._advance(); await frames(1)
	check(tutorial.step == -1 and tutorial.is_done(), "finished: tutorial done and saved")

	print("[tutorial recovery and skip]")
	tutorial.start()
	await frames(3)
	open_kitchen()
	await drop(&"stale_bread")
	await drop(&"patty", 130.0)
	await drop(&"stale_bread")  # locks the offset patty -> collapse
	await physics(90); await frames(2)
	check(board.ruined and tutorial._bubble_text.text.begins_with("It fell over!"), "collapse: recovery advice")
	board.clear()
	await frames(2)
	check(tutorial.step == 0, "board emptied: back to step 1")
	tutorial.skip()
	check(not tutorial.is_running() and not tutorial._bubble.visible, "skip hides the coach")

	print("[first launch and ? menu]")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	tutorial.offer_if_first_time()
	check(tutorial._offer.visible, "no settings: the first-launch offer shows")
	tutorial._stop()
	tutorial._offer.visible = false
	tutorial.offer_if_first_time()
	check(not tutorial._offer.visible, "after skipping, no offer on the next launch")
	kitchen.get_node("%HelpButton").pressed.emit()
	check(tutorial._menu.visible, "? opens the help menu")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))

	print("RESULT: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
