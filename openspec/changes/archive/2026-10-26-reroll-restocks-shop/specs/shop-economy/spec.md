## MODIFIED Requirements

### Requirement: Randomized nightly shop
During each night phase the shop SHALL offer a market of a configured number of stock slots, drawn at random (using the run's seed) from the burger ingredients. Each slot MUST show the ingredient, its quantity, its price, and its freshness. The first slot MUST always offer a single unit of a meat ingredient, also after rerolls, so meat is always affordable. Sauces MUST be sold as full bottles. Purchased ingredients MUST go to the pantry.

#### Scenario: Meat is always on offer
- **WHEN** the market is rolled or rerolled
- **THEN** its first slot offers exactly one unit of a meat ingredient

#### Scenario: New stock each night
- **WHEN** a night phase begins
- **THEN** the shop shows newly rolled stock

#### Scenario: Buy an ingredient
- **WHEN** the player buys a stock slot and has enough money
- **THEN** the price is deducted, the ingredient is added to the pantry, and the slot is marked sold

#### Scenario: Not enough money
- **WHEN** the player cannot afford a stock slot
- **THEN** buying that slot is disabled

### Requirement: Smoothie bar
Once the player owns the blender, the night shop SHALL also offer a smoothie bar: a configured number of stock slots drawn at random from the smoothie ingredients, shown as its own section. The market MUST NOT offer smoothie ingredients. Rerolls MUST restock every smoothie bar slot, sold ones included, together with the market.

#### Scenario: No blender, no smoothie bar
- **WHEN** the player does not own the blender
- **THEN** the night shop shows no smoothie bar and no smoothie ingredients

#### Scenario: Smoothie bar after buying the blender
- **WHEN** the player buys the blender during the night
- **THEN** the smoothie bar appears right away with smoothie ingredients, and the market keeps its burger ingredients

### Requirement: Rerolling the shop
The player SHALL be able to reroll the shop for money. A reroll MUST replace every stock slot with newly rolled stock, including slots that were already bought; bought items stay with the player. The reroll cost MUST start at a configured base and increase by a configured step with each reroll during the same night, resetting to the base the next night.

#### Scenario: Sold slots are restocked
- **WHEN** the player has bought every slot in the market and rerolls
- **THEN** every slot offers new stock for sale

#### Scenario: Rising reroll cost
- **WHEN** the base cost is $1, the step is $1, and the player rerolls twice in one night
- **THEN** the rerolls cost $1 and $2, and the next reroll that night costs $3

#### Scenario: Reroll cost resets
- **WHEN** a new night begins
- **THEN** the reroll cost is back at the base
