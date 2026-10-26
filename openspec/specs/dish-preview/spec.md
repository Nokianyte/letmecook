# dish-preview Specification

## Purpose
Shows players what their dish is worth while they build it, so the scoring rules are learned by doing: the dish in progress is scored live, each contribution pops up where it happened, and the serving window keeps a running breakdown.

## Requirements

### Requirement: Live score preview
While a burger or smoothie is in progress, the game SHALL score it as if it were served right now, using the same scoring rules and the player's gadgets in counter order. The preview MUST be recalculated whenever the dish changes: a layer comes to rest, locks, is removed or re-dropped, a pour stops, or the jar's contents change. A ruined burger MUST have no preview.

#### Scenario: Preview follows the stack
- **WHEN** the player has a bun and a patty on the plate and drops cheese that comes to rest on the patty
- **THEN** the preview includes the cheese's chips and the melt bonus

#### Scenario: Preview matches serving
- **WHEN** the player serves a dish right after the preview was calculated
- **THEN** the served score equals the preview's score

### Requirement: Callouts for gained and lost contributions
When a recalculated preview contains a contribution that the previous preview did not (an ingredient's chips, a bonus, a penalty, or a ×mult), the game SHALL show a short floating callout with its value and label that rises and fades:
- Chip callouts appear at that ingredient's layer.
- Bonus and penalty callouts appear at the top of the dish.
- Mult and ×mult callouts MUST be clearly larger than chip callouts and pop in.
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

### Requirement: "If served now" list
While a dish is in progress and no score tally is playing, the serving window SHALL list the preview's breakdown, followed by the expected score and payout:
- The list covers chips, bonuses, penalties, ×mult and gadget lines, in scoring order, grouped like the tally.
- When the dish is served, the list is replaced by the animated tally.
- When nothing is in progress, the list is hidden.

#### Scenario: Building a Classic Cheese
- **WHEN** the board holds bun, patty, cheese, bun (what used to be the Classic Cheese recipe)
- **THEN** the list shows each ingredient's chips, "Bun ends", "Melt", and the expected score and money
