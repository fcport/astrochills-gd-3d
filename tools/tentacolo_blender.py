# -*- coding: utf-8 -*-
"""IL TENTACOLO che scende dal cielo davanti all'osservatorio.

    python tools/prendi_pelle.py          (una volta: la pelle)
    "D:/programs/blender5/blender.exe" --background --python tools/tentacolo_blender.py

Produce assets/models/tentacolo.glb.

QUELLO CHE ESCE DA QUI NON E' UNA MESH, E' UNO SCHELETRO VESTITO. La forma di un
tentacolo e' la cosa facile: e' un cono. Quello che lo fa leggere come una cosa
viva e' il MOVIMENTO, e un movimento non sta in un .glb - sta nelle ossa, che
`world/tentacolo.gd` piega una per una a ogni fotogramma. Qui dentro c'e' una
catena di ossa lunga millecinquecento metri e la pelle pesata su di loro; l'onda che
ci corre dentro e' scritta di la'. E' anche il motivo per cui un modello scaricato
non avrebbe risolto niente da solo: sarebbe arrivato rigido, e avrebbe comunque
avuto bisogno di questa catena.

DA DOVE VIENE LA FORMA, che e' la regola del progetto (non si inventa: si copia).
E' il BRACCIO DI UN POLPO, Octopus vulgaris, e non un cono con le palline:

  - il braccio rastrema da una base grossa fino a una punta sottilissima, con un
    profilo appena convesso - non e' un cono dritto;
  - le ventose stanno SOLO sulla faccia orale, in DUE FILE ALTERNATE a zigzag
    (biseriali: e' il carattere che distingue un polpo da un calamaro, che le ha
    in quattro file, e da una seppia);
  - la ventosa piu' grande NON e' quella alla base: il rapporto fra ventosa e
    braccio culmina attorno al sesto prossimale e da li' cala verso la punta;
  - la sezione NON e' un cerchio: e' schiacciata sulla faccia orale e porta due
    costole longitudinali sul dorso, che sono i fasci muscolari.

E LA PELLE E' QUELLA DI UN POLPO VERO: una fotografia NOAA resa ripetibile da
`tools/prendi_pelle.py`, con il reticolo di bande scure e papille chiare.

LE VENTOSE SONO IL MOTIVO PER CUI SI CAPISCE COS'E'. Senza, dal prato si vedrebbe
un tubo grigio che ondeggia - potrebbe essere una proboscide, un verme, un cavo.
Con due file alternate di dischi chiari si legge in un decimo di secondo, e si
legge anche di notte, perche' il salto di tinta sopravvive al buio meglio della
geometria.

L'ORIGINE STA IN CIMA, non alla base come per tutto il resto del progetto, e
l'eccezione e' voluta: questa cosa non si appoggia su un piano, PENDE. Chi la
colloca scrive il punto in cielo da cui scende, e il modello va in giu' da li'
(verso -y). La punta cade a LUNGHEZZA metri sotto l'origine: piegandosi la catena
si accorcia, e `world/tentacolo.gd` le rimette la punta al suo posto spostando
l'attacco, lassu' dove non guarda nessuno.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
from modellare import applica_texture, lampada, prepara_render, pulisci  # noqa: E402

# LA TAVOLOZZA STA QUI, NON IN `modellare.COLORI`, ed e' una lezione presa a caro
# prezzo: `verifica_freschezza()` in gen_blockout.py considera `modellare.py` una
# SORGENTE di ogni modello, giustamente - ogni modellatore lo legge. Aggiungerci
# due colori che servono a un oggetto solo faceva risultare vecchi tutti e dieci i
# .glb dell'edificio, e la cura sarebbe stata ricostruirli tutti per due righe di
# tinta. Il telescopio ha la sua tavolozza per lo stesso motivo.
#
# LA PELLE NON E' NERA. Un polpo e' bruno-rossastro, e di notte sotto la luna un
# bruno-rossastro legge come un grigio livido: partendo gia' scuro, contro un cielo
# notturno sarebbe una sagoma senza volume - un buco nel cielo, non una cosa. La
# tinta di "Tentacolo" e' anche quella verso cui `prendi_pelle.py` porta la foto:
# se cambia qui, va cambiata la', o la mappa torna del colore vecchio.
#
# LA FACCIA ORALE E' PIU' CHIARA DELLA SCHIENA, in un polpo come in ogni cefalopode:
# la pigmentazione sta sopra. Ed e' anche l'unico modo perche' le ventose si leggano
# come ventose invece che come bitorzoli: da lontano quello che le fa vedere e' il
# salto di tinta, non la geometria.
#
# BAGNATO, tutti e due: un braccio fuori dall'acqua e' lucido, e il riflesso che
# striscia lungo il braccio mentre si muove e' meta' di cio' che lo fa leggere come
# carne viva invece che come un tubo di gomma.
TAVOLOZZA = {
    "Tentacolo": ((0.27, 0.21, 0.22), 0.35),
    "Ventosa":   ((0.56, 0.45, 0.42), 0.48),
    "Metro":     ((0.86, 0.86, 0.83), 0.80),
}
PELLE = ("pelle-polpo", 1.0)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "tentacolo.glb")
CONFRONTO = os.path.join(RADICE, "_confronto")

# --- quote -------------------------------------------------------------------
# MILLECINQUECENTO METRI. La storia di questo numero e' la storia della richiesta:
#   - 45 m, la prima stesura: alzando la testa si trovava il TAPPO, un disco a
#     mezz'aria, e un braccio che finisce in cielo non viene dal cielo;
#   - 200 m: la fine non si vedeva quasi piu', ma ancora si trovava, un nodo verso
#     lo zenit. Federico: «deve essere proprio incomprensibile quasi da dove arriva.
#     Possibilmente farlo ancora piu' grande».
#   - 1500 m: la cima sta piu' in alto di quanto il tentacolo resti visibile. In
#     partita la pelle si DISSOLVE con la distanza (vedi `world/tentacolo.gd`), e da
#     un certo punto in su non c'e' piu' niente da vedere: la colonna sale e sparisce
#     nel cielo, e dove cominci non lo sa nessuno.
LUNGHEZZA = 1500.0

# IL RAGGIO NON CRESCE ALL'INFINITO. Con la sola rastremazione del polpo - r cresce
# come d^0,85 - a millecinquecento metri il braccio sarebbe largo trecento.
# La tangente iperbolica lascia la formula del polpo dov'e' per i primi metri
# (tanh(x) = x quando x e' piccolo) e la piega verso un tetto: nessun gradino, la
# stessa curva con un asintoto.
#
# IL DOPPIO DI PRIMA, su richiesta («ancora piu' grande»). `R_A_45` e' il raggio a
# quarantacinque metri dalla punta: era 1,85, adesso 3,70 - un tubo di sette metri e
# mezzo all'altezza di un palazzo di quindici piani. La punta raddoppia con lui, e le
# ventose seguono da sole perche' sono una frazione del raggio.
R_A_45 = 3.70
R_MAX = 30.0
R_PUNTA = 0.18

# LE OSSA SI ALLUNGANO SALENDO. In punta ne serve una ogni due metri: l'arricciatura
# vive negli ultimi diciotto, e con ossa piu' lunghe ci finirebbe dentro intera. A un
# chilometro d'altezza la colonna e' larga cinquanta metri, ondeggia su onde di
# centinaia e nessuno la guarda da vicino: li' un osso da quaranta basta. A passo
# fisso da due metri le ossa sarebbero settecentocinquanta, e settecento di quelle
# piegherebbero un tubo che non si piega.
OSSO_MIN = 2.0
OSSO_CRESCITA = 0.04       # metri d'osso in piu' per metro di distanza dalla punta
OSSO_MAX = 40.0

# GLI ANELLI DI PELLE seguono la stessa regola, con piu' finezza: in punta uno ogni
# mezzo metro, in cima uno ogni dodici.
PASSO_ANELLO_MIN = 0.50
PASSO_ANELLO_MAX = 12.0
CRESCITA_PASSO = 0.015

# SEDICI LATI E NON DODICI: raddoppiando il raggio, a cinquanta metri da terra il
# tubo e' largo sette metri e mezzo, e un dodecagono di quella misura contro il
# cielo si vede per quello che e'.
LATI = 16

# QUANTE VOLTE LA PELLE GIRA ATTORNO AL BRACCIO. La mappa si ripete due volte sulla
# circonferenza, a qualunque altezza: la pelle SCALA CON IL RAGGIO, come in un
# animale vero, dove le papille della punta sono piu' piccole di quelle della base.
# Tenendo la mappa a metri fissi, in punta un quadro coprirebbe dieci giri del
# braccio e in cima un centesimo di giro - una sfocatura sopra e un rumore sotto.
GIRI_PELLE = 2.0

# Le due file di ventose, a ±32 gradi dalla mezzeria della faccia orale. La faccia
# orale guarda verso +z in coordinate di gioco (chi la colloca gira il nodo).
FILA = math.radians(32.0)
# Sotto questo diametro non si costruiscono piu': la punta e' il pezzo che arriva
# davanti agli occhi, e da vicino un braccio liscio e appuntito e' un verme. Un polpo
# le ha fino in fondo, sempre piu' piccole.
VENTOSA_MINIMA = 0.10
# E OLTRE QUESTA DISTANZA DALLA PUNTA NON SE NE FANNO PIU'. Lassu' la pelle si e' gia'
# dissolta nel cielo, e trecento ventose da dieci metri che nessuno vede
# costerebbero piu' triangoli di tutto il resto del braccio.
VENTOSE_FINO_A = 400.0


def materiale(nome):
    """Un materiale della tavolozza di questo file."""
    if nome in bpy.data.materials:
        return bpy.data.materials[nome]
    colore, ruvidezza = TAVOLOZZA[nome]
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (colore[0], colore[1], colore[2], 1.0)
    b.inputs["Roughness"].default_value = ruvidezza
    return m


def raggio_d(d):
    """Il raggio del braccio a `d` metri dalla punta.

    L'esponente 0,85 e non 1,0: la rastremazione di un braccio vero e' CONVESSA -
    resta grosso piu' a lungo e poi cala in fretta. Con l'esponente a uno viene un
    cono da cantiere. La tangente iperbolica mette il tetto: vedi `R_MAX`.
    """
    grezzo = R_A_45 * (max(d, 0.0) / 45.0) ** 0.85
    return max(R_MAX * math.tanh(grezzo / R_MAX), R_PUNTA)


def raggio(s):
    """Il raggio alla frazione `s` (0 in cielo, 1 in punta)."""
    return raggio_d(LUNGHEZZA * (1.0 - s))


def _crescente(passo_min, crescita, passo_max):
    """Distanze dalla punta, dalla punta in su, con un passo che cresce salendo."""
    d = 0.0
    fuori = [0.0]
    while True:
        d += min(passo_max, passo_min + crescita * d)
        if d >= LUNGHEZZA:
            break
        fuori.append(d)
    # l'ultimo tratto, fino all'attacco: se e' un avanzo corto si unisce al precedente
    if LUNGHEZZA - fuori[-1] < 0.5 * min(passo_max, passo_min + crescita * fuori[-1]):
        fuori.pop()
    fuori.append(LUNGHEZZA)
    return fuori


def quote_anelli():
    """Le `s` degli anelli di pelle, dall'attacco alla punta."""
    return [1.0 - d / LUNGHEZZA for d in reversed(_crescente(
        PASSO_ANELLO_MIN, CRESCITA_PASSO, PASSO_ANELLO_MAX))]


def giunti_ossa():
    """La profondita' di ogni giunto sotto l'attacco, dall'attacco alla punta."""
    return [LUNGHEZZA - d for d in reversed(_crescente(OSSO_MIN, OSSO_CRESCITA, OSSO_MAX))]


def _profilo(theta):
    """Quanto la sezione si discosta dal cerchio, all'angolo `theta`.

    `theta` = 0 e' la faccia ORALE (quella delle ventose), `pi` il dorso.
    Schiacciata davanti del 10%, due costole muscolari sul dorso a ±26 gradi
    dalla mezzeria dorsale. Sono pochi centesimi: bastano perche' la luce che
    striscia lungo il braccio mentre si muove trovi qualcosa da prendere.
    """
    a = abs(math.atan2(math.sin(theta), math.cos(theta)))
    f = 1.0 - 0.10 * max(0.0, math.cos(a)) ** 2
    f += 0.055 * math.exp(-(((a - (math.pi - 0.45)) / 0.20) ** 2))
    return f


def _direzione(theta):
    """Il versore radiale della sezione. Faccia orale verso -y di Blender (+z di gioco)."""
    return Vector((math.sin(theta), -math.cos(theta), 0.0))


def _diametro_ventosa(s):
    """Il diametro della ventosa alla frazione `s`.

    Il rapporto ventosa/braccio non e' costante: parte da circa un quarto, sale
    fino a 0,40 attorno a s = 0,16 e poi ricala. E' quello che fa la "spalla" di
    ventose grosse vicino alla base, che e' il carattere che si riconosce.
    """
    rapporto = 0.25 + 0.15 * math.exp(-(((s - 0.16) / 0.20) ** 2))
    return 2.0 * raggio(s) * rapporto


class Malla(object):
    """Vertici e facce, con il materiale e le coordinate di texture di ogni faccia.

    LE UV STANNO SUGLI ANGOLI DELLE FACCE, non sui vertici, e serve alla cucitura:
    l'ultimo spicchio del tubo va dalla colonna 15 alla colonna 0, e se la colonna 0
    avesse una u sola - zero - quello spicchio stirerebbe l'intera mappa al contrario
    in una fetta larga un sedicesimo. Con le UV per angolo la stessa colonna vale
    zero per lo spicchio che parte e GIRI_PELLE per quello che chiude.
    """

    def __init__(self):
        self.verts = []
        self.facce = []
        self.materiali = []
        self.uv = []

    def vert(self, p):
        self.verts.append((p[0], p[1], p[2]))
        return len(self.verts) - 1

    def faccia(self, indici, mat, uv):
        self.facce.append(tuple(indici))
        self.materiali.append(mat)
        self.uv.append(tuple(uv))


def costruisci_pelle(m):
    """Il tubo rastremato, i suoi due tappi, e la punta.

    IL VERSO DELLE FACCE E' CALCOLATO, NON CORRETTO DOPO. `recalc_face_normals`
    lavora bene sui gusci chiusi, e le ventose sono gusci aperti appoggiati sopra
    la pelle: su quelli la ricalcolata avrebbe potuto girarle dentro, e una
    ventosa con la normale invertita non si vede come una ventosa storta - si
    vede come una macchia nera. Ogni quadrilatero qui sotto e' scritto nel verso
    giusto, e il provino lo conferma.

    LA v DELLA PELLE SI ACCUMULA ANELLO PER ANELLO, dividendo ogni tratto per la
    circonferenza del braccio in quel punto: e' cio' che tiene i quadri della mappa
    quadrati dappertutto, larghi quanto mezzo giro (vedi `GIRI_PELLE`).
    """
    quote = quote_anelli()
    anelli = []
    vv = []
    v = 0.0
    for i, s in enumerate(quote):
        if i > 0:
            tratto = (s - quote[i - 1]) * LUNGHEZZA
            r_medio = raggio(0.5 * (s + quote[i - 1]))
            v += GIRI_PELLE * tratto / (2.0 * math.pi * r_medio)
        vv.append(v)
        z = -s * LUNGHEZZA
        r = raggio(s)
        fila = []
        for j in range(LATI):
            th = 2.0 * math.pi * j / LATI
            fila.append(m.vert(_direzione(th) * (r * _profilo(th)) + Vector((0.0, 0.0, z))))
        anelli.append(fila)

    def u(j):
        return GIRI_PELLE * j / LATI

    for i in range(len(anelli) - 1):
        a, b = anelli[i], anelli[i + 1]
        for j in range(LATI):
            k = (j + 1) % LATI
            m.faccia((a[j], b[j], b[k], a[k]), 0,
                     ((u(j), vv[i]), (u(j), vv[i + 1]), (u(j + 1), vv[i + 1]), (u(j + 1), vv[i])))

    # il tappo in cima: sta dove la pelle e' gia' sparita nel cielo
    centro = m.vert(Vector((0.0, 0.0, 0.0)))
    for j in range(LATI):
        k = (j + 1) % LATI
        m.faccia((anelli[0][j], anelli[0][k], centro), 0,
                 ((u(j), 0.0), (u(j + 1), 0.0), (0.5 * (u(j) + u(j + 1)), -0.1)))

    # la punta, arrotondata
    fine = vv[-1]
    punta = m.vert(Vector((0.0, 0.0, -LUNGHEZZA - R_PUNTA * 1.4)))
    for j in range(LATI):
        k = (j + 1) % LATI
        m.faccia((anelli[-1][k], anelli[-1][j], punta), 0,
                 ((u(j + 1), fine), (u(j), fine), (0.5 * (u(j) + u(j + 1)), fine + 0.2)))

    return anelli


def costruisci_ventose(m):
    """Le due file alternate, dalla punta fin dove valgono la pena.

    UNA VENTOSA E' UNA COPPA, non un disco: anello di base sulla pelle, orlo
    rialzato piu' stretto, e il foro al centro appena rientrato. Da lontano quello
    che si vede e' il bordo chiaro che prende la luce di taglio - cioe' l'orlo. Un
    disco piatto non lo fa.

    SI COMINCIA DA `VENTOSE_FINO_A` E SI SCENDE: sopra, lassu', non ce ne sono.
    """
    fatte = 0
    s = 1.0 - VENTOSE_FINO_A / LUNGHEZZA
    lato = 1
    while s < 0.9995:
        d = _diametro_ventosa(s)
        if d < VENTOSA_MINIMA:
            break
        # OTTO LATI PER LE GROSSE, SEI PER LE PICCOLE. Sotto il mezzo metro il
        # poligono non si distingue piu' dal cerchio nemmeno col naso attaccato.
        lati = 8 if d >= 0.45 else 6
        th = lato * FILA
        n = _direzione(th)
        asse = Vector((0.0, 0.0, -1.0))
        t = n.cross(asse)
        c = n * (raggio(s) * _profilo(th)) + Vector((0.0, 0.0, -s * LUNGHEZZA))
        re = d / 2.0
        base, orlo = [], []
        for j in range(lati):
            a = 2.0 * math.pi * j / lati
            giro = (math.cos(a) * t + math.sin(a) * asse)
            base.append(m.vert(c + giro * re))
            orlo.append(m.vert(c + giro * (re * 0.74) + n * (re * 0.30)))
        foro = m.vert(c + n * (re * 0.10))
        for j in range(lati):
            k = (j + 1) % lati
            m.faccia((base[j], orlo[j], orlo[k], base[k]), 1,
                     ((0.0, 0.0), (0.0, 0.5), (0.5, 0.5), (0.5, 0.0)))
            m.faccia((foro, orlo[k], orlo[j]), 1, ((0.25, 0.25), (0.5, 0.5), (0.0, 0.5)))
        fatte += 1
        # il passo lungo il braccio e' proporzionale alla ventosa: cosi' le due
        # file restano incastrate a zigzag per tutta la lunghezza, come nel vero
        s += (0.72 * d) / LUNGHEZZA
        lato = -lato
    return fatte


def pesi_delle_ossa(m, giunti):
    """A quale osso appartiene ogni vertice, e quanto.

    DUE OSSA PER VERTICE, MISCELATE. Con un osso solo per vertice la pelle si
    piega a fisarmonica: ogni giunto diventa uno spigolo netto, e si contano le
    ossa come le tacche di un righello. Miscelando fra l'osso che precede e quello
    che segue - in base a dove cade il vertice rispetto ai CENTRI delle due ossa,
    non ai loro estremi - la curva torna continua. Le ossa sono lunghe diverse, e i
    centri si leggono dall'elenco dei giunti.
    """
    centri = [0.5 * (giunti[i] + giunti[i + 1]) for i in range(len(giunti) - 1)]
    ultimo = len(centri) - 1
    pesi = []
    import bisect
    for (_x, _y, z) in m.verts:
        u = -z
        i1 = bisect.bisect_right(centri, u)
        if i1 <= 0:
            pesi.append((0, 1.0, 0, 0.0))
        elif i1 > ultimo:
            pesi.append((ultimo, 1.0, ultimo, 0.0))
        else:
            i0 = i1 - 1
            t = (u - centri[i0]) / (centri[i1] - centri[i0])
            pesi.append((i0, 1.0 - t, i1, t))
    return pesi


def main():
    pulisci()
    m = Malla()
    costruisci_pelle(m)
    ventose = costruisci_ventose(m)

    malla = bpy.data.meshes.new("Tentacolo")
    malla.from_pydata(m.verts, [], m.facce)
    pelle = materiale("Tentacolo")
    if not applica_texture(pelle, "Tentacolo", set_texture=PELLE):
        raise SystemExit("manca la pelle: lancia prima python tools/prendi_pelle.py")
    malla.materials.append(pelle)
    malla.materials.append(materiale("Ventosa"))
    for f, mat in zip(malla.polygons, m.materiali):
        f.material_index = mat
    strato = malla.uv_layers.new(name="UVMap")
    for poly, uv in zip(malla.polygons, m.uv):
        for k, lp in enumerate(range(poly.loop_start, poly.loop_start + poly.loop_total)):
            strato.data[lp].uv = uv[k]
    malla.validate()
    malla.update()

    corpo = bpy.data.objects.new("Tentacolo", malla)
    bpy.context.collection.objects.link(corpo)
    bpy.context.view_layer.objects.active = corpo
    corpo.select_set(True)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(38.0))
    corpo.select_set(False)

    # --- lo scheletro --------------------------------------------------------
    giunti = giunti_ossa()
    ossa = len(giunti) - 1
    arm = bpy.data.armatures.new("Scheletro")
    scheletro = bpy.data.objects.new("Scheletro", arm)
    bpy.context.collection.objects.link(scheletro)
    bpy.context.view_layer.objects.active = scheletro
    scheletro.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    prec = None
    for i in range(ossa):
        b = arm.edit_bones.new("osso_%03d" % i)
        b.head = (0.0, 0.0, -giunti[i])
        b.tail = (0.0, 0.0, -giunti[i + 1])
        if prec is not None:
            b.parent = prec
            b.use_connect = True
        prec = b
    bpy.ops.object.mode_set(mode="OBJECT")
    scheletro.select_set(False)

    for i in range(ossa):
        corpo.vertex_groups.new(name="osso_%03d" % i)
    gruppi = list(corpo.vertex_groups)
    for idx, (i0, w0, i1, w1) in enumerate(pesi_delle_ossa(m, giunti)):
        gruppi[i0].add([idx], w0, "REPLACE")
        if i1 != i0 and w1 > 0.0:
            gruppi[i1].add([idx], w1, "REPLACE")
    mod = corpo.modifiers.new("Armatura", "ARMATURE")
    mod.object = scheletro
    corpo.parent = scheletro

    # --- export --------------------------------------------------------------
    # NON si passa da `modellare.esporta`: quello applica i modificatori, e qui il
    # modificatore E' il rig. Si esportano insieme corpo e scheletro, senza
    # applicare niente.
    os.makedirs(os.path.dirname(USCITA), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    corpo.select_set(True)
    scheletro.select_set(True)
    bpy.context.view_layer.objects.active = scheletro
    bpy.ops.export_scene.gltf(filepath=USCITA, export_format="GLB",
                              use_selection=True, export_apply=False)

    tris = sum(len(f) - 2 for f in m.facce)
    lunghezze = [giunti[i + 1] - giunti[i] for i in range(ossa)]
    print("\nscritto %s  (%.1f MB)" % (USCITA, os.path.getsize(USCITA) / 1e6))
    print("  lungo %.0f m; diametro: in cima %.1f m, a 45 m dalla punta %.2f, punta %.2f" % (
        LUNGHEZZA, 2 * raggio_d(LUNGHEZZA), 2 * raggio_d(45.0), 2 * R_PUNTA))
    print("  %d ossa, da %.2f m in punta a %.1f m in cima; %d anelli; %d vertici, %d triangoli" % (
        ossa, lunghezze[-1], lunghezze[0], len(quote_anelli()), len(m.verts), tris))
    print("  %d ventose negli ultimi %.0f m" % (ventose, VENTOSE_FINO_A))
    return corpo, scheletro, giunti


def provini(_corpo, scheletro, giunti):
    """Si guarda, non si consegna alla cieca.

    SI RENDE PIEGATO, e non dritto. Un tentacolo dritto e' un palo: dal provino
    non si capirebbe ne' se la pelle segue le ossa ne' se le ventose restano
    attaccate mentre si piega - che sono le due cose che possono essere sbagliate
    qui dentro.

    LA POSA SI SCRIVE IN CURVATURA, non in angoli per osso: le ossa sono lunghe
    diverse, e lo stesso angolo su un osso da due metri e su uno da quaranta sono due
    pieghe diverse di venti volte. Ogni osso gira di curvatura per lunghezza.
    """
    for i, osso in enumerate(scheletro.pose.bones):
        lungo = giunti[i + 1] - giunti[i]
        d = LUNGHEZZA - 0.5 * (giunti[i] + giunti[i + 1])
        vivo = math.exp(-d / 300.0)
        kx = 3.0 * (2.0 * math.pi / 60.0) ** 2 * math.sin(2.0 * math.pi * d / 60.0) * vivo
        kz = 2.0 * (2.0 * math.pi / 45.0) ** 2 * math.sin(2.0 * math.pi * d / 45.0 + 1.1) * vivo
        osso.rotation_mode = "XYZ"
        osso.rotation_euler = (kx * lungo, 0.0, kz * lungo)
    bpy.context.view_layer.update()

    # IL METRO UMANO: una scatola alta 1,80 accanto alla punta. Non si esporta
    # (l'export e' gia' avvenuto): serve solo a rispondere alla domanda «enorme
    # quanto?», che senza un riferimento in un render non ha risposta.
    metro = bpy.data.meshes.new("Metro")
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= 0.5
        v.co.y *= 0.35
        v.co.z = (v.co.z + 0.5) * 1.80
    bm.to_mesh(metro)
    bm.free()
    metro.materials.append(materiale("Metro"))
    o = bpy.data.objects.new("Metro", metro)
    bpy.context.collection.objects.link(o)
    bpy.context.view_layer.update()
    # accanto alla punta VERA, dopo la posa: la catena piegata non finisce a -LUNGHEZZA
    ultimo = scheletro.pose.bones[-1]
    coda = scheletro.matrix_world @ ultimo.tail
    o.location = (coda.x + 2.0, coda.y, coda.z - 1.6)

    scatta = prepara_render(1100, 760, cielo=(0.10, 0.12, 0.17))
    sole = lampada("Luna", (40.0, 40.0, 30.0), 3.5, tipo="SUN")
    sole.rotation_euler = (math.radians(58.0), 0.0, math.radians(35.0))
    lampada("Rimbalzo", (-25.0, -10.0, -22.0), 90000.0)

    # in coordinate di gioco: la y e' la z di Blender
    px, py, pz = coda.x, coda.z, -coda.y
    scatta(os.path.join(CONFRONTO, "27_tentacolo.png"),
           (px + 260.0, py + 120.0, pz + 200.0), (px, py + 140.0, pz), lente=28.0)
    scatta(os.path.join(CONFRONTO, "27b_tentacolo_pelle.png"),
           (px + 14.0, py + 22.0, pz + 15.0), (px, py + 22.0, pz), lente=40.0)
    scatta(os.path.join(CONFRONTO, "27c_tentacolo_punta.png"),
           (px + 7.0, py + 3.0, pz + 7.0), (px, py + 2.0, pz), lente=35.0)
    # la camera di Blender taglia a mille metri, e da duemila non vedeva niente
    bpy.context.scene.camera.data.clip_end = 20000.0
    scatta(os.path.join(CONFRONTO, "27d_tentacolo_intero.png"),
           (px + 1600.0, py + 750.0, pz + 1200.0), (px, py + 750.0, pz), lente=35.0)


if __name__ == "__main__":
    _c, _s, _g = main()
    provini(_c, _s, _g)
