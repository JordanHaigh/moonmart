# Moonmart — Asset Production Plan

## Visual source of truth
Original supplied art is canonical. Latest full-room gameplay illustration establishes layout, not a directly usable sprite sheet. The concept art is a reference, not automatically segmented into collision-ready assets. Avoid pixel art, 3D look, harsh outlines, and overly busy HUD. Rounded handwritten typography is a target; no font file or exact font license has been established.

## Deliverable conventions
Editable source + transparent PNG exports for interactive items; layered background exports for scenery. Pivot at feet for characters, bottom-center for floor furniture. Define collision footprint, interaction anchor, y-sort origin, optional emissive overlay and animation state. Use descriptive lowercase snake_case IDs.

## Retail room
Architecture: wall modules, floor, trim, windows, arches, doors, ceiling, exterior sky/trees.
Furniture: register, counter, shelves, fridge, coffee station, display case, seating, boxes.
Decor: hanging ivy, potted plants, rugs, moon lamps, stars, bunting, chalkboards.
Products: milk, drinks, packaged foods, pastries, books, magical items.
VFX: ghost glow, steam, particles, light cones, moonbeams, subtle rain.
UI: logo, clock, coin counter, objective panel, journal, map, prompts, dialogue.

## Character sheets
Player: idle, walk, carry, inspect, interact, talk, craft; left/right and 3/4 views.
Pip: idle float, blink, excited, sad, glow.
Miso: sleep, sit, walk, stretch, play, purr.
Agnes: idle, walk, talk, checkout, wave.
Fern: idle, walk, inspect plants, talk.
Lucien: idle, walk, read, drink, talk.
Wren: idle, walk, browse, cast small magic.
Background customers: idle, walk, browse, queue, purchase.

## Technical checklist
- Character height ~160–240 px in initial sprite targets; scale with scene reference.
- Consistent sprite canvas, anchor and animation timing per character.
- Each refrigerator: closed/open, stock display, lighting overlay, collision and interaction marker.
- Each shelf: reusable product display slots; no product assortment baked into shelf image.
- Each door: closed/open, navigation exit, destination and spawn marker.
- Text: custom Moonmart logo lettering, licensed rounded font for headings and body.
- Preserve original references unmodified alongside derived assets.

## Prototype status
Current repository contains a procedural playable placeholder and design documentation. The earlier locally generated PNG/SVG prototype asset pack and original concept images require separate binary transfer into GitHub. Do not present them as committed until verified.
