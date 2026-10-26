## Context

Scoring currently has hard-coded burger rules in `rules/scoring.gd`:
- Bun ends, Melt and Soggy bottom.
- The smoothie rules: thickness, flavor pairs and muddy color.
- One best-matching named `Recipe`.

The guidance update added a daily specials board of recipes. Playtesters want a board of the *rules that give mult* instead, and more such rules based on adjacency and order. See proposal.md.

## Goals / Non-Goals

**Goals:**
- One data-driven list of combos covers both the old rules and the new ones. The board, the scoring, the callouts and the tests all read that same list.
- New combos can be added in the inspector without code, as long as they are sequence or set rules.
- The layout can't overflow with a tall burger.

**Non-Goals:**
- No change to chips, freshness, gadgets' effects, the shop or the run loop. Balance is retuned only through combo values (and rent only if the simulator says it's needed).
- No in-game collection screen beyond the board.

## Decisions

### `Combo` resource
- Fields:
  - `id`, `display_name`, `rule` (short text such as "cheese touching patty"), `station`, `mult`.
  - `starter`: shown on the board from the start.
  - `kind`, `pattern: Array[StringName]`, `anchor`, `either_order`, `each`, `solids_only`.
- Pattern entries match an ingredient by id or tag (`ingredient.id == x or ingredient.has_tag(x)`).
- Kinds:
  - **SEQUENCE**: `pattern` matches consecutive layers, bottom to top. `solids_only` skips sauce layers first. `anchor` is one of:
    - ANYWHERE: any position.
    - BOTTOM: must start at the first layer.
    - TOP: must end at the last layer.
    - WHOLE: the whole dish.
    - ENDS: the first and last entries match the bottom and top layers, with at least two layers.
  - `either_order` also tries the reversed pattern.
  - `each` counts every occurrence (one line each, like Melt today); otherwise the combo counts once.
  - **SET**: every pattern entry is present anywhere in the dish. This is how the smoothie trio combos work.
  - **THICKNESS**, **FLAVOR_PAIR**, **MUDDY**: the existing smoothie checks (`Smoothie.*`). FLAVOR_PAIR adds one line per pair, labeled "Flavor pair: Banana + Strawberry".
- Values move from `Balance` (`structure_bonus`, `melt_bonus`, `soggy_penalty`, `ratio_bonus`, `flavor_pair_bonus`, `muddy_penalty`) into the combo resources. `GameData.combos` replaces `recipes`. Combos apply in list order, after chips and before gadgets.
- Breakdown lines get a `combo` key holding the combo id, so the board and discovery can find them without parsing labels.
- `Scoring.combo_counts(dish, data) -> Dictionary` (id → count) feeds the board's highlights.
- **Alternative:** a hand-written function per combo. Rejected: eleven near-identical adjacency checks, and no inspector tuning.

### The station enum moves to `Dish`
`Recipe.Station` is used in a dozen places. It becomes `Dish.Station` (BURGER, SMOOTHIE), and `recipe.gd` is deleted. `ScoreResult.recipe_name` is gone. Tally and thumbnail titles use the dish name ("Burger" / "Smoothie").

### Combo list and starting values
Burger combos:

| Combo | Rule | Mult |
|---|---|---|
| Bun ends | bun at bottom and top | +1.0 |
| Melt | cheese touching patty | +0.5 each |
| Sauced patty | sauce right on a patty | +0.5 each |
| Lettuce shield | lettuce right on the bottom bun | +0.5 |
| Fresh pair | tomato touching lettuce | +0.5 each |
| Tangy crunch | pickles touching onion | +0.5 each |
| Double decker | patty · cheese · patty | +1.0 |
| Bread sandwich | only stale bread around ketchup | +1.0 |
| Veg crown | veg right under the top bun (sauce between is fine) | +0.5 |
| Sauce duo | ketchup touching mustard | +0.5 |
| Soggy bottom | sauce right on the bottom bun | −0.5 |

Smoothie combos:

| Combo | Rule | Mult |
|---|---|---|
| Good thickness | 30–60% liquid | +1.0 |
| Flavor pair | flavors that go together | +0.5 each |
| Banana Shake | banana + milk | +1.0 |
| Green Machine | spinach + banana + milk | +1.0 |
| Berry Blast | strawberry + blueberry + yogurt | +1.5 |
| Muddy color | clashing colors | −1.0 |

Starters: Bun ends, Melt and Sauced patty. These three can be built from the starting pantry (stale bread, ketchup, patties). Good thickness is also a starter, but only for smoothies: the smoothie section appears once the blender is bought. These values are a starting point; the simulator decides the final numbers.

### Rent retune
- Combos stack, so a smart builder gets more mult than with one best recipe. The simulator bot (it knows every combo from day 1) went from a 46% to a 100% win rate.
- Combo values stay readable (+0.5 / +1.0). Instead, rent becomes `5, 10, 20, 32, 46, 62, 80` (was `5, 8, 13, 18, 23, 30, 39`).
- 200-run simulator results: competent 49%, competent with blender 40%, careless 65%, staples only 0%. Before: 46% / 17% / 63% / 0%.
- Real players discover combos gradually, so they're weaker than the bot early on.

### Discovery
- `RunState.discovered: Dictionary` (combo id → true), loaded from `user://settings.cfg` (`[combos] discovered`). `RunState.discover(combo)` records it, saves it and emits `combo_discovered(combo)`.
- Settings file access moves from `tutorial.gd` into a small static `Settings` helper (path override via `LETMECOOK_SETTINGS`, as today), shared by the tutorial and `RunState`.
- The live preview discovers combos. When a recalculated preview contains a line from an undiscovered combo, the preview discovers it and pops a big gold "New combo! Lettuce shield +0.5" callout above the dish. A combo that has only ever been served, never previewed, can't happen in the game, so only the preview discovers. The simulator and the rules tests never touch the settings file.
- Penalty combos (Soggy bottom, Muddy color) are discovered the same way and shown in red on the board.

### Combo board (replaces the specials strip)
- A fixed-height panel in the same place as the specials strip. It must not resize mid-build, because the physics stage sits below it.
- It shows a 4-column grid of two-line chips: the name and mult on the first line, the rule underneath. A last dim cell reads "? N more combos to discover". All 11 burger combos fit in 3 rows (118 px). An earlier one-line flow layout needed 6 rows.
- The board shows the combos of the station whose preview was updated last, and the burger combos when nothing is in progress.
- A chip whose combo is active in the dish in progress gets a gold border, and "×N" when the combo counts more than once.
- A newly discovered chip flashes.

### Bigger mult callouts
- `Callout` takes a size and a pop.
- MULT and X_MULT lines use font 26 with a scale pop (1.4 → 1), and stay on screen a little longer.
- Chips callouts stay at 16.
- "New combo!" callouts use 28, in gold.
- Callouts stacked above the dish use a spacing that fits the bigger text.

### Breakdown that fits
- `ScoreTally` groups consecutive lines that share a kind, label and value into one line with a count (`+2.0  Melt ×4`).
- The live list and the animated tally use the same grouping. The animated tally still plays every group once, with the summed value.
- The tally sits in a `ScrollContainer` that takes the remaining height of the serving window and follows the newest line.
- The served-dishes list shows the last 2 dishes. `DishPreview` scales a burger down to fit its box.

## Risks / Trade-offs

- [Removing recipes lowers mult] → retune combo values with the simulator to keep the win rates close to the current ones.
- [Board too tall when everything is discovered] → a 4-column grid with a fixed height for 11 chips at 1280 px. The panel clips rather than grows; checked by a test and a render.
- [Discovery persists across runs, so playtesters on a shared machine see a full board] → acceptable. Replaying the tutorial doesn't reset it. A reset can come later in the "?" menu if needed.
- [Saved settings hold old data] → the `combos` section is new, and unknown ids are ignored.
