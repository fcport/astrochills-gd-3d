# -*- coding: utf-8 -*-
"""Gli alberi del panorama: tre querce e un albero scansionato, messi in piedi e fotografati.

    "D:/programs/blender5/blender.exe" --background --python tools/alberi_blender.py

Serve prima: python tools/prendi_modello.py querce_spoglie albero_scansionato

GLI ALBERI NON SI INVENTANO. Sono due modelli presi da Sketchfab (CC-BY, crediti in
CREDITI.md, scelta in `prendi_modello.py`): "3 English Oak Set", tre querce spoglie fatte
per un gioco, e una scansione fotogrammetrica di un albero vero, spoglio, col tronco
dritto - quello delle foto della sterrata. Qui non si cambia la forma di nessuno: si
separano, si mettono in piedi alla misura giusta e si fotografano.

SCRIVE DUE COSE, perche' un albero si guarda da due distanze:

  * assets/models/alberi.glb, i quattro alberi in 3D (Albero0..Albero3), con l'origine
    alla base del tronco e l'altezza in metri. Sono quelli dei primi sessanta metri:
    `world/panorama.gd` li mette in un MultiMesh per albero.
  * assets/panorama/alberi_sagome.png, gli stessi quattro FOTOGRAFATI DI FIANCO, senza
    luce e senza sfondo, in fila. Oltre i sessanta metri un albero e' due rettangoli
    incrociati con la sua foto sopra, come l'erba del prato (`tools/erba_blender.py`):
    sono cinquantamila, e da quella distanza la differenza non si vede.

LE MISURE. La scansione non dichiara la scala e le querce nemmeno (arrivano alte
ventotto unita'): si portano ad ALTEZZE, che sono quelle di un albero di crinale
dell'Appennino - dieci, quindici metri - e poi `panorama.gd` le varia di un quarto.
LA SCANSIONE PORTA ATTACCATA UNA ZOLLA di terra sotto il tronco: si tolgono le facce del
primo PRATO_TOLTO dell'altezza, che in partita starebbero sospese sui pendii.
"""
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Vector

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
ESTERNI = os.path.join(RADICE, "assets", "models", "esterni")
QUERCE = os.path.join(ESTERNI, "querce_spoglie", "querce_spoglie.glb")
SCANSIONE = os.path.join(ESTERNI, "albero_scansionato", "albero_scansionato.glb")
USCITA_MODELLI = os.path.join(RADICE, "assets", "models", "alberi.glb")
USCITA_SAGOME = os.path.join(RADICE, "assets", "panorama", "alberi_sagome.png")

# L'altezza di ogni albero, in metri, nell'ordine di Albero0..Albero3: prima la scansione,
# che e' l'albero piu' comune nelle foto, poi le tre querce.
ALTEZZE = (13.0, 10.0, 9.0, 11.0)
# Il lato della fotografia di un albero, in metri, e la base: il tronco sta al centro del
# lato basso, BASE_M sopra il bordo, perche' le radici della quercia scendono sotto
# l'origine. `world/panorama.gd` ha gli stessi due numeri (LATO_SAGOMA, BASE_SAGOMA).
LATO_M = 16.0
BASE_M = 0.5
LATO_PX = 512
SOVRA = 2
# Quanta parte dell'altezza della scansione e' zolla.
PRATO_TOLTO = 0.02
# La scansione ha quasi mezzo milione di triangoli: questa e' la frazione che resta.
RIDUZIONE_SCANSIONE = 0.05

for via, nome in ((QUERCE, "querce_spoglie"), (SCANSIONE, "albero_scansionato")):
    if not os.path.exists(via):
        print("MANCA %s" % via)
        print("  lancia prima: python tools/prendi_modello.py %s" % nome)
        sys.exit(1)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


def importa(via):
    prima = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=via)
    nuovi = [o for o in bpy.data.objects if o not in prima]
    mesh = [o for o in nuovi if o.type == "MESH"]
    # via i vuoti di Sketchfab, tenendo la trasformazione del mondo
    for o in mesh:
        m = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = m
    for o in nuovi:
        if o.type != "MESH":
            bpy.data.objects.remove(o)
    return mesh


def applica(o):
    bpy.context.view_layer.objects.active = o
    for x in bpy.context.selected_objects:
        x.select_set(False)
    o.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def unisci(oggetti, nome):
    for x in bpy.context.selected_objects:
        x.select_set(False)
    for o in oggetti:
        o.select_set(True)
    bpy.context.view_layer.objects.active = oggetti[0]
    if len(oggetti) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = nome
    o.data.name = nome
    return o


def scatola(o):
    p = [o.matrix_world @ v.co for v in o.data.vertices]
    return (Vector((min(v.x for v in p), min(v.y for v in p), min(v.z for v in p))),
            Vector((max(v.x for v in p), max(v.y for v in p), max(v.z for v in p))))


def in_piedi(o, altezza):
    """Base del tronco nell'origine, alto `altezza` metri. La base e' il centro dei
    vertici del tronco nel suo primo tre per cento d'altezza."""
    applica(o)
    mn, mx = scatola(o)
    soglia = mn.z + (mx.z - mn.z) * 0.03
    piede = [v.co for v in o.data.vertices if v.co.z <= soglia]
    cx = sum(v.x for v in piede) / len(piede)
    cy = sum(v.y for v in piede) / len(piede)
    s = altezza / (mx.z - mn.z)
    for v in o.data.vertices:
        v.co = Vector(((v.co.x - cx) * s, (v.co.y - cy) * s, (v.co.z - mn.z) * s))
    o.data.update()


# ------------------------------------------------------------ le querce
querce = importa(QUERCE)
for o in querce:
    applica(o)
# I RAMI SPOGLI PER TUTTE E TRE. Il modello ne porta due versioni: "bare_branches", i
# rametti nudi, e "branches", gli stessi con le gemme rosse di marzo. Rosa sul grigio,
# da lontano sembrano fiori; a novembre le gemme non ci sono. Si usa la versione nuda,
# che e' dello stesso autore e sta nello stesso file.
nudi = bpy.data.materials.get("bare_branches")
for o in querce:
    for i, m in enumerate(o.data.materials):
        if m is not None and m.name == "branches" and nudi is not None:
            o.data.materials[i] = nudi
tronchi = [o for o in querce if o.data.materials and "trunk" in o.data.materials[0].name]
rami = [o for o in querce if o not in tronchi]
centri = []
for t in tronchi:
    mn, mx = scatola(t)
    centri.append(Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2)))
if len(tronchi) != 3:
    print("ATTENZIONE: nelle querce ci sono %d tronchi, ne servono tre" % len(tronchi))
    sys.exit(1)
# I RAMI DI DUE QUERCE STANNO IN UNA MESH SOLA: si divide per pezzi staccati e ogni
# pezzo va al tronco piu' vicino.
per_albero = [[t] for t in tronchi]
for r in rami:
    for x in bpy.context.selected_objects:
        x.select_set(False)
    r.select_set(True)
    bpy.context.view_layer.objects.active = r
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    for pezzo in list(bpy.context.selected_objects):
        mn, mx = scatola(pezzo)
        c = Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2))
        k = min(range(3), key=lambda i: (centri[i] - c).length)
        per_albero[k].append(pezzo)
# nell'ordine da ovest a est, come stanno nel modello
ordine = sorted(range(3), key=lambda i: centri[i].x)
alberi = []

# ------------------------------------------------------------ la scansione
scan = importa(SCANSIONE)
scan = unisci(scan, "Albero0")
applica(scan)
mn, mx = scatola(scan)
taglio = mn.z + (mx.z - mn.z) * PRATO_TOLTO
bm = bmesh.new()
bm.from_mesh(scan.data)
via = [f for f in bm.faces if max(v.co.z for v in f.verts) < taglio]
bmesh.ops.delete(bm, geom=via, context="FACES")
bm.to_mesh(scan.data)
bm.free()
in_piedi(scan, ALTEZZE[0])
# LA FOTO SI FA ALLA SCANSIONE INTERA, e si riduce solo la copia in 3D: ridotta al cinque
# per cento, le carte dei rametti si spezzano in puntini, e da vicino non si nota ma in
# una foto di fianco si'.
intera = scan
intera.name = "Albero0Intero"
scan = intera.copy()
scan.data = intera.data.copy()
sc.collection.objects.link(scan)
scan.name = "Albero0"
riduci = scan.modifiers.new("Riduci", "DECIMATE")
riduci.ratio = RIDUZIONE_SCANSIONE
bpy.context.view_layer.objects.active = scan
bpy.ops.object.modifier_apply(modifier=riduci.name)
alberi.append(scan)
for n, i in enumerate(ordine):
    o = unisci(per_albero[i], "Albero%d" % (n + 1))
    in_piedi(o, ALTEZZE[n + 1])
    alberi.append(o)
fotografati = [intera] + alberi[1:]
for n, o in enumerate(alberi):
    o.location = (0.0, 0.0, 0.0)
    tri = sum(len(p.vertices) - 2 for p in o.data.polygons)
    mn, mx = scatola(o)
    print("  %s: %d triangoli, %.1f x %.1f x %.1f m" % (o.name, tri, mx.x - mn.x, mx.y - mn.y, mx.z - mn.z))
    if max(mx.x - mn.x, mx.z - mn.z + BASE_M) > LATO_M * 1.25:
        print("ATTENZIONE: %s non sta in una foto da %.0f m" % (o.name, LATO_M))
        sys.exit(1)

# ------------------------------------------------------------ il 3D
for x in bpy.context.selected_objects:
    x.select_set(False)
for o in alberi:
    o.select_set(True)
os.makedirs(os.path.dirname(USCITA_MODELLI), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=USCITA_MODELLI, export_format="GLB", use_selection=True,
                          export_apply=True, export_yup=True)
print("scritto %s" % USCITA_MODELLI)


# ------------------------------------------------------------ le sagome
def senza_luce(m):
    """Il materiale diventa il suo colore, emesso, con la sua trasparenza: nella foto va
    l'albero e non la luce dello studio - l'ombra la fa il gioco."""
    nodi, fili = m.node_tree.nodes, m.node_tree.links
    bsdf = next((n for n in nodi if n.type == "BSDF_PRINCIPLED"), None)
    uscita = next((n for n in nodi if n.type == "OUTPUT_MATERIAL"), None)
    if bsdf is None or uscita is None:
        return
    colore = bsdf.inputs["Base Color"]
    alfa = bsdf.inputs["Alpha"]
    luce = nodi.new("ShaderNodeEmission")
    buco = nodi.new("ShaderNodeBsdfTransparent")
    mescola = nodi.new("ShaderNodeMixShader")
    if colore.is_linked:
        fili.new(colore.links[0].from_socket, luce.inputs["Color"])
    else:
        luce.inputs["Color"].default_value = colore.default_value
    if alfa.is_linked:
        fili.new(alfa.links[0].from_socket, mescola.inputs["Fac"])
    else:
        mescola.inputs["Fac"].default_value = alfa.default_value
    fili.new(buco.outputs[0], mescola.inputs[1])
    fili.new(luce.outputs[0], mescola.inputs[2])
    fili.new(mescola.outputs[0], uscita.inputs["Surface"])
    m.surface_render_method = "DITHERED"


for m in bpy.data.materials:
    if m.use_nodes:
        senza_luce(m)
sc.render.engine = "BLENDER_EEVEE"
sc.render.film_transparent = True
sc.view_settings.view_transform = "Standard"
sc.render.resolution_x = sc.render.resolution_y = LATO_PX * SOVRA
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
obiettivo = bpy.data.cameras.new("Obiettivo")
obiettivo.type = "ORTHO"
obiettivo.ortho_scale = LATO_M
camera = bpy.data.objects.new("Obiettivo", obiettivo)
sc.collection.objects.link(camera)
sc.camera = camera
camera.rotation_euler = (math.radians(90.0), 0.0, 0.0)   # guarda verso +Y
# LA BASE DEL TRONCO A BASE_M DAL BORDO BASSO, al centro: e' li' che il gioco lo pianta
camera.location = (0.0, -40.0, LATO_M / 2 - BASE_M)

atlante = np.zeros((LATO_PX, LATO_PX * len(alberi), 4), dtype=np.float32)
scatto = os.path.join(bpy.app.tempdir, "albero.png")
for o in alberi:
    o.hide_render = True
for k, voluto in enumerate(fotografati):
    for o in fotografati:
        o.hide_render = o is not voluto
    sc.render.filepath = scatto
    bpy.ops.render.render(write_still=True)
    foto = bpy.data.images.load(scatto, check_existing=False)
    fitti = np.array(foto.pixels[:], dtype=np.float32).reshape(LATO_PX, SOVRA, LATO_PX, SOVRA, 4)
    bpy.data.images.remove(foto)
    # COME PER L'ERBA: un rametto e' piu' sottile di un pixel, e con la media sparirebbe.
    # La copertura e' la piu' alta del quadretto, il colore la media dei soli rametti.
    alfa = fitti[..., 3]
    peso = np.maximum(alfa.sum(axis=(1, 3)), 1e-6)[..., None]
    colore = (fitti[..., :3] * alfa[..., None]).sum(axis=(1, 3)) / peso
    atlante[:, k * LATO_PX:(k + 1) * LATO_PX, :] = np.dstack([colore, alfa.max(axis=(1, 3))])
    print("  sagoma %s: %.1f%% della foto coperta" % (voluto.name, 100.0 * float((atlante[:, k * LATO_PX:(k + 1) * LATO_PX, 3] > 0.3).mean())))

os.makedirs(os.path.dirname(USCITA_SAGOME), exist_ok=True)
uscita = bpy.data.images.new("AlberiSagome", LATO_PX * len(alberi), LATO_PX, alpha=True)
uscita.pixels.foreach_set(atlante.ravel())
uscita.filepath_raw = USCITA_SAGOME
uscita.file_format = "PNG"
uscita.save()
# le mipmap, scritte prima che Godot importi: cinquantamila alberi da due a millecinquecento
# metri campionano questa foto a ogni grandezza
res = "res://" + os.path.relpath(USCITA_SAGOME, RADICE).replace(os.sep, "/")
with open(USCITA_SAGOME + ".import", "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(["[remap]", "", 'importer="texture"', 'type="CompressedTexture2D"', "",
                       "[deps]", "", 'source_file="%s"' % res, "", "[params]", "",
                       "compress/mode=0", "mipmaps/generate=true", "detect_3d/compress_to=0", ""]))
print("scritto %s (%d x %d)" % (USCITA_SAGOME, LATO_PX * len(alberi), LATO_PX))
