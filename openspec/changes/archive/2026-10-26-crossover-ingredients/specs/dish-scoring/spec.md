## ADDED Requirements

### Requirement: Secret crossover combos
The game SHALL include secret combos that need a crossover ingredient (one from the other station). They score like any other combo. At minimum:
- **The Elvis** (burger): banana directly touching a patty.
- **Cheesecake** (burger): strawberry directly touching cheese.
- **Green giant** (burger): spinach directly touching lettuce.
- **Protein shake** (smoothie): patty and milk in the jar.
- **Gazpacho** (smoothie): tomato, onion and water in the jar.

#### Scenario: The Elvis
- **WHEN** a burger has bun, patty, banana, bun (bottom to top)
- **THEN** it earns The Elvis as well as Bun ends

#### Scenario: Protein shake
- **WHEN** a smoothie holds a patty and two milks
- **THEN** it earns Protein shake
