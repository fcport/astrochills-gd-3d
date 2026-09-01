# -*- coding: utf-8 -*-
"""LA RADIOLINA della cucina, staccata dal muro a cui era attaccata.

    "D:/programs/blender5/blender.exe" --background --python tools/radiolina_blender.py

Produce assets/models/radiolina.glb.

PERCHE' ESISTE QUESTO FILE. La radiolina c'era gia': la disegnava
`cucina_blender.py` con quattro primitive, sul piano contro il paraschizzi, ed era
FUSA nella mesh della stanza. Fusa vuol dire che non e' un oggetto - e' un rilievo
del muro, e non la si puo' prendere in mano nemmeno volendo. Federico: «sarebbe
bello renderle un po' tutte prendibili».

QUELLO CHE CAMBIA E' DOVE STA, NON COM'E' FATTA: le quote e le proporzioni sono le
stesse che aveva nella cucina, riportate qui attorno a un'origine propria. Una
radiolina da cucina del 1999 e' una scatola di plastica da ventidue centimetri con
un altoparlante forato, una manopola sul fianco e l'antenna telescopica: quattro
pezzi, ed erano gia' giusti.

L'ORIGINE VA SOTTO E AL CENTRO IN PIANTA, come per tutto quello che si prende in
mano (vedi `prop_blender.py`): chi la colloca scrive la quota del piano e non deve
sottrarre mezza altezza.

L'ANTENNA RESTA FUORI DALLA COLLISIONE, e va detto perche' e' una scelta: e' un
filo da cinque millimetri lungo ventotto centimetri, e dargli un corpo vorrebbe
dire una radiolina che non si appoggia da nessuna parte perche' l'antenna tocca
prima. Un'antenna che compenetra uno stipite e' meno falsa di una radio che
levita.
"""
import os
import sys

import bpy

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
from modellare import (cilindro, cilindro_orizz, esporta, finisci,   # noqa: E402
                       lampada, prepara_render, pulisci, scatola)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "radiolina.glb")
PROVINO = os.path.join(RADICE, "_confronto", "15_radiolina.png")

# --- le quote, in metri, quelle che aveva in cucina --------------------------
LARGA = 0.22
ALTA = 0.115
FONDA = 0.09
ANTENNA = 0.285      # sopra la cassa: telescopica, tirata su
ANTENNA_R = 0.005


def costruisci():
    hx, hz = LARGA / 2, FONDA / 2
    # La cassa. Il FRONTE guarda +z, che e' il verso in cui guardava contro il
    # paraschizzi: cosi' chi la posa sa da che parte gira il muso.
    scatola("Plastica", -hx, hx, 0.0, ALTA, -hz, hz)
    # L'altoparlante: una piastra scura incassata sul fronte, a sinistra.
    scatola("Schermo", -hx + 0.015, -hx + 0.115, 0.025, 0.095, hz, hz + 0.005)
    # La manopola del volume, sul fronte a destra.
    cilindro_orizz("Metallo", hx - 0.055, 0.060, hz, "z", 0.012, 0.020, 12)
    # L'antenna, sul dorso a destra.
    cilindro("Metallo", hx - 0.020, -hz + 0.055, ALTA, ALTA + ANTENNA, ANTENNA_R, 8)


print("")
pulisci()
costruisci()
pezzi = finisci(morbidi=("Metallo",))
facce = sum(len(o.data.polygons) for o in pezzi)
print("  la radiolina e' fatta di %d facce in %d pezzi" % (facce, len(pezzi)))
print("  ingombro %.3f x %.3f m in pianta, alta %.3f con l'antenna (%.3f la cassa)"
      % (LARGA, FONDA, ALTA + ANTENNA, ALTA))
if facce > 600:
    print("\nATTENZIONE: %d facce per una radiolina sono troppe." % facce)
    sys.exit(1)

esporta(USCITA)

os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
scatta = prepara_render(800, 800, cielo=(0.18, 0.19, 0.21))
# Luci basse: e' un oggetto da venti centimetri. Vedi il provino della camera CCD,
# dove le stesse potenze copiate da un oggetto grande hanno bruciato il nero.
lampada("Chiave", (0.30, 0.35, 0.35), 0.5, tipo="AREA", dimensione=0.5)
lampada("Riempimento", (-0.30, 0.18, 0.25), 0.10)
scatta(PROVINO, (0.20, 0.22, 0.55), (0.0, 0.10, 0.0), lente=45.0)
print("\n  provino: %s" % PROVINO)
