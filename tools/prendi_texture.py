# -*- coding: utf-8 -*-
"""Scarica da ambientCG i set di texture dichiarati qui, e li normalizza.

    python tools/prendi_texture.py [nome ...]

PERCHE' NON A MANO. Ogni set finora e' stato scaricato, spacchettato e rinominato a
mano, quattro volte con quattro comandi diversi: il modo sicuro di ritrovarsi fra un
mese con una cartella di file di cui nessuno sa piu' da dove vengono. Qui la scelta
e' DATO - id dell'asset, tinta, motivo - e la cartella si puo' buttare e rifare.

Normalizza tre cose che sbagliate non si vedono subito:
  * prende la **NormalGL** e non la NormalDX. Con quella sbagliata l'illuminazione
    risulta scavata al contrario, e su una texture ferma non si nota.
  * scarta displacement e anteprime, che nel glTF non entrano.
  * applica la TINTA dove serve. Una plastica grigia non diventa beige nel materiale:
    il glTF porta baseColorFactor per il colore piatto, ma qui il colore arriva dalla
    mappa, e la mappa va tinta. Si tinge il file, cosi' quello che Blender vede e'
    quello che Godot riceve.

Licenza: tutti gli asset ambientCG sono CC0, nessuna attribuzione richiesta.
"""
import io
import os
import sys
import zipfile

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
DEST = os.path.join(RADICE, "assets", "textures")
CACHE = os.path.join(QUI, "__texture_cache__")

# cartella -> (asset ambientCG, tinta media voluta in sRGB o None, perche')
SET = {
    "intonaco": ("Plaster001", None,
                 "Intonaco civile per i muri interni."),
    "metallo": ("Metal032", None,
                "Lamiera verniciata per strutture, sedie e carpenteria."),
    "legno-ufficio": ("Wood048", None,
                      "Rovere chiaro per la consolle della sala di controllo. Prima c'era un\n"
                      "truciolare a scaglie: in una sala di controllo non ha senso."),
    "legno-cucina": ("Wood066", None,
                     "Ciliegio rossiccio per i mobili della cucina."),
    "legno-teche": ("Wood051", None,
                    "Noce scuro verniciato per teche, libreria e tavolo della sala."),
    "legno-porte": ("Wood049", None,
                    "Legno medio neutro per ante e telai delle porte."),
    "pavimento": ("Terrazzo013", None,
                  "Graniglia: il pavimento degli edifici pubblici italiani di quegli anni,"
                  " e non c'e' niente che dati meglio un interno del 1999."),
    "tetto": ("Asphalt033", None,
              "Guaina bituminosa per le coperture piane."),
    "lamiera": ("PaintedMetal012", (196, 196, 190),
                "Lamiera verniciata bianca, un po' segnata: le carcasse delle plafoniere\n"
                "e gli apparecchi a parete. Erano un grigio piatto, e sul soffitto\n"
                "leggevano come blocchi appena piu' chiari dell'intonaco invece che\n"
                "come lampade."),
    "diffusore": ("Plastic013A", (225, 224, 215),
                  "Plastica opalina del diffusore. Serve soprattutto ACCESA: la stessa\n"
                  "mappa fa da emissiva nel materiale della scena, e una superficie\n"
                  "luminosa con una trama dentro si legge come un vetro, una senza come\n"
                  "un rettangolo bianco disegnato sopra il soffitto."),
    "placca": ("Plastic010", (219, 209, 184),
               "La plastica avorio degli interruttori. Stesso asset della plastica dei\n"
               "calcolatori ma con un'altra tinta: il beige di un monitor del 1999 e\n"
               "l'avorio di una placca non sono lo stesso colore."),
    "plastica": ("Plastic010", (207, 191, 148),
                 "Plastica beige dei calcolatori. L'asset e' grigio neutro e viene tinto:\n"
                 "il beige dei computer del 1999 non e' un colore qualsiasi, e' quello che\n"
                 "data la stanza. Con un monitor bianco o nero la stanza si sposta di\n"
                 "dieci anni."),
}

MAPPE = {"_Color.jpg": "color.jpg", "_Roughness.jpg": "roughness.jpg",
         "_NormalGL.jpg": "normal.jpg", "_Metalness.jpg": "metallic.jpg"}


def scarica(asset):
    os.makedirs(CACHE, exist_ok=True)
    percorso = os.path.join(CACHE, asset + "_1K-JPG.zip")
    if os.path.exists(percorso) and os.path.getsize(percorso) > 10000:
        return percorso
    import urllib.request
    url = "https://ambientcg.com/get?file=%s_1K-JPG.zip" % asset
    print("  scarico %s" % url)
    # senza User-Agent ambientCG risponde 403: rifiuta il client di default di urllib
    richiesta = urllib.request.Request(url, headers={"User-Agent": "astrochill-build/1.0"})
    with urllib.request.urlopen(richiesta, timeout=180) as r, io.open(percorso, "wb") as f:
        f.write(r.read())
    return percorso


def tingi(percorso, media_voluta):
    """Riscala i canali perche' la media dell'immagine cada sulla tinta voluta."""
    from PIL import Image
    im = Image.open(percorso).convert("RGB")
    piccola = im.resize((64, 64))
    px = list(piccola.getdata())
    media = [sum(c[i] for c in px) / float(len(px)) for i in range(3)]
    fattori = [media_voluta[i] / max(1.0, media[i]) for i in range(3)]
    canali = [c.point(lambda v, f=fattori[i]: min(255, int(v * f)))
              for i, c in enumerate(im.split())]
    Image.merge("RGB", canali).save(percorso, quality=92)
    return media, fattori


def prendi(cartella):
    asset, tinta, perche = SET[cartella]
    fuori = os.path.join(DEST, cartella)
    os.makedirs(fuori, exist_ok=True)
    scritte = []
    with zipfile.ZipFile(scarica(asset)) as z:
        for n in z.namelist():
            for suffisso, nuovo in MAPPE.items():
                if n.endswith(suffisso):
                    io.open(os.path.join(fuori, nuovo), "wb").write(z.read(n))
                    scritte.append(nuovo)
    nota = ""
    if tinta and "color.jpg" in scritte:
        media, fattori = tingi(os.path.join(fuori, "color.jpg"), tinta)
        nota = ("\nTinta: media originale RGB %.0f %.0f %.0f, riportata a %d %d %d\n"
                "(fattori %.2f %.2f %.2f). La rigenera tools/prendi_texture.py.\n"
                % (media[0], media[1], media[2], tinta[0], tinta[1], tinta[2], *fattori))
    io.open(os.path.join(fuori, "FONTE.txt"), "w", encoding="utf-8").write(
        "%s da ambientCG (https://ambientcg.com/view?id=%s)\n"
        "Licenza CC0: nessuna attribuzione richiesta. 1K JPG.\n\n%s\n%s" % (asset, asset, perche, nota))
    print("%-15s <- %-13s %s" % (cartella, asset, ", ".join(sorted(scritte))))


if __name__ == "__main__":
    voluti = sys.argv[1:] or sorted(SET)
    for c in voluti:
        if c not in SET:
            print("sconosciuto: %s (ce ne sono %s)" % (c, ", ".join(sorted(SET))))
            sys.exit(1)
        prendi(c)
