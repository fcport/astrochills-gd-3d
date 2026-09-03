## LE STRISCIATE: una posa lunga finta, che fa vedere attorno a cosa gira il cielo.
##
## PERCHÉ NON BASTAVANO DUE FOTOGRAMMI. La prima stesura di questo attrezzo salvava
## due immagini a due ore di distanza, guardando a est e a ovest, e non dimostravano
## niente: un campo di stelle procedurale è rumore uniforme, e fra due rumori
## uniformi spostati di trenta gradi un occhio non vede nessuna differenza. Sarebbe
## stato un referto che sembra una prova.
##
## COSA FA INVECE. Prende trenta fotogrammi mentre il cielo gira, e di ogni pixel
## tiene il PIÙ LUMINOSO dei trenta. Ogni stella lascia la propria traccia, e le
## tracce sono archi: archi concentrici attorno al polo celeste guardando a nord —
## piccoli vicino al polo, grandi lontano — e archi quasi verticali guardando a est,
## perché a est le stelle salgono. È quello che fa una macchina fotografica lasciata
## aperta un'ora, ed è l'unica immagine che dica da sola dove passa l'asse.
##
## E IL VERSO NON LO DICE, e va detto: una traccia non ha una freccia. Che le stelle
## a est SALGANO e non scendano lo verifica `tools/prova_rotazione.gd`, con un conto
## di tre righe sulla direzione dell'orizzonte est. Queste immagini dicono l'ASSE.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_cielo.tscn
##
## Serve una finestra vera: si salva quello che il rasterizzatore disegna, e in
## headless non disegna nessuno.
##
## LE STELLE SONO SCHIARITE per la stampa, e va detto: nel gioco `luminosita` vale
## uno, ed è tarata per un occhio che si è fatto il buio in venti minuti. Su un PNG
## guardato in una stanza illuminata, a uno non si vede quasi niente. Qui vale tre —
## cambia quanto le stelle si vedono, non dove stanno.
extends Node

## Dove si mette la camera: fuori, sul prato, in alto quanto un tetto. Da lì il
## cielo è libero da ogni parte.
const DOVE := Vector3(11.0, 3.0, 14.0)

## Quanti fotogrammi si sovrappongono, e quanto cielo passa fra uno e l'altro. Trenta
## scatti da quattro minuti fanno due ore di posa: trenta gradi di cielo, cioè archi
## abbastanza lunghi da leggersi come archi e non come trattini.
const SCATTI := 30
const PASSO_MIN := 4.0

## A che risoluzione si combina. SI RIMPICCIOLISCE PRIMA, e non è una scelta
## estetica: il confronto pixel per pixel si fa in GDScript, e un fotogramma pieno
## sono novecentomila pixel per trenta scatti — minuti di attesa per un'immagine che
## a metà misura si legge uguale.
const LARGO := 640
const ALTO := 360

## Dove si guarda: nome, azimut (misurato come `atan2(x, z)`: 0 è il nord) e altezza
## sull'orizzonte. Il primo è il polo — l'altezza VALE la latitudine, ed è lì che gli
## archi si chiudono in cerchi.
const GUARDA := [
	["polo", 0.0, 43.9],
	["est", 90.0, 30.0],
]

const CARTELLA := "res://_bmad-output/planning-artifacts/gdds/gdd-astrochills-gd-3d-2026-08-24/"

var _camera: Camera3D
var _cielo: TempoSiderale


func _ready() -> void:
	_scatta.call_deferred()


func _scatta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().process_frame

	_cielo = TempoSiderale.find_in(get_tree())
	var g := Player.find_in(get_tree())
	if _cielo == null or g == null:
		print("[strisciate] manca il cielo o il giocatore: niente da fotografare")
		get_tree().quit(1)
		return

	# SI USA LA CAMERA DEL GIOCATORE e le si toglie il comando, come fa
	# `prova_cielo.gd`: aggiungerne una nostra vorrebbe dire che il giocatore se la
	# riprende al primo fotogramma e si fotografa l'interno della biblioteca.
	g.set_process(false)
	g.set_physics_process(false)
	g.set_process_unhandled_input(false)
	g.global_position = DOVE
	_camera = g.get_node_or_null("Camera") as Camera3D
	if _camera == null:
		print("[strisciate] il giocatore non ha una camera")
		get_tree().quit(1)
		return

	var we := _cielo.get_node_or_null(_cielo.ambiente) as WorldEnvironment
	var mat := we.environment.sky.sky_material as ShaderMaterial
	mat.set_shader_parameter("luminosita", 3.0)

	for versante in GUARDA:
		await _posa(String(versante[0]), float(versante[1]), float(versante[2]))
	print("[strisciate] gli archi del «polo» sono concentrici attorno al polo celeste; "
		+ "quelli di «est» sono le stelle che salgono")
	get_tree().quit()


## Una posa: `SCATTI` fotogrammi sovrapposti tenendo il pixel più luminoso.
func _posa(nome: String, azimut: float, altezza: float) -> void:
	var a := deg_to_rad(azimut)
	var h := deg_to_rad(altezza)
	var verso := Vector3(sin(a) * cos(h), sin(h), cos(a) * cos(h))
	_camera.look_at_from_position(DOVE, DOVE + verso * 10.0, Vector3.UP)

	var t0 := Game.run.elapsed_min
	var somma: Image = null
	for i in SCATTI:
		Game.run.elapsed_min = t0 + float(i) * PASSO_MIN
		for _f in 3:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.resize(LARGO, ALTO, Image.INTERPOLATE_BILINEAR)
		if somma == null:
			somma = img
			continue
		for y in ALTO:
			for x in LARGO:
				var c := img.get_pixel(x, y)
				var v := somma.get_pixel(x, y)
				# IL PIÙ LUMINOSO DEI DUE, non la somma: sommando, il fondo del cielo
				# si accumula trenta volte e l'immagine diventa grigia con dentro
				# delle tracce. Il massimo lascia il fondo dov'è.
				if c.r + c.g + c.b > v.r + v.g + v.b:
					somma.set_pixel(x, y, c)
	var dove_va := CARTELLA + "cielo-strisciate-%s.png" % nome
	somma.save_png(ProjectSettings.globalize_path(dove_va))
	print("[strisciate] %s: %d scatti, %.0f gradi di cielo -> %s"
		% [nome, SCATTI, _cielo.gradi() - t0 * TempoSiderale.GRADI_AL_MINUTO, dove_va])
