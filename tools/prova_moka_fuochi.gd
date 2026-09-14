## LA MOKA RESTA SUL FUOCO QUANDO LA SI METTE COME LA METTE UN GIOCATORE?
##
## PERCHÉ UNA SECONDA SONDA. `prova_moka.gd` passa, e Federico giocando l'ha vista cadere:
## «anche se dice metti la moka sul fuoco comunque mi cade». Quella sonda però consegna E
## direttamente al giocatore e gli rimette la moka in mano per teletrasporto. Qui si fa come
## si gioca: la moka presa resta a inseguire la mano, ci si mette in piedi davanti al piano
## cottura, si guarda un fuoco, e si preme il TASTO vero, che passa per tutti i viewport.
## Per ognuno dei quattro fuochi si registra dove va la moka nel secondo e mezzo dopo.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_moka_fuochi.tscn
extends Node

## Dove sta il giocatore rispetto al fronte del bancone: il raggio della capsula e cinque
## centimetri.
const DAL_FRONTE := 0.35

var _guasti := 0

## Si accelera come accelera il gioco, con lo strumento di F1–F4: scrivere solo
## `Engine.time_scale` misurerebbe una fisica che nel gioco non c'è più (D-245).
var _tempo: GDScript = load("res://debug/time_control.gd")


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[fuochi] GUASTO: " + msg)


func _prova() -> void:
	Game.profile.mark_owned(Moka.ITEM)
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 60:
		await get_tree().physics_frame

	var moka := Moka.find_in(get_tree())
	var giocatore := Player.find_in(get_tree())
	var fornelli: Array[Fornello] = []
	for n in get_tree().get_nodes_in_group(Fornello.GROUP):
		fornelli.append(n as Fornello)
	fornelli.sort_custom(func(a: Fornello, b: Fornello) -> bool:
		return String(a.name) < String(b.name))

	# A OGNI VELOCITÀ DI F1–F4: Federico ha giocato accelerando, e il tempo scalato allunga il
	# passo di fisica.
	for scala in [1.0, 2.0, 5.0, 10.0]:
		for f in fornelli:
			await _prova_fuoco(giocatore, moka, f, scala)

	print("[fuochi] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


func _prova_fuoco(giocatore: Player, moka: Moka, f: Fornello, scala: float) -> void:
	_tempo.accelera(1.0)
	# In piedi davanti al fuoco, a filo del bancone, guardando il centro del bruciatore.
	var c := f.centro()
	var piedi := Vector3(c.x, 0.0, f.global_position.z + DAL_FRONTE)
	giocatore.velocity = Vector3.ZERO
	giocatore.global_position = piedi
	giocatore.look_at(Vector3(c.x, 0.0, c.z), Vector3.UP)
	giocatore.camera().look_at(c, Vector3.UP)

	# La moka in mano come la prende il giocatore, e poi la si lascia inseguire la mano.
	if giocatore.tenuto() != moka:
		moka.global_transform = giocatore._trasformata_mano()
		moka.linear_velocity = Vector3.ZERO
		giocatore._prendi(moka)
	for _i in 40:
		await get_tree().physics_frame
	var riga := (giocatore.get_node(^"%InteractionPrompt") as InteractionPrompt).riga()
	print("[fuochi] %s: in piedi a %s, la mano tiene la moka a %s, sguardo a %s, riga «%s»"
		% [f.name, _v(piedi), _v(moka.global_position), _v(moka.punto_mirato()), riga])
	if not riga.contains("Metti la moka sul fuoco"):
		_guasto("%s: da davanti al bancone la riga non dice di metterla sul fuoco" % f.name)
		return

	_tempo.accelera(scala)
	await _tasto(KEY_E)
	var in_mano_dopo := giocatore.tenuto() == moka
	var y_min := moka.global_position.y
	var tracce := PackedStringArray()
	for k in 30:
		await get_tree().physics_frame
		y_min = minf(y_min, moka.global_position.y)
		if k % 6 == 0:
			tracce.append("%.3f" % moka.global_position.y)
	await get_tree().create_timer(1.0).timeout
	var sopra := Fornello.sotto_a(get_tree(), moka.global_position)
	_tempo.accelera(1.0)
	print("[fuochi] %s a x%.0f: dopo E in mano %s; quota nei primi 30 passi {%s}, minima %.3f; alla fine a %s, sul fuoco %s"
		% [f.name, scala, in_mano_dopo, ", ".join(tracce), y_min, _v(moka.global_position),
			String(sopra.name) if sopra != null else "nessuno"])
	if in_mano_dopo:
		_guasto("%s a x%.0f: il tasto E non l'ha posata" % [f.name, scala])
	elif sopra != f:
		_guasto("%s a x%.0f: la moka non è rimasta sul fuoco" % [f.name, scala])


## Il tasto vero, come arriva dalla tastiera: passa per `main.gd` e per i viewport prima di
## arrivare al giocatore.
func _tasto(k: Key) -> void:
	var giu := InputEventKey.new()
	giu.keycode = k
	giu.physical_keycode = k
	giu.pressed = true
	Input.parse_input_event(giu)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var su := InputEventKey.new()
	su.keycode = k
	su.physical_keycode = k
	su.pressed = false
	Input.parse_input_event(su)
	await get_tree().physics_frame


func _v(p: Vector3) -> String:
	return "%.2f, %.2f, %.2f" % [p.x, p.y, p.z]
