import math


def pt(r, a):
    return (r * math.cos(math.radians(a)), r * math.sin(math.radians(a)))


def poly(points, **attrs):
    d = "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in points) + "Z"
    a = ' '.join(f'{k.replace("_", "-")}="{v}"' for k, v in attrs.items())
    return f'<path d="{d}" {a}/>'


def circles(n, r, rr, start=0, **attrs):
    a = ' '.join(f'{k.replace("_", "-")}="{v}"' for k, v in attrs.items())
    return ''.join(f'<circle cx="{pt(r, start + i * 360 / n)[0]:.1f}" cy="{pt(r, start + i * 360 / n)[1]:.1f}" r="{rr}" {a}/>'
                   for i in range(n))


# ---------------- tread ring on the face edge (18 notches, matches the tread blocks) ----------------
TREAD = ('<circle r="96" fill="none" stroke="#34363b" stroke-width="9" stroke-dasharray="24.1 9.4" stroke-dashoffset="12.05"/>'
         '<circle r="100" fill="none" stroke="#000" stroke-width="2.4"/>'
         '<circle r="91.5" fill="none" stroke="#000" stroke-width="2"/>')

# ---------------- rotating layer A: tyre, sidewall, rim lip, barrel, brake disc ----------------
holes1 = circles(18, 40, 2.3, 0, fill="#171c21", stroke="#b4bdc4", stroke_width=".55")
holes2 = circles(12, 33, 1.7, 15, fill="#171c21", stroke="#9aa4ab", stroke_width=".45")
vanes = ''.join(
    f'<line x1="{pt(29,a)[0]:.1f}" y1="{pt(29,a)[1]:.1f}" x2="{pt(47,a)[0]:.1f}" y2="{pt(47,a)[1]:.1f}" stroke="#4d565e" stroke-opacity=".45" stroke-width=".7"/>'
    for a in range(0, 360, 20))
bolts = circles(24, 64.8, 1.1, 0, fill="#1c2227", stroke="#e6ebef", stroke_width=".4")
tyreA = f'''<g id="rotA"><circle r="100" fill="#050506"/>{TREAD}
<circle r="90" fill="url(#gSide)"/>
<circle r="87" fill="none" stroke="#000" stroke-opacity=".55" stroke-width="1.4"/>
<circle r="85.4" fill="none" stroke="#3a3b41" stroke-width=".9"/>
<path id="tp" d="M-79 0 a79 79 0 1 1 158 0 a79 79 0 1 1 -158 0" fill="none"/>
<text font-family="Arial Black,Arial,sans-serif" font-weight="900" font-size="9.5" letter-spacing="2" fill="#fff" fill-opacity=".42"><textPath href="#tp">ROLLING RADIUS • ROLLING RADIUS • ROLLING RADIUS •</textPath></text>
<path id="tp2" d="M-73 0 a73 73 0 1 1 146 0 a73 73 0 1 1 -146 0" fill="none"/>
<text font-family="Arial,sans-serif" font-weight="700" font-size="5.6" letter-spacing="1.2" fill="#fff" fill-opacity=".3"><textPath href="#tp2" startOffset="12">255/35 ZR19 • 98Y • TREADWEAR 280 • TRACTION AA • TEMPERATURE A •</textPath></text>
<circle r="72" fill="none" stroke="#8d969d" stroke-opacity=".5" stroke-width="1.6"/>
<circle r="69.5" fill="none" stroke="#3d3e44" stroke-width="3.4"/>
<circle r="71" fill="none" stroke="#5d5e66" stroke-opacity=".7" stroke-width=".7"/>
<circle r="67.7" fill="none" stroke="#000" stroke-opacity=".7" stroke-width="1"/>
<circle r="66.4" fill="url(#gLip)"/>
<circle r="63.7" fill="#0d1115"/>
<circle r="62.8" fill="url(#gLip2)"/>
{bolts}
<circle r="60.6" fill="url(#gBarrel)" stroke="#000" stroke-width="1.2"/>
<circle r="55.5" fill="none" stroke="#000" stroke-opacity=".8" stroke-width="1.7"/>
<circle r="54.1" fill="none" stroke="#6a737b" stroke-opacity=".6" stroke-width=".8"/>
<circle r="50.4" fill="url(#gDisc)" stroke="#3a4249" stroke-width="1.3"/>
<circle r="47" fill="none" stroke="#4d565e" stroke-width=".8"/>
{vanes}{holes1}{holes2}
<circle r="30.5" fill="none" stroke="#3a4249" stroke-width="1.4"/>
<circle r="28.5" fill="url(#gHat)" stroke="#000" stroke-width="1"/></g>'''

# ---------------- static caliper (does not spin with the wheel) ----------------
c0, c1, c2, c3 = pt(58, -32), pt(58, 32), pt(32, 32), pt(32, -32)
b0, b1 = pt(52, -24), pt(52, 24)
caliper = (
    f'<path d="M{c0[0]:.1f} {c0[1]:.1f} A58 58 0 0 1 {c1[0]:.1f} {c1[1]:.1f} L{c2[0]:.1f} {c2[1]:.1f} '
    f'A32 32 0 0 0 {c3[0]:.1f} {c3[1]:.1f}Z" fill="url(#gCal)" stroke="#124560" stroke-width="2.2" stroke-linejoin="round"/>'
    f'<path d="M{b0[0]:.1f} {b0[1]:.1f} A52 52 0 0 1 {b1[0]:.1f} {b1[1]:.1f}" fill="none" stroke="#fff" stroke-opacity=".6" stroke-width="2" stroke-linecap="round"/>'
    f'<path d="M{pt(37,-26)[0]:.1f} {pt(37,-26)[1]:.1f} A37 37 0 0 1 {pt(37,26)[0]:.1f} {pt(37,26)[1]:.1f}" fill="none" stroke="#124560" stroke-opacity=".55" stroke-width="1.4"/>'
    f'<circle cx="{pt(48,-17)[0]:.1f}" cy="{pt(48,-17)[1]:.1f}" r="2.5" fill="#d3dade" stroke="#124560" stroke-width=".9"/>'
    f'<circle cx="{pt(48,17)[0]:.1f}" cy="{pt(48,17)[1]:.1f}" r="2.5" fill="#d3dade" stroke="#124560" stroke-width=".9"/>'
    f'<line x1="{pt(40,0)[0]:.1f}" y1="-5" x2="{pt(54,0)[0]:.1f}" y2="-5" stroke="#124560" stroke-opacity=".5" stroke-width="1"/>'
    f'<line x1="{pt(40,0)[0]:.1f}" y1="5" x2="{pt(54,0)[0]:.1f}" y2="5" stroke="#124560" stroke-opacity=".5" stroke-width="1"/>'
)

# ---------------- rotating layer B: spokes, hub, lug nuts, valve ----------------
sp = []
for i in range(5):
    ac = -90 + i * 72
    # web that joins each twin-spoke pair near the hub
    sp.append(poly([pt(24, ac - 14), pt(40, ac - 11), pt(40, ac + 11), pt(24, ac + 14)], fill="url(#gSp)", stroke="#3c444b", stroke_width="1.1", stroke_linejoin="round"))
    for off in (-10, 10):
        a = ac + off
        body = [pt(24, a - 4.6), pt(60, a - 5.6), pt(60, a + 5.6), pt(24, a + 4.6)]
        shadow = [(x + 1.6, y + 2.3) for x, y in body]
        sp.append(poly(shadow, fill="#000", fill_opacity=".5"))
        sp.append(poly(body, fill="url(#gSp)", stroke="#3c444b", stroke_width="1.3", stroke_linejoin="round"))
        foot = [pt(55, a - 7.2), pt(61.5, a - 7.6), pt(61.5, a + 7.6), pt(55, a + 7.2)]
        sp.append(poly(foot, fill="#8f989f", stroke="#3c444b", stroke_width=".9", stroke_linejoin="round"))
        x1, y1 = pt(27, a)
        x2, y2 = pt(57, a)
        sp.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="#fff" stroke-opacity=".8" stroke-width="1.2" stroke-linecap="round"/>')
        xl1, yl1 = pt(26, a + 3.3)
        xl2, yl2 = pt(58, a + 4.2)
        sp.append(f'<line x1="{xl1:.1f}" y1="{yl1:.1f}" x2="{xl2:.1f}" y2="{yl2:.1f}" stroke="#4a535a" stroke-opacity=".7" stroke-width=".9"/>')
def _nut(i):
    cx, cy = pt(14, -90 + i * 72)
    hexa = [(cx + 4.4 * math.cos(math.radians(k * 60)), cy + 4.4 * math.sin(math.radians(k * 60))) for k in range(6)]
    return (poly(hexa, fill="url(#gNut)", stroke="#2f363c", stroke_width=".9", stroke_linejoin="round")
            + f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="1.4" fill="#2a3036"/>')


nuts = ''.join(_nut(i) for i in range(5))
valve = ('<g transform="rotate(58)"><rect x="52" y="-1.5" width="14" height="3" rx="1.2" fill="#14181c"/>'
         '<rect x="64.5" y="-2" width="4.6" height="4" rx="1" fill="#cbd2d8" stroke="#2f363c" stroke-width=".6"/></g>')
tyreB = (f'<g id="rotB">{"".join(sp)}{valve}<circle r="26" fill="url(#gHub)" stroke="#2f363c" stroke-width="2"/>'
         '<circle r="21.5" fill="none" stroke="#000" stroke-opacity=".5" stroke-width="1"/>'
         '<circle r="20.2" fill="none" stroke="#e9eef2" stroke-opacity=".6" stroke-width=".7"/>'
         f'{nuts}<circle r="9.2" fill="url(#gCap)" stroke="#124560" stroke-width="1.7"/>'
         '<circle r="6.6" fill="none" stroke="#fff" stroke-opacity=".85" stroke-width=".9"/>'
         '<text x="0" y="3" text-anchor="middle" font-family="Arial Black,Arial,sans-serif" font-weight="900" font-size="8.2" fill="#fff">R</text></g>')

# ---------------- static highlights (light stays fixed while the wheel spins) ----------------
hi = ('<g id="hi">'
      '<path d="M-62 -52 A65 65 0 0 1 -26 -60" fill="none" stroke="#fff" stroke-opacity=".9" stroke-width="2.6" stroke-linecap="round"/>'
      '<path d="M-70 -38 A80 80 0 0 1 -50 -64" fill="none" stroke="#fff" stroke-opacity=".38" stroke-width="4.4" stroke-linecap="round"/>'
      '<path d="M-78 -22 A82 82 0 0 1 -73 -34" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="3" stroke-linecap="round"/>'
      '<path d="M32 62 A70 70 0 0 0 58 36" fill="none" stroke="#7fcdf5" stroke-opacity=".7" stroke-width="2.4" stroke-linecap="round"/>'
      '<path d="M40 74 A85 85 0 0 0 66 52" fill="none" stroke="#6fc3ee" stroke-opacity=".4" stroke-width="3.4" stroke-linecap="round"/>'
      '<path d="M-47 -49 L-45 -55 L-43 -49 L-37 -47 L-43 -45 L-45 -39 L-47 -45 L-53 -47 Z" fill="#fff" fill-opacity=".95"/>'
      '</g>')

defs = (
    '<linearGradient id="gSp" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f7fafc"/><stop offset=".5" stop-color="#b7c0c7"/><stop offset="1" stop-color="#6c767e"/></linearGradient>'
    '<radialGradient id="gSide" cx="50%" cy="50%" r="50%"><stop offset=".72" stop-color="#101113"/><stop offset=".9" stop-color="#1f2024"/><stop offset="1" stop-color="#2b2c31"/></radialGradient>'
    '<radialGradient id="gHub" cx="38%" cy="32%" r="75%"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#b8c1c8"/><stop offset="1" stop-color="#5d666d"/></radialGradient>'
    '<linearGradient id="gLip" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f6f9fb"/><stop offset=".4" stop-color="#9aa3aa"/><stop offset=".7" stop-color="#4b545b"/><stop offset="1" stop-color="#c9d0d6"/></linearGradient>'
    '<linearGradient id="gLip2" x1="1" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e2e8ec"/><stop offset=".5" stop-color="#7b848b"/><stop offset="1" stop-color="#e9eef2"/></linearGradient>'
    '<radialGradient id="gBarrel" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#0b0e12"/><stop offset=".7" stop-color="#1b2128"/><stop offset="1" stop-color="#3a424b"/></radialGradient>'
    '<radialGradient id="gDisc" cx="50%" cy="50%" r="50%"><stop offset=".55" stop-color="#7d868e"/><stop offset=".8" stop-color="#a9b2b9"/><stop offset="1" stop-color="#66707a"/></radialGradient>'
    '<radialGradient id="gHat" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#151a1e"/><stop offset="1" stop-color="#2b3238"/></radialGradient>'
    '<linearGradient id="gNut" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f1f5f7"/><stop offset="1" stop-color="#7a848c"/></linearGradient>'
    '<radialGradient id="gCap" cx="38%" cy="30%" r="80%"><stop offset="0" stop-color="#7acdf6"/><stop offset=".6" stop-color="#3997CD"/><stop offset="1" stop-color="#1f6a96"/></radialGradient>'
    '<linearGradient id="gCal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5bb4e4"/><stop offset=".55" stop-color="#3997CD"/><stop offset="1" stop-color="#216d99"/></linearGradient>'
)
