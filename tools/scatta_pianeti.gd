## IL PROVINO DEI PIANETI: come si vedono davvero, e la cella vuota di Marte.
##
## PERCHÉ SERVE, VISTO CHE C'È GIÀ UNA SONDA. Perché `tools/prova_pianeti.gd`
## misura NUMERI — dove sono, quanto sono luminosi, che cosa arriva al materiale
## del cielo — e nessun numero dice se un pianeta sullo schermo si vede, se si
## distingue da una stella, se Venere è una macchia e Saturno un puntino. Quella
## parte si guarda, e per guardarla ci vuole un'immagine.
##
## COSA PRODUCE, tre file:
##   `pianeti-provino.png`   quattro celle a dodici gradi di campo, una per
##                           pianeta: Giove, Saturno e Venere al momento in cui
##                           si vedono, e MARTE, che in quel momento è sotto
##                           l'orizzonte — la sua cella deve essere VUOTA. È
##                           l'immagine della richiesta: non sempre si vede tutto.
##   `pianeti-in-gioco.png`  la vista vera del giocatore, settantacinque gradi,
##                           la sera della notte 1: Giove e Saturno in mezzo alle
##                           stelle, ed è lì che si giudica se si riconoscono.
##   `pianeti-alba.png`      le cinque del mattino, a est: Venere che è sorta da
##                           un'ora, la cosa più luminosa del cielo dopo la Luna.
##
## E NON SI LIMITA A SALVARE, MISURA. Di ogni cella somma la luce del quadratino
## centrale — dove il pianeta è puntato — e confronta l'ordine con quello delle
## magnitudini: il più luminoso in cielo deve essere il più luminoso sullo
## schermo. È la prova che gli array dello shader non si sono scambiati di posto,
## che è l'unico guasto possibile qui che lasci tutti i numeri giusti — cinque
## luci esatte, assegnate al pianeta sbagliato.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_pianeti.tscn
##
## Serve una finestra vera: si salva quello che il rasterizzatore disegna, e in
## headless non disegna nessuno.
extends Node

## Dove si mette la camera: fuori, sul prato, alto quanto un tetto. Lo stesso
## punto di `scatta_luna.gd` e di `scatta_cielo.gd`, per la stessa ragione — da
## lì il cielo è libero da ogni parte e nessun muro entra nell'inquadratura.
const DOVE := Vector3(11.0, 3.0, 14.0)

## LE CELLE DEL PROVINO: pianeta, minuto della notte, e che cosa ci si aspetta di
## vedere. La notte è sempre la 1 — il 16 novembre 1999 — perché è quella con cui
## comincia il gioco, ed è quella che tutte le altre misure di questo lavoro
## raccontano.
##
## MARTE STA IN ELENCO APPOSTA, e la sua cella deve restare nera: alle 21:00 è
## tramontato da mezz'ora. Una cella vuota è più difficile da fraintendere di una
## riga di testo che dice «non visibile», e questo provino esiste per far vedere
## proprio quella metà della cosa.
const CELLE := [
	[&"giove", 0.0, "alto a sud-est, il più luminoso della sera"],
	[&"saturno", 0.0, "poco più su di Giove, giallo e più debole"],
	[&"venere", 480.0, "sorta da un'ora, a est"],
	[&"marte", 0.0, "TRAMONTATO: la cella deve restare vuota"],
]

## La griglia del provino: quattro celle in fila.
const COLONNE := 4
const CELLA := 128

## Quanto stretta si fa la camera per il provino, in gradi. Un pianeta è un PUNTO
## e resta largo un paio di pixel a qualunque campo visivo — non è come la Luna,
## che stringendo diventa un disco — quindi dodici gradi non servono a ingrandire
## il pianeta: servono a mostrarlo IN MEZZO ALLE STELLE, che è l'unico confronto
## che conti. Un pianeta si riconosce perché è più luminoso di quello che ha
## intorno, e senza intorno non si riconosce niente.
const FOV_PROVINO := 12.0

## Il campo visivo VERO del giocatore: il default di `Camera3D`, che
## `world/player/player.tscn` non sovrascrive.
const FOV_GIOCO := 75.0

## Il quadratino centrale su cui si misura, in pixel di cella: il pianeta è
## puntato al centro, e undici pixel bastano a contenerlo con tutto il suo alone.
## Più largo comincerebbe a raccogliere le stelle vicine, che è esattamente il
## rumore da cui questa misura deve stare fuori.
const MISURA := 11

## Sopra questa luminosità un pixel è «acceso», su 1. È la stessa soglia del
## provino della Luna, e per la stessa ragione: sta nell'abisso fra il nucleo di
## un oggetto disegnato e il fondo del cielo, che qui vale centesimi.
const ACCESO := 0.55

## La notte e l'ora delle due vedute a campo pieno.
const NOTTE := 1
const SERA_MIN := 0.0
const ALBA_MIN := 480.0

const CARTELLA := "res://_bmad-output/planning-artifacts/gdds/gdd-astrochills-gd-3d-2026-08-24/"

var _camera: Camera3D
var _pianeti: PianetiInCielo
var _guasti := 0


func _ready() -> void:
	_scatta.call_deferred()


func _scatta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().process_frame

	_pianeti = PianetiInCielo.find_in(get_tree())
	var g := Player.find_in(get_tree())
	if _pianeti == null or g == null or Game.run == null:
		print("[pianeti] mancano i pianeti, il giocatore o la notte: niente da fotografare")
		get_tree().quit(1)
		return

	# SI USA LA CAMERA DEL GIOCATORE e le si toglie il comando, come fanno
	# `prova_cielo.gd`, `scatta_cielo.gd` e `scatta_luna.gd`: aggiungerne una
	# nostra vorrebbe dire che il giocatore se la riprende al primo fotogramma.
	g.set_process(false)
	g.set_physics_process(false)
	g.set_process_unhandled_input(false)
	g.global_position = DOVE
	# VIA IL MIRINO: il puntino bianco sta esattamente al centro dello scatto,
	# cioè proprio dove la camera punta il pianeta, e nel provino sembrerebbe il
	# pianeta stesso. È lo stesso inciampo del provino della Luna.
	g.mostra_mirino(false)
	_camera = g.get_node_or_null("Camera") as Camera3D
	if _camera == null:
		print("[pianeti] il giocatore non ha una camera")
		get_tree().quit(1)
		return

	await _provino()
	await _veduta(SERA_MIN, &"giove", "pianeti-in-gioco.png", "la sera")
	await _veduta(ALBA_MIN, &"venere", "pianeti-alba.png", "l'alba")
	print("[pianeti] %s" % ("nessun guasto" if _guasti == 0 else "%d GUASTI" % _guasti))
	get_tree().quit(1 if _guasti > 0 else 0)


## Il provino: una cella per pianeta, il pianeta al centro.
func _provino() -> void:
	_camera.fov = FOV_PROVINO
	var foglio := Image.create(COLONNE * CELLA, CELLA, false, Image.FORMAT_RGB8)
	foglio.fill(Color.BLACK)
	var misure: Array[float] = []
	var luci_dichiarate: Array[float] = []

	for i in CELLE.size():
		var nome: StringName = CELLE[i][0]
		var minuto: float = CELLE[i][1]
		Game.run.night_index = NOTTE
		Game.run.elapsed_min = minuto
		for _f in 4:
			await get_tree().process_frame
		var e := _uno(nome)
		var luce := _luce(nome)
		_guarda(Vector3(e[&"dir"]))
		for _f in 4:
			await get_tree().process_frame

		var cella := _ritaglio()
		foglio.blit_rect(cella, Rect2i(Vector2i.ZERO, cella.get_size()),
			Vector2i(i * CELLA, 0))
		var somma := _somma_centrale(cella)
		misure.append(somma)
		luci_dichiarate.append(luce)
		print("   %-9s %02d:%02d  alt %+5.1f  mag %+5.2f  luce dichiarata %.3f  misurata %.2f  — %s"
			% [e[&"scritto"], int(Luna.ORA_INIZIO + minuto / 60.0) % 24, int(minuto) % 60,
				e[&"alt"], e[&"magnitudine"], luce, somma, CELLE[i][2]])

		# LA CELLA VUOTA È UNA MISURA COME LE ALTRE: un pianeta con luce zero non
		# deve lasciare NIENTE sullo schermo, e se qualcosa c'è vuol dire che
		# viene disegnato lo stesso — cioè che la selezione non serve a niente.
		if is_zero_approx(luce) and somma > 0.0:
			_guasti += 1
			print("      GUASTO: %s ha luce zero e sullo schermo c'e' qualcosa (%.2f)"
				% [e[&"scritto"], somma])
		if luce > 0.0 and is_zero_approx(somma):
			_guasti += 1
			print("      GUASTO: %s ha luce %.3f e sullo schermo non c'e' niente"
				% [e[&"scritto"], luce])

	var dove := CARTELLA + "pianeti-provino.png"
	foglio.save_png(ProjectSettings.globalize_path(dove))
	print("[pianeti] provino -> %s" % dove)

	# L'ORDINE: chi è dichiarato più luminoso deve misurare di più. È la prova
	# che l'indice dell'array è quello giusto — cinque luci esatte assegnate al
	# pianeta sbagliato darebbero tutti i numeri giusti e un cielo sbagliato.
	for i in misure.size():
		for j in misure.size():
			if luci_dichiarate[i] > luci_dichiarate[j] + 0.2 and misure[i] < misure[j]:
				_guasti += 1
				print("   GUASTO: %s e' dichiarato piu' luminoso di %s e sullo schermo misura meno"
					% [CELLE[i][0], CELLE[j][0]])


## Una veduta a campo pieno, con un pianeta nell'inquadratura.
func _veduta(minuto: float, verso: StringName, file: String, quando: String) -> void:
	_camera.fov = FOV_GIOCO
	Game.run.night_index = NOTTE
	Game.run.elapsed_min = minuto
	for _f in 4:
		await get_tree().process_frame
	_guarda(Vector3(_uno(verso)[&"dir"]))
	for _f in 4:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
	var dove := CARTELLA + file
	img.save_png(ProjectSettings.globalize_path(dove))
	print("[pianeti] %s della notte %d (%02d:%02d), campo %.0f gradi, si vedono: %s -> %s"
		% [quando, NOTTE, int(Luna.ORA_INIZIO + minuto / 60.0) % 24, int(minuto) % 60,
			FOV_GIOCO, ", ".join(_pianeti.visibili()), dove])


## Le effemeridi di un pianeta, per nome, da quelle che il nodo sta usando.
func _uno(nome: StringName) -> Dictionary:
	for e in _pianeti.effemeridi():
		if e[&"nome"] == nome:
			return e
	return {}


## La luce che il nodo ha scritto per quel pianeta.
func _luce(nome: StringName) -> float:
	var luci := _pianeti.luci()
	for i in Pianeti.ORDINE.size():
		if Pianeti.ORDINE[i] == nome and i < luci.size():
			return luci[i]
	return 0.0


## Punta la camera a una direzione del cielo.
func _guarda(verso: Vector3) -> void:
	var alto := Vector3.UP if absf(verso.y) < 0.99 else Vector3.FORWARD
	_camera.look_at_from_position(DOVE, DOVE + verso * 100.0, alto)


## La luce accesa nel quadratino centrale della cella, dove sta il pianeta.
##
## SI SOMMA INVECE DI CONTARE, al contrario del provino della Luna: lì la
## domanda era «quanta area è illuminata», qui è «quanta luce arriva», e un
## pianeta più luminoso non copre più pixel — li accende di più e si porta
## dietro più alone.
func _somma_centrale(img: Image) -> float:
	var mezzo := img.get_width() / 2
	var somma := 0.0
	for y in range(mezzo - MISURA / 2, mezzo + MISURA / 2 + 1):
		for x in range(mezzo - MISURA / 2, mezzo + MISURA / 2 + 1):
			var c := img.get_pixel(x, y)
			var v := maxf(c.r, maxf(c.g, c.b))
			if v > ACCESO:
				somma += v
	return somma


## Il quadrato centrale della finestra, ridotto a una cella. Si ritaglia il
## doppio e si dimezza: il mondo si disegna in un SubViewport da 640x360
## ingrandito due volte col filtro nearest, quindi così tornano esattamente i
## pixel che il gioco ha disegnato.
func _ritaglio() -> Image:
	var img := get_viewport().get_texture().get_image()
	var lato := CELLA * 2
	var da := Rect2i((img.get_size() - Vector2i(lato, lato)) / 2, Vector2i(lato, lato))
	var pezzo := img.get_region(da)
	pezzo.resize(CELLA, CELLA, Image.INTERPOLATE_NEAREST)
	return pezzo
