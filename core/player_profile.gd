## Ciò che è del GIOCATORE, e attraversa le notti. SOLO DATI, nessuna logica.
##
## È la sorella di `core/night_run.gd`, e la linea fra le due è l'intera ragione per
## cui questo file esiste. `NightRun` tiene ciò che appartiene a UNA notte — l'ora,
## i punteggi delle fasi, il bersaglio scelto, le foto scattate, la commessa — e muore
## con lei. Qui sta ciò che il giocatore si porta dietro: le lire guadagnate, quante
## notti ha lavorato, e domani ciò che ha comprato.
##
## PERCHÉ DUE TIPI E NON UNA FUNZIONE CHE COPIA. La storia 2.7 chiede che «portafoglio
## e flag di acquisto siano quelli di prima, e i punteggi delle fasi no: appartengono
## alla notte, non al giocatore». Quella distinzione esisteva nel pensiero e non nel
## codice: `Game.start_night()` faceva `NightRun.new()` e portava via tutto. Scriverla
## come un elenco di campi dentro una funzione di copia significa che ogni campo
## aggiunto da qui all'epica 3 va ricordato a mano, e dimenticarne uno non produce
## nessun errore — produce un portafoglio che si azzera ogni tanto, che è il guasto
## che si insegue per due giorni. Scritta come due tipi, la domanda «questo
## sopravvive?» se la pone chi aggiunge il campo, non chi legge sei mesi dopo.
##
## Chiude il rilievo C1 (2026-08-23), che bloccava la 2.7 e la 3.2.
##
## Salvato con ResourceSaver su user://saves/*.tres — leggibile e diffabile, come
## `NightRun`.
class_name PlayerProfile
extends Resource

## Incrementare a ogni cambio di formato, e gestirlo in `migrate()`.
const CURRENT_VERSION := 1

@export var version: int = CURRENT_VERSION

## Le lire che il giocatore ha davvero in tasca. Ci arrivano a fine notte dal
## `night_earnings` della `NightRun`, mai direttamente da una vendita: chi vende
## accredita sulla notte, e la notte versa al giocatore quando finisce.
@export var wallet_lire: int = 0

## Quante notti sono state portate a termine. È anche ciò da cui la notte successiva
## ricava il proprio `night_index`, e quindi la rotazione dei committenti.
@export var nights_completed: int = 0


func migrate() -> void:
	if version == CURRENT_VERSION:
		return
	# Nessuna migrazione ancora: il ramo esiste dal primo giorno perché aggiungerlo
	# dopo significa avere già partite da riparare.
	Log.warn("save", "PlayerProfile v%d → v%d, nessuna migrazione definita" % [version, CURRENT_VERSION])
	version = CURRENT_VERSION
