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

## Minuti di gioco consumati da un singolo frame di posa.
@export var min_per_frame: float = 5.0

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
