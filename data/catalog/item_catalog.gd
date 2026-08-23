## Il catalogo del terminale: gli articoli in vendita. SOLO DATI, quasi.
##
## Sul modello di `data/clients/client_roster.gd`: una Resource con un `@export Array`
## che referenzia i `.tres` figli. Il terminale riceve il catalogo e chiede
## `for_category()` — questo file raccoglie e filtra, non decide cosa mostrare a schermo.
##
## `for_category` È LOGICA PURA e collaudabile al banco: dato un elenco fisso, per una
## categoria torna sempre gli stessi articoli. Il filtro `implemented` è reale — è la
## regola dell'epica resa codice, non un commento.
class_name ItemCatalog
extends Resource

## Gli articoli, iniettati dal `.tres`. Contiene sia gli implementati (moka, lampadina)
## sia i non implementati (stufetta, lubrificare cupola): il filtro li separa.
@export var items: Array[ItemData] = []

## Gli articoli di una categoria. Di default SOLO gli implementati: è ciò che il
## terminale mostra e vende. `only_implemented = false` dà tutti quelli della categoria
## — lo usa il banco per provare che il filtro fa davvero qualcosa.
##
## L'ordine è quello del `.tres`: stabile e diffabile, come il roster dei committenti.
func for_category(cat: StringName, only_implemented := true) -> Array[ItemData]:
	var out: Array[ItemData] = []
	for item in items:
		if item == null:
			continue
		if item.category != cat:
			continue
		if only_implemented and not item.implemented:
			continue
		out.append(item)
	return out
