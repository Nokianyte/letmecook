## MODIFIED Requirements

### Requirement: Callouts for gained and lost contributions
When a recalculated preview contains a contribution that the previous preview did not (an ingredient's chips, a bonus, a penalty, or a ×mult), the game SHALL show a short floating callout with its value and label that rises and fades:
- Chip callouts appear at that ingredient's layer.
- Bonus and penalty callouts appear at the top of the dish.
- Mult and ×mult callouts MUST be clearly larger than chip callouts, pop in, and stay readable clearly longer than chip callouts (at least 2.5 seconds).
- Penalties MUST be shown in red.
- A bonus that was in the previous preview and no longer applies MUST show a "lost" callout.
- Sauce MUST produce one callout per pour (when pouring stops), not one per dose.

#### Scenario: Ingredient chips
- **WHEN** a fresh patty comes to rest on the burger
- **THEN** "+8 Patty" pops up at the patty

#### Scenario: Bonus gained
- **WHEN** a cheese layer comes to rest directly on a patty
- **THEN** a large callout for the Melt bonus pops up at the top of the burger

#### Scenario: Bonus lost
- **WHEN** the burger has buns at both ends and the player drops a lettuce on top
- **THEN** a "lost" callout for "Bun ends" appears

#### Scenario: Sauce
- **WHEN** the player pours 12 doses of ketchup in one go and releases
- **THEN** a single callout shows the ketchup layer's chips
