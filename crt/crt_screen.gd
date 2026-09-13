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

## Di quanti metri il vetro rientra agli angoli rispetto al centro.
##
## È una proprietà del TUBO, non dello schermo: la dichiara chi monta il monitor,
## perché è lui a sapere quale cinescopio ha davanti. Zero è un vetro piatto, ed è
## il default perché una scena che non lo dichiara non deve cambiare aspetto.
##
## Non si deriva come `image_scale` e `scanline_count`, e la differenza vale la
## pena di dirla: quelli discendono da cose che questo nodo ha in mano — la misura
## del quad, la misura del viewport. La bombatura no: sta nel modello del tubo, che
## vive in `assets/models/` e che questo file non apre. Per la sala di controllo la
## misura `tools/geometria.py`, e `arredi_blender.py` la ricontrolla a ogni passata.
@export var glass_bulge: float = 0.0

## Se il Control mostrato può ricevere eventi. Vedi `set_input_enabled()`.
var _input_enabled := false

## Se vale la pena ridisegnare lo schermo. Vedi `set_live()`.
var _live := false

## Il desktop di Windows 98 che sta SEMPRE sul vetro. Vedi `crt/desktop/desktop.gd`.
var _desktop: Desktop


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

	mat.set_shader_parameter("bulge", glass_bulge)

	# IL DESKTOP SI MONTA QUI, e il vetro non è più mai vuoto. Prende la misura del
	# viewport, che è 352x264 e non più 256x192: è la più piccola 4:3 in cui una finestra
	# con barra del titolo e schede contiene un pannello da 256x192 intero, e in cui
	# terminale e BBS stanno interi in finestra propria. Nessuna schermata del gioco è
	# stata toccata per starci — si incorniciano, non si ridisegnano.
	_desktop = Desktop.new()
	_desktop.setup(DesktopTheme.new(), Vector2(_viewport.size))
	_viewport.add_child(_desktop)

	Events.screen_registered.emit(self)


## Mostra un Control sullo schermo: nella finestra di lavoro del desktop.
##
## REGOLA: il CRT non libera MAI ciò che mostra. Dopo reparent() il Control non
## è più figlio della fase, ma la proprietà resta sua — è la fase a liberarlo
## quando viene distrutta (NOTIFICATION_PREDELETE, vedi core/phase.gd). Un
## queue_free() qui distruggerebbe l'interfaccia di una fase che sta ancora
## girando in background.
##
## NON SVUOTA PIÙ IL VETRO. Fino al desktop questa funzione staccava tutti i figli del
## viewport e ci metteva il nuovo arrivato: chiunque mostrasse qualcosa buttava via chi
## c'era prima, la notte sfrattava il terminale e il terminale la notte. Adesso il vetro
## ha sempre il desktop, e ciò che si mostra va nella finestra di lavoro — dove resta
## anche se quella finestra è chiusa, e dove le altre finestre non lo toccano. La firma
## è la stessa di prima di proposito: chi mostra, cioè l'orchestratore della notte, non
## ha dovuto cambiare una chiamata.
func show_control(c: Control) -> void:
	if _desktop == null:
		return
	_desktop.set_work_content(c)
	_nudge()


## UN FRAME ANCHE A SCHERMO FERMO. Da spento il render target è congelato
## sull'ultimo fotogramma (vedi `set_live()`), quindi ciò che cambia adesso non
## verrebbe disegnato da nessuno. Succede davvero all'alba — il riepilogo arriva mentre
## il giocatore è dall'altra parte della casa — e comparirebbe solo dopo essersi
## seduti. `UPDATE_ONCE` disegna un frame e si rispegne da sé.
func _nudge() -> void:
	if not _live and _viewport != null:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func viewport_size() -> Vector2i:
	return _viewport.size


## Il desktop, per chi deve metterci icone e aprirci finestre: il punto d'ingresso. Chi
## mostra soltanto — l'orchestratore della notte — continua a passare da `show_control()`.
func desktop() -> Desktop:
	return _desktop


## Le schede della finestra di lavoro. È un dato generico, etichette e un indice: il CRT
## non sa che siano fasi, come non sa cosa sia il Control che mostra.
func set_work_tabs(labels: PackedStringArray, current: int) -> void:
	if _desktop == null:
		return
	_desktop.set_work_tabs(labels, current)
	_nudge()


## Il puntatore sul vetro. Passa dal cancello di `set_input_enabled()` come la tastiera:
## una regola che vale solo se chi chiama se la ricorda non è una regola. Vedi `push()`
## per perché il mouse vero non entra nel viewport.
func pointer_move(delta: Vector2) -> void:
	if not _input_enabled or _desktop == null:
		return
	_desktop.pointer_move(delta)


## La pressione passa solo a cancello aperto; il RILASCIO passa sempre, perché chi si
## alza col tasto ancora giù non deve lasciare una finestra appesa al trascinamento.
func pointer_button(pressed: bool) -> void:
	if _desktop == null:
		return
	if pressed and not _input_enabled:
		return
	_desktop.pointer_button(pressed)


## Che cosa c'è sul vetro adesso, come immagine. SOLO PER LE SONDE.
##
## Serve a fare una domanda che a occhio si può sbagliare e a parole non si può
## porre: «il monitor è acceso o è nero?». Un CRT nero è il sintomo di mezza dozzina
## di guasti diversi ed è quello che un giocatore chiama «non va più il computer» —
## ma è anche indistinguibile, in un referto di testo, da un monitor che sta
## disegnando quello che deve. Contando i pixel accesi la domanda si chiude.
func image() -> Image:
	var t := _viewport.get_texture()
	return t.get_image() if t != null else null


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
## Il vetro non è mai vuoto, da quando c'è il desktop: lo sfondo teal copre tutto il
## viewport, e il `default_clear_color` di progetto non si vede più attraverso lo
## shader. Chi un giorno togliesse il desktop ritroverebbe il grigio-verde di un CRT
## acceso senza segnale — vedi `deferred-work.md`.
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
	# nessuna relazione con i pixel del vetro. Inoltrarle darebbe ai Control un
	# puntatore che si muove a caso — peggio di non averne uno, perché sembra
	# funzionare. Il puntatore esiste lo stesso, ma è VIRTUALE: `pointer_move()` gli
	# somma lo spostamento del mouse, e il desktop decide cosa c'è sotto la freccia.
	# È il routing dell'input che ADR-003 prevedeva di dover toccare, fatto senza il
	# raycast (D-232). La tastiera invece è completa: focus e `ui_accept` funzionano.
	if event is InputEventMouse:
		return
	_viewport.push_input(event)
