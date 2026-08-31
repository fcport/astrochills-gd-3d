## La lampada che il giocatore si porta addosso, e che ESISTE SOLO DOVE È BUIO.
##
## Da sola era già utile e già sbagliata: al buio svela quello che sfiori — è tutto
## il suo mestiere — ma accesa la plafoniera continuava a lavorare, e allora la si
## vedeva. Ci si avvicina a una parete illuminata e compare un alone che ti segue,
## che è il modo più veloce di ricordare a chi gioca che sta guardando un motore
## grafico. In una stanza accesa si deve vedere la stanza, non la propria luce
## riflessa addosso alle cose.
##
## COME SI DECIDE SE È BUIO. Non si legge lo schermo: la luminosità dell'inquadratura
## dipende da dove guardi, e girando la testa la lampada si accenderebbe e
## spegnerebbe da sola. Si CHIEDE ALLE LAMPADE, che è un conto esatto e costa
## niente: per ognuna, quanta ne arriva qui — energia per la sua curva di caduta —
## e se da qui la si vede davvero. Il raggio è la metà che conta: una plafoniera
## accesa nella stanza accanto non illumina questa, e senza quel controllo il
## corridoio acceso avrebbe spento la lampada dentro il magazzino chiuso.
##
## LA LUNA È UNA DIREZIONALE e vale lo stesso ragionamento al contrario: illumina
## ovunque, quindi la domanda è se da qui si vede il cielo. Un raggio verso la sua
## direzione, e se incontra il tetto sei al chiuso.
##
## E CI METTE, SALENDO. Il conto si rifà dieci volte al secondo, ma l'energia ci
## arriva scorrendo, e in salita ci mette MEZZO MINUTO: è il tempo in cui un occhio
## si abitua al buio, anzi molto meno del vero. Entrando in una stanza spenta non si
## vede subito quel che si ha accanto — lo si vede emergere. In discesa un quarto di
## secondo,
## perché all'abbagliamento ci si adatta subito, e perché una lampada che ci
## mettesse tre secondi a spegnersi lascerebbe vedere il proprio alone entrando in
## una stanza accesa.
class_name LuceProssimita
extends OmniLight3D

## Sotto questo illuminamento la lampada va al massimo: è buio, serve tutta.
## L'unità è quella delle energie di Godot sommate, quindi ha senso solo confrontata
## con le lampade di questa scena — una plafoniera dell'osservatorio vale 2,1 con
## caduta 0,85 su undici metri, cioè circa 1,7 standoci sotto.
const BUIO := 0.06

## Sopra questo la lampada è spenta del tutto: qui la stanza è illuminata e la
## propria luce sarebbe solo un alone che segue la testa.
const CHIARO := 0.30

## Ogni quanti secondi si rifà il conto. Dieci volte al secondo è più che
## abbastanza per una cosa che cambia camminando, e sono dieci raggi, non mille.
const OGNI := 0.1

## Quanto in fretta la lampada SALE, in frazioni dell'energia piena al secondo.
## Un trentesimo: TRENTA SECONDI per arrivare al massimo.
##
## È lentissimo e va bene così — è anzi più veloce del vero, perché un occhio umano
## ci mette dai venti ai trenta minuti ad adattarsi davvero al buio. Trenta secondi
## sono la versione giocabile di quella curva: entri in una stanza spenta e per la
## prima mezza minuto la stanza ti si apre addosso poco per volta, invece di essere
## già lì.
##
## VA SAPUTA UNA CONSEGUENZA, perché non è un difetto ma lo sembra: passando accanto
## a una lampada accesa la luce si spegne in un quarto di secondo e poi ci rimette
## trenta a tornare. Camminando per un osservatorio mezzo illuminato la si vedrà
## quasi sempre a metà strada, e piena solo restando fermi al buio. È esattamente
## quello che fa un occhio, ma chi si aspetta una torcia la troverà rotta.
const SI_ABITUA := 1.0 / 30.0

## Quanto in fretta SCENDE. Un quarto di secondo, cioè più di dieci volte la
## salita, e l'asimmetria è quella dell'occhio vero: al buio ci si abitua piano, alla
## luce si è abbagliati subito. Ma qui è anche una necessità — la lampada deve
## sparire *prima* che tu abbia il tempo di vedere il tuo alone su una parete
## illuminata, che è il difetto per cui esiste tutto questo file.
const ABBAGLIA := 4.0

## Ogni quanto si ricontano le lampade della scena. Non ogni fotogramma: cambiano
## quando qualcuno ne aggiunge una, cioè mai durante una partita.
const RICONTA := 5.0

var _piena := 0.0
var _lampade: Array[Light3D] = []
var _t := 0.0
var _t_conta := 0.0
var _voluta := 0.0


func _ready() -> void:
	_piena = light_energy
	_voluta = _piena
	_raduna()


func _process(delta: float) -> void:
	_t += delta
	_t_conta += delta
	if _t_conta >= RICONTA:
		_t_conta = 0.0
		_raduna()
	if _t >= OGNI:
		_t = 0.0
		var f := clampf((_altrui() - BUIO) / (CHIARO - BUIO), 0.0, 1.0)
		_voluta = _piena * (1.0 - f)
	var quanto := SI_ABITUA if _voluta > light_energy else ABBAGLIA
	light_energy = move_toward(light_energy, _voluta, _piena * quanto * delta)


## Quanta luce di ALTRI arriva dove sta la lampada.
func _altrui() -> float:
	var spazio := get_world_3d().direct_space_state
	var somma := 0.0
	for L in _lampade:
		if not is_instance_valid(L) or not L.is_visible_in_tree():
			continue
		var quanto := 0.0
		var dove := Vector3.ZERO
		if L is DirectionalLight3D:
			# la direzionale non ha posizione: quel che conta e' se si vede il cielo
			quanto = L.light_energy
			dove = global_position + L.global_transform.basis.z * 300.0
		else:
			var d := global_position.distance_to(L.global_position)
			var portata := 0.0
			var caduta := 1.0
			if L is OmniLight3D:
				portata = (L as OmniLight3D).omni_range
				caduta = (L as OmniLight3D).omni_attenuation
			elif L is SpotLight3D:
				var s := L as SpotLight3D
				portata = s.spot_range
				caduta = s.spot_attenuation
				# fuori dal cono non illumina, per quanto sia potente
				var verso := (global_position - s.global_position).normalized()
				if rad_to_deg(verso.angle_to(-s.global_transform.basis.z)) > s.spot_angle:
					continue
			if d >= portata or portata <= 0.0:
				continue
			quanto = L.light_energy * pow(1.0 - d / portata, caduta)
			dove = L.global_position
		# un filo di luce non cambia niente e non merita un raggio
		if quanto < 0.02:
			continue
		# E DEVE VEDERSI DA QUI. Senza, una plafoniera accesa di la' dal muro
		# spegnerebbe la lampada proprio dove il buio c'e' davvero.
		var q := PhysicsRayQueryParameters3D.create(global_position, dove)
		q.collision_mask = 1               # il mondo; il giocatore sta sul 2
		if not spazio.intersect_ray(q).is_empty():
			continue
		somma += quanto
	return somma


## Raccoglie le lampade della scena, sé stessa esclusa.
func _raduna() -> void:
	_lampade.clear()
	_cerca(get_tree().root)


func _cerca(n: Node) -> void:
	if n is Light3D and n != self:
		_lampade.append(n as Light3D)
	for f in n.get_children():
		_cerca(f)
