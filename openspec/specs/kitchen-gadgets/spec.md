# kitchen-gadgets Specification

## Purpose
Kitchen Gadgets are the run's build-shaping items, in the role of Balatro's jokers: owned gadgets sit on a counter in an order the player chooses and change how dishes score or how the economy works, so each run pulls toward a playstyle (meat stacks, tall towers, sauce, smoothies, thrift).

## Requirements

### Requirement: Counter with ordered slots
The player SHALL own gadgets on a counter with a configured number of slots (default 3). The counter MUST keep its gadgets in a left-to-right order, MUST be visible in the kitchen and at night, and MUST show each gadget's name and effect. A run MUST start with an empty counter, and owned gadgets MUST stay for the rest of the run.

#### Scenario: New run
- **WHEN** a new run starts
- **THEN** the counter is empty and shows its free slots

#### Scenario: Gadgets persist
- **WHEN** the player owns a gadget and a night ends
- **THEN** the gadget is still on the counter the next day

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

### Requirement: Selling gadgets
During the night phase the player SHALL be able to sell an owned gadget for half its price, rounded down, freeing its slot.

#### Scenario: Sell to make room
- **WHEN** the player sells a gadget bought for $8
- **THEN** the player receives $4 and the slot is free

### Requirement: Reordering the counter
The player SHALL be able to reorder gadgets on the counter by dragging them, in the kitchen and at night. The order MUST be kept until the player changes it.

#### Scenario: Drag to reorder
- **WHEN** the player drags the rightmost gadget onto the leftmost slot
- **THEN** it becomes the first gadget and the others shift right

### Requirement: Gadgets in scoring, in counter order
After a dish's chips, station rules and recipe bonus are applied, each scoring gadget SHALL apply its effect in counter order, left to right. A gadget effect MUST be one of: add chips, add mult, or multiply mult (×mult), applied to the totals at that point. Each effect that applies MUST appear as a breakdown line named after the gadget. The minimum mult MUST be applied after all gadgets.

#### Scenario: Order changes the score
- **WHEN** a bun, patty, bun burger (mult 2 before gadgets) is scored with Cast-Iron Griddle (+0.5 mult per patty) left of Sesame Seeds (×1.2 mult with bun ends)
- **THEN** mult is (2 + 0.5) × 1.2 = 3.0, and with the two gadgets swapped it is 2 × 1.2 + 0.5 = 2.9

#### Scenario: A gadget that doesn't apply
- **WHEN** a smoothie is scored with Cast-Iron Griddle on the counter
- **THEN** the griddle adds no line and changes nothing

### Requirement: Gadget feedback
When the tally plays a dish's breakdown, each gadget line SHALL show the gadget's name and effect, and the matching gadget on the counter MUST visibly react at that moment.

#### Scenario: Gadget reacts during the tally
- **WHEN** the tally reaches a line from Sesame Seeds
- **THEN** the line reads "×1.20 Sesame Seeds" and the Sesame Seeds card on the counter wiggles

### Requirement: Starting gadget set
The prototype SHALL include at least these gadgets (prices are configured in data):

| Gadget | Effect |
|---|---|
| Cast-Iron Griddle | +0.5 mult per patty layer |
| Cheese Grater | +0.5 extra mult per cheese–patty melt (doubles the melt bonus) |
| Sesame Seeds | ×1.2 mult if the burger has a bun-tagged layer at the bottom and the top |
| Tower Mold | +0.5 mult per solid layer beyond the fifth |
| Pro Squeeze Bottle | Sauce layers give ×2 chips (adds their chips again) |
| Fruit Basket | +1 mult per distinct fruit in a smoothie |
| Tip Jar | +$2 for every dish served |
| Lucky Coin | The first reroll each night is free |

#### Scenario: Tower Mold rewards tall burgers
- **WHEN** a 7-solid-layer burger is scored with Tower Mold on the counter
- **THEN** Tower Mold adds +1.0 mult (two layers beyond the fifth)

#### Scenario: Pro Squeeze Bottle
- **WHEN** a burger with a ketchup layer worth 2 chips is scored with Pro Squeeze Bottle
- **THEN** Pro Squeeze Bottle adds 2 chips

#### Scenario: Tip Jar
- **WHEN** the player serves a dish with Tip Jar on the counter
- **THEN** money increases by the dish's payout plus $2

#### Scenario: Lucky Coin
- **WHEN** the player rerolls for the first time in a night with Lucky Coin on the counter
- **THEN** the reroll costs $0, and the next reroll that night costs the normal second-reroll price
