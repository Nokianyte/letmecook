extends SceneTree
# Economy simulator: plays full runs through the real rules with simple bots.
# Usage: godot --headless --path . --script res://tools/sim.gd
#   env SIM_RUNS=200, SIM_SET="rent=5,8,...;bread=4;struggle=1.0;smoothie_chips=1.0;combo:melt=0.5;<any Balance field>=value"
var rs
const SAUCE_DOSES := 10
const STRUGGLE_DOSES := 20

func units(id: StringName) -> Array:
	var u = rs.pantry.filter(func(x): return x.ingredient.id == id)
	u.sort_custom(func(a, b): return a.freshness > b.freshness)
	return u

func first_with_tag(tag: StringName, exclude: Array) -> IngredientUnit:
	var best: IngredientUnit = null
	for u in rs.pantry:
		if u.ingredient.has_tag(tag) and not exclude.has(u) and not u.ingredient.is_sauce():
			# prefer real buns over stale bread, then freshness
			if best == null or u.ingredient.base_chips > best.ingredient.base_chips or (u.ingredient == best.ingredient and u.freshness > best.freshness):
				best = u
	return best

func bottle() -> IngredientUnit:
	for u in rs.pantry:
		if u.ingredient.is_sauce() and u.doses_left > 0:
			return u
	return null

# A candidate is an array of [unit, amount] bottom to top (amount > 1 only for sauces).
func candidates() -> Array:
	var result := []
	var used := []
	var bottom := first_with_tag(&"bun", used)
	if bottom == null:
		return result
	used.append(bottom)
	var top := first_with_tag(&"bun", used)
	if top == null:
		return result
	used.append(top)
	var patties := units(&"patty")
	var cheeses := units(&"cheese")
	var sauce := bottle()
	var lettuce := units(&"lettuce")
	var crown := []  # veg under the top bun: tomato, then onion + pickles touching
	for v in [&"tomato", &"onion", &"pickles"]:
		var vu := units(v)
		if vu.size() > 0: crown.append([vu[0], 1])
	if patties.size() > 0:
		# combo stack: bun, lettuce (shield), cheese, patty (melt), sauce (sauced patty), veg (crown), bun
		var stack := [[bottom, 1]]
		if lettuce.size() > 0: stack.append([lettuce[0], 1])
		if cheeses.size() > 0: stack.append([cheeses[0], 1])
		stack.append([patties[0], 1])
		if sauce: stack.append([sauce, mini(SAUCE_DOSES, sauce.doses_left)])
		stack.append_array(crown)
		stack.append([top, 1])
		result.append(stack)
		if cheeses.size() > 0:
			result.append([[bottom, 1], [patties[0], 1], [cheeses[0], 1], [top, 1]])
		if patties.size() > 1 and cheeses.size() > 0:
			# double decker: patty, cheese, patty (two melts), sauce on the top patty
			var double := [[bottom, 1]]
			if lettuce.size() > 0: double.append([lettuce[0], 1])
			double.append_array([[patties[0], 1], [cheeses[0], 1], [patties[1], 1]])
			if sauce: double.append([sauce, mini(SAUCE_DOSES, sauce.doses_left)])
			double.append_array(crown)
			double.append([top, 1])
			result.append(double)
	if sauce and sauce.ingredient.id == &"ketchup" and bottom.ingredient.id == &"stale_bread" and top.ingredient.id == &"stale_bread":
		result.append([[bottom, 1], [sauce, mini(STRUGGLE_DOSES, sauce.doses_left)], [top, 1]])
	if result.is_empty():
		# bread + sauce + bread without a combo beyond the bun ends
		var plain := [[bottom, 1]]
		if sauce: plain.append([sauce, mini(SAUCE_DOSES, sauce.doses_left)])
		plain.append([top, 1])
		result.append(plain)
	return result

func to_dish(cand: Array) -> Dish:
	var d := Dish.new(Dish.Station.BURGER)
	for entry in cand:
		d.layers.append(DishLayer.new(entry[0].ingredient, entry[0].freshness, entry[1]))
	return d

func consume(cand: Array) -> void:
	for entry in cand:
		var u: IngredientUnit = entry[0]
		if u.ingredient.is_sauce():
			u.doses_left -= entry[1]
			if u.doses_left <= 0: rs.pantry.erase(u)
		else:
			rs.pantry.erase(u)

func smoothie_candidate() -> Array:
	for recipe_ids in [[&"spinach", &"banana", &"milk"], [&"strawberry", &"blueberry", &"yogurt"], [&"banana", &"milk"]]:
		var picked := []
		for id in recipe_ids:
			var u := units(id)
			if u.is_empty(): break
			picked.append(u[0])
		if picked.size() == recipe_ids.size():
			return picked
	# No recipe: blend whatever smoothie units there are (up to 4), dropping one if it's muddy.
	var any = rs.pantry.filter(func(u): return u.ingredient.smoothie_ok)
	any.sort_custom(func(a, b): return a.ingredient.base_chips > b.ingredient.base_chips)
	any = any.slice(0, 4)
	if any.size() < 2:
		return []
	var ings: Array[Ingredient] = []
	for u in any: ings.append(u.ingredient)
	if Smoothie.is_muddy(ings, rs.balance):
		any.pop_back()
	return any if any.size() >= 2 else []

func cook_day() -> void:
	while true:
		var best = null
		var best_score := -1
		for cand in candidates():
			var s := Scoring.score_dish(to_dish(cand), rs.data, rs.counter).score
			if s > best_score:
				best_score = s; best = cand
		if best == null: break
		var dish := to_dish(best)
		consume(best)
		rs.serve(dish)
	if rs.has_blender:
		while true:
			var picked := smoothie_candidate()
			if picked.is_empty(): break
			var d := Dish.new(Dish.Station.SMOOTHIE)
			for u in picked:
				d.layers.append(DishLayer.new(u.ingredient, u.freshness))
				rs.pantry.erase(u)
			rs.serve(d)

const BUY_PRIORITY := [&"patty", &"cheese", &"bun", &"lettuce", &"tomato", &"onion", &"pickles", &"mustard"]

func shop_night(staples_only: bool, reserve_frac: float, use_blender: bool) -> void:
	var reserve := int(rs.balance.rent_for_day(rs.day + 1) * reserve_frac)
	# staples: enough bread for the patties we'll have, plus struggle burgers
	for i in 10:
		if rs.money - 1 < reserve and not staples_only: break
		var bought := false
		if units(&"ketchup").is_empty(): bought = rs.buy_staple(&"ketchup")
		if not bought: bought = rs.buy_staple(&"stale_bread")
		if not bought: break
	if staples_only:
		return
	if use_blender and not rs.has_blender and rs.day >= 2 and rs.money - rs.balance.blender_price >= reserve:
		rs.buy_blender()
	for id in BUY_PRIORITY:
		for offer in rs.shop_stock:
			if offer.ingredient.id == id and not offer.sold and rs.money - offer.price >= reserve:
				rs.buy_offer(offer)
	if rs.has_blender:
		for offer in rs.smoothie_stock:
			if not offer.sold and rs.money - offer.price >= reserve:
				rs.buy_offer(offer)
	# fridge: most valuable perishables first
	var perish = rs.pantry.filter(func(u): return u.ingredient.category == Ingredient.Category.PERISHABLE)
	perish.sort_custom(func(a, b): return a.ingredient.base_chips * a.freshness > b.ingredient.base_chips * b.freshness)
	for u in perish:
		rs.set_in_fridge(u, true)

var start_gadget: Gadget = null

func play(seed: int, staples_only: bool, reserve_frac: float, use_blender: bool) -> Dictionary:
	rs.new_run(seed)
	var money_at_close := []
	while rs.phase != rs.Phase.RUN_OVER:
		cook_day()
		money_at_close.append(rs.money - rs.rent_today())
		rs.close_day()
		if rs.phase == rs.Phase.NIGHT:
			# The studied gadget is bought (at full price) on the first night it's affordable.
			if start_gadget != null and not rs.counter.has(start_gadget) and rs.money >= start_gadget.price:
				rs.money -= start_gadget.price
				rs.counter[rs.free_slot()] = start_gadget
			shop_night(staples_only, reserve_frac, use_blender)
			rs.end_night()
	return {"won": rs.run_won, "day": rs.last_day.get("day", rs.day), "score": rs.total_score, "margins": money_at_close}

func report(name: String, staples_only: bool, reserve_frac: float, use_blender: bool, runs: int) -> void:
	var won := 0
	var days := {}
	var margins := []
	for i in rs.balance.days_per_run: margins.append([])
	var score_sum := 0
	for s in runs:
		var r := play(1000 + s, staples_only, reserve_frac, use_blender)
		if r.won: won += 1
		days[r.day] = days.get(r.day, 0) + 1
		score_sum += r.score
		for d in r.margins.size(): margins[d].append(r.margins[d])
	var med := []
	for m in margins:
		if m.is_empty(): med.append("-"); continue
		m.sort(); med.append(m[m.size() / 2])
	var ends := []
	for d in range(1, rs.balance.days_per_run + 1): ends.append("%d:%d" % [d, days.get(d, 0)])
	print("%-22s win %3d%%  ended on day [%s]  median money-after-rent by day %s  avg score %d" % [name, 100 * won / runs, " ".join(ends), str(med), score_sum / runs])

func _initialize() -> void:
	await process_frame
	rs = root.get_node("RunState")
	var runs := int(OS.get_environment("SIM_RUNS")) if OS.get_environment("SIM_RUNS") != "" else 200
	# Overrides: SIM_SET="key=value;key=value" (rent=5,8,...; bread=N; ketchup=N; or any Balance field)
	for pair in OS.get_environment("SIM_SET").split(";", false):
		var kv := pair.split("=")
		match kv[0]:
			"rent": rs.balance.rent_curve = PackedInt32Array(Array(kv[1].split(",")).map(func(x): return int(x)))
			"bread": rs.balance.staple_stock[&"stale_bread"] = int(kv[1])
			"ketchup": rs.balance.staple_stock[&"ketchup"] = int(kv[1])
			"start_bread": rs.balance.starting_pantry[&"stale_bread"] = int(kv[1])
			"struggle":
				rs.get_combo(&"bread_sandwich").mult = float(kv[1])
			"smoothie_chips":
				for i in rs.data.ingredients:
					if i.smoothie_ok: i.base_chips *= float(kv[1])
			_:
				# combo:<id>=mult, or any Balance field
				if kv[0].begins_with("combo:"):
					rs.get_combo(StringName(kv[0].trim_prefix("combo:"))).mult = float(kv[1])
				else:
					rs.balance.set(kv[0], float(kv[1]) if "." in kv[1] else int(kv[1]))
	print("rent ", rs.balance.rent_curve, "  money/pt ", rs.balance.score_to_money, "  staples ", rs.balance.staple_stock)
	# SIM_GADGETS=1: win rate of the careless bot that buys each gadget on the first night it can afford it.
	if OS.get_environment("SIM_GADGETS") != "":
		report("no gadget", false, 0.0, true, runs)
		for gadget in rs.data.gadgets:
			start_gadget = gadget
			report(gadget.display_name, false, 0.0, true, runs)
		start_gadget = null
		quit()
		return
	report("staples only", true, 0.0, false, runs)
	report("competent, burgers", false, 0.5, false, runs)
	report("competent, +blender", false, 0.5, true, runs)
	report("careless (no reserve)", false, 0.0, false, runs)
	quit()
