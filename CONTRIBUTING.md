# Contributing

Please file reproducible issues with iOS version, app version, steps, expected
behavior, and actual behavior. Do not attach personal photos, GPS coordinates,
Apple credentials, signing certificates, or full device logs.

The app is SwiftUI + SwiftData, iOS 17+, with no third-party runtime dependency.
Keep geographic matching, models, and language fallback testable in Core.
Do not add analytics, photo uploads, or accounts as part of unrelated changes.

Run `swift test` and the iOS tests described in README.md. After adding Swift
or resource files, run `python3 scripts/generate_project.py` and commit the
generated project. Validate data with `python3 scripts/validate_global.py`.

Translations live in `scripts/build_localizations.py`; update the matching
row for every language and keep numbered placeholders intact. Then run the
script. Place names come from the map dataset and fall back to English where
that source has no translation. Native-speaker corrections are welcome.

Map updates must preserve existing identifiers or include a tested migration.
Pin upstream versions, record attribution and checksums, and never present
approximate boundaries as authoritative navigation or legal boundaries.
