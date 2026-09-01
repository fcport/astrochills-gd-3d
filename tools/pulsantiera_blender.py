# -*- coding: utf-8 -*-
"""La PULSANTIERA PENSILE della cupola: gialla, appesa al cavo, due pulsanti.

    "D:/programs/blender5/blender.exe" --background --python tools/pulsantiera_blender.py

DA DOVE VIENE LA FORMA. Non e' inventata: e' la Telemecanique/Schneider Harmony
XAC-A, la pulsantiera pensile da paranco che sta appesa in mezzo capannone d'Italia
dagli anni Ottanta. Corpo di ABS giallo, cuffia nera a soffietto in cima da cui esce
il cavo, due pulsanti Ø22 con la freccia su e la freccia giu'. Il CAD vero e' su
TraceParts (codice XACA271) e le quote di qui vengono da li': 64 mm di larghezza,
115 di corpo, 75 di cuffia, e il Ø22 che e' lo standard di tutta la famiglia
Harmony - la stessa misura del foro su ogni quadro industriale europeo.

PERCHE' PENSILE E NON A MURO. Un quadro a muro obbliga a stare dove sta il quadro;
la cupola si guarda aprire da sotto, muovendosi. Una pulsantiera che penzola la si
prende in mano dove serve, ed e' anche il motivo per cui nei capannoni si usa
quella e non un quadro: il comando deve stare dove sta l'occhio.

L'ORIGINE STA IN CIMA AL CAVO, non sul corpo, e per la stessa ragione per cui
quella del battente sta sul cardine (`porta_magazzino_blender.py`): questo oggetto
DONDOLA. Ruotando il nodo attorno alla propria origine la pulsantiera oscilla
appesa; con l'origine sul corpo ruoterebbe su se stessa come una trottola.

VERDE E ROSSO CONTRO IL VERO. Sull'oggetto reale i due cappucci sono tutti e due
neri e a distinguerli e' solo la freccia serigrafata. Qui APRE e' verde e CHIUDE e'
rosso, ed e' una bugia deliberata: il giocatore mira da un metro e mezzo, con la
cupola al buio, e due dischi neri identici sono la stessa incomprensibilita' del
quadro grigio di prima. Le frecce restano, perche' sono loro a dire QUALE VERSO -
il colore dice solo quale dei due.
"""
import os
import sys

import bpy

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
import importlib   # noqa: E402
for _m in ("modellare",):
    if _m in sys.modules:
        importlib.reload(sys.modules[_m])
from modellare import (bm_di, cilindro, esporta, finisci, lampada,   # noqa: E402
                       prepara_render, pulisci, scatola)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "pulsantiera.glb")
PROVINO = os.path.join(RADICE, "_confronto", "12_pulsantiera.png")

# --- quote, in metri, dal catalogo XAC-A -------------------------------------
CAVO_LUNGO = 0.30       # quanto cavo si modella sopra la cuffia
CAVO_R = 0.0055

# LA CUFFIA E' STRETTA, e la prima stesura la sbagliava: svasata fino a 52 mm -
# quasi la larghezza del corpo - sembrava un albero di Natale invece di un
# passacavo. Sul pezzo vero il soffietto arriva a poco piu' di meta' del corpo, ed
# e' quella sproporzione fra scatola larga e collo sottile a rendere la sagoma
# riconoscibile da lontano.
CUFFIA_ALTA = 0.085
CUFFIA_R_SU = 0.010     # dove stringe sul cavo
CUFFIA_R_GIU = 0.019    # dove si innesta sul corpo
CUFFIA_ANELLI = 8
CUFFIA_LABBRO = 0.0018  # quanto sporge ogni anello: e' cio' che la fa a soffietto

CORPO_ALTO = 0.132
CORPO_LARGO = 0.062
CORPO_FONDO = 0.060
SPIGOLO = 0.010         # raggio degli spigoli verticali

PULSANTE_R = 0.011      # Ø22: la misura standard Harmony
GHIERA_R = 0.0165
PULSANTE_PASSO = 0.046  # interasse dei due pulsanti
# I PULSANTI STANNO IN BASSO, non in mezzo: sopra di loro il corpo lascia la
# fascia gialla dove il costruttore stampa il proprio nome, e senza quella
# fascia la pulsantiera diventa una targhetta nera con due bottoni.
PULSANTE_DA_FONDO = 0.050
# DIECI MILLIMETRI DI SPORGENZA, e il numero e' legato alla corsa: il tasto
# rientra di quattro quando lo premi (`DomeButton.TRAVEL`), e un cappuccio che
# sporge meno della propria corsa SPARISCE DENTRO LA TARGHETTA mentre lo tieni.
# E' successo: nel primo scatto in gioco il tasto APRE non c'era, e sembrava un
# problema di colore.
PULSANTE_FUORI = 0.010  # quanto sporge il cappuccio dalla ghiera

# le quote verticali, misurate SCENDENDO dall'origine (che sta in cima al cavo)
Y_CUFFIA_SU = -CAVO_LUNGO
Y_CUFFIA_GIU = Y_CUFFIA_SU - CUFFIA_ALTA
Y_CORPO_SU = Y_CUFFIA_GIU
Y_CORPO_GIU = Y_CORPO_SU - CORPO_ALTO
Y_MEZZO = Y_CORPO_GIU + PULSANTE_DA_FONDO   # centro della COPPIA, non del corpo

Z_FACCIA = CORPO_FONDO / 2.0


def freccia(mat, cx, cy, z, mezza_base, altezza, verso, spessore=0.0012):
    """Un triangolo pieno appoggiato alla faccia frontale, punta su (+1) o giu' (-1).

    Si costruisce a mano invece che con una primitiva perche' non ce n'e' una: le
    frecce sono l'unica cosa che dica QUALE VERSO fa un pulsante, e su un oggetto
    che nel gioco si guarda da un metro e mezzo devono essere geometria vera - una
    freccia dipinta su una texture, a questa scala, sarebbe tre pixel sfocati.
    """
    bm = bm_di(mat)
    punta = (cx, cy + verso * altezza / 2.0)
    base_y = cy - verso * altezza / 2.0
    piano = [punta, (cx - mezza_base, base_y), (cx + mezza_base, base_y)]
    if verso < 0:
        piano = [piano[0], piano[2], piano[1]]   # l'avvolgimento resta antiorario
    davanti = [bm.verts.new((p[0], -(z + spessore), p[1])) for p in piano]
    dietro = [bm.verts.new((p[0], -z, p[1])) for p in piano]
    bm.faces.new(davanti)
    bm.faces.new(list(reversed(dietro)))
    for k in range(3):
        k2 = (k + 1) % 3
        bm.faces.new((dietro[k], dietro[k2], davanti[k2], davanti[k]))


def corpo():
    """La scatola gialla, con gli spigoli verticali arrotondati.

    Non e' un parallelepipedo e non e' un vezzo: una scatola a spigolo vivo e' lo
    stampo che nessuno fa, perche' un pezzo di ABS esce dallo stampo con i raggi.
    Si compone come si compone un rettangolo stondato - due scatole incrociate e
    quattro cilindri agli angoli - invece che con un bisello, che su una mesh
    unita per materiale non si puo' fare senza operatori.
    """
    mx, mz = CORPO_LARGO / 2.0, CORPO_FONDO / 2.0
    scatola("PlasticaGialla", -mx + SPIGOLO, mx - SPIGOLO, Y_CORPO_GIU, Y_CORPO_SU,
            -mz, mz)
    scatola("PlasticaGialla", -mx, mx, Y_CORPO_GIU, Y_CORPO_SU,
            -mz + SPIGOLO, mz - SPIGOLO)
    for sx in (-1, 1):
        for sz in (-1, 1):
            cilindro("PlasticaGialla", sx * (mx - SPIGOLO), sz * (mz - SPIGOLO),
                     Y_CORPO_GIU, Y_CORPO_SU, SPIGOLO, seg=10)


def cuffia():
    """Il soffietto nero: sei anelli svasati, non un cono liscio.

    E' il pezzo che rende riconoscibile l'oggetto da lontano. Un cono liscio
    sembrerebbe un imbuto; sono le nervature a dire «passacavo di gomma», ed e'
    l'unica silhouette che questa pulsantiera ha oltre alla scatola.
    """
    passo = CUFFIA_ALTA / CUFFIA_ANELLI
    for k in range(CUFFIA_ANELLI):
        y_su = Y_CUFFIA_SU - k * passo
        y_giu = y_su - passo
        r_su = CUFFIA_R_SU + (CUFFIA_R_GIU - CUFFIA_R_SU) * (k / CUFFIA_ANELLI)
        r_giu = CUFFIA_R_SU + (CUFFIA_R_GIU - CUFFIA_R_SU) * ((k + 1) / CUFFIA_ANELLI)
        cilindro("Gomma", 0.0, 0.0, y_giu, y_su, r_giu + CUFFIA_LABBRO, seg=16,
                 r2=r_su)


def pulsanti():
    """Ghiera nera, cappuccio colorato, freccia bianca. Due volte."""
    # LA TARGHETTA NERA fa da sfondo ai due comandi: sul giallo pieno un cappuccio
    # verde scuro sparisce, perche' due colori saturi accostati si annullano.
    scatola("Gomma", -0.024, 0.024, Y_MEZZO - 0.045, Y_MEZZO + 0.045,
            Z_FACCIA - 0.001, Z_FACCIA + 0.0015)
    for nome, verso in (("PulsanteApre", 1), ("PulsanteChiude", -1)):
        cy = Y_MEZZO + verso * PULSANTE_PASSO / 2.0
        serigrafia = nome.replace("Pulsante", "Serigrafia")
        # la ghiera: un cilindro schiacciato coricato sulla faccia
        _disco("Gomma", cy, GHIERA_R, Z_FACCIA + 0.0015, Z_FACCIA + 0.005)
        _disco(nome, cy, PULSANTE_R, Z_FACCIA + 0.004,
               Z_FACCIA + 0.004 + PULSANTE_FUORI)
        freccia(serigrafia, 0.0, cy, Z_FACCIA + 0.004 + PULSANTE_FUORI,
                0.0055, 0.011, verso)


def _disco(mat, cy, r, z0, z1):
    """Un cilindro coricato sulla faccia frontale, dal suo asse Z."""
    import bmesh
    import math
    from mathutils import Matrix, Vector
    bmesh.ops.create_cone(
        bm_di(mat), cap_ends=True, cap_tris=False, segments=20,
        radius1=r, radius2=r, depth=z1 - z0,
        matrix=Matrix.Translation(Vector((0.0, -(z0 + z1) / 2.0, cy)))
        @ Matrix.Rotation(math.radians(90.0), 4, "X"))


pulisci()
cilindro("Gomma", 0.0, 0.0, Y_CUFFIA_SU, 0.0, CAVO_R, seg=10)
cuffia()
corpo()
pulsanti()

# I tondi si sfumano, la scatola no: e' la riga che distingue un cilindro tondo da
# una scatola molle. Il giallo resta spigoloso perche' i suoi angoli SONO angoli.
pezzi = finisci(morbidi=("Gomma", "PulsanteApre", "PulsanteChiude"))

facce = sum(len(o.data.polygons) for o in pezzi)
print("  la pulsantiera e' fatta di %d facce in %d pezzi" % (facce, len(pezzi)))
if facce > 4000:
    print("\nATTENZIONE: %d facce per una pulsantiera sono troppe." % facce)
    sys.exit(1)

esporta(USCITA)

# --- il provino: si GUARDA, non si deduce ------------------------------------
# Un modello che non si e' mai visto e' un modello che non si sa se e' venuto. Il
# quadro di prima aveva passato ogni controllo numerico ed era «un quadrato con due
# pallini»: quel giudizio non lo da' nessun assert, lo da' un occhio.
os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
scatta = prepara_render(900, 1000, cielo=(0.055, 0.058, 0.065))
# LE LUCI ERANO DA STUDIO, e slavavano il giudizio: a 45 W la gomma nera usciva
# grigio chiaro, il giallo crema e i due cappucci pastello. Un provino serve a
# decidere dei colori, e un provino bruciato risponde sempre di si'.
lampada("Chiave", (0.35, Y_MEZZO + 0.45, 0.55), 7.0, tipo="AREA", dimensione=0.8)
lampada("Riempimento", (-0.45, Y_MEZZO + 0.10, 0.40), 2.0)
lampada("Contro", (0.0, Y_MEZZO + 0.30, -0.60), 3.0)
scatta(PROVINO, (0.16, Y_MEZZO + 0.13, 0.46), (0.0, Y_MEZZO - 0.02, 0.0), lente=50.0)
