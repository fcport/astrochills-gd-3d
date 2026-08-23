## Il suono di fine sequenza — che APPARTIENE AL LUOGO, non alla fase.
##
## È un `AudioStreamPlayer3D` che vive in `world/` — e dal 2026-08-23 ci vive davvero, appeso presso il monitor/
## telescopio, NON figlio della fase né del CRT. Così la sua collocazione regge
## quando arriveranno cucina e cupola (storia 3.1): resta ancorato al punto dove la
## macchina lavora, e chi si allontana lo sente attenuarsi — segno che è posizionale.
##
## SA TRAMITE `Events`, MAI INTERROGANDO LA FASE. La fine della sequenza coincide
## col `finished` della fase, che `night_session` ripubblica come
## `Events.phase_finished(key, score)` — un segnale che esiste già. Il nodo filtra
## su `key == &"imaging"`: la stessa soft-coupling via stringa che l'epica sanziona
## per la cupola. Zero `Events` nuovi, e il mondo continua a non conoscere la
## cartella delle fasi — «imaging» compare qui solo come StringName di filtro sul bus.
extends AudioStreamPlayer3D


func _ready() -> void:
	# Non `connect` in scena: il collegamento sta nel codice del nodo, così chi
	# istanzia la scena in `world/` non deve ricablare nulla.
	Events.phase_finished.connect(_on_phase_finished)


func _on_phase_finished(key: StringName, _score: int) -> void:
	# SOLO l'imaging suona questo. La polare e il targeting emettono lo stesso
	# segnale con la propria chiave, e passano di qui senza svegliare il tono.
	if key != &"imaging":
		return
	# DA FUORI NON SI SENTE (storia 3.1), e la distanza da sola non poteva dirlo:
	# appena fuori la porta sud si è a ~6,0 m da qui, il centro della cupola a ~7,7
	# — cioè fuori è più VICINO di un posto che deve restare udibile. Serviva sapere
	# DOVE si è, e lo dice `IndoorsVolume`.
	if not _player_indoors():
		return
	play()


## Vero se il giocatore è dentro l'edificio — e vero anche quando la risposta non
## si può dare.
##
## IL RIPIEGO CADE DALLA PARTE GIUSTA. Volume assente, giocatore non trovato, scena
## montata a metà: si torna «dentro», cioè il suono si sente, cioè esattamente il
## comportamento che questo nodo aveva prima della 3.1. Un volume dimenticato non
## deve poter far sparire un suono in silenzio — e il silenzio è il guasto più
## difficile da notare che esista.
func _player_indoors() -> bool:
	var volume := IndoorsVolume.find_in(get_tree())
	var player := Player.find_in(get_tree())
	if volume == null or player == null:
		return true
	return volume.holds(player)
