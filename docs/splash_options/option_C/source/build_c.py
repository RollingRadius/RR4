import json, math
from art import defs, tyreA, caliper, tyreB, hi

G = json.load(open('clean_geo.json'))
import math
BOT = G['bottom']
def arc_x(c, r, y, left=True):
    dx = math.sqrt(r * r - (y - c[1]) ** 2); return c[0] - dx if left else c[0] + dx
# road edge lines (inset 4.6 from each road edge) and dashes
YT = 106.0
li_c, li_r = (308.5, 227.0), 139.5 - 4.6
ri_c, ri_r = (336.5, 229.0), 123.5 + 4.6
lx = arc_x(li_c, li_r, YT, True); rx = arc_x(ri_c, ri_r, YT, True)
edge_l = f"M{li_c[0]-li_r:.2f} {BOT} V{li_c[1]} A{li_r} {li_r} 0 0 1 {lx:.2f} {YT}"
edge_r = f"M{ri_c[0]-ri_r:.2f} {BOT} V{ri_c[1]} A{ri_r} {ri_r} 0 0 1 {rx:.2f} {YT}"
LOGO_DEFS = f'<clipPath id="outerClip"><path d="{G["outer"]}"/></clipPath>'
BLUE = f'<path d="{G["outer"]}" fill="#3997CD"/>'
ROAD = (f'<g clip-path="url(#outerClip)"><path d="{G["road"]}" fill="#000"/>'
        f'<path d="{edge_l}" fill="none" stroke="#fff" stroke-opacity=".9" stroke-width="2"/>'
        f'<path d="{edge_r}" fill="none" stroke="#fff" stroke-opacity=".9" stroke-width="2"/></g>')
DASH = (f'<g clip-path="url(#outerClip)"><path id="dashP" d="{G["dash"]}" fill="none" stroke="#fff" stroke-width="{G["dash_w"]}" '
        f'stroke-dasharray="{G["dash_len"]} {G["dash_gap"]}" stroke-linecap="round"/></g>')
wx, wy, wr = G['wheel']
WHEEL = f'<circle cx="{wx}" cy="{wy}" r="{wr}" fill="#000"/>'
html = open('template_cc.html', encoding='utf-8').read()
for k, v in {'%%DEFS%%': defs + LOGO_DEFS, '%%A%%': tyreA, '%%CAL%%': caliper, '%%B%%': tyreB, '%%HI%%': hi,
             '%%BLUE%%': BLUE, '%%ROAD%%': ROAD, '%%DASH%%': DASH, '%%WHEEL%%': WHEEL}.items():
    html = html.replace(k, v)
open('splash_preview_c.html', 'w', encoding='utf-8').write(html)
print('ok', len(html))
