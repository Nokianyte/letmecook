## Why

The assignment calls for a game prototype built around a single mechanic, due in one week, built solo. LetMeCOOK centers on **assembling dishes from a scarce pantry**: starting with "struggle meals" (stale bread and ketchup) and building up to proper burgers and smoothies over a roguelike run. The prototype must be playable in a browser so anyone can playtest it from a link.

## What Changes

- New Godot 4 (GDScript) 2D gray-box project with a web export, published to GitHub Pages for playtesting (itch.io is blocked in Russia, where playtesters are).
- Core mechanic: drag ingredients from the pantry into a container — a **burger stack** (order matters, physics on drop, the top layer can be adjusted until the next pickup, stability can collapse it) or a **smoothie jar** (order doesn't matter, ratios and color blending). Sauces are bottles with limited doses, poured onto the burger as a stream that spreads into a visible sauce layer.
- Balatro-style scoring with no customer preferences: each dish is served through the window and scored immediately as `Σ(base × freshness × amount) × (1 + Σ mult)`. Mult comes from structure, adjacency, ratio, and flavor-pair rules, plus named-recipe bonuses (e.g. "Struggle Burger", "Classic Cheese", "Green Machine").
- Run structure: N days. Each day you serve as many dishes as your pantry allows, then close for the day and must pay a rising rent or the run ends.
- Economy without automatic refills: ingredients are bought from a randomized nightly shop (rerollable at a rising cost). Struggle staples are restocked every night in a small fixed quantity as a safety floor. Tools (blender unlocks smoothies; fridge upgrades) are also sold.
- Kitchen Gadgets (the run's jokers): build-shaping items bought at night and kept on a counter with limited, ordered slots. In counter order they add chips, add mult, or multiply mult, or bend the economy, so each run pulls toward a playstyle (meat stacks, tall towers, sauce, smoothies, thrift).
- Freshness: each ingredient carries a freshness % that scales its chips and decays every night by category. A limited-slot fridge slows decay. At 0% the item spoils.
- All tunable numbers (prices, decay rates, rent curve, ingredient data, recipes) live in data files, not code.

## Capabilities

### New Capabilities
- `kitchen-assembly`: Dragging ingredients into burger and smoothie containers, burger stacking with drop physics, the adjustable live top layer, stability/collapse, sauce bottles and pouring, smoothie jar mixing, and serving.
- `dish-scoring`: Chips × mult scoring of a single dish, including freshness-scaled chips, structure/adjacency/ratio/flavor rules, named recipe bonuses, and the animated score tally.
- `run-loop`: Run and day structure: day phase, earning money per served dish, closing for the day, rent target, the conversion of score into money, win/lose conditions, and starting state.
- `shop-economy`: The nightly shop with randomized stock and rerolls, always-available struggle staples, tool purchases (blender, fridge upgrades), and the pantry with no automatic refill.
- `ingredient-freshness`: Per-ingredient freshness %, nightly decay by category, fridge slots that slow decay, and spoilage at 0%.
- `kitchen-gadgets`: The counter of ordered gadget slots, buying/selling/reordering gadgets, gadget effects applied in counter order during scoring (including ×mult) and in the economy, gadget feedback in the tally, and the starting gadget set.

### Modified Capabilities
<!-- None: this is a new project with no existing specs. -->

## Impact

- New project; no existing code is affected.
- Dependencies: Godot 4.x (a version with single-threaded web export), GDScript only (C# Godot projects cannot export to web).
- Hosting: GitHub Pages (the `gh-pages` branch, published by `let-me-cook/tools/deploy_pages.sh`); any static host works.
- Out of scope for this change: customers and orders, art beyond gray-box shapes, audio polish, save/load, mobile controls. Stretch goals (in-day discard/reroll, boss days, overripe bonuses, discount stock) and the backlog gadgets from the design's catalog are listed in design and tasks but are not required.
