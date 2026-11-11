# Data-Driven Content Pipeline

Each content type lives in data/ and uses stable snake_case IDs. Parse and validate at startup; report missing references and duplicate IDs as actionable errors. Never let narrative content silently reference a missing product, character, location, clue or quest.

## Characters
id, name, type, portrait, animations, schedule, preferred_products, relationship stages, dialogue_tree, story_arc, event_tags, unlock_conditions.

## Products
id, name, category, price, purchase_cost, stack_limit, shelf_slots, perishability, magical_tags, unlock_conditions.

## Recipes
id, station, inputs, output, preparation_steps, unlock_conditions, character_preference_tags.

## Events
id, category, weight, eligible_hours, weather, prerequisites, cooldown_shifts, exclusive_group, actions, narrative_priority.

## Quests
id, chapter, prerequisites, objectives, dialogue_hooks, completion_effects, rewards, repeatable.

## Investigations
id, clues, hypotheses, valid_connections, alternate_hint_paths, conclusion_effects.

## Dialogue
id, speaker_id, lines, conditions, choices, effects. Choices may set flags or memories; no hardcoded dialogue in customer scripts.

## Validation
CI should verify JSON parse, uniqueness, referenced IDs, valid probability ranges, progression reachability, no softlocks, and save migration fixtures.
