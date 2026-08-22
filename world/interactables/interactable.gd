## Il contratto comune degli oggetti con cui si può interagire (FR24).
##
## L'architettura fissa il nome di questo file e nient'altro: classe base,
## metodi e signal si decidono qui, e diventano il precedente per la moka
## (storia 3.3), la lampada (3.4) e la cupola (3.5).
##
## LA FORMA, E PERCHÉ È QUESTA
##
## `StaticBody3D` e non `Area3D`: il rilevamento avviene con un `RayCast3D` che
## parte dalla camera, perché l'AC dice «quando il giocatore GUARDA un oggetto
## interagibile da vicino» — e un'area di prossimità non distingue «lo guardo»
## da «ci sono accanto». Un corpo statico serve inoltre due scopi con un nodo
## solo: ferma il giocatore che ci cammina contro, e offre al raggio qualcosa da
## colpire.
##
## SIGNAL DIRETTO, MAI `Events`. La tabella § Communication dell'architettura
## elenca «interazione → oggetto interagibile» fra le comunicazioni dirette. La
## regola è: se sai chi ascolta ed è uno solo, signal diretto. Chi interagisce sa
## esattamente con quale oggetto lo sta facendo. `Events` è per i fatti di notte
## con più di due ascoltatori, e un bus senza regola diventa una discarica in tre
## mesi.
##
## LA LINGUA DEL PROMPT È L'ITALIANO, ed è una decisione, non una svista. NFR10
## dice che l'italiano è la lingua del giocatore e l'inglese quella delle
## macchine: il prompt di interazione lo legge il giocatore e non lo scrive un
## computer del 1999, quindi è italiano. Il testo SUL CRT resta inglese, perché
## quello lo scrive una macchina.
class_name Interactable
extends StaticBody3D

## I layer di collisione del progetto, nominati qui e in `project.godot` sotto
## `layer_names/3d_physics/`. I numeri nudi nelle scene sono illeggibili: questi
## sono l'unica definizione, e chi ne aggiunge uno la aggiorna in entrambi i posti.
##
## 1 — MONDO: tutto ciò che ferma il giocatore, e tutto ciò che gli sta davanti.
## 2 — GIOCATORE: il suo corpo, che nessun raggio di interazione deve trovare.
## 3 — INTERAGIBILI: ciò che il raggio cerca.
const LAYER_WORLD := 1 << 0
const LAYER_PLAYER := 1 << 1
const LAYER_INTERACTABLE := 1 << 2

## Emesso quando l'interazione avviene. `by` è chi l'ha eseguita.
signal interacted(by: Node3D)

## Cosa si legge nel prompt. In italiano, breve: la riga vive su uno schermo da
## 640x360 e non deve coprire la scena.
@export var prompt_text: String = "Usa"

## Un interagibile può esistere ed essere temporaneamente inerte — la moka senza
## caffè, la lampada già cambiata. Spento, non mostra prompt e non risponde.
@export var enabled: bool = true


## I layer si aggiungono in `_enter_tree`, e in OR, per due ragioni precise.
##
## IN `_enter_tree` E NON IN `_ready`: così una sottoclasse che definisce il
## proprio `_ready()` non deve ricordarsi di chiamare `super()`. Chi lo
## dimenticasse otterrebbe un oggetto che il raggio non trova mai — nessun
## prompt, nessun errore, e un sintomo che non punta in nessun modo alla causa.
## È la stessa trappola che `interact()` qui sotto dichiara di voler evitare, e
## non ha senso evitarla in un punto e ricrearla nell'altro.
##
## IN OR E NON IN ASSEGNAZIONE: un'assegnazione cieca cancellerebbe qualunque
## layer scelto nell'ispettore. La moka, la lampada e la cupola potrebbero avere
## bisogno di una maschera propria — di accorgersi di qualcosa — e la
## perderebbero all'ingresso in albero senza un log.
func _enter_tree() -> void:
	# Layer 1 perché fermi il giocatore, layer 3 perché il raggio lo trovi.
	collision_layer |= LAYER_WORLD | LAYER_INTERACTABLE


## Se adesso ci si può interagire. Le sottoclassi possono stringere la
## condizione; nessuna deve allentarla.
func can_interact() -> bool:
	return enabled


## La riga che il giocatore legge guardando l'oggetto.
func prompt() -> String:
	return prompt_text


## Esegue l'interazione. NON va sovrascritta per aggiungere comportamento: ci si
## collega a `interacted`, così un oggetto può avere più di un ascoltatore senza
## che nessuno debba ricordarsi di chiamare `super()`.
func interact(by: Node3D) -> void:
	if not can_interact():
		return
	interacted.emit(by)
