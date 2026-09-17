# -*- coding: utf-8 -*-
"""L'OCCHIO NELLA POSA: l'immagine dell'occhio che esce nella stampa al posto del soggetto.

    "D:/programs/blender5/blender.exe" --background --python tools/occhio_cosmico_blender.py

Produce assets/textures/occhio_cosmico/occhio.png.

DA DOVE. "Cosmic Eye of Horror" di Huntaer87 su Sketchfab (CC-BY 4.0, credito in CREDITI.md),
che Federico ha messo in `assets/models/esterni/_da_scaricare/`: un disco a lente con
un'iride che sembra una nebulosa, filamenti azzurri e un bordo rosso-violaceo punteggiato di
stelle. Nella stampa passa per l'oggetto fotografato finché non ci si accorge che guarda.

PERCHE' UN RENDER E NON LA SUA TEXTURE. La texture del modello e' un atlante a pezzi - l'ha
generata Tripo, e ogni pezzo d'iride sta dove gli UV lo hanno messo - quindi l'occhio intero
esiste solo sul modello. Lo si guarda di fronte, una volta, e si tiene l'immagine.

SENZA LUCI: il colore della texture va dritto nell'immagine, come un'emissione. Una nebulosa in
una foto astronomica non ha ombre, e un occhio illuminato da una lampada di Blender
sembrerebbe un oggetto appoggiato sulla foto.

IN "STANDARD" E NON NELLA TRASFORMAZIONE DI VISTA DI BLENDER, che schiarisce e desatura: i
colori devono essere quelli del modello, e il resto lo decide lo sviluppo nel gioco.
"""
import os
import zipfile

import bpy
from mathutils import Vector

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
ZIP = os.path.join(RADICE, "assets", "models", "esterni", "_da_scaricare", "cosmic_eye_of_horror.zip")
CACHE = os.path.join(QUI, "__modelli_cache__", "cosmic_eye_of_horror")
DEST = os.path.join(RADICE, "assets", "textures", "occhio_cosmico")
LATO = 512


def scompatta():
    if not os.path.exists(ZIP):
        raise SystemExit("manca %s: e' il modello di Sketchfab, va rimesso li'" % ZIP)
    os.makedirs(CACHE, exist_ok=True)
    with zipfile.ZipFile(ZIP) as z:
        z.extractall(CACHE)
    open(os.path.join(os.path.dirname(CACHE), ".gdignore"), "w").close()
    return os.path.join(CACHE, "scene.gltf")


def senza_luci():
    """Ogni materiale diventa la sua texture in emissione."""
    for m in bpy.data.materials:
        if not m.use_nodes:
            continue
        nodi = m.node_tree.nodes
        immagine = next((n for n in nodi if n.type == "TEX_IMAGE"), None)
        uscita = next((n for n in nodi if n.type == "OUTPUT_MATERIAL"), None)
        if immagine is None or uscita is None:
            continue
        emissione = nodi.new("ShaderNodeEmission")
        m.node_tree.links.new(immagine.outputs["Color"], emissione.inputs["Color"])
        m.node_tree.links.new(emissione.outputs["Emission"], uscita.inputs["Surface"])


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=scompatta())
    senza_luci()
    maglie = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    lo = Vector((1e9, 1e9, 1e9))
    hi = -lo
    for o in maglie:
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    centro = (lo + hi) * 0.5
    # IL DISCO E' SOTTILE LUNGO X, e l'iride guarda +X: lo si e' visto girandoci attorno
    diametro = max(hi.y - lo.y, hi.z - lo.z)

    scena = bpy.context.scene
    scena.render.engine = "BLENDER_EEVEE"
    scena.render.resolution_x = LATO
    scena.render.resolution_y = LATO
    scena.render.film_transparent = True
    scena.render.image_settings.file_format = "PNG"
    scena.render.image_settings.color_mode = "RGBA"
    scena.view_settings.view_transform = "Standard"
    mondo = bpy.data.worlds.new("Nero")
    mondo.use_nodes = True
    mondo.node_tree.nodes["Background"].inputs[1].default_value = 0.0
    scena.world = mondo
    dati = bpy.data.cameras.new("Camera")
    dati.type = "ORTHO"
    dati.ortho_scale = diametro * 1.02
    camera = bpy.data.objects.new("Camera", dati)
    scena.collection.objects.link(camera)
    scena.camera = camera
    camera.location = centro + Vector((diametro * 2.0, 0.0, 0.0))
    camera.rotation_euler = Vector((-1.0, 0.0, 0.0)).to_track_quat("-Z", "Z").to_euler()

    os.makedirs(DEST, exist_ok=True)
    uscita = os.path.join(DEST, "occhio.png")
    scena.render.filepath = uscita
    bpy.ops.render.render(write_still=True)
    with open(uscita + ".import", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join([
            "[remap]", "",
            'importer="texture"',
            'type="CompressedTexture2D"', "",
            "[deps]", "",
            'source_file="res://assets/textures/occhio_cosmico/occhio.png"', "",
            "[params]", "",
            # SENZA PERDITA: il gioco la legge pixel per pixel per comporre la stampa
            "compress/mode=0",
            "mipmaps/generate=false",
            "detect_3d/compress_to=0",
            "",
        ]))
    print("\nscritto %s  (%dx%d, disco di %.3f unita')" % (uscita, LATO, LATO, diametro))


if __name__ == "__main__":
    main()
