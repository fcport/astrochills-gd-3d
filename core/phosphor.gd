## Il fosforo del CRT: i cinque colori con cui è disegnata ogni schermata del gioco.
##
## STAVANO IN TREDICI FILE, ed è così che si è scoperto che dovevano stare in uno.
## Ogni vista — le sei fasi, il terminale, la BBS, il menu, il riepilogo, la
## vendita, lo stacking — dichiarava le stesse quattro `Color` con gli stessi
## numeri copiati a mano. Finché la palette non cambia, tredici copie sono solo
## brutte; il giorno in cui cambia sono tredici occasioni di dimenticarne una, e la
## schermata dimenticata resta di un altro colore per sempre senza che nessun
## collaudo se ne accorga.
##
## AMBRA E NON VERDE (D-173), e la ragione non è il gusto: chi lavora di notte non
## guarda uno schermo luminoso. L'occhio ci mette venti minuti ad adattarsi al buio
## e un lampo di bianco glieli azzera — è per questo che le sale di controllo degli
## osservatori hanno le luci rosse, ed è per questo che un monitor monocromatico
## caldo, nel 1985, era la scelta di chi poi doveva salire in cupola e vedere
## qualcosa. Il fosforo P3, quello ambra, esisteva ed era comune quanto il P1 verde.
##
## `phases/` può vedere `core/` e nient'altro (tabella dei confini): è per questo
## che questo file sta qui e non in `crt/`, che sarebbe stato il posto più ovvio.
##
## I NUMERI QUI SOTTO NON SONO IL COLORE CHE SI VEDE, e questa riga esiste perché
## chi li legge non li «corregga». Un arancione scritto come lo si vorrebbe —
## (1,0 0,75 0,32) — a schermo esce GIALLO CREMA, e il colpevole è il tonemapping
## della scena: il gioco usa ACES, che comprime i valori alti e nel farlo sposta
## gli arancioni verso il giallo. Il pannello disegnato fuori dal mondo 3D (la
## sonda lo fotografa a grandezza tripla) mostrava l'ambra giusto mentre lo stesso
## pannello dentro il monitor era crema: due immagini della stessa cosa, ed è così
## che si è capito dove guardare. Questi valori sono quindi PRE-COMPENSATI —
## più rossi e meno verdi di quello che vuoi ottenere — e si giudicano sempre
## dentro il monitor, mai qui.
class_name Phosphor
extends RefCounted

## Il fondo: non nero, un bruno quasi spento. Un CRT acceso non ha mai il nero
## assoluto — ha il vetro che restituisce un po' di quello che gli arriva addosso.
const BG := Color(0.045, 0.028, 0.010)

## Il testo e le linee che contano.
const FG := Color(0.88, 0.30, 0.04)

## Quello che c'è ma non chiede attenzione: unità di misura, etichette, comandi.
const DIM := Color(0.56, 0.19, 0.03)

## I bordi dei riquadri e la roba che deve esserci senza vedersi.
const FAINT := Color(0.33, 0.11, 0.02)

## La riga selezionata, negli elenchi. Più chiara del testo, non di un altro colore:
## un fosforo monocromatico ha una sola tinta e tutto il resto è quanta corrente gli
## arriva.
const SEL := Color(0.97, 0.48, 0.12)
