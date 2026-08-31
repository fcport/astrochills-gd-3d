# -*- coding: utf-8 -*-
"""Costruisce l'intero osservatorio in Blender, dalla stessa geometria della pianta.

    "D:/programs/blender5/blender.exe" --background --python tools/osservatorio_blender.py

Non ridisegna niente a mano: legge blocchi_edificio() da geometria.py, la stessa
funzione che genera il blockout navigabile in Godot. Se la pianta cambia, cambiano
insieme il disegno, il blockout e questo modello.

Produce assets/models/osservatorio.glb e due render di controllo.

Sistemi di riferimento: il blockout ragiona come Godot (Y in alto), Blender ha Z in
alto. La conversione e' (x, y, z) -> (x, -z, y), che e' una rotazione di 90 gradi
attorno a X: le rotazioni attorno a X restano quindi invariate.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)

# Rieseguendo lo script dentro una sessione Blender gia' aperta, Python riuserebbe la
# copia di geometria caricata la volta prima: si ricarica, o si lavora su misure vecchie.
import importlib   # noqa: E402
if "geometria" in sys.modules:
    importlib.reload(sys.modules["geometria"])

from geometria import (blocchi_edificio, blocchi_infissi, ante_porte, verifica_ante,   # noqa: E402
                       pezzi_anta,
                       CUPOLA, K, H_DOME_BASE, DOME_R, H_TETTO, SP_TETTO,
                       SALA_TELESCOPIO, R_PASS, W_PASS, H_PASS, SP_PASS, LUNGO_RAMPA,
                       DISL_RAMPA)
from modellare import applica_texture, metri_ripetizione, uv_a_scatola   # noqa: E402

RADICE = os.path.dirname(QUI)
CUPOLA_GLB = os.path.join(RADICE, "assets", "models", "cupola.glb")
TELESCOPIO_GLB = os.path.join(RADICE, "assets", "models", "telescopio.glb")
USCITA = os.path.join(RADICE, "assets", "models", "osservatorio.glb")
RENDER = os.path.join(RADICE, "_bmad-output", "planning-artifacts", "gdds",
                      "gdd-astrochills-gd-3d-2026-08-24")

# --- a quale parte appartiene ogni blocco, dal suo nome ----------------------
PARTI = [
    (("Pav",), "Pavimento", (0.34, 0.32, 0.30)),
    (("Soff",), "Soffitto", (0.72, 0.71, 0.69)),
    (("TettoCup", "Tetto"), "Tetto", (0.20, 0.19, 0.18)),
    (("Pass",), "Passerella", (0.42, 0.35, 0.26)),
    (("Rampa", "Scal"), "Rampa", (0.46, 0.39, 0.29)),
    (("Pilastro", "Tubo"), "Montatura", (0.24, 0.26, 0.30)),
    # PRIMA di "Telaio": parte_di() confronta con startswith, e "TelaioMet"
    # comincia per "Telaio" - messo dopo non verrebbe mai raggiunto.
    (("TelaioMet",), "TelaiMetallo", (0.50, 0.54, 0.50)),
    (("Telaio",), "Telai", (0.30, 0.22, 0.15)),
    (("Anta",), "Ante", (0.38, 0.28, 0.19)),
    (("Davanzale",), "Davanzali", (0.62, 0.60, 0.57)),
    (("Vetro",), "Vetri", (0.55, 0.68, 0.72)),
]
MURI = ("Muri", (0.80, 0.78, 0.74))


def parte_di(nome):
    for prefissi, etichetta, colore in PARTI:
        if nome.startswith(prefissi):
            return etichetta, colore
    return MURI


# I materiali la cui TINTA conta: la mappa va MOLTIPLICATA per il colore, non usata
# com'e'. Serve saperlo qui perche' `applica_texture` prende la tinta dalla tavolozza
# di modellare.py, dove questi nomi non esistono: non trovandoli moltiplicava per
# bianco, cioe' non tingeva. Il set "metallo" e' una lamiera NUDA e chiara, quindi
# senza tinta il telaio del magazzino usciva color alluminio mentre l'anta - che in
# scena e' tinta da Godot - usciva verde scuro. Stesso colore dichiarato, due
# risultati diversi, e la causa non era in nessuno dei due posti dove l'ho cercata.
TINTI_QUI = ("AnteMetallo", "TelaiMetallo")


def materiale(nome, colore):
    if nome in bpy.data.materials:
        return bpy.data.materials[nome]
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    principled = m.node_tree.nodes["Principled BSDF"]
    principled.inputs["Base Color"].default_value = (*colore, 1.0)
    principled.inputs["Roughness"].default_value = 0.85
    if nome == "Vetri":
        # La TRASMISSIONE di Blender rende un vetro bellissimo nei render, ma non
        # attraversa il glTF: Godot importerebbe una lastra opaca. Quello che
        # sopravvive all'export e' l'ALPHA, quindi il vetro si fa con quello.
        principled.inputs["Roughness"].default_value = 0.05
        principled.inputs["IOR"].default_value = 1.45
        # come il vetro delle teche: a 0,18 la finestra era una lastra opaca e
        # di notte non si vedeva fuori
        principled.inputs["Alpha"].default_value = 0.07
        principled.inputs["Base Color"].default_value = (0.80, 0.86, 0.88, 0.07)
        for attributo, valore in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            if hasattr(m, attributo):
                setattr(m, attributo, valore)
        m.use_backface_culling = False
    applica_texture(m, nome, tinta=colore if nome in TINTI_QUI else None)
    return m


def pulisci():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def costruisci():
    """Un oggetto per parte, ciascuno con tutti i suoi volumi in una mesh sola."""
    gruppi = {}
    for (cx, cy, cz, sx, sy, sz, nome, rot, *resto) in blocchi_edificio() + blocchi_infissi():
        if nome.startswith("TettoCup"):
            continue          # lo rifa' tetto_forato(): a strisce il bordo e' a gradini
        if nome.startswith(("Pilastro", "Tubo")):
            continue          # li rimpiazza il modello del telescopio
        if nome.startswith(("Pass", "Rampa", "Scal", "Parapetto", "Montatura")):
            continue          # sono COLLISIONE: la forma la danno passerella_e_scala()
                              # e il modello del telescopio
        etichetta, colore = parte_di(nome)
        bm = gruppi.setdefault(etichetta, (bmesh.new(), colore))[0]
        # (x, y, z) di Godot -> (x, -z, y) di Blender
        # una rotazione attorno a Z di gioco e' attorno a -Y in Blender
        rotz = resto[0] if resto else 0.0
        roty = resto[1] if len(resto) > 1 else 0.0
        # una rotazione attorno a Y di gioco e' attorno a Z in Blender, di segno
        # opposto: la conversione (x, y, z) -> (x, -z, y) ribalta il verso
        if abs(roty) > 1e-9:
            giro = Matrix.Rotation(-roty, 4, "Z")
        elif abs(rotz) > 1e-9:
            giro = Matrix.Rotation(-rotz, 4, "Y")
        else:
            giro = Matrix.Rotation(rot, 4, "X")
        posa = Matrix.Translation(Vector((cx, -cz, cy))) @ giro
        bmesh.ops.create_cube(bm, size=1.0, matrix=posa @ Matrix.Diagonal(Vector((sx, sz, sy, 1.0))))

    oggetti = []
    for etichetta, (bm, colore) in gruppi.items():
        # facce interne fra volumi adiacenti: si tolgono fondendo i vertici coincidenti
        bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-4)
        malla = bpy.data.meshes.new(etichetta)
        uv_a_scatola(bm, metri_ripetizione(etichetta))
        bm.to_mesh(malla)
        bm.free()
        malla.materials.append(materiale(etichetta, colore))
        oggetto = bpy.data.objects.new(etichetta, malla)
        bpy.context.collection.objects.link(oggetto)
        oggetti.append(oggetto)
    return oggetti


# quanto e' spalancata ciascuna porta, in gradi. L'ingresso si apre verso il prato.
APERTE = {"ingresso": 80.0}


def crea_ante():
    """Un oggetto per anta, con l'origine SUL CARDINE.

    Un pezzo che ruota si modella dal perno: e' la stessa regola dei portelli della
    cupola. Con l'origine al centro, aprire la porta la stacca dal telaio.
    """
    fatte = []
    for a in ante_porte():
        L, H_A, T = a["larghezza"], a["altezza"], a["spessore"]
        _d = Vector((a["direzione"][0], -a["direzione"][2], 0.0))
        _n = Vector((a["normale"][0], -a["normale"][2], 0.0))
        a["_verso"] = 1.0 if (_d.x * _n.y - _d.y * _n.x) > 0 else -1.0
        bm = bmesh.new()
        # I pezzi vengono da geometria.pezzi_anta(): gli stessi che il generatore
        # mette nel nodo Door in gioco. Il lato interno qui sta lungo -Y locale
        # quando verso vale +1.
        for (lungo, alto, lato, sx, sy, sz, _etichetta) in pezzi_anta(a):
            bmesh.ops.create_cube(bm, size=1.0, matrix=(
                Matrix.Translation(Vector((lungo, lato * a["_verso"], alto)))
                @ Matrix.Diagonal(Vector((sx, sz, sy, 1.0)))))

        malla = bpy.data.meshes.new("Anta_" + a["nome"])
        uv_a_scatola(bm)
        bm.to_mesh(malla)
        bm.free()
        malla.materials.append(materiale("AnteMetallo", (0.50, 0.54, 0.50))
                               if a.get("metallo")
                               else materiale("Ante", (0.38, 0.28, 0.19)))
        oggetto = bpy.data.objects.new("Anta_" + a["nome"], malla)
        bpy.context.collection.objects.link(oggetto)

        # gioco (x, y, z) -> Blender (x, -z, y): perno, direzione e normale
        px, _, pz = a["perno"]
        dx, _, dz = a["direzione"]
        nx, _, nz = a["normale"]
        d = Vector((dx, -dz, 0.0))
        n = Vector((nx, -nz, 0.0))
        oggetto.location = (px, -pz, 0.0)
        verso = a["_verso"]
        oggetto.rotation_euler = (0.0, 0.0,
                                  math.atan2(d.y, d.x) + verso * math.radians(APERTE.get(a["nome"], 0.0)))
        fatte.append(oggetto)
    return fatte


def passerella_e_scala():
    """L'impalcato anulare con il parapetto, e la scala con i gradini veri.

    Nel blockout la passerella e' un anello di sedici scatole e la rampa un piano
    inclinato: bastano a camminarci, non a guardarle. Nelle foto ha un parapetto
    tubolare a due correnti e una scala a gradini — ed e' l'oggetto piu' vicino
    all'occhio di chi osserva, perche' ci si sta sopra.

    IL PARAPETTO SI INTERROMPE DOVE ARRIVA LA SCALA. Una ringhiera continua
    chiuderebbe l'unico accesso: il varco non e' un dettaglio, e' il motivo per
    cui la passerella e' raggiungibile.
    """
    cx, cz = CUPOLA[0] * K, CUPOLA[1] * K
    calpestio = H_PASS + SP_PASS / 2
    r_int, r_est = R_PASS - W_PASS / 2, R_PASS + W_PASS / 2
    SETTORI = 72
    # la scala arriva dal lato -Y di Blender, cioe' da z crescente in gioco
    varco = math.radians(-90.0)
    mezzo_varco = math.radians(16.0)

    def fuori_dal_varco(ang):
        d = math.atan2(math.sin(ang - varco), math.cos(ang - varco))
        return abs(d) > mezzo_varco

    bm = bmesh.new()
    # --- impalcato: una corona circolare con lo spessore ---------------------
    for i in range(SETTORI):
        a0 = 2 * math.pi * i / SETTORI
        a1 = 2 * math.pi * (i + 1) / SETTORI
        quad = []
        for (r, a) in ((r_int, a0), (r_est, a0), (r_est, a1), (r_int, a1)):
            quad.append((cx + r * math.cos(a), -cz + r * math.sin(a)))
        for z in (calpestio - SP_PASS, calpestio):
            for (x, y) in quad:
                bm.verts.new((x, y, z))
    bm.verts.ensure_lookup_table()
    for i in range(SETTORI):
        b = i * 8
        giu = [bm.verts[b + k] for k in range(4)]
        su = [bm.verts[b + 4 + k] for k in range(4)]
        bm.faces.new(su)
        bm.faces.new(list(reversed(giu)))
        for k in range(4):
            k2 = (k + 1) % 4
            bm.faces.new((giu[k], giu[k2], su[k2], su[k]))

    # --- parapetto: due correnti e i montanti, sui due bordi -----------------
    # SOLO IL BORDO ESTERNO. Quella interna proteggeva il pozzo centrale, che
    # adesso e' pieno: e' sparita dalla collisione in geometria.py e deve sparire
    # anche da qui, o resta una ringhiera che si vede e non si tocca - e in mezzo
    # a un passaggio da un metro e cinque e' anche l'unica cosa in cui inciampare.
    for raggio, verso in ((r_est, +1),):
        for quota in (calpestio + 0.50, calpestio + 1.00):
            for i in range(SETTORI):
                a0 = 2 * math.pi * i / SETTORI
                a1 = 2 * math.pi * (i + 1) / SETTORI
                if not (fuori_dal_varco(a0) and fuori_dal_varco(a1)):
                    continue
                p0 = Vector((cx + raggio * math.cos(a0), -cz + raggio * math.sin(a0), quota))
                p1 = Vector((cx + raggio * math.cos(a1), -cz + raggio * math.sin(a1), quota))
                d = p1 - p0
                bmesh.ops.create_cone(
                    bm, cap_ends=True, cap_tris=False, segments=8,
                    radius1=0.022, radius2=0.022, depth=d.length * 1.02,
                    matrix=Matrix.Translation((p0 + p1) / 2) @ d.to_track_quat("Z", "Y").to_matrix().to_4x4())
        for i in range(0, SETTORI, 6):
            a = 2 * math.pi * i / SETTORI
            if not fuori_dal_varco(a):
                continue
            bmesh.ops.create_cone(
                bm, cap_ends=True, cap_tris=False, segments=8,
                radius1=0.024, radius2=0.024, depth=1.00,
                matrix=Matrix.Translation(Vector((cx + raggio * math.cos(a),
                                                  -cz + raggio * math.sin(a),
                                                  calpestio + 0.50))))

    # --- la scala: alzate vere sopra la rampa di collisione -----------------
    N_GRAD = 4
    alzata = DISL_RAMPA / N_GRAD
    pedata = LUNGO_RAMPA / N_GRAD
    piede_y = -(cz + r_est + LUNGO_RAMPA)
    for g in range(N_GRAD):
        h = alzata * (g + 1)
        y = piede_y + pedata * (g + 0.5)
        bmesh.ops.create_cube(bm, size=1.0, matrix=(
            Matrix.Translation(Vector((cx, y, h - 0.025)))
            @ Matrix.Diagonal(Vector((1.00, pedata, 0.05, 1.0)))))
        bmesh.ops.create_cube(bm, size=1.0, matrix=(
            Matrix.Translation(Vector((cx, y - pedata / 2, h - alzata / 2)))
            @ Matrix.Diagonal(Vector((1.00, 0.04, alzata, 1.0)))))
    # IL CORRIMANO POGGIA SU QUALCOSA. Erano due tubi che partivano a 95 cm da
    # terra e finivano in aria: nessun montante sotto, appesi al niente. Un
    # corrimano e' l'ultima cosa a cui ci si aggrappa, e vederlo sospeso e' la
    # differenza fra una scala e un disegno di una scala.
    H_CORRIMANO = 0.95
    # IL PIANEROTTOLO. Una scala dritta che arriva su un anello lascia due lune
    # vuote ai lati dell'ultimo gradino: il bordo dell'impalcato e' curvo, la
    # pedata e' diritta, e fra i due resta un buco a mezzaluna. Da sopra si vedeva
    # che scala e passerella non si toccavano. Questa lastra copre il raccordo per
    # tutta la larghezza della scala e sborda dentro l'anello di venti centimetri.
    bmesh.ops.create_cube(bm, size=1.0, matrix=(
        Matrix.Translation(Vector((cx, piede_y + LUNGO_RAMPA + 0.10, DISL_RAMPA - 0.025)))
        @ Matrix.Diagonal(Vector((1.00, 0.40, 0.05, 1.0)))))
    for lato in (-1, 1):
        x = cx + lato * 0.52
        a = Vector((x, piede_y, H_CORRIMANO))
        b_ = Vector((x, piede_y + LUNGO_RAMPA, DISL_RAMPA + H_CORRIMANO))
        d = b_ - a
        bmesh.ops.create_cone(
            bm, cap_ends=True, cap_tris=False, segments=8, radius1=0.022, radius2=0.022,
            depth=d.length, matrix=Matrix.Translation((a + b_) / 2) @ d.to_track_quat("Z", "Y").to_matrix().to_4x4())
        # i montanti: a terra, a meta' rampa e in cima, ognuno lungo quanto serve
        # per arrivare dal gradino che ha sotto al corrimano che ha sopra
        for t in (0.0, 0.5, 1.0):
            y = piede_y + LUNGO_RAMPA * t
            sotto = DISL_RAMPA * t
            altezza = H_CORRIMANO
            bmesh.ops.create_cone(
                bm, cap_ends=True, cap_tris=False, segments=8,
                radius1=0.024, radius2=0.024, depth=altezza,
                matrix=Matrix.Translation(Vector((x, y, sotto + altezza / 2))))

    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    malla = bpy.data.meshes.new("Passerella")
    uv_a_scatola(bm)
    bm.to_mesh(malla)
    bm.free()
    malla.materials.append(materiale("Passerella", (0.42, 0.35, 0.26)))
    o = bpy.data.objects.new("Passerella", malla)
    bpy.context.collection.objects.link(o)
    return o


def tetto_forato():
    """Il tetto della sala del telescopio: una lastra sola con il foro tondo della cupola.

    Il generatore lo produce a strisce da 25 cm, che al blockout bastano ma da vicino
    lasciano il bordo a gradini. Qui il foro si taglia davvero, con una booleana: e' il
    caso in cui serve — a differenza della fenditura della cupola, che sta su due piani
    e si taglia meglio con bisect.
    """
    x0, z0, x1, z1 = (v * K for v in SALA_TELESCOPIO)
    SPORTO = 0.30          # verso l'esterno; verso l'interno si sovrappone agli altri tetti
    bm = bmesh.new()
    cx_, cz_ = (x0 - SPORTO + x1 + 0.30) / 2, (z0 - SPORTO + z1 + 0.30) / 2
    lx, lz = (x1 + 0.30) - (x0 - SPORTO), (z1 + 0.30) - (z0 - SPORTO)
    bmesh.ops.create_cube(bm, size=1.0, matrix=(
        Matrix.Translation(Vector((cx_, -cz_, H_TETTO + SP_TETTO / 2)))
        @ Matrix.Diagonal(Vector((lx, lz, SP_TETTO, 1.0)))))
    malla = bpy.data.meshes.new("TettoCupola")
    uv_a_scatola(bm)
    bm.to_mesh(malla); bm.free()
    malla.materials.append(materiale("Tetto", (0.20, 0.19, 0.18)))
    lastra = bpy.data.objects.new("TettoCupola", malla)
    bpy.context.collection.objects.link(lastra)

    # il cilindro che buca: raggio della cupola, alto abbastanza da attraversare la lastra
    bmc = bmesh.new()
    bmesh.ops.create_cone(bmc, cap_ends=True, cap_tris=False, segments=96,
                          radius1=DOME_R, radius2=DOME_R, depth=2.0,
                          matrix=Matrix.Translation(Vector((CUPOLA[0] * K, -CUPOLA[1] * K, H_TETTO))))
    malla_c = bpy.data.meshes.new("_foro")
    bmc.to_mesh(malla_c); bmc.free()
    fresa = bpy.data.objects.new("_foro", malla_c)
    bpy.context.collection.objects.link(fresa)

    mod = lastra.modifiers.new("Foro", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = fresa
    mod.solver = "EXACT"
    bpy.context.view_layer.objects.active = lastra
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(fresa, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    lastra.select_set(True)
    bpy.context.view_layer.objects.active = lastra
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(30.0))
    return lastra


def porta_il_telescopio():
    """Il telescopio al centro della sala, sul suo pilastro."""
    prima = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=TELESCOPIO_GLB)
    nuovi = [o for o in bpy.data.objects if o not in prima]
    radici = [o for o in nuovi if o.parent is None]
    for o in radici:
        o.location = (CUPOLA[0] * K, -CUPOLA[1] * K, 0.0)
    return nuovi


def porta_la_cupola():
    prima = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=CUPOLA_GLB)
    nuovi = [o for o in bpy.data.objects if o not in prima]
    # la cupola sta al centro della sala, appoggiata alla quota di gronda
    cx, cz = CUPOLA[0] * K, CUPOLA[1] * K
    perno = bpy.data.objects.new("Cupola", None)
    bpy.context.collection.objects.link(perno)
    perno.location = (cx, -cz, H_DOME_BASE)
    for o in nuovi:
        if o.parent is None:
            o.parent = perno
    return [perno] + nuovi


pulisci()
parti = costruisci()
ante = crea_ante()
ante_coll = bpy.data.collections.new("Ante")
bpy.context.scene.collection.children.link(ante_coll)
for o in ante:
    bpy.context.collection.objects.unlink(o)
    ante_coll.objects.link(o)
tetto_cupola = tetto_forato()
passerella = passerella_e_scala()

# Tetto e soffitto in una collezione loro: dall'alto nascondono tutto, e volerli
# togliere per guardare dentro e' la prima cosa che si desidera.
copertura = bpy.data.collections.new("Copertura")
bpy.context.scene.collection.children.link(copertura)
for o in parti:
    if o.name in ("Tetto", "Soffitto"):
        bpy.context.collection.objects.unlink(o)
        copertura.objects.link(o)
cupola = porta_la_cupola()
telescopio = porta_il_telescopio()

print()
for o in parti:
    print("  %-12s %6d facce" % (o.name, len(o.data.polygons)))

# --- controlli ---------------------------------------------------------------
problemi = list(verifica_ante())

# la booleana puo' fallire senza dire niente: il foro si misura, non si suppone
_cx, _cz = CUPOLA[0] * K, -CUPOLA[1] * K
_r = [math.hypot(v.co.x - _cx, v.co.y - _cz) for v in tetto_cupola.data.vertices]
_sul_cerchio = [d for d in _r if abs(d - DOME_R) < 0.02]
print("  %-12s %6d facce   %d vertici sul bordo del foro (r=%.2f)"
      % (tetto_cupola.name, len(tetto_cupola.data.polygons), len(_sul_cerchio), DOME_R))
if len(_sul_cerchio) < 60:
    problemi.append("il foro della cupola non e' stato tagliato: %d vertici sul cerchio" % len(_sul_cerchio))
attese = {"Muri", "Pavimento", "Soffitto", "Tetto", "Telai", "Vetri", "Davanzali"}
trovate = {o.name for o in parti}
if attese - trovate:
    problemi.append("parti mancanti: %s" % ", ".join(sorted(attese - trovate)))

tutti = [o for o in parti if o.data.vertices]
minimi = [min((o.matrix_world @ v.co)[i] for o in tutti for v in o.data.vertices) for i in range(3)]
massimi = [max((o.matrix_world @ v.co)[i] for o in tutti for v in o.data.vertices) for i in range(3)]
print("\n  ingombro X %.2f..%.2f   Y %.2f..%.2f   Z %.2f..%.2f" % (
    minimi[0], massimi[0], minimi[1], massimi[1], minimi[2], massimi[2]))
if abs((massimi[0] - minimi[0]) - 19.0) > 0.8:
    problemi.append("larghezza %.2f invece di ~19 m" % (massimi[0] - minimi[0]))
if abs((massimi[1] - minimi[1]) - 9.5) > 0.8:
    problemi.append("profondita' %.2f invece di ~9,5 m" % (massimi[1] - minimi[1]))

if problemi:
    print("\nATTENZIONE:")
    for p in problemi:
        print("  " + p)
    sys.exit(1)

os.makedirs(os.path.dirname(USCITA), exist_ok=True)
# si esporta tutto TRANNE le ante: quelle in gioco sono nodi Door che ruotano
bpy.ops.object.select_all(action="SELECT")
for o in ante:
    o.select_set(False)
bpy.ops.export_scene.gltf(filepath=USCITA, export_format="GLB", use_selection=True, export_apply=True)
print("\nscritto %s" % USCITA)


# --- render di controllo -----------------------------------------------------
scena = bpy.context.scene
scena.render.resolution_x, scena.render.resolution_y = 1100, 660
# Il nome del motore cambia fra le versioni (EEVEE_NEXT in 4.x, EEVEE in 5.x): si legge
# l'elenco invece di indovinarlo. Sbagliando si finisce in Workbench, che IGNORA i
# materiali e rende tutto grigio uniforme, facendo sembrare il modello privo di dettagli.
_motori = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scena.render.engine = next((m for m in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "CYCLES") if m in _motori), _motori[0])
print("motore di render: %s" % scena.render.engine)

# IL TERRENO ESISTE SOLO PER I RENDER, e serve piu' di quanto sembri: senza, la
# camera che guarda la facciata dall'alto passa SOTTO i muri e inquadra
# l'intradosso del solaio, che dal basso legge come una fascia di pavimento che
# sborda tutt'intorno all'edificio. Il difetto non era il solaio - che si ferma
# esatto sul filo interno del muro - era che di fuori non c'era niente.
#
# In gioco il prato c'e' gia' (lo mette gen_blockout), quindi qui basta al banco
# di posa: si aggiunge DOPO l'export, e nel modello non entra.
_bm_terra = bmesh.new()
bmesh.ops.create_grid(_bm_terra, x_segments=1, y_segments=1, size=40.0,
                      matrix=Matrix.Translation(Vector((9.5, -4.5, -0.13))))
_malla_terra = bpy.data.meshes.new("Terreno")
_bm_terra.to_mesh(_malla_terra)
_bm_terra.free()
_malla_terra.materials.append(materiale("Terreno", (0.20, 0.24, 0.16)))
bpy.context.collection.objects.link(bpy.data.objects.new("Terreno", _malla_terra))

mondo = bpy.data.worlds.new("Cielo")
mondo.use_nodes = True
mondo.node_tree.nodes["Background"].inputs[0].default_value = (0.26, 0.30, 0.38, 1)
mondo.node_tree.nodes["Background"].inputs[1].default_value = 1.0
scena.world = mondo

sole_dati = bpy.data.lights.new("Sole", type="SUN")
sole_dati.energy = 3.5
sole = bpy.data.objects.new("Sole", sole_dati)
sole.rotation_euler = (math.radians(55), 0, math.radians(40))
bpy.context.collection.objects.link(sole)

camera_dati = bpy.data.cameras.new("Camera")
camera = bpy.data.objects.new("Camera", camera_dati)
bpy.context.collection.objects.link(camera)
scena.camera = camera

# la camera si punta con un vincolo, non con angoli calcolati a mano
bersaglio = bpy.data.objects.new("Bersaglio", None)
bpy.context.collection.objects.link(bersaglio)
vincolo = camera.constraints.new("TRACK_TO")
vincolo.target = bersaglio
vincolo.track_axis = "TRACK_NEGATIVE_Z"
vincolo.up_axis = "UP_Y"


def scatta(nome, posizione, mira, lente=32.0):
    camera.location = posizione
    camera_dati.lens = lente
    bersaglio.location = mira
    bpy.context.view_layer.update()
    scena.render.filepath = os.path.join(RENDER, nome)
    bpy.ops.render.render(write_still=True)
    print("scritto %s" % scena.render.filepath)


scatta("osservatorio-aereo.png", (30.0, -30.0, 20.0), (9.0, -4.5, 1.2), lente=42.0)
scatta("osservatorio-facciata.png", (13.0, -24.0, 4.5), (7.5, -6.0, 2.0), lente=45.0)
# ravvicinato sull'ingresso: e' qui che si vede se gli infissi ci sono
scatta("osservatorio-cupola.png", (9.5, -12.0, 7.5), (2.6, -2.5, 3.3), lente=52.0)
scatta("osservatorio-telescopio.png", (5.4, -5.6, 2.15), (2.6, -2.5, 2.0), lente=30.0)
# dentro la sala: oltre y=-6,5 si finisce nel muro
scatta("osservatorio-passerella.png", (4.85, -6.15, 2.35), (2.9, -3.7, 0.9), lente=22.0)
scatta("osservatorio-ingresso.png", (15.5, -16.5, 2.6), (10.4, -9.2, 1.2), lente=42.0)
