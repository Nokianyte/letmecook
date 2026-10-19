## Purpose

Defines the roguelike shell around the core mechanic: a run of days, each spent serving dishes to beat a rent target, alternating with a night phase for shopping and storage.

## ADDED Requirements

### Requirement: Run structure
A run SHALL consist of a configured number of days (default 7). Each day MUST have a kitchen phase followed by a night phase, except the last day, which ends the run after its kitchen phase. Every run MUST use a random seed that is shown on the run-over screen.

#### Scenario: Day to night
- **WHEN** the player closes for the day and pays rent successfully on a day that is not the last
- **THEN** the night phase begins

#### Scenario: Seed shown
- **WHEN** a run ends, for any reason
- **THEN** the run-over screen shows the run's seed

### Requirement: Starting state
A new run SHALL start with configured starting money, a starting pantry of struggle staples plus a small number of better ingredients, a fridge with the starting number of slots, and no blender.

#### Scenario: New run
- **WHEN** the player starts a new run
- **THEN** day 1 begins in the kitchen with the starting money, pantry, and fridge, and without the smoothie jar

### Requirement: Earning money from served dishes
Each served dish's score SHALL be converted into money at the configured rate as soon as it is served. The kitchen MUST show the day's running total score and the current money.

#### Scenario: Money after a dish
- **WHEN** the player serves a dish scoring 20 and the rate is $0.5 per point
- **THEN** money increases by $10 and the day's total score increases by 20

### Requirement: Closing for the day
The kitchen SHALL offer a "Close for the day" action available at any time during the kitchen phase. Closing MUST end the kitchen phase and settle rent. A dish still being built when closing MUST be cleared first (its solid ingredients return to the pantry).

#### Scenario: Close with a burger in progress
- **WHEN** the player closes for the day with a bun and a patty on the board
- **THEN** the bun and the patty return to the pantry, and rent is settled

### Requirement: Rent target
Each day SHALL have a rent amount from a configured, rising curve, shown to the player throughout the kitchen phase. When the player closes for the day, rent MUST be deducted from money. If money would go below zero, the run ends in a loss.

#### Scenario: Rent paid
- **WHEN** money at closing is at least that day's rent
- **THEN** rent is deducted and the remaining money carries over

#### Scenario: Rent missed
- **WHEN** money at closing is less than that day's rent
- **THEN** the run ends in a loss and the run-over screen shows the day reached

### Requirement: Winning a run
The run SHALL end in a win when the player pays rent on the last day.

#### Scenario: Survive the last day
- **WHEN** the player pays rent on day 7 (with the default setting)
- **THEN** the run-over screen shows a win, the total score, and the seed

### Requirement: Unused ingredients carry over
Ingredients left in the pantry at the end of the kitchen phase SHALL remain owned and carry into the night phase. Nothing is refilled automatically.

#### Scenario: Leftovers kept
- **WHEN** the player closes for the day with 3 patties still in the pantry
- **THEN** those 3 patties are still owned during the night phase
