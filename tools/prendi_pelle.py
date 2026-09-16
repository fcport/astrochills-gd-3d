# -*- coding: utf-8 -*-
"""La pelle del tentacolo: una fotografia vera di polpo, resa ripetibile.

    python tools/prendi_pelle.py

DA DOVE. "PMNM - He'e Octopus", Greg McFall/NOAA, Papahanaumokuakea Marine National
Monument, 18 settembre 2011: un polpo diurno (Octopus cyanea) a Gardner Pinnacles,
fotografato cosi' da vicino che la pelle del braccio riempie mezzo fotogramma.
Pubblico dominio (NOAA, governo federale USA), preso da Wikimedia Commons; il credito
sta in CREDITI.md.

PERCHE' UNA FOTOGRAFIA E NON UN RUMORE. Per la stessa ragione della Luna in
`prendi_luna.py`: la pelle di un polpo non e' "macchie a caso". E' un RETICOLO - una
rete di bande scure con dentro macchie chiare, che sono le papille - e un rumore
procedurale fa un'altra cosa, qualcosa di vagamente organico che non e' niente. Ne'
ambientCG ne' Poly Haven hanno una pelle di cefalopode: hanno cuoio, che ha i pori di
un bovino ed e' un'altra superficie.

COSA SE NE FA, e ognuno di questi passi c'e' perche' una fotografia non e' una texture:

  * UN RITAGLIO DI SOLA PELLE. Il fotogramma ha un occhio, una grotta e del corallo;
    il quadrato RITAGLIO e' tutto braccio.
  * SI TOGLIE LA LUCE DELLA FOTO. Il braccio e' curvo e il flash lo illumina di piu' a
    sinistra: ripetuto su un tubo, quel gradiente diventerebbe una striscia chiara e una
    scura ogni tanti metri. Si divide per una versione molto sfocata della stessa
    immagine, che contiene solo il gradiente, e resta il disegno.
  * SI RENDE RIPETIBILE SOVRAPPONENDO I MARGINI. Si ritaglia un quadrato piu' grande
    della piastrella, e la striscia che avanza a destra (e sotto) si dissolve sopra
    quella di sinistra (e sopra): l'ultima colonna della piastrella e' seguita, al
    giro, dalla colonna che nella foto le stava davvero accanto. La prima stesura
    fondeva l'immagine con se stessa spostata di mezzo lato, che toglie la cucitura
    ma mette DUE VOLTE lo stesso disegno nella stessa piastrella - una volta al centro
    e una sui bordi - e su un tubo lungo si vedeva la ripetizione a meta' passo.
  * SI TINGE verso la tinta con cui il tentacolo e' gia' stato guardato e approvato -
    quel grigio livido tendente al rosa che di notte sotto la Luna si stacca dal cielo
    senza bruciare (vedi `tentacolo_blender.py`). Il polpo della foto e' arancione: e'
    il colore di un animale diurno su una barriera corallina, non di una cosa che
    scende dal cielo sopra l'Appennino. Del colore vero si tiene un terzo della
    saturazione, cosi' le bande restano bruno-rossastre e le macchie chiare.
  * IL RILIEVO VIENE DALLA LUMINOSITA'. Nella pelle di un polpo le macchie chiare sono
    in rilievo e le bande scure sono solchi: la luminanza e' un'altezza ragionevole, e
    da quella si ricava la normale, in convenzione OpenGL come il resto del progetto.
    La ruvidita' segue: bagnato nei solchi, meno sulle papille.

E DALLA STESSA FOTO L'IRIDE, per l'occhio che si apre nel cielo (`world/occhio.gd`).
Il polpo del fotogramma ha l'occhio a mezzo metro dal braccio: un'iride di cromatofori
rossi su un reticolo bianco, tagliata da una pupilla nera a fessura. Il quadrato
IRIDE e' la parte sotto la pupilla, l'unica che non ha ne' la pupilla ne' la palpebra
dentro. E' piccolo - centoventi pixel - perche' e' quello che c'e': le cellule sono
larghe sei, quindi dentro ce ne stanno una ventina per lato, e sull'occhio la
piastrella si ripete due volte da un bordo all'altro, che e' quante ne ha un'iride vera.

LE MIPMAP, scritte nei .import PRIMA che Godot importi. L'occhio si guarda da due
chilometri e mezzo: una mappa da mille pixel campionata su venti scintillerebbe a
ogni fotogramma. E' la stessa ragione, e lo stesso modo, di `prendi_luna.py`.

SCRIVE in assets/textures/pelle-polpo/: color.jpg, normal.jpg, roughness.jpg, FONTE.txt,
e in assets/textures/iride-polpo/: color.jpg, FONTE.txt. Con i .import di tutte.
"""
import hashlib
import io
import os
import urllib.request

import numpy as np
from PIL import Image, ImageFilter

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
DEST = os.path.join(RADICE, "assets", "textures", "pelle-polpo")
DEST_IRIDE = os.path.join(RADICE, "assets", "textures", "iride-polpo")
CACHE = os.path.join(QUI, "__texture_cache__", "pelle")

URL = ("https://upload.wikimedia.org/wikipedia/commons/f/fb/"
       "PMNM_-_He%27e_Octopus_%2827551309582%29.jpg")
PAGINA = "https://commons.wikimedia.org/wiki/File:PMNM_-_He%27e_Octopus_(27551309582).jpg"
SHA1 = "0a444f4cf0d7f17b6da02a5f74a2d2084eeff02f"

# x0, y0, x1, y1 sull'originale da 5412 x 3744: il braccio in alto a sinistra. Piu'
# grande della piastrella di MARGINE, che e' la striscia che si dissolve al giro.
RITAGLIO = (40, 930, 1140, 2030)
LATO = 1024
MARGINE = 256

# La tinta media voluta, in sRGB: e' la "Tentacolo" di `tentacolo_blender.py`
# (0,27 0,21 0,22 lineari) portata in sRGB.
TINTA = (142, 126, 129)
SATURAZIONE_TENUTA = 0.33

# Quanto e' profondo il rilievo nella normale: piu' alto, piu' la luce radente
# disegna le papille.
RILIEVO = 3.0

# L'iride: il quadrato sotto la pupilla, sull'originale. Piastrella e margine stanno
# nello stesso rapporto della pelle, e si ingrandisce a IRIDE_LATO.
IRIDE = (1850, 2590, 1970, 2710)
IRIDE_MARGINE = 24
IRIDE_LATO = 512
# Del rosso vero se ne tiene piu' che della pelle: un occhio grigio in mezzo a una
# pelle grigia non si legge come occhio. La luce della foto si toglie con una
# sfocatura piu' stretta, perche' il quadrato e' piccolo e la curva del bulbo ci
# passa dentro tutta.
IRIDE_SATURAZIONE = 0.55
IRIDE_SFOCATURA = 24


def scarica():
    os.makedirs(CACHE, exist_ok=True)
    via = os.path.join(CACHE, "originale.jpg")
    if not os.path.exists(via):
        req = urllib.request.Request(URL, headers={"User-Agent": "Astrochill/1.0 (texture tool)"})
        with urllib.request.urlopen(req, timeout=180) as r:
            with open(via, "wb") as f:
                f.write(r.read())
    with open(via, "rb") as f:
        firma = hashlib.sha1(f.read()).hexdigest()
    if firma != SHA1:
        raise SystemExit("l'originale in cache non e' quello atteso (sha1 %s): "
                         "cancellalo e rilancia" % firma)
    return Image.open(via).convert("RGB")


def senza_luce(img, sfocatura=140):
    """Divide per il gradiente di luce della foto, lasciando il disegno."""
    a = np.asarray(img).astype(np.float32) / 255.0
    sfocata = np.asarray(img.filter(ImageFilter.GaussianBlur(sfocatura))).astype(np.float32) / 255.0
    piatta = a / np.maximum(sfocata, 1e-3) * sfocata.mean(axis=(0, 1))
    return np.clip(piatta, 0.0, 1.0)


def ripetibile(a, n=LATO, m=MARGINE):
    """Da un quadrato di n + m a una piastrella di n che si ripete."""
    w = np.linspace(0.0, 1.0, m, dtype=np.float32)
    w = w * w * (3.0 - 2.0 * w)
    # in orizzontale: le prime m colonne sfumano da quelle che nella foto seguono
    # l'ultima colonna tenuta, verso le proprie
    o = a[:, :n].copy()
    o[:, :m] = a[:, n:n + m] * (1.0 - w)[None, :, None] + a[:, :m] * w[None, :, None]
    # in verticale, sullo stesso principio
    v = o[:n].copy()
    v[:m] = o[n:n + m] * (1.0 - w)[:, None, None] + o[:m] * w[:, None, None]
    return v


def tingi(a, saturazione=SATURAZIONE_TENUTA):
    """Porta la media sulla TINTA, tenendo parte della saturazione della foto."""
    lum = (a * np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)).sum(axis=2, keepdims=True)
    colore = lum + (a - lum) * saturazione
    voluta = np.array(TINTA, dtype=np.float32) / 255.0
    colore = colore * (voluta / np.maximum(colore.mean(axis=(0, 1)), 1e-3))
    return np.clip(colore, 0.0, 1.0), lum[..., 0]


def normale(altezza):
    """La normale in convenzione OpenGL (verde verso l'alto), dall'altezza."""
    h = altezza - altezza.mean()
    dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * 0.5 * RILIEVO
    dy = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) * 0.5 * RILIEVO
    n = np.stack([-dx, dy, np.ones_like(h)], axis=2)
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return n * 0.5 + 0.5


def salva(a, nome, dest=DEST):
    via = os.path.join(dest, nome)
    Image.fromarray((np.clip(a, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8)).save(via, quality=92)
    scrivi_import(via)


def scrivi_import(via):
    """Il .import con le mipmap: si scrive PRIMA dell'import, e Godot lo rispetta."""
    res = "res://" + os.path.relpath(via, RADICE).replace(os.sep, "/")
    righe = [
        "[remap]", "",
        'importer="texture"',
        'type="CompressedTexture2D"', "",
        "[deps]", "",
        'source_file="%s"' % res, "",
        "[params]", "",
        "compress/mode=0",
        "mipmaps/generate=true",
        # usata in 3D, Godot ricomprimerebbe da solo in VRAM al primo uso
        "detect_3d/compress_to=0",
        "",
    ]
    with io.open(via + ".import", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(righe))


def iride(img):
    """La piastrella dell'iride: vedi la testata."""
    lato = IRIDE[2] - IRIDE[0] - IRIDE_MARGINE
    pezzo = img.crop(IRIDE)
    piatta = ripetibile(senza_luce(pezzo, IRIDE_SFOCATURA), lato, IRIDE_MARGINE)
    lum = (piatta * np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)).sum(axis=2, keepdims=True)
    colore = np.clip(lum + (piatta - lum) * IRIDE_SATURAZIONE, 0.0, 1.0)
    grande = Image.fromarray((colore * 255.0 + 0.5).astype(np.uint8)).resize(
        (IRIDE_LATO, IRIDE_LATO), Image.LANCZOS)
    os.makedirs(DEST_IRIDE, exist_ok=True)
    salva(np.asarray(grande).astype(np.float32) / 255.0, "color.jpg", DEST_IRIDE)
    with io.open(os.path.join(DEST_IRIDE, "FONTE.txt"), "w", encoding="utf-8") as f:
        f.write("PMNM - He'e Octopus - Greg McFall/NOAA, "
                "Papahanaumokuakea Marine National Monument, 2011\n")
        f.write("Pubblico dominio (NOAA). %s\n" % PAGINA)
        f.write("Iride: ritaglio %s, reso ripetibile da tools/prendi_pelle.py\n" % (IRIDE,))
    print("scritto %s: color a %dx%d, media %s" % (
        DEST_IRIDE, IRIDE_LATO, IRIDE_LATO, tuple(int(v * 255) for v in colore.mean(axis=(0, 1)))))


def main():
    img = scarica()
    pezzo = img.crop(RITAGLIO).resize((LATO + MARGINE, LATO + MARGINE), Image.LANCZOS)
    piatta = ripetibile(senza_luce(pezzo))
    colore, lum = tingi(piatta)
    # un filo di sfocatura sull'altezza: la grana del sensore non e' rilievo
    alt = np.asarray(Image.fromarray((lum * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(1.2))).astype(np.float32) / 255.0
    ruvido = 0.30 + 0.25 * (alt - alt.min()) / max(float(alt.max() - alt.min()), 1e-3)

    os.makedirs(DEST, exist_ok=True)
    salva(colore, "color.jpg")
    salva(normale(alt), "normal.jpg")
    salva(np.repeat(ruvido[..., None], 3, axis=2), "roughness.jpg")
    with io.open(os.path.join(DEST, "FONTE.txt"), "w", encoding="utf-8") as f:
        f.write("PMNM - He'e Octopus - Greg McFall/NOAA, "
                "Papahanaumokuakea Marine National Monument, 2011\n")
        f.write("Pubblico dominio (NOAA). %s\n" % PAGINA)
        f.write("Ritaglio %s, reso ripetibile e tinto da tools/prendi_pelle.py\n" % (RITAGLIO,))
    print("scritto %s: color, normal, roughness a %dx%d, media %s" % (
        DEST, LATO, LATO, tuple(int(v * 255) for v in colore.mean(axis=(0, 1)))))
    iride(img)


if __name__ == "__main__":
    main()
