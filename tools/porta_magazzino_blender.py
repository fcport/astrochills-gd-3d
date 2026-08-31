# -*- coding: utf-8 -*-
"""Il BATTENTE della porta del magazzino, con l'origine sul cardine.

    "D:/programs/blender5/blender.exe" --background --python tools/porta_magazzino_blender.py

QUESTO E' UN MODELLO CHE RUOTA, e per questo sta in un .glb tutto suo invece che
dentro quello dell'edificio. Un'anta ha bisogno di un nodo proprio con l'origine sul
cardine: dentro `osservatorio.glb`, che e' una mesh sola, girerebbe l'intero
edificio. In gioco questo file viene istanziato SOTTO il nodo `Door` del magazzino,
che resta uguale a quello delle altre nove ante e continua a passare per lo stesso
banco.

COSA SI TIENE E COSA SI BUTTA. Il modello scaricato porta cinque pezzi separati -
`Main_Low`, `Handle_Low`, `HandleBase_Low`, `Frame_Low`, `Hinges_Low` - ed e' proprio
quella separazione a renderlo usabile: il TELAIO ce l'abbiamo gia', lo disegna
`osservatorio_blender.py` dai vani dichiarati in `geometria.py`, e montarne un
secondo darebbe due mostre incastrate una nell'altra. Restano il pannello e la
maniglia. I cardini si buttano con il telaio: sono un dettaglio del telaio, non
dell'anta, e a battente chiuso non si vedono comunque.

LA MANIGLIA SI SPECCHIA. Il modello ne ha UNA, sulla faccia da cui l'autore l'ha
fotografata; una porta vera ce l'ha su tutte e due. Non e' pignoleria: senza, la
faccia dell'anta che da' sul corridoio - da cui la porta si apre davvero - sarebbe
una lastra liscia, e il giocatore preme E davanti a niente.
"""
import os
import sys

import bpy
from mathutils import Matrix

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
import importlib   # noqa: E402
for _m in ("geometria", "modellare"):
    if _m in sys.modules:
        importlib.reload(sys.modules[_m])
from geometria import ante_porte   # noqa: E402
from modellare import esporta, pulisci, raddrizza_normali, usa_le_ridotte   # noqa: E402

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "porta_magazzino.glb")
SORGENTE = os.path.join(RADICE, "assets", "models", "esterni", "porta_magazzino",
                        "scene.gltf")

QUALE = "magazzino"

# Quanto puo' essere anisotropa la scala prima di doverlo dire. Il pannello si scala
# in modo NON uniforme - va fatto entrare in un vano che non ha le sue proporzioni -
# e finche' i tre fattori stanno vicini non si vede; oltre, una porta stirata si
# riconosce anche senza metro.
STIRAMENTO_MASSIMO = 1.25


def pezzi():
    """I mesh importati, riconosciuti dalla GEOMETRIA e non dal nome.

    IL NOME NON SOPRAVVIVE ALL'IMPORT: l'importatore glTF chiama gli oggetti come la
    MESH, e in questo modello tutte e cinque le mesh si chiamano `defaultMaterial`.
    Cinque oggetti omonimi, e i nomi buoni - `Main_Low`, `Frame_Low` - restano solo
    nei nodi del .gltf, che l'importatore non riporta. Si riconoscono da come sono
    fatti, che e' comunque il criterio piu' solido: il pannello e' il pezzo largo e
    sottile, il telaio quello che lo contiene, i cardini una striscia sul filo.
    """
    fuori = []
    for o in bpy.data.objects:
        if o.type != "MESH" or o.data is None or not o.data.vertices:
            continue
        p = [o.matrix_world @ v.co for v in o.data.vertices]
        fuori.append((o, (min(q.x for q in p), max(q.x for q in p),
                          min(q.y for q in p), max(q.y for q in p),
                          min(q.z for q in p), max(q.z for q in p))))
    return fuori


def largo(b):
    return b[1] - b[0]


def alto(b):
    return b[5] - b[4]


def spesso(b):
    return b[3] - b[2]


print("")
pulisci()
if not os.path.exists(SORGENTE):
    print("MANCA il modello: %s" % SORGENTE)
    print("  lancia prima: python tools/prendi_modello.py porta_magazzino")
    sys.exit(1)
bpy.ops.import_scene.gltf(filepath=SORGENTE)

tutti = pezzi()
# il PANNELLO e' il pezzo piu' alto fra quelli larghi almeno mezzo modello e spessi
# meno di un decimo dell'altezza: e' la definizione di una lastra
scala_x = max(largo(b) for _o, b in tutti)
candidati = [(o, b) for (o, b) in tutti
             if largo(b) > scala_x * 0.5 and spesso(b) < alto(b) * 0.1]
if not candidati:
    print("ATTENZIONE: nessun pezzo ha la forma di un pannello")
    sys.exit(1)
# fra i due larghi (pannello e telaio) il TELAIO e' quello che contiene l'altro
candidati.sort(key=lambda ob: largo(ob[1]))
pannello, bp = candidati[0]
telaio = [o for (o, b) in candidati[1:]]
print("  pannello: %.1f largo, %.1f alto, %.1f spesso" % (largo(bp), alto(bp), spesso(bp)))

# il CARDINE sta dal lato dove ci sono i cardini: la striscia sottile sul filo
cardini = [(o, b) for (o, b) in tutti
           if o is not pannello and largo(b) < largo(bp) * 0.1 and alto(b) > alto(bp) * 0.5]
if cardini:
    x_cardini = sum((b[0] + b[1]) / 2 for _o, b in cardini) / len(cardini)
else:
    x_cardini = bp[0]
lato_cardine = -1.0 if x_cardini < (bp[0] + bp[1]) / 2 else +1.0
print("  i cardini stanno a x=%.1f, cioe' sul filo %s"
      % (x_cardini, "sinistro" if lato_cardine < 0 else "destro"))

# si buttano telaio e cardini: il telaio lo disegna gia' osservatorio_blender.py
da_buttare = telaio + [o for o, _b in cardini]
maniglia = [o for (o, _b) in tutti if o is not pannello and o not in da_buttare]
print("  si buttano %d pezzi (telaio e cardini), restano il pannello e %d di maniglia"
      % (len(da_buttare), len(maniglia)))
for o in da_buttare:
    bpy.data.objects.remove(o, do_unlink=True)

# --- misure volute -----------------------------------------------------------
a = [x for x in ante_porte() if x["nome"] == QUALE]
if not a:
    print("ATTENZIONE: in geometria non c'e' nessuna porta '%s'" % QUALE)
    sys.exit(1)
a = a[0]
L, HA, T = a["larghezza"], a["altezza"], a["spessore"]
print("  il vano vuole un'anta %.3f x %.3f x %.3f" % (L, HA, T))

sx = L / largo(bp)
sy = T / spesso(bp)
sz = HA / alto(bp)
stira = max(sx, sy, sz) / min(sx, sy, sz)
print("  fattori di scala %.5f %.5f %.5f  (stiramento %.2f)" % (sx, sy, sz, stira))
if stira > STIRAMENTO_MASSIMO:
    print("")
    print("ATTENZIONE: il modello va stirato di %.2f volte per entrare nel vano,"
          % stira)
    print("  oltre il %.2f ammesso. Un'anta stirata cosi' si riconosce a occhio:"
          % STIRAMENTO_MASSIMO)
    print("  o si cambia modello, o si cambia il vano in geometria.py.")
    sys.exit(1)

perno = bpy.data.objects.new("PortaMagazzino", None)
bpy.context.collection.objects.link(perno)
for o in list(bpy.data.objects):
    if o is not perno and o.parent is None:
        o.parent = perno
perno.scale = (sx, sy, sz)
bpy.context.view_layer.update()

# LA MANIGLIA NON SI STIRA CON IL PANNELLO. I tre fattori non sono uguali - il
# pannello deve entrare in un vano che non ha le sue proporzioni - e una maniglia
# schiacciata dell'otto per cento su un asse solo si vede, perche' e' un oggetto
# tondo in mezzo a una lastra piatta. Le si ridà una scala uniforme attorno al
# proprio centro: il pannello resta esatto, la leva resta tonda.
uniforme = (sx * sy * sz) ** (1.0 / 3.0)
for o in bpy.data.objects:
    if o.type != "MESH" or o is pannello or o.data is None:
        continue
    if o.data is pannello.data:
        continue
    o.scale = (uniforme / sx, uniforme / sy, uniforme / sz)
bpy.context.view_layer.update()

# --- si porta il cardine nell'origine ----------------------------------------
# Convenzione del progetto per un'anta: X locale dal CARDINE verso il bordo libero,
# Y l'altezza dal pavimento, Z lo spessore centrato sullo zero. La stessa che usa
# `geometria.pezzi_anta`, e quindi la stessa che si aspetta il nodo `Door`.
b2 = [b for (o, b) in pezzi() if o is pannello][0]
if lato_cardine > 0:
    # i cardini stanno a destra: si specchia, cosi' l'anta si estende sempre verso +X
    perno.scale.x *= -1.0
    bpy.context.view_layer.update()
    b2 = [b for (o, b) in pezzi() if o is pannello][0]
perno.location = (perno.location.x - b2[0],
                  perno.location.y - (b2[2] + b2[3]) / 2.0,
                  perno.location.z - b2[4])
bpy.context.view_layer.update()

b3 = [b for (o, b) in pezzi() if o is pannello][0]
print("  posato: x %.3f..%.3f   y %.3f..%.3f   z %.3f..%.3f"
      % (b3[0], b3[1], b3[2], b3[3], b3[4], b3[5]))
problemi = []
for nome, avuto, voluto in (("il cardine non e' nell'origine", b3[0], 0.0),
                            ("l'anta non e' lunga quanto il vano", b3[1], L),
                            ("l'anta non parte dal pavimento", b3[4], 0.0),
                            ("l'anta non arriva all'architrave", b3[5], HA)):
    if abs(avuto - voluto) > 0.004:
        problemi.append("  %s: %.3f invece di %.3f" % (nome, avuto, voluto))

# --- si cuoce la posa nella mesh, e SOLO ALLORA si specchia la maniglia -------
#
# L'ORDINE E' TUTTO, e sbagliarlo e' costato un giro. Lo specchio era stato fatto
# subito dopo l'import, prima della scala: la correzione uniforme delle maniglie
# riscrive `o.scale` per intero, e con essa cancellava il -1 che faceva lo specchio.
# Le due copie finivano quindi sovrapposte sulla STESSA faccia, e in gioco l'anta
# vista dal corridoio era una lastra liscia senza maniglia - cioe' il giocatore
# premeva E davanti a niente. Adesso prima si cuoce tutto nella mesh, poi si
# specchia una mesh gia' ferma: non c'e' piu' nessuna scala che possa cancellarlo.
for o in [x for x in bpy.data.objects if x.type == "MESH"]:
    o.data.transform(o.matrix_world)
    o.parent = None
    o.matrix_world = Matrix()
bpy.context.view_layer.update()

b_p = [b for (o, b) in pezzi() if o is pannello][0]
mezzo_y = (b_p[2] + b_p[3]) / 2.0
specchio = (Matrix.Translation((0.0, 2.0 * mezzo_y, 0.0))
            @ Matrix.Scale(-1.0, 4, (0.0, 1.0, 0.0)))
for o in list(maniglia):
    copia = o.copy()
    copia.data = o.data.copy()
    bpy.context.collection.objects.link(copia)
    copia.data.transform(specchio)
bpy.context.view_layer.update()
quante = [b for (o, b) in pezzi() if o is not pannello]
print("  la maniglia sta su tutte e due le facce: y da %.3f a %.3f"
      % (min(b[2] for b in quante), max(b[3] for b in quante)))

# raddrizza_normali dopo lo specchio NON e' un di piu': specchiare inverte
# l'avvolgimento delle facce, e in Godot una faccia avvolta al contrario si illumina
# con la normale sbagliata, cioe' esce nera.
girate = raddrizza_normali(list(bpy.data.objects))
if girate:
    print("  %d facce avevano la normale al contrario" % girate)
# METALLICO A ZERO. Ottava volta: il glTF non dichiara `metallicFactor`, e quando
# manca il valore predefinito e' UNO. Una porta VERNICIATA non e' uno specchio, e
# uno specchio in un corridoio buio e' nero.
usa_le_ridotte([o for o in bpy.data.objects if o.type == "MESH"],
               os.path.dirname(SORGENTE), metallico=0.0)

if problemi:
    print("\nATTENZIONE:")
    for p in problemi:
        print(p)
    sys.exit(1)

esporta(USCITA, escludi=(perno,))
_mb = os.path.getsize(USCITA) / 1048576.0
print("  il battente pesa %.1f MB" % _mb)
if _mb > 6.0:
    print("\nATTENZIONE: %.1f MB per un'anta sola - quasi sempre e' una mappa presa"
          " da fuori e rimasta a piena risoluzione: vedi usa_le_ridotte()." % _mb)
    sys.exit(1)
