## Context

The cents economy (2026-10-26) made everything 10× smaller, but playtesters found decimals hard to read. Shop slots are currently drawn uniformly and independently. See proposal.md.

## Goals / Non-Goals

**Goals:**
- Whole numbers everywhere.
- A shop that tends to fill gaps in the pantry, still driven by the run's seeded RNG.
- An easier run than the current one.

**Non-Goals:**
- No change to quantities, prices relative to each other, gadget offers or staples.

## Decisions

### Back to the whole-dollar scale
- Whole numbers with the same price ratios need the earlier scale: patty $4, $0.5 per point. A smaller scale would flatten cheap items into each other ($1 and $2 can't shrink further), and the earlier simulator runs showed that paying less per point stops a run from growing.
- This brings back burgers paying about $20. That's the trade-off for whole numbers.
- `Money.text` stays the single formatter, so displays don't change again.

### Weighted draw
- Weight of an ingredient for a slot = `owned_weight_factor ^ units owned × duplicate_weight_factor ^ slots already holding it in this roll`.
- Starting factors are 0.7 and 0.2. Because both are multipliers above zero, nothing becomes impossible.
- Owned units count pantry and fridge; a sauce bottle counts as one unit. Units bought earlier the same night count, so a reroll after buying reflects them.
- Slots are drawn in order. The meat slot is forced, then counts as holding meat for the slots after it, so extra patties get rarer.
- The market and the smoothie bar count duplicates separately.
- The factors live in `Balance` (`shop_owned_weight_factor`, `shop_duplicate_weight_factor`).

### Longer callouts
Emphasized callouts rise for 2.6 s instead of 1.4 s, then fade over 0.4 s. Chip callouts are unchanged.

### Rent
Retuned last, because the weighted shop also changes the economy. Rent becomes $5, $10, $18, $30, $44, $60, $78. 200-run simulator results: competent 45% (was 34%), with blender 49% (was 19%), careless 58% (was 52%), staples only 0%. The blender gained most, because the smoothie bar now offers more variety.

## Risks / Trade-offs

- [Longer callouts can overlap new ones] → callouts rise and later ones start from the new top of the dish; checked with a render.
- [Bots can't show how weighting feels to people] → the factors are easy to change after the next playtest.
