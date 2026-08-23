## Il volume dell'EDIFICIO: dice se il giocatore è dentro o fuori.
##
## NASCE PER UNA CLAUSOLA CHE LA DISTANZA NON POTEVA SODDISFARE. La storia 3.1
## chiede che il suono di fine sequenza sia ovattato dalla cucina, appena
## percettibile dalla cupola e INUDIBILE da fuori. Ma il punto appena fuori la
## porta sud sta a ~6,0 m dal chime e il centro della cupola a ~7,7: fuori è più
## VICINO di un posto che deve restare udibile, e nessuna curva di attenuazione
## può distinguerli. Serve sapere DOVE si è, non quanto si è lontani.
##
## PERCHÉ AL CONTRARIO DI COME SEMBRA NATURALE. La 3.1 prescriveva «un Area3D che
## rileva il giocatore FUORI e ammutolisce il chime». Ma «fuori» è tutto il resto
## del mondo: servirebbe un volume con dentro il buco dell'edificio, e una forma
## convessa non lo sa fare — si finirebbe a incollare quattro o cinque scatole
## intorno alla casa, ognuna da riallineare a ogni stanza nuova. Il volume
## dell'EDIFICIO invece è UNA scatola, e la si legge dalle misure delle stanze.
##
## E IL RIPIEGO CADE DALLA PARTE GIUSTA. Se questo nodo manca, o se il giocatore
## non si trova, chi interroga ottiene «dentro» — cioè il suono si sente, cioè
## il comportamento che la 2.3 aveva prima che questa storia esistesse. Un volume
## dimenticato non fa sparire un suono in silenzio.
class_name IndoorsVolume
extends Area3D

## Chi ha bisogno del volume lo trova per GRUPPO, mai per percorso di nodo: stessa
## regola del monitor e del letto, e per la stessa ragione.
const GROUP := &"indoors"


func _ready() -> void:
	add_to_group(GROUP)
	# SOLO IL GIOCATORE. Senza la maschera l'area si sveglierebbe per ogni parete e
	# ogni mobile che la attraversano — sono tutti `StaticBody3D` sul layer del
	# mondo — e `overlaps_body()` direbbe «c'è qualcuno dentro» sempre.
	collision_mask = Interactable.LAYER_PLAYER
	# L'area non deve essere TROVATA da nessuno: non è un bersaglio, è una domanda.
	collision_layer = 0
	monitoring = true


## Il volume della scena, o `null` se non ce n'è.
static func find_in(tree: SceneTree) -> IndoorsVolume:
	return tree.get_first_node_in_group(GROUP) as IndoorsVolume


## Vero se quel corpo è dentro l'edificio.
func holds(body: Node3D) -> bool:
	return body != null and overlaps_body(body)
