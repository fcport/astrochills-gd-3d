## IL FUNGO ROSSO STACCA DAVVERO TUTTO?
##
## LA DOMANDA, E PERCHE' NON E' OVVIA. Il quadro spegne le lampade che ha in
## elenco, e l'elenco lo scrive il generatore. Il difetto che questo impianto puo'
## avere e' uno solo, ed e' silenzioso: una lampada FUORI DALL'ELENCO. Resta accesa
## a corrente staccata, non da' nessun errore, e si nota solo passando davanti a
## quella stanza - cioe' magari mai.
##
## PERCIO' NON SI CONTROLLA L'ELENCO, SI CONTROLLA LA SCENA. La sonda cerca da sola
## OGNI luce dell'albero, di qualunque tipo e ovunque sia, e pretende che dopo lo
## scatto siano tutte spente. E' l'unico controllo che non si da' ragione da solo:
## chiedere al quadro se ha spento le lampade del quadro e' ricopiare la sua stessa
## lista in due posti.
##
## E SI CONTROLLA ANCHE IL RITORNO, che e' la meta' che di solito manca: riattaccando
## deve tornare accesa esattamente la roba che era accesa prima, non tutta e non
## niente.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_rete.tscn
extends Node

var _scena: Node
var _t := 0.0
var _fatto := false
var _guasti := 0


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_scena = scena


func _process(d: float) -> void:
	if _scena == null or _fatto:
		return
	_t += d
	if _t < 1.5:
		return
	_fatto = true
	_prova()
	get_tree().quit()


## LE TRE LUCI CHE NON SONO DELL'IMPIANTO, e restano accese per forza.
##
## Non e' una scorciatoia per far passare la prova: sono tre cose che la corrente
## dell'osservatorio non alimenta e non potrebbe. La LUNA e il CIELO stanno fuori
## dal contatore; la luce di PROSSIMITA' non e' una lampada affatto - e' l'aiuto
## di lettura che segue la testa del giocatore, e non ha un interruttore da
## nessuna parte. Ogni altra luce che sopravviva allo scatto e' un difetto.
const NON_DELL_IMPIANTO := ["Luna", "LuceCielo", "Prossimita"]


## Tutte le luci dell'albero che stanno FACENDO luce adesso.
##
## `visible_in_tree` E NON `visible`: il quadro spegne il nodo padre `Accesa`, non
## la `Light3D` che ci sta sotto. Guardando solo la luce si vedrebbe `visible =
## true` per sempre, e questa sonda direbbe che non si spegne mai niente.
func _accese(n: Node, fuori: Array[Light3D]) -> void:
	if (n is Light3D and (n as Light3D).is_visible_in_tree()
			and not NON_DELL_IMPIANTO.has(n.name)):
		fuori.append(n as Light3D)
	for f in n.get_children():
		_accese(f, fuori)


func _elenco() -> Array[Light3D]:
	var out: Array[Light3D] = []
	_accese(get_tree().root, out)
	return out


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[rete] GUASTO: " + msg)


## IL DITO CI ARRIVA? Un pulsante che il raggio del giocatore non trova e' un
## pulsante che non esiste, e non lo dice nessun errore: davanti al quadro non
## compare il prompt e basta. E' successo con il fungo - il bersaglio dell'anta gli
## stava davanti - e si e' visto solo mirandolo in uno scatto.
##
## SI TIRA IL RAGGIO VERO, dalla stessa quota e con la stessa portata di quello del
## giocatore, e si guarda CHI risponde per primo.
func _si_riesce_a_mirarlo(fungo: MainsButton) -> void:
	var da := fungo.global_position + Vector3(0.0, 0.24, 0.85)
	var q := PhysicsRayQueryParameters3D.create(da, fungo.global_position)
	q.collision_mask = Interactable.LAYER_INTERACTABLE
	var colpo := fungo.get_world_3d().direct_space_state.intersect_ray(q)
	if colpo.is_empty():
		_guasto("mirando il fungo il raggio non incontra nessun interagibile")
		return
	var chi: Node = colpo["collider"]
	print("[rete] mirando il fungo il raggio trova %s" % chi.name)
	if chi != fungo:
		_guasto("mirando il fungo si prende %s: il pulsante non e' premibile" % chi.name)


## L'ANTA SI APRE, E SI PORTA DIETRO QUELLO CHE HA SOPRA. Il fungo e' avvitato
## sulla lamiera: se aprendo il quadro resta dov'era, il bersaglio e il pezzo che
## si vede si sono separati - e il giocatore preme un pulsante che sullo schermo
## sta da un'altra parte.
func _l_anta_si_apre(fungo: MainsButton) -> void:
	var anta := PanelDoor.find_in(get_tree())
	if anta == null:
		_guasto("l'anta del quadro non si trova")
		return
	var prima := fungo.global_position
	anta.interact(Player.find_in(get_tree()))
	# Il motore gira a 220 gradi al secondo: mezzo secondo simulato basta e avanza.
	for _i in 40:
		anta._process(0.016)
	var corsa := prima.distance_to(fungo.global_position)
	print("[rete] aprendo il quadro il fungo si sposta di %.3f m (aperta = %s)"
		% [corsa, anta.aperta()])
	if not anta.aperta():
		_guasto("premendo l'anta il quadro non si apre")
	if corsa < 0.10:
		_guasto("il fungo non segue l'anta: resta piantato dov'era")
	# Si richiude: il resto della prova vuole il quadro com'era.
	anta.interact(Player.find_in(get_tree()))
	for _i in 40:
		anta._process(0.016)


func _prova() -> void:
	var quadro := Mains.find_in(get_tree())
	if quadro == null:
		print("[rete] il quadro non si trova: la prova non vale")
		return
	var fungo := MainsButton.find_in(get_tree())
	if fungo == null:
		print("[rete] il pulsante non si trova: la prova non vale")
		return
	var giocatore := Player.find_in(get_tree())

	_si_riesce_a_mirarlo(fungo)
	_l_anta_si_apre(fungo)

	var prima := _elenco()
	print("[rete] a corrente data: %d luci accese nella scena" % prima.size())
	if prima.size() < 5:
		print("[rete] SONDA CIECA: con cosi' poche luci accese non c'e' niente da "
			+ "spegnere, e questa prova passerebbe comunque")

	# SI PREME IL PULSANTE, non si chiama il quadro: fra il dito e la corrente c'e'
	# un interagibile, e se quel filo si stacca il gioco non risponde piu' — che e'
	# il difetto che si vuole vedere.
	fungo.interact(giocatore)
	var dopo := _elenco()
	print("[rete] a corrente staccata: %d luci accese" % dopo.size())
	for l in dopo:
		print("   resta accesa: %s" % l.get_path())
	if not dopo.is_empty():
		_guasto("%d luci non sono in elenco al quadro" % dopo.size())
	if quadro.acceso():
		_guasto("il quadro si dichiara ancora sotto tensione")

	fungo.interact(giocatore)
	var tornate := _elenco()
	print("[rete] a corrente ridata: %d luci accese" % tornate.size())
	if tornate.size() != prima.size():
		_guasto("tornando la corrente si riaccendono %d luci invece di %d"
			% [tornate.size(), prima.size()])
	for l in prima:
		if not tornate.has(l):
			_guasto("%s non si e' riaccesa" % l.name)

	if _guasti == 0:
		print("[rete] ok: il fungo stacca tutta la scena e la rimette com'era")
	else:
		print("[rete] GUASTO: %d controlli falliti" % _guasti)
