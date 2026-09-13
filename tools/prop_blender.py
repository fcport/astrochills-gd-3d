# -*- coding: utf-8 -*-
"""LA ROBA CHE SI PRENDE IN MANO: termos, bottiglia, tazza.

    "D:/programs/blender5/blender.exe" --background --python tools/prop_blender.py

Produce assets/models/termos.glb, bottiglia.glb, tazza.glb.

PERCHE' QUESTI TRE. Non sono decorazioni scelte a caso: sono le cose che uno porta
con se' o si lascia dietro passando una notte sveglio in un edificio freddo. Il
termos e' l'oggetto personale per definizione di chi sta in un osservatorio
d'Appennino a novembre; la bottiglia vuota e la tazza sono la traccia che qualcuno
ci ha passato delle ore. Se sono in giro e' perche' qualcuno le ha usate - che e'
la differenza fra un prop e un soprammobile.

DA POLY HAVEN, CC0, e dichiarati in `tools/prendi_modello.py`.

SI DECIMANO, ed e' il lavoro vero di questo file. I modelli arrivano da undicimila
facce l'uno: sono fatti per un rendering fermo, non per una scena dove tre di loro
rotolano per terra mentre il giocatore cammina. Il budget qui e' di poche
centinaia, e la forma regge - un termos e una bottiglia sono solidi di rotazione,
cioe' esattamente il caso in cui togliere lati non si vede.

E SI TIENE UN PEZZO SOLO. Il set delle bottiglie ne porta quattro e il servizio da
te' dieci pezzi fra piatti, tazze e teiere: qui serve UN oggetto che si prende in
mano, non un servizio apparecchiato. Gli altri pezzi restano nel file scaricato,
pronti per il giorno che servano.

L'ORIGINE VA SOTTO E AL CENTRO, come per la moka e la camera: chi li colloca
scrive la quota del piano su cui appoggiano e non deve sottrarre mezza altezza. E'
anche il centro di massa che il corpo rigido usa, e per una bottiglia averlo in
basso e' giusto - il fondo pesa piu' del collo.
"""
import os
import sys

import bmesh
import bpy
from mathutils import Matrix

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
from modellare import esporta, lampada, prepara_render   # noqa: E402

RADICE = os.path.dirname(QUI)
ESTERNI = os.path.join(RADICE, "assets", "models", "esterni")
PROVINO = os.path.join(RADICE, "_confronto", "14_prop.png")

# slug scaricato -> (pezzo da tenere, nome del .glb, budget di facce, perche')
#
# I BUDGET NON SONO UGUALI perche' non lo sono le forme. Il termos ha il tappo a
# bicchiere, il manico e la fascia: tre dettagli che a poche facce spariscono. La
# bottiglia e' un solido di rotazione liscio e regge la meta'. La tazza e' piccola
# in mano e ancora piu' piccola su un piano, e cinquecento facce sono gia' un
# lusso.
# UNA VOCE PER OGGETTO E NON PER MODELLO: dallo stesso set di bottiglie ne escono
# due sagome diverse, e due bottiglie identiche in due stanze diverse sono la cosa
# che fa sembrare un edificio un catalogo.
PROP = [
    ("modified_thermos", "modified_thermos", "termos", 900,
     "il termos: si porta su, si posa dove capita, e a meta' notte lo si va a "
     "cercare"),
    ("wine_bottles_01", "wine_bottles_01_bordeaux", "bottiglia", 700,
     "una bottiglia vuota. La bordolese: spalla netta e collo lungo, la sagoma "
     "piu' riconoscibile anche in ombra"),
    ("wine_bottles_01", "wine_bottles_01_burgundy", "bottiglione", 700,
     "la seconda bottiglia, borgognona: spalla dolce e pancia larga. Sta in "
     "cucina, e serve a non avere due volte la stessa sagoma in due stanze"),
    ("tea_set_01", "tea_set_01_cup_small_01", "tazza", 500,
     "una tazza. La cosa piu' ovvia da prendere in mano e la piu' facile da "
     "dimenticare su un piano"),
    ("tea_set_01", "tea_set_01_saucer_circular_03", "piattino", 400,
     "il piattino. Da solo non serve a niente, ed e' il punto: una tazza senza "
     "piattino non e' apparecchiata, e' stata usata"),
    # IL QUADERNO NON SI PRENDE IN MANO - si legge, ed e' `quaderno.gd` - ma e' un
    # pezzo preso da un set come gli altri, e ha bisogno delle stesse tre cose:
    # un pezzo solo, poche facce e l'origine sotto. Del set si tiene il CHIUSO: il
    # quaderno aperto e' largo trentasei centimetri e sulla consolle, fra la
    # tastiera e il telefono, non ci sta.
    # MILLEDUECENTO FACCE, piu' della tazza: e' un parallelepipedo, ma la cinghietta
    # col bottone, gli anelli che sporgono dal dorso e il bordo della carta sono le
    # tre cose che lo fanno leggere come un organizer e non come una scatola marrone.
    ("binder_notebook", "binder_notebook_closed", "quaderno", 1200,
     "il quaderno delle procedure, chiuso, sulla consolle a sinistra del monitor"),
]


def prendi_uno(slug, pezzo):
    """Importa il modello e lascia in scena solo il pezzo voluto."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sorgente = os.path.join(ESTERNI, slug, slug + "_1k.gltf")
    if not os.path.exists(sorgente):
        print("MANCA il modello: %s" % sorgente)
        print("  lancia prima: python tools/prendi_modello.py %s" % slug)
        sys.exit(1)
    bpy.ops.import_scene.gltf(filepath=sorgente)
    voluto = bpy.data.objects.get(pezzo)
    if voluto is None:
        print("ATTENZIONE: nel modello %s non c'e' il pezzo %s" % (slug, pezzo))
        print("  ci sono: %s" % ", ".join(sorted(
            o.name for o in bpy.data.objects if o.type == "MESH")))
        sys.exit(1)
    for o in list(bpy.data.objects):
        if o is not voluto:
            bpy.data.objects.remove(o, do_unlink=True)
    voluto.parent = None
    return voluto


def decima(o, budget):
    """Porta il pezzo sotto il budget di facce, e dice di quanto ha tagliato.

    IL RAPPORTO SI CALCOLA, non si sceglie: un `ratio` fisso su modelli da
    quattromila e da dodicimila facce da' due risultati diversi, e quello sbagliato
    e' silenzioso - un oggetto che pesa quattro volte gli altri e nessuno se ne
    accorge finche' la scena non e' finita.
    """
    prima = len(o.data.polygons)
    if prima <= budget:
        print("  %-10s %5d facce, gia' sotto il budget" % (o.name, prima))
        return
    bpy.context.view_layer.objects.active = o
    m = o.modifiers.new("Decima", "DECIMATE")
    m.decimate_type = "COLLAPSE"
    m.ratio = float(budget) / prima
    bpy.ops.object.modifier_apply(modifier=m.name)
    print("  %-10s %5d -> %4d facce (%.1f%%)"
          % (o.name, prima, len(o.data.polygons), 100.0 * len(o.data.polygons) / prima))


def origine_alla_base(o):
    """Porta il pezzo sull'origine: mesh centrata in pianta, base a quota zero.

    DUE COSE INSIEME, e la seconda mancava. La prima e' l'origine sotto il pezzo,
    perche' chi lo posa scriva la quota del PIANO e non debba sottrarre mezza
    altezza. La seconda e' che il pezzo stia sull'origine DEL MONDO: un modello
    preso da un set arriva dove capitava di trovarlo dentro quel set - la tazza a
    quindici centimetri, il bottiglione a quarantuno - e quella posizione finisce
    nel .glb come trasformata del nodo.

    IL DIFETTO CHE NE VENIVA, detto da Federico: «c'e' una tazza incastrata nel
    monitor». Non era la fisica: in Godot il corpo rigido sta dove dice il
    generatore e la mesh gli sta quindici centimetri piu' in la' - dentro la cassa
    del monitor, che e' proprio li'. Misurato, mesh contro collisore: tazza 15 cm
    fuori asse, bottiglia 21, piattino 40, bottiglione 41. La tazza e il piattino
    della cucina, posati nello STESSO punto dal generatore, si vedevano a un
    quarto di metro l'uno dall'altro.

    I VERTICI SI PORTANO IN COORDINATE DI MONDO PRIMA DI GUARDARLI, e poi la
    trasformata dell'oggetto si azzera: cosi' la rotazione e la scala che il pezzo
    si porta dietro dal set finiscono dentro la mesh invece di restare appese al
    nodo. Farlo in coordinate locali darebbe il centro sbagliato su qualunque
    pezzo importato storto.
    """
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.transform(o.matrix_world)
    xs = [v.co for v in bm.verts]
    cx = (min(v.x for v in xs) + max(v.x for v in xs)) / 2
    cy = (min(v.y for v in xs) + max(v.y for v in xs)) / 2
    cz = min(v.z for v in xs)
    bmesh.ops.translate(bm, verts=bm.verts, vec=(-cx, -cy, -cz))
    bm.to_mesh(o.data)
    bm.free()
    o.matrix_world = Matrix.Identity(4)
    o.data.update()


def misura(o):
    vs = [o.matrix_world @ v.co for v in o.data.vertices]
    return (max(v.x for v in vs) - min(v.x for v in vs),
            max(v.y for v in vs) - min(v.y for v in vs),
            max(v.z for v in vs) - min(v.z for v in vs))


print("")
fatti = []
for slug, pezzo, nome, budget, _perche in PROP:
    o = prendi_uno(slug, pezzo)
    decima(o, budget)
    origine_alla_base(o)
    o.name = nome.capitalize()
    lx, ly, lz = misura(o)
    print("  %-10s ingombro %.3f x %.3f x %.3f m" % (nome, lx, ly, lz))
    # UN OGGETTO CHE SI PRENDE IN MANO STA IN MANO, e mezzo metro no: e' il
    # controllo che avrebbe fermato una bottiglia importata alla scala sbagliata,
    # che e' il modo piu' comune in cui un glTF arriva storto.
    if max(lx, ly, lz) > 0.45 or max(lx, ly, lz) < 0.04:
        print("\nATTENZIONE: %s e' alto %.2f m: non e' un oggetto da mano"
              % (nome, max(lx, ly, lz)))
        sys.exit(1)
    uscita = os.path.join(RADICE, "assets", "models", nome + ".glb")
    esporta(uscita)
    fatti.append((nome, lz))

# --- il provino: si GUARDA, non si deduce ------------------------------------
# I tre insieme, allineati e alla stessa scala: l'unico modo di accorgersi che uno
# e' grande il doppio di quanto dovrebbe, che e' il difetto tipico dei modelli
# presi da fuori.
bpy.ops.wm.read_factory_settings(use_empty=True)
x = 0.0
for nome, _lz in fatti:
    bpy.ops.import_scene.gltf(
        filepath=os.path.join(RADICE, "assets", "models", nome + ".glb"))
    for o in bpy.context.selected_objects:
        o.location.x += x
    x += 0.22
piano = bpy.data.meshes.new("Piano")
bm = bmesh.new()
bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=0.5)
bm.to_mesh(piano)
bm.free()
tavolo = bpy.data.objects.new("Piano", piano)
tavolo.location = (0.22, 0.0, 0.0)
bpy.context.collection.objects.link(tavolo)

os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
scatta = prepara_render(1100, 700, cielo=(0.18, 0.19, 0.21))
# Luci basse: sono oggetti di venti centimetri, e le potenze da mezzo metro qui
# arrivano sei volte piu' forti. E' la lezione del provino della camera CCD.
lampada("Chiave", (0.55, 0.55, 0.55), 0.8, tipo="AREA", dimensione=0.8)
lampada("Riempimento", (-0.45, 0.30, 0.35), 0.15)
# `scatta` VUOLE COORDINATE DI GIOCO - x e z in pianta, y in ALTO - mentre i pezzi
# qui sono stati importati e disposti in coordinate di Blender, dove in alto c'e'
# z. E' lo stesso scambio di sistemi di D-195, e ha dato lo stesso genere di
# risultato: nessun errore, e un provino che guardava i tre oggetti dal soffitto.
# Qui la camera sta a quindici centimetri d'altezza e settantacinque davanti,
# cioe' all'altezza di un piano - che e' come li si guarda davvero.
scatta(PROVINO, (0.22, 0.18, 1.05), (0.22, 0.13, 0.0), lente=42.0)
print("\n  provino: %s" % PROVINO)
