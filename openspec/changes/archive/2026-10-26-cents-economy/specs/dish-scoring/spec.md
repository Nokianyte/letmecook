## MODIFIED Requirements

### Requirement: Score breakdown and tally
Scoring SHALL produce a breakdown listing every chip, mult and ×mult contribution with its source, in the order it was applied. When a dish is served, the game MUST play its breakdown back, showing chips and mult building up to the dish's score, then update the day's running total. Each line of the played-back breakdown, and the final score, MUST fade in while shrinking from a larger size to its normal size. Consecutive identical contributions MUST be shown as one line with a count. The breakdown MUST fit inside the serving window, scrolling when it is longer than the window.

#### Scenario: Tally shows contributions
- **WHEN** the player serves a burger of bun, patty, cheese, bun
- **THEN** the tally shows each ingredient's chips (with freshness), the Bun ends bonus and the Melt bonus before showing the dish's score

#### Scenario: Lines fade in shrinking
- **WHEN** a line of the tally appears
- **THEN** it starts transparent and larger than normal, and fades in while shrinking to its normal size

#### Scenario: Tall burger
- **WHEN** the player serves a 16-layer burger with four melts
- **THEN** the melts are shown as one "Melt ×4" line, and the kitchen layout stays within the screen
