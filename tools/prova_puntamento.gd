## IL TELESCOPIO GUARDA FUORI, O GUARDA IL GUSCIO.
##
## PERCHÉ ESISTE. La cupola che insegue il telescopio è la cosa più facile da fare
## in modo che SEMBRI giusta: la calotta gira, il tubo si muove, l'occhio è
## contento, e il raggio esce venticinque gradi fuori dalla fessura senza che nessuno
## se ne accorga — perché da dentro la cupola non si vede il proprio raggio. È
## esattamente il caso in cui guardare non serve a niente e misurare serve a tutto.
##
## COSA MISURA, E PERCHÉ QUESTA E NON ALTRO. Non «la cupola ha girato» (girerebbe
## anche col conto sbagliato) e non «l'azimut è quello atteso» (sarebbe il mio
## stesso conto ricopiato in due posti, cioè un controllo che si dà ragione da solo).
## Si misura la SOLA cosa che conta davvero: si prende il punto in cui il raggio del
## telescopio incontra la sfera della cupola, e si chiede se lì il guscio c'è o non
## c'è — tirando un raggio fisico contro la geometria della calotta. Se lo colpisce,
## il telescopio sta guardando la lamiera.
##
## E SI CONTROLLA ANCHE IL CONTRARIO, che è la metà che di solito manca: con la
## cupola BLOCCATA, gli stessi puntamenti devono essere quasi tutti ostruiti. Un
## controllo che dice sempre «passa» non distingue un inseguimento che funziona da
## una collisione che non rileva niente, e questa sonda comincia proprio così — se
## il difetto iniettato non la fa fallire, la sonda è la prima cosa da riparare.
extends Node

## Quanti secondi si lascia al motore della cupola per arrivare, per puntamento.
## Otto gradi al secondo e mezzo giro possibile: venticinque secondi bastano.
const ATTESA := 26.0

## I puntamenti di prova, in angolo orario e declinazione (gradi).
##
## SCELTI PER COPRIRE I CASI CHE ROMPONO, non per fare numero: est e ovest del
## meridiano (cioè il tubo dalle due parti del pilastro, che è il ribaltamento e
## l'ottanta per cento del problema), alto e basso, e il polo — dove l'azimut non
## è definito e un conto ingenuo divide per zero.
## LE PRIME OTTO ERANO INUTILI, e la sonda stessa l'ha detto: col difetto iniettato
## - la cupola bloccata - passavano identiche, cioè non misuravano l'inseguimento.
## La ragione è geometrica e vale la pena saperla: la fenditura si ALLARGA salendo
## (1,60 m in basso, 2,40 allo zenit) e i due portelli, aperti, si accavallano oltre
## lo zenit. Attorno alla verticale c'è quindi un buco largo sessanta gradi, e
## qualunque puntamento alto esce comunque - con la cupola girata bene o girata male.
##
## Le pose che contano sono quelle a MEZZA ALTEZZA e sparse in azimut: lì l'uscita
## cade dove la fenditura è stretta e un errore di dieci gradi si paga. Restano un
## paio di pose alte e un paio basse, che servono a coprire i due estremi.
const POSE := [
	Vector2(-60.0, 60.0), Vector2(60.0, 60.0),
	Vector2(-45.0, 50.0), Vector2(45.0, 50.0),
	Vector2(-20.0, 45.0), Vector2(20.0, 45.0),
	Vector2(-30.0, 70.0), Vector2(30.0, 70.0),
	Vector2(0.0, 40.0), Vector2(0.0, 85.0),
	Vector2(-90.0, 45.0), Vector2(90.0, 45.0),
]

var _scena: Node
var _i := -1
var _t := 0.0
var _attesa := 0.0
var _esiti: Array[String] = []
var _passati := 0
var _bassi := 0
var _guasti := 0
var _bloccata := false
var _finito := false


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_scena = scena


func _process(d: float) -> void:
	if _scena == null or _finito:
		return
	_t += d
	if _t < 1.5:
		return
	var m := TelescopeMount.find_in(get_tree())
	var c := DomeAzimuth.find_in(get_tree())
	if m == null or c == null:
		print("[puntamento] manca la montatura o la cupola")
		_fine()
		return
	if _i < 0:
		_bloccata = OS.get_environment("BLOCCATA") == "1"
		if _bloccata:
			# IL DIFETTO INIETTATO: la cupola non si muove. Se anche così i raggi
			# escono, questa sonda non sta misurando niente.
			c.set_process(false)
			print("[puntamento] CUPOLA BLOCCATA: quasi tutti i puntamenti devono essere ostruiti")
		# La cupola va aperta, o la fessura non c'è: si annuncia il fatto sul bus,
		# come farebbe la fase.
		Events.dome_aperture_changed.emit(1.0)
		_il_bus_muove_il_tubo(m)
		_dai_un_corpo_al_guscio()
		_prossima(m)
		return

	_attesa += d
	# Si aspetta che TUTTI E DUE siano fermi: il telescopio che arriva prima della
	# cupola darebbe un raggio contro il guscio che è solo ritardo, non errore.
	if _attesa < ATTESA and (m.in_moto() or c.in_moto()):
		return
	_giudica(m, c)
	_prossima(m)


func _prossima(m: TelescopeMount) -> void:
	_i += 1
	if _i >= POSE.size():
		_referto()
		return
	m.punta(POSE[_i].x, POSE[_i].y)
	_attesa = 0.0


## IL FILO FRA LE FASI E IL FERRO ESISTE? Si tira, e si guarda.
##
## Le fasi del puntamento vivono in `phases/`, che non puo' nominare `world/`:
## dicono sul bus dove hanno mandato il tubo e sperano che qualcuno le ascolti.
## Se quel collegamento si stacca — un rename, un `connect` tolto — non succede
## NIENTE di visibile: nessun errore, nessun avviso, solo un telescopio che non si
## muove piu' mentre lo schermo dice che sta puntando. E' il difetto piu'
## silenzioso di tutto questo strato, e costa tre righe controllarlo.
## SI GUARDA `in_moto()` E NON `dove()`, ed e' la seconda volta che questa
## distinzione morde: il bus porta un COMANDO, e `dove()` dice dove il tubo si
## trova ADESSO. Nel fotogramma dell'emissione i due sono ancora diversi — il
## motore non ha fatto un grado — e la prima stesura di questo controllo gridava
## «il bus non muove il tubo» su un collegamento perfettamente sano.
func _il_bus_muove_il_tubo(m: TelescopeMount) -> void:
	var prima := m.dove()
	Events.telescope_aim_changed.emit(prima.x + 30.0, prima.y - 10.0)
	if not m.in_moto():
		print("[puntamento] il bus non muove il tubo: `telescope_aim_changed` "
			+ "non arriva alla montatura")
		_guasti += 1
	else:
		print("[puntamento] ok: il bus muove il tubo")
	m.piazza(prima.x, prima.y)


## IL GUSCIO NON HA COLLISIONE, e senza questa funzione questa sonda non misura
## niente. La calotta e i portelli arrivano dal `.glb` come sole `MeshInstance3D`:
## in gioco nessuno ci sbatte contro, quindi nessuno gli ha mai dato un corpo. Il
## raggio del telescopio ci passava attraverso come se la cupola non ci fosse, e il
## referto diceva «nessun puntamento guarda il guscio» perché il guscio, per la
## fisica, NON ESISTE. Se ne è accorto solo il controllo col difetto iniettato: a
## cupola bloccata passavano tutte e dodici le pose.
##
## Qui il corpo glielo si dà, per la durata della prova, con la MESH VERA
## (`create_trimesh_shape`) e non con una sfera approssimata: la fenditura si
## allarga salendo e i portelli si accavallano oltre lo zenit, e una sfera con un
## buco parametrico sarebbe il mio stesso conto ricopiato — cioè un controllo che si
## dà ragione da solo.
func _dai_un_corpo_al_guscio() -> void:
	for nome in ["Calotta", "PortelloAlto", "PortelloBasso"]:
		var m := get_tree().root.find_child(nome, true, false) as MeshInstance3D
		if m == null:
			print("[puntamento] manca %s: la prova non vale" % nome)
			continue
		var b := StaticBody3D.new()
		b.name = "Guscio" + nome
		b.collision_layer = 1
		b.collision_mask = 0
		var c := CollisionShape3D.new()
		c.shape = m.mesh.create_trimesh_shape()
		b.add_child(c)
		m.add_child(b)


## Il raggio esce, o incontra il guscio? Si tira davvero, contro la geometria vera.
func _giudica(m: TelescopeMount, c: DomeAzimuth) -> void:
	var posa: Vector2 = POSE[_i]
	var da := m.apertura()
	var verso := m.direzione()
	var alt := rad_to_deg(asin(verso.y))
	# Cinque metri: la sfera ha raggio 2,50 e l'apertura ci sta dentro, quindi
	# qualunque uscita cade entro cinque metri.
	var q := PhysicsRayQueryParameters3D.create(da, da + verso * 5.0)
	q.collision_mask = 1
	q.exclude = [Player.find_in(get_tree()).get_rid()]
	var colpo := m.get_world_3d().direct_space_state.intersect_ray(q)
	var chi := "" if colpo.is_empty() else String(colpo["collider"].name)
	# DUE ESITI DIVERSI, E CONFONDERLI FALSAVA IL REFERTO. Se il raggio incontra la
	# CALOTTA o un PORTELLO, la cupola non ha fatto il suo mestiere: e' un guasto.
	# Se incontra un muro, il soffitto o la falda, il telescopio sta puntando sotto
	# la linea di gronda — dove la cupola non c'e' e non puo' aiutare. Quello non e'
	# un guasto: e' l'orizzonte di questo edificio, ed e' un dato di progetto che il
	# targeting dovra' conoscere.
	var guscio := chi.begins_with("Guscio")
	var esito := "LIBERO"
	if guscio:
		esito = "CONTRO LA CUPOLA"
		_guasti += 1
	elif chi != "":
		esito = "sotto la gronda (%s)" % chi
		_bassi += 1
	else:
		_passati += 1
	_esiti.append("  AR %+5.0f  dec %+3.0f  ->  alt %+5.1f  cupola a %+6.1f (err %.1f)  %s"
		% [posa.x, posa.y, alt, c.azimut(), c.errore(), esito])


func _referto() -> void:
	_finito = true
	print("[puntamento] %d pose: %d libere, %d sotto la gronda, %d contro la cupola"
		% [POSE.size(), _passati, _bassi, _guasti])
	for r in _esiti:
		print(r)
	if _bloccata:
		if _guasti < 3:
			print("[puntamento] SONDA CIECA: a cupola ferma solo %d pose finiscono "
				% _guasti + "contro il guscio, quindi non sto misurando l'inseguimento")
		else:
			print("[puntamento] ok: a cupola ferma %d pose sbattono sul guscio, "
				% _guasti + "la sonda vede la differenza")
	elif _guasti == 0:
		print("[puntamento] ok: nessun puntamento guarda il guscio; "
			+ "le %d pose basse sono l'orizzonte dell'edificio, non un difetto" % _bassi)
	else:
		print("[puntamento] GUASTO: %d pose guardano il guscio" % _guasti)
	_fine()


func _fine() -> void:
	_finito = true
	get_tree().quit()
