## Why

Playtesting the guidance update showed three problems:
- Named recipes are rigid: a recipe only pays off when the whole burger matches it exactly. Players also found the specials board hard to read as advice on how to build.
- Mult callouts are easy to miss, even though mult is what makes a dish great.
- A tall burger's breakdown (25+ lines) stretches the serving window past the screen and breaks the layout.

## What Changes

- **BREAKING** Named recipes are removed. Their role moves into **combos**: small adjacency and order rules that each add (or remove) mult. Several combos can apply to the same dish and they stack.
- Burger combos: Bun ends, Melt, Soggy bottom (existing), plus Lettuce shield, Sauced patty, Fresh pair, Tangy crunch, Double decker, Bread sandwich (the old Struggle Burger), Veg crown and Sauce duo.
- Smoothie combos: Good thickness, Flavor pair and Muddy color (existing), plus Banana Shake, Green Machine and Berry Blast, which are now combos rather than recipes.
- **BREAKING** The daily specials board is replaced by a **combo board** listing the combos the player has discovered for the current station. It starts with three simple combos. Any other combo appears on the board, with a large "New combo!" callout, the first time the player builds it. Discoveries are kept across runs.
- On the board, combos that are active in the dish in progress are highlighted, with a count when a combo applies several times.
- Mult and ×mult callouts are larger and pop, so they draw attention.
- Layout:
  - The serving window's breakdown fits on screen. Repeated lines are grouped (e.g. "Melt ×4") and a long list scrolls.
  - Served-dish thumbnails scale tall burgers to fit inside their box.
- Rent is retuned with the simulator (combos stack, so good builds earn more), so the run's difficulty stays about where it was with recipes.

## Capabilities

### New Capabilities
- `combo-board`: the board of discovered combos above the plate, discovery and its persistence, and highlighting active combos.

### Modified Capabilities
- `dish-scoring`: adjacency, order and set rules become a defined list of combos. Named recipes are removed. Grouped breakdown lines.
- `dish-preview`: larger mult callouts, a "New combo!" callout, and a list that fits the window.
- `guided-tutorial`: the specials explanation step now explains the combo board.
- `daily-specials`: removed (replaced by `combo-board`).

## Impact

- Rules:
  - New `Combo` resource and data files.
  - `rules/scoring.gd` evaluates combos.
  - `rules/recipe.gd`, `rules/specials.gd`, `data/recipes/*` and `RunState.specials` are removed.
  - The station enum moves to `Dish`.
- UI:
  - `specials_strip.gd` is replaced by a combo board.
  - `live_preview.gd` handles discovery and bigger callouts.
  - `score_tally.gd` groups lines and scrolls.
  - Also changed: `dish_preview.gd`, the tutorial text and the rules card.
- Settings: discovered combos are saved in `user://settings.cfg`, next to the tutorial flag.
- Tests and the simulator are updated; the balance is re-checked.
