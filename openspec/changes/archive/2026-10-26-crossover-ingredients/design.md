## Context

Ingredients carry `burger_ok` / `smoothie_ok`, which decide both where they can be dropped and which shop sells them. Combos are data resources and the combo board lists the discovered ones per station. See proposal.md.

## Goals / Non-Goals

**Goals:**
- Crossovers work without disturbing the shops.
- Secrets feel secret.

**Non-Goals:**
- No crossover-specific physics, beyond giving fruit a burger layer size.
- No sauces in the jar.

## Decisions

### `crossover` flag instead of reusing the station flags
- `burger_ok` / `smoothie_ok` keep meaning "home station", which drives the shop pools.
- A new `crossover: bool` lets an ingredient also go into the other station.
- `fits_burger()` is `burger_ok or crossover`, and `fits_jar()` is `smoothie_ok or crossover`. Sauces are never crossovers.
- Picking up an ingredient whose home is the burger still locks the live layer, as before. A fruit picked up from the pantry doesn't lock it, because the player may be heading for the jar. Dropping the fruit on the board locks the previous layer anyway, like any drop.

### Smoothie roles of burger food
- Burger ingredients have no smoothie role, so they don't change the liquid ratio.
- Their colors still blend, so a patty can make a smoothie muddy. That's the risk side of experimenting.

### Secret combos
- `Combo.secret`. The secret combos are ordinary SEQUENCE or SET combos.
- The board's counter cell counts only non-secret undiscovered combos. While secrets remain, it adds "+ secret ones", or shows "secret ones left…" alone once every regular combo is found.
- Discovered secrets have a purple name and a "Secret combo" tooltip. A ★ was planned, but the web font has no glyph for it.

### Board fit
- 11 regular + 3 secret burger combos, plus the counter cell, make up to 15 cells. The grid goes from 4 to 5 columns (3 rows).
- Rules are shortened to about 20 characters to fit 132 px chips.
- The existing fit test now runs with everything discovered.

### Values
- Starting values: The Elvis +1.5, Cheesecake +1.0, Green giant +1.0, Protein shake +1.5, Gazpacho +1.5.
- The simulator's bots don't use crossovers, so the balance is unchanged for them. These combos are a bonus for players who experiment.

## Risks / Trade-offs

- [Thin fruit layers make burgers less stable] → intended: a risk for the bonus.
- [Players never think to cross over] → the rules card says so, and the "+ secret ones" hint invites it.
