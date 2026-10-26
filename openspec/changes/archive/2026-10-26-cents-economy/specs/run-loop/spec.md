## ADDED Requirements

### Requirement: Money in dollars and cents
All money in the game (prices, payouts, rent, tips, rerolls and sale prices) SHALL be whole numbers of cents. It MUST always be shown in dollars with two decimals, e.g. "$0.40" or "$12.05". Payouts that come out fractional MUST be rounded down to the cent.

#### Scenario: Shown with cents
- **WHEN** the player has 1,250 cents
- **THEN** the kitchen shows "$12.50"

#### Scenario: Small prices
- **WHEN** a staple costs 10 cents
- **THEN** its Buy button reads "Buy $0.10"

## MODIFIED Requirements

### Requirement: Earning money from served dishes
Each served dish's score SHALL be converted into money at the configured rate as soon as it is served. The kitchen MUST show the day's running total score and the current money.

#### Scenario: Money after a dish
- **WHEN** the player serves a dish scoring 21 and the rate is 5 cents per point
- **THEN** money increases by $1.05 and the day's total score increases by 21
