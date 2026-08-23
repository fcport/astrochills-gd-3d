## Portachiavi, non cervello.
##
## Possiede le DUE cose che compongono una partita e ne gestisce il ciclo di vita:
## la `NightRun` corrente — che nasce e muore con la notte — e il `PlayerProfile`,
## che attraversa le notti. Nessuna logica di gioco: quella sta nelle fasi e
## nell'orchestratore della notte.
##
## LA LINEA FRA I DUE È IL RILIEVO C1, chiuso il 2026-08-23. Prima esisteva solo la
## `NightRun`, e `start_night()` la ricostruiva da zero: il portafoglio moriva con la
## notte, e la 2.7 («il portafoglio è ancora lì la notte dopo») non aveva un posto
## dove mettere ciò che doveva sopravvivere. Adesso ce l'ha, ed è un tipo — non un
## elenco di campi dentro una funzione di copia che qualcuno deve ricordarsi di
## aggiornare.
extends Node

var run: NightRun

## Il giocatore. Esiste prima della prima notte e sopravvive a tutte: `start_night()`
## non lo tocca mai. La 2.7 lo caricherà dal save invece di costruirlo qui.
var profile := PlayerProfile.new()


## Comincia una notte nuova. L'indice NON è un argomento: si ricava dalle notti già
## portate a termine, così la rotazione dei committenti avanza da sola invece di
## dipendere da un numero scritto a mano nel punto d'ingresso.
func start_night() -> NightRun:
	run = NightRun.new()
	run.night_index = profile.nights_completed + 1
	Log.info("game", "notte %d avviata — %d lire in cassa" % [run.night_index, profile.wallet_lire])
	return run


## Chiude la notte e VERSA al giocatore quanto ha guadagnato.
##
## È l'unico punto in cui `profile.wallet_lire` cresce: chi vende accredita su
## `run.night_earnings`, e il travaso avviene qui. Una notte interrotta prima di
## questa chiamata non lascia mezzo guadagno in tasca — o la notte si chiude, o non
## è successo.
func end_night() -> void:
	if run == null:
		return
	profile.wallet_lire += run.night_earnings
	profile.nights_completed += 1
	Log.info("game", "notte %d chiusa — %d lire guadagnate, %d in cassa" % [
		run.night_index, run.night_earnings, profile.wallet_lire])
	run = null
