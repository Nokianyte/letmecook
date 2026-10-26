## Why

The first playtest with other players found one main problem: no obvious direction. Scoring rules only show up after a dish is served, so players build blind and don't know which combinations to aim for. The text-only how-to-play page didn't fix that; people skipped it or didn't connect it to what they were doing.

## What Changes

- **Live score preview while building:** the dish in progress is scored as if served right now (same rules, same gadgets in counter order) after every change.
- **Callouts:** each chip contribution and each bonus or penalty pops up as floating text where it happened ("+8 Patty", "+0.5 Melt!", "−0.5 Soggy bottom"); bonuses that stop applying flash as lost.
- **"If served now" list:** the serving window lists the current breakdown and the expected score and money while a dish is in progress; serving turns it into the animated tally as before.
- **Today's specials:** a board of a few random recipes, redrawn each day, each with its ingredients, its value (scored with the player's current gadgets), and progress ticks for the dish in progress. Recipes not on the board still score as before.
- **Guided tutorial:** offered on first launch, a coach walks the player through a first burger, serving, closing the day, and the night shop, highlighting what to touch and waiting for each action. Skippable, replayable from the "?" button; the rules text stays as a reference card.

## Capabilities

### New Capabilities
- `dish-preview`: Scoring the dish in progress as if served now, floating callouts for gained and lost contributions, and the "if served now" list in the serving window.
- `daily-specials`: The daily board of random recipes with gadget-aware values and progress ticks.
- `guided-tutorial`: The first-launch offer, the guided steps across kitchen and night, skipping/replaying, and the rules reference card.

### Modified Capabilities
<!-- None: scoring rules, recipes' matching, and the run loop are unchanged. -->

## Impact

- Code: `BurgerBoard`/`SmoothieJar` gain a non-destructive preview of the dish in progress; the serving window gains a live list; new UI for callouts, specials and the tutorial coach; the "?" button opens a small menu.
- Data: each recipe gets an explicit example build (used to value it on the specials board).
- Persistence: a small settings file in the browser's storage remembers that the tutorial was finished or skipped.
- No changes to scoring rules, economy, or balance.
