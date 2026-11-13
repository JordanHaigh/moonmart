You took a quiet overnight job at a little convenience store. The pay is decent, the cat is friendly, and most of the customers are perfectly normal. Most of them.

## 1. The vision
Moonmart is a single-player, story-driven shopkeeping simulator set in a quiet town where the ordinary world overlaps with something magical after midnight.

The player manages a tiny convenience store, builds relationships with regular customers, discovers supernatural secrets, and gradually transforms a forgotten corner shop into a sanctuary for people and creatures who don't quite belong anywhere else.

The game should feel like coming home after a long day: comforting, quiet, a little lonely, but ultimately hopeful.
### Game identity
Attribute	Direction
Genre	Cozy simulation + supernatural mystery
Perspective	2D side-on / 2.5D illustrated environments
Art	Hand-painted, soft shapes, warm lighting
Platform	PC first, controller support
Engine	Godot 4
Players	Single-player
Session length	20–40 minutes per shift
Story length	15–25 hours
Completionist	35–50 hours
Structure	Narrative chapters + ongoing sandbox
Failure	No game over, no combat, no hard deadlines

### Five design pillars
1. Comfort in repetition - Serving customers, stocking shelves, making drinks, and cleaning are genuinely enjoyable activities rather than chores.
2. The extraordinary in the ordinary - Magic appears in subtle ways: a customer with no reflection, a receipt dated tomorrow, a plant that whispers when watered.
3. Relationships over rewards - Customers have memories, routines, preferences, and lives outside the store. Helping them matters more than maximizing profit.
4. Curiosity without punishment - Mysteries reward observation and experimentation. Players can discover secrets at their own pace without permanently missing essential content.
5. A place that becomes yours - The shop physically evolves with the player's choices, reflecting their relationships, discoveries, and decorating preferences.

## 2. The central gameplay loop
The game is organized into individual overnight shifts. Each shift combines predictable shopkeeping activities with dynamic customers, character stories, and occasional supernatural events.

Prepare (Stock, decorate, review notes) -> Open the Shop (Serve, Craft, Converse) -> Discover (Clues, Visitors, Strange Events) -> Close and reflect (Earnings, Journal, Relationships) -> Progress (Upgrade, Unlock, New Stories)
[Then Back to prepare - Every completed shift feeds back into the next, while stories and mysteries develop across multiple nights.]


### A typical shift schedule
In-game times; configurable simulation speed
Time	Activity
11:30 PM	Arrive, prepare, review deliveries
12:00 AM	Open for customers
12:00–2:00 AM	Early customers and routine tasks
2:00–3:30 AM	Quiet hours, conversations, mysteries
3:30–5:00 AM	Unusual visitors and late deliveries
5:00–5:30 AM	Closing tasks and final customers
5:30 AM	Close, calculate earnings, save
Between shifts	Upgrades, ordering, exploration, journal

Time should slow or pause during important conversations, and players can end a shift early once mandatory responsibilities are complete.

The intended pacing is approximately 25 minutes of active play per shift, adjustable through accessibility settings.

## 3. The shopkeeping systems
Shopkeeping needs enough depth to remain interesting for dozens of shifts without turning into an exhausting management game.
### 3.1 Inventory and stocking
The shop begins with a small collection of ordinary products.


Everyday products - Milk, bread, biscuits, noodles, soft drinks, coffee, sweets, toiletries, and basic groceries.
Midnight products - Moonflower tea, bottled starlight, dream biscuits, spirit candles, shadow ink, and enchanted snacks.
Special-order products - Unique objects requested by specific characters, often unlocking personal stories or investigations.

Products have configurable attributes: purchase cost, retail price, shelf space, category, demand, availability, perishability, and supernatural properties.

The player can choose their inventory mix. Stocking strawberry milk might attract a particular ghost, while keeping moonflower tea available encourages certain forest spirits to visit.

Important: Products should affect the world, not just generate money.

### 3.2 Checkout
Checkout is a lightweight interactive minigame.
- Scan or manually enter products.
- Pack orders according to customer preferences.
- Accept cash and card payments in Coins, or supernatural transactions settled in Moon Tokens. Unusual objects and symbolic exchanges are handled as narrative or inventory interactions rather than additional currencies.
- Notice unusual items, strange prices, and suspicious receipts.
- Offer optional recommendations or conversation.
A normal transaction takes 10–20 seconds. Repeat interactions become quicker as the player upgrades equipment.

The production checkout flow can offer one in-stock favorite that is not already in the basket; accepting adds it to the transaction and requires it to be scanned, while skipping leaves the original basket and rewards intact. A completed recommended sale earns one optional Hospitality point. Checkout then offers paper, careful, or reusable packing based on the visitor's preference. Matching the preference gives one optional Hospitality point; a mismatch never blocks the sale, lowers its value, or affects story access. Coins transactions let the player select cash or card, while supernatural customers settle automatically in Moon Tokens. The ledger records the tender; older checkout calls default to cash.

Customers never become aggressively impatient. Slow service affects optional bonuses, not relationships or story progression.
### 3.3 Food and drink preparation
The store gradually gains a small preparation station.
Station	Gameplay
Coffee machine	Grind, brew, add milk and toppings
Tea counter	Select leaves, temperature, steeping time
Microwave	Heat snacks and ready meals
Sandwich station	Assemble custom orders
Magical kettle	Prepare supernatural drinks
Bakery warmer	Serve pastries and midnight treats

Recipes can be discovered through experimentation, customer requests, handwritten notes, and story progression.

A favourite drink becomes a personal connection. Remembering a customer's usual order can trigger unique dialogue.

### 3.4 Cleaning and maintenance
Cleaning is intentionally low-pressure and visually satisfying: wiping the counter, sweeping leaves, clearing cups, watering plants, refilling dispensers, and taking out rubbish.

A well-maintained shop feels brighter and attracts more visitors. Neglect creates mild inconvenience, not catastrophic penalties.

Housekeeping offers six repeat-safe actions, including refilling the existing canister dispenser. Each can be completed once per shift, adds its configured cleanliness value plus the Stewardship rank bonus, and returns a task-specific message.

### 3.5 Decoration and layout
The shop is a customizable space, with a grid-assisted placement system for furniture and free placement for smaller decorations.

Players can change lighting, wallpaper, shelving, signage, plants, rugs, seating, counter accessories, window displays, and music.

Some decorations have functional effects. A placed moon lantern casts a dedicated, settings-controlled point light and slightly increases optional supernatural visitor arrivals on clear nights; a placed reading chair encourages optional customers to linger; and Moon Jasmine reveals a small, one-time hidden message. These effects are data-driven and saved with the layout or story state. Existing lighting and reading-nook upgrades provide the same gameplay benefits without stacking with the matching decoration effect.

Moonmart uses horizontal movement with limited vertical depth lanes.

Large furniture uses grid-assisted placement. Smaller decorations may use free placement.

Every interactive furniture object defines:
- Collision footprint
- Ground anchor
- Interaction positions
- Navigation clearance
- Optional display and storage slots

The decoration system must reject placements that block:
- Required shop stations
- Room entrances and exits
- Customer checkout access
- Essential NPC interaction positions
- Mandatory story interactions

Customer navigation must be recalculated when furniture layouts change.

Decorative freedom must not compromise gameplay accessibility or create unreachable objectives.


## 4. The world: Bellwether
The game takes place in Bellwether, a secluded town surrounded by ancient forests, mist-covered hills, and a quiet coastline.

By day, Bellwether is ordinary. People go to work, children attend school, and tourists stop for photographs.

At midnight, something changes.

The boundary between the human world and a place called the Between becomes thin enough for certain beings to cross.

Most residents don't notice. Some have known for generations. Others have spent their lives trying to forget.
### 4.1 The Between
The Between isn't heaven, hell, or another planet. It's a collection of forgotten places, memories, dreams, and things that have slipped out of the ordinary world.

Its inhabitants aren't necessarily dead. Some are spirits, others are magical beings, and some are people who have simply become lost.

The Between follows unusual rules:
- Names and promises have power.
- Memories can become physical objects.
- Time doesn't always move forward.
- Some doors connect places that should be impossibly far apart.
- A person who is forgotten by everyone may gradually disappear into the Between.
The supernatural world should remain mysterious. Players learn its rules through experiences rather than lengthy exposition.

### 4.2 The six districts
#### Moonmart — The Starting Location
The player's store. A modest shop on the edge of town, with a warm interior, a sleepy orange cat, and a peculiar history.

#### Old Bellwether
The historic town centre. Home to a bakery, bookshop, post office, antique shop, and several important characters.

#### Whisperwood
An ancient forest where paths shift, flowers glow, and forest spirits gather around forgotten shrines.

#### Moonwater Harbour
A sleepy fishing harbour where impossible objects wash ashore and certain boats only arrive after midnight.

#### The Old Lighthouse
Abandoned decades ago. Sometimes its light appears in the middle of the night, despite the machinery having been removed.

#### The Midnight Platform
A railway station that doesn't exist on any map. Its trains carry passengers between Bellwether and the Between.


### Exploration
Exploration happens primarily between shifts, although some story events temporarily take the player outside during working hours.

Players navigate interconnected, hand-painted 2D scenes. Each district contains interactive objects, NPCs, hidden collectibles, and environmental puzzles.

Exploration is deliberately compact and dense rather than open-world. A small number of richly detailed locations is preferable to a huge empty map.

Travel between discovered districts is instant from the town map, with optional walking transitions.

## 5. Characters and relationships
The game's characters are its emotional centre.

Each recurring character should have a recognizable appearance, schedule, preferred products, personal story, and relationship with other residents.

### Core cast

#### Miso — The Shop Cat
Companion · Present from the beginning
Sleepy, affectionate, and suspiciously intelligent. Miso can sense supernatural visitors, locate hidden objects, and occasionally communicate through dreams.
Secret: Miso has been guarding Moonmart for far longer than any normal cat could live.

#### Pip — The Little Ghost
First supernatural customer · Chapter 1
A cheerful ghost who visits every Tuesday for strawberry milk. Pip can't remember their real name or why they keep returning.
Story: Help Pip recover fragments of their past without forcing them to abandon the life they've built.

#### Agnes Thorne — The Baker
Human resident · Chapter 1
Runs the bakery across the street. She delivers leftover pastries and seems to know far more about the town than she admits.
Secret: Agnes was once responsible for maintaining the boundary between worlds.

#### Fern — The Forest Spirit
Supernatural customer · Chapter 2
A shy guardian of Whisperwood who purchases tea, seeds, and gardening supplies.
Story: Restore an ancient grove threatened by a spreading silence that has begun swallowing birdsong.

#### Lucien Vale — The Vampire
Supernatural regular · Chapter 2
A polite, exhausted vampire who works as a night-shift librarian. He loves decaf coffee and terrible detective novels.
Story: Help Lucien reconnect with a human friend who has grown old while he hasn't.

#### Wren Hollow — The Witch
Merchant and researcher · Chapter 2
A travelling witch who supplies magical goods and helps the player understand unusual artifacts.
Secret: Wren is searching for someone who boarded the Midnight Train and never returned.

#### The Conductor — Keeper of the Platform
Mysterious figure · Chapter 3
A quiet figure who appears whenever someone is about to leave Bellwether forever.
Secret: The Conductor remembers every passenger, including people who have vanished from everyone else's memories.

#### Elias Marsh — The Lighthouse Keeper
Human resident · Chapter 3
The last keeper of the abandoned lighthouse. He insists that the light is still working, even though nobody believes him.
Story: Discover what the lighthouse was actually built to guide.

### 5.1 Relationship mechanics
Rather than a simple friendship bar, relationships progress through five stages.
1. Stranger — Basic interactions and introductions
2. Familiar — Learn preferences and routines
3. Friend — Personal conversations and optional requests
4. Confidant — Character-specific stories and revelations
5. Kindred — Lasting bond, unique endings and ongoing interactions

Relationships develop through conversations, remembering preferences, completing requests, participating in events, and making meaningful story decisions.

There should be no requirement to give repetitive daily gifts or grind relationship points. Progress comes from varied, meaningful interactions.

Each character has a hidden memory system recording things such as the player's kindness, honesty, promises, and important decisions.

Promises can remain open across shifts and resolve at an authored story outcome. The Midnight Journal lists open commitments and records their resolution; missing a visit or taking extra shifts never fails an essential promise or locks its story.
### 5.2 Customer behaviour
Customers are not just scripted arrivals.

They have schedules, weather preferences, product interests, and social relationships.

For example, Lucien usually arrives after 2 AM, but might visit earlier if it's raining. If Agnes is already in the store, the two may have a unique conversation. If the player stocks a particular book, Lucien may comment on it.

This creates the impression of a living community without requiring complex AI.

When Agnes and Lucien are both browsing in Moonmart, speaking to either can surface their optional shared banter. Its short exchange cycles on a three-shift cooldown and persists its turn without interrupting essential story dialogue.


### Customer scheduling and guaranteed encounters

Ordinary customer visits use weighted schedules influenced by:
- Day of the week
- Time of night
- Weather
- Stocked products
- Relationships
- Story progression

Narratively essential encounters use guaranteed quest scheduling.

If an essential customer visit is missed because of early closing, exploration, seasonal changes, or other player choices, the event remains queued and becomes available on a later eligible shift.

Pip prefers visiting on Tuesdays, but essential encounters involving Pip are not restricted to Tuesdays.

Optional encounters may follow stricter schedules, provided they repeat or have alternative triggers.

No essential narrative progression may become permanently inaccessible because a scheduled customer did not appear.


## 6. The supernatural mystery
The main narrative revolves around a question:

Why does Moonmart exist at the boundary between two worlds, and what happens when that boundary begins to disappear?
### The central premise
Decades ago, Bellwether experienced an event known as the Long Midnight.

For one entire night, the sun failed to rise. People vanished, streets rearranged themselves, and strangers appeared from places that shouldn't exist.

When morning finally came, most residents forgot what happened.

Moonmart was built over a doorway between worlds. Its original owner established an agreement: as long as the shop remained open each night, lost travellers would have a safe place to rest before continuing their journeys.

Now the original agreement is failing.

People are beginning to forget one another. Places disappear from maps. The Midnight Train arrives at the wrong times. And Miso has started behaving strangely.

### 6.1 Mystery mechanics
The Midnight Journal - Automatically records clues, character information, rumours, locations, and unresolved questions. Players can pin important evidence.
Clue connections - Players connect observations to form deductions. For example, a receipt dated 1974 and an old photograph may reveal that a customer hasn't aged.
Moonlight perception - A late-game ability allows the player to notice hidden writing, lingering memories, disguised visitors, and supernatural traces.
Environmental puzzles - Decode old shop ledgers, restore broken mechanisms, follow unusual footprints, and arrange objects to reveal hidden passages.


### 6.2 How deductions work
An investigation contains clues, hypotheses, and a conclusion.

For example, the player discovers that Pip appears every Tuesday, always buys strawberry milk, and leaves before the church bell rings.

The journal presents possible explanations. Connecting the correct clues unlocks a new conversation or location.

Wrong deductions generate alternative dialogue and additional hints, rather than failing the investigation.

Major mysteries use multiple valid investigative paths, allowing players to solve them through observation, relationships, or exploration.

## 7. Narrative structure

### Main story chapters

| Chapter | Target shifts | Title |
|---|---|---|
| 1 | 1–5 | The First Night |
| 2 | 6–12 | Things That Don't Belong |
| 3 | 13–20 | The Forgotten Town |
| 4 | 21–28 | The Midnight Train |
| 5 | 29–36 | The Last Light |
| 6 | 37–42 | Until Morning Comes |

Chapter 1 introduces Moonmart, Miso, Agnes, Pip, and the hidden supernatural service window.

Chapter 2 introduces additional supernatural customers, magical merchandise, Whisperwood, and early investigations.

Chapter 3 explores the Long Midnight, changing photographs, forgotten residents, and mysterious encounters with the Conductor.

Chapter 4 unlocks the Midnight Platform and reveals the history of its passengers and Miso's role in protecting Moonmart.

Chapter 5 focuses on restoring the lighthouse, discovering the original agreement, and confronting the collapsing boundary.

Chapter 6 resolves the central mystery and presents the three major endings.

Shift ranges are pacing targets, never mandatory deadlines.


### Narrative progression rules

Moonmart's main story contains six chapters. Shift ranges are pacing targets, not deadlines.

Essential story progression is controlled by explicit narrative flags, completed investigations, and character milestones. Shop reputation, currency, proficiency, and optional relationships must never permanently block the main story.

Story events that depend on a particular customer, day, or time must be rescheduled when missed. The player can progress at their own pace.

### The Midnight Platform

The Conductor can first appear during Chapter 3 through mysterious encounters, dialogue, and clues.

The Midnight Platform itself becomes fully explorable in Chapter 4. Earlier encounters do not require access to the platform.

### Post-game sandbox

All three endings support continued play:

- The Keeper: Moonmart continues operating as a sanctuary between worlds.
- The Open Door: Human and supernatural communities coexist more openly, introducing mixed-community events.
- The Gentle Goodbye: The original doorway closes. Moonmart remains an ordinary shop. Choosing this ending records a save-backed memory only for places the player actually inspected: the Hidden Midnight Room door or the Midnight Platform and its passenger manifest. The Journal can read recorded memories after the doorway closes; a place with no qualifying experience is not presented as remembered.

Ending-specific content must respect the chosen world state. Essential unfinished activities receive suitable alternatives rather than becoming permanently inaccessible.


## 8. Player Progression

### Progression systems

Progression is divided into five complementary systems.

### 8.1 Narrative progression — authoritative

Narrative progression controls:
- Main chapter advancement
- Essential locations and story interactions
- Required supernatural encounters
- Critical investigations
- Main story abilities
- Access to the three endings

Narrative progression uses explicit flags, quest states, and completed milestones.

Shift number is a pacing reference, never the sole condition for unlocking essential content.

### 8.2 Shop reputation

Shop reputation unlocks optional commercial improvements, equipment, expanded inventory, furniture, and customer services.

| Tier | Name | Major unlock |
|---|---|---|
| 1 | Little Corner Shop | Basic checkout, shelves, coffee |
| 2 | Familiar Faces | Tea station, seating, special orders |
| 3 | Neighbourhood Favourite | Expanded inventory, bakery station |
| 4 | Moonlit Haven | Advanced magical stock and enchanted decorations |
| 5 | Between Worlds | Additional supernatural visitor types and optional services |
| 6 | Midnight Sanctuary | Full customization and advanced facilities |

Supernatural visitors are not locked behind Tier 5.

Pip appears through Chapter 1 narrative progression. Other essential supernatural visitors appear as their respective story chapters begin.

Chapter 2 introduces basic magical merchandise independently of shop reputation.

Reputation unlocks additional merchandise and optional visitor opportunities.

### 8.3 Community bonds

Relationships unlock:
- Personal character stories
- Optional dialogue
- Unique interactions
- Collaborative projects
- Character-specific decorations
- Ending variations

Required story information must always have an alternative discovery path if a particular relationship is optional.

### 8.4 Mystery knowledge

Mystery progression unlocks:
- Optional investigations
- Clue interpretation
- Environmental discoveries
- Additional lore
- Alternative solutions
- Advanced observation techniques

Essential investigation mechanics are introduced through narrative milestones.

### 8.5 Midnight harmony

Midnight Harmony represents Moonmart's connection to the Between.

It unlocks:
- Additional supernatural visitors
- Enchanted furniture
- Optional magical merchandise
- Improvements to supernatural facilities
- Rare magical events

Midnight Harmony cannot block essential supernatural customers or main story progression.

### 8.6 Practical proficiencies

The player develops five proficiencies:
- Hospitality
- Crafting
- Observation
- Stewardship
- Attunement

Each has five mastery milestones earned through varied accomplishments.

All proficiencies can eventually be mastered. There are no permanent build restrictions.

Proficiencies provide conveniences, optional interactions, and alternative solutions rather than mandatory story gates.

### 8.7 Unlock precedence

When multiple progression systems reference the same content, apply the following rules:

1. Essential story content is unlocked through narrative progression.
2. Reputation controls optional commercial improvements.
3. Relationships control personal content and optional variations.
4. Mystery knowledge controls additional discoveries.
5. Midnight Harmony controls optional supernatural expansion.
6. Proficiencies provide convenience and alternative interactions.

No optional progression track may permanently prevent completion of the main narrative.

## 9. Economy and resource systems
The economy should support creativity and meaningful decisions without making players anxious about paying bills.


### Currency and payment rules

Moonmart has exactly two persistent spendable currencies:

- Coins: Used for ordinary products, equipment, decorations, stock purchases, and shop expansion.
- Moon Tokens: Used for enchanted merchandise, supernatural improvements, and special magical services.

Cash and card payments are transaction methods that both produce Coins.

Supernatural customers may offer unusual objects or symbolic exchanges. These are handled as quest items, special-order rewards, or narrative interactions rather than additional persistent currencies.

Moon Tokens cannot be purchased with real money.

Essential story progression must not require excessive currency grinding. Required story items must have an affordable or guaranteed acquisition path.

Inventory transactions must be atomic. Products and payment are exchanged together, preventing partial transactions or negative inventory.


### Economic principles
- No rent deadlines, debt spirals, or bankruptcy.
- Stock purchases should generally be profitable.
- Optional special orders can offer higher margins.
- Expensive decorations provide long-term goals.
- Shop upgrades have clear, predictable benefits.
- Essential story items never require excessive money grinding.
- Unsold perishables can be discounted, donated, or repurposed.
The player can optimize their shop, but optimization is optional.

### Example upgrades

```
Coffee Station II

450 coins

Faster brewing, additional recipes, and the ability to prepare two drinks simultaneously.
```

```
Moonlit Window

12 Moon Tokens

Attracts additional supernatural visitors during clear nights.
```

```
Reading Nook

800 coins

Encourages visitors to stay longer, triggering more conversations and character interactions.
```

Illustrative balance values, subject to playtesting.

## 10. Dynamic night events
No two shifts should feel exactly the same.

A lightweight event director selects optional events based on weather, story progress, relationships, stocked products, and recent encounters.
### Event categories
Event	Example
Ordinary	A delivery arrives late
Social	Two regulars unexpectedly meet
Weather	A thunderstorm knocks out the lights
Magical	All the clocks stop at 2:13 AM
Mystery	A receipt prints an unknown name
Rare	The Midnight Train passes the shop
Seasonal	A spirit lantern festival begins

Events are weighted to avoid repetition. Significant story encounters take priority over random events.
### The midnight anomaly system
Some shifts experience an anomaly: a small supernatural change that the player can investigate.

Examples include a reflection moving independently, products rearranging themselves, a door leading to an unfamiliar room, or a customer who has appeared in a photograph from decades ago.

Anomalies are not enemies or jump scares. They're invitations to be curious.

Resolving them may reward clues, Moon Tokens, unusual decorations, or character dialogue.

Ignoring an anomaly is also valid. Important discoveries can reappear later. The whispering receipt is a localized, optional investigation at the register: inspecting it yields one Moon Token once, records its resolution in the save, and does not set an essential story flag. If ignored, the receipt can return on a later shift.

## 11. The cat companion system
Miso should be more than a decorative pet.
### Everyday interactions
Players can feed, pet, brush, and play with Miso. The cat has preferred sleeping spots, favourite toys, and a daily mood.

Miso wanders around the shop, watches customers, sits on receipts, sleeps on shelves, and occasionally knocks objects over.

These behaviours should be charming but not interrupt essential gameplay.

The optional ambient loop now selects data-driven resting and shop behaviors from Miso's preferred sleep spot, the register receipt perch, and a customer-watching anchor. Miso uses the existing walk and idle atlas poses and collision-safe shop routes. When its isolated, approved flower-bud vase prop is present and reachable, Miso may briefly tip it and restore it exactly. The loop runs only during an open Moonmart shift, suspends while the shop is closed, paused, covered by a panel or dialogue, or using reduced animation, and has per-behavior cooldowns. It is visual-only: it does not change story, inventory, placed decor, or shop economy, and its transient timers are not saved. Deterministic headless coverage checks schedule eligibility, arrival-before-tip, exact restoration after completion and interruption, timer suspension, and absence of story/economy/layout effects.
### Supernatural abilities
As the story progresses, Miso gains new abilities:
- Spirit Sense: Once unlocked, Miso quietly senses a disguised supernatural visitor when they arrive. A static, non-blocking notice is shown once per visitor per shift; reduced-flashing settings do not add or remove anything because the reaction uses no flash or light effect.
- Hidden Paw: Leads the player toward overlooked clues.
- Dreamwalking: Allows the player to explore short dream sequences.
- Memory Echo: Reveals fragments of past events.
- Guardian's Purr: After Miso's Guardian Truth is known, spends one ability use to settle the oldest optional anomaly disturbance delivered to the shop. The unsettled queue saves and resumes, no-target attempts spend nothing, and stabilization grants harmony without setting an essential story flag or changing the painted environment artwork.
Dreamwalking is implemented as an optional, localized four-beat vignette with two authored branches, choices at each beat, save/resume, and a wake action. Waking records a small optional memory; the vignette never gates essential events. Memory Echo reveals three authored passenger memories over separate shifts and records them as optional journal entries. These memory fragments remain separate from the existing `miso_memory_echo` hidden clue and never gate essential story.
Hidden Paw selects an eligible clue target that has an inspect marker in the current location, points to that marker, and leaves the clue and its story flags untouched until the player uses the normal inspect interaction. A location with no reachable clue does not consume the ability for that shift.
Miso's happiness influences optional animations and interactions, but the cat cannot run away, become seriously ill, or die.

## 12. Seasonal and environmental systems
Bellwether has four seasons, each with distinct visuals, merchandise, visitor patterns, and events.
### Spring — New Beginnings
Flowers, gentle rain, returning spirits, gardening events.

### Summer — Long Evenings
Fireflies, festivals, cold drinks, visiting travellers.

### Autumn — The Veil Thins
Falling leaves, harvest markets, increased magical activity.

### Winter — Quiet Reflections
Snowfall, warm drinks, lantern celebrations, intimate stories.

Weather affects ambient audio, customer schedules, product demand, and the appearance of supernatural events.

Optional ordinary customers can express a seasonal or weather-driven demand by swapping one item in their usual basket for a related displayed product. This uses existing retail prices, requires the replacement to be on a display, preserves basket quantities, and never changes essential story orders.

A seasonal calendar should not permanently lock players out of essential content. Missed events repeat or have alternative triggers.


### Seasonal calendar rules

The baseline calendar contains four seasons, each lasting 14 completed shifts.

A full seasonal year therefore contains 56 shifts.

Each season contains two recurring festivals, giving eight festivals per year.

Seasons affect weather, customer preferences, merchandise, ambience, and optional events.

The six-chapter main story is independent of the seasonal calendar. Completing a chapter does not require waiting for a specific season.

Essential seasonal clues and encounters must have alternative non-seasonal triggers.

Missed festivals repeat in subsequent years. Festival-specific optional rewards remain obtainable through future appearances or equivalent activities.

Season lengths and festival schedules are external configuration values.


## 13. Art direction and presentation
The uploaded artwork should be treated as the visual foundation.
### Visual language

Night ( #25243E )
Dusk ( #49446D )
Lavender ( #806587 )
Rose ( #C18B86 )
Peach ( #F1B47D )
Cream ( #FFF0D8 )

Suggested palette sampled conceptually from the original artwork.
The environments should use soft painterly textures, rounded silhouettes, subtle gradients, and layered lighting.

Characters have simple expressive faces, exaggerated but appealing proportions, and recognizable silhouettes.

Animations should be restrained but full of personality: blinking, ear twitching, steam curling, leaves moving, a customer shifting their weight, or a ghost gently bobbing.
### Camera and movement
I'd use a 2D side-on perspective with layered depth, rather than a traditional top-down farming-game camera.

Inside Moonmart, the camera follows the player horizontally through a richly detailed shop. Exterior locations are intended to use connected side-scrolling scenes with foreground and background parallax. The current runtime proves only a small, independently camera-driven foreground signpost on Midnight Platform; distant scenery parallax remains incomplete for all five opaque outdoor district plates.

Interactions happen through contextual hotspots and short, tactile minigames.

This preserves the intimate illustrated feel of the reference image.
### UI design
The UI should resemble a handwritten midnight journal: warm cream typography, muted lavender panels, little stars, crescent moons, and softly animated transitions.

Important screens include the shop ledger, inventory, supplier catalogue, recipe book, town map, character journal, mystery board, calendar, and decoration editor.

The interface should disappear during quiet moments so players can enjoy the scenery.

## 14. Sound and music
Audio is critical to the game's identity.

The soundtrack should consist of original ambient compositions using soft piano, mellow synthesizers, acoustic guitar, brushed percussion, and gentle music-box melodies.

Music changes according to location, weather, and narrative state.

The shop's ambient soundscape includes refrigerator humming, rain on windows, distant cars, soft footsteps, a ticking clock, ceramic cups, and Miso purring.

During supernatural events, the game subtly alters familiar sounds rather than relying on loud horror stingers.

The player can also unlock an in-game radio with multiple original stations.

## 15. Accessibility and comfort
The game should respect different play styles.

Settings include adjustable game speed, optional checkout assistance, simplified crafting, automatic stocking, scalable UI, dyslexia-friendly text options, reduced animation, reduced flashing, independent audio controls, and full controller remapping.

Mystery assistance has three levels: no hints, contextual hints, and guided investigation.

Players can save and quit at any point, including mid-shift. There are no reflex-based challenges required to finish the story.

## 16. Technical architecture
For Godot 4, I would build this as a data-driven 2D game with modular systems.

The important architectural principle is that adding a customer, product, recipe, event, or investigation should rarely require changing core game logic.
### Core systems
System	Responsibility
GameState	Global progression, flags, persistent state
TimeManager	Shift clock, calendar, seasons
ShopManager	Opening, closing, reputation, layout
InventoryManager	Stock, storage, transactions
CustomerManager	Spawning, schedules, preferences
DialogueManager	Branching dialogue, conditions
RelationshipManager	Bonds, memories, story milestones
RecipeManager	Ingredients, crafting, discoveries
EventDirector	Dynamic encounters and anomalies
QuestManager	Tasks, dependencies, rewards
MysteryManager	Clues, deductions, investigations
WorldManager	Locations, travel, unlocks
EconomyManager	Prices, currencies, purchasing
DecorationManager	Furniture placement and effects
AudioManager	Music, ambience, transitions
SaveManager	Versioned persistent save files

### Suggested project structure

Moonmart/
├── project.godot
├── scenes/
│   ├── locations/
│   │   ├── shop_main.tscn
│   │   ├── shop_backroom.tscn
│   │   └── shop_hidden_room.tscn
│   ├── characters/
│   ├── furniture/
│   ├── interactables/
│   ├── minigames/
│   └── ui/
├── scripts/
│   ├── core/
│   ├── shop/
│   ├── customers/
│   ├── narrative/
│   ├── world/
│   └── systems/
├── data/
│   ├── characters/
│   ├── dialogue/
│   ├── products/
│   ├── recipes/
│   ├── events/
│   ├── investigations/
│   ├── quests/
│   ├── locations/
│   └── balance/
├── assets/
│   ├── backgrounds/
│   ├── architecture/
│   ├── characters/
│   ├── furniture/
│   ├── products/
│   ├── decorations/
│   ├── effects/
│   ├── fonts/
│   ├── interface/
│   ├── audio/
│   └── shaders/
├── docs/
│   └── art/
│       └── references/
└── tests/


### Data-driven character example
{ 
  "id": "pip",
  "name": "Pip",
  "type": "ghost",
  "first_appearance": {
    "chapter": 1,
    "minimum_shift": 2
  },
  "schedule": {
    "preferred_days": ["tuesday"],
    "preferred_hours": [0, 1, 2]
  },
  "favourite_products": [
    "strawberry_milk"
  ],
  "relationship": {
    "initial_stage": "stranger",
    "max_stage": "kindred"
  },
  "dialogue_tree": "pip_main",
  "storyline": "pip_lost_memories",
  "tags": [
    "supernatural",
    "friendly",
    "regular"
  ]
}


Character schedules, dialogue conditions, and event weights should all be stored externally.

Use Godot Resources for strongly typed runtime data where appropriate, with JSON or another validated external format for content authoring.
### Save system
Saves should contain the current shift, shop inventory and layout, currency, unlocked locations, relationship memories, story flags, investigation state, calendar, queued events, and the player's last position in each visited location. Restored positions are clamped to the active location's safe movement bounds; older saves without position data use the normal room spawn.

Use versioned save schemas and migrations so updates don't invalidate existing games.

Write saves through a verified temporary file and atomic replacement, keep a last-known-good backup, and preserve unreadable or newer saves. Offer an explicit clean-start recovery that archives the old save and backup instead of silently overwriting them.

Story progression should be driven by explicit event flags and conditions rather than relying only on the shift number.

## 17. Content scope
A full version of the game could target the following content quantities.
Content	Full game target
Main chapters	6
Major locations	6
Recurring named characters	25–35
Background customer variants	40–60
Products	150–200
Craftable recipes	50–70
Furniture and decorations	250–350
Main investigations	12–15
Character storylines	20–25
Dynamic events	80–120
Seasonal festivals	8
Main endings	3

These are aspirational production targets, not minimum requirements. Dialogue, animation, and narrative testing would likely be the largest content costs.

## 18. Development roadmap
I would avoid attempting the entire game immediately.

The right approach is to first prove that running Moonmart is fun even when nothing supernatural happens.
### Phase 1 - Core prototype — 4–6 weeks
One shop scene, player movement, product interaction, basic checkout, inventory, time progression, customer spawning, and save/load.

### Phase 2 - Vertical slice — 8–12 weeks
Five playable shifts, three named customers, Miso, one supernatural investigation, basic dialogue, one crafting station, and initial art and audio.

### Phase 3 - Systems expansion — 3–5 months
Decoration, relationships, event director, more customers, supplier economy, two explorable districts, and the first complete chapter.

### Phase 4 - Narrative production — 6–12 months
Remaining chapters, locations, character stories, puzzles, events, seasonal content, and progression balancing.

### Phase 5 - Polish and release — 2–4 months
Playtesting, accessibility, localization preparation, performance, save compatibility, and release.

Illustrative timelines for a small team with dedicated art and narrative support. Solo development could take substantially longer.

## 19. The first playable vertical slice
Moonmart — First Five Nights
A self-contained 60–90 minute experience
Playable shifts - 5
Named characters - 2 + Miso
Stockable products - 20
Craftable drinks - 5
Investigations - 1
Dynamic events - 6

### The five-night story
1. Monday: First shift. Learn the store, meet Agnes, and settle in with Miso.
2. Tuesday: Pip visits for strawberry milk. Their reflection doesn't appear in the window.
3. Wednesday: An old receipt appears in the register, dated 1974. It contains Pip's order.
4. Thursday: Investigate the receipt, discover a hidden photograph, and unlock the journal's deduction mechanic.
5. Friday: Help Pip recover their first memory. At closing, Miso leads the player to a door that wasn't there before.

### What this prototype must prove
The vertical slice should be judged against five questions: Is serving customers satisfying? Does the store feel comforting to spend time in? Are characters memorable? Is the mystery compelling without being frightening? Does the player want to begin another shift?

If those answers aren't consistently positive, expand neither the world nor the story until the underlying experience improves.

## 20. What makes the game special
The most important mechanic isn't the shop, the mysteries, or the supernatural abilities.

It's remembering people.

A customer who always buys the same tea might suddenly stop coming. Another might start purchasing two drinks instead of one. Someone who normally arrives smiling might quietly sit in the corner without ordering anything.

The player notices these changes because they've spent time with these characters, not because an exclamation mark appears above their heads.

Helping someone could mean solving a mystery, but it might also mean making their favourite drink, giving them somewhere warm to sit, or simply listening.

The store becomes a place where supernatural beings and ordinary people can exist without having to explain themselves.

And as the game progresses, the player realizes that's exactly why Moonmart was created.

## 21. Locked creative decisions
The following decisions are now part of the game's design baseline.
Decision	Locked specification
Camera	2D side-on, hand-painted storybook scenes
Movement	Horizontal movement with limited vertical depth
Shop growth	Expand into neighbouring rooms
Narrative tone	Heartwarming, bittersweet, gently mysterious
Combat	None
Failure	No bankruptcy, permadeath, or mandatory timed failures
Main location	Moonmart convenience store
World	Bellwether and the supernatural Between
Companion	Miso, the orange shop cat
Narrative	Six chapters, character stories, three major endings
Core experience	Shopkeeping, relationships, discovery, customization

The central design principle is comfort through routine, meaning through discovery.

Every system should contribute to at least one of these experiences: making the shop satisfying to operate, making its visitors feel alive, or revealing something meaningful about Bellwether.

## 22. Implementation architecture
I recommend four distinct layers.

### Presentation layer
Scenes · Animation · UI · Audio · Camera
            | ^
            V |
### Gameplay domain layer
Shop · Customers · Inventory · Crafting · Interactions
            | ^
            V |
### Narrative and progression layer
Dialogue · Quests · Clues · Relationships · Events
            | ^
            V |
### Data and persistence layer
Content definitions · Save files · Validation · Balancing

Each domain system should expose clear commands, queries, and signals. For example, the checkout system requests a sale from the economy system rather than directly modifying the player's money.
### Technical rules
- Use typed GDScript for gameplay logic.
- Use Godot scenes for entities and visual composition.
- Use Resources or validated JSON for authored content.
- Use stable string identifiers for products, characters, quests, and clues.
- Keep gameplay rules independent of scene nodes where practical.
- Use event signals to notify other systems of changes.
- Keep all game-changing random decisions on a seeded RNG.
- Save authoritative state, not transient animation state.
- Include automated tests for inventory, economy, progression, and save migration.

## 23. Core interaction specification
The player can walk, inspect, interact, carry items, place objects, open menus, and converse.
### Default keyboard controls
Input	Action
A / D	Move left / right
W / S	Change depth lane where permitted
E	Primary interaction
F	Secondary interaction / inspect
Shift	Walk faster
Tab	Shop ledger
J	Midnight journal
M	Town map
I	Inventory
Esc	Pause / back

All controls must be rebindable. Gamepad inputs use named Godot Input Map actions rather than hardcoded buttons.

The settings panel exposes every gameplay action, including menu/back controls, numbered selections, puzzle submission, decoration operations, and separate one-item versus bulk stock actions. Prompts read the active Input Map binding so remapped controls remain discoverable.
### Interaction priority
When multiple objects are within reach, choose the target using:
1. Whether the object is interactable.
2. Distance from the player.
3. Facing direction.
4. Interaction priority.
5. Stable entity ID as a deterministic tie-breaker.
The selected target displays a subtle contextual prompt. Only one primary interaction prompt appears at a time.

Interactions can trigger an immediate action, open a contextual UI, begin dialogue, or launch a minigame.

Backroom stock uses a physical carry loop. A single-item pickup moves one unit into a saved carried state and the player keeps the carry pose while walking; at the matching shelf or fridge, the player places it onto the display. The player may return the item to storage instead. The hand trolley and opt-in automatic stocking remain quick restock assists.
### State machines
The player uses the following states:

IDLE → MOVING → INTERACTING → DIALOGUE / MINIGAME / MENU → IDLE

Customer states:

SCHEDULED → ARRIVING → BROWSING → QUEUING → CHECKOUT → LEAVING → DESPAWNED

Special customers may enter LINGERING, CONVERSING, or EVENT_LOCKED.

Transitions must be validated, interruptible where safe, and restored sensibly after loading.


## 24. Shift simulation

### Authoritative shift timing

| Parameter | Standard game |
|---|---|
| Preparation begins | 11:30 PM |
| Doors open | 12:00 AM |
| Doors close | 5:30 AM |
| Simulated duration | 360 minutes |
| Simulation speed | 14.4 game minutes per real minute |
| Unpaused shift duration | 25 real minutes |
| Dialogue pauses | Enabled |
| Journal/menu pauses | Enabled |
| Mid-shift saving | Enabled |
| Early closing | Permitted |


The 11:30 PM–12:00 AM preparation period is included in the 360-minute simulated shift. It is not a separate timer. The shop is open to customers for the remaining 330 simulated minutes.

The 25-minute duration refers to running simulation time. Paused dialogue, menus, and between-shift activities may increase the total real-world session length.

The player may end a shift early after completing mandatory responsibilities.

The original supernatural agreement is satisfied by opening for a minimum service period, initially 60 simulated open minutes. This is an externally configurable balance value.

Failing to meet this requirement does not cause a game over or permanently block progression. Outstanding narrative responsibilities carry forward.

The hidden supernatural service window is a narrative discovery within ordinary overnight operations, not a second mandatory playable shift.

Important events remain queued when the clock is paused or the player closes early.

### Vertical slice timing override

The first five playable nights use a compressed tutorial schedule.

- Total target duration: 60–90 minutes
- Average shift duration: 12–18 minutes
- Number of shifts: 5
- Full shopkeeping and narrative interactions remain represented
- Tutorial pacing is configured separately from standard-game timing

This shortened schedule applies only to the vertical slice.

## 25. Shop and economy specifications
### Inventory
Products are identified by immutable IDs. Every stock movement is a transaction with a reason.

Inventory must support storage, shelf capacity, reservations, sales, restocking, spoilage, refunds, and special-order allocations.

A stock movement cannot produce negative quantities. A sale is atomic: either all required products are removed and payment is received, or neither happens.

The production inventory loop separates customer-facing display stock from backroom stock. Supplier deliveries enter storage first; the player replenishes displays within product-specific capacities. The expanded-capacity upgrade adds ten units to each product's authored stock capacity without replacing its individual limit. Perishable batches track remaining shifts and spoil when their date passes. The ledger records sales and can refund the latest sale when the returned goods fit product, shelf, and storage limits. Special orders reserve displayed items by allocation ID so ordinary checkout cannot consume stock already promised to a customer. The inventory panel exposes ordering, shelf replenishment, markdowns, donations, freshness, and refunds.
### Pricing
Initial balancing formula:
\[
P_{\text{sale}} = \operatorname{round}(P_{\text{base}}\times M_{\text{category}}\times M_{\text{event}})
\]

Prices remain fixed and all pricing multipliers remain at 1.0. Weather and season can shift optional ordinary baskets through displayed-stock variants, without changing any product price or essential basket.
### Checkout
Checkout is modeled as a transaction session containing the customer, basket, scanned items, payment method, and completion state.

A transaction may be completed only if the scanned items match the basket and payment is valid.

The player may enable assisted checkout to automate scanning without affecting story rewards.

Essential narrative progress is independent of a completed sale. If an essential visitor's basket cannot be fulfilled, completing an attempted checkout can still resolve their queued story conversation; the atomic sale fails, no goods or payment move, and the visitor waits while the player restocks.
### Shop expansion
Moonmart starts with one main retail room. Additional spaces are unlocked through shop reputation and narrative progression.
Expansion	Purpose
Main retail floor	Shelves, register, customer interactions
Backroom	Storage, deliveries, stock management
Tea corner	Drink preparation and seating
Reading nook	Longer conversations and character events
Enchanted greenhouse	Magical plants and ingredients
Hidden midnight room	Supernatural narrative interactions

Rooms are separate Godot scenes connected by door transitions. They share shop inventory and progression state but maintain independent decoration layouts.

The current production scene set includes the retail floor, backroom, Tea Corner, Reading Nook, Enchanted Greenhouse, town, forest, harbour, lighthouse, Midnight Platform, and Hidden Midnight Room. The Reading Nook and Greenhouse are optional commercial expansions with separate saved decoration layouts. Reading-room interactions support reading and quiet rest; greenhouse plant care uses the once-per-shift watering action and stewardship progression.

[Reference artwork: BEST ART CANDIDATE.png](art_import/BEST%20ART%20CANDIDATE.png)
## 26. Visual production and asset breakdown
### Art Bible v1.0 · Godot 4 · 2D Storybook Exploration

This image is a strong foundation for Moonmart's actual gameplay. I'd treat it as the master gameplay reference, with the original sleeping-cat illustration remaining the master reference for the overall art style.

The biggest production decision is that we shouldn't build this as one enormous background image. We need to separate it into environments, characters, furniture, props, effects, UI, and interaction points so everything can move independently.


### Room unlock authority

Essential narrative rooms, including the Hidden Midnight Room, unlock through story progression.

Optional commercial rooms, including the Reading Nook, Enchanted Greenhouse, and expanded preparation areas, unlock through shop reputation. The Reading Nook upgrade requires Neighbourhood Favourite; the Greenhouse upgrade requires Moonlit Haven.

Rooms that serve both narrative and commercial purposes must provide essential story access regardless of reputation.

No essential story location may require optional reputation grinding.


### Scene breakdown
### Asset categories visible in the reference

Environment
Walls, windows, floor, arches

### Characters
Player, Agnes, Pip, Fern, Lucien, Miso

Furniture
Shelves, counters, fridges, displays

Products
Bottles, boxes, pastries, jars

Decoration
Vines, plants, lamps, banners

Interface
Clock, currency, quest tracker, prompts

Effects
Ghost glow, moonlight, steam, reflections

Interactions
Checkout, browsing, doors, inspection


### Scene layout
The screenshot shows a great arrangement for the initial Moonmart retail room.
Area	Gameplay purpose	Key assets
Left wall	Browsing and product selection	Shelves, books, product packages
Refrigerators	Cold goods and Pip's favourite drink	Two fridges, bottles, lighting
Centre display	Featured products and baked goods	Display case, baskets, sign
Main walkway	Player and customer movement	Floor, interaction zones
Rear wall	Storage and progression	Shelves, doorway, curtains
Checkout	Sales and customer conversations	Counter, register, bell
Front decoration	Depth and atmosphere	Plants, flowers, stools
Windows	Weather and time-of-night effects	Window frames, sky, moon, trees

One important change: Agnes shouldn't be permanently fixed behind the register. The player should be able to operate the register themselves, while Agnes can visit, help during tutorials, or occasionally cover a shift.


## 27. Asset layering
This is the highest-priority art acceptance gate: preserve each painted environment plate and keep every dynamic light or effect independently controllable. Never bake light rays or light particles into an environment image, even if they appear in a composed `art_import/` reference. Also keep animated or switchable glow, changing weather effects, and story VFX separate. Fixed moons, stars, cloud banks, distant atmospheric haze, fixture warmth, and reflections may remain as scenic painting when they do not change with weather, story state, upgrades, or accessibility settings.

Treat composed `art_import/` screenshots as quality and style references; do not flatten their rays, floating particles, steam, or other animated cues into an environment PNG. Recreate those cues on separate raster layers or dedicated lights while preserving fixed scenic sky details, fixture warmth, and painted reflections. Keep rain, snow, wind-borne leaves or motes, and switchable fog as separately controllable effects; fixed clouds and distant haze are allowed only as unchanging scenery.

### Runtime layer stack
Draw the shop from back to front. These roles map to independently controlled Godot nodes; lighting and VFX remain separate from the painted plates.

1. `NightSkyLayer` — moon, clouds, and stars visible through the windows.
2. `ExteriorParallaxLayer` — distant trees, hills, and town silhouettes.
3. `SeparateLightingLayer` — dynamic moon halo and other switchable light sources.
4. Shop `WindowEffectsLayer` — weather, seasonal atmosphere, and story effects. Districts use separate weather and story layers.
5. `ArchitectureLayer` — wall, floor, trim, fixed window frames, and doorway.
6. `BackgroundFurnitureLayer` — shelves, fridge, and other rear furniture.
7. `DepthSortedCharactersLayer` — the player, customers, and interactables, sorted by ground position.
8. `ForegroundFurnitureLayer` — counter fronts, display edges, and close decorations.
9. `PropEffectsLayer` — depth-placed steam, isolated particles, and object-specific effects.
10. `HUDDialogueLayer` — screen-space interface and dialogue.

District scenes use named sky, parallax, lighting, window-effect, architecture, background-furniture, depth-sorted-character, foreground-furniture, weather, story, prop-effect, and HUD layers composed around the intact location plate. Dynamic lighting uses its own independently controlled light layer; weather, story, and foreground effect sprites render above the full plate. Sky and parallax underlays sit behind it and show only through transparent or composed artwork. The runtime supplies missing empty layers and places the backdrop and NPC cast into the architecture and character layers. Keep each effect layer independently switchable; a scene may leave a layer empty until matching art or a dedicated light is authored for it. Per-layer requests and per-frame effect visibility must honor the global visual-effects and dynamic-lighting settings, so scene code cannot override a player's accessibility choice. Backroom placed furniture shares the character layer's depth range so both sort by their ground positions. Foreground fixtures must draw above the depth-sorted character layer; Tea Corner's seat and plant use the dedicated foreground furniture layer. Tea Corner weather uses its transparent window openings and the under-architecture `WindowEffectsLayer`, so the painted window frame clips rain, snow, and seasonal wind to the glass. Midnight Platform has one dedicated `ForegroundParallaxLayer` between its intact plate and depth-sorted characters; its direction signpost is sampled directly from the approved platform-furnishings atlas and moves independently with a subtle camera ratio. This is a foreground-prop depth proof only. All five opaque outdoor district plates still cover their sky and distant-parallax underlays, so background-scenery parallax remains incomplete pending matching composited or transparent scenery layers.

Every location's `NightSkyLayer` and `ExteriorParallaxLayer` also have independent `location_night_sky` and `location_exterior_parallax` visibility controls. These scenery controls persist across location travel and do not use the visual-effects or dynamic-lighting master toggles; architecture remains visible when either scenery layer is hidden. Keep animated or switchable light, weather, particles, and story cues on the separately gated effect layers described above.

Rainy outdoor shifts show low-opacity, animated streaks from the approved raster rain atlas; snowy shifts show individually animated flakes from the approved seasonal atlas. Spring wind carries isolated petals; summer wind drifts subtle warm motes; autumn wind carries leaves; and winter wind sweeps small flakes from the approved seasonal atlas. The five opaque outdoor plates use district-specific compact effect anchors in reviewed atmospheric pockets, with sprite bounds and motion kept inside the scene; snow and wind stay bounded so weather does not wash across prominent painted storefronts, canopy edges, boats, cliffs, or platform scenery. District effects live on each scene's independent `WeatherEffectsLayer`; Tea Corner uses pane-centered effects on its under-architecture `WindowEffectsLayer`, where the transparent architecture masks them to the glass. Effects appear only for their matching weather and season, obey the environmental-effects setting, and freeze when reduced animation is enabled. The Reading Nook and Enchanted Greenhouse use intact painted architecture plates with separate furniture and empty, independently controlled lighting and effect layers. Their composed window panes are scenic and do not receive changeable weather overlays. Neither new plate contains rays, light particles, weather, or story VFX. The restored lighthouse story still lacks a matching separated beam reference in `art_import/`; do not fabricate a beam or bake it into the plate. Fog has no matching approved raster effect yet. Four style-referenced fog raster probes remain QA-only. The first two show edge halos and foreground overlap; two later art-generated refinements still show colored edge fringe and detached speck noise on dark-plum/warm-cream previews. Their low-opacity harbour and lighthouse composites were reviewed, but no candidate passed the Section 28 alpha-edge gate. A new art-generated Bellwether distant-ridge probe also remains QA-only: its paired dark-plum/warm-cream alpha previews are clean, but its hill and town shapes do not align with the intact district plate. No candidate passed location-specific compositing review, so no new fog or parallax art enters runtime. An inventory of all seven art_import PNGs found only composed reference sheets, with no district-specific separated sky/landscape or matching underpaint. The source-derived masks recompose exactly at rest but punch holes through roofs, foliage, or shoreline when shifted, or reveal a hard seam. Distant district parallax therefore needs original layered working files or location-matched scenery with transparent architecture cutouts and sufficient underpaint/overscan. The source plates and atlas pixels remain unchanged.

The `SeparateLightingLayer` owns the dynamic-lighting accessibility toggle. Child lights stay locally enabled and inherit the layer's visibility so a light created while dynamic lighting is off becomes available again when the player turns lighting back on. Per-layer and per-effect visibility requests are retained while the master accessibility toggle is off, then restored when it is enabled; child lights do not duplicate the master setting. Godot 2D lights affect canvas items through their z-range and item mask, so the lighting layer's draw order alone does not hide a light from an opaque architecture plate. The shop moon halo is restricted to the separate sky/parallax z range, Pip's story glow targets Pip's character z only, and placeable fixture lights target the furniture/character depth range so they cannot dynamically alter the opaque environment plate. Keep every new light attached to this separate layer and define its receiver range for the intended composition; outdoor district scenes currently have no additional runtime moon halos.

The Section 27/28 validator checks the reviewed runtime light/effect attachment points, rejects unlayered Light2D or particle nodes in scene files (including root nodes), and fails closed when a new runtime light or particle constructor appears until its layer contract is reviewed and updated. Its source sweep covers Godot scripts, textual scenes/resources/shaders, and C# sources across the project while excluding tests, QA evidence, templates, and generated caches. The validator runs under both Windows PowerShell 5 and PowerShell 7; project-relative paths, OpenRaster layer-name checks, and embedded-image SHA-256 checks use compatible APIs and encodings. The validator cannot inspect painted pixels; every new or revised environment plate still requires native-size and game-scale visual review against `art_import/` for baked rays, particles, or other changing effects.

For movement, I'd implement a 2D side-on scene with shallow depth. Characters move left and right, but can also move a short distance toward or away from the camera to approach shelves and counters.

That means we can retain the exact illustrated perspective while allowing customers to walk around one another naturally.

### Production layering rules
The shop architecture plate contains only fixed room structure: wall, floor, trim, window opening and doorway. Sky, distant town silhouettes, foreground plants, characters, furniture, interface, lighting, changing weather, and story VFX are separate scene elements. Light particles and light rays must never be baked into a background image. Rain, snow, moving leaves or motes, and switchable fog also stay separate. Fixed astronomical stars, clouds, and distant atmospheric haze may be painted into scenery only when they are not animated or changed by weather/story state. Static illustrated illumination that belongs to a fixture or material may remain part of a location painting. Place dynamic effects on independently switchable layers so weather, upgrades, story states and accessibility settings can change them without replacing the room art. Keep the base location painting intact; create any moving or switchable effect as its own transparent raster layer or dedicated 2D light, matched to the palette and brushwork in `art_import/`. Reject any cutout with a visible fringe, detached specks, or an opaque/matted background.

Draw the exterior from back to front: night sky and distant landscape, separate moon lighting, transparent window effects, then the architecture and window frame. Draw shop depth in this order: room architecture and floor/navigation, background furniture, characters and interactables sorted by foot position, foreground furniture, depth-placed prop effects, then HUD and dialogue. Use independently controlled, named scene nodes for sky, parallax, lighting, weather/story effects, architecture, furniture, characters, prop effects, and HUD. Keep foreground steam above the counter silhouette where it rises into view. Use consistent ground anchors and interaction markers rather than baking these into each sprite. Outdoor district plates may retain their painted fixture light and reflections, but must keep light rays, particles, weather, and any animated or switchable lighting outside the base image. District base plates are currently drawn in `ArchitectureLayer`; separate lighting remains independently controlled, while weather, story, and foreground effect layers render above the intact full plate. Sky and parallax underlays sit behind that plate and are visible only where a composed or transparent plate permits them. Keep rays and particles out of all base images. The alpha-clean structural atlas is catalogued in `data/architecture_modules.json`; the finished shop already has matching architecture and trim, so place those modules only in a location composed around them.

## 28. Asset production inventory
`art_import/` is the visual source of truth. In-game artwork is produced as high-resolution raster PNGs in `assets/raster/`, following those references' painterly night palette, soft texture, rounded forms, and warm window light. Keep backgrounds and effect sprites separate as Section 27 specifies. Do not replace the painted art with placeholder SVG illustrations. The current production pack's dimensions, atlases, transparent layers, and runtime use are recorded in `assets/raster/asset_manifest.json`; the larger quantities below remain the content-production targets.

Section 27 is the highest-priority art acceptance rule: never bake light rays or light particles into environment plates. Keep animated or switchable glow, changeable weather effects, and story VFX on independently controlled raster layers or dedicated lights, with runtime visibility respecting accessibility settings. Fixed moons, stars, clouds, distant haze, fixture warmth, and reflections may remain scenic painting when they never change with weather, story state, upgrades, or accessibility settings. A visual audit of all 17 environment images against `art_import/` references found no baked rays, particle fields, changing weather effects, or story VFX. Tea Corner's 1600×900 plate and its derived sky and parallax layers render at native size; weather anchors use the same unscaled glass-pane coordinates, and the layers recompose pixel-exactly with their source. Midnight Platform uses the approved `platform_direction_signpost` atlas cell as a separate foreground prop; the source plate remains unchanged, the layer moves at a near-camera ratio, and it remains visible when optional visual effects are disabled. This does not provide distant scenery parallax. All five opaque outdoor district plates still have no visible independent sky or background-scenery layers. The runtime routes separate lighting and effect layers through the dynamic-lighting and visual-effects settings. Sequential GPU review of all five outdoor locations found and corrected a travel-state regression that re-enabled Moonmart's furniture layers after the first outdoor transition; the shop layers now stay hidden until the player returns to Moonmart. GPU review also covered the remaining five interiors and confirmed their own architecture/furniture stacks. The expanded main-scene headless smoke travels through all ten relevant locations, including both new rooms, and checks their effect controls, interaction markers, and camera framing at three aspect ratios. GPU-backed renders confirm the intact shop plate, separated HUD rows, compact dialogue framing, and clean scene layering; story-state and hands-on input review remain open. `assets/raster/environment_visual_review.json` records SHA-256-bound signoff for the reviewed environment images and their art_import/ source sheets. `assets/raster/asset_visual_review.json` binds every catalogued raster, its cited art_import/ sources, and each available dark-plum/warm-cream preview to SHA-256. The Section 27/28 validator rejects stale image, source, or preview hashes, missing or mismatched preview pairs, uncatalogued PNGs, stale or missing art_import/ citations, unsafe paths, mismatched Light2D receiver z ranges, SVG runtime references, and PNG/atlas dimensions that do not match their declared cells. The main-scene smoke also checks all six story-prop sprites use their exact atlas regions and the Greenhouse return door stays within its inset cell. The scene-region audit corrected the Old Bellwether photo crop and Greenhouse door crop without altering source artwork. New or changed images and previews must be inspected at native size and game scale against art_import/ before refreshing the ledger; hashes detect staleness but cannot replace pixel-level review. All 73 catalogued atlas or transparent PNG entries have paired dark-plum and warm-cream QA previews, with their paths recorded in the manifest. All 89 runtime PNGs use Godot lossless mode (`compress/mode=0`); the Reading Nook and Greenhouse import sidecars were generated and verified. Source-only PNG inputs are kept under `qa_asset_repairs/` and excluded from Godot imports. Reject candidate cutouts with fringe or detached specks; the rejected examples and pixel-only repairs are recorded in `assets/raster/asset_manifest.json`.
### Characters
Character	Required animations
Player	Idle, walk, carry, inspect, interact, talk, craft
Pip	Float, blink, excited, sad, glow
Miso	Sleep, sit, walk, stretch, play, purr
Agnes	Idle, walk, talk, checkout, wave
Fern	Idle, walk, inspect plants, talk
Lucien	Idle, walk, read, drink, talk
Wren	Idle, walk, browse, cast small magic
Generic customers	Idle, walk, browse, queue, purchase

For the player, I recommend four visual facings: left, right, front-three-quarter, and back-three-quarter. Since this is a side-on game with shallow depth, these provide enough flexibility without requiring a fully animated eight-direction character.

Initial sprite target: approximately 160–240 pixels tall at the game's reference resolution, using higher-resolution source artwork for clean scaling.

Each character should be built from consistent proportions and animation pivots. We should not generate independent poses without a model sheet, because the character designs will drift.

The current runtime adds dedicated static talk poses for the player and Agnes, Lucien's isolated drink pose while he lingers, Wren's isolated casting gesture during conversation, a dedicated queue pose, and a four-frame checkout handoff for ordinary shoppers. The player's 8×4 atlas now plays its carry frame on successful restocking, inspect and interact frames on their inputs, and the craft frame after a successful recipe; idle and action poses retain the last movement-facing row, and profile rows are no longer mirrored a second time. Outdoor named visitors hold their existing talk frame only while they are the active conversation partner; non-addressed visitors remain on their idle frame. Pip's four-frame raster atlas uses exact 435×724 integer cells, including a dedicated sad pose for the missing-reflection story beat. Pip's story glow uses a separate `PointLight2D`, and the former atlas glow frame with sparkles has been removed. Character poses contain no environmental light or spell VFX. Reduced animation suppresses Wren's cycling cast gesture, returns Lucien and ordinary shoppers to base poses, and freezes the checkout handoff on its final frame. The core visitor atlases document their left-to-right frame orders in `assets/raster/asset_manifest.json`: Fern's third cell inspects plants, Lucien's third cell reads, and Wren's first and third cells browse and inspect herbs. During `BROWSING`, the runtime selects Fern's plant-inspection cell and Lucien's reading cell; Wren alternates between her herb-browsing cell and inspect-herb cell. Reduced animation suppresses Wren's cycling and keeps visitors on a single task-appropriate pose. Agnes uses her walk pose while arriving and leaving, waves after reaching her arrival target, uses the checkout-talk pose in the queue and at the register, and uses her isolated talk pose during conversations. Reduced-animation mode holds her idle pose. Named visitors still use their existing atlas poses during checkout.

During `BROWSING`, the Conductor reads the passenger manifest (atlas frame 3), Elias inspects the lighthouse lens (frame 2), Mara offers a letter (frame 2), and Osric reads the ticket (frame 2). These role-specific task poses remain static when reduced animation is enabled; Wren's timed alternate pose continues to freeze on her base browsing frame.

Location NPC conversations use the same character-specific pose rules as shop visitors: Agnes uses her standalone talk pose, the Conductor offers the ticket, and Wren's separate casting gesture remains timed and is suppressed by reduced animation. Other location talkers use their documented talk atlas cell.
### Environment assets
Recommended first-room asset quantities
Architecture and structural pieces	15–20
Shelves and furniture modules	20–25
Product icons and shelf variants	35–50
Plants and decorations	25–35
Lighting and VFX elements	12–18
UI elements and icons	25–35

Approximately 132–183 unique visual assets for a richly decorated first room, before animation frames and variations.
### Modular furniture rules
Every interactive furniture asset needs a consistent definition:
- Visual sprite and optional overlays.
- Ground anchor and collision footprint.
- Interaction positions.
- Product display slots or storage capacity.
- Optional animation states.
- Lighting attachment points.
- Decoration placement restrictions.
A refrigerator, for example, needs a closed state, open-door state, interior stock display, light overlay, interaction area, and collision shape.

A shelf should be reusable with different product assortments rather than requiring a separate painted shelf for every inventory combination.

### Current production pack
Raster production assets live under `assets/raster/` and use the artwork in `art_import/` as their visual source of truth. The pack includes a layered architecture plate; separate sky and Bellwether parallax layers; modular shop furniture and door atlases; 100 product icons across one 4 × 5 base atlas and five 4 × 4 extensions; player, Pip, Miso, and Agnes animation atlases; dedicated player/Agnes talk, Lucien drink, Wren casting, ordinary-shopper queue, and checkout handoff art; isolated kettle and UI assets; five district backgrounds; and separate Reading Nook and Enchanted Greenhouse room plates. The shop architecture plate and structural module atlas received pixel-only alpha repairs that cleared low-alpha magenta fringe while preserving painted pixels. Their dimensions and cell layouts are recorded in the manifest. Each atlas documents its cell layout, and furniture definitions carry the visual cell, ground anchor, collision footprint, interaction positions, state list and lighting attachment metadata. Keep all new artwork as transparent raster layers where an asset must be isolated; do not substitute placeholder vector illustrations.

The exploration journal also supports six save-backed keepsakes, one discoverable inspection target in Moonmart and each of the five core outdoor districts. Their catalog and localized names/descriptions live in data; no new environment plate art is required. A generated token-icon probe was rejected for visible yellow edge fringe and detached flecks, so it remains QA-only and outside the runtime asset pack.

The recipe book supports station-specific experimentation. Players can select available ingredients and try an exact combination; failed trials leave stock untouched, while a successful eligible match consumes ingredients atomically, stores the product in the backroom, and records the discovered recipe. Existing shift and story gates remain authoritative, and older saves retain the recipes they had already unlocked.
## 29. UI and typography
The font in the screenshot is worth retaining as a visual direction.

I'd create three typography roles:
Role	Appearance
Moonmart logo	Rounded, playful, slightly handwritten
Headings	Friendly, soft handwritten lettering
Body/UI	Clear rounded sans-serif with similar character

The gameplay and settings UI use the bundled Nunito variable font by default. An optional OpenDyslexic font setting switches the interface typeface and increases text size and line spacing. Both fonts are distributed under the SIL Open Font License 1.1 with their licenses under `assets/fonts/`. Custom logo lettering remains artwork and follows the raster art direction.

The HUD should also be modular: the clock and currencies remain visible, while quests, prompts, and controls appear contextually.

HUD edge anchors and the centered controls hint recalculate from cached base positions and the original reference viewport whenever the viewport resizes; changing window dimensions must not require a UI-scale setting change.

## 30. Godot 4 implementation structure
I'd build each room as a scene with independently movable characters and interactable props.

All scene and asset paths follow the canonical Moonmart project structure defined in Section 16. The following implementation notes describe scene behaviour, not an alternative directory layout.

### Movement and navigation
For a scene like the reference, use CharacterBody2D for the player and moving NPCs, AnimatedSprite2D or AnimationPlayer for character animations, and NavigationAgent2D for customer navigation.

Furniture should have interaction markers positioned in front of it. Customers navigate to those markers, then transition into browsing or checkout animations.

Use depth sorting for the shallow walkable floor, with explicit foreground overlays where necessary.
## 31. Production backlog status
### P0 · Build the playable room — complete
Build the playable room

Import a layered environment, implement player movement and collision, add camera tracking, and make the shop navigable.

### P0 · Create the first character sprites — complete
Create the first character sprites
Player walk and idle animations, Pip floating, Miso sleeping, and one customer movement set.

### P0 · Implement interactions — complete
Implement interactions
Shelves, refrigerator, register, door transitions, contextual prompts, and basic customer checkout.

### P1 · Add atmosphere and interface — complete
Add atmosphere and interface
Dynamic lighting, window parallax, plant movement, steam, ghost glow, clock, currency, and journal UI.

### P1 · Build the first complete shift — complete
Build the first complete shift
Customer arrival, browsing, checkout, conversation, closing, earnings, and saving.

### P2 · Expand the world — first production pass complete
Expand the world
Backroom, exterior street, decorating system, more customer animations, and the first supernatural investigation.

### P2 · Complete the full narrative and visitor roster — complete
The first production pass reaches the lower content counts. The deterministic headless campaign now passes 229 checks across all 37 essential events, all 15 investigations, gated location travel, the Gentle Goodbye ending, and post-ending sandbox. The separate progression suite verifies all three ending gates and world outcomes; manual in-game story and presentation review remains open. Keep essential clue collection and chapter transitions reachable, and keep role-specific poses mapped to the matching states recorded in Section 28. Investigation theories whose required clues remain chapter- or flag-locked stay hidden until those clues can be found, so guided hints do not point to unavailable content. Essential queued story events now resolve at an attempted checkout even when stock prevents the sale; the customer remains available while the player restocks. The player's existing atlas now selects carry, inspect, interact, and craft poses for the matching actions and preserves facing through idle/action poses. Dedicated player-talk and Agnes-talk poses, Lucien-drink and Wren-casting poses, ordinary-shopper queue art, and four-frame checkout-handoff art are integrated; runtime frame routing follows the atlas frame-order records in Section 28. The full named roster now has dedicated raster sheets; ordinary shopper archetypes retain the generic atlas. Miso selects sleep, sit, walk, stretch, play, and purr frames from the matching rest, movement, idle, reduced-animation, and care-action states; Pip uses a brief blink window every 3.6 seconds instead of holding the blink pose for several seconds. The Midnight Platform waiting bench is a reachable rest interaction; its clock does not advance while the player pauses there.

### P2 · Finish adaptive music and the radio — complete
The shop layers a quiet base ambience with refrigerator hum, soft clock ticks, rare distant traffic, and Miso purring. Resting purr follows the Music ambience level; short care-triggered purr follows the Effects level. Footsteps play at a restrained movement cadence and ceramic cups sound on successful service or crafting. The radio upgrade now unlocks three distinct original 32-second stations. Station choice persists in user settings; radio playback stops outside Moonmart and resumes on return, beneath the room ambience. Four original 32-second location scores cover Bellwether, Whisperwood, the harbour/lighthouse, and the Midnight Between; the backroom and Tea Corner use the quiet Window Seat theme. Each location score now has separate original rain, fog, wind, and snow variants built from its own harmony. Outdoor scores select the shift's weather variant and crossfade over two seconds on travel and shift changes; the sheltered backroom and Tea Corner retain Window Seat. Four original location ambience loops add distant town air, forest leaves and rare birds, gentle harbour water and buoy tones, and pulse-free Midnight air; backroom and Tea Corner use a quieter room-tone layer. Outdoor location ambience transitions crossfade over two seconds. Shop and location ambience crossfade over 1.5 seconds during travel, with each layer following the Music volume setting. A 32-second remembered-threshold overlay fades in during the unresolved Pip/doorway story and mixes quietly over eligible location music, fading out when the boundary is stabilized or the ending is chosen. The familiar Moonmart arrival bell and completed-sale register chime gain quiet lower-resonance variants while Pip's reflection is missing; both return to their ordinary chimes after the boundary is stabilized or an ending is chosen. The variants replace the standard sounds instead of stacking with them. Seven original short effects cover ordinary and threshold arrivals, ordinary and threshold completed sales, story reveals, movement-throttled footsteps, and ceramic cups; all use the independent SFX setting. A separate, original rain-on-window loop plays only during rainy Moonmart shifts and follows the Music volume setting; it is independent of the rain visual toggle and background plate. Weather score variants and the unresolved-threshold arrival/sale sound changes are integrated. The automated campaign resolves all 37 essential events; in-game listening and presentation review remain open.

### P3 · Release polish and compatibility — in progress
Startup now loads the system-language catalogs before constructing the initial HUD and pause-menu controls. The main-scene smoke asserts that the first pause button uses the loaded catalog; full-system in-game Spanish fit and readability review remains open.
The QA-only main-scene locale override now drives the production Spanish catalog path on English-hosted builds. A GPU-backed runtime review captured the Spanish HUD, journal, inventory, town map, calendar, settings, and story dialogue at 1600×900, including the minimum and maximum UI scales; 98 runtime localization/layout checks pass. The review routes all 37 essential Spanish story summaries through the production message panel and checks actual rendered line height plus on-screen panel bounds. It also corrected the repeated journal title, moved side-panel text inside the illustrated parchment safe area, and inset Settings section labels from the frame moons. Captures are in `godot_task_state/localization_runtime_review_20261113_02/`. Full long-play and hands-on localization review remains open.
All 25 named characters now have an authored storyline route (ten new three-step arcs for Stellan, Iona, Liora, Rowan, Maribel, Tomas, Juniper, Beckett, Nella, and Aster, with Spanish text; 117 conversations in total). Named visitors without a dedicated opening conversation previously could not reach their routes at all; MoonmartGame.interact() now falls back to the route for any routed character, and the named-storyline suite plays every non-hardwired character's full route through interact(). Several new arcs unlock at chapters 1–3; some third steps still wait for later flags. Hidden keepsakes now number 11: the original six plus one each in the backroom (delivery crates), Between room (memory wall), Tea Corner (moonflower seat), Reading Nook (reading chair), and Greenhouse (moonflower trellis), with English and Spanish text. Room objects with their own handlers award their keepsake on first use and announce it after that interaction's message; the catalog suite checks that every keepsake has text and a real target, and the main-scene smoke covers the platform bench. Dialogue and the UI load optional system-language overlays by stable IDs, with English fallback. The English UI key catalog covers settings, interaction prompts, pause and journal controls, memory instructions, save-recovery messages and actions, welcome/HUD hints, mystery-board guidance, all 15 investigation cases and their hypotheses/results, all 44 clue descriptions, seven environmental puzzles, the nine-location town map, seasonal calendar and festival descriptions, generated journal sections, saved ending memories, open promise text, story event titles, ledger, housekeeping, companion care, radio, upgrades, shift status, pause actions, decoration controls and results, checkout, inventory and stock notices, stock/backroom instructions, system-generated shift and interaction messages, all 100 optional event notices, recipe preparation and experimentation, and product/recipe display names including furniture names in the decoration data; the Spanish UI overlay translates all 1,469 keys and preserves their placeholders. Controller button labels use neutral positions and localized Spanish names across controller layouts; stick and trigger axes also have localized labels. The Spanish dialogue overlay translates all 37 story-event summaries, all 31 everyday visitor lines, the fallback visitor line, and all 87 character conversations plus paired visitor banter while preserving conversation IDs, line counts, order, and placeholders; role labels are localized for display and conversation routing metadata remains source-authoritative. The current Spanish catalog covers the audited UI inventory, including all Dreamwalking scene and choice text plus the authored Memory Echo fragments, automatic Spirit Sense reaction, and Guardian's Purr anomaly messages, and Hidden Paw target guidance and inspect prompt. A Spanish settings-layout smoke checks wrapping of long control labels and reset-button width; game-speed and settings-slider decimal values now use Spanish comma formatting. The accessibility comfort suite samples the raster journal panel, checks visible settings text at a 4.5:1 contrast minimum, and checks keyboard/gamepad focus rings at 3:1; all 778 checks pass. Full in-game fit/readability review and catalogs for additional languages remain open. Long side-panel content, including all 150 inventory products, now uses a vertical scroll area with Page Up/Down and wheel support. The settings view lets translated titles and descriptions wrap and grow inside its scroll area; automatic-stock controls use separate product and quantity rows. UI scaling now keeps edge HUD groups aligned to their screen edges and centers the full-width controls hint; the main-scene smoke verifies compact currency icons, in-viewport HUD bounds at the minimum and maximum scales, and settings-dialog bounds and keyboard focus at both scales, plus HUD, dialogue, settings, and camera framing at 1280×960, 1920×1080, and 2560×1080 aspect ratios. When ultrawide framing crops the room vertically, the camera follows the player along the cropped axis; the main-scene smoke asserts the player stays visible while the view remains within the painted plate. Versioned saves reject missing payloads, invalid schema numbers, and malformed known nested state before import, while omitted optional fields remain compatible with older schemas. If the primary save is missing or unreadable, only structurally verified `.tmp`, `.replace`, backup staging, or preserved recovery-copy candidates are eligible for recovery; unreadable primaries are archived, and a recovered temporary candidate is preserved before a later save reuses its staging path. User settings verify staged data and roll back failed replacements; malformed or unreadable settings are restored from a verified staged candidate when possible, otherwise preference writes are locked, with the unreadable primary retained in an archive when recovery succeeds. Headless game-save coverage now exercises legacy migrations, malformed and future formats, verified writes, backup rollover, corrupt-primary recovery, unreadable-save archiving, and staged recovery candidates. Settings-file coverage now exercises legacy normalization, current-schema writes, future-schema preservation, malformed-primary write locks, staged promotion, corrupt-primary archival, valid-stage recovery, and invalid-stage preservation. QA composites and source-review sheets now sit in a `.gdignore` folder rather than the runtime raster pack; the pack is about 150 MiB. Static audio inventory found 41 source WAV files (including music, ambience, and effects), 166.17 MiB total. Their 41 Godot imports use QOA compression (`compress/mode=2`) and occupy 33.57 MiB in the current import cache. All runtime audio references point to WAV sources; no Ogg/MP3 source or import sidecars are present. Compare playback quality and memory on target hardware before changing the source format or import mode. Target-device profiling remains. The latest full headless run (30 suites, isolated app data) passes 30/30, adding 151 named-storyline checks, 98 checkout-packing checks, 22 checkout-recommendation checks, 8 checkout-tender checks, 137 Spanish layout checks and 21 Miso ambient checks to the gates below. Previously recorded headless gates passed: 47 housekeeping checks, 168 economy/time checks, 55 adaptive-audio checks, 67 progression checks, 229 full-campaign checks, 153 environmental-puzzle checks, 902 recipe-catalog checks, 38 navigation/layout checks, 33 game-save migration/recovery checks, 29 settings migration/recovery checks, 5,642 localization catalog checks, 2,201 visitor/event catalog checks, 778 accessibility comfort checks, 24 calendar-cycle checks, 23 Miso-companion checks, 20 Dreamwalking gameplay checks, 14 Memory Echo gameplay checks, 14 Spirit Sense gameplay checks, 19 Guardian's Purr gameplay checks, 12 Hidden Paw gameplay checks, 14 optional-anomaly investigation checks, and a main-scene smoke across the ten locations including the Reading Nook and Greenhouse. It also verifies every visited destination retains its visible, full-color raster environment plate on ArchitectureLayer; the smoke passes with zero assertions failed. Earlier listed system counts predate these room changes. The production pack now contains 17 environment images with SHA-256 visual signoff, 89 raster assets, and 73 paired atlas/transparent previews. A fresh Section 27/28 automated gate passed after adding the two new room plates. The new rooms pass a post-change headless travel/scale smoke; hands-on GUI composition review remains open. Manual in-game story/audio listening and presentation, visual localization fit/readability, hands-on contrast and controller review, and target-device performance profiling remain before release. Automated Spanish layout and accessibility comfort checks pass, but they do not replace those device and presentation reviews. Runtime smoke assertions passed with no runtime warnings during the earlier location travel/layer checks. The auto-stock OptionButton is attached to its intended row. A fresh post-fix shutdown smoke passed with zero assertion failures, and its Godot log contained no errors or warnings. Runtime reparenting owner warnings are fixed. Section 34 lists the required system coverage for validation.

A local 300-iteration startup profile on Godot 4.7.2 and an NVIDIA RTX 4070 completed cleanly in 6.19 seconds, with a sampled 340.4 MiB peak process working set and 3.59 seconds of CPU time. This startup/idle baseline is recorded in `godot_task_state/profile_20261113/summary.txt`; target-device profiling under gameplay load remains open because the release hardware is not specified.

Two local gameplay-load profile runs (rainy shift, four visitors, movement, dialogue and journal UI; 1600×900, 60 FPS cap, RTX 4070) held a P99 frame interval of 16.9 ms in the active phase. Run 2 contains one 623 ms frame that run 1 does not; process CPU fell during it and a 37 MiB private-memory transient appeared, which points to a wait in the driver, audio device or OS, but the cause is unidentified (`godot_task_state/profile_gameplay_20261113/RUN_02_OUTLIER_ANALYSIS.md`). The profiler now records a per-frame process/draw/rest split and a stall log so a repeat can be attributed. A third valid run and target-device profiling remain open.

Controlled GPU review of the production settings panel at 1600×900 in Spanish found that body controls encroached on the illustrated frame and the footer sat below it. The left/right content insets, vertical scroll viewport, and footer position were corrected; fresh top and bottom captures at the default, minimum, and maximum UI scales show translated settings content contained within the frame, with long Spanish action labels wrapping and reset buttons remaining legible. Full in-game dialogue and HUD fit review remains open.

A separate 1600×900 GPU capture routes the Spanish `lighthouse_restored` story summary and a 202-character Spanish optional-event notice through the main scene's actual message-panel handler; both wrap to two lines inside a 114px panel without clipping. The capture leaves other interface text in the host's English locale, so it verifies the story panel's Spanish fit only; full-system-language dialogue/HUD review remains open.

The authored main-story plan spans shifts 1–42; at the standard 25-minute full-shift pace this is about 17.5 hours, within the 15–25-hour target. That is a pacing estimate rather than a measured run. The 35–50-hour completionist target remains unverified because no full-clear human route has been timed.

## 32. Important asset-production decisions
### Asset-production decisions
Reference resolution: 1920 × 1080, with scalable UI and camera framing for different aspect ratios.

Character scale: Player approximately 25–30% of the visible room height, adjusted to match furniture.

Art format: Layered high-resolution PNG exports for painted assets, with editable source files retained separately.

Editable source packages are kept under `art_sources/`, outside Godot's runtime import tree. The Tea Corner's OpenRaster source preserves its exact-split 1600×900 architecture, exterior parallax, and night-sky layers plus the merged plate, with a byte-integrity validator. This reconstructed stack is not the original painting-session file; original layered masters for the other painted locations are still missing.

Animation: Frame-by-frame animation for expressive actions, supplemented by Godot transforms and shaders for subtle environmental motion.

Lighting: Painted base lighting plus selective dynamic 2D lights, rather than trying to recreate the entire atmosphere through real-time lighting.

Typography: Custom Moonmart logo lettering and a licensed rounded font for interface text.

Asset consistency: Every new character and environment must be checked against the original reference image for proportions, palette, texture, and lighting.
## 33. The next production milestone — implementation delivered; source-art dependencies and release review open
The latest full headless sweep passed all 29 scripts with empty stderr (`godot_task_state/p3_section27_audio_followup/summary.csv`); the GPU-backed Spanish runtime-locale smoke passed 98 checks and covered all 37 essential story summaries in the production message panel. Its review rendered the Spanish runtime screens and UI scale variants. The Section 27/28 gate passes in Windows PowerShell 5 and PowerShell 7.
The Section 33 implementation pass covers its narrative, visitor, systems, and asset targets. The full narrative and visitor roster, adaptive music and radio, recipes, investigations, furniture, raster artwork, layered environments, and animation integration are delivered. The 216-check end-to-end campaign, 55-check adaptive-audio suite, and Section 27/28 art validator pass. The Reading Nook and Enchanted Greenhouse scenes and plates are included. The ten-location headless travel/scale smoke verifies that every destination retains its intact, full-color environment plate, and the smoke passes. `tools/run_headless_suite.ps1` reproduces the full 29-script headless sweep with isolated app-data and per-test logs; the most recent 2026-11-13 run passed all 29 scripts with exit code 0 and empty stderr (`godot_task_state/p3_section27_audio_followup/summary.csv`), including physical stock carry/save coverage, map travel through the final page after all optional rooms unlock, and an essential visitor retry across closing, committed save/load, and the next shift. Checkout packing (92), checkout recommendation (22), recipe catalog (902), and controller binding labels (3) also pass. A clean GPU-backed sweep renders all ten locations and caught outdoor-to-outdoor shop-layer leakage, Tea Corner's undersized native 1600×900 layer stack and offset weather anchors, and the exploration HUD's stale Moonmart welcome caption. The pause menu moves keyboard focus into its controls and restores the previous visible control on close, with a distinct focus ring. Control rebinding now rejects duplicate keyboard/gamepad inputs, names the conflicting action in the localized notice, and preserves the old mapping. The HUD clock no longer shares a row with the shop tagline; dialogue now retains enough vertical space for its nine-patch frame and hint. Static composition review covers all ten locations; story-state presentation and hands-on input review remain open. Section 31 P3 release polish remains open for in-game story/audio presentation, Spanish fit and readability review, controller and focus-contrast review, and target-device profiling. Sections 27–28 remain the visual acceptance gates, with Section 27 as the highest-priority art rule: every dynamic light and effect stays independent of the environment plates. The painted raster style follows `art_import/`.

The latest persistence follow-up stores the player's last position in each visited location, restores it on load and travel, clamps it to that room's safe bounds, and keeps older saves on their existing spawn behavior. A late-campaign save failure caused by integer-valued JSON numbers in the Spirit Sense guard is fixed; `save_now()` reports commit success, and the campaign now verifies Keeper, Open Door, and Gentle Goodbye through save/load and sandbox continuation. Failed commits show a localized notice, and Save/Continue or Save/Quit keeps the session open until a commit succeeds. The most recent 29-script rerun passed with 216 story checks across all 37 essential events, plus 98 GPU-backed Spanish runtime-localization/layout checks and focus restoration (`godot_task_state/p3_section27_audio_followup/summary.csv`); the Section 27/28 gate passed for all 17 reviewed environment plates, 89 hash-bound raster assets, and 73 paired previews. The art gate now also passes in both Windows PowerShell 5 and PowerShell 7, so local Windows installs can run the same Section 27/28 acceptance checks.

Save validation now normalizes whole-number Spirit Sense shifts parsed from JSON while rejecting fractional values, preventing valid late-campaign state from leaving a stale save behind. The 216-check story playthrough now exercises Keeper, Open Door, and Gentle Goodbye through public ending selection, world/epilogue state, committed save/load, and sandbox shift restoration (`godot_task_state/ending_integration_verified/story_playthrough.log`).

After that full sweep, the main-scene smoke was rerun with the location-NPC animation update: outdoor Agnes uses her standalone talk pose, the Conductor uses his offer-ticket pose, and Wren's separate cast gesture remains suppressed by reduced animation. The smoke passed with zero failed assertions and empty stderr.

The first-room subset meets the Section 28 quantity target with 150 unique visuals, including its initial 36 product icons. The broader catalog now meets Section 17's lower bound with 150 product definitions and 100 unique icon visuals: 32 campaign additions in two 4 × 4 atlases and 32 additional pantry goods in two more 4 × 4 atlases; 50 craft-only outputs reuse close-match icons. The recipe book has 50 reachable recipes across six station-filtered preparation stations. Five one-time accomplishment milestones now reward each of the five proficiencies for varied actions across the game. Stock and backroom panels display the selected product icon; checkout uses the same atlas routing. Crafting puts output into backroom storage, then normal restocking and checkout sell it with freshness and capacity rules. Transparent furniture, product, plant, UI, and structural atlases use documented integer cells and dark/light previews. Pixel-only alpha repairs cleared low-opacity red/magenta fringe from the structural atlas and room window panes without altering painted artwork. The structural atlas remains catalog-only because the finished shop is not designed for its duplicate window, sign, doorway, and trim modules.

The optional night-event pool now has 100 data-driven entries, including weather, stock, relationship, seasonal, and story-gated moments. Existing shift gates use the event director's `min_shift` field. The receipt-whispers anomaly now offers an optional register investigation, a one-time Moon Token reward, and a saved resolution marker; ignored encounters remain eligible to return.

Forty-four ordinary visitor archetypes now add optional everyday shoppers through a separate data file. Each has its own basket, product preferences, schedule, weather preferences, and name pool; they use the generic customer art and do not enter story or relationship progression. The scheduler caps these visitors at two per shift.

Four named visitor pairs—Agnes/Lucien, Agnes/Fern, Fern/Wren, and Lucien/Mara—now have optional shared shop conversations when both are present and available. Agnes and Lucien's four alternating dialogue turns surface one at a time, resume their saved turn after a three-shift cooldown, and yield to the existing character route whenever either visitor is essential or the pair is unavailable.

Lucien can also comment on the Midnight Storybook while it is displayed. This stock-dependent conversation is routed after his story-flag dialogue so existing narrative beats keep priority.

Exploration now has a separate six-item keepsake collection across Moonmart and the five core districts. Inspecting each authored target discovers its keepsake once; stable IDs persist in save data and discovered names and descriptions appear in the midnight journal. The keepsakes are distinct from mystery clues and do not change chapter or story gates.

Recipe experimentation adds an explicit, save-backed cookbook discovery layer to all six preparation stations. The recipe panel lets players assemble ingredient combinations using paged controls, previews available quantities, preserves the existing shift/story gates, and only consumes stock for a successful exact match. Newly discovered recipes appear in the journal; older saves migrate their previously available recipes without losing access.

Small static, nonessential 1×1 decorations now support continuous mouse placement and fine keyboard/controller nudging within protected grid footprints. Large furniture remains grid-assisted, and route validation still uses saved occupancy cells.

The six low-pressure housekeeping actions cover every Section 3.4 task. Refill the dispenser adds four cleanliness points plus the existing Stewardship rank bonus, is available once per shift, and has localized EN/ES action and completion text.

Three placed décor examples now have data-driven gameplay effects: Moon Lantern increases optional supernatural arrival odds on clear nights and adds a point light under `SeparateLightingLayer`, Reading Chair extends optional customer lingering, and Moon Jasmine offers a saved one-time note through the normal interaction and inspect controls. The light reuses the runtime soft-light texture, follows the furniture attachment point, and respects the dynamic-lighting setting. All three use the existing raster furniture art and leave environment plates and VFX unchanged.

Seasonal merchandise now marks its matching season in the stock panel while remaining orderable year-round. Fifteen orderable products carry season tags, with at least three goods represented in each season. Eight optional ordinary visitor archetypes gain seasonal browsing preferences, two per season; preferences affect only optional visitor odds and browsing when matching merchandise is displayed, and never gate essential story baskets.

Eight optional ordinary visitors now also have data-driven demand variants across all four seasons and four weather conditions. A variant replaces one existing basket item only when its replacement is already displayed, keeps the basket size stable, and leaves fixed retail prices and essential customer baskets unchanged.

The recurring named-character roster now meets the lower target at 25, with dedicated raster sheets for all named visitors: the eight core town characters; Hollis Quince, Anouk Harrow, Oda Lovell, Miriam Underwood, Iona Pebble, Tomas Wicks, Liora Fenwick, Nella Finch, Maribel Frost, Aster Rowe, Rowan Pike, Stellan Rusk, Elowen Charter, Sabine Kersey, Juniper Hale, and Beckett Shore; plus Pip's companion sheet. The 50 ordinary shopper archetypes continue using the generic customer atlas. Hollis's transparent 4×1 idle/walk/talk atlas uses integer 543×724 cells, a centered pivot, 0.30 runtime scale, and a consistent visible footline at 93.4–94.5% of cell height. The other named-townsperson sheets use the same transparent 4×1 cells and pose order, rendered at 0.28 scale to match visitor height and footline. Their integrated identifying props are separately described in the raster asset README. All these sheets contain no environmental lighting or VFX.

The investigation catalog now has fifteen cases (Section 17 target 12–15), including the optional Moonwater Harbour mystery “A Small Wish for Safe Returns.” Its three clues use existing harbour interactables and award a nonessential memory flag. Three further optional cases deepen the world without touching the endings: “The Boats That Leave After Midnight” (harbour, chapter 3, after the Long Midnight is explained), “The Paths That Rearrange Themselves” (Whisperwood, chapter 3, after the silence is understood) and “The Drawer Marked Unclaimed” (new Old Bellwether archive marker, chapter 4, tied to the Conductor and Osric arcs and echoing Juniper, Maribel, and Tomas). Each has three clues, two conclusive hypotheses plus a gentle inconclusive one, nonessential result flags, and English and Spanish text (UI catalog now 1,499 keys).

Twenty optional character mini-arcs add 60 conversations across the named cast. They use existing dialogue routes and relationship memories without changing the main quest gates.

The shop has a room-architecture PNG with sixteen transparent window panes, a separate night sky and Bellwether parallax, and independent moon lighting, rain, seasonal, story-memory, and kettle-steam effects. Pixel-only alpha repairs cleared near-transparent red/magenta residue from the window panes and structural cutouts. A 12-piece structural atlas adds door, window, trim, awning, curtain, and threshold modules. It remains catalog-only because the finished shop plate already contains matching window, sign, doorway, and trim artwork; place the modules in a location composed around them. Named scene layers keep the architecture, sky, parallax, window effects, lighting, furniture, characters, prop effects, and HUD controllable on their own. No light rays, particles, or weather are baked into the architecture or district backgrounds.

The pack includes modular furniture atlases plus twelve additional furniture modules; fourteen 16-piece placeable furniture/decor atlases with 224 isolated props; an isolated kettle and shop sign; potted moonflower (`assets/raster/furniture/potted_moonflower.png`); a placeable crescent wall sconce (`assets/raster/furniture/crescent_wall_sconce.png`); two 16-piece placeable plant atlases (`assets/raster/furniture/moonmart_plant_decor_atlas.png`, `assets/raster/furniture/moonmart_plant_decor_atlas_2.png`); 279 unique furniture and decor definitions; 100 product icons; four player facings with action poses; the 25-character recurring cast, including dedicated raster sheets for the core town characters; and 44 data-driven ordinary visitor archetypes; five isolated story props; and a painted UI kit with 24 icon sprites across two atlases. All 29 character atlases and four effect atlases have paired dark-plum and warm-cream QA previews. Five district scenes plus the backroom, hidden story room, Tea Corner, Reading Nook, and Enchanted Greenhouse use raster environment plates. Tea Corner uses separate sky/parallax/architecture layers, prep-station art, a reading seat, a moonflower, and a no-pressure stock browsing interaction. The Reading Nook and Greenhouse keep their room architecture, furnishings, decoration layer, interaction markers, and lighting/effect nodes separate.

Furniture definitions record atlas cells, visual anchors, collision footprints, interaction positions, display/storage capacity, states, and lighting attachments. Small nonessential 1×1 decorations support bounded sub-cell visual nudges while their saved occupancy and route protections remain grid-based. Retail-floor, backroom, Reading Nook, and Enchanted Greenhouse decorations persist as independent room layouts, render on their own furniture layers, and block player movement and protected work areas. `assets/raster/README.md` and `assets/raster/asset_manifest.json` document the delivery and conventions. The assembled scene supports player movement with fixed and placeable furniture blocking, edge sliding, and camera tracking; customer grid routes avoid the same static and placed obstacles and refresh after layout changes. It also supports browsing, checkout, lingering, customer conversations, animated characters, and independently controlled visual effects alongside the existing story and shop systems. Supplier deliveries enter backroom storage; individual units use the saved physical carry loop and persistent carry pose to reach matching displays, with trolley bulk restocking and opt-in automatic stocking preserved; perishable lots age between shifts, and the ledger supports markdowns, donations, and refunds. Optional environmental puzzles load from data, open at their target objects, accept player answers, reveal hints, and persist solved state. District runtime scenes keep named lighting independent, while weather, story, and foreground effect layers render above the intact raster plates; sky and parallax underlays sit behind the full plate and show only through transparent or composed artwork.


## 34. Authoritative implementation rules

These rules form Moonmart's implementation baseline.

### 1. Source of truth

Locked creative decisions and the reconciled implementation rules govern development.

Narrative progression controls essential content.

Prototype-specific overrides apply only to the prototype.

Illustrative examples must not override authoritative specifications.

### 2. Narrative guarantees

Essential visitors, locations, investigations, abilities, and chapter progression must always remain obtainable.

Optional reputation, relationships, proficiency, and Midnight Harmony cannot permanently block the main story.

### 3. Scheduling

Essential story events use persistent quest scheduling.

Missed essential events must be rescheduled.

Ordinary NPC visits continue to use weighted schedules.

### 4. Shop operation

Early closing is permitted after mandatory responsibilities are completed.

The minimum open-service period is configurable in `data/balance/timing.json`; early closing is unavailable until the player has met it.

Unfinished narrative obligations carry forward without permanent punishment.

There is no bankruptcy, permadeath, or mandatory timed failure.

### 5. Time

The standard shift lasts 360 simulated minutes at a default rate of 14.4 simulated minutes per real minute.

The five-night vertical slice uses separate compressed timing.

All timing and balancing values should be externally configurable.

### 6. Economy

Coins and Moon Tokens are the only persistent spendable currencies.

Special supernatural exchanges are narrative or inventory transactions, not additional currencies.

### 7. World and endings

All three endings support continued sandbox play.

Epilogue content must respect the chosen ending.

The Gentle Goodbye permanently closes the original doorway in that save's epilogue.

The Gentle Goodbye records data-driven alternatives only for Between locations whose prerequisite story flags and required physical inspections were completed before the ending. The Midnight Platform memory requires inspecting the platform and reading its manifest; Conductor events at Moonmart alone do not qualify. Those memory snapshots persist in the narrative save, appear in the Journal, and provide an explicit read route when an associated doorway is closed. Legacy ending saves may reconstruct snapshots only from qualifying saved flags; missing prerequisites must remain unrecorded. Do not claim an unavailable activity has been preserved.

### 8. Navigation

Furniture placement must preserve access to essential interactions, exits, and shop facilities.

Navigation and collision validation are mandatory for layout changes.

The town map must keep every unlocked destination selectable when optional rooms expand the list beyond nine entries. Use localized page navigation and retain the existing numbered selection controls on each page.

### 9. Project architecture

The canonical project root is the repository root containing `project.godot`.

There must be one authoritative Godot project structure.

Gameplay systems should remain modular and data-driven.

### 10. Asset references

Temporary browser blob URLs are not valid asset references.

Use repository-relative asset paths.

Missing artwork must be identified rather than silently replaced or fabricated.

### 11. Testing requirements

Automated tests should cover:
- Essential narrative unlocks
- Missed customer encounters
- Inventory transactions
- Currency consistency
- Shift timing and early closing
- Furniture navigation
- Save/load and migration
- Ending-specific epilogue states

### 12. Implementation precedence

When specifications disagree, use this order:

1. Locked creative decisions
2. Authoritative implementation rules
3. Specific narrative and progression requirements
4. System specifications
5. Illustrative examples and prototype demonstrations

Any unresolved conflict must be documented before implementation rather than silently interpreted.
