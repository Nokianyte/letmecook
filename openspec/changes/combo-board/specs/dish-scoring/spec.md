## MODIFIED Requirements

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
Scoring SHALL produce a breakdown listing every chip, mult and ×mult contribution with its source, in the order it was applied. When a dish is served, the game MUST play its breakdown back, showing chips and mult building up to the dish's score, then update the day's running total. Consecutive identical contributions MUST be shown as one line with a count. The breakdown MUST fit inside the serving window, scrolling when it is longer than the window.

#### Scenario: Tally shows contributions
- **WHEN** the player serves a burger of bun, patty, cheese, bun
- **THEN** the tally shows each ingredient's chips (with freshness), the Bun ends bonus and the Melt bonus before showing the dish's score

#### Scenario: Tall burger
- **WHEN** the player serves a 16-layer burger with four melts
- **THEN** the melts are shown as one "Melt ×4" line, and the kitchen layout stays within the screen

## REMOVED Requirements

### Requirement: Named recipe bonuses
**Reason**: Whole-dish recipes were too rigid and duplicated what combos express better.
**Migration**: The recipes' role moves to combos. Struggle Burger becomes the Bread sandwich combo, and the smoothie recipes become the Banana Shake, Green Machine and Berry Blast set combos. Classic Cheese, Double Cheese and Garden Stack are now covered by Bun ends, Melt, Double decker, Fresh pair and Veg crown.
