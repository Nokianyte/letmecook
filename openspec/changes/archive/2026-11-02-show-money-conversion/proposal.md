## Why

Playtesters can't tell how points turn into dollars: the game only says "Every point pays money".

## What Changes

- The "If served now" list and the tally show the sum under the score, e.g. "45 pts × $0.5 = $22", with " + $2 tips" when tips apply.
- The rules card and the tutorial state the rate and that it rounds down per dish.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `run-loop`: payouts show how they were calculated.

## Impact

- `ui/score_tally.gd`, `scenes/kitchen/serving_window.gd`, `rules/money.gd`, `ui/how_to_play.gd`, `ui/tutorial.gd`, and tests. No balance change.
