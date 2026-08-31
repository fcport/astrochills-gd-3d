# -*- coding: utf-8 -*-
"""Il bagno, dalla stessa impronta che lo fa collidere.

    "D:/programs/blender5/blender.exe" --background --python tools/bagno_blender.py

Stesso patto degli altri modellatori: `geometria.ARREDI_BAGNO` dichiara i rettangoli
in pianta, qui dentro ci si costruisce, e alla fine si controlla che nessuna mesh
esca dalla sua impronta. Quello che si vede e quello contro cui si sbatte restano la
stessa cosa.

UN BAGNO ITALIANO DEL 1999, E NON UN BAGNO. La differenza non la fanno i sanitari -
un water e' un water in ogni paese e in ogni decennio - la fanno tre cose che qui
sono geometria e materiale, non arredamento:

  * IL RIVESTIMENTO SI FERMA A 1,60 e sopra c'e' intonaco. Piastrellare fino al
    soffitto e' un gesto di oggi; fermarsi a mezza altezza con una riga di
    chiusura e' quello di allora, e da solo sposta la stanza di trent'anni.
  * IL LISTELLO. La fascia di losanghe azzurrine sopra il rivestimento e' il pezzo
    che data il bagno piu' di tutto il resto messo insieme. Non esiste in nessuna
    libreria CC0 - un listello e' un pezzo di gusto - e infatti se lo disegna
    tools/fai_listello.py.
  * IL BIDET. Un bagno senza bidet non e' italiano, punto. E la distanza dal water
    e' 75 cm da asse ad asse: sotto i 55 non ci si siede, sopra gli 80 la parete
    sembra vuota in mezzo.

SENZA VASCA, per richiesta: al suo posto la doccia nell'angolo sud-est, 90x90 con
box in cristallo. In un bagno di servizio di un osservatorio e' anche piu'
credibile - ci si sciacqua dopo una notte in cupola, non ci si fa il bagno.

I SANITARI ARRIVANO DA FUORI, quando ci sono. Un water, un bidet e un lavabo a
colonna sono superfici curve continue: fatti con le scatole vengono mobili, non
ceramiche. Se i modelli non sono ancora stati scaricati questo script NON fallisce -
mette i suoi segnaposto e lo dice - perche' un bagno senza sanitari e' comunque una
stanza da guardare, mentre un modellatore che si rifiuta di girare non lo e'.

Produce assets/models/bagno.glb.
"""
import math
import os
import sys

import bpy

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
import importlib   # noqa: E402
for _m in ("geometria", "modellare"):
    if _m in sys.modules:
        importlib.reload(sys.modules[_m])
from geometria import ARREDI_BAGNO, SALA_BAGNO, W_SILL   # noqa: E402
from modellare import (cilindro, cilindro_orizz, esporta, finisci,   # noqa: E402
                       lampada, posa_modello, prepara_render, pulisci, scatola,
                       verifica_impronte)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "bagno.glb")
ESTERNI = os.path.join(RADICE, "assets", "models", "esterni")
RENDER = os.path.join(RADICE, "_bmad-output", "planning-artifacts", "gdds",
                      "gdd-astrochills-gd-3d-2026-08-24")

IMPRONTE = {n: (x0, z0, x1, z1, h) for (n, x0, z0, x1, z1, h) in ARREDI_BAGNO}
X0, Z0, X1, Z1 = SALA_BAGNO[0]

# il vano della porta sul muro nord e quello della finestra sul muro sud: il
# rivestimento si interrompe li', e il listello con lui
PORTA = (5.80, 7.10)
FINESTRA = (6.20, 7.20)

# Il rivestimento arriva a 1,60 e il listello sono gli ultimi 8 cm. Non 2,00 e non
# fino al soffitto: 1,60 e' l'altezza a cui si fermava il rivestimento nei bagni di
# quegli anni, ed e' anche l'altezza a cui l'occhio di chi sta in piedi lo incontra.
RIV = 1.60
LIST = 0.08
SPESS = 0.012      # lo spessore della piastrella, che si vede solo di taglio
SPORGE = 0.010     # di quanto il listello esce dal filo del rivestimento

# I sanitari presi da fuori: cartella dentro assets/models/esterni -> (impronta,
# gradi, come si chiama in italiano). I gradi sono la rotazione attorno alla
# verticale perche' guardino DENTRO la stanza: un modello non conosce il nostro nord.
SANITARI = [
    ("wc_bagno",     "Wc",     -90.0, "il water"),
    ("bidet_bagno",  "Bidet",  -90.0, "il bidet"),
    ("lavabo_bagno", "Lavabo",  90.0, "il lavabo a colonna"),
]

mancanti = []


# --- il guscio: piastrelle, listello, pavimento ------------------------------
def riveste():
    """Il rivestimento a mezza altezza, con i vani lasciati liberi."""
    # ovest ed est, per tutta la lunghezza
    scatola("PiastrelleMuro", X0, X0 + SPESS, 0.0, RIV, Z0, Z1)
    scatola("PiastrelleMuro", X1 - SPESS, X1, 0.0, RIV, Z0, Z1)
    # nord: due tratti, di qua e di la' dalla porta
    for (xa, xb) in ((X0, PORTA[0]), (PORTA[1], X1)):
        scatola("PiastrelleMuro", xa, xb, 0.0, RIV, Z0, Z0 + SPESS)
    # sud: tutto fino al davanzale, e sopra il davanzale solo ai lati della finestra
    scatola("PiastrelleMuro", X0, X1, 0.0, W_SILL, Z1 - SPESS, Z1)
    for (xa, xb) in ((X0, FINESTRA[0]), (FINESTRA[1], X1)):
        scatola("PiastrelleMuro", xa, xb, W_SILL, RIV, Z1 - SPESS, Z1)


def listello():
    """La fascia decorativa che chiude il rivestimento, e sporge di un centimetro.

    SPORGE APPOSTA. A filo del rivestimento sarebbe un disegno stampato sul muro;
    sporgendo di dieci millimetri prende una riga d'ombra sotto e una luce sopra, e
    diventa un pezzo di ceramica incollato li'. E' la stessa lezione delle nervature
    della porta del magazzino, dove otto millimetri non bastavano a farsi vedere.
    """
    y0, y1 = RIV - LIST, RIV
    s = SPESS + SPORGE
    scatola("Listello", X0, X0 + s, y0, y1, Z0, Z1)
    scatola("Listello", X1 - s, X1, y0, y1, Z0, Z1)
    for (xa, xb) in ((X0, PORTA[0]), (PORTA[1], X1)):
        scatola("Listello", xa, xb, y0, y1, Z0, Z0 + s)
    # sul muro sud il listello passa alla quota della finestra: si interrompe nel vano
    for (xa, xb) in ((X0, FINESTRA[0]), (FINESTRA[1], X1)):
        scatola("Listello", xa, xb, y0, y1, Z1 - s, Z1)


def pavimento():
    """Il gres beige, sopra il pavimento della stanza."""
    scatola("PiastrellePav", X0, X1, 0.0, 0.012, Z0, Z1)


# --- la doccia ---------------------------------------------------------------
def doccia():
    x0, z0, x1, z1, alto = IMPRONTE["Doccia"]
    b = 0.02                       # il piatto sta dentro l'impronta di due centimetri
    px0, pz0, px1, pz1 = x0 + b, z0 + b, x1 - b, z1 - b
    # IL PIATTO E' ALTO 12 CM E HA IL BORDO. I piatti a filo pavimento sono di
    # adesso; nel 1999 il piatto era un catino di ceramica che si sale, e quel
    # gradino si vede da tutta la stanza.
    scatola("Ceramica", px0, px1, 0.0, 0.10, pz0, pz1)
    for (a, b_, c, d) in ((px0, pz0, px1, pz0 + 0.05), (px0, pz1 - 0.05, px1, pz1),
                          (px0, pz0, px0 + 0.05, pz1), (px1 - 0.05, pz0, px1, pz1)):
        scatola("Ceramica", a, c, 0.10, 0.14, b_, d)
    cilindro("Inox", (px0 + px1) / 2, (pz0 + pz1) / 2, 0.100, 0.104, 0.045)

    # il box: una lastra fissa a nord, e a ovest una lastra che lascia il varco
    # per entrare. Un box chiuso su tre lati e' un armadio.
    scatola("Vetrina", px0, px1, 0.14, alto, pz0, pz0 + 0.008)
    meta = pz0 + (pz1 - pz0) * 0.5
    scatola("Vetrina", px0, px0 + 0.008, 0.14, alto, pz0, meta)
    # i profili di alluminio: sopra, sotto e sui montanti
    for (a, c) in ((px0, px1),):
        for y in (0.14, alto):
            scatola("Inox", a, c, y - 0.02, y + 0.02, pz0 - 0.004, pz0 + 0.012)
    for y in (0.14, alto):
        scatola("Inox", px0 - 0.004, px0 + 0.012, y - 0.02, y + 0.02, pz0, meta)
    for zz in (pz0, meta):
        scatola("Inox", px0 - 0.004, px0 + 0.012, 0.14, alto, zz - 0.008, zz + 0.008)
    scatola("Inox", px1 - 0.016, px1, 0.14, alto, pz0 - 0.004, pz0 + 0.012)

    # soffione e miscelatore sul muro est, che e' il muro cieco
    xm = px1 - 0.01
    cilindro_orizz("Inox", xm - 0.14, 1.95, (pz0 + pz1) / 2, "x", 0.28, 0.014)
    cilindro("Inox", xm - 0.27, (pz0 + pz1) / 2, 1.86, 1.95, 0.055, seg=12)
    cilindro_orizz("Inox", xm - 0.05, 1.15, (pz0 + pz1) / 2, "x", 0.10, 0.028)
    cilindro_orizz("Inox", xm - 0.10, 1.15, (pz0 + pz1) / 2 + 0.08, "x", 0.02, 0.010)


# --- il mobiletto e lo specchio ----------------------------------------------
def pensile():
    """Appeso al muro nord: noce scuro e anta a specchio. E' il pezzo della foto."""
    x0, z0, x1, z1, alto = IMPRONTE["Pensile"]
    basso, cima = 1.45, alto
    zf = z1 - 0.004
    # cassa
    scatola("LegnoTeche", x0, x1, basso, cima, z0, z1)
    # l'anta a specchio, incassata di un filo nella cornice di legno
    scatola("Specchio", x0 + 0.05, x1 - 0.05, basso + 0.05, cima - 0.05,
            zf, zf + 0.006)
    # la cornice sporge: senza, lo specchio sembra dipinto sull'anta
    for (a, b, c, d) in ((x0, basso, x1, basso + 0.05), (x0, cima - 0.05, x1, cima),
                         (x0, basso, x0 + 0.05, cima), (x1 - 0.05, basso, x1, cima)):
        scatola("LegnoTeche", a, c, b, d, zf, zf + 0.014)
    # il pomello
    cilindro_orizz("Inox", x1 - 0.10, (basso + cima) / 2, zf + 0.02, "z", 0.03, 0.012)


def sopra_il_lavabo():
    """Specchio, mensola e applique: il muro ovest sopra il lavabo."""
    x0, z0, x1, z1, _alto = IMPRONTE["Lavabo"]
    xf = x0 + SPESS + SPORGE
    # lo specchio, con la cornice di alluminio
    scatola("Specchio", xf, xf + 0.006, 1.05, 1.75, z0 + 0.04, z1 - 0.04)
    for (a, b) in ((1.05, 1.075), (1.725, 1.75)):
        scatola("Inox", xf, xf + 0.016, a, b, z0 + 0.03, z1 - 0.03)
    for zz in (z0 + 0.04, z1 - 0.04):
        scatola("Inox", xf, xf + 0.016, 1.05, 1.75, zz - 0.012, zz + 0.012)
    # la mensola di cristallo sotto lo specchio, con i due reggi-mensola
    scatola("Vetrina", xf, xf + 0.13, 0.99, 1.006, z0 + 0.03, z1 - 0.03)
    for zz in (z0 + 0.08, z1 - 0.08):
        scatola("Inox", xf, xf + 0.05, 0.975, 0.99, zz - 0.015, zz + 0.015)
    # l'applique sopra lo specchio: carcassa e tubo, SPENTO come tutti gli altri
    # diffusori del progetto (la faccia accesa sta nella scena, non nel modello)
    # CERAMICA E NON LAMIERA. La lamiera di questo progetto e' quella verniciata e
    # segnata delle plafoniere industriali: sopra uno specchio da bagno leggeva come
    # un pezzo arrugginito. Un'applique da bagno e' metallo smaltato bianco liscio.
    scatola("Ceramica", xf, xf + 0.075, 1.82, 1.90, z0 + 0.09, z1 - 0.09)
    cilindro_orizz("Neon", xf + 0.045, 1.855, (z0 + z1) / 2, "z", z1 - z0 - 0.24, 0.016)


def portasalviette():
    x0, z0, x1, z1, _alto = IMPRONTE["Portasalv"]
    xf = x0 + SPESS + SPORGE
    for zz in (z0 + 0.05, z1 - 0.05):
        cilindro("Inox", xf + 0.04, zz, 1.05, 1.22, 0.010, seg=8)
    cilindro_orizz("Inox", xf + 0.04, 1.22, (z0 + z1) / 2, "z", z1 - z0 - 0.10, 0.010)
    # l'asciugamano piegato in due, che e' l'unica macchia di colore della stanza
    scatola("Spugna", xf + 0.018, xf + 0.062, 0.86, 1.23, z0 + 0.10, z1 - 0.10)


def termosifone():
    """A elementi, sotto la finestra. Undici colonnine e due collettori.

    SMALTATO BIANCO, non lamiera: un radiatore di ghisa verniciato non ha niente
    della lamiera segnata delle plafoniere, e con quella addosso sembrava arrugginito
    sotto la finestra di un bagno pulito.
    """
    x0, z0, x1, z1, alto = IMPRONTE["Termo"]
    basso, cima = 0.18, alto - 0.03
    n = 11
    for k in range(n):
        x = x0 + 0.05 + (x1 - x0 - 0.10) * k / (n - 1.0)
        scatola("Ceramica", x - 0.017, x + 0.017, basso, cima, z0 + 0.02, z1 - 0.02)
    for y in (basso, cima):
        scatola("Ceramica", x0 + 0.03, x1 - 0.03, y - 0.022, y + 0.022,
                z0 + 0.035, z1 - 0.035)
    # le due mensole a muro e la valvola
    for xx in (x0 + 0.10, x1 - 0.10):
        scatola("Inox", xx - 0.012, xx + 0.012, basso - 0.03, basso, z1 - 0.06, z1)
    cilindro("Inox", x0 + 0.05, (z0 + z1) / 2, basso - 0.10, basso, 0.014, seg=8)


# --- i sanitari: da fuori se ci sono, segnaposto se no ------------------------
def wc_segnaposto():
    x0, z0, x1, z1, _a = IMPRONTE["Wc"]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    # la tazza: due tronchi di cono sovrapposti, che e' il minimo per non sembrare
    # una scatola. Non e' un water: e' il posto dove ne andra' uno.
    cilindro("Ceramica", cx + 0.04, cz, 0.0, 0.20, 0.11, seg=12, r2=0.15)
    cilindro("Ceramica", cx + 0.04, cz, 0.20, 0.40, 0.15, seg=12, r2=0.18)
    scatola("Bianco", x0 + 0.06, x1 - 0.14, 0.40, 0.43, z0 + 0.02, z1 - 0.02)
    # la cassetta appoggiata, che nel 1999 era ancora la norma
    scatola("Ceramica", x1 - 0.20, x1, 0.43, 0.80, z0 + 0.03, z1 - 0.03)
    cilindro("Inox", x1 - 0.10, cz, 0.80, 0.82, 0.022, seg=10)


def bidet_segnaposto():
    x0, z0, x1, z1, _a = IMPRONTE["Bidet"]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    cilindro("Ceramica", cx + 0.03, cz, 0.0, 0.22, 0.09, seg=12, r2=0.14)
    cilindro("Ceramica", cx + 0.03, cz, 0.22, 0.40, 0.14, seg=12, r2=0.17)
    cilindro("Inox", x1 - 0.07, cz, 0.40, 0.52, 0.018, seg=10)
    cilindro_orizz("Inox", x1 - 0.13, 0.51, cz, "x", 0.09, 0.012)


def lavabo_segnaposto():
    x0, z0, x1, z1, _a = IMPRONTE["Lavabo"]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    # la colonna
    cilindro("Ceramica", cx, cz, 0.0, 0.72, 0.09, seg=12, r2=0.11)
    # il catino: fondo e quattro sponde, che e' come si fa un lavabo con le scatole
    scatola("Ceramica", x0, x1 - 0.02, 0.72, 0.78, z0 + 0.02, z1 - 0.02)
    for (a, b, c, d) in ((x0, z0 + 0.02, x1 - 0.02, z0 + 0.06),
                         (x0, z1 - 0.06, x1 - 0.02, z1 - 0.02),
                         (x1 - 0.06, z0 + 0.02, x1 - 0.02, z1 - 0.02)):
        scatola("Ceramica", a, c, 0.78, 0.86, b, d)
    scatola("Ceramica", x0, x0 + 0.09, 0.78, 0.88, z0 + 0.02, z1 - 0.02)
    # il miscelatore monocomando, che nel 1999 aveva gia' sostituito i due rubinetti
    cilindro("Inox", x0 + 0.055, cz, 0.86, 0.98, 0.020, seg=10)
    cilindro_orizz("Inox", x0 + 0.09, 0.975, cz, "x", 0.10, 0.013)
    scatola("Inox", x0 + 0.045, x0 + 0.075, 0.98, 1.02, cz + 0.01, cz + 0.05)


def sanitari():
    """Monta i modelli scaricati; dove mancano mette il segnaposto e lo dice."""
    fatti = {"Wc": wc_segnaposto, "Bidet": bidet_segnaposto,
             "Lavabo": lavabo_segnaposto}
    for (cartella, quale, gradi, come_si_chiama) in SANITARI:
        via = os.path.join(ESTERNI, cartella, "scene.gltf")
        if os.path.exists(via):
            posa_modello(via, IMPRONTE[quale], gradi=gradi)
            print("  %-8s dal modello scaricato" % quale)
        else:
            fatti[quale]()
            mancanti.append("%s (%s) - manca %s" % (quale, come_si_chiama, via))
            print("  %-8s SEGNAPOSTO: il modello non c'e' ancora" % quale)


# --- costruzione -------------------------------------------------------------
pulisci()
riveste()
listello()
pavimento()
doccia()
pensile()
sopra_il_lavabo()
portasalviette()
termosifone()
sanitari()

oggetti = finisci(morbidi=("Ceramica", "Inox"))

# IL GUSCIO NON HA IMPRONTA, ED E' GIUSTO COSI'. Rivestimento, listello e pavimento
# non sono arredi: sono uno strato di un centimetro incollato a superfici che la
# collisione ce l'hanno gia'. Dichiararli fra gli arredi darebbe quattro strisce che
# si sovrappongono a ogni sanitario addossato al muro - cioe' a tutti - e il
# controllo degli arredi si riempirebbe di guasti inventati.
GUSCIO = ("PiastrelleMuro", "PiastrellePav", "Listello")
problemi = verifica_impronte(
    [o for o in oggetti if o.name not in GUSCIO],
    [(x0, z0, x1, z1) for (x0, z0, x1, z1, _h) in IMPRONTE.values()])

ALTEZZA_STANZA = 3.00
_alto = max((o.matrix_world @ v.co).z for o in oggetti for v in o.data.vertices)
print("\n  il pezzo piu' alto arriva a %.2f m, il soffitto sta a %.2f"
      % (_alto, ALTEZZA_STANZA))
if _alto > ALTEZZA_STANZA:
    problemi.append("un arredo sfonda il soffitto: %.2f m" % _alto)

# IL RIVESTIMENTO DEVE ARRIVARE AL LISTELLO E FERMARSI LI'. Sembra ovvio e non lo e':
# basta cambiare RIV senza cambiare l'altezza del listello per ritrovarsi la fascia
# in mezzo alle piastrelle o staccata dal loro bordo, e in un render notturno non si
# distingue da un difetto della texture.
for o in oggetti:
    if o.name != "Listello":
        continue
    cima = max((o.matrix_world @ v.co).z for v in o.data.vertices)
    if abs(cima - RIV) > 1e-3:
        problemi.append("il listello chiude a %.3f invece che a %.3f" % (cima, RIV))

if problemi:
    print("\nATTENZIONE:")
    for p in problemi:
        print("  " + p)
    sys.exit(1)

esporta(USCITA)

if mancanti:
    print("\nSANITARI ANCORA DA SCARICARE (adesso ci sono i segnaposto):")
    for m in mancanti:
        print("  " + m)

# --- render di controllo -----------------------------------------------------
scatta_su = prepara_render()
_osservatorio = os.path.join(RADICE, "assets", "models", "osservatorio.glb")
if os.path.exists(_osservatorio):
    bpy.ops.import_scene.gltf(filepath=_osservatorio)
lampada("Plafoniera", ((X0 + X1) / 2, 2.60, (Z0 + Z1) / 2), 90.0,
        tipo="AREA", dimensione=1.0)
lampada("Applique", (5.25, 1.86, 8.55), 8.0)


def scatta(nome, posizione, mira, lente=28.0):
    scatta_su(os.path.join(RENDER, nome), posizione, mira, lente)


# entrando dalla porta: si deve vedere la fila dei sanitari e il listello che corre
scatta("bagno.png", (6.45, 1.62, 6.95), (7.90, 1.05, 8.60), lente=20.0)
# il lavabo con lo specchio, dal centro della stanza
scatta("bagno-lavabo.png", (6.60, 1.62, 8.10), (5.05, 1.20, 8.55), lente=24.0)
# la doccia e la finestra
scatta("bagno-doccia.png", (5.60, 1.62, 7.20), (7.90, 1.10, 9.20), lente=22.0)
# il listello da vicino: e' il pezzo che data la stanza, va guardato
scatta("bagno-listello.png", (6.30, 1.55, 7.60), (8.10, 1.52, 7.30), lente=45.0)
