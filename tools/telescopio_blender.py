# -*- coding: utf-8 -*-
"""Il telescopio dell'osservatorio: un riflettore preso da fuori, MONTATO SUL PILASTRO.

    "D:/programs/blender5/blender.exe" --background --python tools/telescopio_blender.py

Produce assets/models/telescopio.glb.

PERCHE' NON E' PIU' MODELLATO A MANO. Lo era, con una cinquantina di cilindri e
scatole, e il risultato era la cosa piu' brutta della stanza: un tubo liscio senza un
bullone, una forcella fatta di parallelepipedi, e nessuna delle mille minuzie - viti,
collari, manopole, cavi flessibili - che sono esattamente cio' che fa leggere uno
strumento ottico come uno strumento e non come un disegno. Quelle minuzie non si
modellano in una serata: si prendono da chi le ha gia' fatte.

Il modello e' assets/models/esterni/telescopio_riflettore, dichiarato in
tools/prendi_modello.py (Sketchfab, GhInko, CC-BY: l'attribuzione e' obbligatoria e
sta in CREDITI.md). Qui dentro non si modella, si MONTA - ed e' un lavoro diverso:

  * il TREPPIEDE si butta. Il modello nasce da campagna, con tre gambe divaricate su
    un metro e novanta; in una cupola il telescopio sta su un pilastro di cemento
    piantato nel pavimento, che e' l'unica cosa che non trasmette le vibrazioni dei
    passi sulla passerella. Il pilastro lo facciamo noi, qui sotto.
  * gli ASSI si MISURANO, non si leggono dai nomi. L'analisi delle componenti
    principali dei vertici dice dove punta ogni pezzo, e i numeri sono usciti
    perfetti: l'asse di declinazione e' ortogonale a quello polare a meno di 1e-4, le
    due rette si incontrano a mezza unita', e l'asse polare sta a 43,2 gradi -
    Montegrimano e' a 43,9, si raddrizza di sette decimi di grado.
  * la GERARCHIA si ricostruisce. Il modello arriva come cinquantacinque oggetti
    piatti in una lista: e' una scultura, non una macchina. Qui vengono divisi in cio'
    che sta fermo, cio' che gira in ascensione retta e cio' che bascula in
    declinazione, e annidati in modo che inseguire sia ruotare UN nodo.
  * la MAPPA METALLICA si stacca. Il novantatre per cento della sua superficie e'
    dichiarata metallica a 0,93: dentro una cupola dove non c'e' niente da
    riflettere, quello e' il modo esatto in cui un oggetto diventa nero. E' lo stesso
    difetto che aveva il telescopio fatto a mano, e ha la stessa cura.
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
from modellare import uv_a_scatola, applica_texture   # noqa: E402
from geometria import (R_PASS, W_PASS, H_PASS, SP_PASS,   # noqa: E402
                       AR_RIPOSO_GRADI, DEC_RIPOSO_GRADI, LATITUDINE)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "telescopio.glb")
MODELLO = os.path.join(RADICE, "assets", "models", "esterni", "telescopio_riflettore")

# LATITUDINE arriva da geometria.py: la leggono anche il gioco e i controlli
AZIMUT = 0.0           # dove guarda il polo: 0 = verso -Y di Blender, il nord del blockout

# --- il pilastro, l'unica cosa che modelliamo noi ----------------------------
H_PILASTRO, D_PILASTRO = 0.75, 0.50

# --- quanto e' grande lo strumento -------------------------------------------
# LA SCALA NON E' UN NUMERO INVENTATO, e' la lunghezza del tubo. Il file arriva senza
# unita' (l'ingombro e' 270 per 190, che non sono ne' metri ne' centimetri): si
# dichiara quanto dev'essere lungo il tubo e la scala esce da li'. Cosi' se un giorno
# si ricambia modello, questa riga resta vera.
#
# IL VINCOLO NON E' LA CUPOLA, che ha raggio 2,50: e' la PASSERELLA. L'anello lascia
# al centro un pozzo di 0,87 di raggio, e li' dentro deve starci TUTTO cio' che gira,
# contrappeso compreso. Uno strumento piu' grande, in una cupola da cinque metri, non
# ci sarebbe stato nemmeno per davvero.
L_TUBO = 1.50

# --- la posa in cui il telescopio sta fermo ----------------------------------
# Il modello arriva col tubo parallelo all'asse polare: e' la posizione di riposo di
# una equatoriale tedesca, quella in cui il contrappeso sta in basso. Da li' si ruota
# per puntare, e questa e' la posa in cui il giocatore lo trova.
AR_POSA = math.radians(AR_RIPOSO_GRADI)
DEC_POSA = math.radians(DEC_RIPOSO_GRADI)

# --- come sono divisi i cinquantacinque pezzi --------------------------------
# I nomi del modello sono parlanti (Xaxis, Yaxis, Load, Main, Rim, Scope) e la
# divisione li segue - ma non si FIDA di loro: sotto ci sono i controlli che la
# verificano contro la geometria misurata, e uno che pretende che ogni pezzo del file
# sia nominato qui. Se un domani il modello cambia e arriva un pezzo nuovo, la
# costruzione si ferma invece di lasciarlo per terra in mezzo alla cupola.
TREPPIEDE = {"Leg1", "Leg2", "Leg3", "Leg11", "Leg22", "Leg33"}
FISSO = {"LegsBase", "Zaxis", "Zaxisdetail", "Xaxis", "Xcontrol1", "Xcontrol2", "Xcontrol3"}
POLARE = {"Yaxis", "Yaxis2", "Yaxis3", "Yaxis4", "Yaxisadjust",
          "Ycontrol1", "Ycontrol2", "Ypart1", "Ypart2", "Ypart3",
          "Load", "Loadkeeper",
          "Mainadjust1", "Mainadjust2", "Mainadjust3",
          "Mainadjust4", "Mainadjust5", "Mainadjust6"}
DEC = {"Telescopebase", "Mainaxis", "Main1", "Main2", "Main3", "Main4", "Main5",
       "Rim11", "Rim12", "Rim111", "Rim121",
       "Bolt2", "Bolt11", "Bolt12", "Bolt21", "Bolt111", "Bolt121",
       "Scope1", "Scope2", "Scope3", "Scope4", "Scope5",
       "Adjuster", "Adjuster1"}

# --- il pozzo che la passerella lascia libero --------------------------------
# DA geometria.py, non ribattuti a mano. Prima erano tre numeri scritti qui dentro
# (0,975 - 1,825 - 0,99) e nessuno dei tre era piu' vero: la passerella e' stata
# allargata a 1,05 e abbassata a 0,59, e il controllo continuava a dire che andava
# tutto bene misurando una passerella che non esisteva piu'.
R_INT, R_EST = R_PASS - W_PASS / 2, R_PASS + W_PASS / 2
CALPESTIO = H_PASS + SP_PASS / 2
FRANCO = 0.05              # quanto lo strumento deve stare lontano dal bordo interno
CUPOLA_R, CUPOLA_BASE = 2.50, 3.38
COLMO = CUPOLA_BASE + CUPOLA_R


# ============================================================================
# misura
# ============================================================================
def direzione(punti):
    """Direzione principale di una nuvola: l'autovettore maggiore della covarianza.

    Senza numpy lo trova l'iterazione di potenza, che in tre dimensioni converge in
    poche passate. Serve per sapere dove punta un pezzo SENZA credere al suo nome.
    """
    n = len(punti)
    c = sum(punti, Vector((0, 0, 0))) / n
    scarti = [p - c for p in punti]
    v = Vector((1.0, 0.3, 0.7)).normalized()
    for _ in range(60):
        w = Vector((0, 0, 0))
        for p in scarti:
            w += p * p.dot(v)
        if w.length < 1e-12:
            break
        v = w.normalized()
    lungo = max(p.dot(v) for p in scarti) - min(p.dot(v) for p in scarti)
    return c, (v if v.z >= 0 else -v), lungo


def incontro(c1, d1, c2, d2):
    """Il punto piu' vicino a due rette sghembe: qui i due assi si incrociano."""
    w = c1 - c2
    a, b, c, d, e = d1.dot(d1), d1.dot(d2), d2.dot(d2), d1.dot(w), d2.dot(w)
    den = a * c - b * b
    p1, p2 = c1 + d1 * ((b * e - c * d) / den), c2 + d2 * ((a * e - b * d) / den)
    return (p1 + p2) / 2.0, (p1 - p2).length


def vertici(nomi):
    return [o.matrix_world @ v.co for o in bpy.data.objects if o.type == "MESH"
            and o.name.split("_")[0] in nomi for v in o.data.vertices]


# ============================================================================
# il pilastro: cemento, e lo facciamo noi
# ============================================================================
COLORE_PILASTRO = (0.62, 0.61, 0.58)


def costruisci_pilastro(genitore):
    m = bpy.data.materials.new("Pilastro")
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = (COLORE_PILASTRO[0], COLORE_PILASTRO[1],
                                            COLORE_PILASTRO[2], 1.0)
    p.inputs["Roughness"].default_value = 0.8
    applica_texture(m, "Pilastro", tinta=COLORE_PILASTRO,
                    set_texture=("metallo", 0.55), metallico=False)

    bm = bmesh.new()
    for raggio, alto, quota in ((D_PILASTRO / 2, H_PILASTRO, H_PILASTRO / 2),
                                (D_PILASTRO / 2 + 0.09, 0.10, 0.05)):
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=32,
                              radius1=raggio, radius2=raggio, depth=alto,
                              matrix=Matrix.Translation(Vector((0, 0, quota))))
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    malla = bpy.data.meshes.new("Pilastro")
    uv_a_scatola(bm, 0.55)
    bm.to_mesh(malla)
    bm.free()
    malla.materials.append(m)
    o = bpy.data.objects.new("Pilastro", malla)
    bpy.context.collection.objects.link(o)
    o.parent = genitore
    return o


# ============================================================================
# costruzione
# ============================================================================
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

bpy.ops.import_scene.gltf(filepath=os.path.join(MODELLO, "scene.gltf"))
bpy.context.view_layer.update()

# --- ogni pezzo del file dev'essere dichiarato qui sopra ---------------------
presenti = set(o.name.split("_")[0] for o in bpy.data.objects if o.type == "MESH")
dichiarati = TREPPIEDE | FISSO | POLARE | DEC
if presenti != dichiarati:
    print("\nATTENZIONE: i gruppi non coprono il modello.")
    if presenti - dichiarati:
        print("  pezzi senza gruppo: %s" % ", ".join(sorted(presenti - dichiarati)))
    if dichiarati - presenti:
        print("  gruppi senza pezzo: %s" % ", ".join(sorted(dichiarati - presenti)))
    sys.exit(1)

# --- gli assi, misurati ------------------------------------------------------
centro_pol, dir_pol, _ = direzione(vertici({"Xaxis"}))
centro_dec, dir_dec, _ = direzione(vertici({"Yaxis", "Yaxis2", "Yaxis3", "Yaxis4",
                                            "Load", "Loadkeeper"}))
centro_tubo, dir_tubo, lungo_tubo = direzione(vertici({"Main1", "Main2", "Main3",
                                                       "Main4", "Main5"}))
P, scarto = incontro(centro_pol, dir_pol, centro_dec, dir_dec)
print("  asse polare a %.1f gradi; ortogonalita' col dec %.4f; assi incidenti a %.2f"
      % (math.degrees(math.asin(dir_pol.z)), abs(dir_pol.dot(dir_dec)), scarto))
if abs(dir_pol.dot(dir_dec)) > 0.02 or scarto > 2.0:
    print("\nATTENZIONE: la montatura del modello non e' l'equatoriale che si credeva")
    sys.exit(1)

# Il tubo sta dalla parte opposta del contrappeso rispetto all'asse di declinazione:
# e' la definizione di equatoriale tedesca, ed e' cio' che distingue i due gruppi che
# ruotano. I nomi dicono chi va dove, questo controlla che dicano il vero.
lato_tubo = (centro_tubo - P).dot(dir_dec)
lato_peso = (direzione(vertici({"Load", "Loadkeeper"}))[0] - P).dot(dir_dec)
if lato_tubo * lato_peso >= 0:
    print("\nATTENZIONE: tubo e contrappeso stanno dalla stessa parte dell'asse dec")
    sys.exit(1)
sbagliati = [n for n in sorted(DEC)
             if (direzione(vertici({n}))[0] - P).dot(dir_dec) * lato_tubo < 0]
if sbagliati:
    print("\nATTENZIONE: dichiarati solidali al tubo ma stanno dalla parte del "
          "contrappeso: %s" % ", ".join(sbagliati))
    sys.exit(1)

SCALA = L_TUBO / lungo_tubo
print("  tubo lungo %.1f unita' del file -> scala %.5f per farlo di %.2f m"
      % (lungo_tubo, SCALA, L_TUBO))

# --- via il treppiede --------------------------------------------------------
bpy.ops.object.select_all(action="DESELECT")
for o in [o for o in bpy.data.objects if o.type == "MESH" and o.name.split("_")[0] in TREPPIEDE]:
    o.select_set(True)
bpy.ops.object.delete()

# --- si stacca dagli Empty del file e si trasforma ---------------------------
bpy.ops.object.select_all(action="DESELECT")
for o in [o for o in bpy.data.objects if o.type == "MESH"]:
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
for o in [o for o in bpy.data.objects if o.type == "EMPTY"]:
    bpy.data.objects.remove(o, do_unlink=True)

# Ruota in due tempi: prima l'azimut attorno alla verticale - che lascia in piedi la
# colonna della montatura - poi i sette decimi di grado che portano il polo dalla
# latitudine del modello alla nostra. Una rotazione sola farebbe la stessa cosa ma
# inclinerebbe anche la colonna di un angolo che nessuno ha scelto.
bersaglio = Vector((math.sin(AZIMUT) * math.cos(math.radians(LATITUDINE)),
                    -math.cos(AZIMUT) * math.cos(math.radians(LATITUDINE)),
                    math.sin(math.radians(LATITUDINE))))
azimut_modello = math.atan2(dir_pol.x, -dir_pol.y)
giro = Matrix.Rotation(AZIMUT - azimut_modello, 4, "Z")
raddrizza = (giro.to_3x3() @ dir_pol).normalized().rotation_difference(
    bersaglio).to_matrix().to_4x4()

# IL PILASTRO VA SOTTO L'INCROCIO DEGLI ASSI, non sotto la colonna della montatura.
# Sembra la stessa cosa e non lo e': su una equatoriale tedesca l'asse polare e'
# inclinato, e il punto in cui incrocia quello di declinazione - il punto attorno a
# cui l'intera testa gira - sta ventun centimetri di lato rispetto alla colonna.
# Centrando la colonna, tutto cio' che ruota spazzava un cerchio scentrato di
# altrettanto nella cupola.
M = Matrix.Scale(SCALA, 4) @ raddrizza @ giro
base_modello = Vector((0.0, 0.0, min(v.z for v in vertici(FISSO))))
alza = H_PILASTRO - (M @ base_modello).z
centra = M @ P
M = Matrix.Translation(Vector((-centra.x, -centra.y, alza))) @ M

for o in [o for o in bpy.data.objects if o.type == "MESH"]:
    o.matrix_world = M @ o.matrix_world
P = M @ P
asse_pol = (M.to_3x3() @ dir_pol).normalized()
asse_dec = (M.to_3x3() @ dir_dec).normalized()


# --- la gerarchia dell'inseguimento ------------------------------------------
# QUATTRO PERNI, non due, e ognuno fa UNA cosa. "Polo" e "Declinazione" portano solo
# l'ORIENTAMENTO degli assi; "AssePolare" e "AsseDec" ruotano solo attorno al proprio
# Z. Con orientamento e rotazione sullo stesso nodo sarebbe l'ordine degli angoli di
# Eulero a decidere il risultato, e inseguire diventerebbe un problema di convenzioni
# invece che una rotazione sola.
#
#   Telescopio
#   |- Pilastro                 il cemento, fermo
#   |- Montatura                colonna e scatola dell'asse polare, ferme
#   `- Polo                     inclinato di 43,9 gradi verso nord
#      `- AssePolare            <- QUI gira l'ascensione retta, e basta
#         |- Contrappeso        il peso e la scatola della declinazione
#         `- Declinazione       ortogonale al polo
#            `- AsseDec         <- QUI bascula la declinazione, e basta
#               `- Tubo         tubo, anelli, cercatore, focheggiatore
def perno(nome, genitore=None, posizione=None, verso=None, giro=0.0):
    e = bpy.data.objects.new(nome, None)
    bpy.context.collection.objects.link(e)
    base = Matrix.Identity(4)
    if verso is not None:
        base = Vector((0, 0, 1)).rotation_difference(verso).to_matrix().to_4x4()
    if posizione is not None:
        base = Matrix.Translation(posizione) @ base
    e.matrix_world = base @ Matrix.Rotation(giro, 4, "Z")
    if genitore is not None:
        e.parent = genitore
        e.matrix_parent_inverse = genitore.matrix_world.inverted()
    return e


radice = perno("Telescopio")
costruisci_pilastro(radice)
polo = perno("Polo", radice, P, asse_pol)
asse_ar = perno("AssePolare", polo, P, asse_pol)
declinazione = perno("Declinazione", asse_ar, P, asse_dec)
asse_de = perno("AsseDec", declinazione, P, asse_dec)
bpy.context.view_layer.update()


def raduna(nome, gruppo, genitore):
    """Unisce i pezzi di un gruppo in una mesh sola e la appende al suo perno."""
    pezzi = [o for o in bpy.data.objects if o.type == "MESH" and o.name.split("_")[0] in gruppo]
    bpy.ops.object.select_all(action="DESELECT")
    for o in pezzi:
        o.select_set(True)
    bpy.context.view_layer.objects.active = pezzi[0]
    bpy.ops.object.join()
    unito = bpy.context.view_layer.objects.active
    unito.name = nome
    unito.data.name = nome
    unito.parent = genitore
    unito.matrix_parent_inverse = genitore.matrix_world.inverted()
    return unito


montatura = raduna("Montatura", FISSO, radice)
contrappeso = raduna("Contrappeso", POLARE, asse_ar)
tubo = raduna("Tubo", DEC, asse_de)
bpy.context.view_layer.update()

# LA POSA SI APPLICA ADESSO, DOPO aver appeso le mesh ai perni, e non prima. Prima
# non si vedeva: `matrix_parent_inverse` viene calcolata sul genitore com'e' in quel
# momento, e annulla esattamente la rotazione che il genitore aveva gia'. Costruito
# nell'altro ordine il telescopio restava nella posa di riposo qualunque angolo si
# scrivesse qui sopra, e nessuno se ne accorgeva perche' la posa di riposo e' a sua
# volta una posa sensata.
#
# Ne segue il contratto per chi in partita fara' l'inseguimento: ZERO E' IL RIPOSO.
# AssePolare e AsseDec a rotazione nulla danno il telescopio col tubo parallelo
# all'asse polare e il contrappeso in basso.
verso_cielo = (M.to_3x3() @ dir_tubo).normalized()      # dove punta il tubo a riposo
polo_riposo = polo.matrix_world.copy()                 # AssePolare a zero
asse_de_riposo = asse_de.matrix_world.copy()           # AsseDec a zero
dec_su_ar = asse_ar.matrix_world.inverted() @ declinazione.matrix_world
tubo_su_dec = asse_de.matrix_world.inverted() @ tubo.matrix_world
peso_su_ar = asse_ar.matrix_world.inverted() @ contrappeso.matrix_world
# --- LA MIRA: il modello dichiara dove guarda --------------------------------
# UN EMPTY IN CIMA AL TUBO, sull'asse ottico, appeso ad AsseDec. Sembra un
# dettaglio e invece e' il contratto fra chi modella e chi in partita deve puntare:
# senza, il gioco dovrebbe INDOVINARE l'asse ottico dalla mesh del tubo - e sopra
# c'e' scritto, con i numeri, come va a finire: la retta di regressione della
# nuvola di punti dava 62 gradi dove il tubo ne faceva 43, perche' in quella nuvola
# ci sono anche cercatore, anelli, bulloni e culatta.
#
# E SERVE ALLA CUPOLA PRIMA CHE AL TELESCOPIO. Per sapere dove il raggio buca la
# calotta non basta la direzione: serve il PUNTO DA CUI PARTE, perche' su una
# equatoriale tedesca l'apertura sta fino a un metro fuori dall'asse del pilastro e
# due metri sotto il centro della sfera. Con l'origine sbagliata l'azimut della
# cupola sbaglia di decine di gradi. Vedi `world/dome_azimuth.gd`.
#
# STA SULL'ASSE, NON SUL BORDO: si prende il vertice del tubo piu' avanti lungo
# l'asse ottico e lo si PROIETTA sull'asse. Il vertice piu' avanti in assoluto sta
# sul labbro del tubo, cioe' fuori centro di mezzo diametro, e da li' partirebbe un
# raggio parallelo a quello vero ma spostato - che e' l'errore piu' facile da fare
# e il piu' difficile da vedere.
_inv_de = asse_de_riposo.inverted()
_dir_loc = (asse_de_riposo.to_3x3().inverted() @ verso_cielo).normalized()
_avanti = max((_inv_de @ (tubo.matrix_world @ v.co) for v in tubo.data.vertices),
              key=lambda p: p.dot(_dir_loc))
_apertura = asse_de_riposo @ (_dir_loc * _avanti.dot(_dir_loc))
mira = perno("Mira", asse_de, _apertura, verso_cielo)
print("  mira: apertura a %.2f m dal pavimento, %.2f m fuori dall'asse del pilastro"
      % (_apertura.z, math.hypot(_apertura.x - P.x, _apertura.y - P.y)))

for nodo, angolo in ((asse_ar, AR_POSA), (asse_de, DEC_POSA)):
    nodo.matrix_basis = nodo.matrix_basis @ Matrix.Rotation(angolo, 4, "Z")
bpy.context.view_layer.update()

# --- il materiale: le mappe ridotte, e quella metallica staccata -------------
# SI SOSTITUISCE IL NODO, non il percorso dell'immagine. L'importatore glTF IMPACCHETTA
# le texture dentro il file di Blender, e su un'immagine impacchettata `reload()`
# ricarica il pacchetto e ignora il percorso appena scritto: il .glb usciva da
# ventiquattro megabyte con dentro le mappe originali da 4096 che credevo di aver
# sostituito. E cercando le immagini per nome in tutta la scena, il "normal.jpg" del
# PILASTRO finiva anche lui riagganciato alla normale del telescopio - un materiale
# corrotto da una riga che serviva a un altro.
NOSTRE = {"basecolor": "color.jpg", "normal": "normal.png", "metallicroughness": "roughness.jpg"}

for m in bpy.data.materials:
    if m.name == "Pilastro" or not m.use_nodes:
        continue
    p = m.node_tree.nodes.get("Principled BSDF")
    if p is None:
        continue
    for nodo in m.node_tree.nodes:
        if nodo.type != "TEX_IMAGE" or nodo.image is None:
            continue
        vecchia = nodo.image.name.lower()
        for pezzo, nostro in NOSTRE.items():
            if pezzo in vecchia:
                nodo.image = bpy.data.images.load(os.path.join(MODELLO, "textures", nostro),
                                                  check_existing=True)
                nodo.image.colorspace_settings.name = ("sRGB" if pezzo == "basecolor"
                                                       else "Non-Color")
                break
    for legame in list(m.node_tree.links):
        if legame.to_socket == p.inputs["Metallic"]:
            m.node_tree.links.remove(legame)
    # 0,2 e non 0,93: la vernice a fuoco di uno strumento riflette un poco, uno
    # specchio no. Con la mappa attaccata il telescopio restituisce il colore di cio'
    # che ha intorno, e intorno c'e' una cupola spenta.
    #
    # NEL glTF QUESTO 0,2 VIENE MOLTIPLICATO dal canale blu della mappa impacchettata,
    # che qui porta la rugosita': il metallico effettivo esce sullo 0,09 invece che
    # sullo 0,20. E' meno di quanto scritto, cioe' dalla parte giusta - un decimo di
    # metallico su una vernice non si vede, il doppio del previsto in una stanza buia
    # si vedrebbe eccome.
    p.inputs["Metallic"].default_value = 0.2


# ============================================================================
# controlli
# ============================================================================
problemi = []
tutti = [o.matrix_world @ v.co for o in (montatura, contrappeso, tubo)
         for v in o.data.vertices]
raggio_max = max(math.hypot(p.x, p.y) for p in tutti)
alto_max = max(p.z for p in tutti)
print("  ingombro nella posa: raggio %.2f m, altezza %.2f m" % (raggio_max, alto_max))
if raggio_max > CUPOLA_R - 0.15:
    problemi.append("il telescopio tocca la parete: raggio %.2f su %.2f" % (raggio_max, CUPOLA_R))
if alto_max > COLMO - 0.20:
    problemi.append("il telescopio tocca il colmo: %.2f su %.2f" % (alto_max, COLMO))

# Dove punta: l'asse ottico a riposo, portato nella posa. NON la direzione principale
# della mesh montata - quella nuvola contiene anche cercatore, anelli, bulloni e
# culatta, e la sua retta di regressione non e' l'asse del tubo: dava 62 gradi dove il
# tubo ne faceva 43, ed era un numero che sembrava giusto.
def dove_punta(mondo_dec):
    v = (mondo_dec.to_3x3() @ (asse_de_riposo.to_3x3().inverted() @ verso_cielo)).normalized()
    return math.degrees(math.asin(max(-1.0, min(1.0, v.z))))


altitudine = dove_punta(asse_de.matrix_world)
print("  il tubo punta a %.0f gradi sull'orizzonte" % altitudine)
if altitudine < 15.0:
    problemi.append("il tubo punta a %.0f gradi: sotto il tetto, non al cielo" % altitudine)

# l'oculare di un newtoniano sta in cima al tubo, di fianco, e dev'essere a portata di
# chi e' in piedi sulla passerella
h_oculare = max((tubo.matrix_world @ v.co).z for v in tubo.data.vertices) - 0.25
print("  oculare a %.2f m dal pavimento (calpestio della passerella a %.2f)"
      % (h_oculare, CALPESTIO))
if not (CALPESTIO + 0.75 <= h_oculare <= CALPESTIO + 1.85):
    problemi.append("oculare a %.2f m: fuori dalla portata di chi sta sulla passerella "
                    "(%.2f - %.2f)" % (h_oculare, CALPESTIO + 0.75, CALPESTIO + 1.85))

# --- LA PASSERELLA. Lo strumento GIRA: non basta che stia libero nella posa in cui e'
# montato, deve restarlo in tutte le pose che assume davvero. Il contrappeso spazza un
# cono attorno all'asse polare e il tubo un secondo cono attorno a quello di
# declinazione, e la passerella e' un anello alla loro stessa quota.
#
# SI CONTROLLA L'ATTRAVERSAMENTO DEL FERRO, NON LA VICINANZA. Un primo tentativo
# vietava allo strumento di sporgere sopra l'anello a qualunque quota sotto i due metri
# e mezzo, e quel controllo era sbagliato in partenza: la passerella ESISTE per
# arrivare all'oculare, quindi il telescopio ci deve passare vicino per forza, e
# l'oculare stesso e' un pezzo di telescopio a portata di mano di chi ci sta sopra. Il
# difetto vero e' un altro, ed e' solido contro solido: il tubo che entra
# nell'impalcato o nel parapetto. Quello si vede subito e non si spiega.
IMPALCATO = (CALPESTIO - SP_PASS - 0.03, CALPESTIO + 0.03)
PARAPETTO = (CALPESTIO, CALPESTIO + 1.02, R_EST - 0.09)
LIMITE_ACCETTABILE = 30.0    # piu' in alto di cosi' la cupola servirebbe a poco
punti_tubo = [tubo_su_dec @ v.co for v in list(tubo.data.vertices)[::3]]
punti_peso = [peso_su_ar @ v.co for v in list(contrappeso.data.vertices)[::3]]


def franco(punti, mondo):
    """Quanto manca perche' questi punti tocchino il ferro. Negativo = ci sono dentro.

    Si misura la DISTANZA, non si risponde si'/no. Con una soglia si arriva sempre
    allo stesso vicolo: il numero passa o non passa e non si sa di quanto, e per tre
    giri di seguito ho stretto e allargato un margine credendo di spostare il
    telescopio quando spostavo solo la mia soglia. Il gioco lo stampa e si vede.
    """
    minimo = 9.9
    for q in punti:
        w = mondo @ q
        r = math.hypot(w.x, w.y)
        if IMPALCATO[0] <= w.z <= IMPALCATO[1]:
            minimo = min(minimo, R_INT - r)         # il bordo interno dell'impalcato
        if PARAPETTO[0] <= w.z <= PARAPETTO[1]:
            minimo = min(minimo, PARAPETTO[2] - r)  # il montante del parapetto
        minimo = min(minimo, w.z)                   # e il pavimento
    return minimo


# NON SI CHIEDE "URTA O NON URTA": si chiede FINO A CHE ALTEZZA PUO' SCENDERE. La
# domanda binaria non ha risposta utile, perche' combinando le due rotazioni il tubo
# copre la sfera intera e a puntamenti bassi la culatta scende e si allarga: urta
# sempre, in ogni cupola, anche in quelle vere. Il numero che conta e' il puntamento
# piu' basso a cui lo strumento resta libero, ed e' un DATO DI PROGETTO - l'altezza
# sotto la quale in questo osservatorio non si osserva. Il gioco dovra' rispettarlo
# quando fara' inseguire il telescopio.
LIBERO = 0.02          # meno di due centimetri e la compenetrazione si vede
urti = []
for ar in range(0, 360, 5):
    m_ar = polo_riposo @ Matrix.Rotation(math.radians(ar), 4, "Z")
    m_dec_base = m_ar @ dec_su_ar
    f_peso = franco(punti_peso, m_ar)
    for de in range(0, 360, 5):
        m_de = m_dec_base @ Matrix.Rotation(math.radians(de), 4, "Z")
        alto = dove_punta(m_de)
        if alto < 0.0:
            continue          # il tubo guarda il pavimento: non e' una posa
        f = min(f_peso, franco(punti_tubo, m_de))
        if f < LIBERO:
            urti.append((alto, f, ar, de))

limite = max((u[0] for u in urti), default=-1.0)
if urti:
    alto, f, ar, de = max(urti, key=lambda u: u[0])
    print("  passerella: libera per ogni puntamento sopra %.0f gradi; a %.0f (AR %d, "
          "dec %d) lo strumento ci entra di %.2f m" % (limite, alto, ar, de, max(0.0, -f)))
else:
    print("  passerella: mai toccata, a qualunque puntamento")
if limite > LIMITE_ACCETTABILE:
    problemi.append("il telescopio non scende sotto %.0f gradi senza toccare la "
                    "passerella: da questa cupola si vedrebbe troppo poco cielo" % limite)
if altitudine < limite:
    problemi.append("la posa a riposo punta a %.0f gradi, sotto il limite di %.0f"
                    % (altitudine, limite))


# --- scandaglio delle pose (solo per scegliere AR_POSA/DEC_POSA a occhi aperti) ---
if os.environ.get("SCANDAGLIO"):
    print("\n  AR   dec   altezza   oculare")
    for ar in range(-90, 91, 15):
        for de in range(-70, 1, 10):
            m = (polo_riposo @ Matrix.Rotation(math.radians(ar), 4, "Z")
                 @ dec_su_ar @ Matrix.Rotation(math.radians(de), 4, "Z"))
            a = dove_punta(m)
            if a < 40 or a > 70:
                continue
            alto = max((m @ tubo_su_dec @ v.co).z
                       for v in list(tubo.data.vertices)[::9])
            print("  %4d %5d %8.0f %9.2f" % (ar, de, a, alto - 0.25))

if problemi:
    print("\nATTENZIONE:")
    for x in problemi:
        print("  " + x)
    sys.exit(1)

print("  %d facce in tre pezzi (fermo, ascensione retta, declinazione)"
      % sum(len(o.data.polygons) for o in (montatura, contrappeso, tubo)))

os.makedirs(os.path.dirname(USCITA), exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=USCITA, export_format="GLB", use_selection=True,
                          export_apply=False)

# --- si RILEGGE quello che si e' scritto -------------------------------------
# Il .glb e' uscito da ventiquattro megabyte con dentro le mappe da 4096 che credevo
# di aver sostituito, e da Blender non si vedeva: le immagini erano collegate, il
# materiale era giusto, i controlli passavano tutti. L'unico posto dove il difetto
# esisteva era il file. Da allora il file si riapre.
PESO_MASSIMO = 6.0        # megabyte: un 1K per mappa ci sta largo, un 4K no
import json as _json      # noqa: E402
import struct as _struct  # noqa: E402

with open(USCITA, "rb") as _f:
    _f.read(12)
    _n, _ = _struct.unpack("<II", _f.read(8))
    _g = _json.loads(_f.read(_n).decode("utf-8"))
_peso = os.path.getsize(USCITA) / 1e6
_nodi = [n.get("name") for n in _g["nodes"]]
_manca = [n for n in ("Telescopio", "Polo", "AssePolare", "Declinazione", "AsseDec",
                      "Pilastro", "Montatura", "Contrappeso", "Tubo") if n not in _nodi]
if _manca:
    print("\nATTENZIONE: nel .glb mancano i nodi %s" % ", ".join(_manca))
    sys.exit(1)
if _peso > PESO_MASSIMO:
    _grosse = sorted(((_g["bufferViews"][i["bufferView"]]["byteLength"] / 1e6, i.get("name"))
                      for i in _g.get("images", [])), reverse=True)[:3]
    print("\nATTENZIONE: il .glb pesa %.1f MB, il massimo e' %.1f. Le mappe piu' grosse: %s"
          % (_peso, PESO_MASSIMO, ", ".join("%s %.1f MB" % (n, p) for p, n in _grosse)))
    sys.exit(1)
print("\nscritto %s  -  %.1f MB, gerarchia dell'inseguimento verificata NEL FILE"
      % (USCITA, _peso))
