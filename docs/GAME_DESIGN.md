# Moonmart — Game Design Document v1.2

## Locked direction
Moonmart is a cozy, single-player supernatural mystery and shopkeeping simulation. Players physically navigate a 2D side-on storybook world with limited walkable depth; it is **not a visual novel**. The shop expands into neighboring rooms. Tone is warm, gently mysterious and bittersweet. Original user-provided illustration is canonical art direction: lavender/navy nighttime, peach/cream lighting, rounded characters, soft painted texture, sleeping orange cat, friendly glowing ghost, abundant plants. Rounded handwritten typography is the UI target, not a specific identified font.

## Player fantasy
Manage a welcoming night shop where ordinary and supernatural travelers find safety. Notice customers' routines and changes; serve their favorite orders; learn their stories; investigate the Long Midnight and the Between; make Moonmart your own.

## Design pillars
1. Comfort through tactile routine.
2. Magic in mundane details.
3. Remembering people, not grinding relationship points.
4. Curiosity without punishment.
5. A home that evolves with the player.

## Core loop
Prepare (11:30–00:00) → Open (00:00–05:30) → Serve, stock, craft and converse → Observe clues and events → Close and review earnings → Explore, upgrade, decorate → Next shift. Target 20–40 real minutes; 25 minutes typical. Dialogue and journals pause clock. Save any time.

## Shopkeeping
Products have stable ID, category, base price, purchase cost, shelf space, perishability, demand, unlock conditions, magical tags. Inventory uses atomic stock movements and no negative stock. Customers browse, queue, purchase and leave; checkout scans basket and confirms payment. Craft coffee, tea, snacks and magical beverages through short accessible interactions. Restocking, sweeping, watering and cleaning are optional gentle activities. No bankruptcy or irreversible story failure.

## Shop progression
Tier 1 Little Corner Shop: retail floor, basic register and coffee.
Tier 2 Familiar Faces: seating and tea.
Tier 3 Neighborhood Favourite: bakery and expanded stock.
Tier 4 Moonlit Haven: magical stock and decorations.
Tier 5 Between Worlds: supernatural visitors and services.
Tier 6 Midnight Sanctuary: advanced facilities and full customization.
Expand retail floor → backroom → tea corner → reading nook → enchanted greenhouse → hidden midnight room. Rooms are individual scenes with door transitions and persistent furniture layouts.

## Economy
Coins from sales, orders and commissions; Moon Tokens from supernatural kindness, investigations and magical events. No real-money purchases. Essential story content does not require repetitive grinding. Prices start fixed and can later use category/event modifiers. Unsold perishables can be discounted, donated or reused.

## Relationships
Five stages: Stranger, Familiar, Friend, Confidant, Kindred. Progress through meaningful conversations, preferences, requests and story choices. Persistent character memories record promises, honesty and care. No daily gift treadmill. Character schedules vary by weekday, time, weather, products and narrative state.

## Mysteries
Midnight Journal records clues, rumours, people and places. Player connects clues to hypotheses and conclusions. Wrong deductions unlock hints, not dead ends. Moonlight Perception later reveals hidden writing, memory echoes and disguised visitors. Investigations can resolve through observation, relationships or exploration.

## World
Bellwether is ordinary by day; at night the boundary with the Between thins. Moonmart sits over a threshold. Old Bellwether, Whisperwood, Moonwater Harbour, Old Lighthouse, Midnight Platform are compact, dense, interconnected scenes. The Between contains memories, forgotten places and lost travelers. Names and promises matter; time can behave strangely.

## Character arcs
Miso: orange guardian cat, dreamwalking and clues.
Pip: cheerful ghost buying strawberry milk, recovering memories.
Agnes: baker and former boundary keeper.
Fern: forest spirit restoring a silent grove.
Lucien: vampire librarian navigating friendships and time.
Wren: witch searching for a lost train passenger.
Conductor: keeper of forgotten passenger memories.
Elias: lighthouse keeper who knows what the light guides.

## Narrative
Six chapters: The First Night; Things That Don't Belong; The Forgotten Town; The Midnight Train; The Last Light; Until Morning Comes. Main mystery: Moonmart's protective agreement is failing and the town is forgetting people. Three non-punitive endings: The Keeper, The Open Door, The Gentle Goodbye. Postgame epilogue sandbox reflects choices.

## World simulation
Time-driven event director selects ordinary, social, weather, magical, mystery, rare and seasonal events with weights, cooldowns, narrative priorities and repeat protection. Four seasons, weather affecting ambience, demand and schedules. No missable essential events.

## Miso
Feed, pet, brush and play. Idle wandering and naps. Spirit Sense, Hidden Paw, Dreamwalking, Memory Echo and Guardian's Purr unlock narratively. No pet death, runaway or harsh punishment.

## Accessibility
Remappable keyboard/controller controls, adjustable time speed, automatic checkout and restocking assists, reduced motion/flashing, scalable UI, text options, hint levels, independent volume sliders, save-and-quit midshift.

## Target scope (aspirational)
6 chapters; 6 districts; 25–35 recurring characters; 40–60 background customer variants; 150–200 products; 50–70 recipes; 250–350 furniture/decor; 12–15 major investigations; 20–25 character stories; 80–120 dynamic events; 8 festivals; 3 endings.

## Production gates
Prototype: movement, 1 room, 1 customer, 3 products, register, clock, save.
Vertical slice: 5 nights, Pip mystery, Miso, Agnes, 20 products, 5 drinks, 1 investigation.
Expansion: rooms, relationships, seasons, events and districts.
Full release: narrative, accessibility, polish and QA.
