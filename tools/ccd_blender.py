# -*- coding: utf-8 -*-
"""La CAMERA CCD: SBIG ST-8 con la ruota filtri CFW-8 attaccata.

    "D:/programs/blender5/blender.exe" --background --python tools/ccd_blender.py

DA DOVE VIENE LA FORMA, e non e' inventata. Il GDD la nomina per modello - «SBIG
ST-8, chip KAF-1600 da 1530x1020 pixel di 9 micron, raffreddata a Peltier» piu' la
«SBIG CFW-8, cinque posizioni» - e dice anche che questo pezzo va modellato a mano
perche' lo si guarda da vicino. Le quote vengono dalla scheda SBIG di allora:

    testa ottica   5 pollici di diametro x 3 di profondita' = 12,5 x 7,5 cm
    peso           2,2 libbre / 1 kg
    raffreddamento Peltier a stadio singolo + VENTOLA sul retro, predisposta acqua
    attacco        T-Thread, nasi da 1,25" e 2" in dotazione
    back focus     0,92 pollici / 2,3 cm
    CFW-8          si avvita davanti, cinque filtri da 1,25", +1" di back focus

E LA FORMA VIENE DA TRE FOTOGRAFIE. La prima stesura ne aveva vista una sola, e la
camera era venuta un CILINDRO IN PIEDI SU UNA BASE QUADRATA: nel provino leggeva
come una scatola di biscotti. La ST-8 vera e' un'altra cosa, e le tre foto la
dicono tutta:

  1. Catalogo SBIG, tre quarti da davanti (Company Seven, `sbwgifs/ST-7.jpg`).
     Davanti c'e' una PIASTRA CIRCOLARE PIANA grande quanto tutta la camera, con
     sei brugole sul bordo; dietro di lei il pacco delle ALETTE ANULARI, un poco
     piu' strette della piastra; dietro ancora una SCATOLA QUADRATA - il vano
     dell'elettronica - i cui angoli SPORGONO dall'ingombro tondo. Il naso non e'
     al centro: e' decentrato di un paio di centimetri.
  2. La stessa camera montata su un C14 (Pedro Re', astrosurf.com/re/). E' l'unica
     che mostra il RETRO: una ventola tonda incassata, un'ETICHETTA BIANCA - che
     su un oggetto tutto nero e' la cosa che si vede per prima - e i connettori a
     vaschetta con i cavi che pendono da un fianco.
  3. Catalogo della CFW-8 (Company Seven, `sbig/images/cfw8.gif`). E' un DISCO
     PIATTO col bordo liscio, e da un lato sporge la GOBBA TONDA del motore passo
     passo. Il naso e' decentrato anche qui, e per un motivo meccanico: il disco
     gira attorno al proprio centro e l'asse ottico passa per UNA delle cinque
     posizioni, non per il perno.

NERO E NON GRIGIO: e' alluminio anodizzato nero, e a occhio legge come nero opaco.
Il corpo usa quindi `PlasticaNera` e non `Metallo` - non perche' sia plastica, ma
perche' quel materiale ha il colore e la ruvidezza giusti; il metallo lucido resta
alle brugole, ai connettori e al naso, che sono gli unici pezzi che brillano.
L'etichetta e' l'unico pezzo chiaro, ed e' il pezzo che salva l'oggetto: dodici
centimetri di nero opaco in una cupola al buio sono una macchia, con un rettangolo
bianco sopra sono uno strumento.

L'ORIGINE STA SUL PANNELLO POSTERIORE, con l'asse ottico in su. Posata su un piano
sta in piedi sulla ventola; per montarla al telescopio la si gira portando il
proprio +Y lungo l'uscita del focheggiatore, che il modello del telescopio dichiara
con un Empty (vedi `telescopio_blender.py`), e i novanta gradi che servono li mette
`world/interactables/ccd_camera.gd`.

LA RUOTA FILTRI E' MODELLATA INSIEME e non gira. In un osservatorio le due cose si
montano una volta e restano montate; e la ruota la comanda il software - in gioco
la scelta del filtro e' una schermata sul CRT, non un gesto. Il giorno che servisse
farla girare, e' un disco solo da staccare.

COSA NON C'E', E PERCHE'. La flangia T-Thread della camera e il suo foro non sono
modellati: stanno SOTTO la ruota filtri, che e' larga il doppio e sta li' sempre.
Non si vedono da nessuna angolazione, e una faccia che non si vede non si fa. Il
buco nero che si deve vedere - quello che dice che la camera guarda qualcosa - e'
in cima al naso della ruota, dove sta anche nel vero. Non c'e' nemmeno il cavetto
piatto che nella foto va dalla ruota alla camera: questo e' un oggetto che si
prende in mano e rotola per terra, e un cavo modellato rigido gli penderebbe
dietro come un filo di ferro.
"""
import math
import os
import sys

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
import importlib   # noqa: E402
for _m in ("modellare",):
    if _m in sys.modules:
        importlib.reload(sys.modules[_m])
from modellare import (barra, cilindro, esporta, finisci, lampada,   # noqa: E402
                       prepara_render, pulisci, scatola)

RADICE = os.path.dirname(QUI)
USCITA = os.path.join(RADICE, "assets", "models", "ccd.glb")
PROVINO = os.path.join(RADICE, "_confronto", "13_ccd.png")

# --- le quote, in metri, dalla scheda SBIG -----------------------------------
DIAMETRO = 0.125          # 5 pollici
PROFONDA = 0.075          # 3 pollici, tutto compreso

# Come i 7,5 cm si spartiscono lungo l'asse ottico, da dietro in avanti. La somma
# DEVE fare `PROFONDA`, e sotto c'e' il controllo che lo pretende.
# LE PROPORZIONI SI CONTANO SULLE FOTO, misurando il bordo dei pezzi: quasi mezza
# camera e' il vano dell'elettronica, un terzo il pacco alettato, e la piastra
# frontale e' una lastra sottile.
VENTOLA_FUORI = 0.010     # LA VENTOLA E' MONTATA FUORI, non incassata: nella foto
                          # del retro sporge dal pannello con la sua griglia a
                          # raggi e le quattro viti agli angoli, come una ventola
                          # da computer avvitata sopra. Sta dentro i tre pollici
                          # dichiarati, quindi si mangia un centimetro di vano.
VANO_ALTO = 0.032         # il vano dell'elettronica
ALETTE_ALTE = 0.026       # il pacco delle alette anulari
PIASTRA_ALTA = 0.007      # la piastra circolare davanti

# IL QUADRATO E' PIU' STRETTO DEL TONDO, MA I SUOI ANGOLI SPORGONO. 10,5 cm di
# lato dentro un cerchio da 12,5: i fianchi restano un centimetro dentro il bordo
# delle alette, i quattro angoli ne escono di dodici millimetri. E' quel dettaglio
# - due profili diversi nella stessa silhouette - a dire che la camera e' fatta di
# due pezzi avvitati, ed e' esattamente cio' che si vede in catalogo.
SCATOLA_LATO = 0.105

ALETTE = 6                # quante se ne contano nella foto
ALETTA_SPESSA = 0.003     # e le gole fra loro sono larghe quanto le alette
GOLA_D = 0.113            # il diametro in fondo alla gola

# IL DECENTRAMENTO DELL'ASSE OTTICO, verso quello che nella foto di catalogo e'
# l'alto. Non e' un vezzo: e' il motivo per cui il vano dell'elettronica sta tutto
# da una parte, ed e' visibile a occhio nel confronto fra il naso e il centro
# della piastra. Due centimetri, misurati sulla foto.
DECENTRO = 0.020

# LA RUOTA FILTRI STA DAVANTI E AGGIUNGE UN POLLICE, che e' il numero che SBIG
# dichiara come back focus aggiunto. Il suo diametro non e' dichiarato da nessuna
# parte: cinque filtri da 1,25" su un carosello non ci stanno sotto i 10 cm.
RUOTA_ALTA = 0.022
# PIU' STRETTA DELLA CAMERA, e il primo giro non lo era: a 11,5 cm la ruota
# copriva le alette e l'oggetto leggeva come due dischi impilati con un coperchio
# sopra. Nel disegno d'assieme di SBIG la CFW-8 e' visibilmente piu' piccola della
# testa, ed e' quel gradino a dire che sono due pezzi avvitati insieme.
RUOTA_D = 0.098
MOTORE_D = 0.036          # la gobba tonda del passo passo, sul bordo del disco
MOTORE_FUORI = 0.040      # quanto e' lontano dall'asse il centro della gobba

NASO_D = 0.0317           # il barilotto da 1,25", che e' il diametro vero
# TRE CENTIMETRI DI NASO, non uno e mezzo. Un barilotto corto legge come un tappo,
# e nella foto della CFW-8 il naso sporge quanto e' spesso il disco della ruota.
# La camera diventa cosi' 12,7 cm invece di 11,1, e i 11,1 restano lo stesso -
# come QUANTO SI ARRETRA per montarla: il centimetro e mezzo di differenza e' il
# pezzo di naso che entra nel focheggiatore, che e' quello che fa un naso vero.
NASO_LUNGO = 0.030
FORO_D = 0.026            # il buco nero dell'ottica, dentro il naso

VENTOLA_D = 0.046         # la ventola sul pannello posteriore
PANNELLO = VENTOLA_FUORI  # la faccia posteriore, dietro cui c'e' il vano


def controlla():
    somma = VENTOLA_FUORI + VANO_ALTO + ALETTE_ALTE + PIASTRA_ALTA
    if abs(somma - PROFONDA) > 0.0005:
        print("\nATTENZIONE: ventola+vano+alette+piastra fanno %.3f, la camera "
              "e' profonda %.3f" % (somma, PROFONDA))
        sys.exit(1)
    # I QUATTRO ANGOLI DEVONO SPORGERE, o la scatola sparisce dentro il tondo e
    # con lei se ne va meta' della silhouette. Mezza diagonale contro il raggio.
    if SCATOLA_LATO * 0.7071 <= DIAMETRO / 2:
        print("\nATTENZIONE: gli angoli della scatola non escono dall'ingombro "
              "tondo: la camera torna un cilindro")
        sys.exit(1)


def vano():
    """Il vano squadrato dietro, che e' meta' della camera e tutta la sua faccia.

    IL PANNELLO POSTERIORE E' LA FACCIA PIU' RICCA DI TUTTO L'OGGETTO, e la prima
    stesura lo aveva lasciato nudo: nella foto di Pedro Re' ci stanno la ventola,
    una griglia di feritoie alta mezzo pannello, l'etichetta bianca col marchio
    CE, un connettore e una spia. E' anche la faccia che si vede in gioco, perche'
    con la camera montata al fuoco il naso guarda dentro il telescopio e il retro
    guarda chi sta sulla passerella.
    """
    h = SCATOLA_LATO / 2
    scatola("PlasticaNera", -h, h, PANNELLO, PANNELLO + VANO_ALTO, -h, h)
    ventola()
    feritoie()
    etichetta()
    connettori()


def ventola():
    """La ventola avvitata sul pannello, con la griglia a raggi e le sue viti.

    NON E' UN DISCO NERO E BASTA. Un cerchio scuro su un fondo scuro non si vede;
    quello che si riconosce di una ventola sono i RAGGI DELLA GRIGLIA - poche
    barrette chiare su un buco - ed e' il dettaglio del retro che si legge da piu'
    lontano. Sta decentrata come nella foto, dalla stessa parte dell'asse ottico.
    """
    xc, zc = -0.020, -0.023
    r = VENTOLA_D / 2
    q = r + 0.005
    # LA CORNICE E' FORATA, ED E' UN ERRORE CHE HO GIA' FATTO: al primo giro era
    # una scatola piena con dentro il pozzetto della ventola, e una scatola piena
    # non ha un dentro - il provino ha restituito una piastrina liscia con quattro
    # viti. Quattro barre attorno a un buco, e il buco si vede.
    for (x0, x1, z0, z1) in ((xc - q, xc + q, zc - q, zc - r),
                             (xc - q, xc + q, zc + r, zc + q),
                             (xc - q, xc - r, zc - r, zc + r),
                             (xc + r, xc + q, zc - r, zc + r)):
        scatola("PlasticaNera", x0, x1, 0.002, PANNELLO, z0, z1)
    cilindro("Schermo", xc, zc, 0.004, PANNELLO, r, seg=20)
    cilindro("Metallo", xc, zc, 0.0025, 0.007, 0.007, seg=10)
    for k in range(6):
        a = math.radians(30 + 60 * k)
        barra("Metallo", (xc, 0.0035, zc),
              (xc + math.cos(a) * r, 0.0035, zc + math.sin(a) * r), 0.0010)
    for x in (xc - q + 0.0025, xc + q - 0.0025):
        for z in (zc - q + 0.0025, zc + q - 0.0025):
            cilindro("Metallo", x, z, 0.0015, 0.0035, 0.0022, seg=6)


def feritoie():
    """La griglia di sfogo sul pannello: otto asole verticali, come nella foto.

    L'aria che la ventola tira dentro deve uscire da qualche parte. Sono UNA
    GRIGLIA e non due tacche, e la differenza non e' di fedelta' ma di lettura: e'
    l'unico pezzo di questa camera con un ritmo fitto, e un ritmo fitto accanto a
    superfici lisce e' quello che fa sembrare industriale un oggetto.
    """
    for k in range(8):
        x = -0.042 + k * 0.0050
        scatola("Schermo", x, x + 0.0026, PANNELLO - 0.0015, PANNELLO,
                0.002, 0.036)


def etichetta():
    """La targhetta bianca, e non e' un dettaglio decorativo.

    Su una camera nera opaca dentro una cupola al buio, il rettangolo chiaro del
    numero di serie e' il primo pezzo che l'occhio trova - nella foto di Pedro Re'
    e' l'unica cosa che si distingue del retro. Toglierla costerebbe due facce e
    la leggibilita' dell'intero oggetto.

    E' `Bianco` E NON `Carta`, che sarebbe il materiale ovvio: `Carta` porta la
    trama della carta a trenta centimetri per ripetizione, e su una targhetta di
    tre centimetri se ne vede un decimo - cioe' un rettangolo beige rigato, che
    nel provino leggeva come un pezzo di compensato incollato dietro la camera.
    Una targhetta stampata e' una tinta piatta chiara, e basta.
    """
    scatola("Bianco", 0.010, 0.036, PANNELLO - 0.0006, PANNELLO, 0.002, 0.032)


def connettori():
    """La presa di corrente, le vaschette e la spia accesa.

    Sulla ST-8 del 1999 il collegamento al PC e' una PARALLELA, non l'USB delle
    camere di oggi - ma a questa scala si vede una vaschetta metallica e basta, e
    la differenza non arriva all'occhio. Le vaschette stanno sul fianco, che nella
    foto e' quello da cui pendono i cavi: sporgono di quattro millimetri e restano
    dentro l'ingombro cilindrico del collider, cosi' la camera continua a rotolare
    su se stessa invece di impuntarsi su una spina.

    LA SPIA ROSSA COSTA UNA MESH INTERA - un materiale in piu' nel .glb e' un
    oggetto in piu' in Godot - e li vale: su dodici centimetri di nero opaco e'
    l'unico punto di colore, ed e' la differenza fra uno strumento acceso e un
    pezzo di ferro. Nella foto e' li', accesa, accanto alla griglia.
    """
    z = SCATOLA_LATO / 2
    y = PANNELLO + VANO_ALTO / 2
    for x in (-0.024, 0.006):
        scatola("Metallo", x - 0.013, x + 0.013, y - 0.007, y + 0.007, z, z + 0.004)
    cilindro("Metallo", 0.030, -0.036, PANNELLO - 0.0025, PANNELLO + 0.001,
             0.007, seg=12)
    cilindro("NeonRosso", 0.006, -0.014, PANNELLO - 0.0015, PANNELLO + 0.0008,
             0.0025, seg=8)


def alette():
    """Il pacco alettato: sei anelli che sporgono da un cilindro piu' stretto.

    E' QUELLA DIFFERENZA DI RAGGIO a fare l'ombra a righe che rende riconoscibile
    questo oggetto da lontano, ed e' il motivo per cui le gole sono larghe quanto
    le alette invece che sottili: una scanalatura da un millimetro non fa ombra,
    fa rumore sul bordo.
    """
    y0 = PANNELLO + VANO_ALTO
    y1 = y0 + ALETTE_ALTE
    cilindro("PlasticaNera", 0.0, 0.0, y0, y1, GOLA_D / 2, seg=24)
    passo = ALETTE_ALTE / ALETTE
    for k in range(ALETTE):
        y = y0 + passo * k + (passo - ALETTA_SPESSA) / 2
        cilindro("PlasticaNera", 0.0, 0.0, y, y + ALETTA_SPESSA,
                 DIAMETRO / 2, seg=24)


def piastra():
    """La lastra circolare davanti, con le sei brugole sul bordo.

    LE VITI SI VEDONO, ed e' la lezione che arriva dalla camera moderna presa a
    riferimento: su un corpo tutto di un colore, le teste metalliche delle viti
    sono l'unica cosa che dice la scala dell'oggetto. Sei, sul cerchio a cui
    stanno nella foto di catalogo.
    """
    y0 = PROFONDA - PIASTRA_ALTA
    cilindro("PlasticaNera", 0.0, 0.0, y0, PROFONDA, DIAMETRO / 2, seg=24)
    for k in range(6):
        a = math.radians(30 + 60 * k)
        cilindro("Metallo", math.cos(a) * 0.054, math.sin(a) * 0.054,
                 PROFONDA - 0.0025, PROFONDA + 0.0005, 0.0025, seg=6)


def ruota():
    """La CFW-8: il disco piatto, la gobba del motore e il naso da 1,25 pollici."""
    y0 = PROFONDA
    y1 = y0 + RUOTA_ALTA
    zc = -DECENTRO
    # IL DISCO E' CENTRATO SUL CORPO, IL NASO NO, e non e' una svista: il carosello
    # gira attorno al proprio perno e l'asse ottico passa per una delle cinque
    # posizioni. E' il motivo per cui nella foto di catalogo della CFW-8 il naso
    # sta in alto invece che in mezzo.
    cilindro("PlasticaNera", 0.0, 0.0, y0, y1, RUOTA_D / 2, seg=24)
    # la gobba tonda del motore passo passo, che sporge dal bordo del disco: e' il
    # pezzo che distingue una ruota filtri da un anello distanziale
    cilindro("PlasticaNera", 0.0, MOTORE_FUORI, y0 + 0.002, y1 - 0.002,
             MOTORE_D / 2, seg=16)
    for k in range(4):
        a = math.radians(45 + 90 * k)
        cilindro("Metallo", math.cos(a) * 0.041, math.sin(a) * 0.041,
                 y1 - 0.0025, y1 + 0.0005, 0.0022, seg=6)
    # la ghiera alla base del naso, e il naso
    cilindro("Metallo", 0.0, zc, y1 - 0.001, y1 + 0.003, 0.021, seg=16)
    cilindro("Metallo", 0.0, zc, y1, y1 + NASO_LUNGO, NASO_D / 2, seg=16)
    cilindro("Schermo", 0.0, zc, y1 + 0.002, y1 + NASO_LUNGO + 0.0005,
             FORO_D / 2, seg=16)


controlla()
pulisci()
vano()
alette()
piastra()
ruota()

# I TONDI VANNO SFUMATI, LE SCATOLE NO, e l'angolo li separa da solo: a
# ventiquattro segmenti due facce vicine di un cilindro stanno a quindici gradi e
# si fondono, i novanta gradi di uno spigolo restano spigolo. Prima era sfumato il
# solo `Metallo` e il corpo - che e' fatto quasi tutto di cilindri - usciva
# sfaccettato come un dado da gioco di ruolo.
pezzi = finisci(morbidi=("PlasticaNera", "Metallo"))
facce = sum(len(o.data.polygons) for o in pezzi)
print("  la camera e' fatta di %d facce in %d pezzi" % (facce, len(pezzi)))
print("  ingombro dichiarato: %.0f mm di diametro, %.0f di profondita' "
      "(%.0f con la ruota filtri e il naso)"
      % (DIAMETRO * 1000, PROFONDA * 1000,
         (PROFONDA + RUOTA_ALTA + NASO_LUNGO) * 1000))
if facce > 3000:
    print("\nATTENZIONE: %d facce per una camera CCD sono troppe." % facce)
    sys.exit(1)

esporta(USCITA)

# --- il provino: si GUARDA, non si deduce ------------------------------------
# La lezione del quadro (D-174) e della pulsantiera: un modello che non si e' mai
# visto e' un modello che non si sa se e' venuto, e nessun controllo numerico dice
# «sembra una camera CCD».
os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
# LA SI CORICA PRIMA DI FOTOGRAFARLA, e non e' un vezzo da fotografo. Il modello
# nasce con l'asse ottico in su perche' cosi' lo vuole il montaggio; guardato in
# quella posa sembra una torta a strati, e i primi due giri di questo file sono
# stati giudicati su provini che mentivano per colpa dell'inquadratura. Coricata
# e' come sta in catalogo ED e' come sta in gioco - avvitata a un telescopio che
# punta il cielo, non appoggiata su un tavolo. La rotazione arriva DOPO
# `esporta()`: il .glb e' gia' scritto e non se ne accorge.
for _o in pezzi:
    _o.rotation_euler = (math.radians(90.0), 0.0, 0.0)
scatta = prepara_render(900, 900, cielo=(0.16, 0.17, 0.19))
# LE LUCI VANNO CON IL QUADRATO DELLA DISTANZA, e questo oggetto e' piccolo: le
# stesse potenze del provino della pulsantiera - mezzo metro di oggetto, luci a
# mezzo metro - qui stanno a venti centimetri da una camera di dodici, cioe'
# arrivano sei volte piu' forti. Al primo giro il corpo anodizzato NERO e' uscito
# grigio chiaro, e il provino diceva che il colore era sbagliato quando era
# sbagliata la lampada. Un provino bruciato risponde sempre di si'.
lampada("Chiave", (0.22, 0.26, 0.24), 0.55, tipo="AREA", dimensione=0.5)
lampada("Riempimento", (-0.24, 0.12, 0.18), 0.10)
lampada("Contro", (0.0, 0.18, -0.28), 0.18)
# TRE SCATTI, E IL PRIMO E' QUELLO DEL CATALOGO. Si mette la camera nella stessa
# posa della fotografia da cui e' copiata: e' l'unico modo di confrontare un
# modello con la sua fonte invece di guardarlo e dirsi che va bene. Il secondo e'
# il retro, l'unico che mostra ventola ed etichetta; il terzo e' di profilo, dove
# si contano le alette e si vede il gradino fra camera e ruota filtri.
scatta(PROVINO, (0.19, 0.10, 0.23), (0.0, 0.0, 0.055), lente=55.0)
scatta(PROVINO.replace("13_", "13b_"), (0.13, 0.075, -0.20), (0.0, 0.0, 0.02),
       lente=50.0)
scatta(PROVINO.replace("13_", "13c_"), (0.30, 0.02, 0.06), (0.0, 0.0, 0.062),
       lente=55.0)
