# -*- coding: utf-8 -*-
"""GERARDO, LO SPRITE ALLA DOOM (D-287): otto lati per sette pose, da un modello vero.

    "D:/programs/blender5/blender.exe" --background --python tools/gerardo_blender.py

Produce assets/sprites/gerardo.png (l'atlante, 448 x 1024) e il provino
_confronto/gerardo.png. Vuole prima, in assets/models/_da_scaricare/gerardo/:

    gerardo_trellis.glb    il modello, fatto da TRELLIS sulla foto scontornata

E' UNA PERSONA VERA. Il capo dei soci del Gruppo Astrofili DLF, da una foto sola di
fronte, davanti all'osservatorio. Il dietro e i fianchi li ha ricostruiti TRELLIS
(Microsoft, licenza MIT): e' la parte generata, e su Steam va dichiarata. La foto e il
modello stanno in una cartella che git esclude - il repository e' pubblico, e la
faccia di una persona non ci va come sorgente. L'atlante si', perche' e' il gioco.

COME LO FACEVA ID SOFTWARE. I mostri di Doom erano modellini fotografati da otto lati,
un fotogramma per posa. Qui il modellino e' il .glb, e le fotografie le fa una camera
ortografica che gli gira intorno: riga 0 la faccia, poi ogni 45 gradi in senso
antiorario visto dall'alto (lo stesso verso in cui `gerardo.gd` sceglie la riga).
Colonne: fermo, quattro passi, due di parola. Le braccia restano ferme: vedi POSE.

NIENTE ARMATURA, E NON PER PIGRIZIA. Il modello arriva senza scheletro, e un'armatura di
Blender vuole il roll di ogni osso giusto perche' «avanti» voglia dire avanti: dieci
numeri da indovinare per una camminata di quattro pose. Qui le ossa sono punti di
rotazione in coordinate del mondo, e i vertici si deformano a mano con lo skinning
lineare - lo stesso conto che fa una scheda video, scritto in venti righe. Ogni posa
diventa una shape key.

LE ARTICOLAZIONI SONO MISURATE, non stimate: la sagoma frontale e quella di fianco,
riga per riga (D-287), sul modello fatto da quattro viste (fronte, fianco, dietro, tre
quarti). Le gambe si separano sotto 0,32 dell'altezza, le braccia si staccano dal busto
solo fra 0,51 e 0,54 - sotto, la mano tocca i pantaloncini; ginocchio 0,28, gomito 0,63,
spalla 0,80. Chi rifa' il modello rifaccia la misura: i numeri stanno in OSSA.

LA TESTA SI RIDIPINGE DIETRO, SE SERVE. Dalla sola foto di fronte TRELLIS aveva inventato
capelli neri sulla nuca di un uomo calvo con i lati grigi; con la foto da dietro la nuca
e' giusta. Si sostituiscono soltanto i pixel NERI della parte della testa che non guarda
avanti: i capelli grigi veri restano. La faccia resta quella della foto.

SI RENDERIZZA IL COLORE, NON LA LUCE (Workbench, piatto): lo sprite in gioco prende la
luce della scena (`shaded`), e un'ombra cotta dentro si sommerebbe alla sua.
"""
import math
import os

import bpy
import numpy as np
from mathutils import Matrix, Vector

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
MODELLO = os.path.join(RADICE, "assets", "models", "_da_scaricare", "gerardo",
                       "gerardo_trellis.glb")
ATLANTE = os.path.join(RADICE, "assets", "sprites", "gerardo.png")
PROVINO = os.path.join(RADICE, "_confronto", "gerardo.png")
LAVORO = os.path.join(QUI, "__modelli_cache__", "gerardo")

# QUANTO E' ALTO. Un uomo italiano di settant'anni: un metro e settantadue.
ALTEZZA = 1.72
# Il fotogramma: 64 x 128 pixel per 2,10 m, i piedi sul bordo basso. Lo legge
# `gerardo.tscn` (pixel_size 0,0164, figura a 1,05 m).
FOTO_L, FOTO_H = 64, 128
INQUADRATO = 2.10
# Si renderizza a quattro volte e si riduce: il pixel finale e' la media di sedici, non
# un campione a caso.
SOPRA = 4
DIREZIONI = 8

# --- le articolazioni, in unita' del modello (alto 1, piedi a -0,5, faccia verso -Y) --
# Ogni osso: (padre, perno). Le misure vengono dalle sagome (vedi l'intestazione).
OSSA = {
    "bacino":      (None,        (0.002, 0.030, -0.020)),
    "schiena":     ("bacino",    (0.002, 0.030, 0.000)),
    "testa":       ("schiena",   (0.000, 0.000, 0.345)),
    "coscia_px":   ("bacino",    (0.066, 0.036, -0.030)),
    "stinco_px":   ("coscia_px", (0.066, 0.034, -0.220)),
    "coscia_nx":   ("bacino",    (-0.062, 0.036, -0.030)),
    "stinco_nx":   ("coscia_nx", (-0.062, 0.034, -0.220)),
    "braccio_px":  ("schiena",   (0.128, 0.000, 0.295)),
    "avambr_px":   ("braccio_px", (0.140, 0.020, 0.130)),
    "braccio_nx":  ("schiena",   (-0.128, 0.000, 0.295)),
    "avambr_nx":   ("braccio_nx", (-0.142, 0.020, 0.130)),
}
CENTRO_X = 0.002
GINOCCHIO_Z = -0.220
GOMITO_Z = 0.130
COLLO_Z = 0.345
ANCA_Z = 0.000
# LE BRACCIA SONO CAPSULE attorno al loro asse, non «tutto quello che sta fuori dal busto».
# La prima stesura usava la seconda regola, e la mano appoggiata sulla tasca si portava
# dietro un lembo di pantaloncini a ogni gesto (visto nel provino). Assi e raggi dalle
# sagome: la manica e' larga dieci centimetri, l'avambraccio sei e mezzo, la mano sette.
# (asse da, asse a, raggio) per lato +x; il lato -x e' lo specchio sul suo perno.
BRACCIO = ((0.128, 0.000, 0.295), (0.140, 0.020, 0.130), 0.052)
AVAMBRACCIO = ((0.140, 0.020, 0.130), (0.138, 0.000, -0.030), 0.034)
MANO = ((0.138, 0.000, -0.030), (0.140, -0.005, -0.100), 0.036)
SFUMA = 0.012
# E SOLO FUORI DAL BUSTO: una capsula da cinque centimetri attorno alla spalla entrerebbe
# nel petto.
BUSTO_MEZZO = 0.105
SPALLA_Z = 0.300


def _liscio(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3.0 - 2.0 * t)


def _dentro(p, capsula, lato):
    """Quanto un punto sta dentro una capsula del braccio: 1 dentro, 0 oltre la sfumatura."""
    a, b, r = capsula
    if lato == "nx":
        # lo specchio del lato +x sul perno del suo osso: le due braccia non sono simmetriche
        # attorno al centro, quindi si sposta l'asse di quanto e' spostata la spalla
        d = OSSA["braccio_nx"][1][0] + OSSA["braccio_px"][1][0]
        a = (d - a[0], a[1], a[2])
        b = (d - b[0], b[1], b[2])
    A, B, P = Vector(a), Vector(b), Vector(p)
    t = max(0.0, min(1.0, (P - A).dot(B - A) / max((B - A).length_squared, 1e-9)))
    dist = (P - (A + (B - A) * t)).length
    return 1.0 - _liscio((dist - r) / SFUMA)


def pesi(p):
    """I pesi di un vertice, come {osso: peso}. Regioni misurate, bordi sfumati."""
    x, _y, z = p
    lato = "px" if x >= CENTRO_X else "nx"
    dx = abs(x - CENTRO_X)
    # LE BRACCIA: dentro le capsule e fuori dal busto
    if dx > BUSTO_MEZZO and z < SPALLA_Z + 0.03:
        w_su = _dentro(p, BRACCIO, lato)
        w_giu = max(_dentro(p, AVAMBRACCIO, lato), _dentro(p, MANO, lato))
        if w_su + w_giu > 0.0:
            sotto = _liscio((GOMITO_Z + 0.03 - z) / 0.06)          # 1 sotto il gomito
            verso_spalla = _liscio((z - (SPALLA_Z - 0.06)) / 0.08)  # 1 alla spalla
            braccio = max(w_su, w_giu)
            w_avambr = braccio * sotto
            w_braccio = braccio * (1.0 - sotto) * (1.0 - verso_spalla)
            resto = 1.0 - w_avambr - w_braccio
            altro = pesi_corpo(p, lato)
            fuori = {"avambr_" + lato: w_avambr, "braccio_" + lato: w_braccio}
            for k, w in altro.items():
                fuori[k] = fuori.get(k, 0.0) + w * resto
            return fuori
    return pesi_corpo(p, lato)


def pesi_corpo(p, lato):
    """I pesi di cio' che non e' braccio: testa, gambe, busto."""
    _x, _y, z = p
    # LA TESTA
    if z > COLLO_Z - 0.015:
        t = _liscio((z - (COLLO_Z - 0.015)) / 0.03)
        return {"testa": t, "schiena": 1.0 - t}
    # LE GAMBE: sotto l'anca, coi pantaloncini che seguono la coscia per meta'
    if z < ANCA_Z + 0.02:
        gamba = _liscio(((ANCA_Z + 0.02) - z) / 0.12)
        stinco = _liscio((GINOCCHIO_Z + 0.03 - z) / 0.06)
        return {"stinco_" + lato: gamba * stinco, "coscia_" + lato: gamba * (1.0 - stinco),
                "bacino": 1.0 - gamba}
    # IL BUSTO: la schiena dalla vita in su, il bacino sotto
    t = _liscio((z - ANCA_Z) / 0.12)
    return {"schiena": t, "bacino": 1.0 - t}


# --- le pose ------------------------------------------------------------------
# Angoli in gradi attorno all'asse X del mondo, che per chi guarda verso -Y e'
# l'asse del passo: NEGATIVO porta avanti (verso -Y) cio' che sta sotto il perno.
# Un vecchio cammina corto: diciotto gradi di coscia, non trenta.
# LE BRACCIA NON SI MUOVONO, e non per scelta di stile: TRELLIS ha fuso la mano col fianco
# dei pantaloncini, e ogni gesto della mano si portava dietro un lembo di stoffa (visto due
# volte nel provino, con due regole di pesi diverse). Cammina con le mani lungo i fianchi,
# come fa un uomo di settant'anni, e parlando annuisce.
POSE = [
    ("fermo", {}, 0.0),
    # A: px avanti, nx indietro sulla punta
    ("passo_1", {"coscia_px": -17, "stinco_px": 4, "coscia_nx": 13, "stinco_nx": 16}, -0.012),
    # B: passaggio, nx alzata che viene avanti
    ("passo_2", {"coscia_px": 3, "stinco_px": 3, "coscia_nx": -9, "stinco_nx": 32}, 0.0),
    # C: lo specchio di A
    ("passo_3", {"coscia_nx": -17, "stinco_nx": 4, "coscia_px": 13, "stinco_px": 16}, -0.012),
    # D: lo specchio di B
    ("passo_4", {"coscia_nx": 3, "stinco_nx": 3, "coscia_px": -9, "stinco_px": 32}, 0.0),
    # PARLA: la testa annuisce e il busto si sporge appena verso chi ascolta
    ("parla_1", {"testa": -6, "schiena": -1.5}, 0.0),
    ("parla_2", {"testa": 3, "schiena": 0.5}, 0.0),
]

def trasformate(posa, abbassa):
    """La matrice del mondo di ogni osso in questa posa: rotazione attorno al proprio
    perno, composta con quella del padre."""
    fuori = {}
    for nome, (padre, perno) in OSSA.items():
        P = Vector(perno)
        R = Matrix.Rotation(math.radians(posa.get(nome, 0.0)), 4, "X")
        locale = Matrix.Translation(P) @ R @ Matrix.Translation(-P)
        base = fuori[padre] if padre else Matrix.Translation((0.0, 0.0, abbassa))
        fuori[nome] = base @ locale
    return fuori


# --- la testa -----------------------------------------------------------------
# Sotto questa luminosita' un pixel della nuca e' «capello nero inventato». I grigi veri
# della foto da dietro stanno sopra 0,3.
NERO = 0.18


def ridipingi_nuca(ob):
    """I pixel scuri della testa che non guarda avanti diventano pelle sopra e grigio ai
    lati: i capelli neri inventati da TRELLIS su un uomo calvo."""
    mat = ob.active_material
    nodo = next(n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE")
    img = nodo.image
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    me = ob.data
    uv = me.uv_layers.active.data
    pelle = []
    da_fare = []
    for poli in me.polygons:
        zs = [me.vertices[i].co.z for i in poli.vertices]
        if min(zs) < COLLO_Z + 0.02:
            continue
        tri = [uv[li].uv.copy() for li in poli.loop_indices]
        n = poli.normal
        if n.y < -0.55 and max(zs) > 0.40:
            pelle.append(tri)          # la fronte: da qui si prende il colore della pelle
        elif n.y > -0.25:
            da_fare.append((tri, max(zs)))
    def pixel_di(tri):
        xs = [t.x * w for t in tri]
        ys = [t.y * h for t in tri]
        x0, x1 = int(max(0, min(xs))), int(min(w - 1, max(xs) + 1))
        y0, y1 = int(max(0, min(ys))), int(min(h - 1, max(ys) + 1))
        if x1 < x0 or y1 < y0:
            return []
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = [(t.x * w, t.y * h) for t in tri[:3]]
        d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(d) < 1e-9:
            return []
        l1 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / d
        l2 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / d
        dentro = (l1 >= -0.02) & (l2 >= -0.02) & (1 - l1 - l2 >= -0.02)
        return list(zip((gy[dentro] - 0.5).astype(int), (gx[dentro] - 0.5).astype(int)))
    campioni = [px[r, c, :3] for tri in pelle for (r, c) in pixel_di(tri)]
    colore_pelle = np.median(np.array(campioni), axis=0) if campioni else np.array([0.75, 0.55, 0.45])
    # grigio sporco e non argento: una frangia corta che lascia vedere la pelle sotto
    grigio = np.array([0.50, 0.47, 0.44])
    cambiati = 0
    for tri, ztop in da_fare:
        colore = colore_pelle if ztop > 0.455 else grigio
        for (r, c) in pixel_di(tri):
            if px[r, c, :3].max() < NERO:
                # la grana resta: la luminosita' del pixel di prima modula il colore nuovo
                px[r, c, :3] = colore * (0.75 + 0.9 * px[r, c, :3].max())
                cambiati += 1
    img.pixels[:] = px.ravel()
    print("[gerardo] nuca: %d pixel ridipinti, pelle %s" % (cambiati, np.round(colore_pelle, 2)))


# --- la scena -----------------------------------------------------------------
def prepara():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=MODELLO)
    ob = next(o for o in bpy.data.objects if o.type == "MESH")
    # le trasformate si cuociono: le ossa sono scritte in coordinate del mondo
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for m in bpy.data.materials:
        b = m.node_tree.nodes.get("Principled BSDF")
        if b is not None:
            b.inputs["Metallic"].default_value = 0.0
    ridipingi_nuca(ob)
    return ob


def _posato(p, pesi_p, T):
    """Un vertice nella posa: lo skinning lineare, la media delle ossa pesata."""
    q = Vector((0.0, 0.0, 0.0))
    tot = 0.0
    for osso, w in pesi_p.items():
        if w > 1e-4:
            q += (T[osso] @ p) * w
            tot += w
    return q / tot if tot > 0 else p


def chiavi(ob):
    """Una shape key per posa, deformata con lo skinning lineare."""
    me = ob.data
    riposo = [v.co.copy() for v in me.vertices]
    tabella = [pesi(p) for p in riposo]
    ob.shape_key_add(name="Basis")
    for nome, posa, abbassa in POSE:
        T = trasformate(posa, abbassa)
        k = ob.shape_key_add(name=nome)
        for i, p in enumerate(riposo):
            k.data[i].co = _posato(p, tabella[i], T)
    # IN SCALA, CON I PIEDI A TERRA E IL BACINO SULL'ASSE: l'asse verticale dello sprite e'
    # dove sta il nodo in gioco
    s = ALTEZZA / 0.997
    z0 = min(p.z for p in riposo)
    ob.location = (-CENTRO_X * s, -OSSA["bacino"][1][1] * s, -z0 * s)
    ob.scale = (s, s, s)


def scena():
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.light = "FLAT"
    sc.display.shading.color_type = "TEXTURE"
    sc.render.film_transparent = True
    sc.render.resolution_x = FOTO_L * SOPRA
    sc.render.resolution_y = FOTO_H * SOPRA
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    cam = bpy.data.objects.new("obiettivo", bpy.data.cameras.new("obiettivo"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = INQUADRATO
    return sc, cam


def fotografa(ob, sc, cam):
    os.makedirs(LAVORO, exist_ok=True)
    tavole = []
    for riga in range(DIREZIONI):
        a = math.radians(riga * 360.0 / DIREZIONI)
        d = 6.0
        # la camera gira in senso antiorario visto dall'alto, partendo dalla faccia (-Y)
        cam.location = (d * math.sin(a), -d * math.cos(a), INQUADRATO / 2.0)
        cam.rotation_euler = (math.radians(90.0), 0.0, a)
        for col, (nome, _posa, _abbassa) in enumerate(POSE):
            for k in ob.data.shape_keys.key_blocks[1:]:
                k.value = 1.0 if k.name == nome else 0.0
            via = os.path.join(LAVORO, "r%d_c%d.png" % (riga, col))
            sc.render.filepath = via
            bpy.ops.render.render(write_still=True)
            tavole.append((riga, col, via))
    return tavole


def _leggi(via):
    """Un PNG come array RGBA dall'alto in basso. Blender tiene le righe dal basso."""
    im = bpy.data.images.load(via)
    w, h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(im)
    return a


def _scrivi(a, via):
    h, w = a.shape[:2]
    im = bpy.data.images.new(os.path.basename(via), w, h, alpha=True)
    im.pixels[:] = np.ascontiguousarray(a[::-1]).ravel()
    im.filepath_raw = via
    im.file_format = "PNG"
    im.save()
    bpy.data.images.remove(im)


def atlante(tavole):
    fuori = np.zeros((FOTO_H * DIREZIONI, FOTO_L * len(POSE), 4), np.float32)
    for riga, col, via in tavole:
        a = _leggi(via)
        # MEDIA CON L'ALFA PREMOLTIPLICATA, poi un taglio netto: lo sprite in gioco scarta
        # sotto mezza opacita' (alpha_cut), e un bordo semitrasparente diventerebbe un alone
        al = a[:, :, 3:4]
        rgb = (a[:, :, :3] * al).reshape(FOTO_H, SOPRA, FOTO_L, SOPRA, 3).mean(axis=(1, 3))
        al = al.reshape(FOTO_H, SOPRA, FOTO_L, SOPRA, 1).mean(axis=(1, 3))
        col_ = np.where(al > 1e-4, rgb / np.maximum(al, 1e-4), 0.0)
        pieno = (al[:, :, 0] >= 0.5).astype(np.float32)
        fuori[riga * FOTO_H:(riga + 1) * FOTO_H, col * FOTO_L:(col + 1) * FOTO_L] =             np.dstack([np.clip(col_, 0.0, 1.0) * pieno[:, :, None], pieno])
    os.makedirs(os.path.dirname(ATLANTE), exist_ok=True)
    _scrivi(fuori, ATLANTE)
    # il provino: l'atlante ingrandito tre volte su un grigio, per guardarlo
    grigio = np.array([0.38, 0.38, 0.41], np.float32)
    prov = fuori[:, :, :3] * fuori[:, :, 3:4] + grigio * (1.0 - fuori[:, :, 3:4])
    prov = np.repeat(np.repeat(prov, 3, axis=0), 3, axis=1)
    os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
    _scrivi(np.dstack([prov, np.ones(prov.shape[:2], np.float32)]), PROVINO)
    print("[gerardo] atlante %s (%d x %d), provino %s" % (
        ATLANTE, fuori.shape[1], fuori.shape[0], PROVINO))


if not os.path.exists(MODELLO):
    raise SystemExit("[gerardo] manca %s: vedi l'intestazione" % MODELLO)
modello = prepara()
chiavi(modello)
s_, c_ = scena()
atlante(fotografa(modello, s_, c_))
