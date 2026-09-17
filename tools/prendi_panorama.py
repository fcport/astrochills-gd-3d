# -*- coding: utf-8 -*-
"""Il panorama attorno all'osservatorio: il terreno vero di Monte San Lorenzo.

    python tools/prendi_panorama.py

NIENTE COLLINE INVENTATE. L'osservatorio esiste (Monte Grimano Terme, Pesaro e Urbino),
e quello che si vede dal suo prato e' misurato: le quote, il colore dei campi e dei
boschi, le sterrate, i paesi. Qui si scaricano quelle misure e si trasformano in quello
che serve a `world/panorama.gd` per costruirsi all'avvio.

DA DOVE, e i crediti stanno in CREDITI.md:
  * TINITALY 1.1 (INGV, CC-BY 4.0): il modello del TERRENO a dieci metri, la tessera
    w48575. E' il terreno nudo, senza alberi: serve vicino, dove ci si cammina sopra.
  * Copernicus DEM GLO-30 (ESA/Airbus, licenza Copernicus): la SUPERFICIE a trenta
    metri, per lontano. Copre anche dove TINITALY finisce, e dove le due si
    sovrappongono si passa dall'una all'altra in due chilometri.
  * Sentinel-2 L2A (Copernicus, dati aperti): la scena del 19 novembre 2020, alle
    10:18, praticamente senza nuvole. Novembre perche' e' il mese del gioco: i boschi
    sono spogli e i campi arati, non l'estate del mosaico medio.
  * ESA WorldCover 2021 (CC-BY 4.0): dove sono gli alberi e dove le case, a dieci metri.
  * OpenStreetMap (ODbL): le strade, e la posizione dell'edificio.

COSA SE NE FA, e ogni passo c'e' perche' un dato non e' un paesaggio:

  * L'OSSERVATORIO VERO STA DOVE STA QUELLO DEL GIOCO, E GIRATO COME LUI. Il baricentro
    dell'edificio in OSM coincide col centro della pianta (`geometria.PERIMETRO`). Il
    nord vero sta a `geometria.NORD` gradi da +Z, come per il cielo (`Luna.direzione`):
    l'edificio vero ha il lato lungo a quarantacinque gradi, e nel gioco sta lungo x.
  * IL PAVIMENTO NON STA SUL RILIEVO. TINITALY a dieci metri e' il pendio di prima
    della casa. Le foto dicono che lo slargo davanti al cancello sta un metro sopra il
    pavimento (`geometria.STRADA_SUL_PAVIMENTO`): lo zero del gioco e' la quota dello
    slargo meno quel metro.
  * LE DISTANZE SONO QUELLE VERE DALL'OSSERVATORIO: ogni punto del gioco diventa
    latitudine e longitudine con una proiezione azimutale equidistante, che conserva
    esattamente distanza e direzione da chi guarda - ed e' tutto quello che un
    panorama chiede. La Terra curva si toglie in altezza, con la rifrazione solita
    (k = 0,13): a trenta chilometri sono sessanta metri, e senza le montagne lontane
    starebbero troppo alte.
  * DA LONTANO SI FA LA MEDIA, NON SI PESCA. Un vertice a quaranta chilometri copre un
    chilometro di terreno: si legge la quota media di quel chilometro, non quella del
    pixel che capita sotto, o il profilo delle creste tremolerebbe di cento metri.
  * SI TOGLIE LA LUCE DELLA FOTO, come in `prendi_pelle.py`. Il satellite ha visto
    l'Appennino con il Sole a ventisei gradi, e i versanti a nord sono scuri nella
    foto: in gioco li illumina la Luna, e la foto li renderebbe scuri due volte. Si
    divide per l'ombreggiatura calcolata dal rilievo con il Sole di quella mattina.
  * IL COLORE E' RIFLETTANZA. La TCI di Sentinel-2 e' la riflettanza da 0 a 0,2 su
    0-255, lineare: si converte in sRGB, che e' quello che una texture di albedo e'.

SCRIVE in assets/panorama/:
  * panorama.tres           le quote vicine (griglia) e lontane (anelli), dove stanno
                            gli alberi e le luci dei paesi
  * vicino_colore.jpg       il satellite sui 1600 m attorno, in assi di gioco
  * lontano_colore.jpg      il satellite sui 60 km attorno
  * vicino_maschere.png     rosso: sterrate; verde: bosco; blu: asfalto
  * FONTE.txt, e i .import con le mipmap.

La cartella dei download e' tools/__panorama_cache__ (settecento megabyte, ignorata da
git): cancellarla vuol dire riscaricare.
"""
import io
import math
import os
import sys
import urllib.request
import warnings
import xml.etree.ElementTree as ET
import zipfile
import zlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
CACHE = os.path.join(QUI, "__panorama_cache__")
DEST = os.path.join(RADICE, "assets", "panorama")
sys.path.insert(0, QUI)
import geometria as G  # noqa: E402

Image.MAX_IMAGE_PIXELS = None
NL = chr(10)

# ------------------------------------------------------------------ dove
# L'EDIFICIO IN OPENSTREETMAP: way 'Osservatorio Monte San Lorenzo', man_made=observatory,
# baricentro dei quattro vertici. Lo script lo rilegge dal file OSM e si ferma se non torna.
ANCORA_LAT, ANCORA_LON = 43.84860, 12.47988
# Il centro della pianta del gioco, dagli spigoli del perimetro.
_PX = [v * G.K for s in G.PERIMETRO for v in (s[0], s[2])]
_PZ = [v * G.K for s in G.PERIMETRO for v in (s[1], s[3])]
ANCORA_GIOCO = ((min(_PX) + max(_PX)) / 2.0, (min(_PZ) + max(_PZ)) / 2.0)

# ------------------------------------------------------------------ quanto
# LA GRIGLIA VICINA: il terreno su cui si cammina e su cui stanno gli alberi veri.
# Cinque metri di passo su un rilievo da dieci: fra un dato e l'altro la superficie
# si interpola con una bicubica, e i versanti non fanno le pieghe della bilineare.
VICINO_MEZZO = 800.0
VICINO_PASSO = G.PASSO_RILIEVO
# GLI ANELLI LONTANI, da dove finisce la griglia fino all'ultima cresta che conta.
# Settecentoventi settori, mezzo grado l'uno; ogni anello e' il due per cento piu'
# largo del precedente, cosi' un quadrilatero ha sempre la stessa forma a qualunque
# distanza. Cominciano un centinaio di metri dentro la griglia: la sovrapposizione
# e' quella che nasconde la cucitura.
LONTANO_DA = 700.0
LONTANO_A = 45000.0
SETTORI = 720
CRESCITA = 0.02
# Il raggio terrestre e la rifrazione standard per la caduta dell'orizzonte.
RAGGIO_TERRA = 6371000.0
RIFRAZIONE = 0.13
# LE IMMAGINI
COLORE_VICINO_PX = 1024
COLORE_LONTANO_MEZZO = 30000.0
COLORE_LONTANO_PX = 4096
MASCHERE_PX = 2048
# Il Sole della scena Sentinel-2 (dal catalogo STAC della scena)
SOLE_AZIMUT, SOLE_ALTEZZA = 170.0, 26.07
# QUANTO LA FOTO DIPENDE DALL'OMBRA, misurato e non supposto: sui sedici chilometri
# attorno la luminanza va come l'ombreggiatura alla 0,39 (regressione in logaritmi),
# perche' metà della luce di una mattina di novembre e' cielo e non Sole. Dividere per
# tutta l'ombra rovesciava il rilievo: la correlazione con l'ombra passava da +0,19 a
# -0,40, e i versanti a nord uscivano chiari. Con 0,35 va a zero.
SOLE_ESPONENTE = 0.35

# GLI ALBERI: dove WorldCover dice «copertura arborea», un albero ogni tanti metri,
# fino a questa distanza. Oltre, il bosco lo fa il colore del satellite.
ALBERI_MEZZO = 1500.0
ALBERI_PASSO = 7.0
# LE LUCI: i paesi fino a questa distanza, una luce per cella dove ci sono case.
LUCI_RAGGIO = 30000.0
LUCI_CELLA = 40.0
OCCHIO = 1.7

TINITALY = ("w48575_s10", "https://tinitaly.pi.ingv.it/data_1.1/w48575_s10/w48575_s10.zip")
COPERNICUS = ["N43_00_E011_00", "N43_00_E012_00", "N43_00_E013_00",
              "N44_00_E011_00", "N44_00_E012_00", "N44_00_E013_00"]
SENTINEL = ("S2B_32TQP_20201119_1_L2A_TCI.tif",
            "https://sentinel-cogs.s3.us-west-2.amazonaws.com/sentinel-s2-l2a-cogs/32/T/QP/"
            "2020/11/S2B_32TQP_20201119_1_L2A/TCI.tif")
WORLDCOVER = ("ESA_WorldCover_10m_2021_v200_N42E012_Map.tif",
              "https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map/"
              "ESA_WorldCover_10m_2021_v200_N42E012_Map.tif")
OSM = ("osm_vicino.osm",
       "https://api.openstreetmap.org/api/0.6/map?bbox=12.4489,43.8261,12.5109,43.8711")


def scarica(nome, url):
    via = os.path.join(CACHE, nome)
    if os.path.exists(via) and os.path.getsize(via) > 0:
        return via
    os.makedirs(CACHE, exist_ok=True)
    print("[panorama] scarico %s" % url)
    req = urllib.request.Request(url, headers={"User-Agent": "astrochills-panorama/1.0"})
    with urllib.request.urlopen(req, timeout=1800) as r, open(via + ".parte", "wb") as f:
        while True:
            pezzo = r.read(1 << 20)
            if not pezzo:
                break
            f.write(pezzo)
    os.replace(via + ".parte", via)
    return via


# ------------------------------------------------------------------ geodesia
# QUI SI GIRA IL MONDO, E SOLO QUI. `latlon` e `piano` parlano in metri dall'osservatorio
# LUNGO GLI ASSI DEL GIOCO (x, z), e dentro portano l'azimut da quello del gioco a quello
# vero: tutto il resto dello script - il rilievo, il satellite, le strade, gli alberi, le
# luci - passa da loro e gira insieme, senza saperlo.
NORD = math.radians(G.NORD)


def latlon(est, nord):
    """Dal piano del gioco (metri dall'osservatorio lungo x e z) alla Terra: azimutale
    equidistante."""
    f1, l1 = math.radians(ANCORA_LAT), math.radians(ANCORA_LON)
    d = np.hypot(est, nord)
    th = np.arctan2(est, nord) - NORD
    de = d / RAGGIO_TERRA
    f2 = np.arcsin(np.sin(f1) * np.cos(de) + np.cos(f1) * np.sin(de) * np.cos(th))
    l2 = l1 + np.arctan2(np.sin(th) * np.sin(de) * np.cos(f1), np.cos(de) - np.sin(f1) * np.sin(f2))
    return np.degrees(f2), np.degrees(l2)


def piano(lat, lon):
    """L'inverso di `latlon`: da latitudine e longitudine a metri lungo x e z del gioco."""
    f1, l1 = math.radians(ANCORA_LAT), math.radians(ANCORA_LON)
    f2, l2 = np.radians(lat), np.radians(lon)
    c = np.arccos(np.clip(np.sin(f1) * np.sin(f2) + np.cos(f1) * np.cos(f2) * np.cos(l2 - l1), -1, 1))
    th = np.arctan2(np.sin(l2 - l1) * np.cos(f2),
                    np.cos(f1) * np.sin(f2) - np.sin(f1) * np.cos(f2) * np.cos(l2 - l1))
    d = c * RAGGIO_TERRA
    return d * np.sin(th + NORD), d * np.cos(th + NORD)


def utm32(lat, lon):
    """UTM fuso 32 su WGS84: le coordinate di TINITALY e della scena Sentinel-2."""
    a = 6378137.0
    f = 1 / 298.257223563
    e2 = f * (2 - f)
    k0 = 0.9996
    ep2 = e2 / (1 - e2)
    phi = np.radians(lat)
    lam = np.radians(lon) - math.radians(9.0)
    n = a / np.sqrt(1 - e2 * np.sin(phi) ** 2)
    t = np.tan(phi) ** 2
    c = ep2 * np.cos(phi) ** 2
    aa = np.cos(phi) * lam
    e4, e6 = e2 * e2, e2 * e2 * e2
    m = a * ((1 - e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256) * phi
             - (3 * e2 / 8 + 3 * e4 / 32 + 45 * e6 / 1024) * np.sin(2 * phi)
             + (15 * e4 / 256 + 45 * e6 / 1024) * np.sin(4 * phi)
             - (35 * e6 / 3072) * np.sin(6 * phi))
    x = k0 * n * (aa + (1 - t + c) * aa ** 3 / 6 + (5 - 18 * t + t * t + 72 * c - 58 * ep2) * aa ** 5 / 120) + 500000
    y = k0 * (m + n * np.tan(phi) * (aa * aa / 2 + (5 - t + 9 * c + 4 * c * c) * aa ** 4 / 24
                                    + (61 - 58 * t + t * t + 600 * c - 330 * ep2) * aa ** 6 / 720))
    return x, y


def caduta(d):
    """Quanto la Terra curva abbassa un punto a `d` metri, rifrazione compresa."""
    return d * d / (2.0 * RAGGIO_TERRA / (1.0 - RIFRAZIONE))


# ------------------------------------------------------------------ griglie
class Griglia:
    """Un raster georiferito: `a` ha le righe da nord a sud, x0/y0 sono lo spigolo in
    alto a sinistra, dx/dy il lato del pixel. Con la piramide delle medie per leggere
    da lontano."""

    def __init__(self, a, x0, y0, dx, dy):
        self.livelli = [a.astype(np.float32)]
        self.x0, self.y0, self.dx, self.dy = x0, y0, dx, dy

    def piramide(self, quanti):
        while len(self.livelli) <= quanti:
            b = self.livelli[-1]
            h, w = (b.shape[0] // 2) * 2, (b.shape[1] // 2) * 2
            b = b[:h, :w].reshape(h // 2, 2, w // 2, 2, *b.shape[2:])
            with warnings.catch_warnings():
                warnings.simplefilter("ignore", RuntimeWarning)
                self.livelli.append(np.nanmean(b, axis=(1, 3)).astype(np.float32))

    def leggi(self, x, y, livello=0, cubica=False):
        a = self.livelli[livello]
        s = 2 ** livello
        r = (self.y0 - y) / (self.dy * s) - 0.5
        c = (x - self.x0) / (self.dx * s) - 0.5
        fuori = (r < 0) | (c < 0) | (r > a.shape[0] - 1) | (c > a.shape[1] - 1)
        r = np.clip(r, 0, a.shape[0] - 1.0001)
        c = np.clip(c, 0, a.shape[1] - 1.0001)
        r0, c0 = np.floor(r).astype(np.int64), np.floor(c).astype(np.int64)
        fr, fc = r - r0, c - c0
        if a.ndim == 3:
            fr, fc = fr[..., None], fc[..., None]
        if not cubica:
            v = (a[r0, c0] * (1 - fr) * (1 - fc) + a[r0, c0 + 1] * (1 - fr) * fc
                 + a[r0 + 1, c0] * fr * (1 - fc) + a[r0 + 1, c0 + 1] * fr * fc)
        else:
            def peso(t):
                # Catmull-Rom sui quattro campioni -1, 0, 1, 2
                return [((-t + 2) * t - 1) * t / 2, (((3 * t - 5) * t) * t + 2) / 2,
                        ((-3 * t + 4) * t + 1) * t / 2, ((t - 1) * t * t) / 2]
            wr, wc = peso(fr), peso(fc)
            v = 0
            for i in range(4):
                ri = np.clip(r0 + i - 1, 0, a.shape[0] - 1)
                riga = 0
                for j in range(4):
                    cj = np.clip(c0 + j - 1, 0, a.shape[1] - 1)
                    riga = riga + a[ri, cj] * wc[j]
                v = v + riga * wr[i]
        if a.ndim == 2:
            return np.where(fuori, np.nan, v)
        return np.where(fuori[..., None], np.nan, v)


def finestra_tiff(via, riga0, col0, righe, colonne):
    """Legge solo le tessere di un GeoTIFF a tessere che servono. PIL aprirebbe un
    36000 x 36000 intero; qui si prendono i pezzi, si scompattano e si rimettono in fila.
    Solo deflate, col predittore orizzontale o senza: sono i due file che servono."""
    im = Image.open(via)
    t = im.tag_v2
    larg, alt = t[256], t[257]
    tw, th = t[322], t[323]
    offs, lung = t[324], t[325]
    campioni = t.get(277, 1)
    assert t[259] == 8, "compressione %s non gestita" % t[259]
    predittore = t.get(317, 1)
    riga0, col0 = max(riga0, 0), max(col0, 0)
    righe, colonne = min(righe, alt - riga0), min(colonne, larg - col0)
    fuori = np.zeros((righe, colonne, campioni), np.uint8)
    per_riga = (larg + tw - 1) // tw
    with open(via, "rb") as f:
        for ty in range(riga0 // th, (riga0 + righe - 1) // th + 1):
            for tx in range(col0 // tw, (col0 + colonne - 1) // tw + 1):
                k = ty * per_riga + tx
                f.seek(offs[k])
                pezzo = np.frombuffer(zlib.decompress(f.read(lung[k])), np.uint8).reshape(th, tw, campioni)
                if predittore == 2:
                    pezzo = np.cumsum(pezzo, axis=1, dtype=np.uint8)
                ya, xa = ty * th, tx * tw
                r0, r1 = max(riga0, ya), min(riga0 + righe, ya + th)
                c0, c1 = max(col0, xa), min(col0 + colonne, xa + tw)
                fuori[r0 - riga0:r1 - riga0, c0 - col0:c1 - col0] = pezzo[r0 - ya:r1 - ya, c0 - xa:c1 - xa]
    return fuori, riga0, col0


def tinitaly():
    via = scarica(TINITALY[0] + ".zip", TINITALY[1])
    with zipfile.ZipFile(via) as z:
        dati = z.read("%s/%s.tif" % (TINITALY[0], TINITALY[0]))
    im = Image.open(io.BytesIO(dati))
    t = im.tag_v2
    a = np.array(im, np.float32)
    a[a < -1000] = np.nan
    ox, oy = t[33922][3], t[33922][4]
    return Griglia(a, ox, oy, t[33550][0], t[33550][1])


def copernicus(lat_min, lat_max, lon_min, lon_max):
    """Il mosaico delle tessere Copernicus che servono, ritagliato."""
    passo = 1.0 / 3600.0
    r_alto, r_basso = int((45.0 - lat_max) / passo), int(math.ceil((45.0 - lat_min) / passo))
    c_sin, c_des = int((lon_min - 11.0) / passo), int(math.ceil((lon_max - 11.0) / passo))
    tutto = np.full((r_basso - r_alto, c_des - c_sin), np.nan, np.float32)
    for nome in COPERNICUS:
        url = ("https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_%s_DEM/"
               "Copernicus_DSM_COG_10_%s_DEM.tif" % (nome, nome))
        via = scarica("cop_%s.tif" % nome, url)
        lat_t, lon_t = int(nome[1:3]) + 1, int(nome[8:11])
        a = np.array(Image.open(via), np.float32)
        r0 = int(round((45.0 - lat_t) / passo))
        c0 = int(round((lon_t - 11.0) / passo))
        rr0, rr1 = max(r0, r_alto), min(r0 + a.shape[0], r_basso)
        cc0, cc1 = max(c0, c_sin), min(c0 + a.shape[1], c_des)
        if rr0 < rr1 and cc0 < cc1:
            tutto[rr0 - r_alto:rr1 - r_alto, cc0 - c_sin:cc1 - c_sin] = a[rr0 - r0:rr1 - r0, cc0 - c0:cc1 - c0]
    return Griglia(tutto, 11.0 + c_sin * passo, 45.0 - r_alto * passo, passo, passo)


class Quote:
    """La quota assoluta di un punto del gioco: TINITALY dove c'e', Copernicus altrove,
    e in una fascia di due chilometri una sfuma nell'altra."""

    def __init__(self):
        self.tin = tinitaly()
        self.tin.piramide(8)
        ml = (LONTANO_A + 5000) / 111000.0
        mo = ml / math.cos(math.radians(ANCORA_LAT))
        self.cop = copernicus(ANCORA_LAT - ml, ANCORA_LAT + ml, ANCORA_LON - mo, ANCORA_LON + mo)
        self.cop.piramide(6)
        self.scarto = 0.0

    def assoluta(self, est, nord, piede=0.0):
        """`piede` e' quanti metri di terreno rappresenta il punto: sceglie il livello."""
        lat, lon = latlon(est, nord)
        x, y = utm32(lat, lon)
        lt = int(np.clip(math.floor(math.log2(max(piede, 10.0) / 10.0)), 0, 8))
        lc = int(np.clip(math.floor(math.log2(max(piede, 30.0) / 30.0)), 0, 6))
        t = self.tin.leggi(x, y, lt, cubica=(lt == 0))
        c = self.cop.leggi(lon, lat, lc) - self.scarto
        # quanto si e' dentro la tessera TINITALY, in metri dal bordo
        g = self.tin
        dentro = np.minimum.reduce([x - g.x0, g.x0 + g.livelli[0].shape[1] * g.dx - x,
                                    g.y0 - y, y - (g.y0 - g.livelli[0].shape[0] * g.dy)])
        w = np.clip((dentro - 500.0) / 2000.0, 0.0, 1.0)
        w = np.where(np.isnan(t), 0.0, w)
        return np.where(w > 0, np.nan_to_num(t) * w + np.nan_to_num(c) * (1 - w), c)


# ------------------------------------------------------------------ OSM
def osm():
    via = scarica(*OSM)
    radice = ET.parse(via).getroot()
    nodi = {n.get("id"): (float(n.get("lat")), float(n.get("lon"))) for n in radice.findall("node")}
    vie = []
    for w in radice.findall("way"):
        tag = {k.get("k"): k.get("v") for k in w.findall("tag")}
        punti = [nodi[nd.get("ref")] for nd in w.findall("nd") if nd.get("ref") in nodi]
        vie.append((tag, punti))
    return vie


def controlla_ancora(vie):
    for tag, punti in vie:
        if tag.get("man_made") == "observatory":
            p = np.array(punti[:-1] if punti[0] == punti[-1] else punti)
            lat, lon = p[:, 0].mean(), p[:, 1].mean()
            e, n = piano(lat, lon)
            print("[panorama] osservatorio in OSM a %.5f %.5f (%.1f m dall'ancora)" % (lat, lon, math.hypot(e, n)))
            if math.hypot(e, n) > 5.0:
                sys.exit("l'edificio in OSM non sta piu' dove dice ANCORA_LAT/LON: ricontrollare")
            return
    sys.exit("in OSM non c'e' l'osservatorio: il file scaricato e' quello giusto?")


# ------------------------------------------------------------------ prodotti
def griglia_gioco(mezzo, px):
    """Le coordinate di gioco dei centri dei pixel di un'immagine quadrata. La riga 0
    e' il bordo a z minore (sud): la UV del gioco e' (x - x0) / lato, (z - z0) / lato."""
    lato = 2 * mezzo / px
    u = (np.arange(px) + 0.5) * lato - mezzo
    est, nord = np.meshgrid(u, u)
    return est, nord


def normali(h, passo):
    gz, gx = np.gradient(h, passo)
    n = np.stack([-gx, np.ones_like(h), -gz], axis=-1)
    return n / np.linalg.norm(n, axis=-1, keepdims=True)


def senza_luce(rgb, h, passo):
    """Divide la foto per l'ombreggiatura del Sole della scena (lambert sul rilievo,
    riferita al terreno piano) alla SOLE_ESPONENTE. Le normali sono in assi del gioco, e
    il Sole ci va girato come il resto."""
    az, alt = math.radians(SOLE_AZIMUT) + NORD, math.radians(SOLE_ALTEZZA)
    sole = np.array([math.sin(az) * math.cos(alt), math.sin(alt), math.cos(az) * math.cos(alt)])
    ombra = np.clip(normali(h, passo) @ sole, 0.0, None) / math.sin(alt)
    return rgb / np.power(np.clip(ombra, 0.2, 1.8), SOLE_ESPONENTE)[..., None]


def riflettanza_srgb(tci):
    """TCI (riflettanza 0-0,2 su 0-255, lineare) -> albedo sRGB fra 0 e 1."""
    lineare = np.clip(tci / 255.0 * 0.2, 0.0, 1.0)
    return np.where(lineare <= 0.0031308, lineare * 12.92, 1.055 * np.power(lineare, 1 / 2.4) - 0.055)


def sentinel(est, nord):
    """Il colore della scena Sentinel-2 nei punti del gioco (bicubica), NaN fuori."""
    via = scarica(*SENTINEL)
    lat, lon = latlon(est, nord)
    x, y = utm32(lat, lon)
    ox, oy, lato = 699960.0, 4900020.0, 10.0
    r0 = int((oy - np.nanmax(y)) / lato) - 3
    c0 = int((np.nanmin(x) - ox) / lato) - 3
    r1 = int((oy - np.nanmin(y)) / lato) + 4
    c1 = int((np.nanmax(x) - ox) / lato) + 4
    a, r0, c0 = finestra_tiff(via, r0, c0, r1 - r0, c1 - c0)
    # NIENTE NODATA DENTRO LA TESSERA: lo zero su tutte e tre le bande c'e' davvero,
    # nelle ombre dei boschi sui versanti a nord, e trattato come vuoto la bicubica lo
    # allargava in quadrati da quaranta metri. Il vuoto e' solo fuori dalla finestra.
    a = a.astype(np.float32)
    g = Griglia(a, ox + c0 * lato, oy - r0 * lato, lato, lato)
    return g.leggi(x, y, cubica=True)


_WORLDCOVER = []


def worldcover(est, nord):
    """La classe WorldCover nei punti del gioco (il pixel piu' vicino). La finestra dei
    trentadue chilometri attorno si legge una volta sola."""
    passo = 1.0 / 12000.0
    if not _WORLDCOVER:
        via = scarica(*WORLDCOVER)
        m = (LUCI_RAGGIO + 2000.0) / 111000.0
        mo = m / math.cos(math.radians(ANCORA_LAT))
        r0 = int((45.0 - ANCORA_LAT - m) / passo)
        c0 = int((ANCORA_LON - mo - 12.0) / passo)
        a, r0, c0 = finestra_tiff(via, r0, c0, int(2 * m / passo), int(2 * mo / passo))
        _WORLDCOVER.extend([a[..., 0], r0, c0])
    a, r0, c0 = _WORLDCOVER
    lat, lon = latlon(est, nord)
    r = ((45.0 - lat) / passo).astype(np.int64) - r0
    c = ((lon - 12.0) / passo).astype(np.int64) - c0
    return a[np.clip(r, 0, a.shape[0] - 1), np.clip(c, 0, a.shape[1] - 1)]


def salva_immagine(a, nome):
    via = os.path.join(DEST, nome)
    Image.fromarray(np.clip(a * 255.0 + 0.5, 0, 255).astype(np.uint8)).save(via, quality=92)
    scrivi_import(via)
    print("[panorama] %s" % via)


def scrivi_import(via):
    """Il .import con le mipmap, scritto PRIMA che Godot importi (come in prendi_luna.py).
    Senza, un pendio a due chilometri campionato da una mappa da quattromila pixel
    scintillerebbe a ogni passo."""
    res = "res://" + os.path.relpath(via, RADICE).replace(os.sep, "/")
    righe = ["[remap]", "", 'importer="texture"', 'type="CompressedTexture2D"', "",
             "[deps]", "", 'source_file="%s"' % res, "", "[params]", "",
             "compress/mode=0", "mipmaps/generate=true", "detect_3d/compress_to=0", ""]
    with io.open(via + ".import", "w", encoding="utf-8", newline=NL) as f:
        f.write(NL.join(righe))


def quote_vicine(quote):
    n = int(round(2 * VICINO_MEZZO / VICINO_PASSO)) + 1
    u = np.arange(n) * VICINO_PASSO - VICINO_MEZZO
    est, nord = np.meshgrid(u, u)
    h = quote.assoluta(est, nord) - quote.zero - caduta(np.hypot(est, nord))
    assert not np.isnan(h).any(), "buchi nel rilievo vicino"
    return h.astype(np.float32)


def anelli():
    r = [LONTANO_DA]
    while r[-1] < LONTANO_A:
        r.append(r[-1] * (1.0 + CRESCITA))
    return np.array(r)


def quote_lontane(quote, raggi):
    th = np.radians(np.arange(SETTORI) * 360.0 / SETTORI)
    h = np.zeros((len(raggi), SETTORI), np.float32)
    for i, r in enumerate(raggi):
        piede = max(r * CRESCITA, r * 2 * math.pi / SETTORI)
        v = quote.assoluta(r * np.sin(th), r * np.cos(th), piede)
        v = np.where(np.isnan(v), np.nanmean(v) if not np.isnan(v).all() else quote.zero, v)
        h[i] = v - quote.zero - caduta(r)
    return h


def strade(vie, px, mezzo):
    """Le strade di OSM disegnate sulla maschera: rosso le sterrate, blu l'asfalto.
    Le larghezze sono quelle tipiche della categoria, non misurate. Sopra, la ghiaia del
    posto e il viottolo d'erba, che OSM non ha (`geometria.py`, il posto vero)."""
    lato = 2 * mezzo / px
    sterrate = Image.new("L", (px, px), 0)
    asfalto = Image.new("L", (px, px), 0)
    ax, az = ANCORA_GIOCO

    def a_pixel(punti):
        return [((x - ax + mezzo) / lato, (z - az + mezzo) / lato) for x, z in punti]
    for poligono in (G.PIAZZALE, G.SLARGO):
        ImageDraw.Draw(sterrate).polygon(a_pixel(poligono), fill=255)
    # il viottolo e' due solchi nell'erba, non una strada bianca: meta' ghiaia
    ImageDraw.Draw(sterrate).line(a_pixel(G.VIOTTOLO), fill=140,
                                  width=max(1, int(round(2.5 / lato))), joint="curve")
    tipi = {"track": (sterrate, 3.5), "service": (sterrate, 3.0), "unclassified": (asfalto, 4.5),
            "tertiary": (asfalto, 6.0), "secondary": (asfalto, 6.5), "residential": (asfalto, 5.0)}
    for tag, punti in vie:
        if tag.get("highway") not in tipi or len(punti) < 2:
            continue
        dove, largo = tipi[tag["highway"]]
        p = np.array(punti)
        e, n = piano(p[:, 0], p[:, 1])
        xy = [((ei + mezzo) / lato, (ni + mezzo) / lato) for ei, ni in zip(e, n)]
        ImageDraw.Draw(dove).line(xy, fill=255, width=max(1, int(round(largo / lato))), joint="curve")
    morbido = ImageFilter.GaussianBlur(0.8)
    return (np.array(sterrate.filter(morbido), np.float32) / 255.0,
            np.array(asfalto.filter(morbido), np.float32) / 255.0)


def alberi(maschera_bosco, strade_tutte, px, mezzo):
    """Un albero per casella di una griglia da ALBERI_PASSO, spostato a caso nella casella,
    dove WorldCover vede copertura arborea e non c'e' una strada."""
    rng = np.random.default_rng(1999)
    n = int(2 * ALBERI_MEZZO / ALBERI_PASSO)
    j, i = np.meshgrid(np.arange(n), np.arange(n), indexing="ij")
    est = (i + rng.random(i.shape)) * ALBERI_PASSO - ALBERI_MEZZO
    nord = (j + rng.random(j.shape)) * ALBERI_PASSO - ALBERI_MEZZO
    scala = rng.uniform(0.75, 1.25, i.shape)
    variante = rng.integers(0, 256, i.shape)
    classe = worldcover(est, nord)
    lato = 2 * mezzo / px
    ci = np.clip(((est + mezzo) / lato).astype(int), 0, px - 1)
    cj = np.clip(((nord + mezzo) / lato).astype(int), 0, px - 1)
    vicino = (np.abs(est) < mezzo) & (np.abs(nord) < mezzo)
    su_strada = vicino & (strade_tutte[cj, ci] > 0.05)
    tieni = (classe == 10) & ~su_strada
    return est[tieni], nord[tieni], scala[tieni], variante[tieni]


def luci(quote):
    """Una luce per cella da LUCI_CELLA metri dove WorldCover vede costruito, con la
    probabilita' della frazione di costruito, se dall'osservatorio si vede."""
    rng = np.random.default_rng(1999)
    n = int(2 * LUCI_RAGGIO / LUCI_CELLA)
    j, i = np.meshgrid(np.arange(n), np.arange(n), indexing="ij")
    est = (i + 0.5) * LUCI_CELLA - LUCI_RAGGIO
    nord = (j + 0.5) * LUCI_CELLA - LUCI_RAGGIO
    d = np.hypot(est, nord)
    dentro = (d < LUCI_RAGGIO) & (d > 150.0)
    est, nord = est[dentro], nord[dentro]
    # la frazione di costruito: sedici campioni per cella
    conta = np.zeros(est.shape, np.float32)
    passo = LUCI_CELLA / 4
    for a in range(4):
        for b in range(4):
            conta += worldcover(est + (a - 1.5) * passo, nord + (b - 1.5) * passo) == 50
    frazione = conta / 16.0
    tieni = rng.random(est.shape) < frazione * 0.8
    est, nord = est[tieni] + rng.uniform(-passo, passo, tieni.sum()), nord[tieni] + rng.uniform(-passo, passo, tieni.sum())
    h = quote.assoluta(est, nord, 30.0) - quote.zero - caduta(np.hypot(est, nord)) + 6.0
    # SI VEDE? Un raggio dall'occhio alla lampada, sulla superficie Copernicus (che ha gli
    # alberi): basta un punto del terreno sopra la retta e la lampada e' nascosta.
    visibile = np.ones(est.shape, bool)
    d = np.hypot(est, nord)
    for t in np.geomspace(60.0 / LUCI_RAGGIO, 0.995, 96):
        pe, pn = est * t, nord * t
        dd = d * t
        lat, lon = latlon(pe, pn)
        s = quote.cop.leggi(lon, lat, 0) - quote.scarto - quote.zero - caduta(dd)
        retta = OCCHIO + (h - OCCHIO) * t
        # la superficie attorno alla lampada ha le case e gli alberi della lampada stessa
        conta = (dd > 60.0) & (d - dd > 80.0)
        visibile &= ~(conta & (s > retta + 1.0))
    print("[panorama] luci: %d celle costruite, %d visibili" % (tieni.sum(), visibile.sum()))
    potenza = rng.uniform(0.6, 1.2, est.shape)
    return est[visibile], h[visibile], nord[visibile], potenza[visibile]


def numeri(a, fmt):
    return ", ".join(fmt % v for v in np.asarray(a).ravel())


def main():
    os.makedirs(DEST, exist_ok=True)
    vie = osm()
    controlla_ancora(vie)
    quote = Quote()
    lat, lon = latlon(np.array([0.0]), np.array([0.0]))
    x, y = utm32(lat, lon)
    sul_rilievo = float(quote.tin.leggi(x, y, cubica=True)[0])
    ax, az = ANCORA_GIOCO
    davanti = G.davanti_al_cancello()
    lat, lon = latlon(np.array([davanti[0] - ax]), np.array([davanti[1] - az]))
    x, y = utm32(lat, lon)
    quota_slargo = float(quote.tin.leggi(x, y, cubica=True)[0])
    quote.zero = quota_slargo - G.STRADA_SUL_PAVIMENTO
    print("[panorama] slargo davanti al cancello %.1f m; pavimento %.1f m, %.1f sopra il rilievo sotto l'edificio"
          % (quota_slargo, quote.zero, quote.zero - sul_rilievo))
    # LO SCARTO FRA LE DUE FONTI, misurato dove non ci sono ne' alberi ne' case: fra tre e
    # dieci chilometri, dove TINITALY c'e' ancora e Copernicus serve gia'.
    th = np.radians(np.arange(0, 360, 2.0))
    campioni_e, campioni_n = [], []
    for r in np.linspace(3000, 10000, 15):
        campioni_e.append(r * np.sin(th))
        campioni_n.append(r * np.cos(th))
    ce, cn = np.concatenate(campioni_e), np.concatenate(campioni_n)
    la, lo = latlon(ce, cn)
    ux, uy = utm32(la, lo)
    t = quote.tin.leggi(ux, uy)
    c = quote.cop.leggi(lo, la)
    classe = worldcover(ce, cn)
    aperto = ~np.isnan(t) & ~np.isnan(c) & np.isin(classe, [30, 40, 60])
    quote.scarto = float(np.median(c[aperto] - t[aperto]))
    print("[panorama] quota dell'osservatorio %.1f m, Copernicus sta %.1f m sopra TINITALY" % (quote.zero, quote.scarto))

    h_vicino = quote_vicine(quote)
    raggi = anelli()
    h_lontano = quote_lontane(quote, raggi)
    print("[panorama] griglia %d x %d, anelli %d x %d" % (h_vicino.shape[1], h_vicino.shape[0], len(raggi), SETTORI))

    # IL COLORE VICINO: il satellite, meno la luce della foto
    est, nord = griglia_gioco(VICINO_MEZZO, COLORE_VICINO_PX)
    rgb = sentinel(est, nord)
    lato = 2 * VICINO_MEZZO / COLORE_VICINO_PX
    h = quote.assoluta(est, nord, lato)
    rgb = riflettanza_srgb(senza_luce(rgb, h, lato))
    medio = np.nanmean(rgb.reshape(-1, 3), axis=0)
    salva_immagine(np.where(np.isnan(rgb), medio, rgb), "vicino_colore.jpg")

    # IL COLORE LONTANO
    est, nord = griglia_gioco(COLORE_LONTANO_MEZZO, COLORE_LONTANO_PX)
    rgb = np.zeros(est.shape + (3,), np.float32)
    h = np.zeros(est.shape, np.float32)
    lato = 2 * COLORE_LONTANO_MEZZO / COLORE_LONTANO_PX
    for r in range(0, COLORE_LONTANO_PX, 512):
        rgb[r:r + 512] = sentinel(est[r:r + 512], nord[r:r + 512])
        h[r:r + 512] = quote.assoluta(est[r:r + 512], nord[r:r + 512], lato)
    rgb = riflettanza_srgb(senza_luce(rgb, h, lato))
    medio_lontano = np.nanmean(rgb.reshape(-1, 3), axis=0)
    salva_immagine(np.where(np.isnan(rgb), medio_lontano, rgb), "lontano_colore.jpg")

    # LE MASCHERE: sterrate, bosco, asfalto
    est, nord = griglia_gioco(VICINO_MEZZO, MASCHERE_PX)
    sterrate, asfalto = strade(vie, MASCHERE_PX, VICINO_MEZZO)
    bosco = (worldcover(est, nord) == 10).astype(np.float32)
    bosco = np.array(Image.fromarray((bosco * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3)), np.float32) / 255
    salva_immagine(np.stack([sterrate, bosco, asfalto], axis=-1), "vicino_maschere.png")

    ae, an, ascala, avariante = alberi(bosco, np.maximum(sterrate, asfalto), MASCHERE_PX, VICINO_MEZZO)
    print("[panorama] alberi: %d" % len(ae))
    le, lh, ln, lp = luci(quote)

    ax, az = ANCORA_GIOCO
    righe = [
        '[gd_resource type="Resource" script_class="PanoramaDati" load_steps=2 format=3]', "",
        '[ext_resource type="Script" path="res://world/panorama_dati.gd" id="1_dati"]', "",
        "[resource]", 'script = ExtResource("1_dati")',
        "ancora = Vector2(%.3f, %.3f)" % (ax, az),
        "quota_zero = %.2f" % quote.zero,
        "vicino_mezzo = %.1f" % VICINO_MEZZO,
        "vicino_passo = %.1f" % VICINO_PASSO,
        "vicino_lato = %d" % h_vicino.shape[0],
        "vicino_quote = PackedFloat32Array(%s)" % numeri(h_vicino, "%.2f"),
        "lontano_raggi = PackedFloat32Array(%s)" % numeri(raggi, "%.1f"),
        "lontano_settori = %d" % SETTORI,
        "lontano_quote = PackedFloat32Array(%s)" % numeri(h_lontano, "%.1f"),
        "colore_vicino_medio = Color(%.4f, %.4f, %.4f, 1)" % tuple(medio),
        "colore_lontano_mezzo = %.1f" % COLORE_LONTANO_MEZZO,
        "colore_lontano_medio = Color(%.4f, %.4f, %.4f, 1)" % tuple(medio_lontano),
        "alberi = PackedVector3Array(%s)" % ", ".join(
            "%.2f, %.3f, %.2f" % (e + ax, s, n + az) for e, n, s in zip(ae, an, ascala)),
        "alberi_varianti = PackedByteArray(%s)" % numeri(avariante, "%d"),
        "luci = PackedVector3Array(%s)" % ", ".join(
            "%.1f, %.1f, %.1f" % (e + ax, h, n + az) for e, h, n in zip(le, lh, ln)),
        "luci_potenza = PackedFloat32Array(%s)" % numeri(lp, "%.2f"),
        "",
    ]
    via = os.path.join(DEST, "panorama.tres")
    with io.open(via, "w", encoding="utf-8", newline=NL) as f:
        f.write(NL.join(righe))
    print("[panorama] %s" % via)
    with io.open(os.path.join(DEST, "FONTE.txt"), "w", encoding="utf-8", newline=NL) as f:
        f.write(NL.join([
            "Il panorama attorno all'Osservatorio Monte San Lorenzo (tools/prendi_panorama.py).",
            "Rilievo vicino: TINITALY 1.1, tessera w48575 - Tarquini S. et al., INGV, CC-BY 4.0,",
            "  doi:10.13127/tinitaly/1.1",
            "Rilievo lontano: Copernicus DEM GLO-30 - produced using Copernicus WorldDEM-30",
            "  (c) DLR e.V. 2010-2014 and (c) Airbus Defence and Space GmbH 2014-2018 provided under",
            "  COPERNICUS by the European Union and ESA; all rights reserved",
            "Colore: contains modified Copernicus Sentinel data 2020 (S2B_32TQP_20201119, L2A TCI)",
            "Copertura del suolo: (c) ESA WorldCover project 2021 / Contains modified Copernicus",
            "  Sentinel data (2021) processed by ESA WorldCover consortium, CC-BY 4.0",
            "Strade ed edificio: (c) OpenStreetMap contributors, ODbL",
            "Il posto (recinto, cancello, ghiaia, viottolo): Carta Tecnica Regionale 2019 e ortofoto",
            "  AGEA 2022, Regione Marche, Geoportale (servizio WMS)",
            "Nord vero a %.0f gradi dall'asse +Z del gioco." % G.NORD,
            "Quota del pavimento: %.1f m. Copernicus - TINITALY sul terreno aperto: %.1f m." % (quote.zero, quote.scarto),
            ""]))


if __name__ == "__main__":
    main()
