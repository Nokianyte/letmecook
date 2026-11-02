## Why

Playtest feedback on the last build:
- Decimal prices are much harder to read than whole numbers.
- The difficulty curve is too steep.
- The shop often offers what the player already has, and several slots of the same ingredient.
- Mult callouts disappear too quickly to read.

## What Changes

- **BREAKING** Money goes back to whole dollars everywhere (patty $4, rent in dollars). This replaces the cents economy.
- The rent curve is lowered, tuned with the simulator after the shop change.
- Shop stock is weighted: ingredients the player owns less of come up more often, and an ingredient already in another slot of the same roll is much less likely. Applies to the market and the smoothie bar, including rerolls. The meat slot stays guaranteed.
- Mult, ×mult and "New combo!" callouts stay on screen longer.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `run-loop`: whole-dollar money.
- `shop-economy`: weighted stock; bundle and reroll amounts in whole dollars.
- `kitchen-gadgets`: sale price and Tip Jar in whole dollars.
- `dish-preview`: longer mult callouts.

## Impact

- `rules/shop.gd` gets weighted rolls, and `RunState` passes the pantry to it. `Balance` gets two tuning factors.
- All amounts in `data/` and `Balance`; `Money.text`.
- `ui/callout.gd` timing.
- Tests and the simulator.
