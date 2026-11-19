# Editable raster source projects

Keep editable source packages here, outside Godot's runtime import and raster export folders. Each source package must retain its component PNG layers, reference them to `art_import/`, and document whether it is an original working file or a reconstructed, pixel-preserving layer stack. Do not claim a flattened export is an editable source.

## Moonmart Tea Corner

`moonmart_tea_corner.ora` is an OpenRaster project with three individually editable 1600×900 raster layers: fixed architecture, exterior parallax scenery, and night sky scenery. The archive also contains the exact approved merged plate. Its source layers are copied unchanged from `assets/raster/environment/`; the Tea Corner splitter at `tools/split_tea_corner_window.ps1` verifies zero changed RGBA pixels when they are recomposed over `moonmart_tea_corner.png`.

This is a reconstructed editable stack from the approved lossless layer exports, not the original painting-session file. It contains no weather, dynamic lighting, rays, particles, or story effects. Those continue to live in separate runtime resources under Section 27. Rebuild the archive with `pwsh -File tools/build_tea_corner_source.ps1` after reviewing its input PNG hashes and exact-split source.

Original layered masters for the other painted plates are still not present in the repository. In particular, the five outdoor district plates need matching underpaint and transparent architecture cutouts before distant scenery parallax can be authored to the required fidelity.
