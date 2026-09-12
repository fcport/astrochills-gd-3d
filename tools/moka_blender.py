# -*- coding: utf-8 -*-
"""LA MOKA della cucina: l'unico articolo del negozio che aveva gia' il suo codice.

    "D:/programs/blender5/blender.exe" --background --python tools/moka_blender.py

Produce assets/models/moka.glb. Vuole prima:

    python tools/prendi_modello.py moka

PERCHE' ESISTE QUESTO FILE. `world/interactables/moka.gd` e `moka.tscn` sono scritti
da mesi, interi: il rituale, il timer, il borbottio, la comparsa legata al possesso.
Ma la moka NON stava nel mondo, e il suo articolo nel negozio era
`implemented = false` - perche' la sua geometria erano quattro scatole grigie, e
D-183 le ha tolte dalla stanza con una riga che vale la pena rileggere: «fra un posto
vuoto e un posto occupato male, vuoto legge meglio». Il negozio era vuoto per quel
motivo li', e si riempie facendo il modello, non cambiando il filtro.

SI SCARICA, NON SI MODELLA, ed e' la seconda stesura di questo file. La prima
costruiva la Bialetti a ottagoni sulle quote del costruttore - 98 facce a tinta
piatta - e stava in piedi. Ma la regola del progetto e' quella scritta in
`prendi_modello.py` accanto alla pulsantiera: si modella solo quando NON si trova, e
la pulsantiera pendente non si trovava. Una moka si trova. Federico: «trova un
modello per la moca».

QUALE, E PERCHE' QUELLA - vedi la voce `moka` in `prendi_modello.py`, dove la scelta
e' scritta per esteso. In breve: fra ventiquattro moka su Sketchfab si erano tenute le
due Bialetti ottagonali, e Federico ha scelto la CONICA - «ho sbagliato, metti la old
moka». Non e' una Moka Express, e' la forma piu' vecchia; e in un osservatorio di
provincia mezzo abbandonato ci sta la caffettiera lasciata li' vent'anni fa, non
l'oggetto di design che sta al MoMA.

L'ATTRIBUZIONE E' OBBLIGATORIA: CC-BY-4.0, credito in
`assets/models/esterni/moka/FONTE.txt`.

L'ALTEZZA E' DICHIARATA QUI, non presa dal file. Un modello di fuori arriva con la
scala di chi l'ha fatto, e `posa_modello` lo porta all'altezza scritta nell'impronta:
venti centimetri col pomello, che e' una caffettiera conica da tre tazze - piu' alta
e piu' stretta di una Bialetti, che a parita' di tazze ne fa diciassette. Cosi'
quello che si vede e quello contro cui sbatte il raggio del giocatore sono la stessa
cosa, come per tutto il resto del progetto.

L'ORIGINE VA SOTTO E AL CENTRO IN PIANTA, come per tutto quello che si posa su un
piano (vedi `prop_blender.py` e `radiolina_blender.py`): chi la colloca scrive la
quota del bancone e non deve sottrarre mezza altezza.
"""
import os
import sys

import bpy  # noqa: F401

QUI = os.path.dirname(os.path.abspath(__file__))
if QUI not in sys.path:
    sys.path.insert(0, QUI)
from modellare import (esporta, lampada,   # noqa: E402
                       posa_modello, prepara_render, pulisci)

RADICE = os.path.dirname(QUI)
MODELLO = os.path.join(RADICE, "assets", "models", "esterni", "moka", "scene.gltf")
USCITA = os.path.join(RADICE, "assets", "models", "moka.glb")
PROVINO = os.path.join(RADICE, "_confronto", "16_moka.png")

# --- le quote dichiarate: caffettiera conica da tre tazze ---------------------
ALTA = 0.200            # col pomello, dal piano

# L'IMPRONTA IN PIANTA E' LARGA APPOSTA. `posa_modello` scala sull'ALTEZZA e poi
# rimpicciolisce ancora se in pianta non ci sta: un'impronta stretta vorrebbe dire
# una moka piu' bassa dei diciassette centimetri dichiarati, per far entrare il
# manico. Qui comanda l'altezza, e la pianta la si MISURA dopo - vedi il referto.
LARGA = 0.26
FONDA = 0.20

# DI QUANTO SI GIRA, e serve a una cosa sola: da che parte guarda il MANICO.
#
# Il modello nasce col becco verso +z di gioco e il manico verso -z. Sul bancone
# della cucina il muro sta a z minori e la stanza a z maggiori: cosi' com'e', la moka
# offrirebbe il manico al paraschizzi e il becco al giocatore. Mezzo giro, e il manico
# torna dalla parte da cui la si prende - che e' anche il verso in cui una moka la
# lascia chi la usa.
GIRO = 180.0


if not os.path.exists(MODELLO):
    print("\nMANCA il modello scaricato: %s" % MODELLO)
    print("  lancia prima:  python tools/prendi_modello.py moka")
    sys.exit(1)

print("")
pulisci()
# `finisci()` NON C'ENTRA QUI, e la prima stesura la chiamava: quella funzione monta
# le mesh che le primitive di casa hanno accumulato in `GRUPPI`, e un modello
# IMPORTATO in quei gruppi non c'e' mai stato. Tornava zero pezzi e zero facce, cioe'
# un .glb vuoto - senza un errore, perche' esportare niente riesce benissimo.
# I pezzi sono quelli che `posa_modello` restituisce.
posati = posa_modello(MODELLO, (-LARGA / 2, -FONDA / 2, LARGA / 2, FONDA / 2, ALTA),
                      gradi=GIRO)
pezzi = [o for o in posati if o.type == "MESH"]
facce = sum(len(o.data.polygons) for o in pezzi)

# L'INGOMBRO SI MISURA, non si dichiara: e' quello che `moka.tscn` deve usare per il
# volume di collisione, e un numero scritto a mano qui sarebbe la seconda verita'
# sulla stessa cosa. Il corpo e il manico si guardano insieme, perche' la differenza
# fra i due e' esattamente cio' che il collider NON deve contenere.
xs = [(o.matrix_world @ v.co).x for o in pezzi for v in o.data.vertices]
ys = [(o.matrix_world @ v.co).y for o in pezzi for v in o.data.vertices]
zs = [(o.matrix_world @ v.co).z for o in pezzi for v in o.data.vertices]
print("  la moka e' fatta di %d facce in %d pezzi" % (facce, len(pezzi)))
print("  alta %.3f m, ingombro in pianta %.3f x %.3f m" % (max(zs), max(xs) - min(xs),
                                                          max(ys) - min(ys)))
print("  in pianta va da x %.3f a %.3f, y %.3f a %.3f (l'origine e' lo zero)"
      % (min(xs), max(xs), min(ys), max(ys)))
# DA CHE PARTE GUARDA IL MANICO, che e' l'unica cosa che `GIRO` decide. Si stampa il
# baricentro di ogni pezzo invece di guardarlo nel provino: il manico e' scuro e
# sottile, e in un rendering da otto centimetri sta dietro il corpo meta' delle volte.
for o in pezzi:
    n_ = len(o.data.vertices)
    cx = sum((o.matrix_world @ v.co).x for v in o.data.vertices) / n_
    cy = sum((o.matrix_world @ v.co).y for v in o.data.vertices) / n_
    print("    %-22s %4d facce, baricentro x %+.3f y %+.3f (y di Blender = -z di gioco)"
          % (o.name[:22], len(o.data.polygons), cx, cy))
if abs(max(zs) - ALTA) > 0.002:
    print("\nATTENZIONE: e' alta %.3f invece di %.3f" % (max(zs), ALTA))
    sys.exit(1)
if min(zs) < -0.002:
    print("\nATTENZIONE: qualcosa scende sotto il piano di %.3f m" % -min(zs))
    sys.exit(1)
# Il tetto: due modelli scaricati di questa taglia stanno sotto le tremila facce, e
# una moka non ha ragione di costare piu' della camera CCD.
if facce > 3000:
    print("\nATTENZIONE: %d facce per una moka sono troppe." % facce)
    sys.exit(1)

esporta(USCITA)

os.makedirs(os.path.dirname(PROVINO), exist_ok=True)
scatta = prepara_render(800, 800, cielo=(0.18, 0.19, 0.21))
# Luci basse: e' un oggetto da diciassette centimetri. Stessa taratura della
# radiolina, e per la stessa ragione - le potenze copiate da un oggetto grande
# bruciano il nero.
lampada("Chiave", (0.28, 0.32, 0.30), 0.5, tipo="AREA", dimensione=0.5)
lampada("Riempimento", (-0.28, 0.16, 0.22), 0.10)
scatta(PROVINO, (0.18, 0.18, 0.38), (0.0, 0.100, 0.0), lente=50.0)
print("\n  provino: %s" % PROVINO)
