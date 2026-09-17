# -*- coding: utf-8 -*-
"""LA PIETRA DEL COLORE VENUTO DALLO SPAZIO (`Ctrl+F8`): una meteorite vera.

    "D:/programs/blender5/blender.exe" --background --python tools/meteorite_blender.py

Produce assets/models/meteorite.glb.

DA DOVE. Astromaterials 3D della NASA (https://ares.jsc.nasa.gov/astromaterials3d/), la
collezione delle meteoriti antartiche: il campione GRO 17102,0, una meteorite ferrosa
IAB trovata dall'ANSMET sui Grosvenor Mountains nel 2017, fotografata da tutti i lati e
ricostruita con la sua texture. Pubblico dominio, con il credito chiesto dalla pagina
(CREDITI.md). Lo script scarica il modello "Low Resolution" la prima volta e lo tiene in
`tools/__modelli_cache__/meteorite/`.

PERCHE' QUESTA. La prima pietra era una sfera deformata da un rumore con uno shader sopra, e
Federico: «sto sasso e' una merda». Di sette meteoriti scansionate guardate una accanto
all'altra, questa e' quella che chiunque riconosce come una meteorite: bruna, arrotondata dal
volo, con la superficie a IMPRONTE DI POLLICE (regmaglipti), le fossette che l'aria scava
fondendo il metallo. Ed e' ferrosa come la pietra del racconto, che «si comportava come un
metallo».

LA SCALA E' DICHIARATA: il campione vero e' lungo tredici centimetri. Il racconto parla di un
«grosso cumulo brunastro» nel prato, e qui si esporta a grandezza vera; la grandezza da
orrore la mette `world/orrori/colore.gd`, che la moltiplica.

COSA SI FA AL MODELLO: centrato sul suo ingombro, con il lato piu' lungo lungo X; ridotto a
un terzo dei triangoli (da centocinquantamila, per una pietra che si guarda da qualche metro, sono
troppi e non si vedono); la texture da 5200 portata a 2048.
"""
import math
import os
import urllib.request
import zipfile

import bpy
from mathutils import Vector

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "meteorite.glb")
CACHE = os.path.join(QUI, "__modelli_cache__", "meteorite")
URL = ("https://ares-a3d.s3.us-gov-east-1.amazonaws.com/samples/GRO17102-0/"
       "2b_GRO17102-0_Web-Resolution-Model/"
       "GRO17102-0_SFM_Web-Resolution-Model_Coordinate-Unregistered.zip")
RIDUCI = 0.33
TEXTURE = 2048


def procura():
    os.makedirs(CACHE, exist_ok=True)
    open(os.path.join(os.path.dirname(CACHE), ".gdignore"), "w").close()
    zip_ = os.path.join(CACHE, os.path.basename(URL))
    if not os.path.exists(zip_):
        print("scarico %s" % URL)
        richiesta = urllib.request.Request(URL, headers={"User-Agent": "astrochills-tools"})
        with urllib.request.urlopen(richiesta) as r, open(zip_, "wb") as f:
            f.write(r.read())
    with zipfile.ZipFile(zip_) as z:
        z.extractall(CACHE)
    return next(os.path.join(CACHE, n) for n in os.listdir(CACHE) if n.endswith(".obj"))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=procura())
    pietra = next(o for o in bpy.context.scene.objects if o.type == "MESH")
    pietra.name = "Meteorite"
    bpy.context.view_layer.objects.active = pietra
    pietra.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # centrata sul suo ingombro
    lo = Vector((min(v.co.x for v in pietra.data.vertices), min(v.co.y for v in pietra.data.vertices),
                 min(v.co.z for v in pietra.data.vertices)))
    hi = Vector((max(v.co.x for v in pietra.data.vertices), max(v.co.y for v in pietra.data.vertices),
                 max(v.co.z for v in pietra.data.vertices)))
    centro = (lo + hi) * 0.5
    for v in pietra.data.vertices:
        v.co -= centro
    lati = hi - lo
    # il lato piu' lungo lungo X
    if lati.y > lati.x and lati.y >= lati.z:
        pietra.rotation_euler = (0.0, 0.0, math.radians(90.0))
    elif lati.z > lati.x and lati.z > lati.y:
        pietra.rotation_euler = (0.0, math.radians(90.0), 0.0)
    bpy.ops.object.transform_apply(rotation=True)

    prima = sum(len(p.vertices) - 2 for p in pietra.data.polygons)
    mod = pietra.modifiers.new("Riduci", "DECIMATE")
    mod.ratio = RIDUCI
    with bpy.context.temp_override(object=pietra, active_object=pietra, selected_objects=[pietra]):
        bpy.ops.object.modifier_apply(modifier=mod.name)
    print("  triangoli prima della riduzione: %d" % prima)
    bpy.ops.object.shade_smooth()

    for m in pietra.data.materials:
        for n in m.node_tree.nodes if m and m.use_nodes else []:
            if n.type == "TEX_IMAGE" and n.image is not None:
                if max(n.image.size) > TEXTURE:
                    n.image.scale(TEXTURE, TEXTURE)
                n.image.pack()
            if n.type == "BSDF_PRINCIPLED":
                n.inputs["Roughness"].default_value = 0.75
                n.inputs["Metallic"].default_value = 0.0

    os.makedirs(os.path.dirname(USCITA), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=USCITA, export_format="GLB", use_selection=True,
                              export_image_format="JPEG")
    dims = [max(v.co[i] for v in pietra.data.vertices) - min(v.co[i] for v in pietra.data.vertices)
            for i in range(3)]
    print("\nscritto %s  (%.1f MB)" % (USCITA, os.path.getsize(USCITA) / 1e6))
    print("  %d triangoli; %.0f x %.0f x %.0f mm" % (
        sum(len(p.vertices) - 2 for p in pietra.data.polygons), dims[0] * 1000, dims[1] * 1000, dims[2] * 1000))


if __name__ == "__main__":
    main()
