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

L'ANTA ARRIVA APERTA, e va chiusa qui. Nel .gltf sta ruotata di 58 gradi attorno
alla verticale - l'autore l'ha fotografata cosi' - e la sua posa non e' un dato
utile: in gioco il quadro nasce CHIUSO, perche' un quadro elettrico aperto in
facciata e' un quadro che qualcuno ha lasciato aperto, cioe' una storia che qui
non c'e'. Si raddrizza per costruzione (la si porta parallela alla faccia della
cassa e ci si appoggia sopra) invece di sottrarre l'angolo dichiarato: cosi' il
risultato non dipende da quanto era aperta.

IL CARDINE SI DEDUCE, non si sceglie. Chiudendo l'anta, uno dei due spigoli
verticali si muove molto e l'altro quasi niente: quello fermo E' il cardine, ed e'
l'informazione che il modello porta senza dichiararla. Sceglierlo a caso avrebbe
funzionato la meta' delle volte, e nell'altra meta' l'anta si sarebbe aperta dal
lato della cerniera dipinta.
"""
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

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

# Il fungo rosso: Ø30 di cappello su una ghiera Ø34, sporgente 12 mm.
#
# NON E' UN PULSANTE QUALUNQUE, E' UN ARRESTO D'EMERGENZA, e la forma lo dice: il
# cappello a fungo si preme col palmo, anche al buio e anche con i guanti. E'
# esattamente il gesto che serve qui - si esce di notte, si dà corrente, si rientra.
FUNGO_R = 0.015
GHIERA_R = 0.017
FUNGO_FUORI = 0.012
GHIERA_FUORI = 0.004


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


def asse_sottile(P):
    """La direzione lungo cui la nuvola e' PIU' SCHIACCIATA, e il suo centro.

    Per una cassa e' la profondita', per un'anta e' lo spessore: in tutti e due i
    casi e' la normale della faccia grande, che e' quello che serve per orientarli.
    Si trova per iterazione di potenza su (traccia*I - covarianza), che ha lo
    stesso autovettore dominante dell'autovalore PIU' PICCOLO della covarianza.
    """
    c = sum(P, Vector()) / len(P)
    M = [[0.0] * 3 for _ in range(3)]
    for p in P:
        d = p - c
        for i in range(3):
            for j in range(3):
                M[i][j] += d[i] * d[j]
    m = Matrix(M)
    A = Matrix.Scale(m[0][0] + m[1][1] + m[2][2], 3) - m
    v = Vector((0.31, 0.67, 0.13)).normalized()
    for _ in range(300):
        v = (A @ v).normalized()
    return c, v


def orizzontale(v):
    """La componente orizzontale di una direzione, normalizzata."""
    w = Vector((v.x, v.y, 0.0))
    return w.normalized() if w.length > 1e-6 else Vector((1.0, 0.0, 0.0))


def applica(o, M):
    o.matrix_world = M @ o.matrix_world


def main():
    pulisci()
    cassa, anta = importa()

    Pc = punti(cassa)
    Pa = punti(anta)
    centro_c, n_c = asse_sottile(Pc)
    centro_a, n_a = asse_sottile(Pa)
    n_c = orizzontale(n_c)
    n_a = orizzontale(n_a)

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
    applica(cassa, Matrix.Translation(Vector((
        -(max(xs) + min(xs)) / 2.0, -max(ys), -(max(zs) + min(zs)) / 2.0))))
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

    # L'ANTA SI CHIUDE PER COSTRUZIONE. La si gira attorno alla verticale finche' e'
    # parallela alla faccia della cassa, poi la si appoggia sopra: centro con
    # centro, e la sua faccia interna a filo del fronte. Non si sottrae l'angolo di
    # apertura dichiarato dal modello - cosi' il risultato non dipende da quanto
    # l'autore l'aveva spalancata.
    prima = punti(anta)
    _, n_a2 = asse_sottile(prima)
    n_a2 = orizzontale(n_a2)
    if n_a2.dot(Vector((0.0, -1.0, 0.0))) < 0.0:
        n_a2 = -n_a2
    giro = math.atan2(n_a2.y, n_a2.x) - math.atan2(-1.0, 0.0)
    perno_prov = sum(prima, Vector()) / len(prima)
    applica(anta, Matrix.Translation(perno_prov) @ Matrix.Rotation(-giro, 4, "Z")
            @ Matrix.Translation(-perno_prov))
    Pa = punti(anta)
    xs = [p.x for p in Pa]
    ys = [p.y for p in Pa]
    zs = [p.z for p in Pa]
    applica(anta, Matrix.Translation(Vector((
        -(max(xs) + min(xs)) / 2.0,
        fronte - max(ys),
        -(max(zs) + min(zs)) / 2.0))))

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
    perno_x = a_sx if cardine_sx else a_dx
    print("  anta chiusa: spigolo sinistro ha corso %.3f m, destro %.3f m -> "
          "cardine a %s" % (corse["sinistro"], corse["destro"],
                            "sinistra" if cardine_sx else "destra"))

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
    bx = perno_x + (0.10 if cardine_sx else -0.10)
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
    ghiera = bpy.data.objects.get("PlasticaNera")
    fungo = bpy.data.objects.get("PulsanteRete")
    if fungo is not None:
        fungo.name = "Fungo"
    if ghiera is not None:
        ghiera.name = "Ghiera"

    # L'ORIGINE DELL'ANTA SUL CARDINE, e con lei quella del pulsante: in gioco si
    # ruota il nodo `Anta`, e tutto quello che ci sta appeso deve girare con lei.
    perno = Vector((perno_x, fronte, 0.0))
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

    pezzi = [o for o in (cassa, anta) if o is not None]
    raddrizza_normali(pezzi)
    usa_le_ridotte(pezzi, "quadro_elettrico")
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


main()
