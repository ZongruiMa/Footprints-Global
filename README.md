# Footprints Global

An offline iPhone travel journal: explore a world map, choose a country or
territory, mark visited regions, write notes, and group photos by embedded GPS.

**Development preview, iOS 17+.** This repository provides source and unsigned
builds. It is not an App Store or TestFlight release. Photo authorization on
physical devices remains part of release acceptance; an earlier device report
of a system authorization prompt failing to appear is not claimed resolved.

## Features

- 258 country/territory map units and 4,558 regional records, bundled offline.
- Switch between the world and a country's first-level regions; searchable
  place lists make small islands and small regions selectable.
- Ten interface languages: English, Simplified Chinese, Traditional Chinese,
  Japanese, Korean, French, German, Spanish, Portuguese, and Arabic. Follow
  system language or choose in Settings. Arabic uses right-to-left layout;
  geographic coordinates keep their orientation.
- Mark places, keep local notes, use five map colors, browse country albums
  that include photos from their regions, and assign photos manually.
- Optional PhotoKit scan of accessible photos, or select image files through
  the system picker without full-library authorization. File import reads GPS
  locally, retains copies, and puts images without matched GPS in Unsorted.
- No account, app server, analytics, advertisements, or photo uploads.

Maps are administrative outlines, not street or satellite navigation maps.
Some territories have no finer subdivisions in the dataset. Place-name
translations depend on upstream data and fall back to English. Languages and
map coverage are extensible; this is not a promise to cover every language or
every current administrative boundary. See [map data](docs/MAP_DATA.md).

## Install

Use [Windows installation instructions](docs/INSTALL-WINDOWS.md) or build in
Xcode. An unsigned `.ipa` cannot be opened directly as an installed iPhone app;
it must be signed using your own Apple account. Never upload Apple passwords,
certificates, provisioning profiles, or phone data to GitHub.

GitHub Actions **Build iPhone App** runs core tests, simulator integration
tests, and an arm64 iPhone Release build. A successful run contains a
`Footprints-iPhone-<number>` artifact with `Footprints.ipa`, checksums, and build
metadata. Artifacts expire after seven days; rerun the workflow in your fork.
Signing and App Store distribution are separate from building an IPA.

## Build and test

CI uses Xcode 16.4 / macOS 15 and targets iOS 17+. Python 3 is needed to
regenerate the project. The Swift app has no external package dependencies.

```sh
python3 scripts/generate_project.py
swift test
open TravelMemory.xcodeproj
```

In Xcode, select the TravelMemory scheme, choose your signing team and a unique
bundle identifier, then run on your own device. To reproduce the unsigned CI
build on a Mac with Xcode, run `bash scripts/build-cloud.sh`.

Optional host checks (Windows/macOS):

```sh
python -m pip install -r scripts/requirements-dev.txt
python scripts/validate.py --phase global-host
python scripts/validate_global.py
python scripts/test-package-ipa.py
```

Host checks are syntax/data checks, not a replacement for Xcode compilation.
`Tests` includes regional matching, geographic holes and boundaries, language
fallback, dateline fitting, photo permission timeout/late callback handling,
GPS file ingestion, limited-access persistence, manual assignments, and notes.

The DEBUG-only `--preview` launch flag dismisses onboarding in a simulator
without requesting photo access; `--preview-settings` opens Settings. CI captures
English world, Japanese region map, and Arabic settings screenshots.

## Local data and upgrading

The original 34 China-map identifiers and geometries are retained. Existing
notes and assignments keep their keys when an update uses the same signed
app identity. There is no cloud sync or export yet. **Uninstalling removes
local records and imported copies.** Changing signing identity may install a
separate app instead of updating the existing one. See [privacy](PRIVACY.md).

Automatic means scan on opening or on observed photo-library changes while
the app runs; it does not promise continuous background scanning when iOS has
suspended the app. Private Access through the system picker grants access to
selected files only. If the full-library prompt does not appear, use selected
file import; do not reset system-wide privacy settings to troubleshoot this app.

## Open source

Code: [MIT](LICENSE). Geographic data: Natural Earth public domain and
geoBoundaries attribution under CC BY 4.0; see [notices](THIRD_PARTY_NOTICES.md).
[Contributions](CONTRIBUTING.md), native-speaker translation corrections,
and reproducible bug reports are welcome. Do not submit personal photo/GPS data.
