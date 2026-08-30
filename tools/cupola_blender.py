# -*- coding: utf-8 -*-
"""Genera la cupola dell'osservatorio Astrochill e la esporta in glTF per Godot.

Si esegue senza aprire Blender:

    "D:/programs/blender5/blender.exe" --background --python tools/cupola_blender.py

Produce assets/models/cupola.glb con tre oggetti:

    Calotta         il guscio con la fenditura tagliata
    PortelloBasso   scorre verso il basso
    PortelloAlto    scorre oltre lo zenit

Tutti e tre hanno l'origine nel CENTRO DELLA SFERA, che nel gioco sta alla quota di
gronda (3,00 m). E' la cosa da non sbagliare: i portelli si aprono ruotando attorno
all'asse X, e con l'origine altrove si staccherebbero dal guscio.

Blender lavora in Z-up, Godot in Y-up: la conversione la fa l'esportatore glTF.
Le misure vengono da geometria.py, la stessa fonte della pianta e del blockout.
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
from modellare import uv_a_scatola, applica_texture   # noqa: E402

# --- misure, dalla stessa fonte del resto ------------------------------------
R = 2.50            # raggio della calotta: diametro 5,00 m (geometria.py, DOME_R)
SPESSORE = 0.08     # il guscio ha spessore: senza, i bordi della fenditura sono di carta
FENDITURA = 1.60    # larghezza della fenditura di osservazione
GIOCO = 0.06        # distanza fra guscio e portelli, perche' non compenetrino
SEGMENTI, ANELLI = 96, 48

# Il taglio si allarga per compensare lo spessore: il Solidify sposta i bordi lungo la
# normale radiale, quindi un guscio spesso ha la fenditura piu' stretta dentro che fuori.
# Quello che conta e' la LUCE NETTA, cioe' quanto cielo si vede: la piu' stretta.
MEZZA_F = (FENDITURA / 2.0) * R / (R - SPESSORE / 2.0)
LUCE_ZENIT = 2.40   # la fenditura si allarga salendo, come nella cupola reale


def luce_a(phi_gradi):
    """Larghezza della fenditura all'elevazione data, in metri.

    Nelle foto la fenditura non ha i lati paralleli: sale stretta e si apre verso
    lo zenit. Costante fino a 45 gradi, poi si allarga fino a LUCE_ZENIT.
    """
    if phi_gradi <= 45.0:
        return FENDITURA
    t = min(1.0, (phi_gradi - 45.0) / 45.0)
    return FENDITURA + (LUCE_ZENIT - FENDITURA) * t


def semiangolo(phi_gradi, raggio, extra=0.0):
    """Da larghezza in metri a mezzo angolo sul parallelo di quell'elevazione.

    Il parallelo a elevazione phi ha raggio r*cos(phi): la stessa corda vi
    sottende un angolo tanto piu' largo quanto piu' si sale. Vicino allo zenit i
    meridiani convergono e l'angolo esploderebbe, quindi si limita.
    """
    mezza = luce_a(phi_gradi) / 2.0 + extra
    raggio_parallelo = raggio * math.cos(math.radians(phi_gradi))
    if raggio_parallelo <= 1e-6:
        return math.radians(60.0)
    return min(math.asin(min(1.0, mezza / raggio_parallelo)), math.radians(60.0))
R_PORT = R + SPESSORE / 2.0 + GIOCO      # i portelli scorrono FUORI dal guscio
MEZZA_P = MEZZA_F + 0.18                 # coprono un po' piu' della luce, come una battuta

QUI = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
USCITA = os.path.join(QUI, "assets", "models", "cupola.glb")


def pulisci():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for blocco in (bpy.data.meshes, bpy.data.materials):
        for elemento in list(blocco):
            blocco.remove(elemento)


def emisfero(nome, raggio):
    """Mezza sfera aperta in basso, senza il polo inferiore."""
    malla = bpy.data.meshes.new(nome)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=SEGMENTI, v_segments=ANELLI, radius=raggio)
    # via tutto cio' che sta sotto l'equatore: la cupola poggia sulla gronda
    sotto = [v for v in bm.verts if v.co.z < -1e-6]
    bmesh.ops.delete(bm, geom=sotto, context="VERTS")
    uv_a_scatola(bm)
    bm.to_mesh(malla)
    bm.free()
    oggetto = bpy.data.objects.new(nome, malla)
    bpy.context.collection.objects.link(oggetto)
    return oggetto


def taglia(oggetto, piani, tieni):
    """Taglia la mesh sui piani dati e tiene solo le facce per cui tieni(centro) e' vero.

    Si usa bisect e non una booleana: taglia esattamente sul piano e lascia bordi
    puliti, senza dover far tornare i conti con la segmentazione della sfera.
    """
    bm = bmesh.new()
    bm.from_mesh(oggetto.data)
    for (punto, normale) in piani:
        bmesh.ops.bisect_plane(
            bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
            plane_co=Vector(punto), plane_no=Vector(normale), clear_inner=False, clear_outer=False)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not tieni(f.calc_center_median())],
                     context="FACES")
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges[:])
    uv_a_scatola(bm)
    bm.to_mesh(oggetto.data)
    bm.free()


def ispessisci(oggetto, spessore):
    modificatore = oggetto.modifiers.new("Spessore", "SOLIDIFY")
    modificatore.thickness = spessore
    modificatore.offset = 0.0
    modificatore.use_rim = True
    bpy.context.view_layer.objects.active = oggetto
    bpy.ops.object.modifier_apply(modifier=modificatore.name)


def elevazione(punto):
    """Angolo dal piano di base lungo il meridiano della fenditura, in gradi."""
    return math.degrees(math.atan2(punto.z, punto.y))


def superficie(nome, raggio, phi_da, phi_a, dentro_la_luce, extra=0.0,
               anelli=64, lungo=96, raggio_luce=None):
    """Genera una porzione di sfera con i bordi ESATTAMENTE sulla sagoma voluta.

    Si costruisce invece di tagliare. Tagliare una sfera gia' fatta — a bisect o a
    booleana — lascia il bordo dove capitano i suoi meridiani, e su una fenditura
    che cambia larghezza il gradino si vede: e' proprio il bordo che il giocatore
    ha davanti agli occhi dalla passerella.

    `dentro_la_luce` sceglie se si tiene il pezzo DENTRO la fenditura (i portelli)
    o quello FUORI (la calotta).
    """
    # La sagoma si calcola sul raggio dove la LUCE va misurata: per la calotta e'
    # il filo interno, perche' e' quello che stringe il passaggio della vista.
    rl = raggio if raggio_luce is None else raggio_luce
    bm = bmesh.new()
    righe = []
    for i in range(anelli + 1):
        phi = phi_da + (phi_a - phi_da) * i / anelli
        th = semiangolo(phi, rl, extra)
        cp, sp = math.cos(math.radians(phi)), math.sin(math.radians(phi))
        # dentro la luce: da -th a +th. fuori: il resto del parallelo.
        a, b = (-th, th) if dentro_la_luce else (th, 2 * math.pi - th)
        riga = []
        for j in range(lungo + 1):
            t = a + (b - a) * j / lungo
            riga.append(bm.verts.new((raggio * cp * math.sin(t),
                                      raggio * cp * math.cos(t),
                                      raggio * sp)))
        righe.append(riga)
    bm.verts.ensure_lookup_table()
    for i in range(anelli):
        for j in range(lungo):
            try:
                bm.faces.new((righe[i][j], righe[i][j + 1], righe[i + 1][j + 1], righe[i + 1][j]))
            except ValueError:
                pass          # ai poli i vertici collassano: la faccia degenere si salta
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    malla = bpy.data.meshes.new(nome)
    uv_a_scatola(bm)
    bm.to_mesh(malla)
    bm.free()
    o = bpy.data.objects.new(nome, malla)
    bpy.context.collection.objects.link(o)
    return o


# --- la calotta: la sfera meno la fenditura, costruita col bordo giusto ------
pulisci()
calotta = superficie("Calotta", R, 0.0, 89.0, dentro_la_luce=False,
                     raggio_luce=R - SPESSORE / 2.0)
ispessisci(calotta, SPESSORE)

# --- i portelli: due gusci che coprono la fenditura --------------------------
# chiusi coprono da 0 a 90 gradi; si sovrappongono di 2 gradi per non lasciare luce
for nome, da, a in [("PortelloBasso", -2.0, 48.0), ("PortelloAlto", 46.0, 92.0)]:
    portello = superficie(nome, R_PORT, da, a, dentro_la_luce=True, extra=0.16,
                          anelli=40, lungo=28)
    ispessisci(portello, SPESSORE * 0.7)

# --- l'ossatura interna: costoloni radiali, anelli e tiranti -----------------
# Nelle foto la cupola non e' un guscio liscio: dentro ha costoloni che corrono
# lungo i meridiani, due anelli orizzontali e cavi incrociati fra un costolone e
# l'altro. E' la superficie che il giocatore ha davanti agli occhi tutta la notte,
# quindi vale piu' di quanto costi.
R_INT = R - SPESSORE / 2.0
COSTOLONI = 16
SEZ_C, SPORGENZA = 0.05, 0.07      # larghezza del costolone e quanto rientra
ANELLI_ORIZZONTALI = (22.0, 52.0)


def _punto(raggio, phi_gradi, theta):
    cp, sp = math.cos(math.radians(phi_gradi)), math.sin(math.radians(phi_gradi))
    return Vector((raggio * cp * math.sin(theta), raggio * cp * math.cos(theta), raggio * sp))


bm_oss = bmesh.new()

for k in range(COSTOLONI):
    theta = 2 * math.pi * k / COSTOLONI
    # un costolone che finirebbe dentro la fenditura non esiste: li' il guscio e' aperto
    if abs(math.atan2(math.sin(theta), math.cos(theta))) < semiangolo(20.0, R_INT, 0.10):
        continue
    passi = 26
    for i in range(passi):
        phi0 = 2.0 + 84.0 * i / passi
        phi1 = 2.0 + 84.0 * (i + 1) / passi
        if abs(math.atan2(math.sin(theta), math.cos(theta))) < semiangolo(phi1, R_INT, 0.10):
            break          # salendo la fenditura si allarga e mangia il costolone
        a, b = _punto(R_INT, phi0, theta), _punto(R_INT, phi1, theta)
        mezzo = (a + b) / 2
        lungo = (b - a).length
        su = mezzo.normalized()
        avanti = (b - a).normalized()
        lato = avanti.cross(su).normalized()
        base = Matrix((
            (lato.x, avanti.x, su.x, mezzo.x),
            (lato.y, avanti.y, su.y, mezzo.y),
            (lato.z, avanti.z, su.z, mezzo.z),
            (0, 0, 0, 1)))
        bmesh.ops.create_cube(bm_oss, size=1.0, matrix=(
            base @ Matrix.Translation(Vector((0, 0, -SPORGENZA / 2)))
            @ Matrix.Diagonal(Vector((SEZ_C, lungo * 1.05, SPORGENZA, 1.0)))))

for phi in ANELLI_ORIZZONTALI:
    passi = 96
    for j in range(passi):
        t0 = 2 * math.pi * j / passi
        t1 = 2 * math.pi * (j + 1) / passi
        if abs(math.atan2(math.sin(t1), math.cos(t1))) < semiangolo(phi, R_INT, 0.10):
            continue
        a, b = _punto(R_INT, phi, t0), _punto(R_INT, phi, t1)
        mezzo = (a + b) / 2
        su = mezzo.normalized()
        avanti = (b - a).normalized()
        lato = avanti.cross(su).normalized()
        base = Matrix((
            (lato.x, avanti.x, su.x, mezzo.x), (lato.y, avanti.y, su.y, mezzo.y),
            (lato.z, avanti.z, su.z, mezzo.z), (0, 0, 0, 1)))
        bmesh.ops.create_cube(bm_oss, size=1.0, matrix=(
            base @ Matrix.Translation(Vector((0, 0, -0.045 / 2)))
            @ Matrix.Diagonal(Vector((0.04, (b - a).length * 1.05, 0.045, 1.0)))))

ossatura = bpy.data.objects.new("Ossatura", bpy.data.meshes.new("Ossatura"))
uv_a_scatola(bm_oss)
bm_oss.to_mesh(ossatura.data)
bm_oss.free()
bpy.context.collection.objects.link(ossatura)

# i tiranti: cavi sottili incrociati fra costoloni vicini, come nelle foto
bm_cavi = bmesh.new()
for k in range(COSTOLONI):
    t0 = 2 * math.pi * k / COSTOLONI
    t1 = 2 * math.pi * (k + 1) / COSTOLONI
    for (pa, ta), (pb, tb) in (((26.0, t0), (50.0, t1)), ((50.0, t0), (26.0, t1))):
        if (abs(math.atan2(math.sin(ta), math.cos(ta))) < semiangolo(pa, R_INT, 0.12)
                or abs(math.atan2(math.sin(tb), math.cos(tb))) < semiangolo(pb, R_INT, 0.12)):
            continue
        a, b = _punto(R_INT - 0.06, pa, ta), _punto(R_INT - 0.06, pb, tb)
        direzione = (b - a)
        mezzo = (a + b) / 2
        rot = direzione.to_track_quat("Z", "Y").to_matrix().to_4x4()
        bmesh.ops.create_cone(bm_cavi, cap_ends=True, cap_tris=False, segments=6,
                              radius1=0.008, radius2=0.008, depth=direzione.length,
                              matrix=Matrix.Translation(mezzo) @ rot)
cavi = bpy.data.objects.new("Tiranti", bpy.data.meshes.new("Tiranti"))
uv_a_scatola(bm_cavi)
bm_cavi.to_mesh(cavi.data)
bm_cavi.free()
bpy.context.collection.objects.link(cavi)

# materiali: il guscio chiaro, l'ossatura piu' scura, i cavi quasi neri
def _mat(nome, colore, ruvido=0.6, metallo=0.0, texture=None):
    """Il materiale, e per la calotta anche le mappe della lamiera.

    LA CALOTTA SENZA TEXTURE E' LA TELA IDEALE PER IL BANDING, ed e' misurato: su
    una superficie perfettamente liscia l'alone rosso si scalinava in fasce di
    venti-quaranta pixel che differiscono di UN livello su 255. Il debanding le
    dimezza ma non le toglie, perche' dithera mezzo livello e qui il gradiente e'
    piu' lento di cosi'. Una lamiera vera ha grana e ammaccature: la variazione
    della normale rompe le fasce con una cosa che c'e' davvero, invece di
    mascherarle con del rumore. E una cupola di lamiera liscia come una biglia
    non era comunque giusta.
    """
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    p_ = m.node_tree.nodes["Principled BSDF"]
    p_.inputs["Base Color"].default_value = (*colore, 1.0)
    p_.inputs["Roughness"].default_value = ruvido
    p_.inputs["Metallic"].default_value = metallo
    if texture is not None:
        # metallico=False anche se la mappa si chiama "Metallo": e' lamiera
        # VERNICIATA, e collegare la mappa metallica farebbe della cupola uno
        # specchio - cioe' una superficie nera, perche' qui non c'e' cielo da
        # riflettere. E' lo stesso inganno che ha reso nero il telescopio.
        applica_texture(m, texture, metallico=False)
    return m


# LA LAMIERA DELLE PLAFONIERE ERA LA SCELTA SBAGLIATA. PaintedMetal012 e' una
# vernice SCROSTATA: su una calotta da cinque metri diventa una distesa di macchie
# scure che non si capisce cosa siano - non leggono come usura, leggono come
# sporco sulla texture. E i portelli non l'avevano, quindi la cupola era chiazzata
# e il suo sportello no: due pezzi dello stesso guscio con due storie diverse.
# Il set della carpenteria e' una lamiera verniciata pulita, ed e' quello che e'
# una cupola: un guscio di metallo verniciato che qualcuno mantiene.
CUPOLA_TEX = "Metallo"
for oggetto_, colore_, ruvido_, metallo_, tex_ in (
        (calotta, (0.84, 0.84, 0.85), 0.75, 0.0, CUPOLA_TEX),
        (ossatura, (0.46, 0.46, 0.48), 0.55, 0.4, CUPOLA_TEX),
        (cavi, (0.13, 0.13, 0.14), 0.4, 0.7, None)):
    oggetto_.data.materials.append(
        _mat(oggetto_.name, colore_, ruvido_, metallo_, tex_))
# I PORTELLI PRENDONO LA STESSA MAPPA. Sono ritagliati nello stesso guscio: dargli
# un materiale liscio mentre la calotta ne ha uno con la trama e' la cosa che
# faceva chiedere "perche' quello che si apre non e' come il resto".
for oggetto_ in bpy.data.objects:
    if oggetto_.name.startswith("Portello") and not oggetto_.data.materials:
        oggetto_.data.materials.append(
            _mat(oggetto_.name, (0.72, 0.72, 0.74), 0.6, 0.2, CUPOLA_TEX))

# --- la calotta e' una sfera, non un poliedro --------------------------------
# Senza shading liscio ognuno dei 48 anelli di latitudine ha una normale COSTANTE:
# una lampada vicina lo illumina tutto uguale, e sulla cupola compaiono anelli
# concentrici a gradino. Con la luce rossa, che vive su un canale solo, quei
# gradini sono la cosa piu' visibile della stanza.
# Trenta gradi: le facce della sfera stanno abbondantemente sotto e si fondono,
# gli spigoli veri - il bordo della fenditura, i profili dell'ossatura - restano
# vivi. Va fatto PRIMA di applicare le trasformazioni, altrimenti opera su una
# selezione che non esiste ancora.
bpy.ops.object.select_all(action="DESELECT")
for oggetto_ in bpy.data.objects:
    oggetto_.select_set(True)
bpy.context.view_layer.objects.active = calotta
bpy.ops.object.shade_smooth_by_angle(angle=math.radians(30.0))

# --- origini nel centro della sfera, trasformazioni applicate ----------------
for oggetto in bpy.data.objects:
    oggetto.location = (0.0, 0.0, 0.0)
bpy.ops.object.select_all(action="SELECT")
bpy.context.view_layer.objects.active = bpy.data.objects["Calotta"]
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)

# --- controlli, prima di esportare -------------------------------------------
problemi = []
for oggetto in bpy.data.objects:
    n = len(oggetto.data.polygons)
    if n == 0:
        problemi.append("%s: mesh vuota" % oggetto.name)
    if tuple(oggetto.location) != (0.0, 0.0, 0.0):
        problemi.append("%s: origine fuori dal centro della sfera" % oggetto.name)
    if n == 0:
        print("  %-14s VUOTA" % oggetto.name)
        continue
    print("  %-14s %5d facce   bbox z %.2f..%.2f" % (
        oggetto.name, n,
        min(v.co.z for v in oggetto.data.vertices),
        max(v.co.z for v in oggetto.data.vertices)))

# la luce si misura sui BORDI della fenditura, non sull'intero guscio: i vertici
# piu' vicini al piano x=0 fra quelli che guardano verso l'apertura
luce = bpy.data.objects["Calotta"]
xs = [v.co.x for v in luce.data.vertices if v.co.y > 0.8 and 0.15 < v.co.z < 0.85]
destri, sinistri = [x for x in xs if x > 0], [x for x in xs if x < 0]
if destri and sinistri:
    misurata = min(destri) - max(sinistri)   # la luce netta, al filo interno
    print("  fenditura misurata sulla mesh: %.3f m (attesa %.2f)" % (misurata, FENDITURA))
    if abs(misurata - FENDITURA) > 0.02:
        problemi.append("fenditura larga %.3f invece di %.2f" % (misurata, FENDITURA))

if problemi:
    print("\nATTENZIONE:")
    for p in problemi:
        print("  " + p)
    sys.exit(1)

os.makedirs(os.path.dirname(USCITA), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=USCITA, export_format="GLB", use_selection=False,
                          export_apply=True, export_yup=True)
print("\nscritto %s" % USCITA)
