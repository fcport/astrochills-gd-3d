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

## Chi tiene qualcosa in memoria lo scriva ADESSO: si sta per cambiare partita, o per
## copiare questa. Lo ascolta `MemoriaDelMondo`, che sta in `world/` e che `Game` non può
## nominare — da qui la si chiama soltanto.
signal salvataggio_richiesto

## La partita aperta, cioè la cartella dei salvataggi (D-243). Fuori dallo sviluppo è
## sempre quella vera; le altre le apre il pannello di F10.
var partita := SaveManager.PARTITA_VERA

## Com'era il mondo quando lo si è lasciato (D-243): dove stanno le cose e cosa c'è
## dentro. Lo carica `_ready()`, lo rilegge `MemoriaDelMondo` rimettendo le cose al loro
## posto, lo riscrive `ricorda_mondo()`.
var mondo := WorldState.new()

## Quale partita ha aperto per ultima il pannello di F10: così una partita di prova resta
## aperta anche rilanciando il gioco, finché non se ne sceglie un'altra. Solo in sviluppo.
const SCELTA_PATH := "user://saves/scelta.txt"


## Carica profilo e mondo dal disco PRIMA della prima notte. Un save assente è un avvio
## nuovo, silenzioso; un save illeggibile diventa un profilo pulito (la frase gentile
## resta su `_saves.last_load_message`, canale 2): all'avvio non c'è CRT montato dove
## mostrarla, e nessun AC chiede una schermata di boot — basta non crashare e proseguire.
func _ready() -> void:
	SaveManager.trasloca_vecchi()
	var sviluppo := OS.is_debug_build()
	var nome := partita_dell_avvio(OS.get_cmdline_args(), OS.get_environment("PARTITA"),
		_leggi_scelta() if sviluppo else "", sviluppo)
	if nome == SaveManager.PARTITA_SONDE:
		SaveManager.svuota_partita(nome)
	_apri(nome)


## Quale partita apre questo avvio. PURA e STATICA, per il banco.
##
## NELL'ORDINE: la variabile d'ambiente `PARTITA`, se c'è — è il modo di far girare una
## sonda su una partita precisa, anche quella vera; poi, se si sta lanciando una scena che
## non è `main.tscn`, cioè una sonda, la partita delle sonde; poi, in sviluppo, l'ultima
## scelta col pannello; e infine la vera.
static func partita_dell_avvio(args: PackedStringArray, env: String, scelta: String,
		sviluppo: bool) -> String:
	if SaveManager.nome_valido(env):
		return env
	for a in args:
		if a.ends_with(".tscn") and a.get_file() != "main.tscn":
			return SaveManager.PARTITA_SONDE
	if sviluppo and SaveManager.nome_valido(scelta):
		return scelta
	return SaveManager.PARTITA_VERA


func _apri(nome: String) -> void:
	partita = nome
	_saves.usa_partita(nome)
	profile = _saves.load_profile()
	mondo = _saves.load_world()
	if nome != SaveManager.PARTITA_VERA:
		Log.info("game", "partita «%s»: %d notti, %d lire" % [
			nome, profile.nights_completed, profile.wallet_lire])


## Apre un'altra partita e ricomincia la scena da capo (pannello di F10).
##
## PRIMA SI SCRIVE QUELLA DI ADESSO: dopo `_apri()` ogni salvataggio andrebbe nella
## cartella nuova. La notte in corso non si salva, ed è la regola di sempre — una notte
## interrotta non è successa.
func apri_partita(nome: String) -> void:
	if not SaveManager.nome_valido(nome):
		return
	salvataggio_richiesto.emit()
	_scrivi_scelta(nome)
	_apri(nome)
	run = null
	get_tree().paused = false
	get_tree().reload_current_scene.call_deferred()


## Crea una partita vuota, da zero, e ne restituisce il nome. Non la apre.
func nuova_partita() -> String:
	var nome := SaveManager.nome_libero(SaveManager.elenco_partite())
	return nome if SaveManager.crea_partita(nome) else ""


## Copia la partita `da` in una di prova e ne restituisce il nome, vuoto se non ci è
## riuscita. Non la apre. Se `da` è quella aperta, prima si scrive il mondo di adesso.
func copia_partita(da: String) -> String:
	if da == partita:
		salvataggio_richiesto.emit()
	var nome := SaveManager.nome_libero(SaveManager.elenco_partite())
	return nome if SaveManager.copia_partita(da, nome) else ""


## Riscrive com'è il mondo (D-243). Come `save_prints`: il mondo compone le voci, il
## disco lo tocca `Game`.
func ricorda_mondo(oggetti: Dictionary) -> void:
	mondo.oggetti = oggetti
	_saves.save_world(mondo)


func _leggi_scelta() -> String:
	if not FileAccess.file_exists(SCELTA_PATH):
		return ""
	var f := FileAccess.open(SCELTA_PATH, FileAccess.READ)
	return f.get_line().strip_edges() if f != null else ""


func _scrivi_scelta(nome: String) -> void:
	DirAccess.make_dir_recursive_absolute(SaveManager.SAVES_DIR)
	var f := FileAccess.open(SCELTA_PATH, FileAccess.WRITE)
	if f != null:
		f.store_line(nome)


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


## Se il giocatore può permettersi una spesa. `wallet_now()` è la sola somma —
## nessuna schermata la ricalcola — e la spesa la CONFRONTA, non la rifà.
func can_afford(amount: int) -> bool:
	return wallet_now() >= amount


## Come si divide una spesa fra la presa della notte e il portafoglio del giocatore.
## PURA e STATICA: nessuno stato, nessun autoload — così il banco può collaudarla senza
## uno SceneTree. Torna `[from_earnings, from_wallet]`.
##
## PERCHÉ EARNINGS-PRIMA-POI-WALLET. `wallet_now() = wallet_lire + night_earnings`, e
## il travaso della presa sul portafoglio avviene solo in `end_night()` (C1). Dedurre
## tutto da `wallet_lire` lo manderebbe negativo quando la presa di stanotte non è
## ancora versata. Si toglie prima da `night_earnings` (fino a 0), il resto da
## `wallet_lire`: entrambi restano ≥ 0, e `wallet_now()` cala esatto. Conseguenza
## voluta: `NIGHT TAKE` cala man mano che spendi — è la presa che ti resta.
##
## Il chiamante garantisce `amount <= wallet_now()` (via `can_afford`).
static func split_spend(amount: int, night_earnings: int) -> Array[int]:
	var from_earnings := mini(amount, night_earnings)
	var from_wallet := amount - from_earnings
	return [from_earnings, from_wallet]


## Scala `amount` lire e SALVA. Torna `true` se speso, `false` se il giocatore non
## se lo poteva permettere (nel qual caso non tocca niente).
##
## MARCARE IL POSSESSO È DEL CHIAMANTE: qui si muovono solo le lire. Il terminale
## chiama `spend_lire`, poi `profile.mark_owned(id)`, poi emette `Events.item_purchased`
## — questa funzione non sa cosa si stia comprando, come `wallet_now()` non lo sa.
##
## SI SALVANO ENTRAMBI, con lo stesso `_saves` di `end_night()`: la spesa attraversa
## un riavvio come il guadagno. Se un save fallisce, `SaveManager` lo registra su
## canale 1 e ritorna `false`; la spesa in memoria è già avvenuta e non si annulla —
## la stessa scelta di `end_night()`.
func spend_lire(amount: int) -> bool:
	if not can_afford(amount):
		return false
	var earned := run.night_earnings if run != null else 0
	var split := split_spend(amount, earned)
	if run != null:
		run.night_earnings -= split[0]
	profile.wallet_lire -= split[1]
	if run != null:
		_saves.save_run(run)
	_saves.save_profile(profile)
	return true


## Segna il messaggio `id` del forum come letto (3.7) e SALVA. Mutazione+salvataggio
## atomici in un punto solo, come `spend_lire`: la persistenza resta
## di `Game`, unico chiamante di `SaveManager` in gioco — la BBS non tocca mai
## `FileAccess`/`SaveManager`. Un save per messaggio aperto, come `spend_lire` salva per
## acquisto.
##
## IDEMPOTENTE: `mark_read` non duplica; se il messaggio e' gia' letto salva comunque,
## ed e' innocuo. Se il save fallisce, `SaveManager` lo registra su canale 1; il letto in
## memoria e' gia' avvenuto e non si annulla — la stessa scelta di `spend_lire`.
func mark_forum_read(id: StringName) -> void:
	profile.mark_read(id)
	_saves.save_profile(profile)


## Riscrive il registro delle stampe (D-239) e SALVA. Come `mark_forum_read`: la persistenza
## resta di `Game`, e la stampante nel mondo non tocca mai `SaveManager`.
##
## SI RISCRIVE INTERO, non si aggiunge una voce: a sapere dove sta ogni stampa adesso è la
## stampante, che le ha tutte sotto gli occhi, e una lista aggiornata a pezzi qui
## divergerebbe alla prima stampa spostata.
func save_prints(records: Array[Dictionary]) -> void:
	profile.photo_prints = records
	_saves.save_profile(profile)


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
