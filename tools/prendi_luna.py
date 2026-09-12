# -*- coding: utf-8 -*-
"""Scarica le mappe della Luna vera e ne ricava le due texture del disco.

    python tools/prendi_luna.py

DA DOVE. Il "CGI Moon Kit" dello Scientific Visualization Studio della NASA
(https://svs.gsfc.nasa.gov/4720/): la mappa a colori e' il mosaico della camera del
Lunar Reconnaissance Orbiter, le quote vengono dall'altimetro laser LOLA dello
stesso satellite. Pubblico dominio, con la richiesta di citare la fonte: il credito
sta in CREDITI.md.

PERCHE' NON UN RUMORE PROCEDURALE. Perche' i crateri inventati sono la cosa che in
questo progetto non si fa (inventare la forma), e perche' la Luna e' l'unico
oggetto del cielo che TUTTI riconoscono: la faccia - i mari scuri, Tycho con i suoi
raggi in basso, Copernico - e' la stessa da quando esiste l'uomo, e una Luna con
dei buchi a caso non sarebbe la Luna.

COSA SCRIVE, in assets/textures/luna/:
  * colore.jpg   la mappa LRO a 2048x1024, tale e quale. E' la faccia.
  * rilievo.png  una mappa di PENDENZE ricavata dalle quote, e questo e' l'unico
                 pezzo lavorato. La mappa a 8 bit del kit (ldem_3_8bit) non dice a
                 quanti metri corrisponda un livello di grigio, quindi non la si
                 puo' usare senza inventare una scala; quella a 16 bit si':
                 mezzi metri, con uno scostamento di ventimila (lo dice la pagina
                 del kit). Da li' si calcolano le pendenze VERE, in metri su
                 metri, e si scrivono come normale. Nessuna esagerazione: il
                 rilievo che si vede al terminatore e' quello che c'e'.
  * i due .import, con le mipmap accese. Senza, un disco da dieci pixel
    campionerebbe una mappa da duemila e scintillerebbe a ogni fotogramma.

Le due mappe sono centrate sulla longitudine zero, con il nord in alto e l'est a
DESTRA (convenzione IAU: Mare Crisium sta a +59 gradi). Lo shader lo sa.
"""
import os
import urllib.request

import numpy as np
from PIL import Image

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
DEST = os.path.join(RADICE, "assets", "textures", "luna")
CACHE = os.path.join(QUI, "__texture_cache__", "luna")
BASE = "https://svs.gsfc.nasa.gov/vis/a000000/a004700/a004720/"

COLORE = "lroc_color_2k.jpg"
QUOTE = "ldem_4_uint.tif"

# Il raggio di riferimento di tutti i dati LRO, in chilometri (pagina del kit).
R_KM = 1737.4

# LA PENDENZA PIU' RIPIDA CHE SI SCRIVE, in metri su metri. Serve solo ai poli,
# dove la mappa cilindrica stringe i meridiani fino a zero e la differenza fra due
# pixel vicini diventa una divisione per quasi niente. I poli stanno sul bordo del
# disco, dove non si vede nulla: il tetto evita che ci compaiano spilli luminosi.
PENDENZA_MAX = 3.0


def scarica(nome):
    os.makedirs(CACHE, exist_ok=True)
    dove = os.path.join(CACHE, nome)
    if not os.path.exists(dove) or os.path.getsize(dove) < 1024:
        print("scarico %s ..." % nome)
        urllib.request.urlretrieve(BASE + nome, dove)
    return dove


def scrivi_import(file_png, nome_res):
    """Il .import con le mipmap: si scrive PRIMA dell'import, e Godot lo rispetta."""
    righe = [
        "[remap]", "",
        'importer="texture"',
        'type="CompressedTexture2D"', "",
        "[deps]", "",
        'source_file="res://assets/textures/luna/%s"' % nome_res, "",
        "[params]", "",
        # SENZA PERDITA: la mappa del rilievo e' un dato, non un'immagine, e una
        # compressione a blocchi ne sporcherebbe le pendenze proprio lungo i bordi
        # dei crateri, che sono la cosa da vedere.
        "compress/mode=0",
        "mipmaps/generate=true",
        # E NIENTE CAMBI DI IDEA AUTOMATICI: usata in 3D, Godot ricomprimerebbe da
        # solo in VRAM al primo uso.
        "detect_3d/compress_to=0",
        "",
    ]
    with open(file_png + ".import", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(righe))


def rilievo(sorgente, destinazione):
    q = np.array(Image.open(sorgente)).astype(np.float64)
    km = (q - 20000.0) / 2000.0                     # mezzi metri, scostati di 10 km
    righe, colonne = km.shape                        # 720 x 1440, 4 pixel per grado

    # Il passo della griglia, in chilometri. In latitudine e' costante; in
    # longitudine si stringe col coseno della latitudine.
    lat = np.radians(90.0 - (np.arange(righe) + 0.5) * 180.0 / righe)
    passo_nord = np.pi * R_KM / righe
    passo_est = 2.0 * np.pi * R_KM * np.maximum(np.cos(lat), 0.02) / colonne

    # Differenze centrate. In longitudine la mappa si chiude su se stessa (np.roll);
    # in latitudine no, e ai due bordi si ripete la riga estrema.
    d_est = (np.roll(km, -1, axis=1) - np.roll(km, 1, axis=1)) / (2.0 * passo_est[:, None])
    su = np.vstack([km[:1], km[:-1]])
    giu = np.vstack([km[1:], km[-1:]])
    d_nord = (su - giu) / (2.0 * passo_nord)         # la riga 0 e' il nord

    d_est = np.clip(d_est, -PENDENZA_MAX, PENDENZA_MAX)
    d_nord = np.clip(d_nord, -PENDENZA_MAX, PENDENZA_MAX)

    # La normale nel riferimento locale (est, nord, su): una superficie che sale
    # verso est guarda a ovest, da cui i due meno.
    n = np.stack([-d_est, -d_nord, np.ones_like(km)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    rgb = np.clip(np.round((n * 0.5 + 0.5) * 255.0), 0, 255).astype(np.uint8)
    Image.fromarray(rgb).save(destinazione)

    pend = np.degrees(np.arctan(np.hypot(d_est, d_nord)))
    print("rilievo: quote da %.1f a %.1f km, pendenza media %.1f gradi, 99%% sotto %.1f"
          % (km.min(), km.max(), pend.mean(), np.percentile(pend, 99)))


def main():
    os.makedirs(DEST, exist_ok=True)

    src = scarica(COLORE)
    dst = os.path.join(DEST, "colore.jpg")
    with open(src, "rb") as a, open(dst, "wb") as b:
        b.write(a.read())
    scrivi_import(dst, "colore.jpg")
    print("colore: %s %s" % (Image.open(dst).size, dst))

    dst = os.path.join(DEST, "rilievo.png")
    rilievo(scarica(QUOTE), dst)
    scrivi_import(dst, "rilievo.png")
    print("rilievo: %s %s" % (Image.open(dst).size, dst))

    with open(os.path.join(DEST, "FONTE.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write(
            "CGI Moon Kit, NASA's Scientific Visualization Studio\n"
            "https://svs.gsfc.nasa.gov/4720/\n"
            "Pubblico dominio (NASA). Credito richiesto: \"NASA's Scientific Visualization\n"
            "Studio\" - sta in CREDITI.md.\n\n"
            "colore.jpg  = %s (mosaico LROC), tale e quale.\n"
            "rilievo.png = pendenze calcolate da %s (quote LOLA, mezzi metri + 20000)\n"
            "              da tools/prendi_luna.py, senza esagerazione.\n"
            % (COLORE, QUOTE))
    print("scritto %s" % DEST)


if __name__ == "__main__":
    main()
