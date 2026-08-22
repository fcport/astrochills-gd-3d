## Portachiavi, non cervello.
##
## Possiede la NightRun corrente e ne gestisce il ciclo di vita. Nessuna logica
## di gioco: quella sta nelle fasi e nell'orchestratore della notte.
extends Node

var run: NightRun


func start_night(index: int) -> NightRun:
	run = NightRun.new()
	run.night_index = index
	Log.info("game", "notte %d avviata" % index)
	return run


func end_night() -> void:
	Log.info("game", "notte %d chiusa — %d lire" % [run.night_index, run.wallet_lire])
	run = null
