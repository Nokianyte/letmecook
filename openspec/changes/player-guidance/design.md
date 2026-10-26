## Context

The prototype is shipped (see the archived `cooking-roguelike-prototype` change and the baseline specs). Scoring already produces a full, ordered breakdown (`ScoreResult.lines`), and the tally plays it after serving. Playtesters lacked direction because that breakdown only appears after the dish is gone. See proposal.md for the motivation.

## Goals / Non-Goals

**Goals:**
- Reuse `Scoring.score_dish` for everything (preview, specials values), so what the player sees always equals what they get.
- Keep the board/jar the single owner of the dish in progress; guidance UI only reads from them.
- A tutorial that can't get the player stuck: every step is a condition on game state, re-checked every frame.

**Non-Goals:**
- No changes to scoring rules, recipes' matching, balance, or the run loop.
- No scripted/forced tutorial content (no special pantry or locked UI); it uses the normal starting run.

## Decisions

### Preview = scoring a snapshot of the dish in progress
- `BurgerBoard.preview_dish()` builds a `Dish` from the locked entries plus the live layer if it is resting (same conversion as `take_dish`, without resetting the board). `SmoothieJar.preview_dish()` does the same for the jar. Both return null when there is nothing to score (empty, ruined, or only sauce).
- The kitchen recalculates on the stations' `state_changed` signals (and `RunState.changed`, for gadget changes), skipping recalculation while sauce is being poured, so a pour produces one update when it stops.
- **Alternative:** scoring inside the board on every physics frame. Rejected: wasteful, and callouts would fire mid-fall.

### Callouts by diffing breakdowns
- Each preview line gets a key: kind + label (e.g. `CHIPS|Patty (100%)`, `MULT|Melt: cheese on patty`). New keys → "gained" callouts; keys that disappear → "lost" callouts (only for bonus lines; a chip line disappearing means the player took the ingredient back). Lines whose value changed (a sauce layer after another pour) count as gained.
- Position: chip lines map to their layer (the board exposes each entry's position on screen); everything else appears above the top of the dish. A `Callout` is a Label in an overlay CanvasLayer that tweens up ~40 px and fades over ~0.9 s; several in one update are staggered slightly so they don't overlap.
- Colors follow the tally: chips blue, mult red-orange, ×mult pink, penalties and lost bonuses red/grey.

### Live list in the serving window
- `ScoreTally` gains `show_preview(result)`: a static listing (no animation) of the same lines plus "≈ N pts (+$M)". `play()` replaces it on serve; when the dish is empty or ruined the list clears. The tally's existing rendering of lines is shared so both look identical.

### Specials board
- `RunState.specials: Array[Recipe]` drawn when a kitchen day begins (new run and `end_night`), with its own `RandomNumberGenerator` seeded from `hash([run_seed, day])`, so drawing specials doesn't shift the shop's random sequence and the same seed/day always gives the same specials.
- `Recipe` gets `example: Array[StringName]` (bottom to top; sauce ids get a default dose count). A special's value is `Scoring.score_dish(example_dish, data, counter)` at 100% freshness. Example builds: Struggle Burger = bread, ketchup, bread; Classic Cheese = its ingredients; Double Cheese = its ingredients; Garden Stack = bun, patty, lettuce, tomato, onion, bun; smoothie recipes = their ingredients.
- Progress ticks compare the example's ingredients with the dish in progress as a multiset (each tick consumes one matching layer), which reads naturally for both ordered and unordered recipes; "matched" uses the real `Scoring.matches`.
- Placement: a strip of cards above the burger board (the board area has spare height).
- **Alternative considered:** specials as the only recipes that score that day. Rejected for now: it would punish players for knowing other recipes; the board is guidance.

### Guided tutorial
- `Tutorial` (CanvasLayer above the game, below the debug panel) owns a list of steps. Each step has a message, a target (a function returning the screen rectangle to highlight, found by unique node names in the current phase scene, e.g. the pantry chip for an ingredient), and a completion check (a function over `RunState` and the current scene) or a Next button. It re-evaluates in `_process`, so it never misses a signal and survives scene swaps.
- Highlight: a pulsing outline around the target plus a coach bubble placed beside it; both ignore the mouse so the game stays fully interactive.
- Recovery: during steps 1–4, if the board is ruined the message switches to recovery advice; when the board is empty again the tutorial goes back to step 1.
- Persistence: `user://settings.cfg` (`ConfigFile`, stored in the browser's IndexedDB on the web) with `tutorial_done`. First launch shows an offer panel; the "?" button opens a menu (Replay the tutorial, Rules reference, Close). The existing rules text becomes the reference card.

## Risks / Trade-offs

- [Callout spam during fast building] → staggered, short-lived callouts; sauce reports once per pour; preview skipped while a layer is still falling.
- [Preview disagrees with the served score] → both use `Scoring.score_dish` on the same conversion; a test asserts equality.
- [Tutorial target not on screen, e.g. no stale bread left] → the step's message tells the player what to do; targets fall back to no highlight; Skip is always available.
- [Browser storage unavailable] → the offer just appears again next time; nothing breaks.
- [Found while building this: a layer locked within ~0.2 s of landing could jump ~40 px, in a real window only] → Godot re-applied a stale transform from the fall to the just-frozen body. Locked layers now remember their locked transform and undo any move that isn't the board's; locking also takes the position from the physics server. Separately, the board never moves its physics stage while a burger is on it, and the specials strip has fixed-height content so it can't shift the board mid-build.
- [Godot editor left open while files change on disk] → it re-saved data files from stale copies and dropped seven ingredients' chip values; they were restored from git. Reload the project in the editor after external changes.

## Open Questions

- Number of specials (default 3) and whether specials should later get an extra bonus are tuning questions for the next playtest.
