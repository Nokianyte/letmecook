## MODIFIED Requirements

### Requirement: Buying gadgets at night
The night shop SHALL offer a configured number of gadgets (default 2), drawn at random (using the run's seed) from gadgets the player does not own, each with its price and effect. The player MUST be able to buy an offered gadget when they have the money and a free counter slot; it is placed in the leftmost free slot. Rerolling the shop MUST replace every gadget offer, including ones already bought, with gadgets the player does not own.

#### Scenario: Buy a gadget
- **WHEN** the player buys an offered gadget with enough money and a free slot
- **THEN** the price is deducted, the gadget goes in the leftmost free slot, and the offer is marked sold

#### Scenario: Counter full
- **WHEN** every counter slot is taken
- **THEN** gadget offers cannot be bought until a gadget is sold

#### Scenario: Owned gadgets are not offered
- **WHEN** the shop rolls or rerolls gadget offers
- **THEN** none of them is a gadget the player already owns

#### Scenario: Bought offer is restocked on reroll
- **WHEN** the player buys a gadget offer and then rerolls
- **THEN** that offer slot shows a different gadget for sale
