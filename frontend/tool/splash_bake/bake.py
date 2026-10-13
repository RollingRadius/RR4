"""Bakes the splash-animation sprites (PNG) used by lib/presentation/screens/splash/.

The animated splash draws these sprites with a few cheap canvas calls instead of
rebuilding the vector art every frame (this is what keeps it smooth on low-end phones).

Run (needs Python 3 + Pillow + Chrome):  python tool/splash_bake/bake.py
Outputs to assest/splash/.
"""
import math
import os
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

import art

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
OUT = os.path.join(ROOT, 'assest', 'splash')
CHROME = os.environ.get('CHROME', r'C:\Program Files\Google\Chrome\Application\chrome.exe')
TMP = tempfile.mkdtemp(prefix='splash_bake_')

# Sprite geometry contract shared with lib/.../splash_sprites.dart
TYRE_PX, TYRE_UNITS = 512, 208            # tyre sprites: 512px cover 208 art units (centre = tyre centre)
TREAD_W, TREAD_H = 256, 1440              # tread texture: width = tread width (72 u), height = 360 degrees
SMOKE_CELL, SMOKE_STEPS, SMOKE_VARIANTS = 256, 7, 4
SMOKE_RB = 64                              # puff reference radius (px) inside a cell


def shoot(html, name, w, h):
    src = os.path.join(TMP, name + '.html')
    with open(src, 'w', encoding='utf-8') as f:
        f.write(html)
    out = os.path.join(OUT, name + '.png')
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--default-background-color=00000000', '--force-device-scale-factor=1',
                    f'--window-size={w},{h}', '--virtual-time-budget=3000',
                    f'--screenshot={out}', 'file:///' + src.replace('\\', '/')],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    im = Image.open(out)
    if im.size != (w, h):                      # headless can add a few px of chrome; crop to the exact size
        im = im.crop((0, 0, w, h))
    im.save(out)
    print('wrote', os.path.relpath(out, ROOT), im.size)


def svg_page(content, size=TYRE_PX, units=TYRE_UNITS):
    h = units / 2
    return (f'<html><body style="margin:0;background:transparent"><svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{size}" height="{size}" viewBox="{-h} {-h} {units} {units}"><defs>{art.defs}</defs>{content}</svg></body></html>')


def bake_tyre():
    shoot(svg_page(art.tyreA), 'tyre_a', TYRE_PX, TYRE_PX)
    shoot(svg_page(art.tyreB), 'tyre_b', TYRE_PX, TYRE_PX)
    shoot(svg_page(art.caliper), 'tyre_caliper', TYRE_PX, TYRE_PX)
    shoot(svg_page(art.hi), 'tyre_hi', TYRE_PX, TYRE_PX)


TREAD_JS = r'''
const W=%(W)d,H=%(H)d,HW=36,RIBS=4,RA=2*HW/RIBS,GA=2.6,SLANT=9,NB=18,PITCH=360/NB,HB=PITCH*0.36;
const kx=W/(2*HW), ky=H/360, ku=3;
const c=document.getElementById('c').getContext('2d');
function rnd(i,j,k){const v=Math.sin(i*127.1+j*311.7+k*74.7)*43758.5453;return v-Math.floor(v);}
c.fillStyle='#0a0a0c';c.fillRect(0,0,W,H);
const X=a=>(a+HW)*kx, Y=t=>t*ky;
for(let j=1;j<RIBS;j++){const ga=-HW+j*RA;
  c.fillStyle='#010102';c.fillRect(X(ga-GA/2),0,GA*kx,H);
  c.fillStyle='rgba(164,167,176,.5)';c.fillRect(X(ga+GA*.55)-.5,0,1.4,H);}
for(let j=0;j<RIBS;j++){
  const a0=-HW+j*RA+GA/2+.2,a1=-HW+(j+1)*RA-GA/2-.2,dir=j<RIBS/2?-1:1,ph=(RIBS-1-j)*PITCH*.37,d0=-dir*SLANT,d1=dir*SLANT;
  for(let i=0;i<NB;i++)for(const wrap of [-360,0,360]){
    const pc=i*PITCH+ph+wrap, lo=pc-HB, hi=pc+HB;
    if(hi+d1<-20||lo+d0>360+20&&lo+d1>360+20)continue;
    c.fillStyle='#464951';c.beginPath();
    c.moveTo(X(a0),Y(lo+d0));c.lineTo(X(a0),Y(hi+d0));c.lineTo(X(a1),Y(hi+d1));c.lineTo(X(a1),Y(lo+d1));c.closePath();c.fill();
    c.lineCap='round';
    c.strokeStyle='rgba(185,188,197,.85)';c.lineWidth=1.3*ku;c.beginPath();c.moveTo(X(a0),Y(hi+d0));c.lineTo(X(a1),Y(hi+d1));c.stroke();
    c.lineCap='butt';
    c.strokeStyle='rgba(9,9,11,.95)';c.lineWidth=1.6*ku;c.beginPath();c.moveTo(X(a0),Y(lo+d0));c.lineTo(X(a1),Y(lo+d1));c.stroke();
    c.strokeStyle='rgba(11,11,13,.9)';c.lineWidth=.9*ku;c.beginPath();
    c.moveTo(X(a0+.12*RA),Y(pc+d0*.8));c.lineTo(X(a1-.12*RA),Y(pc+d1*.8));c.stroke();
    for(let k=0;k<3;k++){const ap=a0+(a1-a0)*(.15+.7*rnd(i,j,k)), pp=lo+(hi-lo)*(.2+.6*rnd(i,j,k+9));
      c.fillStyle='rgba(108,111,119,.5)';c.beginPath();c.arc(X(ap),Y(pp),.55*ku,0,6.2832);c.fill();}
  }
}
'''


def bake_tread():
    html = (f'<html><body style="margin:0;background:#0a0a0c"><canvas id="c" width="{TREAD_W}" height="{TREAD_H}" '
            f'style="display:block"></canvas><script>{TREAD_JS % dict(W=TREAD_W, H=TREAD_H)}</script></body></html>')
    shoot(html, 'tread', TREAD_W, TREAD_H)


SMOKE_JS = r'''
const CELL=%(CELL)d,STEPS=%(STEPS)d,VARS=%(VARS)d,RB=%(RB)d;
const clamp=(v,a=0,b=1)=>Math.min(b,Math.max(a,v));
function rnd(i,j,k){const v=Math.sin(i*127.1+j*311.7+k*74.7)*43758.5453;return v-Math.floor(v);}
const mixc=(a,b,k)=>{const p=h=>[1,3,5].map(i=>parseInt(h.slice(i,i+2),16));const A=p(a),B=p(b);
  return '#'+A.map((v,i)=>Math.round(v+(B[i]-v)*k).toString(16).padStart(2,'0')).join('');};
const cv=document.getElementById('c'),c=cv.getContext('2d');
const IDX=[2,3,6,9];
for(let v=0;v<VARS;v++)for(let s=0;s<STEPS;s++){
  const i=IDX[v],k=s/(STEPS-1)*.92,cx0=s*CELL+CELL/2,cy0=v*CELL+CELL/2;
  const cOut=mixc('#0a1017','#34414f',k),cBase=mixc('#2a3644','#566679',k),cMid=mixc('#3a4959','#6f8196',k),cLit=mixc('#506074','#9aabbd',k);
  const sw=(i%%2?1:-1)*k*1.1,rb=RB,grow=1,L=[];
  for(let l=0;l<6;l++){
    const ang=rnd(i,l,1)*6.2832+sw,dist=rb*.62*rnd(i,l,2)*grow,lr=rb*grow*(.42+.32*rnd(i,l,3)),ld=rnd(i,l,4);
    const m=1-clamp((k-.4-.38*ld)/.3);if(m<=.03)continue;
    L.push({x:cx0+Math.cos(ang)*dist,y:cy0+Math.sin(ang)*dist*.8-lr*.1,r:lr*m});}
  const fill=(col,f)=>{c.fillStyle=col;L.forEach(o=>{const q=f(o);c.beginPath();c.arc(q[0],q[1],q[2],0,6.2832);c.fill();});};
  fill(cOut,o=>[o.x,o.y,o.r+3]);fill(cBase,o=>[o.x,o.y,o.r]);
  fill(cMid,o=>[o.x-o.r*.16,o.y-o.r*.2,o.r*.78]);
  c.globalAlpha=.8;fill(cLit,o=>[o.x-o.r*.34,o.y-o.r*.4,o.r*.4]);c.globalAlpha=1;
}
'''


def bake_smoke():
    w, h = SMOKE_CELL * SMOKE_STEPS, SMOKE_CELL * SMOKE_VARIANTS
    js = SMOKE_JS % dict(CELL=SMOKE_CELL, STEPS=SMOKE_STEPS, VARS=SMOKE_VARIANTS, RB=SMOKE_RB)
    html = (f'<html><body style="margin:0;background:transparent"><canvas id="c" width="{w}" height="{h}" '
            f'style="display:block"></canvas><script>{js}</script></body></html>')
    shoot(html, 'smoke', w, h)


def bake_wordmark():
    """The brand wordmark, cut from the existing logo PNG and converted to a transparent black-on-alpha sprite."""
    src = Image.open(os.path.join(ROOT, 'assest', 'images', 'app-logo-with-name.png')).convert('L')
    a = 255 - np.array(src).astype(int)
    a[:, :195] = 0                                      # drop the road strip of the mark on the left
    ytop = int(np.where(a[:, 380:] > 60)[0].min())      # text top, measured right of the wheel
    a[:max(0, ytop - 3), :] = 0                         # drop the road/wheel mark above the text
    ys, xs = np.where(a > 60)
    x0, x1, y0, y1 = xs.min() - 4, xs.max() + 4, ys.min() - 4, ys.max() + 4
    crop = a[y0:y1, x0:x1].clip(0, 255).astype('uint8')
    rgba = np.zeros(crop.shape + (4,), 'uint8')
    rgba[..., 3] = crop
    im = Image.fromarray(rgba, 'RGBA')
    im = im.resize((640, round(640 * im.size[1] / im.size[0])), Image.LANCZOS)
    path = os.path.join(OUT, 'wordmark.png')
    im.save(path)
    print('wrote', os.path.relpath(path, ROOT), im.size)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    bake_tyre()
    bake_tread()
    bake_smoke()
    bake_wordmark()
    print('done')
