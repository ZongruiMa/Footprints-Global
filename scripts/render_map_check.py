"""Map data/projection preview, explicitly not an iOS screenshot. Also builds the app icon."""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
features=json.loads((ROOT/'App/Resources/Map/china_provinces.geojson').read_text(encoding='utf-8'))['features']
def polygons(f):
    g=f['geometry']; return [g['coordinates']] if g['type']=='Polygon' else g['coordinates']
def xy(p): return (p[0]*math.cos(math.radians(35)), -p[1])
points=[xy(p) for f in features for poly in polygons(f) for ring in poly for p in ring]
xs,ys=zip(*points); xmin,xmax,ymin,ymax=min(xs),max(xs),min(ys),max(ys)
def draw_map(im,box,visited):
    draw=ImageDraw.Draw(im); x,y,w,h=box
    scale=min(w/(xmax-xmin),h/(ymax-ymin))
    def project(p):
        px,py=xy(p); return ((px-(xmin+xmax)/2)*scale+x+w/2,(py-(ymin+ymax)/2)*scale+y+h/2)
    for f in features:
        color='#DCEEFF' if f['properties']['id'] in visited else '#ECEFF1'
        for poly in polygons(f):
            for i,ring in enumerate(poly):
                pts=[project(p) for p in ring]
                draw.polygon(pts,fill=color if i==0 else '#FAFAFA')
                draw.line(pts,fill='white',width=2)
preview=Image.new('RGB',(1170,1700),'#FAFAFA')
draw_map(preview,(60,140,1050,1300),{'320000','510000','530000'})
draw=ImageDraw.Draw(preview)
draw.text((60,1500),'MAP DATA / PROJECTION CHECK',fill='#737B82')
draw.text((60,1530),'Preview states only. Not an iOS screenshot.',fill='#737B82')
out=ROOT/'artifacts';out.mkdir(exist_ok=True)
preview.save(out/'map-data-preview.png')
catalog=ROOT/'App/Assets.xcassets';icon=catalog/'AppIcon.appiconset';icon.mkdir(parents=True,exist_ok=True)
(catalog/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
appicon=Image.new('RGB',(1024,1024),'#FAFAFA')
draw_map(appicon,(90,160,844,704),{'320000','510000','530000'})
appicon.save(icon/'AppIcon.png')
(icon/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}},indent=2))
print('Map preview and 1024px app icon written')
