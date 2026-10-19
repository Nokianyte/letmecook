## Context

Greenfield project. Constraints: one week, one developer (some Unity experience, new to Godot), gray-box visuals are acceptable, and the prototype must run in a browser. See proposal.md for the game concept and scope. Behavior is defined in `specs/`; this document covers how to build it.

## Goals / Non-Goals

**Goals:**
- Get a playable browser build early (day 1) and keep it playable every day after.
- Keep game rules (scoring, decay, economy) separate from scenes and input, so they can be tuned and debugged without touching the UI.
- Make balancing fast: changing any number should not require touching code.

**Non-Goals:**
- Final art, audio, juice beyond the score tally and drop physics.
- Fully simulated physics (items stay simulated after they settle).
- Persistence between browser sessions.

## Decisions

### Engine: Godot 4.x, GDScript, 2D
- **Why:** lightweight editor, fast iteration, strong Control-node UI with built-in drag-and-drop, small web builds. Newer 4.x releases support a single-threaded web export that works on itch.io without cross-origin-isolation headers.
- **GDScript, not C#:** Godot 4 C# projects cannot be exported to web.
- **Alternatives:** Unity (known to the developer, but web builds are heavier and the iteration loop is slower); Phaser or plain TypeScript (best for the web, weaker editor tooling for physics and layout).
- **Fallback:** if by the end of day 1 the web export or the Godot learning curve is blocking, switch to Unity 2D WebGL. The rules layer below is engine-agnostic by design, so the decision costs about a day.

### Architecture: rules layer vs. presentation layer
```
 ┌───────────────── data (Resources / JSON) ─────────────────┐
 │ ingredients, recipes, decay rates, prices, rent curve, … │
 └───────────────────────────┬───────────────────────────────┘
                             ▼
 ┌──────────────── rules (plain GDScript, no nodes) ─────────┐
 │ RunState (day, money, pantry, fridge, tools)              │
 │ Scoring.score_dish(dish) → breakdown                      │
 │ Freshness.apply_night(state)                              │
 │ Shop.roll_stock(rng, state) / reroll / buy                │
 └───────────────────────────┬───────────────────────────────┘
                             ▼
 ┌──────────────── scenes (presentation) ────────────────────┐
 │ KitchenScene: pantry panel, burger board, smoothie jar,   │
 │               serving window, serve/close, score tally    │
 │ NightScene:   shop, fridge assignment, rent result        │
 │ RunOverScene                                              │
 └───────────────────────────────────────────────────────────┘
```
- `RunState` is a single autoload (singleton) that scenes read from and act on through rule functions.
- Scoring returns a **breakdown** (one line per chip and mult contribution), not just a number. The tally animation and debugging both use it.
- **Alternative:** logic inside node scripts. Faster to start, but scoring and balancing get tangled with drag-and-drop code.

### Data: Godot custom Resources (`.tres`)
- An `Ingredient` resource holds: id, display name, gray-box color/shape, category (staple / shelf-stable / perishable), base chips, tags, kind (solid or sauce), burger size, sauce doses per bottle, smoothie properties (liquid vs. thick, color), price.
- A `Recipe` resource holds a name, a matcher (required ingredients or tags, optional exact composition), and mult bonus.
- A `Balance` resource holds all tuning numbers: days per run, rent curve, starting money and pantry, decay rates per category (outside and inside the fridge), reroll cost base and step, score-to-money rate, fridge slot counts.
- **Why Resources over JSON:** editable in the Godot inspector with type checking, and no parsing code. JSON would only help for editing outside the engine, which isn't needed.

### Burger physics: live top layer, freeze on the next pickup
- A dropped ingredient becomes a `RigidBody2D` (rotation locked) falling onto the stack. Only one may fall at a time.
- The newest layer stays **live** (dynamic) so the player can adjust it. It **locks** (frozen, static) when the player picks up the next ingredient or bottle, or serves. Lock detection uses `NOTIFICATION_DRAG_BEGIN` (every Control receives it) for pantry drags, and an explicit call when pouring or serving. If the live layer is still falling at that moment, it locks as soon as it comes to rest.
- **Re-dragging the live layer** uses the same Godot drag-and-drop as the pantry: the board is the drag source for its live layer, removes the body, and drops it again on release over the board. On `NOTIFICATION_DRAG_END` with an unsuccessful drop, the board returns the unit to the pantry.
- **Stability** is computed by the rules layer, not by the physics solver, whenever a layer locks: horizontal offset of each layer's center relative to the one below, plus a height penalty. Below the threshold, a scripted collapse plays and the burger is ruined. While a layer is live, the board shows the stability it would have if locked now. (Slipperiness was dropped after the first playtest.)
- **Alternatives:** full physics (fun, but tall stacks jitter and tuning could take days); pure snap with no physics (safe, but loses the tactile feel). Freezing locked layers keeps the feel while keeping the outcome deterministic.

### Sauces: bottles that pour a stream onto a heightfield
- A sauce is owned as a bottle: one `IngredientUnit` with `doses_left`. Pressing a bottle chip starts a custom pour gesture (not Godot drag-and-drop, which only reports a single drop): the bottle follows the cursor and, while the button is held over the top solid layer, pours one dose per interval. The stream is drawn as a straight line from the nozzle to the surface.
- Sauce has **no physics**. Each sauce layer is a `SauceSmear` node sitting on the top surface of the layer it was poured on: a 1D heightfield (one column per couple of pixels across that layer's width). A dose adds a soft bump where the stream lands; a short diffusion step after each dose lets bumps merge and flatten, which is what makes it read as liquid. It is drawn as one filled shape. Each smear also carries a flat static collider (a rectangle, never circles) spanning the wet area at the sauce's average thickness, so the next solid rests on a sauce "cushion" without jitter; when that solid comes to rest, the heightfield is flattened to that average, so the sauce shows as its own thin layer between the solids.
- The board records consecutive doses of the same sauce on the same layer as one sauce layer `{ingredient, amount}`, so scoring and recipes see an ordinary layer list.
- **Alternatives considered:** physics blobs (tried: they looked like beads, stacked into towers, tunneled, and made solids jitter); merging blobs on contact (still beads, same physics bugs); metaball shader over physics particles (liquid look, but keeps the physics bugs and adds shader work).

### Serving
- Each dish is scored as soon as it is served; there are no tray slots. The serving window shows the last dish leaving. A "Close for the day" action ends the kitchen phase and settles rent.

### Smoothie jar: physics for feel only
- Items tumble into the jar with physics for visual feedback; the outcome only depends on which ingredients are in it. The jar color is the average of the ingredient colors, weighted by amount.

### Scoring pipeline
```
 chips = Σ base_i × freshness_i × amount_i      (amount = doses for sauce layers, else 1)
 mult  = 1 + structure + adjacency + ratio + flavor pairs + named recipe
 score = chips × mult
```
Each step appends lines to the breakdown, which the tally plays back in order. All rule values come from `Balance` and `Recipe` resources.

### Kitchen Gadgets (the run's jokers)
- **Model:** `Gadget` is a Resource with an id, name, description, price, and optional hooks:
  ```
  func modify_score(dish: Dish, result: ScoreResult) -> void   # add chips / mult / ×mult lines
  func on_dish_served(dish: Dish) -> int                        # extra money (Tip Jar)
  func modify_reroll_cost(cost: int, rerolls_tonight: int) -> int   # Lucky Coin
  func modify_decay(unit: IngredientUnit, amount: float) -> float   # backlog: Deep Freezer
  ```
  Most scoring gadgets share one data-driven subclass (`TagGadget`: "for each layer with tag X: add chips / add mult / ×mult by Y", with an optional condition such as "bun-tagged ends" or "smoothie only"), so they are a `.tres` edited in the inspector. Odd ones get a tiny subclass of their own.
- **Order matters:** `RunState.counter` is an ordered `Array[Gadget]` (fixed slot count, empty slots allowed). Scoring runs: layer chips → station rules → recipe → **gadgets left to right** → min-mult clamp → score. `ScoreResult` gets a third line kind, `X_MULT`, which multiplies the running mult; because the tally already plays lines in order, ×mult reads naturally ("×1.5 Sesame Seeds").
- **Economy hooks** are called from the existing sites: `RunState.serve` (Tip Jar), `RunState.reroll_cost` (Lucky Coin), `Freshness.apply_night` (backlog).
- **Shop:** a "Gadgets" section at night with 2 offers drawn from unowned gadgets with the run's RNG, rerolled with the shop; selling refunds half the price (rounded down).
- **UI:** one `CounterRow` widget used in the kitchen top bar and at night: gadget cards with tooltips, drag-to-swap reordering (Godot drag-and-drop between cards), and a wiggle tween when the tally plays that gadget's line (the line carries the gadget id).
- **Balance:** each gadget's effect is measured with the simulator (win-rate change when the bot owns it from day 2), to catch anything that breaks the economy.
- **Alternatives considered:** a pure data effect enum with no scripts (inspector-friendly, but the odd gadgets don't fit); a fixed rule of "all additive, then all ×mult" instead of counter order (simpler, but loses the Balatro-style ordering puzzle the player asked for).

#### Gadget catalog
Built now (the spec's starting set) and backlog. Built-now values were tuned with the simulator (a bot that buys the gadget on the first affordable night): strong picks reach ~60% wins vs 29% without, situational ones 31–38%. Fruit Basket and Lucky Coin can't be judged by the bot (it rarely blends and never rerolls). Backlog values are starting guesses.

| Gadget | Effect | Playstyle | Hook | Status |
|---|---|---|---|---|
| Cast-Iron Griddle | +0.5 mult per patty layer | meat stacks | score | now |
| Cheese Grater | +0.5 extra mult per cheese–patty melt | meat stacks | score | now |
| Sesame Seeds | ×1.2 mult with bun-tagged bottom and top | proper burgers | score | now |
| Tower Mold | +0.5 mult per solid layer beyond the fifth | tall towers | score | now |
| Pro Squeeze Bottle | sauce layers give ×2 chips | sauce | score | now |
| Fruit Basket | +1 mult per distinct fruit in a smoothie | smoothies | score | now |
| Tip Jar | +$2 per dish served | thrift | serve | now |
| Lucky Coin | first reroll each night is free | thrift | reroll | now |
| Toothpick | stability can't drop below 20% until the burger has 8 layers | tall towers | stability | backlog |
| Napkin Stack | no soggy-bottom penalty | sauce | score | backlog |
| Day-Old Bakery | stale bread gives ×3 chips | struggle | score | backlog |
| Struggle Pride | Struggle Burger gets ×2 mult | struggle | score | backlog |
| Ice Crusher | "Good thickness" bonus ×2 | smoothies | score | backlog |
| Deep Freezer | units in the fridge don't decay | thrift | decay | backlog |
| Wholesale Card | doubles the bulk discount (20% off per extra unit) | thrift | shop price | backlog |
| Salad Spinner | +3 chips per veg layer | garden | score | backlog |
| Pickle Jar | +1 mult per sour layer | garden | score | backlog |
| Spice Rack | +1 mult per different sauce in a burger | sauce | score | backlog |
| Lunch Rush Bell | the first dish each day gets ×2 mult | any | score | backlog |
| Bigger Counter | +1 gadget slot (max 5); sold as a tool | any | counter | backlog |

The Toothpick needs a new hook into `Stability.compute` (a stability floor) rather than scoring; the rest fit the hooks above.

### Randomness
- One seeded RNG per run, stored in `RunState`. The seed is shown on the run-over screen, so a playtester's run can be replayed while debugging.

### Web build and distribution
- Single-threaded web export uploaded to itch.io as an HTML5 game. The empty-project export is uploaded on day 1 to remove this risk early.

## Risks / Trade-offs

- [Godot learning curve eats into the week] → Timebox learning to day 1; fallback to Unity as described above.
- [Physics jitter or tunneling with small bodies] → Freeze locked layers, clamp drop height, continuous collision detection, rectangle colliders only; sauce has no physics.
- [Economy death spiral: a bad day leads to an unwinnable run] → Struggle staples are restocked every night (a fixed nightly quantity), cheap, and never spoil; the Struggle Burger recipe makes them viable. The nightly limit stops them from becoming an unlimited money loop.
- [Economy balance is the riskiest tuning: rent, prices, decay, and score conversion all interact] → All numbers in one `Balance` resource; a debug overlay to add money and skip days; tune with playtest feedback from day 5.
- [Two containers double the content work] → Smoothies are behind the blender unlock and can be cut entirely without breaking the run.
- [Drag-and-drop across Control UI and physics bodies is awkward] → Pantry is Control-based; on drop over a container, spawn a physics body at the cursor and remove the pantry item.

## Migration Plan

Not applicable (new project). Deployment: re-upload the web export to itch.io whenever a playable milestone is reached.

## Open Questions

- Exact tuning values. Day 6 tuning used a headless simulator (bots playing hundreds of seeded runs through the real rules): rent 5/8/13/18/23/30/39 (raised slightly after adding the 10% bulk discount), 4 stale bread + 1 ketchup per night, Struggle Burger +1.0, smoothie ingredients' chips doubled, blender $12, 4 smoothie bar slots. Simulated: a careless-but-active player wins ~60%, a cautious one ~44%, staples-only runs out on day 6. Human playtests should confirm, especially the smoothie path, which the bots play poorly.
- Whether stretch goals (in-day discard, boss days, overripe bonuses, discount stock) and backlog gadgets make it in depends on time left on day 7.
