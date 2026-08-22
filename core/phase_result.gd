## Esito di una fase — il CANALE DIEGETICO.
##
## Non è un errore di programma: è contenuto che il giocatore legge sul CRT.
## Un fallimento diegetico non passa MAI da push_error(); un errore di programma
## non appare MAI sul CRT. Vedi game-architecture.md § Cross-cutting Concerns.
##
## `reason` è in INGLESE: è la lingua delle macchine.
class_name PhaseResult
extends RefCounted

var ok: bool
var reason: String       ## diegetico, inglese, mostrato sul CRT
var score: int           ## 0-100
var payload: Dictionary  ## dati per le fasi successive


func _init(p_ok := true, p_reason := "", p_score := 100, p_payload := {}) -> void:
	ok = p_ok
	reason = p_reason
	score = p_score
	payload = p_payload
