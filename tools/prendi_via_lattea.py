# -*- coding: utf-8 -*-
"""La Via Lattea vera, per il cielo del gioco.

    "D:/programs/blender5/blender.exe" --background --python tools/prendi_via_lattea.py

(Con Blender e non con python: il file della NASA e' un OpenEXR a mezza precisione, e
l'OpenCV installato qui e' compilato senza OpenEXR. Blender lo legge, e ha numpy dentro.)

DA DOVE. "Deep Star Maps 2020" dello Scientific Visualization Studio della NASA
(https://svs.gsfc.nasa.gov/4851/), lo strato "milkyway": la mappa di 1,7 miliardi di
stelle dei cataloghi Hipparcos-2, Tycho-2 e Gaia DR2, SENZA le stelle brillanti di
Hipparcos e Tycho. Restano le stelle di Gaia, troppo deboli per vederle una a una, che
tutte insieme sono la Via Lattea: le nubi del Cigno, la fenditura scura, il nucleo nel
Sagittario, le Nubi di Magellano. Credito chiesto dalla pagina: "NASA/Goddard Space
Flight Center Scientific Visualization Studio. Gaia DR2: ESA/Gaia/DPAC" (CREDITI.md).

PERCHE' UNA MAPPA E NON UNA FASCIA PROCEDURALE. La fascia che c'era prima era una
gaussiana attorno a un piano scelto a caso, screziata da un rumore: nessuna nube, nessuna
fenditura, e nel posto sbagliato. La Via Lattea invece e' la cosa del cielo notturno che
si riconosce di piu' dopo la Luna, e ha una forma precisa - la stessa ragione per cui la
Luna del gioco e' il mosaico del Lunar Reconnaissance Orbiter e non dei crateri a caso.

LE STELLE RESTANO QUELLE DELLO SHADER. Questa mappa porta solo il chiarore diffuso; le
stelle una per una sono ancora il campo procedurale di `cielo.gdshader`, che non finge di
essere un catalogo.

COSA SCRIVE, in assets/textures/via_lattea/:
  * via_lattea.png  2048x1024, coordinate equatoriali J2000 in proiezione cilindrica
                    come l'originale: al centro l'ascensione retta zero, che cresce
                    verso SINISTRA; in alto il polo nord celeste.
  * il suo .import, senza perdita e con le mipmap.

COSA SI FA AL FILE, e perche':
  * SI DIMEZZA, da 4096 a 2048: a 640 pixel per 75 gradi di schermo un texel da dieci
    primi basta, e la mappa grande pesa quattro volte tanto senza dare niente.
  * SI SFUMA DI UN TEXEL: le stelle di Gaia piu' luminose restano puntini isolati sulla
    mappa, e sullo schermo formicolerebbero. La Via Lattea a occhio nudo e' una nebbia,
    non una sabbia.
  * SI NORMALIZZA sul millesimo piu' luminoso, che e' il nucleo galattico: cosi' la mappa
    dice quanto e' chiara una regione rispetto alle altre, e quanto e' chiara in cielo lo
    decide lo shader, dove si tara.
  * SI SCRIVE LA RADICE, in otto bit: la Via Lattea va dal nucleo a regioni cento volte
    piu' deboli, e in otto bit lineari le regioni deboli - che sono quasi tutto quello
    che si vede d'autunno - avrebbero tre livelli di grigio. Lo shader la rimette al
    quadrato.
"""
import os
import urllib.request

import bpy
import numpy as np

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
DEST = os.path.join(RADICE, "assets", "textures", "via_lattea")
CACHE = os.path.join(QUI, "__texture_cache__", "via_lattea")
URL = "https://svs.gsfc.nasa.gov/vis/a000000/a004800/a004851/milkyway_2020_4k.exr"

LARGHEZZA = 2048
ALTEZZA = 1024
# Il percentile di luminanza che diventa uno: il nucleo della Galassia.
PERCENTILE = 99.9


def scarica():
    os.makedirs(CACHE, exist_ok=True)
    via = os.path.join(CACHE, os.path.basename(URL))
    if not os.path.exists(via):
        print("scarico %s" % URL)
        # senza un User-Agent i server della NASA a volte rispondono 403
        richiesta = urllib.request.Request(URL, headers={"User-Agent": "astrochills-tools"})
        with urllib.request.urlopen(richiesta) as r, open(via, "wb") as f:
            f.write(r.read())
    return via


def leggi(via):
    """L'EXR come array (righe, colonne, 3), riga zero IN ALTO, luce lineare."""
    img = bpy.data.images.load(via)
    img.colorspace_settings.name = "Non-Color"
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    # Blender tiene le righe dal basso
    return px.reshape(h, w, 4)[::-1, :, :3].copy()


def sfuma(a):
    """Una gaussiana di un texel, separabile, che gira in orizzontale (l'ascensione retta
    e' un cerchio) e si ferma in verticale (i poli sono bordi)."""
    k = np.array([0.061, 0.242, 0.383, 0.242, 0.061], dtype=np.float32)
    orizz = sum(k[i] * np.roll(a, i - 2, axis=1) for i in range(5))
    pad = np.pad(orizz, ((2, 2), (0, 0), (0, 0)), mode="edge")
    return sum(k[i] * pad[i:i + a.shape[0]] for i in range(5))


def scrivi_import(file_png, nome_res):
    righe = [
        "[remap]", "",
        'importer="texture"',
        'type="CompressedTexture2D"', "",
        "[deps]", "",
        'source_file="res://assets/textures/via_lattea/%s"' % nome_res, "",
        "[params]", "",
        # SENZA PERDITA: una compressione a blocchi su una nebbia cosi' debole fa gradini
        "compress/mode=0",
        "mipmaps/generate=true",
        "detect_3d/compress_to=0",
        "",
    ]
    with open(file_png + ".import", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(righe))


def main():
    a = leggi(scarica())
    h, w, _ = a.shape
    # dimezzata a media di quattro texel: la luce si conserva
    a = a.reshape(ALTEZZA, h // ALTEZZA, LARGHEZZA, w // LARGHEZZA, 3).mean(axis=(1, 3))
    a = sfuma(a)
    lum = a @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    uno = float(np.percentile(lum, PERCENTILE))
    a = np.clip(a / uno, 0.0, 1.0)
    enc = np.sqrt(a)

    os.makedirs(DEST, exist_ok=True)
    uscita = os.path.join(DEST, "via_lattea.png")
    img = bpy.data.images.new("ViaLattea", LARGHEZZA, ALTEZZA, alpha=False, float_buffer=False)
    img.colorspace_settings.name = "Non-Color"
    rgba = np.ones((ALTEZZA, LARGHEZZA, 4), dtype=np.float32)
    rgba[:, :, :3] = enc
    img.pixels.foreach_set(rgba[::-1].ravel())
    img.filepath_raw = uscita
    img.file_format = "PNG"
    img.save()
    scrivi_import(uscita, "via_lattea.png")

    mediana = float(np.median(lum / uno))
    print("\nscritto %s" % uscita)
    print("  %dx%d; il nucleo (percentile %.1f) vale %.3g nell'EXR; la mediana del cielo e' %.4f del nucleo"
          % (LARGHEZZA, ALTEZZA, PERCENTILE, uno, mediana))


if __name__ == "__main__":
    main()
