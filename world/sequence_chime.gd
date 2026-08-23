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
	play()
