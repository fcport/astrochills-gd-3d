# -*- coding: utf-8 -*-
"""Gli arredi della sala di controllo, dalla stessa impronta che li fa collidere.

    "D:/programs/blender5/blender.exe" --background --python tools/arredi_blender.py

L'IMPRONTA COMANDA. Ogni pezzo di questo file sta dentro il rettangolo che
geometria.ARREDI_PC gli assegna, e un controllo alla fine lo verifica: quello
contro cui il giocatore sbatte e quello che vede sono la stessa cosa. Senza il
vincolo la mesh cresce e la collisione no, e si finisce a passare attraverso un
monitor o a fermarsi contro l'aria.

Sta fuori da osservatorio_blender.py perche' l'edificio e l'arredo cambiano con
ritmi diversi: rigenerare una scrivania non deve costare la ricostruzione della
cupola, del telescopio e dei sei render.

Produce assets/models/controllo_pc.glb.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
import importlib   # noqa: E402
for _m in ("geometria", "modellare"):
    if _m in sys.modules:
        importlib.reload(sys.modules[_m])
from geometria import ARREDI_PC, verifica_arredi, V_SILL   # noqa: E402
from modellare import (barra, bm_di, cilindro, cilindro_orizz, esporta,   # noqa: E402
                       finisci, lampada, materiale, posa_modello, prepara_render,
                       prisma, pulisci, scatola, scatola_inclinata, verifica_impronte)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "controllo_pc.glb")
RENDER = os.path.join(RADICE, "_bmad-output", "planning-artifacts", "gdds",
                      "gdd-astrochills-gd-3d-2026-08-24")

IMPRONTE = {n: (x0, z0, x1, z1, h) for (n, x0, z0, x1, z1, h) in ARREDI_PC}

# La girevole viene da fuori. Poly Haven non ne ha una - fra le sue sedute ci sono
# poltrone, dondoli e una sedia da barbiere - e questa arriva da OpenGameArt,
# CC0. Vedi tools/prendi_modello.py.
SEDIA_UFFICIO = os.path.join(RADICE, "assets", "models", "esterni",
                             "office_chair", "Office_Chair.fbx")
# Il monitor a tubo viene da fuori, OpenGameArt CC0, e ha lo SCHERMO come oggetto
# separato dalla cassa: e' esattamente la divisione che serve, perche' quello che
# si vede sullo schermo lo comanda il gioco e la cassa no.
MONITOR = os.path.join(RADICE, "assets", "models", "esterni",
                       "crt_monitor", "cctvcrt.blend")

# --- i pezzi -----------------------------------------------------------------
# Dove si siede: sotto questa fascia di Z, fra il piano e il pavimento, non ci va
# NIENTE. C'era un ripiano basso a 0,24 lungo meta' consolle, e ci si sbatteva le
# ginocchia; e il fianco centrale cadeva proprio dove stanno i piedi.
VANO_GAMBE = (IMPRONTE["Sedia1"][1] - 0.15, IMPRONTE["Sedia1"][3] + 0.15)


def consolle():
    x0, z0, x1, z1, alt = IMPRONTE["Consolle"]
    g0, g1 = VANO_GAMBE
    scatola("LegnoUfficio", x0, x1, alt - 0.04, alt, z0, z1)                   # piano
    # fianchi: i due estremi e uno intermedio, messo FUORI dal vano gambe
    for z in (z0, z1 - 0.04, (g1 + z1) / 2):
        scatola("LegnoUfficio", x0 + 0.02, x1, 0.02, alt - 0.04, z, z + 0.04)
    # traversa sotto il bordo: alzata a 0,66 di luce libera, che e' la quota sotto cui
    # un ginocchio non passa. Prima cominciava a 0,60.
    scatola("LegnoUfficio", x1 - 0.06, x1, alt - 0.09, alt - 0.04, z0 + 0.04, z1 - 0.04)
    scatola("Metallo", x0 + 0.02, x1, 0.0, 0.02, z0, z1)                # piedini


def postazione(zc, accesa):
    """Il monitor a tubo, la tastiera e il cavo.

    IL MONITOR NON E' PIU' NOSTRO. Il nostro era una cassa rastremata con cornice,
    tasti e feritoie - fatto bene per essere fatto di scatole - ma sessanta facce
    restano sessanta facce, e questo ne ha milletrecento. Soprattutto arriva con lo
    SCHERMO gia' staccato dalla cassa, che e' la divisione di cui il gioco ha
    bisogno: la cassa e' arredo, lo schermo e' un display che qualcosa comanda.

    La tastiera resta la nostra: gli ottanta tasti li abbiamo, e nessuno dei modelli
    CC0 trovati ne aveva una migliore.
    """
    x0, _z0, _x1, _z1, alt = IMPRONTE["Consolle"]
    y_piano = alt
    # MONITOR E TASTIERA SULLA STESSA MEZZERIA, che e' quella della sedia. Stava
    # scostato di venti centimetri, e il motivo scritto accanto era che al centro
    # avrebbe occupato il posto del mouse - vero quando il mouse stava a +0,38, cioe'
    # dallo stesso lato. Poi il mouse e' passato a destra, a -0,38, e quel motivo e'
    # scaduto senza che nessuno tornasse a leggerlo: restava un monitor sfasato di
    # venti centimetri rispetto alla tastiera, che davanti si vede subito - ci si
    # siede diritti sulla tastiera e lo schermo e' di sbieco.
    #
    # E' il modo tipico in cui questo progetto sbaglia: non un numero preso a caso,
    # ma un numero giusto il giorno che e' stato scritto, sopravvissuto alla ragione
    # che lo teneva su. Il mouse adesso sta a 1,62 e il monitor centrato va da 1,76 a
    # 2,24: non si toccano nemmeno.
    posati = posa_modello(MONITOR, (x0 + 0.03, zc - 0.24, x0 + 0.53, zc + 0.24, 0.42),
                          gradi=0.0, appoggio=y_piano)
    # lo schermo acceso: in partita ci andra' il display vero, qui basta che si veda
    # che e' acceso, ed e' l'unica luce propria della stanza
    for o in posati:
        if o.type != "MESH":
            continue
        if "screen" in o.name.lower():
            if accesa:
                o.data.materials.clear()
                o.data.materials.append(materiale("Acceso"))
        else:
            # la cassa arriva grigia: le si mette la nostra plastica beige, che e'
            # la stessa della tastiera e della torre - e il beige data la stanza
            o.data.materials.clear()
            o.data.materials.append(materiale("Plastica"))

    # --- tastiera: la base a cuneo e i tasti veri ----------------------------
    kx0, kx1 = x0 + 0.485, x0 + 0.655
    kz0, kz1 = zc - 0.235, zc + 0.235
    scatola("Plastica", kx0, kx1, y_piano, y_piano + 0.014, kz0, kz1)
    scatola("Plastica", kx0, kx0 + 0.045, y_piano + 0.014, y_piano + 0.028, kz0, kz1)
    RIGHE, COLONNE = 5, 16
    px = (kx1 - kx0 - 0.024) / RIGHE
    pz = (kz1 - kz0 - 0.020) / COLONNE
    for r in range(RIGHE):
        for c in range(COLONNE):
            ky = y_piano + 0.014 + 0.014 * (RIGHE - 1 - r) / (RIGHE - 1.0)
            scatola("Plastica", kx0 + 0.012 + r * px, kx0 + 0.012 + (r + 0.78) * px,
                    ky, ky + 0.008,
                    kz0 + 0.010 + c * pz, kz0 + 0.010 + (c + 0.80) * pz)
    cilindro("Gomma", x0 + 0.06, zc + 0.17, 0.10, y_piano - 0.05, 0.008, 8)
    return posati


def sedia(nome, verso_x=-1.0):
    """La girevole della sala di controllo, rifatta pezzo per pezzo.

    NON VIENE DA FUORI, E NON PER SCELTA. Le altre sedie dell'osservatorio sono
    modelli CC0 presi da Poly Haven, che pero' non ha una girevole da ufficio: fra
    le sue sedute ci sono poltrone, dondoli e una sedia da barbiere. Nessun'altra
    fonte CC0 raggiungibile senza chiave ne ha una. Quindi questa e' fatta in casa,
    e vale la pena farla per bene: e' l'unico posto dell'edificio dove il giocatore
    sta seduto per venti notti.

    Le cose che rendono una girevole una girevole, e che nella prima versione non
    c'erano: le razze RASTREMATE con la forcella e la ruota di taglio, il manicotto
    telescopico del pistone, il blocco del meccanismo sotto la seduta, il cuscino
    con il bordo arrotondato davanti, lo schienale in tre tratti con la curva
    lombare, e i braccioli. `verso_x` e' dove guarda chi ci siede.
    """
    x0, z0, x1, z1, alt = IMPRONTE[nome]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    r = min(x1 - x0, z1 - z0) / 2 - 0.015
    dietro = -verso_x                      # da che parte sta lo schienale

    # --- base a cinque razze, forcelle e ruote --------------------------------
    for k in range(5):
        ang = 2 * math.pi * k / 5 + math.pi / 5
        dx, dz = math.cos(ang), -math.sin(ang)
        # la razza si rastrema: larga al mozzo, sottile alla forcella
        for t, larghezza, spessore, quota in ((0.28, 0.075, 0.055, 0.085),
                                              (0.62, 0.055, 0.040, 0.075),
                                              (0.88, 0.045, 0.032, 0.068)):
            bmesh.ops.create_cube(bm_di("Metallo"), size=1.0, matrix=(
                Matrix.Translation(Vector((cx + dx * r * t, -(cz + dz * r * t), quota)))
                @ Matrix.Rotation(ang, 4, "Z")
                @ Matrix.Diagonal(Vector((r * 0.34, larghezza, spessore, 1.0)))))
        # forcella e ruota: la ruota gira su un asse orizzontale, di taglio
        fx, fz = cx + dx * r * 0.94, cz + dz * r * 0.94
        cilindro("Metallo", fx, fz, 0.052, 0.088, 0.016, 8)
        perp = Vector((-dz, -dx, 0.0)).normalized() * 0.021
        barra("Gomma", (fx - perp.x, 0.032, fz - perp.y),
              (fx + perp.x, 0.032, fz + perp.y), 0.032, 10)
    cilindro("Metallo", cx, cz, 0.078, 0.115, 0.055, 14)          # mozzo

    # --- pistone, manicotto e meccanismo -------------------------------------
    cilindro("Plastica", cx, cz, 0.115, 0.300, 0.048, 14, r2=0.042)
    cilindro("Metallo", cx, cz, 0.300, 0.455, 0.026, 12)
    scatola("Plastica", cx - 0.11, cx + 0.11, 0.440, 0.500, cz - 0.13, cz + 0.13)
    # la leva di regolazione, sul fianco destro di chi siede
    cilindro_orizz("Metallo", cx + 0.02, 0.470, cz + 0.20, "z", 0.14, 0.011, 8)

    # --- seduta: scocca, cuscino e bordo arrotondato -------------------------
    scatola("Plastica", cx - 0.235, cx + 0.235, 0.498, 0.522, cz - 0.235, cz + 0.235)
    scatola("Tessuto", cx - 0.225, cx + 0.225, 0.520, 0.585, cz - 0.225, cz + 0.225)
    # il bordo davanti scende: e' quello che distingue un cuscino da una tavola
    scatola_inclinata("Tessuto", cx + verso_x * 0.225, 0.548, cz,
                      0.070, 0.052, 0.450, -26.0 * verso_x, asse="z")

    # --- schienale in tre tratti, con la curva lombare -----------------------
    bx = cx + dietro * 0.215
    cilindro("Metallo", bx, cz, 0.545, 0.640, 0.022, 10)
    scatola("Plastica", bx - 0.035, bx + 0.035, 0.600, 0.660, cz - 0.075, cz + 0.075)
    tratti = ((0.660, 0.790, 0.150, -7.0), (0.790, 0.920, 0.185, 1.0), (0.920, alt, 0.165, 8.0))
    for (ya, yb, mezzo, gradi) in tratti:
        scatola_inclinata("Tessuto", bx + dietro * 0.012, (ya + yb) / 2, cz,
                          0.055, yb - ya, mezzo * 2, gradi * dietro, asse="z")

    # --- braccioli -----------------------------------------------------------
    for lato in (-1, 1):
        za = cz + lato * 0.245
        scatola("Plastica", cx - 0.02, cx + 0.10, 0.520, 0.660, za - 0.020, za + 0.020)
        scatola("Plastica", cx - verso_x * 0.02, cx + verso_x * 0.19, 0.655, 0.685,
                za - 0.028, za + 0.028)


def rack():
    x0, z0, x1, z1, alt = IMPRONTE["Rack"]
    scatola("Metallo", x0, x1, 0.0, 0.10, z0, z1)                       # zoccolo
    scatola("Metallo", x0 + 0.02, x1, 0.10, alt, z0, z0 + 0.04)         # montanti
    scatola("Metallo", x0 + 0.02, x1, 0.10, alt, z1 - 0.04, z1)
    scatola("Metallo", x1 - 0.03, x1, 0.10, alt, z0, z1)                # schiena
    scatola("Metallo", x0 + 0.02, x1, alt - 0.03, alt, z0, z1)          # cielo
    # apparati: fronte verso ovest, cioe' verso la stanza
    quote = [(0.18, 0.31), (0.34, 0.47), (0.50, 0.72), (0.76, 0.89), (0.95, 1.30)]
    for i, coppia in enumerate(quote):
        a, b = coppia
        scatola("Plastica" if i % 2 else "Metallo", x0, x0 + 0.06, a, b, z0 + 0.04, z1 - 0.04)
        for k in range(3):
            scatola("Acceso" if (i + k) % 3 == 0 else "Schermo",
                    x0 - 0.004, x0 + 0.002, a + 0.030, a + 0.045,
                    z0 + 0.10 + k * 0.06, z0 + 0.13 + k * 0.06)
    # matassa di cavi che esce dal fondo
    for k in range(4):
        cilindro("Gomma", x1 - 0.08 - k * 0.02, z0 + 0.15 + k * 0.12, 0.02, 0.55, 0.009, 8)


def schedario():
    x0, z0, x1, z1, alt = IMPRONTE["Schedario"]
    scatola("Metallo", x0 + 0.02, x1, 0.0, alt, z0, z1)
    for k in range(4):
        a = 0.04 + k * (alt - 0.06) / 4
        b = a + (alt - 0.06) / 4 - 0.012
        scatola("Metallo", x0, x0 + 0.02, a, b, z0 + 0.02, z1 - 0.02)
        scatola("Plastica", x0 - 0.02, x0, (a + b) / 2 - 0.015, (a + b) / 2 + 0.015,
                (z0 + z1) / 2 - 0.07, (z0 + z1) / 2 + 0.07)
    # una pila di raccoglitori sopra
    for k in range(3):
        scatola("Carta", x0 + 0.10, x0 + 0.42, alt + k * 0.055, alt + 0.05 + k * 0.055,
                z0 + 0.08 + k * 0.02, z1 - 0.08 + k * 0.02)


def mobile_e_stampante():
    x0, z0, x1, z1, alt = IMPRONTE["Mobile"]
    scatola("LegnoUfficio", x0, x1, 0.06, alt, z0, z1)
    scatola("Metallo", x0 + 0.03, x1 - 0.03, 0.0, 0.06, z0 + 0.03, z1 - 0.03)
    for k in range(2):                                                  # due ante
        a = x0 + 0.02 + k * (x1 - x0 - 0.04) / 2
        b = a + (x1 - x0 - 0.04) / 2 - 0.015
        scatola("LegnoUfficio", a, b, 0.10, alt - 0.04, z1, z1 + 0.015)
        scatola("Metallo", b - 0.08, b - 0.04, (0.10 + alt) / 2 - 0.01,
                (0.10 + alt) / 2 + 0.01, z1 + 0.012, z1 + 0.035)
    # stampante ad aghi, con il modulo continuo che esce e ricade
    sx0, sx1 = x0 + 0.18, x0 + 0.72
    scatola("Plastica", sx0, sx1, alt, alt + 0.13, z0 + 0.05, z1 - 0.04)
    scatola("Plastica", sx0 + 0.04, sx1 - 0.04, alt + 0.13, alt + 0.17, z0 + 0.10, z0 + 0.22)
    scatola("Schermo", sx1 - 0.16, sx1 - 0.05, alt + 0.128, alt + 0.135, z0 + 0.30, z0 + 0.36)
    for k in range(5):                                                  # il foglio a fisarmonica
        scatola("Carta", sx0 + 0.06, sx1 - 0.06, alt + 0.17 - k * 0.006,
                alt + 0.175 - k * 0.006, z1 - 0.06 - k * 0.035, z1 - 0.02 - k * 0.035)
    # pila di stampati sull'altro lato
    for k in range(4):
        scatola("Carta", x1 - 0.42, x1 - 0.10, alt + k * 0.012, alt + 0.010 + k * 0.012,
                z0 + 0.08 + k * 0.008, z1 - 0.06 + k * 0.008)


def minutaglia():
    """Quello che dice che qualcuno ci lavora, e quello che occupa i due metri di
    piano rimasti liberi quando la seconda postazione e' sparita."""
    x0, z0, x1, z1, alt = IMPRONTE["Consolle"]
    zs = (IMPRONTE["Sedia1"][1] + IMPRONTE["Sedia1"][3]) / 2
    # tappetino e mouse, a fianco della tastiera
    # IL MOUSE STA A DESTRA, e destra qui vuol dire z DECRESCENTE: chi si siede
    # guarda la vetrata, cioe' verso -X, e con il pollice in su la sua destra cade
    # su -Z. Stava a +0,38 - la mano sinistra - ed e' una di quelle cose che non si
    # calcolano, si guardano.
    zm = zs - 0.38
    scatola("Gomma", x0 + 0.48, x0 + 0.66, alt, alt + 0.004, zm - 0.09, zm + 0.09)
    scatola("Plastica", x0 + 0.53, x0 + 0.61, alt + 0.004, alt + 0.032, zm - 0.045, zm + 0.045)
    # il telefono: nel 1999 e' l'unico modo che ha questo posto di parlare con fuori
    tz = zs + 0.85
    scatola("Plastica", x0 + 0.10, x0 + 0.34, alt, alt + 0.055, tz - 0.11, tz + 0.11)
    scatola("Plastica", x0 + 0.13, x0 + 0.23, alt + 0.055, alt + 0.075, tz - 0.09, tz + 0.09)
    for dz in (-0.075, 0.075):
        scatola("Plastica", x0 + 0.25, x0 + 0.33, alt + 0.055, alt + 0.085, tz + dz - 0.02, tz + dz + 0.02)
    scatola("Plastica", x0 + 0.24, x0 + 0.34, alt + 0.085, alt + 0.105, tz - 0.10, tz + 0.10)
    for k in range(4):
        cilindro("Gomma", x0 + 0.08, tz + 0.08 - k * 0.012, alt + 0.02, alt + 0.03, 0.010, 8)
    # il registro delle osservazioni, aperto, con la penna
    rz = zs + 1.15
    scatola("Carta", x0 + 0.10, x0 + 0.52, alt, alt + 0.018, rz - 0.15, rz + 0.15)
    scatola("Carta", x0 + 0.12, x0 + 0.50, alt + 0.018, alt + 0.021, rz - 0.14, rz + 0.14)
    cilindro_orizz("Plastica", x0 + 0.31, alt + 0.026, rz - 0.02, "z", 0.14, 0.005, 8)
    # una pila di stampati sull'angolo, e la tazza
    for k in range(5):
        scatola("Carta", x0 + 0.14, x0 + 0.44, alt + k * 0.006, alt + 0.005 + k * 0.006,
                z1 - 0.52 + k * 0.004, z1 - 0.22 + k * 0.004)
    cilindro("Carta", x0 + 0.58, z1 - 0.32, alt, alt + 0.095, 0.038, 14)
    cilindro_orizz("Carta", x0 + 0.62, alt + 0.055, z1 - 0.32, "z", 0.035, 0.008, 8)
    # lampada da tavolo: base, stelo, braccio inclinato, paralume
    lx, lz = x0 + 0.16, z1 - 0.10
    cilindro("Metallo", lx, lz, alt, alt + 0.018, 0.075, 14)
    cilindro("Metallo", lx, lz, alt + 0.018, alt + 0.33, 0.011, 8)
    bmesh.ops.create_cone(bm_di("Metallo"), cap_ends=True, cap_tris=False, segments=8,
                          radius1=0.011, radius2=0.011, depth=0.22,
                          matrix=Matrix.Translation(Vector((lx + 0.09, -(lz - 0.02), alt + 0.38)))
                          @ Matrix.Rotation(math.radians(70.0), 4, "Y"))
    bmesh.ops.create_cone(bm_di("Metallo"), cap_ends=True, cap_tris=False, segments=16,
                          radius1=0.070, radius2=0.032, depth=0.10,
                          matrix=Matrix.Translation(Vector((lx + 0.17, -(lz - 0.03), alt + 0.35)))
                          @ Matrix.Rotation(math.radians(145.0), 4, "Y"))
    # UNA torre sola, e all'estremita' sud: sotto il posto a sedere non c'e' niente
    zt = z1 - 0.34
    scatola("Plastica", x0 + 0.06, x0 + 0.28, 0.0, 0.42, zt, zt + 0.20)
    # il fronte guarda a est come il monitor: floppy, tasto, spia e feritoie
    fx = x0 + 0.28
    scatola("Schermo", fx - 0.004, fx + 0.006, 0.315, 0.331, zt + 0.035, zt + 0.135)
    scatola("Plastica", fx - 0.002, fx + 0.010, 0.300, 0.316, zt + 0.140, zt + 0.162)
    scatola("Plastica", fx - 0.002, fx + 0.012, 0.150, 0.176, zt + 0.030, zt + 0.062)
    scatola("Acceso", fx + 0.002, fx + 0.010, 0.158, 0.168, zt + 0.075, zt + 0.091)
    for k in range(6):
        y = 0.040 + k * 0.014
        scatola("Schermo", fx - 0.002, fx + 0.004, y, y + 0.007, zt + 0.035, zt + 0.165)


# --- costruzione -------------------------------------------------------------
pulisci()
consolle()
_s = IMPRONTE["Sedia1"]
_monitor = postazione((_s[1] + _s[3]) / 2, True)
# 180 gradi: come nasce guarda dalla parte opposta, e girata cosi' finiva rivolta
# alla finestra invece che alla consolle
_sedia = posa_modello(SEDIA_UFFICIO, IMPRONTE["Sedia1"], gradi=270.0)
rack()
schedario()
mobile_e_stampante()
minutaglia()

oggetti = finisci(morbidi=("Metallo", "Gomma"))

print()
for o in oggetti:
    print("  %-10s %5d facce" % (o.name, len(o.data.polygons)))

# --- controlli ---------------------------------------------------------------
problemi = list(verifica_arredi())

problemi += verifica_impronte(
    oggetti + _sedia + _monitor,
    [(x0, z0, x1, z1) for (x0, z0, x1, z1, _h) in IMPRONTE.values()])

# quanto la roba sulla consolle sale dentro la vetrata: non e' un difetto, ma va detto
_lim = IMPRONTE["Consolle"][2]
alto = max([(o.matrix_world @ v.co).z for o in oggetti for v in o.data.vertices
            if (o.matrix_world @ v.co).x < _lim] or [0.0])
print("\n  la roba sulla consolle arriva a %.2f m, il vetro parte da %.2f: "
      "entra nel vetro per %.0f cm" % (alto, V_SILL, max(0.0, alto - V_SILL) * 100))

if problemi:
    print("\nATTENZIONE:")
    for p in problemi:
        print("  " + p)
    sys.exit(1)

esporta(USCITA)

# --- render di controllo -----------------------------------------------------
scatta_su = prepara_render()

# L'EDIFICIO ENTRA SOLO ORA, dopo l'export: serve al render e non al modello.
# Senza, il colpo d'occhio che conta - la consolle, il vetro, il telescopio dietro -
# non si puo' guardare, e si consegnerebbe la stanza alla cieca.
_osservatorio = os.path.join(RADICE, "assets", "models", "osservatorio.glb")
if os.path.exists(_osservatorio):
    bpy.ops.import_scene.gltf(filepath=_osservatorio)
    lampada("Cupola", (2.6, 2.9, 2.5), 300.0)
    lampada("Corridoio", (6.8, 2.6, 3.9), 60.0)

def scatta(nome, posizione, mira, lente=28.0):
    scatta_su(os.path.join(RENDER, nome), posizione, mira, lente)


# dalla porta verso la consolle: e' come la stanza si vede entrando
scatta("controllo-pc.png", (7.60, 1.62, 4.10), (5.90, 0.95, 2.20), lente=22.0)
scatta("controllo-pc-postazione.png", (6.95, 1.45, 1.30), (5.60, 1.00, 1.62), lente=30.0)
# in piedi dietro la consolle, e attraverso il vetro il telescopio: e' la ragione
# per cui la porta e' sparita e il muro e' rimasto
scatta("controllo-pc-vetrata.png", (6.90, 1.65, 2.50), (2.60, 2.05, 2.50), lente=24.0)
# e da seduti alla postazione accesa, che e' dove si passa la notte
scatta("controllo-pc-seduti.png", (6.35, 1.22, 1.58), (3.20, 2.15, 2.20), lente=26.0)
