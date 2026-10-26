## Context

Money was whole dollars (ints). Payouts were `floor(score × 0.5)`. Prices were $1–$12 for ingredients and tools. The combo update raised rent to $5–$80. See proposal.md.

## Goals / Non-Goals

**Goals:**
- Numbers about 10× smaller, with fractions.
- No float rounding drift.
- Difficulty about where it is now.

**Non-Goals:**
- No changes to scoring.

## Decisions

### Integer cents
- `money` and every price stay `int`, now in cents. A float dollar amount would accumulate rounding errors and make comparisons like `money >= price` fragile.
- `Money.text(cents)` is the only formatter, and always prints two decimals.
- `score_to_money` becomes cents per point: 5.0, the same rate as before at the new scale.

### Rebalance
1. Converting everything exactly (×0.1) gave the same picture as before, a little easier because payouts now round down to the cent instead of the dollar.
2. Paying less per point (2–3¢) was tried to make starting burgers feel smaller next to their ingredient costs. It removed the margin the run needs to grow: the competent bot won 0–30% even with much lower rent.
3. So the rate stays at 5¢ per point, and rent is nudged up to $0.50 / $1.00 / $2.00 / $3.30 / $4.80 / $6.50 / $8.50.

200-run simulator results:

| Bot | Win rate |
|---|---|
| Competent, burgers only | 53% |
| Competent, with blender | 44% |
| Careless | 67% |
| Staples only | 0% |

### Tally fade-in
- Every played-back line starts at alpha 0 and scale 1.8, anchored at its left edge, and tweens to alpha 1 and scale 1 over 0.25 s (cubic ease-out).
- The final score starts at 2.4× and takes 0.35 s.
- The static "If served now" list doesn't animate.

## Risks / Trade-offs

- [Saved settings or old builds] → money isn't saved between sessions, so nothing needs migrating.
