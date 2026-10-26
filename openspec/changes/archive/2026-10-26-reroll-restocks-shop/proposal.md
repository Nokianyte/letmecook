## Why

Playtesting showed that a reroll only replaces unsold slots: after buying most of the market, a paid reroll changes little or nothing and the sold slots stay empty for the rest of the night. Players expect a reroll to bring a fresh shop.

## What Changes

- A reroll replaces **every** slot of the market, the smoothie bar and the gadget offers, including slots already bought (bought items stay in the pantry or on the counter).
- The market's first slot still always offers one unit of meat after a reroll.
- Staples and tools are unchanged (not affected by rerolls).

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `shop-economy`: rerolls restock the whole market and smoothie bar, sold slots included; the meat guarantee holds after every reroll.
- `kitchen-gadgets`: rerolls replace all gadget offers, sold ones included.

## Impact

- `rules/shop.gd` reroll functions; tests in `tools/tests/test_run_loop.gd` and `test_gadgets.gd`.
- Rerolls become more valuable; the rising reroll cost still limits them.
