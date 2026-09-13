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
    # LA CARTA DELLA CONSOLLE. Sul piano c'erano tre scatole piatte di materiale
    # "Carta": da un metro erano tre scatole piatte. Un blocco di fogli non e' un
    # parallelepipedo - ha i fogli che non sono pari, il cartone dietro, la costa
    # incollata in rosso - e sono le tre cose che dicono "qualcuno ci lavora".
    # Questo set ne porta otto, fra blocchi interi, mezzi e fogli sciolti, che e'
    # quello che serve per fare un piano disordinato invece di un piano arredato.
    "office_notepads": ("1k",
                        "Blocchi per appunti e fogli sciolti per la consolle della\n"
                        "sala di controllo. Otto pezzi diversi: e' quello che serve\n"
                        "per sparpagliare un piano invece di posarci sopra tre\n"
                        "scatole uguali."),
    "stationery_supplies": ("1k",
                            "Cancelleria da scrivania, il contorno del registro delle\n"
                            "osservazioni. Sono gli oggetti che nessuno guarda e che,\n"
                            "se non ci sono, fanno sembrare la stanza un rendering di\n"
                            "catalogo."),
    # LA ROBA CHE SI PRENDE IN MANO. Sono i primi oggetti raccoglibili del gioco
    # (vedi world/interactables/carryable.gd), e la scelta non e' arbitraria: sono
    # le tre cose che uno porta con se' o si lascia dietro passando una notte
    # sveglio in un edificio freddo. Un termos, delle bottiglie vuote, delle
    # tazze. Niente di decorativo: se sono in giro e' perche' qualcuno le ha usate.
    "modified_thermos": ("1k",
                         "Il termos. In un osservatorio d'Appennino a novembre e' l'oggetto\n"
                         "personale per definizione: si porta su, si posa dove capita, e a\n"
                         "meta' notte lo si va a cercare."),
    "wine_bottles_01": ("1k",
                        "Bottiglie. Vuote, in giro: sono la traccia che qualcuno ha passato\n"
                        "delle ore qui dentro, ed e' quello che le rende diverse da un\n"
                        "soprammobile."),
    "tea_set_01": ("1k",
                   "Servizio da te': le tazze sono la cosa piu' ovvia da prendere in mano\n"
                   "e la piu' facile da dimenticare su un piano."),
    # IL QUADERNO DELLE PROCEDURE, accanto al monitor. Federico l'ha chiesto «con le
    # istruzioni per giocare e fare le varie fasi», e fra i tre candidati ha scelto
    # questo: un raccoglitore di pelle ad anelli, consumato, con la cinghietta. Il
    # set ne porta DUE, uno aperto e uno chiuso - si tiene il chiuso, posato sul
    # piano. Nel 1999 un organizer ad anelli di pelle e' esattamente la cosa in cui
    # chi gestisce un posto infila i fogli battuti a macchina per chi viene dopo.
    "binder_notebook": ("1k",
                        "Il quaderno di pelle ad anelli con le procedure del turno. Si\n"
                        "tiene il chiuso dei due: sta sulla consolle, a sinistra del\n"
                        "monitor, e si legge."),
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
    # LE DUE VOCI DEL QUADRO DELLA CUPOLA NON CI SONO PIU' (D-175). Erano un
    # pulsante industriale singolo e una parete di quadri vintage, tutti e due da
    # Sketchfab, tutti e due scartati da Federico: quello che serviva non era un
    # quadro a muro ma una PULSANTIERA PENSILE - la scatola gialla che penzola dal
    # cavo, con la freccia su e la freccia giu'. Su Sketchfab non c'e' (interrogata
    # l'API con sei formulazioni diverse: "crane pendant control", "hoist remote",
    # "pendant station" e altre danno zero risultati pertinenti), su Poly Haven
    # nemmeno, e Fab e BlenderKit rispondono solo a un browser vero.
    #
    # Quindi si e' MODELLATA, ed e' la sola volta in cui modellare batte scaricare:
    # la forma non e' inventata, e' la Telemecanique/Schneider Harmony XAC-A -
    # codice XACA271 - di cui il CAD quotato sta su TraceParts, ed e' quattro
    # volumi. Vedi `tools/pulsantiera_blender.py`. Il riferimento dimensionale:
    # https://www.traceparts.com/en/product/schneider-electric-harmony-xac-pendant-control-station-plastic-yellow-2-push-buttons-with-1-no?PartNumber=XACA271
    # LA MOKA: cercata su Poly Haven prima, come vuole l'ordine di questo file, e
    # li' non c'e' - 521 modelli, e in cucina hanno bollitori elettrici e vasi di
    # ottone. Su Sketchfab invece ce ne sono ventiquattro, e la scelta si e' fatta
    # guardandole: scartata quella a licenza NonCommercial (Rocco Giandomenico) e
    # quella a Free Standard di Sketchfab, che non sono licenze con cui si spedisce
    # un gioco; scartate le tre da duecentomila triangoli, che sono modelli da
    # rendering; scartata la conica di "ninja of stealth", bellissima e VESUVIANA -
    # e' una napoletana, non una Moka Express, e la sagoma che il giocatore
    # riconosce e' l'ottagono.
    #
    # RESTAVANO DUE BIALETTI QUASI PARI - quella di Samize (2134 facce), lucida da
    # negozio, e quella di shaqsh (2001), con la caldaia annerita dal fuoco - e si era
    # scelta la seconda. POI HA SCELTO FEDERICO, e ha scelto la CONICA: «ho sbagliato,
    # metti la old moka». E' una scelta che vale la pena avere scritta, perche' va
    # contro la ragione per cui l'avevo scartata io.
    #
    # LA MIA RAGIONE ERA: non e' una Moka Express, e' una napoletana - la sagoma che
    # si riconosce e' l'ottagono. E' vera come regola generale e sbagliata per QUESTA
    # cucina. In un osservatorio di provincia mezzo abbandonato non c'e' l'oggetto di
    # design che sta al MoMA: c'e' la caffettiera che qualcuno ha lasciato li' vent'anni
    # fa, ammaccata, senza marca, con l'alluminio opaco e le colature. Riconoscibile e'
    # un criterio da vetrina; questa stanza chiede l'altro criterio - vissuto.
    #
    # SOSTITUISCE UNA MOKA FATTA IN CASA. `tools/moka_blender.py` ne aveva costruita
    # una a ottagoni sulle quote del costruttore, e funzionava; ma il progetto scarica
    # quando puo' e modella quando deve (vedi la pulsantiera, qui sopra), e
    # milleseicento facce texturizzate battono novantotto facce a tinta piatta.
    "moka": (
        ("old_moka_pot.zip", "moka.zip"),
        "https://sketchfab.com/3d-models/old-moka-pot-5c860efa0cfa4566b21309d5bc4b1577",
        "ninja of stealth", "CC-BY-4.0",
        'This work is based on "Old moka pot" '
        "(https://sketchfab.com/3d-models/old-moka-pot-5c860efa0cfa4566b21309d5bc4b1577) "
        "by ninja of stealth (https://sketchfab.com/ninjaofstealth) licensed under "
        "CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)",
        "Caffettiera conica di alluminio, 1622 facce e cinque mappe. Non e' una"
        " Bialetti: e' la forma piu' vecchia, quella a tronco di cono col coperchio a"
        " cupola e il manico di bachelite - e l'alluminio e' segnato, opaco, con le"
        " colature. E' l'oggetto del registro FARE dell'attesa: la si mette sul fuoco"
        " e si aspetta che borbotti, un'attesa piccola dentro l'attesa grande."),
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
    "porta_magazzino": (
        ("porta_magazzino.zip", "metal_door.zip"),
        "https://sketchfab.com/3d-models/metal-door-5174e00a43a541e8bdd0f407c6502877",
        "tboiston", "CC-BY-4.0",
        'This work is based on "Metal door" '
        "(https://sketchfab.com/3d-models/metal-door-5174e00a43a541e8bdd0f407c6502877) "
        "by tboiston (https://sketchfab.com/tboiston) licensed under CC-BY-4.0 "
        "(http://creativecommons.org/licenses/by/4.0/)",
        "Porta di lamiera verniciata grigia con maniglia a leva e bocchetta a chiave."
        " Quella fatta a mano aveva i pezzi giusti - nervature, griglia,"
        " portalucchetto - ma erano scatole, e da un metro si vedeva che erano"
        " scatole: una porta di lamiera la fa la VERNICE, cioe' la texture, non il"
        " rilievo."
        "\n\nTRECENTOTRENTOTTO FACCE, e i pezzi SEPARATI: Main_Low,"
        " Handle_Low, HandleBase_Low, Frame_Low, Hinges_Low. E' la differenza fra un"
        " modello che si puo' usare e uno che no - il telaio ce l'abbiamo gia', lo"
        " disegna Blender dai vani, e quello che serve e' il solo BATTENTE con"
        " l'origine sul cardine. Con tutto fuso in una mesh sola non si sarebbe"
        " potuto separare senza tagliare a mano."),
    "termosifone_bagno": (
        ("termosifone_bagno.zip", "old_radiator.zip"),
        "https://sketchfab.com/3d-models/old-radiator-8a1a2e0263aa401591c1e87d824a79ef",
        "thethieme", "CC-BY-4.0",
        'This work is based on "Old Radiator" '
        "(https://sketchfab.com/3d-models/old-radiator-8a1a2e0263aa401591c1e87d824a79ef) "
        "by thethieme (https://sketchfab.com/thethieme) licensed under CC-BY-4.0 "
        "(http://creativecommons.org/licenses/by/4.0/)",
        "Radiatore di ghisa a colonne con valvole, texturizzato. Il nostro era fatto"
        " a mano con centoventi cilindri, e da vicino si vedeva che i cilindri erano"
        " cilindri: le colonne di un radiatore vero non sono tubi lisci, hanno la"
        " sezione a otto, il cappello fuso e la ruggine dove gocciola la valvola. La"
        " ghisa e' la sola cosa in questo bagno che DEVE essere segnata - un"
        " radiatore lucido in un edificio del 1962 sarebbe l'unica cosa nuova."),
    "distributore_carta": (
        ("distributore_carta.zip",
         "dispensador_de_toalla_de_papel_-_paper_dispenser.zip",
         "dispensador_de_toalla_de_papel_paper_dispenser.zip",
         "paper_dispenser.zip", "dispensador-de-toalla-de-papel-paper-dispenser.zip"),
        "https://sketchfab.com/3d-models/dispensador-de-toalla-de-papel-paper-dispenser-4af9dde390bd4c35b5f978142187cfeb",
        "tlalokan", "CC-BY-4.0",
        'This work is based on "Dispensador de toalla de papel - Paper dispenser" '
        "(https://sketchfab.com/3d-models/dispensador-de-toalla-de-papel-paper-dispenser-4af9dde390bd4c35b5f978142187cfeb) "
        "by tlalokan (https://sketchfab.com/tlalokan) licensed under CC-BY-4.0 "
        "(http://creativecommons.org/licenses/by/4.0/)",
        "Distributore di salviette di carta a muro, 2.444 facce. Quello fatto a mano"
        " erano sei scatole, e da un metro erano sei scatole: un distributore vero ha"
        " la calotta arrotondata, il labbro sotto da cui esce il foglio e il fondo"
        " rastremato, e sono tre curve - cioe' la cosa che con le scatole non si fa."
        " Arriva BIANCO SENZA MAPPE, ed e' giusto cosi': la forma la da' lui, l'eta'"
        " gliela diamo noi con la lamiera verniciata e scrostata. E' la divisione"
        " opposta a quella del radiatore, dove di fuori si e' preso proprio lo"
        " sporco."),
    "portarotolo": (
        ("portarotolo.zip", "toilet_paper_dispenser.zip"),
        "https://sketchfab.com/3d-models/toilet-paper-dispenser-96e96772a7564df0b417244bd2be33f3",
        "tobei", "CC-BY-4.0",
        'This work is based on "toilet paper dispenser" '
        "(https://sketchfab.com/3d-models/toilet-paper-dispenser-96e96772a7564df0b417244bd2be33f3) "
        "by tobei (https://sketchfab.com/tobei) licensed under CC-BY-4.0 "
        "(http://creativecommons.org/licenses/by/4.0/)",
        "Portarotolo a muro con il rotolo e il lembo che pende, 714 facce. E' il"
        " pezzo che un bagno non puo' non avere e che nessuno nota finche' non"
        " manca: un water senza portarotolo accanto legge come un sanitario da"
        " catalogo, non come un cesso in servizio. Il braccio cromato lo porta lui,"
        " ed e' l'unica cosa cromata rimasta nella stanza da quando la barra degli"
        " asciugamani e' diventata un distributore di lamiera."),
    "postazione_retro": (
        ("postazione_retro.zip", "retro_crt_computer_1990s_desktop_pc.zip",
         "retro_crt_computer_(1990s_desktop_pc).zip"),
        "https://sketchfab.com/3d-models/retro-crt-computer-1990s-desktop-pc-ea9faf1298d24497b916c27a4ea38636",
        "MadeByYeshe", "CC-BY-4.0",
        'This work is based on "Retro CRT Computer (1990s Desktop PC)" '
        "(https://sketchfab.com/3d-models/retro-crt-computer-1990s-desktop-pc-ea9faf1298d24497b916c27a4ea38636) "
        "by MadeByYeshe (https://sketchfab.com/MadeByYeshe) licensed under "
        "CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)",
        "Postazione completa del 1990: monitor, TASTIERA, MOUSE A PALLINA e case",
    ),
    "quadro_elettrico": (
        ("quadro_elettrico.zip", "small_fuse_box.zip"),
        "https://sketchfab.com/3d-models/small-fuse-box-1818361dc6554d17bef8c0400959f93f",
        "big guy", "CC-BY-4.0",
        'This work is based on "Small Fuse Box" '
        "(https://sketchfab.com/3d-models/small-fuse-box-1818361dc6554d17bef8c0400959f93f) "
        "by big guy (https://sketchfab.com/ondra.lit) licensed under CC-BY-4.0 "
        "(http://creativecommons.org/licenses/by/4.0/)",
        "Quadretto elettrico da esterno con l'ANTA SEPARATA dalla cassa, e la"
        " separazione e' tutto: un quadro che non si apre e' una scatola sul muro."
        " E' il contatore che il GDD mette in facciata - quello che governa PC,"
        " monitor, montatura e luci, e che nel 1999 si riarma A MANO, di notte,"
        " uscendo."
        "\n\nIL PULSANTE ROSSO E' DIPINTO, non modellato: nel .gltf ci sono due sole"
        " mesh, cassa e anta. Il tasto che si preme lo mettiamo noi sopra la sua"
        " serigrafia, come il pilastro sotto il telescopio - e' la stessa regola,"
        " si modella solo il pezzo che il modello scaricato non ha e che deve"
        " muoversi."),
    "telefono_ufficio": (
        ("telefono_ufficio.zip", "phone.zip"),
        "https://sketchfab.com/3d-models/phone-eaa0a0cbce964b2099b955f5ea241eee",
        "Schmoldt5000", "CC-BY-4.0",
        'This work is based on "Phone" '
        "(https://sketchfab.com/3d-models/phone-eaa0a0cbce964b2099b955f5ea241eee) "
        "by Schmoldt5000 (https://sketchfab.com/Schmoldt5000) licensed under "
        "CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)",
        "Telefono da tavolo beige con la cornetta e il filo a spirale",
    ),
    # LA STAMPANTE AD AGHI del mobile sotto la finestra nord. Quella fatta a mano
    # (arredi_blender.mobile_e_stampante) e' una scatola con sopra una scatola piu'
    # piccola, e da mezzo metro e' quello che sembra. Questa e' una MACCHINA VERA -
    # Okidata Microline 320 Turbo, 9 aghi, uscita nel 1990 - col coperchio acrilico,
    # la manopola del rullo e il pannello serigrafato PRINT QUALITY / CHARACTER
    # PITCH: e' esattamente la stampante che nel 1999 sta attaccata al PC di
    # acquisizione, perche' un'osservazione la si vuole su carta e la carta a moduli
    # continui non si inceppa da sola di notte.
    #
    # E' LARGA 36 CM, NON 54. La ML320 e' una carrozza da 9 pollici: 360 x 275 x 106
    # mm. L'impronta a mano ne dichiarava 54 di larghezza, e posa_modello scala sulla
    # PIANTA - passargliela cosi' com'e' fa una stampante taglia e mezzo piu' grande
    # del vero. La misura giusta la mette arredi_blender.
    #
    # IL MODULO CONTINUO NON CE L'HA, e resta fatto a mano: il modello e' la macchina
    # sola, senza il foglio che esce dal trattore e ricade a fisarmonica dietro il
    # mobile. E' la stessa regola del pulsante del quadro elettrico - si modella il
    # pezzo che il modello scaricato non ha.
    "stampante_aghi": (
        ("stampante_aghi.zip", "okidata_microline_320_turbo.zip"),
        "https://sketchfab.com/3d-models/okidata-microline-320-turbo-f7bf859023544e91ab622a8f18862ecf",
        "Remik.Papaj", "CC-BY-4.0",
        'This work is based on "OKIDATA Microline 320 Turbo" '
        "(https://sketchfab.com/3d-models/okidata-microline-320-turbo-f7bf859023544e91ab622a8f18862ecf) "
        "by Remik.Papaj (https://sketchfab.com/Remik.Papaj) licensed under "
        "CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)",
        "Stampante ad aghi beige da ufficio, 1.528 triangoli e texture PBR sporche."
        " L'alternativa CC-BY scaricabile era una Heathkit anni Settanta senza"
        " coperchio ne' trattore, e il tributo alla OKI 320 low poly e' CC BY-NC:"
        " non si puo' usare.",
    ),
    # I FALDONI. Sopra lo schedario della sala di controllo c'e' una PILA DI TRE
    # SCATOLE di materiale "Carta" (vedi arredi_blender.schedario), e da un metro
    # sono tre scatole: un faldone non e' un parallelepipedo - ha la costa
    # rigida, l'etichetta, il buco per il dito e gli anelli dentro, e sono quelle
    # quattro cose a dirlo. E' anche l'arredo che un osservatorio ha per forza:
    # i log delle osservazioni, prima di stare su un floppy, stavano li'.
    #
    # SU POLY HAVEN NON CI SONO (interrogata l'API sui 521 modelli: c'e' un
    # `binder_notebook`, che e' un'agenda di pelle, e `office_notepads`, che sono
    # i blocchi che gia' usiamo). Su Sketchfab si', CC-BY, e sono due modelli
    # perche' i due posti vogliono due cose diverse.
    "faldoni_fila": (
        "faldoni_fila.zip",
        "https://sketchfab.com/3d-models/several-folders-1a493b49ef954985ab8057ca66c387d5",
        "janexx", "CC-BY-4.0",
        'This work is based on "Several Folders" '
        "(https://sketchfab.com/3d-models/several-folders-1a493b49ef954985ab8057ca66c387d5) "
        "by janexx (https://sketchfab.com/janexx) licensed under CC-BY-4.0 "
        "(http://creativecommons.org/licenses/by/4.0/)",
        "Cinque faldoni ad anelli in fila, neri, con l'etichetta sulla costa e il"
        " foro per il dito: e' il raccoglitore da ufficio italiano, quello che sta"
        " in piedi su uno scaffale. 5.130 triangoli per cinque pezzi - meno di"
        " milleduecento l'uno - ed e' quello che serve per riempire un ripiano"
        " senza pagarlo."),
    "faldone": (
        "faldone.zip",
        "https://sketchfab.com/3d-models/ring-binder-a0026e7d1b244b9a9223daf4223c9372",
        "Jura", "CC-BY-4.0",
        'This work is based on "Ring Binder" '
        "(https://sketchfab.com/3d-models/ring-binder-a0026e7d1b244b9a9223daf4223c9372) "
        "by Jura (https://sketchfab.com/Jurassik94) licensed under CC-BY-4.0 "
        "(http://creativecommons.org/licenses/by/4.0/)",
        "Un faldone solo, nero, con l'etichetta scritta a mano. Trecento triangoli:"
        " e' il pezzo per le PILE - sopra lo schedario, sopra un armadio, di"
        " traverso su una consolle - dove ne servono tre o quattro sfalsati e"
        " nessuno li guarda da vicino."),
    # IL PROIETTORE A DIAPOSITIVE, e sostituisce quello a pellicola.
    #
    # LA RICHIESTA, DA FEDERICO: «il proiettore secondo me va cambiato, forse e'
    # un po' troppo old style, servirebbe uno con le diapositive». Ha ragione, e
    # la ragione e' storica prima che estetica: nel 1999, in una sala divulgativa
    # di un osservatorio, la serata la si faceva con le DIAPOSITIVE - il cielo,
    # le nebulose, le foto dei soci - e il proiettore a pellicola 8 mm era gia'
    # roba da cineteca. La scelta precedente (`filmstrip_projector_8mm`, Poly
    # Haven) l'aveva scritto anche nel proprio commento - «le proiezioni
    # divulgative si facevano ancora con la pellicola E LE DIAPOSITIVE» - e fra le
    # due ha preso quella sbagliata.
    #
    # E' UNA SCANSIONE DA MUSEO, quindi ha la forma vera e la sporcizia vera, e in
    # cambio pesa: 692.583 triangoli da decimare prima di portarli in scena. Il
    # gemello e' il «Narcyz» dello stesso museo (397.252 triangoli, sempre CC0):
    # piu' leggero, con la maniglia e il cavo, ma il caricatore non si vede. Qui
    # il caricatore SI DEVE VEDERE - e' l'unica cosa che distingue a colpo
    # d'occhio un proiettore per diapositive da uno per pellicola, cioe' tutto il
    # motivo per cui lo si sta cambiando.
    "proiettore_diapositive": (
        "proiettore_diapositive.zip",
        "https://sketchfab.com/3d-models/diaprex-b-11-slide-projector-0b107065c28f4972a72d5053d3f24591",
        "Virtual Museums of Malopolska", "CC0",
        "",
        "Proiettore per diapositive Diaprex B-11 con il CARICATORE A SLITTA che"
        " sporge di fianco, obiettivo e carter di lamiera. E' l'apparecchio delle"
        " serate divulgative, e la slitta e' il pezzo che lo dice."),
}

# Le texture arrivano a 4096: dentro il .glb della stanza sarebbero ventidue megabyte
# per un oggetto solo, e il tubo si guarda da un metro. Si riducono a 1K, e si tiene
# quello che serve - il metallico NON serve, vedi telescopio_blender.py.
LATO_RIDOTTO = 1024


def prendi_a_mano(cartella):
    zip_atteso, pagina, autore, licenza, credito, perche = A_MANO[cartella]
    fuori = os.path.join(DEST, cartella)
    # PIU' DI UN NOME AMMESSO, e non e' pigrizia. Sketchfab consegna lo zip col nome
    # che l'autore ha dato al modello - `old_radiator.zip` - mentre qui la cartella si
    # chiama come la usiamo noi. Pretendere il nostro nome vuol dire chiedere a chi
    # scarica di rinominare a mano, e un passo a mano in piu' e' un passo che prima o
    # poi si sbaglia. Si accetta il nome dell'autore E il nostro.
    nomi = (zip_atteso,) if isinstance(zip_atteso, str) else tuple(zip_atteso)
    # E DUE CARTELLE AMMESSE, per la stessa ragione dei nomi: «la cartella dove
    # mettiamo i modelli» ha due letture ovvie - `assets/models/_da_scaricare` e
    # `assets/models/esterni/_da_scaricare` - e chi scarica ne sceglie una senza
    # pensarci. Pretenderne una sola vuol dire far fallire lo script con un
    # «MANCA» mentre il file c'e', a venti centimetri di distanza.
    cartelle_zip = [os.path.join(DEST, "_da_scaricare"),
                    os.path.join(os.path.dirname(DEST), "_da_scaricare")]
    cartella_zip = cartelle_zip[0]
    archivio = os.path.join(cartella_zip, nomi[0])
    for c in cartelle_zip:
        for n in nomi:
            if os.path.exists(os.path.join(c, n)):
                archivio = os.path.join(c, n)
                break
        else:
            continue
        break
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

    # UN MODELLO PUO' AVERE PIU' DI UN SET, e per un pezzo questo non lo sapeva.
    # Il quadro elettrico ne porta due - `Fuse_box_main_*` e `fuse_box_door_*` -
    # e finivano tutti e due negli stessi tre file: il primo arrivato vinceva, il
    # secondo veniva scartato in silenzio (`if os.path.exists: continue`), e in
    # gioco la cassa e l'anta si ritrovavano la stessa faccia. Nessun errore,
    # nessun avviso, e il difetto si vede solo guardando il modello.
    #
    # Con un set solo i nomi restano quelli piatti di sempre - `color.jpg` - e
    # nessuno dei modelli gia' fatti cambia. Con piu' set ognuno tiene il proprio
    # prefisso, e `modellare.usa_le_ridotte()` lo ritrova dal nome dell'immagine
    # originale.
    def prefisso(nome):
        radice = os.path.splitext(nome)[0]
        for s in ("_baseColor", "_diffuse", "_albedo", "_normal",
                  "_metallicRoughness", "_roughness"):
            i = radice.lower().rfind(s.lower())
            if i > 0:
                return radice[:i].lower()
        return radice.lower()

    candidati = [n for n in os.listdir(cartella_texture)
                 if n.lower() not in ("color.jpg", "normal.png", "roughness.jpg")
                 and (e_una(n.lower(), ("_basecolor", "_diffuse", "_albedo",
                                        "_normal", "_metallicroughness", "_roughness")))]
    set_ = sorted({prefisso(n) for n in candidati})
    molti = len(set_) > 1
    for n in candidati:
        b = n.lower()
        # `_rid_` E NON SOLO IL PREFISSO, o il file ridotto si chiama come il suo
        # sorgente: `fuse_box_door` + `normal.png` fa esattamente
        # `fuse_box_door_normal.png`, cioe' l'originale a 4096 - che «esiste gia'»
        # e quindi non viene ridotto. Le mappe di colore uscivano (l'estensione
        # cambia da .jpeg a .jpg) e le normali no, in silenzio.
        capo = (prefisso(n) + "_rid_") if molti else ""
        if e_una(b, ("_basecolor", "_diffuse", "_albedo")):
            lavori.append((n, capo + "color.jpg", None))
        elif e_una(b, ("_normal",)):
            lavori.append((n, capo + "normal.png", None))
        elif e_una(b, ("_metallicroughness", "_roughness")):
            # nel glTF la rugosita' e' il canale VERDE e la metallicita' il BLU:
            # si estrae il verde, il blu si butta.
            lavori.append((n, capo + "roughness.jpg", 1))
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
