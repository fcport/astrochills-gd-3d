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
