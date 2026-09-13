# -*- coding: utf-8 -*-
"""Le pagine che escono dalla stampante: una per soggetto e per livello, gia' composte.

COSA C'E' SU UNA PAGINA. Il modulo continuo della Okidata ML320 - nove pollici e
mezzo per undici, strisce del trattore comprese - con la foto al centro e la sigla
del soggetto sotto. Le strisce hanno i fori veri, trasparenti: appesa al muro, la
stampa lascia vedere l'intonaco attraverso i buchi, e da due metri e' quello che la
distingue da un poster.

LA FOTO E' A COLORI, e la ML320 non lo sa fare: ha un nastro nero e nove aghi.
L'epoca diceva retino in bianco e nero, le foto del prototipo sono a colori, e
Federico ha scelto le foto (vedi il decision-log, D-239). Qui la foto si incolla
com'e'.

LE FOTO VENGONO DAL PROTOTIPO PHASER, `../phaser_astrochill/public/assets/photos`,
tre per soggetto: `_t1` la piu' rovinata, `_t3` la piu' pulita. Da dove il
prototipo le abbia prese non e' scritto da nessuna parte - vedi `CREDITI.md`.

SI COMPONE QUI E NON IN GIOCO. La pagina di un soggetto a un livello e' sempre la
stessa, quindi comporla a ogni stampa vorrebbe dire rifare lo stesso lavoro a ogni
notte; e le PNG d'origine arrivano fino a 4788x3194, che caricate per incollarne
duecento pixel sarebbero sedici megabyte per niente.

DUECENTOCINQUANTASEI PIXEL DI LARGHEZZA, cioe' un pixel per millimetro. Appesa, la
pagina si guarda da mezzo metro in un mondo reso a 640x360, e occupa un centinaio
di pixel di schermo: di piu' sarebbe solo sfarfallio col filtro `Nearest`.

    python tools/stampe_foto.py
"""
import os
import re

from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.normpath(os.path.join(QUI, ".."))
FONTE = os.path.normpath(os.path.join(RADICE, "..", "phaser_astrochill",
                                      "public", "assets", "photos"))
BERSAGLI = os.path.join(RADICE, "data", "targets")
FUORI = os.path.join(RADICE, "assets", "stampe")

# Il modulo continuo: 241,3 x 279,4 mm. I pixel per millimetro li decide la
# larghezza, l'altezza segue.
LARGO = 256
MM = LARGO / 241.3
ALTO = round(279.4 * MM)

# Le strisce del trattore: mezzo pollice per lato, fori da quattro millimetri a
# passo di mezzo pollice, centrati sulla striscia. Sono le quote dello standard del
# modulo continuo, non un disegno.
STRISCIA = round(12.7 * MM)
FORO_R = 2.0 * MM
FORO_PASSO = 12.7 * MM

# La foto sta in una cornice di 190 x 200 mm, a 22 mm dal bordo alto, e ci entra
# senza deformarsi: la M13 e' in piedi, la M31 coricata.
FOTO_LARGA = 190 * MM
FOTO_ALTA = 200 * MM
FOTO_SOPRA = round(22 * MM)
SIGLA_SOTTO = round(6 * MM)

# LA CARTA E' BIANCA, e la prima era crema: appesa all'intonaco della sala, che e' crema
# anche lui sotto le lampade calde, il foglio spariva e restava una foto sospesa sul
# muro. Il modulo continuo da ufficio e' bianco.
CARTA = (246, 245, 240, 255)
PERFORAZIONE = (200, 198, 190, 255)
INCHIOSTRO = (46, 46, 52, 255)
BUCO = (0, 0, 0, 0)

# La sigla la scrive la stampante col suo carattere, cinque punti per sette. Solo i
# segni che le sigle dei soggetti usano: lettere dei cataloghi e cifre.
CARATTERE = {
    "M": ("10001", "11011", "10101", "10101", "10001", "10001", "10001"),
    "N": ("10001", "11001", "10101", "10011", "10001", "10001", "10001"),
    "G": ("01110", "10001", "10000", "10111", "10001", "10001", "01110"),
    "C": ("01110", "10001", "10000", "10000", "10000", "10001", "01110"),
    "I": ("01110", "00100", "00100", "00100", "00100", "00100", "01110"),
    "0": ("01110", "10001", "10011", "10101", "11001", "10001", "01110"),
    "1": ("00100", "01100", "00100", "00100", "00100", "00100", "01110"),
    "2": ("01110", "10001", "00001", "00010", "00100", "01000", "11111"),
    "3": ("11111", "00010", "00100", "00010", "00001", "10001", "01110"),
    "4": ("00010", "00110", "01010", "10010", "11111", "00010", "00010"),
    "5": ("11111", "10000", "11110", "00001", "00001", "10001", "01110"),
    "6": ("00110", "01000", "10000", "11110", "10001", "10001", "01110"),
    "7": ("11111", "00001", "00010", "00100", "01000", "01000", "01000"),
    "8": ("01110", "10001", "10001", "01110", "10001", "10001", "01110"),
    "9": ("01110", "10001", "10001", "01111", "00001", "00010", "01100"),
    " ": ("00000",) * 7,
}


def carta():
    """La pagina vuota: carta, perforazioni e fori. E' anche il retro di ogni stampa."""
    im = Image.new("RGBA", (LARGO, ALTO), CARTA)
    d = ImageDraw.Draw(im)
    # la perforazione fra striscia e pagina, e quella fra una pagina e l'altra
    for y in range(0, ALTO, 2):
        d.point((STRISCIA, y), PERFORAZIONE)
        d.point((LARGO - 1 - STRISCIA, y), PERFORAZIONE)
    for x in range(0, LARGO, 2):
        d.point((x, 0), PERFORAZIONE)
        d.point((x, ALTO - 1), PERFORAZIONE)
    cx = (STRISCIA / 2.0, LARGO - STRISCIA / 2.0)
    y = FORO_PASSO / 2.0
    while y < ALTO:
        for x in cx:
            d.ellipse((x - FORO_R, y - FORO_R, x + FORO_R, y + FORO_R), fill=BUCO)
        y += FORO_PASSO
    return im


def scrivi(im, testo, y):
    """La sigla centrata, un punto per pixel. Un segno che il carattere non ha si salta
    e lo si dice: una sigla scritta a meta' si nota solo guardando la stampa."""
    segni = [c for c in testo.upper() if c in CARATTERE]
    if len(segni) != len(testo):
        print("  ATTENZIONE: nella sigla %r ci sono segni che il carattere non ha" % testo)
    largo = len(segni) * 6 - 1
    x0 = (LARGO - largo) // 2
    for k, c in enumerate(segni):
        for r, riga in enumerate(CARATTERE[c]):
            for q, bit in enumerate(riga):
                if bit == "1":
                    im.putpixel((x0 + k * 6 + q, y + r), INCHIOSTRO)


def sigla(bersaglio):
    """La sigla del soggetto la dice il suo `.tres`, non il nome del file."""
    with open(os.path.join(BERSAGLI, bersaglio + ".tres"), encoding="utf-8") as f:
        trovata = re.search(r'^short = "([^"]*)"', f.read(), re.M)
    return trovata.group(1) if trovata else bersaglio.upper()


def pagina(bersaglio, livello):
    im = carta()
    foto = Image.open(os.path.join(FONTE, "%s_t%d.png" % (bersaglio, livello))).convert("RGBA")
    scala = min(FOTO_LARGA / foto.width, FOTO_ALTA / foto.height)
    w, h = max(1, round(foto.width * scala)), max(1, round(foto.height * scala))
    foto = foto.resize((w, h), Image.LANCZOS)
    # L'ALFA DELLA FOTO NON BUCA LA CARTA: si stampa l'immagine su bianco, come fa una
    # stampante, e i fori restano solo quelli del trattore.
    piena = Image.new("RGBA", foto.size, CARTA)
    piena.alpha_composite(foto)
    x = (LARGO - w) // 2
    y = FOTO_SOPRA + (round(FOTO_ALTA) - h) // 2
    im.paste(piena, (x, y))
    scrivi(im, sigla(bersaglio), FOTO_SOPRA + round(FOTO_ALTA) + SIGLA_SOTTO)
    return im


def main():
    Image.MAX_IMAGE_PIXELS = None
    os.makedirs(FUORI, exist_ok=True)
    # I SOGGETTI SONO QUELLI CHE IL GIOCO HA, non quelli che il prototipo aveva: una
    # pagina per un bersaglio che non si puo' scegliere sarebbe peso morto.
    soggetti = sorted(n[:-5] for n in os.listdir(BERSAGLI) if n.endswith(".tres"))
    fatte = 0
    for s in soggetti:
        for livello in (1, 2, 3):
            if not os.path.exists(os.path.join(FONTE, "%s_t%d.png" % (s, livello))):
                print("  MANCA la foto di %s al livello %d: quella stampa non uscira'" % (s, livello))
                continue
            pagina(s, livello).save(os.path.join(FUORI, "%s_t%d.png" % (s, livello)))
            fatte += 1
    carta().save(os.path.join(FUORI, "retro.png"))
    print("scritte %d pagine e il retro in %s (%dx%d)" % (fatte, FUORI, LARGO, ALTO))


if __name__ == "__main__":
    main()
