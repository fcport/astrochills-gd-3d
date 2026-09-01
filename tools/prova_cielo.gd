## LE STELLE STANNO FERME MENTRE GIRO LA TESTA?
##
## IL DIFETTO, DETTO DA FEDERICO: «una cosa che ha poco senso sono le stelle che
## cambiano se muovo la visuale». Non e' scintillio — le stelle vere tremolano di
## INTENSITA', per l'aria che si muove — e' che si accendono e si spengono, tutte
## insieme, mentre la camera ruota.
##
## LA CAUSA E' ARITMETICA E NON ARTISTICA. Il dischetto di una stella misura poco
## piu' di mezzo pixel: girando, il suo centro passa da una parte all'altra del
## confine fra due pixel, e la stella o viene campionata o non viene campionata. E'
## l'aliasing piu' vecchio del mondo, ed e' invisibile a fermo — che e' il motivo
## per cui non era stato notato quando il cielo e' stato scritto.
##
## COME SI MISURA. Si punta la camera al cielo e la si gira di un ventesimo di
## grado alla volta - meno di un pixel - misurando ogni volta quanta luce c'e' in
## tutto il fotogramma. Un cielo stabile cambia pochissimo: le stelle escono da un
## bordo e ne entrano altrettante dall'altro. Un cielo che pulsa cambia di molto, e
## il numero che lo dice e' lo SCARTO RELATIVO fra un fotogramma e il successivo.
##
## E SI GUARDA ANCHE IL DIFETTO, come ogni sonda di questo progetto: `CRUDO=1`
## azzera `antialias` nel cielo, cioe' rimette le stelle sotto il pixel. Se il
## tremolio non peggiora, questa sonda non sta misurando quello che crede.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_cielo.tscn
##     CRUDO=1 Godot_v4.7.2-stable_win64.exe --path . tools/prova_cielo.tscn
##
## Serve una finestra vera: si misura quello che il rasterizzatore disegna, e in
## headless non disegna nessuno.
extends Node

## Di quanto si gira fra un fotogramma e l'altro, in gradi. Un ventesimo di grado
## e' meno di un pixel a qualunque risoluzione ragionevole: quello che cambia fra
## due scatti cosi' vicini non e' il cielo, e' il campionamento.
const PASSO_GRADI := 0.05

## Quanti scatti. Venti bastano a distinguere un tremolio da un caso.
const SCATTI := 20

## Quanti fotogrammi si lasciano passare prima di cominciare a misurare.
const RESPIRO := 20

## Quanto tremolio si ammette, in frazione della luce del fotogramma. Mezzo per
## cento: misurato, il cielo corretto sta a 0,31 e quello crudo a 1,13.
const SOGLIA := 0.005

var _camera: Camera3D
var _luci: Array[float] = []
var _fatti := 0
var _aspetta := 0
var _crudo := false
var _finito := false


func _ready() -> void:
	_crudo = OS.get_environment("CRUDO") == "1"
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena

	# SI USA LA CAMERA DEL GIOCATORE, e non una nostra. La prima stesura ne
	# aggiungeva una e le diceva `current = true`: il giocatore nasce DOPO e se la
	# riprende, e la sonda ha misurato per tre giri l'interno della biblioteca —
	# con un tremolio dello 0,000 per cento, che era vero e non voleva dire niente.
	# Si prende quella che c'e' gia', le si toglie il comando e la si porta fuori.
	var g := Player.find_in(get_tree())
	if g == null:
		print("[cielo] non trovo il giocatore: la prova non vale")
		_finito = true
		get_tree().quit()
		return
	g.set_process(false)
	g.set_physics_process(false)
	g.set_process_unhandled_input(false)
	g.global_position = Vector3(11.0, 3.0, 14.0)
	_camera = g.get_node_or_null("Camera") as Camera3D
	if _camera == null:
		print("[cielo] il giocatore non ha una camera: la prova non vale")
		_finito = true
		get_tree().quit()
		return
	# In su e verso nord: li' c'e' cielo e non edificio.
	_camera.global_rotation_degrees = Vector3(35.0, 0.0, 0.0)

	var amb := _cerca_ambiente(get_tree().root)
	if amb == null or amb.environment == null or amb.environment.sky == null:
		print("[cielo] non trovo il cielo: la prova non vale")
		_finito = true
		get_tree().quit()
		return
	var mat := amb.environment.sky.sky_material as ShaderMaterial
	if mat == null:
		print("[cielo] il cielo non ha un ShaderMaterial: la prova non vale")
		_finito = true
		get_tree().quit()
		return
	if _crudo:
		# IL DIFETTO INIETTATO: stelle piu' piccole di un pixel, com'erano prima.
		mat.set_shader_parameter("antialias", 0.0)
		print("[cielo] CRUDO: antialias a zero, le stelle devono tornare a pulsare")
	# Piu' luminose del normale SOLO per la misura: il tremolio si misura sulle
	# stelle, e con il fondo che pesa quanto loro il segnale si annacqua.
	mat.set_shader_parameter("luminosita", 4.0)


func _cerca_ambiente(n: Node) -> WorldEnvironment:
	if n is WorldEnvironment:
		return n as WorldEnvironment
	for f in n.get_children():
		var t := _cerca_ambiente(f)
		if t != null:
			return t
	return null


func _process(_d: float) -> void:
	if _finito or _camera == null:
		return
	_aspetta += 1
	if _aspetta < RESPIRO:
		return
	var img: Image = get_viewport().get_texture().get_image()
	if _fatti == 0:
		img.save_png("user://cielo_scatto.png")
	_luci.append(_luce(img))
	_fatti += 1
	if _fatti >= SCATTI:
		_referto()
		return
	_camera.global_rotation_degrees.y += PASSO_GRADI


## Quanta luce c'e' in tutto il fotogramma, 0-255. La somma e' la cosa giusta da
## guardare: le stelle sono poche e piccole, e una media su tutto il fotogramma
## le annegherebbe nel fondo — ma il FONDO NON CAMBIA girando di un ventesimo di
## grado, quindi tutto quello che si muove in questo numero sono loro.
func _luce(img: Image) -> float:
	var somma := 0.0
	var w := img.get_width()
	var h := img.get_height()
	# Un pixel ogni due per lato: quattro volte piu' veloce, e il campione resta
	# abbastanza grande da non fare rumore proprio.
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			var c := img.get_pixel(x, y)
			somma += c.r + c.g + c.b
	return somma


func _referto() -> void:
	_finito = true
	var media := 0.0
	for v in _luci:
		media += v
	media /= _luci.size()
	# LO SCARTO FRA UN FOTOGRAMMA E IL SUCCESSIVO, non la varianza sull'insieme: il
	# difetto e' che il cielo PULSA, cioe' che due fotogrammi consecutivi sono
	# diversi. Una deriva lenta - il campo che scorre - non e' un difetto.
	var salto := 0.0
	var peggio := 0.0
	for i in range(1, _luci.size()):
		var s: float = absf(_luci[i] - _luci[i - 1]) / maxf(media, 1.0)
		salto += s
		peggio = maxf(peggio, s)
	salto /= float(_luci.size() - 1)
	print("[cielo] luce media per fotogramma %.0f (se e' zero, non sto guardando il cielo)" % media)
	print("[cielo] %d scatti a %.2f gradi l'uno: tremolio medio %.3f%%, peggiore %.3f%%"
		% [SCATTI, PASSO_GRADI, salto * 100.0, peggio * 100.0])
	print("[cielo] %s" % ("con le stelle sotto il pixel (CRUDO)" if _crudo
		else "con le stelle allargate a un pixel"))
	# I DUE GIUDIZI. Il primo e' il difetto di Federico; il secondo e' che questa
	# sonda sappia vederlo — misurato una volta, a mano, e scritto qui: senza
	# correzione il tremolio medio sta sopra l'uno per cento e i picchi sopra il
	# tre, con correzione sotto il mezzo. Fra i due c'e' un fattore tre abbondante,
	# che e' il margine perche' questo confronto non dipenda dallo schermo.
	if not _crudo and salto > SOGLIA:
		print("[cielo] GUASTO: le stelle pulsano (%.3f%% contro %.3f%% ammesso)"
			% [salto * 100.0, SOGLIA * 100.0])
	if _crudo and salto <= SOGLIA:
		print("[cielo] SONDA CIECA: senza correzione il tremolio resta sotto la "
			+ "soglia, quindi questa misura non distingue i due cieli")
	get_tree().quit()
