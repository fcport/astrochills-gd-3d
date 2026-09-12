## IL PROVINO DELLE FASI: dodici lune di fila, da guardare.
##
## PERCHÉ SERVE, VISTO CHE C'È GIÀ UNA SONDA. Perché `tools/prova_luna.gd` misura
## NUMERI — la fase, la distanza, l'energia, i parametri che arrivano al
## materiale — e nessun numero dice se la falce guarda dalla parte giusta, se il
## terminatore è una curva o una scaletta, se il disco sembra la Luna o un
## dischetto bianco. Quella parte si vede e basta, e per vederla ci vuole
## un'immagine.
##
## COSA PRODUCE, tre file:
##   `luna-fasi.png`       dodici ritagli, uno per notte, con la camera stretta a
##                         dodici gradi: è la Luna INGRANDITA, per guardare la forma.
##   `luna-in-gioco.png`   una veduta normale, settantacinque gradi, da fuori: è
##                         quanto la Luna si vede DAVVERO giocando. Le due immagini
##                         servono insieme, e la seconda è quella onesta.
##   `luna-da-vicino.png`  il primo quarto a tre gradi di campo: il terminatore,
##                         dove si giudica se il rilievo dei crateri arriva.
##
## LE NOTTI NON SONO IN ORDINE DI CALENDARIO, sono in ordine di FASE: si parte
## dalla falce crescente della seconda lunazione (notti 28 e 30) e si prosegue
## con la prima (1, 3, 5...). Il ciclo si ripete, quindi messe in fila danno una
## progressione continua da falce a falce passando per la piena.
##
## E MANCA IL NOVILUNIO, ed è giusto che manchi: le notti dal 20 al 27 la Luna
## sta in cielo di GIORNO — sorge con il Sole e tramonta con lui — quindi durante
## il turno non c'è affatto. Non è un buco del provino: è il fatto che il provino
## racconta, ed è il motivo per cui quelle sono le notti buone per fotografare.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_luna.tscn
##
## E NON SI LIMITA A SALVARE, MISURA. Di ogni cella conta i pixel accesi e li
## confronta con la frazione illuminata che le effemeridi dichiarano: se il disco
## e' illuminato al ventinove per cento, di pixel bianchi ce ne devono essere il
## ventinove per cento dell'area del disco. E' quello che trasforma un'immagine
## da guardare in una misura, e non e' teoria — al primo scatto le fasi uscivano
## tutte COMPLEMENTARI (la piena disegnata come falce, la falce come piena) per un
## segno sbagliato nella normale, e nessuna prova numerica poteva vederlo: l'ora,
## la data, la fase e l'energia erano tutte giuste, sbagliava solo il disegno.
## Questo controllo lo avrebbe visto al primo colpo, e adesso lo vede.
##
## Serve una finestra vera: si salva quello che il rasterizzatore disegna, e in
## headless non disegna nessuno.
extends Node

## Dove si mette la camera: fuori, sul prato, alto quanto un tetto. Lo stesso
## punto di `scatta_cielo.gd`, e per la stessa ragione — da lì il cielo è libero
## da ogni parte e nessun muro entra nell'inquadratura.
const DOVE := Vector3(11.0, 3.0, 14.0)

## Le notti del provino, in ordine di fase. SONO TUTTE NOTTI IN CUI LA LUNA SI
## VEDE DAVVERO, e la scelta è già una misura: la falce più sottile che questo
## turno riesce a vedere è quella CALANTE (notte 18, illuminata 0,15, alle 05:30),
## non quella crescente. La falce crescente tramonta poco dopo il Sole, e alle
## 21:00 — quando si arriva all'osservatorio — è già sotto l'orizzonte.
const NOTTI := [28, 30, 1, 3, 5, 7, 9, 11, 13, 15, 17, 18]

## La griglia: sei per due.
const COLONNE := 6
const CELLA := 128

## Quanto stretta si fa la camera per il provino, in gradi. Il disco disegnato
## misura due gradi (mezzo grado vero per l'ingrandimento dichiarato in
## `LuceDiLuna`), quindi a dodici gradi riempie un sesto dell'altezza del
## SubViewport, cioè una sessantina di pixel per cella: abbastanza per leggere la
## curva del terminatore, con attorno abbastanza cielo da vedere anche l'alone.
## A sei — il primo tentativo — il disco sbordava dalla cella e il provino
## sembrava una fila di lune piene tagliate.
const FOV_PROVINO := 12.0

## E questo è il campo visivo VERO del giocatore: il default di `Camera3D`, che
## `world/player/player.tscn` non sovrascrive.
const FOV_GIOCO := 75.0

## Sopra questa luminosità un pixel è «acceso», su 1. Mezzo e passa: il disco
## illuminato viene disegnato a 1,3 volte la sua albedo — gli altipiani al
## bianco, i mari grigi ma ben sopra la soglia — mentre l'alone più forte non
## arriva a un ventesimo. Fra le due cose c'è un abisso, e la soglia può stare
## ovunque in mezzo.
const ACCESO := 0.55

## Quanto si ammette che l'area illuminata sbagli, in frazione dell'area del
## disco. UN DECIMO, ed è largo apposta: il terminatore è sfumato di due gradi e
## i pixel sono quadrati, quindi il conto non può tornare esatto. Un segno
## sbagliato non sbaglia di un decimo — sbaglia del complemento, cioè fino a uno.
const SCARTO_AREA_MAX := 0.10

## L'altezza del SubViewport in pixel, che è anche la misura del campo visivo
## verticale: serve a sapere quanti pixel è largo il disco, e quindi quanti
## pixel dovrebbero essere accesi. `main.tscn`, `stretch_shrink = 2` su 720.
const VIEWPORT_ALTO := 360.0

## La notte della veduta normale: la 4, gibbosa crescente alta quarantasei gradi
## alle 21:00. È la notte in cui c'è più Luna da vedere all'ora in cui si comincia.
const NOTTE_IN_GIOCO := 4

## Quanti minuti di notte si provano per trovare il momento in cui la Luna è più
## alta. Un passo da mezz'ora su nove ore: la Luna si sposta di sette gradi in
## mezz'ora, e per un provino è una risoluzione più che sufficiente.
const PASSO_MIN := 30.0
const ULTIMO_MIN := 510.0

const CARTELLA := "res://_bmad-output/planning-artifacts/gdds/gdd-astrochills-gd-3d-2026-08-24/"

var _camera: Camera3D
var _luna: LuceDiLuna
var _guasti := 0


func _ready() -> void:
	_scatta.call_deferred()


func _scatta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().process_frame

	_luna = LuceDiLuna.find_in(get_tree())
	var g := Player.find_in(get_tree())
	if _luna == null or g == null or Game.run == null:
		print("[luna] manca la luna, il giocatore o la notte: niente da fotografare")
		get_tree().quit(1)
		return

	# SI USA LA CAMERA DEL GIOCATORE e le si toglie il comando, come fanno
	# `prova_cielo.gd` e `scatta_cielo.gd`: aggiungerne una nostra vorrebbe dire
	# che il giocatore se la riprende al primo fotogramma, e si fotografa
	# l'interno della biblioteca.
	g.set_process(false)
	g.set_physics_process(false)
	g.set_process_unhandled_input(false)
	g.global_position = DOVE
	# VIA IL MIRINO. Si fotografa la finestra vera, e la finestra vera ha sopra
	# l'interfaccia: il puntino bianco del mirino sta esattamente al centro di
	# ogni scatto — cioè proprio dove la camera guarda la Luna — e nel provino
	# sembrava una stella dentro il disco. Si spegne con l'API del giocatore, la
	# stessa che usa l'oculare: nasconderne il nodo a mano non bastava, al
	# secondo lancio il puntino c'era ancora.
	g.mostra_mirino(false)
	_camera = g.get_node_or_null("Camera") as Camera3D
	if _camera == null:
		print("[luna] il giocatore non ha una camera")
		get_tree().quit(1)
		return

	await _provino()
	await _in_gioco()
	await _da_vicino()
	print("[luna] %s" % ("nessun guasto" if _guasti == 0 else "%d GUASTI" % _guasti))
	get_tree().quit(1 if _guasti > 0 else 0)


## Il provino: una cella per notte, la Luna al centro.
func _provino() -> void:
	_camera.fov = FOV_PROVINO
	var righe: int = int(ceil(float(NOTTI.size()) / float(COLONNE)))
	var foglio := Image.create(COLONNE * CELLA, righe * CELLA, false, Image.FORMAT_RGB8)
	foglio.fill(Color.BLACK)

	for i in NOTTI.size():
		var notte: int = NOTTI[i]
		var minuto := await _quando_e_piu_alta(notte)
		Game.run.night_index = notte
		Game.run.elapsed_min = minuto
		for _f in 4:
			await get_tree().process_frame
		var e := _luna.effemeridi()
		_guarda(Vector3(e[&"dir"]))
		for _f in 4:
			await get_tree().process_frame

		var cella := _ritaglio()
		foglio.blit_rect(cella, Rect2i(Vector2i.ZERO, cella.get_size()),
			Vector2i((i % COLONNE) * CELLA, (i / COLONNE) * CELLA))

		# LA MISURA: quanti pixel sono accesi, contro quanti dovrebbero esserlo.
		# L'area del disco si calcola, non si conta: contarla vorrebbe dire
		# distinguere la parte in ombra dal cielo, e la parte in ombra è illuminata
		# dalla luce cenere — cioè è proprio il pezzo che sta fra i due.
		# Il raggio in pixel: gradi di disco (già ingranditi) per pixel per grado.
		# La cella È un ritaglio 1:1 del SubViewport, non un'immagine riscalata —
		# vedi `_ritaglio()` — quindi qui i pixel sono quelli che il gioco disegna.
		var raggio_px := (float(e[&"diametro"]) * LuceDiLuna.INGRANDIMENTO * 0.5
			* (VIEWPORT_ALTO / FOV_PROVINO))
		var area := PI * raggio_px * raggio_px
		var accesi := _accesi(cella)
		var frazione := accesi / area
		var scarto := absf(frazione - float(e[&"illuminata"]))
		print("   cella %2d: notte %2d (%s), %02d:%02d — %-18s illuminata %.2f, misurata %.2f, alta %.0f gradi"
			% [i + 1, notte, Luna.data_scritta(notte),
				int(Luna.ORA_INIZIO + minuto / 60.0) % 24, int(minuto) % 60,
				Luna.fase_scritta(float(e[&"fase"]), Luna.crescente(float(e[&"eta"]))),
				e[&"illuminata"], frazione, e[&"alt"]])
		if scarto > SCARTO_AREA_MAX:
			_guasti += 1
			print("      GUASTO: il disegno mostra %.0f%% di disco acceso e le effemeridi ne dichiarano %.0f%%"
				% [frazione * 100.0, float(e[&"illuminata"]) * 100.0])

	var dove := CARTELLA + "luna-fasi.png"
	foglio.save_png(ProjectSettings.globalize_path(dove))
	print("[luna] provino delle fasi -> %s" % dove)


## La veduta vera: campo visivo del giocatore, la Luna dove capita.
func _in_gioco() -> void:
	_camera.fov = FOV_GIOCO
	Game.run.night_index = NOTTE_IN_GIOCO
	Game.run.elapsed_min = 0.0
	for _f in 4:
		await get_tree().process_frame
	var e := _luna.effemeridi()
	_guarda(Vector3(e[&"dir"]))
	for _f in 4:
		await get_tree().process_frame

	var img := get_viewport().get_texture().get_image()
	img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
	var dove := CARTELLA + "luna-in-gioco.png"
	img.save_png(ProjectSettings.globalize_path(dove))
	print("[luna] la notte %d alle 21:00, campo visivo %.0f gradi: il disco misura %.0f pixel su 360 -> %s"
		% [NOTTE_IN_GIOCO, FOV_GIOCO,
			float(e[&"diametro"]) * LuceDiLuna.INGRANDIMENTO / (FOV_GIOCO / 360.0), dove])


## LA LUNA DA VICINO: il primo quarto della notte 1, con la camera stretta a tre
## gradi — il disco disegnato ne misura due, cioè due terzi dell'altezza. È la
## vista in cui si giudica il RILIEVO: i crateri non si vedono alla luna piena, e
## non si vedono nel mezzo della parte illuminata; si vedono lungo il
## terminatore, dove il Sole è radente e ogni pendenza cambia la luce. Se lì il
## terminatore è una riga liscia, la mappa del rilievo non sta arrivando.
const FOV_VICINO := 3.0


func _da_vicino() -> void:
	_camera.fov = FOV_VICINO
	Game.run.night_index = 1
	Game.run.elapsed_min = 0.0
	for _f in 4:
		await get_tree().process_frame
	var e := _luna.effemeridi()
	_guarda(Vector3(e[&"dir"]))
	for _f in 4:
		await get_tree().process_frame
	# Il quadrato centrale di 720 pixel di finestra, dimezzato: i pixel veri del
	# SubViewport, come in `_ritaglio()`.
	var img := get_viewport().get_texture().get_image()
	var lato := mini(img.get_width(), img.get_height())
	var pezzo := img.get_region(Rect2i((img.get_size() - Vector2i(lato, lato)) / 2,
		Vector2i(lato, lato)))
	pezzo.resize(lato / 2, lato / 2, Image.INTERPOLATE_NEAREST)
	var dove := CARTELLA + "luna-da-vicino.png"
	pezzo.save_png(ProjectSettings.globalize_path(dove))
	print("[luna] la notte 1 alle 21:00 a %.0f gradi di campo, il terminatore -> %s"
		% [FOV_VICINO, dove])


## In che minuto della notte la Luna è più alta. Non è una raffinatezza: nella
## metà calante del mese la Luna sorge dopo mezzanotte, e fotografarla sempre
## alle 21:00 darebbe metà provino nero.
func _quando_e_piu_alta(notte: int) -> float:
	var meglio := 0.0
	var alta := -90.0
	var m := 0.0
	while m <= ULTIMO_MIN:
		var e := Luna.effemeridi(Luna.istante(notte, m))
		if float(e[&"alt"]) > alta:
			alta = float(e[&"alt"])
			meglio = m
		m += PASSO_MIN
	return meglio


## Punta la camera a una direzione del cielo.
func _guarda(verso: Vector3) -> void:
	# Il vettore alto si scambia se si guarda quasi allo zenit, dove `UP` sarebbe
	# parallelo alla vista e `look_at` non saprebbe più come stare dritta.
	var alto := Vector3.UP if absf(verso.y) < 0.99 else Vector3.FORWARD
	_camera.look_at_from_position(DOVE, DOVE + verso * 100.0, alto)


## Quanti pixel della cella sono accesi, cioè fanno parte della parte illuminata
## del disco.
func _accesi(img: Image) -> float:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if maxf(c.r, maxf(c.g, c.b)) > ACCESO:
				n += 1
	return float(n)


## Il quadrato centrale della finestra, ridotto a una cella.
##
## SI RITAGLIA IL DOPPIO E SI DIMEZZA, e non è un vezzo: il mondo si disegna in
## un SubViewport da 640x360 ingrandito due volte col filtro nearest, quindi
## ritagliare 256 pixel di finestra e ridurli a 128 restituisce esattamente i
## pixel che il gioco ha disegnato, senza inventarne né perderne.
func _ritaglio() -> Image:
	var img := get_viewport().get_texture().get_image()
	var lato := CELLA * 2
	var da := Rect2i((img.get_size() - Vector2i(lato, lato)) / 2, Vector2i(lato, lato))
	var pezzo := img.get_region(da)
	pezzo.resize(CELLA, CELLA, Image.INTERPOLATE_NEAREST)
	return pezzo
