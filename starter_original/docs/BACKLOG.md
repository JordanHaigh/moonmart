# Moonmart — Prioritized Godot 4 Backlog

## P0 — Prototype stabilization
- MM-001 Import project in installed Godot 4; resolve parser/import errors; add CI headless launch check.
- MM-002 Replace raw key polling with named Input Map actions and gamepad bindings.
- MM-003 Implement proper `CharacterBody2D` player and static collision for furniture.
- MM-004 Add `NavigationRegion2D` and `NavigationAgent2D` for customers.
- MM-005 Add deterministic queue slots and customer checkout state machine.
- MM-006 Replace placeholder time formatting with 11:30 PM → 5:30 AM clock.
- MM-007 Add save versioning, schema validation, backup and migration tests.
- MM-008 Add inventory transactions with nonnegative stock and atomic sales.
- MM-009 Implement data-driven interactions instead of match branches.
- MM-010 Build real shop ledger and dialogue UI with licensed font.

## P1 — First playable five-night slice
- MM-011 Script Night 1 tutorial, Agnes dialogue and Miso interaction.
- MM-012 Script Night 2 Pip visit and milk order.
- MM-013 Script Night 3 old receipt and ledger.
- MM-014 Script Night 4 clue linking and deduction board.
- MM-015 Script Night 5 memory scene and hidden door.
- MM-016 Add persistent dialogue and quest flags with conditional triggers.
- MM-017 Create finished player turnaround and walk/idle animation set.
- MM-018 Create finished Pip, Miso and Agnes animation sets.
- MM-019 Replace prototype architecture with layered hand-painted room assets.
- MM-020 Add soundscape, soft ambient music and interaction SFX.
- MM-021 Implement customer product selection and visible carried items.
- MM-022 Add accessibility: text scale, reduced motion, input rebinding.

## P2 — Vertical slice polish
- MM-023 Add backroom scene, doors and transition persistence.
- MM-024 Add drink preparation station and recipe definitions.
- MM-025 Implement furniture placement, grid snapping and decoration save.
- MM-026 Add day/weather backdrop and seasonal ambience.
- MM-027 Add relationship memory flags and five-stage bond progression.
- MM-028 Add weighted event director and anti-repeat cooldowns.
- MM-029 Add Miso companion states and spirit-sense interaction.
- MM-030 Add dynamic light overlays, moonbeams, plant sway, ghost glow.
- MM-031 Add tutorial prompts and contextual quest tracker.
- MM-032 Add story regression tests for missable events.

## P3 — Full-game expansion
- MM-033 Add Whisperwood and Moonwater Harbour.
- MM-034 Add Old Bellwether and Midnight Platform.
- MM-035 Add Lighthouse and the Between sequences.
- MM-036 Implement chapters 2–6 and three endings.
- MM-037 Implement shop room expansion unlocks.
- MM-038 Add seasonal events, products and decorations.
- MM-039 Add 25+ named NPCs and complete character story arcs.
- MM-040 Add localization pipeline and controller certification pass.

## Definition of done
Each ticket requires documented acceptance criteria, reproducible test steps, no broken save data, and visual review against the canonical original illustration. Art assets require transparent export, source master, dimensions, pivots and asset ID.
