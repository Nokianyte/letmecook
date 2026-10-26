## Purpose

Defines how a finished dish is scored, Balatro-style: ingredient quality gives chips, clever combinations give mult, and there are no customer preferences.

## ADDED Requirements

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
Burgers SHALL earn mult for structure and for specific adjacent layers, and lose mult for bad adjacencies. At minimum:
- **Structure:** a bun-tagged ingredient as both the bottom and top layer gives a mult bonus.
- **Melt:** a cheese layer directly touching a patty layer gives a mult bonus.
- **Soggy:** a sauce layer directly on the bottom bun gives a mult penalty.

#### Scenario: Proper bun structure
- **WHEN** a burger's bottom and top layers are both bun-tagged
- **THEN** the structure bonus is added to mult

#### Scenario: Melt bonus
- **WHEN** cheese sits directly above or below a patty
- **THEN** the melt bonus is added to mult

#### Scenario: Soggy penalty
- **WHEN** a sauce layer sits directly on top of the bottom bun
- **THEN** the soggy penalty is subtracted from mult

### Requirement: Smoothie ratio and flavor rules
Smoothies SHALL earn mult for a good balance between liquid and thick ingredients (within a configured ratio range) and for configured flavor pairs. A smoothie whose blended color is classified as muddy (too many clashing colors) MUST receive a mult penalty.

#### Scenario: Good ratio
- **WHEN** a smoothie's liquid-to-thick ratio is within the configured range
- **THEN** the ratio bonus is added to mult

#### Scenario: Flavor pair
- **WHEN** a smoothie contains both ingredients of a configured flavor pair (e.g. banana and berry)
- **THEN** that pair's bonus is added to mult

### Requirement: Named recipe bonuses
The game SHALL define named recipes, each matching a specific composition. When a dish matches a named recipe, the dish MUST show the recipe's name and add its mult bonus. Sauce layers MUST be ignored when matching a recipe that lists no sauces. If a dish matches more than one recipe, only the one with the largest bonus MUST apply. The prototype MUST include at least: "Struggle Burger" (only stale bread and ketchup), "Classic Cheese" (bun, patty, cheese, bun, in that order), and "Green Machine" (spinach, banana, and milk), plus a few more of your choice.

#### Scenario: Struggle Burger
- **WHEN** a burger contains only stale bread and ketchup
- **THEN** the dish is labeled "Struggle Burger" and the recipe's mult bonus is applied

#### Scenario: Extra sauce doesn't break a recipe
- **WHEN** a burger has bun, patty, ketchup, cheese, bun (bottom to top)
- **THEN** it matches "Classic Cheese", because that recipe lists no sauces and the ketchup layer is ignored

#### Scenario: Order matters for burger recipes
- **WHEN** a burger has bun, cheese, patty, bun (bottom to top)
- **THEN** it does not match "Classic Cheese"

### Requirement: Score breakdown and tally
Scoring SHALL produce a breakdown listing every chip, mult and ×mult contribution with its source, in the order it was applied. When a dish is served, the game MUST play its breakdown back, showing chips and mult building up to the dish's score, then update the day's running total.

#### Scenario: Tally shows contributions
- **WHEN** the player serves a Classic Cheese burger
- **THEN** the tally shows each ingredient's chips (with freshness), the melt bonus, the structure bonus, and the recipe bonus before showing the dish's score
