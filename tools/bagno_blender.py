# -*- coding: utf-8 -*-
"""Il bagno, dalla stessa impronta che lo fa collidere.

    "D:/programs/blender5/blender.exe" --background --python tools/bagno_blender.py

Stesso patto degli altri modellatori: `geometria.ARREDI_BAGNO` dichiara i rettangoli
in pianta, qui dentro ci si costruisce, e alla fine si controlla che nessuna mesh
esca dalla sua impronta. Quello che si vede e quello contro cui si sbatte restano la
stessa cosa.

UN BAGNO ITALIANO DEL 1999, E NON UN BAGNO. La differenza non la fanno i sanitari -
un water e' un water in ogni paese e in ogni decennio - la fanno tre cose che qui
sono geometria e materiale, non arredamento:

  * IL RIVESTIMENTO SI FERMA A 1,60 e sopra c'e' intonaco. Piastrellare fino al
    soffitto e' un gesto di oggi; fermarsi a mezza altezza con una riga di
    chiusura e' quello di allora, e da solo sposta la stanza di trent'anni.
  * IL LISTELLO. La fascia di losanghe azzurrine sopra il rivestimento e' il pezzo
    che data il bagno piu' di tutto il resto messo insieme. Non esiste in nessuna
    libreria CC0 - un listello e' un pezzo di gusto - e infatti se lo disegna
    tools/fai_listello.py.
  * IL BIDET. Un bagno senza bidet non e' italiano, punto. E la distanza dal water
    e' 75 cm da asse ad asse: sotto i 55 non ci si siede, sopra gli 80 la parete
    sembra vuota in mezzo.

SENZA VASCA E SENZA DOCCIA, e la seconda e' stata una correzione. Al posto della
vasca c'era finita una doccia con box in cristallo, che e' l'arredo di una camera
d'albergo: in un osservatorio in servizio, nell'angolo sud-est ci sta l'ARMADIO dei
detersivi, dei ricambi e del camice. Un bagno di servizio non e' un bagno piccolo,
e' un bagno con dentro cose diverse.

LE ANTE DEI MOBILI NON STANNO IN QUESTO FILE. Un pezzo che ruota ha bisogno di un
nodo suo con l'origine sul cardine, e un .glb e' una mesh sola: pensile e armadio
qui sono la CASSA, le loro ante sono dati in `geometria.ANTE_MOBILI` e in gioco
diventano nodi `Door` come le sette porte dell'edificio. Il piano su cui battono lo
legge `filo_anta()` da quella stessa tabella, cosi' cassa e anta non possono
scollarsi.

I SANITARI ARRIVANO DA FUORI, quando ci sono. Un water, un bidet e un lavabo a
colonna sono superfici curve continue: fatti con le scatole vengono mobili, non
ceramiche. Se i modelli non sono ancora stati scaricati questo script NON fallisce -
mette i suoi segnaposto e lo dice - perche' un bagno senza sanitari e' comunque una
stanza da guardare, mentre un modellatore che si rifiuta di girare non lo e'.

Produce assets/models/bagno.glb.
"""
import io
import math
import os
import sys

import bpy

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
import importlib   # noqa: E402
for _m in ("geometria", "modellare"):
    if _m in sys.modules:
        importlib.reload(sys.modules[_m])
from geometria import (ante_mobili, ARREDI_BAGNO, impronta_utile,   # noqa: E402
                       SALA_BAGNO, scalati, SPESS_PIASTRELLA, W_SILL)
from modellare import (COLORI, cilindro, cilindro_orizz, esporta,   # noqa: E402
                       finisci, raddrizza_normali, usa_le_ridotte,
                       lampada, posa_modello, prepara_render, pulisci, scatola,
                       verifica_impronte)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "bagno.glb")
ESTERNI = os.path.join(RADICE, "assets", "models", "esterni")
RENDER = os.path.join(RADICE, "_bmad-output", "planning-artifacts", "gdds",
                      "gdd-astrochills-gd-3d-2026-08-24")

IMPRONTE = {n: (x0, z0, x1, z1, h) for (n, x0, z0, x1, z1, h) in ARREDI_BAGNO}
X0, Z0, X1, Z1 = SALA_BAGNO[0]

# il vano della porta sul muro nord e quello della finestra sul muro sud: il
# rivestimento si interrompe li', e il listello con lui.
#
# LETTI DA GEOMETRIA, NON RICOPIATI. Erano due coppie di numeri scritte a mano che
# per caso coincidevano con l'apertura vera, e il giorno in cui le porte interne
# sono state ristrette per uniformarle il rivestimento del bagno sarebbe rimasto
# tagliato dov'era la porta prima - una striscia di intonaco in mezzo alle
# piastrelle, che in un render notturno non si distingue da un difetto della texture.
def vano(nome):
    """Dove cade un'apertura, in metri di gioco lungo il muro che la porta."""
    _, aperture, _, _, _, _ = scalati()
    for (px, pz, w, o, _t, n) in aperture:
        if n == nome:
            a = px if o == "h" else pz
            return (a, a + w)
    raise KeyError("apertura sconosciuta: %s" % nome)


PORTA = vano("bagno")
FINESTRA = vano("finestra bagno")

# Il rivestimento arriva a 1,60 e il listello sono gli ultimi 8 cm. Non 2,00 e non
# fino al soffitto: 1,60 e' l'altezza a cui si fermava il rivestimento nei bagni di
# quegli anni, ed e' anche l'altezza a cui l'occhio di chi sta in piedi lo incontra.
RIV = 1.60
LIST = 0.08
# lo spessore della piastrella, che si vede solo di taglio. LETTO da geometria
# invece che riscritto: con questo numero li' si calcola di quanto arretrare i
# mobili addossati, e due copie dello stesso millimetro sono una copia di troppo.
SPESS = SPESS_PIASTRELLA
SPORGE = 0.010     # di quanto il listello esce dal filo del rivestimento

# I sanitari presi da fuori: cartella dentro assets/models/esterni -> (impronta,
# gradi, come si chiama in italiano). I gradi sono la rotazione attorno alla
# verticale perche' guardino DENTRO la stanza: un modello non conosce il nostro nord.
# I sanitari presi da fuori: cartella -> (impronta, gradi, altezza di posa, nome).
#
# I GRADI SONO MISURATI, non indovinati: li stampa `tools/verso_sanitari.py`, che
# posa ogni modello alle quattro rotazioni e conta quanti vertici finiscono a filo
# del muro a cui quel pezzo e' addossato. Per il water quel conteggio non bastava -
# con la cassetta non arriva mai ai lati dell'impronta e dava zero a tutte e quattro
# - e li' decide da che parte pende la meta' alta del modello: un water ha la
# cassetta in alto e dietro.
#
# E L'ALTEZZA DI POSA NON E' QUELLA DELL'IMPRONTA. L'impronta del lavabo e' alta
# 1,90 perche' comprende specchio, mensola e applique; il lavabo e' alto 86 cm.
# Passando 1,90 a `posa_modello` il lavabo veniva scalato per essere alto quasi un
# metro, cioe' dieci centimetri troppo, e da fermi davanti si vedeva.
SANITARI = [
    ("wc_bagno",     "Wc",      90.0, 0.78, "il water"),
    ("bidet_bagno",  "Bidet",  180.0, 0.52, "il bidet"),
    ("lavabo_bagno", "Lavabo", 270.0, 0.86, "il lavabo a colonna"),
]

# IL TERMOSIFONE NON LO DECIDE `verso_sanitari.py`, e vale la pena dire perche'.
# Quel banco sceglie l'angolo che appoggia piu' vertici al muro, e sul radiatore
# vince 90 gradi con il 51% - solo che a 90 gradi il modello viene schiacciato a due
# centimetri di larghezza per stare nei venti di fondo dell'impronta. E' la stessa
# trappola del water: un pezzo orientato male viene RIMPICCIOLITO da posa_modello
# finche' ci sta, e da rimpicciolito tocca il muro dappertutto. Il numero che
# smaschera il caso e' l'ingombro - largo 0.02, alto 0.13 - non la percentuale.
# Restano 0 e 180, che per un radiatore di ghisa sono lo stesso pezzo specchiato:
# decide da che parte stanno la valvola e il detentore, e quello si e' guardato in
# render (bagno-termo.png). A zero la valvola cade verso la porta, cioe' dalla parte
# da cui la si vede entrando; a 180 finisce nell'angolo cieco sotto la finestra.
GRADI_TERMO = 0.0

# Quanto sta staccato da terra. Un radiatore di ghisa non poggia sul pavimento:
# sta su mensole a muro, e sotto ci passa lo spazzolone. E' anche l'unico modo
# che gli resta di sembrare piu' grande: la larghezza e' bloccata fra il passaggio
# davanti al lavabo e l'anta dell'armadio, e senza larghezza non c'e' altezza -
# `posa_modello` scala tutto insieme.
STACCO_TERMO = 0.10

# Chi arriva bianco di fabbrica e va portato all'eta' degli altri. Il water e il
# lavabo no: quelli si sono trovati gia' segnati, ed e' meglio lo sporco vero di
# chi li ha fatti che una tinta uniforme passata sopra.
# NESSUNO. C'era il bidet, e invecchiarlo e' stato un errore: arrivava a 227 su 255
# - l'unico dei tre gia' bianco - e moltiplicarlo per una tinta calda lo ha portato a
# 186 con una dominante, cioe' l'ha reso il piu' scuro dei tre. In una stanza sola tre
# ceramiche devono essere lo STESSO bianco, e quel bianco lo pareggia
# `tools/pareggia_ceramica.py` sulle mappe, dove si puo' anche schiarire.
INVECCHIARE = ()

# Il bianco a cui stanno tutte le ceramiche, letto da chi lo decide invece che
# ricopiato: due numeri uguali in due file diventano due numeri diversi.
BIANCO = float(__import__("re").search(
    r"^BERSAGLIO = ([\d.]+)",
    io.open(os.path.join(QUI, "pareggia_ceramica.py"), encoding="utf-8").read(),
    __import__("re").M).group(1))

mancanti = []

# I pezzi di ogni sanitario montato, per poterne misurare il bianco alla fine.
MONTATI = {}


# --- il guscio: piastrelle, listello, pavimento ------------------------------
def riveste():
    """Il rivestimento a mezza altezza, con i vani lasciati liberi."""
    # ovest ed est, per tutta la lunghezza
    scatola("PiastrelleMuro", X0, X0 + SPESS, 0.0, RIV, Z0, Z1)
    scatola("PiastrelleMuro", X1 - SPESS, X1, 0.0, RIV, Z0, Z1)
    # nord: due tratti, di qua e di la' dalla porta
    for (xa, xb) in ((X0, PORTA[0]), (PORTA[1], X1)):
        scatola("PiastrelleMuro", xa, xb, 0.0, RIV, Z0, Z0 + SPESS)
    # sud: tutto fino al davanzale, e sopra il davanzale solo ai lati della finestra
    scatola("PiastrelleMuro", X0, X1, 0.0, W_SILL, Z1 - SPESS, Z1)
    for (xa, xb) in ((X0, FINESTRA[0]), (FINESTRA[1], X1)):
        scatola("PiastrelleMuro", xa, xb, W_SILL, RIV, Z1 - SPESS, Z1)


def listello():
    """La fascia decorativa che chiude il rivestimento, e sporge di un centimetro.

    SPORGE APPOSTA. A filo del rivestimento sarebbe un disegno stampato sul muro;
    sporgendo di dieci millimetri prende una riga d'ombra sotto e una luce sopra, e
    diventa un pezzo di ceramica incollato li'. E' la stessa lezione delle nervature
    della porta del magazzino, dove otto millimetri non bastavano a farsi vedere.
    """
    y0, y1 = RIV - LIST, RIV
    s = SPESS + SPORGE
    scatola("Listello", X0, X0 + s, y0, y1, Z0, Z1)
    scatola("Listello", X1 - s, X1, y0, y1, Z0, Z1)
    for (xa, xb) in ((X0, PORTA[0]), (PORTA[1], X1)):
        scatola("Listello", xa, xb, y0, y1, Z0, Z0 + s)
    # sul muro sud il listello passa alla quota della finestra: si interrompe nel vano
    for (xa, xb) in ((X0, FINESTRA[0]), (FINESTRA[1], X1)):
        scatola("Listello", xa, xb, y0, y1, Z1 - s, Z1)


def pavimento():
    """Il gres beige, sopra il pavimento della stanza."""
    scatola("PiastrellePav", X0, X1, 0.0, 0.012, Z0, Z1)


# --- l'armadio di servizio ---------------------------------------------------
def armadio():
    """Armadio di lamiera a due ante, nell'angolo dove stava la doccia.

    In un osservatorio il bagno di servizio non ha la doccia: ha il posto dove
    stanno i detersivi, i ricambi e il camice. Un armadio da spogliatoio in lamiera
    verniciata dice quello, e lo dice con tre dettagli che sono geometria:
    le FERITOIE in alto (un armadio chiuso senza sfiato ammuffisce, e chi li fa lo
    sa), le maniglie VERTICALI a bastone, e lo zoccolo che lo stacca dal pavimento
    bagnato. Senza quei tre, una scatola grigia e' una scatola grigia.
    """
    _xi, z0, x1, z1, alto = impronta_utile("Armadio")
    x0 = filo_anta("armadio bagno 1")[0]   # dove batte l'anta: la cassa sta dietro
    zoccolo = 0.10
    M = "Armadietto"
    # LA CASSA, E GLI ASSI VANNO GUARDATI DUE VOLTE. L'armadio e' addossato alla
    # parete est: la SCHIENA sta a x alto, la FRONTE a x basso, e i FIANCHI sono i
    # due piani a z costante. Alla prima stesura fianchi e fronte si erano scambiati
    # di posto e ne era uscito un armadio aperto di lato, con le ante appiccicate
    # sopra il pannello che avrebbero dovuto essere.
    for (za, zb) in ((z0, z0 + 0.02), (z1 - 0.02, z1)):          # fianchi
        scatola(M, x0, x1, zoccolo, alto, za, zb)
    scatola(M, x1 - 0.02, x1, zoccolo, alto, z0, z1)             # schiena
    for (b, d) in ((zoccolo, zoccolo + 0.02), (alto - 0.02, alto)):
        scatola(M, x0, x1, b, d, z0, z1)                         # fondo e cielo
    # TRE RIPIANI, non piu' uno. Con le ante incollate davanti se ne intravedeva uno
    # solo dalla fessura, e uno bastava; adesso le ante si aprono e dentro si guarda.
    # Un armadio di servizio con un ripiano solo e un metro e mezzo di vuoto sopra
    # non e' un armadio di servizio, e' una scatola.
    for y in (0.55, 1.05, 1.55):
        scatola(M, x0 + 0.02, x1 - 0.02, y, y + 0.018, z0 + 0.02, z1 - 0.02)
    # lo zoccolo rientrato: un armadio a filo pavimento sembra incollato
    scatola(M, x0 + 0.04, x1 - 0.04, 0.0, zoccolo, z0 + 0.04, z1 - 0.04)

    # LE DUE ANTE NON STANNO PIU' QUI. Con feritoie, maniglie a bastone e serratura
    # se ne sono andate in `ANTE_MOBILI`, e in gioco sono due nodi `Door` che girano
    # sul cardine. Restava un dettaglio da salvare: la battuta contro cui chiudono,
    # senza la quale ad ante chiuse si vede la fessura fino in fondo al mobile.
    meta = (z0 + z1) / 2
    scatola(M, x0, x0 + 0.012, zoccolo + 0.02, alto - 0.02, meta - 0.010, meta + 0.010)


# --- il mobiletto e lo specchio ----------------------------------------------
def filo_anta(nome):
    """Dove batte l'anta di un mobile: il piano oltre il quale la cassa non va.

    LO LEGGE DALLA TABELLA CHE GENERA ANCHE IL NODO IN GIOCO. Cassa e anta le
    disegnano due programmi diversi - il mobile qui, l'anta il generatore della
    scena - e se il numero fosse scritto due volte, prima o poi sarebbero due
    numeri: la cassa avanzerebbe di qualche millimetro e l'anta ci sparirebbe
    dentro, oppure resterebbe una fessura da cui si vede il muro.

    Torna la coppia (x, z) del piano; si usa la componente che serve.
    """
    for a in ante_mobili():
        if a["nome"] == nome:
            (px, _py, pz), (ax, _ay, az) = a["perno"], a["normale"]
            T = a["spessore"]
            return (px - ax * T / 2.0, pz - az * T / 2.0)
    raise KeyError("anta sconosciuta: %s" % nome)


def pensile():
    """Appeso al muro nord: noce scuro. L'ANTA NON STA QUI.

    Un pezzo che ruota non puo' stare nel modello: il .glb e' una mesh sola, e
    l'anta ha bisogno di un nodo suo con l'origine sul cardine. Sta in
    `ANTE_MOBILI` di geometria.py insieme a quelle delle porte, e in gioco diventa
    un nodo `Door` come tutti gli altri.

    E TOLTA L'ANTA, IL MOBILE VA SVUOTATO. Finche' l'anta era incollata davanti, la
    cassa poteva essere un blocco pieno e non se ne accorgeva nessuno; aprendola si
    vedrebbe il pieno. Fianchi, schiena, cielo, fondo e un ripiano - che e' anche
    l'unica cosa che rende l'apertura interessante.

    IL MURO NON E' NE' A z0 NE' A x0: li' c'e' la piastrella - ma quell'arretramento
    non si fa piu' qui. Lo fa `geometria.impronta_utile()`, su ogni lato che tocchi
    un muro, perche' fatto a mano e' stato dimenticato tre volte di fila: prima la
    schiena, poi il fianco ovest, poi il fianco sud dell'armadio.

    FUORI IL LEGNO, DENTRO IL BIANCO. Aperto, il pensile mostrava un buco nero con
    dentro un ripiano nero, e la colpa non era della luce: la cassa era di
    `LegnoTeche`, la mappa piu' scura del progetto (65 su 255), e dentro un pensile
    la luce non entra comunque. Un mobile di quegli anni e' impiallacciato fuori e
    melamminico bianco dentro - e quella verita' e' anche quello che rende
    l'apertura leggibile.
    """
    x0, z0, x1, z1, alto = impronta_utile("Pensile")
    basso, cima = 1.45, alto
    zf = filo_anta("pensile bagno")[1]
    S, L = 0.018, 0.004       # spessore della cassa, e del rivestimento interno
    M, D = "LegnoBagno", "InternoMobile"
    for (a, b) in ((x0, x0 + S), (x1 - S, x1)):          # fianchi
        scatola(M, a, b, basso, cima, z0, zf)
    for (a, b) in ((basso, basso + S), (cima - S, cima)):  # fondo e cielo
        scatola(M, x0, x1, a, b, z0, zf)
    scatola(M, x0, x1, basso, cima, z0, z0 + 0.010)      # schiena, di fuori
    # e il vano dentro, foderato: schiena, fianchi, cielo e fondo
    ix0, ix1, iy0, iy1 = x0 + S, x1 - S, basso + S, cima - S
    scatola(D, ix0, ix1, iy0, iy1, z0 + 0.010, z0 + 0.010 + L)
    for (a, b) in ((ix0, ix0 + L), (ix1 - L, ix1)):
        scatola(D, a, b, iy0, iy1, z0 + 0.014, zf)
    for (a, b) in ((iy0, iy0 + L), (iy1 - L, iy1)):
        scatola(D, ix0, ix1, a, b, z0 + 0.014, zf)
    mezzo = (basso + cima) / 2
    scatola(D, ix0, ix1, mezzo - 0.008, mezzo + 0.008, z0 + 0.014, zf - 0.004)
    dentro_il_pensile(ix0, ix1, iy0 + L, mezzo + 0.008, z0 + 0.014, zf - 0.004)


def dentro_il_pensile(x0, x1, ripiano_basso, ripiano_alto, z0, z1):
    """Quello che ci sta dentro: e' un bagno di servizio, non una vetrina.

    UN PENSILE VUOTO E' UN PENSILE CHE NON VALE LA PENA APRIRE. Il meccanismo puo'
    essere perfetto - e lo e', il banco lo misura - ma se dietro l'anta non c'e'
    niente, aprirla e' una cosa che si fa una volta. Quattro oggetti bastano, e
    devono essere QUATTRO OGGETTI DI QUEL POSTO: in un osservatorio, nel pensile
    del bagno, ci stanno l'alcol, una scatola di garze, il sapone di scorta e i
    rotoli. Non un set da toeletta.
    """
    zc = (z0 + z1) / 2
    # sul ripiano basso: la bottiglia di alcol e il flacone del sapone
    cilindro("Alcol", x0 + 0.07, zc, ripiano_basso, ripiano_basso + 0.19, 0.032, seg=12)
    cilindro("Flacone", x0 + 0.07, zc, ripiano_basso + 0.19, ripiano_basso + 0.215, 0.014, seg=8)
    scatola("Flacone", x0 + 0.15, x0 + 0.21, ripiano_basso, ripiano_basso + 0.14,
            zc - 0.028, zc + 0.028)
    # la scatola di garze, coricata
    scatola("Cartone", x0 + 0.26, x0 + 0.40, ripiano_basso, ripiano_basso + 0.075,
            zc - 0.045, zc + 0.045)
    # sul ripiano alto: due rotoli in piedi
    for k in (0, 1):
        cilindro("Rotolo", x0 + 0.09 + k * 0.13, zc, ripiano_alto + 0.008,
                 ripiano_alto + 0.108, 0.055, seg=14)


def sopra_il_lavabo():
    """Sopra il lavabo NON C'E' NIENTE, e ci sono voluti due giri per arrivarci.

    Qui stavano uno specchio con la cornice, una mensola di cristallo, i suoi due
    reggi-mensola e un'applique. Tutti e quattro tolti su richiesta, e la richiesta
    ha ragione: e' il bagno di servizio di un osservatorio, non una stanza da bagno
    di casa. I due reggi-mensola in particolare erano il sintomo - da un metro e
    mezzo non si capiva cosa fossero, e un oggetto che non si riconosce e' un oggetto
    che non serve.

    Lo specchio in stanza c'e' lo stesso: e' l'anta del pensile.

    La funzione resta, vuota, perche' la sua chiamata nella costruzione dice DOVE
    guardare se un giorno sopra il lavabo dovra' tornarci qualcosa.
    """
    return


def portasalviette():
    """La barra e l'asciugamano piegato in due, che e' l'unico colore della stanza."""
    x0, z0, x1, z1, _alto = IMPRONTE["Portasalv"]
    xf = x0 + SPESS + SPORGE
    barra = 1.22
    for zz in (z0 + 0.05, z1 - 0.05):
        cilindro("Cromo", xf + 0.04, zz, 1.05, barra, 0.010, seg=8)
    cilindro_orizz("Cromo", xf + 0.04, barra, (z0 + z1) / 2, "z", z1 - z0 - 0.10,
                   0.010, seg=10)
    asciugamano(xf + 0.04, barra, (z0 + z1) / 2, z1 - z0 - 0.20)


def asciugamano(x, barra, cz, largo):
    """Un telo piegato sulla barra, NON una lastra.

    Prima era una scatola: quattro centimetri di spessore, spigoli vivi, e da vicino
    si vedeva un rettangolo verde appoggiato al muro. Un asciugamano appeso ha tre
    cose che una scatola non ha, e sono tutte e tre geometria:

      * LA PIEGA sopra la barra, che e' un mezzo tubo e non uno spigolo;
      * DUE FALDE di lunghezza diversa - chi lo appende non le pareggia mai - e
        quella davanti copre quella dietro;
      * L'ONDA. Un telo appeso non e' piano: si gonfia dove pende e rientra dove il
        peso lo tira. Qui sono cinque strisce con la faccia spostata di pochi
        millimetri una dall'altra, ed e' quel poco che lo fa leggere come stoffa.
    """
    M = "Spugna"
    sp = 0.008
    # la piega sopra la barra
    cilindro_orizz(M, x, barra, cz, "z", largo, 0.016, seg=10)
    n = 5
    passo = largo / n
    for k in range(n):
        za = cz - largo / 2 + passo * k
        zb = za + passo - 0.002
        # l'onda: le strisce si spostano avanti e indietro di pochi millimetri
        onda = 0.006 * (1 if k % 2 == 0 else -1)
        # davanti, piu' lunga
        scatola(M, x - 0.016 + onda, x - 0.016 + onda + sp, 0.83, barra, za, zb)
        # dietro, piu' corta e senza onda: sta appoggiata al muro
        scatola(M, x + 0.010, x + 0.010 + sp, 0.90, barra, za, zb)
    # il bordo inferiore, un filo piu' spesso: e' l'orlo cucito
    scatola(M, x - 0.018, x - 0.018 + sp + 0.004, 0.83, 0.845,
            cz - largo / 2, cz + largo / 2)


def termosifone():
    """Il radiatore scaricato se c'e', quello fatto a mano se no.

    IL SEGNAPOSTO QUI ERA GIA' BUONO - centoventi cilindri, i cappelli, i nippli, la
    valvola - e resta, perche' e' quello che regge se il modello non c'e'. Ma un
    radiatore di ghisa e' fatto di ruggine e smalto scrostato attorno alla valvola,
    e quella e' TEXTURE: a mano si puo' fare la forma, non i sessant'anni.
    """
    via = os.path.join(ESTERNI, "termosifone_bagno", "scene.gltf")
    if not os.path.exists(via):
        termosifone_segnaposto()
        mancanti.append("Termo (il termosifone) - manca %s" % via)
        print("  Termo    SEGNAPOSTO: il modello non c'e' ancora")
        return
    pezzi = posa_modello(via, IMPRONTE["Termo"], gradi=GRADI_TERMO,
                         appoggio=STACCO_TERMO)
    girate = raddrizza_normali(pezzi)
    if girate:
        print("  Termo    %d facce avevano la normale al contrario" % girate)
    # METALLICO A ZERO ANCHE QUI, e stavolta il glTF non lo dichiara nemmeno: quando
    # `metallicFactor` manca il valore predefinito e' UNO, cioe' metallo pieno. Un
    # metallo in una stanza chiusa riflette il nero dell'ambiente ed esce nero - la
    # stessa trappola dello specchio, della porta del magazzino e dei sanitari.
    usa_le_ridotte(pezzi, os.path.dirname(via), metallico=0.0)
    print("  Termo    dal modello scaricato")


def termosifone_segnaposto():
    """Radiatore di GHISA A COLONNE, che e' quello che stava in un bagno di allora.

    Prima era fatto di lastre piatte, ed era un radiatore d'acciaio a piastre: quelli
    sono degli anni Duemila. Il ghisa a colonne si riconosce da tre cose, e sono tutte
    e tre geometria:

      * LE COLONNE SONO TONDE, due per elemento, e si vedono una per una. Le piastre
        d'acciaio sono un muro liscio, la ghisa e' una fila di tubi.
      * OGNI ELEMENTO HA IL SUO CAPPELLO in cima e il suo piede: non e' un pannello
        unico, sono pezzi imbullonati uno accanto all'altro, e il profilo a onda che
        ne esce e' la firma del radiatore di ghisa.
      * I NIPPLI FRA UN ELEMENTO E L'ALTRO, cioe' i raccordi filettati che li tengono
        insieme. Sono piccoli e sono quello che dice "questo si smonta".

    Piu' la valvola da una parte, il detentore dall'altra e lo sfiato in cima: un
    radiatore senza rubinetti e' un mobile.
    """
    x0, z0, x1, z1, alto = IMPRONTE["Termo"]
    M = "Radiatore"
    piede, cima = 0.14, alto - 0.04
    # sta staccato dal muro: dietro un termosifone ci passa la mano
    zc = z1 - 0.115
    passo_z = 0.075                       # le due colonne di uno stesso elemento
    za, zb = zc - passo_z / 2, zc + passo_z / 2

    n = 12
    larghezza = x1 - x0 - 0.10
    passo = larghezza / (n - 1.0)
    for k in range(n):
        x = x0 + 0.05 + passo * k
        for zz in (za, zb):
            cilindro(M, x, zz, piede, cima, 0.026, seg=10)
        # il cappello e il piede dell'elemento: uniscono le due colonne, e il loro
        # profilo affiancato fa l'onda che si riconosce da lontano
        for (y0, y1) in ((cima - 0.045, cima + 0.010), (piede - 0.010, piede + 0.045)):
            cilindro_orizz(M, x, (y0 + y1) / 2, zc, "z", passo_z + 0.052,
                           (y1 - y0) / 2, seg=10)
        # il nipplo verso l'elemento successivo
        if k < n - 1:
            for zz in (za, zb):
                cilindro_orizz(M, x + passo / 2, (piede + cima) / 2, zz, "x",
                               passo - 0.052, 0.016, seg=8)

    # i due collettori, che attraversano tutto: sono quelli che portano l'acqua
    for y in (cima - 0.018, piede + 0.018):
        for zz in (za, zb):
            cilindro_orizz(M, (x0 + x1) / 2, y, zz, "x", larghezza + 0.10, 0.018, seg=8)

    # i piedini
    for xx in (x0 + 0.10, x1 - 0.10):
        scatola(M, xx - 0.022, xx + 0.022, 0.0, piede - 0.005, zc - 0.05, zc + 0.05)

    # LA VALVOLA e il detentore, uno per capo, e lo sfiato in cima. Sono i tre pezzi
    # che dicono che ci passa dentro dell'acqua.
    cilindro("Cromo", x0 + 0.02, zc, piede + 0.010, piede + 0.075, 0.020, seg=10)
    cilindro_orizz("Cromo", x0 - 0.01, piede + 0.018, zc, "x", 0.06, 0.014, seg=8)
    cilindro("Cromo", x0 + 0.02, zc, piede + 0.075, piede + 0.115, 0.026, seg=10)
    cilindro("Cromo", x1 - 0.02, zc, piede + 0.010, piede + 0.070, 0.018, seg=10)
    cilindro_orizz("Cromo", x1 + 0.01, piede + 0.018, zc, "x", 0.06, 0.014, seg=8)
    cilindro_orizz("Cromo", x1 - 0.03, cima - 0.010, zc, "x", 0.035, 0.010, seg=8)


# --- i sanitari: da fuori se ci sono, segnaposto se no ------------------------
def wc_segnaposto():
    x0, z0, x1, z1, _a = IMPRONTE["Wc"]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    # la tazza: due tronchi di cono sovrapposti, che e' il minimo per non sembrare
    # una scatola. Non e' un water: e' il posto dove ne andra' uno.
    cilindro("CeramicaVecchia", cx + 0.04, cz, 0.0, 0.20, 0.11, seg=12, r2=0.15)
    cilindro("CeramicaVecchia", cx + 0.04, cz, 0.20, 0.40, 0.15, seg=12, r2=0.18)
    scatola("Bianco", x0 + 0.06, x1 - 0.14, 0.40, 0.43, z0 + 0.02, z1 - 0.02)
    # la cassetta appoggiata, che nel 1999 era ancora la norma
    scatola("CeramicaVecchia", x1 - 0.20, x1, 0.43, 0.80, z0 + 0.03, z1 - 0.03)
    cilindro("Cromo", x1 - 0.10, cz, 0.80, 0.82, 0.022, seg=10)


def bidet_segnaposto():
    x0, z0, x1, z1, _a = IMPRONTE["Bidet"]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    cilindro("CeramicaVecchia", cx + 0.03, cz, 0.0, 0.22, 0.09, seg=12, r2=0.14)
    cilindro("CeramicaVecchia", cx + 0.03, cz, 0.22, 0.40, 0.14, seg=12, r2=0.17)
    cilindro("Cromo", x1 - 0.07, cz, 0.40, 0.52, 0.018, seg=10)
    cilindro_orizz("Cromo", x1 - 0.13, 0.51, cz, "x", 0.09, 0.012)


def rubinetto_lavabo(quota):
    """Il miscelatore sopra il lavabo, che nel modello scaricato NON c'e'.

    Il lavabo d'epoca arriva col solo foro: la rubinetteria e' un pezzo a parte in
    quasi tutti i modelli di sanitari, e un lavabo senza rubinetto e' una vasca. Sta
    qui e non dentro il segnaposto proprio per questo - serve in tutti e due i casi,
    e messo dentro il segnaposto sarebbe sparito il giorno in cui il modello e'
    arrivato.

    MONOCOMANDO e non due rubinetti separati: nel 1999 il miscelatore aveva gia'
    sostituito la coppia acqua calda / acqua fredda, che e' di vent'anni prima.
    """
    x0, z0, x1, z1, _a = IMPRONTE["Lavabo"]
    cz = (z0 + z1) / 2
    xr = x0 + 0.10
    cilindro("Cromo", xr, cz, quota, quota + 0.15, 0.021, seg=10)
    # il becco sporge 14 cm sopra il bacino: a dieci restava dentro il bordo del
    # lavabo e da fermi davanti si vedeva solo il corpo del miscelatore
    cilindro_orizz("Cromo", xr + 0.075, quota + 0.145, cz, "x", 0.15, 0.013)
    # la leva, inclinata all'indietro come sta una leva alzata a meta'
    scatola("Cromo", xr - 0.012, xr + 0.014, quota + 0.15, quota + 0.185,
            cz + 0.008, cz + 0.055)


def lavabo_segnaposto():
    x0, z0, x1, z1, _a = IMPRONTE["Lavabo"]
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    # la colonna
    cilindro("CeramicaVecchia", cx, cz, 0.0, 0.72, 0.09, seg=12, r2=0.11)
    # il catino: fondo e quattro sponde, che e' come si fa un lavabo con le scatole
    scatola("CeramicaVecchia", x0, x1 - 0.02, 0.72, 0.78, z0 + 0.02, z1 - 0.02)
    for (a, b, c, d) in ((x0, z0 + 0.02, x1 - 0.02, z0 + 0.06),
                         (x0, z1 - 0.06, x1 - 0.02, z1 - 0.02),
                         (x1 - 0.06, z0 + 0.02, x1 - 0.02, z1 - 0.02)):
        scatola("CeramicaVecchia", a, c, 0.78, 0.86, b, d)
    scatola("CeramicaVecchia", x0, x0 + 0.09, 0.78, 0.88, z0 + 0.02, z1 - 0.02)
    # il miscelatore lo mette rubinetto_lavabo(), che serve anche al modello vero


def bianco_ceramica(pezzi, su255):
    """Porta al bianco voluto un sanitario che il colore ce l'ha NEL MATERIALE.

    Non tutti i modelli portano una mappa: questo lavabo ha tre materiali a tinta
    piatta e nessuna texture, quindi `pareggia_ceramica.py` - che lavora sui file
    delle mappe - non ha niente da correggere. Il pareggio va fatto qui, e per
    fortuna e' anche piu' semplice: senza mappa il colore di base non e' un fattore
    che moltiplica qualcosa, e' IL colore, e glielo si scrive.

    QUAL E' LA CERAMICA FRA I TRE. Quello con piu' facce: il corpo di un lavabo ha
    dieci volte i triangoli del suo rubinetto. Gli altri sono rubinetteria e restano
    del loro colore.

    E IL BIANCO SI CONVERTE IN LINEARE. Blender lavora in lineare e i 212 su 255
    sono in sRGB: scritti tali e quali darebbero una ceramica molto piu' chiara del
    dovuto. E' lo stesso scarto - fattore 2,4 - che ha gia' fatto uscire l'anta del
    magazzino a meta' della tinta del suo telaio.

    METALLICITA' A ZERO SU TUTTO, e qui non e' pignoleria. In glTF `metallicFactor`
    vale 1.0 se non e' dichiarato, e due dei tre materiali di questo lavabo non lo
    dichiarano: arriverebbero metallici pieni e lisci come uno specchio. In una
    stanza chiusa senza niente da riflettere, uno specchio e' NERO - il difetto piu'
    ricorrente di questo progetto, e questa e' la quinta volta.
    """
    c = su255 / 255.0
    lineare = (c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    conta = {}
    for o in pezzi:
        if o.type != "MESH" or o.data is None:
            continue
        for slot in o.material_slots:
            if slot.material is not None:
                conta[slot.material] = conta.get(slot.material, 0) + len(o.data.polygons)
    if not conta:
        return
    corpo = max(conta, key=conta.get)
    for m in conta:
        if not m.use_nodes:
            continue
        for n in m.node_tree.nodes:
            if n.type != "BSDF_PRINCIPLED":
                continue
            n.inputs["Metallic"].default_value = 0.0
            if m is corpo and not n.inputs["Base Color"].is_linked:
                n.inputs["Base Color"].default_value = (lineare, lineare, lineare, 1.0)
                n.inputs["Roughness"].default_value = 0.25
            else:
                # la rubinetteria: senza metallicita' serve un po' di ruvidezza, o
                # resta una plastica grigia troppo lucida
                r = n.inputs["Roughness"]
                r.default_value = max(0.30, r.default_value)


def ingiallisci(pezzi, tinta):
    """Da' vent'anni a una ceramica che arriva nuova di fabbrica.

    Il water e il lavabo si sono trovati gia' segnati; il bidet no, e di bidet
    vecchi non ne esiste nemmeno uno con licenza libera. Non e' un caso: il bidet e'
    un oggetto italiano e francese e le librerie 3D sono anglosassoni. Accanto a due
    sanitari ingialliti, un bidet bianco di fabbrica sarebbe l'unica cosa nuova della
    stanza - e in una stanza dove tutto ha vent'anni, l'unica cosa nuova e' quella
    che si nota.

    SI MOLTIPLICA la mappa colore per una tinta calda, non la si sostituisce: quella
    mappa porta le ombre e i dettagli del modello, e buttarla via per un colore
    piatto sarebbe un peggioramento travestito da invecchiamento. E' lo stesso nodo
    Mix in MULTIPLY che `modellare.applica_texture` usa per i dorsi dei libri, e
    l'esportatore glTF lo sa tradurre.
    """
    fatti = set()
    for o in pezzi:
        for slot in getattr(o, "material_slots", []):
            m = slot.material
            if m is None or m.name in fatti or not m.use_nodes:
                continue
            fatti.add(m.name)
            nt = m.node_tree
            bsdf = None
            for n in nt.nodes:
                if n.type == "BSDF_PRINCIPLED":
                    bsdf = n
                    break
            if bsdf is None:
                continue
            base = bsdf.inputs["Base Color"]
            if base.is_linked:
                sorgente = base.links[0].from_socket
                mix = nt.nodes.new("ShaderNodeMix")
                mix.data_type = "RGBA"
                mix.blend_type = "MULTIPLY"
                mix.inputs["Factor"].default_value = 1.0
                mix.inputs[6].default_value = (tinta[0], tinta[1], tinta[2], 1.0)
                nt.links.new(mix.inputs[7], sorgente)
                nt.links.new(base, mix.outputs[2])
            else:
                c = base.default_value
                base.default_value = (c[0] * tinta[0], c[1] * tinta[1],
                                      c[2] * tinta[2], 1.0)
            # e lo smalto perde il lucido, che e' meta' di quello che lo fa vecchio
            r = bsdf.inputs["Roughness"]
            r.default_value = max(0.38, r.default_value)
    return pezzi


def sanitari():
    """Monta i modelli scaricati; dove mancano mette il segnaposto e lo dice."""
    fatti = {"Wc": wc_segnaposto, "Bidet": bidet_segnaposto,
             "Lavabo": lavabo_segnaposto}
    for (cartella, quale, gradi, alto, come_si_chiama) in SANITARI:
        via = os.path.join(ESTERNI, cartella, "scene.gltf")
        x0, z0, x1, z1, _h = IMPRONTE[quale]
        # BOCCIATO DA `pareggia_ceramica.py`: si torna al segnaposto. Un modello
        # sbagliato che resta montato e' peggio di un segnaposto - il segnaposto si
        # vede che e' provvisorio, il modello sbagliato sembra una scelta.
        bocciato = os.path.exists(os.path.join(ESTERNI, cartella, "DA_SOSTITUIRE.txt"))
        if os.path.exists(via) and not bocciato:
            pezzi = posa_modello(via, (x0, z0, x1, z1, alto), gradi=gradi)
            MONTATI[quale] = pezzi
            girate = raddrizza_normali(pezzi)
            if girate:
                print("  %-8s %d facce avevano la normale al contrario" % (quale, girate))
            # LE MAPPE RIDOTTE, e la metallicita' a zero. Una ceramica non e' un
            # metallo: la mappa metallicRoughness dei sanitari, presa com'e', la
            # farebbe specchiare, e in un bagno chiuso lo specchio e' nero.
            fatte = usa_le_ridotte(pezzi, os.path.dirname(via), metallico=0.0)
            if fatte == 0:
                # nessuna mappa da sostituire: il colore sta nel materiale, e il
                # pareggio va fatto li'
                bianco_ceramica(pezzi, BIANCO)
            if quale in INVECCHIARE:
                ingiallisci(pezzi, COLORI["CeramicaVecchia"])
                print("  %-8s dal modello scaricato, invecchiato qui" % quale)
            else:
                print("  %-8s dal modello scaricato" % quale)
        else:
            fatti[quale]()
            # IL RUBINETTO SOLO COL SEGNAPOSTO. Il modello scaricato il suo
            # miscelatore ce l'ha, e aggiungerne un secondo ne lascerebbe due nello
            # stesso foro. Serviva col lavabo precedente, che arrivava senza.
            if quale == "Lavabo":
                rubinetto_lavabo(0.86)
            if bocciato:
                print("  %-8s SEGNAPOSTO: il modello scaricato e' stato bocciato" % quale)
                mancanti.append("%s (%s) - il modello scaricato e' stato BOCCIATO, "
                                "vedi %s/DA_SOSTITUIRE.txt" % (quale, come_si_chiama,
                                                               cartella))
            else:
                print("  %-8s SEGNAPOSTO: il modello non c'e' ancora" % quale)
                mancanti.append("%s (%s) - manca %s" % (quale, come_si_chiama, via))


def prova_ingiallisci():
    """`ingiallisci` scattera' fra giorni, quando il bidet sara' stato scaricato.

    Provata oggi, su un cubo di prova: si costruisce un materiale con la texture
    delle piastrelle, lo si invecchia e si controlla che il Base Color sia passato
    per un nodo Mix in MULTIPLY. Un pezzo di codice che nessuno esegue e' un pezzo di
    codice che non funziona, e questo qui non lo eseguirebbe nessuno fino al giorno
    in cui serve - cioe' il giorno peggiore per scoprire che sbaglia il nome di un
    socket.
    """
    from modellare import materiale
    mesh = bpy.data.meshes.new("_provaMesh")
    o = bpy.data.objects.new("_prova", mesh)
    bpy.context.collection.objects.link(o)
    m = materiale("PiastrelleMuro").copy()
    m.name = "_provaMat"
    o.data.materials.append(m)
    ingiallisci([o], (0.5, 0.4, 0.3))
    base = None
    for n in m.node_tree.nodes:
        if n.type == "BSDF_PRINCIPLED":
            base = n.inputs["Base Color"]
    esito = []
    if base is None or not base.is_linked:
        esito.append("ingiallisci: il Base Color non e' rimasto collegato")
    else:
        nodo = base.links[0].from_node
        if nodo.type != "MIX" or nodo.blend_type != "MULTIPLY":
            esito.append("ingiallisci: davanti al Base Color c'e' %s, non un Mix "
                         "in MULTIPLY" % nodo.type)
        elif tuple(round(v, 3) for v in nodo.inputs[6].default_value)[:3] != (0.5, 0.4, 0.3):
            esito.append("ingiallisci: la tinta non e' finita nel socket giusto")
    bpy.data.objects.remove(o, do_unlink=True)
    return esito


def quanto_e_chiara(mappa):
    """La luminosita' media di un'immagine, su 255 e IN sRGB.

    Il Python di Blender non ha PIL, quindi si legge con Blender - e li' `pixels`
    restituisce valori LINEARI, perche' e' quello che serve a un motore di render.
    Mediare quelli e confrontarli con i numeri di `pareggia_ceramica.py`, che legge i
    byte del file, darebbe due misure diverse della stessa immagine: la media di una
    ceramica chiara scenderebbe di una quarantina di livelli e il controllo
    accuserebbe un difetto che non c'e'. Ogni pixel si riporta in sRGB PRIMA di
    mediare.

    E NON SI RIDIMENSIONA L'IMMAGINE. Il primo tentativo la portava a 64x64 per
    fare in fretta, e misurava 234 dove `pareggia_ceramica.py` misura 212 sulla
    stessa mappa: `img.scale()` media in spazio LINEARE, e la media lineare di
    valori sparsi, riportata in sRGB, viene piu' chiara della media dei valori sRGB.
    Il controllo accusava due ceramiche perfettamente pareggiate. Si campiona invece
    un pixel ogni cento, che e' altrettanto veloce e non tocca i valori.
    """
    import array
    img = bpy.data.images.load(mappa, check_existing=False)
    # NON-COLOR, E POI NESSUNA CONVERSIONE. Cosi' `pixels` restituisce i byte del
    # file normalizzati, che e' esattamente quello che legge PIL dall'altra parte.
    # Lasciandola in sRGB e riconvertendo a mano la stessa mappa misurava 234 invece
    # di 212 - una conversione applicata due volte - e il controllo accusava due
    # ceramiche perfettamente pareggiate.
    img.colorspace_settings.name = "Non-Color"
    w, h = img.size
    buf = array.array("f", [0.0]) * (w * h * 4)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    somma = 0.0
    n = 0
    for i in range(0, w * h, 97):
        for c in buf[i * 4:i * 4 + 3]:
            somma += max(0.0, min(1.0, c))
            n += 1
    return somma / max(1, n) * 255.0


def bianco_del_materiale(pezzi):
    """Il bianco di un sanitario che il colore ce l'ha nel materiale, riportato a 255.

    Si guarda il materiale del CORPO - quello con piu' facce, come in
    `bianco_ceramica` - e si riconverte il suo colore da lineare a sRGB, che e' la
    scala in cui parlano tutti gli altri numeri di questo controllo.
    """
    conta = {}
    for o in pezzi:
        if o.type != "MESH" or o.data is None:
            continue
        for slot in o.material_slots:
            if slot.material is not None:
                conta[slot.material] = conta.get(slot.material, 0) + len(o.data.polygons)
    if not conta:
        return None
    m = max(conta, key=conta.get)
    if not m.use_nodes:
        return None
    for n in m.node_tree.nodes:
        if n.type != "BSDF_PRINCIPLED" or n.inputs["Base Color"].is_linked:
            continue
        c = sum(n.inputs["Base Color"].default_value[:3]) / 3.0
        c = max(0.0, min(1.0, c))
        srgb = (c * 12.92 if c <= 0.0031308 else 1.055 * (c ** (1.0 / 2.4)) - 0.055)
        return srgb * 255.0
    return None


def ceramiche_pari():
    """I sanitari montati devono essere lo STESSO bianco.

    E' il controllo che nasce da una stanza in cui tre ceramiche prese da tre autori
    stavano a 227, 174 e 130 su 255. Nessuna delle tre era sbagliata da sola: era
    sbagliato averle insieme, e a occhio si vedeva solo che "qualcosa stona". Adesso
    `tools/pareggia_ceramica.py` le porta tutte a un bianco solo, e questo controllo
    verifica che ci siano rimaste - perche' un modello aggiunto domani, o uno
    riscaricato che sovrascrive la mappa corretta, tornerebbe a stonare in silenzio.
    """
    # IL BERSAGLIO SI LEGGE DAL SORGENTE, non importando il modulo:
    # `pareggia_ceramica.py` usa PIL, e il Python di Blender PIL non ce l'ha. Una
    # riga di regex evita di duplicare il numero in due file, che e' il modo sicuro
    # di ritrovarseli diversi fra sei mesi.
    import re
    sorgente = io.open(os.path.join(QUI, "pareggia_ceramica.py"),
                       encoding="utf-8").read()
    bersaglio = float(re.search(r"^BERSAGLIO = ([\d.]+)", sorgente, re.M).group(1))

    guai = []
    for (cartella, quale, _g, _a, _n) in SANITARI:
        if quale not in MONTATI:
            continue                     # segnaposto: e' roba nostra, gia' pari
        mappa = os.path.join(ESTERNI, cartella, "textures", "color.jpg")
        if os.path.exists(mappa):
            grigio = quanto_e_chiara(mappa)
        else:
            # SENZA MAPPA IL BIANCO STA NEL MATERIALE, e va misurato li'. Il primo
            # controllo saltava questi - `continue` se non c'era il file - e con il
            # lavabo nuovo, che di mappe non ne ha, verificava due sanitari su tre
            # dichiarando pari anche il terzo.
            grigio = bianco_del_materiale(MONTATI[quale])
            if grigio is None:
                continue
        print("  %-8s ceramica a %.0f su 255" % (quale, grigio))
        if abs(grigio - bersaglio) > 10.0:
            guai.append("%s: la ceramica sta a %.0f invece dei %.0f degli altri - "
                        "rilancia tools/pareggia_ceramica.py"
                        % (quale, grigio, bersaglio))
    return guai


# --- costruzione -------------------------------------------------------------
pulisci()
riveste()
listello()
pavimento()
armadio()
pensile()
sopra_il_lavabo()
portasalviette()
termosifone()
sanitari()

_prova = prova_ingiallisci()
oggetti = finisci(morbidi=("Ceramica", "CeramicaVecchia", "Cromo", "Radiatore"))

# IL GUSCIO NON HA IMPRONTA, ED E' GIUSTO COSI'. Rivestimento, listello e pavimento
# non sono arredi: sono uno strato di un centimetro incollato a superfici che la
# collisione ce l'hanno gia'. Dichiararli fra gli arredi darebbe quattro strisce che
# si sovrappongono a ogni sanitario addossato al muro - cioe' a tutti - e il
# controllo degli arredi si riempirebbe di guasti inventati.
GUSCIO = ("PiastrelleMuro", "PiastrellePav", "Listello")
problemi = _prova + ceramiche_pari() + verifica_impronte(
    [o for o in oggetti if o.name not in GUSCIO],
    [(x0, z0, x1, z1) for (x0, z0, x1, z1, _h) in IMPRONTE.values()])

ALTEZZA_STANZA = 3.00
_alto = max((o.matrix_world @ v.co).z for o in oggetti for v in o.data.vertices)
print("\n  il pezzo piu' alto arriva a %.2f m, il soffitto sta a %.2f"
      % (_alto, ALTEZZA_STANZA))
if _alto > ALTEZZA_STANZA:
    problemi.append("un arredo sfonda il soffitto: %.2f m" % _alto)

# IL RIVESTIMENTO DEVE ARRIVARE AL LISTELLO E FERMARSI LI'. Sembra ovvio e non lo e':
# basta cambiare RIV senza cambiare l'altezza del listello per ritrovarsi la fascia
# in mezzo alle piastrelle o staccata dal loro bordo, e in un render notturno non si
# distingue da un difetto della texture.
for o in oggetti:
    if o.name != "Listello":
        continue
    cima = max((o.matrix_world @ v.co).z for v in o.data.vertices)
    if abs(cima - RIV) > 1e-3:
        problemi.append("il listello chiude a %.3f invece che a %.3f" % (cima, RIV))

if problemi:
    print("\nATTENZIONE:")
    for p in problemi:
        print("  " + p)
    sys.exit(1)

esporta(USCITA)

# QUANTO PESA, RILETTO DAL FILE SCRITTO. Il bagno e' arrivato a 33 MB - piu'
# dell'intero edificio - perche' i tre sanitari restavano attaccati alle loro mappe
# a 4096 mentre le versioni ridotte stavano nella cartella accanto senza che nessuno
# le usasse. Non se ne accorgeva niente: il modello era giusto, i controlli passavano,
# e il numero lo si vede solo guardando la cartella. Adesso lo guarda lui.
PESO_MASSIMO = 20.0
_mb = os.path.getsize(USCITA) / 1048576.0
print("  il modello pesa %.1f MB" % _mb)
if _mb > PESO_MASSIMO:
    print("")
    print("ATTENZIONE: %.1f MB contro i %.1f ammessi - quasi sempre e' una mappa"
          % (_mb, PESO_MASSIMO))
    print("  presa da fuori e rimasta a piena risoluzione: vedi usa_le_ridotte().")
    sys.exit(1)

if mancanti:
    print("\nSANITARI ANCORA DA SCARICARE (adesso ci sono i segnaposto):")
    for m in mancanti:
        print("  " + m)

# --- render di controllo -----------------------------------------------------
scatta_su = prepara_render()
_osservatorio = os.path.join(RADICE, "assets", "models", "osservatorio.glb")
if os.path.exists(_osservatorio):
    bpy.ops.import_scene.gltf(filepath=_osservatorio)
lampada("Plafoniera", ((X0 + X1) / 2, 2.60, (Z0 + Z1) / 2), 90.0,
        tipo="AREA", dimensione=1.0)
lampada("Applique", (5.25, 1.86, 8.55), 8.0)


def scatta(nome, posizione, mira, lente=28.0):
    scatta_su(os.path.join(RENDER, nome), posizione, mira, lente)


# entrando dalla porta: si deve vedere la fila dei sanitari e il listello che corre
scatta("bagno.png", (5.90, 1.62, 8.80), (8.10, 0.75, 7.05), lente=24.0)
# il lavabo con lo specchio, dal centro della stanza
scatta("bagno-lavabo.png", (6.60, 1.62, 8.10), (5.05, 1.20, 8.55), lente=24.0)
# l'armadio e la finestra
scatta("bagno-armadio.png", (5.60, 1.62, 7.20), (7.90, 1.10, 9.20), lente=22.0)
# LA STESSA INQUADRATURA DELLO SCATTO IN GIOCO, per confrontare mela con mela: in
# Godot dentro il catino del lavabo compare una striscia nera a spigolo vivo, e
# finche' non si guarda lo stesso punto dallo stesso posto non si sa se e' un'ombra
# del motore o un pezzo di mesh che manca.
scatta("bagno-catino.png", (5.85, 1.30, 8.52), (4.98, 0.80, 8.52), lente=28.0)
# il termosifone sotto la finestra, da vicino: le colonne di ghisa si devono contare
scatta("bagno-termo.png", (6.10, 1.20, 8.30), (6.90, 0.45, 9.30), lente=30.0)
# il listello da vicino: e' il pezzo che data la stanza, va guardato
scatta("bagno-listello.png", (6.30, 1.55, 7.60), (8.10, 1.52, 7.30), lente=45.0)
