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
    "mandorlata": ("MetalPlates006", (176, 174, 170),
                   "Lamiera mandorlata per l'impalcato della passerella. Prima portava la"
                   " stessa lamiera verniciata della carpenteria e leggeva come un disco"
                   " di cartone: un piano su cui si cammina in quota ha il rilievo"
                   " antiscivolo, ed e' quel rilievo a dirti che ci puoi salire."),
    "libri": ("Fabric062", (198, 196, 190),
              "Tela da rilegatura per i dorsi dei libri. Sugli scaffali c'erano"
              " parallelepipedi a tinta piatta: da un metro leggevano come un motivo"
              " geometrico, non come una libreria. La tela si tinge NEUTRA apposta -"
              " il colore di ogni dorso arriva dal materiale e moltiplica la mappa,"
              " cosi' otto colori diversi condividono una trama sola."),
    # IL BAGNO. Due piastrelle diverse e non una sola: in un bagno italiano di quegli
    # anni il rivestimento a parete e il pavimento non sono mai lo stesso pezzo. A
    # muro la ceramica bianca lucida da 15x15, che riflette e si sporca di aloni; a
    # terra il gres beige opaco, piu' grande e piu' vissuto. Usare la stessa per
    # entrambi e' l'errore che fa leggere un bagno come una piscina.
    "piastrelle-muro": ("Tiles036", None,
                        "Ceramica bianca lucida quadrata per il rivestimento del bagno"
                        " fino a 1,60 m. E' quella della foto: bianco crema, fuga"
                        " sottile, lucida."),
    "piastrelle-pavimento": ("Tiles142", None,
                             "Gres beige opaco per il pavimento del bagno. Segnato"
                             " quanto basta: un pavimento di bagno del 1999 non e'"
                             " nuovo di posa."),
    "carta": ("Paper004", (222, 214, 196),
              "Carta ingiallita: i volumi coricati, i registri, i fogli sui banchi."),
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
        "Licenza CC0: nessuna attribuzione richiesta. 1K JPG.\n%s\n\n%s\n%s" % (asset, asset, righello(asset), perche, nota))
    print("%-15s <- %-13s %s" % (cartella, asset, ", ".join(sorted(scritte))))


def righello(asset):
    """Quanto copre il quadro, nel mondo. E' IL RIGHELLO, e va scritto sul posto.

    ambientCG la misura la pubblica - Wood048 copre 80x80 cm, Wood066 quaranta - e
    finche' nessuno la leggeva le ripetizioni in `modellare.TEXTURE` erano numeri
    indovinati a occhio: il rovere della consolle si ripeteva ogni 1,10 invece che
    ogni 0,80, quello della cucina ogni 0,80 invece che ogni 0,40, cioe' il doppio.
    Scritta qui accanto alla cartella, la legge `gen_blockout.verifica_ripetizioni()`
    e il numero smette di essere un'opinione.

    Non tutti i set la dichiarano - l'intonaco, il terrazzo, la lamiera no - e in
    quel caso lo si dice, cosi' chi guarda sa che li' la scala la sceglie l'occhio e
    che il perche' deve stare scritto accanto al numero.
    """
    import json
    import urllib.request
    u = "https://ambientcg.com/api/v2/full_json?id=%s&include=dimensionsData" % asset
    try:
        r = urllib.request.Request(u, headers={"User-Agent": "astrochill"})
        a = (json.load(urllib.request.urlopen(r, timeout=25)).get("foundAssets")
             or [{}])[0]
        dx, dy = int(a.get("dimensionX") or 0), int(a.get("dimensionY") or 0)
    except Exception as e:
        return "Il quadro copre una misura che non si e' potuta chiedere (%s)." % e
    a_capo = chr(10)
    if not dx:
        return ("Il quadro copre una misura NON dichiarata da ambientCG: la "
                "ripetizione in" + a_capo + "modellare.TEXTURE si sceglie guardando "
                "il disegno, e il perche' va scritto li'.")
    return ("Il quadro copre %d x %d cm (dichiarato da ambientCG): e' il righello, "
            "e la" % (dx, dy) + a_capo
            + "ripetizione in modellare.TEXTURE deve valere quello, salvo motivo "
              "scritto.")


if __name__ == "__main__":
    voluti = sys.argv[1:] or sorted(SET)
    for c in voluti:
        if c not in SET:
            print("sconosciuto: %s (ce ne sono %s)" % (c, ", ".join(sorted(SET))))
            sys.exit(1)
        prendi(c)
