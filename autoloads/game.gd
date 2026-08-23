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
## non lo tocca mai. Lo carica `_ready()` dal save (2.7): un avvio nuovo trova un
## profilo pulito, un avvio dopo una notte conclusa ritrova le lire di prima.
var profile := PlayerProfile.new()

## Il persistore del save. Puro (RefCounted, no SceneTree): `Game` ne è l'unico
## chiamante in gioco. Carica all'avvio, versa+salva alla chiusura della notte.
var _saves := SaveManager.new()


## Carica il profilo dal disco PRIMA della prima notte. Un save assente è un avvio
## nuovo, silenzioso; un save illeggibile diventa un profilo pulito (la frase gentile
## resta su `_saves.last_load_message`, canale 2): all'avvio non c'è CRT montato dove
## mostrarla, e nessun AC chiede una schermata di boot — basta non crashare e proseguire.
func _ready() -> void:
	profile = _saves.load_profile()


## Comincia una notte nuova. L'indice NON è un argomento: si ricava dalle notti già
## portate a termine, così la rotazione dei committenti avanza da sola invece di
## dipendere da un numero scritto a mano nel punto d'ingresso.
func start_night() -> NightRun:
	run = NightRun.new()
	run.night_index = profile.nights_completed + 1
	Log.info("game", "notte %d avviata — %d lire in cassa" % [run.night_index, profile.wallet_lire])
	return run


## Quante lire ha il giocatore ADESSO, notte in corso compresa.
##
## NESSUNO DEI DUE NUMERI, PRESO DA SOLO, È QUELLO CHE HA IN TASCA.
## `profile.wallet_lire` è il saldo di IERI: il travaso avviene in `end_night()`,
## quindi finché la notte gira i guadagni stanno su `run.night_earnings` e il
## profilo non li ha ancora visti. Chi vuole mostrare «le lire» deve sommarli.
##
## STA QUI E NON NELLE SCHERMATE perché le schermate che lo mostrano sono già
## quattro — vendita, menu post-foto, riepilogo dell'alba, overlay di debug — e
## quattro copie della stessa somma sono quattro occasioni perché una diverga il
## giorno in cui il travaso cambia momento.
func wallet_now() -> int:
	var earned := run.night_earnings if run != null else 0
	return profile.wallet_lire + earned


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
	# Il lavoro della notte arriva alla successiva: si scrive la notte conclusa e il
	# profilo versato PRIMA di azzerare `run`. Se un save fallisce, `SaveManager`
	# ritorna `false` e registra su canale 1; la notte si chiude comunque.
	_saves.save_run(run)
	_saves.save_profile(profile)
	run = null
