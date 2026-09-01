## QUANTO IN BASSO PUÒ GUARDARE QUESTO EDIFICIO.
##
## PERCHÉ ESISTE, E PERCHÉ NON È LA STESSA DOMANDA DI `prova_puntamento`. Quella
## chiede «la cupola sta dove serve»; questa chiede una cosa che la cupola non può
## risolvere in nessun modo: sotto una certa altezza il raggio del telescopio esce
## dalla fessura, scende, e trova la falda del tetto o il muro della sala. Non c'è
## azimut che aiuti — è l'orizzonte dell'EDIFICIO, e nasce dal fatto che
## l'apertura del tubo sta un metro e mezzo sotto il centro della sfera.
##
## SERVE AL TARGETING, e non è una curiosità architettonica: un bersaglio che
## culmina sotto questa linea non è fotografabile da questa cupola in nessun
## momento della notte. Il planetario che lo offrisse starebbe mentendo, e la
## bugia si scoprirebbe solo dopo il GOTO, con il tubo puntato contro l'intonaco.
##
## COME MISURA. Per ogni angolo orario si scende in declinazione un grado alla
## volta e si tira il raggio vero contro la geometria vera, con la calotta portata
## nel punto MIGLIORE possibile — cioè si misura il limite dell'edificio, non
## quello del motore. La calotta si gira scrivendole la rotazione invece di
## aspettare gli otto gradi al secondo: qui la domanda non è quanto ci mette.
##
## CONTRO L'EDIFICIO E NON CONTRO IL GUSCIO, e la differenza è la domanda stessa.
## Che la fessura si porti dove serve è già misurato altrove (`prova_puntamento`);
## qui si chiede se il raggio arriva ALLA cupola o se muore prima, contro la falda
## e i muri. Quindi al guscio non si dà nessun corpo e il raggio gli passa
## attraverso: quello che lo ferma, se lo ferma, è l'edificio.
##
## E LA CALOTTA NON SI TOCCA, che è anche l'unico modo perché la misura sia vera.
## Ruotarla e sparare nello stesso fotogramma dava «MAI LIBERO» su tutta la
## tabella: un corpo statico spostato da `_process` non esiste ancora per il
## motore fisico quando il raggio parte, quindi la lamiera era ferma dov'era e il
## raggio ci sbatteva sempre. Il guscio qui è un conto, non un oggetto:
## `azimut_di_uscita` dice se il raggio esce sopra la gronda, e ci vuole un solo
## numero.
extends Node

## La latitudine di Montegrimano. Sta in `tools/geometria.py`, e qui va ricopiata
## perché un file `.gd` non importa un `.py`: se cambia là, cambia qui.
const LATITUDINE := 43.9

## Gli angoli orari su cui si misura, in gradi. Est e ovest del meridiano: il tubo
## sta dalle due parti del pilastro, e l'apertura si sposta con lui.
const ANGOLI_ORARI := [-75.0, -60.0, -45.0, -30.0, -15.0, 0.0, 15.0, 30.0, 45.0, 60.0, 75.0]

## Da dove si comincia a scendere, e dove ci si ferma, in declinazione.
const DEC_ALTA := 85.0
const DEC_BASSA := -35.0
const PASSO := 1.0

## Quanto si aspetta prima di misurare: i battenti viaggiano a 0,30 di corsa al
## secondo, quindi tre secondi e mezzo, piu' margine.
const ATTESA_BATTENTI := 7.0

var _scena: Node
var _t := 0.0
var _fatto := false
var _aperto := false
var _spia := OS.get_environment("SPIA") == "1"
var _calotta: Node3D
var _cupola: DomeAzimuth


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
	# I BATTENTI CI METTONO IL LORO TEMPO, e misurare prima che si siano aperti
	# dava «MAI LIBERO» su tutta la tabella: il raggio sbatteva contro i portelli
	# ancora chiusi. `dome_shutter.gd` insegue l'apertura a 0,30 di corsa al
	# secondo, cioe' tre secondi e mezzo di viaggio.
	if _aperto:
		if _t < ATTESA_BATTENTI:
			return
	else:
		Events.dome_aperture_changed.emit(1.0)
		_aperto = true
		return
	_fatto = true
	var m := TelescopeMount.find_in(get_tree())
	_cupola = DomeAzimuth.find_in(get_tree())
	if m == null or _cupola == null:
		print("[orizzonte] manca la montatura o la cupola")
		get_tree().quit()
		return
	_calotta = _cupola.get_node_or_null(_cupola.calotta) as Node3D
	if _calotta == null:
		print("[orizzonte] la calotta non si trova: la prova non vale")
		get_tree().quit()
		return
	# QUANTO COSTEREBBE ALZARE LO STRUMENTO. Il limite di questo edificio nasce da
	# un rapporto: l'incrocio degli assi sta a 1,30 m e il foro del tetto a 3,20,
	# cioe' il telescopio guarda fuori da due metri sotto il proprio oblo'. Con
	# `ALZA=<metri>` si solleva il telescopio e si rimisura: serve a mettere un
	# numero sotto la domanda «e se il pilastro fosse piu' alto», invece di
	# discuterne.
	var alza := float(OS.get_environment("ALZA"))
	if alza > 0.0:
		# IL NODO DELLO STRUMENTO, non il padre del nodo che lo comanda: il
		# comando (`TelescopeMount`) e' fratello di `Osservatorio`, il telescopio
		# gli sta dentro. Alzando il padre sbagliato si alzava tutto il mondo, e
		# la tabella usciva identica per qualunque valore - il modo piu' silenzioso
		# di non misurare niente.
		var t := get_tree().root.find_child("Telescopio", true, false) as Node3D
		if t != null:
			t.position.y += alza
		else:
			print("[orizzonte] il telescopio non si trova: ALZA non ha fatto niente")
		print("[orizzonte] telescopio alzato di %.2f m" % alza)
	_misura(m)
	get_tree().quit()


## L'altezza sull'orizzonte di un puntamento, in gradi. Trigonometria sferica
## classica: è la stessa formula con cui si è tarato `AR_ZERO`, e serve solo a
## dare al referto un numero che si legge senza convertire.
func _altezza(ha: float, dec: float) -> float:
	var h := deg_to_rad(ha)
	var d := deg_to_rad(dec)
	var l := deg_to_rad(LATITUDINE)
	return rad_to_deg(asin(sin(d) * sin(l) + cos(d) * cos(l) * cos(h)))


func _misura(m: TelescopeMount) -> void:
	var limiti: Array[float] = []
	var righe: Array[String] = []
	for ha in ANGOLI_ORARI:
		var dec := DEC_ALTA
		var ultimo_libero := NAN
		while dec >= DEC_BASSA:
			if not _passa(m, ha, dec):
				break
			ultimo_libero = dec
			dec -= PASSO
		if is_nan(ultimo_libero):
			righe.append("  AR %+5.0f   MAI LIBERO" % ha)
			continue
		var alt := _altezza(ha, ultimo_libero)
		limiti.append(alt)
		righe.append("  AR %+5.0f   scende fino a dec %+5.1f  =  %5.1f gradi di altezza"
			% [ha, ultimo_libero, alt])
	print("[orizzonte] l'edificio non vede sotto queste altezze:")
	for r in righe:
		print(r)
	if limiti.is_empty():
		print("[orizzonte] SONDA CIECA: nessun puntamento e' mai uscito")
		return
	var peggiore := limiti[0]
	var migliore := limiti[0]
	var somma := 0.0
	for v in limiti:
		peggiore = maxf(peggiore, v)
		migliore = minf(migliore, v)
		somma += v
	print("[orizzonte] limite: %.1f gradi nel punto migliore, %.1f nel peggiore, %.1f in media"
		% [migliore, peggiore, somma / limiti.size()])
	# LA SONDA DEVE POTER FALLIRE. Se il raggio uscisse sempre, il limite migliore
	# sarebbe zero e questo referto non starebbe misurando niente — che e' esattamente
	# come questa famiglia di sonde ha gia' mentito una volta (D-189).
	if migliore <= 1.0:
		print("[orizzonte] SONDA CIECA: il raggio esce anche all'orizzonte, "
			+ "quindi il guscio non lo sta fermando")


## Porta il tubo li', mette la calotta nel punto migliore possibile, e spara.
func _passa(m: TelescopeMount, ha: float, dec: float) -> bool:
	# NIENTE RAMPA: si scrivono gli angoli e si legge subito. `punta()` muove a
	# dodici gradi al secondo, e qui i puntamenti sono milleduecento.
	m.piazza(ha, dec)
	var da := m.apertura()
	var verso := m.direzione()
	# PRIMA IL CONTO: il raggio esce dalla sfera sopra la gronda, o sotto? Sotto,
	# la cupola non c'e' proprio e nessun azimut aiuta.
	if is_nan(DomeAzimuth.azimut_di_uscita(da, verso, _calotta.global_position,
			_cupola.raggio)):
		return false
	# POI IL RAGGIO VERO, contro l'edificio: puo' uscire dalla sfera sopra la
	# gronda e morire lo stesso contro la falda che gli sta davanti.
	var q := PhysicsRayQueryParameters3D.create(da, da + verso * 5.0)
	q.collision_mask = 1
	q.exclude = [Player.find_in(get_tree()).get_rid()]
	var colpo := m.get_world_3d().direct_space_state.intersect_ray(q)
	if _spia and not colpo.is_empty():
		print("  [spia] AR %+.0f dec %+.0f  colpisce %s"
			% [ha, dec, colpo["collider"].name])
	return colpo.is_empty()
