# -*- coding: utf-8 -*-
"""Renderizza la cupola esportata, per guardarla senza aprire Blender.

    "D:/programs/blender5/blender.exe" --background --python tools/cupola_render.py

Produce due immagini in _bmad-output/.../gdds/<cartella>/:
  cupola-fuori.png   come si vede arrivando dal prato
  cupola-dentro.png  come si vede dalla passerella, che e' il punto di vista del gioco
"""
import math
import os

import bpy

QUI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELLO = os.path.join(QUI, "assets", "models", "cupola.glb")
FUORI = os.path.join(QUI, "_bmad-output", "planning-artifacts", "gdds",
                     "gdd-astrochills-gd-3d-2026-08-24")

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=MODELLO)

scena = bpy.context.scene
scena.render.resolution_x, scena.render.resolution_y = 960, 620
scena.render.film_transparent = False
# Il nome del motore cambia fra le versioni (EEVEE_NEXT in 4.x, EEVEE in 5.x): si legge
# l'elenco invece di indovinarlo. Sbagliando si finisce in Workbench, che IGNORA i
# materiali e rende tutto grigio uniforme, facendo sembrare il modello privo di dettagli.
_motori = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scena.render.engine = next((m for m in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "CYCLES") if m in _motori), _motori[0])
print("motore di render: %s" % scena.render.engine)

# un cielo grigio, cosi' la forma si legge
mondo = bpy.data.worlds.new("Cielo")
mondo.use_nodes = True
mondo.node_tree.nodes["Background"].inputs[0].default_value = (0.30, 0.34, 0.40, 1)
mondo.node_tree.nodes["Background"].inputs[1].default_value = 1.2
scena.world = mondo

sole_dati = bpy.data.lights.new("Sole", type="SUN")
sole_dati.energy = 3.0
sole = bpy.data.objects.new("Sole", sole_dati)
sole.rotation_euler = (math.radians(50), 0, math.radians(35))
bpy.context.collection.objects.link(sole)

camera_dati = bpy.data.cameras.new("Camera")
camera = bpy.data.objects.new("Camera", camera_dati)
bpy.context.collection.objects.link(camera)
scena.camera = camera


# Puntare la camera con gli angoli di Eulero e' un modo affidabile di sbagliarsi:
# si usa un Empty come bersaglio e un vincolo TRACK_TO, che li calcola Blender.
bersaglio_vuoto = bpy.data.objects.new("Bersaglio", None)
bpy.context.collection.objects.link(bersaglio_vuoto)
vincolo = camera.constraints.new("TRACK_TO")
vincolo.target = bersaglio_vuoto
vincolo.track_axis = "TRACK_NEGATIVE_Z"
vincolo.up_axis = "UP_Y"


def inquadra(posizione, bersaglio, lente=35.0):
    camera.location = posizione
    camera_dati.lens = lente
    bersaglio_vuoto.location = bersaglio
    bpy.context.view_layer.update()


def scatta(nome):
    scena.render.filepath = os.path.join(FUORI, nome)
    bpy.ops.render.render(write_still=True)
    print("scritto %s" % scena.render.filepath)


# da fuori, dal prato: la fenditura guarda verso +Y in Blender
inquadra((5.0, 9.0, 3.2), (0.0, 0.0, 1.1), lente=38.0)
scatta("cupola-fuori.png")

# da dentro, in piedi sulla passerella a 0,99 sotto la quota di gronda
inquadra((0.9, -1.30, -0.31), (0.0, 1.6, 1.8), lente=20.0)
scatta("cupola-dentro.png")
