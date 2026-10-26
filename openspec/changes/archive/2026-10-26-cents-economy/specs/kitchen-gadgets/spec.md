## MODIFIED Requirements

### Requirement: Selling gadgets
During the night phase the player SHALL be able to sell an owned gadget for half its price, rounded down to the cent, freeing its slot.

#### Scenario: Sell to make room
- **WHEN** the player sells a gadget bought for $0.75
- **THEN** the player receives $0.37 and the slot is free

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
| Tip Jar | +$0.20 for every dish served |
| Lucky Coin | The first reroll each night is free |

#### Scenario: Tower Mold rewards tall burgers
- **WHEN** a 7-solid-layer burger is scored with Tower Mold on the counter
- **THEN** Tower Mold adds +1.0 mult (two layers beyond the fifth)

#### Scenario: Pro Squeeze Bottle
- **WHEN** a burger with a ketchup layer worth 2 chips is scored with Pro Squeeze Bottle
- **THEN** Pro Squeeze Bottle adds 2 chips

#### Scenario: Tip Jar
- **WHEN** the player serves a dish with Tip Jar on the counter
- **THEN** money increases by the dish's payout plus $0.20

#### Scenario: Lucky Coin
- **WHEN** the player rerolls for the first time in a night with Lucky Coin on the counter
- **THEN** the reroll costs $0, and the next reroll that night costs the normal second-reroll price
