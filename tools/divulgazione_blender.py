# -*- coding: utf-8 -*-
"""Lo spazio divulgazione: i libri davanti, le teche dietro.

    "D:/programs/blender5/blender.exe" --background --python tools/divulgazione_blender.py

Stesso patto delle altre stanze: `geometria.ARREDI_DIVULGAZIONE` dichiara i
rettangoli in pianta, qui dentro ci si costruisce, e i controlli contano quello
che ne esce.

LA STANZA E' GRANDE E QUASI VUOTA, ed e' giusto cosi': sono 65 m2 di sala aperta
al pubblico in un osservatorio dove il pubblico non viene. Il vuoto e' il
contenuto. Quello che c'e' sta contro i muri - la libreria sul muro della cucina,
le teche in fondo e sul lato est - e in mezzo restano due file di sedie
apparecchiate per una serata a cui non e' venuto nessuno.

Produce assets/models/divulgazione.glb.
"""
import math
import os
import random
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
from geometria import ARREDI_DIVULGAZIONE, verifica_arredi, W_SILL   # noqa: E402
from modellare import (barra, cilindro, cilindro_orizz, esporta, faldone,   # noqa: E402
                       finisci, lampada, prepara_render, pulisci, sasso, scatola,
                       posa_modello, scatola_inclinata, verifica_impronte,
                       verifica_luce)

RADICE = os.path.dirname(QUI)
PROIETTORE = os.path.join(RADICE, "assets", "models", "esterni",
                          "filmstrip_projector_8mm", "filmstrip_projector_8mm_1k.gltf")
USCITA = os.path.join(RADICE, "assets", "models", "divulgazione.glb")
RENDER = os.path.join(RADICE, "_bmad-output", "planning-artifacts", "gdds",
                      "gdd-astrochills-gd-3d-2026-08-24")

IMPRONTE = {n: (x0, z0, x1, z1, h) for (n, x0, z0, x1, z1, h) in ARREDI_DIVULGAZIONE}

# La sedia viene da fuori: la nostra era quattro scatole e un tubo, e in due file
# da quattro si vedeva. Poly Haven, CC0. Vedi tools/prendi_modello.py.
SEDIA_SALA = os.path.join(RADICE, "assets", "models", "esterni",
                          "SchoolChair_01", "SchoolChair_01_1k.gltf")

# Le due finestre della sala, per il controllo dell'occlusione.
FINESTRE = [
    ("divulgazione sud", 14.50, 8.90, 16.50, 9.40, W_SILL, "x"),
    ("divulgazione est", 18.40, 3.80, 19.00, 5.80, W_SILL, "z"),
]

# I dorsi dei libri e le stoffe delle teche pescano da qui. Il seme e' fisso: due
# esecuzioni dello stesso script devono dare lo stesso file.
# I DORSI NON SONO DI LEGNO. Nella prima versione la tavolozza dei libri conteneva
# il materiale del mobile, e sugli scaffali finivano dorsi di legno venato.
DORSI = ("LibroRosso", "LibroBlu", "LibroVerde", "LibroCrema",
         "Tessuto", "Carta", "Smalto", "Meteorite")


def libreria():
    """La libreria di astronomia del GDD: sul muro della cucina, dalla parte della sala.

    I RIPIANI NON SONO VUOTI. Una libreria senza libri e' uno scaffale, e questa e'
    l'unica cosa che dice che in questo edificio qualcuno legge. I dorsi hanno
    larghezze, altezze e colori diversi, e qualcuno e' inclinato: una fila di
    parallelepipedi identici si legge come un motivo, non come dei libri.
    """
    x0, z0, x1, z1, alt = IMPRONTE["Libreria"]
    rnd = random.Random(4207)
    scatola("LegnoTeche", x0 + 0.04, x1 - 0.04, 0.0, 0.06, z0 + 0.03, z1 - 0.02)
    scatola("LegnoTeche", x0, x1, 0.06, alt, z0, z0 + 0.018)              # schienale
    for x in (x0, (2 * x0 + x1) / 3 - 0.015, (x0 + 2 * x1) / 3 - 0.015, x1 - 0.03):
        scatola("LegnoTeche", x, x + 0.03, 0.06, alt, z0, z1)             # fianchi e montanti
    quote = [0.06] + [0.38 + k * 0.335 for k in range(5)] + [alt - 0.03]
    for y in quote:
        scatola("LegnoTeche", x0, x1, y, y + 0.025, z0, z1)               # ripiani
    campate = ((x0 + 0.03, (2 * x0 + x1) / 3 - 0.015),
               ((2 * x0 + x1) / 3 + 0.015, (x0 + 2 * x1) / 3 - 0.015),
               ((x0 + 2 * x1) / 3 + 0.015, x1 - 0.03))
    for i, (a, b) in enumerate(campate):
        for k in range(len(quote) - 1):
            y = quote[k] + 0.025
            luce = quote[k + 1] - y
            x = a + 0.015
            # si riempie fino a dove entra, e si lascia un vuoto a caso: uno scaffale
            # pieno preciso fino al bordo e' l'unica cosa che non succede mai
            fine = b - 0.015 - rnd.uniform(0.0, 0.28)
            while x < fine:
                sp = rnd.uniform(0.018, 0.052)
                if x + sp > fine:
                    break
                h = min(luce - 0.02, rnd.uniform(0.17, 0.29))
                mat = DORSI[rnd.randrange(len(DORSI))]
                if rnd.random() < 0.08 and x + sp + 0.09 < fine:
                    # ogni tanto uno inclinato contro i vicini
                    scatola_inclinata(mat, x + sp / 2 + 0.03, y + h / 2, (z0 + z1) / 2 + 0.02,
                                      sp, h, z1 - z0 - 0.10, 14.0)
                else:
                    scatola(mat, x, x + sp, y, y + h, z0 + 0.05, z1 - 0.03)
                x += sp + 0.002
            # qualche volume coricato sopra la fila
            if rnd.random() < 0.45:
                pila = rnd.randrange(2, 4)
                for j in range(pila):
                    scatola(DORSI[rnd.randrange(len(DORSI))], a + 0.04, a + 0.04 + rnd.uniform(0.19, 0.24),
                            y + 0.30 + j * 0.035, y + 0.332 + j * 0.035,
                            z0 + 0.06 + j * 0.006, z1 - 0.05 + j * 0.006)


def reperti(mappa, cartellino, l0, l1, d0, d1, y, seme, quanti):
    """I pezzi dentro una teca, allineati LUNGO la teca, con i cartellini sul fronte.

    L'ALLINEAMENTO NON E' UN DETTAGLIO. Prima i reperti si spargevano sempre lungo
    l'asse X, qualunque fosse l'orientamento della teca: nelle due vetrine del muro
    est — lunghe 1,90 in Z e profonde 0,60 in X — finivano incolonnati nella
    PROFONDITA', uno dietro l'altro, invece di stare in fila lungo il vetro. Da
    fuori si vedeva un grumo di sassi in mezzo a un ripiano vuoto.

    `mappa(l, d)` traduce «lungo la teca / dal fronte al fondo» in (x, z) di gioco, e
    `cartellino(l, y)` posa un cartellino sul fronte: cosi' questa funzione non sa ne'
    vuole sapere come e' girata la vetrina.
    """
    rnd = random.Random(seme)
    passo = (l1 - l0) / quanti
    for k in range(quanti):
        cl = l0 + passo * (k + 0.5)
        cd = (d0 + d1) / 2 + rnd.uniform(-0.03, 0.03)
        cx, cz = mappa(cl, cd)
        r = rnd.uniform(0.035, 0.075)
        mat = "Ferro" if rnd.random() < 0.3 else "Meteorite"
        cilindro("Gomma", cx, cz, y, y + 0.012, r * 0.55, 12)
        sasso(mat, cx, y + 0.012 + r * 0.55, cz, r, seme + k)
        cartellino(cl, y)


def teca_a_muro(nome, seme, asse="x"):
    """Vetrina alta addossata a un muro: basamento pieno, cassa di vetro, cornice.

    `asse` e' la direzione LUNGA della teca. Il muro sta sul lato di coordinata
    maggiore dell'altra direzione, e il fronte guarda verso quella minore: dentro,
    tutto si descrive in «lungo / profondo» e la funzione `pz` lo riporta agli assi
    di gioco. Senza questo, una vetrina girata di novanta gradi ha il vetro frontale
    su un fianco e il pannello dei testi davanti al pubblico invece che dietro.
    """
    x0, z0, x1, z1, alt = IMPRONTE[nome]
    L0, L1 = (x0, x1) if asse == "x" else (z0, z1)
    D0, D1 = (z0, z1) if asse == "x" else (x0, x1)      # D0 = fronte, D1 = muro

    def pz(mat, l_0, l_1, y_0, y_1, d_0, d_1):
        if asse == "x":
            scatola(mat, l_0, l_1, y_0, y_1, d_0, d_1)
        else:
            scatola(mat, d_0, d_1, y_0, y_1, l_0, l_1)

    def mappa(l, d):
        return (l, d) if asse == "x" else (d, l)

    def cartellino(l, y):
        """Coricato all'indietro sul fronte del ripiano, e LARGO LUNGO LA VETRINA.

        La larghezza deve stare sull'asse attorno a cui il cartellino si corica, o
        succedono insieme le due cose che si sono viste: girato di novanta gradi lo
        si guarda **di taglio** stando davanti alla teca, e la sua dimensione lunga
        - otto centimetri e mezzo - si inclina verso il basso e **entra nel ripiano**.
        Non bastava mappare la posizione: vanno mappate anche le misure.
        """
        ex, ez = mappa(l, D0 + 0.135)
        if asse == "x":
            scatola_inclinata("Carta", ex, y + 0.012, ez, 0.085, 0.052, 0.003, 70.0, asse="x")
        else:
            scatola_inclinata("Carta", ex, y + 0.012, ez, 0.003, 0.052, 0.085, 70.0, asse="z")

    y_base, y_cima = 0.85, alt - 0.10
    pz("LegnoTeche", L0 + 0.03, L1 - 0.03, 0.0, 0.08, D0 + 0.03, D1 - 0.03)
    pz("LegnoTeche", L0, L1, 0.08, y_base, D0, D1)
    pz("LegnoTeche", L0 - 0.015, L1 + 0.015, y_base, y_base + 0.03, D0 - 0.015, D1 + 0.015)
    pz("LegnoTeche", L0 - 0.02, L1 + 0.02, y_cima, alt, D0 - 0.02, D1 + 0.02)
    for a in (L0, L1 - 0.022):
        for b in (D0, D1 - 0.022):
            pz("Metallo", a, a + 0.022, y_base + 0.03, y_cima, b, b + 0.022)
    pz("Vetrina", L0 + 0.01, L1 - 0.01, y_base + 0.03, y_cima, D0 + 0.004, D0 + 0.012)
    for a, b in ((L0 + 0.004, L0 + 0.012), (L1 - 0.012, L1 - 0.004)):
        pz("Vetrina", a, b, y_base + 0.03, y_cima, D0 + 0.01, D1 - 0.01)
    pz("Vetrina", L0 + 0.01, L1 - 0.01, y_cima - 0.012, y_cima - 0.004, D0 + 0.01, D1 - 0.01)
    for k, y in enumerate((y_base + 0.06, y_base + 0.44)):
        pz("LegnoTeche", L0 + 0.03, L1 - 0.03, y - 0.018, y, D0 + 0.05, D1 - 0.05)
        quanti = max(3, int((L1 - L0) / 0.38))
        reperti(mappa, cartellino, L0 + 0.10, L1 - 0.10, D0 + 0.14, D1 - 0.06, y,
                seme + k * 17, quanti)
    # il pannello con i testi sta sul FONDO, dentro: dietro i pezzi, non davanti
    pz("Carta", L0 + 0.08, L1 - 0.08, y_cima - 0.30, y_cima - 0.06, D1 - 0.036, D1 - 0.030)


def fila_di_sedie(nome, seme):
    """Una fila di sedie impilabili, rivolte allo schermo.

    UNA E' STORTA. Una fila perfetta sembra un render; una fila con una sedia
    girata di sette gradi sembra una fila che qualcuno ha messo a mano.
    """
    x0, z0, x1, z1, alt = IMPRONTE[nome]
    rnd = random.Random(seme)
    quante = int((x1 - x0) / 0.50)
    passo = (x1 - x0) / quante
    posate = []
    for k in range(quante):
        a = x0 + passo * k
        storta = rnd.uniform(-7.0, 7.0) if rnd.random() < 0.3 else 0.0
        posate += posa_modello(SEDIA_SALA, (a + 0.02, z0, a + passo - 0.02, z1, alt),
                               gradi=180.0 + storta)
    return posate


def schermo():
    """Telo avvolgibile sul muro nord: cassonetto, telo srotolato e barra di zavorra.

    IL MURO NORD E' L'UNICO SENZA APERTURE per tutto il tratto est. Le altre tre
    pareti della sala proiezioni hanno una finestra o danno sul resto della sala, e
    uno schermo davanti a una finestra e' un modo di non poter proiettare mai.
    """
    x0, z0, x1, z1, alt = IMPRONTE["Schermo"]
    scatola("Metallo", x0 - 0.03, x1 + 0.03, alt - 0.12, alt, z0, z1)   # cassonetto
    for x in (x0 - 0.02, x1 - 0.02):
        scatola("Metallo", x, x + 0.04, alt - 0.10, alt - 0.02, z0 + 0.01, z1 - 0.01)
    scatola("Bianco", x0, x1, 0.95, alt - 0.12, z0 + 0.05, z0 + 0.058)  # il telo
    scatola("Metallo", x0 - 0.02, x1 + 0.02, 0.92, 0.95, z0 + 0.045, z0 + 0.065)
    cilindro_orizz("Gomma", x1 + 0.02, 1.55, z0 + 0.055, "x", 0.03, 0.008, 8)


def tavolo_sala():
    """Il tavolo davanti alle sedie: e' cosi' che sta l'osservatorio vero.

    Non e' arredo di riempimento. Due file di sedie davanti a un muro sono sedie;
    due file davanti a un tavolo sono una sala dove qualcuno parla. Sopra ci resta
    quello che si lascia su un tavolo del genere: fogli, un paio di volumi, un
    campione da far girare fra le mani e un bicchiere.
    """
    x0, z0, x1, z1, alt = IMPRONTE["TavoloSala"]
    scatola("LegnoTeche", x0, x1, alt - 0.035, alt, z0, z1)
    scatola("LegnoTeche", x0 + 0.08, x1 - 0.08, alt - 0.30, alt - 0.035, z0 + 0.04, z0 + 0.09)
    for gx in (x0 + 0.07, x1 - 0.12):
        for gz in (z0 + 0.06, z1 - 0.11):
            scatola("Metallo", gx, gx + 0.05, 0.0, alt - 0.035, gz, gz + 0.05)
    # fogli sparsi e una pila di volumi
    rnd = random.Random(913)
    for k in range(6):
        scatola_inclinata("Carta", x0 + 0.45 + rnd.uniform(0, 0.55), alt + 0.002 + k * 0.002,
                          (z0 + z1) / 2 + rnd.uniform(-0.10, 0.10),
                          0.21, 0.001, 0.297, rnd.uniform(-14, 14), asse="z")
    for k in range(3):
        scatola(("Smalto", "Rame", "Tessuto")[k], x1 - 0.52, x1 - 0.30,
                alt + k * 0.038, alt + 0.034 + k * 0.038,
                z0 + 0.16 + k * 0.012, z1 - 0.20 + k * 0.012)
    # un campione fuori dalla teca, per farlo toccare
    cilindro("Gomma", x0 + 0.26, z0 + 0.34, alt, alt + 0.014, 0.045, 12)
    sasso("Ferro", x0 + 0.26, alt + 0.014 + 0.048, z0 + 0.34, 0.075, 3301)
    scatola_inclinata("Carta", x0 + 0.26, alt + 0.014, z0 + 0.52, 0.085, 0.052, 0.003,
                      70.0, asse="x")
    # bicchiere
    cilindro("Vetrina", x1 - 0.18, z1 - 0.22, alt, alt + 0.105, 0.034, 14, r2=0.038)


def proiettore():
    """Carrello con il proiettore a pellicola, dietro l'ultima fila.

    E' un 8 mm, non un videoproiettore: nel 1999 in una sala come questa c'era
    quello, e le bobine sopra sono la cosa che lo data.

    Il CARRELLO e' nostro, il PROIETTORE viene da fuori (Poly Haven, CC0). La
    divisione non e' casuale: un carrello sono sei tubi e due ripiani e farlo
    costa niente, mentre un proiettore e' bobine, obiettivo, manopole e carter -
    e il nostro era una scatola con un cono davanti, che e' esattamente il pezzo
    che si guarda quando si entra in sala.
    """
    x0, z0, x1, z1, alt = IMPRONTE["Proiettore"]
    cx = (x0 + x1) / 2
    y_piano = 0.72
    scatola("Metallo", x0 + 0.04, x1 - 0.04, y_piano - 0.03, y_piano, z0 + 0.04, z1 - 0.04)
    scatola("Metallo", x0 + 0.06, x1 - 0.06, 0.30, 0.33, z0 + 0.06, z1 - 0.06)   # ripiano basso
    for a in (x0 + 0.05, x1 - 0.09):
        for b in (z0 + 0.05, z1 - 0.09):
            cilindro("Metallo", a + 0.02, b + 0.02, 0.06, y_piano - 0.03, 0.014, 10)
            cilindro("Gomma", a + 0.02, b + 0.02, 0.0, 0.06, 0.030, 12)
    # I RACCOGLITORI DELLE SERATE, sul ripiano di sotto.
    #
    # Erano TRE SCATOLE color carta impilate e sfalsate di un centimetro, e da
    # mezzo metro erano un blocco di cartone: Federico li ha chiamati «i faldoni»
    # e ha chiesto di aggiustarli. Un raccoglitore lo fanno la costa, l'etichetta,
    # il foro per il dito e il cantonale - vedi `modellare.faldone`.
    #
    # IN PIEDI IN FILA, NON IN PILA, e non e' una scelta estetica: sotto un
    # proiettore la roba si tiene in piedi perche' la si prende a serata iniziata,
    # al buio, tirandola per il foro. Gli ultimi due pendono, come pende sempre
    # l'ultimo raccoglitore di una fila che non arriva in fondo al ripiano; gli
    # altri due sono coricati di piatto nello spazio che avanza.
    # LE COSTE GUARDANO A OVEST, cioe' da dove si entra in sala. Alla prima posa
    # guardavano il muro dietro: dal carrello si vedevano cinque COPERTINE, che
    # sono la faccia liscia, e restavano cinque libroni. Un raccoglitore lo si
    # riconosce dalla costa, quindi la costa va dove qualcuno passa - qui il lato
    # lungo del corridoio fra le sedie e le teche.
    for (dz, pende, col) in ((0.000,  0.0, "Tessuto"),
                             (0.056,  0.0, "LibroBlu"),
                             (0.110,  0.0, "Meteorite"),
                             (0.168,  7.0, "LibroRosso"),
                             (0.228, 12.0, "Tessuto")):
        faldone(x0 + 0.28, 0.33, z0 + 0.14 + dz, gradi=-90.0, pende=pende, colore=col)
    for k, (col, g_) in enumerate((("LibroVerde", -90.0), ("Tessuto", -84.0))):
        faldone(x0 + 0.585, 0.33 + k * 0.052, z0 + 0.30, gradi=g_,
                coricato=True, colore=col)
    cilindro("Gomma", cx + 0.16, z1 - 0.10, 0.02, 0.06, 0.010, 8)      # il cavo per terra
    # IL MUSO GUARDA A NORD, verso lo schermo. I gradi non li ho dedotti: li ho
    # provati tutti e quattro contro il controllo in fondo al file, perche' avevo
    # dedotto novanta guardando dove sta l'obiettivo nel glTF e mi ero sbagliato
    # di un quarto di giro. Dal render sembrava giusto lo stesso.
    return posa_modello(PROIETTORE,
                        (x0 + 0.06, z0 + 0.06, x1 - 0.06, z1 - 0.06, alt - y_piano),
                        gradi=180.0, appoggio=y_piano)


def spirale(x_a, x_b, cy, cz, r, giri, segmenti, fase=0.0):
    """L'elica di una corsia: segmenti lungo un'elica vera, con asse lungo X.

    Non anelli sovrapposti. Dietro un vetro la differenza fra le due cose si nota
    subito: una pila di anelli e' una molla schiacciata, e non tiene niente.
    """
    punti = []
    for i in range(segmenti + 1):
        t = float(i) / segmenti
        ang = fase + 2 * math.pi * giri * t
        punti.append((x_a + (x_b - x_a) * t, cy + r * math.cos(ang), cz + r * math.sin(ang)))
    for i in range(segmenti):
        barra("Metallo", punti[i], punti[i + 1], 0.0045, 4)


def distributore():
    """Il distributore di snack, alla giunzione fra i due corpi (GDD).

    IL FRONTE GUARDA A EST, cioe' verso la sala: la macchina e' addossata al muro
    che divide l'ala est dal corridoio, e chi la usa sta nello spazio aperto al
    pubblico. Da questo discende tutto, compresa la cosa che si sbaglia sempre — la
    colonna dei comandi sta a z BASSO, perche' quella e' la destra di chi guarda la
    macchina, ed e' li' che sta su ogni distributore mai costruito.

    Le misure sono quelle vere di una macchina da snack: 0,78 di profondita', 0,85
    di fronte, 1,83 di altezza.
    """
    x0, z0, x1, z1, alt = IMPRONTE["Distributore"]
    rnd = random.Random(5501)
    xf = x1                      # filo del fronte
    z_com = z0 + 0.24            # confine fra colonna comandi e vetrina

    # --- cassa ----------------------------------------------------------------
    scatola("Metallo", x0 + 0.03, x1 - 0.03, 0.0, 0.10, z0 + 0.03, z1 - 0.03)
    for a in (x0 + 0.06, x1 - 0.16):
        for b in (z0 + 0.06, z1 - 0.16):
            cilindro("Gomma", a + 0.05, b + 0.05, 0.0, 0.03, 0.022, 10)
    # LA CASSA E' UN GUSCIO, NON UN BLOCCO. Scritta come una scatola piena riempiva
    # di metallo tutto il volume: ripiani, spirali e merce restavano sepolti dentro,
    # e da fuori il vetro era una lastra grigia. Non era il vetro a essere opaco —
    # era che dietro non c'era niente da vedere.
    scatola("Metallo", x0, x0 + 0.04, 0.10, alt, z0, z1)                   # schiena
    for lato in (z0, z1 - 0.04):                                           # fianchi
        scatola("Metallo", x0, x1 - 0.05, 0.10, alt, lato, lato + 0.04)
    scatola("Metallo", x0, x1 - 0.05, alt - 0.04, alt, z0, z1)             # cielo
    scatola("Metallo", x0, x1 - 0.24, 0.10, 0.50, z0, z1)                  # basamento pieno
    # l'anta: colonna comandi, montante opposto, traverse sotto e sopra il vetro
    scatola("Metallo", x1 - 0.05, x1, 0.10, alt, z0, z_com)
    scatola("Metallo", x1 - 0.05, x1, 0.10, alt, z1 - 0.05, z1)
    scatola("Metallo", x1 - 0.05, x1, 0.10, 0.52, z_com, z1 - 0.05)
    scatola("Metallo", x1 - 0.05, x1, 1.64, alt, z_com, z1 - 0.05)
    cilindro("Metallo", xf - 0.026, z_com - 0.055, 0.62, 1.40, 0.016, 12)
    for y in (0.62, 1.40):
        scatola("Metallo", x1 - 0.05, xf - 0.016, y - 0.012, y + 0.012,
                z_com - 0.075, z_com - 0.035)

    # --- vetrina e interno ----------------------------------------------------
    vz0, vz1 = z_com + 0.01, z1 - 0.06
    scatola("Vetrina", x1 - 0.046, x1 - 0.036, 0.52, 1.64, vz0, vz1)
    # DENTRO E' CHIARO E C'E' UN TUBO ACCESO. Con il fondo scuro e nessuna luce
    # propria, da fuori il vetro era una lastra grigia: la merce non si vedeva, ed e'
    # l'unica cosa che un distributore deve far vedere. Un distributore vero e'
    # illuminato dentro, e di notte in una sala spenta e' l'unica cosa accesa.
    scatola("Bianco", x0 + 0.04, x0 + 0.05, 0.30, 1.70, z0 + 0.04, z1 - 0.04)
    for lato in (z0 + 0.04, z1 - 0.05):
        scatola("Bianco", x0 + 0.05, x1 - 0.09, 0.30, 1.70, lato, lato + 0.01)
    scatola("Insegna", x1 - 0.16, x1 - 0.08, 1.575, 1.605, vz0 + 0.03, vz1 - 0.03)
    scatola("Metallo", x1 - 0.18, x1 - 0.06, 1.605, 1.635, vz0 + 0.02, vz1 - 0.02)

    CORSIE = 3
    passo_z = (vz1 - vz0) / CORSIE
    for y_rip in (0.60, 0.85, 1.10, 1.35):
        scatola("Metallo", x0 + 0.06, x1 - 0.10, y_rip - 0.012, y_rip, vz0, vz1)
        for c in range(CORSIE):
            zc = vz0 + passo_z * (c + 0.5)
            # il cartellino del prezzo, sul bordo del ripiano
            scatola("Carta", x1 - 0.104, x1 - 0.097, y_rip - 0.030, y_rip - 0.008,
                    zc - 0.030, zc + 0.030)
            spirale(x0 + 0.10, x1 - 0.11, y_rip + 0.055, zc, 0.045,
                    giri=3.5, segmenti=34, fase=rnd.uniform(0.0, 6.28))
            # la merce infilata fra le spire: le corsie non sono mai piene uguali,
            # e una mezza vuota dice piu' di tre piene
            for j in range(rnd.randrange(2, 5)):
                xm = x0 + 0.10 + (0.12 + j * 0.145) * (x1 - 0.21 - x0)
                mat = ("Smalto", "Rame", "Tessuto", "Carta", "Bianco")[rnd.randrange(5)]
                scatola(mat, xm, xm + 0.030, y_rip + 0.014,
                        y_rip + 0.014 + rnd.uniform(0.10, 0.14), zc - 0.055, zc + 0.055)

    # --- colonna dei comandi --------------------------------------------------
    scatola("Schermo", xf - 0.006, xf + 0.005, 1.44, 1.53, z0 + 0.04, z_com - 0.05)
    scatola("Acceso", xf + 0.003, xf + 0.007, 1.465, 1.505, z0 + 0.06, z_com - 0.09)
    for riga in range(4):
        for col in range(3):
            by = 1.34 - riga * 0.075
            bz = z0 + 0.045 + col * 0.058
            scatola("Plastica", xf - 0.004, xf + 0.009, by - 0.026, by + 0.026, bz, bz + 0.046)
    scatola("Metallo", xf - 0.010, xf + 0.007, 0.960, 1.030, z0 + 0.060, z_com - 0.070)
    scatola("Schermo", xf - 0.008, xf + 0.010, 0.985, 1.005, z0 + 0.075, z_com - 0.085)
    scatola("Schermo", xf - 0.008, xf + 0.003, 0.845, 0.875, z0 + 0.050, z_com - 0.060)
    scatola("Plastica", xf - 0.004, xf + 0.011, 0.745, 0.785, z0 + 0.085, z_com - 0.095)
    scatola("Metallo", xf - 0.036, xf + 0.005, 0.505, 0.530, z0 + 0.045, z_com - 0.055)
    scatola("Schermo", xf - 0.032, xf + 0.001, 0.530, 0.612, z0 + 0.055, z_com - 0.065)

    # --- sportello di erogazione ---------------------------------------------
    scatola("Schermo", x1 - 0.22, xf - 0.014, 0.18, 0.44, vz0 + 0.02, vz1 - 0.02)
    scatola("Vetrina", xf - 0.016, xf - 0.006, 0.20, 0.42, vz0 + 0.04, vz1 - 0.04)
    scatola("Metallo", xf - 0.020, xf + 0.005, 0.42, 0.455, vz0 + 0.02, vz1 - 0.02)

    # --- insegna luminosa in alto --------------------------------------------
    scatola("Insegna", xf - 0.008, xf + 0.007, 1.68, alt - 0.03, z0 + 0.05, z1 - 0.05)
    for y_0, y_1 in ((1.655, 1.68), (alt - 0.03, alt)):
        scatola("Metallo", xf - 0.014, xf + 0.011, y_0, y_1, z0 + 0.03, z1 - 0.03)


# --- costruzione -------------------------------------------------------------
pulisci()
libreria()
# le due sul muro est sono lunghe in Z, la bacheca sul muro sud e' lunga in X
teca_a_muro("TecaEst1", 101, asse="z")
teca_a_muro("TecaEst2", 211, asse="z")
teca_a_muro("Meteoriti", 307, asse="x")
_sedie = fila_di_sedie("FilaSedie1", 601) + fila_di_sedie("FilaSedie2", 701)
tavolo_sala()
schermo()
_proiettore = proiettore()
distributore()

oggetti = finisci(morbidi=("Meteorite", "Ferro", "Metallo", "Gomma"))
print()
for o in oggetti:
    print("  %-10s %5d facce" % (o.name, len(o.data.polygons)))

# --- controlli ---------------------------------------------------------------
problemi = list(verifica_arredi())
problemi += verifica_luce(oggetti, FINESTRE)
# anche i modelli presi da fuori devono stare nella loro impronta: e' il patto
problemi += verifica_impronte(
    oggetti + _sedie + _proiettore, [(x0, z0, x1, z1) for (x0, z0, x1, z1, _h) in IMPRONTE.values()])

# IL MUSO DEVE GUARDARE LO SCHERMO. Un proiettore girato e' l'unico errore che in
# una sala di proiezione si vede senza guardare niente, e la rotazione di un
# modello preso da fuori o la si indovina o la si controlla. Il pezzo "focus" e'
# l'obiettivo: deve stare piu' vicino allo schermo del resto del proiettore.
_focus = [o for o in _proiettore if o.type == "MESH" and "focus" in o.name]
if not _focus:
    problemi.append("il proiettore non ha piu' un pezzo 'focus': il controllo sul muso e' cieco")
else:
    def _z_medio(oggetti_):
        p_ = [(o.matrix_world @ Vector(c)) for o in oggetti_ if o.type == "MESH"
              for c in o.bound_box]
        return -sum(q.y for q in p_) / len(p_)
    _zf, _zc = _z_medio(_focus), _z_medio(_proiettore)
    _z_schermo = (IMPRONTE["Schermo"][1] + IMPRONTE["Schermo"][3]) / 2
    print("  il muso del proiettore sta a z=%.2f, il corpo a %.2f, lo schermo a %.2f"
          % (_zf, _zc, _z_schermo))
    # SERVE UNO SBALZO, non solo il segno giusto: la ghiera e' un pezzo piccolo
    # vicino al centro, e a girare il proiettore di novanta gradi si sposterebbe
    # di un paio di centimetri - abbastanza per far passare un confronto secco.
    _sbalzo = (_zc - _zf) * (1 if _z_schermo < _zc else -1)
    if _sbalzo < 0.04:
        problemi.append("il proiettore non guarda lo schermo: il muso sbalza di %.0f mm"
                        % (_sbalzo * 1000))

_alto = max((o.matrix_world @ v.co).z for o in oggetti for v in o.data.vertices)
print("\n  il pezzo piu' alto arriva a %.2f m, il soffitto sta a 3,00" % _alto)
if _alto > 3.00:
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
    bpy.ops.import_scene.gltf(filepath=_osservatorio)
for _p in ((11.0, 2.60, 6.0), (16.5, 2.60, 3.4), (16.5, 2.60, 7.6)):
    # 130 W per lampada bruciavano i muri e facevano leggere i meteoriti come
    # polistirolo: a un render sovraesposto non si puo' chiedere di giudicare un colore
    lampada("Plafoniera%d" % int(_p[0] * 10 + _p[2]), _p, 55.0, tipo="AREA", dimensione=1.6)


def scatta(nome, posizione, mira, lente=28.0):
    scatta_su(os.path.join(RENDER, nome), posizione, mira, lente)


# entrando dalla porta d'ingresso: le teche a isola davanti, la sala proiezioni in fondo
scatta("divulgazione.png", (10.60, 1.65, 8.90), (14.80, 1.20, 5.60), lente=20.0)
# la libreria, che sta sul muro della cucina
scatta("divulgazione-libreria.png", (11.60, 1.60, 6.40), (11.90, 1.25, 4.30), lente=30.0)
# la sala proiezioni, dal fondo: proiettore, tre file, schermo
scatta("divulgazione-proiezioni.png", (17.30, 1.55, 8.90), (16.30, 1.05, 4.20), lente=24.0)
# il distributore, alla giunzione fra i due corpi
scatta("divulgazione-distributore.png", (11.10, 1.35, 6.20), (9.05, 1.00, 6.82), lente=30.0)
# le teche a muro sul lato est
scatta("divulgazione-teche.png", (16.20, 1.62, 4.60), (18.60, 1.25, 2.60), lente=26.0)
# LA CARTA DA VICINO, che da lontano e' un colore e da mezzo metro e' un oggetto:
# il ripiano basso del carrello e il piano del tavolo.
scatta("divulgazione-carta-carrello.png", (15.30, 0.78, 7.70), (16.40, 0.42, 7.08), lente=45.0)
scatta("divulgazione-carta-coricati.png", (15.90, 0.62, 7.72), (16.70, 0.36, 7.06), lente=70.0)
scatta("divulgazione-carta-tavolo.png", (15.95, 1.30, 4.15), (16.35, 0.79, 3.10), lente=45.0)
# il proiettore da vicino, di tre quarti: il muso deve guardare lo schermo
scatta("divulgazione-proiettore.png", (15.60, 1.20, 8.10), (16.50, 0.86, 7.10), lente=45.0)
