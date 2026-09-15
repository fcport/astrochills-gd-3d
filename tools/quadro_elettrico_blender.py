# -*- coding: utf-8 -*-
"""Il QUADRO ELETTRICO in facciata: cassa, anta che si apre, pulsante di rete.

    "D:/programs/blender5/blender.exe" --background --python tools/quadro_elettrico_blender.py

E' il contatore che il GDD mette in facciata - quello che governa PC, monitor,
montatura e luci, e che nel 1999 si riarma A MANO, uscendo al buio. Sta in un .glb
suo e non dentro `osservatorio.glb` per la stessa ragione della porta del
magazzino: ha un pezzo che RUOTA, e un'anta dentro una mesh sola farebbe girare
l'edificio.

QUELLO CHE ARRIVA E QUELLO CHE MANCA. Il modello scaricato ha due mesh, cassa e
anta, e la separazione e' l'unica ragione per cui vale la pena usarlo: un quadro
che non si apre e' una scatola sul muro. Non ha invece nessun pulsante - dentro
c'e' il cablaggio, sull'anta c'e' un cartello di pericolo, e basta. Il fungo rosso
lo mettiamo noi, ed e' la stessa regola del pilastro sotto il telescopio: si
modella il pezzo che manca e che deve muoversi, non si reinventa quello che c'e'.

L'ANTA ARRIVA APERTA, e va chiusa qui. Nel .gltf sta spalancata di 117 gradi
attorno alla verticale - l'autore l'ha fotografata cosi' - e la sua posa non e' un
dato utile: in gioco il quadro nasce CHIUSO, perche' un quadro elettrico aperto in
facciata e' un quadro che qualcuno ha lasciato aperto, cioe' una storia che qui
non c'e'. Si chiude girandola sulla sua cerniera finche' e' parallela alla faccia
della cassa, e poi ci si appoggia sopra (D-254). Per un mese la si e' girata
attorno al centro, di 58 gradi, ed era montata al contrario.

IL CARDINE SI DEDUCE, non si sceglie. Chiudendo l'anta, uno dei due spigoli
verticali si muove molto e l'altro quasi niente: quello fermo E' il cardine, ed e'
l'informazione che il modello porta senza dichiararla. Sceglierlo a caso avrebbe
funzionato la meta' delle volte, e nell'altra meta' l'anta si sarebbe aperta dal
lato della cerniera dipinta.
"""
import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.kdtree import KDTree

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
import importlib   # noqa: E402
for _m in ("geometria", "modellare"):
    if _m in sys.modules:
        importlib.reload(sys.modules[_m])
from modellare import (cilindro_orizz, esporta, finisci, lampada,   # noqa: E402
                       materiale,
                       prepara_render, pulisci, raddrizza_normali,
                       usa_le_ridotte)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "quadro_elettrico.glb")
SORGENTE = os.path.join(RADICE, "assets", "models", "esterni", "quadro_elettrico",
                        "scene.gltf")
PROVINO = os.path.join(RADICE, "_confronto", "14_quadro_elettrico.png")

# QUANTO E' ALTO IL QUADRO, in metri. E' la quota da cui esce tutto il resto: il
# modello arriva senza unita' (57,7 x 39,3 x 28,0 di nulla), si dichiara una misura
# vera e la scala esce da li'. Quarantadue centimetri e' un quadretto da esterno da
# dodici moduli - quello che governa un edificio piccolo, non un capannone.
ALTO = 0.42

# Di quanti gradi la apre `PanelDoor.APERTURA`: il provino dell'anta aperta la mette li'.
APERTA = 110.0

# Il fungo rosso: Ø30 di cappello su una ghiera Ø34, sporgente 12 mm.
#
# NON E' UN PULSANTE QUALUNQUE, E' UN ARRESTO D'EMERGENZA, e la forma lo dice: il
# cappello a fungo si preme col palmo, anche al buio e anche con i guanti. E'
# esattamente il gesto che serve qui - si esce di notte, si dà corrente, si rientra.
FUNGO_R = 0.015
GHIERA_R = 0.017
FUNGO_FUORI = 0.012
GHIERA_FUORI = 0.004

# IL PULSANTE ROSSO DENTRO IL QUADRO (D-256). C'e' nel modello - un fungo su una
# piastrina nera, a destra dei morsetti - ed e' quello che si preme a quadro aperto.
# Federico: «mi dai la possibilita' qui di staccare tutte le luci e riaccenderle?». Il
# fungo sull'anta stacca la stessa corrente, ma ad anta aperta sta girato dall'altra
# parte. Dove sta sulla faccia della cassa, (x, alto) in metri, misurato il 15/9: il
# cappello e' largo 2,4 cm, e lo si cerca in una finestra di 5.
PULSANTE_DENTRO = (0.095, 0.002)
FINESTRA_PULSANTE = 0.025


def importa():
    """I due pezzi, riconosciuti dal MATERIALE e non dal nome.

    IL NOME NON SOPRAVVIVE ALL'IMPORT: l'importatore glTF chiama gli oggetti come
    la mesh, e qui tutte e due le mesh si chiamano `defaultMaterial`. Il materiale
    invece porta il nome che l'autore gli ha dato, ed e' l'unica cosa distinguibile
    - stessa trappola e stessa cura di `porta_magazzino_blender.py`.
    """
    if not os.path.exists(SORGENTE):
        print("MANCA il modello del quadro elettrico.")
        print("  lancia prima: python tools/prendi_modello.py quadro_elettrico")
        raise SystemExit(1)
    bpy.ops.import_scene.gltf(filepath=SORGENTE)
    pezzi = {}
    for o in list(bpy.data.objects):
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)
            continue
        pezzi[o.data.materials[0].name] = o
    manca = {"Fuse_box_main", "fuse_box_door"} - set(pezzi)
    if manca:
        raise SystemExit("il modello non ha i materiali attesi: manca %s" % manca)
    return pezzi["Fuse_box_main"], pezzi["fuse_box_door"]


def punti(o):
    return [o.matrix_world @ v.co for v in o.data.vertices]


def faccia_grande(o):
    """Il centro dei vertici, e la direzione ORIZZONTALE della faccia grande.

    Per una cassa e' la profondita', per un'anta e' lo spessore: in tutti e due i
    casi e' quello che serve per orientarli.

    SI PESA PER AREA, NON PER VERTICE (D-256). La prima stesura cercava la direzione
    lungo cui la nuvola di vertici e' piu' schiacciata, e cosi' ogni vertice contava
    uguale: le cerniere e il bordo ripiegato dell'anta ne hanno piu' della lamiera
    intera, e la tiravano di 5,3 gradi. Chiusa, l'anta toccava la cassa dal lato
    libero e ne stava a 2,3 cm dal lato del cardine - e aperta sembrava staccata.
    Federico: «e' ancora un po' staccato». Le facce invece pesano quanto sono grandi,
    e la lamiera vince.

    Davanti e dietro sono la stessa direzione, quindi le normali si piegano su mezzo
    giro: si prende il grado con piu' area, e si media attorno a quello.
    """
    R = o.matrix_world.to_3x3()
    facce = []
    area = {}
    for f in o.data.polygons:
        n = (R @ f.normal).normalized()
        if abs(n.z) > 0.3:
            continue
        n = Vector((n.x, n.y, 0.0)).normalized()
        g = round(math.degrees(math.atan2(n.y, n.x))) % 180
        facce.append((n, f.area, g))
        area[g] = area.get(g, 0.0) + f.area
    piu = max(area, key=area.get)
    rif = Vector((math.cos(math.radians(piu)), math.sin(math.radians(piu)), 0.0))
    somma = Vector()
    for n, a, g in facce:
        if min((g - piu) % 180, (piu - g) % 180) <= 10:
            somma += n * a * (1.0 if n.dot(rif) >= 0.0 else -1.0)
    P = punti(o)
    return sum(P, Vector()) / len(P), somma.normalized()


def applica(o, M):
    o.matrix_world = M @ o.matrix_world


def stacca_il_pulsante(cassa):
    """Il cappello rosso del pulsante interno, staccato dalla cassa: in gioco rientra.

    SI RICONOSCE DAL COLORE, non dalla forma. Nella stessa finestra c'e' la piastrina
    nera su cui e' avvitato, alla profondita' del gambo: separarli per quota vorrebbe
    dire scegliere un millimetro. La texture invece li distingue da sola.
    """
    img = None
    for n in cassa.data.materials[0].node_tree.nodes:
        if n.type == "TEX_IMAGE" and n.image is not None and any(
                l.to_socket.name == "Base Color" for l in n.outputs["Color"].links):
            img = n.image
    if img is None:
        raise SystemExit("la cassa non ha la texture di colore: il pulsante non si trova")
    w, h = img.size
    colori = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(colori)
    colori = colori.reshape(h, w, 4)
    uv = cassa.data.uv_layers.active.data
    cx, cz = PULSANTE_DENTRO
    rosse = []
    for f in cassa.data.polygons:
        c = cassa.matrix_world @ f.center
        # Davanti al fondo della cassa, che sta a tre centimetri dal muro.
        if abs(c.x - cx) > FINESTRA_PULSANTE or abs(c.z - cz) > FINESTRA_PULSANTE or c.y > -0.030:
            continue
        u = sum(uv[i].uv[0] for i in f.loop_indices) / f.loop_total
        v = sum(uv[i].uv[1] for i in f.loop_indices) / f.loop_total
        r, g, b = colori[int(v * h) % h, int(u * w) % w][:3]
        if r > 0.25 and g < 0.6 * r and b < 0.6 * r:
            rosse.append(f.index)
    if len(rosse) < 20:
        raise SystemExit("il cappello rosso non si trova: %d facce rosse" % len(rosse))

    bpy.ops.object.select_all(action="DESELECT")
    cassa.select_set(True)
    bpy.context.view_layer.objects.active = cassa
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_mode(type="FACE")
    bpy.ops.mesh.select_all(action="DESELECT")
    bm = bmesh.from_edit_mesh(cassa.data)
    bm.faces.ensure_lookup_table()
    for i in rosse:
        bm.faces[i].select_set(True)
    bmesh.update_edit_mesh(cassa.data)
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    pulsante = next(o for o in bpy.context.selected_objects if o is not cassa)
    P = punti(pulsante)
    print("  pulsante dentro: %d facce rosse, x [%.3f %.3f] y [%.3f %.3f] z [%.3f %.3f]"
          % (len(rosse), min(p.x for p in P), max(p.x for p in P), min(p.y for p in P),
             max(p.y for p in P), min(p.z for p in P), max(p.z for p in P)))
    return pulsante


def centro(o):
    P = punti(o)
    return Vector(((min(p.x for p in P) + max(p.x for p in P)) / 2.0,
                   (min(p.y for p in P) + max(p.y for p in P)) / 2.0,
                   (min(p.z for p in P) + max(p.z for p in P)) / 2.0))


def in_gioco(v):
    """Da Blender al gioco: x resta x, l'alto e' y, e la profondita' cambia segno."""
    return Vector((v.x, v.z, -v.y))


def main():
    pulisci()
    cassa, anta = importa()

    Pc = punti(cassa)
    centro_c, n_c = faccia_grande(cassa)
    centro_a, _ = faccia_grande(anta)

    # DA CHE PARTE E' IL DAVANTI DELLA CASSA. Non dalla forma - il retro e il
    # fronte di una scatola si somigliano - ma dall'ANTA: e' appesa al davanti, e
    # nel modello sta spalancata li'. Il verso in cui il suo centro si allontana da
    # quello della cassa e' il verso della faccia aperta.
    if (centro_a - centro_c).dot(n_c) < 0.0:
        n_c = -n_c

    # Tutto in piedi e rivolto a -Y: la conversione Y-alto del glTF manda -Y di
    # Blender su +Z di Godot, che e' il verso in cui questo progetto fa guardare
    # gli oggetti appesi a un muro (vedi la pulsantiera).
    ang = math.atan2(n_c.y, n_c.x) - math.atan2(-1.0, 0.0)
    R = Matrix.Rotation(-ang, 4, "Z")
    zs = [p.z for p in Pc]
    scala = ALTO / (max(zs) - min(zs))
    S = Matrix.Scale(scala, 4)
    applica(cassa, S @ R)
    applica(anta, S @ R)

    # La cassa: retro sul muro (y = 0), centrata in x, centrata in z.
    Pc = punti(cassa)
    xs = [p.x for p in Pc]
    ys = [p.y for p in Pc]
    zs = [p.z for p in Pc]
    # E L'ANTA CON LEI: si chiude girando sul cardine, e il cardine si riconosce perche'
    # sta accanto al bordo della cassa. Spostata solo la cassa, l'anta restava dov'era.
    sposta = Matrix.Translation(Vector((
        -(max(xs) + min(xs)) / 2.0, -max(ys), -(max(zs) + min(zs)) / 2.0)))
    applica(cassa, sposta)
    applica(anta, sposta)
    Pc = punti(cassa)
    fronte = min(p.y for p in Pc)          # la faccia aperta, verso -Y
    largo = max(p.x for p in Pc) - min(p.x for p in Pc)
    fondo = max(p.y for p in Pc) - min(p.y for p in Pc)
    print("  cassa: %.3f largo, %.3f fondo, %.3f alto; faccia aperta a y = %.3f"
          % (largo, fondo, ALTO, fronte))
    print("  cassa: x [%.3f %.3f]  y [%.3f %.3f]  z [%.3f %.3f]"
          % (min(p.x for p in Pc), max(p.x for p in Pc),
             min(p.y for p in Pc), max(p.y for p in Pc),
             min(p.z for p in Pc), max(p.z for p in Pc)))
    pulsante = stacca_il_pulsante(cassa)

    # L'ANTA SI CHIUDE GIRANDO SUL SUO CARDINE (D-254), poi la si appoggia sopra: centro
    # con centro, e la sua faccia interna a filo del fronte.
    #
    # LA PRIMA STESURA LA GIRAVA ATTORNO AL SUO CENTRO, della rotazione PIU' CORTA che
    # la rende parallela alla faccia: cinquantotto gradi. Ma l'autore l'ha spalancata
    # oltre l'angolo retto, e i gradi veri erano centodiciassette (D-256): l'anta usciva montata al
    # contrario - la vaschetta col bordo verso fuori, il cartello del pericolo verso i
    # fili - e col cardine dall'altra parte. Federico: «come se qualcuno montasse una
    # porta con lo spioncino che guarda verso dentro». Il provino la mostrava, e nessuno
    # l'aveva guardato con quella domanda.
    #
    # UNA ROTAZIONE ATTORNO ALLA CERNIERA NON PUO' ROVESCIARE L'ANTA: e' il gesto vero di
    # chi la chiude. La cerniera e' lo spigolo verticale dell'anta piu' vicino a uno
    # spigolo del fronte della cassa; delle due rotazioni che rendono l'anta parallela si
    # tiene quella che la porta DAVANTI all'apertura, e non dall'altra parte del cardine.
    prima = punti(anta)
    _, n_a2 = faccia_grande(anta)
    largo_a = Vector((-n_a2.y, n_a2.x, 0.0))
    lati = [p.dot(largo_a) for p in prima]

    def spigolo(dove):
        sel = [p for p, l in zip(prima, lati) if abs(l - dove) < 0.02]
        m = sum(sel, Vector()) / len(sel)
        return Vector((m.x, m.y, 0.0))

    bordi = [Vector((min(p.x for p in Pc), fronte, 0.0)),
             Vector((max(p.x for p in Pc), fronte, 0.0))]
    cerniera = min((spigolo(min(lati)), spigolo(max(lati))),
                   key=lambda s: min((s - b).length for b in bordi))
    centro_prima = sum(prima, Vector()) / len(prima)
    centro_prima.z = 0.0
    giro = math.atan2(n_a2.y, n_a2.x) - math.atan2(-1.0, 0.0)
    scelta = None
    for g in (giro, giro + math.pi):
        M = (Matrix.Translation(cerniera) @ Matrix.Rotation(-g, 4, "Z")
             @ Matrix.Translation(-cerniera))
        # La cassa e' centrata in x: davanti all'apertura vuol dire vicino a x = 0.
        scarto = abs((M @ centro_prima).x)
        if scelta is None or scarto < scelta[0]:
            scelta = (scarto, M, g)
    applica(anta, scelta[1])
    gradi = math.degrees(math.atan2(math.sin(-scelta[2]), math.cos(-scelta[2])))
    print("  anta chiusa sulla cerniera a x %.3f y %.3f, girandola di %.0f gradi"
          % (cerniera.x, cerniera.y, gradi))
    # SI APPOGGIA SPOSTANDOLA SOLO IN PROFONDITA'. Girata sulla cerniera vera, l'anta e'
    # gia' all'altezza e al lato in cui l'ha messa l'autore. La prima stesura la
    # centrava sull'ingombro della cassa, che comprende le staffe sotto: il centro
    # cadeva tre centimetri piu' in basso della cassa, e sopra l'anta chiusa restava una
    # fessura da cui si vedevano i fili (D-254).
    Pa = punti(anta)
    appoggio = Matrix.Translation(Vector((0.0, fronte - max(p.y for p in Pa), 0.0)))
    applica(anta, appoggio)

    # IL PERNO E' IL PUNTO CHE LA CHIUSURA LASCIA FERMO (D-255), e non lo spigolo della
    # lamiera. La cerniera scelta sopra e' la media dei vertici del bordo della vaschetta,
    # e dopo il giro l'anta e' stata anche spostata in profondita': giro piu' spostamento
    # e' ancora una rotazione di 117 gradi, ma attorno a un altro punto. E' quello il
    # perno vero - riaprendo l'anta li' attorno torna esattamente come l'ha fotografata
    # l'autore, appesa alla cassa a tre millimetri. Messo sullo spigolo, l'anta girava
    # staccata di tre centimetri e mezzo. Federico: «STACCATO».
    chiusura = appoggio @ scelta[1]
    fermo = Matrix(((1.0 - chiusura[0][0], -chiusura[0][1]),
                    (-chiusura[1][0], 1.0 - chiusura[1][1]))).inverted() @ Vector(
        (chiusura[0][3], chiusura[1][3]))

    # IL CARDINE E' LO SPIGOLO CHE NON SI E' MOSSO. Chiudendo, uno dei due spigoli
    # verticali dell'anta ha fatto un arco e l'altro e' rimasto quasi dov'era: il
    # secondo e' la cerniera. Si misura, invece di sceglierla - e cosi' l'anta si
    # apre dalla parte da cui e' incernierata anche nel modello.
    dopo = punti(anta)
    print("  anta: x [%.3f %.3f]  y [%.3f %.3f]  z [%.3f %.3f]"
          % (min(p.x for p in dopo), max(p.x for p in dopo),
             min(p.y for p in dopo), max(p.y for p in dopo),
             min(p.z for p in dopo), max(p.z for p in dopo)))
    a_sx = min(p.x for p in dopo)
    a_dx = max(p.x for p in dopo)
    corse = {}
    for nome, x in (("sinistro", a_sx), ("destro", a_dx)):
        vicini = [(prima[i], dopo[i]) for i in range(len(dopo))
                  if abs(dopo[i].x - x) < 0.02]
        corse[nome] = (sum((b - a).length for a, b in vicini) / max(len(vicini), 1))
    cardine_sx = corse["sinistro"] <= corse["destro"]
    bordo_x = a_sx if cardine_sx else a_dx
    print("  anta chiusa: spigolo sinistro ha corso %.3f m, destro %.3f m -> "
          "cardine a %s" % (corse["sinistro"], corse["destro"],
                            "sinistra" if cardine_sx else "destra"))
    if (fermo.x < 0.0) != cardine_sx:
        raise SystemExit("il perno (x %.3f) non sta dal lato del cardine" % fermo.x)
    print("  PERNO: x %.3f y %.3f (in gioco: Anta a %.3f, 0, %.3f)"
          % (fermo.x, fermo.y, fermo.x, -fermo.y))

    # Il fungo, sull'anta e sul suo lato ESTERNO: un arresto d'emergenza si preme
    # senza aprire niente, che e' tutto il suo senso.
    # ATTENZIONE ALLE COORDINATE: i mattoni di `modellare` lavorano in coordinate
    # DI GIOCO - x e z in pianta, y in alto - e le convertono da sole in quelle di
    # Blender. Tutto il resto di questo file sta invece in coordinate di Blender,
    # perche' maneggia matrici di oggetti importati. Confonderle e' costato un
    # pulsante costruito sottoterra, dietro il muro e con l'asse verticale: nel
    # provino non c'era, e non c'era nessun errore.
    #
    # La faccia esterna dell'anta sta a `y` minimo in Blender, cioe' a `-y` in
    # gioco; il fungo sporge da li' verso l'esterno.
    fuori = -min(p.y for p in dopo)
    bx = bordo_x + (0.10 if cardine_sx else -0.10)
    cilindro_orizz("PlasticaNera", bx, -0.09, fuori + GHIERA_FUORI / 2.0, "z",
                   GHIERA_FUORI, GHIERA_R, seg=20)
    cilindro_orizz("PulsanteRete", bx, -0.09,
                   fuori + GHIERA_FUORI + FUNGO_FUORI / 2.0, "z",
                   FUNGO_FUORI, FUNGO_R, seg=20)
    for nome in ("PlasticaNera", "PulsanteRete"):
        materiale(nome)
    finisci()

    # I nomi finali: sono quelli che il generatore del blockout cerca in scena.
    cassa.name = "Cassa"
    anta.name = "Anta"
    pulsante.name = "Pulsante"
    ghiera = bpy.data.objects.get("PlasticaNera")
    fungo = bpy.data.objects.get("PulsanteRete")
    if fungo is not None:
        fungo.name = "Fungo"
    if ghiera is not None:
        ghiera.name = "Ghiera"

    # L'ORIGINE DELL'ANTA SUL CARDINE, e con lei quella del pulsante: in gioco si
    # ruota il nodo `Anta`, e tutto quello che ci sta appeso deve girare con lei.
    perno = Vector((fermo.x, fermo.y, 0.0))
    for o in (anta, fungo, ghiera):
        if o is None:
            continue
        # SPOSTARE UN'ORIGINE E' DUE MOSSE CHE SI ANNULLANO: la mesh indietro di
        # tanto nelle sue coordinate, l'oggetto avanti di altrettanto nel mondo.
        # Farne una sola - o peggio, scrivere `location` DOPO aver assegnato
        # `matrix_world` - sposta l'oggetto per davvero: la prima stesura lo
        # faceva, e nel provino l'anta era finita per aria mezzo metro sopra la
        # cassa, con il quadro spalancato sul suo cablaggio.
        locale = o.matrix_world.inverted() @ perno
        o.data.transform(Matrix.Translation(-locale))
        o.matrix_world = o.matrix_world @ Matrix.Translation(locale)
    for o in (fungo, ghiera):
        if o is None:
            continue
        o.parent = anta
        o.matrix_parent_inverse = anta.matrix_world.inverted()

    # I NUMERI CHE COPIA IL GENERATORE (`gen_blockout.py`, QuadroElettrico). Il corpo
    # dell'anta ha l'origine sul perno, e il suo collisore e il fungo gli stanno appesi.
    p_g = in_gioco(perno)
    Pa = punti(anta)
    lati = (max(p.x for p in Pa) - min(p.x for p in Pa), max(p.z for p in Pa) - min(p.z for p in Pa),
            max(p.y for p in Pa) - min(p.y for p in Pa))
    print("  IN GIOCO  Anta %.3f, 0.000, %.3f" % (p_g.x, p_g.z))
    print("            Anta/Col %.3f, %.3f, %.3f  lati %.3f, %.3f, %.3f"
          % (*(in_gioco(centro(anta)) - p_g), *lati))
    if fungo is not None:
        print("            Anta/Fungo %.3f, %.3f, %.3f" % tuple(in_gioco(centro(fungo)) - p_g))
    print("            Pulsante %.3f, %.3f, %.3f" % tuple(in_gioco(centro(pulsante))))

    pezzi = [cassa, anta, pulsante]
    raddrizza_normali(pezzi)
    # IL PERCORSO INTERO. Qui c'era il solo nome della cartella, che `usa_le_ridotte`
    # cercava accanto a dove si lancia Blender: non la trovava mai, e il quadro si
    # portava dentro le mappe a 4096 (D-254).
    usa_le_ridotte(pezzi, os.path.dirname(SORGENTE))
    esporta(USCITA)
    print("  scritto %s" % USCITA)

    # IL PROVINO: si GUARDA, non si deduce. Un modello che ha passato tutti i
    # controlli numerici puo' benissimo essere un mattone con un pallino sopra, e
    # quel giudizio non lo da' nessun assert.
    os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
    # COORDINATE DI GIOCO, non di Blender: `scatta` e `lampada` le convertono da
    # sole (x, y in alto, z), e la faccia del quadro guarda +Z. Passando le
    # coordinate di Blender la camera finiva sotto il pavimento a guardare in su.
    scatta = prepara_render(900, 900, cielo=(0.10, 0.11, 0.13))
    lampada("Chiave", (0.55, 0.55, 0.85), 45.0, tipo="AREA", dimensione=1.0)
    lampada("Riempimento", (-0.60, 0.10, 0.70), 18.0)
    lampada("Contro", (0.0, 0.40, -0.60), 12.0)
    scatta(PROVINO, (0.34, 0.22, 0.62), (0.0, 0.0, -0.03), lente=45.0)
    scatta(PROVINO.replace("14_", "14b_"), (0.16, 0.10, 0.75), (0.0, 0.0, -0.02),
           lente=52.0)

    # E APERTA, come la apre `PanelDoor`: i due provini di sopra la mostravano solo
    # chiusa, e un'anta che gira staccata dalla cassa da chiusa e' perfetta (D-255).
    # Si misura anche: il vertice della lamiera piu' vicino alla cassa.
    anta.matrix_world = (Matrix.Translation(perno) @ Matrix.Rotation(math.radians(APERTA), 4, "Z")
                         @ Matrix.Translation(-perno) @ anta.matrix_world)
    bpy.context.view_layer.update()
    albero = KDTree(len(cassa.data.vertices))
    for i, p in enumerate(punti(cassa)):
        albero.insert(p, i)
    albero.balance()
    stacco = min(albero.find(p)[2] for p in punti(anta))
    print("  aperta di %.0f gradi l'anta sta a %.1f mm dalla cassa" % (APERTA, stacco * 1000.0))
    scatta(PROVINO.replace("14_", "14c_"), (-0.30, 0.20, 0.75), (0.08, 0.0, 0.08),
           lente=40.0)


main()
