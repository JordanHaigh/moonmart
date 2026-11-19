# Raster QA evidence

This folder contains review-only composites, candidate source sheets, source-only PNG inputs, pixel-repair scripts, and before/after evidence. `.gdignore` keeps it out of Godot's resource scan; game scenes reference only production assets under `assets/raster/`. Source inputs used to prepare Agnes's talk pose and the final product icon atlases are kept here rather than in the runtime pack.

Paired dark-plum and warm-cream preview paths are recorded in `assets/raster/asset_manifest.json`. They show transparent atlas edges against contrasting backgrounds without changing the source PNGs. Environment plates were separately reviewed for baked rays, particles, weather, switchable lighting, and story effects; see `assets/raster/README.md` and the Section 27/28 gate in `tools/validate_section27.ps1`.

Pixel repairs are limited to documented alpha-only edge cleanup. Each repair entry identifies the source hash or exact alpha predicate, count, and visual review where available. Do not replace or redraw source artwork in this folder; preserve originals and keep every dynamic effect independent of the painted environment plate.

The latest Old Bellwether ridge-layer probes are `candidate_old_bellwether_parallax_generated.png` and `candidate_old_bellwether_ridge_v2.png`/`v3.png`; v2/v3 include paired dark-plum/warm-cream previews. The v3 full-size source-over composite is `candidate_old_bellwether_ridge_v3_plate_composite.png`. All remain QA-only because the hill layer overlaps the existing storefront and sidewalk without a location-matched architecture cutout.
