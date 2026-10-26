# shop-economy Specification

## Purpose
Defines how the player gets ingredients and tools: a randomized nightly shop with rerolls, always-available struggle staples, and no automatic refills, so variety comes from scarcity rather than rules.

## Requirements

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

### Requirement: Bulk discount
Stock slots with more than one unit SHALL be cheaper per unit: the price is the unit price × quantity, reduced by a configured fraction (default 10%) for each unit beyond the first, rounded to the nearest cent. The card MUST show only the bundle's price, so players work out the saving themselves.

#### Scenario: Patty bundles
- **WHEN** patties cost $0.40 each and the discount is 10% per extra unit
- **THEN** one patty costs $0.40, two cost $0.72, and three cost $0.96

#### Scenario: Cheap items
- **WHEN** onions cost $0.10 each
- **THEN** two cost $0.18 and three cost $0.24

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
- **WHEN** the base cost is $0.10, the step is $0.10, and the player rerolls twice in one night
- **THEN** the rerolls cost $0.10 and $0.20, and the next reroll that night costs $0.30

#### Scenario: Reroll cost resets
- **WHEN** a new night begins
- **THEN** the reroll cost is back at the base

### Requirement: Struggle staples are always available
The shop SHALL offer struggle staples (at least stale bread and ketchup) every night in addition to the random stock, at a low configured price, in a configured nightly quantity that is restocked each night. Staples MUST NOT be affected by rerolls.

#### Scenario: Staples sell out for the night
- **WHEN** the player buys all of tonight's stale bread
- **THEN** stale bread shows as sold out until the next night, when it is restocked

#### Scenario: Staples after a reroll
- **WHEN** the player rerolls the shop
- **THEN** the staples are still offered at the same price

### Requirement: Tools
The shop SHALL offer tools for purchase: the blender (unlocks the smoothie jar) and fridge upgrades (each adds fridge slots, up to a configured maximum). A tool already owned, or a fridge already at its maximum, MUST NOT be offered again.

#### Scenario: Buy the blender
- **WHEN** the player buys the blender
- **THEN** the smoothie jar is available from the next kitchen phase, the smoothie bar opens, and the blender is no longer offered

#### Scenario: Fridge upgrade
- **WHEN** the player buys a fridge upgrade
- **THEN** the fridge gains the configured number of slots immediately
