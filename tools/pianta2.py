# -*- coding: utf-8 -*-
"""Pianta dell'osservatorio Astrochill - ridisegnata sulla mappa di Federico."""
from PIL import Image, ImageDraw, ImageFont
from geometria import (PERIMETRO, INTERNI, APERTURE, K as _K, superfici, DOME_R,
                       H as H_GEO, H_TETTO, SP_TETTO, H_DOME_BASE)

SUP = superfici()   # le superfici si misurano sulla geometria, non si scrivono a mano

K = _K           # dimezzamento della pianta (da geometria.py: fonte unica)
S = 52           # px per metro-originale (S*K = 26 px per metro reale)
MX, MY = 95, 135
W, H = 38.0, 19.0
IMG_W, IMG_H = int(MX * 2 + W * K * S + 70), int(MY + H * K * S + 250)

def px(x): return int(MX + x * K * S)
def py(z): return int(MY + z * K * S)

img = Image.new("RGB", (IMG_W, IMG_H), "#FFFFFF")
d = ImageDraw.Draw(img)

def font(sz, bold=False):
    for n in (["arialbd.ttf"] if bold else ["arial.ttf"]):
        try: return ImageFont.truetype("C:/Windows/Fonts/" + n, sz)
        except Exception: pass
    return ImageFont.load_default()

F_ROOM, F_MQ, F_SM, F_TIT, F_SUB = font(15, True), font(12), font(11), font(26, True), font(13)
INK, GREY, WALL = "#1A1A1A", "#6B6B6B", "#1A1A1A"
COL = {"lavoro": "#DCE9F5", "servizi": "#EDEDED", "segreta": "#F3DEDE",
       "pubblico": "#E4EFDC", "transito": "#F8F8F8", "arredo": "#E8DFC8",
       "abitare": "#FBF0DC"}


# ------------------------------------------------- campiture
AREE = [
    (0, 0, 10.4, 13, "lavoro"),        # sala cupola
    (10.4, 0, 16.5, 8.8, "lavoro"),    # stanza controllo pc
    (0, 13, 3.9, 19, "transito"),      # disimpegno ovest
    (3.9, 13, 6.7, 19, "segreta"),     # allargata a 1,20 m di luce
    (6.7, 13, 9.8, 19, "servizi"),
    (9.8, 13, 16.5, 19, "servizi"),
    (10.4, 8.8, 16.5, 13, "transito"), # corridoio, profondo 2,1 m
    (16.5, 3, 38, 19, "pubblico"),     # grande spazio
    (16.5, 3, 26.8, 8.2, "abitare"),   # cucina
    (26.8, 3, 29.3, 9.5, "segreta"),
]
for x0, z0, x1, z1, cat in AREE:
    d.rectangle([px(x0), py(z0), px(x1), py(z1)], fill=COL[cat])

# ------------------------------------------------- cupola
cx, cz, r = 5.2, 5.0, 5.0
bb = [px(cx - r), py(cz - r), px(cx + r), py(cz + r)]
for a in range(0, 360, 6):
    if (a // 6) % 2 == 0:
        d.arc(bb, a, a + 6, fill="#7A96AE", width=3)
# passerella anulare attorno al telescopio (raggio 3,4 m, larghezza 1,2)
rp_e, rp_i = 3.4, 2.2
d.ellipse([px(cx - rp_e), py(cz - rp_e), px(cx + rp_e), py(cz + rp_e)], fill="#CBD9E4", outline="#6A8AA6", width=2)
d.ellipse([px(cx - rp_i), py(cz - rp_i), px(cx + rp_i), py(cz + rp_i)], fill=COL["lavoro"], outline="#6A8AA6", width=2)
# scala di risalita alla passerella
for i in range(6):
    yy = py(cz + rp_i + 0.12 + i * 0.22)
    d.line([px(cx) - 12, yy, px(cx) + 12, yy], fill="#6A8AA6", width=2)
# montatura fissa: pilastro nel pavimento + tubo del telescopio
d.rectangle([px(cx) - 8, py(cz) - 62, px(cx) + 8, py(cz) + 2], fill="#B9CBDB", outline="#5A7A96", width=2)
d.ellipse([px(cx) - 13, py(cz) - 13, px(cx) + 13, py(cz) + 13], fill="#8FA8BE", outline="#3A5A76", width=3)
d.line([px(cx), py(cz - r), px(cx), py(cz - r) + 24], fill="#7A96AE", width=3)
d.text((px(cx) + 12, py(cz - r) + 3), "fenditura", font=F_SM, fill="#5A7A96")
d.text((px(cx) + 17, py(cz) - 4), "pilastro", font=F_SM, fill="#3A5A76")
d.text((px(cx - 1.2), py(cz + rp_e + 0.55)), "passerella anulare", font=F_SM, fill="#3A5A76")

# ------------------------------------------------- muri interni
for x0, z0, x1, z1 in INTERNI:
    d.line([px(x0), py(z0), px(x1), py(z1)], fill=WALL, width=4)

for x0, z0, x1, z1 in PERIMETRO:
    d.line([px(x0), py(z0), px(x1), py(z1)], fill=WALL, width=7)

# ------------------------------------------------- arredi fissi
def arredo(x0, z0, x1, z1, testo, sotto=False):
    d.rectangle([px(x0), py(z0), px(x1), py(z1)], fill=COL["arredo"], outline="#8A7A50", width=2)
    w = d.textlength(testo, font=F_SM)
    yy = py((z0 + z1) / 2.0) - 6 if not sotto else py(z1) + 5
    d.text((px((x0 + x1) / 2.0) - w / 2, yy), testo, font=F_SM, fill="#6A5A30")

arredo(19.6, 8.2, 26.8, 10.0, "libreria di astronomia")
arredo(25.2, 17.2, 38, 19, "bacheca: meteoriti e reperti")
arredo(16.5, 14.0, 18.4, 19, "")
d.text((px(18.8), py(15.4)), "distributore", font=F_SM, fill="#6A5A30")
d.text((px(18.8), py(16.0)), "snack", font=F_SM, fill="#6A5A30")

# ------------------------------------------------- aperture
def porta(x, z, orient, w=1.4):
    w = w / K   # la larghezza e' reale, il disegno e' in metri-originali
    if orient == "h":
        d.line([px(x), py(z), px(x + w), py(z)], fill="#FFFFFF", width=9)
        d.arc([px(x), py(z) - w * K * S, px(x + 2 * w), py(z) + w * K * S], 180, 270, fill="#8A8A8A", width=2)
        d.line([px(x), py(z), px(x), py(z - w)], fill="#8A8A8A", width=2)
    else:
        d.line([px(x), py(z), px(x), py(z + w)], fill="#FFFFFF", width=9)
        d.arc([px(x) - w * K * S, py(z), px(x) + w * K * S, py(z + 2 * w)], 270, 0, fill="#8A8A8A", width=2)
        d.line([px(x), py(z), px(x + w), py(z)], fill="#8A8A8A", width=2)


def finestra(x, z, lung, orient, interna=False):
    lung = lung / K
    col = "#2A7A9A" if interna else "#4A6E8A"
    sp = 4 if interna else 3
    if orient == "h":
        d.line([px(x), py(z), px(x + lung), py(z)], fill="#FFFFFF", width=9)
        d.line([px(x), py(z) - sp, px(x + lung), py(z) - sp], fill=col, width=2)
        d.line([px(x), py(z) + sp, px(x + lung), py(z) + sp], fill=col, width=2)
    else:
        d.line([px(x), py(z), px(x), py(z + lung)], fill="#FFFFFF", width=9)
        d.line([px(x) - sp, py(z), px(x) - sp, py(z + lung)], fill=col, width=2)
        d.line([px(x) + sp, py(z), px(x) + sp, py(z + lung)], fill=col, width=2)

for (_x, _z, _w, _o, _t, _n) in APERTURE:
    if _t == "porta":
        porta(_x, _z, _o, _w)
    else:
        finestra(_x, _z, _w, _o, interna=(_t == "vetrata"))
d.text((px(11.0), py(7.2)), "vetrata", font=F_SM, fill="#2A7A9A")

# pannellature chiuse delle due stanze segrete
for xa, za, orient in [(4.8, 13, "h"), (26.8, 6.0, "v")]:
    for i in range(5):
        if orient == "h":
            d.line([px(xa + i * 0.24), py(za) - 5, px(xa + i * 0.24), py(za) + 5], fill="#B03030", width=3)
        else:
            d.line([px(xa) - 5, py(za + i * 0.24), px(xa) + 5, py(za + i * 0.24)], fill="#B03030", width=3)

# ------------------------------------------------- etichette
def label(x, z, nome, mq=None, ruota=False, col=INK):
    if ruota:
        tw = int(d.textlength(nome, font=F_MQ)) + 8
        tmp = Image.new("RGBA", (tw, F_MQ.size + 8), (255, 255, 255, 0))
        ImageDraw.Draw(tmp).text((4, 2), nome, font=F_MQ, fill=col)
        tmp = tmp.rotate(90, expand=True)
        img.paste(tmp, (int(px(x) - tmp.width / 2), int(py(z) - tmp.height / 2)), tmp)
        if mq:
            t = ("%.1f m2" if mq < 10 else "%.0f m2") % mq
            tw2 = int(d.textlength(t, font=F_SM)) + 8
            tmp2 = Image.new("RGBA", (tw2, F_SM.size + 8), (255, 255, 255, 0))
            ImageDraw.Draw(tmp2).text((4, 2), t, font=F_SM, fill=GREY)
            tmp2 = tmp2.rotate(90, expand=True)
            img.paste(tmp2, (int(px(x) + 16 - tmp2.width / 2), int(py(z) - tmp2.height / 2)), tmp2)
    else:
        w = d.textlength(nome, font=F_ROOM)
        d.text((px(x) - w / 2, py(z) - 16), nome, font=F_ROOM, fill=col)
        if mq:
            t = ("%.1f m2" if mq < 10 else "%.0f m2") % mq
            w2 = d.textlength(t, font=F_MQ)
            d.text((px(x) - w2 / 2, py(z) + 3), t, font=F_MQ, fill=GREY)

label(5.2, 11.2, "CUPOLA E TELESCOPIO", SUP["sala del telescopio"])
label(13.4, 4.4, "CONTROLLO PC", SUP["controllo pc"])
label(13.45, 11.0, "corridoio", SUP["corridoio"], col=GREY)
label(13.1, 16.0, "BAGNO", SUP["bagno"])
label(8.25, 16.0, "MAGAZZINO", SUP["magazzino"], ruota=True)
label(5.35, 16.0, "SEGRETA", SUP["segreta ovest"], ruota=True, col="#8A3030")
label(28.05, 6.2, "SEGRETA", SUP["segreta est"], ruota=True, col="#8A3030")
label(21.6, 5.6, "CUCINA", SUP["cucina"])
label(30.5, 13.5, "SPAZIO DIVULGAZIONE", SUP["spazio divulgazione"], col=INK)
label(1.95, 16.0, "disimp.", SUP["disimpegno"], ruota=True, col=GREY)
d.text((px(1.0), py(4.4)), "cupola", font=F_SM, fill="#5A7A96")
d.text((px(1.0), py(5.1)), "\u00f8 %.0f m" % (DOME_R * 2), font=F_SM, fill="#5A7A96")

# ------------------------------------------------- quote
def quota(x0, x1, z, testo, dy):
    y = py(z) + dy
    d.line([px(x0), y, px(x1), y], fill=GREY, width=1)
    for xx in (x0, x1):
        d.line([px(xx), y - 5, px(xx), y + 5], fill=GREY, width=1)
        d.line([px(xx), y, px(xx), py(z)], fill="#C8C8C8", width=1)
    w = d.textlength(testo, font=F_SM)
    m = (x0 + x1) / 2.0
    d.rectangle([px(m) - w / 2 - 3, y - 8, px(m) + w / 2 + 3, y + 8], fill="#FFFFFF")
    d.text((px(m) - w / 2, y - 7), testo, font=F_SM, fill=GREY)

def quota_v(z0, z1, x, testo, dx):
    xq = px(x) + dx
    d.line([xq, py(z0), xq, py(z1)], fill=GREY, width=1)
    for zz in (z0, z1):
        d.line([xq - 5, py(zz), xq + 5, py(zz)], fill=GREY, width=1)
        d.line([xq, py(zz), px(x), py(zz)], fill="#C8C8C8", width=1)
    w = d.textlength(testo, font=F_SM)
    m = (z0 + z1) / 2.0
    d.rectangle([xq - w / 2 - 3, py(m) - 8, xq + w / 2 + 3, py(m) + 8], fill="#FFFFFF")
    d.text((xq - w / 2, py(m) - 7), testo, font=F_SM, fill=GREY)

quota(0, 38, 0, "19,00", -46)
quota(0, 16.5, 19, "8,25", 92)
quota(16.5, 38, 19, "10,75", 92)
quota_v(0, 19, 0, "9,50", -52)
quota_v(0, 3, 38, "1,50", 52)

# nord
nx, ny = IMG_W - 78, MY + 20
d.line([nx, ny + 38, nx, ny - 20], fill=INK, width=3)
d.polygon([(nx, ny - 30), (nx - 9, ny - 12), (nx + 9, ny - 12)], fill=INK)
d.text((nx - 7, ny + 42), "N", font=F_ROOM, fill=INK)

# ingresso
d.text((px(27.5), py(19.9)), "\u2190 INGRESSO", font=font(13, True), fill="#3A6E3A")
d.text((px(27.5), py(20.7)), "20 m fino al cancello e all'auto", font=F_SM, fill="#3A6E3A")

# titolo
d.text((MX, 30), "OSSERVATORIO \u2014 PIANTA", font=F_TIT, fill=INK)
d.text((MX, 66), "19 \u00d7 9,5 m \u00b7 ~164 m\u00b2 coperti, %.0f calpestabili \u00b7 un piano \u00b7 edificio a L" % sum(SUP.values()), font=F_SUB, fill=GREY)

ly = MY + int(H * K * S) + 118
d.text((MX, ly), "NOTA:", font=font(13, True), fill="#B03030")
d.text((MX + 110, ly), "porte e finestre sono a MISURA VERA e non seguono la scala dell'edificio — come l'auto e i soffitti.",
       font=F_SM, fill="#B03030")
ly2 = ly + 26
d.text((MX, ly2), "Percorsi:  monitor → telescopio 5 m / 2 s   ·   monitor → bagno 6,5 m / 3 s   ·   monitor → moka 8 m / 3 s   ·   monitor → ingresso 9 m / 4 s   ·   passo 2,5 m/s", font=F_SM, fill=GREY)
d.text((MX, ly2 + 22), ("Quote verticali (NON scalate): soffitto %.2f · tetto %.2f-%.2f · cupola ø %.2f "
     "con colmo a %.2f · porte 2,10 · davanzali 1,00." % (H_GEO, H_TETTO, H_TETTO + SP_TETTO, DOME_R * 2, H_DOME_BASE + DOME_R)),
       font=F_SM, fill=GREY)
d.text((MX, ly2 + 44), "Grigio = porte   ·   blu = finestre   ·   azzurro = vetrata interna PC/cupola   ·   rosso = pannellatura chiusa   ·   beige = arredi fissi",
       font=F_SM, fill=GREY)

bx, by = IMG_W - 330, ly2 + 76
d.line([bx, by, bx + int(10 * S * K), by], fill=INK, width=3)
for i in range(11):
    d.line([bx + int(i * S * K), by - 5, bx + int(i * S * K), by + 5], fill=INK, width=2 if i % 5 == 0 else 1)
d.text((bx - 4, by + 8), "0", font=F_SM, fill=INK)
d.text((bx + int(10 * S * K) - 16, by + 8), "10 m", font=F_SM, fill=INK)

out = r"E:\GIT\astrochills-gd-3d\_bmad-output\planning-artifacts\gdds\gdd-astrochills-gd-3d-2026-08-24\pianta-osservatorio.png"
img.save(out)
print("scritto:", out, img.size)
