## Stato di una notte. SOLO DATI, nessuna logica.
##
## Tenuta dall'autoload sottile `Game`, che è un portachiavi e non un cervello.
## Si costruisce con NightRun.new() in un test, senza caricare alcun autoload.
##
## Salvata con ResourceSaver su user://saves/*.tres — leggibile, diffabile, e
## apribile in un editor di testo durante la validazione dell'MVP.
class_name NightRun
extends Resource

## Incrementare a ogni cambio di formato, e gestirlo in _migrate().
const CURRENT_VERSION := 1

@export var version: int = CURRENT_VERSION
@export var night_index: int = 1
@export var elapsed_min: float = 0.0

## Chiave = Phase.key(), MAI Phase.name.
@export var phase_scores: Dictionary = {}

## Quanto si e' guadagnato STANOTTE. Non e' il portafoglio: quello vive in
## `PlayerProfile` e attraversa le notti (C1, chiuso il 2026-08-23). Questo numero
## nasce a zero a ogni notte, cresce a ogni vendita, e viene versato al giocatore
## quando la notte si chiude. Serve anche al riepilogo dell'alba, che deve poter dire
## quanto ha reso questa notte e non quanto c'e' in cassa.
@export var night_earnings: int = 0
@export var selected_target_id: StringName = &""
@export var photos: Array[Dictionary] = []

## La commessa della notte: un committente + il soggetto richiesto + il
## moltiplicatore, o `{}` se nessun committente abilitato. Determinata all'inizio
## della notte (vedi `photo/commission.gd`), è stato di NOTTE — salvabile per la 2.7,
## che gestirà la persistenza cross-notte. Le chiavi vivono in `Commission.*`.
@export var commission: Dictionary = {}


func migrate() -> void:
	if version == CURRENT_VERSION:
		return
	# Nessuna migrazione ancora: il ramo esiste dal primo giorno perché
	# aggiungerlo dopo significa avere già partite da riparare.
	Log.warn("save", "NightRun v%d → v%d, nessuna migrazione definita" % [version, CURRENT_VERSION])
	version = CURRENT_VERSION
