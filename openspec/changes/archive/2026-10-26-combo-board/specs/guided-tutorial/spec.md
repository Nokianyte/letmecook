## MODIFIED Requirements

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
