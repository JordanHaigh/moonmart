# Moonmart rain ambience

`moonmart_rain_window.wav` is an original, deterministic 32-second rain-on-glass ambience loop. It combines gently filtered noise with sparse, softly resonant synthesized droplets. It uses no third-party recordings.

The game plays it as a separate audio layer only during rainy Moonmart shifts. It follows the Music volume setting and does not depend on the rain-visual accessibility toggle. Keep rain audio and visual weather separate from every environment plate; the room artwork contains no weather effects.

The file is stereo, 44.1 kHz, 16-bit PCM, with a peak near -20 dBFS. A 120 ms cosine fade brings both ends to exact digital silence for a quiet loop boundary. The companion JSON records the technical metadata and SHA-256 checksum.

Rebuild it from the repository root with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/build_moonmart_rain_ambience.ps1
```

The generator uses only PowerShell and the .NET runtime.
