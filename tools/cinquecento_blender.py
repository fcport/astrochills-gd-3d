# -*- coding: utf-8 -*-
"""L'AUTO DEL RITORNO A CASA: la Fiat 500F del 1965, ferma e leggera.

    "D:/programs/blender5/blender.exe" --background --python tools/cinquecento_blender.py

Produce assets/models/cinquecento.glb, che prende il posto della scatola grigia da
4,20 x 1,50 x 1,80 del nodo `Macchina` (vedi world/interactables/macchina.gd), e il
provino _confronto/cinquecento.png.

E' UN SEGNAPOSTO CON UNA LICENZA CHE NON SI SPEDISCE. Il modello e' CC-BY-NC-SA 4.0:
niente uso commerciale, e questo .glb - che e' una versione modificata - resta sotto
la stessa licenza. Federico l'ha scelto sapendolo, e prima di distribuire il gioco va
sostituito. Vedi la voce `cinquecento` in `tools/prendi_modello.py` e CREDITI.md.

COME ESCE. Una mesh sola, `Cinquecento`, con una superficie per materiale. Il MUSO
guarda +X di Blender, che in Godot resta +X; la fiancata sinistra sta a +Y di
Blender, cioe' a -Z di Godot. L'origine e' al centro dell'ingombro in pianta e a
quota zero SOTTO LE GOMME: chi la posa scrive la quota del prato, non mezza altezza.

ARRIVA DA 334.030 FACCE, ed e' un modello da vetrina: il motore intero, il vano
anteriore con serbatoio e ruota di scorta, i tamburi dei freni dentro le ruote. In
gioco la si vede fuori, di notte, da qualche metro e a 640 x 360: quello che da fuori
non si vede si butta, il resto si decima fino a BUDGET facce per l'auto intera.

LO SCHELETRO NON C'E', malgrado i nomi. I pezzi `SK_` - porte, cofano, baule, tetto -
nel .gltf sono nodi qualunque senza `skin`, e Blender li importa come mesh appese a un
empty. L'auto "a pezzi sparsi" delle prime viste era la CAMERA: il modello arriva
largo un centimetro e mezzo, e con il piano di taglio a dieci centimetri se ne vedeva
una fetta. Le trasformate si cuociono lo stesso nella mesh prima di misurare, perche'
la scala di un centesimo sta nei nodi e non nei vertici.
"""
import math
import os
import re
import sys

import bpy
from mathutils import Matrix, Vector

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
import importlib   # noqa: E402
for _m in ("modellare",):
    if _m in sys.modules:
        importlib.reload(sys.modules[_m])
from modellare import esporta, lampada, prepara_render, pulisci, usa_le_ridotte   # noqa: E402

RADICE = os.path.dirname(QUI)
SORGENTE = os.path.join(RADICE, "assets", "models", "esterni", "cinquecento", "scene.gltf")
USCITA = os.path.join(RADICE, "assets", "models", "cinquecento.glb")
PROVINO = os.path.join(RADICE, "_confronto", "cinquecento.png")

# LE MISURE VERE DELLA 500F: 2970 mm fuori tutto, 1320 di larghezza, 1320 d'altezza,
# 1840 di interasse. Dalla LUNGHEZZA esce la scala; le altre tre non si impongono,
# si CONTROLLANO - sono quello che dice se dalla scala e' uscita un'auto.
LUNGHEZZA = 2.97
LARGHEZZA = 1.32
ALTEZZA = 1.32
INTERASSE = 1.84
# quanto possono scostarsi larghezza e altezza, in frazione, e l'interasse, in metri
TOLLERANZA = 0.06
TOLLERANZA_INTERASSE = 0.05

# FACCE PER L'AUTO INTERA. E' l'oggetto piu' grosso che il giocatore vede fuori, ma lo
# vede di notte e a 640 x 360: ventimila sono gia' piu' dell'intero bagno, e il
# dettaglio che resta da vedere e' la sagoma, non la bulloneria.
BUDGET = 20000
# SOTTO QUESTA SOGLIA UN PEZZO NON SI TOCCA. La decimazione e' in proporzione, e al
# otto per cento lo specchietto da trenta facce ne terrebbe due: un pezzo piccolo non
# pesa sul budget, e ridotto a un triangolo smette di essere un pezzo.
PAVIMENTO = 60

# COSA SI BUTTA. Il gruppo `SM_Engine` NON E' SOLO IL MOTORE: e' anche la vasca del
# vano anteriore con il serbatoio e la ruota di scorta, e il vano motore dietro con le
# sospensioni. Sono novantaduemila facce - piu' di un quarto del modello - chiuse
# sotto il cofano e il cofano motore, che in gioco non si aprono.
BUTTA_NODI = ("SM_Engine_",)
# I TAMBURI DEI FRENI stanno dentro il cerchione: da fuori se ne vede, forse, un
# riflesso dai fori. Quattro volte milleduecento facce per un riflesso.
BUTTA_MATERIALI = ("MI_Change_Brake1",)


def facce(oggetti):
    return sum(len(o.data.polygons) for o in oggetti)


def importa():
    if not os.path.exists(SORGENTE):
        print("MANCA il modello: %s" % SORGENTE)
        print("  lancia prima: python -X utf8 tools/prendi_modello.py cinquecento")
        sys.exit(1)
    bpy.ops.import_scene.gltf(filepath=SORGENTE)


def cuoci():
    """Porta ogni mesh in coordinate di mondo e butta gli empty che la reggevano.

    LE MATRICI SI LEGGONO TUTTE PRIMA DI TOCCARNE UNA: staccare un pezzo dal padre
    cambia cosa vuol dire la sua `matrix_basis`, e leggerle man mano mescolerebbe
    pezzi gia' cotti e pezzi ancora appesi. Una mesh condivisa fra due nodi si
    sdoppia prima, o la si cuocerebbe due volte.
    """
    mesh = [o for o in bpy.data.objects if o.type == "MESH" and o.data is not None]
    mondo = {o.name: o.matrix_world.copy() for o in mesh}
    for o in mesh:
        if o.data.users > 1:
            o.data = o.data.copy()
        o.data.transform(mondo[o.name])
        o.parent = None
        o.matrix_world = Matrix.Identity(4)
    for o in [x for x in bpy.data.objects if x.type != "MESH"]:
        bpy.data.objects.remove(o, do_unlink=True)
    return [o for o in bpy.data.objects if o.type == "MESH"]


def butta(mesh):
    tenuti, motore, freni = [], 0, 0
    for o in mesh:
        materiali = [m.name for m in o.data.materials if m is not None]
        if any(n in o.name for n in BUTTA_NODI):
            motore += len(o.data.polygons)
        elif any(b in m for m in materiali for b in BUTTA_MATERIALI):
            freni += len(o.data.polygons)
        else:
            tenuti.append(o)
            continue
        bpy.data.objects.remove(o, do_unlink=True)
    print("  si buttano motore e vani (%d facce) e tamburi dei freni (%d facce)"
          % (motore, freni))
    print("  restano %d pezzi, %d facce" % (len(tenuti), facce(tenuti)))
    return tenuti


def trasforma(mesh, M):
    for o in mesh:
        o.data.transform(M)
        o.data.update()


def ingombro(mesh):
    P = [v.co for o in mesh for v in o.data.vertices]
    return (Vector((min(p.x for p in P), min(p.y for p in P), min(p.z for p in P))),
            Vector((max(p.x for p in P), max(p.y for p in P), max(p.z for p in P))))


def centro(oggetti):
    P = [v.co for o in oggetti for v in o.data.vertices]
    return sum(P, Vector()) / len(P)


def gomme(mesh):
    return [o for o in mesh
            if any("Classic_Tyre" in m.name for m in o.data.materials if m is not None)]


def orienta(mesh):
    """Gira l'auto col muso verso +X.

    IL MUSO SI TROVA DAI FANALI, non si sceglie. Nel .gltf guarda verso -Y, ma e' un
    dato di questo file e non una regola: lo dicono i nomi `SM_Light_F` e
    `SM_Light_B`, che qui - a differenza della porta del magazzino - sopravvivono
    all'import. Che i nomi non mentano lo controlla poi `verifica`, con le ruote.
    """
    davanti = [o for o in mesh if "SM_Light_F_" in o.name]
    dietro = [o for o in mesh if "SM_Light_B_" in o.name]
    if not davanti or not dietro:
        print("ATTENZIONE: non trovo i fanali (SM_Light_F / SM_Light_B): il modello"
              " non e' quello atteso")
        sys.exit(1)
    d = centro(davanti) - centro(dietro)
    angolo = math.atan2(d.y, d.x)
    print("  il muso arriva a %.0f gradi da +X: si gira" % math.degrees(angolo))
    trasforma(mesh, Matrix.Rotation(-angolo, 4, "Z"))


def posa(mesh):
    """Lunga LUNGHEZZA, centrata in pianta, con le gomme a quota zero.

    SI CHIAMA DUE VOLTE, prima e dopo la decimazione. Prima, perche' decimare un'auto
    larga un centimetro e mezzo vuol dire lavorare con spigoli da un decimo di
    millimetro, cioe' dove le soglie di Blender scambiano un triangolo per un punto.
    Dopo, perche' il collasso degli spigoli sposta i vertici e l'auto si accorcia di
    qualche millimetro: la misura vera la si rimette alla fine, non la si spera.

    LO ZERO E' SOTTO LE GOMME, non sotto il punto piu' basso: se una marmitta o un
    paraspruzzi scendessero sotto il battistrada, posata sul loro minimo l'auto
    galleggerebbe sul prato. Che niente scenda sotto, lo guarda `verifica`.
    """
    lo, hi = ingombro(mesh)
    trasforma(mesh, Matrix.Scale(LUNGHEZZA / (hi.x - lo.x), 4))
    lo, hi = ingombro(mesh)
    z0 = min(v.co.z for o in gomme(mesh) for v in o.data.vertices)
    trasforma(mesh, Matrix.Translation(Vector((-(lo.x + hi.x) / 2.0,
                                               -(lo.y + hi.y) / 2.0, -z0))))


def decima(mesh):
    """Porta l'auto a BUDGET facce, in proporzione su ogni pezzo.

    IL RAPPORTO SI CERCA, non si sceglie, per la stessa ragione di `prop_blender`: con
    il PAVIMENTO i pezzi piccoli restano interi, e quello che non tagliano loro va
    tolto a tutti gli altri. Il rapporto giusto e' quello per cui la somma torna, e lo
    si trova per bisezione.
    """
    conti = [(o, len(o.data.polygons)) for o in mesh]

    def quante(r):
        return sum(min(n, max(PAVIMENTO, int(n * r))) for _o, n in conti)

    prima = facce(mesh)
    if quante(1.0) <= BUDGET:
        print("  %d facce, gia' sotto il budget" % prima)
        return
    basso, alto = 0.0, 1.0
    for _ in range(40):
        r = (basso + alto) / 2.0
        if quante(r) > BUDGET:
            alto = r
        else:
            basso = r
    r = basso
    for o, n in conti:
        voluto = min(n, max(PAVIMENTO, int(n * r)))
        if voluto >= n:
            continue
        m = o.modifiers.new("Decima", "DECIMATE")
        m.decimate_type = "COLLAPSE"
        m.ratio = float(voluto) / n
        with bpy.context.temp_override(object=o, active_object=o):
            bpy.ops.object.modifier_apply(modifier=m.name)
    dopo = facce(mesh)
    print("  decimata al %.1f%% per pezzo: %d -> %d facce" % (100.0 * r, prima, dopo))


def materiali(mesh):
    """Le mappe ridotte, e tre cose che in questa scena farebbero il contrario.

    METALLICO A ZERO. La carrozzeria dichiara 0,82, i cromi 0,92, perfino i sedili
    0,48: in Godot, fuori, di notte, un metallo riflette il cielo nero ed e' NERO. E'
    il difetto ricorrente del progetto, e un'auto e' fatta quasi solo di superfici che
    l'autore ha dichiarato metalliche.

    L'EMISSIONE DEL CRUSCOTTO SI SPEGNE: l'auto e' parcheggiata, a motore spento, e un
    quadro strumenti acceso al buio sarebbe l'unica luce del parcheggio - cioe' un
    invito a guardare dentro un'auto dove non c'e' niente.

    LA TRASMISSIONE DEI VETRI SI TOGLIE. In Godot non arriva - e' la stessa trappola
    delle teche, D-044 - e quello che arriva e' l'alpha. Lasciandola, il provino
    mostrerebbe vetri che in gioco non ci sono: si guarda quello che il gioco vedra'.
    """
    sostituite = usa_le_ridotte(mesh, os.path.dirname(SORGENTE), metallico=0.0)
    print("  %d mappe sostituite con le ridotte" % sostituite)
    visti = set()
    for o in mesh:
        for m in o.data.materials:
            if m is None or m.name in visti or not m.use_nodes:
                continue
            visti.add(m.name)
            for n in m.node_tree.nodes:
                if n.type != "BSDF_PRINCIPLED":
                    continue
                # prima si stacca il filo, poi si scrive il valore: vedi usa_le_ridotte
                for ingresso, valore in (("Emission Strength", 0.0),
                                         ("Emission Color", (0.0, 0.0, 0.0, 1.0)),
                                         ("Transmission Weight", 0.0)):
                    if ingresso not in n.inputs:
                        continue
                    for filo in list(n.inputs[ingresso].links):
                        m.node_tree.links.remove(filo)
                    n.inputs[ingresso].default_value = valore


def verifica(mesh):
    """Le misure che dicono se e' uscita un'auto intera, dritta e nel verso giusto.

    LE RUOTE SONO IL RIGHELLO, e controllano tre cose che l'ingombro da solo non vede:
    l'INTERASSE dice che la scala e' quella vera (la lunghezza la si e' imposta, non
    prova niente); le anteriori a +X e le sinistre a +Y dicono che il muso e' davanti e
    che l'auto non e' specchiata - un'auto specchiata ha la stessa sagoma e il volante
    dall'altra parte; le quattro gomme a quota zero dicono che e' dritta.
    """
    problemi = []
    ruote = {}
    for o in gomme(mesh):
        m = re.search(r"_(F|B)(L|R)\d", o.name)
        if m is None:
            problemi.append("gomma senza posizione nel nome: %s" % o.name)
            continue
        ruote[m.group(1) + m.group(2)] = (centro([o]),
                                          min(v.co.z for v in o.data.vertices))
    if sorted(ruote) != ["BL", "BR", "FL", "FR"]:
        problemi.append("le gomme non sono le quattro attese: %s" % sorted(ruote))
    else:
        for nome, (c, basso) in sorted(ruote.items()):
            print("  gomma %s: centro x %+.3f y %+.3f, poggia a %.3f" % (nome, c.x, c.y, basso))
        interasse = ((ruote["FL"][0].x + ruote["FR"][0].x)
                     - (ruote["BL"][0].x + ruote["BR"][0].x)) / 2.0
        print("  interasse %.3f m (il vero e' %.2f)" % (interasse, INTERASSE))
        if abs(interasse - INTERASSE) > TOLLERANZA_INTERASSE:
            problemi.append("interasse %.3f invece di %.2f: la scala e' sbagliata"
                            % (interasse, INTERASSE))
        if not (min(ruote["FL"][0].x, ruote["FR"][0].x) > 0.0
                > max(ruote["BL"][0].x, ruote["BR"][0].x)):
            problemi.append("le ruote anteriori non stanno a +X: il muso e' dietro")
        if not (min(ruote["FL"][0].y, ruote["BL"][0].y) > 0.0
                > max(ruote["FR"][0].y, ruote["BR"][0].y)):
            problemi.append("le ruote sinistre non stanno a +Y: l'auto e' specchiata")
        alte = max(b for _c, b in ruote.values())
        if alte > 0.01:
            problemi.append("una gomma poggia %.0f mm sopra le altre: l'auto e' storta"
                            % (alte * 1000.0))
    lo, hi = ingombro(mesh)
    lx, ly, lz = hi.x - lo.x, hi.y - lo.y, hi.z - lo.z
    print("  ingombro: lunga %.3f (X), larga %.3f (Y), alta %.3f (Z) m" % (lx, ly, lz))
    print("  x %.3f..%.3f  y %.3f..%.3f  z %.3f..%.3f"
          % (lo.x, hi.x, lo.y, hi.y, lo.z, hi.z))
    for nome, avuto, voluto in (("larga", ly, LARGHEZZA), ("alta", lz, ALTEZZA)):
        if abs(avuto - voluto) > voluto * TOLLERANZA:
            problemi.append("e' %s %.3f invece di %.2f: non e' una 500" % (nome, avuto, voluto))
    if abs(lx - LUNGHEZZA) > 0.005:
        problemi.append("e' lunga %.3f invece di %.2f" % (lx, LUNGHEZZA))
    if lo.z < -0.02:
        problemi.append("qualcosa scende %.0f mm sotto le gomme" % (-lo.z * 1000.0))
    if abs(lo.x + hi.x) > 0.01 or abs(lo.y + hi.y) > 0.01:
        problemi.append("l'origine non e' al centro della pianta")
    return problemi


def unisci(mesh):
    """Un oggetto solo: e' ferma, e in Godot un nodo con diciotto superfici si posa
    e si sposta come un pezzo, settanta nodi no.

    LE NORMALI D'AUTORE SI TOLGONO A TUTTI, non solo ai decimati. Il collasso degli
    spigoli le perde comunque; i pezzi sotto il pavimento le avrebbero ancora, e
    uniti agli altri darebbero una mesh sfumata con due regole diverse. Lo sfumato
    per angolo tiene gli spigoli veri - il bordo di un parafango - e ammorbidisce il
    resto.

    LE UV DI TROPPO SI BUTTANO. Il modello ne porta tre set, ma i materiali leggono
    solo il primo: gli altri due sono le UV delle lightmap del motore da cui e' stato
    esportato, e nel .glb pesavano mezzo megabyte - piu' della geometria che
    descrivono - per non essere lette da nessuno.

    `raddrizza_normali` QUI NON SI CHIAMA, ed e' misurato: sul .glb finito girerebbe
    8.106 facce su 19.981, fra cui 47 delle 48 del cruscotto e 88 delle 89 dello
    specchietto, che l'autore ha orientato giuste. Un'auto e' fatta di gusci aperti -
    lamiere senza spessore, vetri, cerchioni - e su un guscio aperto "fuori" non e'
    definito: il ricalcolo tira a indovinare. Qui l'auto viene solo girata e scalata
    in modo uniforme, niente specchi, quindi l'avvolgimento resta quello d'autore; e
    tutti i materiali sono a due facce.
    """
    for o in mesh:
        uv = o.data.uv_layers
        while len(uv) > 1:
            uv.remove(uv[len(uv) - 1])
        if getattr(o.data, "has_custom_normals", False):
            with bpy.context.temp_override(object=o, active_object=o):
                bpy.ops.mesh.customdata_custom_splitnormals_clear()
    bpy.ops.object.select_all(action="DESELECT")
    for o in mesh:
        o.select_set(True)
    capo = max(mesh, key=lambda x: len(x.data.polygons))
    bpy.context.view_layer.objects.active = capo
    bpy.ops.object.join()
    capo.name = "Cinquecento"
    capo.data.name = "Cinquecento"
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(40.0))
    return capo


# --- il provino --------------------------------------------------------------
def tinta(nome, c):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (c[0], c[1], c[2], 1.0)
    b.inputs["Roughness"].default_value = 0.9
    return m


def blocco(nome, x0, x1, y0, y1, z0, z1, mat):
    """Un parallelepipedo in coordinate DI BLENDER, come l'auto importata."""
    v = [(x, y, z) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me = bpy.data.meshes.new(nome)
    me.from_pydata(v, [], f)
    me.materials.append(mat)
    o = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(o)
    return o


def provino():
    """Si GUARDA IL FILE SCRITTO, non la scena che l'ha prodotto.

    Il .glb si reimporta da capo: quello che conta e' cosa esce dall'esportatore, e un
    materiale che in scena funziona e nel file perde la mappa si vede solo cosi'.
    Quattro viste in una tessera, ognuna grande quanto lo schermo del gioco: davanti
    di tre quarti, dietro di tre quarti ad altezza d'occhio, di fianco e dall'alto.
    Il PALETTO ROSSO sta a +X, cioe' davanti al muso; le due righe chiare a terra sono
    gli assi, e dall'alto dicono se l'origine e' al centro.
    """
    import numpy as np
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=USCITA)
    auto = [o for o in bpy.data.objects if o.type == "MESH"]
    print("  il .glb reimportato: %d mesh, %d facce" % (len(auto), facce(auto)))
    mancano = [i.name for i in bpy.data.images if i.size[0] == 0]
    if mancano:
        print("ATTENZIONE: immagini senza dati nel .glb (uscirebbero magenta): %s" % mancano)
        sys.exit(1)

    blocco("Prato", -6.0, 6.0, -6.0, 6.0, -0.02, 0.0, tinta("Prato", (0.05, 0.055, 0.05)))
    righe = tinta("Assi", (0.45, 0.45, 0.42))
    blocco("AsseX", -3.0, 3.0, -0.012, 0.012, 0.0, 0.004, righe)
    blocco("AsseY", -0.012, 0.012, -3.0, 3.0, 0.0, 0.004, righe)
    blocco("Muso", 2.00, 2.08, -0.04, 0.04, 0.0, 0.60, tinta("Muso", (0.60, 0.02, 0.02)))

    os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
    L, H = 640, 360
    scatta = prepara_render(L, H, cielo=(0.10, 0.11, 0.13))
    if hasattr(bpy.context.scene, "eevee"):
        bpy.context.scene.eevee.taa_render_samples = 32
    # COORDINATE DI GIOCO da qui in giu' - x, y in alto, z - mentre i blocchi qui sopra
    # sono in quelle di Blender, come l'auto. E' lo scambio che in questo progetto ha
    # gia' messo una camera sotto il pavimento (D-195): la fiancata sinistra dell'auto
    # sta a +Y di Blender, cioe' a -z di gioco.
    lampada("Chiave", (3.0, 5.0, -3.0), 2500.0, tipo="AREA", dimensione=3.0)
    lampada("Riempimento", (-4.0, 2.5, 4.0), 900.0)
    lampada("Contro", (-3.5, 3.5, -3.5), 600.0)
    viste = (((4.4, 2.2, -4.4), (0.2, 0.5, 0.0)),     # davanti-sinistra, dall'alto
             ((-4.6, 1.6, 4.0), (0.0, 0.6, 0.0)),     # dietro-destra, ad altezza d'occhio
             ((0.0, 0.8, 6.0), (0.0, 0.6, 0.0)),      # fianco destro: il muso a destra
             ((0.0, 8.5, 1.2), (0.0, 0.0, 0.0)))      # dall'alto
    tessere = []
    for posizione, mira in viste:
        scatta(PROVINO, posizione, mira, lente=32.0)
        img = bpy.data.images.load(PROVINO)
        px = np.empty(L * H * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        tessere.append(px.reshape(H, L, 4))
        bpy.data.images.remove(img)
    # le righe di un'immagine di Blender partono dal BASSO
    tutto = np.concatenate([np.concatenate(tessere[2:], axis=1),
                            np.concatenate(tessere[:2], axis=1)], axis=0)
    fuori = bpy.data.images.new("Provino", 2 * L, 2 * H, alpha=False)
    fuori.pixels.foreach_set(tutto.ravel())
    fuori.filepath_raw = PROVINO
    fuori.file_format = "PNG"
    fuori.save()
    print("\n  provino: %s" % PROVINO)


def main():
    print("")
    pulisci()
    importa()
    mesh = butta(cuoci())
    orienta(mesh)
    posa(mesh)
    decima(mesh)
    posa(mesh)
    problemi = verifica(mesh)
    if problemi:
        print("\nATTENZIONE: non e' uscita un'auto")
        for p in problemi:
            print("  " + p)
        sys.exit(1)
    materiali(mesh)
    auto = unisci(mesh)
    print("  %s: %d facce, %d materiali" % (auto.name, len(auto.data.polygons),
                                          len(auto.data.materials)))
    esporta(USCITA)
    mb = os.path.getsize(USCITA) / 1048576.0
    print("  il .glb pesa %.2f MB" % mb)
    if mb > 6.0:
        print("\nATTENZIONE: %.1f MB per un'auto parcheggiata - quasi sempre e' una mappa"
              " rimasta a piena risoluzione: vedi usa_le_ridotte()." % mb)
        sys.exit(1)
    provino()


main()
