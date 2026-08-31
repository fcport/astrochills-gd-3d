# -*- coding: utf-8 -*-
"""Porta i sanitari presi da fuori allo STESSO bianco, misurandolo.

    python tools/pareggia_ceramica.py

IL PROBLEMA NON E' CHE UNO SIA BRUTTO: e' che sono tre. Tre modelli presi da tre
autori diversi arrivano con tre bianchi diversi, e in una stanza sola la differenza
non si legge come "ceramiche di eta' diverse" - si legge come un errore. Misurati, il
bidet stava a 227 su 255, il water a 174 con una dominante calda, il lavabo a 130.
Il primo sembrava bianco, il terzo sembrava fango, e nessuno dei tre era sbagliato da
solo.

E NON SI PUO' SCHIARIRE NEL MATERIALE. Il colore di base di un glTF e' un FATTORE che
moltiplica la mappa, e un fattore sta fra zero e uno: si puo' scurire, non schiarire.
L'unico posto dove si schiarisce e' la mappa stessa, quindi si riscrive quella.

Si riparte SEMPRE dall'originale scaricato, mai dal file gia' corretto: applicare due
volte la correzione porterebbe la ceramica al bianco assoluto, e la seconda volta
nessuno se ne accorgerebbe perche' il numero misurato sarebbe gia' giusto.
"""
import io
import os
import sys

from PIL import Image, ImageStat

QUI = os.path.dirname(os.path.abspath(__file__))
ESTERNI = os.path.join(os.path.dirname(QUI), "assets", "models", "esterni")

# Il bianco a cui si portano tutti, su 255. Non 255 e nemmeno 240: una ceramica
# smaltata sotto una plafoniera non e' un foglio di carta, e un bianco troppo alto
# in una stanza buia diventa l'unica cosa che si vede. 212 e' il bianco del bidet
# appena abbassato, cioe' quello che gia' funzionava.
BERSAGLIO = 212.0

# Quanto si puo' schiarire al massimo. Oltre questo la mappa si slava: le ombre
# dipinte dentro la texture diventano grigio uniforme e l'oggetto perde il volume.
# Chi sfora non va corretto, va SOSTITUITO - ed e' il caso del lavabo a 130.
SCHIARIMENTO_MASSIMO = 1.45

# I sanitari, e con che nome si chiama la loro mappa originale
CERAMICHE = ("wc_bagno", "bidet_bagno", "lavabo_bagno")
ORIGINALI = ("_basecolor", "_diffuse", "_albedo")

LATO = 1024


def originale(cartella):
    """La mappa colore come l'ha scaricata Sketchfab, non la nostra."""
    dentro = os.path.join(ESTERNI, cartella, "textures")
    if not os.path.isdir(dentro):
        return None
    for n in sorted(os.listdir(dentro)):
        radice = os.path.splitext(n.lower())[0]
        if any(radice.endswith(s) for s in ORIGINALI):
            return os.path.join(dentro, n)
    return None


def misura(im):
    s = ImageStat.Stat(im.convert("RGB"))
    return sum(s.mean) / 3.0, s.mean, sum(s.stddev) / 3.0


def main():
    problemi = []
    print("")
    for cartella in CERAMICHE:
        via = originale(cartella)
        if via is None:
            print("%-14s la mappa originale non c'e'" % cartella)
            continue
        im = Image.open(via).convert("RGB")
        if max(im.size) > LATO:
            im = im.resize((LATO, LATO), Image.LANCZOS)
        grigio, canali, sd = misura(im)
        k = BERSAGLIO / max(1.0, grigio)

        # LA DOMINANTE SI TOGLIE PER CANALE. Il water arriva con 180/179/164: un
        # bianco che tira al giallo. Scalando tutti e tre i canali dello stesso
        # fattore il giallo resta, solo piu' chiaro - e accanto a un bidet neutro si
        # vede. Ogni canale va al bersaglio per conto suo.
        fattori = [BERSAGLIO / max(1.0, c) for c in canali]
        fuori_scala = max(fattori) > SCHIARIMENTO_MASSIMO
        segnale = os.path.join(ESTERNI, cartella, "DA_SOSTITUIRE.txt")
        if fuori_scala:
            # E LO SI SCRIVE SU DISCO, non solo a schermo. Un modello bocciato che
            # resta montato e' peggio di un segnaposto: il segnaposto si vede che e'
            # provvisorio, il modello sbagliato sembra una scelta. `bagno_blender.py`
            # legge questo file e torna al segnaposto finche' non arriva il buono.
            io.open(segnale, "w", encoding="utf-8").write("\n".join([
                "Bocciato da tools/pareggia_ceramica.py.", "",
                "La sua mappa colore sta a %.0f su 255 e per arrivare a %.0f"
                % (grigio, BERSAGLIO),
                "andrebbe schiarita di %.2f volte, oltre il %.2f ammesso: a quel"
                % (max(fattori), SCHIARIMENTO_MASSIMO),
                "punto le ombre dipinte dentro la texture diventano grigio",
                "uniforme e l'oggetto perde il volume.", "",
                "Serve un altro modello. Finche' questo file c'e', il",
                "modellatore monta il segnaposto.", ""]))
            problemi.append(
                "%s: per arrivare a %d va schiarito di %.2f volte, oltre il %.2f "
                "ammesso. A quel punto la mappa si slava e l'oggetto perde il "
                "volume: questo modello va SOSTITUITO, non corretto."
                % (cartella, BERSAGLIO, max(fattori), SCHIARIMENTO_MASSIMO))
            continue

        if os.path.exists(segnale):
            os.remove(segnale)          # promosso: il segnale non serve piu'
        tab = []
        for f in fattori:
            tab.extend([min(255, int(v * f + 0.5)) for v in range(256)])
        fuori = im.point(tab)
        dopo, _c, sd2 = misura(fuori)
        fuori.save(os.path.join(ESTERNI, cartella, "textures", "color.jpg"),
                   quality=92)
        print("%-14s %5.1f -> %5.1f   (x%.2f %.2f %.2f)   chiazze %4.1f -> %4.1f"
              % (cartella, grigio, dopo, fattori[0], fattori[1], fattori[2], sd, sd2))

    if problemi:
        print("\nDA SOSTITUIRE:")
        for p in problemi:
            print("  " + p)
        return 1
    print("\ntutte le ceramiche a %d su 255: in una stanza sola devono essere lo "
          "stesso bianco" % BERSAGLIO)
    return 0


if __name__ == "__main__":
    sys.exit(main())
