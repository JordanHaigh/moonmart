# District sky split probes — rejected for runtime

These are source-derived QA probes only. `../.gdignore` keeps the PNGs out of Godot's runtime resource scan. The source district plates were not modified, and none of these candidates is listed in `assets/raster/asset_manifest.json` or referenced by a scene.

The generator is `tools/probe_district_sky_split.ps1`. It flood-fills blue-violet pixels connected to the top edge, copies the selected pixels to a transparent sky layer, clears alpha for those same pixels on a derived architecture layer, and verifies exact source-over recomposition. It writes paired dark-plum and warm-cream previews.

## Old Lighthouse

The default probe selected 874,025 connected pixels and reconstructed the source with zero changed pixels. Its selected pixels still include parts of the lighthouse tower, roof, distant water reflections, and shoreline. The architecture-on-plum preview exposes large holes through the lighthouse and roof. A stricter color range (B-R ≥ 42, B-G ≥ 16, mean ≥ 48) selected 800,101 pixels, but still cut through the tower, roof, trees, and shore.

## Moonwater Harbour

The upper-sky probe was limited to y ≤ 250 to avoid the sea and lower foreground. It selected 310,937 pixels and reconstructed the source with zero changed pixels. The mask still clears portions of the overhanging leaves and right-hand roof/chimney. The row limit also creates a hard horizontal cut across the sky. It is not suitable as a production layer.

Exact recomposition proves the binary split preserves the pixels at the original position; it does not prove semantic separation or that a shifted layer will stay clean. These tests show a broad flood-fill cannot distinguish the painted sky from cool-toned architecture and foliage on these plates. Keep the intact plates in runtime until purpose-composed district layers or accurately hand-authored masks with matching underpainting are available.

Source SHA-256:

- `old_lighthouse.png`: `1B8815A6A3A65A93AD755B2D81CC8EA446A2560DBAD92B4C9CAB525E4D33592D`
- `moonwater_harbour.png`: `7E698AFCAC863447B6C76FFD869C2288701C4CBE06BD1DC205B6171942F441C3`
