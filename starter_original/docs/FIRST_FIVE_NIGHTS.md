# Moonmart — First Five Nights: Playable Narrative Outline

## Night 1: A Little Shop at the Edge of Town
**Goal:** Learn movement, shelves, checkout and closing. Agnes introduces the register, Miso sleeps on the counter. Customers are ordinary. End beat: the shop sign briefly glows when the clock strikes midnight.
**Tasks:** Walk to the fridge; restock biscuits; serve a customer; pet Miso; close shop.
**Dialogue:** Agnes: "It gets quiet after midnight. Not empty, mind you. Just... quiet in a different way."

## Night 2: Strawberry Milk
**Goal:** Meet Pip, a gentle glowing ghost. Pip asks for strawberry milk. The player can serve them from stock or fetch it from the fridge. Pip comments that the shop feels familiar.
**Clues:** Pip does not appear in the window reflection; Tuesday routine.
**Dialogue:** Pip: "You remembered! Strawberry milk, just like always."
**Safety:** If milk is out of stock, a small restock delivery appears; story is never blocked.

## Night 3: A Receipt from 1974
**Goal:** Find a faded receipt behind the counter. The purchase is strawberry milk, customer PIP, dated decades ago. Inspect the ledger and ask Agnes.
**Clues:** Old receipt, ledger page missing, faded shop photograph.
**Dialogue:** Agnes: "That's before your time, dear. Before mine, too... or so I'd like to think."

## Night 4: The Name That Stayed
**Goal:** Connect clues in the journal: Pip's Tuesday routine, old receipt, missing ledger. The player can investigate through Agnes, Miso or the backroom.
**Discovery:** The receipt wasn't printed by the current register. The shop remembers transactions from other times.
**Dialogue:** Miso (dream text): "Not everything lost wants to be found. But everyone deserves to be remembered."

## Night 5: Behind the Curtain
**Goal:** Help Pip recover a small memory: a warm kitchen, a red straw, someone waiting at a table. This does not reveal their whole past. Miso leads the player toward a hidden door in the backroom.
**Ending beat:** A new moon-shaped keyhole appears. Cut to the title MOONMART.
**Next chapter hook:** A visitor from Whisperwood arrives with a jar full of silence.

## Implementation notes
Use quest flags: `pip_met`, `pip_served`, `receipt_found`, `agnes_asked`, `ledger_found`, `pip_memory_1`, `hidden_door_seen`. Gate night-specific scenes with `minimum_shift` and prerequisites, but queue missed beats on later shifts. This pack's playable prototype implements a subset of these flags; the five-night sequence is the production target, not yet fully scripted.
