# -*- coding: utf-8 -*-
"""Disegna il listello decorativo del bagno, perche' nessuno lo regala.

    python tools/fai_listello.py

PERCHE' NON SI SCARICA. Le librerie CC0 sono piene di piastrelle e non hanno
listelli: il listello e' un pezzo di gusto, e il gusto non si fotografa in una
libreria di materiali generici. Ma e' anche il pezzo che DATA il bagno piu' di tutti
gli altri messi insieme. Un rivestimento bianco che si ferma a un metro e sessanta
senza niente sopra e' un bagno di adesso; lo stesso rivestimento con una fascia di
losanghe azzurrine e' il 1995, e non serve altro.

E' un disegno geometrico di dieci righe: fondo crema, due filetti sottili in alto e
in basso, e una fila di losanghe con il punto in mezzo. Esattamente la cornice che
correva sopra i lavabi di mezza Italia.

Scrive assets/textures/listello/color.jpg e la sua roughness.
"""
import io
import os

from PIL import Image, ImageDraw

QUI = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(os.path.dirname(QUI), "assets", "textures", "listello")

# QUADRATA E CON UN MOTIVO SOLO. La prima versione era 4:1 con quattro losanghe, e
# sarebbe stata sbagliata: le UV di questo progetto si cuociono con una scala sola
# per le due direzioni (vedi TEXTURE in modellare.py), quindi una tessera larga
# quattro volte l'altezza si sarebbe schiacciata sulla fascia mostrandone un quarto.
# Una tessera quadrata con una losanga dentro, ripetuta ogni 8 cm, da' una losanga
# ogni 8 cm - che e' il passo giusto - e non ha modo di deformarsi.
LARGO, ALTO = 256, 256
MOTIVI = 1

FONDO = (238, 233, 223)          # crema, appena piu' caldo della piastrella bianca
FILETTO = (150, 163, 172)        # azzurro grigio spento, come lo smalto di allora
LOSANGA = (163, 180, 190)
CUORE = (208, 196, 168)          # il punto caldo in mezzo, che rompe il monocromo


def disegna():
    img = Image.new("RGB", (LARGO, ALTO), FONDO)
    d = ImageDraw.Draw(img)
    # i due filetti: stretti, e staccati dal bordo. Attaccati al bordo, sul muro,
    # si fondono con la fuga della piastrella sopra e il listello perde il contorno.
    for y in (20, 28, ALTO - 29, ALTO - 21):
        d.line([(0, y), (LARGO, y)], fill=FILETTO, width=3)

    passo = LARGO // MOTIVI
    for k in range(MOTIVI):
        cx = passo * k + passo // 2
        cy = ALTO // 2
        r = int(passo * 0.24)
        d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)],
                  fill=LOSANGA)
        d.polygon([(cx, cy - r // 2), (cx + r // 2, cy), (cx, cy + r // 2),
                   (cx - r // 2, cy)], fill=CUORE)
        # NIENTE TRATTINI FRA UNA LOSANGA E L'ALTRA. In una tessera con un motivo
        # solo cadrebbero sul bordo, cioe' meta' di qua e meta' di la', e basta un
        # pixel di scarto perche' sul muro si vedano doppi o tagliati.
    return img


def main():
    os.makedirs(DEST, exist_ok=True)
    img = disegna()
    img.save(os.path.join(DEST, "color.jpg"), quality=95)
    # UNA RUGOSITA' UNIFORME, non una copiata da un'altra piastrella. Il listello e'
    # smaltato come il resto del rivestimento: se prendesse la rugosita' di un altro
    # materiale rifletterebbe in modo diverso dalla piastrella che ha intorno, e a
    # quel punto si vedrebbe che e' un pezzo appiccicato sopra.
    Image.new("L", (LARGO, ALTO), 58).save(os.path.join(DEST, "roughness.jpg"),
                                           quality=95)
    io.open(os.path.join(DEST, "FONTE.txt"), "w", encoding="utf-8").write(
        "listello: DISEGNATO, non scaricato.\n\n"
        "Lo genera tools/fai_listello.py: fondo crema, due filetti azzurro grigio e\n"
        "una fila di losanghe col cuore caldo. Le librerie CC0 hanno le piastrelle e\n"
        "non hanno i listelli, perche' un listello e' un pezzo di gusto - ed e'\n"
        "proprio il pezzo che data il bagno. Nessuna licenza da rispettare: e'\n"
        "roba nostra.\n\n"
        "Per cambiarlo si cambia lo script, non il file.\n")
    print("listello scritto in %s (%dx%d, %d motivi)" % (DEST, LARGO, ALTO, MOTIVI))


if __name__ == "__main__":
    main()
