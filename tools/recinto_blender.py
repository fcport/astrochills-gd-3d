# -*- coding: utf-8 -*-
"""La rete del recinto: un modulo di rete metallica e un palo, dalla rete di Poly Haven.

    "D:/programs/blender5/blender.exe" --background --python tools/recinto_blender.py

Serve prima: python tools/prendi_modello.py modular_chainlink_fence

IL RECINTO DELLE FOTO. Nelle foto del sito (Street View, marzo) il prato dell'osservatorio
e' chiuso da una rete metallica a maglia romboidale plastificata verde, alta un metro e
mezzo, su pali: la recinzione di un terreno pubblico. Il gioco aveva quattro muri grigi. La
rete e' `modular_chainlink_fence` di Poly Haven (CC0), che pero' e' alta due metri e mezzo,
da cantiere americano.

SI TAGLIA, NON SI SCHIACCIA. Scalata in altezza la maglia diventerebbe un rombo appiattito, e
la maglia e' proprio la cosa che si guarda: il pannello da due metri si taglia a ALTEZZA_M e
resta com'e'. Il palo invece e' un tubo, e schiacciato resta un tubo col suo tappo.
Il verde lo mette il gioco (`world/recinto.gd`), moltiplicato sulla zincatura.

SCRIVE assets/models/recinto.glb con due oggetti: `Rete`, il pannello da LARGO_M con lo
spigolo in basso a sinistra nell'origine e la larghezza lungo +X, e `Palo`, con la base
nell'origine.
"""
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
SORGENTE = os.path.join(RADICE, "assets", "models", "esterni", "modular_chainlink_fence",
                        "modular_chainlink_fence_1k.gltf")
OPACITA = os.path.join(os.path.dirname(SORGENTE), "textures",
                       "modular_chainlink_fence_wire_opacity_1k.png")
USCITA = os.path.join(RADICE, "assets", "models", "recinto.glb")

# L'altezza della rete e del palo, in metri: quella delle foto, un palmo sopra un uomo seduto.
ALTEZZA_M = 1.5
PALO_M = 1.6
# La larghezza del pannello doppio del modello: `world/recinto.gd` ha lo stesso numero
# (MODULO), e questo script si ferma se il modello non la rispetta.
LARGO_M = 1.91

if not os.path.exists(SORGENTE) or not os.path.exists(OPACITA):
    print("MANCA %s" % SORGENTE)
    print("  lancia prima: python tools/prendi_modello.py modular_chainlink_fence")
    sys.exit(1)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SORGENTE)
rete = bpy.data.objects.get("modular_chainlink_fence_double")
palo = bpy.data.objects.get("modular_chainlink_fence_post")
if rete is None or palo is None:
    print("ATTENZIONE: nel modello non ci sono il pannello doppio e il palo")
    sys.exit(1)
for o in list(bpy.data.objects):
    if o not in (rete, palo):
        bpy.data.objects.remove(o)

# LA MAGLIA HA BISOGNO DELLA SUA OPACITA'. Il glTF di Poly Haven porta il colore in JPEG,
# senza trasparenza (vedi MAPPE_IN_PIU in prendi_modello.py): si scrive un PNG con il
# colore e, nel canale alfa, l'opacita', e lo si collega al materiale.
filo = bpy.data.materials.get("modular_chainlink_fence_wire")
nodi = filo.node_tree.nodes
bsdf = next(n for n in nodi if n.type == "BSDF_PRINCIPLED")
colore = bsdf.inputs["Base Color"].links[0].from_node
opaco = bpy.data.images.load(OPACITA)
larg, alt = colore.image.size
if tuple(opaco.size) != (larg, alt):
    opaco.scale(larg, alt)
rgba = np.array(colore.image.pixels[:], dtype=np.float32).reshape(alt, larg, 4)
rgba[..., 3] = np.array(opaco.pixels[:], dtype=np.float32).reshape(alt, larg, opaco.channels)[..., 0]
unito = bpy.data.images.new("modular_chainlink_fence_wire_diff_alpha", larg, alt, alpha=True)
unito.pixels.foreach_set(rgba.ravel())
unito.file_format = "PNG"
unito.pack()
colore.image = unito
filo.node_tree.links.new(colore.outputs["Alpha"], bsdf.inputs["Alpha"])


def scatola(o):
    p = [o.matrix_world @ v.co for v in o.data.vertices]
    return (Vector((min(v.x for v in p), min(v.y for v in p), min(v.z for v in p))),
            Vector((max(v.x for v in p), max(v.y for v in p), max(v.z for v in p))))


def applica(o):
    for x in bpy.context.selected_objects:
        x.select_set(False)
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


applica(rete)
applica(palo)
mn, mx = scatola(rete)
if abs((mx.x - mn.x) - LARGO_M) > 0.05:
    print("ATTENZIONE: il pannello e' largo %.2f m, non %.2f" % (mx.x - mn.x, LARGO_M))
    sys.exit(1)
# il pannello: spigolo in basso a sinistra nell'origine, poi il taglio
for v in rete.data.vertices:
    v.co = Vector((v.co.x - mn.x, v.co.y - (mn.y + mx.y) / 2, v.co.z - mn.z))
bm = bmesh.new()
bm.from_mesh(rete.data)
bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], dist=0.0001,
                       plane_co=(0.0, 0.0, ALTEZZA_M), plane_no=(0.0, 0.0, 1.0),
                       clear_outer=True)
bm.to_mesh(rete.data)
bm.free()
rete.name = rete.data.name = "Rete"
# il palo: base nell'origine, alto PALO_M
mn, mx = scatola(palo)
s = PALO_M / (mx.z - mn.z)
for v in palo.data.vertices:
    v.co = Vector((v.co.x - (mn.x + mx.x) / 2, v.co.y - (mn.y + mx.y) / 2, (v.co.z - mn.z) * s))
palo.name = palo.data.name = "Palo"
for o in (rete, palo):
    o.data.update()
    mn, mx = scatola(o)
    print("  %s: %d facce, %.2f x %.2f x %.2f m" % (o.name, len(o.data.polygons), mx.x - mn.x, mx.y - mn.y, mx.z - mn.z))

for x in bpy.context.selected_objects:
    x.select_set(False)
rete.select_set(True)
palo.select_set(True)
os.makedirs(os.path.dirname(USCITA), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=USCITA, export_format="GLB", use_selection=True, export_yup=True)
print("scritto %s" % USCITA)
