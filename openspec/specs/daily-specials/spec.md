# daily-specials Specification

## Purpose
Gives players concrete targets each day: a small board of recipes worth aiming for, valued with the player's own gadgets, with progress shown for the dish they are building.

## Requirements

### Requirement: A specials board each day
Each kitchen day SHALL show a board of a configured number of specials (default 3): different recipes drawn at random from the run's seed and the day, so the same seed and day always give the same specials. Smoothie recipes MUST only be drawn when the player owns the blender. The board MUST be redrawn at the start of every day and stay the same throughout the day.

#### Scenario: New specials each day
- **WHEN** the player opens the kitchen on a new day
- **THEN** the specials board shows a fresh draw of recipes

#### Scenario: Same seed, same specials
- **WHEN** two runs with the same seed reach the same day
- **THEN** they show the same specials

#### Scenario: No smoothies without a blender
- **WHEN** the player does not own the blender
- **THEN** no smoothie recipe is on the board

### Requirement: Specials show what they are worth
Each special SHALL show the recipe's name, its ingredients (as its example build), and its value: the score and payout of the example build at 100% freshness, scored with the player's current gadgets in counter order. Values MUST update when the player's gadgets or their order change.

#### Scenario: Value includes gadgets
- **WHEN** a Classic Cheese special is on the board and the player owns Sesame Seeds
- **THEN** its value is the Classic Cheese example build's score with the Sesame Seeds bonus applied

### Requirement: Progress toward specials
While a dish is in progress, each special SHALL mark which of its ingredients the dish already contains. A special whose recipe the dish in progress matches MUST be highlighted.

#### Scenario: Partial progress
- **WHEN** the board holds a bun and a patty and Classic Cheese is a special
- **THEN** the Classic Cheese special marks bun and patty as done and cheese and the top bun as still needed

#### Scenario: Recipe matched
- **WHEN** the dish in progress matches a special's recipe
- **THEN** that special is highlighted

### Requirement: Specials guide, they don't restrict
Recipes that are not on today's board SHALL still be recognised and score as usual.

#### Scenario: Off-board recipe
- **WHEN** the player serves a Struggle Burger on a day it isn't a special
- **THEN** it still gets the Struggle Burger bonus
