# ingredient-freshness Specification

## Purpose
Defines how ingredients lose value over time and how the fridge protects them, so that storage decisions feed directly into dish scores.

## Requirements

### Requirement: Every ingredient unit has a freshness value
Each owned ingredient unit SHALL carry a freshness value from 0% to 100%. A sauce bottle is one unit: all of its doses share its freshness. Ingredients bought from the shop MUST start at the freshness shown in the shop (100% unless stated otherwise). The pantry and fridge MUST show freshness for every unit.

#### Scenario: Fresh purchase
- **WHEN** the player buys lettuce shown at 100%
- **THEN** the lettuce in the pantry shows 100% freshness

### Requirement: Nightly decay by category
At the end of each night phase, every owned ingredient unit SHALL lose freshness by the configured amount for its category and storage location. Staples MUST NOT lose freshness. Freshness MUST NOT go below 0%.

#### Scenario: Perishable outside the fridge
- **WHEN** a patty at 100% stays outside the fridge overnight and perishable decay outside the fridge is 30%
- **THEN** the patty is at 70% the next day

#### Scenario: Staple never decays
- **WHEN** stale bread stays outside the fridge for several nights
- **THEN** its freshness is unchanged

### Requirement: Fridge slows decay
During the night phase the player SHALL be able to move ingredient units into and out of the fridge, up to the fridge's slot count (one unit per slot). Units in the fridge at the end of the night MUST decay by the configured in-fridge amount for their category instead of the outside amount. Units remain usable in the kitchen whether or not they are in the fridge.

#### Scenario: Fridge protects a patty
- **WHEN** a patty at 100% is in the fridge overnight and perishable decay inside the fridge is 5%
- **THEN** the patty is at 95% the next day

#### Scenario: Fridge full
- **WHEN** all fridge slots are occupied
- **THEN** the player cannot move another unit into the fridge until one is moved out

### Requirement: Spoilage at zero freshness
When a unit's freshness reaches 0%, it SHALL spoil and be removed from the pantry or fridge at the end of that night. The player MUST be told which units spoiled.

#### Scenario: Lettuce spoils
- **WHEN** a lettuce unit's freshness reaches 0% during nightly decay
- **THEN** it is removed and the next day starts with a notice listing it as spoiled
