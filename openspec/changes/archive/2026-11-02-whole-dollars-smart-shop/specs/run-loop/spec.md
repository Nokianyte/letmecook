## ADDED Requirements

### Requirement: Money in whole dollars
All money in the game (prices, payouts, rent, tips, rerolls and sale prices) SHALL be whole dollars, shown without decimals, e.g. "$4". Payouts that come out fractional MUST be rounded down to the dollar.

#### Scenario: Shown without decimals
- **WHEN** the player has 12 dollars
- **THEN** the kitchen shows "$12"

#### Scenario: Fractional payout
- **WHEN** a dish scoring 45 is served at $0.5 per point
- **THEN** the base payout is $22

## MODIFIED Requirements

### Requirement: Earning money from served dishes
Each served dish's score SHALL be converted into money at the configured rate as soon as it is served. The kitchen MUST show the day's running total score and the current money.

#### Scenario: Money after a dish
- **WHEN** the player serves a dish scoring 20 and the rate is $0.5 per point
- **THEN** money increases by $10 and the day's total score increases by 20

## REMOVED Requirements

### Requirement: Money in dollars and cents
**Reason**: Playtesters found decimals much harder to read.
**Migration**: Replaced by "Money in whole dollars"; all amounts go back to the whole-dollar scale.
