# guided-tutorial Specification

## Purpose
Teaches the game by doing instead of by reading: on first launch a coach walks the player through a first burger, serving, closing the day and the night shop, one action at a time.

## Requirements

### Requirement: First-launch offer
On the first launch the game SHALL offer to play the tutorial or skip it. Once the tutorial has been finished or skipped, the offer MUST NOT appear again on later launches in the same browser.

#### Scenario: First launch
- **WHEN** the game starts for the first time in a browser
- **THEN** it offers "Play the tutorial" and "Skip"

#### Scenario: Later launches
- **WHEN** the player skipped or finished the tutorial before and opens the game again
- **THEN** the game starts without the offer

### Requirement: Guided steps
The tutorial SHALL start a fresh run and walk through these steps in order, each with a coach message and a highlight on what to use, advancing only when the player has done it (or pressed Next, for explanation steps):
1. Drop a stale bread on the plate.
2. Put the patty on top.
3. Pour some ketchup on the patty.
4. Top it with stale bread (buns on both ends).
5. Serve it.
6. Explanation of the tally: chips × mult (Next).
7. Explanation of the combo board: combos give mult, light up when the burger has them, and new ones are discovered by trying layer orders (Next).
8. Close for the day.
9. At night: the market and bundles (Next).
10. The fridge (Next).
11. Kitchen Gadgets and their order (Next).
12. Done (Next), leaving the player at night to continue the run.
The highlight MUST NOT block the player from interacting with the game.

#### Scenario: Waits for the action
- **WHEN** the coach asks the player to put the patty on top
- **THEN** the tutorial stays on that step until a patty is on the burger

#### Scenario: Explanation step
- **WHEN** the coach explains the tally
- **THEN** it shows a Next button and advances when it is pressed

### Requirement: Recovering from mistakes
If the burger collapses or the board is emptied during the burger steps (1–4), the tutorial SHALL explain how to recover and return to the first burger step once the board is empty.

#### Scenario: Collapse during the tutorial
- **WHEN** the burger collapses on step 3
- **THEN** the coach says to discard it and try again with layers centered, and the tutorial resumes from step 1 once the board is empty

### Requirement: Skip and replay
The player SHALL be able to skip the tutorial at any step. The "?" button SHALL open a menu with "Replay the tutorial", "Rules reference" (the full rules text) and "Close".

#### Scenario: Skip mid-way
- **WHEN** the player presses "Skip tutorial" on any step
- **THEN** the coach disappears, the run continues, and the tutorial counts as done

#### Scenario: Replay
- **WHEN** the player chooses "Replay the tutorial" from the "?" menu
- **THEN** a fresh run starts and the tutorial begins at step 1
