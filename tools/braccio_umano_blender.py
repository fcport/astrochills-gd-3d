# -*- coding: utf-8 -*-
"""IL BRACCIO UMANO delle braccia all'orizzonte (`Ctrl+F4`).

    "D:/programs/blender5/blender.exe" --background --python tools/braccio_umano_blender.py

Produce assets/models/braccio_umano.glb.

LA FORMA NON SI INVENTA, SI PRENDE. E' il braccio destro di "Body Male - Realistic",
dal bundle "Human Base Meshes" v1.4.1 di Blender Studio (CC0), scolpito da chi fa
anatomia per mestiere: deltoide, gomito, tendini del polso, nocche, unghie. Lo script
lo scarica da solo la prima volta e lo tiene in `tools/__modelli_cache__/`.

LE GIUNTURE NON SI STIMANO: IL MODELLO LE DICE GIA'. Chi l'ha scolpito ha diviso la
superficie in face set, uno per segmento — braccio, avambraccio, palmo e ogni singola
falange, unghia compresa. Il confine fra due face set e' un anello di pelle attorno
all'articolazione, e il suo centro e' il perno. Il bundle ha anche uno scheletro
anatomico, ed era la prima idea: ma e' di un'altra persona in un'altra posa, e
sovrapposto al corpo ne esce di quattro centimetri.

UNA SOLA ECCEZIONE, LA NOCCA. Il confine fra palmo e dito sta alla PLICA INTERDIGITALE,
la pelle fra un dito e l'altro, e l'articolazione metacarpo-falangea sta piu' indietro:
sul dorso la nocca e' ben prima di dove il dito si separa. Piegare le dita dalla plica
le farebbe spuntare dal palmo come stecchi infilati. Il perno si arretra verso il
polso di NOCCA_INDIETRO volte la distanza fra plica e articolazione successiva.

LO SCHELETRO ESCE GIA' ORIENTATO PER CHI LO USA: la spalla nell'origine, il braccio
lungo +Z di Blender (+Y in Godot), il palmo verso -Y di Blender (+Z in Godot, cioe'
verso chi guarda quando `world/orrori/braccia.gd` gira il braccio verso la camera) e il
pollice verso +X. E' la mano destra alzata a mostrare il palmo. Le braccia sinistre
sono questa specchiata.

LE OSSA hanno l'asse Z verso il lato in cui l'articolazione si flette — il palmo per
polso e dita, il davanti del braccio per il gomito — cosi' la flessione e' una
rotazione attorno all'asse X dell'osso. Godot comunque non ci si fida: rilegge i
versi dalla posa di riposo.

Si esporta a grandezza vera, in metri: la scala da gigante la mette chi lo colloca.
"""
import math
import os
import sys
import urllib.request
import zipfile

import bmesh
import bpy
from mathutils import Matrix, Vector

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
if QUI not in sys.path:
    sys.path.insert(0, QUI)

USCITA = os.path.join(RADICE, "assets", "models", "braccio_umano.glb")
CONFRONTO = os.path.join(RADICE, "_confronto")
CACHE = os.path.join(QUI, "__modelli_cache__")
URL = ("https://download.blender.org/demo/asset-bundles/human-base-meshes/"
       "human-base-meshes-bundle-v1.4.1.zip")
BLEND = os.path.join(CACHE, "human-base-meshes-bundle-v1.4.1", "human_base_meshes_bundle.blend")
CORPO = "GEO-body_male_realistic"

# Il livello di multires: 0 e' la gabbia, 3 il modello scolpito da 677 mila vertici.
# Il 2 tiene nocche e tendini, e il braccio intero sta sotto i trentamila.
LIVELLO = 2

# I face set del corpo, letti uno per uno (centri e ingombri) prima di scriverli qui.
# Il lato destro del personaggio sta verso -X.
TORSO = 1
BRACCIO = 20
AVAMBRACCIO = 11
MANO = 10
# Per ogni dito, dalla base alla punta; l'ultimo e' l'unghia. Il pollice ha il suo
# primo tratto sul bordo del palmo, poi le due falangi.
DITA = {
    "pollice": (84, 85, 86, 87),
    "indice": (88, 89, 90, 91),
    "medio": (92, 93, 94, 95),
    "anulare": (96, 97, 98, 99),
    "mignolo": (100, 101, 102, 103),
}
NOCCA_INDIETRO = 0.45

# Dove si taglia la spalla, in metri sopra il suo perno. Il face set del braccio sale fino
# al trapezio, e orientato dritto quel lembo si apre sotto il braccio come una gonna. La
# spalla comunque sta sotto l'orizzonte: un taglio netto, se mai si vedesse, e' un moncone.
TAGLIO = 0.07


def procura():
    """Il bundle, scaricato e scompattato una volta sola."""
    if os.path.exists(BLEND):
        return
    os.makedirs(CACHE, exist_ok=True)
    # dentro c'e' un .blend, e Godot proverebbe a importarlo cercando Blender
    open(os.path.join(CACHE, ".gdignore"), "w").close()
    zip_ = os.path.join(CACHE, os.path.basename(URL))
    if not os.path.exists(zip_):
        print("scarico %s" % URL)
        # senza un User-Agent download.blender.org risponde 403
        richiesta = urllib.request.Request(URL, headers={"User-Agent": "astrochills-tools"})
        with urllib.request.urlopen(richiesta) as r, open(zip_, "wb") as f:
            f.write(r.read())
    with zipfile.ZipFile(zip_) as z:
        z.extractall(CACHE)


def tutti_i_set():
    s = {BRACCIO, AVAMBRACCIO, MANO}
    for dito in DITA.values():
        s.update(dito)
    return s


def estrai():
    """Il braccio destro al LIVELLO voluto, con il face set di ogni faccia."""
    corpo = bpy.data.objects[CORPO]
    base = corpo.data
    fs = base.attributes[".sculpt_face_set"]
    # I face set sono un attributo interno e il multires non li porta ai livelli
    # suddivisi: una copia con un nome normale invece si', faccia per faccia.
    seg = base.attributes.new("segmento", "INT", "FACE")
    for a, b in zip(fs.data, seg.data):
        b.value = a.value
    mr = next(m for m in corpo.modifiers if m.type == "MULTIRES")
    mr.levels = LIVELLO
    mr.render_levels = LIVELLO
    dg = bpy.context.evaluated_depsgraph_get()
    malla = bpy.data.meshes.new_from_object(corpo.evaluated_get(dg))
    malla.name = "BraccioUmano"

    tenere = tutti_i_set()
    bm = bmesh.new()
    bm.from_mesh(malla)
    strato = bm.faces.layers.int.get("segmento")
    via = [f for f in bm.faces if f[strato] not in tenere]
    bmesh.ops.delete(bm, geom=via, context="FACES")
    sciolti = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=sciolti, context="VERTS")
    bm.to_mesh(malla)
    bm.free()
    return malla


def confine(malla, a, b):
    """Il centro dell'anello di vertici che le facce del set `a` e del set `b` hanno in comune."""
    seg = malla.attributes["segmento"].data
    va, vb = set(), set()
    for p in malla.polygons:
        s = seg[p.index].value
        if s == a:
            va.update(p.vertices)
        elif s == b:
            vb.update(p.vertices)
    comuni = va & vb
    if not comuni:
        raise SystemExit("i face set %d e %d non si toccano: il modello e' cambiato" % (a, b))
    return sum((malla.vertices[i].co for i in comuni), Vector()) / len(comuni)


def punta(malla, sets, da):
    """Il vertice dei set `sets` piu' lontano dal punto `da`."""
    seg = malla.attributes["segmento"].data
    idx = set()
    for p in malla.polygons:
        if seg[p.index].value in sets:
            idx.update(p.vertices)
    return max((malla.vertices[i].co for i in idx), key=lambda c: (c - da).length).copy()


def giunture(malla):
    """Tutti i perni, nelle coordinate del corpo."""
    g = {}
    g["spalla"] = confine(malla_intera(), TORSO, BRACCIO)
    g["gomito"] = confine(malla, BRACCIO, AVAMBRACCIO)
    g["polso"] = confine(malla, AVAMBRACCIO, MANO)
    for nome, (s0, s1, s2, s3) in DITA.items():
        plica = confine(malla, MANO, s0)
        g1 = confine(malla, s0, s1)
        g2 = confine(malla, s1, s2)
        g[nome + "_punta"] = punta(malla, (s2, s3), g2)
        if nome == "pollice":
            g[nome + "_0"] = plica
        else:
            g[nome + "_0"] = plica + (plica - g1) * NOCCA_INDIETRO
        g[nome + "_1"] = g1
        g[nome + "_2"] = g2
    return g


_INTERA = {}


def malla_intera():
    """Il corpo intero al livello 0, solo per il confine col torso."""
    if "m" not in _INTERA:
        m = bpy.data.objects[CORPO].data.copy()
        seg = m.attributes.get("segmento")
        if seg is None:
            fs = m.attributes[".sculpt_face_set"]
            seg = m.attributes.new("segmento", "INT", "FACE")
            for a, b in zip(fs.data, seg.data):
                b.value = a.value
        _INTERA["m"] = m
    return _INTERA["m"]


def orientamento(g):
    """La rotazione che porta la spalla nell'origine, il braccio su e il palmo davanti.

    Il palmo si legge dalla mano stessa: `radiale` va dalla nocca del mignolo a quella
    dell'indice (verso il pollice), `lungo` dal polso alla nocca del medio. Per una mano
    DESTRA il palmo guarda verso radiale x lungo.
    """
    su = (g["polso"] - g["spalla"]).normalized()
    radiale = (g["indice_0"] - g["mignolo_0"]).normalized()
    lungo = (g["medio_0"] - g["polso"]).normalized()
    palmo = radiale.cross(lungo).normalized()
    palmo = (palmo - su * palmo.dot(su)).normalized()
    x = su.cross(palmo).normalized()
    # colonne: dove vanno X, Y, Z di Blender; righe: la matrice che porta il corpo li'
    s = Matrix((x, -palmo, su))
    return s.to_4x4() @ Matrix.Translation(-g["spalla"])


# Le ossa: nome, da quale giuntura a quale, padre. Le dita appese al palmo.
def ossa():
    elenco = [("braccio", "spalla", "gomito", None),
              ("avambraccio", "gomito", "polso", "braccio"),
              ("mano", "polso", "medio_0", "avambraccio")]
    for nome in DITA:
        elenco.append((nome + "_1", nome + "_0", nome + "_1", "mano"))
        elenco.append((nome + "_2", nome + "_1", nome + "_2", nome + "_1"))
        elenco.append((nome + "_3", nome + "_2", nome + "_punta", nome + "_2"))
    return elenco


def verso_della_flessione(nome, davanti):
    """Da che parte si piega l'osso, nel riferimento gia' orientato.

    Il gomito porta l'avambraccio sul davanti del corpo; polso e dita si chiudono sul
    palmo, che sta verso -Y; il pollice si chiude sul palmo E verso il mignolo, che sta
    verso -X.
    """
    if nome in ("braccio", "avambraccio"):
        return davanti
    if nome.startswith("pollice"):
        return Vector((-1.0, -1.0, 0.0)).normalized()
    return Vector((0.0, -1.0, 0.0))


def arma(corpo, g, davanti):
    dati = bpy.data.armatures.new("Scheletro")
    scheletro = bpy.data.objects.new("Scheletro", dati)
    bpy.context.collection.objects.link(scheletro)
    bpy.context.view_layer.objects.active = scheletro
    scheletro.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    fatte = {}
    for nome, da, a, padre in ossa():
        b = dati.edit_bones.new(nome)
        b.head = g[da]
        b.tail = g[a]
        b.align_roll(verso_della_flessione(nome, davanti))
        if padre is not None:
            b.parent = fatte[padre]
            b.use_connect = (padre != "mano")
        fatte[nome] = b
    bpy.ops.object.mode_set(mode="OBJECT")

    # I PESI LI CALCOLA BLENDER, per diffusione di calore dalle ossa: sulle dita e'
    # l'unico metodo che non fa colare il medio sull'anulare, perche' il calore segue
    # la superficie e fra due dita la superficie passa dal palmo.
    bpy.ops.object.select_all(action="DESELECT")
    corpo.select_set(True)
    scheletro.select_set(True)
    bpy.context.view_layer.objects.active = scheletro
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    senza = [v.index for v in corpo.data.vertices if not v.groups]
    if senza:
        raise SystemExit("%d vertici senza peso: la diffusione non ha trovato soluzione" % len(senza))
    return scheletro


def pelle():
    m = bpy.data.materials.new("Pelle")
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    # Godot la rimpiazza: qui serve solo che il provino abbia un colore di pelle.
    bsdf.inputs["Base Color"].default_value = (0.62, 0.50, 0.45, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.6
    return m


def apri():
    procura()
    if os.path.normcase(os.path.abspath(bpy.data.filepath or "")) != os.path.normcase(BLEND):
        bpy.ops.wm.open_mainfile(filepath=BLEND)


def main():
    apri()
    malla = estrai()
    g = giunture(malla)
    m = orientamento(g)
    malla.transform(m)
    for k in g:
        g[k] = m @ g[k]
    davanti = (m.to_3x3() @ Vector((0.0, -1.0, 0.0))).normalized()
    bm = bmesh.new()
    bm.from_mesh(malla)
    via = [f for f in bm.faces if f.calc_center_median().z < TAGLIO]
    bmesh.ops.delete(bm, geom=via, context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(malla)
    bm.free()
    malla.shade_smooth()
    malla.materials.append(pelle())

    # Si butta via tutto il resto del bundle, cosi' l'export e i provini vedono solo il braccio.
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    corpo = bpy.data.objects.new("BraccioUmano", malla)
    bpy.context.scene.collection.objects.link(corpo)
    scheletro = arma(corpo, g, davanti)

    os.makedirs(os.path.dirname(USCITA), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    corpo.select_set(True)
    scheletro.select_set(True)
    bpy.context.view_layer.objects.active = scheletro
    bpy.ops.export_scene.gltf(filepath=USCITA, export_format="GLB",
                              use_selection=True, export_apply=False)

    print("\nscritto %s  (%.1f MB)" % (USCITA, os.path.getsize(USCITA) / 1e6))
    print("  %d vertici, %d ossa" % (len(malla.vertices), len(scheletro.data.bones)))
    print("  spalla-gomito %.0f mm, gomito-polso %.0f, polso-punta del medio %.0f" % (
        (g["gomito"] - g["spalla"]).length * 1000, (g["polso"] - g["gomito"]).length * 1000,
        (g["medio_punta"] - g["polso"]).length * 1000))
    for nome in DITA:
        pz = [g[nome + k] for k in ("_0", "_1", "_2", "_punta")]
        print("  %-8s falangi %s mm" % (nome, [round((pz[i + 1] - pz[i]).length * 1000) for i in range(3)]))
    return corpo, scheletro, g


def provini(corpo, scheletro, g):
    """Si guarda, e si guarda PIEGATO: dritto non dice se la pelle segue le ossa."""
    from modellare import lampada, prepara_render
    scatta = prepara_render(900, 1000, cielo=(0.10, 0.12, 0.17))
    sole = lampada("Luna", (2.0, 3.0, 2.0), 3.5, tipo="SUN")
    sole.rotation_euler = (math.radians(50.0), 0.0, math.radians(20.0))
    lampada("Rimbalzo", (-1.0, 0.6, 1.5), 40.0)
    # in coordinate di gioco il braccio va lungo +y e il palmo guarda +z
    scatta(os.path.join(CONFRONTO, "31_braccio_umano.png"), (0.25, 0.42, 1.6), (0.0, 0.40, 0.0), lente=50.0)
    scatta(os.path.join(CONFRONTO, "31b_braccio_umano_mano.png"), (0.05, 0.60, 0.45), (0.03, 0.60, 0.0), lente=50.0)

    def gira(nome, gradi):
        o = scheletro.pose.bones[nome]
        o.rotation_mode = "XYZ"
        o.rotation_euler = (math.radians(gradi), 0.0, 0.0)

    gira("avambraccio", 70.0)
    gira("mano", 25.0)
    for nome in DITA:
        pollice = nome == "pollice"
        gira(nome + "_1", 30.0 if pollice else 75.0)
        gira(nome + "_2", 35.0 if pollice else 90.0)
        gira(nome + "_3", 40.0 if pollice else 60.0)
    bpy.context.view_layer.update()
    scatta(os.path.join(CONFRONTO, "31c_braccio_umano_pugno.png"), (0.25, 0.42, 1.6), (0.0, 0.40, 0.0), lente=50.0)
    scatta(os.path.join(CONFRONTO, "31d_braccio_umano_pugno_lato.png"), (1.4, 0.45, 0.2), (0.0, 0.40, 0.0), lente=50.0)


if __name__ == "__main__":
    _c, _s, _g = main()
    provini(_c, _s, _g)
