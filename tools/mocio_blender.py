# -*- coding: utf-8 -*-
"""IL MOCIO del magazzino (D-251): quello che pulisce il caffe' rovesciato.

    "D:/programs/blender5/blender.exe" --background --python tools/mocio_blender.py

Produce assets/models/mocio.glb. Vuole prima:

    python tools/prendi_modello.py mocio

QUALE, E PERCHE' QUELLO - vedi la voce `mocio` in `prendi_modello.py`: «Pair of mops» di
Sousinho, CC-BY-4.0, scelto da Federico fra i due mocio a frange trovati. Il credito sta in
`CREDITI.md`.

IL SET NE PORTA DUE, E SI TIENE IL PULITO. Ogni mocio sono due mesh, le frange e il manico, e si
riconoscono dal MATERIALE - `T_mop_clean` contro `T_mop_dirty` - perche' i nomi dei nodi
(`SM_Mop_1_2`, `SM_Mop_1.001_3`) non dicono quale sia quale.

IL MANICO SI RADDRIZZA. Nel modello le frange stanno piatte a terra e il manico pende di tredici
gradi, come un mocio lasciato in piedi. In gioco il manico e' l'asse del collisore e della mano
(`mocio.gd`, `PRESA`): lasciato storto dentro il modello, a un metro d'altezza il bastone che si
vede starebbe venti centimetri piu' in la' di quello che si mira. Si gira tutto il mocio finche'
il manico e' verticale, e le frange restano inclinate di quanto pendeva; appoggiato al muro del
magazzino dalla stessa parte (`gen_blockout.py`, `MOCIO_PENDE`) tornano quasi piatte.

L'ALTEZZA E' DICHIARATA QUI, come per la moka: `mocio.tscn` e `gen_blockout.py` contano su un
metro e trenta, e un modello di fuori arriva con la scala di chi l'ha fatto.

L'ORIGINE VA IN FONDO ALLE FRANGE, SULL'ASSE DEL MANICO: e' il punto che tocca la macchia, e
quello da cui `PRESA` misura dove sta la mano.
"""
import os
import sys

import bpy
from mathutils import Matrix, Vector

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
from modellare import (esporta, lampada, prepara_render,   # noqa: E402
                       pulisci, usa_le_ridotte)

RADICE = os.path.dirname(QUI)
CARTELLA = os.path.join(RADICE, "assets", "models", "esterni", "mocio")
MODELLO = os.path.join(CARTELLA, "scene.gltf")
USCITA = os.path.join(RADICE, "assets", "models", "mocio.glb")
PROVINO = os.path.join(RADICE, "_confronto", "26_mocio.png")

ALTO = 1.30
TENUTO = "T_mop_clean"

# LE FACCE: quasi tutte sono delle frange, che nel modello sono ottomilaquattrocento triangoli di
# fili. Tremila come la moka: a un metro di distanza e con la grana della PS1 un filo in piu' non
# si vede, e il mocio non ha ragione di costare piu' di una caffettiera.
BUDGET = 3000


def vertici(o):
    return [o.matrix_world @ v.co for v in o.data.vertices]


def decima(o, quante):
    prima = len(o.data.polygons)
    if prima <= quante:
        return
    bpy.context.view_layer.objects.active = o
    m = o.modifiers.new("Decima", "DECIMATE")
    m.decimate_type = "COLLAPSE"
    m.ratio = float(quante) / prima
    bpy.ops.object.modifier_apply(modifier=m.name)
    print("  %-8s %5d -> %4d facce" % (o.name, prima, len(o.data.polygons)))


if not os.path.exists(MODELLO):
    print("\nMANCA il modello scaricato: %s" % MODELLO)
    print("  lancia prima:  python tools/prendi_modello.py mocio")
    sys.exit(1)

print("")
pulisci()
bpy.ops.import_scene.gltf(filepath=MODELLO)
pezzi = [o for o in bpy.data.objects if o.type == "MESH"
         and any(s.material is not None and s.material.name.startswith(TENUTO)
                 for s in o.material_slots)]
if len(pezzi) != 2:
    print("\nATTENZIONE: col materiale %s ci sono %d pezzi invece di due: %s"
          % (TENUTO, len(pezzi), ", ".join(o.name for o in pezzi)))
    sys.exit(1)

# LA POSIZIONE DI MONDO SI CUOCE DENTRO LA MESH PRIMA DI BUTTARE I GENITORI. I pezzi stanno sotto
# tre nodi vuoti con le loro rotazioni: tolto il genitore, un figlio tiene la trasformata LOCALE,
# e il manico si ritroverebbe coricato altrove.
for o in pezzi:
    o.data.transform(o.matrix_world)
    o.parent = None
    o.matrix_world = Matrix.Identity(4)
for o in list(bpy.data.objects):
    if o not in pezzi:
        bpy.data.objects.remove(o, do_unlink=True)

# Il manico e' il pezzo lungo: piu' di un metro in una direzione.
def lungo(o):
    vs = vertici(o)
    return max(max(v[i] for v in vs) - min(v[i] for v in vs) for i in range(3))

manico, frange = sorted(pezzi, key=lungo, reverse=True)
manico.name, frange.name = "Manico", "Frange"

# --- il manico verticale ------------------------------------------------------------
# L'ASSE SI MISURA DAI DUE CAPI, non da tutto il bastone: si prendono i vertici entro tre
# centimetri dal punto piu' alto e dal piu' basso, e l'asse va dal centro dei primi a quello dei
# secondi. Il pomello in cima e il raccordo in fondo sono simmetrici attorno all'asse, quindi i
# centri ci cadono sopra.
vs = vertici(manico)
alto_, basso_ = max(v.z for v in vs), min(v.z for v in vs)
cima = sum((v for v in vs if v.z > alto_ - 0.03), Vector()) / len([v for v in vs if v.z > alto_ - 0.03])
fondo = sum((v for v in vs if v.z < basso_ + 0.03), Vector()) / len([v for v in vs if v.z < basso_ + 0.03])
asse = (cima - fondo).normalized()
pendeva = asse.angle(Vector((0.0, 0.0, 1.0)))
print("  il manico pendeva di %.1f gradi, verso x %+.2f y %+.2f (di Blender)"
      % (pendeva * 57.2958, asse.x, asse.y))
giro = asse.rotation_difference(Vector((0.0, 0.0, 1.0))).to_matrix().to_4x4()
for o in pezzi:
    o.data.transform(giro)

# --- sull'origine, e all'altezza dichiarata -------------------------------------------
vs = vertici(manico)
cx = sum(v.x for v in vs) / len(vs)
cy = sum(v.y for v in vs) / len(vs)
tutti = [v for o in pezzi for v in vertici(o)]
sotto = min(v.z for v in tutti)
for o in pezzi:
    o.data.transform(Matrix.Translation((-cx, -cy, -sotto)))
alta = max(v.z for o in pezzi for v in vertici(o))
for o in pezzi:
    o.data.transform(Matrix.Scale(ALTO / alta, 4))
    o.data.update()
print("  scalato da %.3f a %.3f m (x%.3f)" % (alta, ALTO, ALTO / alta))

decima(frange, BUDGET - len(manico.data.polygons))
usate = usa_le_ridotte(pezzi, CARTELLA, metallico=0.0)
print("  texture ridotte agganciate: %d" % usate)

# --- il referto: le misure che servono al collisore ---------------------------------
vf = vertici(frange)
vm = vertici(manico)
facce = sum(len(o.data.polygons) for o in pezzi)
print("  alto %.3f m, %d facce" % (max(v.z for o in pezzi for v in vertici(o)), facce))
print("  frange: larghe %.3f x %.3f, da z %.3f a %.3f"
      % (max(v.x for v in vf) - min(v.x for v in vf), max(v.y for v in vf) - min(v.y for v in vf),
         min(v.z for v in vf), max(v.z for v in vf)))
print("  manico: da z %.3f a %.3f, largo %.3f x %.3f"
      % (min(v.z for v in vm), max(v.z for v in vm),
         max(v.x for v in vm) - min(v.x for v in vm), max(v.y for v in vm) - min(v.y for v in vm)))
if facce > BUDGET + 50:
    print("\nATTENZIONE: %d facce per un mocio sono troppe." % facce)
    sys.exit(1)

esporta(USCITA)

os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
scatta = prepara_render(700, 1000, cielo=(0.18, 0.19, 0.21))
# Luci da oggetto di un metro e mezzo guardato da due: sei volte quelle della roba da tavolo.
lampada("Chiave", (1.2, 2.0, 1.4), 6.0, tipo="AREA", dimensione=1.5)
lampada("Riempimento", (-1.2, 1.0, 1.0), 1.5)
scatta(PROVINO, (1.5, 1.0, 1.9), (0.0, 0.62, 0.0), lente=35.0)
print("\n  provino: %s" % PROVINO)
