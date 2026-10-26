## Why

The two stations never interact: burger food only goes on the board and smoothie food only in the jar. Letting ingredients cross over gives players something to experiment with, and secret combos reward the weird ideas ("a banana on a burger? ...The Elvis!").

## What Changes

- Crossover ingredients:
  - Every solid burger ingredient (bun, stale bread, patty, cheese, lettuce, tomato, onion, pickles) can also go into the smoothie jar.
  - Fruit (banana, strawberry, blueberry) and spinach can also go on the burger, as thin layers.
  - Liquids, yogurt and sauces stay in their own station.
  - The shops are unchanged: the market sells burger food and the smoothie bar sells smoothie food.
- Five **secret combos** need a crossover:
  - The Elvis, banana touching patty (+1.5).
  - Cheesecake, strawberry touching cheese (+1.0).
  - Green giant, spinach touching lettuce (+1.0).
  - Protein shake, patty and milk (+1.5).
  - Gazpacho, tomato, onion and water (+1.5).
- Secret combos aren't counted in "N more to discover". The board only hints that secret ones exist, and marks them as secret once discovered.
- Crossovers otherwise follow the normal rules. A burger ingredient in the jar adds its chips and color, so it can turn a smoothie muddy. Fruit on a burger can break adjacency combos.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `kitchen-assembly`: the jar accepts burger solids and the board accepts fruit and spinach.
- `dish-scoring`: secret crossover combos.
- `combo-board`: secret combos are hidden from the count and marked once found.

## Impact

- Station checks: `Ingredient.crossover` plus `fits_burger()` / `fits_jar()`, used by the burger board and the jar.
- Fruit and spinach get burger layer sizes.
- `Combo.secret`, and five new combo resources.
- The combo board moves to 5 columns so up to 14 burger combos fit.
- The rules card mentions crossovers.
- Tests are updated.
