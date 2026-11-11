# Asset catalog

All prototype images exist as both `assets/svg/...` and `assets/png/...`.

## Background / environment
`env/sky`, `env/treeline`, `env/wall`, `env/floor`, `env/window`, `env/arch`, `env/plant`, `env/lamp`, `env/star_lamp`.

## Furniture
`furniture/shelf`, `furniture/fridge`, `furniture/counter`, `furniture/register`, `furniture/display`, `furniture/door`, `furniture/coffee`, `furniture/box`.

## Characters
`characters/player`, `characters/player_walk_0..3`, `characters/agnes`, `characters/fern`, `characters/lucien`, `characters/wren`, `characters/pip`, `characters/miso`.

## Planned production replacements
- Layered 2200px-wide shop architecture with separate windows and weather layers.
- Front/back/side turnarounds and consistent animation frames for all characters.
- Proper customer navigation and queue markers.
- Product icons, held-item sprites and shelf slots.
- Font family selection, Moonmart custom wordmark, 9-slice UI panels.
- Lighting masks, steam, dust motes, weather, ghost glow.
- Room transition props and the complete backroom.

## Collision and anchors
World baseline y≈700. Player visual anchor is centre of feet. Furniture sprite positions are currently illustrative; production furniture needs explicit `StaticBody2D` footprints and interaction markers. See `docs/BACKLOG.md`.
