# Moonmart concept-art transfer

The original Moonmart concept-art ZIP is approximately 18.6 MB; its Base64 encoding is approximately 24.8 MB. **The encoded payload is not stored in this repository yet.** The GitHub integration cannot directly read the binary archive in the assistant's local runtime.

The importer in `tools/import_concept_art.ps1` accepts either a local Base64 text file or the ZIP, validates it, extracts the artwork to `art/concept/`, commits the files and pushes to `main`.

## PowerShell: Base64 text
```powershell
git pull origin main
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\import_concept_art.ps1 -Base64File "$env:USERPROFILE\Downloads\Moonmart_Concept_Art_Fresh_2026-11-11.zip.base64.txt"
```

## PowerShell: ZIP
```powershell
git pull origin main
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\import_concept_art.ps1 -ZipFile "$env:USERPROFILE\Downloads\Moonmart_Concept_Art_Fresh_2026-11-11.zip"
```

## If you already extracted the PNGs
Copy them into `art/concept/`, then run:
```powershell
git add art/concept
git commit -m "Import Moonmart concept art"
git push origin main
```

## Verify
```powershell
git ls-files art/concept
git status
```

This imports concept art only. Modular game-ready sprites belong under `starter_original/assets/` and are managed by the separate original-asset importer.
