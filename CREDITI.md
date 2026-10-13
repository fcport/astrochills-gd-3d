# Crediti

Materiale di terzi usato in Astrochill, con la licenza che lo accompagna.

Questo file esiste perché **una delle licenze lo impone**. Fino a ieri tutto ciò che
il progetto prendeva da fuori era CC0 — nessuna attribuzione richiesta — e bastava il
`FONTE.txt` accanto a ogni cartella. Il telescopio no: è CC-BY, e la CC-BY chiede che
il credito viaggi *col gioco*, non con la cartella di lavoro. `assets/models/` è
ignorato da git e non finisce in nessuna copia distribuita, quindi un credito scritto
solo lì non sarebbe un credito.

Chi aggiunge un asset non CC0 aggiunge una riga qui, nello stesso momento.

## Modelli 3D

**Reflector telescope** — il telescopio della cupola.
Autore: [GhInko](https://sketchfab.com/GhInko).
Fonte: <https://sketchfab.com/3d-models/reflector-telescope-62549e8c60d24ee5adb2a01a2c226a03>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Reflector telescope"
> (https://sketchfab.com/3d-models/reflector-telescope-62549e8c60d24ee5adb2a01a2c226a03)
> by GhInko (https://sketchfab.com/GhInko) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

Il modello arriva col treppiede da campagna e senza gerarchia; qui viene montato su un
pilastro e riarticolato sui due assi equatoriali da `tools/telescopio_blender.py`. La
licenza permette le modifiche e l'uso commerciale, a patto del credito qui sopra.

**Cosmic Eye of Horror** — l'occhio che esce nella stampa al posto del soggetto (`Ctrl+F6`).
Autore: [Huntaer87](https://sketchfab.com/huntaer87).
Fonte: <https://sketchfab.com/3d-models/cosmic-eye-of-horror-06da91d166d844b98bac8484652301cf>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Cosmic Eye of Horror"
> (https://sketchfab.com/3d-models/cosmic-eye-of-horror-06da91d166d844b98bac8484652301cf)
> by Huntaer87 (https://sketchfab.com/huntaer87) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

Nel gioco non c'è il modello ma una sua immagine: `tools/occhio_cosmico_blender.py` lo rende di
fronte, senza luci, in `assets/textures/occhio_cosmico/occhio.png`, e il gioco lo sfuma e lo
sviluppa dentro la foto stampata.

**GRO 17102,0 (Astromaterials 3D)** — la meteorite del colore venuto dallo spazio (`Ctrl+F8`).
Autori: NASA Astromaterials Acquisition & Curation Office, Astromaterials 3D. Una meteorite
ferrosa IAB raccolta dall'ANSMET sui Grosvenor Mountains (Antartide) nel 2017, fotografata e
ricostruita in 3D.
Fonte: <https://ares.jsc.nasa.gov/astromaterials3d/sample-details.htm?sample=GRO17102-0>
Licenza: pubblico dominio (NASA), con la richiesta di citare la fonte come sotto.

> NASA/These 3D reconstructed image data were produced at the Antarctic Meteorite Sample Laboratory
> Facility for Astromaterials 3D in NASA's Acquisition & Curation Office and were funded by NASA
> Planetary Data Archiving, Restoration, and Tools Program, Proposal No.: 15-PDART15_2-0041.

La scarica `tools/meteorite_blender.py` (il modello a bassa risoluzione), che la centra, la
riduce a un terzo dei triangoli e ne porta la texture a 2048.

**Human Base Meshes** (v1.4.1) — il braccio umano delle braccia all'orizzonte (`Ctrl+F4`).
Autore: Blender Studio.
Fonte: <https://www.blender.org/download/demo-files/#assets>
Licenza: [CC0](https://creativecommons.org/publicdomain/zero/1.0/) — nessuna attribuzione richiesta.

Lo scarica `tools/braccio_umano_blender.py`, che dal corpo "Body Male - Realistic" taglia il
braccio destro alla spalla e lo arma con le giunture prese dai face set del modello.

**Lavabo** — il lavabo a semicolonna del bagno.
Autore: [Antonio Rossin](https://sketchfab.com/antoniorossin).
Fonte: <https://sketchfab.com/3d-models/33cbd0ac6ae24bd292783a4e06fc4138>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Lavabo"
> (https://sketchfab.com/3d-models/33cbd0ac6ae24bd292783a4e06fc4138)
> by Antonio Rossin (https://sketchfab.com/antoniorossin) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Game Ready - Dirty Old Toilet** — il water del bagno.
Autore: [Allan-Jay Branscombe](https://sketchfab.com/AllanJayBranscombe).
Fonte: <https://sketchfab.com/3d-models/6ac515a1c4154db18b5b4bd0b46d6405>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Game Ready - Dirty Old Toilet"
> (https://sketchfab.com/3d-models/6ac515a1c4154db18b5b4bd0b46d6405)
> by Allan-Jay Branscombe (https://sketchfab.com/AllanJayBranscombe) licensed under
> CC-BY-4.0 (http://creativecommons.org/licenses/by/4.0/)

**Bidet** — il bidet del bagno. Arriva bianco di fabbrica e viene invecchiato da
`tools/bagno_blender.py`: di bidet vecchi non ne esiste uno con licenza libera, e non
è un caso — il bidet è un oggetto italiano e le librerie 3D sono anglosassoni.
Autore: [Joele segreto](https://sketchfab.com/joelesegreto).
Fonte: <https://sketchfab.com/3d-models/e52d1be9d7594dd39c8ae8e3dcab9cd5>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Bidet"
> (https://sketchfab.com/3d-models/e52d1be9d7594dd39c8ae8e3dcab9cd5)
> by Joele segreto (https://sketchfab.com/joelesegreto) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Old Radiator** — il termosifone del bagno. Radiatore di ghisa a colonne con
valvola termostatica. Quello fatto a mano prima aveva la forma giusta ma non poteva
avere i sessant'anni: la ruggine attorno alla valvola e lo smalto scrostato sono
texture, non geometria.
Autore: [thethieme](https://sketchfab.com/thethieme).
Fonte: <https://sketchfab.com/3d-models/old-radiator-8a1a2e0263aa401591c1e87d824a79ef>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Old Radiator"
> (https://sketchfab.com/3d-models/old-radiator-8a1a2e0263aa401591c1e87d824a79ef)
> by thethieme (https://sketchfab.com/thethieme) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Metal door** — il battente della porta del magazzino. Lamiera verniciata con
maniglia a leva e bocchetta a chiave, 338 facce. Quella fatta a mano aveva i pezzi
giusti — nervature, griglia, portalucchetto — ma erano scatole, e da un metro si
vedeva: una porta di lamiera la fa la vernice, cioè la texture, non il rilievo. Del
modello si tiene **solo il battente**: il telaio ce l'abbiamo già, lo disegna
`osservatorio_blender.py` dai vani.
Autore: [tboiston](https://sketchfab.com/tboiston).
Fonte: <https://sketchfab.com/3d-models/metal-door-5174e00a43a541e8bdd0f407c6502877>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Metal door"
> (https://sketchfab.com/3d-models/metal-door-5174e00a43a541e8bdd0f407c6502877)
> by tboiston (https://sketchfab.com/tboiston) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Interior Wood Doors Pack 1** — il battente delle cinque porte interne di legno.
Porta tamburata liscia finto mogano, con maniglia a leva su rosetta e serratura sul
bordo: è la porta interna di un edificio pubblico italiano di fine anni Novanta. Le
nostre erano una lastra con la venatura e nessuna maniglia. Del pacchetto si tiene
**una porta sola** (la D2, il mogano; la D1 è wengé) e **solo il battente**, senza
telaio né cardini: `tools/porte_legno_blender.py` lo porta allo spessore del nostro
vano e ne fa un .glb unico per tutte e cinque.
Autore: [Toni García Vilche](https://sketchfab.com/zul_gv).
Fonte: <https://sketchfab.com/3d-models/interior-wood-doors-pack-1-32707dcfa6304f49bf99148d0211f5f7>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Interior Wood Doors Pack 1"
> (https://sketchfab.com/3d-models/interior-wood-doors-pack-1-32707dcfa6304f49bf99148d0211f5f7)
> by Toni García Vilche (https://sketchfab.com/zul_gv) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Refrigerator (low-poly)** — il frigorifero della cucina. Doppia porta col
congelatore in alto, vernice consumata e ruggine, 2.448 facce. Il modello porta
dodici adesivi e un disegno a gesso **dipinti nelle mappe**: li toglie
`tools/ritocca_texture.py` quando `prendi_modello.py` spacchetta lo zip, ricopiando
sopra la vernice pulita accanto su colore, rugosità e rilievo. È una modifica, e la
licenza la permette.
Autore: [Vladimir_kizx](https://sketchfab.com/kizx3d).
Fonte: <https://sketchfab.com/3d-models/refrigerator-low-poly-1b0d689a926244e9a72b50e25c7e2a45>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Refrigerator (low-poly)"
> (https://sketchfab.com/3d-models/refrigerator-low-poly-1b0d689a926244e9a72b50e25c7e2a45)
> by Vladimir_kizx (https://sketchfab.com/kizx3d) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Stove with Hood** — la cappa della cucina. Nel file sta sopra una cucina elettrica:
se ne usa solo la cappa, piatta, da 76 cm, con le levette di luce e ventola.
Autore: [HippoStance](https://sketchfab.com/hippostance).
Fonte: <https://sketchfab.com/3d-models/stove-with-hood-ce6f590e7cb848e398c80208ee3b6fdf>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Stove with Hood"
> (https://sketchfab.com/3d-models/stove-with-hood-ce6f590e7cb848e398c80208ee3b6fdf)
> by HippoStance (https://sketchfab.com/hippostance) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Kitchen Appliances** — il contatore del gas della cucina. Del set si usa solo il
contatore a membrana con il montante e la discesa, ridotto a 0,68 e col montante
allungato fino al soffitto.
Autore: [Nicolai Kilstrup](https://sketchfab.com/nkilstrup).
Fonte: <https://sketchfab.com/3d-models/kitchen-appliances-0b01a398fe1649aaacd6ebdf85bf5d6c>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Kitchen Appliances"
> (https://sketchfab.com/3d-models/kitchen-appliances-0b01a398fe1649aaacd6ebdf85bf5d6c)
> by Nicolai Kilstrup (https://sketchfab.com/nkilstrup) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Small Fuse Box** — il quadro elettrico in facciata, accanto all'ingresso. È il
contatore che il GDD mette lì: governa le luci di tutto l'edificio e si arma a mano,
di notte, uscendo. Del modello contano **due mesh separate**, cassa e anta — un
quadro che non si apre è una scatola sul muro — e arriva con l'anta spalancata a 58
gradi: `tools/quadro_elettrico_blender.py` la chiude per costruzione e deduce da
quale spigolo si è mosso di meno dove sta il cardine. Il **fungo rosso** non c'è nel
modello e lo mettiamo noi, che è la stessa regola del pilastro sotto il telescopio:
si modella il pezzo che manca e che deve muoversi.
Autore: [big guy](https://sketchfab.com/ondra.lit).
> This work is based on "Small Fuse Box"
> (https://sketchfab.com/3d-models/small-fuse-box-1818361dc6554d17bef8c0400959f93f)
> by big guy (https://sketchfab.com/ondra.lit) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Dispensador de toalla de papel** — il distributore di salviette del bagno.
Del modello si prende solo la **forma**: la calotta arrotondata, il labbro da cui
esce il foglio e il fondo rastremato sono tre curve, e con le scatole non si fanno.
Arriva bianco senza mappe, ed è giusto così — in un bagno del 1999 sarebbe l'unica
cosa nuova della stanza: la lamiera verniciata e scrostata gliela mette
`tools/bagno_blender.py`.
Autore: [tlalokan](https://sketchfab.com/tlalokan).
Fonte: <https://sketchfab.com/3d-models/dispensador-de-toalla-de-papel-paper-dispenser-4af9dde390bd4c35b5f978142187cfeb>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Dispensador de toalla de papel - Paper dispenser"
> (https://sketchfab.com/3d-models/dispensador-de-toalla-de-papel-paper-dispenser-4af9dde390bd4c35b5f978142187cfeb)
> by tlalokan (https://sketchfab.com/tlalokan) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**toilet paper dispenser** — il portarotolo accanto al water. È il pezzo che un
bagno non può non avere e che nessuno nota finché non manca: un water senza
portarotolo accanto legge come un sanitario da catalogo, non come un cesso in
servizio. Questo arriva già fatto — braccio, rotolo, lembo che pende — e l'unica
cosa corretta è `metallicFactor`, che in glTF vale uno se non è dichiarato.
Autore: [tobei](https://sketchfab.com/tobei).
Fonte: <https://sketchfab.com/3d-models/toilet-paper-dispenser-96e96772a7564df0b417244bd2be33f3>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "toilet paper dispenser"
> (https://sketchfab.com/3d-models/toilet-paper-dispenser-96e96772a7564df0b417244bd2be33f3)
> by tobei (https://sketchfab.com/tobei) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Retro CRT Computer (1990s Desktop PC)** — la **tastiera** e il **mouse** della
consolle. Del modello si prendono solo quei due pezzi: il monitor resta l'altro,
perché ha lo schermo staccato dalla cassa e questo no — e uno schermo che il gioco non
può comandare è un adesivo. La tastiera fatta a mano aveva ottanta tasti veri, cinque
righe per sedici colonne, e da un metro erano ottanta scatole.
Autore: [MadeByYeshe](https://sketchfab.com/MadeByYeshe).
Fonte: <https://sketchfab.com/3d-models/retro-crt-computer-1990s-desktop-pc-ea9faf1298d24497b916c27a4ea38636>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Retro CRT Computer (1990s Desktop PC)"
> (https://sketchfab.com/3d-models/retro-crt-computer-1990s-desktop-pc-ea9faf1298d24497b916c27a4ea38636)
> by MadeByYeshe (https://sketchfab.com/MadeByYeshe) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Phone** — il telefono della sala di controllo. Nel 1999 è l'unico modo che ha questo
posto di parlare con l'esterno. Arriva con la **cornetta posata di fianco** invece che
sulla forcella, e il filo a spirale che ne esce: è il dettaglio che dice che qualcuno
ha telefonato, e con le scatole non si fa.
Autore: [Schmoldt5000](https://sketchfab.com/Schmoldt5000).
Fonte: <https://sketchfab.com/3d-models/phone-eaa0a0cbce964b2099b955f5ea241eee>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Phone"
> (https://sketchfab.com/3d-models/phone-eaa0a0cbce964b2099b955f5ea241eee)
> by Schmoldt5000 (https://sketchfab.com/Schmoldt5000) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**OKIDATA Microline 320 Turbo** — la stampante ad aghi della sala di controllo.
Autore: [Remik.Papaj](https://sketchfab.com/Remik.Papaj).
Fonte: <https://sketchfab.com/3d-models/okidata-microline-320-turbo-f7bf859023544e91ab622a8f18862ecf>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "OKIDATA Microline 320 Turbo"
> (https://sketchfab.com/3d-models/okidata-microline-320-turbo-f7bf859023544e91ab622a8f18862ecf)
> by Remik.Papaj (https://sketchfab.com/Remik.Papaj) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

È una macchina vera del 1990, nove aghi, e sostituisce le tre scatole che facevano
la stampante a mano. Arriva con un materiale solo per quattordici mesh, dichiarato
trasparente perché tre di quelle sono il coperchio acrilico: `opacizza_il_pieno()` in
`tools/modellare.py` rimette piene le altre undici. Il modulo continuo non ce l'ha, e
resta fatto a mano da `tools/arredi_blender.py`.

**Kitchen Sink** — il lavello della cucina. Un blocco da incasso con la vasca, il
gocciolatoio e il miscelatore; sostituisce la vasca d'acciaio fatta a mano, e sotto il
piano di lavoro sparisce dentro il mobile.
Autore: [Heliona](https://sketchfab.com/Heliona).
Fonte: <https://sketchfab.com/3d-models/kitchen-sink-d4044684be3a45d2b8b81dbcb83847fa>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Kitchen Sink"
> (https://sketchfab.com/3d-models/kitchen-sink-d4044684be3a45d2b8b81dbcb83847fa)
> by Heliona (https://sketchfab.com/Heliona) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Plate** — i quattro piatti nello scolapiatti della cucina, tutti dallo stesso modello.
Autore: [Black Snow](https://sketchfab.com/BlackSnow02).
Fonte: <https://sketchfab.com/3d-models/plate-519c319332ed4708ba4b3ca1dfd5f54a>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Plate"
> (https://sketchfab.com/3d-models/plate-519c319332ed4708ba4b3ca1dfd5f54a)
> by Black Snow (https://sketchfab.com/BlackSnow02) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**1965 Fiat 500F** — l'auto parcheggiata fuori, quella con cui il giocatore torna a
casa all'alba. **È un segnaposto, e va sostituito prima di distribuire il gioco.** È
l'unico asset del progetto con una licenza **non commerciale** (NC) e **condivisa allo
stesso modo** (SA): con questa auto dentro il gioco non si vende, e la versione ridotta
che ne fa `tools/cinquecento_blender.py` — motore e vani buttati, decimata a ventimila
facce — resta sotto la stessa licenza. Federico l'ha scelta sapendolo, al posto della
scatola grigia da quattro metri, finché non c'è un'auto con una licenza con cui si
distribuisce.
Autore: [Ddiaz Design](https://sketchfab.com/ddiaz-design).
Fonte: <https://sketchfab.com/3d-models/1965-fiat-500f-91c9a625d0c24026b266fbe68352e6fa>
Licenza: [CC-BY-NC-SA 4.0](http://creativecommons.org/licenses/by-nc-sa/4.0/) — **attribuzione obbligatoria, niente uso commerciale, modifiche sotto la stessa licenza**.

> This work is based on "1965 Fiat 500F"
> (https://sketchfab.com/3d-models/1965-fiat-500f-91c9a625d0c24026b266fbe68352e6fa)
> by Ddiaz Design (https://sketchfab.com/ddiaz-design) licensed under CC-BY-NC-SA-4.0
> (http://creativecommons.org/licenses/by-nc-sa/4.0/)

**Pair of mops** — il mocio del magazzino, quello che pulisce il caffè rovesciato. Del set
si tiene il mocio pulito; `tools/mocio_blender.py` ne raddrizza il manico, lo porta a un
metro e trenta e ne decima le frange.
Autore: [Sousinho](https://sketchfab.com/sousinho).
Fonte: <https://sketchfab.com/3d-models/pair-of-mops-56daf9708906449ea4f8576790ee476f>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Pair of mops"
> (https://sketchfab.com/3d-models/pair-of-mops-56daf9708906449ea4f8576790ee476f)
> by Sousinho (https://sketchfab.com/sousinho) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**3 English Oak Set (Quercus Robur) \*Updated** — tre querce spoglie, gli alberi lontani
del panorama (sagome fotografate da `tools/alberi_blender.py`, che ai rami con le gemme
sostituisce quelli nudi dello stesso modello).
Autore: [Yag1z](https://sketchfab.com/Yag1z).
Fonte: <https://sketchfab.com/3d-models/3-english-oak-set-quercus-robur-updated-750fac732a8c453e9dd748f1396275fa>,
scaricato dall'archivio [Objaverse](https://huggingface.co/datasets/allenai/objaverse).
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "3 English Oak Set (Quercus Robur) *Updated"
> (https://sketchfab.com/3d-models/3-english-oak-set-quercus-robur-updated-750fac732a8c453e9dd748f1396275fa)
> by Yag1z (https://sketchfab.com/Yag1z) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

**Free Tree fullsize photogrammetry scan 2 Draft** — l'albero spoglio scansionato: quelli
vicini al recinto in 3D, e una delle sagome lontane. `tools/alberi_blender.py` gli toglie
la zolla, lo porta a tredici metri e ne riduce la copia in 3D al cinque per cento.
Autore: [Epic_Tree_Store](https://sketchfab.com/johngreenstone).
Fonte: <https://sketchfab.com/3d-models/free-tree-fullsize-photogrammetry-scan-2-draft-fabc5ef137854b369152062b59444159>,
scaricato dall'archivio [Objaverse](https://huggingface.co/datasets/allenai/objaverse).
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> This work is based on "Free Tree fullsize photogrammetry scan 2 Draft"
> (https://sketchfab.com/3d-models/free-tree-fullsize-photogrammetry-scan-2-draft-fabc5ef137854b369152062b59444159)
> by Epic_Tree_Store (https://sketchfab.com/johngreenstone) licensed under CC-BY-4.0
> (http://creativecommons.org/licenses/by/4.0/)

## Il paesaggio

Il panorama attorno all'osservatorio (`world/panorama.gd`) è fatto di dati veri,
scaricati e trasformati da `tools/prendi_panorama.py`. Quattro licenze su cinque chiedono
il credito.

**TINITALY 1.1** — il rilievo a dieci metri attorno all'osservatorio (tessera w48575).
Autori: Tarquini S., Isola I., Favalli M., Battistini A., Dotta G., Istituto Nazionale di
Geofisica e Vulcanologia (INGV).
Fonte: <https://tinitaly.pi.ingv.it/>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> Tarquini S., Isola I., Favalli M., Battistini A., Dotta G. (2023). TINITALY, a digital
> elevation model of Italy with a 10 meters cell size (Version 1.1). Istituto Nazionale di
> Geofisica e Vulcanologia (INGV). https://doi.org/10.13127/tinitaly/1.1

**Copernicus DEM GLO-30** — il rilievo lontano, fino a quarantacinque chilometri.
Fonte: <https://registry.opendata.aws/copernicus-dem/>
Licenza: licenza Copernicus DEM, uso libero anche commerciale con il credito.

> Produced using Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space
> GmbH 2014-2018 provided under COPERNICUS by the European Union and ESA; all rights reserved.

**Sentinel-2 L2A** — il colore del terreno: la scena S2B_32TQP del 19 novembre 2020.
Fonte: <https://registry.opendata.aws/sentinel-2-l2a-cogs/>
Licenza: dati Copernicus Sentinel, liberi e aperti, con il credito.

> Contains modified Copernicus Sentinel data 2020.

**ESA WorldCover 2021** — dove stanno gli alberi e dove le luci dei paesi.
Fonte: <https://esa-worldcover.org/>
Licenza: [CC-BY 4.0](http://creativecommons.org/licenses/by/4.0/) — **attribuzione obbligatoria**.

> © ESA WorldCover project 2021 / Contains modified Copernicus Sentinel data (2021) processed
> by ESA WorldCover consortium.

**OpenStreetMap** — le strade attorno all'osservatorio, e dove sta l'edificio.
Fonte: <https://www.openstreetmap.org/>
Licenza: [ODbL](https://opendatacommons.org/licenses/odbl/) — **attribuzione obbligatoria**.

> © OpenStreetMap contributors

**Regione Marche, Geoportale** — il recinto, il cancello, la ghiaia e il viottolo attorno
all'edificio (D-276): la Carta Tecnica Regionale 2019 (1:10.000) e l'ortofoto AGEA 2022,
consultate dal servizio WMS del Geoportale. Nel gioco non c'è nessuna delle due immagini:
ci sono le misure che se ne sono prese, scritte in `tools/geometria.py`.
Fonte: <https://www.regione.marche.it/Regione-Utile/Paesaggio-Territorio-Urbanistica/Cartografia>
Licenza: da verificare sul Geoportale; il servizio WMS non dichiara vincoli di accesso.

> Cartografia: Regione Marche — Carta Tecnica Regionale 2019; ortofoto AGEA 2022.

## Immagini

**Le foto delle stampe**: `assets/stampe/*.png`, le pagine che escono dalla stampante
della sala di controllo (D-239). Le compone `tools/stampe_foto.py` a partire dalle PNG del
prototipo Phaser (`phaser_astrochill/public/assets/photos`), tre versioni ciascuna: M1, M8,
M13, M16, M22, M27, M31, M33, M42, M45, M51, M57, M82, M97, M104, NGC 869, NGC 891, NGC 2237,
NGC 7000 e IC 1396. Le ultime quattordici sono arrivate con i cataloghi (D-261).
**Fonte e licenza: non documentate.** Sono astrofotografie vere, e il prototipo le usa
senza dire da dove vengono. Prima di distribuire il gioco vanno rintracciati autore e
licenza di ognuna, e scritti qui.

## Tutto il resto

Gli altri modelli e tutte le texture sono **CC0**: nessuna attribuzione richiesta.
Restano comunque tracciati, uno per uno e con il motivo della scelta, in
`tools/prendi_texture.py`, `tools/prendi_modello.py` e nei `FONTE.txt` che quegli
script scrivono accanto a ogni cartella scaricata.

- Texture: [ambientCG](https://ambientcg.com) (CC0)
- Il **listello** del bagno non viene da nessuna parte: lo disegna
  `tools/fai_listello.py`. Le librerie CC0 hanno le piastrelle e non hanno i
  listelli, perché un listello è un pezzo di gusto — ed è proprio il pezzo che data
  il bagno.
- Modelli: [Poly Haven](https://polyhaven.com) (CC0), [OpenGameArt](https://opengameart.org) (solo voci CC0)

## Riferimenti visivi (non sono asset)

Modelli guardati per decidere come deve essere fatta una cosa, e mai scaricati né
usati. Stanno qui perché il giorno in cui il segnaposto diventerà un modello vero
si riparta da dove si era guardato, invece che da capo.

- **Il sito dell'osservatorio** (D-273): cinque fotogrammi di Google Street View
  (© 2025 Google) dalla sterrata davanti al cancello, mandati da Federico il 16
  settembre 2026. Hanno deciso la rete verde del recinto, gli alberi spogli lungo la
  strada, la strada bianca e il bosco sul versante. Non sono nel gioco né nel
  repository.

- **Quadro della cupola** (i due pulsanti a muro, D-171): *Old Soviet Electrical
  Junction Box (220V)* di uliana, Sketchfab, CC-BY —
  https://sketchfab.com/models/fe37bff7b3fa45a7960b7defa30b3f3e
  Scatola verniciata grigio-verde con targa e triangolo di pericolo: è
  esattamente quello che starebbe sul muro di una cupola italiana del 1985. La
  targa in cirillico è la ragione per cui è un riferimento e non un asset.

## Mappe

**CGI Moon Kit** — la faccia e il rilievo della Luna in cielo e all'oculare.
Autori: NASA's Scientific Visualization Studio (visualizzazione di Ernie Wright, USRA;
scienziato Noah Petro, NASA/GSFC), dai dati della camera LROC e dell'altimetro LOLA del
Lunar Reconnaissance Orbiter.
Fonte: <https://svs.gsfc.nasa.gov/4720/>
Licenza: pubblico dominio (NASA), con la richiesta di citare la fonte.

> Moon maps courtesy of NASA's Scientific Visualization Studio.

Le scarica `tools/prendi_luna.py`; la mappa del rilievo è ricavata dalle quote LOLA, senza
esagerazione.

**Deep Star Maps 2020** — la Via Lattea nel cielo (`assets/textures/via_lattea`).
Autori: NASA/Goddard Space Flight Center Scientific Visualization Studio (visualizzazione di
Ernie Wright, USRA), dai cataloghi Hipparcos-2, Tycho-2 e Gaia DR2.
Fonte: <https://svs.gsfc.nasa.gov/4851/> — lo strato «milkyway», senza le stelle brillanti.
Licenza: NASA, con la richiesta di citare la fonte come sotto.

> NASA/Goddard Space Flight Center Scientific Visualization Studio. Gaia DR2: ESA/Gaia/DPAC.

La scarica `tools/prendi_via_lattea.py`, che la dimezza, la sfuma di un texel e ne scrive la
radice.

**PMNM - He'e Octopus** — la pelle del tentacolo (`assets/textures/pelle-polpo`) e l'iride
dell'occhio nel cielo (`assets/textures/iride-polpo`).
Autore: Greg McFall/NOAA, Papahānaumokuākea Marine National Monument (Gardner Pinnacles,
18 settembre 2011): un polpo diurno, *Octopus cyanea*.
Fonte: <https://commons.wikimedia.org/wiki/File:PMNM_-_He%27e_Octopus_(27551309582).jpg>
Licenza: pubblico dominio (NOAA, governo federale degli Stati Uniti).

> Octopus skin texture from a photograph by Greg McFall/NOAA, Papahānaumokuākea Marine National Monument.

La scarica `tools/prendi_pelle.py`, che ne ritaglia un quadrato di sola pelle, toglie la luce
della foto, la rende ripetibile e la tinge verso il grigio livido del tentacolo; e dall'occhio
dello stesso polpo ritaglia un quadrato d'iride, sotto la pupilla.

## Effemeridi

**Keplerian Elements for Approximate Positions of the Major Planets** — le orbite dei
cinque pianeti che si vedono in cielo.
Autore: E. M. Standish, Jet Propulsion Laboratory (NASA/Caltech).
Fonte: <https://ssd.jpl.nasa.gov/planets/approx_pos.html>
Licenza: pubblico dominio (NASA).

Sono i sei elementi orbitali di ciascun pianeta e le loro derive per secolo, adattati ai
minimi quadrati sulle effemeridi DE405 per l'intervallo 1800-2050. Non è un file scaricato:
la tabella sta in chiaro dentro `core/pianeti.gd`, che è il posto giusto per trenta numeri
che non cambieranno mai e senza i quali quel file non calcola niente.

## Citazioni

**The Colour Out of Space** — H. P. Lovecraft, pubblicato su *Amazing Stories* nel 1927.
L'orrore di `Ctrl+F8` (`world/orrori/colore.gd`) ne è una citazione dichiarata: la pietra
che cade, l'erba che brilla di notte e si muove senza vento, il colore che risale al cielo,
la cenere grigia. Due frasi del racconto, tradotte, stanno nella testata di quel file.
Licenza: pubblico dominio (pubblicato negli Stati Uniti nel 1927; l'autore è morto nel 1937).
