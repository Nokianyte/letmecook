# kitchen-assembly Specification

## Purpose
Defines the core mechanic: building burgers and smoothies by dragging owned ingredients into a container, pouring sauces from bottles, and serving finished dishes.

## Requirements

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

### Requirement: Burger stacking is ordered and physical
Ingredients dropped onto the burger board SHALL fall onto the stack with physics. The burger MUST record its layers in bottom-to-top order. Only one layer may be falling at a time; the board MUST refuse a new drop until the falling layer has come to rest.

#### Scenario: Layer order is recorded
- **WHEN** the player drops a bun, then a patty, then cheese
- **THEN** the burger's layers are bun (bottom), patty, cheese (top)

#### Scenario: Off-center drop
- **WHEN** the player drops an ingredient so it lands partly off the layer below
- **THEN** it rests at that offset

### Requirement: The top layer stays live until the next pickup
The most recently dropped solid layer SHALL stay live: it is not locked into the stack and the player can pick it up again. It MUST lock in place when the player picks up another ingredient or sauce bottle from the pantry, or serves the burger. Once locked, a layer MUST NOT move again unless the burger collapses.

#### Scenario: Picking up the next ingredient locks the live layer
- **WHEN** a patty is the live layer and the player starts dragging cheese from the pantry
- **THEN** the patty locks in place

#### Scenario: Locked layers stay put
- **WHEN** a layer has locked
- **THEN** it cannot be picked up and does not move as later layers land on it

### Requirement: Repositioning the live layer
The player SHALL be able to drag the live layer to any position. Releasing it over the burger board MUST drop it again from the release point. Releasing it anywhere else MUST return the unit to the pantry with its freshness unchanged.

#### Scenario: Re-drop the live layer
- **WHEN** the player drags the live cheese and releases it further left over the board
- **THEN** the cheese falls again from the release point and is still the live layer

#### Scenario: Return the live layer to the pantry
- **WHEN** the player drags the live cheese and releases it over the pantry
- **THEN** the cheese is removed from the burger and is back in the pantry

### Requirement: Unstable burgers collapse
Whenever a layer locks, the game SHALL compute the burger's stability from how far each layer is offset from the one below and from the burger's height. When stability falls below the configured threshold, the burger MUST visibly collapse and become ruined. A ruined burger's ingredients are lost. While a layer is live, the board MUST show the stability the burger would have if it locked now.

#### Scenario: Locking an offset layer collapses the burger
- **WHEN** an offset layer locks and the burger's stability drops below the threshold
- **THEN** the burger plays a collapse, is marked ruined, and its ingredients are not returned to the pantry

#### Scenario: Adjusting avoids a collapse
- **WHEN** the live layer would make the burger collapse and the player re-drops it centered before picking up the next ingredient
- **THEN** the burger does not collapse when the layer locks

### Requirement: Sauce bottles
Sauces SHALL be owned as bottles, each holding a number of doses (its capacity) and sharing one freshness value. The pantry MUST show each bottle's remaining doses. The player SHALL pour by pressing a bottle and moving it over the burger while holding the mouse button: while the cursor is above the top solid layer (or above the plate when the burger is empty), sauce MUST stream out of the bottle's nozzle at a fixed rate of doses. Pouring MUST pause while the cursor is anywhere else and stop when the button is released or the bottle is empty. Picking up a bottle locks the live layer. An empty bottle MUST be removed from the pantry.

#### Scenario: Pour a few doses
- **WHEN** the player holds a ketchup bottle with 40 doses over the burger long enough for 3 doses and releases
- **THEN** 3 doses of ketchup land on the burger and the bottle shows 37 doses left

#### Scenario: Bottle runs out
- **WHEN** the player keeps pouring until a bottle has no doses left
- **THEN** pouring stops and the bottle disappears from the pantry

### Requirement: Sauce becomes part of the burger
Poured sauce SHALL fall as a stream straight down from the bottle's nozzle onto the top solid layer (or the plate), without physics. Each dose MUST add sauce where the stream lands, and the sauce MUST spread a little and merge into one smooth surface on that layer, so moving while pouring draws a line and holding still makes a puddle. Consecutive doses of the same sauce poured onto the same layer MUST be recorded as one sauce layer, with an amount equal to the number of doses, placed directly above that layer in the burger's layer order. A later solid layer MUST rest on the sauce as on a flat cushion: the cushion covers the area where sauce was poured and is as thick as the sauce's average thickness there. When the solid comes to rest, the sauce under it MUST flatten into that uniform layer (keeping the same amount of sauce), so the burger shows the sauce between the two solids.

#### Scenario: Pouring while moving
- **WHEN** the player pours while moving the bottle from the left edge of the bun to the right edge
- **THEN** a continuous line of sauce covers the bun from left to right

#### Scenario: Covered sauce stays visible
- **WHEN** the player pours ketchup on a bun and drops a patty on top
- **THEN** the patty rests on a flat ketchup layer, and the ketchup is visible between the bun and the patty

#### Scenario: Sauce between bun and patty
- **WHEN** the player locks a bun, pours 4 doses of ketchup, then drops a patty
- **THEN** the burger's layers are bun, ketchup (amount 4), patty

### Requirement: Smoothie jar mixing
Ingredients dropped into the smoothie jar SHALL be added to the smoothie regardless of order. The jar MUST display a color blended from the colors of its contents, weighted by amount.

#### Scenario: Mix color updates
- **WHEN** the player adds a banana and then a strawberry to the jar
- **THEN** the jar shows a color blended between the banana's and the strawberry's colors

### Requirement: Clearing a container in progress
Before a dish is served, the player SHALL be able to clear a container. Clearing MUST return all solid ingredients, with their freshness unchanged, to the pantry. Sauce already poured MUST be lost. Clearing a ruined burger discards it.

#### Scenario: Clear a burger
- **WHEN** the player clears a standing burger made of bun, ketchup (3 doses) and patty
- **THEN** the bun and the patty return to the pantry, the ketchup doses are not returned, and the board is empty

### Requirement: Serving a dish
The player SHALL be able to serve the dish in a container at any time during the kitchen phase, as long as it holds at least one solid ingredient and is not ruined. Serving a burger MUST first lock its live layer and check stability; if it collapses, nothing is served. A served dish MUST be scored immediately, shown leaving through the serving window, and removed from the container. There is no limit on the number of dishes served per day.

#### Scenario: Serve a burger
- **WHEN** the player serves a standing burger
- **THEN** it is scored, shown in the serving window, and the board is empty

#### Scenario: Serving locks and checks the live layer
- **WHEN** the player serves a burger whose live layer would make it collapse
- **THEN** the burger collapses and nothing is served
