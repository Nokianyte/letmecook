# Let me cook!

**Play in the browser: https://nokianyte.github.io/letmecook/**

A one-mechanic cooking roguelike prototype, made in a week with Godot 4. You're broke: stack burgers and blend smoothies from whatever your pantry holds, then serve them Balatro-style — ingredients give **chips**, clever combinations give **mult**. Pay rising rent for 7 days, shop at night, keep the good stuff in the fridge, and build a counter of **Kitchen Gadgets** that bend the scoring.

The single mechanic: **assembling dishes from scarce ingredients.** Drag to stack, hold a bottle to pour, and don't let the tower fall.

## How to play

- **Burger:** drag ingredients onto the plate. The newest layer (white outline) can still be moved, or dragged off the board to take it back; it locks when you pick up the next thing. Off-center stacks lose stability and can collapse.
- **Sauce:** press a bottle and hold it over the burger to pour.
- **Serve** scores the dish: chips (ingredient value × freshness) × mult (bun ends, melted cheese, recipes, gadgets).
- **Close for the day** pays rent. At night: buy ingredients (bundles are cheaper), staples, tools and gadgets, and choose what goes in the fridge.
- **Smoothies** unlock with the blender: aim for 30–60% liquid, pair flavors, avoid muddy colors.
- **Gadgets** apply left to right on the counter — drag to reorder.
- `F1` opens a debug panel (money, skip day, run seed).

## Running the project

Open `let-me-cook/project.godot` in **Godot 4.7** (GDScript, Compatibility renderer).

```
let-me-cook/
  rules/      game rules as plain GDScript: scoring, shop, freshness, run state, gadgets
  data/       all content and tuning as .tres resources (ingredients, recipes, gadgets, balance)
  scenes/     kitchen, night shop, run-over screen
  ui/         reusable widgets (pantry chips, tally, gadget counter, how-to-play, debug)
  tools/      headless tests, the economy simulator, the deploy script
openspec/     design docs: proposal, design, specs and tasks for the prototype
```

### Tests and the economy simulator

```bash
GODOT=/path/to/godot let-me-cook/tools/run_tests.sh
```

The simulator plays hundreds of seeded runs through the real rules with simple bots; balance was tuned with it:

```bash
cd let-me-cook
SIM_RUNS=200 godot --headless --path . --script res://tools/sim.gd
SIM_GADGETS=1 godot --headless --path . --script res://tools/sim.gd   # win rate per gadget
```

### Publishing the web build

```bash
GODOT=/path/to/godot let-me-cook/tools/deploy_pages.sh
```

Exports the web build and replaces the `gh-pages` branch with it (GitHub Pages serves that branch).
