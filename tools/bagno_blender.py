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
import io
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
from modellare import (COLORI, cilindro, cilindro_orizz, esporta,   # noqa: E402
                       finisci, usa_le_ridotte,
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
# I sanitari presi da fuori: cartella -> (impronta, gradi, altezza di posa, nome).
#
# I GRADI SONO MISURATI, non indovinati: li stampa `tools/verso_sanitari.py`, che
# posa ogni modello alle quattro rotazioni e conta quanti vertici finiscono a filo
# del muro a cui quel pezzo e' addossato. Per il water quel conteggio non bastava -
# con la cassetta non arriva mai ai lati dell'impronta e dava zero a tutte e quattro
# - e li' decide da che parte pende la meta' alta del modello: un water ha la
# cassetta in alto e dietro.
#
# E L'ALTEZZA DI POSA NON E' QUELLA DELL'IMPRONTA. L'impronta del lavabo e' alta
# 1,90 perche' comprende specchio, mensola e applique; il lavabo e' alto 86 cm.
# Passando 1,90 a `posa_modello` il lavabo veniva scalato per essere alto quasi un
# metro, cioe' dieci centimetri troppo, e da fermi davanti si vedeva.
SANITARI = [
    ("wc_bagno",     "Wc",      90.0, 0.78, "il water"),
    ("bidet_bagno",  "Bidet",  180.0, 0.52, "il bidet"),
    ("lavabo_bagno", "Lavabo", 270.0, 0.86, "il lavabo a colonna"),
]

# Chi arriva bianco di fabbrica e va portato all'eta' degli altri. Il water e il
# lavabo no: quelli si sono trovati gia' segnati, ed e' meglio lo sporco vero di
# chi li ha fatti che una tinta uniforme passata sopra.
# NESSUNO. C'era il bidet, e invecchiarlo e' stato un errore: arrivava a 227 su 255
# - l'unico dei tre gia' bianco - e moltiplicarlo per una tinta calda lo ha portato a
# 186 con una dominante, cioe' l'ha reso il piu' scuro dei tre. In una stanza sola tre
# ceramiche devono essere lo STESSO bianco, e quel bianco lo pareggia
# `tools/pareggia_ceramica.py` sulle mappe, dove si puo' anche schiarire.
INVECCHIARE = ()

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


# --- l'armadio di servizio ---------------------------------------------------
def armadio():
    """Armadio di lamiera a due ante, nell'angolo dove stava la doccia.

    In un osservatorio il bagno di servizio non ha la doccia: ha il posto dove
    stanno i detersivi, i ricambi e il camice. Un armadio da spogliatoio in lamiera
    verniciata dice quello, e lo dice con tre dettagli che sono geometria:
    le FERITOIE in alto (un armadio chiuso senza sfiato ammuffisce, e chi li fa lo
    sa), le maniglie VERTICALI a bastone, e lo zoccolo che lo stacca dal pavimento
    bagnato. Senza quei tre, una scatola grigia e' una scatola grigia.
    """
    xi, z0, x1, z1, alto = IMPRONTE["Armadio"]
    x0 = xi + 0.07          # il filo dell'anta: i 7 cm davanti sono le maniglie
    zoccolo = 0.10
    M = "Armadietto"
    # LA CASSA, E GLI ASSI VANNO GUARDATI DUE VOLTE. L'armadio e' addossato alla
    # parete est: la SCHIENA sta a x alto, la FRONTE a x basso, e i FIANCHI sono i
    # due piani a z costante. Alla prima stesura fianchi e fronte si erano scambiati
    # di posto e ne era uscito un armadio aperto di lato, con le ante appiccicate
    # sopra il pannello che avrebbero dovuto essere.
    for (za, zb) in ((z0, z0 + 0.02), (z1 - 0.02, z1)):          # fianchi
        scatola(M, x0, x1, zoccolo, alto, za, zb)
    scatola(M, x1 - 0.02, x1, zoccolo, alto, z0, z1)             # schiena
    for (b, d) in ((zoccolo, zoccolo + 0.02), (alto - 0.02, alto)):
        scatola(M, x0, x1, b, d, z0, z1)                         # fondo e cielo
    # il ripiano di mezzo, che si vede dalla fessura fra le ante
    scatola(M, x0 + 0.02, x1 - 0.02, 1.05, 1.068, z0 + 0.02, z1 - 0.02)
    # lo zoccolo rientrato: un armadio a filo pavimento sembra incollato
    scatola(M, x0 + 0.04, x1 - 0.04, 0.0, zoccolo, z0 + 0.04, z1 - 0.04)

    # le due ante, con la fuga in mezzo
    xa = x0
    meta = (z0 + z1) / 2
    for (za, zb) in ((z0 + 0.012, meta - 0.005), (meta + 0.005, z1 - 0.012)):
        scatola(M, xa, xa + 0.018, zoccolo + 0.025, alto - 0.025, za, zb)
        # LE FERITOIE, e sporgono in fuori invece di essere incassate. Un armadio
        # chiuso senza sfiato ammuffisce e chi li fabbrica lo sa; ma incassate di
        # quattro millimetri, in una stanza senza occlusione ambientale, non fanno
        # ombra e non esistono - la stessa lezione delle nervature del magazzino.
        for k in range(3):
            y = alto - 0.16 - k * 0.05
            scatola("Schermo", xa - 0.004, xa + 0.006, y, y + 0.018,
                    za + 0.07, zb - 0.07)
            scatola(M, xa - 0.010, xa - 0.004, y - 0.008, y + 0.026,
                    za + 0.062, zb - 0.062)
    # le maniglie a bastone, verticali, ai due lati della fuga
    for zz in (meta - 0.055, meta + 0.055):
        cilindro("Inox", xa - 0.052, zz, 0.95, 1.28, 0.011, seg=8)
        for y in (0.95, 1.28):
            cilindro_orizz("Inox", xa - 0.035, y, zz, "x", 0.035, 0.009)
    # la serratura a chiave: un armadio di servizio si chiude
    cilindro("Inox", xa - 0.006, meta - 0.12, 1.12, 1.13, 0.013, seg=10)


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
    cilindro("CeramicaVecchia", cx + 0.04, cz, 0.0, 0.20, 0.11, seg=12, r2=0.15)
    cilindro("CeramicaVecchia", cx + 0.04, cz, 0.20, 0.40, 0.15, seg=12, r2=0.18)
    scatola("Bianco", x0 + 0.06, x1 - 0.14, 0.40, 0.43, z0 + 0.02, z1 - 0.02)
    # la cassetta appoggiata, che nel 1999 era ancora la norma
    scatola("CeramicaVecchia", x1 - 0.20, x1, 0.43, 0.80, z0 + 0.03, z1 - 0.03)
    cilindro("Inox", x1 - 0.10, cz, 0.80, 0.82, 0.022, seg=10)


def bidet_segnaposto():
    x0, z0, x1, z1, _a = IMPRONTE["Bidet"]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    cilindro("CeramicaVecchia", cx + 0.03, cz, 0.0, 0.22, 0.09, seg=12, r2=0.14)
    cilindro("CeramicaVecchia", cx + 0.03, cz, 0.22, 0.40, 0.14, seg=12, r2=0.17)
    cilindro("Inox", x1 - 0.07, cz, 0.40, 0.52, 0.018, seg=10)
    cilindro_orizz("Inox", x1 - 0.13, 0.51, cz, "x", 0.09, 0.012)


def rubinetto_lavabo(quota):
    """Il miscelatore sopra il lavabo, che nel modello scaricato NON c'e'.

    Il lavabo d'epoca arriva col solo foro: la rubinetteria e' un pezzo a parte in
    quasi tutti i modelli di sanitari, e un lavabo senza rubinetto e' una vasca. Sta
    qui e non dentro il segnaposto proprio per questo - serve in tutti e due i casi,
    e messo dentro il segnaposto sarebbe sparito il giorno in cui il modello e'
    arrivato.

    MONOCOMANDO e non due rubinetti separati: nel 1999 il miscelatore aveva gia'
    sostituito la coppia acqua calda / acqua fredda, che e' di vent'anni prima.
    """
    x0, z0, x1, z1, _a = IMPRONTE["Lavabo"]
    cz = (z0 + z1) / 2
    xr = x0 + 0.10
    cilindro("Inox", xr, cz, quota, quota + 0.15, 0.021, seg=10)
    # il becco sporge 14 cm sopra il bacino: a dieci restava dentro il bordo del
    # lavabo e da fermi davanti si vedeva solo il corpo del miscelatore
    cilindro_orizz("Inox", xr + 0.075, quota + 0.145, cz, "x", 0.15, 0.013)
    # la leva, inclinata all'indietro come sta una leva alzata a meta'
    scatola("Inox", xr - 0.012, xr + 0.014, quota + 0.15, quota + 0.185,
            cz + 0.008, cz + 0.055)


def lavabo_segnaposto():
    x0, z0, x1, z1, _a = IMPRONTE["Lavabo"]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    # la colonna
    cilindro("CeramicaVecchia", cx, cz, 0.0, 0.72, 0.09, seg=12, r2=0.11)
    # il catino: fondo e quattro sponde, che e' come si fa un lavabo con le scatole
    scatola("CeramicaVecchia", x0, x1 - 0.02, 0.72, 0.78, z0 + 0.02, z1 - 0.02)
    for (a, b, c, d) in ((x0, z0 + 0.02, x1 - 0.02, z0 + 0.06),
                         (x0, z1 - 0.06, x1 - 0.02, z1 - 0.02),
                         (x1 - 0.06, z0 + 0.02, x1 - 0.02, z1 - 0.02)):
        scatola("CeramicaVecchia", a, c, 0.78, 0.86, b, d)
    scatola("CeramicaVecchia", x0, x0 + 0.09, 0.78, 0.88, z0 + 0.02, z1 - 0.02)
    # il miscelatore lo mette rubinetto_lavabo(), che serve anche al modello vero


def ingiallisci(pezzi, tinta):
    """Da' vent'anni a una ceramica che arriva nuova di fabbrica.

    Il water e il lavabo si sono trovati gia' segnati; il bidet no, e di bidet
    vecchi non ne esiste nemmeno uno con licenza libera. Non e' un caso: il bidet e'
    un oggetto italiano e francese e le librerie 3D sono anglosassoni. Accanto a due
    sanitari ingialliti, un bidet bianco di fabbrica sarebbe l'unica cosa nuova della
    stanza - e in una stanza dove tutto ha vent'anni, l'unica cosa nuova e' quella
    che si nota.

    SI MOLTIPLICA la mappa colore per una tinta calda, non la si sostituisce: quella
    mappa porta le ombre e i dettagli del modello, e buttarla via per un colore
    piatto sarebbe un peggioramento travestito da invecchiamento. E' lo stesso nodo
    Mix in MULTIPLY che `modellare.applica_texture` usa per i dorsi dei libri, e
    l'esportatore glTF lo sa tradurre.
    """
    fatti = set()
    for o in pezzi:
        for slot in getattr(o, "material_slots", []):
            m = slot.material
            if m is None or m.name in fatti or not m.use_nodes:
                continue
            fatti.add(m.name)
            nt = m.node_tree
            bsdf = None
            for n in nt.nodes:
                if n.type == "BSDF_PRINCIPLED":
                    bsdf = n
                    break
            if bsdf is None:
                continue
            base = bsdf.inputs["Base Color"]
            if base.is_linked:
                sorgente = base.links[0].from_socket
                mix = nt.nodes.new("ShaderNodeMix")
                mix.data_type = "RGBA"
                mix.blend_type = "MULTIPLY"
                mix.inputs["Factor"].default_value = 1.0
                mix.inputs[6].default_value = (tinta[0], tinta[1], tinta[2], 1.0)
                nt.links.new(mix.inputs[7], sorgente)
                nt.links.new(base, mix.outputs[2])
            else:
                c = base.default_value
                base.default_value = (c[0] * tinta[0], c[1] * tinta[1],
                                      c[2] * tinta[2], 1.0)
            # e lo smalto perde il lucido, che e' meta' di quello che lo fa vecchio
            r = bsdf.inputs["Roughness"]
            r.default_value = max(0.38, r.default_value)
    return pezzi


def sanitari():
    """Monta i modelli scaricati; dove mancano mette il segnaposto e lo dice."""
    fatti = {"Wc": wc_segnaposto, "Bidet": bidet_segnaposto,
             "Lavabo": lavabo_segnaposto}
    for (cartella, quale, gradi, alto, come_si_chiama) in SANITARI:
        via = os.path.join(ESTERNI, cartella, "scene.gltf")
        x0, z0, x1, z1, _h = IMPRONTE[quale]
        # BOCCIATO DA `pareggia_ceramica.py`: si torna al segnaposto. Un modello
        # sbagliato che resta montato e' peggio di un segnaposto - il segnaposto si
        # vede che e' provvisorio, il modello sbagliato sembra una scelta.
        bocciato = os.path.exists(os.path.join(ESTERNI, cartella, "DA_SOSTITUIRE.txt"))
        if os.path.exists(via) and not bocciato:
            pezzi = posa_modello(via, (x0, z0, x1, z1, alto), gradi=gradi)
            # LE MAPPE RIDOTTE, e la metallicita' a zero. Una ceramica non e' un
            # metallo: la mappa metallicRoughness dei sanitari, presa com'e', la
            # farebbe specchiare, e in un bagno chiuso lo specchio e' nero.
            usa_le_ridotte(pezzi, os.path.dirname(via), metallico=0.0)
            if quale in INVECCHIARE:
                ingiallisci(pezzi, COLORI["CeramicaVecchia"])
                print("  %-8s dal modello scaricato, invecchiato qui" % quale)
            else:
                print("  %-8s dal modello scaricato" % quale)
        else:
            fatti[quale]()
            if bocciato:
                mancanti.append("%s (%s) - il modello scaricato e' stato BOCCIATO, "
                                "vedi %s/DA_SOSTITUIRE.txt" % (quale, come_si_chiama,
                                                               cartella))
            else:
                mancanti.append("%s (%s) - manca %s" % (quale, come_si_chiama, via))
        if quale == "Lavabo":
            rubinetto_lavabo(0.80 if os.path.exists(via) else 0.86)
            print("  %-8s SEGNAPOSTO: il modello non c'e' ancora" % quale)


def prova_ingiallisci():
    """`ingiallisci` scattera' fra giorni, quando il bidet sara' stato scaricato.

    Provata oggi, su un cubo di prova: si costruisce un materiale con la texture
    delle piastrelle, lo si invecchia e si controlla che il Base Color sia passato
    per un nodo Mix in MULTIPLY. Un pezzo di codice che nessuno esegue e' un pezzo di
    codice che non funziona, e questo qui non lo eseguirebbe nessuno fino al giorno
    in cui serve - cioe' il giorno peggiore per scoprire che sbaglia il nome di un
    socket.
    """
    from modellare import materiale
    mesh = bpy.data.meshes.new("_provaMesh")
    o = bpy.data.objects.new("_prova", mesh)
    bpy.context.collection.objects.link(o)
    m = materiale("PiastrelleMuro").copy()
    m.name = "_provaMat"
    o.data.materials.append(m)
    ingiallisci([o], (0.5, 0.4, 0.3))
    base = None
    for n in m.node_tree.nodes:
        if n.type == "BSDF_PRINCIPLED":
            base = n.inputs["Base Color"]
    esito = []
    if base is None or not base.is_linked:
        esito.append("ingiallisci: il Base Color non e' rimasto collegato")
    else:
        nodo = base.links[0].from_node
        if nodo.type != "MIX" or nodo.blend_type != "MULTIPLY":
            esito.append("ingiallisci: davanti al Base Color c'e' %s, non un Mix "
                         "in MULTIPLY" % nodo.type)
        elif tuple(round(v, 3) for v in nodo.inputs[6].default_value)[:3] != (0.5, 0.4, 0.3):
            esito.append("ingiallisci: la tinta non e' finita nel socket giusto")
    bpy.data.objects.remove(o, do_unlink=True)
    return esito


def quanto_e_chiara(mappa):
    """La luminosita' media di un'immagine, su 255 e IN sRGB.

    Il Python di Blender non ha PIL, quindi si legge con Blender - e li' `pixels`
    restituisce valori LINEARI, perche' e' quello che serve a un motore di render.
    Mediare quelli e confrontarli con i numeri di `pareggia_ceramica.py`, che legge i
    byte del file, darebbe due misure diverse della stessa immagine: la media di una
    ceramica chiara scenderebbe di una quarantina di livelli e il controllo
    accuserebbe un difetto che non c'e'. Ogni pixel si riporta in sRGB PRIMA di
    mediare.

    E NON SI RIDIMENSIONA L'IMMAGINE. Il primo tentativo la portava a 64x64 per
    fare in fretta, e misurava 234 dove `pareggia_ceramica.py` misura 212 sulla
    stessa mappa: `img.scale()` media in spazio LINEARE, e la media lineare di
    valori sparsi, riportata in sRGB, viene piu' chiara della media dei valori sRGB.
    Il controllo accusava due ceramiche perfettamente pareggiate. Si campiona invece
    un pixel ogni cento, che e' altrettanto veloce e non tocca i valori.
    """
    import array
    img = bpy.data.images.load(mappa, check_existing=False)
    # NON-COLOR, E POI NESSUNA CONVERSIONE. Cosi' `pixels` restituisce i byte del
    # file normalizzati, che e' esattamente quello che legge PIL dall'altra parte.
    # Lasciandola in sRGB e riconvertendo a mano la stessa mappa misurava 234 invece
    # di 212 - una conversione applicata due volte - e il controllo accusava due
    # ceramiche perfettamente pareggiate.
    img.colorspace_settings.name = "Non-Color"
    w, h = img.size
    buf = array.array("f", [0.0]) * (w * h * 4)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    somma = 0.0
    n = 0
    for i in range(0, w * h, 97):
        for c in buf[i * 4:i * 4 + 3]:
            somma += max(0.0, min(1.0, c))
            n += 1
    return somma / max(1, n) * 255.0


def ceramiche_pari():
    """I sanitari montati devono essere lo STESSO bianco.

    E' il controllo che nasce da una stanza in cui tre ceramiche prese da tre autori
    stavano a 227, 174 e 130 su 255. Nessuna delle tre era sbagliata da sola: era
    sbagliato averle insieme, e a occhio si vedeva solo che "qualcosa stona". Adesso
    `tools/pareggia_ceramica.py` le porta tutte a un bianco solo, e questo controllo
    verifica che ci siano rimaste - perche' un modello aggiunto domani, o uno
    riscaricato che sovrascrive la mappa corretta, tornerebbe a stonare in silenzio.
    """
    # IL BERSAGLIO SI LEGGE DAL SORGENTE, non importando il modulo:
    # `pareggia_ceramica.py` usa PIL, e il Python di Blender PIL non ce l'ha. Una
    # riga di regex evita di duplicare il numero in due file, che e' il modo sicuro
    # di ritrovarseli diversi fra sei mesi.
    import re
    sorgente = io.open(os.path.join(QUI, "pareggia_ceramica.py"),
                       encoding="utf-8").read()
    bersaglio = float(re.search(r"^BERSAGLIO = ([\d.]+)", sorgente, re.M).group(1))

    guai = []
    for (cartella, quale, _g, _a, _n) in SANITARI:
        mappa = os.path.join(ESTERNI, cartella, "textures", "color.jpg")
        if not os.path.exists(mappa):
            continue
        if os.path.exists(os.path.join(ESTERNI, cartella, "DA_SOSTITUIRE.txt")):
            continue                     # gia' bocciato, e gia' detto
        grigio = quanto_e_chiara(mappa)
        print("  %-8s ceramica a %.0f su 255" % (quale, grigio))
        if abs(grigio - bersaglio) > 10.0:
            guai.append("%s: la ceramica sta a %.0f invece dei %.0f degli altri - "
                        "rilancia tools/pareggia_ceramica.py"
                        % (quale, grigio, bersaglio))
    return guai


# --- costruzione -------------------------------------------------------------
pulisci()
riveste()
listello()
pavimento()
armadio()
pensile()
sopra_il_lavabo()
portasalviette()
termosifone()
sanitari()

_prova = prova_ingiallisci()
oggetti = finisci(morbidi=("Ceramica", "CeramicaVecchia", "Inox"))

# IL GUSCIO NON HA IMPRONTA, ED E' GIUSTO COSI'. Rivestimento, listello e pavimento
# non sono arredi: sono uno strato di un centimetro incollato a superfici che la
# collisione ce l'hanno gia'. Dichiararli fra gli arredi darebbe quattro strisce che
# si sovrappongono a ogni sanitario addossato al muro - cioe' a tutti - e il
# controllo degli arredi si riempirebbe di guasti inventati.
GUSCIO = ("PiastrelleMuro", "PiastrellePav", "Listello")
problemi = _prova + ceramiche_pari() + verifica_impronte(
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

# QUANTO PESA, RILETTO DAL FILE SCRITTO. Il bagno e' arrivato a 33 MB - piu'
# dell'intero edificio - perche' i tre sanitari restavano attaccati alle loro mappe
# a 4096 mentre le versioni ridotte stavano nella cartella accanto senza che nessuno
# le usasse. Non se ne accorgeva niente: il modello era giusto, i controlli passavano,
# e il numero lo si vede solo guardando la cartella. Adesso lo guarda lui.
PESO_MASSIMO = 20.0
_mb = os.path.getsize(USCITA) / 1048576.0
print("  il modello pesa %.1f MB" % _mb)
if _mb > PESO_MASSIMO:
    print("")
    print("ATTENZIONE: %.1f MB contro i %.1f ammessi - quasi sempre e' una mappa"
          % (_mb, PESO_MASSIMO))
    print("  presa da fuori e rimasta a piena risoluzione: vedi usa_le_ridotte().")
    sys.exit(1)

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
scatta("bagno.png", (5.90, 1.62, 8.80), (8.10, 0.75, 7.05), lente=24.0)
# il lavabo con lo specchio, dal centro della stanza
scatta("bagno-lavabo.png", (6.60, 1.62, 8.10), (5.05, 1.20, 8.55), lente=24.0)
# l'armadio e la finestra
scatta("bagno-armadio.png", (5.60, 1.62, 7.20), (7.90, 1.10, 9.20), lente=22.0)
# il listello da vicino: e' il pezzo che data la stanza, va guardato
scatta("bagno-listello.png", (6.30, 1.55, 7.60), (8.10, 1.52, 7.30), lente=45.0)
