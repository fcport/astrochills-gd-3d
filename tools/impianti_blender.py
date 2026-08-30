# -*- coding: utf-8 -*-
"""L'impianto luce: gli apparecchi che fanno la luce e le placche che la comandano.

    "D:/programs/blender5/blender.exe" --background --python tools/impianti_blender.py

FINO A IERI LA LUCE ERA MAGIA. Dieci OmniLight3D a mezz'aria in gen_blockout.py:
nessuna lampada sopra, nessun interruttore su un muro. In un gioco che si regge
sull'essere un posto vero, e' l'unica cosa che non aveva una causa.

Qui non si sceglie niente: le posizioni stanno in geometria (PUNTI_LUCE e
punti_interruttori), che le da' anche al generatore del blockout. Se lampada e
OmniLight si separassero, sarebbe perche' leggono due liste diverse - e infatti
ne leggono una.

Le plafoniere vengono da fuori (Poly Haven, CC0): un apparecchio a due tubi con la
gabbia, che e' quello che sta sui soffitti di un edificio pubblico italiano. Le
placche invece si fanno qui: sono otto centimetri di geometria e nessun modello di
fuori vale il suo peso in file.

Produce assets/models/impianti.glb.
"""
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
from geometria import (H, H_PLAFONIERA, H_INTERRUTTORE, L_PLACCA, A_PLACCA,   # noqa: E402
                       SP_PLACCA, punti_luce, punti_applique, punti_interruttori,
                       verifica_interruttori)
from modellare import (esporta, finisci, lampada, prepara_render,   # noqa: E402
                       pulisci, scatola)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "impianti.glb")
# La plafoniera esce DA SOLA, in un file suo, e non insieme alle placche.
# Ragione: nel blockout va istanziata dieci volte, e ogni copia deve stare sotto
# il nodo che l'interruttore spegne INSIEME alla sua OmniLight. Dentro un glb
# unico le dieci lampade diventerebbero due mesh sole (una per materiale, e' cosi'
# che si esporta qui), e spegnerne una vorrebbe dire spegnerle tutte - oppure
# lasciare acceso un diffusore emissivo sopra una stanza al buio, che e' peggio
# di non avere la lampada.
UNA_PLAFONIERA = os.path.join(RADICE, "assets", "models", "plafoniera.glb")
APPLIQUE = os.path.join(RADICE, "assets", "models", "applique_rossa.glb")
RENDER = os.path.join(RADICE, "_bmad-output", "planning-artifacts", "gdds",
                      "gdd-astrochills-gd-3d-2026-08-24")
# La plafoniera: 1,28 x 0,28, alta 9 cm. E' la misura di un apparecchio a due tubi
# da 36 W, quello che sta sul soffitto di ogni ufficio pubblico italiano.
#
# NON VIENE DA FUORI, E L'HO PROVATO. Poly Haven ha mounted_fluorescent_lights, ed
# e' un TUBO NUDO da quattro centimetri con due staffe: montato a tre metri sparisce,
# e soprattutto non ha un diffusore, cioe' non ha la superficie che si accende. Il
# pezzo che conta di una plafoniera e' proprio quello: la faccia luminosa che dice
# da dove viene la luce. Otto scatole fatte qui la danno, un modello di fuori no.
L_PLAF, P_PLAF, H_PLAF = 1.28, 0.28, 0.09


def plafoniera(diffusore="Neon"):
    """UNA plafoniera, in origine, distesa lungo X e con il fondo a quota zero.

    Carcassa di lamiera, testate, e il diffusore prismatico che sporge sotto. Il
    diffusore e' l'unico pezzo emissivo, ed e' anche l'unico che si vede da sotto:
    da tre metri della carcassa si intravede il bordo e basta.

    Sta nell'origine perche' il posto glielo da' il blockout, che ne mette una per
    ogni punto di `PUNTI_LUCE` con dentro la sua luce.
    """
    a_, b_ = L_PLAF / 2, P_PLAF / 2
    scatola("Lamiera", -a_, a_, 0.035, H_PLAF, -b_, b_)          # cassonetto
    for (x0, x1) in ((-a_, -a_ + 0.045), (a_ - 0.045, a_)):      # testate
        scatola("Lamiera", x0, x1, 0.0, H_PLAF, -b_, b_)
    d = 0.045
    scatola(diffusore, -a_ + d, a_ - d, 0.0, 0.038, -b_ + 0.012, b_ - 0.012)


def applique():
    """L'apparecchio a parete della cupola: piastra, corpo e vetro rosso.

    NASCE ADDOSSATO AL MURO x=0 E SPORGE VERSO +X, con il centro del vetro a
    quota zero: il posto e la rotazione glieli da' il blockout, che ha la normale
    del muro. Le misure sono quelle di un apparecchio da esterno in fusione -
    sedici per ventisei, tredici di sporgenza - perche' e' quello che si mette in
    una sala telescopio, dove l'umidita' e' quella di fuori.

    IN CUPOLA NON C'E' SOFFITTO. Sopra c'e' la calotta, e la plafoniera che ci
    avevo messo pendeva a mezz'aria sotto la volta: si vedeva accendere una lampada
    sospesa nel vuoto in mezzo alla sala. Una luce di servizio in una sala
    telescopio sta a parete, sempre.
    """
    l, a = 0.080, 0.130          # semi-larghezza e semi-altezza
    scatola("Metallo", 0.0, 0.020, -a, a, -l, l)                       # piastra
    scatola("Metallo", 0.020, 0.115, -a, -a + 0.022, -l + 0.012, l - 0.012)
    scatola("Metallo", 0.020, 0.115, a - 0.022, a, -l + 0.012, l - 0.012)
    for zl in (-l + 0.012, l - 0.024):                                 # fianchi
        scatola("Metallo", 0.020, 0.115, -a + 0.022, a - 0.022, zl, zl + 0.012)
    # il vetro rosso: e' la faccia che si accende, e sporge appena dal telaio
    scatola("NeonRosso", 0.100, 0.128, -a + 0.020, a - 0.020,
            -l + 0.020, l - 0.020)
    # la gabbietta di protezione, due ferri in croce davanti al vetro
    for zl in (-0.026, 0.026):
        scatola("Metallo", 0.128, 0.136, -a + 0.014, a - 0.014, zl - 0.004, zl + 0.004)
    scatola("Metallo", 0.128, 0.136, -0.004, 0.004, -l + 0.014, l - 0.014)


def placche():
    """Gli interruttori: cornice svasata e un basculante bombato, in avorio.

    VECCHIO STILE, e vuol dire una cosa precisa: non una placca a moduli stretti
    come quelle di oggi, ma la cornice rettangolare con dentro UN tasto grande -
    e il tasto non e' piatto, e' bombato in due falde. E' quella forma a farla
    leggere come un interruttore vecchio, insieme al colore: l'avorio ingiallito,
    non il bianco.

    A 1,45 e non a 1,10, che sarebbe la quota vera. L'occhio del giocatore sta a
    1,65 e il raggio di interazione va dritto: a quota da manuale bisognava
    accovacciarsi per accendere la luce.
    """
    for (nome, x, z, nx, nz) in punti_interruttori():
        y = H_INTERRUTTORE

        def pezzo(mat, semi_lungo, y0, y1, da, a_):
            """da/a_ = quote lungo la normale, misurate dalla faccia del muro."""
            if nz:
                scatola(mat, x - semi_lungo, x + semi_lungo, y0, y1,
                        z + nz * da, z + nz * a_)
            else:
                scatola(mat, x + nx * da, x + nx * a_, y0, y1,
                        z - semi_lungo, z + semi_lungo)

        # la cornice, in due gradini: quello a muro largo, quello davanti rientrato
        pezzo("Avorio", L_PLACCA / 2, y - A_PLACCA / 2, y + A_PLACCA / 2, 0.0, 0.006)
        pezzo("Avorio", L_PLACCA / 2 - 0.007, y - A_PLACCA / 2 + 0.007,
              y + A_PLACCA / 2 - 0.007, 0.006, 0.011)
        # il vano scuro dietro il tasto: senza, avorio su avorio non fa ombra e
        # la placca resta un rettangolo liscio
        pezzo("Schermo", L_PLACCA / 2 - 0.015, y - 0.043, y + 0.043, 0.011, 0.013)
        # il basculante, in due falde: sopra rientra, sotto sporge. E' la
        # differenza fra un tasto e un adesivo, e si vede da un metro.
        for (ya, yb, da, a_) in ((y + 0.002, y + 0.044, 0.013, SP_PLACCA - 0.004),
                                 (y - 0.044, y + 0.002, 0.013, SP_PLACCA)):
            pezzo("Avorio", L_PLACCA / 2 - 0.020, ya, yb, da, a_)
        # LA SPIA. Al buio la placca non si vede: avorio su intonaco avorio, alta
        # quindici centimetri, in una stanza dove non arriva luce. Questa e' la
        # risposta che davano gli interruttori veri, e la danno ancora.
        pezzo("Spia", 0.010, y - 0.024, y - 0.008, SP_PLACCA - 0.002, SP_PLACCA + 0.002)
        yield nome


# --- costruzione: prima la plafoniera da sola, poi le placche -----------------
# PRIMA DI TUTTO SI SVUOTA LA SCENA. Blender parte con un cubo da due metri
# nell'origine, e senza questa riga finisce nel .glb: dieci plafoniere sono
# diventate dieci lastroni azzurri sospesi sopra le stanze. Gli altri quattro
# modellatori la chiamano da sempre; questo era nuovo e se l'era persa.
pulisci()
plafoniera()
finisci(morbidi=())
esporta(UNA_PLAFONIERA)
pulisci()

# l'apparecchio a parete della cupola. File a parte e non un colore cambiato in
# Godot: il materiale porta anche l'emissione, e cambiarla nel motore vorrebbe
# dire riscrivere a mano un materiale che qui esiste gia'.
applique()
finisci(morbidi=("Metallo",))
esporta(APPLIQUE)
pulisci()   # e non una rimozione a mano: finisci() tiene i suoi bmesh in un
            # registro globale, e cancellare gli oggetti senza svuotarlo lascia
            # la seconda passata a lavorare su mesh che non esistono piu'

_nomi = list(placche())
oggetti = finisci(morbidi=())
print()
for o in oggetti:
    print("  %-12s %5d facce" % (o.name, len(o.data.polygons)))
print("  1 plafoniera (x%d) + 1 applique (x%d) nel blockout, %d placche: %s"
      % (len(punti_luce()), len(punti_applique()), len(_nomi), ", ".join(_nomi)))

# --- controlli ---------------------------------------------------------------
problemi = list(verifica_interruttori())
# nessuna plafoniera deve sfondare il solaio ne' scendere sulla testa: sotto
# H_PLAFONIERA - 10 cm ci si sbatte, sopra H sta dentro il cemento
# la plafoniera montata a soffitto non deve arrivare in testa: il suo fondo cade a
# H - H_PLAF, e sotto H_PLAFONIERA - 10 cm ci si sbatte
_fondo = H - H_PLAF
print("  plafoniera alta %.3f m: montata, il diffusore sta a %.2f m" % (H_PLAF, _fondo))
if _fondo < H_PLAFONIERA - 0.10:
    problemi.append("la plafoniera pende troppo: il diffusore cade a %.2f m" % _fondo)
_alto = max((o.matrix_world @ v.co).z for o in oggetti for v in o.data.vertices)
if _alto > H_INTERRUTTORE + A_PLACCA:
    problemi.append("una placca e' fuori quota: arriva a %.2f m" % _alto)

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
lampada("Sala", (10.80, 2.60, 3.00), 200.0, tipo="AREA", dimensione=2.0)
# per il render la plafoniera si rimette al suo posto: nel modello esportato non
# c'e' piu', ma questa immagine serve a guardare com'e' fatta montata
bpy.ops.import_scene.gltf(filepath=UNA_PLAFONIERA)
for _o in bpy.context.selected_objects:
    _o.location = (6.70, -2.50, H - H_PLAF)


def scatta(nome, posizione, mira, lente=28.0):
    scatta_su(os.path.join(RENDER, nome), posizione, mira, lente)


# LE CAMERE SEGUONO LA PLACCA, non un numero copiato. La placca si e' gia'
# spostata due volte - di quota e di faccia del muro - e le due volte il render
# ha continuato a inquadrare il muro vuoto dove stava prima.
_prima = dict((n, (x, z, nx, nz)) for (n, x, z, nx, nz) in punti_interruttori())
_x, _z, _nx, _nz = _prima["pc -> corridoio"]
scatta("impianti-interruttore.png",
       (_x + _nx * 0.75 + 0.30, H_INTERRUTTORE + 0.10, _z + _nz * 0.75 + 0.10),
       (_x, H_INTERRUTTORE, _z), lente=45.0)
# la plafoniera della sala di controllo, guardando in su
scatta("impianti-plafoniera.png", (6.90, 1.55, 3.40), (6.70, 2.95, 2.50), lente=24.0)
