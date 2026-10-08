"""Build offline maps from a pinned Natural Earth snapshot. No user data involved."""
from pathlib import Path
import argparse, hashlib, json, urllib.request
from shapely.geometry import shape, mapping
from shapely import make_valid

ROOT = Path(__file__).resolve().parents[1]
REV = 'ca96624a56bd078437bca8184e78163e5039ad19'
LANGS = {'en':'en','zh-Hans':'zh','zh-Hant':'zht','ja':'ja','ko':'ko','fr':'fr','de':'de','es':'es','pt':'pt','ar':'ar'}
def write(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, separators=(',',':')), encoding='utf-8')
def prepare(cache):
    provenance = {'source':'Natural Earth','revision':REV,'license':'Public domain','simplificationDegrees':0.004,'inputs':{}}
    raw = {}
    for kind, filename in [('countries','ne_10m_admin_0_countries'),('regions','ne_10m_admin_1_states_provinces')]:
        p = cache / (kind + '.geojson')
        url = f'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/{REV}/geojson/{filename}.geojson'
        if not p.exists():
            p.parent.mkdir(parents=True, exist_ok=True)
            urllib.request.urlretrieve(url, p)
        provenance['inputs'][kind] = {'url':url, 'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
        raw[kind] = json.loads(p.read_text(encoding='utf-8'))['features']
    def feature(f, country=False):
        p = {k.lower():v for k,v in f['properties'].items()}
        code = p['adm0_a3']
        names = {l:p.get('name_'+field) for l,field in LANGS.items() if p.get('name_'+field)}
        name = names.get('en') or p.get('name') or p.get('admin') or code
        geo = make_valid(shape(f['geometry'])).simplify(0.004, preserve_topology=True)
        if geo.geom_type == 'GeometryCollection':
            from shapely.ops import unary_union
            geo = unary_union([g for g in geo.geoms if g.geom_type in ('Polygon','MultiPolygon')])
        assert geo.geom_type in ('Polygon','MultiPolygon') and not geo.is_empty
        center = geo.representative_point()
        props = {'id':'country:'+code if country else 'region:'+p['adm1_code'], 'name':name, 'displayName':name,
                 'countryID':'country:'+code,'isCountry':country,'names':names,'center':[center.x,center.y]}
        return {'type':'Feature','properties':props,'geometry':mapping(geo)}
    countries = [feature(f, True) for f in raw['countries']]
    known = {f['properties']['id'] for f in countries}
    regions = [feature(f) for f in raw['regions'] if f['properties']['adm0_a3'] not in ('CHN','TWN','HKG','MAC')]
    regions = [f for f in regions if f['properties']['countryID'] in known]
    # Keep IDs/geometry used by the original app so local notes and assignments survive.
    old = json.loads((ROOT/'App/Resources/Map/china_provinces.geojson').read_text(encoding='utf-8'))['features']
    china_names = {str(f['properties'].get('iso_3166_2','')).split('-')[-1]:f for f in raw['regions'] if f['properties']['adm0_a3']=='CHN'}
    china_codes = dict(zip('11 12 13 14 15 21 22 23 31 32 33 34 35 36 37 41 42 43 44 45 46 50 51 52 53 54 61 62 63 64 65'.split(), 'BJ TJ HE SX NM LN JL HL SH JS ZJ AH FJ JX SD HA HB HN GD GX HI CQ SC GZ YN XZ SN GS QH NX XJ'.split()))
    for f in old:
        p=f['properties']; country={'710000':'TWN','810000':'HKG','820000':'MAC'}.get(p['id'],'CHN')
        source=china_names.get(china_codes.get(p['id'][:2]))
        names = feature(source)['properties']['names'] if source else {}
        if not source and country!='CHN':
            names=next((c['properties']['names'] for c in countries if c['properties']['countryID']=='country:'+country),{})
        names['zh-Hans']=p['displayName']
        p.update(countryID='country:'+country,isCountry=False,names=names)
        regions.append(f)
    for name, features in [('world_countries',countries),('world_regions',regions)]:
        assert len(features)==len({f['properties']['id'] for f in features})
        out=ROOT/'App/Resources/Map'/f'{name}.geojson'
        write(out,{'type':'FeatureCollection','features':features})
        provenance[name]={'count':len(features),'sha256':hashlib.sha256(out.read_bytes()).hexdigest()}
    write(ROOT/'docs/sources/world-provenance.json',provenance)
    print(json.dumps({k:v for k,v in provenance.items() if k.startswith('world_')}, indent=2))
if __name__=='__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--cache',type=Path,default=ROOT/'.map-cache')
    prepare(parser.parse_args().cache)
