## MODIFIED Requirements

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
