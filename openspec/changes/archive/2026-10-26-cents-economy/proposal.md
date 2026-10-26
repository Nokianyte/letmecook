## Why

Playtesters found the money numbers too big: a starting burger paid about $20. With all the new stacking combos, the economy also needed a fresh check. The tally also felt flat: each line just appears.

## What Changes

- Money is counted in cents and shown as dollars and cents. Every price, payout, rent, tip and reroll is about 10× smaller than before, e.g. a patty costs $0.40 and a starting burger pays about $1.50.
- Payouts, bundle prices and sale prices round to the cent instead of the dollar, so small amounts no longer collapse (three onions cost $0.24, not the same as two).
- Rent is rebalanced with the simulator for the combo-era economy: $0.50, $1.00, $2.00, $3.30, $4.80, $6.50, $8.50.
- Each line of the score tally, and the final score, fades in while shrinking from a larger size to its normal size.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `run-loop`: money in cents, shown as dollars with two decimals; payout example updated.
- `shop-economy`: bundle and reroll prices in cents.
- `kitchen-gadgets`: sale prices and Tip Jar in cents.
- `dish-scoring`: tally lines fade in while shrinking.

## Impact

- New `Money` formatter. Every money display uses it.
- All prices in `data/` and `Balance` are now in cents: ingredient and gadget prices, rent, reroll, blender, fridge upgrade, Tip Jar, and `score_to_money` (cents per point).
- `ScoreTally` gets the fade-in animation.
- Tests and the simulator now use cents.
