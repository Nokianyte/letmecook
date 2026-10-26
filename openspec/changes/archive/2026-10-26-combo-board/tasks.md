## 1. Combos in scoring

- [x] 1.1 `Combo` resource (sequence/set/smoothie kinds), data files for the 17 combos, `GameData.combos`; move the station enum to `Dish`; remove `Recipe`, recipe data and `Specials`
- [x] 1.2 `Scoring` evaluates combos in list order (lines carry the combo id); `combo_counts`; gadgets' helpers (`has_bun_ends`, `melt_count`) kept
- [x] 1.3 Retune rent (and combo values if needed) with the simulator (updated to build combo-friendly burgers)

## 2. Combo board and discovery

- [x] 2.1 `Settings` helper shared by the tutorial and `RunState`; `RunState.discovered`, `discover()`, `combo_discovered`
- [x] 2.2 Combo board replacing the specials strip: fixed height, station-aware, active highlights with counts, "N to discover"
- [x] 2.3 Live preview discovers combos and pops "New combo!"

## 3. Feedback and layout

- [x] 3.1 Larger, popping mult and ×mult callouts
- [x] 3.2 Grouped breakdown lines; scrolling tally; served-dish thumbnails fit; last 2 dishes
- [x] 3.3 Tutorial step 7 and the rules card describe combos

## 4. Verify and ship

- [x] 4.1 Tests: every combo, stacking, discovery and persistence, board highlights, grouping, layout of a tall burger
- [x] 4.2 Render check; export and deploy to GitHub Pages
