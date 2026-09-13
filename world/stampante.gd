## La stampante della sala di controllo, quando stampa: le foto escono da qui.
##
## NON È LA MACCHINA CHE SI VEDE. Quella è la Okidata dentro `controllo_pc.glb`, posata
## da `tools/arredi_blender.py`, e resta arredo. Questo nodo è la FESSURA: sta dove esce
## la carta, sa quando c'è da stampare, e tiene il registro di tutte le stampe che girano
## per l'osservatorio.
##
## STAMPA DA SOLA, A FOTO EMERSA. È la richiesta di Federico (D-239): «quando una foto
## finisce di essere renderizzata in automatico parte una stampa». Il fatto arriva da
## `night/` sul bus (`Events.photo_revealed`), perché il mondo non può nominare la notte
## e la notte non può nominare il mondo.
##
## UNA ALLA VOLTA, come una stampante vera. Due foto rivelate di fila fanno due stampe in
## fila; e quando comincia la seconda, la prima — se nessuno l'ha strappata — si stacca e
## cade: il modulo continuo la spingerebbe fuori comunque.
##
## IL REGISTRO È DEL GIOCATORE (`PlayerProfile.photo_prints`): una foto appesa stanotte è ancora
## appesa domani, e dopo un riavvio. Lo scrive questo nodo; il disco lo tocca `Game`,
## perché il mondo non conosce `SaveManager`.
class_name Stampante
extends Node3D

const GRUPPO := &"stampante"

## Quanto ci mette una pagina a uscire, in secondi di gioco. Una ML320 in grafica ci
## mette minuti; qui venti, perché la foto la si va a prendere appena vista sul monitor, e
## una stampa che arriva quando si è già tornati al lavoro non la guarda nessuno. Segue
## `Engine.time_scale`, quindi F1-F4 la accelerano. Si tara guardando.
@export var secondi := 20.0

## Dove esce la carta, rispetto a questo nodo, che sta al centro della carrozza sul piano
## del mobile. L'ALTEZZA NON SI SCRIVE: la misura `_misura_fessura()` guardando la
## macchina, così il giorno che il modello cambia la carta esce ancora da lei.
@export var fessura := Vector3(0.0, 0.0, -0.03)

## Di quanto pende all'indietro il foglio che esce, verso il muro.
@export var pendenza_gradi := 15.0

## Quanto si aspetta dall'ultimo cambiamento prima di scrivere il registro. Una stampa
## lasciata cadere rimbalza e rotola: scriverla subito vorrebbe dire ricordarla a
## mezz'aria, e scriverla a ogni rimbalzo vorrebbe dire dieci salvataggi per un gesto.
const ATTESA_SALVATAGGIO := 1.5

## Le foto rivelate che aspettano il loro turno.
var _coda: Array[Dictionary] = []
var _in_stampa: Stampa = null
## L'ultima uscita, finché nessuno l'ha strappata.
var _attaccata: Stampa = null
var _tempo := 0.0
var _uscita := Transform3D.IDENTITY
var _pronta := false
var _salvataggio: Timer


static func find_in(tree: SceneTree) -> Stampante:
	return tree.get_first_node_in_group(GRUPPO) as Stampante


func _ready() -> void:
	add_to_group(GRUPPO)
	Events.photo_revealed.connect(_su_foto_rivelata)
	_salvataggio = Timer.new()
	_salvataggio.one_shot = true
	_salvataggio.timeout.connect(_salva)
	add_child(_salvataggio)
	_avvia.call_deferred()


## SI ASPETTANO DUE PASSI DI FISICA, e non per scrupolo. La corazza si costruisce anche lei
## differita, e i suoi corpi entrano nello spazio fisico al passo dopo: prima di allora la
## stampante non si vede — la fessura si misurerebbe sul piano del mobile — e una stampa
## di ieri rimessa per terra cadrebbe attraverso un pavimento che per il motore non c'è
## ancora.
func _avvia() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_misura_fessura()
	ripristina(Game.profile.photo_prints)
	_pronta = true
	_prossima()


## LA FESSURA STA SULLA MACCHINA: si scende dall'alto finché si tocca, sulla geometria che
## si vede. Si parte trenta centimetri sopra il piano e non di più: sopra la stampante c'è
## il davanzale della finestra nord, e partendo da lassù la carta uscirebbe dal davanzale.
func _misura_fessura() -> void:
	var punto := to_global(fessura)
	var giu := PhysicsRayQueryParameters3D.create(punto + Vector3.UP * 0.30,
		punto - Vector3.UP * 0.05, Corazza.LAYER_APPOGGI)
	var colpo := get_world_3d().direct_space_state.intersect_ray(giu)
	if colpo.is_empty():
		Log.warn("stampa", "sopra %s non c'è la stampante: la carta esce dal piano" % punto)
	else:
		punto = colpo["position"]
	_uscita = Transform3D(global_basis * Basis(Vector3.RIGHT, -deg_to_rad(pendenza_gradi)), punto)


func _su_foto_rivelata(photo_id: int, target_id: StringName, image_tier: int) -> void:
	_coda.append({
		&"target": target_id, &"livello": image_tier,
		&"notte": Game.run.night_index if Game.run != null else 0, &"foto": photo_id,
	})
	_prossima()


func _prossima() -> void:
	if not _pronta or _in_stampa != null:
		return
	while not _coda.is_empty():
		var voce: Dictionary = _coda.pop_front()
		var s := Stampa.crea(voce[&"target"], voce[&"livello"], voce[&"notte"], voce[&"foto"])
		if s == null:
			Log.info("stampa", "nessuna pagina per «%s» al livello %d: la foto non si stampa"
				% [voce[&"target"], voce[&"livello"]])
			continue
		if _attaccata != null and is_instance_valid(_attaccata):
			_attaccata.stacca_dalla_stampante()
		_attaccata = null
		s.mondo = get_parent()
		get_parent().add_child(s, true)
		s.inizia_stampa()
		_collega(s)
		_in_stampa = s
		_tempo = 0.0
		_esci()
		Log.info("stampa", "comincia a stampare %s" % s.nome)
		return


func _process(delta: float) -> void:
	if _in_stampa == null:
		return
	if not is_instance_valid(_in_stampa):
		_in_stampa = null
		_prossima()
		return
	_tempo += delta
	_esci()
	if _tempo >= secondi:
		_in_stampa.finisci_stampa()
		_attaccata = _in_stampa
		_in_stampa = null
		_prossima()


## Il foglio in stampa sta con il bordo basso sulla fessura, e sale man mano che esce.
func _esci() -> void:
	var f := clampf(_tempo / maxf(secondi, 0.001), 0.0, 1.0)
	_in_stampa.esci(f)
	_in_stampa.global_transform = Transform3D(_uscita.basis,
		_uscita.origin + _uscita.basis.y * Stampa.ALTEZZA * (f - 0.5))


## Rimette al mondo le stampe del registro: appese dove erano appese, le altre dove erano.
##
## UNA COSA APPESA A CIÒ CHE NON C'È PIÙ resta dov'era, ferma. Il muro può essere sparito
## da un modello rifatto; farla cadere per terra direbbe «si è staccata», e non è vero.
func ripristina(voci: Array) -> void:
	var radice := get_parent()
	for v: Dictionary in voci:
		var s := Stampa.crea(StringName(v.get(&"target", &"")), int(v.get(&"livello", 1)),
			int(v.get(&"notte", 0)), int(v.get(&"foto", 0)))
		if s == null:
			continue
		s.mondo = radice
		var xf: Transform3D = v.get(&"xf", Transform3D.IDENTITY)
		if bool(v.get(&"appesa", false)):
			var su := radice.get_node_or_null(NodePath(String(v.get(&"su", "")))) as Node3D
			if su != null and v.has(&"xf_su"):
				s.appendi(su, su.global_transform * (v[&"xf_su"] as Transform3D), false)
			else:
				s.appendi(radice as Node3D, xf, false)
		else:
			radice.add_child(s, true)
			s.global_transform = xf
		_collega(s)
	if not voci.is_empty():
		Log.info("stampa", "%d stampe rimesse al loro posto" % voci.size())


func _collega(s: Stampa) -> void:
	if not s.cambiata.is_connected(_salva_presto):
		s.cambiata.connect(_salva_presto)


func _salva_presto() -> void:
	_salvataggio.start(ATTESA_SALVATAGGIO)


## Il registro si riscrive intero dalle stampe che esistono: una lista tenuta a parte e
## aggiornata a mano diverge alla prima stampa che nessuno aveva previsto.
func _salva() -> void:
	var voci: Array[Dictionary] = []
	for n in get_tree().get_nodes_in_group(Stampa.GRUPPO):
		var s := n as Stampa
		if s == null or s.is_queued_for_deletion():
			continue
		voci.append(s.ricordo(get_parent()))
	Game.save_prints(voci)
