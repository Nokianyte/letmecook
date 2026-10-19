## 1. Day 1 — Setup and web export

- [x] 1.1 Create Godot 4 project (GDScript, 2D), set window/viewport size and stretch mode for browser play
- [ ] 1.2 Export an empty scene with the single-threaded web preset and upload it to a private itch.io page; confirm it runs in the browser
- [x] 1.3 Create folders: `data/`, `rules/`, `scenes/`, `ui/`
- [x] 1.4 Define `Ingredient`, `Recipe`, and `Balance` custom Resources with all fields from design.md
- [x] 1.5 Author first ingredient data: staples (stale bread, ketchup), burger set (bun, patty, cheese, lettuce, tomato, onion, pickles, mustard), and default `Balance` values
- [x] 1.6 Create `RunState` autoload with seeded RNG, day, money, pantry (units with freshness), fridge, tools
- [x] 1.7 Checkpoint: if the Godot learning curve or web export is still blocking, switch to Unity 2D WebGL per design.md

## 2. Day 2 — Burger assembly

- [x] 2.1 Kitchen scene layout: pantry panel, burger board, tray with K slots, rent/money/day labels (gray boxes)
- [x] 2.2 Pantry panel lists owned ingredients with counts and freshness, built from `RunState`
- [x] 2.3 Drag from pantry; drop over burger board spawns a physics body at the cursor and removes the unit from the pantry; drop elsewhere returns it
- [x] 2.4 Settle-then-freeze for burger layers; record bottom-to-top layer order
- [x] 2.5 Stability calculation in the rules layer (offset + slippery penalties) and scripted collapse that marks the burger ruined
- [x] 2.6 Clear-container action (returns units unless ruined) and finish-dish action that moves the burger to the next tray slot
- [x] 2.7 Playtest changes: remove slipperiness (ingredient flag, stability penalties, balance fields) and tray slots
- [x] 2.8 Live top layer: stays dynamic; locks on the next pantry pickup, pour, or serve (waiting for it to settle if needed); stability check on lock; live stability preview
- [x] 2.9 Re-drag the live layer: drop over the board re-drops it; drop anywhere else returns it to the pantry
- [x] 2.10 Sauce bottles: sauce ingredients with doses per bottle, chips show doses left, hold-to-pour over the burger, empty bottles removed; record sauce layers {ingredient, amount} in the stack
- [x] 2.11 Serve action (locks, checks stability, sends the dish out through the serving window) and "Close for the day" button (clears the board; rent settled in 4.1)
- [x] 2.12 Replace sauce physics blobs with a stream from the nozzle and a heightfield smear on the top layer (spread, merge, covered by the next layer)
- [x] 2.13 Covered sauce stays visible: flat sauce cushion collider at the wet area's average thickness; flatten the sauce when the next solid comes to rest

## 3. Day 3 — Scoring

- [x] 3.1 `Scoring.score_dish()` returning a breakdown: freshness- and amount-scaled chips, then mult lines, then final score, with minimum mult
- [x] 3.2 Burger rules: bun structure bonus, melt adjacency bonus, soggy penalty
- [x] 3.3 Named recipe matcher (ordered composition for burgers, ignoring sauce layers unless the recipe lists sauces) with "Struggle Burger", "Classic Cheese", and 1–2 more burger recipes
- [x] 3.4 Score each dish on serve, convert its score to money immediately, track the day's running total
- [x] 3.5 Score tally animation playing a served dish's breakdown, then updating the day total
- [ ] 3.6 Upload a playable build (kitchen loop only)

## 4. Day 4 — Run loop, shop, and freshness

- [x] 4.1 Rent curve from `Balance`; deduct when closing for the day; loss when money would go negative; win after the last day's rent
- [x] 4.2 Night scene: randomized shop stock from the run seed, buy with money, sold-out state, disabled buy when unaffordable
- [x] 4.3 Reroll with rising cost per night, reset each night; staples always offered and unaffected by rerolls
- [x] 4.4 Fridge panel: move units in/out up to slot count
- [x] 4.5 Nightly decay by category and location, spoilage at 0%, and a "spoiled overnight" notice at the start of the next day
- [x] 4.6 Starting state for a new run; run-over screen with result, day reached, total score, and seed; restart button
- [ ] 4.7 Upload a full-loop build (burgers only)
- [x] 4.8 Guarantee a single unit of meat in the first market slot (also after rerolls)

## 5. Day 5 — Smoothies, tools, and first playtest

- [x] 5.1 Tools in the shop: blender (one-time) and fridge upgrades (up to max); hide when owned or maxed
- [x] 5.2 Smoothie jar shown only with the blender; physics tumble for feel; contents are unordered
- [x] 5.3 Jar color blending weighted by amount; muddy-color classification
- [x] 5.4 Smoothie ingredients (milk, water, banana, strawberry, blueberry, spinach, yogurt) and rules: ratio bonus, flavor pairs, muddy penalty
- [x] 5.5 "Green Machine" and 1–2 more smoothie recipes
- [x] 5.6 Debug overlay: add money, skip day, set seed
- [x] 5.8 Smoothie bar: its own night-shop section once the blender is owned; the market keeps burger ingredients only
- [ ] 5.7 Upload build and run a first playtest with 2–3 people; note balance issues

## 6. Day 6 — Balance and feel

- [x] 6.0 Limit staples to a nightly stock (closes the unlimited struggle-burger money loop)
- [x] 6.1 Tune `Balance` from playtest notes: rent curve, prices, decay rates, score-to-money rate, fridge slots, sauce doses per bottle
- [x] 6.2 Verify the death-spiral floor: a run that only uses staples can survive early days
- [x] 6.3 Clarity pass: freshness shown on every unit, rent always visible, recipe names shown on finished dishes
- [x] 6.4 Small juice: drop squash, tally pop, collapse shake
- [ ] 6.5 Stretch, if time allows: in-day discard, overripe banana bonus in smoothies, discount stock, boss days

## 7. Day 7 — Kitchen Gadgets

- [x] 7.1 `Gadget` resource with hooks (score, serve, reroll cost) and a data-driven `TagGadget`; `RunState.counter` with 3 ordered slots, empty on a new run; `ScoreResult` ×mult line kind
- [x] 7.2 Scoring: gadget pass in counter order after the recipe, min-mult clamp after gadgets; tally shows gadget lines including ×mult
- [x] 7.3 The 8 starting gadgets as data (Cast-Iron Griddle, Cheese Grater, Sesame Seeds, Tower Mold, Pro Squeeze Bottle, Fruit Basket, Tip Jar, Lucky Coin), plus a `fruit` tag on fruits
- [x] 7.4 Night shop "Gadgets" section: 2 seeded offers from unowned gadgets, buy into the leftmost free slot, sell for half, rerolled with the shop
- [x] 7.5 `CounterRow` widget in the kitchen top bar and at night: cards with tooltips, drag-to-reorder, wiggle when the tally plays a gadget's line
- [x] 7.6 Tests for every gadget, counter order, buy/sell/reroll; simulator check of each gadget's win-rate effect

## 8. Day 7 — Ship

- [x] 8.0 Bulk discount: 10% off per extra unit in a stock slot, rounded; cards show the saving
- [x] 8.1 Bug-fix pass on drag edge cases (dropping during settle, re-dragging the live layer, pouring an empty bottle, fridge full, reordering gadgets)
- [x] 8.2 Short how-to-play screen explaining chips × mult, freshness, the fridge, and gadgets
- [ ] 8.3 Final web export and public itch.io page with a short description of the single mechanic
- [ ] 8.4 Play one full run in the uploaded build start to finish (win and loss) to confirm it works in the browser

## 9. Backlog — more Kitchen Gadgets (see design.md, Gadget catalog)

- [ ] 9.1 Toothpick: stability can't drop below 20% until the burger has 8 layers (new stability hook)
- [ ] 9.2 Napkin Stack: no soggy-bottom penalty
- [ ] 9.3 Day-Old Bakery: stale bread gives ×3 chips
- [ ] 9.4 Struggle Pride: Struggle Burger gets ×2 mult
- [ ] 9.5 Ice Crusher: "Good thickness" bonus ×2
- [ ] 9.6 Deep Freezer: units in the fridge don't decay (decay hook)
- [ ] 9.7 Wholesale Card: doubles the bulk discount (shop price hook)
- [ ] 9.8 Salad Spinner: +3 chips per veg layer
- [ ] 9.9 Pickle Jar: +1 mult per sour layer
- [ ] 9.10 Spice Rack: +1 mult per different sauce in a burger
- [ ] 9.11 Lunch Rush Bell: the first dish each day gets ×2 mult
- [ ] 9.12 Bigger Counter: +1 gadget slot (max 5), sold as a tool
