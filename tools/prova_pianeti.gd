## I PIANETI SONO QUELLI DEL 1999? E SI VEDONO SOLO QUANDO SI DEVONO VEDERE?
##
## PERCHÉ SERVE UNA SONDA. Per la stessa ragione della Luna, ma peggio: un
## modello planetario sbagliato non ha nessun sintomo. Cinque puntini luminosi
## che sorgono, attraversano il cielo e tramontano sembrano giusti a chiunque li
## guardi — compreso a chi li ha scritti — perché nessuno sa a memoria dov'era
## Saturno il 16 novembre 1999. La differenza fra un sistema solare vero e cinque
## numeri plausibili non si vede a occhio: si vede solo contro un almanacco.
##
## LE DOMANDE:
##   0. IL SOLE, DUE VOLTE. `core/luna.gd` calcola il Sole con la formula di
##      Meeus; `core/pianeti.gd` lo ricava dalla posizione della TERRA nella sua
##      orbita. Sono due modelli diversi, scritti in due file diversi, che
##      rispondono alla stessa domanda: se non danno lo stesso Sole, uno dei due
##      sbaglia — ed è l'unica verifica di questa sonda che non abbia bisogno di
##      un libro.
##   1. LE CONFIGURAZIONI DEL 1999, che sono l'almanacco. L'opposizione di Giove
##      del 23 ottobre, quella di Saturno del 6 novembre, la massima elongazione
##      di Venere del 30 ottobre a 46 gradi e mezzo. Sono date PUBBLICATE: il
##      modello le deve ritrovare cercandole, non riceverle.
##   2. GLI INVARIANTI, che nessun modello sbagliato rispetta. Mercurio non si
##      allontana mai più di ventotto gradi dal Sole e Venere mai più di
##      quarantasette: sono conseguenze del raggio della loro orbita, e un
##      pianeta interno con l'orbita sbagliata li sfonda subito. Si misurano su
##      vent'anni, cioè su ottanta congiunzioni.
##   3. IL MESE DI LAVORO, che non è una prova: è la tabella da leggere. Per
##      trenta notti, a tre ore diverse, CHI SI VEDE. È la risposta alla
##      richiesta da cui è nato tutto questo — «non sempre si vede tutto» — ed è
##      anche l'unico posto dove si vede che la risposta cambia.
##   4. IL NODO IN SCENA: le direzioni e le luci arrivano davvero nel materiale
##      del cielo, e chi sta sotto l'orizzonte ha luce zero.
##   5. L'ARIA E LA LUNA: un pianeta basso si spegne, e con la luna piena il
##      limite si alza. Sono i due conti che decidono la visibilità, e si
##      collaudano sulla funzione pura invece che a occhio.
##
## IL DIFETTO SI RIMETTE, ed è l'interruttore che dice se questa sonda misura
## quello che crede:
##   TUTTI=1   si disegnano tutti e cinque sempre, orizzonte e aria ignorati. La
##             domanda 4 deve trovare cinque luci accese e pianeti sotto i piedi
##             disegnati lo stesso. Se non cambiasse niente, vorrebbe dire che la
##             selezione non sta selezionando.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_pianeti.tscn
##     TUTTI=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_pianeti.tscn
##
## GIRA IN HEADLESS: qui non si guarda nessun pixel, si leggono numeri e
## parametri di materiale. Come sono DISEGNATI i cinque punti è un'altra domanda,
## e ha un altro attrezzo — `tools/scatta_pianeti.gd`, che li fotografa e ne
## misura la luce sullo schermo. Le due cose servono insieme, ed è la seconda ad
## aver trovato l'unico guasto vero di questo lavoro (Saturno che spariva dentro
## un pixel): qui i numeri erano tutti giusti.
extends Node

## LE CONFIGURAZIONI PUBBLICATE DEL 1999: nome, pianeta, anno, mese, giorno, e che
## cosa ci deve essere quel giorno. Sono valori d'almanacco, non prodotti da
## questo codice.
##
## L'OPPOSIZIONE NON È «ELONGAZIONE 180», e non è un dettaglio: un pianeta
## all'opposizione sta dalla parte opposta al Sole in LONGITUDINE, ma resta fuori
## dall'eclittica della sua latitudine — due gradi e mezzo per Saturno — quindi
## l'angolo Sole-Terra-pianeta si ferma un po' prima di 180. Per questo la prova
## cerca il MASSIMO dell'elongazione e ne guarda la DATA, che è la cosa che
## l'almanacco pubblica davvero.
const ALMANACCO := [
	["opposizione di Giove", &"giove", 1999, 10, 23],
	["opposizione di Saturno", &"saturno", 1999, 11, 6],
	["massima elongazione di Venere", &"venere", 1999, 10, 30],
]

## Quanto si ammette di sbagliare la data di una configurazione, in giorni.
##
## UN GIORNO E MEZZO, E VUOL DIRE POCO. Attorno al massimo l'elongazione è piatta
## — è un massimo — quindi la data si sposta facilmente di qualche ora anche fra
## due almanacchi che scrivono lo stesso numero. Quello che questa soglia esclude
## è un modello che sbagli la SETTIMANA, cioè che metta Giove dall'altra parte
## del cielo: misurato, il modello sta sotto le dodici ore su tutte e tre.
const SCARTO_DATA_MAX := 1.5

## La massima elongazione di Venere in quell'occasione, pubblicata: 46 gradi e
## 30 primi. È il numero che dice che l'orbita di Venere ha il raggio giusto —
## un Venere con l'orbita sbagliata del cinque per cento darebbe la data giusta e
## l'angolo sbagliato.
const ELONGAZIONE_VENERE := 46.5
const SCARTO_ELONGAZIONE_MAX := 0.5

## GLI INVARIANTI DEI DUE PIANETI INTERNI: quanto possono allontanarsi dal Sole,
## in gradi, e in che intervallo deve stare il massimo misurato. Mercurio varia
## fra 18 e 28 a seconda di dove capita la congiunzione sulla sua orbita molto
## eccentrica, Venere fra 45 e 47 perché la sua è quasi un cerchio.
const INVARIANTI := [
	[&"mercurio", 26.5, 28.5],
	[&"venere", 45.0, 48.0],
]

## Su quanti anni si cercano i massimi: vent'anni sono ottanta congiunzioni di
## Mercurio e dodici di Venere, abbastanza perché il massimo vero ci capiti
## dentro più volte.
const ANNI_INVARIANTI := 20

## Le notti del calendario che si stampano nella tabella, e le ore dentro la
## notte a cui si guarda: l'inizio, il mezzo e la fine. Sono i tre momenti in cui
## il cielo di una notte è diverso da sé stesso.
const NOTTI := 30
const ORE := [0.0, 240.0, 480.0]

var _guasti := 0
var _tutti := false


func _ready() -> void:
	_tutti = OS.get_environment("TUTTI") == "1"
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[pianeti] GUASTO: " + msg)


func _prova() -> void:
	print("")
	print("=== I PIANETI DEL 1999 ===")
	_sole()
	_almanacco()
	_invarianti()
	_calendario()
	_aria_e_luna()
	await _in_scena()
	print("")
	print("[pianeti] %s" % ("nessun guasto" if _guasti == 0 else "%d GUASTI" % _guasti))
	get_tree().quit(1 if _guasti > 0 else 0)


## --- 0. IL SOLE, CALCOLATO DUE VOLTE ----------------------------------------
func _sole() -> void:
	print("")
	print("-- 0. il Sole: la Luna lo calcola con Meeus, i pianeti con l'orbita della Terra")
	var peggio := 0.0
	for notte in [1, 10, 20, 30]:
		for minuti in ORE:
			var jd := Luna.istante(notte, minuti)
			var a: Vector3 = Luna.effemeridi(jd)[&"sole_dir"]
			var b: Vector3 = Pianeti.sole(jd)[&"dir"]
			peggio = maxf(peggio, rad_to_deg(a.angle_to(b)))
	print("   scarto massimo fra i due Soli, su dodici istanti: %.4f gradi" % peggio)
	if peggio > 0.05:
		_guasto("i due modelli del Sole non concordano: uno dei due sbaglia di %.3f gradi"
			% peggio)


## --- 1. L'ALMANACCO ---------------------------------------------------------
func _almanacco() -> void:
	print("")
	print("-- 1. le configurazioni pubblicate del 1999, cercate e non ricevute")
	for riga in ALMANACCO:
		var etichetta: String = riga[0]
		var nome: StringName = riga[1]
		var atteso := float(Luna.giuliano_di(riga[2], riga[3], riga[4])) - 0.5
		# SI CERCA IL MASSIMO DELL'ELONGAZIONE di ora in ora, in una finestra di
		# venti giorni attorno alla data pubblicata: il modello deve TROVARE la
		# configurazione, non confermarla.
		var meglio := -1.0
		var quando := 0.0
		for passo in range(-240, 241):
			var jd := atteso + float(passo) / 24.0
			var e := _pianeta(nome, jd)
			var el := float(e[&"elongazione"])
			if el > meglio:
				meglio = el
				quando = jd
		var scarto := quando - atteso
		print("   %-32s massimo %.2f gradi, a %+.2f giorni (%+.1f ore) dalla data pubblicata"
			% [etichetta, meglio, scarto, scarto * 24.0])
		if absf(scarto) > SCARTO_DATA_MAX:
			_guasto("%s: il modello la mette %.1f giorni fuori" % [etichetta, scarto])
		if nome == &"venere" and absf(meglio - ELONGAZIONE_VENERE) > SCARTO_ELONGAZIONE_MAX:
			_guasto("l'elongazione di Venere vale %.2f invece di %.1f: l'orbita ha il raggio sbagliato"
				% [meglio, ELONGAZIONE_VENERE])


## --- 2. GLI INVARIANTI ------------------------------------------------------
func _invarianti() -> void:
	print("")
	print("-- 2. quanto si staccano dal Sole i due interni, su %d anni" % ANNI_INVARIANTI)
	var inizio := float(Luna.giuliano_di(1990, 1, 1)) - 0.5
	for riga in INVARIANTI:
		var nome: StringName = riga[0]
		var massimo := 0.0
		for giorno in ANNI_INVARIANTI * 365:
			massimo = maxf(massimo, float(_pianeta(nome, inizio + float(giorno))[&"elongazione"]))
		print("   %-9s massima elongazione %.2f gradi (attesa fra %.1f e %.1f)"
			% [Pianeti.scritto(nome), massimo, riga[1], riga[2]])
		if massimo < float(riga[1]) or massimo > float(riga[2]):
			_guasto("%s arriva a %.2f gradi dal Sole: l'orbita non e' la sua"
				% [Pianeti.scritto(nome), massimo])


## --- 3. IL MESE DI LAVORO ---------------------------------------------------
func _calendario() -> void:
	print("")
	print("-- 3. il mese di lavoro: chi si vede, notte per notte")
	print("   (altezza sull'orizzonte in gradi; chi non compare e' sotto, o troppo debole)")
	print("")
	print("   notte  data              21:00              01:00              05:00")
	var conteggio := {}
	for nome in Pianeti.ORDINE:
		conteggio[nome] = 0
	var momenti := 0
	for notte in range(1, NOTTI + 1):
		var celle := PackedStringArray()
		for minuti in ORE:
			var e := Pianeti.effemeridi(Luna.istante(notte, minuti))
			var chiarore := _chiarore(notte, minuti)
			var cella := ""
			for i in e.size():
				if PianetiInCielo.luce_di(e[i], chiarore) <= 0.0:
					continue
				conteggio[e[i][&"nome"]] += 1
				cella += "%s%+3.0f " % [String(e[i][&"scritto"]).substr(0, 2),
					float(e[i][&"alt"])]
			celle.append("%-18s" % (cella if cella != "" else "-"))
			momenti += 1
		print("   %4d   %-14s %s" % [notte, Luna.data_scritta(notte), " ".join(celle)])

	print("")
	var righe := PackedStringArray()
	for nome in Pianeti.ORDINE:
		righe.append("%s %d" % [Pianeti.scritto(nome), conteggio[nome]])
	print("   su %d momenti (%d notti x 3 ore), quante volte si vede ciascuno:" % [momenti, NOTTI])
	print("      " + ", ".join(righe))
	# LE DUE PROVE DI QUESTA TABELLA, e sono l'una il contrario dell'altra: se si
	# vedessero sempre tutti, la selezione non starebbe selezionando; se non si
	# vedesse mai nessuno, il cielo sarebbe vuoto e nessuno se ne accorgerebbe.
	var sempre := true
	var mai := true
	for nome in Pianeti.ORDINE:
		if conteggio[nome] < momenti:
			sempre = false
		if conteggio[nome] > 0:
			mai = false
	if sempre:
		_guasto("si vedono tutti e cinque in tutti i momenti: la visibilita' non decide niente")
	if mai:
		_guasto("non si vede mai nessun pianeta: il cielo e' vuoto tutte le notti")


## --- 5. L'ARIA E LA LUNA ----------------------------------------------------
##
## Sui numeri e non a occhio: `luce_di` è una funzione pura, quindi si può
## interrogare direttamente invece di dedurne il comportamento da uno schermo.
func _aria_e_luna() -> void:
	print("")
	print("-- 5. l'aria che si mangia la luce, e la luna che alza il limite")
	var alto := {&"alt": 60.0, &"magnitudine": -2.7}
	var basso := {&"alt": 1.0, &"magnitudine": -2.7}
	print("   Giove (mag -2,7) a 60 gradi: luce %.3f   a 1 grado: luce %.3f   (aria: %.1f masse)"
		% [PianetiInCielo.luce_di(alto, 0.0), PianetiInCielo.luce_di(basso, 0.0),
			PianetiInCielo.massa_daria(1.0)])
	if PianetiInCielo.luce_di(basso, 0.0) >= PianetiInCielo.luce_di(alto, 0.0):
		_guasto("un pianeta a un grado dall'orizzonte non e' piu' debole di uno allo zenit")
	var sotto := {&"alt": -1.0, &"magnitudine": -4.3}
	if PianetiInCielo.luce_di(sotto, 0.0) > 0.0:
		_guasto("un pianeta tramontato si disegna lo stesso")

	# LA LUNA PIENA NON SPEGNE UN PIANETA, ALZA IL PAVIMENTO, e la differenza si
	# vede solo dove il pianeta è già vicino a quel pavimento — cioè in basso,
	# dove l'aria gli ha già portato via due o tre magnitudini. In alto non
	# cambia niente, ed è giusto: con la luna piena Giove si vede eccome, sono
	# le stelle deboli a sparire. Per questo la prova si fa a CINQUE GRADI, che
	# è dove un astrofilo smette di aspettare un pianeta e va a dormire.
	var alte := [40.0, 5.0]
	print("   col cielo buio e con la luna piena:")
	var tenuto := {}
	for h in alte:
		for m in [0.2, -4.3]:
			var e := {&"alt": h, &"magnitudine": m}
			var buio := PianetiInCielo.luce_di(e, 0.0)
			var piena := PianetiInCielo.luce_di(e, 1.0)
			tenuto["%.0f/%.1f" % [h, m]] = piena
			print("      mag %+5.1f a %2.0f gradi:  %.3f -> %.3f" % [m, h, buio, piena])
	if tenuto["5/0.2"] > 0.0:
		_guasto("con la luna piena un pianeta di magnitudine +0,2 a cinque gradi "
			+ "si vede lo stesso: il chiarore non alza nessun limite")
	if is_zero_approx(tenuto["5/-4.3"]):
		_guasto("con la luna piena Venere a cinque gradi sparisce: il limite e' alzato troppo")
	if is_zero_approx(tenuto["40/0.2"]):
		_guasto("con la luna piena sparisce anche un pianeta alto: il limite e' alzato troppo")


## --- 4. IN SCENA ------------------------------------------------------------
func _in_scena() -> void:
	print("")
	print("-- 4. il nodo in scena, e quello che arriva allo shader")
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().process_frame

	var nodo := PianetiInCielo.find_in(get_tree())
	if nodo == null:
		_guasto("non trovo i pianeti in scena: il copione non e' montato sul nodo")
		return
	if Game.run == null:
		_guasto("la notte non e' cominciata: non c'e' un calendario da seguire")
		return
	if _tutti:
		nodo.tutti = true
		print("   TUTTI=1: si disegnano tutti e cinque sempre, orizzonte ignorato")

	var mat := _materiale_del_cielo()
	if mat == null:
		_guasto("non trovo il materiale del cielo: i pianeti non li disegna nessuno")
		return

	Game.run.night_index = 1
	Game.run.elapsed_min = 0.0
	await get_tree().process_frame
	await get_tree().process_frame

	var dati := nodo.effemeridi()
	var luci: PackedFloat32Array = mat.get_shader_parameter("pianeta_luce")
	var dirs: PackedVector3Array = mat.get_shader_parameter("pianeta_dir")
	var tinte: PackedVector3Array = mat.get_shader_parameter("pianeta_tinta")
	print("   notte 1, 21:00. Nel materiale del cielo:")
	if luci.size() != Pianeti.ORDINE.size() or dirs.size() != Pianeti.ORDINE.size():
		_guasto("nel cielo ci sono %d luci e %d direzioni invece di %d"
			% [luci.size(), dirs.size(), Pianeti.ORDINE.size()])
		return
	var sotto_disegnati := 0
	for i in dati.size():
		var e: Dictionary = dati[i]
		print("      %-9s alt %+6.1f  az %5.1f  mag %+5.2f  luce %.3f  tinta (%.2f %.2f %.2f)"
			% [e[&"scritto"], e[&"alt"], e[&"az"], e[&"magnitudine"], luci[i],
				tinte[i].x, tinte[i].y, tinte[i].z])
		if dirs[i].distance_to(Vector3(e[&"dir"])) > 0.001:
			_guasto("la direzione di %s nel cielo non e' quella delle sue effemeridi"
				% e[&"scritto"])
		if float(e[&"alt"]) < 0.0 and luci[i] > 0.0:
			sotto_disegnati += 1
	print("   visibili adesso: %s" % (", ".join(nodo.visibili()) if not nodo.visibili().is_empty()
		else "nessuno"))

	if _tutti:
		var spenti := 0
		for l in luci:
			if l <= 0.0:
				spenti += 1
		print("   TUTTI=1: %d pianeti accesi, di cui %d sotto l'orizzonte"
			% [luci.size() - spenti, sotto_disegnati])
		if spenti > 0:
			_guasto("TUTTI=1 e ci sono ancora %d pianeti spenti" % spenti)
		if sotto_disegnati == 0:
			_guasto("TUTTI=1 e nessun pianeta sotto l'orizzonte viene disegnato: "
				+ "l'interruttore non rimette niente")
		return

	if sotto_disegnati > 0:
		_guasto("%d pianeti sotto l'orizzonte hanno luce sopra zero" % sotto_disegnati)

	# LA NOTTE INTERA, ora per ora: l'insieme di quelli visibili DEVE cambiare.
	# È la richiesta da cui nasce tutto questo lavoro, ridotta a un numero.
	print("")
	print("   la notte 1, ora per ora:")
	var insiemi := {}
	for ora in range(0, 9):
		Game.run.elapsed_min = float(ora) * 60.0
		await get_tree().process_frame
		var chi := nodo.visibili()
		var etichetta := ", ".join(chi) if not chi.is_empty() else "nessuno"
		insiemi[etichetta] = true
		print("      %02d:00  %s" % [(Luna.ORA_INIZIO + ora) % 24, etichetta])
	print("   insiemi diversi nella notte: %d" % insiemi.size())
	if insiemi.size() < 2:
		_guasto("in nove ore si vedono sempre gli stessi: il cielo non si muove")


## Il chiarore della Luna in quell'istante — lo stesso numero che `LuceDiLuna`
## passa allo shader. Ricalcolato qui perché la tabella si stampa PRIMA di
## montare la scena: è una formula di una riga e sta scritta accanto alla sua
## gemella, non nascosta dentro un nodo.
func _chiarore(notte: int, minuti: float) -> float:
	var e := Luna.effemeridi(Luna.istante(notte, minuti))
	return float(e[&"illuminata"]) * clampf(sin(deg_to_rad(float(e[&"alt"]))), 0.0, 1.0)


## Un pianeta solo, per nome, a quell'istante.
func _pianeta(nome: StringName, jd: float) -> Dictionary:
	for e in Pianeti.effemeridi(jd):
		if e[&"nome"] == nome:
			return e
	return {}


func _materiale_del_cielo() -> ShaderMaterial:
	var we := get_tree().current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if we == null or we.environment == null or we.environment.sky == null:
		return null
	return we.environment.sky.sky_material as ShaderMaterial
