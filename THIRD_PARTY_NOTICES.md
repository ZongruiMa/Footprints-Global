# Third-party notices

## Map data: geoBoundaries

geoBoundaries, William & Mary geoLab and community contributors.
https://www.geoboundaries.org/
https://github.com/wmgeolab/geoBoundaries

Dataset: gbOpen CHN ADM1, boundary ID CHN-ADM1-43563684, 34 features.
Pinned commit: 9469f09592ced973a3448cf66b6100b741b64c0d.
Source represents 2019 boundaries; build metadata: 2023-12-12.

The geoBoundaries distribution is licensed under Creative Commons Attribution
4.0 International (CC BY 4.0):
https://creativecommons.org/licenses/by/4.0/
https://creativecommons.org/licenses/by/4.0/legalcode

The per-file upstream metadata additionally describes its source as
"geoBoundaries, Wikimedia Commons" and "Public Domain". This project retains
that metadata and follows the geoBoundaries distribution's CC BY 4.0 attribution
requirements. No endorsement by geoBoundaries is implied.

Changes: preserved all source Polygon/MultiPolygon geometry; added stable
app IDs, Chinese display names, administrative codes and bounding-box centers;
normalized upstream "Guangzhou Province" to 广东 and the duplicated Ningxia
label to 宁夏. These are metadata changes, not boundary edits.

Recommended dataset citation:
Runfola, D. et al. (2020). geoBoundaries: A global database of political
administrative boundaries. PLoS ONE 15(4): e0231866.
https://doi.org/10.1371/journal.pone.0231866

## Code

No third-party runtime libraries or copied third-party application code.
Ray casting, data normalization and the application are implemented for this
project. Apple frameworks are supplied by the iOS SDK, not redistributed here.

The optional developer checks use tree-sitter (MIT), tree-sitter-swift (MIT)
and Shapely (BSD-3-Clause); they are not included in the iPhone app.
