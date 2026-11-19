# Narrative music overlay

`remembered_threshold.wav` is an original, no-vocal 32-second music layer for quiet mixing under Moonmart's location scores. Its open, warm harmony and sparse rounded tones suggest a remembered doorway gradually feeling safe. It stays deliberately restrained so it can be mixed at a low level without crowding the location music.

The loop is 44.1 kHz, stereo, 16-bit PCM. The first and final stereo frames are exactly silent. The music is synthesized deterministically from tones and envelopes, with no third-party samples.

Rebuild the audio and metadata from the repository root:

```powershell
& .\tools\build_moonmart_narrative_overlay.ps1
```

[`metadata.json`](metadata.json) records the track ID, format, duration, arrangement, peak level, and file size.
