# Moonmart — Production Status

## In the repository
- Root Godot 4 project with a minimal procedural movement and shop interaction sketch (`project.godot`, `scenes/main.tscn`, `scripts/main.gd`).
- Preserved original starter project structure under `starter_original/`, including its project settings, scene, sprite-based prototype script and original starter data JSON files.
- Design, story, lore, art direction, character arcs, first five nights, technical contracts and prioritized backlog.
- Example content JSON in the root `data/` directory (characters, events, investigations, locations, products, quests and recipes).
- PowerShell helpers for importing the original starter archive and artwork archive.

## Still missing or unverified
- The original starter's artwork archive and its PNG/SVG assets, contact sheet, concept references and supplementary files. The restoration helper expects a ZIP containing `modular_assets/png/characters/player.png`; no such archive is present in this repository.
- Godot editor/runtime verification of either project. The procedural prototype is a code sketch; the original sprite-based starter expects the missing assets.
- Production-ready painted sprite sheets, complete playable five-night quest, customer AI and navigation.

## Next actions
1. Locate the original artwork ZIP and restore the verified assets into `starter_original/assets/` with `tools/restore_original_starter_assets.ps1`.
2. Open each project in Godot 4 and resolve parser, resource and interaction issues.
3. Choose which project is the active development base, then build out the playable foundation from `docs/BACKLOG.md`.
4. Add the layered shop scene and production character sprites, then implement inventory transactions, the customer FSM and the five-night narrative slice.

The import helpers currently stage, commit and push changes to `main`. Review their effects before using them in a workflow where a local-only import is intended.
