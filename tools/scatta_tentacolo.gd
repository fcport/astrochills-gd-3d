## IL TENTACOLO IN PARTITA, fotografato da dove lo si vedrebbe.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_tentacolo.tscn
##
## Serve una FINESTRA VERA: si salva quello che il rasterizzatore disegna, e in
## headless non disegna nessuno. È lo stesso attrezzo di `tools/scatta_cielo.gd`,
## con la stessa regola — si usa la camera del giocatore e le si toglie il comando,
## invece di aggiungerne una nostra che il giocatore si riprenderebbe.
##
## `tools/prova_tentacolo.gd` misura il movimento: i gradi di piega, il ritardo
## dell'onda, dove cade la punta. Nessuno di quei numeri dice se la cosa si GUARDA,
## e questa è la domanda per cui si scatta: quanto è grande vista da un uomo alto
## un metro e ottanta, se contro il cielo notturno si stacca o sparisce, se
## scendendo si legge come una cosa che scende.
##
## LA LUNA RESTA DOV'E', e le si alza solo l'energia. Girarla dove faceva comodo
## rendeva lo scatto una bugia: il disco lunare lo disegna lo shader del cielo e
## sta dov'è la Luna vera della notte, quindi con la luce girata altrove si sarebbe
## fotografata un'ombra che viene da una parte e una Luna che sta dall'altra. Qui
## la direzione è quella della partita e l'energia sale da 0,42 a 0,70: cambia
## quanto si vede, non da dove.
##
## E SI ASPETTA L'OCCHIO PRIMA DI CALARLO. `world/dark_adaptation.gd` alza
## l'esposizione di 2,4 volte in cinquanta secondi, che è l'occhio che si fa il
## buio. Il primo giro lo calava subito e lo scatto a metà discesa è venuto un
## rettangolo di stelle: la cosa c'era, in mezzo all'inquadratura, e non si vedeva
## perché l'occhio non era ancora aperto. Qui si aspetta un minuto fermi sul prato
## e POI si chiama, che è anche l'unico modo in cui un giocatore la vedrebbe
## davvero — nessuno esce e guarda in alto nel primo secondo.
extends Node

const CARTELLA := "res://_confronto/"

## Dove si cala, come in `debug/tentacolo.gd`.
const DOVE := Vector2(10.6, 17.0)
const FRANCO := 1.5

## L'occhio di un uomo in piedi.
const OCCHIO := 1.70

## Quanto si aspetta fermi sul prato prima di calarlo: l'occhio ci mette cinquanta
## secondi a fare il buio, più un margine.
const ATTESA_OCCHIO := 62.0

## Gli scatti: nome, da dove, verso dove (in metri di gioco), e a che secondo DELLA
## DISCESA, che adesso dura quarantadue secondi.
##
## LA DISCESA SI FOTOGRAFA TARDI, e non è pigrizia di inquadratura: da trecento
## metri, a metà corsa la punta sta ancora a centoventi metri sopra la testa, cioè
## a ottanta gradi sull'orizzonte da qualunque punto del prato — un'inquadratura
## che si può fare solo puntando la camera quasi allo zenit, e che non è quello che
## un uomo in piedi vede. Al ventesimo secondo la punta è scesa a venti metri, e lì
## sta nell'inquadratura di uno che guarda in alto.
##
## E UNO SCATTO GUARDA IN SU, che è la domanda nuova: la prima stesura era lunga
## quarantacinque metri e alzando la testa si trovava il TAPPO, un disco a
## mezz'aria. A duecento metri quel disco dovrebbe essere un francobollo nero su
## nero — questo scatto serve a controllarlo, non a fare bella figura.
const SCATTI := [
	["a_meta_discesa", Vector3(21.0, OCCHIO, 28.0), Vector3(10.6, 60.0, 17.0), 30.0],
	["dal_piazzale", Vector3(21.0, OCCHIO, 28.0), Vector3(10.6, 12.0, 17.0), 50.0],
	["dalla_porta", Vector3(10.85, OCCHIO, 10.6), Vector3(10.6, 3.0, 17.0), 58.0],
	["sotto_la_punta", Vector3(15.8, OCCHIO, 21.5), Vector3(10.6, 2.0, 17.0), 66.0],
	["in_su", Vector3(16.0, OCCHIO, 22.0), Vector3(10.6, 300.0, 17.0), 74.0],
	["in_su_da_lontano", Vector3(25.0, OCCHIO, 30.0), Vector3(10.6, 200.0, 17.0), 80.0],
	["contro_l_edificio", Vector3(10.6, OCCHIO, 30.0), Vector3(10.6, 14.0, 17.0), 88.0],
]

var _camera: Camera3D


func _ready() -> void:
	_scatta.call_deferred()


func _scatta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().process_frame

	var g := Player.find_in(get_tree())
	if g == null:
		print("[tentacolo] niente giocatore: non c'è da dove guardare")
		get_tree().quit(1)
		return
	g.set_process(false)
	g.set_physics_process(false)
	g.set_process_unhandled_input(false)
	_camera = g.get_node_or_null("Camera") as Camera3D

	var luna := LuceDiLuna.find_in(get_tree())
	if luna != null:
		luna.set_process(false)
		# `LUNA=2` alza la luce per capire COSA C'E' NEL BUIO. Di notte una superficie
		# scura contro un cielo nero sparisce, e sparendo può nascondere sia una cosa
		# giusta sia un difetto: guardando in su, la colonna sembrava FINIRE a
		# venticinque metri, e senza questa manopola non c'era modo di sapere se
		# finiva davvero o se il resto era solo troppo scuro.
		var forzatura := OS.get_environment("LUNA")
		luna.light_energy = float(forzatura) if forzatura != "" else 0.70

	# fuori, fermi, ad aspettare che l'occhio si apra
	_inquadra(SCATTI[0][1] as Vector3, SCATTI[0][2] as Vector3, g)
	var atteso := 0.0
	while atteso < ATTESA_OCCHIO:
		await get_tree().process_frame
		atteso += get_process_delta_time()

	var t := (load("res://world/tentacolo.tscn") as PackedScene).instantiate() as Tentacolo
	scena.get_node("%SubViewport").add_child(t)
	t.posa_sul_prato(DOVE.x, DOVE.y, FRANCO)
	t.scendi()

	var passato := 0.0
	for s in SCATTI:
		var quando := float(s[3])
		while passato < quando:
			await get_tree().process_frame
			passato += get_process_delta_time()
		_inquadra(s[1] as Vector3, s[2] as Vector3, g)
		await get_tree().process_frame
		await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var dove := CARTELLA + "28_tentacolo_%s.png" % s[0]
		img.save_png(ProjectSettings.globalize_path(dove))
		# DOVE STA LA PUNTA, stampato accanto a ogni scatto: una punta sottile e scura
		# contro un muro scuro sparisce, e dai pixel non si distingue una punta
		# invisibile da una punta che non è scesa.
		var p := t.punta()
		print("[tentacolo] %5.1f s  punta a (%.1f, %.1f, %.1f)  %s" % [
			passato, p.x, p.y, p.z, dove])
	get_tree().quit()


func _inquadra(da: Vector3, a: Vector3, g: Node3D) -> void:
	g.global_position = Vector3(da.x, da.y - OCCHIO, da.z)
	if _camera != null:
		_camera.look_at_from_position(da, a, Vector3.UP)
