## La sorgente onesta della fase dell'accensione: risponde chi ha corrente.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente, e la
## regola sta in tre righe: un apparecchio risponde se il software gli ha aperto
## la porta, se era alimentato allora, e se lo è ancora adesso.
##
## FUNZIONE PURA DI `input`, ed è un requisito e non uno stile: nessuno stato
## interno, `delta` mai usato. Tutta la memoria della fase — chi era acceso quando
## hai tentato — viaggia dentro `input`, ed è quello che permette al banco di
## collaudare questa sorgente senza montare niente.
##
## L'ORDINE SBAGLIATO NON PERDONA DA SÉ, e cade fuori da qui senza un caso
## speciale: chi ha tentato la porta a interruttore spento ha `powered_when` senza
## il proprio bit, e quel bit non torna indietro accendendo l'interruttore dopo.
## Torna col RESET, che è ciò che si fa davvero quando un driver ha preso una
## porta vuota.
class_name HonestBus
extends StartupTruthSource

## Chi alimenta chi: per ogni apparecchio, l'indice di quello che gli dà corrente,
## oppure -1 se ha un interruttore suo.
##
## LA CATENA È UN FATTO DEL BUS, non della fase, e sta qui per questo: la ruota
## portafiltri di una SBIG prende i suoi dodici volt dalla camera, e con la camera
## spenta non c'è niente da collegare. È anche il solo pezzo di questa fase che il
## giocatore deve DEDURRE invece di eseguire — lo schermo non glielo scrive.
@export var fed_by: PackedInt32Array = PackedInt32Array([-1, -1, 1])


func sample(input: StartupInput, _delta: float) -> int:
	var risponde := 0
	for i in fed_by.size():
		var bit := 1 << i
		if input.attempted & bit == 0:
			continue
		var allora := input.powered_when[i] if i < input.powered_when.size() else 0
		if _alimentato(i, allora) and _alimentato(i, input.powered):
			risponde |= bit
	return risponde


## Se l'apparecchio `i` ha corrente, data una maschera di interruttori.
##
## Ricorsiva perché la catena può essere lunga: la ruota dalla camera, e un giorno
## la camera da un alimentatore che a sua volta ha un interruttore. Il caso di
## oggi ha un anello solo, ma scriverlo a mano per un anello vorrebbe dire
## riscriverlo al secondo.
func _alimentato(i: int, interruttori: int) -> bool:
	var da := fed_by[i] if i < fed_by.size() else -1
	if da < 0:
		return interruttori & (1 << i) != 0
	return _alimentato(da, interruttori)
