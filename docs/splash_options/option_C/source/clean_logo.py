import math, json, subprocess, os
import numpy as np
from PIL import Image

# ---- parameters measured from rr_logo.png (512 space) ----
BOT = 388.5
OL_C, OL_R = (224.0, 214.5), 97.5          # outer-left corner circle (left x = 126.5, top y = 117)
OR_C, OR_R = (301.5, 225.0), 108.2
DM_C, DM_R = (337.0, 213.9), 71.7
RL_C, RL_R = (308.5, 227.0), 139.5         # road left edge circle (tangent x = 169)
RR_C, RR_R = (336.5, 229.0), 123.5         # road right edge circle (tangent x = 213)
WH_C, WH_R = (354.5, 198.0), 46.5          # wheel
DASH_X, DASH_LEN, DASH_GAP, DASH_W = 191.0, 10.0, 15.0, 4.6
CL_C, CL_R = (322.75, 228.0), 131.5        # dash centre-line arc

def circ_inter(c1, r1, c2, r2):
    (x1, y1), (x2, y2) = c1, c2
    d = math.hypot(x2 - x1, y2 - y1)
    a = (r1 ** 2 - r2 ** 2 + d ** 2) / (2 * d)
    h = math.sqrt(r1 ** 2 - a ** 2)
    xm, ym = x1 + a * (x2 - x1) / d, y1 + a * (y2 - y1) / d
    p1 = (xm + h * (y2 - y1) / d, ym - h * (x2 - x1) / d)
    p2 = (xm - h * (y2 - y1) / d, ym + h * (x2 - x1) / d)
    return p1, p2

tips = circ_inter(OR_C, OR_R, DM_C, DM_R)
tip = min(tips, key=lambda p: p[1])
inner_left = (DM_C[0] - DM_R, DM_C[1])

f = lambda v: f"{v:.2f}"
outer = (f"M{f(OL_C[0]-OL_R)} {f(BOT)} V{f(OL_C[1])} A{OL_R} {OL_R} 0 0 1 {f(OL_C[0])} {f(OL_C[1]-OL_R)} "
         f"H{f(OR_C[0])} A{OR_R} {OR_R} 0 0 1 {f(tip[0])} {f(tip[1])} "
         f"A{DM_R} {DM_R} 0 0 0 {f(inner_left[0])} {f(inner_left[1])} V{f(BOT)} Z")

def x_on(c, r, y, left=True):
    dx = math.sqrt(r * r - (y - c[1]) ** 2)
    return c[0] - dx if left else c[0] + dx

YT = 106.0
xl, xr = x_on(RL_C, RL_R, YT), x_on(RR_C, RR_R, YT)
road = (f"M{f(RL_C[0]-RL_R)} {f(BOT)} V{f(RL_C[1])} A{RL_R} {RL_R} 0 0 1 {f(xl)} {f(YT)} "
        f"H{f(xr)} A{RR_R} {RR_R} 0 0 0 {f(RR_C[0]-RR_R)} {f(RR_C[1])} V{f(BOT)} Z")
y_end = 123.0
cx_end = CL_C[0] - math.sqrt(CL_R ** 2 - (y_end - CL_C[1]) ** 2)
dash = (f"M{f(DASH_X)} {f(BOT)} V{f(CL_C[1])} A{CL_R} {CL_R} 0 0 1 {f(cx_end)} {f(y_end)}")

geo = dict(outer=outer, road=road, dash=dash, tip=tip, wheel=[*WH_C, WH_R],
           dash_len=DASH_LEN, dash_gap=DASH_GAP, dash_w=DASH_W, bottom=BOT)
json.dump(geo, open('clean_geo.json', 'w'), indent=1)
print(json.dumps(geo, indent=1))

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<rect width="512" height="512" fill="#fff"/>
<defs><clipPath id="c"><path d="{outer}"/></clipPath></defs>
<path d="{outer}" fill="#3997CD"/>
<g clip-path="url(#c)"><path d="{road}" fill="#000"/></g>
<path d="{dash}" fill="none" stroke="#fff" stroke-width="{DASH_W}" stroke-dasharray="{DASH_LEN} {DASH_GAP}"/>
<circle cx="{WH_C[0]}" cy="{WH_C[1]}" r="{WH_R}" fill="#000"/>
</svg>'''
open('clean_logo.svg', 'w').write(svg)

here = os.getcwd()
html = f'<html><body style="margin:0">{svg}</body></html>'
open('clean_logo.html', 'w').write(html)
subprocess.run([r"C:\Program Files\Google\Chrome\Application\chrome.exe", "--headless=new", "--disable-gpu",
                "--hide-scrollbars", "--window-size=512,512", f"--screenshot={here}\\clean_logo.png",
                f"file:///{here}/clean_logo.html"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def masks(path):
    im = Image.open(path).convert('RGBA')
    bg = Image.new('RGBA', im.size, 'white'); bg.alpha_composite(im)
    a = np.array(bg.convert('RGB').resize((512, 512))).astype(int)
    a[:4, :] = 255; a[-4:, :] = 255; a[:, :4] = 255; a[:, -4:] = 255
    R, G, B = a[..., 0], a[..., 1], a[..., 2]
    return (B > 150) & (R < 140) & (G > 110) & (G < 190), (R < 70) & (G < 70) & (B < 70)

ob, ok = masks(r'D:\RR4\frontend\assest\logos\rr_logo.png')
nb, nk = masks('clean_logo.png')
iou = lambda p, q: (p & q).sum() / max(1, (p | q).sum())
print('IoU blue', round(iou(ob, nb), 4), 'IoU black', round(iou(ok, nk), 4))
# visual diff
diff = np.zeros((512, 512, 3), np.uint8) + 255
diff[ob & ~nb] = (255, 0, 0); diff[nb & ~ob] = (0, 160, 0); diff[ok & ~nk] = (255, 120, 0); diff[nk & ~ok] = (0, 200, 200)
Image.fromarray(diff).save('diff.png')
