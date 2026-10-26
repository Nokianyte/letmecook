# combo-board Specification

## Purpose
Shows the player which combos (the rules that give or take mult) they know about, lights up the ones the dish in progress already has, and grows as new combos are discovered by building them.

## Requirements

### Requirement: Board of discovered combos
The kitchen SHALL show a combo board above the plate listing every discovered combo of the current station: its name, a short rule, and its mult value (penalties in red). The board MUST also show how many combos of that station are still undiscovered. Secret combos MUST NOT be counted or listed until discovered; while any of the station's secret combos are undiscovered, the board only hints that secret ones exist. Discovered secret combos are marked as secret. Smoothie combos MUST only appear once the blender is owned. The board's size MUST NOT change while a burger is being built.

#### Scenario: Fresh save
- **WHEN** a player who has discovered nothing starts their first run
- **THEN** the board shows only the starter combos (Bun ends, Melt, Sauced patty) and how many burger combos remain to be discovered

#### Scenario: Secrets stay hidden
- **WHEN** the player has discovered every regular burger combo but not The Elvis
- **THEN** the board shows no count of combos left, only a hint that secret ones exist

#### Scenario: Station follows the dish
- **WHEN** the player owns the blender and drops an ingredient into the jar
- **THEN** the board shows the discovered smoothie combos

### Requirement: Discovering combos
The first time a dish in progress earns a combo that is not yet discovered, the game SHALL mark it discovered, add it to the board, and show a prominent "New combo!" callout with its name and value. Discovered combos MUST be remembered across runs and page reloads.

#### Scenario: First lettuce shield
- **WHEN** the player places lettuce directly on the bottom bun for the first time
- **THEN** a "New combo! Lettuce shield" callout appears and Lettuce shield is added to the board

#### Scenario: Remembered
- **WHEN** the player discovered Tangy crunch in a previous run and starts a new run
- **THEN** Tangy crunch is on the board from the start

### Requirement: Active combos are highlighted
While a dish is in progress, every combo on the board that the dish currently earns SHALL be highlighted, with a count when the dish earns it more than once.

#### Scenario: Two melts
- **WHEN** the burger in progress has patty, cheese, patty
- **THEN** the Melt chip is highlighted with "×2", and Double decker is highlighted if it has been discovered
