## MODIFIED Requirements

### Requirement: Earning money from served dishes
Each served dish's score SHALL be converted into money at the configured rate as soon as it is served. The kitchen MUST show the day's running total score and the current money. Wherever a payout is shown (the "If served now" list and the tally), the game MUST also show how it was calculated: score, rate and result, plus any tips. The rules card and the tutorial MUST state the rate.

#### Scenario: Money after a dish
- **WHEN** the player serves a dish scoring 20 and the rate is $0.5 per point
- **THEN** money increases by $10 and the day's total score increases by 20

#### Scenario: Conversion is shown
- **WHEN** a dish scoring 45 is served at $0.5 per point with no tips
- **THEN** the tally shows "45 pts × $0.5 = $22"

#### Scenario: Conversion with tips
- **WHEN** the same dish is served with Tip Jar on the counter
- **THEN** the tally shows "45 pts × $0.5 = $22 + $2 tips"
