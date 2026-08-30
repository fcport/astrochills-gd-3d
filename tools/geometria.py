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
APERTURE = [
    (20.0, 19, 1.20, "h", "porta",    "ingresso"),   # un battente solo, antipanico
    (17.6, 8.2, 1.40, "h", "porta",   "cucina"),
    (16.5, 9.5, 1.40, "v", "porta",   "corridoio -> spazio"),
    # 1,30 e non 1,60: era la piu' larga dell'edificio, e in mezzo a porte da
    # 1,30-1,40 un vano da 1,60 legge come un errore di disegno.
    (12.9, 8.8, 1.30, "h", "porta",   "pc -> corridoio"),
    (7.35, 13, 0.90, "h", "porta",    "magazzino"),
    (11.6, 13, 1.30, "h", "porta",    "bagno"),
    (0.65, 13, 1.30, "h", "porta",   "disimpegno"),
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

APERTURA_PORTE = {
    "ingresso":            ("a", +1),   # verso il prato
    "cucina":              ("a", -1),   # dentro la cucina
    "corridoio -> spazio": ("b", +1),   # verso lo spazio divulgazione: il corridoio e' stretto
    "pc -> corridoio":     ("a", -1),   # dentro il controllo pc, per non ostruire il corridoio
    "magazzino":           ("a", -1),   # verso la sala: il magazzino e' largo 1,55
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
R_PASS, W_PASS, H_PASS = 2.8 * K, 0.85, 0.50   # 0,50 + mezzo impalcato = 0,59 di calpestio
SP_PASS = 0.18                          # spessore dell'impalcato
DISL_RAMPA = H_PASS + SP_PASS / 2       # si sale al PIANO DI CALPESTIO, non alla quota nominale
LUNGO_RAMPA = 0.75        # 38 gradi, con margine sotto il floor_max_angle di 45


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
    interni = [b for b in blocchi if b[6].startswith("ParapettoInt")]
    if not interni:
        problemi.append("  TRAPPOLA          il vuoto centrale (%.2f m di luce) non ha parapetto"
                        % luce_sotto)
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

    def aggiungi(cx, cy, cz, sx, sy, sz, nome, rot_x=0.0, rot_z=0.0):
        if sx > 0.01 and sy > 0.01 and sz > 0.01:
            blocchi.append((cx, cy, cz, sx, sy, sz, nome, rot_x, rot_z))

    # ---------------------------------------------------------------- muri con aperture
    for i, (x0, z0, x1, z1) in enumerate(MURI):
        orizz = abs(z1 - z0) < 0.001
        a, b = (min(x0, x1), max(x0, x1)) if orizz else (min(z0, z1), max(z0, z1))
        fisso = z0 if orizz else x0
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
        cur = a
        for (p0, p1, t) in ap:
            if p0 > cur + 0.01:
                aggiungi_seg = (cur, p0)
                m, L = (aggiungi_seg[0] + aggiungi_seg[1]) / 2.0, aggiungi_seg[1] - aggiungi_seg[0]
                if orizz: aggiungi(m, y_muro, fisso, L, h_muro, SP, "M%d" % i)
                else:     aggiungi(fisso, y_muro, m, SP, h_muro, L, "M%d" % i)
            cur = p1
        if b > cur + 0.01:
            m, L = (cur + b) / 2.0, b - cur
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
    N = 16
    for k in range(N):
        ang = 2 * math.pi * k / N
        aggiungi(CX + R_PASS * math.cos(ang), H_PASS, CZ + R_PASS * math.sin(ang),
                 W_PASS, SP_PASS, 2 * math.pi * R_PASS / N + 0.25, "Pass%d" % k)

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
        corda = 2 * math.pi / N_PAR
        for raggio, nome in ((R_PASS - W_PASS / 2, "ParapettoInt"), (R_PASS + W_PASS / 2, "ParapettoEst")):
            larghezza = raggio * corda + 0.10
            # il box si allinea grossolanamente all'arco: a 24 settori basta
            sx = max(0.10, abs(larghezza * math.sin(ang))) + 0.06
            sz = max(0.10, abs(larghezza * math.cos(ang))) + 0.06
            aggiungi(CX + raggio * math.cos(ang), calpestio + 0.50, CZ + raggio * math.sin(ang),
                     sx, 1.00, sz, nome)

    # e il telescopio si tocca: prima ci si passava attraverso
    aggiungi(CX, 1.60, CZ, 0.85, 1.30, 0.85, "Montatura")
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
        posa(px_ + TS / 2 if o == "h" else pz + TS / 2, y0 + h / 2, TS, h, "Telaio")
        posa((px_ + w - TS / 2) if o == "h" else (pz + w - TS / 2), y0 + h / 2, TS, h, "Telaio")
        posa(m, y1 - TS / 2, w - 2 * TS, TS, "Telaio")
        if not porta:
            posa(m, y0 + TS / 2, w - 2 * TS, TS, "Telaio")

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
    ("Sedia1",    6.02, 1.28, 6.64, 1.90, 1.05),   # 62 x 62: la misura di una girevole vera
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
        problemi.append("  SACCA ISOLATA     %.2f m2 di pavimento non raggiungibili a piedi" % persi)
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
GIRATE_PLAFONIERA = ("pc", "cucina")
# LA CUPOLA HA LUCE ROSSA, E DI DEFAULT NON CE L'HA ACCESA. Non e' atmosfera: la
# luce bianca brucia l'adattamento al buio dell'occhio, e per rifarlo servono venti
# minuti. In una sala telescopio o si sta al rosso o si sta al buio - e il buio e'
# lo stato normale, perche' la luce riflessa dalle stanze accanto basta a muoversi.
# Accendere il rosso e' un gesto, accendere il bianco non e' proprio possibile.
LUCI_ROSSE = ("cupola1", "cupola2")
PARTE_SPENTA = ("cupola1", "cupola2")
H_PLAFONIERA = 2.72     # sotto l'intradosso: la plafoniera e' alta 12 cm e pende poco
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
APPLIQUE = [
    ("cupola1", 2.60, 0.10, 0.0, +1.0),    # muro nord, sopra il varco della scala
    ("cupola2", 0.10, 3.20, +1.0, 0.0),    # muro ovest
]


def punti_luce():
    """(x, z, nome) in metri reali: le plafoniere a soffitto."""
    return [(x * K, z * K, n) for (x, z, n) in PUNTI_LUCE]


def punti_applique():
    """(nome, x, z, nx, nz) in metri reali: le luci a parete."""
    return list(APPLIQUE)


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
    ("cupola", 5.20, 4.10, -1.0, 0.0, ("cupola1", "cupola2")),
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
    return [n for n in tutte if n not in comandate]


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
