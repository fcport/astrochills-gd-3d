# -*- coding: utf-8 -*-
"""La cucina, dalla stessa impronta che la fa collidere.

    "D:/programs/blender5/blender.exe" --background --python tools/cucina_blender.py

Stesso patto di arredi_blender.py: `geometria.ARREDI_CUCINA` dichiara i rettangoli
in pianta, qui dentro ci si costruisce, e un controllo alla fine conta i vertici
usciti. Quello che si vede e quello contro cui si sbatte restano la stessa cosa.

LA STANZA E' UN CORRIDOIO: 4,95 x 2,40 m. Non e' una cucina abitabile con il
tavolo in mezzo, e provare a farla sembrare tale la renderebbe solo scomoda. E'
una cucina in linea - tutto su un lato, il passaggio sull'altro - con il tavolino
spinto nell'angolo che la porta non spazza.

Produce assets/models/cucina.glb.
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
from geometria import ARREDI_CUCINA, COTTURA, FUOCHI, verifica_arredi, W_SILL   # noqa: E402
from modellare import (bm_di, cilindro, cilindro_orizz, esporta, finisci,   # noqa: E402
                       lampada, materiale, prepara_render, prisma, pulisci, scatola,
                       posa_modello, scatola_inclinata, usa_le_ridotte,
                       verifica_impronte, verifica_luce)

# La finestra sopra il lavello, in coordinate di gioco: il muro nord sta a z 1,50 e
# il vano va da x 9,10 a 10,30. Serve a due cose - interrompere il paraschizzi e i
# pensili, e misurare quanto la si tappa.
FINESTRA = ("finestra cucina", 9.10, 1.50, 10.30, 2.10, W_SILL, "x")

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "cucina.glb")
RENDER = os.path.join(RADICE, "_bmad-output", "planning-artifacts", "gdds",
                      "gdd-astrochills-gd-3d-2026-08-24")

IMPRONTE = {n: (x0, z0, x1, z1, h) for (n, x0, z0, x1, z1, h) in ARREDI_CUCINA}

# Sedia di legno verniciata, presa da fuori. Poly Haven, CC0.
SEDIA = os.path.join(RADICE, "assets", "models", "esterni",
                     "painted_wooden_chair_01", "painted_wooden_chair_01_1k.gltf")

# IL LAVELLO E I PIATTI VENGONO DA FUORI, e li ha scelti Federico: Sketchfab, CC-BY,
# con il credito in CREDITI.md. Li scompatta `tools/prendi_modello.py`.
LAVELLO_GLTF = os.path.join(RADICE, "assets", "models", "esterni", "lavello_cucina",
                            "scene.gltf")
PIATTO_GLTF = os.path.join(RADICE, "assets", "models", "esterni", "piatto", "scene.gltf")

# La cucina e' addossata al muro NORD: il fronte dei mobili guarda +z, cioe' verso
# chi entra. Tutte le maniglie, le ante e i rubinetti nascono da questo.
BASE = IMPRONTE["CucinaBase"]
X_A, Z_MURO, X_B, Z_FRONTE, H_TOP = BASE

# IL LAVELLO IN PIANTA, x0 z0 x1 z1: 86 x 52, la misura di serie di un monovasca con
# gocciolatoio, a quattro centimetri dal muro e dal bordo del piano. Sta sopra il
# vano con le due ante, dove sotto c'e' il sifone e non ci vanno cassetti.
LAVELLO = (X_A + 0.81, Z_MURO + 0.04, X_A + 1.67, Z_FRONTE - 0.04)
# IL FORO DEL LAVELLO, e sta qui perche' lo devono conoscere in due: il piano di
# lavoro in formica e la carcassa ci passano tutti e due sopra, e finche' e' stato
# dichiarato in uno solo la vasca e' rimasta coperta dall'altro. E' UN CENTIMETRO
# DENTRO IL BORDO del lavello: il piano ci passa sotto, e nessuna faccia del foro
# resta a filo di una faccia del modello.
FORO = (LAVELLO[0] + 0.01, LAVELLO[2] - 0.01, LAVELLO[1] + 0.01, LAVELLO[3] - 0.01)
# Di quanto il bordo del lavello sta sopra la formica: un lavello da incasso ci
# appoggia sopra con il bordo, non ci affonda a filo.
BORDO_LAVELLO = 0.004
# IL MISCELATORE VA VERSO IL MURO. Il modello nasce con la vasca e il gocciolatoio in
# fila lungo il suo asse lungo e il rubinetto su un fianco: a 270 gradi il fianco
# del rubinetto guarda il muro, la vasca va a est e il gocciolatoio a ovest.
GRADI_LAVELLO = 270.0

# I piatti dello scolapiatti: ventiquattro centimetri, e in piedi pendono un poco,
# come un piatto che si appoggia a quello dopo.
DIAMETRO_PIATTO = 0.24
PENDENZA_PIATTO = 8.0


def maniglia(x0, x1, y, z):
    """Una barra orizzontale su un'anta: due gambetti e un tondino."""
    for x in (x0, x1):
        scatola("Metallo", x - 0.008, x + 0.008, y - 0.008, y + 0.008, z, z + 0.028)
    cilindro_orizz("Metallo", (x0 + x1) / 2, y, z + 0.028, "x", x1 - x0, 0.008)


def anta(x0, x1, y0, y1, z, verso=1):
    """Un'anta di mobile, con la sua maniglia sul bordo interno."""
    scatola("LegnoCucina", x0, x1, y0, y1, z, z + 0.018)
    xm = (x1 - 0.10) if verso > 0 else (x0 + 0.04)
    maniglia(min(xm, x1 - 0.04) - 0.06, min(xm, x1 - 0.04) + 0.02,
             (y0 + y1) / 2, z + 0.018)


def piano_forato(mat, x0, x1, y0, y1, z0, z1, foro):
    """Una lastra con un buco rettangolare: quattro pezzi invece di uno.

    IL LAVELLO ERA PIATTO PER QUESTO. La vasca c'era gia' - fondo e quattro
    pareti, sedici centimetri di incavo - ma sopra ci passavano due lastre intere
    e la tappavano. E' lo stesso errore del distributore: non era il vetro a non
    far vedere, era che dietro il vetro non c'era niente.
    """
    fx0, fx1, fz0, fz1 = foro
    for (a, b, c, d) in ((x0, fx0, z0, z1), (fx1, x1, z0, z1),
                         (fx0, fx1, z0, fz0), (fx0, fx1, fz1, z1)):
        if b - a > 0.001 and d - c > 0.001:
            scatola(mat, a, b, y0, y1, c, d)


def basi():
    """Il blocco cottura-lavello-basi: zoccolo, carcassa, piano e paraschizzi."""
    scatola("LegnoCucina", X_A + 0.04, X_B - 0.04, 0.0, 0.10, Z_MURO + 0.06, Z_FRONTE - 0.05)
    # ANCHE LA CARCASSA VA BUCATA, non solo le due lastre sopra. La vasca scende a
    # venti centimetri sotto il piano, cioe' DENTRO il mobile: bucare solo i piani
    # apre un foro che mostra il fianco di legno del mobile, che e' peggio di
    # prima - prima almeno sembrava un lavello chiuso.
    piano_forato("LegnoCucina", X_A, X_B, 0.10, H_TOP - 0.04, Z_MURO, Z_FRONTE, FORO)
    piano_forato("Formica", X_A, X_B, H_TOP - 0.04, H_TOP, Z_MURO, Z_FRONTE, FORO)
    # paraschizzi: la fascia di piastrelle fra piano e pensili, ed e' l'unico colore
    # della stanza. Sta appoggiata al muro, non lo sostituisce - E SI INTERROMPE
    # SOTTO LA FINESTRA, altrimenti le piastrelle attraversano il vetro.
    fx0, fx1 = FINESTRA[1], FINESTRA[3]
    scatola("Smalto", X_A, fx0, H_TOP, 1.45, Z_MURO, Z_MURO + 0.015)
    scatola("Smalto", fx1, X_B, H_TOP, 1.45, Z_MURO, Z_MURO + 0.015)
    scatola("Smalto", fx0, fx1, H_TOP, W_SILL, Z_MURO, Z_MURO + 0.015)

    # ante e cassetti, in ordine da ovest: base a due ante, lavello, cassettiera, forno
    for a, b in ((X_A + 0.02, X_A + 0.38), (X_A + 0.40, X_A + 0.76)):
        anta(a, b, 0.14, H_TOP - 0.08, Z_FRONTE)
    # SOTTO IL LAVELLO NON CI VANNO CASSETTI. Sotto un lavello c'e' il sifone, e
    # un cassetto non ci passa: nelle cucine vere quello e' un vano unico con le
    # ante, e dentro stanno i detersivi. Sono due e non una perche' il modulo e'
    # largo 88 cm - a un'anta sola servirebbe una cerniera che non esiste.
    for a, b in ((X_A + 0.80, X_A + 1.23), (X_A + 1.25, X_A + 1.68)):
        anta(a, b, 0.14, H_TOP - 0.08, Z_FRONTE, verso=-1 if a < X_A + 1.0 else 1)
    for k in range(2):
        y = 0.16 + k * 0.33
        scatola("LegnoCucina", X_A + 1.72, X_A + 2.28, y, y + 0.31, Z_FRONTE, Z_FRONTE + 0.018)
        maniglia(X_A + 1.88, X_A + 2.12, y + 0.155, Z_FRONTE + 0.018)
    # forno sotto il piano cottura: sportello a vetro e manigliona
    scatola("Inox", X_A + 2.32, X_B - 0.02, 0.14, 0.72, Z_FRONTE, Z_FRONTE + 0.02)
    scatola("Schermo", X_A + 2.40, X_B - 0.10, 0.26, 0.62, Z_FRONTE + 0.02, Z_FRONTE + 0.026)
    # la manigliona del forno sporge, ma non piu' di quanto l'impronta tolleri:
    # a sette centimetri il controllo l'ha bocciata, ed e' il suo mestiere
    cilindro_orizz("Metallo", (X_A + 2.32 + X_B) / 2, 0.66, Z_FRONTE + 0.045,
                   "x", X_B - X_A - 2.50, 0.011)
    # UNA SOLA FILA DI MANOPOLE. Il forno ne aveva quattro sue, dieci centimetri
    # sotto le quattro del piano: due file identiche a mezzo palmo di distanza, che
    # da vicino leggevano come un errore. Al forno restano termostato e timer.
    cilindro_orizz("Plastica", X_A + 2.48, 0.78, Z_FRONTE + 0.02, "z", 0.03, 0.021, 12)
    cilindro("Schermo", X_A + 2.66, Z_FRONTE + 0.021, 0.765, 0.795, 0.026, 12)
    # lo strofinaccio appeso alla manigliona
    scatola("Bianco", X_A + 2.62, X_A + 2.86, 0.40, 0.655, Z_FRONTE + 0.048, Z_FRONTE + 0.056)


def lavello():
    """Il lavello preso da fuori, dentro il foro del piano, col bordo sulla formica.

    E' UN BLOCCO DA INCASSO: vasca, gocciolatoio e miscelatore sono un pezzo solo, e
    sotto il bordo il modello scende dentro il mobile, dove nessuno lo vede. Prima
    era fatto a mano - quattro pareti d'acciaio, un fondo, la piletta e un rubinetto
    di cilindri - e da vicino erano scatole.

    SI SCALA SULLA PIANTA, e l'altezza passata a `posa_modello` e' un numero che non
    comanda mai. POI SI ALZA SUL BORDO, non sul fondo: `posa_modello` appoggia il
    punto piu' basso, che qui e' il fondo del blocco e non dice niente di dove stia
    il bordo. Il bordo si misura sul lato davanti, dove il rubinetto non c'e'.
    """
    x0, z0, x1, z1 = LAVELLO
    pezzi = posa_modello(LAVELLO_GLTF, (x0, z0, x1, z1, 10.0), gradi=GRADI_LAVELLO)
    mesh = [o for o in pezzi if o.type == "MESH"]
    davanti = [p.z for o in mesh for p in (o.matrix_world @ v.co for v in o.data.vertices)
               if -p.y > z1 - 0.015]
    pezzi[0].location.z += H_TOP + BORDO_LAVELLO - max(davanti)
    bpy.context.view_layer.update()
    # la mappa metallicRoughness, presa com'e', farebbe del lavello uno specchio: e
    # uno specchio in una cucina chiusa e' nero (vedi `usa_le_ridotte`)
    usa_le_ridotte(mesh, os.path.dirname(LAVELLO_GLTF), metallico=0.0)
    return pezzi


def piatto(x, base, z):
    """Un piatto in piedi nello scolapiatti, di taglio fra le due sponde.

    DEL MODELLO SI PRENDE LA FORMA. Arriva grigio a mezza luce, largo sessanta
    centimetri e senza mappe: accanto alla tazza e al piattino sarebbe l'unica
    ceramica grigia della casa. La ceramica e' quella della cucina.
    """
    prima = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=PIATTO_GLTF)
    nuovi = [o for o in bpy.data.objects if o not in prima]
    mesh = [o for o in nuovi if o.type == "MESH"]
    perno = bpy.data.objects.new("Piatto", None)
    bpy.context.collection.objects.link(perno)
    for o in nuovi:
        if o.parent is None:
            o.parent = perno
    for o in mesh:
        o.data.materials.clear()
        o.data.materials.append(materiale("Ceramica"))
    bpy.context.view_layer.update()

    def punti():
        return [o.matrix_world @ v.co for o in mesh for v in o.data.vertices]

    # nato disteso: si misura quanto e' largo, si scala e lo si mette in piedi
    largo = max(p.x for p in punti()) - min(p.x for p in punti())
    perno.scale = (DIAMETRO_PIATTO / largo,) * 3
    perno.rotation_euler = (0.0, math.radians(90.0 - PENDENZA_PIATTO), 0.0)
    bpy.context.view_layer.update()
    tutti = punti()
    perno.location = (x - (min(p.x for p in tutti) + max(p.x for p in tutti)) / 2,
                      -z - (min(p.y for p in tutti) + max(p.y for p in tutti)) / 2,
                      base - min(p.z for p in tutti))
    bpy.context.view_layer.update()
    return [perno] + nuovi


def cottura():
    """Quattro fuochi e le griglie. Niente manopole, e niente moka.

    LA MOKA DISEGNATA SUL FUOCO NON C'E' PIU' (D-244). Federico: «ci sono due moke,
    una e' sui fornelli, una e' a sinistra, ed e' quella che si deve acquistare».
    Quella sul fuoco era un rilievo del piano - si vedeva e non si toccava - e
    accanto alla moka vera diceva che il caffe' si fa da solo. La moka adesso e'
    una, `moka.tscn`, compare comprandola, e sul fuoco ce la si mette.

    LE MANOPOLE NON SI DISEGNANO PIU' QUI: si girano, e una cosa che si gira non
    puo' essere un pezzo della stanza. Le fa `world/interactables/fornello.gd`,
    con la stessa forma che avevano qui, nei punti di `geometria.MANOPOLE`.

    Dove stanno piano e fuochi lo dice `geometria.py`, perche' lo deve sapere anche
    il gioco: e' li' che una moka cuoce.
    """
    x0, z0, x1, z1 = COTTURA
    scatola("Inox", x0, x1, H_TOP - 0.005, H_TOP + 0.010, z0, z1)
    for fx, fz in FUOCHI:
        cilindro("Metallo", fx, fz, H_TOP + 0.010, H_TOP + 0.030, 0.055, 16, r2=0.045)
        cilindro("Schermo", fx, fz, H_TOP + 0.030, H_TOP + 0.042, 0.028, 12)
    # griglie: due telai rettangolari con le traverse
    for i in range(2):
        gx = x0 + 0.24 + i * 0.42
        for dz in (-0.13, 0.13):
            scatola("Metallo", gx - 0.18, gx + 0.18, H_TOP + 0.028, H_TOP + 0.040,
                    z0 + 0.13 + 0.11 + dz - 0.006, z0 + 0.13 + 0.11 + dz + 0.006)
        for dx in (-0.17, 0.0, 0.17):
            scatola("Metallo", gx + dx - 0.006, gx + dx + 0.006, H_TOP + 0.028, H_TOP + 0.040,
                    z0 + 0.02, z0 + 0.42)


def sul_piano():
    """Scolapiatti, bottiglia e radio: il piano vuoto era la cosa piu' finta della stanza."""
    # scolapiatti sul gocciolatoio, che e' la meta' a ovest del lavello (GRADI_LAVELLO),
    # con quattro piatti in piedi
    sx, sz = LAVELLO[0] + 0.215, (LAVELLO[1] + LAVELLO[3]) / 2
    base = H_TOP + BORDO_LAVELLO
    for a in (-0.16, 0.16):
        scatola("Metallo", sx + a - 0.008, sx + a + 0.008, base, base + 0.132,
                sz - 0.14, sz + 0.14)
    for dz in (-0.13, 0.13):
        cilindro_orizz("Metallo", sx, base + 0.127, sz + dz, "x", 0.34, 0.007)
    posati = []
    for k in range(4):
        posati += piatto(sx - 0.1225 + k * 0.075, base, sz)
    # LA BOTTIGLIA E LA RADIOLINA NON SI DISEGNANO PIU' QUI, e non sono sparite:
    # sono diventate OGGETTI. Erano due gruppi di primitive fusi in questa mesh,
    # cioe' due rilievi del piano di lavoro - si vedevano e non si potevano
    # toccare. Adesso la bottiglia e' `bottiglione.glb` e la radiolina
    # `radiolina.glb`, li posa `gen_blockout.py` come corpi che si prendono in
    # mano, e stanno negli stessi punti in cui stavano disegnate.
    #
    # La radiolina conserva le quote che aveva qui: ventidue centimetri di cassa,
    # l'altoparlante, la manopola e l'antenna. Vedi `tools/radiolina_blender.py`.
    return posati


def bacheca():
    """Il tabellone dei turni, sul muro sud. E' l'unico posto della cucina dove
    qualcuno ha scritto qualcosa, e regge tre fogli e un calendario."""
    x0, z0, x1, z1, _alt = IMPRONTE["Bacheca"]
    scatola("LegnoCucina", x0, x1, 1.12, 1.90, z1 - 0.035, z1)
    scatola("Rame", x0 + 0.03, x1 - 0.03, 1.15, 1.87, z1 - 0.038, z1 - 0.035)
    fogli = ((0.08, 1.30, 0.21, 0.28), (0.34, 1.42, 0.17, 0.24),
             (0.56, 1.24, 0.15, 0.21), (0.76, 1.50, 0.18, 0.30))
    for (dx, y, w, h) in fogli:
        scatola("Carta", x0 + dx, x0 + dx + w, y, y + h, z1 - 0.041, z1 - 0.038)
        scatola("Metallo", x0 + dx + w / 2 - 0.006, x0 + dx + w / 2 + 0.006,
                y + h - 0.02, y + h - 0.008, z1 - 0.045, z1 - 0.041)


def cappa():
    """La cappa sopra il piano cottura: tronco di piramide e canna fino al pensile."""
    x0, x1 = X_B - 0.92, X_B - 0.02
    z0, z1 = Z_MURO, Z_MURO + 0.48
    prisma("Inox",
           [(x0, 1.52, z0), (x1, 1.52, z0), (x1, 1.52, z1), (x0, 1.52, z1)],
           [(x0 + 0.31, 1.84, z0), (x1 - 0.31, 1.84, z0),
            (x1 - 0.31, 1.84, z0 + 0.20), (x0 + 0.31, 1.84, z0 + 0.20)])
    scatola("Inox", x0 + 0.31, x1 - 0.31, 1.84, 2.14, z0, z0 + 0.20)
    scatola("Schermo", x0 + 0.04, x1 - 0.04, 1.505, 1.52, z0 + 0.04, z1 - 0.04)


def pensili():
    """Una mensola a giorno sola, a ovest della finestra.

    Prima erano due, e coprivano tutto il muro fino alla cappa. Con la finestra
    sopra il lavello quel muro non c'e' piu': fra il vano e la cappa restano 38 cm,
    che non sono un pensile. Meglio una mensola sola e la finestra libera - che e'
    poi il motivo per cui la finestra e' stata aperta.
    """
    y0, y1 = 1.45, 2.10
    z0, z1 = Z_MURO, Z_MURO + 0.35
    xa, xb = X_A, FINESTRA[1] - 0.05
    for y in (y0, y0 + 0.32, y1 - 0.022):
        scatola("LegnoCucina", xa, xb, y, y + 0.022, z0, z1)
    for x in (xa, xb - 0.022):
        scatola("LegnoCucina", x, x + 0.022, y0, y1, z0, z1)
    for k in range(3):
        cilindro("Ceramica", xa + 0.14 + k * 0.20, z0 + 0.17, y0 + 0.022, y0 + 0.10, 0.042, 14)
        cilindro_orizz("Ceramica", xa + 0.185 + k * 0.20, y0 + 0.065, z0 + 0.17,
                       "z", 0.032, 0.007, 8)
    for k, r in enumerate((0.055, 0.045, 0.038)):
        cilindro("Rame", xa + 0.15 + k * 0.21, z0 + 0.18, y0 + 0.342,
                 y0 + 0.342 + 0.13 - k * 0.02, r, 14)


def frigo():
    x0, z0, x1, z1, alt = IMPRONTE["Frigo"]
    scatola("Bianco", x0, x1, 0.02, alt, z0, z1 - 0.02)
    scatola("Metallo", x0 + 0.04, x1 - 0.04, 0.0, 0.02, z0 + 0.04, z1 - 0.06)
    # due sportelli: il congelatore in alto
    scatola("Bianco", x0 + 0.01, x1 - 0.01, alt - 0.40, alt - 0.01, z1 - 0.02, z1)
    scatola("Bianco", x0 + 0.01, x1 - 0.01, 0.05, alt - 0.44, z1 - 0.02, z1)
    for y in (alt - 0.20, alt - 0.60):
        scatola("Plastica", x1 - 0.10, x1 - 0.03, y - 0.07, y + 0.07, z1, z1 + 0.032)
    # qualche foglio attaccato con le calamite: e' quello che dice che qualcuno ci vive
    scatola("Carta", x0 + 0.10, x0 + 0.28, alt - 0.75, alt - 0.50, z1 + 0.001, z1 + 0.004)
    scatola("Carta", x0 + 0.32, x0 + 0.44, alt - 0.70, alt - 0.56, z1 + 0.001, z1 + 0.004)


def dispensa():
    x0, z0, x1, z1, alt = IMPRONTE["Dispensa"]
    scatola("LegnoCucina", x0, x1, 0.10, alt, z0, z1 - 0.02)
    scatola("LegnoCucina", x0 + 0.04, x1 - 0.04, 0.0, 0.10, z0 + 0.06, z1 - 0.06)
    for a, b, verso in ((x0 + 0.02, (x0 + x1) / 2 - 0.01, -1), ((x0 + x1) / 2 + 0.01, x1 - 0.02, 1)):
        anta(a, b, 0.14, alt - 0.04, z1 - 0.02, verso)
    # scatoloni sopra, che e' dove finiscono in ogni cucina di servizio
    scatola("Carta", x0 + 0.08, x0 + 0.46, alt, alt + 0.24, z0 + 0.08, z1 - 0.14)
    scatola("Carta", x0 + 0.50, x1 - 0.06, alt, alt + 0.16, z0 + 0.12, z1 - 0.10)


def tavolo_e_sedie():
    x0, z0, x1, z1, alt = IMPRONTE["Tavolo"]
    scatola("LegnoCucina", x0, x1, alt - 0.035, alt, z0, z1)
    scatola("LegnoCucina", x0 + 0.06, x1 - 0.06, alt - 0.10, alt - 0.035, z0 + 0.06, z1 - 0.06)
    for gx in (x0 + 0.06, x1 - 0.10):
        for gz in (z0 + 0.06, z1 - 0.10):
            scatola("Metallo", gx, gx + 0.04, 0.0, alt - 0.10, gz, gz + 0.04)
    # sopra: un blocco di fogli. LA TAZZA NON E' PIU' DISEGNATA QUI - era tre
    # cilindri di ceramica fusi nel tavolo, e adesso e' `tazza.glb` col suo
    # piattino, posata da `gen_blockout.py` nello stesso punto. I fogli restano:
    # un foglio non si prende in mano, si legge, ed e' un'altra meccanica.
    scatola("Carta", x1 - 0.52, x1 - 0.16, alt, alt + 0.014, z0 + 0.18, z1 - 0.14)

    # le sedie ai capi del tavolo si guardano: quella a ovest verso est, e viceversa
    posate = []
    for nome, gradi in (("SediaC1", -90.0), ("SediaC2", 90.0)):
        posate += posa_modello(SEDIA, IMPRONTE[nome], gradi=gradi)
    return posate


def pattumiera():
    x0, z0, x1, z1, alt = IMPRONTE["Pattumiera"]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    r = min(x1 - x0, z1 - z0) / 2 - 0.01
    cilindro("Plastica", cx, cz, 0.02, alt - 0.05, r * 0.86, 20, r2=r)
    cilindro("Plastica", cx, cz, alt - 0.05, alt - 0.015, r, 20, r2=r * 0.92)
    cilindro("Metallo", cx, cz, 0.0, 0.02, r * 0.80, 16)
    scatola("Metallo", x0 + 0.04, x1 - 0.04, 0.03, 0.055, z1 - 0.02, z1 + 0.05)


# --- costruzione -------------------------------------------------------------
pulisci()
basi()
_lavello = lavello()
cottura()
_piatti = sul_piano()
bacheca()
cappa()
pensili()
frigo()
dispensa()
_sedie = tavolo_e_sedie()
pattumiera()

oggetti = finisci(morbidi=("Inox", "Ceramica", "Rame", "Metallo", "Plastica"))
print()
for o in oggetti:
    print("  %-10s %5d facce" % (o.name, len(o.data.polygons)))

# --- controlli ---------------------------------------------------------------
problemi = list(verifica_arredi())
# DENTRO IL LAVELLO NON CI DEVE STARE NIENTE DI NOSTRO. E' il controllo che manca
# ogni volta: la vasca c'era gia', erano i pezzi che le passavano sopra e attorno
# a nasconderla, e nessuno se ne accorgeva perche' guardavano tutti la vasca. Adesso
# la vasca e' il modello di fuori, e i pezzi fatti qui devono restarne fuori uguale.
_fx0, _fx1, _fz0, _fz1 = FORO
_intrusi = set()
for _o in oggetti:
    if _o.name == "Inox":
        continue
    for _v in _o.data.vertices:
        _p = _o.matrix_world @ _v.co
        if (_fx0 + 0.02 < _p.x < _fx1 - 0.02 and _fz0 + 0.02 < -_p.y < _fz1 - 0.02
                # dal fondo si lasciano fuori quattro centimetri: li' ci stanno la
                # piletta e la sua crociera, che sono nere ed e' giusto che lo siano
                and H_TOP - 0.16 < _p.z < H_TOP - 0.01):
            _intrusi.add(_o.name)
for _n in sorted(_intrusi):
    problemi.append("dentro la vasca del lavello c'e' del materiale %s" % _n)
problemi += verifica_luce(oggetti, [FINESTRA])
# anche i modelli presi da fuori devono stare nella loro impronta: e' il patto
problemi += verifica_impronte(
    oggetti + _sedie + _lavello + _piatti,
    [(x0, z0, x1, z1) for (x0, z0, x1, z1, _h) in IMPRONTE.values()])

# niente deve superare l'altezza della stanza: la dispensa e i suoi scatoloni ci
# vanno vicino, e un mobile dentro il solaio non si vede finche' non ci si passa sotto
ALTEZZA_STANZA = 3.00
_alto = max((o.matrix_world @ v.co).z for o in oggetti for v in o.data.vertices)
print("\n  il pezzo piu' alto arriva a %.2f m, il soffitto sta a %.2f" % (_alto, ALTEZZA_STANZA))
if _alto > ALTEZZA_STANZA:
    problemi.append("un arredo sfonda il soffitto: %.2f m" % _alto)

if problemi:
    print("\nATTENZIONE:")
    for p in problemi:
        print("  " + p)
    sys.exit(1)

esporta(USCITA)

# --- render di controllo -----------------------------------------------------
scatta_su = prepara_render()
_osservatorio = os.path.join(RADICE, "assets", "models", "osservatorio.glb")
if os.path.exists(_osservatorio):
    # l'edificio entra SOLO ORA, dopo l'export: serve al render e non al modello
    bpy.ops.import_scene.gltf(filepath=_osservatorio)
lampada("Plafoniera", (10.80, 2.60, 2.60), 140.0, tipo="AREA", dimensione=1.4)
lampada("SottoPensile", (8.70, 1.40, 1.90), 10.0)


def scatta(nome, posizione, mira, lente=28.0):
    scatta_su(os.path.join(RENDER, nome), posizione, mira, lente)


# entrando dalla porta: e' la prima cosa che si vede. La camera sta a 9,90 e non a
# 9,60 perche' li' finiva col naso nel rubinetto, che e' esattamente al centro del vano
scatta("cucina.png", (9.90, 1.62, 3.85), (11.40, 1.05, 2.00), lente=20.0)
# e dall'angolo del tavolo verso ovest: tutta la linea in un colpo
scatta("cucina-linea.png", (12.70, 1.62, 3.20), (8.80, 1.05, 2.00), lente=22.0)
# il lavello e i fuochi, da vicino
scatta("cucina-fuochi.png", (10.05, 1.45, 3.00), (10.95, 1.02, 1.95), lente=34.0)
# l'angolo del tavolo, verso est
scatta("cucina-tavolo.png", (9.90, 1.60, 3.00), (12.60, 0.90, 3.70), lente=26.0)
# il lavello dall'alto: dentro la vasca ci si deve vedere
scatta("cucina-lavello.png", (9.90, 1.62, 3.35), (9.75, 0.80, 2.10), lente=30.0)
