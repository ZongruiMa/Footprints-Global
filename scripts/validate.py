"""Host checks, NOT an iOS build or Swift type check."""
from pathlib import Path
import argparse, hashlib, json, plistlib, re, sys, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(); parser.add_argument('--phase',default='review'); args=parser.parse_args()
checks=[]
plistlib.load((ROOT/'App/Info.plist').open('rb')); checks.append('Info.plist parsed')
ET.parse(ROOT/'TravelMemory.xcodeproj/xcshareddata/xcschemes/TravelMemory.xcscheme'); checks.append('Shared scheme XML parsed')
from tree_sitter import Language, Parser
import tree_sitter_swift
p=Parser(Language(tree_sitter_swift.language()))
sources=list((ROOT/'App').rglob('*.swift'))+list((ROOT/'Core').rglob('*.swift'))+list((ROOT/'Tests').rglob('*.swift'))
errors=[]
for f in sources:
    tree=p.parse(f.read_bytes())
    def inspect(n):
        if n.type=='ERROR' or n.is_missing: errors.append(f'{f.relative_to(ROOT)}:{n.start_point.row+1} {n.type}')
        for child in n.children: inspect(child)
    inspect(tree.root_node)
if errors: print('\n'.join(errors)); sys.exit(1)
checks.append(f'{len(sources)} Swift files: tree-sitter syntax parsed (not type checked)')
project=(ROOT/'TravelMemory.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
from openstep_parser import OpenStepDecoder
pbx=OpenStepDecoder.ParseFromString(project)
objects=pbx['objects']; assert pbx['rootObject'] in objects
single_refs={'fileRef','buildConfigurationList','productReference','mainGroup','productRefGroup','containerPortal','targetProxy','target'}
multi_refs={'children','files','buildConfigurations','buildPhases','dependencies','targets'}
for entry in objects.values():
    for key,value in entry.items():
        if key in single_refs: assert value in objects, (key,value)
        if key in multi_refs:
            for v in value: assert v in objects,(key,v)
checks.append(f'OpenStep project parsed; {len(objects)} PBX objects and their references valid')
for f in sources: assert f.relative_to(ROOT).as_posix() in project, f
checks.append('All Swift files included in Xcode project')
app_source='\n'.join(f.read_text(encoding='utf-8') for f in sources if 'Tests' not in f.parts)
assert not re.search(r'PHAssetChangeRequest|PHAssetCreationRequest|URLSession|fatalError\s*\(|try!',app_source)
assert 'isNetworkAccessAllowed = false' in app_source
checks.append('No system-photo mutation, URLSession, fatalError or forced-try calls; automatic image network access disabled')
assert (ROOT/'App/Resources/THIRD_PARTY_NOTICES.md').read_bytes()==(ROOT/'THIRD_PARTY_NOTICES.md').read_bytes()
plistlib.load((ROOT/'App/Resources/PrivacyInfo.xcprivacy').open('rb'))
checks.append('Bundled attribution matches original; privacy manifest parsed')
map_path=ROOT/'App/Resources/Map/china_provinces.geojson'
if map_path.exists():
    from shapely.geometry import shape, Point
    data=json.loads(map_path.read_text(encoding='utf-8')); features=data['features']
    original_path=ROOT/'docs/sources/geoBoundaries-CHN-ADM1.original.geojson'
    original=json.loads(original_path.read_text(encoding='utf-8'))
    provenance=json.loads((ROOT/'docs/sources/map-provenance.json').read_text(encoding='utf-8'))
    assert hashlib.sha256(original_path.read_bytes()).hexdigest()==provenance['sourceSHA256']
    assert hashlib.sha256(map_path.read_bytes()).hexdigest()==provenance['preparedSHA256']
    assert original['crs']['properties']['name']=='urn:ogc:def:crs:OGC:1.3:CRS84'
    geometries={f['properties']['shapeID']:f['geometry'] for f in original['features']}
    assert all(f['geometry']==geometries[f['properties']['shapeID']] for f in features)
    assert map_path.read_bytes()==(ROOT/'Tests/Fixtures/china_provinces.geojson').read_bytes()
    checks.append('WGS84 source hashes verified; all original geometry preserved; Swift test fixture matches bundle')
    assert len(features)==34 and len({f['properties']['id'] for f in features})==34
    for f in features:
        assert shape(f['geometry']).is_valid, f['properties']['name']
    fixtures=[('320000',118.7969,32.0603),('510000',104.0665,30.5728),('110000',116.4074,39.9042),('310000',121.4737,31.2304),('440000',113.2644,23.1291),('530000',102.8329,24.8801),('460000',110.1983,20.0442),('650000',87.6168,43.8256),('540000',91.1172,29.6469),('810000',114.1694,22.3193),('820000',113.5439,22.1987),('710000',121.5654,25.0330),(None,140,20),(None,0,0)]
    for expected,lon,lat in fixtures:
        matches=[f['properties']['id'] for f in features if shape(f['geometry']).covers(Point(lon,lat))]
        assert expected in matches if expected else not matches, (expected,lon,lat,matches)
    checks.append('34 valid geometries, 12 region and 2 outside fixtures passed with independent Shapely engine')
result={'phase':args.phase,'checks':checks,'iOS_build':'NOT RUN: no Xcode on this host','Swift_tests':'NOT RUN: no Swift toolchain on this host'}
logs=ROOT/'docs/validation'; logs.mkdir(parents=True,exist_ok=True)
(logs/(args.phase+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
