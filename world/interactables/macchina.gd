## L'AUTO: l'unico modo di far finire una giornata e cominciare la successiva.
##
## PRIMA ERA UN LETTO, E STAVA NEL MAGAZZINO. Federico: «puoi rimuovere il letto
## dal magazzino, non serve». Aveva ragione due volte. La prima è il buonsenso —
## una branda fra gli scaffali di un magazzino è la soluzione di chi non sapeva
## dove metterla. La seconda sta scritta nel GDD da sempre, in `docs/idea/idea.md`
## §, e nessuno l'aveva letta fino in fondo: «ogni notte il giocatore arriva
## all'osservatorio, lavora fino all'alba, POI RISALE IN MACCHINA E TORNA A CASA A
## DORMIRE». Il turnista non dorme all'osservatorio. Ci arriva e se ne va.
##
## PERCHÉ UN OGGETTO E NON UN PULSANTE, che è la ragione già scritta per il letto e
## vale identica: il riepilogo dell'alba avrebbe potuto guadagnare una riga «START
## NIGHT 2», e sarebbe stato il primo pulsante di menu su uno schermo che non ne ha
## mai avuti. ADR-003 dice che i passaggi sono GESTI: ci si siede al monitor perché
## si è camminati fin lì, e si va a casa perché si è usciti e si è attraversato il
## prato fino al parcheggio.
##
## E LA CAMMINATA È IL PUNTO, non un pedaggio. Sono venti metri di prato al buio,
## dalla porta al cancello, con l'osservatorio che si spegne alle spalle: è la
## stessa distanza che si è fatta arrivando, rifatta nel verso opposto, e chiude
## la notte invece di tagliarla.
##
## SI ACCENDE SOLO ALL'ALBA, come il letto e per la stessa ragione: andarsene con
## una posa in corso chiuderebbe la notte a metà, ed è un caso che nessuno ha
## ancora deciso come debba comportarsi. Chi la accende è `main.gd`, l'unico che
## vede sia il mondo sia la notte.
class_name Macchina
extends Interactable

## Chi ha bisogno dell'auto la trova per GRUPPO, mai per percorso di nodo: stessa
## regola del monitor e del fungo (D-196), e per la stessa ragione — un percorso
## si rompe al primo spostamento.
const GROUP := &"macchina"


func _ready() -> void:
	add_to_group(GROUP)


## L'auto della scena, o `null` se non ce n'è.
static func find_in(tree: SceneTree) -> Macchina:
	return tree.get_first_node_in_group(GROUP) as Macchina
