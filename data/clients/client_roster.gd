## L'elenco dei committenti della notte. SOLO DATI, nessuna logica.
##
## Sul modello di `phases/targeting/sources/honest_catalog.tres`: una Resource con
## un `@export Array` che referenzia i `.tres` figli. La scelta della commessa la fa
## `photo/commission.gd`, che riceve `clients` — questo file li raccoglie soltanto.
class_name ClientRoster
extends Resource

## I committenti, iniettati dal `.tres`. `privato_g` è nell'elenco ma disabilitato:
## la selezione lo filtra via.
@export var clients: Array[ClientData] = []
