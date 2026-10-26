extends SceneTree
# Day 4 check: rent, win/loss, market, rerolls, staples, tools, fridge, decay, scene flow.
var fails := 0
var rs

func check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond: fails += 1

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

	print("[rent and night]")
	rs.new_run(7)
	var patties: int = rs.count_of(&"patty")
	check(rs.phase == rs.Phase.KITCHEN and rs.day == 1 and rs.money == b.starting_money, "new run starts in the day 1 kitchen")
	rs.close_day()
	check(rs.money == b.starting_money - b.rent_for_day(1), "rent deducted (%d left)" % rs.money)
	check(rs.phase == rs.Phase.NIGHT and rs.day == 1, "night after day 1")
	check(rs.count_of(&"patty") == patties, "leftovers carry over")

	print("[market]")
	check(rs.shop_stock.size() == b.shop_stock_slots, "%d stock slots" % rs.shop_stock.size())
	check(rs.shop_stock.all(func(o): return not b.staple_ids.has(o.ingredient.id)), "staples are not in the random stock")
	check(rs.shop_stock.all(func(o): return o.quantity == 1 if o.ingredient.is_sauce() else o.quantity in [1, 2, 3]), "sauces are single bottles, solids 1-3")
	check(rs.shop_stock.all(func(o): return o.price == ShopOffer.bulk_price(o.ingredient.price, o.quantity, b.bulk_discount_per_extra_unit)), "prices follow the bulk rule")
	var patty: Ingredient = rs.get_ingredient(&"patty")
	check([1, 2, 3].map(func(q): return ShopOffer.new(patty, q, 1.0, 0.1).price) == [4, 7, 10], "patties: 1 for $4, 2 for $7, 3 for $10")
	var onion: Ingredient = rs.get_ingredient(&"onion")
	check([1, 2, 3].map(func(q): return ShopOffer.new(onion, q, 1.0, 0.1).price) == [1, 2, 2], "cheap items: rounding keeps small bundles sane")
	rs.money = 100
	var offer: ShopOffer = rs.shop_stock[0]
	var before: int = rs.count_of(offer.ingredient.id)
	check(rs.buy_offer(offer) and offer.sold and rs.money == 100 - offer.price, "buying deducts the price and marks it sold")
	check(rs.count_of(offer.ingredient.id) == before + offer.quantity, "bought units go to the pantry")
	check(not rs.buy_offer(offer), "a sold slot can't be bought again")
	rs.money = 0
	check(not rs.buy_offer(rs.shop_stock[1]), "can't buy without money")

	print("[rerolls]")
	rs.money = 100
	var kept = rs.shop_stock[0]
	var old1 = rs.shop_stock[1]
	var costs := []
	for i in 3:
		costs.append(rs.reroll_cost())
		rs.reroll_shop()
	check(costs == [b.reroll_base_cost, b.reroll_base_cost + b.reroll_cost_step, b.reroll_base_cost + 2 * b.reroll_cost_step], "reroll costs rise: %s" % [costs])
	check(rs.money == 100 - costs.reduce(func(acc, c): return acc + c, 0), "rerolls are paid")
	check(rs.shop_stock[0] != kept and rs.shop_stock[1] != old1, "a reroll replaces every slot, sold ones included")
	check(rs.shop_stock.all(func(o): return not o.sold), "after a reroll every slot is for sale")
	for o in rs.shop_stock.duplicate():
		rs.money = 100
		rs.buy_offer(o)
	rs.money = 100
	rs.reroll_shop()
	check(rs.shop_stock.all(func(o): return not o.sold) and rs.shop_stock[0].quantity == 1 and rs.shop_stock[0].ingredient.has_tag(&"meat"), "buying out the market then rerolling restocks it (meat still first)")

	print("[staples]")
	var bread: int = rs.count_of(&"stale_bread")
	var m: int = rs.money
	check(rs.buy_staple(&"stale_bread") and rs.buy_staple(&"stale_bread") and rs.count_of(&"stale_bread") == bread + 2, "staples: one per purchase")
	check(rs.money == m - 2 * rs.get_ingredient(&"stale_bread").price, "staples cost their price")
	var nightly: int = b.staple_stock[&"stale_bread"]
	while rs.buy_staple(&"stale_bread"):
		pass
	check(rs.count_of(&"stale_bread") == bread + nightly and rs.staples_left[&"stale_bread"] == 0, "stale bread sells out after %d tonight" % nightly)
	rs.reroll_shop()
	check(rs.staples_left[&"stale_bread"] == 0, "a reroll doesn't restock staples")
	check(not rs.buy_staple(&"patty"), "non-staples can't be bought as staples")

	print("[tools]")
	rs.money = 100
	check(rs.blender_on_sale() and rs.buy_blender() and rs.has_blender and not rs.blender_on_sale(), "blender: bought once, then gone")
	var slots: int = rs.fridge_slots
	check(rs.buy_fridge_upgrade() and rs.fridge_slots == slots + b.fridge_upgrade_slots, "fridge upgrade adds slots")
	rs.money = 1000
	while rs.fridge_upgrade_on_sale():
		rs.buy_fridge_upgrade()
	check(rs.fridge_slots == b.fridge_max_slots, "fridge stops at its max (%d)" % rs.fridge_slots)

	print("[fridge and decay]")
	rs.new_run(8)
	rs.close_day()
	rs.add_units(&"lettuce", 1, 0.2)
	var p_out = unit_of(&"patty")
	var p_in = rs.pantry.filter(func(u): return u.ingredient.id == &"patty")[1]
	var sb = unit_of(&"stale_bread")
	var lettuce = unit_of(&"lettuce")
	check(rs.set_in_fridge(p_in, true) and p_in.in_fridge, "move a patty into the fridge")
	for u in rs.pantry:
		if not u.in_fridge and u != p_out and u != lettuce:
			rs.set_in_fridge(u, true)
	check(rs.fridge_used() == rs.fridge_slots, "fridge filled to %d" % rs.fridge_slots)
	check(not rs.set_in_fridge(p_out, true) and not p_out.in_fridge, "a full fridge refuses more")
	rs.end_night()
	check(rs.phase == rs.Phase.KITCHEN and rs.day == 2, "night ends into the day 2 kitchen")
	check(is_equal_approx(p_out.freshness, 1.0 - b.perishable_decay_outside), "patty outside: %.2f" % p_out.freshness)
	check(is_equal_approx(p_in.freshness, 1.0 - b.perishable_decay_inside), "patty in fridge: %.2f" % p_in.freshness)
	check(is_equal_approx(sb.freshness, 1.0), "staples never decay")
	check(not rs.pantry.has(lettuce) and rs.spoiled_overnight.has(lettuce), "lettuce at 0 spoiled and was removed")
	rs.close_day()
	check(rs.reroll_cost() == b.reroll_base_cost, "reroll cost resets each night")
	check(rs.staples_left[&"stale_bread"] == b.staple_stock[&"stale_bread"], "staples are restocked the next night")

	print("[win and loss]")
	rs.new_run(9)
	rs.money = 0
	rs.close_day()
	check(rs.phase == rs.Phase.RUN_OVER and not rs.run_won, "can't pay rent: run lost")
	rs.new_run(10)
	rs.day = b.days_per_run
	rs.money = 1000
	rs.close_day()
	check(rs.phase == rs.Phase.RUN_OVER and rs.run_won, "rent paid on the last day: run won")

	print("[seed]")
	rs.new_run(42)
	rs.close_day()
	var a = rs.shop_stock.map(func(o): return [o.ingredient.id, o.quantity])
	rs.new_run(42)
	rs.close_day()
	var c = rs.shop_stock.map(func(o): return [o.ingredient.id, o.quantity])
	check(a == c, "same seed, same market")

	print("[scene flow]")
	rs.new_run(11)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	var kitchen = main.current_scene()
	var board = kitchen.get_node("%BurgerBoard")
	board.drop_unit(unit_of(&"patty"), Vector2(board.size.x / 2, 50))
	for i in 120:
		await physics_frame
	var patty_count: int = rs.count_of(&"patty")
	kitchen.get_node("%CloseButton").pressed.emit()
	await frames(2)
	check(rs.count_of(&"patty") == patty_count + 1, "closing returns the burger in progress to the pantry")
	var night = main.current_scene()
	check(night.name == "Night", "night scene shown")
	check(night.get_node("%Stock").get_child_count() == b.shop_stock_slots, "market cards shown")
	var bread_before: int = rs.count_of(&"stale_bread")
	var staple_button: Button = night.get_node("%Staples").get_child(0).get_child(0).get_child(3)
	staple_button.pressed.emit()
	await frames(1)
	check(rs.count_of(&"stale_bread") == bread_before + 1, "staple card buys stale bread")
	rs.add_units(&"lettuce", 1, 0.1)
	night = main.current_scene()
	night.get_node("%OpenButton").pressed.emit()
	await frames(2)
	kitchen = main.current_scene()
	check(kitchen.name == "Kitchen" and rs.day == 2, "open the kitchen: day 2")
	var notice: Label = kitchen.get_node("%SpoiledNotice")
	check(notice.visible and notice.text.contains("Lettuce"), "morning notice: %s" % notice.text)
	rs.money = 0
	kitchen.get_node("%CloseButton").pressed.emit()
	await frames(2)
	var over = main.current_scene()
	check(over.name == "RunOver" and over.get_node("%SeedLabel").text == "Seed 11", "run over shows the seed")
	check(over.get_node("%ResultLabel").text == "Evicted", "loss result shown")
	over.get_node("%NewRunButton").pressed.emit()
	await frames(2)
	check(main.current_scene().name == "Kitchen" and rs.day == 1 and rs.run_seed != 11, "new run starts in the kitchen")

	print("RESULT: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
