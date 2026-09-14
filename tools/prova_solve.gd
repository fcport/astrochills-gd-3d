## «SLEWING» AL PRIMO TASTO IN SOLVE?
##
## Federico: «il primo movimento che faccio mi dice slewing e poi non lo dice più». Il
## lampeggio del D-198 è curato, ed è un'altra cosa: quello era la montatura che non sapeva
## se stava viaggiando. Qui la montatura lo sa benissimo — le arriva un comando lontano.
##
## IL SOSPETTO, da confermare prima di curare. La stella di taratura ha un angolo orario
## fisso, mentre la montatura nel mondo insegue il cielo. Fermi a guardare, il tubo gira
## col cielo; il primo tasto rimanda la fase al suo angolo di partenza, e dopo qualche
## secondo la differenza supera il mezzo grado che accende la scritta.
##
## LE DOMANDE, con la fase SOLVE vera sulla montatura vera:
##   1. il GOTO sulla stella accende e spegne la scritta una volta
##   2. fermi a guardare per qualche secondo, la scritta non si accende
##   3. il primo tasto dopo l'attesa non la accende
##   4. e il tubo, dopo il tasto, è ancora sulla stella che il cielo ha portato avanti
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_solve.tscn
extends Node

## Quanto si sta fermi prima del primo tasto, in secondi. Il cielo gira di 0,15 gradi al
## secondo vero: otto secondi sono più del doppio della soglia di partenza.
const FERMI := 8.0

var _cambi := 0
var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[solve] GUASTO: " + msg)


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 60:
		await get_tree().physics_frame
	var m := TelescopeMount.find_in(get_tree())
	if m == null or Game.run == null:
		print("[solve] manca la montatura o la notte: la prova non vale")
		get_tree().quit(1)
		return
	Events.telescope_slewing_changed.connect(func(_v: bool) -> void: _cambi += 1)

	var fase: PhaseSync = (load("res://phases/sync/phase_sync.tscn") as PackedScene).instantiate()
	if fase.truth == null:
		fase.truth = load("res://phases/sync/sources/honest_star.tres")
	fase.setup(Game.run, {})
	get_tree().root.add_child(fase)

	# --- 1. IL GOTO SULLA STELLA ---------------------------------------------
	var arrivata := await _aspetta(func() -> bool: return _cambi >= 2 and not m.in_moto(), 30.0)
	print("[solve] GOTO sulla stella: %d cambi di stato, arrivata %s, tubo a %s"
		% [_cambi, arrivata, m.dove()])
	if not arrivata:
		_guasto("il GOTO sulla stella non si accende o non arriva")
		_fine()
		return

	# --- 2. FERMI A GUARDARE -------------------------------------------------
	_cambi = 0
	var prima := m.dove()
	var minuti_prima := Game.run.elapsed_min
	await get_tree().create_timer(FERMI).timeout
	var girato := m.dove().x - prima.x
	print("[solve] fermi %.0f s: la notte avanza di %.2f minuti, il tubo insegue di %.2f gradi, %d cambi"
		% [FERMI, Game.run.elapsed_min - minuti_prima, girato, _cambi])
	if _cambi > 0:
		_guasto("stando fermi la scritta si accende")

	# --- 3. IL PRIMO TASTO ---------------------------------------------------
	_cambi = 0
	var prima_del_tasto := m.dove()
	Input.action_press(&"aim_right")
	await get_tree().create_timer(0.3).timeout
	Input.action_release(&"aim_right")
	await get_tree().create_timer(2.0).timeout
	print("[solve] un tasto di tre decimi: %d cambi; il tubo da %s a %s"
		% [_cambi, prima_del_tasto, m.dove()])
	if _cambi > 0:
		_guasto("il primo tasto dopo %.0f s di attesa accende SLEWING" % FERMI)
	else:
		print("[solve] ok: il primo tasto non accende la scritta")

	# --- 4. IL TUBO È ANCORA DOVE IL CIELO L'HA PORTATO ------------------------
	#
	# Il tasto sposta di un decimo e mezzo di grado verso destra; tornare indietro di
	# quanto il cielo è girato vorrebbe dire il tubo lontano dalla stella di un grado.
	var indietro := prima_del_tasto.x - m.dove().x
	if indietro > 0.3:
		_guasto("dopo il tasto il tubo è tornato indietro di %.2f gradi: ha perso il cielo" % indietro)
	_fine()


func _fine() -> void:
	Input.action_release(&"aim_right")
	print("[solve] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


func _aspetta(condizione: Callable, secondi: float) -> bool:
	var fine := Time.get_ticks_msec() + int(secondi * 1000.0)
	while Time.get_ticks_msec() < fine:
		if condizione.call():
			return true
		await get_tree().process_frame
	return condizione.call()
