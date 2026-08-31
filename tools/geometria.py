# -*- coding: utf-8 -*-
"""Geometria dell'osservatorio Astrochill: FONTE UNICA.

La pianta disegnata (pianta2.py) e il blockout navigabile (gen_blockout.py) leggono
entrambi da qui. Prima erano due liste separate, ed erano gia' divergenti: il disegno
mostrava una porta su un muro che nel blockout non esisteva piu'.

Le coordinate sono in "unita' di pianta originale": si moltiplicano per K per avere i
metri reali. Le LARGHEZZE delle aperture invece sono gia' in metri reali e non si scalano
mai, perche' sono misure antropometriche (D-031).
"""
import math

K = 0.5          # dimezzamento della pianta (D-028)
SP = 0.20        # spessore dei muri, in metri reali
H = 3.00         # altezza interna e quota di gronda
H_ARCH = 2.10    # altezza delle porte
W_SILL, W_TOP = 1.00, 2.40      # davanzale e sommita' delle finestre
# La vetrata interna non e' una finestra e non prende le sue quote: e' un
# serramento a tutta parete fra due locali, e parte piu' in basso e finisce piu'
# in alto. Sotto ci sta la consolle (0,75), sopra restano 40 cm di architrave.
V_SILL, V_TOP = 0.90, 2.60
# IL VETRO E' UNA LASTRA. Prima riempiva tutto lo spessore del muro, e l'infisso
# sembrava scolpito in un blocco di vetro invece che montato in un telaio.
SP_VETRO = 0.016
SP_SOLAIO = 0.20                # solaio: intradosso a H, estradosso a H + SP_SOLAIO
SP_TETTO = 0.18
H_TETTO = H + SP_SOLAIO         # il tetto appoggia SOPRA il solaio: 3,20
# La cupola poggia sull'estradosso del tetto, non sulla gronda: finche' la sala del
# telescopio non aveva copertura i due valori coincidevano, dandogliela non piu' —
# e la cupola e' rimasta 38 cm dentro il tetto senza che si vedesse da dentro.
H_DOME_BASE = H_TETTO + SP_TETTO
DOME_R, DOME_H = 2.50, 5.00     # raggio 2,50 -> diametro 5,00; in Godot l'emisfero e' alto height/2

# --- muri: (x0, z0, x1, z1) --------------------------------------------------
PERIMETRO = [
    (0, 0, 16.5, 0), (16.5, 0, 16.5, 3), (16.5, 3, 38, 3), (38, 3, 38, 19),
    (0, 19, 38, 19), (0, 0, 0, 19),
]
INTERNI = [
    (10.4, 0, 10.4, 8.8),     # sala telescopio / controllo pc; si ferma a 8.8: varco pieno (D-034)
    (10.4, 8.8, 16.5, 8.8),   # controllo pc / corridoio
    (16.5, 3, 16.5, 19),
    (3.9, 13, 3.9, 19), (6.7, 13, 6.7, 19), (9.8, 13, 9.8, 19),   # segreta ovest allargata
    (0, 13, 16.5, 13),
    (26.8, 3, 26.8, 9.5), (29.3, 3, 29.3, 9.5), (26.8, 9.5, 29.3, 9.5),
    (16.5, 8.2, 26.8, 8.2),
]
MURI = PERIMETRO + INTERNI

# --- aperture: (x, z, larghezza REALE, orientamento, tipo, nome) -------------
# TUTTE LE PORTE INTERNE HANNO LO STESSO VANO, ed e' 1,06 - cioe' 90 cm di luce
# netta una volta tolti gli 8 cm di mostra per parte. La porta 90 e' la misura di
# serie di un edificio pubblico italiano, e SERVE ricordarsi perche' prima erano
# fra 1,30 e 1,40.
#
# Non era generosita': e' che la pianta di questo edificio e' dimezzata (D-028)
# mentre le altezze sono vere. Le stanze si sono ristrette, le porte no, e il
# risultato e' che in gioco leggevano come vani da capannone - 2,10 di altezza per
# 1,24 di luce fa un rapporto di 1,7, mentre una porta vera sta sopra il 2,3. Il
# difetto si vede solo camminandoci dentro, perche' in pianta 1,30 e' un numero
# ragionevole.
#
# Restano fuori le due che una misura ce l'hanno per un motivo: l'INGRESSO, che e'
# una via di fuga con il maniglione, e il MAGAZZINO, che e' una porta di servizio da
# 90 di vano e 74 di luce.
#
# I vani si sono stretti TENENDO FERMO IL CENTRO, non il bordo: lasciando la
# coordinata dichiarata, ogni porta sarebbe scivolata di dieci-quindici centimetri
# verso il suo montante, e in due casi verso l'angolo.
VANO_PORTA = 1.06

APERTURE = [
    (20.0, 19, 1.20, "h", "porta",    "ingresso"),   # un battente solo, antipanico
    (17.94, 8.2, VANO_PORTA, "h", "porta",   "cucina"),
    (16.5, 9.84, VANO_PORTA, "v", "porta",   "corridoio -> spazio"),
    (13.14, 8.8, VANO_PORTA, "h", "porta",   "pc -> corridoio"),
    (7.35, 13, 0.90, "h", "porta",    "magazzino"),
    (11.84, 13, VANO_PORTA, "h", "porta",    "bagno"),
    (0.89, 13, VANO_PORTA, "h", "porta",   "disimpegno"),
    # UNA SOLA APERTURA SUL MURO DELLA CUPOLA, E NON SI ATTRAVERSA. C'era anche
    # una porta, e serviva solo a raddoppiare un collegamento che il corridoio
    # gia' fa: dalla sala di controllo si passa dal corridoio, e verso la cupola
    # si GUARDA. Il muro resta (regge il solaio e separa il caldo dal freddo),
    # la porta no, e al suo posto la vetrata si allarga a 2,80 m centrati sul
    # telescopio, che sta a z=2,50.
    (10.4, 2.4, 2.80, "v", "vetrata", "vetrata PC / cupola"),
    (29.0, 19, 2.00, "h", "finestra", "divulgazione sud"),
    (38, 7.6, 2.00, "v", "finestra",  "divulgazione est"),
    (12.4, 19, 1.00, "h", "finestra", "finestra bagno"),
    (12.0, 0, 1.60, "h", "finestra",  "finestra pc nord"),
    # Sopra il lavello, sul muro nord. Una cucina senza finestre non e' realistica,
    # e questo e' l'unico dei suoi quattro muri che da' fuori.
    (18.2, 3, 1.20, "h", "finestra",  "finestra cucina"),
]

# Come si apre ogni porta: (cardine, verso).
#   cardine "a" = l'estremo con la coordinata minore lungo il muro, "b" = l'altro
#   verso  +1/-1 = da che parte sbatte l'anta, lungo la normale al muro
# L'ingresso si apre VERSO FUORI: e' un edificio pubblico, e la porta di una via di
# fuga non puo' aprirsi verso l'interno. Le altre si aprono verso il locale servito,
# tranne dove il locale e' troppo stretto per contenere l'anta.
MANIGLIONE = ("ingresso",)   # maniglione antipanico, sul lato INTERNO dell'anta

# LE PORTE DI SERVIZIO NON SONO DI LEGNO. In un edificio pubblico italiano di fine
# anni Novanta il magazzino ha una porta in lamiera pressopiegata, verniciata,
# spesso con la griglia di aerazione in basso e il portalucchetto: e' quella che
# dice "qui dentro non ci sta un ufficio, ci stanno le casse". Con l'anta di legno
# come tutte le altre, il locale non si distingueva da un bagno.
# La differenza non e' solo il colore: sono le NERVATURE, la griglia e il lucchetto
# a farla leggere come una porta di lamiera. Una lastra grigia liscia resta una
# porta di legno dipinta di grigio.
PORTE_METALLO = ("magazzino",)

APERTURA_PORTE = {
    "ingresso":            ("a", +1),   # verso il prato
    "cucina":              ("a", -1),   # dentro la cucina
    "corridoio -> spazio": ("b", +1),   # verso lo spazio divulgazione: il corridoio e' stretto
    "pc -> corridoio":     ("a", -1),   # dentro il controllo pc, per non ostruire il corridoio
    # DENTRO IL MAGAZZINO. Si apriva verso la sala perche' il locale e' largo
    # 1,55, ma l'anta ne misura 0,90 e ruotando si appoggia al muro di fianco:
    # ci sta. Una porta di ripostiglio che si apre addosso a chi passa nel
    # disimpegno e' peggio di una che ruba mezzo metro dentro.
    "magazzino":           ("a", +1),   # dentro il magazzino
    "bagno":               ("b", +1),   # dentro il bagno
    "disimpegno":          ("a", +1),   # dentro il disimpegno
}

PAVIMENTI = [(0, 0, 16.5, 19), (16.5, 3, 38, 19)]
SOFFITTI = [(10.4, 0, 16.5, 19), (0, 13, 10.4, 19), (16.5, 3, 38, 19)]
SALA_TELESCOPIO = (0, 0, 10.4, 13)      # coperta dal tetto forato + calotta, non dai SOFFITTI
CUPOLA = (5.2, 5.0)                     # centro in pianta

# passerella anulare e rampa di risalita (misure reali, non scalate)
# La passerella sta a 60 cm, non a 90. La quota non e' arbitraria: viene
# dall'oculare, che cade a 2,29 m dal pavimento. Con l'impalcato a 0,60 l'occhio
# di chi ci sta in piedi arriva a 2,30, cioe' esattamente all'oculare; a 0,90 ci
# si doveva chinare di quaranta centimetri. E la scala scende da 1,25 a 0,77 m di
# sviluppo, liberando la fascia verso il muro dove prima si saliva schiacciati.
# 1,05 DI LARGHEZZA, NON 0,85. Con 0,85 e un parapetto per lato restavano 0,71 di
# passaggio netto contro una capsula da 0,60: undici centimetri di gioco in tutto,
# e camminandoci ci si incastrava contro la ringhiera al primo scarto. Il numero da
# guardare non e' la larghezza dell'impalcato, e' quello che resta fra i parapetti.
# La capsula del giocatore, da world/player/player.tscn: e' la misura contro cui si
# valuta ogni passaggio, e sta qui perche' i controlli la usano.
CAPSULA = 0.60
R_PASS, W_PASS, H_PASS = 2.8 * K, 1.05, 0.50   # 0,50 + mezzo impalcato = 0,59 di calpestio
SP_PASS = 0.18                          # spessore dell'impalcato
DISL_RAMPA = H_PASS + SP_PASS / 2       # si sale al PIANO DI CALPESTIO, non alla quota nominale
# 1,10 e non 0,75. A 0,75 la rampa saliva a 38 gradi e i gradini disegnati sopra
# venivano da quindici centimetri di pedata: una scala a pioli, non una scala. A
# 1,10 la pendenza scende a 28 gradi e la pedata a ventidue - e il piede resta
# comunque a un metro dal muro della sala.
LUNGO_RAMPA = 1.10


def scalati():
    """Le stesse liste in metri reali. Le larghezze delle aperture restano invariate."""
    m = [tuple(v * K for v in w) for w in MURI]
    a = [(x * K, z * K, w, o, t, n) for (x, z, w, o, t, n) in APERTURE]
    p = [tuple(v * K for v in w) for w in PAVIMENTI]
    s = [tuple(v * K for v in w) for w in SOFFITTI]
    sala = tuple(v * K for v in SALA_TELESCOPIO)
    cup = (CUPOLA[0] * K, CUPOLA[1] * K)
    return m, a, p, s, sala, cup


def verifica_aperture(min_montante=0.30):
    """Ogni apertura deve stare in un muro, lasciare `min_montante` dai bordi
    e altrettanto dall'apertura vicina sullo stesso muro."""
    muri, aperture, _, _, _, _ = scalati()
    problemi, collocate = [], {}
    for (px_, pz, w, o, t, nome) in aperture:
        trovata = False
        for j, (x0, z0, x1, z1) in enumerate(muri):
            orizz = abs(z1 - z0) < 0.001
            if (o == "h") != orizz:
                continue
            fisso = z0 if orizz else x0
            if abs((pz if orizz else px_) - fisso) > 0.01:
                continue
            a, b = (min(x0, x1), max(x0, x1)) if orizz else (min(z0, z1), max(z0, z1))
            p = px_ if orizz else pz
            if p >= a - 0.01 and p + w <= b + 0.01:
                trovata = True
                # I montanti non si misurano sugli estremi del muro ma sui vincoli piu'
                # vicini: un muro lungo e' attraversato dai divisori, e una porta puo'
                # avere due metri di muro davanti e venti centimetri dal tramezzo.
                tagli = [a, b]
                for (qx0, qz0, qx1, qz1) in muri:
                    q_orizz = abs(qz1 - qz0) < 0.001
                    if q_orizz == orizz:
                        continue
                    trasv = qx0 if orizz else qz0          # dove taglia il nostro muro
                    lungo0, lungo1 = (min(qz0, qz1), max(qz0, qz1)) if orizz else (min(qx0, qx1), max(qx0, qx1))
                    if lungo0 - 0.01 <= fisso <= lungo1 + 0.01 and a - 0.01 <= trasv <= b + 0.01:
                        tagli.append(trasv)
                sinistra = max([t for t in tagli if t <= p + 0.01], default=a)
                destra = min([t for t in tagli if t >= p + w - 0.01], default=b)
                m1, m2 = p - sinistra, destra - (p + w)
                if min(m1, m2) < min_montante - 1e-6:
                    problemi.append("  MONTANTE SOTTILE  %-20s %.2f / %.2f m dai bordi" % (nome, m1, m2))
                collocate.setdefault(j, []).append((p, p + w, nome))
                break
        if not trovata:
            problemi.append("  SCARTATA          %-20s non entra in nessun muro" % nome)
    for lista in collocate.values():
        lista.sort()
        for i in range(len(lista) - 1):
            gap = lista[i + 1][0] - lista[i][1]
            if gap < min_montante - 1e-6:
                problemi.append("  TROPPO VICINE     %-20s e %-16s %.2f m fra loro"
                                % (lista[i][2], lista[i + 1][2], gap))
    return problemi


def verifica_copertura(tetti_extra=(), passo=0.10):
    """Ogni metro quadro di pavimento deve avere sopra un soffitto, un tetto o la calotta."""
    _, _, pav, soff, _, cup = scalati()
    tetti = list(soff) + list(tetti_extra)
    scoperto = 0.0
    for (x0, z0, x1, z1) in pav:
        x = x0 + passo / 2
        while x < x1:
            z = z0 + passo / 2
            while z < z1:
                if not (any(a <= x <= c and b <= z <= d for (a, b, c, d) in tetti)
                        or math.hypot(x - cup[0], z - cup[1]) <= DOME_R):
                    scoperto += passo * passo
                z += passo
            x += passo
    return scoperto


# --- ambienti: nome + un punto interno da cui riempire -----------------------
# Le superfici NON si scrivono a mano: si misurano riempiendo le stanze dai muri.
AMBIENTI = [
    ("sala del telescopio", 5.0, 4.0), ("controllo pc", 13.5, 4.0),
    ("corridoio", 13.5, 11.0), ("bagno", 13.0, 16.0), ("magazzino", 8.0, 16.0),
    ("disimpegno", 2.0, 16.0), ("segreta ovest", 5.3, 16.0),
    ("cucina", 20.0, 5.5), ("segreta est", 28.0, 6.0), ("spazio divulgazione", 33.0, 14.0),
]
# separatori che non sono muri: il varco senza porta fra corridoio e sala del
# telescopio (D-034) va chiuso per contare le due stanze separatamente
SOGLIE = [(10.4, 8.8, 10.4, 13)]


def superfici(passo=0.05):
    """Metri quadri netti di ogni ambiente, misurati sulla geometria."""
    from collections import deque
    muri, _, pav, _, _, _ = scalati()
    muri = muri + [tuple(v * K for v in s) for s in SOGLIE]
    x0g = min(p[0] for p in pav); z0g = min(p[1] for p in pav)
    x1g = max(p[2] for p in pav); z1g = max(p[3] for p in pav)
    nx, nz = int((x1g - x0g) / passo) + 1, int((z1g - z0g) / passo) + 1
    def c(i, j): return (x0g + (i + 0.5) * passo, z0g + (j + 0.5) * passo)

    libera = [[False] * nz for _ in range(nx)]
    for i in range(nx):
        for j in range(nz):
            x, z = c(i, j)
            if not any(a <= x <= b and d <= z <= e for (a, d, b, e) in pav):
                continue
            muro = False
            for (ax, az, bx, bz) in muri:
                if abs(bz - az) < 1e-9:
                    if min(ax, bx) - SP / 2 <= x <= max(ax, bx) + SP / 2 and abs(z - az) <= SP / 2:
                        muro = True; break
                else:
                    if min(az, bz) - SP / 2 <= z <= max(az, bz) + SP / 2 and abs(x - ax) <= SP / 2:
                        muro = True; break
            libera[i][j] = not muro

    vis = [[False] * nz for _ in range(nx)]
    out = {}
    for (nome, sx, sz) in AMBIENTI:
        i = int((sx * K - x0g) / passo); j = int((sz * K - z0g) / passo)
        if not (0 <= i < nx and 0 <= j < nz) or not libera[i][j] or vis[i][j]:
            out[nome] = None
            continue
        q, n = deque([(i, j)]), 0
        vis[i][j] = True
        while q:
            a, b = q.popleft(); n += 1
            for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                na, nb = a + da, b + db
                if 0 <= na < nx and 0 <= nb < nz and libera[na][nb] and not vis[na][nb]:
                    vis[na][nb] = True; q.append((na, nb))
        out[nome] = n * passo * passo
    return out


def verifica_trappole(statura=1.80):
    """Nessun posto in cui si possa cadere e non si possa uscire.

    Il vuoto sotto la passerella e' alto meno di una persona: chi ci finisce non si
    alza in piedi, e per risalire dovrebbe scavalcare il bordo dell'impalcato, che
    un CharacterBody3D non sa fare. L'unica difesa e' non poterci cadere, cioe' un
    parapetto CON COLLISIONE sul bordo interno.

    Il controllo si spegne da solo se un domani la passerella verra' alzata quanto
    basta a starci sotto: allora non sarebbe piu' una trappola.
    """
    blocchi = blocchi_edificio()
    problemi = []
    luce_sotto = H_PASS - SP_PASS / 2
    if luce_sotto >= statura:
        return problemi
    # DUE MODI DI NON CADERCI, e il controllo deve accettarli tutti e due: un
    # parapetto sul bordo interno, OPPURE un vuoto centrale cosi' stretto che non ci
    # si entra. Prima chiedeva il parapetto e basta - il mezzo invece del fine - e
    # quando il centro e' stato riempito fino a filo del calpestio ha continuato a
    # protestare per un pozzo che non esiste piu'.
    interni = [b for b in blocchi if b[6].startswith("ParapettoInt")]
    if not interni:
        pieno = [b for b in blocchi if b[6].startswith("Montatura")]
        # il raggio libero peggiore: sul mezzo faccia dell'ottagono, non sui vertici
        libero = R_PASS - W_PASS / 2.0
        for b in pieno:
            mezzo = min(b[3], b[5]) / 2.0
            libero = min(libero, (R_PASS - W_PASS / 2.0) - mezzo)
        if libero >= CAPSULA:
            problemi.append("  TRAPPOLA          il vuoto centrale (%.2f m di luce) non ha "
                            "parapetto e resta aperto per %.2f m" % (luce_sotto, libero))
        return problemi
    # il parapetto deve girare tutto intorno, salvo il varco della scala
    angoli = sorted(math.degrees(math.atan2(b[2] - CUPOLA[1] * K, b[0] - CUPOLA[0] * K)) % 360
                    for b in interni)
    buchi = [(angoli[i + 1] - angoli[i]) for i in range(len(angoli) - 1)]
    buchi.append(360.0 - angoli[-1] + angoli[0])
    if len(buchi) > 1 and sorted(buchi)[-2] > 25.0:
        problemi.append("  TRAPPOLA          il parapetto interno ha due varchi (%.0f e %.0f gradi)"
                        % (sorted(buchi)[-1], sorted(buchi)[-2]))
    return problemi


def blocchi_edificio():
    """Tutti i volumi dell'osservatorio: muri con le loro aperture, solai, tetti,
    passerella, montatura e rampa. Restituisce (cx, cy, cz, sx, sy, sz, nome, rot_x).

    E' la traduzione della pianta in volumi, e sta qui perche' la usano sia il
    blockout Godot sia il modello Blender: se vivesse in uno dei due, l'altro
    prima o poi divergerebbe.
    """
    import math as _m
    import math
    MURI, APERTURE, PAVIMENTI, SOFFITTI, SALA, (_CX, _CZ) = scalati()
    _R = DOME_R
    blocchi = []

    def aggiungi(cx, cy, cz, sx, sy, sz, nome, rot_x=0.0, rot_z=0.0, rot_y=0.0):
        # ROT_Y SERVE A UN ANELLO. Senza, una passerella circolare si puo' fare solo
        # con scatole allineate agli assi messe su una circonferenza: dove l'anello
        # corre in diagonale la scatola non lo copre, e restano buchi e scalini che
        # camminandoci si sentono tutti. E' esattamente il difetto che c'era.
        if sx > 0.01 and sy > 0.01 and sz > 0.01:
            blocchi.append((cx, cy, cz, sx, sy, sz, nome, rot_x, rot_z, rot_y))

    # ---------------------------------------------------------------- muri con aperture
    # GLI ANGOLI VANNO CHIUSI. Un muro va da asse ad asse e ha spessore SP centrato
    # sull'asse: dove due muri FINISCONO nello stesso punto, il quadrato di SP/2 per
    # SP/2 dalla parte esterna dell'angolo non lo copre nessuno dei due e resta un
    # intaglio alto quanto il muro. Non e' una fessura fra due stanze - non ci si
    # vede attraverso - e' un pezzo di spigolo che manca: da dentro l'angolo non
    # legge come uno spigolo a novanta gradi ma come uno scalino di dieci centimetri.
    #
    # Si allunga ogni muro di mezzo spessore SU QUELL'ESTREMO E SOLO LI'. Il pezzo in
    # piu' cade dentro l'ingombro del muro che gli sta di traverso, quindi non sporge
    # da nessuna parte: riempie il quadrante che mancava e basta. Dove invece un muro
    # ne INCROCIA un altro senza finirci - la T di un tramezzo - l'angolo e' gia'
    # pieno, e allungare farebbe spuntare un moncone nella stanza di la'.
    _capi = {}
    for (x0, z0, x1, z1) in MURI:
        for capo in ((round(x0, 3), round(z0, 3)), (round(x1, 3), round(z1, 3))):
            _capi[capo] = _capi.get(capo, 0) + 1

    for i, (x0, z0, x1, z1) in enumerate(MURI):
        orizz = abs(z1 - z0) < 0.001
        a, b = (min(x0, x1), max(x0, x1)) if orizz else (min(z0, z1), max(z0, z1))
        fisso = z0 if orizz else x0

        def _capo(v, _o=orizz, _f=fisso):
            return (round(v, 3), round(_f, 3)) if _o else (round(_f, 3), round(v, 3))

        # gli estremi da usare per il PIENO. Le aperture restano contate su a e b:
        # allungando anche quelli, una porta a filo dell'angolo entrerebbe in un muro
        # che non e' il suo.
        a_est = a - SP / 2 if _capi.get(_capo(a), 0) >= 2 else a
        b_est = b + SP / 2 if _capi.get(_capo(b), 0) >= 2 else b
        ap = [(p, p + w, t) for (px_, pz, w, o, t, _nm) in APERTURE
              if (o == "h") == orizz and abs((pz if orizz else px_) - fisso) < 0.01
              for p in [px_ if orizz else pz]
              if p >= a - 0.01 and p + w <= b + 0.01]
        ap.sort()
        # tratti pieni fra le aperture
        # I MURI PERIMETRALI SCENDONO SOTTO IL PAVIMENTO. Fermandoli a quota zero,
        # sotto di loro restava una fessura alta quanto lo spessore del solaio, e da
        # fuori ci si vedeva dentro il taglio della lastra: una riga di graniglia
        # lungo tutta la base della facciata. Un muro vero ha una fondazione, e
        # trentacinque centimetri bastano a chiuderla in qualunque condizione di
        # terreno. I tramezzi interni non ne hanno bisogno.
        # E SALGONO FINO SOTTO IL TETTO, non fino al soffitto. Fermandoli a H
        # restava una fessura di venti centimetri - lo spessore del solaio - lungo
        # tutto il perimetro della sala del telescopio, che il solaio non copre
        # perche' li' sopra c'e' il tetto forato con la calotta. Da fuori ci si
        # vedeva dentro, e di notte la luce rossa usciva a fascia sopra la facciata.
        # Sotto il solaio non si vede da nessuna parte: dentro il soffitto e'
        # sempre a H.
        giu = 0.35 if i < len(PERIMETRO) else 0.0
        h_muro, y_muro = H_TETTO + giu, (H_TETTO - giu) / 2.0
        cur = a_est
        for (p0, p1, t) in ap:
            if p0 > cur + 0.01:
                aggiungi_seg = (cur, p0)
                m, L = (aggiungi_seg[0] + aggiungi_seg[1]) / 2.0, aggiungi_seg[1] - aggiungi_seg[0]
                if orizz: aggiungi(m, y_muro, fisso, L, h_muro, SP, "M%d" % i)
                else:     aggiungi(fisso, y_muro, m, SP, h_muro, L, "M%d" % i)
            cur = p1
        if b_est > cur + 0.01:
            m, L = (cur + b_est) / 2.0, b_est - cur
            if orizz: aggiungi(m, y_muro, fisso, L, h_muro, SP, "M%d" % i)
            else:     aggiungi(fisso, y_muro, m, SP, h_muro, L, "M%d" % i)
        # architravi e parapetti
        for (p0, p1, t) in ap:
            m, L = (p0 + p1) / 2.0, p1 - p0
            if t == "porta":
                cy, sy = (H_ARCH + H) / 2.0, H - H_ARCH
                if orizz: aggiungi(m, cy, fisso, L, sy, SP, "A%d" % i)
                else:     aggiungi(fisso, cy, m, SP, sy, L, "A%d" % i)
            else:
                sotto, sopra = (V_SILL, V_TOP) if t == "vetrata" else (W_SILL, W_TOP)
                # anche il parapetto sotto una finestra scende con la fondazione, o
                # sotto ogni finestra resta la fessura che il muro pieno ha chiuso
                for cy, sy in [((sotto - giu) / 2.0, sotto + giu), ((sopra + H) / 2.0, H - sopra)]:
                    if orizz: aggiungi(m, cy, fisso, L, sy, SP, "F%d" % i)
                    else:     aggiungi(fisso, cy, m, SP, sy, L, "F%d" % i)

    # ---------------------------------------------------------------- pavimenti e soffitti
    # IL SOLAIO SI RITIRA DI MEZZO MURO. I rettangoli di PAVIMENTI arrivano all'ASSE
    # dei muri, che e' giusto per i controlli ma non per il volume: cosi' com'e' la
    # lastra sbordava di 10 cm oltre la faccia esterna, e tutt'intorno all'edificio
    # correva una fascia di graniglia a vista. I giunti che restano cadono sotto i
    # muri, che sono spessi quanto il ritiro sommato dei due lati.
    for j, (x0, z0, x1, z1) in enumerate(PAVIMENTI):
        aggiungi((x0 + x1) / 2.0, -0.10, (z0 + z1) / 2.0,
                 x1 - x0 - SP, 0.20, z1 - z0 - SP, "Pav%d" % j)
    for j, (x0, z0, x1, z1) in enumerate(SOFFITTI):
        aggiungi((x0 + x1) / 2.0, H + SP_SOLAIO / 2, (z0 + z1) / 2.0, x1 - x0, SP_SOLAIO, z1 - z0, "Soff%d" % j)
        # tetto: sporge 30 cm oltre il filo dei muri
        aggiungi((x0 + x1) / 2.0, H_TETTO + SP_TETTO / 2, (z0 + z1) / 2.0, x1 - x0 + 0.6, SP_TETTO, z1 - z0 + 0.6, "Tetto%d" % j)

    # ---------------------------------------------------------------- tetto della sala del telescopio
    # La cupola (diametro 5 m) NON copre una sala di 5,2 x 6,5: restavano 14 m2 aperti al cielo.
    # Tetto piano forato, a strisce che seguono il cerchio: la cupola vi poggia sopra, come da GDD.
    import math as _m
    DX = 0.25
    # IL FORO E' PIU' STRETTO DELLA CALOTTA di trenta centimetri: la cupola poggia
    # su un anello di tetto invece che sul bordo esatto del proprio foro. Con i due
    # raggi uguali il foro arrivava a filo del muro nord, e li' sopra il muro non
    # c'era ne' tetto ne' calotta - la calotta comincia diciotto centimetri piu' su.
    # Una feritoia che da fuori faceva vedere dentro, e di notte lasciava uscire la
    # luce rossa a fascia sopra la facciata.
    _R_FORO = _R - 0.30
    _n = int(round((SALA[2] - SALA[0]) / DX))
    for _i in range(_n):
        x0 = SALA[0] + _i * DX
        x1 = x0 + DX
        # semi-corda del cerchio, presa sul bordo di striscia PIU' LONTANO dal centro:
        # cosi' il tetto avanza fin sotto la calotta invece di ritirarsi e lasciare fessure
        d = max(abs(x0 - _CX), abs(x1 - _CX))
        c = _m.sqrt(_R_FORO * _R_FORO - d * d) if d < _R_FORO else -1.0
        tratti = [(SALA[1], SALA[3])] if c < 0 else [(SALA[1], _CZ - c), (_CZ + c, SALA[3])]
        for (z0, z1) in tratti:
            if z1 - z0 > 0.01:
                aggiungi((x0 + x1) / 2.0, H_TETTO + SP_TETTO / 2, (z0 + z1) / 2.0, DX, SP_TETTO, z1 - z0, "TettoCup")

    # ---------------------------------------------------------------- passerella anulare + pilastro
    import math
    CX, CZ = 5.2 * K, 5.0 * K
    # L'IMPALCATO E' FATTO DI CONCI TANGENTI, non di scatole allineate agli assi.
    # Ogni settore e' largo W_PASS in senso radiale (X locale) e lungo la corda in
    # senso tangenziale (Z locale), e il blocco si gira di rot_y. Ventiquattro
    # settori: la freccia dell'arco resta sotto il centimetro, quindi il calpestio
    # e' piano davvero e non a scodella.
    N = 24
    corda = 2 * math.pi * R_PASS / N
    for k in range(N):
        ang = 2 * math.pi * k / N
        # X locale radiale: la tangente e' l'angolo + 90 gradi
        aggiungi(CX + R_PASS * math.cos(ang), H_PASS, CZ + R_PASS * math.sin(ang),
                 W_PASS, SP_PASS, corda + 0.06, "Pass%d" % k,
                 rot_y=-(ang + math.pi / 2.0))

    # IL PARAPETTO HA UNA COLLISIONE, e non e' un dettaglio di comodo.
    # Senza, si attraversa la ringhiera e si cade nel vuoto centrale: li' sotto
    # restano 81 cm di altezza libera — non ci si sta in piedi — e per risalire
    # servirebbe scavalcare un bordo di 99 cm, che un CharacterBody3D non fa.
    # E' una trappola senza uscita, e il modo di non averla e' non poterci cadere.
    calpestio = H_PASS + SP_PASS / 2
    VARCO_ANG, VARCO_MEZZO = math.pi / 2, math.radians(18.0)   # dove arriva la scala
    N_PAR = 24
    for k in range(N_PAR):
        ang = 2 * math.pi * k / N_PAR
        scarto = math.atan2(math.sin(ang - VARCO_ANG), math.cos(ang - VARCO_ANG))
        if abs(scarto) <= VARCO_MEZZO:
            continue          # il varco della scala resta aperto, o non si sale
        passo = 2 * math.pi / N_PAR
        # IL PARAPETTO INTERNO NON C'E' PIU', e non e' un taglio per far posto:
        # non ha piu' niente da proteggere. Serviva contro il pozzo centrale - 81
        # cm di altezza libera da cui non si risaliva - e quel pozzo adesso e'
        # pieno fino a filo del calpestio dall'ottagono della montatura. Una
        # ringhiera davanti a un muro e' solo una cosa contro cui incastrarsi.
        for raggio, nome in ((R_PASS + W_PASS / 2, "ParapettoEst"),):
            # TANGENTE ANCHE QUESTO. Prima la scatola si allineava "grossolanamente"
            # all'arco allargandosi sui due assi: sui settori a 45 gradi diventava
            # un quadrato che sporgeva sul calpestio da una parte e lasciava il
            # vuoto dall'altra. Con rot_y la sezione e' quella vera, sei centimetri.
            aggiungi(CX + raggio * math.cos(ang), calpestio + 0.50,
                     CZ + raggio * math.sin(ang),
                     0.07, 1.00, raggio * passo + 0.04, nome,
                     rot_y=-(ang + math.pi / 2.0))

    # IL VUOTO CENTRALE SI RIEMPIE, ed e' la risposta a due difetti insieme.
    # Con la sola scatola della montatura si camminava DENTRO il tubo - che e'
    # inclinato e passa proprio all'altezza di chi sta sulla passerella - e
    # entrandoci lo si vedeva da dentro. E sotto restava il pozzo centrale, alto
    # ottantuno centimetri: chi ci cadeva non ne usciva.
    # Un ottagono (due scatole a 45 gradi l'una dall'altra) riempie il cerchio
    # interno fino a filo del calpestio: dalla passerella lo strumento si guarda,
    # non ci si entra.
    # Il lato del quadrato inscritto vale il raggio per radice di due: cosi'
    # l'ottagono tocca il bordo interno del calpestio negli otto vertici e rientra
    # di ventotto centimetri a meta' faccia - una rientranza in cui una capsula da
    # sessanta non entra.
    _r_int = R_PASS - W_PASS / 2
    _lato = _r_int * math.sqrt(2.0)
    for _g in (0.0, math.pi / 4.0):
        aggiungi(CX, 1.30, CZ, _lato, 2.60, _lato, "Montatura", rot_y=_g)
    # montatura fissa: pilastro nel pavimento + tubo del telescopio.
    # Erano un nodo scritto a mano che pescava la mesh con idx[dims[0]], cioe' "la prima
    # dimensione della lista": si prendeva il blocco piu' sottile esistente - il recinto,
    # 0,15 x 1,40 x 30 m - e lo piantava in mezzo alla cupola. Nessun caso speciale.
    # Solo il pilastro: e' l'unica parte del telescopio che si trova all'altezza di
    # chi cammina. Il tubo vero e' inclinato e sta sopra la testa, e una collisione
    # a scatola nella posa sbagliata sarebbe peggio che nessuna collisione.
    aggiungi(CX, 0.50, CZ, 0.50, 1.00, 0.50, "Pilastro")

    # Rampa dritta, radiale. La variante a elle e' stata provata e scartata: il
    # pianerottolo mangiava la fascia fra passerella e muro invece di liberarla.
    #
    # In produzione la mesh avra' i gradini veri; QUESTA resta la collisione,
    # perche' un CharacterBody3D non fa step-up (D-033).
    DISL, LUNGO = DISL_RAMPA, LUNGO_RAMPA
    _ang = _m.atan2(DISL, LUNGO)
    _piede = CZ + R_PASS + W_PASS / 2 + LUNGO
    aggiungi(CX, DISL / 2 - 0.10 / _m.cos(_ang), _piede - LUNGO / 2,
             1.10, 0.20, _m.hypot(DISL, LUNGO), "Rampa", rot_x=-_ang)

    return blocchi


def blocchi_infissi():
    """Telai, ante, vetri e davanzali di ogni porta e finestra.

    Sta fuori da blocchi_edificio() apposta: il blockout Godot vuole i vani VUOTI,
    per poterci passare. Gli infissi servono al modello, non alla camminata.
    """
    _, aperture, _, _, _, _ = scalati()
    TS = 0.08          # sezione del telaio
    SPT = SP + 0.02    # il telaio sborda di un centimetro per lato
    ANTA = 0.045
    blocchi = []

    def aggiungi(cx, cy, cz, sx, sy, sz, nome):
        if sx > 0.005 and sy > 0.005 and sz > 0.005:
            blocchi.append((cx, cy, cz, sx, sy, sz, nome, 0.0))

    for (px_, pz, w, o, t, nome) in aperture:
        porta = (t == "porta")
        if porta:
            y0, y1 = 0.0, H_ARCH
        else:
            y0, y1 = (V_SILL, V_TOP) if t == "vetrata" else (W_SILL, W_TOP)
        h = y1 - y0
        m = px_ + w / 2 if o == "h" else pz + w / 2      # mezzeria lungo il vano
        fisso = pz if o == "h" else px_

        def posa(centro_lungo, cy, lungo, alto, nome_, spess=SPT):
            """lungo = dimensione nel senso del vano, alto = verticale.
            `spess` e' la profondita' nel muro: il telaio la occupa tutta, il vetro no."""
            if o == "h":
                aggiungi(centro_lungo, cy, fisso, lungo, alto, spess, nome_)
            else:
                aggiungi(fisso, cy, centro_lungo, spess, alto, lungo, nome_)

        # montanti verticali, traversa in alto, e in basso solo per le finestre
        # un'anta di lamiera non sta in un telaio di legno: il controtelaio segue l'anta
        tel = "TelaioMet" if nome in PORTE_METALLO else "Telaio"
        posa(px_ + TS / 2 if o == "h" else pz + TS / 2, y0 + h / 2, TS, h, tel)
        posa((px_ + w - TS / 2) if o == "h" else (pz + w - TS / 2), y0 + h / 2, TS, h, tel)
        posa(m, y1 - TS / 2, w - 2 * TS, TS, tel)
        if not porta:
            posa(m, y0 + TS / 2, w - 2 * TS, TS, tel)

        luce_l, luce_h = w - 2 * TS, h - (TS if porta else 2 * TS)
        if porta:
            pass          # le ante le fa ante_porte(): ruotano, quindi vogliono un perno
        else:
            # UN SERRAMENTO LARGO SI DIVIDE. Oltre il metro e dieci di luce nessun
            # infisso reale e' una lastra sola: i montanti intermedi sono quello che
            # fa leggere una vetrata come un serramento invece che come un buco.
            campate = max(1, int(math.ceil(luce_l / 1.10)))
            passo = luce_l / campate
            l0 = (px_ if o == "h" else pz) + TS
            cy_luce = y0 + TS + luce_h / 2
            for k in range(1, campate):
                posa(l0 + k * passo, cy_luce, TS, luce_h, "Telaio")
            # e il vetro sta AL CENTRO del telaio, spesso 16 mm: e' una lastra
            for k in range(campate):
                posa(l0 + (k + 0.5) * passo, cy_luce,
                     passo - (TS if campate > 1 else 0.0), luce_h, "Vetro", SP_VETRO)
            # davanzale: sporge di 5 cm e deborda di 5 per lato. Non sulla vetrata interna.
            if t != "vetrata":
                if o == "h":
                    aggiungi(m, y0 - 0.02, fisso, w + 0.10, 0.04, SP + 0.10, "Davanzale")
                else:
                    aggiungi(fisso, y0 - 0.02, m, SP + 0.10, 0.04, w + 0.10, "Davanzale")
    return blocchi


def ante_porte(apertura_gradi=0.0):
    """Le ante, una per una, con il loro CARDINE.

    Non sono volumi centrati come il resto: un'anta ruota, e un pezzo che ruota si
    descrive dal perno. E' la stessa regola dei portelli della cupola — con l'origine
    altrove l'anta si stacca dal telaio appena la si apre.

    Restituisce dizionari con il perno in coordinate di gioco (X, altezza, Z), la
    direzione dell'anta chiusa, la normale verso cui si apre, e le misure.
    """
    _, aperture, _, _, _, _ = scalati()
    TS, ANTA = 0.08, 0.045
    ante = []
    for (px_, pz, w, o, t, nome) in aperture:
        if t != "porta":
            continue
        cardine, verso = APERTURA_PORTE.get(nome, ("a", +1))
        a0, a1 = (px_ + TS, px_ + w - TS) if o == "h" else (pz + TS, pz + w - TS)
        lung = a1 - a0
        perno_lungo = a0 if cardine == "a" else a1
        segno_lungo = +1.0 if cardine == "a" else -1.0        # dove si estende l'anta da chiusa
        if o == "h":
            perno = (perno_lungo, 0.0, pz)
            direzione = (segno_lungo, 0.0, 0.0)
            normale = (0.0, 0.0, float(verso))
        else:
            perno = (px_, 0.0, perno_lungo)
            direzione = (0.0, 0.0, segno_lungo)
            normale = (float(verso), 0.0, 0.0)
        # oltre 1,60 di luce servirebbero due ante: nessun battente reale e' cosi' largo
        if lung > 1.60:
            for meta, (perno_m, segno_m) in enumerate(((a0, +1.0), (a1, -1.0))):
                p_m = (perno_m, 0.0, pz) if o == "h" else (px_, 0.0, perno_m)
                d_m = (segno_m, 0.0, 0.0) if o == "h" else (0.0, 0.0, segno_m)
                ante.append({
                    "nome": "%s %d" % (nome, meta + 1), "perno": p_m, "direzione": d_m,
                    "normale": normale, "larghezza": lung / 2.0,
                    "altezza": H_ARCH - TS, "spessore": ANTA, "apertura": apertura_gradi,
                })
            continue
        ante.append({
            "nome": nome, "perno": perno, "direzione": direzione, "normale": normale,
            "larghezza": lung, "altezza": H_ARCH - TS, "spessore": ANTA,
            "apertura": apertura_gradi, "maniglione": nome in MANIGLIONE,
            "metallo": nome in PORTE_METALLO,
        })
    return ante


def pezzi_anta(a):
    """Di che cosa e' fatta un'anta, in coordinate LOCALI: pannello e maniglione.

    Sta qui e non nel modellatore perche' l'anta esiste in due posti — la mesh in
    Blender e il nodo Door in gioco — e finche' il maniglione l'ha disegnato solo
    Blender, in gioco la porta era una tavola liscia.

    Ogni pezzo e' (lungo, alto, lato, sx, sy, sz, nome):
      lungo  distanza dal CARDINE
      alto   dal pavimento
      lato   scostamento dal piano dell'anta. NEGATIVO = faccia interna, quella
             opposta al verso di apertura. Ogni consumatore lo mappa sul proprio
             sistema di assi, che non e' lo stesso.
    """
    L, H_A, T = a["larghezza"], a["altezza"], a["spessore"]
    pezzi = [(L / 2, H_A / 2, 0.0, L, H_A, T, "Anta")]
    if a.get("maniglione"):
        # barra antipanico a 1,05 m sulla faccia interna: si spinge da dentro
        pezzi.append((L / 2, 1.05, -(T / 2 + 0.055), L - 0.20, 0.045, 0.035, "Maniglione"))
        for x in (0.13, L - 0.13):
            pezzi.append((x, 1.05, -(T / 2 + 0.028), 0.045, 0.075, 0.055, "Maniglione"))
    if a.get("metallo"):
        # LA LAMIERA NON E' UN COLORE, SONO LE NERVATURE. Un'anta pressopiegata ha
        # due bugne orizzontali stampate che la irrigidiscono, e sono loro a farla
        # leggere come lamiera: una lastra grigia liscia resta una porta di legno
        # dipinta di grigio. Stanno su tutte e due le facce perche' la piega passa
        # da parte a parte.
        for quota in (0.62, 1.42):
            for faccia in (+1.0, -1.0):
                # QUINDICI MILLIMETRI, non otto. A otto la nervatura c'era e non
                # si vedeva: senza occlusione ambientale un rilievo cosi' basso non
                # fa ombra, e l'anta tornava a leggere come una lastra liscia
                # verniciata di grigio. Un millimetro e mezzo e' anche la bugna
                # vera di una porta pressopiegata.
                pezzi.append((L / 2, quota, faccia * (T / 2 + 0.0075),
                              L - 0.10, 0.075, 0.015, "Lamiera"))
        # griglia di aerazione in basso: in un magazzino ci sta perche' dentro non
        # ci si ferma, e tre alette bastano a dirlo
        for k in range(3):
            for faccia in (+1.0, -1.0):
                pezzi.append((L / 2, 0.28 + k * 0.048, faccia * (T / 2 + 0.005),
                              L - 0.28, 0.026, 0.010, "Lamiera"))
        # maniglia a leva: rosetta vicino al bordo libero, leva che punta verso il
        # cardine - dall'altra parte sporgerebbe fuori dall'anta
        for faccia in (+1.0, -1.0):
            pezzi.append((L - 0.09, 1.05, faccia * (T / 2 + 0.006),
                          0.075, 0.135, 0.012, "Maniglia"))
            pezzi.append((L - 0.145, 1.05, faccia * (T / 2 + 0.048),
                          0.115, 0.028, 0.028, "Maniglia"))
        # PORTALUCCHETTO, e sta su una faccia sola: un magazzino si chiude da fuori.
        # Il lato negativo e' quello opposto al verso di apertura, cioe' quello da
        # cui si spinge - che per una porta che si apre verso l'interno e' proprio
        # il fuori. E' il pezzo che, da solo, dice che locale c'e' dietro.
        pezzi.append((L - 0.10, 0.88, -(T / 2 + 0.008), 0.130, 0.055, 0.016, "Maniglia"))
        pezzi.append((L - 0.10, 0.825, -(T / 2 + 0.014), 0.048, 0.060, 0.026, "Maniglia"))
    return pezzi


# --- le ante dei mobili, che sono ante come quelle delle porte ----------------
#
# STESSO MECCANISMO, NON UNO NUOVO. Un'anta di armadietto ha esattamente i bisogni
# di un'anta di porta: gira attorno a un cardine, si guarda, si preme E, e non deve
# passare dentro chi l'ha aperta. Scriverne un secondo tipo avrebbe voluto dire due
# posti dove il comportamento puo' divergere - e il primo a divergere sarebbe stato
# proprio quello meno provato. In gioco sono nodi `Door` come tutti gli altri, e il
# banco `prova_ante.gd` li misura senza sapere che sono mobili.
#
# QUELLO CHE CAMBIA E' LA QUOTA. Una porta parte dal pavimento; un pensile appeso
# parte a un metro e quarantacinque. Da qui la voce in piu' nel dizionario, che per
# le porte vale zero.
#
# Le coordinate sono quelle del bagno, cioe' METRI DI GIOCO gia' scalati: il
# modello del bagno si innesta nella scena senza trasformazione, quindi qui e in
# `ARREDI_BAGNO` si parla la stessa lingua.
#
# IL CARDINE NON SI SCRIVE: SI CALCOLA DALL'IMPRONTA. Scritto a mano, era un numero
# uguale in due posti - qui e nel modellatore che disegna la cassa - e due numeri
# uguali in due posti diventano due numeri diversi al primo che ne muove uno. Basta
# spostare l'armadio di quattro centimetri per staccargli l'anta, e il giorno che
# succede nessuno guarda questa tabella. Qui si dichiara solo quello che
# dall'impronta non si ricava: DA CHE PARTE guarda il fronte, quante ante, di che
# tipo, e fra che quote.
#
# L'APERTURA E' MISURATA, non scelta: la stampa `tools/prova_porte.gd`, che prova la
# sagoma di ogni anta grado per grado contro tutto il resto della stanza. Novanta
# dove ci stanno; meno dove qualcosa e' nel giro, e allora il numero dice CHE COSA -
# perche' un'anta che si ferma a meta' senza motivo scritto, fra un anno, sembra un
# difetto.
#
#  arredo, dove guarda il fronte, quante ante, da che capo il cardine (conta solo
#  per l'anta singola), tipo, quota della base, cima, spessore, quanto si lascia
#  davanti alle maniglie, apertura in gradi
MOBILI_CON_ANTE = [
    # IL CARDINE STA A OVEST, ED E' IL PENSILE CHE SI E' SPOSTATO. Incernierato a
    # ovest con il mobile addossato al muro, il battente ruotava DENTRO il piano di
    # quel muro: a novanta gradi stava nel rivestimento, e si vedeva attraversare il
    # listello. La prima cura e' stata mettere il cardine dall'altro capo, e non era
    # la cura giusta - risolveva il taglio ma dava un mobile che si apre al
    # contrario di come lo aprirebbe chiunque ci stia davanti.
    #
    # Il cardine e' quello di prima; e' il pensile che ha smesso di stare
    # nell'angolo. Ventotto centimetri a est bastano perche' l'anta giri nel vuoto -
    # e non trenta, che l'attaccherebbero allo stipite della porta del bagno (il
    # vano comincia a 5,92).
    ("Pensile", "sud",   1, "a", "specchio", 1.450, 2.050, 0.018, 0.000, 90.0),
    ("Armadio", "ovest", 2, "a", "lamiera",  0.125, 1.825, 0.018, 0.070, 90.0),
]

# La fessura ai due capi di una fila di ante e quella fra un'anta e l'altra. Ai capi
# serve piu' larga: li' l'anta gira contro il fianco del mobile, e a filo ci
# sfregherebbe dentro.
FUGA_CAPO, FUGA_MEZZO = 0.012, 0.005

# Lo spessore del rivestimento del bagno. STA QUI e non solo nel modellatore perche'
# non e' un dettaglio di disegno: chi calcola dove cade il cardine di un'anta deve
# saperlo quanto chi disegna la cassa a cui quell'anta e' attaccata.
SPESS_PIASTRELLA = 0.012


def impronta_utile(nome):
    """L'impronta di un arredo del bagno, ARRETRATA dove tocca un muro.

    Un mobile addossato a un muro piastrellato non parte dal filo del muro: parte
    dal filo della piastrella, dodici millimetri piu' in dentro. Sembra niente e non
    lo e' - a filo muro la fuga passa DENTRO il mobile, e si vede da mezza stanza.

    QUESTO DIFETTO E' STATO CORRETTO TRE VOLTE, UNA FACCIA ALLA VOLTA: prima la
    schiena del pensile, poi il suo fianco ovest, poi il fianco sud dell'armadio.
    Ogni volta la meta' corretta nascondeva la meta' rotta, e ogni volta sembrava
    finita. Adesso l'arretramento lo fa la regola su OGNI lato che tocchi un muro, e
    non resta una faccia da dimenticare.

    Un lato che NON tocca il muro non si arretra: se l'impronta dichiara un mobile
    staccato dalla parete, quello stacco e' voluto e va rispettato.
    """
    impronte = {n: (a, b, c, d, e) for (n, a, b, c, d, e) in ARREDI_BAGNO}
    x0, z0, x1, z1, h = impronte[nome]
    rx0, rz0, rx1, rz1 = SALA_BAGNO[0]
    e = 1e-6
    if abs(x0 - rx0) < e:
        x0 += SPESS_PIASTRELLA
    if abs(x1 - rx1) < e:
        x1 -= SPESS_PIASTRELLA
    if abs(z0 - rz0) < e:
        z0 += SPESS_PIASTRELLA
    if abs(z1 - rz1) < e:
        z1 -= SPESS_PIASTRELLA
    return (x0, z0, x1, z1, h)


def ante_mobili():
    """Le ante degli arredi, nella stessa forma di `ante_porte()`.

    Torna gli stessi campi - perno, direzione, normale, misure - perche' il
    generatore ne fa una cosa sola: il verso di rotazione lo ricava da direzione e
    normale con la stessa formula, e sbagliarla in un posto solo la sbaglia per
    tutti, che e' esattamente quello che si vuole.
    """
    ante = []
    for (arredo, fronte, quante, capo, tipo, base, cima, T, sporge, apre) in MOBILI_CON_ANTE:
        x0, z0, x1, z1, _h = impronta_utile(arredo)
        # il piano del fronte, la direzione in cui l'anta si apre, e lungo quale
        # asse corre la fila delle ante
        piano, normale, lungo, asse = {
            "sud":   (z1, (0.0, 1.0), (x0, x1), "x"),
            "nord":  (z0, (0.0, -1.0), (x0, x1), "x"),
            "ovest": (x0, (-1.0, 0.0), (z0, z1), "z"),
            "est":   (x1, (1.0, 0.0), (z0, z1), "z"),
        }[fronte]
        nx, nz = normale
        # il cardine sta in mezzo allo spessore dell'anta, e l'anta sta appena
        # dentro il fronte: a filo, meno lo spazio lasciato alle maniglie
        dentro = sporge + T / 2.0
        fisso = piano - (nx if asse == "z" else nz) * dentro
        a0, a1 = lungo
        if quante == 1:
            tratti = [(a0, a1, capo)]
        else:
            meta = (a0 + a1) / 2.0
            tratti = [(a0 + FUGA_CAPO, meta - FUGA_MEZZO, "a"),
                      (meta + FUGA_MEZZO, a1 - FUGA_CAPO, "b")]
        for k, (b0, b1, da) in enumerate(tratti):
            perno_lungo = b0 if da == "a" else b1
            segno = 1.0 if da == "a" else -1.0
            nome = arredo.lower() + " bagno"
            if quante > 1:
                nome += " %d" % (k + 1)
            if asse == "x":
                perno, direzione = (perno_lungo, base, fisso), (segno, 0.0, 0.0)
            else:
                perno, direzione = (fisso, base, perno_lungo), (0.0, 0.0, segno)
            ante.append({
                "nome": nome, "perno": perno, "direzione": direzione,
                "normale": (nx, 0.0, nz), "larghezza": b1 - b0,
                "altezza": cima - base, "spessore": T,
                "quota": base, "tipo": tipo, "apertura": apre,
            })
    return ante


def pezzi_anta_mobile(a):
    """Di che cosa e' fatta un'anta di mobile, nelle stesse coordinate locali.

    `alto` si misura dalla BASE DELL'ANTA, non dal pavimento: il nodo in gioco sta
    gia' alla quota giusta, e ripetere l'offset qui vorrebbe dire sommarlo due volte.
    """
    L, HA, T = a["larghezza"], a["altezza"], a["spessore"]
    pezzi = [(L / 2, HA / 2, 0.0, L, HA, T, "Anta")]
    if a["tipo"] == "specchio":
        # LO SPECCHIO STA SULLA FACCIA CHE SI VEDE DA CHIUSA, cioe' quella verso cui
        # l'anta si apre: `lato` positivo. Sulla faccia sbagliata sarebbe uno
        # specchio rivolto dentro il mobile - visibile solo ad anta spalancata, che
        # e' il solo momento in cui a nessuno serve.
        pezzi.append((L / 2, HA / 2, T / 2 + 0.003, L - 0.10, HA - 0.10, 0.006, "Vetro"))
        # la cornice sporge attorno allo specchio: senza, sembra dipinto sull'anta
        for (lu, al, sx, sy) in ((L / 2, 0.025, L, 0.050), (L / 2, HA - 0.025, L, 0.050),
                                 (0.025, HA / 2, 0.050, HA), (L - 0.025, HA / 2, 0.050, HA)):
            pezzi.append((lu, al, T / 2 + 0.005, sx, sy, 0.010, "Anta"))
        # il pomello, vicino al bordo libero
        pezzi.append((L - 0.075, HA / 2, T / 2 + 0.022, 0.030, 0.030, 0.038, "Maniglia"))
        return pezzi
    # lamiera: le feritoie in alto, la maniglia a bastone e la serratura
    for k in range(3):
        y = HA - 0.135 - k * 0.05
        pezzi.append((L / 2, y, T / 2 + 0.005, L - 0.14, 0.018, 0.010, "Feritoia"))
        pezzi.append((L / 2, y + 0.009, T / 2 + 0.009, L - 0.126, 0.034, 0.006, "Anta"))
    # LA MANIGLIA STA SUL BORDO LIBERO, che per queste due ante e' quello verso il
    # centro dell'armadio: si aprono a libro, e le maniglie affiancate in mezzo sono
    # la firma di un armadio da spogliatoio.
    pezzi.append((L - 0.045, 0.865, T / 2 + 0.030, 0.022, 0.330, 0.022, "Maniglia"))
    for al in (0.700, 1.030):
        pezzi.append((L - 0.045, al, T / 2 + 0.016, 0.018, 0.018, 0.032, "Maniglia"))
    pezzi.append((L - 0.115, 0.995, T / 2 + 0.006, 0.026, 0.026, 0.012, "Maniglia"))
    return pezzi


# --- arredi della sala di controllo -----------------------------------------
# L'IMPRONTA STA QUI, IL DETTAGLIO NO. Ogni voce e' il volume che il giocatore
# non attraversa: (nome, x0, z0, x1, z1, altezza) in metri reali di gioco.
# Il modellatore Blender ci costruisce dentro monitor, sedie e cavi, ma non puo'
# uscirne: cosi' quello che si vede e quello contro cui si sbatte sono la stessa
# cosa. E' la stessa divisione fra blocchi_edificio() e il modello dell'edificio.
#
# LA CONSOLLE STA SOTTO LA VETRATA, e non e' una scelta di stile: chi lavora
# siede rivolto al telescopio, e alzando gli occhi dal monitor lo vede. Girata
# verso qualunque altro muro, la vetrata sarebbe alle spalle di chi la usa.
#
# La sala e' netta x 5,30..8,15 e z 0,10..4,30 (2,85 x 4,20 m, 12 m2).
ARREDI_PC = [
    ("Consolle",  5.30, 1.20, 6.00, 4.00, 0.75),   # sotto la vetrata, due postazioni
    ("Rack",      7.55, 0.70, 8.15, 1.50, 1.80),   # elettronica di acquisizione
    ("Schedario", 7.55, 1.70, 8.15, 2.25, 1.35),   # classificatore metallico
    ("Mobile",    6.10, 0.10, 7.50, 0.55, 0.85),   # sotto la finestra nord, con la stampante
    # UNA POSTAZIONE SOLA. Erano due, e la seconda non serviva a niente: due monitor
    # per un turno di una persona. Il resto dei 2,80 m di piano regge quello che si
    # posa su una consolle - telefono, registro, stampati, lampada.
    # LA SEDIA NON STA PIU' IN FONDO ALLA CONSOLLE, e non e' un dettaglio: la
    # postazione si costruisce attorno a lei, e in fondo alla consolle il mouse non
    # ci stava. Chi si siede guarda la vetrata, cioe' verso -X, e la sua destra cade
    # su -Z: con la sedia in mezzeria su 1,59 restavano trentanove centimetri di
    # piano a destra, e la tastiera da sola ne occupa quarantasette. Il mouse
    # finiva a sbalzo oltre il bordo - il controllo delle impronte lo diceva, e
    # per due sessioni non l'ha letto nessuno perche' il modello continuava a
    # esistere: era quello vecchio. Spostata a 2,00 restano ottanta centimetri a
    # destra, che e' quanto serve per posarci un mouse.
    ("Sedia1",    6.02, 1.69, 6.64, 2.31, 1.05),   # 62 x 62: la misura di una girevole vera
]

# La cucina e' netta x 8,35..13,30 e z 1,60..4,00: quasi cinque metri per due e
# quaranta, cioe' un CORRIDOIO. Non ci sta una cucina abitabile con il tavolo in
# mezzo, ci sta una cucina in linea: tutto su un lato, il passaggio sull'altro, e
# il tavolino spinto nell'angolo che la porta non spazza.
#
# Non ha finestre. Nessuno dei suoi quattro muri ne ha una: il nord e' perimetrale
# e libero, quindi si potrebbe aprire, ma la pianta non lo prevede e cambiarla non
# faceva parte di quello che era chiesto.
ARREDI_CUCINA = [
    ("CucinaBase",  8.35, 1.60, 11.60, 2.20, 0.90),   # lavello, cottura, pensili sopra
    ("Frigo",      11.70, 1.60, 12.30, 2.25, 1.55),
    ("Dispensa",   12.40, 1.60, 13.30, 2.20, 2.00),
    # LE SEDIE STANNO AI CAPI DEL TAVOLO, non sul lato lungo. Messe davanti, fra
    # loro e il bancone restavano 65 cm: sopra i 60 del giocatore per cinque
    # centimetri, cioe' un passaggio che il controllo accetta e le gambe no.
    # Ai capi, il corridoio nord passa da 0,65 a 1,15 m.
    ("Tavolo",     11.60, 3.35, 12.80, 4.00, 0.78),
    ("SediaC1",    11.05, 3.40, 11.55, 3.90, 0.92),
    ("SediaC2",    12.80, 3.40, 13.30, 3.90, 0.92),
    ("Pattumiera",  8.40, 3.60,  8.75, 3.95, 0.60),   # dietro la porta, dove non da' fastidio
    # La bacheca e' spessa 4 cm e sta appesa al muro sud: entra fra gli arredi solo
    # perche' anche una cosa appesa deve stare dentro un'impronta, altrimenti il
    # controllo delle mesh non la vede e puo' crescere quanto vuole.
    ("Bacheca",    10.30, 3.96, 11.30, 4.00, 1.95),
]


# LO SPAZIO DIVULGAZIONE NON E' UN RETTANGOLO: e' quello che resta dell'ala est
# tolte la cucina e la segreta, cioe' una elle. Si descrive con tre rettangoli che
# si toccano, e i controlli lavorano sulla loro unione — un rettangolo solo avrebbe
# dichiarato praticabile mezza cucina.
ARREDI_DIVULGAZIONE = [
    # DAVANTI ALLA CUCINA la libreria di astronomia, come dice il GDD: sta sul muro
    # della cucina ma dalla parte della sala, e comincia dopo la porta.
    ("Libreria",     10.30, 4.20, 13.30, 4.55, 2.10),
    ("Meteoriti",    11.60, 9.00, 14.20, 9.40, 1.90),   # la bacheca del GDD, muro sud
    # Le teche a isola stavano in mezzo alla sala e sono state tolte: il centro
    # dello spazio divulgazione resta vuoto, che e' quello che dice di piu' su una
    # sala aperta al pubblico in un posto dove il pubblico non viene.
    # 0,78 di profondita' per 0,85 di fronte, alto 1,83: sono le misure di un
    # distributore di snack vero. A 0,75 x 0,75 era una macchinetta in scala.
    ("Distributore",  8.35, 6.35,  9.13, 7.20, 1.83),   # alla giunzione fra i due corpi
    # LA PARTE PIU' A EST E' LA SALA PROIEZIONI, e non e' una zona qualsiasi: e' un
    # blocco di 4,15 x 7,80 che il volume dell'ala gia' definisce. Schermo sul muro
    # nord — l'unico tratto di parete senza aperture — tre file di sedie rivolte a
    # nord, e il proiettore su carrello dietro l'ultima fila.
    #
    # Le sedie stavano al centro della sala: sbagliato, e detto da Federico. Al centro
    # erano sedie appoggiate in mezzo a niente; qui sono una sala dentro la sala.
    # LE FILE SONO LARGHE 2,20 E NON 2,60, e la differenza sono i due corridoi
    # laterali: 0,65 a ovest e 0,70 a est. A 2,60 fra le sedie e la teca est
    # restavano 30 cm, e dietro la teca si apriva un metro e settanta di pavimento
    # raggiungibile solo strisciando — il controllo l'ha misurato in 0,48 m2.
    # DUE FILE, NON TRE, E UN TAVOLO DAVANTI: e' cosi' che sta l'osservatorio vero.
    # Il tavolo del relatore non e' un arredo in piu' — e' quello che spiega le sedie.
    ("Schermo",      15.30, 1.60, 17.70, 1.74, 2.30),
    ("TavoloSala",   15.40, 2.70, 17.60, 3.50, 0.78),
    ("FilaSedie1",   15.40, 4.60, 17.60, 5.14, 0.90),
    ("FilaSedie2",   15.40, 5.50, 17.60, 6.04, 0.90),
    ("Proiettore",   16.10, 6.80, 16.90, 7.40, 1.05),
    # le teche a muro restano sul lato est, ai due capi della sala proiezioni
    ("TecaEst1",     18.30, 1.70, 18.90, 3.60, 1.85),
    ("TecaEst2",     18.30, 6.00, 18.90, 7.90, 1.85),
]

# Ogni stanza arredata: nome, ELENCO di rettangoli netti (x0, z0, x1, z1), mobili.
# Aggiungerne una significa aggiungere una riga qui: i controlli, la collisione nel
# blockout e il conto dei pezzi la prendono da sola.
# --- il bagno ----------------------------------------------------------------
# 3,15 x 2,80 al netto, con la porta sul muro nord (che si apre DENTRO, verso ovest)
# e la finestra al centro del muro sud. Da quei due vincoli discende tutto il resto:
# la parete est e' l'unica libera per tutta la sua lunghezza ed e' li' che vanno i
# sanitari in fila; la parete ovest la prende il lavabo, che dev'essere fuori dal
# giro dell'anta; sotto la finestra ci sta solo roba bassa, cioe' il termosifone.
#
# SENZA VASCA, per richiesta. E nemmeno la doccia, che era il primo rimpiazzo e non
# reggeva: in un osservatorio non ci si lava, ci si lavora. L'angolo sud-est lo
# prende un armadio di lamiera da locale tecnico.
#
# L'INTERASSE WC-BIDET E' 75 CM e non e' un numero a caso: sotto i 55 non ci si
# siede, sopra gli 80 la parete sembra vuota in mezzo. Settantacinque e' la misura
# che si trova nei bagni veri di quegli anni.
SALA_BAGNO = [(5.00, 6.60, 8.15, 9.40)]
ARREDI_BAGNO = [
    # parete est, in fila da nord a sud: wc, bidet, armadio
    # 46 cm di larghezza e non 40: `posa_modello` scala sull'altezza e poi
    # rimpicciolisce finche' l'ingombro in pianta ci sta, e a 40 il water usciva
    # alto 68 cm invece di 78. Sei centimetri di impronta valgono dieci di water.
    #
    # E ADESSO SONO PIU' GRANDI DEL VERO, DI UN QUARTO ABBONDANTE. Non e' una svista:
    # e' il secondo giro sulla stessa lamentela. Il primo giro i sanitari si sono
    # MISURATI - water 0,78, lavabo 0,86, i numeri veri al centimetro - e il colpevole
    # era il rivestimento, che a 7,5 cm per piastrella faceva da righello sbagliato.
    # Corretto quello, sembrano piccoli lo stesso. Quello che resta e' l'ottica: la
    # camera del giocatore sta al campo visivo di fabbrica, 75 gradi in verticale,
    # cioe' 107 in orizzontale su 16:9, e a quell'apertura quello che sta al centro
    # dello schermo si allontana. Sotto tre metri di soffitto un water di misura
    # esatta legge come un water da bambini. Qui si sceglie di sbagliare la MISURA
    # invece che l'IMPRESSIONE: chi ci gioca non ha il metro in mano, e l'unica prova
    # che conta e' guardarli da dentro la stanza.
    ("Wc",          7.31, 6.84, 8.15, 7.48, 1.10),
    ("Bidet",       7.39, 7.70, 8.15, 8.16, 0.83),
    # NIENTE DOCCIA. C'era, ed era la risposta sbagliata alla domanda «cosa ci metto
    # al posto della vasca»: qui non ci si lava, e' il bagno di servizio di un
    # osservatorio, non una camera d'albergo. Al suo posto un armadio di lamiera da
    # locale tecnico - detersivi, ricambi, il camice - che e' quello che in un posto
    # cosi' sta davvero in bagno.
    # 7,58 e non 7,65: le maniglie a bastone sporgono cinque centimetri dall'anta,
    # e l'impronta deve contenere quello che si tocca, non la cassa.
    # E NON ARRIVA AL MURO SUD. Ci arrivava, ed erano due difetti in uno: il fianco
    # finiva dentro le piastrelle - `impronta_utile` adesso lo arretrerebbe da solo -
    # ma soprattutto un armadio incastrato nell'angolo contro il muro della finestra
    # sembra murato. Spostato di sei centimetri a nord: restano cinque centimetri di
    # luce fra il fianco e la piastrella, che e' quanto basta perche' si legga come
    # un mobile appoggiato li' invece che costruito li'.
    ("Armadio",     7.58, 8.44, 8.15, 9.34, 1.85),
    # parete ovest: il lavabo con lo specchio e la mensola sopra, tutto in una
    # impronta sola - sono un pezzo unico per chi ci sbatte contro
    ("Lavabo",      5.00, 8.06, 5.67, 8.96, 1.90),
    # muro nord, a OVEST della porta e non a est: il vano va da 5,80 a 7,10 e il
    # perno sta a 7,02, quindi l'anta spazza il quadrante verso ovest fino a 1,14 m.
    # Messo a est era addosso al cardine e il controllo l'ha preso in pieno.
    ("Pensile",     5.28, 6.60, 5.88, 6.92, 2.05),
    # sotto la finestra, e piu' basso del davanzale: un termosifone davanti a un
    # vetro e' normale, un mobile no. Allineato al vano vero, che va da 6,20 a 7,20.
    # 20 cm di profondita' e non 15: un radiatore di ghisa a due colonne e'
    # profondo tredici centimetri e sta staccato dal muro di quattro, o non ci
    # passa la mano per pulirci dietro. Con quindici le colonne uscivano
    # dall'impronta.
    # PIU' LARGA DEL VANO, e la larghezza e' quella che comanda: `posa_modello`
    # scala sull'altezza e poi rimpicciolisce finche' l'ingombro in pianta ci sta,
    # e su questo radiatore vince sempre la pianta. Con un metro netto usciva alto
    # 67 cm, cioe' un radiatore da bagnetto.
    #
    # E PIU' DI COSI' NON PUO' CRESCERE, in nessuna delle due direzioni, ed e' stato
    # misurato invece che temuto:
    #   * verso EST c'e' l'anta dell'armadio, che aperta arriva a 7,226: oltre 7,20
    #     il radiatore glielo mette davanti;
    #   * verso OVEST c'e' il passaggio fra il lavabo e il radiatore, e a 6,08 si
    #     chiude. Il controllo delle sacche lo dice - "0,01 m2 non raggiungibili
    #     a piedi" - e a 6,14 tace: fra i due c'e' il mezzo centimetro che separa
    #     una stanza percorribile da un angolo murato.
    # Quello che resta e' ALZARLO. Un ghisa a colonne sta su mensole, non per terra,
    # e dieci centimetri di stacco portano la sua cima da 0,67 a 0,81 - che e' il
    # numero che si vede da un metro, molto piu' della larghezza.
    ("Termo",       6.14, 9.20, 7.20, 9.40, 0.85),
    # IL DISTRIBUTORE DI CARTA, e prima era un portasciugamani. L'asciugamano era
    # geometria buona - la piega sopra la barra, due falde di lunghezza diversa,
    # l'onda del telo - con addosso una TINTA PIATTA: in `TEXTURE` non c'era la
    # spugna, e da un metro leggeva come un cartoncino verde appeso a un filo. La
    # via corta sarebbe stata cercare una texture di spugna; quella giusta e'
    # chiedersi cosa ci sta davvero in un bagno di servizio di un osservatorio, e
    # non e' un asciugamano di casa - e' il distributore di carta a muro, che e'
    # lamiera verniciata, cioe' un materiale che questo progetto ha gia'.
    # PROFONDO VENTICINQUE CENTIMETRI, e non e' un errore: questo non e' il
    # distributore piatto da salviette piegate, e' quello a ROTOLO con la leva, che
    # dentro ci deve tenere una bobina. Il modello lo dice da solo - largo 0,30,
    # alto 0,36, profondo 0,23 - e sono le misure di un apparecchio vero.
    # SPOSTATO A SUD di ventidue centimetri rispetto a dove stava la barra degli
    # asciugamani: piu' profondo, entrava nel giro dell'anta del pensile, che dal
    # suo cardine a 5,28 arriva fino a z 7,51. Da 7,60 in giu' quel giro non ci
    # arriva piu'.
    ("Distributore", 5.00, 7.60, 5.25, 7.94, 1.58),
    # IL PORTAROTOLO, sul muro nord a fianco del water. Non e' un ornamento: un
    # water senza portarotolo accanto legge come un sanitario da catalogo, non come
    # un cesso in servizio. Sta a NORD e non a est perche' il muro est ce l'ha tutto
    # occupato - fra water e bidet restano ventidue centimetri - e perche' seduti si
    # guarda a ovest, quindi il muro nord cade a portata di mano destra.
    ("Portarotolo",  7.55, 6.60, 7.85, 6.75, 0.86),
]

SALA_PC = [(5.30, 0.10, 8.15, 4.30)]
SALA_CUCINA = [(8.35, 1.60, 13.30, 4.00)]
SALA_DIVULGAZIONE = [
    (8.35, 4.20, 13.30, 4.85),      # la striscia sotto la cucina
    (8.35, 4.85, 18.90, 9.40),      # la fascia sud, per tutta la larghezza
    (14.75, 1.60, 18.90, 4.85),     # il volume grande a est, oltre la segreta
]
STANZE_ARREDATE = [
    ("controllo pc", SALA_PC, ARREDI_PC),
    ("cucina", SALA_CUCINA, ARREDI_CUCINA),
    ("divulgazione", SALA_DIVULGAZIONE, ARREDI_DIVULGAZIONE),
    ("bagno", SALA_BAGNO, ARREDI_BAGNO),
]


def arredi():
    """Gli arredi come volumi di collisione: (cx, cy, cz, sx, sy, sz, nome, 0, 0).

    Stessa forma dei blocchi dell'edificio, cosi' il generatore del blockout li
    tratta senza casi speciali. Stanno FUORI da blocchi_edificio() apposta: quella
    la legge anche il modello architettonico, che non deve ritrovarsi le sedie
    come scatole grigie.
    """
    fuori = []
    for (_stanza, _sala, elenco) in STANZE_ARREDATE:
        for (nome, x0, z0, x1, z1, alt) in elenco:
            fuori.append(((x0 + x1) / 2, alt / 2, (z0 + z1) / 2,
                          x1 - x0, alt, z1 - z0, nome, 0.0, 0.0))
    return fuori


def verifica_arredi(raggio=0.32, passo=0.05):
    """Tutte le stanze arredate, una per una."""
    problemi = []
    for (stanza, sala, elenco) in STANZE_ARREDATE:
        for p in verifica_stanza(sala, elenco, raggio, passo):
            problemi.append("%s [%s]" % (p, stanza))
    return problemi


def verifica_stanza(sala, elenco, raggio=0.32, passo=0.05):
    """Quattro modi in cui un arredo puo' rovinare una stanza, tutti misurati.

    1. sta dentro la stanza e non dentro un muro
    2. non compenetra un altro arredo
    3. non finisce sotto un'anta che si apre — le porte qui non hanno collisione
       contro i mobili, quindi ci passerebbero attraverso senza dire niente
    4. non tappa un'apertura: davanti a una finestra o alla vetrata puo' starci
       solo roba piu' bassa del davanzale, o il vetro serve a guardare un mobile
    5. ci si passa: erodendo lo spazio libero del raggio del giocatore (0,30 m)
       quel che resta deve essere tutto collegato, senza sacche irraggiungibili
    """
    from collections import deque
    problemi = []
    pezzi = list(elenco)
    X0 = min(r[0] for r in sala); Z0 = min(r[1] for r in sala)
    X1 = max(r[2] for r in sala); Z1 = max(r[3] for r in sala)

    def nella_sala(x, z):
        for (a, b, c, d) in sala:
            if a - 1e-9 <= x <= c + 1e-9 and b - 1e-9 <= z <= d + 1e-9:
                return True
        return False

    for (nome, x0, z0, x1, z1, _h) in pezzi:
        # tutti e quattro gli angoli devono cadere nell'unione, non nel suo contorno:
        # in una elle il rettangolo che li contiene tutti contiene anche le altre stanze
        if not all(nella_sala(x, z) for x in (x0, x1) for z in (z0, z1)):
            problemi.append("  ARREDO NEL MURO   %-10s (%.2f,%.2f)-(%.2f,%.2f) esce dalla sala"
                            % (nome, x0, z0, x1, z1))

    for i in range(len(pezzi)):
        for j in range(i + 1, len(pezzi)):
            a, b = pezzi[i], pezzi[j]
            sx = min(a[3], b[3]) - max(a[1], b[1])
            sz = min(a[4], b[4]) - max(a[2], b[2])
            if sx > 1e-6 and sz > 1e-6:
                problemi.append("  ARREDI SOVRAPPOSTI %-10s e %-10s per %.2f x %.2f m"
                                % (a[0], b[0], sx, sz))

    # 3. spazzata delle ante che si aprono dentro la sala
    for a in ante_porte():
        px, _, pz = a["perno"]
        if not (X0 - SP <= px <= X1 + SP and Z0 - SP <= pz <= Z1 + SP):
            continue
        nx, _, nz = a["normale"]
        dx, _, dz = a["direzione"]
        raggio_anta = a["larghezza"]
        for (nome, x0, z0, x1, z1, _h) in pezzi:
            # il punto dell'arredo piu' vicino al cardine
            qx = min(max(px, x0), x1)
            qz = min(max(pz, z0), z1)
            if math.hypot(qx - px, qz - pz) > raggio_anta:
                continue
            # e dentro il quadrante spazzato: componenti positive su direzione e normale
            vx, vz = qx - px, qz - pz
            if vx * dx + vz * dz >= -1e-9 and vx * nx + vz * nz >= -1e-9:
                problemi.append("  L'ANTA CI SBATTE  %-10s e' nella spazzata di %s"
                                % (nome, a["nome"]))

    # 4. niente di alto davanti a un'apertura
    _, aperture, _, _, _, _ = scalati()
    for (px_, pz_, w, o, t, nome_ap) in aperture:
        if t == "porta":
            continue
        sotto = V_SILL if t == "vetrata" else W_SILL
        if o == "h":
            ax0, ax1, az0, az1 = px_, px_ + w, pz_ - 0.60, pz_ + 0.60
        else:
            ax0, ax1, az0, az1 = px_ - 0.60, px_ + 0.60, pz_, pz_ + w
        for (nome, x0, z0, x1, z1, h) in pezzi:
            if min(x1, ax1) - max(x0, ax0) > 1e-6 and min(z1, az1) - max(z0, az0) > 1e-6:
                if h > sotto + 1e-6:
                    problemi.append("  TAPPA IL VETRO    %-10s alto %.2f davanti a %s (davanzale %.2f)"
                                    % (nome, h, nome_ap, sotto))

    # 5. si passa dappertutto
    nx_ = int((X1 - X0) / passo)
    nz_ = int((Z1 - Z0) / passo)
    def centro(i, j):
        return X0 + (i + 0.5) * passo, Z0 + (j + 0.5) * passo
    occupata = [[False] * nz_ for _ in range(nx_)]
    for i in range(nx_):
        for j in range(nz_):
            x, z = centro(i, j)
            occupata[i][j] = (not nella_sala(x, z)) or any(
                x0 <= x <= x1 and z0 <= z <= z1
                for (_n, x0, z0, x1, z1, _h) in pezzi)
    # erosione: una cella e' percorribile se il giocatore ci sta con il suo raggio
    r = int(math.ceil(raggio / passo))
    libera = [[False] * nz_ for _ in range(nx_)]
    for i in range(nx_):
        for j in range(nz_):
            ok = True
            for di in range(-r, r + 1):
                for dj in range(-r, r + 1):
                    if (di * passo) ** 2 + (dj * passo) ** 2 > raggio * raggio:
                        continue
                    a, b = i + di, j + dj
                    if not (0 <= a < nx_ and 0 <= b < nz_) or occupata[a][b]:
                        ok = False
                        break
                if not ok:
                    break
            libera[i][j] = ok
    partenze = [(i, j) for i in range(nx_) for j in range(nz_) if libera[i][j]]
    if not partenze:
        problemi.append("  SALA IMPRATICABILE nessun punto in cui il giocatore ci stia")
        return problemi
    vis = {partenze[0]}
    coda = deque([partenze[0]])
    while coda:
        i, j = coda.popleft()
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, b = i + di, j + dj
            if 0 <= a < nx_ and 0 <= b < nz_ and libera[a][b] and (a, b) not in vis:
                vis.add((a, b)); coda.append((a, b))
    if len(vis) < len(partenze):
        persi = (len(partenze) - len(vis)) * passo * passo
        # DOVE, non solo quanto. "0,01 m2 non raggiungibili" e' un numero che non si
        # puo' andare a guardare: costringe a rifare a mano il conto della griglia
        # per sapere in che angolo cercare. Con le coordinate ci si va e si vede.
        fuori = [centro(i, j) for (i, j) in partenze if (i, j) not in vis]
        dove = "  ".join("%.2f,%.2f" % c for c in fuori[:4])
        if len(fuori) > 4:
            dove += " e altre %d" % (len(fuori) - 4)
        problemi.append("  SACCA ISOLATA     %.2f m2 di pavimento non raggiungibili a piedi"
                        % persi + " (in %s)" % dove)
    return problemi


def punto_libero(x, z, margine=0.0):
    """Vero se (x, z) non cade dentro un muro PIENO. Coordinate di gioco, metri reali.

    Le aperture non sono muro: un'anta che ruota resta dentro il proprio vano per i
    primi gradi, e contarlo come ostacolo boccerebbe ogni porta dell'edificio.
    """
    muri, aperture, _, _, _, _ = scalati()
    for (x0, z0, x1, z1) in muri:
        orizz = abs(z1 - z0) < 1e-9
        fisso = z0 if orizz else x0
        lungo, trasv = (x, z) if orizz else (z, x)
        a, b = (min(x0, x1), max(x0, x1)) if orizz else (min(z0, z1), max(z0, z1))
        if not (a - margine <= lungo <= b + margine and abs(trasv - fisso) <= SP / 2 + margine):
            continue
        nel_vano = any(
            (o == "h") == orizz and abs((pz if orizz else px_) - fisso) < 0.01
            and (px_ if orizz else pz) <= lungo <= (px_ if orizz else pz) + w
            for (px_, pz, w, o, t, nm) in aperture)
        if not nel_vano:
            return False
    return True


def verifica_ante():
    """Ogni anta spalancata deve trovare il vuoto, non un muro."""
    problemi = []
    for a in ante_porte():
        px, _, pz = a["perno"]
        nx, _, nz = a["normale"]
        dx, _, dz = a["direzione"]
        L = a["larghezza"] * 0.92
        # si spazza tutto l'arco, non due punti soli: l'anta puo' passare libera a
        # meta' corsa e trovare il tramezzo poco piu' avanti
        import math as _m
        fermata = None
        for passo in range(1, 13):                 # da 7,5 a 90 gradi
            ang = _m.radians(90.0 * passo / 12.0)
            ux = dx * _m.cos(ang) + nx * _m.sin(ang)
            uz = dz * _m.cos(ang) + nz * _m.sin(ang)
            for r in (L * 0.55, L):                # meta' anta e bordo libero
                if not punto_libero(px + ux * r, pz + uz * r):
                    fermata = 90.0 * passo / 12.0
                    break
            if fermata:
                break
        if fermata:
            problemi.append("  ANTA CONTRO IL MURO  %-20s si ferma a %.0f gradi" % (a["nome"], fermata))
    return problemi


# --- impianto luce ----------------------------------------------------------
# LA LUCE DEVE AVERE UN APPARECCHIO E UN COMANDO. Le OmniLight3D stavano in
# gen_blockout.py, dieci punti a mezz'aria e basta: nessuna plafoniera sopra,
# nessun interruttore su un muro. Una stanza illuminata da niente e accesa da
# niente e' l'unica cosa magica di un gioco che non ha magie.
#
# I punti stanno qui e non nel generatore per la stessa ragione di tutto il
# resto: il modellatore delle plafoniere e il generatore del blockout devono
# leggere le STESSE coordinate, o la lampada e la luce finiscono in due posti.
# Coordinate di pianta (si scalano); l'altezza no, e' il soffitto.
PUNTI_LUCE = [
    (13.4, 5.0, "pc"), (13.4, 11.5, "corridoio"),
    (21.5, 5.5, "cucina"),
    # TRE, E NON CINQUE. Il buio fra una lampada e l'altra l'avevo curato
    # aggiungendo lampade, ed era la cura sbagliata: cinque plafoniere in una
    # sala di servizio sono un negozio. Il buio fra le lampade si toglie con la
    # portata e l'energia, che sono numeri, non con altri apparecchi a soffitto.
    (22, 12, "divulg1"), (32, 8, "divulg2"), (32, 16, "divulg3"),
    (13, 16, "bagno"), (8, 16, "magazzino"), (2.2, 16, "disimp"),
]
# le stanze profonde in Z e strette in X: li' la plafoniera va girata di novanta
# gradi, o sporge dai muri. Lo sanno in due - chi la modella e chi la posa nel
# blockout - quindi sta qui.
# IL MAGAZZINO CI E' ENTRATO DOPO, e ci e' entrato perche' la plafoniera si vedeva
# infilata nel muro. Ha un metro e trentacinque netti in X e l'apparecchio ne misura
# uno e ventotto: pure centrato perfettamente resterebbero tre centimetri per parte,
# e centrato non era - il punto luce sta a 4,00 e il centro della stanza a 4,125,
# quindi sfondava di nove centimetri dentro il muro ovest. Adesso lo dice
# `verifica_plafoniere()` invece di aspettare che qualcuno alzi la testa.
GIRATE_PLAFONIERA = ("pc", "cucina", "magazzino")
# LA CUPOLA HA LUCE ROSSA, E DI DEFAULT NON CE L'HA ACCESA. Non e' atmosfera: la
# luce bianca brucia l'adattamento al buio dell'occhio, e per rifarlo servono venti
# minuti. In una sala telescopio o si sta al rosso o si sta al buio - e il buio e'
# lo stato normale, perche' la luce riflessa dalle stanze accanto basta a muoversi.
# Accendere il rosso e' un gesto, accendere il bianco non e' proprio possibile.
LUCI_ROSSE = ("cupola1", "cupola2", "cupola3")
PARTE_SPENTA = ("cupola1", "cupola2", "cupola3")
H_PLAFONIERA = 2.72     # sotto l'intradosso: la plafoniera e' alta 12 cm e pende poco
# L'INGOMBRO DELL'APPARECCHIO STA QUI e non solo in `impianti_blender.py`. Chi lo
# disegna e chi controlla che ci stia nella stanza devono leggere lo stesso numero:
# scritto due volte, il giorno che la plafoniera diventa da 1,50 il controllo
# continua a dire che va bene. Nato lungo X: `GIRATE_PLAFONIERA` dice chi si gira.
L_PLAF, P_PLAF, H_PLAF = 1.28, 0.28, 0.09
# 1,45 e non 1,10. L'altezza vera di un interruttore italiano e' 1,10, ma
# l'occhio del giocatore sta a 1,65 e il raggio di interazione parte dalla camera
# e va DRITTO: a 1,10 bisognava accovacciarsi per accendere la luce. Fra la quota
# da manuale e un gesto che funziona vince il gesto - e 1,45 e' comunque un'altezza
# che esiste, quella dei comandi negli edifici pubblici accessibili.
H_INTERRUTTORE = 1.45
DA_STIPITE = 0.125      # dal filo del vano al centro della placca
# Placca a un basculante, di quelle vecchie: piu' grande e piu' spessa di una
# moderna a moduli, con la cornice svasata e il tasto bombato.
L_PLACCA, A_PLACCA, SP_PLACCA = 0.110, 0.155, 0.022


# Le luci A MURO: (nome, x, z, nx, nz) in metri REALI, con la normale uscente.
# La cupola non ha soffitto - sopra c'e' la calotta - e la plafoniera che le
# avevo messo pendeva a mezz'aria sotto la volta. Una sala telescopio si illumina
# da parete, e in rosso.
H_APPLIQUE = 2.05
# Il CRT acceso e' una sorgente, non un adesivo: illumina il piano e la faccia di
# chi ci sta davanti, ed e' l'unica luce che resta se si spegne tutto il resto.
# Le coordinate discendono da dove arredi_blender.py posa il monitor: consolle a
# x 5,30 (il tubo comincia tre centimetri dentro e ne occupa cinquanta), z al
# centro della sedia, e il piano a 0,75.
LUCE_MONITOR = (ARREDI_PC[0][1] + 0.65,
                ARREDI_PC[0][5] + 0.27,
                (ARREDI_PC[4][2] + ARREDI_PC[4][4]) / 2.0)

# --- LA POSTAZIONE AL MONITOR ------------------------------------------------
# Dove sta la cassa del tubo e dove sta il vetro, in metri di gioco. Servono al
# generatore del blockout per montarci sopra l'interagibile e lo schermo vivo.
#
# QUESTI NUMERI NON DISCENDONO DALLA PIANTA, ed e' l'eccezione di questo file.
# Tutto il resto qui dentro e' una decisione: dove passa un muro, quanto e' alta
# una consolle. Questi sono una MISURA: il tubo e' un modello preso da fuori,
# `posa_modello` lo scala finche' entra nell'impronta, e dove finisca il vetro lo
# sa solo Blender. Stanno qui lo stesso perche' il generatore deve poterli leggere
# anche a modelli assenti - `assets/models/` e' fuori da git e si rigenera - e un
# generatore che si ferma perche' manca un .glb non genera piu' niente.
#
# E NON SONO UN ATTO DI FEDE: `arredi_blender.py` li rimisura a ogni passata e si
# ferma se il modello si e' spostato di piu' di mezzo centimetro. Un numero
# ricopiato a mano che nessuno ricontrolla e' il modo in cui questo progetto ha
# gia' sbagliato tre volte - il monitor sfasato di venti centimetri, la lampada di
# rimbalzo, lo `shadow_blur` scritto due volte.
#
# (centro x, centro y, centro z, lato x, lato y, lato z) dell'ingombro del tubo.
# E' la collisione, cioe' cio' che il raggio dell'interazione cerca: senza, il
# monitor non ha prompt perche' il raggio non trova niente da colpire.
CASSA_MONITOR = (5.550, 0.960, 2.000, 0.386, 0.420, 0.430)
# (x della faccia anteriore, centro y, centro z, larghezza, altezza) del vetro.
# Il tubo e' bombato: la x e' il punto piu' avanzato, e ai bordi il vetro rientra
# di tredici millimetri.
VETRO_MONITOR = (5.741, 0.978, 2.000, 0.309, 0.274)
# L'IMMAGINE E' MENO DEL VETRO, e questa invece e' una decisione. Il vetro e' quasi
# quadrato (30,9 x 27,4) e l'immagine e' 4:3, come il viewport del CRT: presa a
# tutta larghezza restano ventitre millimetri sopra e sotto. Non sono un errore -
# sono la maschera nera attorno all'immagine, che su un tubo vero c'e' sempre.
# Stirare l'immagine per riempire il vetro allungherebbe ogni carattere del 18%.
IMMAGINE_MONITOR = (0.304, 0.228)
# Dove va la testa di chi si siede: quanto AVANTI al vetro e quanto SOPRA il suo
# centro. Il beccheggio del sedile non si dichiara, si calcola da questi due
# numeri - un marcatore che punta altrove che al proprio vetro e' il difetto che
# `crt/desk_camera.gd` racconta per esteso.
#
# 42 cm e' la distanza a cui l'immagine occupa i due terzi dell'inquadratura da
# seduti (FOV 42 gradi). Il centro del vetro sta a 0,98 e l'occhio a 1,15: si
# guarda in basso di 22 gradi, che e' quanto si guardava in basso nel 1999 con un
# tubo su una scrivania da 75.
SEDILE_MONITOR = (0.42, 0.172)
# (nome, x, z, nx, nz, quota). Le esterne stanno piu' in alto, sopra l'architrave.
APPLIQUE = [
    ("cupola1", 2.60, 0.10, 0.0, +1.0, H_APPLIQUE),   # muro nord, sopra il varco
    ("cupola2", 0.10, 3.20, +1.0, 0.0, H_APPLIQUE),   # muro ovest
    # LA TERZA, ED E' QUELLA CHE FA VEDERE QUALCOSA. Con due sole lampade, tutte e
    # due sui muri in fondo, chi entra dal corridoio ha la luce IN FACCIA e la
    # passerella, la ringhiera e il telescopio davanti: erano sagome nere sopra un
    # muro rosso, e non perche' fossero scuri - erano controluce. Questa sta sul
    # muro da cui si entra e li illumina dalla parte di chi guarda.
    ("cupola3", 2.20, 6.40, 0.0, -1.0, H_APPLIQUE),   # muro sud, sopra l'ingresso in sala
    # LE DUE DI FUORI. Leggerissime, e non e' una scelta di resa: sono le luci di
    # servizio di un OSSERVATORIO, e una lampada forte davanti alla porta
    # brucerebbe l'adattamento al buio di chi esce - lo stesso motivo per cui
    # dentro la cupola si sta al rosso. Servono a non inciampare sui gradini
    # tornando all'auto, non a illuminare il prato.
    # z 9,60 e non 9,50: qui si da' la FACCIA del muro, non il suo asse - come per
    # le due della cupola. Sull'asse la piastra resta annegata dentro l'intonaco.
    # NON SOPRA UN'APERTURA. Erano a 10,60 e 14,60: la prima esattamente sullo
    # stipite dell'ingresso (il vano va da 10,00 a 11,20), la seconda in mezzo alla
    # finestra della divulgazione (14,50-16,50). Una lampada puntiforme davanti a
    # un buco illumina la stanza di dentro, e da dentro erano due macchie bianche
    # senza spiegazione. Il muro fa ombra, il vano no. Lo controlla
    # verifica_applique().
    ("esterno_porta", 11.90, 9.60, 0.0, +1.0, 2.42),  # accanto all'ingresso, dal lato
                                                      # opposto a dove sbatte l'anta
    ("esterno_sud",   17.60, 9.60, 0.0, +1.0, 2.42),  # sul piazzale, oltre la finestra
]

# Le due esterne non hanno comando e non lo avranno: una luce di servizio davanti
# a una porta sta accesa tutta la notte, ed e' il motivo per cui esiste.
SEMPRE_ACCESE = ("esterno_porta", "esterno_sud")


def punti_luce():
    """(x, z, nome) in metri reali: le plafoniere a soffitto."""
    return [(x * K, z * K, n) for (x, z, n) in PUNTI_LUCE]


def punti_applique():
    """(nome, x, z, nx, nz, quota) in metri reali: le luci a parete."""
    return list(APPLIQUE)


def _stanza_attorno(px, pz, muri):
    """Le quattro facce di muro piu' vicine a un punto: (ovest, est, nord, sud).

    I muri di `MURI` sono ASSI, non volumi: lo spessore glielo mette
    `blocchi_edificio()`, mezzo `SP` per parte. Qui si torna la faccia INTERNA,
    cioe' quella che si vede dalla stanza, perche' e' quella contro cui un
    apparecchio sbatte.
    """
    ovest = est = nord = sud = None
    mezzo = SP / 2.0
    for (x0, z0, x1, z1) in muri:
        orizz = abs(z1 - z0) < 0.001
        a, b = min(x0, x1), max(x0, x1)
        c, d = min(z0, z1), max(z0, z1)
        if orizz:
            if not (a - 0.01 <= px <= b + 0.01):
                continue
            if c <= pz and (nord is None or c + mezzo > nord):
                nord = c + mezzo
            if c >= pz and (sud is None or c - mezzo < sud):
                sud = c - mezzo
        else:
            if not (c - 0.01 <= pz <= d + 0.01):
                continue
            if a <= px and (ovest is None or a + mezzo > ovest):
                ovest = a + mezzo
            if a >= px and (est is None or a - mezzo < est):
                est = a - mezzo
    return ovest, est, nord, sud


def verifica_plafoniere(franco=0.04):
    """Ogni apparecchio a soffitto sta DENTRO la sua stanza, non dentro il muro.

    IL CONTROLLO NASCE DA UN DIFETTO VISTO A OCCHIO: nel magazzino la plafoniera
    era infilata nel muro ovest per nove centimetri, e non se ne accorgeva niente -
    a soffitto non si passa, quindi nessuna verifica di ingombro la guardava, e
    l'unico modo di vederla era alzare la testa in quella stanza.

    La misura e' banale e proprio per questo andava scritta: il magazzino ha un
    metro e trentacinque netti in X, l'apparecchio ne misura uno e ventotto, e il
    punto luce non stava nemmeno in mezzo. Bastava girarlo di novanta gradi - la
    stanza e' profonda tre metri in Z - e la stessa cosa vale per ogni stanza
    stretta che qualcuno aggiungera'.

    `franco` e' l'aria minima che deve restare fra il testata e l'intonaco: a zero
    l'apparecchio tocca il muro, che e' una posa che non fa nessuno.
    """
    muri, _, _, _, _, _ = scalati()
    problemi = []
    for (x, z, nome) in punti_luce():
        girato = nome in GIRATE_PLAFONIERA
        ix, iz = (P_PLAF, L_PLAF) if girato else (L_PLAF, P_PLAF)
        ovest, est, nord, sud = _stanza_attorno(x, z, muri)
        for (faccia, quanto, verso) in (
                ("ovest", None if ovest is None else (x - ix / 2) - ovest, "muro ovest"),
                ("est",   None if est is None else est - (x + ix / 2), "muro est"),
                ("nord",  None if nord is None else (z - iz / 2) - nord, "muro nord"),
                ("sud",   None if sud is None else sud - (z + iz / 2), "muro sud")):
            if quanto is None:
                continue
            if quanto < franco:
                come = "dentro il" if quanto < 0 else "a %.0f mm dal" % (quanto * 1000)
                problemi.append(
                    "  PLAFONIERA STRETTA       %s: %s %s%s"
                    % (nome, come, verso,
                       " di %.0f mm" % (-quanto * 1000) if quanto < 0 else ""))
    return problemi


# porta -> verso in cui si ENTRA nella stanza che l'interruttore comanda.
# Solo questo si dichiara: da che parte sta la stanza, cioe' su quale delle due
# facce del muro va la placca. Si accende PRIMA di entrare al buio, non dopo aver
# attraversato la stanza.
VERSO_INTERNO = {
    "ingresso":            (0, -1),   # si entra da sud verso l'atrio
    "cucina":              (0, -1),   # la cucina sta a nord della sua porta
    "corridoio -> spazio": (+1, 0),   # lo spazio divulgazione sta a est
    "pc -> corridoio":     (0, -1),   # la sala di controllo sta a nord
    "magazzino":           (0, +1),
    "bagno":               (0, +1),
    "disimpegno":          (0, +1),
}
# DA CHE PARTE DEL MURO STA LA PLACCA. Regola: dal lato OPPOSTO alla stanza che
# illumina, cioe' quello da cui ci si arriva. Si accende prima di entrare al buio,
# non dopo aver attraversato la stanza - e per la cucina la differenza e' che o si
# apre la porta, si entra al buio, si chiude e si torna indietro, oppure no.
#
# La prima versione aveva il segno rovesciato e metteva ogni placca DENTRO la
# stanza servita, che e' esattamente il contrario di quello che il commento
# accanto dichiarava di fare.
#
# Un'eccezione, e dev'essere dichiarata: dal lato opposto all'atrio c'e' il prato.
DENTRO_PER_FORZA = ("ingresso",)

# Il capo del vano NON si dichiara: e' quello della MANIGLIA, cioe' l'opposto del
# cardine, e il cardine sta gia' in APERTURA_PORTE. E' la regola vera - la mano
# che apre e' la mano che accende - ed e' anche l'unica che non si sbaglia in
# meta' dei casi, perche' non e' una scelta ripetuta sette volte ma un dato solo
# letto sette volte. "A destra di chi entra" la sbagliava tre volte su sette:
# mandava la placca contro il tramezzo del magazzino e contro quello del
# disimpegno, che sono appunto i due lati dove il cardine non sta.
# Quali lampade comanda ogni placca. E' un DATO e non una ricerca per prossimita':
# due stanze confinanti hanno lampade a tre metri l'una dall'altra, e un raggio
# che funziona in cucina accende anche il corridoio.
#
# Cupola e corridoio non hanno comando, e non e' una dimenticanza: nessuna porta
# ci si affaccia dal lato giusto - la placca della sala di controllo sta dentro la
# sala, quella dello spazio divulgazione sta dentro lo spazio. Un interruttore per
# quei due locali vuole un punto suo, che non discende da un'apertura: quando
# serviranno spegnibili, si dichiareranno qui con le loro coordinate.
# UNA PLACCA PER LOCALE, ALLA PORTA DI QUEL LOCALE. Prima ce n'erano undici, con
# due placche sulle stesse tre lampade e una batteria di tre accanto all'ingresso:
# a guardarle non si capiva cosa accendesse cosa, ed e' un difetto peggiore di una
# stanza senza interruttore. Un comando per porta, e il comando accende la stanza
# in cui quella porta entra. Non c'e' niente da ricordare.
LUCI_COMANDATE = {
    "ingresso":            ("divulg1", "divulg2", "divulg3"),
    "corridoio -> spazio": ("corridoio",),   # la placca sta DAL LATO CORRIDOIO
    "cucina":              ("cucina",),
    "pc -> corridoio":     ("pc",),
    "magazzino":           ("magazzino",),
    "bagno":               ("bagno",),
    "disimpegno":          ("disimp",),
}

# Il nome del locale che ogni placca accende, per il prompt. «Accendi la cucina»
# davanti a una porta dice tutto quello che serve sapere; «Accendi» non dice
# niente, e con dieci placche uguali il giocatore le prova a caso.
NOME_LOCALE = {
    "ingresso": "la sala", "corridoio -> spazio": "il corridoio",
    "cucina": "la cucina", "pc -> corridoio": "la sala di controllo",
    "magazzino": "il magazzino", "bagno": "il bagno",
    "disimpegno": "il disimpegno", "cupola": "la luce rossa",
}

CONTRO_MANIGLIA = {
    # unica eccezione, e va detta: dal lato della maniglia della porta della
    # cucina, addossata al muro, c'e' la bacheca alta 1,90.
    "cucina": True,
}


def punti_interruttori():
    """Le placche: (nome, x, z, nx, nz) in metri reali, nx/nz = normale uscente."""
    _, aperture, _, _, _, _ = scalati()
    fuori = []
    for (px_, pz, w, o, t, nome) in aperture:
        if t != "porta" or nome not in VERSO_INTERNO:
            continue
        dx, dz = VERSO_INTERNO[nome]
        cardine, _verso = APERTURA_PORTE[nome]
        # la maniglia sta al capo opposto al cardine; l'eccezione lo ribalta
        capo_alto = (cardine == "a") != bool(CONTRO_MANIGLIA.get(nome))
        verso_placca = 1.0 if nome in DENTRO_PER_FORZA else -1.0
        if o == "h":
            x = (px_ + w + DA_STIPITE) if capo_alto else (px_ - DA_STIPITE)
            z, nx, nz = pz, 0.0, float(dz) * verso_placca
        else:
            z = (pz + w + DA_STIPITE) if capo_alto else (pz - DA_STIPITE)
            x, nx, nz = px_, float(dx) * verso_placca, 0.0
        fuori.append((nome, x + nx * SP / 2.0, z + nz * SP / 2.0, nx, nz))
    for (nome, x, z, nx, nz, _luci) in INTERRUTTORI_LIBERI:
        fuori.append((nome, x + nx * SP / 2.0, z + nz * SP / 2.0, nx, nz))
    return fuori


# Le placche che NON nascono da una porta: (nome, x, z, nx, nz, luci comandate),
# in metri reali, con la normale uscente dal muro. Servono dove il comando non
# discende da un'apertura - la sala divulgazione e' grande come tre stanze e ha
# due porte sole, e da dentro non c'era modo di spegnere niente di preciso.
#
# Stanno tutte sul montante fra la porta del corridoio e l'angolo, in fila: e'
# il posto dove un quadretto di comandi sta in un edificio pubblico, subito
# dentro la sala e a portata di chi entra dal corridoio.
INTERRUTTORI_LIBERI = [
    # x/z sono l'ASSE del muro: la faccia la trova punti_interruttori()
    # aggiungendo mezzo spessore lungo la normale.
    #
    # NE E' RIMASTA UNA. Ce n'erano quattro - tre accanto all'ingresso per
    # accendere separatamente le tre zone della sala - e il risultato era che
    # davanti a quattro placche identiche non si capiva quale facesse cosa.
    # Meglio una sala che si accende tutta insieme.
    #
    # Questa resta perche' la cupola non ha porte: ci si entra dal varco, e un
    # varco non ha stipiti su cui mettere una placca.
    ("cupola", 5.20, 4.10, -1.0, 0.0, ("cupola1", "cupola2", "cupola3")),
]


def comandate_da(nome):
    """Le lampade di una placca, che venga da una porta o stia da sola. Chi
    genera la scena non deve sapere da quale delle due liste arriva."""
    for (n, _x, _z, _nx, _nz, gruppo) in INTERRUTTORI_LIBERI:
        if n == nome:
            return gruppo
    return LUCI_COMANDATE.get(nome, ())


def luci_senza_comando():
    """I punti luce che nessuna placca accende. Non e' un errore: e' una nota,
    e va stampata perche' una dimenticanza e una scelta si somigliano troppo."""
    comandate = set()
    for gruppo in LUCI_COMANDATE.values():
        comandate.update(gruppo)
    for (_n, _x, _z, _nx, _nz, gruppo) in INTERRUTTORI_LIBERI:
        comandate.update(gruppo)
    tutte = [n for (_x, _z, n) in PUNTI_LUCE] + [a[0] for a in APPLIQUE]
    return [n for n in tutte if n not in comandate and n not in SEMPRE_ACCESE]


def verifica_passerella(passo_gradi=2.0, franco=0.12):
    """L'anello si cammina tutto, senza buchi e senza scalini.

    E' il controllo che mancava, e il difetto lo si sentiva solo camminandoci: la
    passerella era fatta di scatole ALLINEATE AGLI ASSI messe su una
    circonferenza, quindi copriva l'anello dove l'arco era orizzontale o
    verticale e lo lasciava scoperto in diagonale. Qui si percorre la mezzeria
    ogni due gradi e si chiede che ogni punto stia dentro almeno un concio, con
    `franco` di margine dal bordo - il piede non cammina sullo spigolo.

    Si controlla anche che tutti i conci abbiano lo stesso calpestio: uno di
    quota diversa e' uno scalino, e un CharacterBody3D non fa step-up.
    """
    import math as _m
    conci = [b for b in blocchi_edificio() if b[6].startswith("Pass")]
    problemi = []
    if not conci:
        return ["  PASSERELLA ASSENTE       nessun concio di impalcato"]
    quote = set(round(b[1] + b[4] / 2.0, 3) for b in conci)
    if len(quote) > 1:
        problemi.append("  IMPALCATO A SCALINI      calpestii diversi: %s"
                        % sorted(quote))
    CXp, CZp = 5.2 * K, 5.0 * K
    passi = int(360.0 / passo_gradi)
    scoperti = 0
    for i in range(passi):
        ang = 2 * _m.pi * i / passi
        px = CXp + R_PASS * _m.cos(ang)
        pz = CZp + R_PASS * _m.sin(ang)
        coperto = False
        for (cx, cy, cz, sx, sy, sz, _n, _rx, _rz, ry) in conci:
            # nel sistema del concio: si disfa la rotazione attorno a Y
            dx, dz = px - cx, pz - cz
            c, sn = _m.cos(-ry), _m.sin(-ry)
            lx = dx * c + dz * sn
            lz = -dx * sn + dz * c
            if abs(lx) <= sx / 2 - franco and abs(lz) <= sz / 2 - franco:
                coperto = True
                break
        if not coperto:
            scoperti += 1
    if scoperti:
        problemi.append("  BUCHI NELL'ANELLO        %d punti su %d della mezzeria "
                        "non poggiano su nessun concio" % (scoperti, passi))
    # E CI SI DEVE PASSARE. La larghezza che conta non e' quella dell'impalcato ma
    # quella che resta fra gli ostacoli: parapetti da una parte, il pieno centrale
    # dall'altra. La capsula del giocatore e' larga 0,60, e sotto i venti
    # centimetri di gioco camminare diventa incastrarsi.
    ostacoli = [b for b in blocchi_edificio() if b[6].startswith("Parapetto")]
    dentro = R_PASS - W_PASS / 2.0
    fuori_r = R_PASS + W_PASS / 2.0
    for b in ostacoli:
        r = _m.hypot(b[0] - CXp, b[2] - CZp)
        mezzo = b[3] / 2.0 if b[3] < b[5] else b[5] / 2.0
        if r > R_PASS:
            fuori_r = min(fuori_r, r - mezzo)
        else:
            dentro = max(dentro, r + mezzo)
    netto = fuori_r - dentro
    # TRENTA CENTIMETRI DI GIOCO, non venti. Con venti la configurazione vecchia -
    # 0,85 di impalcato e un parapetto per lato - passava per un centimetro, e
    # camminandoci ci si incastrava lo stesso: un margine che approva il difetto
    # che deve trovare e' peggio di nessun margine.
    if netto < CAPSULA + 0.30:
        problemi.append("  PASSAGGIO STRETTO        fra gli ostacoli restano %.2f m, "
                        "la capsula ne misura %.2f" % (netto, CAPSULA))
    return problemi


def verifica_applique(franco=0.45):
    """Un'applique non va davanti a un buco.

    Il muro fa ombra, il vano no: una lampada piazzata sopra una porta o in mezzo
    a una finestra illumina la stanza dall'altra parte, e da li' non si capisce da
    dove venga quella luce. E' esattamente quello che era successo alle due
    esterne, sistemate sullo stipite dell'ingresso e in mezzo alla finestra della
    divulgazione. `franco` e' quanto muro pieno deve restare fra la lampada e il
    bordo del vano: meno di mezzo metro e il cono la lambisce comunque.
    """
    _, aperture, _, _, _, _ = scalati()
    problemi = []
    for (nome, ax, az, anx, _anz, _q) in APPLIQUE:
        lungo_x = abs(anx) < 0.5          # la normale e' su Z: il muro corre lungo X
        p = ax if lungo_x else az
        fisso = az if lungo_x else ax
        for (px_, pz, w, o, _t, nap) in aperture:
            if (o == "h") != lungo_x:
                continue
            # la faccia dell'applique sta mezzo spessore fuori dall'asse del muro
            if abs((pz if lungo_x else px_) - fisso) > SP / 2 + 0.02:
                continue
            a, b = (px_, px_ + w) if lungo_x else (pz, pz + w)
            if a - franco < p < b + franco:
                problemi.append("  APPLIQUE SUL VANO        %s a %.2f: l'apertura %s "
                                "va da %.2f a %.2f" % (nome, p, nap, a, b))
    return problemi


def verifica_interruttori(aria=0.03):
    """Una placca sbagliata non si vede: sta dentro un muro, o su un muro che
    non c'e', o dietro un armadio. Tre cose, tre controlli.
    """
    muri, aperture, _, _, _, _ = scalati()
    problemi = []
    noti = set(n for (_x, _z, n) in PUNTI_LUCE) | set(a[0] for a in APPLIQUE)
    for (nome_l, _x, _z, _nx, _nz, gruppo) in INTERRUTTORI_LIBERI:
        for luce in gruppo:
            if luce not in noti:
                problemi.append("  LUCE INESISTENTE         %s comanda %s, che non c'e'"
                                % (nome_l, luce))
    for porta, gruppo in LUCI_COMANDATE.items():
        if porta not in VERSO_INTERNO:
            problemi.append("  INTERRUTTORE FANTASMA    %s non e' una porta con placca" % porta)
        for luce in gruppo:
            if luce not in noti:
                problemi.append("  LUCE INESISTENTE         %s comanda %s, che non c'e'"
                                % (porta, luce))
    for (nome, x, z, nx, nz) in punti_interruttori():
        # 1. il muro deve esistere sotto la placca, e la placca starci dentro.
        # I bordi non sono gli estremi del segmento: e' la stessa cosa dei
        # montanti delle aperture. Su un muro lungo passano i tramezzi, e il
        # vincolo vero e' la faccia del piu' vicino - mezzo spessore oltre il suo
        # asse. Sei centimetri dall'estremo di un segmento sono una placca
        # piegata sullo spigolo.
        xm, zm = x - nx * SP / 2.0, z - nz * SP / 2.0
        bordo = L_PLACCA / 2.0 + SP / 2.0 + aria
        su_muro = False
        for (x0, z0, x1, z1) in muri:
            orizz = abs(z1 - z0) < 0.001
            lungo, trasv = (xm, zm) if orizz else (zm, xm)
            fisso = z0 if orizz else x0
            if abs(trasv - fisso) > 0.01:
                continue
            a, b = (min(x0, x1), max(x0, x1)) if orizz else (min(z0, z1), max(z0, z1))
            if not (a <= lungo <= b):
                continue
            # i vincoli: gli estremi del segmento e ogni muro che lo incrocia
            vincoli = [a, b]
            for (ux0, uz0, ux1, uz1) in muri:
                u_orizz = abs(uz1 - uz0) < 0.001
                if u_orizz == orizz:
                    continue
                u_fisso = uz0 if u_orizz else ux0
                if abs(u_fisso - fisso) > 0.01 and not (
                        min(uz0, uz1) - 0.01 <= fisso <= max(uz0, uz1) + 0.01 if orizz
                        else min(ux0, ux1) - 0.01 <= fisso <= max(ux0, ux1) + 0.01):
                    continue
                u_lungo = ux0 if orizz else uz0
                if a - 0.01 <= u_lungo <= b + 0.01:
                    vincoli.append(u_lungo)
            # e le APERTURE, che nel muro sono un buco: una placca in mezzo a un
            # vano non sta su niente, e finora il controllo guardava solo i muri
            for (ap_x, ap_z, ap_w, ap_o, _t, _n) in aperture:
                if (ap_o == "h") != orizz:
                    continue
                if abs((ap_z if orizz else ap_x) - fisso) > 0.01:
                    continue
                ap_a = ap_x if orizz else ap_z
                # il margine di un vano non e' quello di un muro incidente: un
                # vano non ha spessore, basta che la placca non ci entri dentro
                vano = L_PLACCA / 2.0 + aria
                if ap_a - vano < lungo < ap_a + ap_w + vano:
                    problemi.append("  INTERRUTTORE NEL VANO   %-22s dentro %s"
                                    % (nome, _n))
            vicino = min(abs(lungo - v) for v in vincoli)
            if vicino >= bordo:
                su_muro = True
            else:
                problemi.append("  INTERRUTTORE SULLO SPIGOLO %-19s a %.0f cm dal muro vicino"
                                % (nome, vicino * 100))
                su_muro = True
            break
        if not su_muro:
            problemi.append("  INTERRUTTORE NEL VUOTO  %-22s (%.2f, %.2f)" % (nome, x, z))
            continue
        # 2. davanti alla placca ci si deve poter stare: 25 cm di aria
        if not punto_libero(x + nx * 0.25, z + nz * 0.25):
            problemi.append("  INTERRUTTORE MURATO     %-22s non ci si arriva" % nome)
        # 3. nessun mobile addossato
        for (_s, _sala, elenco) in STANZE_ARREDATE:
            for (n_a, ax0, az0, ax1, az1, alt) in elenco:
                if alt < H_INTERRUTTORE:
                    continue
                if ax0 - 0.05 <= x <= ax1 + 0.05 and az0 - 0.05 <= z <= az1 + 0.05:
                    problemi.append("  INTERRUTTORE COPERTO    %-22s dietro %s" % (nome, n_a))
    return problemi
