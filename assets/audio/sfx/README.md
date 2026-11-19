# Moonmart original sound effects

The four short effects in this directory are authored from reproducible inharmonic resonator synthesis by `tools/build_moonmart_sfx.ps1`; no third-party recordings or samples are used. The script writes 44.1 kHz, 16-bit stereo PCM WAV files with struck bell/glass modal partials, damped envelopes, and short early reflections. It also emits a static metadata report with sample rate, channel count, duration, peak target, and file size.

`data/audio_sfx.json` defines the event routing and per-effect levels. `scripts/systems/sfx_manager.gd` loads that catalog and exposes `play_door_bell()`, `play_threshold_door_bell()`, `play_register_chime()`, `play_story_reveal()`, and `play_sfx(id)`. The threshold door bell keeps the familiar two-strike rhythm, with a quiet low resonance and slight detune at 8 dB below the ordinary bell. Missing files, events, or the SFX bus do not crash the game; the manager falls back to the Master bus or returns `false` silently.

Runtime hooks in `scripts/main.gd`:

- Door bell: when a visitor arrival is accepted in Moonmart. Rebuilding visitors from an already-open saved shift suppresses the sound.
- Threshold door bell: replaces the ordinary chime for Moonmart arrivals only while Pip's reflection is missing and the boundary remains unresolved; the ordinary bell returns after stabilization or an ending.
- Register chime: once after a checkout transaction commits successfully.
- Story reveal: when the game emits a committed story event, rather than on repeated dialogue updates.

Effects use the SFX bus, so the player's independent sound-effects volume setting controls them. Keep the story reveal attached to committed story events only.
