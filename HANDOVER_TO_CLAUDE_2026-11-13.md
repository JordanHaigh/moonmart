# Moonmart handover to Claude

**Date:** 2026-11-13 (Australia/Sydney)  
**Workspace:** `C:\devel\moonmart`  
**Goal status:** Paused at the user's request because they are out of credits. The game is not complete; preserve the full objective and continue only when the user resumes or directs Claude to take over.

## Objective

Build the full Moonmart game according to `Moonmart.md`, expanding the current vertical slice across its systems, narrative, world, art and playable content. The user explicitly emphasized Sections 27 and 28: dynamic light rays, particles, weather and story effects must remain separate from environment plates. Art should match `art_import/` in quality; do not substitute placeholder or low-quality SVG art.

## Current state

- Most of the documented game systems and content are implemented. `Moonmart.md` is the design and production-status source of truth; Sections 31 and 33 still identify release and visual-acceptance work as open.
- Section 27/28 validation last passed for **17 reviewed environment plates, 89 hash-bound raster assets and 73 paired previews** in both Windows PowerShell 5 and PowerShell 7. The gate also validates separated light/effect layer contracts and raster references, but cannot inspect painted pixels by itself.
- The Section 27/28 prose says the environment plates remain unchanged and no dynamic rays, particles, weather or story VFX are baked in. Keep that invariant.
- The visual audit of the seven current `art_import/` PNGs found composed screenshots/concept sheets; Tea Corner is the only editable layered environment source. There are no clean matching layers for the five opaque outdoor plates, approved fog raster or separated lighthouse beam. Previous fog/parallax probes failed review and are QA-only. Do not extract effects from the flattened screenshots or add mismatched art. The safest way to complete those art gaps is to obtain the original layered masters or location-matched transparent layers with adequate underpaint/overscan.
- The full headless suite passed **29/29**, with empty stderr, at `godot_task_state/p3_section27_audio_followup/summary.csv`.
- The GPU-backed Spanish runtime review passed **98 checks**. All 37 Spanish essential story summaries went through the production message panel and were checked for rendered line-height fit and on-screen panel bounds. Captures are in `godot_task_state/localization_runtime_review_20261113_02/`.
- Resting Miso purr now follows the Music ambience level; a care-triggered purr follows Effects. The adaptive-audio assertions cover both routes.
- The user's pause request was honored. A process check found no running Godot process; no profile job is active.

## Gameplay profile work

Two of three planned local gameplay-profile runs completed. They used Godot 4.7.2, a Ryzen 5 9600X, RTX 4070, OpenGL Compatibility, 1600×900, a fixed 60 FPS cap, normal system audio, rainy active shift, movement, four in-memory visitors, dialogue/journal UI, and fresh isolated app-data directories. The driver avoids `begin_shift()`, checkout and save calls, and reports whether an unexpected save appeared.

- Run 1: `godot_task_state/profile_gameplay_20261113/run_01/phase_summary.csv`. Active rainy visitor phase: P99 frame interval **16.889 ms**, max **18.963 ms**. UI phase max: **50.166 ms**.
- Run 2: `godot_task_state/profile_gameplay_20261113/run_02/phase_summary.csv`. Active rainy visitor phase: P99 **16.911 ms**, with one **623.451 ms** maximum outlier. Preserve and investigate this outlier; do not hide it behind percentiles.
- `run_03` in that folder was interrupted and has only the baseline summary. A retry at `godot_task_state/profile_gameplay_20261113_retry/run_01/` was also stopped before measured phases completed. Neither is a valid full run.
- `tools/run_gameplay_profile.ps1` and `tests/performance/profile_gameplay.gd` implement the runner and fixture. There are short smoke-run artifacts under `godot_task_state/profile_gameplay_smoke*/`; those validate the driver, not the full performance requirement.
- These are local comparative results, not release-target sign-off. The release device is unspecified. The user asked to stop while out of credits, so do not start another long profile until asked to resume.

## Remaining documented release work

1. Source-dependent Section 27/28 art: separated outdoor scenery/underpaint, approved fog, and a matching lighthouse-beam layer. Preserve the plates while those sources are unavailable.
2. Hands-on story/audio presentation and controller/focus review. Automated accessibility checks passed, but they do not replace this review.
3. Target-device gameplay profiling and audio playback/memory review. The two valid local runs are useful baseline evidence only.
4. Full-play and completionist pacing verification remains an estimate, not a timed human playthrough.

## Relevant files

- `Moonmart.md` — full game specification and current production status. Sections 27/28 define the critical art constraints; Sections 31/33 track release/milestone gaps.
- `tools/validate_section27.ps1` — Section 27/28 raster, hash, and layer gate.
- `tools/run_headless_suite.ps1` — isolated full headless suite runner.
- `tools/run_gameplay_profile.ps1`, `tests/performance/profile_gameplay.gd` — local gameplay profiling harness.
- `tests/headless/test_localization_runtime.gd` — 98-check Spanish runtime UI/story fit review.
- `scripts/main.gd`, `tests/headless/test_adaptive_audio.gd` — Miso purr routing and assertions.
- `assets/raster/environment_visual_review.json`, `assets/raster/asset_visual_review.json`, `assets/raster/asset_manifest.json` — reviewed art records and runtime raster inventory.

## Worktree caution

The worktree already contains extensive modified, deleted and untracked project files. Do not run `git clean`, reset, or bulk-revert changes. Inspect the live tree before editing; prior notes are context, not a substitute for current evidence.

## Update, 2026-11-13 (Claude session)

- Run 2's 623 ms frame was analysed from the recorded artifacts: `godot_task_state/profile_gameplay_20261113/RUN_02_OUTLIER_ANALYSIS.md`. Process CPU dropped during the frame and private bytes rose 37 MiB for 3 s, so it was a wait, not script work. Cause unidentified.
- `tests/performance/profile_gameplay.gd` now writes `process_ms`/`draw_ms`/`rest_ms` per frame plus `stall_events.csv` and `fixture_events.csv`. Verified on Linux with Godot 4.7.2 (headless and software OpenGL); not yet run on the Windows GPU setup. `tools/run_gameplay_profile.ps1` is unchanged.
- No Windows Godot process was started. The third profile run is still outstanding.
- Fixture gap: all four visitors are queuing from 14.5 s of the active phase onward, so most of that phase measures a static queue.
