# -*- coding: utf-8 -*-
"""Scarica da Poly Haven i modelli 3D dichiarati qui.

    python tools/prendi_modello.py [nome ...]

Stessa idea di prendi_texture.py: la scelta e' un DATO - slug, risoluzione,
motivo - e la cartella si puo' buttare e rifare. Un .gltf di Poly Haven pesa due
chilobyte e non serve a niente da solo: porta fuori il .bin e le tre texture, e
vanno prese tutte o l'import fallisce in silenzio con un modello senza materiali.

Da OpenGameArt si prende invece uno zip diretto: li' la licenza NON e' uniforme e va
guardata a mano asset per asset, quindi ogni voce la dichiara insieme all'autore. Qui
si scaricano solo CC0.
"""
import io
import json
import os
import sys
import urllib.request
import zipfile

QUI = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(os.path.dirname(QUI), "assets", "models", "esterni")

# NON C'E' LA PLAFONIERA, e l'ho scaricata prima di toglierla:
# mounted_fluorescent_lights e' un TUBO NUDO da quattro centimetri con due
# staffe, senza diffusore. Montato a tre metri sparisce, e soprattutto non ha la
# superficie che si accende - che e' l'unico pezzo che conta di una lampada. La
# plafoniera la fa tools/impianti_blender.py con otto scatole.

# slug Poly Haven -> (risoluzione, perche')
MODELLI = {
    "SchoolChair_01": ("1k",
                       "Sedia impilabile da conferenza per la sala divulgazione. La nostra era\n"
                       "quattro scatole e un tubo, e in due file da quattro si vedeva."),
    "painted_wooden_chair_01": ("1k",
                                "Sedia di legno verniciata per la cucina: e' esattamente quella che\n"
                                "sta in una cucina di servizio italiana di fine anni Novanta."),
    "filmstrip_projector_8mm": ("1k",
                                "Proiettore a pellicola su carrello per la sala divulgazione. Il nostro\n"
                                "era una scatola con un cono davanti; questo ha bobine, obiettivo e\n"
                                "carter, ed e' l'oggetto giusto per una sala del 1999 - le proiezioni\n"
                                "divulgative si facevano ancora con la pellicola e le diapositive."),
}


# OpenGameArt: cartella -> (url dello zip, pagina, autore, licenza, perche')
# Su Poly Haven una girevole da ufficio non esiste - fra le sue sedute ci sono
# poltrone, dondoli e una sedia da barbiere - e nessuna delle fonti CC0 con API
# aperta ne ha una. OpenGameArt si', ed e' l'unica ragione per cui c'e' una seconda
# fonte in questo file.
DA_OGA = {
    "office_chair": (
        "https://opengameart.org/sites/default/files/office_chair.zip",
        "https://opengameart.org/content/office-chair-1", "nisu", "CC0",
        "Girevole da ufficio con base a cinque razze, ruote e braccioli, e un set PBR"
        " completo. E' quella della sala di controllo."),
    "crt_monitor": (
        "https://opengameart.org/sites/default/files/cctvcrt.blend",
        "https://opengameart.org/content/old-crt-monitor-tv", "DREAM_SEARCH_REPEAT", "CC0",
        "Monitor a tubo, 1385 facce, con l'oggetto SCHERMO gia' separato dalla cassa:"
        " e' esattamente come serve, perche' lo schermo in partita lo comanda il gioco"
        " e la cassa no. L'altro candidato CC0 (old_computer) e' un unico oggetto da"
        " quaranta vertici, meno dettagliato di quello che avevamo fatto a mano."),
    "old_computer": (
        ("https://opengameart.org/sites/default/files/old_computer_fbx_0.zip",
         "https://opengameart.org/sites/default/files/old_computer_blend_0.zip"),
        "https://opengameart.org/content/old-computer-0", "yethiel", "CC0",
        "Monitor a tubo, torre e tastiera beige di fine anni Novanta. Servono DUE"
        " archivi: quello FBX contiene il solo modello e quello .blend la sola texture,"
        " e presi separatamente danno o un computer grigio o una figura senza forma."
        " La versione DAE li avrebbe insieme, ma Blender 5 non importa piu' Collada."),
}


def prendi_oga(cartella):
    urls, pagina, autore, licenza, perche = DA_OGA[cartella]
    if isinstance(urls, str):
        urls = (urls,)
    assert licenza == "CC0", "su OpenGameArt si scarica solo CC0: %s e' %s" % (cartella, licenza)
    fuori = os.path.join(DEST, cartella)
    os.makedirs(fuori, exist_ok=True)
    for i, url in enumerate(urls):
        if not url.lower().endswith(".zip"):
            # alcuni asset sono un file solo, senza archivio
            prendi_url(url, os.path.join(fuori, os.path.basename(url)))
            continue
        zip_locale = os.path.join(fuori, "_scaricato%d.zip" % i)
        prendi_url(url, zip_locale)
        with zipfile.ZipFile(zip_locale) as z:
            for n in z.namelist():
                if n.endswith("/") or n.lower().endswith(".blend"):
                    continue      # il .blend non serve: si tiene la texture che porta
                io.open(os.path.join(fuori, os.path.basename(n)), "wb").write(z.read(n))
        os.remove(zip_locale)
    io.open(os.path.join(fuori, "FONTE.txt"), "w", encoding="utf-8").write(
        "\n".join(["%s da OpenGameArt (%s)" % (cartella, pagina),
                   "Autore: %s. Licenza: %s." % (autore, licenza), "", perche, ""]))
    print("%-26s %d file (OpenGameArt, %s)" % (cartella, len(os.listdir(fuori)) - 1, licenza))


def prendi_url(url, percorso):
    os.makedirs(os.path.dirname(percorso), exist_ok=True)
    if os.path.exists(percorso) and os.path.getsize(percorso) > 200:
        return
    richiesta = urllib.request.Request(url, headers={"User-Agent": "astrochill-build/1.0"})
    with urllib.request.urlopen(richiesta, timeout=180) as r, io.open(percorso, "wb") as f:
        f.write(r.read())


def prendi(slug):
    risoluzione, perche = MODELLI[slug]
    url = "https://api.polyhaven.com/files/%s" % slug
    richiesta = urllib.request.Request(url, headers={"User-Agent": "astrochill-build/1.0"})
    with urllib.request.urlopen(richiesta, timeout=60) as r:
        dati = json.load(r)
    voce = dati["gltf"][risoluzione]["gltf"]
    fuori = os.path.join(DEST, slug)
    prendi_url(voce["url"], os.path.join(fuori, os.path.basename(voce["url"])))
    presi = [os.path.basename(voce["url"])]
    for relativo, sotto in voce.get("include", {}).items():
        prendi_url(sotto["url"], os.path.join(fuori, relativo.replace("/", os.sep)))
        presi.append(relativo)
    io.open(os.path.join(fuori, "FONTE.txt"), "w", encoding="utf-8").write(
        "%s da Poly Haven (https://polyhaven.com/a/%s), %s\n"
        "Licenza CC0: nessuna attribuzione richiesta.\n\n%s\n" % (slug, slug, risoluzione, perche))
    print("%-26s %d file" % (slug, len(presi)))
    return os.path.join(fuori, os.path.basename(voce["url"]))


if __name__ == "__main__":
    for s in (sys.argv[1:] or (sorted(MODELLI) + sorted(DA_OGA))):
        if s in MODELLI:
            prendi(s)
        elif s in DA_OGA:
            prendi_oga(s)
        else:
            print("sconosciuto: %s" % s)
            sys.exit(1)
