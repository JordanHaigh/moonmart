# Moonmart location scores

These four original, quiet location themes provide a calm bed for the non-shop scenes. Each file is a 32-second seamless loop in stereo, 44.1 kHz, 16-bit PCM WAV. The arrangements are generated from synthesized tones and envelopes; they use no samples and contain no baked-in ambience or sound effects.

| Track ID | File | Character |
| --- | --- | --- |
| `old_bellwether` | `old_bellwether.wav` | Warm, measured felt-piano-like harmony with gentle plucks and a faint brushed texture. |
| `whisperwood` | `whisperwood.wav` | Airy, open harmony with sparse high bell tones and no percussion. |
| `harbour_lighthouse` | `harbour_lighthouse.wav` | Soft coastal harmony with plucked notes and a restrained brushed pulse. |
| `midnight_between` | `midnight_between.wav` | Sparse suspended chords and distant glassy tones, without percussion. |

The source of truth is [`location_metadata.json`](location_metadata.json), which records format, loop duration, arrangement notes, file sizes, and generated peak levels. Rebuild all WAVs and metadata from the repository root with:

```powershell
& .\tools\build_moonmart_location_music.ps1
```

The same build creates sixteen matched rain, fog, wind, and snow variants, one for each of the four score themes. `weather_variants.json` records their locations, arrangements, loop lengths, peak levels, and sizes. Outdoor location scores select the current shift's weather variant and crossfade over two seconds when the player travels or a new shift changes the weather; backroom and Tea Corner retain their sheltered Window Seat theme. Weather variants in the same score family stay phase-aligned during a transition, while a different location theme begins at the start of its musical phrase. Rain-on-window sound remains a separate ambience layer.

The generator uses PowerShell and the .NET runtime only. The resulting WAVs have distinct SHA-256 hashes, and the first and last stereo frames are silent to keep the loop seam clean.
