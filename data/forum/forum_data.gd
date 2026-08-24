## Il collettore del forum: raccoglie le aree (board) della BBS. SOLO DATI.
##
## È a `ForumBoard` ciò che `ItemCatalog` è a `ItemData`: una Resource con un solo
## `@export Array` che referenzia i `.tres` figli. La BBS carica QUESTO (`forum.tres`)
## e itera `boards`; ogni board sa filtrare i propri messaggi per notte.
##
## Perché un collettore e non un array di board sciolto sulla BBS: così il contenuto
## sta tutto in `data/*.tres` (niente JSON, niente `FileAccess`) e si aggiunge un'area
## nuova toccando solo i dati, mai il codice — stessa forma del catalogo del terminale.
class_name ForumData
extends Resource

## Le aree del forum, iniettate dal `.tres`. L'ordine è quello del file: è l'ordine in
## cui la BBS le mostra nell'elenco.
@export var boards: Array[ForumBoard] = []
