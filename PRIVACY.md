# Privacy

Footprints processes photos, embedded GPS metadata, notes, visited places,
language, and map preferences locally. It has no user account, application
server, advertising, tracking SDK, or analytics. The app itself makes no
network requests. Maps and UI translations are bundled for offline use.

Photo library access is optional. With permission, the app stores references
to accessible system photos. A system photo picker can instead share selected
image files; these are copied to the app's private storage. Location grouping
requires GPS metadata in the shared file. The app does not reconstruct absent
locations and never deletes or modifies photos in the system library.

Apple's system picker may download iCloud originals when the user selects
them. This is handled by iOS and the user's Apple services, not a Footprints
server. Automatic thumbnail requests do not enable network access.

Application records and imported copies are excluded from cloud backup; they
are not synced. Uninstalling deletes local records and imported copies. There
is currently no export or cross-device restore feature. Changing photo access
can hide library references, while explicitly imported copies remain local.

Language and map preferences use this app's UserDefaults. The privacy manifest
declares that required-reason API. Diagnostics are displayed locally and are
not sent automatically. GitHub only hosts source and build outputs.
