# -*- coding: utf-8 -*-
"""Il telescopio dell'osservatorio: riflettore su montatura equatoriale a forcella.

    "D:/programs/blender5/blender.exe" --background --python tools/telescopio_blender.py

Produce assets/models/telescopio.glb.

MODELLATO SULLE FOTO DELL'OSSERVATORIO REALE, non su un'idea generica di telescopio.
Da quelle vengono: la forcella che regge il tubo su due perni invece di un braccio
solo, la cella del primario bullonata in fondo, i DUE tubi guida paralleli montati
sopra il principale con i loro collari, e il focheggiatore vicino alla bocca.

LA GERARCHIA E' IL PUNTO, PIU' DELLE FORME. Il telescopio dovra' inseguire un
oggetto in cielo, e un inseguimento equatoriale e' UNA rotazione sola attorno
all'asse polare. Perche' funzioni, quell'asse deve essere inclinato della
LATITUDINE del luogo e i nodi devono essere annidati nell'ordine giusto:

    Telescopio            fermo, alla base del pilastro
    └── AssePolare        inclinato di 43,9 gradi: qui gira l'ascensione retta
        └── AsseDec       qui si punta la declinazione, una volta per bersaglio
            └── il tubo, le guide, la cella, il focheggiatore

Con questa catena inseguire e' ruotare UN nodo a velocita' costante. Con un asse
verticale servirebbero due motori coordinati, ed e' esattamente il motivo per cui
le montature equatoriali esistono.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

QUI_ = os.path.dirname(os.path.abspath(__file__))
if QUI_ not in sys.path:
    sys.path.insert(0, QUI_)
from modellare import uv_a_scatola   # noqa: E402

QUI = os.path.dirname(os.path.abspath(__file__))
RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "telescopio.glb")

LATITUDINE = 43.9          # Montegrimano (PU): l'asse polare si inclina di tanto

# --- misure, in metri --------------------------------------------------------
H_PILASTRO, D_PILASTRO = 1.00, 0.50
H_BASE, L_BASE = 0.34, 0.72          # il basamento della montatura, sopra il pilastro
BRACCIO_L, BRACCIO_S = 1.05, 0.11    # i due bracci della forcella
LUCE_FORCELLA = 0.76                 # distanza fra i bracci: ci passa il tubo
D_TUBO, L_TUBO = 0.46, 1.90
D_CELLA, H_CELLA = 0.53, 0.24
GUIDE = ((0.13, 1.15, 0.135), (0.095, 0.88, -0.125))  # (diametro, lunghezza, scostamento laterale)
D_FUOCO, L_FUOCO = 0.11, 0.26

COLORI = {
    "Pilastro": (0.62, 0.61, 0.58), "Montatura": (0.82, 0.82, 0.80),
    "Tubo": (0.09, 0.15, 0.33), "Collari": (0.07, 0.07, 0.08),
    "Guide": (0.70, 0.71, 0.72), "Cella": (0.10, 0.10, 0.11),
    "Ottica": (0.16, 0.17, 0.19),
}


def materiale(nome):
    if nome in bpy.data.materials:
        return bpy.data.materials[nome]
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = (*COLORI[nome], 1.0)
    p.inputs["Roughness"].default_value = 0.45 if nome in ("Tubo", "Guide") else 0.7
    p.inputs["Metallic"].default_value = 0.6 if nome in ("Guide", "Ottica") else 0.1
    return m


def cilindro(bm, raggio, altezza, matrice, lati=32):
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=lati,
                          radius1=raggio, radius2=raggio, depth=altezza, matrix=matrice)


def scatola(bm, dimensioni, matrice):
    bmesh.ops.create_cube(bm, size=1.0, matrix=matrice @ Matrix.Diagonal(Vector((*dimensioni, 1.0))))


def oggetto(nome, bm, genitore=None, posizione=(0, 0, 0)):
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    malla = bpy.data.meshes.new(nome)
    uv_a_scatola(bm)
    bm.to_mesh(malla)
    bm.free()
    malla.materials.append(materiale(nome))
    o = bpy.data.objects.new(nome, malla)
    bpy.context.collection.objects.link(o)
    o.location = posizione
    if genitore is not None:
        o.parent = genitore
    return o


def perno(nome, genitore=None, posizione=(0, 0, 0), rotazione=(0, 0, 0)):
    e = bpy.data.objects.new(nome, None)
    bpy.context.collection.objects.link(e)
    e.location = posizione
    e.rotation_euler = rotazione
    if genitore is not None:
        e.parent = genitore
    return e


bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

radice = perno("Telescopio")

# --- il pilastro: fisso nel pavimento, non un treppiede ----------------------
bm = bmesh.new()
cilindro(bm, D_PILASTRO / 2, H_PILASTRO, Matrix.Translation(Vector((0, 0, H_PILASTRO / 2))))
cilindro(bm, D_PILASTRO / 2 + 0.09, 0.10, Matrix.Translation(Vector((0, 0, 0.05))))   # plinto
oggetto("Pilastro", bm, radice)

# --- il basamento della montatura --------------------------------------------
bm = bmesh.new()
scatola(bm, (L_BASE, L_BASE, H_BASE), Matrix.Translation(Vector((0, 0, H_PILASTRO + H_BASE / 2))))
oggetto("Montatura", bm, radice)

# --- l'asse polare: qui gira l'ascensione retta, ed e' inclinato -------------
altezza_asse = H_PILASTRO + H_BASE
asse_polare = perno("AssePolare", radice, (0, 0, altezza_asse),
                    (math.radians(90.0 - LATITUDINE), 0, 0))

# il corpo che porta la forcella, lungo l'asse polare (asse Z locale)
bm = bmesh.new()
cilindro(bm, 0.17, 0.52, Matrix.Translation(Vector((0, 0, 0.20))))
oggetto("Montatura", bm, asse_polare)

# --- l'asse di declinazione: la forcella e cio' che regge -------------------
asse_dec = perno("AsseDec", asse_polare, (0, 0, 0.62))

bm = bmesh.new()
scatola(bm, (LUCE_FORCELLA + 2 * BRACCIO_S, BRACCIO_S * 1.4, 0.14),
        Matrix.Translation(Vector((0, 0, 0.07))))          # la traversa che unisce i bracci
for lato in (-1, 1):
    scatola(bm, (BRACCIO_S, BRACCIO_S, BRACCIO_L),
            Matrix.Translation(Vector((lato * LUCE_FORCELLA / 2, 0, BRACCIO_L / 2 + 0.10))))
    # il perno su cui il tubo bascula, in punta ai bracci
    cilindro(bm, 0.075, 0.12,
             Matrix.Translation(Vector((lato * (LUCE_FORCELLA / 2 - 0.04), 0, BRACCIO_L * 0.72)))
             @ Matrix.Rotation(math.radians(90), 4, "Y"), lati=20)
oggetto("Montatura", bm, asse_dec)

# --- il tubo, dentro la forcella: bascula in declinazione -------------------
tubo_perno = perno("Tubo", asse_dec, (0, 0, BRACCIO_L * 0.72), (math.radians(-81.0), 0, 0))

bm = bmesh.new()
cilindro(bm, D_TUBO / 2, L_TUBO, Matrix.Translation(Vector((0, 0, 0))))
oggetto("Tubo", bm, tubo_perno)

bm = bmesh.new()
for z in (-0.34, 0.30):    # i collari di fissaggio alla forcella
    cilindro(bm, D_TUBO / 2 + 0.022, 0.075, Matrix.Translation(Vector((0, 0, z))))
oggetto("Collari", bm, tubo_perno)

bm = bmesh.new()
cilindro(bm, D_CELLA / 2, H_CELLA, Matrix.Translation(Vector((0, 0, -L_TUBO / 2 - H_CELLA / 2 + 0.02))), lati=6)
oggetto("Cella", bm, tubo_perno)

# --- i due tubi guida, sopra il principale -----------------------------------
bm = bmesh.new()
for (d, lung, off) in GUIDE:
    cilindro(bm, d / 2, lung, Matrix.Translation(Vector((off, -(D_TUBO / 2 + d / 2 + 0.03), 0.10))))
oggetto("Guide", bm, tubo_perno)

bm = bmesh.new()
for (d, lung, off) in GUIDE:
    for z in (-lung / 2 + 0.16, lung / 2 - 0.16):
        cilindro(bm, d / 2 + 0.02, 0.05,
                 Matrix.Translation(Vector((off, -(D_TUBO / 2 + d / 2 + 0.03), 0.10 + z))))
oggetto("Collari", bm, tubo_perno)

# --- il focheggiatore, vicino alla bocca: e' qui che si mette l'occhio -------
bm = bmesh.new()
cilindro(bm, D_FUOCO / 2, L_FUOCO,
         Matrix.Translation(Vector((D_TUBO / 2 + L_FUOCO / 2 - 0.03, 0, L_TUBO / 2 - 0.30)))
         @ Matrix.Rotation(math.radians(90), 4, "Y"), lati=20)
cilindro(bm, D_FUOCO / 2 - 0.018, 0.10,
         Matrix.Translation(Vector((D_TUBO / 2 + L_FUOCO + 0.02, 0, L_TUBO / 2 - 0.30)))
         @ Matrix.Rotation(math.radians(90), 4, "Y"), lati=20)
oculare = oggetto("Ottica", bm, tubo_perno)

for o in bpy.data.objects:
    if o.type == "MESH":
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35.0))

# --- controlli ---------------------------------------------------------------
bpy.context.view_layer.update()
problemi = []
CUPOLA_R, CUPOLA_BASE, COLMO = 2.50, 3.38, 3.38 + 2.50
PASSERELLA = 0.99

punti = [o.matrix_world @ v.co for o in bpy.data.objects if o.type == "MESH" for v in o.data.vertices]
raggio_max = max(math.hypot(p.x, p.y) for p in punti)
alto_max = max(p.z for p in punti)
print("  ingombro: raggio %.2f m, altezza %.2f m" % (raggio_max, alto_max))
if raggio_max > CUPOLA_R - 0.15:
    problemi.append("il telescopio tocca la cupola: raggio %.2f su %.2f" % (raggio_max, CUPOLA_R))
if alto_max > COLMO - 0.20:
    problemi.append("il telescopio tocca il colmo: %.2f su %.2f" % (alto_max, COLMO))

# l'oculare deve stare a portata di chi e' in piedi sulla passerella
h_oculare = (oculare.matrix_world @ Vector((0, 0, 0))).z
print("  oculare a %.2f m dal pavimento (passerella a %.2f)" % (h_oculare, PASSERELLA))
direzione = (tubo_perno.matrix_world.to_3x3() @ Vector((0, 0, 1))).normalized()
altitudine = math.degrees(math.asin(max(-1.0, min(1.0, direzione.z))))
print("  il tubo punta a %.0f gradi sull'orizzonte" % altitudine)
if altitudine < 15.0:
    problemi.append("il tubo punta a %.0f gradi: sotto il tetto, non al cielo" % altitudine)

if not (PASSERELLA + 0.75 <= h_oculare <= PASSERELLA + 1.85):
    problemi.append("oculare a %.2f m: non si raggiunge dalla passerella" % h_oculare)

# Il telescopio RUOTA in ascensione retta: spazza un cono intero attorno all'asse
# polare. Non basta che stia libero nella posa in cui e' modellato — deve restare
# libero in TUTTE le pose, e la passerella e' un anello alla sua stessa quota.
R_INT, R_EST, Q_PASS = 0.975, 1.825, 0.99
mobili = [o for o in bpy.data.objects
          if o.type == "MESH" and o.name not in ("Pilastro",)]
urti = []
for o in mobili:
    for v_ in o.data.vertices:
        q = o.matrix_world @ v_.co
        r = math.hypot(q.x, q.y)
        if q.z <= Q_PASS + 0.05 and R_INT - 0.05 <= r <= R_EST + 0.05:
            urti.append((o.name, r, q.z))
if urti:
    peggiore = min(urti, key=lambda u: u[2])
    problemi.append("il telescopio attraversa la passerella: %s a r=%.2f, quota %.2f (%d punti)"
                    % (peggiore[0], peggiore[1], peggiore[2], len(urti)))
else:
    print("  passerella: libera in ogni posizione del telescopio")

if problemi:
    print("\nATTENZIONE:")
    for p in problemi:
        print("  " + p)
    sys.exit(1)

os.makedirs(os.path.dirname(USCITA), exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=USCITA, export_format="GLB", use_selection=True, export_apply=True)
print("\nscritto %s" % USCITA)
