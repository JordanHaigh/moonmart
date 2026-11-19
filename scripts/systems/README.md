# Progression systems

These typed `RefCounted` managers are independent of the scene tree. The parent `MoonmartGame` can own them, forward their signals, and include each `export_state()` result in the save envelope. Definitions are passed in from validated JSON rows or authored resources.

| Class | Main API | Save API |
|---|---|---|
| `MoonmartRelationships` | `register_character`, `record_memory`, `advance_stage`, `remember_promise`, `resolve_promise`, `open_promises`, `all_open_promises` | `export_state` / `import_state` |
| `MoonmartNarrative` | `resolve_event`, `record_ending_memories`, `ending_memory_route`, `ending_memories_for_journal`, `read_ending_memory` | `to_save` / `from_save` |
| `MoonmartQuests` | `setup`, `begin_shift`, `accept`, `complete_objective`, `complete_quest`, `resolve_essential_encounter`, `note_visit_missed` | `export_state` / `import_state` |
| `MoonmartMysteries` | `setup`, `add_clue`, `pin_clue`, `available_solutions`, `submit_deduction`, `journal_lines` | `export_state` / `import_state` |
| `MoonmartWorld` | `setup`, `set_story_flag`, `unlock_optional`, `travel_to`, `choose_ending`, `continue_sandbox` | `export_state` / `import_state` |
| `MoonmartDecorations` | `setup`, `set_access_point`, `can_place`, `place`, `move`, `remove`, `supports_free_visual_placement`, `set_visual_offset`, `visual_position_in_cells`, `visual_offset_in_cells`, `effects_for_instance`, `effect_for_instance`, `active_effects`, `navigation_is_valid` | `export_state` / `import_state` |
| `MoonmartEventDirector` | `setup`, `queue_essential`, `begin_shift`, `resolve_essential`, `miss_essential`, `optional_context_hint` | `export_state` / `import_state` |
| `MoonmartCalendar` | `setup`, `set_current_shift`, `current_date`, `current_season`, `current_weather`, `current_festival`, `next_festival_shift` | `export_state` / `import_state` |

Quest definitions use stable IDs and can declare `essential`, `visitor_id`, `requires_flags`, `requires_quests`, `trigger` (`min_shift`, optional `max_shift` and context matches), `objectives`, `sets_flags`, and `rewards`. Essential encounters remain in the queue until explicitly resolved; missing one does not discard it.

Story-event rows may declare `creates_promises` and `resolves_promises`. The game records open promises in the relationship save state, displays them in the journal, and resolves them only when the authored outcome occurs. Promise resolution never gates an essential event. `MoonmartRelationships` owns relationship stage progression; the narrative manager keeps the richer journal-memory projection synchronized without advancing stages for each dialogue line.

Investigation hypotheses in `data/investigations.json` keep their primary `result_flag` and may add `grants_flags` for chapter or unlock milestones. A successful deduction propagates every granted flag to the narrative, quest, mystery, and world state; this lets an outcome satisfy a chapter gate without replacing the case's descriptive result flag. Submitting a theory without enough evidence returns a hint and leaves the investigation open.

Location rows can declare `essential`, `requires_flags`, `reputation_required`, and `requires_open_door`. `unlock_optional` rejects essential locations, so reputation cannot gate story access. Endings can only be committed after the final chapter and required explicit flags are complete; all endings remain sandboxable. `data/ending_memories.json` defines Gentle Goodbye alternatives and their required story flags and physical inspections. The Midnight Platform entry requires inspecting the platform and reading its manifest, in addition to the story milestones; Conductor events at Moonmart alone are insufficient. Qualifying entries are snapshotted into the narrative save at ending selection, shown and readable from the Journal, and used as blocked-activity routes only when that saved entry exists. Legacy saves can reconstruct missing snapshots only from qualifying saved flags; absent prerequisites remain absent.

Decoration furniture rows use a stable `id`, a grid `footprint` (`Vector2i` or a two-number array), and optional `essential`. Required access points identify the spawn, exit, register, and story hotspots. A placement is accepted only when it fits, avoids those hotspots, does not overlap another item, and leaves every required point path-connected. Layout coordinates export as JSON-safe integer arrays.

Optional event rows use `weight`, optional context `weight_rules`, `days`, `min_shift`, `max_shift`, `cooldown_shifts`, `max_uses`, `requires_flags`, `forbidden_flags`, `stock_categories`, `minimum_bond`, `visitor`, and `hint`. Seed and RNG state are saveable. Essential story events bypass weighted rolls and persist in their own queue.

The calendar reads `data/calendar.json`. Four seasons use configurable shift lengths and deterministic weighted weather. Festival dates recur every seasonal year; missing one never blocks story progress and the next occurrence can be queried for a gentle reminder.
