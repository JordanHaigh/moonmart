# Location ambience loops

These four original synthesized ambience beds are separate from Moonmart's location music and visual layers. Each is a 32-second stereo loop at 44.1 kHz, 16-bit PCM. They use deterministic filtered noise, simple oscillators, and envelopes only; there are no third-party samples, music, or visual effects. Their restrained peaks leave room for the music layer.

| ID | File | Sound palette |
| --- | --- | --- |
| `bellwether_night` | `bellwether_night.wav` | Soft distant town air, low filtered texture, slow far-off tonal swells. |
| `whisperwood_night` | `whisperwood_night.wav` | Filtered leaf-like rustle with rare, delicate two-note night-bird calls. |
| `moonwater_harbour` | `moonwater_harbour.wav` | Gentle rolling water texture, occasional soft rope resonance, distant buoy tones. |
| `midnight_air` | `midnight_air.wav` | Very soft, slowly evolving airy texture without a pulse, impacts, or ominous tones. |

All tracks have an exact silent first and final stereo frame for a clean loop seam. [`metadata.json`](metadata.json) records each track's peak level, byte size, and SHA-256 hash as well as the audio format.

Rebuild the WAVs and metadata from the repository root:

```powershell
& .\tools\build_moonmart_location_ambience.ps1
```
