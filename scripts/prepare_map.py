"""Pinned WGS84 data; preserve geometry, normalize properties only."""
from pathlib import Path
import hashlib, json, urllib.request
ROOT=Path(__file__).resolve().parents[1]
URL='https://media.githubusercontent.com/media/wmgeolab/geoBoundaries/9469f09/releaseData/gbOpen/CHN/ADM1/geoBoundaries-CHN-ADM1.geojson'
ROWS='''Beijing|110000|北京
Tianjin|120000|天津
Hebei|130000|河北
Shanxi|140000|山西
Inner Mongolia|150000|内蒙古
Liaoning|210000|辽宁
Jilin|220000|吉林
Heilongjiang|230000|黑龙江
Shanghai|310000|上海
Jiangsu|320000|江苏
Zhejiang|330000|浙江
Anhui|340000|安徽
Fujian|350000|福建
Jiangxi|360000|江西
Shandong|370000|山东
Henan|410000|河南
Hubei|420000|湖北
Hunan|430000|湖南
Guangzhou|440000|广东
Guangxi|450000|广西
Hainan|460000|海南
Chongqing|500000|重庆
Sichuan|510000|四川
Guizhou|520000|贵州
Yunnan|530000|云南
Tibet|540000|西藏
Shaanxi|610000|陕西
Gansu|620000|甘肃
Qinghai|630000|青海
Ningxia|640000|宁夏
Xinjiang|650000|新疆
Taiwan|710000|台湾
Hong Kong|810000|香港
Macau|820000|澳门'''
raw=urllib.request.urlopen(URL,timeout=60).read(); data=json.loads(raw)
assert data['crs']['properties']['name']=='urn:ogc:def:crs:OGC:1.3:CRS84'
out=ROOT/'App/Resources/Map'; out.mkdir(parents=True,exist_ok=True)
provenance=ROOT/'docs/sources'; provenance.mkdir(parents=True,exist_ok=True)
(provenance/'geoBoundaries-CHN-ADM1.original.geojson').write_bytes(raw)
for feature in data['features']:
    p=feature['properties']
    rows=[r.split('|') for r in ROWS.splitlines() if p['shapeName'].startswith(r.split('|')[0]+' ')]
    assert len(rows)==1,p
    _,code,name=rows[0]
    g=feature['geometry']; polys=[g['coordinates']] if g['type']=='Polygon' else g['coordinates']
    points=[pt for poly in polys for ring in poly for pt in ring]
    xs,ys=zip(*[(pt[0],pt[1]) for pt in points])
    p.update(id=code,adcode=code,name=name,displayName=name,center=[(min(xs)+max(xs))/2,(min(ys)+max(ys))/2])
    feature['id']=code
assert len(data['features'])==34
data['features'].sort(key=lambda f:f['id'])
(out/'china_provinces.geojson').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')),encoding='utf-8')
metadata_url=URL.replace('.geojson','-metaData.json')
metadata_raw=urllib.request.urlopen(metadata_url,timeout=60).read()
(provenance/'metaData.json').write_bytes(metadata_raw)
meta=json.loads(metadata_raw)
meta.update(downloadURL=URL,sourceSHA256=hashlib.sha256(raw).hexdigest(),preparedSHA256=hashlib.sha256((out/'china_provinces.geojson').read_bytes()).hexdigest(),note='Geometry unchanged; Guangzhou Province label normalized to Guangdong. Geometry is commit pinned.')
(provenance/'map-provenance.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
fixtures=ROOT/'Tests/Fixtures'; fixtures.mkdir(parents=True,exist_ok=True)
(fixtures/'china_provinces.geojson').write_bytes((out/'china_provinces.geojson').read_bytes())
print('Prepared 34 regions; original CRS84 geometry preserved; '+str(len(raw))+' bytes')
