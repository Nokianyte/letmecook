# dish-scoring Specification

## Purpose
Defines how a finished dish is scored, Balatro-style: ingredient quality gives chips, clever combinations give mult, and there are no customer preferences.

## Requirements

### Requirement: Chips times mult
Each dish's score SHALL be `chips × mult`, where chips is the sum over its layers of `base value × freshness × amount` (freshness from 0% to 100%; amount is 1 for a solid ingredient and the number of doses for a sauce layer, whose base value is per dose), and mult is `1` plus all mult bonuses and penalties that apply. Kitchen Gadgets then apply in counter order and may add chips, add mult, or multiply mult (see kitchen-gadgets). Mult MUST NOT go below a configured minimum (default 1), checked after all of these.

#### Scenario: Plain dish
- **WHEN** a dish holds a patty (base 8, freshness 100%) and stale bread (base 2, freshness 100%), and no bonuses apply
- **THEN** chips is 10, mult is 1, and the score is 10

#### Scenario: Freshness scales chips only
- **WHEN** a patty with base 8 is at 50% freshness
- **THEN** it contributes 4 chips, and the mult bonuses it takes part in are unchanged

#### Scenario: Sauce amount
- **WHEN** a burger has a ketchup layer of 4 doses, ketchup's base value is 0.5 per dose, and the bottle is at 100%
- **THEN** the ketchup layer contributes 2 chips

### Requirement: Burger structure and adjacency rules
Burgers SHALL earn mult from a configured list of combos, which are rules on structure, adjacency and order. Every combo that applies adds its mult, and several combos stack. Some combos count once per occurrence. At minimum:
- **Bun ends:** a bun-tagged layer at the bottom and at the top.
- **Melt** (each): cheese directly touching a patty.
- **Sauced patty** (each): a sauce layer directly on top of a patty.
- **Lettuce shield:** lettuce directly on the bottom bun.
- **Fresh pair** (each): tomato directly touching lettuce.
- **Tangy crunch** (each): pickles directly touching onion.
- **Double decker:** patty, cheese, patty in a row.
- **Bread sandwich:** only stale bread, ketchup, stale bread (bottom to top).
- **Veg crown:** a veg-tagged layer directly under the top bun (sauce between them is allowed).
- **Sauce duo:** ketchup directly touching mustard.
- **Soggy bottom** (penalty): a sauce layer directly on the bottom bun.

#### Scenario: Proper bun structure
- **WHEN** a burger's bottom and top layers are both bun-tagged
- **THEN** the Bun ends bonus is added to mult

#### Scenario: Melt bonus
- **WHEN** cheese sits directly above or below a patty
- **THEN** the Melt bonus is added to mult

#### Scenario: Soggy penalty
- **WHEN** a sauce layer sits directly on top of the bottom bun
- **THEN** the Soggy bottom penalty is subtracted from mult

#### Scenario: Combos stack
- **WHEN** a burger is bun, lettuce, patty, ketchup, cheese, tomato, bun (bottom to top)
- **THEN** it earns Bun ends, Lettuce shield, Sauced patty and Veg crown, and no Melt, because the ketchup separates the patty from the cheese

#### Scenario: Struggle meal
- **WHEN** a burger is stale bread, ketchup, stale bread
- **THEN** it earns Bun ends and Bread sandwich

### Requirement: Smoothie ratio and flavor rules
Smoothies SHALL earn mult from smoothie combos:
- **Good thickness:** the liquid share of liquid and thick ingredients is within a configured range.
- **Flavor pair** (each): a configured pair of ingredients that go together.
- **Muddy color** (penalty): the blended color is classified as muddy because it has too many clashing colors.
- Set combos that need specific ingredients together, in any amounts: **Banana Shake** (banana and milk), **Green Machine** (spinach, banana and milk), **Berry Blast** (strawberry, blueberry and yogurt).

#### Scenario: Good ratio
- **WHEN** a smoothie's liquid-to-thick ratio is within the configured range
- **THEN** the Good thickness bonus is added to mult

#### Scenario: Flavor pair
- **WHEN** a smoothie contains both ingredients of a configured flavor pair (e.g. banana and berry)
- **THEN** that pair's bonus is added to mult

#### Scenario: Set combos stack
- **WHEN** a smoothie contains spinach, banana and milk
- **THEN** it earns both Green Machine and Banana Shake

### Requirement: Score breakdown and tally
Scoring SHALL produce a breakdown listing every chip, mult and ×mult contribution with its source, in the order it was applied. When a dish is served, the game MUST play its breakdown back, showing chips and mult building up to the dish's score, then update the day's running total. Each line of the played-back breakdown, and the final score, MUST fade in while shrinking from a larger size to its normal size. Consecutive identical contributions MUST be shown as one line with a count. The breakdown MUST fit inside the serving window, scrolling when it is longer than the window.

#### Scenario: Tally shows contributions
- **WHEN** the player serves a burger of bun, patty, cheese, bun
- **THEN** the tally shows each ingredient's chips (with freshness), the Bun ends bonus and the Melt bonus before showing the dish's score

#### Scenario: Lines fade in shrinking
- **WHEN** a line of the tally appears
- **THEN** it starts transparent and larger than normal, and fades in while shrinking to its normal size

#### Scenario: Tall burger
- **WHEN** the player serves a 16-layer burger with four melts
- **THEN** the melts are shown as one "Melt ×4" line, and the kitchen layout stays within the screen

### Requirement: Secret crossover combos
The game SHALL include secret combos that need a crossover ingredient (one from the other station). They score like any other combo. At minimum:
- **The Elvis** (burger): banana directly touching a patty.
- **Cheesecake** (burger): strawberry directly touching cheese.
- **Green giant** (burger): spinach directly touching lettuce.
- **Protein shake** (smoothie): patty and milk in the jar.
- **Gazpacho** (smoothie): tomato, onion and water in the jar.

#### Scenario: The Elvis
- **WHEN** a burger has bun, patty, banana, bun (bottom to top)
- **THEN** it earns The Elvis as well as Bun ends

#### Scenario: Protein shake
- **WHEN** a smoothie holds a patty and two milks
- **THEN** it earns Protein shake
