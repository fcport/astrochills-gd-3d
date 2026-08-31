# -*- coding: utf-8 -*-
"""Da che parte guarda un sanitario preso da fuori, misurato invece che indovinato.

    "D:/programs/blender5/blender.exe" --background --python tools/verso_sanitari.py

Un modello scaricato non conosce il nostro nord: va ruotato, e l'angolo giusto si
trova per tentativi guardando un render alla volta - tre modelli per quattro angoli
fa dodici render e mezz'ora buttata, con il rischio di fermarsi al primo che "sembra
giusto".

Qui l'angolo si MISURA. Un sanitario addossato ha una faccia piatta contro il muro:
si contano i vertici che cadono a filo di ciascuno dei quattro lati dell'impronta, e
il lato che ne raccoglie di piu' e' il retro. Poi si confronta con il muro a cui
quel pezzo e' addossato in pianta, e l'angolo che li fa combaciare e' quello.

Stampa una tabella. I numeri che ne escono vanno in SANITARI dentro bagno_blender.py.
"""
import os
import sys

import bpy
from mathutils import Vector

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
from geometria import ARREDI_BAGNO   # noqa: E402
from modellare import posa_modello, pulisci   # noqa: E402

RADICE = os.path.dirname(QUI)
ESTERNI = os.path.join(RADICE, "assets", "models", "esterni")
IMPRONTE = {n: (x0, z0, x1, z1, h) for (n, x0, z0, x1, z1, h) in ARREDI_BAGNO}

# quale pezzo, quale cartella, e contro quale lato dell'impronta sta il muro
DA_PROVARE = [
    ("Wc", "wc_bagno", "est"),
    ("Bidet", "bidet_bagno", "est"),
    ("Lavabo", "lavabo_bagno", "ovest"),
    ("Termo", "termosifone_bagno", "sud"),
]

# di quanto si considera "a filo" del lato
FILO = 0.06


def ingombro(pezzi):
    """Quanto misura davvero il modello dopo essere stato posato.

    SERVE QUANTO IL CONTEGGIO DEI VERTICI, e per il water serviva di piu': i suoi
    conteggi davano zero contro est e contro ovest a TUTTE E QUATTRO le rotazioni, e
    sembrava un modello senza retro. Non lo era: `posa_modello` scala sull'altezza e
    poi rimpicciolisce ancora finche' l'ingombro in pianta ci sta, quindi un pezzo
    orientato male viene ridotto e non arriva piu' a nessun muro. Il numero che lo
    dice e' la misura, non il conteggio.
    """
    punti = [o.matrix_world @ v.co for o in pezzi
             if o.type == "MESH" and o.data is not None for v in o.data.vertices]
    if not punti:
        return (0.0, 0.0, 0.0)
    return (max(p.x for p in punti) - min(p.x for p in punti),
            max(p.z for p in punti) - min(p.z for p in punti),
            max(-p.y for p in punti) - min(-p.y for p in punti))


def dov_e_la_cima(pezzi):
    """Da che parte pende la META' ALTA del modello, in x di gioco.

    E' il criterio che distingue 90 da 270 gradi quando il conteggio al muro non
    distingue niente - cioe' per il water, che con la sua cassetta non arriva mai
    ai lati dell'impronta. Un water ha la cassetta in alto e DIETRO: se la meta'
    alta pende verso il muro il verso e' giusto, se pende verso la stanza il water
    e' girato e la cassetta guarda chi entra.

    Torna lo scarto fra il baricentro dei vertici alti e quello di tutti: positivo
    verso est.
    """
    punti = [o.matrix_world @ v.co for o in pezzi
             if o.type == "MESH" and o.data is not None for v in o.data.vertices]
    if not punti:
        return 0.0
    zmin = min(p.z for p in punti)
    zmax = max(p.z for p in punti)
    alti = [p for p in punti if p.z > zmin + (zmax - zmin) * 0.62]
    if not alti:
        return 0.0
    return (sum(p.x for p in alti) / len(alti)) - (sum(p.x for p in punti) / len(punti))


def conta(pezzi, impronta):
    """Quanti vertici stanno a filo di ciascuno dei quattro lati."""
    x0, z0, x1, z1, _h = impronta
    quanti = {"ovest": 0, "est": 0, "nord": 0, "sud": 0}
    for o in pezzi:
        if o.type != "MESH" or o.data is None:
            continue
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            gx, gz = p.x, -p.y
            if gx - x0 < FILO:
                quanti["ovest"] += 1
            if x1 - gx < FILO:
                quanti["est"] += 1
            if gz - z0 < FILO:
                quanti["nord"] += 1
            if z1 - gz < FILO:
                quanti["sud"] += 1
    return quanti


print("")
for (quale, cartella, muro) in DA_PROVARE:
    via = os.path.join(ESTERNI, cartella, "scene.gltf")
    if not os.path.exists(via):
        print("%-8s manca: %s" % (quale, via))
        continue
    righe = []
    for gradi in (0.0, 90.0, 180.0, 270.0):
        pulisci()
        pezzi = posa_modello(via, IMPRONTE[quale], gradi=gradi)
        q = conta(pezzi, IMPRONTE[quale])
        totale = max(1, sum(q.values()))
        righe.append((gradi, q, q[muro] / float(totale), ingombro(pezzi),
                      dov_e_la_cima(pezzi)))
    meglio = max(righe, key=lambda r: r[2])
    print("%-8s addossato a %s" % (quale, muro))
    x0, z0, x1, z1, alt = IMPRONTE[quale]
    print("   impronta: %.2f (x) x %.2f (z), alta %.2f" % (x1 - x0, z1 - z0, alt))
    for (gradi, q, quota, ing, cima) in righe:
        segno = "  <-- e' questo" if gradi == meglio[0] else ""
        verso = "verso il muro" if (cima > 0) == (muro == "est") else "verso la stanza"
        print("   %3.0f gradi   al muro %2.0f%%   largo %.2f  alto %.2f  fondo %.2f"
              "   la cima pende %s (%+.3f)%s"
              % (gradi, quota * 100, ing[0], ing[1], ing[2], verso, cima, segno))
    print("")
