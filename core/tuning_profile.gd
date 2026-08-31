## Valori di bilanciamento — tutto ciò che è stato SCELTO e potrebbe essere sbagliato.
##
## Se un numero è una verità matematica, è una const nel codice. Se è una
## decisione, sta qui.
##
## `night_length_min` e `game_min_per_sec` sono LA variabile sperimentale
## dell'MVP: l'ipotesi da validare è che l'attesa sia piacevole, e quanto duri
## l'attesa è precisamente ciò che va provato. Per questo esiste anche
## l'override esterno (vedi autoloads/tuning.gd): una build già esportata si
## tara sul posto, senza riaprire l'editor.
class_name TuningProfile
extends Resource

## Durata della notte in minuti di gioco. 21:00 → 06:00 = 540.
@export var night_length_min: float = 540.0

## Quanti minuti di gioco passano per ogni secondo reale.
## 0.6 = una notte in 15 minuti reali (il valore del prototipo Phaser).
@export var game_min_per_sec: float = 0.6

## Quanti minuti di GIOCO vale un minuto di integrazione. La posa dura
## `frame x esposizione`, e questa è la sola manopola che ne cambia il peso senza
## toccare la fisica: a 1.0 un'ora di posa è un'ora di notte.
##
## HA SOSTITUITO `min_per_frame`, che valeva 5.0 minuti a frame FISSI — cioè
## indipendenti dall'esposizione scelta. Con quella regola una posa da 30 secondi
## a frame e una da 600 duravano uguale, e il campo EXPOSURE non cambiava niente:
## né la durata, né il punteggio (segnaposto a 100). Era un valore da regolare
## senza una ragione per regolarlo.
@export var pose_time_scale: float = 1.0

## Finestra su cui si media la deriva per il punteggio della fase polare, in
## secondi reali.
##
## Non è un dettaglio: è la finestra che impedisce di truccare il punteggio
## correggendo un istante prima di chiudere. Troppo corta e il trucco funziona,
## troppo lunga e una correzione onesta a fine fase non viene mai vista.
@export var polar_score_window_sec: float = 8.0

## Velocità di deriva alla quale il punteggio della fase polare è 0, in
## arcominuti al secondo. Sotto, il punteggio sale linearmente fino a 100.
@export var polar_max_drift_rate: float = 0.2

## Diametro delle stelle (HFD, in pixel) al quale la fase del fuoco dà 100.
##
## STA UN FILO SOPRA IL MINIMO CHE L'OTTICA PUÒ DARE, e non è generosità: il minimo
## esatto è un passo su milleottocento, e chiederlo trasformerebbe una fase di
## mestiere in una lotteria di precisione. Sotto questa soglia si prende pieno.
@export var focus_best_hfd: float = 2.7

## Diametro al quale la fase del fuoco dà 0. In mezzo il punteggio scende lineare.
@export var focus_max_hfd: float = 6.5

## La curva a scaglioni del payout: dalla qualità aggregata alle lire.
##
## Ogni voce è `{min_score, lire}`, ordinata per `min_score` crescente: si legge lo
## scaglione più alto con `min_score <= quality` (vedi `photo/payout.gd`).
##
## SEGNAPOSTO (FR22): non tarare. Sono cifre plausibili, non calibrate — la
## progressione (500 → 1500 → 3500 → 7000 → 15000) è una decisione d'economia, e vive
## nel dato. Il `.tres` la sovrascrive; questo default esiste perché lo script resti
## totale se il `.tres` mancasse.
@export var payout_tiers: Array[Dictionary] = [
	{&"min_score": 0, &"lire": 500},
	{&"min_score": 30, &"lire": 1500},
	{&"min_score": 50, &"lire": 3500},
	{&"min_score": 75, &"lire": 7000},
	{&"min_score": 90, &"lire": 15000},
]
