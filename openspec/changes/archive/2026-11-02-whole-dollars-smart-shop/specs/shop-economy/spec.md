## ADDED Requirements

### Requirement: Shop stock favors variety
Each stock slot in the market and smoothie bar SHALL be drawn with weighted chances. An ingredient's chance MUST fall with every unit of it the player already owns (pantry and fridge), and with every other slot of the same section already holding it in the current roll. Neither rule MUST make an ingredient impossible. The market's guaranteed meat slot is exempt from the weighting, but it counts as a slot holding that ingredient for the slots after it.

#### Scenario: Missing ingredients come up more
- **WHEN** the player owns several lettuces and no tomatoes, and the market is rolled many times
- **THEN** tomato is offered noticeably more often than lettuce

#### Scenario: Fewer repeats in one roll
- **WHEN** the market is rolled many times
- **THEN** rolls with several slots of one ingredient are much rarer than with uniform chances, but still possible

## MODIFIED Requirements

### Requirement: Bulk discount
Stock slots with more than one unit SHALL be cheaper per unit: the price is the unit price × quantity, reduced by a configured fraction (default 10%) for each unit beyond the first, rounded to the nearest dollar. The card MUST show only the bundle's price, so players work out the saving themselves.

#### Scenario: Patty bundles
- **WHEN** patties cost $4 each and the discount is 10% per extra unit
- **THEN** one patty costs $4, two cost $7, and three cost $10

#### Scenario: Cheap items
- **WHEN** onions cost $1 each
- **THEN** two cost $2 and three cost $2

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
