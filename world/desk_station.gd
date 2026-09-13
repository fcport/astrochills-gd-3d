## La postazione al monitor, senza la notte: ci si siede e ci si rialza.
##
## PERCHÉ ESISTE UN SECONDO POSTO CHE FA SEDERE, e va detto subito perché è il
## difetto tipico di questo progetto — un numero, o una sequenza, che sopravvive
## alla ragione che lo teneva su.
##
## `main.gd` fa già questa sequenza, e la fa da marzo. Ma la fa intrecciata con
## l'orchestratore della notte: si siede solo se `_night.has_phase()`, avverte la
## notte con `set_player_present()`, apre e chiude terminale e BBS. Nel blockout
## non c'è nessuna notte — c'è un edificio da percorrere a piedi — e importarci
## dentro l'orchestratore per potersi sedere sarebbe come accendere la centrale
## per provare una lampadina.
##
## QUESTO NODO È LA SOLA MECCANICA: togli il controllo, muovi il corpo, accendi
## il vetro, ridai il controllo. È il sottoinsieme di `main.gd` che non sa cosa
## sia una fase.
##
## **DEBITO DICHIARATO, E ADESSO SCADUTO.** Sono due copie della stessa sequenza, e
## due copie di una verità sola invecchiano male: la prima volta che qualcuno
## correggerà l'ordine dei passi in un file e non nell'altro, il difetto si vedrà
## solo in uno dei due mondi.
##
## IL TRASLOCO È AVVENUTO — 31 agosto 2026, `main.tscn` punta al blockout — e il
## debito NON è stato pagato. Va detto com'è invece di lasciarlo scritto al futuro:
## quando il gioco gira, questa scena è istanziata dentro `main.tscn`, la guardia
## qui sotto vede che `current_scene` non è lei, e questo file TACE per tutta la
## partita. La postazione la comanda `main.gd`. Quello che resta acceso qui serve
## alle sonde — `tools/prova_postazione.tscn`, `tools/prova_cupola.tscn` — che
## montano il blockout da solo, senza notte e senza orchestratore, per provare una
## cosa alla volta.
##
## QUINDI: la sequenza vera è quella di `main.gd`; questa è la sua gemella
## semplificata, viva solo sul banco. Il giorno in cui si vorrà una copia sola, la
## strada è portare i tre passi QUI e far chiamare questo file a `main.gd`, che
## resterebbe padrone di tutto ciò che la notte aggiunge — le fasi, il terminale,
## la BBS. Non è stato fatto insieme al trasloco per non mettere una riscrittura
## della postazione nello stesso commit che cambia il mondo sotto i piedi.
##
## L'ORDINE DEI PASSI È ADR-003, e non è decorativo:
##   1. `player.set_enabled(false)` — il controllo si toglie PRIMA di muovere
##      qualunque cosa;
##   2. `desk.toggle()` — il corpo si aggancia al `Marker3D` e la camera
##      interpola, mezzo secondo, con il FOV che si stringe a 33°;
##   3. su `seated` — e solo lì — lo schermo comincia a ricevere input.
## All'uscita l'inverso, e il controller torna acceso solo su `left`.
class_name DeskStation
extends Node3D

## Lo schermo e la postazione si risolvono in `_ready()` e restano.
var _crt: CrtScreen
var _desk: DeskCamera
var _monitor: CrtMonitor


## SI MONTA SOLO SE QUESTA SCENA STA GIRANDO DA SOLA, e la guardia non è
## difensiva: è il confine fra i due mondi, scritto in una riga.
##
## DAL 31 AGOSTO 2026 QUESTA GUARDIA LAVORA DAVVERO, tutte le partite: la scena è
## istanziata dentro `main.tscn`, che ha già il suo orchestratore della postazione.
## Due nodi che rispondono alla stessa `E` sullo stesso monitor farebbero partire
## due transizioni sovrapposte sullo stesso corpo: il giocatore finirebbe seduto
## due volte e in piedi una sola. Era una riga scritta in previsione; adesso è
## l'unica cosa che tiene separati i due mondi.
##
## `current_scene` è la scena che il motore sta eseguendo: quando è questo nodo, il
## blockout gira da solo e la postazione è sua. Quando non lo è, qualcun altro
## comanda, e questo file tace senza chiedere chi.
##
## SI GUARDA UN FRAME DOPO, e non è una precauzione: è che dentro `_ready()` la
## risposta non è ancora stabile. Quando il motore carica la scena principale
## `current_scene` è già assegnato all'ingresso in albero; ma chi monta la scena a
## mano — una sonda, un banco di prova — non può fare lo stesso, perché
## `set_current_scene()` da GDScript pretende che il nodo sia GIÀ figlio della
## radice. Letto in `_ready()`, lo stesso nodo risponderebbe in due modi diversi a
## seconda di chi l'ha caricato, e la sonda proverebbe una postazione che non si è
## montata dicendo che è rotta. Differito, la risposta è una sola.
func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	if get_tree().current_scene != self:
		return
	var monitor := CrtMonitor.find_in(get_tree())
	if monitor == null:
		# Canale 1: è un errore di programma. Senza monitor non c'è postazione, e
		# chi gioca girerebbe per la stanza senza capire perché la consolle è muta.
		push_error("[postazione] nessun CrtMonitor nel gruppo '%s'" % CrtMonitor.GROUP)
		return
	_crt = monitor.screen()
	if _crt == null:
		push_error("[postazione] il CrtMonitor non ha uno schermo")
		return

	var player := Player.find_in(get_tree())
	if player == null:
		push_error("[postazione] nessun Player nel gruppo '%s'" % Player.GROUP)
		return

	# `add_child()` NON È FACOLTATIVO: `create_tween()` lega il Tween allo
	# SceneTree del nodo, e da orfano restituisce un Tween che non riceve mai un
	# tick. La transizione partirebbe e non finirebbe mai — seduti per sempre,
	# senza controllo e senza input. `DeskCamera.toggle()` ha una guardia che lo
	# grida, ma la guardia è la rete: il posto giusto è questa riga.
	var desk := DeskCamera.new()
	desk.name = "DeskCamera"
	# L'ESITO SI GUARDA, e `_desk` resta nullo se la configurazione è fallita. Una
	# postazione montata a metà è peggio di una assente: da fuori sembrerebbe
	# pronta, e alla prima `E` il controllo verrebbe tolto al giocatore PRIMA che
	# `toggle()` rifiuti di partire — nessun tween, nessun segnale, e nessun modo
	# di rialzarsi.
	if not desk.configure(player, player.camera(), _crt.seat):
		desk.free()
		return
	desk.seated.connect(_on_seated)
	desk.left.connect(_on_left)
	add_child(desk)
	_desk = desk

	# CI SI COLLEGA SOLO A POSTAZIONE MONTATA: collegarsi prima trasformerebbe una
	# diagnosi detta una volta all'avvio in uno spam a ogni pressione di `E`.
	monitor.interacted.connect(_on_monitor_interacted)
	_monitor = monitor


## `E` sul monitor: ci si siede.
##
## Qui non si controlla se ci sia qualcosa da fare, perché in questo mondo non c'è
## un piano della notte da consultare: il monitor è acceso e ci si può sedere. È
## l'unica differenza di comportamento rispetto a `main.gd`, ed è dichiarata.
func _on_monitor_interacted(_by: Node3D) -> void:
	_sit_down()


## DURANTE LA TRANSIZIONE NON PASSA UN COMANDO.
##
## `_input()` e non `_unhandled_input()`: tutti gli `_input` dell'albero precedono
## qualunque `_unhandled_input`, ed è l'unico stadio in cui questo file arriva
## prima di ciò che vive dentro il CRT.
##
## SI INGOIANO SOLO LE AZIONI DELL'`InputMap`. I tasti degli strumenti di debug
## sono keycode grezzi e non azioni: restano raggiungibili anche a metà
## transizione, perché chi sviluppa non deve chiedersi perché lo strumento non ha
## risposto.
func _input(event: InputEvent) -> void:
	if _desk == null or not _desk.is_busy():
		return
	for action in InputMap.get_actions():
		if event.is_action(action):
			get_viewport().set_input_as_handled()
			return


## `E` per rialzarsi si legge QUI, e non in `_unhandled_input()`.
##
## La propagazione di `_unhandled_input` va dai nodi profondi verso la radice:
## basta che un `Control` dentro il CRT consumi l'evento perché questo file non lo
## veda più, e il gesto per alzarsi smetta di funzionare — il giocatore resterebbe
## seduto senza un tasto per uscirne. `_shortcut_input()` gira dopo `_input` e
## PRIMA di ogni `_unhandled_input`, e nessun Control lo implementa: qui si vince
## per costruzione, non per fortuna.
##
## Da seduti il controller del giocatore è spento, e con lui il suo lettore di
## `interact`: leggerlo qui non gli toglie niente.
func _shortcut_input(event: InputEvent) -> void:
	if _desk == null or not _desk.is_seated:
		return
	if event.is_action_pressed(&"interact"):
		_stand_up()
		get_viewport().set_input_as_handled()


## Ciò che nessuno ha gestito arriva allo schermo, e solo da seduti. Il cancello
## vero sta in `crt/crt_screen.gd`: qui si decide solo QUANDO bussare.
func _unhandled_input(event: InputEvent) -> void:
	if _desk == null or not _desk.is_seated:
		return
	if _crt != null:
		_crt.push(event)


## Porta il giocatore alla postazione. Passi 1 e 2; il 3 è su `_on_seated()`.
func _sit_down() -> void:
	if _desk == null or _desk.is_seated:
		return
	_set_player_active(false)
	# Lo schermo torna vivo ADESSO e non all'arrivo: aspettando `seated` la
	# transizione si guarderebbe un fermo immagine e l'interfaccia comparirebbe di
	# scatto. L'input invece aspetta davvero `seated`.
	_crt.set_live(true)
	_desk.toggle()


func _stand_up() -> void:
	if _desk == null or not _desk.is_seated:
		return
	_crt.set_input_enabled(false)
	_crt.set_live(false)
	_desk.toggle()


func _on_seated() -> void:
	# QUI, e non un frame prima: l'input passa al SubViewport solo a interpolazione
	# finita, mai prima.
	_crt.set_input_enabled(true)


func _on_left() -> void:
	# E il controller torna attivo solo a transizione conclusa, che è l'altra metà
	# della stessa clausola.
	_set_player_active(true)


## Dà o toglie il controllo al giocatore. Il mondo resta renderizzato in entrambi
## i casi: alla postazione il giocatore DEVE vedersi intorno la stanza.
##
## Le azioni si rilasciano tutte allo scambio, iterando l'`InputMap` invece di
## elencarle: elencarle qui significherebbe ricopiare in questo file i nomi che
## vivono altrove. Chi teneva il dito giù deve rialzarlo per ricominciare.
func _set_player_active(active: bool) -> void:
	var player := Player.find_in(get_tree())
	if player == null:
		push_error("[postazione] nessun Player nel gruppo '%s'" % Player.GROUP)
		return
	for action in InputMap.get_actions():
		Input.action_release(action)
	player.set_enabled(active)
