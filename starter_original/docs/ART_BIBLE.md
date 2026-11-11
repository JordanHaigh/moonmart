# Moonmart — Art Bible v0.1

## Canonical references
- `references/original_style_reference.png`: canonical style, palette, mood, rounded shapes, painterly textures.
- `references/gameplay_reference.png`: canonical movement-gameplay composition and HUD direction.
- Other `references/` images: exploratory visual development, not authoritative production sprites.

## Palette
Night indigo #25243E; twilight violet #49446D; lavender #806587; dusty rose #C18B86; warm peach #F1B47D; moon cream #FFF0D8; foliage olive #7E9459.

## Character style
Rounded, softly shaded, friendly silhouettes. Player and named humans approximately 1.7–2 heads tall in gameplay; ghosts and pets even simpler. Avoid highly detailed anime faces or sharp line art. Preserve the gentle, rounded quality of the original sleeping cat and smiling lamp.

## Environmental style
Hand-painted storybook interiors with soft brush edges and atmospheric lighting. Separate foreground plants, middle furniture, room architecture, windows, sky, and lighting overlays. Night should be rich rather than black. Peach light pools create visual safety.

## Typography
Use a playful rounded handwritten wordmark for 'Moonmart' with crescent and sparkles. Body copy needs a legible, licensed rounded sans or handwritten-inspired typeface. The reference art does not include an extractable font; do not assume a generated image grants a usable font file. The prototype intentionally uses Godot's fallback UI font.

## Asset pipeline
1. Paint or vector the canonical character turnaround.
2. Produce consistent poses and animation pivots.
3. Export transparent high-resolution PNGs and keep layered editable sources.
4. Export modular architectural and prop assets separately.
5. Validate scale, collision and interaction markers in Godot.
6. Add light and shadow overlays after gameplay composition works.

## Sprite requirements
Transparent RGBA; consistent baseline/pivot; avoid baked shadows on moving characters; separate glows when practical. Save authoring masters at 2× or 4× display scale. Define naming `category/name_state_frame.png`.

## Animation targets
Player idle 6, walk 8, carry 4, inspect 4, talk 4, craft 6; Pip float 8, happy 6, sad 6; Miso sleep 8, walk 8, stretch 8, play 8. These are production targets, not assets already delivered.

## What this pack actually provides
Simplified SVG-generated sprites and PNG rasterizations. They demonstrate layer separation and asset conventions but do **not** visually match the painted reference at production quality. Replace them with painted source assets incrementally.
