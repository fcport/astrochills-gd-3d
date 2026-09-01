# -*- coding: utf-8 -*-
"""La CAMERA CCD: SBIG ST-8 con la ruota filtri CFW-8 attaccata.

    "D:/programs/blender5/blender.exe" --background --python tools/ccd_blender.py

DA DOVE VIENE LA FORMA, e non e' inventata. Il GDD la nomina per modello - «SBIG
ST-8, chip KAF-1600 da 1530x1020 pixel di 9 micron, raffreddata a Peltier» piu' la
«SBIG CFW-8, cinque posizioni» - e dice anche che questo pezzo va modellato a mano
perche' lo si guarda da vicino. Le quote e l'aspetto vengono dal SITO DI SBIG di
allora, recuperato dall'archivio:

    testa ottica   5 pollici di diametro x 3 di profondita' = 12,5 x 7,5 cm
    peso           2,2 libbre / 1 kg
    attacco        T-Thread, nasi da 1,25" e 2" in dotazione
    back focus     0,92 pollici / 2,3 cm
    CFW-8          si attacca davanti, cinque filtri da 1,25", +1" di back focus

E la foto di catalogo (Model ST-8XE, SBIG 2002) dice il resto, che nessuna tabella
dice: il corpo e' un CILINDRO NERO con quattro alette anulari di raffreddamento
tutt'intorno, appoggiato su una base squadrata; in cima, DECENTRATO, un blocchetto
quadrato con dentro la ghiera filettata; dietro, un pannello con la presa di
corrente circolare e due connettori a vaschetta.

NERO E NON GRIGIO: e' alluminio anodizzato nero, e a occhio legge come nero opaco.
Il corpo usa quindi `PlasticaNera` e non `Metallo` - non perche' sia plastica, ma
perche' quel materiale ha il colore e la ruvidezza giusti; il metallo lucido resta
alla ghiera, alle viti e ai connettori, che sono gli unici pezzi che brillano.

L'ORIGINE STA SULLA BASE, con l'asse ottico in su. Posata su un piano sta come
nella foto; per montarla al telescopio la si gira portando il proprio +Y lungo
l'uscita del focheggiatore, che il modello del telescopio dichiara con un Empty
(vedi `telescopio_blender.py`).

LA RUOTA FILTRI E' MODELLATA INSIEME e non gira. In un osservatorio le due cose si
montano una volta e restano montate; e la ruota la comanda il software - in gioco
la scelta del filtro e' una schermata sul CRT, non un gesto. Il giorno che servisse
farla girare, e' un cilindro solo da staccare.
"""
import os
import sys

import bpy

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
import importlib   # noqa: E402
for _m in ("modellare",):
    if _m in sys.modules:
        importlib.reload(sys.modules[_m])
from modellare import (cilindro, esporta, finisci, lampada,   # noqa: E402
                       prepara_render, pulisci, scatola)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "ccd.glb")
PROVINO = os.path.join(RADICE, "_confronto", "13_ccd.png")

# --- le quote, in metri, dal sito SBIG ---------------------------------------
DIAMETRO = 0.125          # 5 pollici
PROFONDA = 0.075          # 3 pollici, tutto compreso

# Come i 7,5 cm si spartiscono in altezza. La somma DEVE fare `PROFONDA`, e sotto
# c'e' il controllo che lo pretende: sono tre numeri scelti guardando la foto, e
# tre numeri scelti guardando una foto si sbagliano.
# LE PROPORZIONI SI CONTANO SULLA FOTO, non si spartiscono in parti uguali: nel
# catalogo il pacco delle alette occupa piu' di meta' dell'altezza, la base ne
# prende un quarto scarso e il blocchetto quello che resta. Al primo giro erano
# 22/33/20 e la camera leggeva come tre dischi impilati invece che come un corpo
# raffreddato con una base sotto.
BASE_ALTA = 0.019         # la scatola squadrata col pannello dei connettori
CORPO_ALTO = 0.043        # il cilindro alettato
NASO_ALTO = 0.013         # il blocchetto quadrato con la ghiera

# LA RUOTA FILTRI STA DAVANTI E AGGIUNGE UN POLLICE, che e' il numero che SBIG
# dichiara come back focus aggiunto. Il suo diametro non e' dichiarato da nessuna
# parte: cinque filtri da 1,25" su un carosello non ci stanno sotto i 10 cm, e
# nella foto d'assieme la ruota e' larga quanto la camera. 11,5 cm.
RUOTA_ALTA = 0.022
# PIU' STRETTA DEL CORPO, e il primo giro non lo era: a 11,5 cm la ruota copriva le
# alette e l'oggetto leggeva come due dischi impilati con un coperchio sopra.
# Nell'assieme disegnato da SBIG la CFW-8 e' visibilmente piu' piccola della testa,
# ed e' quel gradino a dire che sono due pezzi avvitati insieme.
RUOTA_D = 0.098

ALETTE = 5                # quante se ne contano nella foto
ALETTA_SPESSA = 0.004
NASO_LATO = 0.046
NASO_INDIETRO = 0.012     # di quanto il blocchetto e' decentrato, come in foto

# Il filetto T-Thread e' M42x0.75: 42 mm di diametro, ed e' lo standard di mezza
# astrofotografia. Il foro dentro e' quello che si vede da davanti.
FILETTO_D = 0.042
FORO_D = 0.030


def controlla():
    somma = BASE_ALTA + CORPO_ALTO + NASO_ALTO
    if abs(somma - PROFONDA) > 0.0005:
        print("\nATTENZIONE: base+corpo+naso fanno %.3f, la camera e' profonda %.3f"
              % (somma, PROFONDA))
        sys.exit(1)


def base():
    """La scatola squadrata sotto, e il pannello dei connettori sul retro.

    NON E' LARGA QUANTO IL DIAMETRO. Al primo giro lo era, e i quattro angoli
    sporgevano di due centimetri buoni oltre il cilindro: la camera sembrava
    appoggiata su un piedistallo. Nella foto la scatola sta DENTRO l'ingombro
    tondo, e si vede sporgere solo davanti, dove c'e' il pannello.
    """
    r = DIAMETRO / 2 - 0.006
    scatola("PlasticaNera", -r, r, 0.0, BASE_ALTA, -r, r)
    # I CONNETTORI. Nella foto sono quattro: la presa di corrente circolare, poi
    # tre connettori dati in fila. Sulla ST-8 del 1999 il collegamento al PC e'
    # una PARALLELA, non l'USB della XE fotografata - ma a questa scala si vede
    # una vaschetta metallica e basta, e la differenza non arriva all'occhio.
    z = -r + 0.002
    y = BASE_ALTA / 2
    cilindro("Metallo", -0.040, z, y - 0.009, y + 0.009, 0.009, seg=12)
    for x in (-0.010, 0.016, 0.042):
        scatola("Metallo", x - 0.011, x + 0.011, y - 0.006, y + 0.006, z - 0.004, z)


def corpo():
    """Il cilindro nero con le alette anulari di raffreddamento."""
    y0 = BASE_ALTA
    y1 = BASE_ALTA + CORPO_ALTO
    # LE ALETTE SPORGONO, il cilindro sotto no: e' quella differenza di raggio a
    # fare l'ombra a righe che rende riconoscibile questo oggetto da lontano.
    cilindro("PlasticaNera", 0.0, 0.0, y0, y1, DIAMETRO / 2 - 0.007, seg=20)
    passo = CORPO_ALTO / (ALETTE + 1)
    for k in range(ALETTE):
        y = y0 + passo * (k + 1) - ALETTA_SPESSA / 2
        cilindro("PlasticaNera", 0.0, 0.0, y, y + ALETTA_SPESSA, DIAMETRO / 2, seg=20)
    # la faccia piana in cima, con le quattro viti a vista
    cilindro("PlasticaNera", 0.0, 0.0, y1 - 0.004, y1, DIAMETRO / 2, seg=20)
    for (x, z) in ((-0.048, -0.020), (0.048, -0.020), (-0.048, 0.036), (0.048, 0.036)):
        cilindro("Metallo", x, z, y1 - 0.001, y1 + 0.002, 0.0035, seg=6)


def naso():
    """Il blocchetto quadrato con la ghiera filettata, decentrato come nel vero."""
    y0 = BASE_ALTA + CORPO_ALTO
    y1 = y0 + NASO_ALTO
    h = NASO_LATO / 2
    zc = NASO_INDIETRO
    scatola("PlasticaNera", -h, h, y0, y1, zc - h, zc + h)
    # I due pomelli di bloccaggio sui fianchi.
    for x in (-h - 0.004, h + 0.004):
        cilindro("Metallo", x, zc, y1 - 0.010, y1 - 0.002, 0.004, seg=8)
    # La ghiera filettata dentro il blocchetto, e il buco nero dell'ottica: senza
    # il buco il naso legge come un tappo, e una camera col tappo su e' una camera
    # che non guarda niente.
    cilindro("Metallo", 0.0, zc, y1 - 0.012, y1 + 0.001, FILETTO_D / 2, seg=16)
    cilindro("Schermo", 0.0, zc, y1 - 0.014, y1 + 0.0015, FORO_D / 2, seg=16)


def ruota():
    """La CFW-8: il disco della ruota filtri, davanti alla camera."""
    y0 = PROFONDA
    y1 = y0 + RUOTA_ALTA
    zc = NASO_INDIETRO
    cilindro("PlasticaNera", 0.0, zc, y0, y1, RUOTA_D / 2, seg=20)
    # Il motorino passo-passo sporge da un lato: e' il pezzo che distingue una
    # ruota filtri da un anello distanziale, e nell'assieme si vede.
    scatola("PlasticaNera", 0.030, 0.062, y0 + 0.004, y1 - 0.004,
            zc - 0.016, zc + 0.016)
    # e il naso davanti, quello che entra nel focheggiatore
    cilindro("Metallo", 0.0, zc, y1 - 0.002, y1 + 0.014, FILETTO_D / 2, seg=16)
    cilindro("Schermo", 0.0, zc, y1 - 0.002, y1 + 0.0155, FORO_D / 2, seg=16)


controlla()
pulisci()
base()
corpo()
naso()
ruota()

pezzi = finisci(morbidi=("Metallo",))
facce = sum(len(o.data.polygons) for o in pezzi)
print("  la camera e' fatta di %d facce in %d pezzi" % (facce, len(pezzi)))
print("  ingombro dichiarato: %.0f mm di diametro, %.0f di profondita' "
      "(%.0f con la ruota filtri)"
      % (DIAMETRO * 1000, PROFONDA * 1000, (PROFONDA + RUOTA_ALTA + 0.014) * 1000))
if facce > 3000:
    print("\nATTENZIONE: %d facce per una camera CCD sono troppe." % facce)
    sys.exit(1)

esporta(USCITA)

# --- il provino: si GUARDA, non si deduce ------------------------------------
# La lezione del quadro (D-174) e della pulsantiera: un modello che non si e' mai
# visto e' un modello che non si sa se e' venuto, e nessun controllo numerico dice
# «sembra una camera CCD».
os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
scatta = prepara_render(900, 900, cielo=(0.16, 0.17, 0.19))
# LE LUCI VANNO CON IL QUADRATO DELLA DISTANZA, e questo oggetto e' piccolo: le
# stesse potenze del provino della pulsantiera - mezzo metro di oggetto, luci a
# mezzo metro - qui stanno a venti centimetri da una camera di dodici, cioe'
# arrivano sei volte piu' forti. Al primo giro il corpo anodizzato NERO e' uscito
# grigio chiaro, e il provino diceva che il colore era sbagliato quando era
# sbagliata la lampada. Un provino bruciato risponde sempre di si'.
lampada("Chiave", (0.22, 0.26, 0.24), 0.55, tipo="AREA", dimensione=0.5)
lampada("Riempimento", (-0.24, 0.12, 0.18), 0.10)
lampada("Contro", (0.0, 0.18, -0.28), 0.18)
# DUE SCATTI: uno di tre quarti da sopra, che e' come la si guarda posata su un
# piano, e uno da dietro, che e' l'unico modo di vedere il pannello dei connettori
# - il pezzo che dice «questo e' uno strumento» e non un barattolo.
scatta(PROVINO, (0.17, 0.16, 0.19), (0.0, 0.05, 0.0), lente=50.0)
scatta(PROVINO.replace("13_", "13b_"), (0.05, 0.09, -0.22), (0.0, 0.03, 0.0),
       lente=50.0)
