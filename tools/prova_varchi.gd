## UNA PORTA APERTA DEVE LASCIAR PASSARE ANCHE QUELLO CHE SI HA IN MANO.
##
## IL DIFETTO, E PERCHE' NESSUNA PROVA LO VEDEVA. In questa scena il mondo ha due
## collisioni: gli INGOMBRI, blocchi grezzi su cui cammina il giocatore, e gli
## APPOGGI, la geometria vera a triangoli con cui collide la roba che si prende in
## mano (vedi `world/corazza.gd`). La corazza si costruiva copiando la posizione
## delle mesh AL MOMENTO DELL'AVVIO, quando le porte sono chiuse: da li' in poi
## nel vano di ogni porta restava la sagoma dell'anta chiusa, ferma per sempre.
##
## Il giocatore non poteva accorgersene - lui cammina sugli ingombri, dove il vano
## e' aperto - ma la borraccia che teneva in mano sbatteva contro un'anta che non
## c'era piu'. In partita si legge come «un muro invisibile sulla porta».
##
## COSA MISURA. Apre tutte le porte e tira un raggio nel centro esatto di ogni
## vano - il centro e' preso PRIMA di aprire, dalla mesh dell'anta chiusa, che e'
## per definizione il buco che l'anta riempie - e lo fa su tutti e due i mondi:
## sugli ingombri deve essere libero, e sugli appoggi pure. Le ante dei MOBILI non
## si contano: dietro un pensile c'e' il pensile, ed e' giusto che il raggio ci
## sbatta.
##
## IL DIFETTO SI RIMETTE con `CORAZZA_FERMA=1`, che riporta la corazza al corpo
## unico congelato. Serve a dimostrare che questa prova sa vedere: senza, un
## banco che dice sempre «va bene» non distingue un mondo sano da uno rotto.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_varchi.tscn
##     CORAZZA_FERMA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_varchi.tscn
extends Node

## Quanto lungo e' il raggio da una parte e dall'altra del piano dell'anta: mezzo
## metro basta a passare lo spessore di un muro e non arriva ai mobili di la'.
const MEZZO_VARCO := 0.45

## L'altezza a cui si guarda non conta: il raggio parte dal CENTRO della mesh
## dell'anta, che e' a mezza porta. E' li' che passa quello che si ha in mano.
var _scena: Node
var _guasti := 0


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[varchi] GUASTO: " + msg)


func _tick() -> void:
	await get_tree().physics_frame


func _porte(n: Node, fuori: Array) -> void:
	if n is Door:
		fuori.append(n)
	for f in n.get_children():
		_porte(f, fuori)


func _mesh(n: Node, fuori: Array) -> void:
	if n is MeshInstance3D:
		fuori.append(n)
	for f in n.get_children():
		_mesh(f, fuori)


## Il centro del buco che l'anta riempie: la media dei centri delle sue mesh,
## presa mentre e' ancora chiusa.
func _centro(d: Node3D) -> Vector3:
	var ms: Array = []
	_mesh(d, ms)
	if ms.is_empty():
		return d.global_position
	var somma := Vector3.ZERO
	for m in ms:
		var mi := m as MeshInstance3D
		somma += mi.global_transform * mi.get_aabb().get_center()
	return somma / ms.size()


func _ostruito(spazio: PhysicsDirectSpaceState3D, centro: Vector3,
		normale: Vector3, strato: int) -> bool:
	var q := PhysicsRayQueryParameters3D.create(centro - normale * MEZZO_VARCO,
		centro + normale * MEZZO_VARCO)
	q.collision_mask = strato
	return not spazio.intersect_ray(q).is_empty()


func _prova() -> void:
	_scena = load("res://world/blockout.tscn").instantiate()
	get_tree().root.add_child(_scena)
	get_tree().current_scene = _scena
	for _i in 12:
		await _tick()

	var tutte: Array = []
	_porte(_scena, tutte)
	# SOLO LE PORTE, non le ante dei mobili: dietro un pensile c'e' il pensile.
	var porte: Array = []
	for p in tutte:
		if String((p as Node3D).name).begins_with("Porta_"):
			porte.append(p)
	if porte.size() < 5:
		print("[varchi] trovate %d porte: la prova non vale" % porte.size())
		get_tree().quit(1)
		return

	var vani := {}
	for p in porte:
		vani[p] = [_centro(p as Node3D), (p as Node3D).global_transform.basis.z]
		(p as Door).set_open(true, true)
	for _i in 30:
		await _tick()

	var difetto := OS.get_environment("CORAZZA_FERMA") == "1"
	var spazio := (_scena as Node3D).get_world_3d().direct_space_state
	var murate := 0
	for p in porte:
		var nome := String((p as Node3D).name)
		var centro: Vector3 = vani[p][0]
		var normale: Vector3 = vani[p][1]
		var ingombri := _ostruito(spazio, centro, normale, 1)
		var appoggi := _ostruito(spazio, centro, normale, Corazza.LAYER_APPOGGI)
		if appoggi:
			murate += 1
		print("[varchi] %-26s ingombri %s, appoggi %s"
			% [nome, "OSTRUITI" if ingombri else "liberi",
			   "OSTRUITI" if appoggi else "liberi"])
		if difetto:
			continue
		if ingombri:
			_guasto("%s aperta, ma il vano e' chiuso per il giocatore" % nome)
		if appoggi:
			_guasto("%s aperta, ma il vano e' chiuso per quello che si ha in "
				% nome + "mano: e' il muro invisibile")

	# SONDA CIECA: col difetto rimesso i vani DEVONO risultare murati. Se non lo
	# sono, questa prova sta guardando un mondo dove il difetto non c'e' - e allora
	# il suo «va bene» di prima non vuol dire niente.
	if difetto:
		print("[varchi] col difetto rimesso: %d vani su %d murati sugli appoggi"
			% [murate, porte.size()])
		if murate < porte.size():
			_guasto("SONDA CIECA: col difetto rimesso solo %d vani su %d "
				% [murate, porte.size()] + "risultano murati")

	if _guasti > 0:
		print("[varchi] GUASTO: %d controlli falliti" % _guasti)
		get_tree().quit(1)
		return
	print("[varchi] ok: da ogni porta aperta passa anche quello che si ha in mano")
	get_tree().quit(0)
