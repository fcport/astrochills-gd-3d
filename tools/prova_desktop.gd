## IL DESKTOP DI WINDOWS, GIOCABILE. Si cammina, ci si siede, si clicca.
##
## PROVVISORIO, E SOLO PER PROVARE. Il gioco NON è modificato: questa sonda carica
## `main.tscn` e gli mette il desktop sul vetro dall'esterno. Chiuderla non lascia
## niente dietro, e avviare il gioco normalmente lo trova identico a prima.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_desktop.tscn
##
## I TASTI. Da F1 a F12 sono già tutti presi fra `debug/` e le fasi, quindi:
##     E    ci si siede al computer, e ci si alza.
##     ALT  TENUTO PREMUTO: si torna a guardarsi attorno.
##     Il mouse muove la freccia; il click sinistro apre le icone, chiude le finestre
##     con la X, porta avanti quella che tocchi, e ARRIVA DENTRO — le schede di
##     «Internet» e le righe degli elenchi rispondono. Le finestre si TRASCINANO per
##     la barra del titolo; i tre pulsanti in alto a destra riducono a icona, portano
##     a tutto schermo e chiudono; la taskbar e il menu Start funzionano.
##
## SI PARTE DAL DESKTOP VUOTO: sfondo, tre icone, taskbar. Le cose le apre chi lo usa,
## quando gli servono.
##
## IL COMPUTER È ACCESO E RESTA ACCESO. Windows sta sul vetro dall'inizio, e si vede
## anche da in piedi dall'altra parte della stanza — perché è quello che fa un PC
## acceso. Sedersi non accende niente: avvicina la camera, ferma la visuale e passa il
## mouse al puntatore. Due versioni fa il desktop stava dietro un tasto, e una versione
## fa compariva sedendosi: nel primo caso ci si sedeva e il mouse girava ancora la
## testa, nel secondo il monitor mostrava una cosa da vicino e un'altra da lontano.
##
## IL MOUSE È DEL COMPUTER, NON DELLA TESTA. Da seduti il mouse muove il puntatore sul
## vetro e la visuale sta ferma; girare la testa passa sotto ALT, tenuto premuto. In
## piedi non cambia niente: il mouse guarda come sempre.
extends Node

const TEMA := preload("res://tools/tema98.gd")
const DESKTOP := preload("res://tools/finestra98.gd")
const CORNICE := preload("res://tools/cornice98.gd")
const ELENCO := preload("res://tools/elenco98.gd")
const INTERNET := preload("res://tools/internet98.gd")
const MAXIM := preload("res://tools/maxim98.gd")
const AVVISO := preload("res://tools/avviso98.gd")
const CURSORE := preload("res://tools/cursore98.gd")

const VETRO_DESKTOP := Vector2i(320, 240)
const VETRO_NOTTE := Vector2i(256, 192)

## Quanto il puntatore corre rispetto al mouse. Più basso di
## `DeskCamera.MOUSE_SENSITIVITY` perché lì si gira una testa e qui si attraversa uno
## schermo largo 320 px: con la stessa cifra il cursore sbatterebbe da un bordo
## all'altro con un colpo di polso.
const PASSO_CURSORE := 0.55

## Le finestre si aprono a cascata, come in Windows: ognuna un po' più in là della
## precedente, così la seconda non nasce esattamente sotto la prima.
const CASCATA := Vector2(14, 12)
const PRIMA := Vector2(52, 10)

var _scena: Node
var _crt: Node
var _mesh: MeshInstance3D
var _desktop: Control
var _cursore: Control
var _hud: Label
var _tema: RefCounted
var _acceso := false
var _quante := 0
## La finestra che si sta trascinando, e da che punto della sua barra la si è presa.
## L'offset si tiene perché senza, al primo movimento la finestra salterebbe con
## l'angolo sotto il cursore invece di seguirlo dal punto dove l'hai afferrata.
var _trascina: Control
var _presa := Vector2.ZERO


func _ready() -> void:
	_monta.call_deferred()


## Con `--scatta` la sonda si siede da sé, apre MaxIm a tutto schermo, fotografa a
## piu' FOV e se ne va. Serve per una domanda sola e misurabile: a che apertura il
## vetro ci sta TUTTO nell'inquadratura. Con le finestre piccole non se ne accorgeva
## nessuno; massimizzata, i pixel che escono in alto sono la barra del titolo.
func _prova_fov() -> void:
	await get_tree().create_timer(0.6).timeout
	_scena._sit_down()
	await get_tree().create_timer(1.4).timeout

	# TUTTI E OTTO I MODULI, uno dopo l altro. E la prova che serve davvero: aprirne
	# uno solo non dice niente sugli altri sette, e il crash di `phase_goto` — che
	# asserisce se non ha ricevuto la notte — si e visto proprio cliccando una scheda
	# che nessuno aveva mai provato. Se un modulo muore, muore qui e non in partita.
	_apri("maxim")
	var f: Control = _desktop.finestre()[0]
	var mx: Control = _contenuto(f)
	for i in mx.MODULI.size():
		mx.clic(mx.rect_modulo(i).get_center())
		for _k in 3:
			await get_tree().process_frame
		var vivo: bool = mx._aperti.has(i) and mx._aperti[i]["schermo"] != null
		print("[prova] modulo %s: %s" % [mx.MODULI[i][0], "ok" if vivo else "SENZA PANNELLO"])

	# E lo stato non si perde tornando indietro: si cambia scheda e si torna, e il
	# pannello deve essere lo STESSO oggetto di prima, non uno nuovo.
	var primo = mx._aperti[0]["schermo"]
	mx.clic(mx.rect_modulo(3).get_center())
	mx.clic(mx.rect_modulo(0).get_center())
	print("[prova] stato conservato: %s" % ("si" if mx._aperti[0]["schermo"] == primo else "NO"))

	# --- INTERNET, i tre verbi, cliccati come li cliccherebbe una mano: sul vetro,
	# alle coordinate della finestra, passando per lo stesso `_clic` del giocatore.
	_apri("internet")
	var fi: Control = _desktop.finestre()[_desktop.finestre().size() - 1]
	var net: Control = _contenuto(fi)
	var dentro := func(punto: Vector2) -> void:
		_clic(fi.position + net.position + punto)

	var prima: int = net.lire
	net.sezione = 0
	net.cursori[0] = 2          # Space heater, senza stato: ordinabile
	dentro.call(net.rect_azione().get_center())
	print("[prova] Order: lire %d -> %d" % [prima, net.lire])

	dentro.call(net.rect_tab(1).get_center())
	net.cursori[1] = 3
	dentro.call(net.rect_azione().get_center())
	var letto: int = net.leggendo
	dentro.call(net.rect_azione().get_center())
	print("[prova] Read/Back: %d -> %d" % [letto, net.leggendo])

	dentro.call(net.rect_tab(2).get_center())
	var quante: int = net.vendita.size()
	var soldi: int = net.lire
	dentro.call(net.rect_azione().get_center())
	print("[prova] Sell: file %d -> %d, lire %d -> %d" % [quante, net.vendita.size(), soldi, net.lire])

	dentro.call(net.rect_tab(0).get_center())
	print("[prova] cursore market ricordato: %s" % ("si" if net.cursori[0] == 2 else "NO"))

	_minimizza(fi)
	var quali: Array = _desktop.finestre()
	_clic(_desktop.rect_taskbar(quali.find(fi), quali.size()).get_center())
	print("[prova] minimizza e ripresa: visibile=%s attiva=%s" % [fi.visible, fi.attiva])

	_clic(_desktop.rect_start().get_center())
	var voci: Array = _desktop.voci_start()
	var m: Rect2 = _desktop.rect_menu()
	_clic(Vector2(m.position.x + 40, m.position.y + 3 + (voci.size() - 1) * 16 + 8))
	var modale := false
	for f2 in _desktop.finestre():
		if f2.id == "_spegni":
			modale = true
			_chiudi(f2)
	print("[prova] menu Start e modale: %s" % modale)

	# Lo scatto finale: il forum aperto, che e il testo piu difficile da leggere.
	net.sezione = 1
	net.cursori[1] = 4
	net._aggiorna_stato()
	net.queue_redraw()
	_apri("photos")
	for _k in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var im := get_viewport().get_texture().get_image()
	if im != null:
		im.save_png("user://tutto.png")
	print("[prova] finestre aperte: %d" % _desktop.finestre().size())
	get_tree().quit()


func _monta() -> void:
	_scena = load("res://main.tscn").instantiate()
	get_tree().root.add_child(_scena)
	get_tree().current_scene = _scena
	await get_tree().create_timer(2.0).timeout
	_crt = _scena._crt
	if _crt == null:
		push_error("[prova_desktop] il monitor non è agganciato")
		return
	# L OROLOGIO SI FERMA, e non e' una comodita': e' l unico modo perche' questa
	# sonda non consumi il gioco vero. Carica `main.tscn` con gli autoload veri, quindi
	# la notte parte, il tempo scorre e dopo un quarto d ora reale arriva l alba: la
	# notte si chiude, il save si scrive e il contatore avanza. Provando l interfaccia
	# per mezz ora si bruciavano tre notti della partita.
	#
	# FERMANDOLO l alba non arriva piu' e il numero della notte resta dov era. In
	# cambio l ora nella tray non gira: segna l ora di arrivo e resta li'. E' la
	# rinuncia giusta per una prova che guarda le finestre, non il tempo — e l ora
	# VERA sul vetro l ha gia' dimostrata, e' quella che si vedeva scorrere prima.
	if _scena._night != null and _scena._night.has_method("clock"):
		var orologio = _scena._night.clock()
		if orologio != null and orologio.has_method("stop"):
			orologio.stop()

	# E L ORCHESTRATORE SI FERMA DEL TUTTO, che e' la stessa ragione portata fino in
	# fondo. Fermare l orologio toglie l alba ma non toglie la GARA PER IL VETRO:
	# `night/` continua a chiamare `show_control()` per conto suo a ogni cambio di
	# fase, e `CrtScreen.show_control()` svuota il viewport prima di consegnare —
	# quindi butta via il desktop e ci mette la sua schermata a tutto schermo. Il
	# rimedio di prima lo rimetteva ogni fotogramma, e il risultato era mezzo desktop
	# e mezza fase, con il vincitore deciso da chi parlava per ultimo.
	#
	# Spegnendo il nodo la notte smette di parlare al monitor e il vetro ha un padrone
	# solo. Le fasi restano perfettamente vive DENTRO MaxIm DL, perche' quelle le
	# istanzia `tools/maxim98.gd` per conto suo e non passano da qui.
	#
	# NEL GIOCO VERO NON SI FA COSI', e va detto: li' la notte serve. La gara si toglie
	# cambiando chi comanda il vetro — il desktop — e facendo si' che `night/` gli
	# CHIEDA di aprire un pannello invece di scavalcarlo con `show_control`.
	if _scena._night != null:
		_scena._night.process_mode = Node.PROCESS_MODE_DISABLED

	_mesh = _crt.find_child("ScreenMesh", true, false) as MeshInstance3D
	# L'aberrazione abbassata: a 0,0018 le cifre si spaccano e «L. 2.000» legge
	# «2.DDD». Si tocca il materiale, non `crt.gdshader`.
	_parametro("aberration", 0.0008)
	_monta_hud()
	# IL COMPUTER È ACCESO, E LO È SEMPRE. Windows sta sul vetro da quando la sonda
	# parte: non compare sedendosi e non sparisce alzandosi. La versione prima lo
	# accendeva su `seated` e lo spegneva su `left`, e il risultato era un monitor che
	# da lontano mostrava un'altra cosa — come se il PC cambiasse sistema operativo a
	# seconda di dove sei in piedi nella stanza. Sedersi cambia la CAMERA e chi comanda
	# il MOUSE, non cosa c'è sullo schermo.
	_accendi(true)
	if "--scatta" in OS.get_cmdline_user_args():
		_prova_fov.call_deferred()
		return
	print("[prova_desktop] E per sederti al computer, ALT per guardarti attorno")


func _monta_hud() -> void:
	var strato := CanvasLayer.new()
	add_child(strato)
	_hud = Label.new()
	_hud.text = "Tieni premuto ALT per muovere la visuale liberamente"
	_hud.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_hud.add_theme_constant_override("shadow_offset_y", 1)
	_hud.position = Vector2(20, 684)
	_hud.visible = false
	strato.add_child(_hud)


## IL MOUSE, PRIMA CHE LO VEDA LA POSTAZIONE.
##
## `DeskCamera` gira la testa leggendo il movimento del mouse dal suo
## `_unhandled_input`. Tutti gli `_input` dell'albero precedono qualunque
## `_unhandled_input`, quindi questo è l'unico stadio da cui si arriva prima di lei:
## consumando l'evento qui, la testa non si muove e il puntatore sì, senza toccare una
## riga di quel file.
##
## CON ALT PREMUTO NON SI CONSUMA NIENTE e l'evento prosegue: la postazione fa il suo
## mestiere di sempre. È free view proprio perché è il comportamento originale
## lasciato passare, non un secondo sistema che lo imita.
func _input(event: InputEvent) -> void:
	if not _alla_postazione():
		return
	if Input.is_key_pressed(KEY_ALT):
		return
	# DURANTE LA TRANSIZIONE LA TESTA STA FERMA LO STESSO. Mezzo secondo di scivolata
	# verso il monitor è poco, ma è esattamente il momento in cui la mano è già sul
	# mouse: senza questo, ci si siede e la visuale parte per conto suo prima ancora
	# che il desktop compaia. Qui non c'è ancora un cursore da muovere — si consuma
	# l'evento e basta, che è tutto quello che serve.
	if not _al_computer():
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		_cursore.muovi(event.relative * PASSO_CURSORE, Vector2(VETRO_DESKTOP))
		if is_instance_valid(_trascina):
			_sposta(_trascina, _cursore.punto - _presa)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_clic(_cursore.punto)
		else:
			_trascina = null
		get_viewport().set_input_as_handled()


## Seduti, o mentre ci si sta sedendo: da qui in poi il mouse non è più della testa.
func _alla_postazione() -> bool:
	if _scena == null or _scena._desk == null:
		return false
	return _scena._desk.is_seated or _scena._desk.is_busy()


## Seduti davvero, col desktop acceso e un cursore da muovere.
func _al_computer() -> bool:
	return _acceso and _cursore != null and _scena != null \
			and _scena._desk != null and _scena._desk.is_seated


## Un click sul vetro. L'ordine conta e non è arbitrario: si guardano PRIMA le
## finestre, dall'alto verso il basso della pila, e solo dopo il desktop — perché
## un'icona coperta da una finestra non è cliccabile, e il contrario farebbe aprire
## programmi cliccando sopra le finestre che ci stanno davanti.
func _clic(p: Vector2) -> void:
	# IL MENU START PER PRIMO: quando è aperto copre tutto, e un click che gli cade
	# sopra è suo anche se sotto ci fosse una finestra.
	if _desktop.start_aperto:
		var voce: String = _desktop.voce_start_a(p)
		_desktop.start_aperto = false
		_desktop.queue_redraw()
		if voce == "_chiudi_menu":
			_spegni()
		elif voce != "":
			_apri(voce)
		return
	if _desktop.rect_start().has_point(p):
		_desktop.start_aperto = true
		_desktop.queue_redraw()
		return

	# POI LA TASKBAR, che sta sopra le finestre: ci si clicca per riprendere quelle
	# ridotte a icona, e per mandarci quelle che danno fastidio.
	var lista: Array = _desktop.finestre()
	for i in lista.size():
		if not _desktop.rect_taskbar(i, lista.size()).has_point(p):
			continue
		var f: Control = lista[i]
		if f.minimizzata:
			f.minimizzata = false
			f.visible = true
			_avanti(f)
		elif f.attiva:
			# Cliccare il pulsante della finestra che hai davanti la manda giù: è il
			# comportamento di Windows, ed è anche l'unico modo di minimizzare senza
			# arrivare al pulsantino in alto a destra.
			_minimizza(f)
		else:
			_avanti(f)
		_desktop.queue_redraw()
		return

	# POI LE FINESTRE, dall'alto verso il basso della pila. Quelle ridotte a icona non
	# ci sono: un click non può cadere su una cosa che non si vede.
	for i in range(lista.size() - 1, -1, -1):
		var f: Control = lista[i]
		if f.minimizzata:
			continue
		var locale := p - f.position
		if not Rect2(Vector2.ZERO, f.size).has_point(locale):
			continue
		if f.rect_chiudi().has_point(locale):
			_chiudi(f)
			return
		if f.rect_massimizza().has_point(locale):
			_avanti(f)
			_massimizza(f)
			return
		if f.rect_minimizza().has_point(locale):
			_minimizza(f)
			return
		_avanti(f)
		# Una finestra a tutto schermo non si trascina: non c'è dove portarla, e in
		# Windows la barra di una finestra massimizzata infatti non risponde.
		if f.rect_titolo().has_point(locale) and not f.massimizzata:
			# PRESA PER LA BARRA. Non si trascina dai bordi né dal contenuto: è anche
			# l'unico posto dove un trascinamento non si confonde con un click su
			# qualcosa che sta dentro la finestra.
			_trascina = f
			_presa = locale
			return
		# IL CLICK PROSEGUE DENTRO, ed è ciò che separa una finestra usabile da una
		# guardabile. Il contenuto lo riceve in coordinate SUE — tolta la posizione
		# della finestra e l'area di chrome — e risponde se sa rispondere.
		var dentro: Control = _contenuto(f)
		if dentro != null and dentro.has_method("clic"):
			if dentro.clic(locale - dentro.position):
				# Un modale sparisce quando gli si risponde; una finestra normale no.
				if f.id == "_spegni":
					_chiudi(f)
				else:
					dentro.queue_redraw()
		return

	# E per ultimo il desktop.
	var id: String = _desktop.icona_a(p)
	if id != "":
		_apri(id)


## «Shut Down...» apre il modale di conferma, che e l unico posto dove un modale ci
## sta davvero: e una domanda, e una domanda blocca finche non le rispondi. Gli ESITI
## invece restano sul vetro nella barra di stato — quella e la regola del progetto
## (UX-DR10: niente modali per dire com e andata).
func _spegni() -> void:
	for f in _desktop.finestre():
		if f.id == "_spegni":
			_avanti(f)
			return
	var c := _cornice("Shut Down Windows", Vector2(184, 92), "_spegni")
	c.bottoni = false
	c.position = Vector2(64, 60)
	_desktop.add_child(c)
	var a := AVVISO.new() as Control
	a.righe = ["Are you sure you want to shut down", "the computer?"]
	a.configura(_tema, c.area_client().size)
	c.ospita(a)
	_avanti(c)


## Riduce a icona: sparisce dal vetro ma resta in taskbar, e il fuoco passa a chi c'è
## sotto — altrimenti i tasti andrebbero a una finestra che non si vede.
func _minimizza(f: Control) -> void:
	f.minimizzata = true
	f.visible = false
	f.attiva = false
	if _trascina == f:
		_trascina = null
	var restanti: Array = []
	for altra in _desktop.finestre():
		if not altra.minimizzata:
			restanti.append(altra)
	if not restanti.is_empty():
		_avanti(restanti[restanti.size() - 1])
	_desktop.queue_redraw()


## A tutto schermo e ritorno.
##
## IL CONTENUTO VA RIDIMENSIONATO CON LEI, e non lo fa da sé: i Control dentro le
## finestre hanno una misura decisa quando sono stati costruiti. Chi sa adattarsi
## espone `configura(tema, dimensione)` e glielo si richiede; chi non ce l'ha — le
## schermate delle fasi, che si impongono 256x192 in `_ready()` — resta della sua
## misura. Per quelle il tutto schermo è comunque un guadagno: la finestra grande le
## contiene quasi intere, mentre in una piccola erano tagliate a metà.
func _massimizza(f: Control) -> void:
	var utile := Rect2(Vector2.ZERO,
			Vector2(float(VETRO_DESKTOP.x), float(VETRO_DESKTOP.y) - _desktop.TASKBAR_H))
	f.massimizza(utile)
	var dentro: Control = _contenuto(f)
	if dentro != null and dentro.has_method("configura"):
		dentro.configura(_tema, f.area_client().size)
	if dentro != null:
		dentro.position = f.area_client().position
		dentro.queue_redraw()


## Sposta una finestra tenendola raggiungibile.
##
## IL CLAMP NON È COSMETICO. Senza, una finestra si porta fuori dal vetro e non torna
## più: la barra del titolo — l'unica presa che ha — finisce oltre il bordo, e da lì
## non la riafferra nessuno. Si tiene dentro la barra, non tutta la finestra: sporgere
## col corpo è normale e utile, perdere la maniglia no. In basso il limite è il bordo
## alto della taskbar, che in Windows sta sopra le finestre e non sotto.
func _sposta(f: Control, dove: Vector2) -> void:
	var largo := float(VETRO_DESKTOP.x)
	var alto: float = float(VETRO_DESKTOP.y) - _desktop.TASKBAR_H
	var min_x := -(f.size.x - 40.0)
	f.position = Vector2(
			clampf(dove.x, min_x, largo - 40.0),
			clampf(dove.y, 0.0, alto - f.rect_titolo().size.y))


## Il Control ospitato da una cornice: è il primo figlio Control che non sia il
## cursore. La cornice non lo tiene in una variabile di proposito — ospita e dimentica.
func _contenuto(f: Control) -> Control:
	for c in f.get_children():
		if c is Control:
			return c
	return null


## Porta una finestra davanti e le dà il fuoco. Il z-order in Godot è l'ordine dei
## figli: l'ultimo si disegna sopra. Il cursore resta l'ultimo di tutti, sempre.
func _avanti(f: Control) -> void:
	if f.minimizzata:
		f.minimizzata = false
		f.visible = true
	for altra in _desktop.finestre():
		altra.attiva = false
		altra.queue_redraw()
	f.attiva = true
	_desktop.move_child(f, -1)
	_desktop.move_child(_cursore, -1)
	f.queue_redraw()
	_desktop.queue_redraw()


func _chiudi(f: Control) -> void:
	if _trascina == f:
		_trascina = null
	f.queue_free()
	# `queue_free` libera al fotogramma dopo, ma la taskbar si ridisegna adesso: senza
	# toglierlo subito dall'albero il pulsante resterebbe lì un frame di troppo.
	_desktop.remove_child(f)
	var restanti: Array = _desktop.finestre()
	if not restanti.is_empty():
		_avanti(restanti[restanti.size() - 1])
	_desktop.queue_redraw()


## Apre il programma di un'icona. Se è già aperto lo porta davanti invece di aprirne
## un secondo: due «MaxIm DL» sullo stesso desktop non vogliono dire niente.
func _apri(id: String) -> void:
	for f in _desktop.finestre():
		if f.id == id:
			_avanti(f)
			return
	var c := _costruisci(id)
	if c == null:
		return
	c.position = PRIMA + CASCATA * float(_quante % 5)
	_quante += 1
	_desktop.add_child(c)
	_avanti(c)


## COSA C'È DENTRO OGNI ICONA. Il desktop non lo sa e non deve saperlo: lui annuncia
## un id, qui si decide cosa istanziare. Le fasi entrano COL LORO FOSFORO, e non è una
## dimenticanza — è la regola di `tema98`: i programmi che parlano con le macchine
## restano monocromatici, Windows gli sta solo attorno.
func _costruisci(id: String) -> Control:
	match id:
		"maxim":
			# TUTTO QUELLO CHE RIGUARDA LA FOTOGRAFIA sta qui dentro: le otto fasi che
			# hanno uno schermo, dietro la loro barra. La nona — la cupola — non ce
			# l'ha per decisione dichiarata, e infatti non compare.
			var cm := _cornice("MaxIm DL", Vector2(268, 176), id)
			var mx := MAXIM.new() as Control
			mx.configura(_tema, cm.area_client().size)
			cm.ospita(mx)
			return cm
		"internet":
			var ci := _cornice("Internet", Vector2(244, 168), id)
			var net := INTERNET.new() as Control
			net.configura(_tema, ci.area_client().size)
			ci.ospita(net)
			return ci
		"photos":
			return _elenco("Photos", id, [
				["m42_001.fit", "1.2M", "21:14"],
				["m42_002.fit", "1.2M", "21:38"],
				["m42_003.fit", "1.2M", "22:02"],
				["ngc891_004.fit", "1.2M", "23:05"],
				["dark_120s.fit", "1.2M", "20:51"],
				["flat_r.fit", "1.2M", "20:44"],
			], "6 object(s)")
	return null


func _cornice(titolo: String, dim: Vector2, id: String) -> Control:
	var c := CORNICE.new() as Control
	c.configura(_tema, titolo, dim, id)
	return c


func _elenco(titolo: String, id: String, righe: Array, stato: String) -> Control:
	var c := _cornice(titolo, Vector2(214, 132), id)
	var e := ELENCO.new() as Control
	e.configura(_tema, c.area_client().size)
	e.righe = righe
	e.stato = stato
	c.ospita(e)
	return c


func _accendi(si: bool) -> void:
	if _crt == null or si == _acceso:
		return
	_acceso = si
	if si:
		_crt._viewport.size = VETRO_DESKTOP
		_parametro("scanline_count", float(VETRO_DESKTOP.y) * 0.5)
		_crt.show_control(_costruisci_desktop())
		_crt.set_live(true)
	else:
		_libera()
		_crt._viewport.size = VETRO_NOTTE
		_parametro("scanline_count", float(VETRO_NOTTE.y) * 0.5)
		# Si toglie il desktop e basta. `night/` non ha un modo pubblico per farsi
		# ridisegnare, quindi il vetro resta vuoto finché non è la notte stessa a
		# mostrare qualcosa. In una sonda va bene; nel gioco vero il ripristino
		# sarebbe compito del punto d'ingresso, che è già quello che fa `main.gd`
		# chiudendo il terminale.
		_crt.show_control(null)
	print("[prova_desktop] desktop %s" % ("acceso" if si else "spento"))


## Il desktop NUDO: sfondo, icone, taskbar. Nessuna finestra.
func _costruisci_desktop() -> Control:
	_tema = TEMA.new()
	_desktop = DESKTOP.new() as Control
	_desktop.configura(_tema, Vector2(VETRO_DESKTOP))
	_desktop.ora = _ora()
	_quante = 0
	_cursore = CURSORE.new() as Control
	_cursore.configura(Vector2(VETRO_DESKTOP))
	_desktop.add_child(_cursore)
	return _desktop


func _libera() -> void:
	if is_instance_valid(_desktop):
		_desktop.queue_free()
	_desktop = null
	_cursore = null
	_trascina = null


## RIMETTE IL DESKTOP SE QUALCUNO GLIELO HA TOLTO.
##
## `CrtScreen.show_control()` SVUOTA il viewport prima di consegnare: chiunque mostri
## qualcosa butta via chi c era prima. E l orchestratore della notte lo chiama per
## conto suo — a ogni cambio di fase, alla vendita, all alba — quindi il desktop
## spariva e al suo posto compariva una schermata da 256x192 dentro un vetro da
## 320x240, con il fondo del viewport a fare da cornice. E' il difetto che si vedeva
## guardando il monitor da lontano.
##
## QUI SI RIPRENDE IL VETRO OGNI FOTOGRAMMA, che e un rimedio da sonda e si dichiara
## come tale: e una gara fra due padroni dello schermo, e la vince chi parla per
## ultimo. Nel gioco vero la gara non va vinta, va TOLTA — se il PC ha Windows, le
## fasi non possono prendersi il vetro: devono aprirsi in una finestra come fa MaxIm
## DL qui dentro, e `night/` deve chiedere al desktop invece che al monitor.
func _riprendi_il_vetro() -> void:
	if not _acceso or not is_instance_valid(_desktop) or _crt == null:
		return
	if _desktop.get_parent() != _crt._viewport:
		_crt.show_control(_desktop)


## L'ora vera della notte, per la tray. Si rilegge a ogni fotogramma: è il dettaglio
## che fa smettere quel computer di essere il disegno di un computer.
func _ora() -> String:
	if _scena != null and _scena._night != null and _scena._night.has_method("clock"):
		var o = _scena._night.clock()
		if o != null:
			return o.clock_text()
	return "21:00"


func _process(_d: float) -> void:
	_riprendi_il_vetro()
	if _hud != null and _scena != null and _scena._desk != null:
		_hud.visible = _acceso and _scena._desk.is_seated
	if _acceso and is_instance_valid(_desktop):
		var adesso := _ora()
		if adesso != _desktop.ora:
			_desktop.ora = adesso
			_desktop.queue_redraw()


func _parametro(nome: String, valore) -> void:
	if _mesh == null:
		return
	var mat := _mesh.get_surface_override_material(0) as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter(nome, valore)
