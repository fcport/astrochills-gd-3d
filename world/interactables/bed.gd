## Il letto: l'unico modo di far finire una giornata e cominciare la successiva.
##
## PERCHÉ UN OGGETTO E NON UN PULSANTE. Il riepilogo dell'alba avrebbe potuto
## guadagnare una riga «START NIGHT 2» e sarebbe costato un decimo. Ma sarebbe
## stato il primo pulsante di menu su uno schermo che finora non ne ha mai avuti,
## e avrebbe trascinato il giocatore alla notte dopo restando seduto. ADR-003 dice
## che i passaggi sono GESTI: ci si siede al monitor perché si è camminati fin
## lì. Andare a dormire è lo stesso gesto dall'altro capo della notte.
##
## SI ACCENDE SOLO ALL'ALBA, e non è una limitazione tecnica: è l'unica regola
## che tiene la storia coerente senza aprire il caso «dormire con una posa in
## corso». Chi la decide è il punto d'ingresso — `main.gd` è l'unico che vede
## sia il mondo sia la notte — esattamente come già decide quando il monitor
## merita di mostrare un prompt.
class_name Bed
extends Interactable

## Chi ha bisogno del letto lo trova per GRUPPO, mai per percorso di nodo: stessa
## regola del monitor, e per la stessa ragione — un percorso si rompe al primo
## spostamento, e la storia 3.1 sposta mezza casa.
const GROUP := &"bed"


func _ready() -> void:
	add_to_group(GROUP)


## Il letto della scena, o `null` se non ce n'è.
static func find_in(tree: SceneTree) -> Bed:
	return tree.get_first_node_in_group(GROUP) as Bed
