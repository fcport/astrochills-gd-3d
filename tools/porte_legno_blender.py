# -*- coding: utf-8 -*-
"""Il BATTENTE delle porte interne di legno, con l'origine sul cardine.

    "D:/programs/blender5/blender.exe" --background --python tools/porte_legno_blender.py

UN .glb SOLO PER CINQUE PORTE. Le interne hanno tutte lo stesso vano (`VANO_PORTA`
in `geometria.py`), e un'anta con la maniglia su tutte e due le facce e' la stessa
qualunque sia la mano: il nodo `Door` la gira dal cardine, e il verso lo decide
lui. Quali porte la usano lo dice `PORTE_TAMBURATE`.

DAL PACCHETTO SI PRENDE UNA PORTA SOLA, la D2. Ne porta due, identiche nella forma:
la D1 e' wenge', la D2 finto mogano. In un edificio pubblico di fine anni Novanta
la porta interna e' la seconda - il wenge' e' venuto dopo.

LA MANIGLIA E' FUSA NELL'ANTA, e non come nel magazzino. Qui la mesh `D2-Door` e'
una sola: pannello, leva, rosetta, frontale della serratura e cardini. Si separa
per parti sconnesse e si riconosce ogni pezzo DALLA MISURA - il pannello e' fatto
di lastre lunghe quasi quanto l'anta, la ferramenta di pezzi di pochi centimetri.

IL MODELLO E' SPESSO IL DOPPIO DEL NOSTRO, e non si puo' stirare in blocco. Le sue
proporzioni danno un'anta di otto centimetri, e la nostra ne misura 4,5 - il vano,
la collisione e il banco delle porte la vogliono cosi'. Uno schiacciamento a meta'
su un asse solo su una LASTRA non si vede; su una maniglia tonda si', e subito.
Quindi il pannello si porta alle misure del vano con tre fattori diversi, e la
ferramenta con UNO SOLO - quello dell'altezza, che e' la dimensione in cui il
modello e' gia' a misura d'uomo: la leva esce a 1,06 dal pavimento, lunga diciassette
centimetri. Ogni gruppo di ferramenta resta attaccato alla sua faccia: il suo punto
d'appoggio segue il pannello, il resto scala attorno a quello.

I CARDINI SI BUTTANO. Un cardine anuba sporge dalla faccia verso cui la porta si
apre, e questo .glb serve sia alle porte che si aprono da una parte sia a quelle
che si aprono dall'altra: su meta' di loro il cardine starebbe sulla faccia
sbagliata. Un'anta senza cardini non la nota nessuno, una con i cardini al
contrario si'.
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
from geometria import PORTE_TAMBURATE, ante_porte   # noqa: E402
from modellare import esporta, pulisci, raddrizza_normali, usa_le_ridotte   # noqa: E402

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "porta_legno.glb")
SORGENTE = os.path.join(RADICE, "assets", "models", "esterni", "porte_legno", "scene.gltf")

QUALE_NEL_PACCHETTO = "D2-Door"

# Un pezzo e' PANNELLO se la sua dimensione maggiore supera questa frazione della
# diagonale di faccia dell'anta. Le lastre del pannello sono lunghe quanto l'anta o
# quanto meta' (e' spezzato in due all'altezza della maniglia); il pezzo di
# ferramenta piu' grande, il frontale della serratura, arriva a un nono.
QUOTA_PANNELLO = 0.3

# Quanto vicino al bordo libero deve stare un pezzo per essere SERRATURA e non
# maniglia, in unita' del modello (l'anta ne misura due di larghezza). Il frontale e
# lo scrocco stanno entro 0,07 dal bordo; la rosetta comincia a 0,12.
FASCIA_BORDO = 0.07


def bordi(o):
    p = [o.matrix_world @ v.co for v in o.data.vertices]
    return [min(q[i] for q in p) for i in range(3)], [max(q[i] for q in p) for i in range(3)]


print("")
pulisci()
if not os.path.exists(SORGENTE):
    print("MANCA il modello: %s" % SORGENTE)
    print("  lancia prima: python tools/prendi_modello.py porte_legno")
    sys.exit(1)
bpy.ops.import_scene.gltf(filepath=SORGENTE)

anta = [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(QUALE_NEL_PACCHETTO)]
if len(anta) != 1:
    print("ATTENZIONE: nel pacchetto non c'e' una e una sola '%s'" % QUALE_NEL_PACCHETTO)
    sys.exit(1)
anta = anta[0]
# LA POSA SI CUOCE PRIMA DI BUTTARE IL RESTO: la scala e la rotazione dell'import
# stanno nei genitori, e togliendo quelli l'anta tornerebbe alle sue coordinate
# grezze - cento volte piu' grande e sdraiata.
anta.data.transform(anta.matrix_world)
anta.parent = None
anta.matrix_world = Matrix()
# tutto il resto - l'altra anta, i due telai, le due anteprime - si butta
for o in list(bpy.data.objects):
    if o is not anta:
        bpy.data.objects.remove(o, do_unlink=True)

bpy.context.view_layer.objects.active = anta
anta.select_set(True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.separate(type="LOOSE")
bpy.ops.object.mode_set(mode="OBJECT")
pezzi = [(o, *bordi(o)) for o in bpy.data.objects if o.type == "MESH"]

# --- chi e' pannello e chi ferramenta ----------------------------------------
# Nel modello: X lo spessore, Y la larghezza, Z l'altezza.
lo = [min(b[0][i] for b in [(p[1], p[2]) for p in pezzi]) for i in range(3)]
hi = [max(b[1][i] for b in [(p[1], p[2]) for p in pezzi]) for i in range(3)]
diag = ((hi[1] - lo[1]) ** 2 + (hi[2] - lo[2]) ** 2) ** 0.5
pannello = [p for p in pezzi if max(p[2][i] - p[1][i] for i in range(3)) > diag * QUOTA_PANNELLO]
ferramenta = [p for p in pezzi if p not in pannello]
if not pannello:
    print("ATTENZIONE: nessun pezzo ha la misura di un pannello")
    sys.exit(1)
pl = [min(p[1][i] for p in pannello) for i in range(3)]
ph = [max(p[2][i] for p in pannello) for i in range(3)]
print("  pannello: %d lastre, %.3f spesso, %.3f largo, %.3f alto (unita' del modello)"
      % (len(pannello), ph[0] - pl[0], ph[1] - pl[1], ph[2] - pl[2]))

# IL CARDINE STA DALLA PARTE OPPOSTA ALLA MANIGLIA, e non c'e' altro modo di
# saperlo che guardarla. Si guarda la sola LEVA, cioe' quello che sporge di piu'
# dalle facce: sporgono anche le rosette e le alette dei cardini, e i cardini sono
# trentaquattro pezzi contro una dozzina di maniglia - con la media di tutto, il
# cardine finiva dalla parte della maniglia.
mezzo_y = (pl[1] + ph[1]) / 2.0
sporge = 0.06 * (ph[1] - pl[1])
leve = [p for p in ferramenta if p[2][0] > ph[0] + sporge or p[1][0] < pl[0] - sporge]
if not leve:
    print("ATTENZIONE: non c'e' nessuna leva che sporga dalle facce")
    sys.exit(1)
cy_maniglia = sum((p[1][1] + p[2][1]) / 2.0 for p in leve) / len(leve)
cardine_a_y_alto = cy_maniglia < mezzo_y
y_cardine = ph[1] if cardine_a_y_alto else pl[1]
y_libero = pl[1] if cardine_a_y_alto else ph[1]
print("  la maniglia sta a y=%.2f: il cardine e' a y=%.2f" % (cy_maniglia, y_cardine))

cardini, serratura, faccia_piu, faccia_meno = [], [], [], []
for p in ferramenta:
    o, b0, b1 = p
    cy = (b0[1] + b1[1]) / 2.0
    cx = (b0[0] + b1[0]) / 2.0
    if abs(cy - y_cardine) < FASCIA_BORDO * 1.5:
        cardini.append(o)
    elif abs(cy - y_libero) < FASCIA_BORDO:
        serratura.append(p)
    elif cx > (pl[0] + ph[0]) / 2.0:
        faccia_piu.append(p)
    else:
        faccia_meno.append(p)
print("  ferramenta: %d pezzi di maniglia su una faccia, %d sull'altra, %d di serratura;"
      " %d di cardini, che si buttano"
      % (len(faccia_piu), len(faccia_meno), len(serratura), len(cardini)))
if not faccia_piu or not faccia_meno:
    print("ATTENZIONE: la maniglia non sta su tutte e due le facce - andrebbe specchiata")
    sys.exit(1)
for o in cardini:
    bpy.data.objects.remove(o, do_unlink=True)

# --- misure volute -----------------------------------------------------------
a = [x for x in ante_porte() if x["nome"] in PORTE_TAMBURATE]
misure = {(round(x["larghezza"], 3), round(x["altezza"], 3), round(x["spessore"], 3)) for x in a}
if len(misure) != 1:
    print("ATTENZIONE: le porte tamburate non hanno tutte la stessa anta: %s" % sorted(misure))
    print("  un .glb solo non basta: o si pareggiano i vani, o ne serve uno per misura.")
    sys.exit(1)
L, HA, T = misure.pop()
print("  il vano vuole un'anta %.3f x %.3f x %.3f" % (L, HA, T))

s_larg = L / (ph[1] - pl[1])
s_alt = HA / (ph[2] - pl[2])
s_spess = T / (ph[0] - pl[0])
s_ferro = s_alt
print("  il pannello scala %.4f in larghezza, %.4f in altezza, %.4f nello spessore;"
      " la ferramenta %.4f in tutte e tre" % (s_larg, s_alt, s_spess, s_ferro))
# Il limite vale fra larghezza e altezza, che sono le due che si vedono: lo spessore
# di una lastra no. Oltre, una porta stirata si riconosce anche senza metro.
if max(s_larg, s_alt) / min(s_larg, s_alt) > 1.25:
    print("ATTENZIONE: l'anta andrebbe stirata di %.2f volte in faccia"
          % (max(s_larg, s_alt) / min(s_larg, s_alt)))
    sys.exit(1)
cx_pannello = (pl[0] + ph[0]) / 2.0
# da che parte del cardine si va verso il bordo libero
segno = -1.0 if cardine_a_y_alto else +1.0


def posa(x, y, z):
    """Dal modello all'anta: X dal cardine, Y lo spessore centrato, Z l'altezza.

    E' una rotazione e non uno specchio - (x, y, z) diventa (y, -x, z), con i segni
    girati quando il cardine sta dalla parte bassa - e non a caso: uno specchio
    rovescerebbe l'avvolgimento delle facce, e in Godot una faccia rovesciata
    prende la luce dalla parte sbagliata, cioe' esce nera.
    """
    return (segno * (y - y_cardine) * s_larg,
            -segno * (x - cx_pannello) * s_spess,
            (z - pl[2]) * s_alt)


def sposta(o, appoggio=None, s_trasversale=None):
    """Porta un pezzo nell'anta con UNA MATRICE, non vertice per vertice.

    `Mesh.transform` gira anche le normali personalizzate che l'import glTF lascia
    sui vertici; scrivendo `v.co` a mano le coordinate si sarebbero girate e le
    normali no, e la leva avrebbe preso la luce di un'altra direzione.
    """
    if appoggio is None:
        # il pannello: tre fattori diversi, attorno al cardine a terra
        m = Matrix(((0.0, segno * s_larg, 0.0, -segno * s_larg * y_cardine),
                    (-segno * s_spess, 0.0, 0.0, segno * s_spess * cx_pannello),
                    (0.0, 0.0, s_alt, -s_alt * pl[2]),
                    (0.0, 0.0, 0.0, 1.0)))
    else:
        # la ferramenta: un fattore solo attorno al suo appoggio, e l'appoggio segue
        # il pannello - cosi' la maniglia resta tonda e resta sulla sua faccia
        ax, ay, az = appoggio
        px, py, pz = posa(ax, ay, az)
        st = s_ferro if s_trasversale is None else s_trasversale
        m = Matrix(((0.0, segno * s_ferro, 0.0, px - segno * s_ferro * ay),
                    (-segno * st, 0.0, 0.0, py + segno * st * ax),
                    (0.0, 0.0, s_ferro, pz - s_ferro * az),
                    (0.0, 0.0, 0.0, 1.0)))
    o.data.transform(m)
    o.data.update()


for o, _b0, _b1 in pannello:
    sposta(o)
for gruppo, x_appoggio in ((faccia_piu, ph[0]), (faccia_meno, pl[0]), (serratura, cx_pannello)):
    if not gruppo:
        continue
    g0 = [min(p[1][i] for p in gruppo) for i in range(3)]
    g1 = [max(p[2][i] for p in gruppo) for i in range(3)]
    # la maniglia poggia sulla sua faccia; la serratura sul bordo libero, al centro
    # dello spessore - e lo scrocco che ne sporge resta sporgente, com'e' giusto
    y_appoggio = y_libero if gruppo is serratura else (g0[1] + g1[1]) / 2.0
    appoggio = (x_appoggio, y_appoggio, (g0[2] + g1[2]) / 2.0)
    # LA SERRATURA SI SCHIACCIA NELLO SPESSORE COME IL PANNELLO, e non per
    # comodita'. Nella fascia del bordo non c'e' solo il frontale: ci sono anche i
    # ritagli di legno che chiudono il bordo attorno a lui, larghi quanto l'anta.
    # Scalati come ferramenta uscivano quasi due centimetri dalle facce - punte
    # scure ai due capi del frontale, viste nel primo render. Schiacciati come il
    # pannello combaciano, e il frontale viene largo due centimetri: quello vero.
    trasversale = s_spess if gruppo is serratura else None
    for o, _b0, _b1 in gruppo:
        sposta(o, appoggio, trasversale)



def fondi(oggetti, nome):
    bpy.ops.object.select_all(action="DESELECT")
    for o in oggetti:
        o.select_set(True)
    bpy.context.view_layer.objects.active = oggetti[0]
    bpy.ops.object.join()
    fuso = bpy.context.view_layer.objects.active
    fuso.name = fuso.data.name = nome
    return fuso


# --- le leve si staccano dall'anta -------------------------------------------
# LA LEVA SI ABBASSA, e per farlo deve essere un nodo suo con l'origine sull'asse
# del quadro - che e' il centro della rosetta. Si stacca solo il BRACCIO, cioe' i
# pezzi lunghi e stretti: rosetta, collo e bottone sono tondi e centrati sull'asse,
# e girare con la leva o restare fermi e' lo stesso - restano con l'anta. `door.gd`
# cerca i nodi che si chiamano `Leva*` e li gira attorno al loro Z.
leve = []
for gruppo, lato in ((faccia_piu, "piu"), (faccia_meno, "meno")):
    pezzi_g = []
    for o, _b0, _b1 in gruppo:
        v = [q.co for q in o.data.vertices]
        c0 = [min(q[i] for q in v) for i in range(3)]
        c1 = [max(q[i] for q in v) for i in range(3)]
        pezzi_g.append((o, c0, c1))
    # nell'anta posata X e' la larghezza e Z l'altezza: la faccia e' il piano X-Z

    def allungato(c0, c1):
        dx, dz = c1[0] - c0[0], c1[2] - c0[2]
        return max(dx, dz) > 2.5 * max(min(dx, dz), 1e-4)
    braccio = [x for x in pezzi_g if allungato(x[1], x[2])]
    tondi = [x for x in pezzi_g if not allungato(x[1], x[2])]
    if not braccio or not tondi:
        print("ATTENZIONE: nella maniglia '%s' non si distinguono braccio e rosetta" % lato)
        sys.exit(1)
    # la ROSETTA e' il pezzo tondo piu' grande: il suo centro e' l'asse del quadro
    ros = max(tondi, key=lambda x: (x[2][0] - x[1][0]) * (x[2][2] - x[1][2]))
    asse = [(ros[1][i] + ros[2][i]) / 2.0 for i in range(3)]
    leva = fondi([x[0] for x in braccio], "Leva_" + lato)
    # l'origine sull'asse: la mesh si sposta indietro di quanto l'oggetto va avanti
    leva.data.transform(Matrix.Translation((-asse[0], -asse[1], -asse[2])))
    leva.location = asse
    punta = max((q.co for q in leva.data.vertices), key=lambda q: abs(q[0]))
    print("  leva %s: asse a x=%.3f z=%.3f, il braccio arriva %.1f cm verso %s"
          % (lato, asse[0], asse[2], abs(punta[0]) * 100,
             "il cardine" if punta[0] < 0 else "il bordo libero"))
    # una leva che punta verso il bordo libero sporgerebbe oltre l'anta
    if punta[0] > 0:
        print("ATTENZIONE: la leva '%s' punta verso il bordo libero" % lato)
        sys.exit(1)
    leve.append(leva)

# il resto si rifonde in un oggetto solo: e' un'anta, e una sola chiamata di disegno
porta = fondi([o for o in bpy.data.objects if o.type == "MESH" and o not in leve], "PortaLegno")
pezzi_finali = [porta] + leve

# --- controlli ----------------------------------------------------------------
p = [o.matrix_world @ v.co for o in pezzi_finali for v in o.data.vertices]
b0 = [min(q[i] for q in p) for i in range(3)]
b1 = [max(q[i] for q in p) for i in range(3)]
print("  posato: x %.3f..%.3f   y %.3f..%.3f   z %.3f..%.3f"
      % (b0[0], b1[0], b0[1], b1[1], b0[2], b1[2]))
problemi = []
# lo scrocco sporge oltre il bordo libero di un paio di centimetri, e la leva dalle
# facce di sette: il controllo e' sul pannello, e quindi sui soli margini veri
for nome, avuto, voluto, tolleranza in (("il cardine non e' nell'origine", b0[0], 0.0, 0.004),
                                        ("l'anta non parte dal pavimento", b0[2], 0.0, 0.004),
                                        ("l'anta non arriva all'architrave", b1[2], HA, 0.004),
                                        ("lo scrocco sporge troppo", b1[0], L, 0.035),
                                        ("la maniglia sporge troppo", b1[1], T / 2, 0.09),
                                        ("la maniglia sporge troppo", -b0[1], T / 2, 0.09)):
    if abs(avuto - voluto) > tolleranza:
        problemi.append("  %s: %.3f invece di %.3f" % (nome, avuto, voluto))
leva = [q for q in p if abs(q[1]) > T / 2 + 0.01]
if leva:
    quota = sum(q[2] for q in leva) / len(leva)
    print("  la maniglia sta a %.2f m da terra, e sporge %.1f cm dalle facce"
          % (quota, (max(abs(q[1]) for q in leva) - T / 2) * 100))
    if not 0.95 < quota < 1.15:
        problemi.append("  la maniglia sta a %.2f da terra: una porta vera la ha a 1,05" % quota)

girate = raddrizza_normali(pezzi_finali)
if girate:
    print("  %d facce avevano la normale al contrario" % girate)
# METALLICO A ZERO, come per il magazzino e per la stessa ragione: la mappa ridotta
# porta solo la rugosita', e collegata anche al metallico renderebbe il legno uno
# specchio. La maniglia esce satinata chiara invece che cromata, e da un metro e'
# quello che si legge comunque.
usa_le_ridotte(pezzi_finali, os.path.dirname(SORGENTE), metallico=0.0)

if problemi:
    print("\nATTENZIONE:")
    for r in problemi:
        print(r)
    sys.exit(1)

esporta(USCITA)
_mb = os.path.getsize(USCITA) / 1048576.0
print("  il battente pesa %.1f MB" % _mb)
if _mb > 6.0:
    print("\nATTENZIONE: %.1f MB per un'anta sola - quasi sempre e' una mappa presa"
          " da fuori e rimasta a piena risoluzione: vedi usa_le_ridotte()." % _mb)
    sys.exit(1)
