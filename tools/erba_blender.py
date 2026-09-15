# -*- coding: utf-8 -*-
"""L'erba del prato: i ciuffi di Poly Haven fotografati di fianco, in fila su una texture.

    "D:/programs/blender5/blender.exe" --background --python tools/erba_blender.py

Produce assets/textures/erba_ciuffi.png, che `world/prato.gd` mette su due rettangoli
incrociati per ciuffo.

L'ERBA NON SI INVENTA. `grass_medium_02` (Poly Haven, CC0, dichiarato in
`tools/prendi_modello.py`) sono cinque ciuffi veri di un prato, dai quindici ai
quaranta centimetri, con i fili secchi in mezzo a quelli verdi: e' quello che c'e' a
novembre sull'Appennino. Ma pesano da settecento a duemilacinquecento facce l'uno, e
sul prato ne servono migliaia. Quindi si FOTOGRAFANO: una vista di fianco, senza luce
e senza sfondo, e restano il colore del ciuffo e la sua sagoma. E' il modo in cui
l'erba la faceva la PlayStation.

TUTTI ALLA STESSA SCALA, con il lato LATO_M: un ciuffo da quindici centimetri resta
piccolo accanto a uno da quaranta. `world/prato.gd` ha lo stesso numero
(LATO_CIUFFO), e il banco controlla che i due coincidano.
"""
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Vector

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
SORGENTE = os.path.join(RADICE, "assets", "models", "esterni", "grass_medium_02",
                        "grass_medium_02_1k.gltf")
USCITA = os.path.join(RADICE, "assets", "textures", "erba_ciuffi.png")

# I ciuffi che si tengono, nell'ordine delle colonne. Il primo del set (`_a`) resta
# fuori: sedici centimetri e quattro fili, e a questa scala e' un graffio.
CIUFFI = ("grass_medium_02_b", "grass_medium_02_c", "grass_medium_02_d",
          "grass_medium_02_e")
# Il lato della fotografia, in metri e in pixel. 64 pixel per 42 centimetri sono sei
# millimetri e mezzo a pixel: a tre metri, dove l'erba si guarda, un pixel della
# texture e' un pixel dello schermo. A 128 lo schermo ne saltava uno su due, e i fili
# si spezzavano in una pioggia di punti.
LATO_M = 0.42
LATO_PX = 64
# Quante volte piu' fitto si scatta prima di ridurre. UN FILO E' PIU' SOTTILE DI UN
# PIXEL: ridotto con la media diventerebbe una velatura sotto la soglia, e sparirebbe.
# Tenendo la copertura piu' alta di ogni quadretto resta un filo largo un pixel.
SOVRA = 4
# Sotto questa copertura il pixel non c'e': e' la `soglia` di `erba.gdshader`.
SOGLIA = 0.4

if not os.path.exists(SORGENTE):
    print("MANCA %s" % SORGENTE)
    print("  lancia prima: python tools/prendi_modello.py grass_medium_02")
    sys.exit(1)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SORGENTE)
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
# SENZA LUCE: nella texture va il colore del ciuffo, e l'ombra la fa il gioco. Con la
# luce da studio ogni ciuffo si porterebbe dietro un chiaroscuro che in partita
# guarderebbe sempre dalla stessa parte, qualunque sia la Luna.
sc.display.shading.light = "FLAT"
sc.display.shading.color_type = "TEXTURE"
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

atlante = np.zeros((LATO_PX, LATO_PX * len(CIUFFI), 4), dtype=np.float32)
scatto = os.path.join(bpy.app.tempdir, "ciuffo.png")
for k, nome in enumerate(CIUFFI):
    voluto = bpy.data.objects.get(nome)
    if voluto is None:
        print("ATTENZIONE: nel modello non c'e' il ciuffo %s" % nome)
        sys.exit(1)
    for o in sc.objects:
        if o.type == "MESH":
            o.hide_render = o is not voluto
    punti = [voluto.matrix_world @ Vector(c) for c in voluto.bound_box]
    x0, x1 = min(p.x for p in punti), max(p.x for p in punti)
    y0 = min(p.y for p in punti)
    z0, z1 = min(p.z for p in punti), max(p.z for p in punti)
    if max(x1 - x0, z1 - z0) > LATO_M:
        print("ATTENZIONE: %s e' %.2f x %.2f m e non sta in una foto da %.2f"
              % (nome, x1 - x0, z1 - z0, LATO_M))
        sys.exit(1)
    # LA BASE DEL CIUFFO SUL BORDO BASSO DELLA FOTO: e' li' che il gioco lo pianta
    camera.location = ((x0 + x1) / 2, y0 - 2.0, z0 + LATO_M / 2)
    sc.render.filepath = scatto
    bpy.ops.render.render(write_still=True)
    foto = bpy.data.images.load(scatto, check_existing=False)
    fitti = np.array(foto.pixels[:], dtype=np.float32).reshape(
        LATO_PX, SOVRA, LATO_PX, SOVRA, 4)
    bpy.data.images.remove(foto)
    # la copertura e' la piu' alta del quadretto; il colore e' la media dei soli fili
    alfa = fitti[..., 3]
    peso = np.maximum(alfa.sum(axis=(1, 3)), 1e-6)[..., None]
    colore = (fitti[..., :3] * alfa[..., None]).sum(axis=(1, 3)) / peso
    pixel = np.dstack([colore, alfa.max(axis=(1, 3))])
    atlante[:, k * LATO_PX:(k + 1) * LATO_PX, :] = pixel
    print("  %-20s %.2f x %.2f m, %4.1f%% della foto coperta"
          % (nome, x1 - x0, z1 - z0, 100.0 * float((pixel[:, :, 3] > SOGLIA).mean())))

os.makedirs(os.path.dirname(USCITA), exist_ok=True)
uscita = bpy.data.images.new("ErbaCiuffi", LATO_PX * len(CIUFFI), LATO_PX, alpha=True)
uscita.pixels.foreach_set(atlante.ravel())
uscita.filepath_raw = USCITA
uscita.file_format = "PNG"
uscita.save()
print("scritto %s (%d x %d)" % (USCITA, LATO_PX * len(CIUFFI), LATO_PX))
