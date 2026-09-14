## La memoria della casa: rimette le cose dove erano state lasciate, e si ricorda dove
## vengono lasciate adesso (D-243).
##
## CHI SI RICORDA DI SÉ entra nel gruppo `GRUPPO` e promette tre cose:
## `stato_da_ricordare()`, che restituisce un `Dictionary` con quello che vuole ritrovare;
## `torna_come_ricordato(voce)`, che lo rimette; e il segnale `cambiato`, quando c'è
## qualcosa di nuovo da ricordare. Tutto
## quello che si prende in mano ci entra da sé (`Carryable`), e così i fuochi della cucina.
## Questo nodo non sa cosa sia una tazza: sa soltanto chiedere.
##
## SALVA POCO DOPO, NON SUBITO. Una tazza posata rimbalza, e scriverla al primo contatto
## vorrebbe dire ricordarla a mezz'aria; scriverla a ogni rimbalzo, dieci salvataggi per un
## gesto. Si aspetta un secondo e mezzo dall'ultimo cambiamento — la stessa attesa della
## stampante, per la stessa ragione. E si salva comunque quando si chiude la finestra, così
## l'ultima cosa posata non dipende da quanto in fretta si esce.
##
## IL DISCO LO TOCCA `Game`, come per le stampe: il mondo non conosce `SaveManager`.
class_name MemoriaDelMondo
extends Node

## Il gruppo di chi si ricorda di sé. Vedi l'intestazione per cosa promette chi ci entra.
const GRUPPO := &"si_ricorda"

## Secondi di quiete dall'ultimo cambiamento prima di scrivere.
const ATTESA_SALVATAGGIO := 1.5

var _salvataggio: Timer

## Falso finché le cose non sono state rimesse al loro posto. Prima, un salvataggio
## scriverebbe le posizioni della SCENA sopra quelle del file — cioè cancellerebbe la
## memoria nel momento stesso in cui la si sta leggendo.
var _pronta := false


func _ready() -> void:
	_salvataggio = Timer.new()
	_salvataggio.one_shot = true
	_salvataggio.timeout.connect(salva_adesso)
	add_child(_salvataggio)
	# Chi cambia partita chiede di scrivere PRIMA di passare all'altra: dopo, `Game`
	# guarderebbe già la cartella nuova, e il mondo di questa finirebbe dentro quella.
	Game.salvataggio_richiesto.connect(salva_adesso)
	_avvia.call_deferred()


## DUE PASSI DI FISICA PRIMA DI RIMETTERE, come la stampante: la corazza si costruisce
## differita, e una tazza rimessa sul tavolo prima che il tavolo esista per il motore
## cadrebbe attraverso il tavolo.
func _avvia() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var voci: Dictionary = Game.mondo.oggetti
	var rimessi := 0
	for n in get_tree().get_nodes_in_group(GRUPPO):
		var chiave := chiave_di(n)
		if voci.has(chiave):
			n.torna_come_ricordato(voci[chiave])
			rimessi += 1
		n.cambiato.connect(_salva_presto)
	_pronta = true
	if rimessi > 0:
		Log.info("mondo", "%d cose rimesse dove erano state lasciate" % rimessi)


## La chiave di un oggetto: il suo percorso dalla radice del mondo, che è il genitore di
## questo nodo. Non il nome da solo — due tazze in due stanze possono chiamarsi uguali.
func chiave_di(n: Node) -> String:
	return String(get_parent().get_path_to(n))


func _salva_presto() -> void:
	if _pronta:
		_salvataggio.start(ATTESA_SALVATAGGIO)


## Si riscrive intero da ciò che esiste adesso, come il registro delle stampe.
func salva_adesso() -> void:
	if not _pronta:
		return
	_salvataggio.stop()
	var voci := {}
	for n in get_tree().get_nodes_in_group(GRUPPO):
		if n.is_queued_for_deletion():
			continue
		# UNA VOCE VUOTA NON SI SCRIVE: è una cosa che nessuno ha toccato, e deve restare
		# dove la mette la scena anche quando la scena cambia.
		var voce: Dictionary = n.stato_da_ricordare()
		if not voce.is_empty():
			voci[chiave_di(n)] = voce
	Game.ricorda_mondo(voci)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		salva_adesso()
