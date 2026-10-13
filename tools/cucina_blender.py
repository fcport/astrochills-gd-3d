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
from geometria import (ARREDI_CUCINA, CAPPELLI, COTTURA, FORNO, FUOCHI, H,   # noqa: E402
                       H_GRIGLIA, MANOPOLE, verifica_arredi, W_SILL)
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
# E IL FRIGORIFERO, anche lui scelto da Federico su Sketchfab (CC-BY, CREDITI.md):
# vecchio, con la vernice consumata. Arriva senza gli adesivi che l'autore ci aveva
# dipinto sopra - li toglie `prendi_modello.py` spacchettandolo.
FRIGO_GLTF = os.path.join(RADICE, "assets", "models", "esterni", "frigo", "scene.gltf")
# La cappa piatta, che nel suo file sta sopra una cucina elettrica, e il contatore del
# gas, che sta in un set di elettrodomestici: di tutti e due si tiene un pezzo solo.
CAPPA_GLTF = os.path.join(RADICE, "assets", "models", "esterni", "cappa", "scene.gltf")
GAS_GLTF = os.path.join(RADICE, "assets", "models", "esterni", "contatore_gas", "scene.gltf")

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

    # ante e cassetti, in ordine da ovest: base a due ante, lavello, cassettiera, forno,
    # anta da trenta
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
    # IL FORNO SOTTO IL PIANO COTTURA, da sessanta come il piano (D-285): prima era largo
    # novanta, sotto un piano da ottantasei inventato. Sportello a vetro, manigliona e
    # il pannello dei comandi in alto, satinato come il piano che gli sta sopra.
    f0, f1 = FORNO
    scatola("InoxSatinato", f0, f1, 0.14, 0.83, Z_FRONTE, Z_FRONTE + 0.02)
    scatola("Schermo", f0 + 0.08, f1 - 0.08, 0.26, 0.62, Z_FRONTE + 0.02, Z_FRONTE + 0.026)
    # la manigliona del forno sporge, ma non piu' di quanto l'impronta tolleri:
    # a sette centimetri il controllo l'ha bocciata, ed e' il suo mestiere
    cilindro_orizz("Metallo", (f0 + f1) / 2, 0.68, Z_FRONTE + 0.045, "x", f1 - f0 - 0.18, 0.011)
    # AL FORNO LE SUE DUE, termostato e timer. Le quattro del piano stanno sul piano,
    # sulla sua striscia a destra: le posa il gioco (`fornello.gd`).
    cilindro_orizz("Plastica", f0 + 0.10, 0.775, Z_FRONTE + 0.02, "z", 0.03, 0.021, 12)
    cilindro_orizz("Schermo", f1 - 0.10, 0.775, Z_FRONTE + 0.02, "z", 0.03, 0.021, 12)
    # lo strofinaccio appeso alla manigliona
    scatola("Bianco", f0 + 0.30, f0 + 0.54, 0.40, 0.675, Z_FRONTE + 0.048, Z_FRONTE + 0.056)
    # FRA IL FORNO E IL FRIGO un'anta da trenta: il fuoco non sta attaccato al fianco del
    # frigorifero, e trenta centimetri sono il modulo stretto delle cucine vere
    anta(f1 + 0.02, X_B - 0.02, 0.14, H_TOP - 0.08, Z_FRONTE)


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
    """Il piano cottura: uno Smeg S64S, fuochi e griglie. Niente manopole, e niente moka.

    E' UNO S64S (D-285) perche' Federico ha bocciato il piano di prima - «i fornelli
    sono molto brutti» - e poi tutti i modelli scaricabili - «nessuna di queste e'
    molto italiana». Lo S64S e' il piano inox da 60 cm che sta nelle cucine italiane
    da decenni: le quote vengono dalla scheda del costruttore (585 x 500, griglie alte
    48,5 mm sul piano di lavoro), la disposizione dalla sua foto dall'alto, e stanno in
    `geometria.py` perche' il gioco le deve sapere.

    COM'E' FATTO, dalla foto. Il piano satinato con la striscia rialzata dei comandi a
    destra; attorno a ogni fuoco la coppetta stampata nella lamiera; i bruciatori Sabaf
    nei tre formati - spartifiamma d'alluminio e cappellotto smaltato nero - e due
    griglie di piattina nera, una per colonna, con le traverse che si incrociano sopra
    i fuochi.

    LA MOKA DISEGNATA SUL FUOCO NON C'E' PIU' (D-244): la moka e' una, `moka.tscn`,
    compare comprandola, e sul fuoco ce la si mette.

    LE MANOPOLE NON SI DISEGNANO QUI: si girano, e una cosa che si gira non puo'
    essere un pezzo della stanza. Le fa `world/interactables/fornello.gd`, nei punti
    di `geometria.MANOPOLE`; qui si disegnano solo le tacche serigrafate accanto.
    """
    x0, z0, x1, z1 = COTTURA
    piano = H_TOP + 0.006
    # la lamiera: appoggiata sul top, sei millimetri di bordo
    scatola("InoxSatinato", x0, x1, H_TOP - 0.002, piano, z0, z1)
    # la striscia dei comandi, rialzata di tre millimetri, da 488 a 578 mm
    scatola("InoxSatinato", x0 + 0.488, x0 + 0.578, piano, piano + 0.003, z0 + 0.014, z1 - 0.012)
    # le tacche della serigrafia, a sinistra di ogni manopola
    for (mx, my, mz) in MANOPOLE:
        scatola("SmaltoNero", mx - 0.036, mx - 0.030, my, my + 0.0006, mz - 0.002, mz + 0.002)
    for (fx, fz), cappello in zip(FUOCHI, CAPPELLI):
        r = cappello / 2.0
        # la coppetta stampata attorno al fuoco: un gradino di un millimetro e mezzo
        cilindro("InoxSatinato", fx, fz, piano, piano + 0.0015, r * 1.9, 32)
        # la tazza del bruciatore, poi lo spartifiamma fino a 21 mm dal piano di
        # lavoro, e sopra il cappellotto nero, con la cima appena bombata
        cilindro("Alluminio", fx, fz, piano, piano + 0.004, r + 0.012, 24)
        cilindro("Alluminio", fx, fz, piano + 0.004, H_TOP + 0.024, r + 0.005, 24)
        cilindro("SmaltoNero", fx, fz, H_TOP + 0.024, H_TOP + 0.030, r, 24, r2=r * 0.92)
    # LE GRIGLIE: due, una per colonna di fuochi, di piattina da 5 x 9 mm. Il telaio e,
    # dentro, una traversa lungo la colonna e tre attraverso: due passano sopra i fuochi
    # e una a meta'. Stanno su quattro piedi, agli angoli.
    alto, basso, mezza = H_GRIGLIA, H_GRIGLIA - 0.009, 0.0025
    for g0, g1, gx in ((x0 + 0.018, x0 + 0.244, FUOCHI[0][0]),
                       (x0 + 0.250, x0 + 0.476, FUOCHI[2][0])):
        a, b = z0 + 0.020, z1 - 0.021
        for zz in (a, b, FUOCHI[0][1], (a + b) / 2, FUOCHI[1][1]):
            scatola("SmaltoNero", g0, g1, basso, alto, zz - mezza, zz + mezza)
        for xx in (g0, g1, gx):
            scatola("SmaltoNero", xx - mezza, xx + mezza, basso, alto, a, b)
        for xx in (g0, g1):
            for zz in (a, b):
                scatola("SmaltoNero", xx - mezza, xx + mezza, piano, basso, zz - mezza, zz + mezza)


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


def _sopra(quota):
    """Un `ritaglia` per `posa_modello`: butta tutto quello che sta sotto `quota`,
    nelle misure del modello come arriva."""
    def ritaglia(nuovi):
        bpy.context.view_layer.update()
        for o in [o for o in nuovi if o.type == "MESH"]:
            bm = bmesh.new()
            bm.from_mesh(o.data)
            mw = o.matrix_world
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if (mw @ v.co).z < quota],
                             context="VERTS")
            vuota = not bm.verts
            bm.to_mesh(o.data)
            bm.free()
            if vuota:
                nuovi.remove(o)
                bpy.data.objects.remove(o, do_unlink=True)
        return nuovi
    return ritaglia


def cappa():
    """La cappa sopra i fuochi: piatta, di quelle che si appendono al muro.

    Nel modello sta sopra una cucina elettrica americana, e fra le due c'e' un
    vuoto netto: niente fra 1,1 e 1,48 m. Si taglia a 1,30 e resta solo la cappa,
    con le due levette di luce e ventola. Sta a ottanta centimetri dal piano,
    centrata sui fuochi. Era a settanta, il minimo sopra un fuoco a gas: in gioco
    Federico l'ha voluta piu' alta, e dieci centimetri in piu' la tolgono dalla
    linea degli occhi di chi sta davanti ai fuochi.
    """
    cx = (COTTURA[0] + COTTURA[2]) / 2
    pezzi = posa_modello(CAPPA_GLTF, (cx - 0.40, Z_MURO, cx + 0.40, Z_MURO + 0.534, 0.184),
                         gradi=90.0, appoggio=H_TOP + 0.80, ritaglia=_sopra(1.30))
    mesh = [o for o in pezzi if o.type == "MESH"]
    # smalto, non acciaio: col metallico della mappa in una cucina chiusa verrebbe nera
    usa_le_ridotte(mesh, os.path.dirname(CAPPA_GLTF), metallico=0.0)
    return pezzi


def _solo(genitore):
    """Un `ritaglia` che tiene le mesh figlie di `genitore` e butta il resto."""
    def ritaglia(nuovi):
        for o in [o for o in nuovi if o.type == "MESH"]:
            if o.parent is None or o.parent.name != genitore:
                nuovi.remove(o)
                bpy.data.objects.remove(o, do_unlink=True)
        return nuovi
    return ritaglia


def contatore():
    """Il contatore del gas sul muro est, col montante da terra al soffitto.

    Nel modello il montante e' alto 3,52 m, cioe' 2,40 alla scala a cui il
    contatore viene giusto: finirebbe a sessanta centimetri dal soffitto, un tubo
    del gas che si ferma nel vuoto. Allora lo si ALLUNGA - si alzano i vertici
    sopra i 2,10, dove c'e' solo il montante - e lo si taglia al soffitto, cosi'
    entra nel solaio come uno vero. La discesa verso la cucina entra nel
    pavimento, e va bene: il tubo corre sotto.
    """
    pezzi = posa_modello(GAS_GLTF, IMPRONTE["Contatore"], gradi=90.0,
                         ritaglia=_solo("Pipes_Kitchen_A_6"))
    mesh = [o for o in pezzi if o.type == "MESH"]
    bpy.context.view_layer.update()
    cima = max((o.matrix_world @ v.co).z for o in mesh for v in o.data.vertices)
    alza = H + 0.05 - cima
    for o in mesh:
        mw = o.matrix_world
        inv = mw.inverted()
        bm = bmesh.new()
        bm.from_mesh(o.data)
        for v in bm.verts:
            w = mw @ v.co
            if w.z > 2.10:
                w.z += alza
                v.co = inv @ w
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:],
                               plane_co=inv @ Vector((0.0, 0.0, H)),
                               plane_no=(inv.to_3x3() @ Vector((0.0, 0.0, 1.0))).normalized(),
                               clear_outer=True)
        bm.to_mesh(o.data)
        bm.free()
    # vernice grigia, non ferro nudo: stesso discorso della cappa
    usa_le_ridotte(mesh, os.path.dirname(GAS_GLTF), metallico=0.0)
    return pezzi


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
    """Il frigorifero preso da fuori, in piedi nella sua impronta, con lo sportello
    verso la stanza.

    Prima era di scatole: un parallelepipedo bianco con due sportelli e due fogli
    attaccati. I fogli non ci sono piu' - Federico ha voluto il frigo senza niente
    attaccato sopra, e un foglio di carta con la calamita e' la stessa cosa di un
    adesivo.
    """
    pezzi = posa_modello(FRIGO_GLTF, IMPRONTE["Frigo"])
    mesh = [o for o in pezzi if o.type == "MESH"]
    # la vernice di un frigorifero non e' uno specchio, e il metallico preso dalla
    # mappa in una cucina chiusa lo farebbe nero (vedi `usa_le_ridotte`)
    usa_le_ridotte(mesh, os.path.dirname(FRIGO_GLTF), metallico=0.0)
    return pezzi


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
_cappa = cappa()
pensili()
_frigo = frigo()
_contatore = contatore()
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
    oggetti + _sedie + _lavello + _piatti + _frigo + _cappa + _contatore,
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
