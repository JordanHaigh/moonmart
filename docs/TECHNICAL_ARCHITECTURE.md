# Godot 4 Architecture & Gameplay Contracts

## Domain boundaries
GameState: flags, player progression, global events.
TimeManager: in-game time, shift phases, pause-token ownership.
WorldManager: rooms, doors, spawn points, district unlocks.
ShopManager: reputation, layout, open/close, shelf assignments.
InventoryManager: stock and reservations with atomic transactions.
CustomerManager: arrivals, schedules, AI state and queues.
EconomyManager: coins, Moon Tokens, price calculation and ledger.
CraftingManager: recipes, ingredients, stations and outputs.
DialogueManager: conditional conversations and effects.
RelationshipManager: stages, memories, preferences, milestones.
QuestManager: objectives, prerequisites, completion and rewards.
MysteryManager: evidence, hypotheses, deduction state.
EventDirector: weighted event eligibility, cooldowns and priority.
DecorationManager: placement, collisions, persistence and effects.
SaveManager: versioned snapshots and migrations.
AudioManager: ambience, location/music transitions, SFX.

## Player interaction
Actions: move_left, move_right, depth_up, depth_down, interact, inspect, sprint, inventory, journal, map, pause. Target selection: interactability → distance → facing → priority → stable entity ID. Single contextual prompt. UI does not monopolize scene during ordinary play.

## Player state
IDLE ↔ MOVING → INTERACTING → DIALOGUE/MINIGAME/MENU → IDLE. Dialogue is an overlay while characters remain in-world. Interactions can be canceled where safe.

## Customer FSM
SCHEDULED → ARRIVING → BROWSING → QUEUING → CHECKOUT → LEAVING → DESPAWNED, with optional LINGERING, CONVERSING and EVENT_LOCKED. NavigationAgent2D approaches marked interaction anchors. CharacterBody2D handles movement and collision. Queue slots reserved deterministically.

## Time
Shift from 23:30 to 05:30 (360 simulated minutes). Default 14.4 game minutes per real minute, subject to playtesting. Opening at 00:00, closing at 05:30. Important events queued, not discarded if clock jumps. Pause tokens avoid accidental unpause.

## Transaction invariants
A sale either removes all items and credits payment or does neither. Stock cannot be negative. Product IDs stable. Refunds reverse an existing transaction exactly once. All money movements logged with reason and timestamp.

## Narrative invariants
Story flags have stable IDs and explicit prerequisites. Mandatory content cannot be permanently missed by clock/season. A failed deduction offers alternate clue paths. NPC relationship state does not depend on scene instances.

## Saving
Save JSON in user:// with schema_version, shift, time, coins, tokens, inventory, shop layout, unlocked locations, character memories, quest states, evidence, event cooldowns and RNG seed. Atomic write via temporary file and replace; maintain backup. Validate migration on load. Never serialize transient nodes/animations as authority.

## Godot conventions
Use typed GDScript; scene resources for visual composition; validated external JSON or custom Resources for authored content; autoload only core managers. Use signals for notifications, explicit calls for commands. Keep systems testable without rendering. Reference design resolution 1920×1080, responsive UI.

## Visual layering
Sky → exterior parallax → architecture → back furniture → walkable floor → y-sorted characters and interactables → foreground furniture/foliage → atmosphere → HUD. Do not bake UI or NPCs into room paintings.

## Testing
Unit: inventory transactions, currency, recipe costs, eligibility predicates, relationship thresholds, event repeat limits, save migrations.
Integration: customer browse-to-sale; dialogue-to-quest flag; shift close-to-next day; room travel and saved layout; investigation completion.
Acceptance: five-night vertical slice can be played with keyboard/controller and restored from a midshift save.
