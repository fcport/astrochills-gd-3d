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


# Sketchfab: cartella -> (zip atteso, pagina, autore, licenza, credito, perche')
#
# QUI IL DOWNLOAD NON SI PUO' AUTOMATIZZARE, ed e' l'unico caso in tutto il progetto.
# L'API di RICERCA di Sketchfab e' aperta - e' cosi' che questo modello e' stato
# trovato - ma quella di DOWNLOAD vuole un account autenticato: nessuna chiave da
# mettere in un file, va cliccato da un browser con la sessione aperta. Quindi la
# SCELTA resta versionata qui come tutte le altre, e a mancare e' solo il file.
#
# Le tre alternative scaricabili sono state aperte e MISURATE prima di scartarle,
# non guardate in anteprima:
#   * Dobson CC0 (OpenGameArt, Light Game Studio): 310 facce, dieci oggetti chiamati
#     "Cylinder.003" - un assemblaggio di primitive, meno di quello che avevamo a mano.
#   * Rifrattore CC-BY 3.0 (OpenGameArt, cptx032): 924 triangoli e NESSUN materiale,
#     ed e' un cannocchiale da appassionato su treppiede fotografico.
#   * Poly Haven non ha telescopi (interrogata l'API), Poly Pizza risponde 401 senza chiave.
A_MANO = {
    "telescopio_riflettore": (
        "reflector_telescope.zip",
        "https://sketchfab.com/3d-models/reflector-telescope-62549e8c60d24ee5adb2a01a2c226a03",
        "GhInko", "CC-BY-4.0",
        'This work is based on "Reflector telescope" '
        "(https://sketchfab.com/3d-models/reflector-telescope-62549e8c60d24ee5adb2a01a2c226a03) "
        "by GhInko (https://sketchfab.com/GhInko) licensed under CC-BY-4.0 "
        "(http://creativecommons.org/licenses/by/4.0/)",
        "Newtoniano su montatura equatoriale TEDESCA con contrappeso, 13.272 facce,"
        " texturizzato. E' l'unico dei candidati che sia lo strumento giusto: in una"
        " cupola non ci sta un cannocchiale su treppiede, ci sta un tubo su una"
        " montatura fissata a un pilastro. E la sua montatura e' gia' tarata per la"
        " nostra latitudine - l'asse polare misurato sta a 43 gradi, Montegrimano e'"
        " a 43,9: si raddrizza di un grado, non si reinventa."),
    "lavabo_bagno": (
        "lavabo_bagno.zip",
        "https://sketchfab.com/3d-models/33cbd0ac6ae24bd292783a4e06fc4138",
        "Antonio Rossin", "CC-BY-4.0",
        'This work is based on "Lavabo" '
        "(https://sketchfab.com/3d-models/33cbd0ac6ae24bd292783a4e06fc4138) "
        "by Antonio Rossin (https://sketchfab.com/antoniorossin) licensed under "
        "CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)",
        "Lavabo a semicolonna con bacino rettangolare arrotondato e miscelatore"
        " monocomando: la forma di serie di un lavabo italiano degli anni Novanta."
        "\n\nIL SECONDO TENTATIVO. Il primo era un 'Old Dirty Pedestal Sink':"
        " forma"
        " giusta, ma la sua ceramica stava a 130 su 255 contro i 212 degli altri due"
        " sanitari e le piastrelle pulite. Non era vecchio, era sporco - e le due"
        " cose non sono la stessa. In un osservatorio in funzione i sanitari sono"
        " puliti di forma datata, non da rudere."),
    "bidet_bagno": (
        "bidet_bagno.zip",
        "https://sketchfab.com/3d-models/e52d1be9d7594dd39c8ae8e3dcab9cd5",
        "Joele segreto", "CC-BY-4.0",
        'This work is based on "Bidet" '
        "(https://sketchfab.com/3d-models/e52d1be9d7594dd39c8ae8e3dcab9cd5) "
        "by Joele segreto (https://sketchfab.com/joelesegreto) licensed under CC-BY-4.0 "
        "(http://creativecommons.org/licenses/by/4.0/)",
        "Bidet monoforo con miscelatore, 2.600 facce. Un bagno italiano senza bidet non e' un bagno italiano, e questo ha la forma giusta - catino ovale su base piena - invece che quella sospesa di adesso."),
    "wc_bagno": (
        "wc_bagno.zip",
        "https://sketchfab.com/3d-models/6ac515a1c4154db18b5b4bd0b46d6405",
        "Allan-Jay Branscombe", "CC-BY-4.0",
        'This work is based on "Game Ready - Dirty Old Toilet" '
        "(https://sketchfab.com/3d-models/6ac515a1c4154db18b5b4bd0b46d6405) "
        "by Allan-Jay Branscombe (https://sketchfab.com/AllanJayBranscombe) "
        "licensed under CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)",
        "Water con cassetta bassa appoggiata e ceramica segnata, 7.646 facce. La"
        " cassetta appoggiata e' quella del 1999: incassata a muro e' di adesso,"
        " alta con la catena e' di cinquant'anni prima. E lo sporco e' voluto - non"
        " un rudere, un sanitario vecchio."),
}

# Le texture arrivano a 4096: dentro il .glb della stanza sarebbero ventidue megabyte
# per un oggetto solo, e il tubo si guarda da un metro. Si riducono a 1K, e si tiene
# quello che serve - il metallico NON serve, vedi telescopio_blender.py.
LATO_RIDOTTO = 1024


def prendi_a_mano(cartella):
    zip_atteso, pagina, autore, licenza, credito, perche = A_MANO[cartella]
    fuori = os.path.join(DEST, cartella)
    archivio = os.path.join(DEST, "_da_scaricare", zip_atteso)
    if not os.path.exists(os.path.join(fuori, "scene.gltf")):
        if not os.path.exists(archivio):
            print("MANCA %s." % cartella)
            print("  Sketchfab consegna i file solo a un account autenticato,")
            print("  quindi questo passo e' a mano:")
            print("    1. apri %s" % pagina)
            print("    2. Download 3D Model -> glTF")
            print("    3. lascia lo zip in %s" % os.path.dirname(archivio))
            print("  poi rilancia questo script.")
            return False
        os.makedirs(fuori, exist_ok=True)
        with zipfile.ZipFile(archivio) as z:
            z.extractall(fuori)
    riduci(os.path.join(fuori, "textures"))
    righe = ["%s da Sketchfab (%s)" % (cartella, pagina),
             "Autore: %s. Licenza: %s - L'ATTRIBUZIONE E' OBBLIGATORIA." % (autore, licenza),
             "", "Credito da riportare ovunque il modello sia distribuito:", credito,
             "", perche,
             "", "Scaricato a mano: l'API di download di Sketchfab vuole un account.",
             "Le texture sono state ridotte a %d px da prendi_modello.py;" % LATO_RIDOTTO,
             "gli originali a 4096 restano nello zip.", ""]
    io.open(os.path.join(fuori, "FONTE.txt"), "w", encoding="utf-8").write("\n".join(righe))
    print("%-26s pronto (Sketchfab, %s: attribuzione obbligatoria)" % (cartella, licenza))
    return True


def riduci(cartella_texture):
    """Porta le mappe a LATO_RIDOTTO e le rinomina come tutte le altre del progetto."""
    from PIL import Image
    if not os.path.isdir(cartella_texture):
        return
    lavori = []
    # L'ESTENSIONE NON E' SEMPRE .png, e per un po' questo pezzo ha creduto di si'.
    # Il water del bagno porta `M_Toilet_baseColor.jpeg`: non finendo per `.png` non
    # veniva riconosciuto, non veniva ridotto, e il modello restava attaccato
    # all'originale da tre megabyte. Nessun errore, nessun avviso - solo un .glb da
    # trentatre megabyte, piu' pesante dell'intero edificio. Si guarda il NOME della
    # mappa e si accetta qualunque formato PIL sappia aprire.
    def e_una(nome, che_cosa):
        radice = os.path.splitext(nome.lower())[0]
        return any(radice.endswith(s) for s in che_cosa)

    for n in os.listdir(cartella_texture):
        b = n.lower()
        if b in ("color.jpg", "normal.png", "roughness.jpg"):
            continue                      # gia' nostro: non si riduce due volte
        if e_una(b, ("_basecolor", "_diffuse", "_albedo")):
            lavori.append((n, "color.jpg", None))
        elif e_una(b, ("_normal",)):
            lavori.append((n, "normal.png", None))
        elif e_una(b, ("_metallicroughness", "_roughness")):
            # nel glTF la rugosita' e' il canale VERDE e la metallicita' il BLU:
            # si estrae il verde, il blu si butta.
            lavori.append((n, "roughness.jpg", 1))
    for sorgente, destino, canale in lavori:
        fuori = os.path.join(cartella_texture, destino)
        if os.path.exists(fuori):
            continue
        im = Image.open(os.path.join(cartella_texture, sorgente))
        if canale is not None:
            im = im.convert("RGB").split()[canale].convert("L")
        im = im.convert("L" if canale is not None else "RGB")
        im = im.resize((LATO_RIDOTTO, LATO_RIDOTTO), Image.LANCZOS)
        im.save(fuori, quality=92)
        print("    %s -> %s (%d px)" % (sorgente, destino, LATO_RIDOTTO))


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
    for s in (sys.argv[1:] or (sorted(MODELLI) + sorted(DA_OGA) + sorted(A_MANO))):
        if s in MODELLI:
            prendi(s)
        elif s in DA_OGA:
            prendi_oga(s)
        elif s in A_MANO:
            if not prendi_a_mano(s):
                sys.exit(1)
        else:
            print("sconosciuto: %s" % s)
            sys.exit(1)
