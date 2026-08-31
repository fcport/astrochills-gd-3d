## Uno schermo CRT diegetico: un Control renderizzato dentro il mondo 3D.
##
## Non sa MAI cosa sta mostrando. Riceve un Control — può essere una fase, il
## negozio, il terminale — ed è questo che rende indolore l'upgrade futuro al
## raycast sul mesh (ADR-003).
class_name CrtScreen
extends Node3D

@onready var _viewport: SubViewport = %Viewport
@onready var _mesh: MeshInstance3D = %ScreenMesh
@onready var seat: Marker3D = %Seat

## Se il Control mostrato può ricevere eventi. Vedi `set_input_enabled()`.
var _input_enabled := false

## Se vale la pena ridisegnare lo schermo. Vedi `set_live()`.
var _live := false


func _ready() -> void:
	# LO STATO INIZIALE SI DICHIARA. Un CRT nasce muto e fermo: chi non è alla
	# postazione non digita sullo schermo, e non c'è niente da ridisegnare.
	# Lasciarlo al default della scena significherebbe che aprire
	# `crt_screen.tscn`, cambiare una casella e salvare consegna una build in cui
	# si scrive sul monitor dall'altra parte della stanza.
	_viewport.gui_disable_input = not _input_enabled
	set_live(_live)

	var mat := _mesh.get_surface_override_material(0) as ShaderMaterial
	if mat == null:
		push_error("[crt] ScreenMesh senza ShaderMaterial")
		return
	mat.set_shader_parameter("screen_tex", _viewport.get_texture())

	# Le scanline si derivano dalla risoluzione, non si scelgono a mano.
	# Un numero di scanline pari all'altezza del viewport significa un ciclo di
	# seno per pixel: non sono righe, è rumore. Metà altezza è il massimo che il
	# campionamento regge.
	mat.set_shader_parameter("scanline_count", float(_viewport.size.y) * 0.5)

	# QUANTO DEL VETRO OCCUPA L'IMMAGINE, e si deriva anche questo: un tubo non ha
	# il rapporto che decidi tu. Quello della sala di controllo e' 30,9 x 27,4 cm
	# — quasi quadrato, perche' e' un modello preso da fuori e misurato, non
	# disegnato attorno al viewport — e l'immagine e' 4:3. Se il quad e' il vetro e
	# l'immagine e' 4:3, qualcosa deve stare fra le due.
	#
	# LE DUE VIE SCARTATE. Stirare l'immagine fino a riempire il vetro allunga ogni
	# carattere del 18%, ed e' testo che si deve leggere. Rimpicciolire il quad
	# fino al 4:3 lascia scoperta la mesh del modello dietro, che e' un secondo
	# rettangolo illuminato dalle luci della stanza: da seduti, con la camera
	# inclinata di 22 gradi, i due non possono coincidere — banda spessa sopra e
	# niente sotto, ed e' il difetto che ha fatto dire «quello dietro e quello
	# davanti non coincidono».
	#
	# Cosi' invece il quad E' il vetro, e la cornice la disegna lo shader: stesso
	# oggetto, stessi pixel, nera davvero perche' lo shader e' `unshaded`.
	#
	# SI CALCOLA E NON SI DICHIARA, per la stessa ragione delle scanline: chi
	# cambia il tubo o la risoluzione del viewport non deve ricordarsi di venire
	# qui. Con un tubo 4:3 e un viewport 4:3 viene (1, 1), cioe' il vecchio
	# comportamento esatto.
	var quad := _mesh.mesh as QuadMesh
	if quad != null and quad.size.y > 0.0 and _viewport.size.y > 0:
		var vetro := quad.size.x / quad.size.y
		var immagine := float(_viewport.size.x) / float(_viewport.size.y)
		var scala := Vector2.ONE
		if immagine > vetro:
			scala.y = vetro / immagine     # vetro piu' alto: bande sopra e sotto
		elif immagine < vetro:
			scala.x = immagine / vetro     # vetro piu' largo: bande ai lati
		mat.set_shader_parameter("image_scale", scala)

	Events.screen_registered.emit(self)


## Mostra un Control sullo schermo.
##
## REGOLA: il CRT non libera MAI ciò che mostra. Dopo reparent() il Control non
## è più figlio della fase, ma la proprietà resta sua — è la fase a liberarlo
## quando viene distrutta (NOTIFICATION_PREDELETE, vedi core/phase.gd). Un
## queue_free() qui distruggerebbe l'interfaccia di una fase che sta ancora
## girando in background.
func show_control(c: Control) -> void:
	for child in _viewport.get_children():
		_viewport.remove_child(child)
	if c == null:
		return
	if c.get_parent() != null:
		c.reparent(_viewport)
	else:
		_viewport.add_child(c)
	# `set_anchors_AND_OFFSETS_preset`, non `set_anchors_preset`. Il secondo lascia
	# `keep_offsets = true` e quindi PRESERVA il rect che il Control ha già: sposta
	# le ancore e ricalcola gli offset perché nulla si muova. Funzionava per
	# coincidenza, perché `polar_screen._ready()` si impone 256x192 a (0,0) e il
	# viewport è 256x192. Il primo Control che arrivasse con un rect diverso
	# resterebbe della sua misura dentro uno schermo di un'altra.
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# UN FRAME ANCHE A SCHERMO FERMO. Da spento il render target è congelato
	# sull'ultimo fotogramma (vedi `set_live()`), quindi ciò che arriva adesso
	# non verrebbe disegnato da nessuno: si vedrebbe ancora la cosa di prima.
	# Succede davvero all'alba — il riepilogo arriva mentre il giocatore è
	# dall'altra parte della casa, cioè esattamente quando lo schermo è fermo — e
	# comparirebbe solo dopo essersi seduti, perché `set_live(true)` è lì per
	# un'altra ragione. `UPDATE_ONCE` disegna un frame e si rispegne da sé: è la
	# stessa cosa che `set_live(false)` concede, e non riaccende niente.
	if not _live:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func viewport_size() -> Vector2i:
	return _viewport.size


## Apre o chiude il cancello dell'input dello schermo.
##
## CHI ORCHESTRA LO APRE SOLO A TRANSIZIONE FINITA (ADR-003): prima che il
## giocatore sia arrivato alla postazione lo schermo non è raggiungibile, e non
## deve comportarsi come se lo fosse.
##
## `gui_disable_input` è l'interruttore giusto perché è UNO SOLO e li blocca
## tutti — mouse e tastiera insieme. Vive qui, in casa del viewport, e non nel
## punto d'ingresso: così un secondo chiamante che un giorno inoltrasse eventi da
## un'altra parte trova il cancello chiuso invece di scavalcarlo senza saperlo.
func set_input_enabled(value: bool) -> void:
	_input_enabled = value
	if _viewport != null:
		_viewport.gui_disable_input = not value


func is_input_enabled() -> bool:
	return _input_enabled


## Se vale la pena ridisegnare lo schermo, cioè se quello che mostra sta
## cambiando. Chiude il rilievo M4.
##
## NFR15: «i `SubViewport` non usano `UPDATE_ALWAYS` per default: ogni schermo
## CRT è un render pass in più, ed è il costo reale del progetto». La scena
## nasceva con `UPDATE_ALWAYS` scritto a mano e senza un proprietario — tre
## storie lo hanno guardato senza toccarlo. Adesso il proprietario c'è: alla
## postazione questo schermo È la superficie di gioco e deve aggiornare sempre;
## dall'altra parte della casa mostra un'immagine ferma, e ridisegnarla sessanta
## volte al secondo è un render pass buttato.
##
## SPENTO È `UPDATE_ONCE`, NON `UPDATE_DISABLED`, e la differenza vale il doppio
## di quel che sembra: `ONCE` disegna ancora un frame e POI si ferma da sé — il
## motore lo riporta a `DISABLED` da solo. Così qualunque cosa sia appena
## cambiata finisce comunque a schermo prima del congelamento. Con `DISABLED`
## secco, uno `show_control(null)` seguito subito da `set_live(false)`
## lascerebbe a video l'interfaccia di una fase già liberata.
##
## Il render target CONSERVA l'ultimo frame: fermarlo non annerisce il monitor,
## lo congela. È QUESTO — e non `_draw` — a tenere a schermo lo stato vero
## mentre il giocatore è dall'altra parte della casa: con lo schermo fermo non
## si ridisegna niente, si guarda l'ultimo fotogramma. È ciò che l'AC5 della
## storia 1.3 chiede di vedere da lontano.
##
## Da vuoto il render target non è nero: un `SubViewport` con
## `transparent_bg = false` si pulisce con `default_clear_color`, che è
## un'impostazione GLOBALE di progetto e vale 0,3 grigio. Attraverso lo shader
## diventa il grigio-verde di un CRT acceso senza segnale — guardato e scelto il
## 2026-08-22 (col nero lo shader sparisce e il vetro sembra un buco nella
## scocca). Chi un giorno cambierà quel default per un'altra ragione cambierà
## anche questo: vedi `deferred-work.md`.
func set_live(value: bool) -> void:
	# Lo stato si ricorda PRIMA della guardia, come in `set_input_enabled()`: una
	# chiamata arrivata prima di `_ready()` non deve essere persa in silenzio, e
	# `_ready()` la applica. Le due funzioni sono gemelle e devono comportarsi
	# allo stesso modo — l'asimmetria è una correzione della code review.
	_live = value
	if _viewport == null:
		return
	_viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_ONCE)


func is_live() -> bool:
	return _live


## Consegna un evento al Control mostrato.
##
## SERVE, e non è una comodità: questo `SubViewport` non è figlio di un
## `SubViewportContainer` — è figlio di un `Node3D`, perché lo schermo è un
## oggetto del mondo — e un SubViewport nudo non riceve NIENTE da solo, né tasti
## né mouse. `push_input()` è l'unica porta.
##
## Oggi nessun `Control` del progetto gestisce input, quindi questa porta non ha
## ancora un destinatario: è costruita perché la clausola dell'AC1 resti
## verificabile e perché il primo `Button` diegetico trovi la strada fatta. Che
## il focus da tastiera funzioni davvero, dentro questo viewport, lo scoprirà chi
## quel `Button` lo scrive — qui non è stato misurato.
##
## Il cancello si ricontrolla qui e non solo nel chiamante: `set_input_enabled()`
## è la regola, e una regola che vale solo se chi chiama se la ricorda non è una
## regola.
##
## NON sa cosa mostra lo schermo, e non deve: riceve un evento e lo passa al
## Control, chiunque esso sia. È la stessa proprietà che rende `show_control()`
## indipendente dalle fasi.
func push(event: InputEvent) -> void:
	if not _input_enabled or _viewport == null:
		return
	# IL MOUSE NON PASSA, e non è una svista. Questo schermo è un quad nel mondo:
	# le coordinate di un evento del mouse sono quelle della finestra, e non hanno
	# nessuna relazione con i 256x192 del vetro. Inoltrarle darebbe a un Control
	# futuro un puntatore che si muove a caso — che è peggio di non averne uno,
	# perché sembra funzionare. A mappare il puntatore sarà il raycast sul mesh,
	# che ADR-003 rinvia dichiaratamente: «l'upgrade tocca solo il routing
	# dell'input, non il codice delle fasi», ed è questa riga il punto in cui
	# toccherà. La tastiera invece è completa: focus e `ui_accept` funzionano.
	if event is InputEventMouse:
		return
	_viewport.push_input(event)
