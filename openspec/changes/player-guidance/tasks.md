## 1. Live score preview

- [x] 1.1 `BurgerBoard.preview_dish()` and `SmoothieJar.preview_dish()` (non-destructive snapshots; null when empty, ruined, or sauce only); screen positions of board entries for callouts
- [x] 1.2 Kitchen recalculates the preview on station/run changes (not while pouring or while a layer falls); preview score equals served score
- [x] 1.3 Callouts: diff previous/new breakdown, gained lines at their layer or the dish top, lost bonuses, one callout per pour; rise-and-fade animation, staggered
- [x] 1.4 "If served now" list in the serving window (`ScoreTally.show_preview`), replaced by the tally on serve, cleared when empty

## 2. Today's specials

- [x] 2.1 `Recipe.example` builds for all recipes; `RunState.specials` drawn per day with a seed+day RNG (smoothies only with blender)
- [x] 2.2 Specials strip above the board: name, ingredients with progress ticks, gadget-aware value (score and payout), highlight when matched; refresh on gadget changes

## 3. Guided tutorial

- [x] 3.1 `Tutorial` overlay: steps with message, target rectangle and completion check, re-evaluated every frame; pulsing highlight and coach bubble that don't block input; Skip button
- [x] 3.2 The 12 steps across kitchen and night, with collapse/empty-board recovery during the burger steps
- [x] 3.3 First-launch offer, `user://settings.cfg` persistence, "?" menu (Replay tutorial, Rules reference, Close)

## 4. Verify and ship

- [x] 4.1 Tests: preview equals served score, callout diffing, specials determinism/values/progress, tutorial step progression and recovery, settings persistence
- [ ] 4.2 Render check of the kitchen with preview, callouts and specials, and of a tutorial step; export and deploy to GitHub Pages
