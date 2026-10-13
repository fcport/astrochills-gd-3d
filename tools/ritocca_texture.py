# -*- coding: utf-8 -*-
"""Toglie da un modello preso da fuori quello che l'autore ci ha DIPINTO sopra.

    from ritocca_texture import togli_adesivi
    togli_adesivi(cartella_texture, adesivi)

Lo chiama `prendi_modello.py` appena spacchettato lo zip, prima di ridurre le mappe:
gli originali restano nello zip, e rifare la cartella rifa' anche il ritocco.

IL CASO CHE L'HA FATTO SCRIVERE. Il frigorifero di Sketchfab porta dodici adesivi e
un disegnino a gesso, e Federico li voleva via. Non sono geometria: sono dipinti in
Substance nella stessa mappa della vernice, quindi toglierli vuol dire ridipingere
quei punti - su TUTTE e tre le mappe, colore, rugosita' e rilievo, o l'adesivo
resterebbe visibile come una lucentezza o un bordo in rilievo senza colore.

COME SI RIDIPINGE, e le due strade scartate guardando il risultato:

  * un riempimento liscio (inpainting) lascia una macchia PULITA su una vernice
    sporca, e da vicino si legge come una toppa;
  * la fusione di Poisson (`cv2.seamlessClone`) accorda i bordi ma si porta dentro
    l'alone colorato dell'adesivo - toppe rosa, gialle, azzurre.

Quella che resta: si RICOPIA un pezzo di vernice pulita li' vicino (la grana dello
sporco e' quella vera), e se ne corregge il TONO con una membrana tesa sul bordo di
vernice pulita attorno all'adesivo. I pixel estranei - il bordo di un'altra isola
della mappa, una macchia di ruggine - non tirano la membrana e non vengono toccati.
"""
import os

import numpy as np

# Di quanto si allarga la toppa oltre l'adesivo: il bordo della toppa deve cadere
# sulla vernice, non sull'alone sfumato che l'adesivo lascia attorno a se'.
ALLARGA = 18

# Oltre questa distanza di colore (0-255, euclidea) dal fondo un pixel e' ADESIVO se
# e' attaccato al seme, ESTRANEO se no. Lo sporco della vernice sta sotto i 30.
SOGLIA_ADESIVO = 34
SOGLIA_ESTRANEO = 45


def _mappe(cartella):
    """Le tre mappe del set, riconosciute dal nome come fa `prendi_modello.riduci`."""
    trovate = {}
    for n in os.listdir(cartella):
        b = os.path.splitext(n)[0].lower()
        for chiave in ("basecolor", "metallicroughness", "normal"):
            if b.endswith("_" + chiave) and "_rid_" not in b:
                trovate[chiave] = os.path.join(cartella, n)
    return trovate


def _zona(C, x, y, w, h, tipo, margine):
    """La toppa (omega) e i pixel estranei, in una finestra attorno al seme."""
    import cv2
    H, W = C.shape[:2]
    m = 110 + ALLARGA
    X0, Y0, X1, Y1 = max(0, x - m), max(0, y - m), min(W, x + w + m), min(H, y + h + m)
    fin = C[Y0:Y1, X0:X1]
    m1 = np.zeros(fin.shape[:2], np.uint8)
    if tipo == "r":
        # un rettangolo e basta: per gli adesivi piccoli su un fondo molto sporco,
        # dove la soglia di colore si prenderebbe anche lo sporco
        m1[max(0, y - Y0 - margine):y - Y0 + h + margine,
           max(0, x - X0 - margine):x - X0 + w + margine] = 1
    else:
        bordo = np.concatenate([fin[:12].reshape(-1, 3), fin[-12:].reshape(-1, 3),
                                fin[:, :12].reshape(-1, 3), fin[:, -12:].reshape(-1, 3)])
        prova = np.median(bordo, axis=0)
        if tipo == "g":
            # un disegno a gesso: le linee sono PIU' CHIARE del fondo, e l'alone di
            # sporco attorno va via con loro, o resta la sagoma pulita del disegno
            m0 = ((fin.mean(axis=2) - prova.mean()) > 18).astype(np.uint8)
            m0 = cv2.morphologyEx(m0, cv2.MORPH_CLOSE, np.ones((45, 45), np.uint8))
            m0 = cv2.dilate(m0, np.ones((31, 31), np.uint8))
        else:
            m0 = (np.linalg.norm(fin - prova, axis=2) > SOGLIA_ADESIVO).astype(np.uint8)
            m0 = cv2.morphologyEx(m0, cv2.MORPH_CLOSE, np.ones((15, 15), np.uint8))
        _n, lab, _st, _c = cv2.connectedComponentsWithStats(m0)
        tieni = set(np.unique(lab[y - Y0:y - Y0 + h, x - X0:x - X0 + w])) - {0}
        m1 = cv2.dilate(np.isin(lab, list(tieni)).astype(np.uint8), np.ones((9, 9), np.uint8))
    # IL FONDO SI MISURA ATTORNO ALL'ADESIVO, non sul bordo della finestra: vicino a
    # un'isola grigia della mappa il bordo della finestra e' mezzo grigio, il fondo
    # veniva grigio, e la toppa pure.
    anello = (cv2.dilate(m1, np.ones((41, 41), np.uint8))
              - cv2.dilate(m1, np.ones((21, 21), np.uint8)))
    fondo = np.median(fin[anello > 0], axis=0)
    estranei = ((np.linalg.norm(fin - fondo, axis=2) > SOGLIA_ESTRANEO) & (m1 == 0)).astype(np.uint8)
    lato = 2 * ALLARGA + 1
    omega = cv2.dilate(m1, np.ones((lato, lato), np.uint8)) & (1 - estranei)
    return (X0, Y0, X1, Y1), omega, estranei, fondo


def _scarto(a):
    """Quanto e' increspato un pezzo di mappa: il 97esimo percentile dello scarto
    dalla sua mediana."""
    return float(np.percentile(np.linalg.norm(a - np.median(a.reshape(-1, 3), axis=0), axis=-1), 97))


def _sorgente(C, sat, riquadro, fondo, altre, bordo):
    """Dove prendere la vernice pulita: stessa misura, il piu' vicino possibile.

    PULITA IN TUTTE LE MAPPE, non solo nel colore. Scegliendola sul colore e basta,
    due toppe si sono portate dentro una costa della normal map - il bordo smussato
    di un'anta, che nel colore non si vede - e sul frigo sarebbero comparse due
    righe in rilievo dove prima c'era un adesivo. Per ogni altra mappa il pezzo non
    deve essere piu' increspato del bordo attorno all'adesivo (`bordo`: lo scarto
    misurato li'), con un po' di margine: la rugosita' ha le crepe dappertutto, e
    quelle vanno bene.
    """
    H, W = C.shape[:2]
    bx0, by0, bx1, by1 = riquadro
    bw, bh = bx1 - bx0, by1 - by0
    for passo in (1.1, 1.4, 1.8, 2.4, 3.2):
        migliore = None
        for ang in range(0, 360, 15):
            dx = int(round(np.cos(np.radians(ang)) * passo * max(bw, bh)))
            dy = int(round(np.sin(np.radians(ang)) * passo * max(bw, bh)))
            sx0, sy0 = bx0 + dx, by0 + dy
            if sx0 < 0 or sy0 < 0 or sx0 + bw > W or sy0 + bh > H:
                continue
            p = C[sy0:sy0 + bh, sx0:sx0 + bw]
            d = np.linalg.norm(p - fondo, axis=2)
            # pulita: niente colore pieno, niente bordo di un'altra isola
            if (np.percentile(sat[sy0:sy0 + bh, sx0:sx0 + bw], 99) > 70
                    or np.percentile(d, 97) > 40):
                continue
            if any(_scarto(M[sy0:sy0 + bh, sx0:sx0 + bw]) > 1.5 * lim + 6.0
                   for M, lim in zip(altre, bordo)):
                continue
            costo = (float(np.linalg.norm(p.mean(axis=(0, 1)) - fondo))
                     + 0.01 * float(np.hypot(dx, dy)))
            if migliore is None or costo < migliore[0]:
                migliore = (costo, dx, dy)
        if migliore is not None:
            return migliore
    return None


def _membrana(diff, noti, ignoti, passi=1500, scala=4):
    """La correzione di tono dentro la toppa: una membrana tesa sul bordo pulito.

    E' l'interpolazione ARMONICA - ogni punto e' la media dei vicini - e per questo
    non fa spigoli: l'inpainting di Telea, provato prima, lasciava spicchi e croci di
    tono nelle toppe grandi. I pixel estranei non la tirano (bordo libero), quelli
    puliti la tengono ferma. Si risolve a un quarto della risoluzione, che per una
    correzione di tono e' anche troppo.
    """
    import cv2
    h, w = noti.shape
    hs, ws = (h + scala - 1) // scala, (w + scala - 1) // scala

    def pad(a):
        return np.pad(a, ((0, hs * scala - h), (0, ws * scala - w)) + ((0, 0),) * (a.ndim - 2))

    def blocchi(a):
        return a.reshape(hs, scala, ws, scala, *a.shape[2:]).sum(axis=(1, 3))

    peso = blocchi(pad(noti.astype(np.float32)))
    fissi = peso > 0
    val = blocchi(pad(diff * noti[..., None])) / np.maximum(peso, 1e-6)[..., None]
    liberi = (blocchi(pad(ignoti.astype(np.float32))) > 0) & ~fissi
    attivi = fissi | liberi
    v = val.copy()
    v[liberi] = val[fissi].mean(axis=0) if fissi.any() else 0.0
    for _ in range(passi):
        somma = np.zeros_like(v)
        quanti = np.zeros(v.shape[:2], np.float32)
        for sy, sx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            vic = np.roll(v, (sy, sx), axis=(0, 1))
            ok = np.roll(attivi, (sy, sx), axis=(0, 1))
            # np.roll fa il giro: la riga che rientra dall'altra parte non e' un vicino
            if sy == 1:
                ok[0] = False
            if sy == -1:
                ok[-1] = False
            if sx == 1:
                ok[:, 0] = False
            if sx == -1:
                ok[:, -1] = False
            somma += vic * ok[..., None]
            quanti += ok
        nuovo = somma / np.maximum(quanti, 1)[..., None]
        v = np.where(liberi[..., None] & (quanti[..., None] > 0), nuovo, v)
    grande = cv2.resize(v, (ws * scala, hs * scala), interpolation=cv2.INTER_LINEAR)
    return grande[:h, :w]


def togli_adesivi(cartella, adesivi, lato_atteso=None):
    """Ridipinge gli `adesivi` su colore, rugosita' e rilievo, sovrascrivendo le mappe.

    `adesivi` e' una lista di (x, y, larghezza, altezza, tipo, margine), in pixel della
    mappa ORIGINALE: e' il riquadro del colore pieno dell'adesivo, da cui si parte per
    trovarlo tutto. `tipo` e' "c" (adesivo: si prende quello che si stacca dal fondo),
    "r" (un rettangolo, allargato di `margine`) o "g" (un disegno a gesso).

    `lato_atteso`: le coordinate valgono per UNA misura di mappa. Se l'autore
    ripubblica il modello a un'altra risoluzione, cadrebbero nel posto sbagliato e
    ridipingerebbero un pezzo di vernice buona - meglio fermarsi.
    """
    import cv2
    from PIL import Image
    trovate = _mappe(cartella)
    if "basecolor" not in trovate:
        raise RuntimeError("in %s non c'e' una mappa colore" % cartella)
    immagini = {k: Image.open(p) for k, p in trovate.items()}
    modi = {k: im.mode for k, im in immagini.items()}
    mappe = {k: np.asarray(im.convert("RGB")).astype(np.float32) for k, im in immagini.items()}
    C = mappe["basecolor"]
    H, W = C.shape[:2]
    if lato_atteso is not None and (W, H) != (lato_atteso, lato_atteso):
        raise RuntimeError("la mappa colore e' %dx%d, gli adesivi sono segnati su %d"
                           % (W, H, lato_atteso))
    for k, M in mappe.items():
        if M.shape[:2] != (H, W):
            raise RuntimeError("la mappa %s non ha la misura della mappa colore" % k)
    C0 = C.copy()
    originali = {k: M.copy() for k, M in mappe.items()}
    sat = cv2.cvtColor(C0.astype(np.uint8), cv2.COLOR_RGB2HSV)[..., 1].astype(np.float32)
    rifatti = 0
    for (x, y, w, h, tipo, margine) in adesivi:
        (X0, Y0, X1, Y1), omega, estranei, fondo = _zona(C0, x, y, w, h, tipo, margine)
        ys, xs = np.nonzero(omega)
        if len(xs) == 0:
            print("    adesivo a %d,%d: non trovato" % (x, y))
            continue
        b = 4
        # il riquadro resta dentro la finestra in cui la toppa e' stata calcolata
        bx0, by0 = max(X0, X0 + xs.min() - b), max(Y0, Y0 + ys.min() - b)
        bx1, by1 = min(X1, X0 + xs.max() + 1 + b), min(Y1, Y0 + ys.max() + 1 + b)
        # quanto sono increspate le altre mappe attorno all'adesivo, fuori dalla toppa
        fuori = (omega[by0 - Y0:by1 - Y0, bx0 - X0:bx1 - X0] == 0) &                 (estranei[by0 - Y0:by1 - Y0, bx0 - X0:bx1 - X0] == 0)
        altre = [originali[k] for k in sorted(originali) if k != "basecolor"]
        bordo = [_scarto(M[by0:by1, bx0:bx1][fuori][None]) if fuori.any() else 20.0
                 for M in altre]
        scelta = _sorgente(C0, sat, (bx0, by0, bx1, by1), fondo, altre, bordo)
        if scelta is None:
            raise RuntimeError("adesivo a %d,%d: nessun pezzo di vernice pulita vicino" % (x, y))
        _costo, dx, dy = scelta
        om = omega[by0 - Y0:by1 - Y0, bx0 - X0:bx1 - X0]
        es = estranei[by0 - Y0:by1 - Y0, bx0 - X0:bx1 - X0]
        ignoti = (om > 0) | (es > 0)
        a = cv2.GaussianBlur((om > 0).astype(np.float32), (0, 0), 2.0)[..., None]
        a = np.where((om > 0)[..., None], a, 0.0)
        for M in mappe.values():
            dst = M[by0:by1, bx0:bx1]
            src = M[by0 + dy:by1 + dy, bx0 + dx:bx1 + dx]
            corr = _membrana((dst - src).astype(np.float32), ~ignoti, ignoti)
            M[by0:by1, bx0:bx1] = dst * (1 - a) + (src + corr) * a
        rifatti += 1
    for k, M in mappe.items():
        im = Image.fromarray(np.clip(M + 0.5, 0, 255).astype(np.uint8), "RGB")
        if modi[k] in ("RGBA", "LA"):
            im.putalpha(immagini[k].getchannel("A"))
        im.save(trovate[k])
    print("    tolti %d adesivi su %d mappe (%s)" % (rifatti, len(mappe), ", ".join(sorted(mappe))))
    return rifatti
