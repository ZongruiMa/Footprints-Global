"""Independent geometry, legacy migration and translation coverage checks."""
from pathlib import Path
import json, re, hashlib
from shapely.geometry import shape, Point
ROOT=Path(__file__).resolve().parents[1]
def load(name): return json.loads((ROOT/'App/Resources/Map'/f'{name}.geojson').read_text(encoding='utf-8'))['features']
countries, regions, legacy = load('world_countries'), load('world_regions'), load('china_provinces')
by_id={f['properties']['id']:f for f in countries+regions}
assert len(by_id)==len(countries)+len(regions)
for f in regions: assert f['properties']['countryID'] in by_id
for old in legacy:
    assert by_id[old['properties']['id']]['geometry']==old['geometry']
    assert by_id[old['properties']['id']]['properties']['names'].get('en'), old['properties']['id']
geometries=[(f['properties'],shape(f['geometry'])) for f in regions+countries]
assert all(g.is_valid and not g.is_empty for _,g in geometries)
fixtures=[('JPN',139.6917,35.6895),('FRA',2.3522,48.8566),('USA',-74.006,40.7128),('BRA',-46.6333,-23.5505),('AUS',151.2093,-33.8688),('ZAF',28.0473,-26.2041),('EGY',31.2357,30.0444),('IND',77.209,28.6139),('GBR',-0.1276,51.5072),('CHN',118.7969,32.0603)]
for country,lon,lat in fixtures:
    matches=[p for p,g in geometries if g.covers(Point(lon,lat))]
    assert matches and matches[0]['countryID']=='country:'+country,(country,matches)
    assert not matches[0]['isCountry'],country
table=json.loads((ROOT/'App/Resources/Translations.json').read_text(encoding='utf-8'))
languages=['en','zh-Hans','zh-Hant','ja','ko','fr','de','es','pt','ar']
for key,values in table.items():
    assert set(values)==set(languages) and all(values.values()),key
    placeholders=set(re.findall(r'\{\d+\}',key))
    assert all(set(re.findall(r'\{\d+\}',v))==placeholders for v in values.values()),key
for folder in ['App','Core']:
    for file in (ROOT/folder).rglob('*.swift'):
        for key in re.findall(r'\bL\("([^"\n]+)"',file.read_text(encoding='utf-8')):
            assert key in table,(file,key)
for language in languages: assert (ROOT/'App/Resources'/f'{language}.lproj/InfoPlist.strings').exists()
provenance=json.loads((ROOT/'docs/sources/world-provenance.json').read_text(encoding='utf-8'))
for name in ['world_countries','world_regions']:
    assert hashlib.sha256((ROOT/'App/Resources/Map'/f'{name}.geojson').read_bytes()).hexdigest()==provenance[name]['sha256']
print(f'PASS: {len(countries)} country/territory shapes, {len(regions)} regions, 34 preserved IDs/geometries, {len(fixtures)} world cities, {len(table)} messages in {len(languages)} languages.')
