## Context

Rerolls currently skip sold slots (see the archived prototype design: "Replaces every unsold offer; sold slots stay sold"). See proposal.md for why this changes.

## Goals / Non-Goals

**Goals:** a reroll gives a whole fresh shop. **Non-Goals:** changing reroll prices, staples, or tools.

## Decisions

- `Shop.reroll`, `Shop.reroll_smoothie` and `Shop.reroll_gadget_offers` replace every slot regardless of `sold`. Market slot 0 keeps rolling from the meat pool with quantity 1.
- Gadget offers on reroll are drawn like a fresh roll (`roll_gadget_offers`), so they are distinct and never owned.
- **Alternative considered:** only restocking sold slots and keeping unsold ones. Rejected: players pay for a reroll to see new options; keeping some slots makes rerolls feel weaker and is harder to read.

## Risks / Trade-offs

- [Rerolls become stronger] → the rising reroll cost still applies; simulator bots don't reroll, so balance numbers are unaffected for them.
