# Offline maps

The world view contains 258 Natural Earth country/territory map units. These
are source dataset units, including dependencies and special territories; the
number is not a claim about the number of sovereign countries.

The regional view has 4,558 records. Natural Earth 10m Admin 1 geometry is
repaired where necessary and simplified at 0.004 degrees. Names in ten UI
languages are retained when supplied by the source, with English fallback.
The country view includes all linked subdivisions, including remote islands.
Regions that cross the dateline use a circular longitude window to fit the
view. Search is available when a region is too small to tap.

Source commit: `ca96624a56bd078437bca8184e78163e5039ad19`, public domain.
Input URLs, SHA-256 hashes, output hashes and feature counts are recorded in
[`sources/world-provenance.json`](sources/world-provenance.json).

The original app's 34 geoBoundaries China-map records retain their IDs and
geometry byte-for-byte as JSON structures, to preserve notes and assignments.
They replace the Natural Earth CHN/TWN/HKG/MAC subdivisions, with country
links corresponding to the Natural Earth world map. The legacy records for
Taiwan, Hong Kong and Macao remain single region records; finer divisions
are not supplied in this version. Country and region borders can differ
because they come from different datasets and dates. Retained attribution and
original geometry are under `sources`; see the repository's third-party notices.

Classification uses WGS84 longitude/latitude from PhotoKit or image EXIF. It
tries regional polygons first, then country polygons where a subdivision
does not match. It respects holes and shared boundaries, with deterministic
tie-breaking. Ocean coordinates and absent/invalid GPS remain unclassified.
The currently displayed country never restricts classification.

These maps are approximate, may lag changes in administrative boundaries, and
are not for navigation, surveying, or legal interpretation. Displaying a map
unit does not endorse a territorial claim. Manual assignment is available.

## Regenerate

```sh
python -m pip install shapely==2.1.2
python scripts/prepare_global_map.py --cache .map-cache
python scripts/validate_global.py
```

The download cache is excluded from Git. The app does not download maps.
Never silently replace legacy IDs; add a migration when a dataset update
changes region identity. Place-name translations may need local review.
