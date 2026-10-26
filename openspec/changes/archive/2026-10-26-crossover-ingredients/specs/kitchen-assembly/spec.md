## MODIFIED Requirements

### Requirement: Drag ingredients from the pantry into a container
The kitchen SHALL show every ingredient the player owns, and the player SHALL be able to drag one unit of a solid ingredient onto an active container (burger board or smoothie jar). Every solid burger ingredient MUST also be accepted by the smoothie jar, and fruit and spinach MUST also be accepted by the burger board (crossover ingredients). Liquids, yogurt and sauces stay in their own station. Dropping a unit into a container MUST remove it from the pantry. Dropping anywhere else MUST return it to the pantry unchanged.

#### Scenario: Drop onto the burger board
- **WHEN** the player drags a patty from the pantry and releases it over the burger board
- **THEN** the patty is added to the burger and the pantry count for patties decreases by one

#### Scenario: Crossover into the jar
- **WHEN** the player owns the blender and drags a patty onto the smoothie jar
- **THEN** the patty goes into the jar

#### Scenario: Crossover onto the burger
- **WHEN** the player drags a banana onto the burger board
- **THEN** the banana becomes the burger's new layer

#### Scenario: Drop outside any container
- **WHEN** the player releases a dragged ingredient over empty space
- **THEN** the ingredient returns to the pantry and its count is unchanged

#### Scenario: Smoothie jar unavailable without a blender
- **WHEN** the player does not own the blender
- **THEN** the smoothie jar is not shown and ingredients can only be dropped onto the burger board
