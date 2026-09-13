## Quali fasi compongono una notte, e in che ordine.
##
## Le fasi di setup si eseguono una volta per notte e restano valide fino
## all'alba; quelle di foto si rieseguono per ogni scatto (economia.md §12).
##
## È un dato, non codice, perché gli upgrade tolgono fasi dalla routine: quando
## arriverà il livella motorizzato, automatizzare una fase sarà cancellare una
## riga da un .tres invece di modificare l'orchestratore.
class_name NightPlan
extends Resource

@export var setup_phases: Array[PackedScene] = []
@export var photo_phases: Array[PackedScene] = []


## La casella del piano in corso, contando le fasi di setup e poi quelle di foto messe in
## fila: è l'indice che la barra delle schede evidenzia.
##
## GLI INDICI SONO QUELLI DOPO L'AVANZAMENTO. L'orchestratore incrementa l'indice nel
## momento in cui prende la scena, quindi quando la fase è montata puntano già alla
## casella successiva: il meno uno sta qui, in un posto solo, invece che in ogni
## chiamante.
static func tab_index(in_setup: bool, setup_index: int, photo_index: int,
		setup_count: int) -> int:
	if in_setup:
		return setup_index - 1
	return setup_count + photo_index - 1
