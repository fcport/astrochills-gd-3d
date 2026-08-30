## Una porta che si apre e si chiude guardandola e premendo `E`.
##
## PERCHÉ È UN `Interactable` E NON UN MECCANISMO PROPRIO. Il contratto di
## `interactable.gd` esiste per non avere due modi di premere `E`: il raggio parte
## dalla camera, distingue «la guardo» da «ci sono accanto», e il prompt lo scrive
## il giocatore in italiano. Una porta non ha nessun bisogno diverso da quelli, e
## una seconda strada per lo stesso gesto sarebbe solo un posto in più dove il
## comportamento può divergere.
##
## IL NODO STA SUL CARDINE, NON AL CENTRO DELL'ANTA. È la stessa regola dei
## portelli della cupola e delle ante nel modello Blender: un pezzo che ruota si
## descrive dal perno. Mesh e collisione sono quindi spostate di mezza anta lungo
## `+X` locale, e aprire è ruotare il nodo attorno a `Y`. Con l'origine al centro
## l'anta si staccherebbe dal telaio al primo grado di rotazione.
##
## IL VERSO È UN DATO, NON UNA CONVENZIONE. `verso` vale +1 o -1 e arriva dal
## generatore, che lo calcola dalla stessa `APERTURA_PORTE` di `geometria.py` da
## cui nascono la pianta e il modello. L'ingresso si apre verso il prato perché
## una via di fuga non si apre verso l'interno; le interne verso il locale
## servito, tranne dove il locale è troppo stretto per contenere l'anta.
##
## `StaticBody3D` CHE SI MUOVE, E IL SUO LIMITE DICHIARATO. `Interactable` estende
## `StaticBody3D`, che non spinge un `CharacterBody3D` fermo nel suo raggio: chi
## sta esattamente nel vano mentre la porta si chiude può restare incastrato.
## Nel blockout è accettabile e preferibile a duplicare la gerarchia
## dell'interagibile; quando le porte diventeranno oggetti di produzione la
## risposta è un `AnimatableBody3D` a parte, non un secondo contratto.
class_name Door
extends Interactable

## Quanto si spalanca. Ottanta gradi e non novanta: una porta aperta a filo di
## muro sembra smontata, e questi dieci gradi la fanno leggere come una porta.
@export var apertura_gradi: float = 80.0

## Da che parte gira: +1 o -1 rispetto alla rotazione a battente chiuso. Lo
## scrive il generatore, che lo ricava dalla normale del muro.
@export var verso: int = 1

## Quanto dura il movimento. Mezzo secondo scarso: abbastanza da vedersi, non
## tanto da far aspettare chi attraversa venti volte per notte.
@export var durata: float = 0.55

## Emesso a movimento concluso, con lo stato raggiunto. Serve a chi vorrà
## appenderci un suono o una reazione senza sapere come è fatta la rotazione.
signal moved(open: bool)

var _aperta := false
var _chiusa_y := 0.0
var _tween: Tween = null


func _ready() -> void:
	# La rotazione con cui la porta nasce È la posizione di battente chiuso: la
	# decide il generatore orientando il nodo lungo il muro. Leggerla invece di
	# assumere zero significa che una porta ruotata a mano nell'editor continua a
	# funzionare.
	_chiusa_y = rotation.y
	# `interact()` non va sovrascritta — lo dice il contratto — così un domani la
	# porta può avere più di un ascoltatore senza che nessuno chiami `super()`.
	interacted.connect(_on_interacted)


## Il prompt cambia con lo stato, e il player rilegge il testo a ogni sguardo:
## chi la guarda sa già cosa succederà premendo `E`.
func prompt() -> String:
	return "Chiudi" if _aperta else "Apri"


## Se è aperta adesso. Di sola lettura: si cambia stato solo interagendo.
func is_open() -> bool:
	return _aperta


## Porta la porta nello stato voluto. `immediata` salta l'animazione — serve a
## chi allestisce una scena già aperta senza vederla sbattere all'avvio.
func set_open(open: bool, immediata: bool = false) -> void:
	if _tween != null and _tween.is_valid():
		# Chi cambia idea a metà corsa non deve accodare due rotazioni: la
		# precedente si annulla, e si riparte da dove l'anta è arrivata.
		_tween.kill()
	_aperta = open
	var bersaglio := _chiusa_y + (deg_to_rad(apertura_gradi) * signf(verso) if open else 0.0)
	if immediata:
		rotation.y = bersaglio
		moved.emit(_aperta)
		return
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, ^"rotation:y", bersaglio, durata)
	_tween.finished.connect(func() -> void: moved.emit(_aperta))


func _on_interacted(_by: Node3D) -> void:
	set_open(not _aperta)
