## MODIFIED Requirements

### Requirement: Bulk discount
Stock slots with more than one unit SHALL be cheaper per unit: the price is the unit price × quantity, reduced by a configured fraction (default 10%) for each unit beyond the first, rounded to the nearest cent. The card MUST show only the bundle's price, so players work out the saving themselves.

#### Scenario: Patty bundles
- **WHEN** patties cost $0.40 each and the discount is 10% per extra unit
- **THEN** one patty costs $0.40, two cost $0.72, and three cost $0.96

#### Scenario: Cheap items
- **WHEN** onions cost $0.10 each
- **THEN** two cost $0.18 and three cost $0.24

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
