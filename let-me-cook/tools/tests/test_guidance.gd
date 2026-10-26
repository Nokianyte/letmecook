extends SceneTree
# Player guidance: live preview and callouts, the "if served now" list, the combo board
# and discovery, and the guided tutorial (including recovery, skip and the "?" menu).
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


func center(dx := 0.0) -> Vector2:
	return Vector2(board.size.x / 2 + dx, 50)


func drop(id: StringName, dx := 0.0) -> void:
	board.drop_unit(unit_of(id), center(dx))
	await physics(110)
	await frames(1)


## Every callout that appeared since the last clear_callouts() (they fade within ~1 s).
var seen_callouts: Array[String] = []
## Callout text -> font size.
var callout_sizes := {}


func callout_texts() -> Array[String]:
	return seen_callouts


func clear_callouts() -> void:
	seen_callouts.clear()
	callout_sizes.clear()


func _record_callout(node: Node) -> void:
	seen_callouts.append(node.text)
	callout_sizes[node.text] = node.get_theme_font_size("font_size")


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
	rs.add_units(&"bun", 6); rs.add_units(&"cheese", 2); rs.add_units(&"lettuce", 2); rs.add_units(&"patty", 2)
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
	check(callout_sizes.get("+0.5  Melt", 0) > callout_sizes.get("+4.0  Cheese (100%)", 99), "the mult callout is bigger than the chips one (%s)" % [callout_sizes])
	await drop(&"bun")
	check(tally.get_child(0).text == "If served now", "the window lists 'If served now'")
	var listed = tally.get_children().map(func(c): return c.text)
	check(listed.has("+1.0  Bun ends") and listed.has("+0.5  Melt") and listed.back().begins_with("≈"), "list shows the combos and the expected score (%s)" % [listed])
	var preview: ScoreResult = kitchen.live_preview.score(board.preview_dish())
	clear_callouts()
	await drop(&"lettuce")
	check(callout_texts().any(func(t): return t == "lost: Bun ends"), "lettuce on top: lost callout (%s)" % [callout_texts()])
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

	print("[combo board and discovery]")
	var combo_board = kitchen.get_node("%ComboBoard")
	# The sauce test above discovered Soggy bottom; start from a fresh save.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	rs.load_discoveries()
	combo_board._rebuild()
	var height: float = combo_board.size.y
	var shown = combo_board.shown_combos().map(func(c): return c.id)
	check(shown == [&"bun_ends", &"melt", &"sauced_patty"], "fresh save: only the starters (%s)" % [shown])
	check(combo_board._hidden_label.text.contains("8 more combos"), "a cell counts the rest: %s" % combo_board._hidden_label.text)
	clear_callouts()
	await drop(&"bun"); await drop(&"lettuce")
	check(callout_texts().has("New combo! Lettuce shield +0.5"), "first lettuce shield: New combo! callout (%s)" % [callout_texts()])
	check(rs.discovered.has(&"lettuce_shield") and combo_board.shown_combos().any(func(c): return c.id == &"lettuce_shield"), "...added to the board")
	check(Array(Settings.get_value("combos", "discovered", [])).has("lettuce_shield"), "...and saved")
	await drop(&"patty"); await drop(&"cheese"); await drop(&"patty")
	var lit: Dictionary = combo_board.active()
	check(lit.get(&"melt") == 2 and lit.get(&"double_decker") == 1 and lit.has(&"lettuce_shield"), "active combos lit up, Melt ×2 (%s)" % [lit])
	check(combo_board._chips[&"melt"].count.text == "×2", "the Melt chip shows ×2")
	check(is_equal_approx(combo_board.size.y, height), "the board's height never changes (%.0f)" % combo_board.size.y)
	clear_callouts()
	await drop(&"lettuce")
	check(not callout_texts().any(func(t): return t.begins_with("New combo! Lettuce")), "no second New combo! for a known combo")
	board.clear()
	await frames(2)
	check(combo_board.active().is_empty(), "nothing lit with an empty board")
	rs.discovered.clear()
	rs.load_discoveries()  # what a new run or a reload does
	check(rs.discovered.has(&"lettuce_shield") and rs.discovered.has(&"double_decker"), "discoveries are loaded back from the save")
	for combo in rs.data.combos:
		rs.discover(combo)
	await frames(2)
	check(combo_board.shown_combos().size() == 11 and combo_board._hidden_label == null, "everything discovered: 11 burger combos, no counter cell")
	var content: Vector2 = combo_board._grid.get_combined_minimum_size()
	check(content.x <= combo_board.size.x and content.y <= combo_board.size.y, "all burger combos fit the board (%s in %s)" % [content, combo_board.size])
	check(is_equal_approx(combo_board.size.y, height), "...at the same height")
	rs.has_blender = true
	combo_board.show_dish(Dish.Station.SMOOTHIE, null)
	check(combo_board.station == Dish.Station.SMOOTHIE and combo_board.shown_combos().size() == 6 and combo_board._chips.has(&"berry_blast"), "smoothie dish: smoothie combos")
	rs.has_blender = false
	rs.changed.emit()
	check(combo_board.station == Dish.Station.BURGER, "no blender: back to burger combos")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	rs.load_discoveries()

	print("[tally fits]")
	rs.add_units(&"patty", 4); rs.add_units(&"cheese", 4)
	await drop(&"bun")
	for i in 4:
		await drop(&"patty"); await drop(&"cheese")
	await drop(&"bun")
	kitchen.get_node("%ServeButton").pressed.emit()
	await frames(2)
	var waited := 0
	while tally.is_playing() and waited < 1200:
		await frames(1); waited += 1
	var texts_tall = tally.get_children().map(func(c): return c.text)
	check(texts_tall.has("+3.5  Melt ×7"), "repeated melts grouped (%s)" % [texts_tall])
	check(kitchen.get_node("%Window").get_global_rect().end.y <= root.get_visible_rect().size.y + 0.5, "the serving window stays on screen")
	check(kitchen.get_node("Margin/VBox/CounterBar").get_global_rect().position.y >= 0, "the layout isn't pushed off the top")

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
	check(tutorial.step == 6 and tutorial._highlight_rect.has_area(), "Next: combo board step")
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
