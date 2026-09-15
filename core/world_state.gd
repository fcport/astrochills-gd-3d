## Com'è il mondo quando lo si lascia: dove stanno le cose, e cosa c'è dentro. SOLO DATI.
##
## È LA TERZA SORELLA di `PlayerProfile` e `NightRun`, e la linea con le altre due è la
## ragione per cui esiste (D-243). La notte muore col sonno, e se si chiude il gioco a metà
## riparte da capo alle 21:00: l'ha scelto Federico, e salvare una fase a metà vorrebbe
## dire rendere salvabile ogni fase. Il mondo no. La tazza lasciata sul tavolo della
## cucina è ancora lì, la moka ha ancora il caffè dentro, il fuoco lasciato acceso è
## ancora acceso. Nessuna di queste cose è della notte, e nessuna è del giocatore: sono
## della casa.
##
## PERCHÉ NON STA NEL PROFILO, dove pure stanno le stampe appese (D-239). Il profilo è
## ciò che il giocatore POSSIEDE — lire, acquisti, messaggi letti — e cambia quando
## compra o legge. Questo cambia ogni volta che una tazza si ferma. Tenerli insieme
## vorrebbe dire riscrivere il portafoglio cento volte a notte per spostare un termos, e
## un file mozzo a metà di quella scrittura si porterebbe via le lire insieme al termos.
##
## CHI SCRIVE COSA. Le voci le compone `MemoriaDelMondo`, chiedendo a ogni oggetto il suo
## `stato_da_ricordare()`; il disco lo tocca `Game`; qui si tengono soltanto. La chiave è il percorso
## del nodo dalla radice del mondo — `TazzaCucina`, `Moka`, `Fornello2` — e il valore è
## quello che l'oggetto ha deciso di ricordare di sé: la posizione sempre, e per chi ce
## l'ha il contenuto.
##
## Salvato con ResourceSaver in `user://saves/<partita>/world.tres`, leggibile e
## diffabile come gli altri due.
class_name WorldState
extends Resource

## Incrementare a ogni cambio di formato, e gestirlo in `migrate()`.
const CURRENT_VERSION := 1

## Default 0 e non `CURRENT_VERSION`, per la ragione scritta per esteso in
## `PlayerProfile.version`: `ResourceSaver` omette le proprietà uguali al default, e il
## numero vero sul disco lo timbra `SaveManager` subito prima di scrivere.
@export var version: int = 0

## Percorso del nodo dalla radice del mondo → il suo `stato_da_ricordare()`.
##
## UN OGGETTO CHE NON C'È PIÙ si porta dietro la sua voce finché qualcuno non salva di
## nuovo, e a quel punto sparisce: la lista si riscrive intera da ciò che esiste, come il
## registro delle stampe. Un oggetto NUOVO, che nel file non ha voce, resta dove lo mette
## la scena — e così uno MAI TOCCATO, perché la voce la scrive solo chi il giocatore ha
## preso, spostato o riempito. Spostare un mobile nel generatore sposta anche le cose che
## nessuno ha toccato.
@export var oggetti: Dictionary = {}

## Le macchie di caffè per terra (D-251), una voce per macchia: dove sta, quanto è grande, quanto
## ne resta (`Macchia.stato_da_ricordare()`).
##
## NON STANNO FRA GLI OGGETTI perché nella scena non esistono. Una tazza c'è sempre, e il file
## dice solo dove; una macchia c'è solo se il file la dice, e la rifà `MemoriaDelMondo`.
##
## LA VERSIONE NON CAMBIA: un salvataggio di prima non ha il campo, e leggerlo vuoto vuol dire
## «nessuna macchia», che è esattamente com'era.
@export var macchie: Array = []


func migrate() -> void:
	if version == CURRENT_VERSION:
		return
	# Nessuna migrazione ancora: il ramo esiste dal primo giorno per la stessa ragione
	# degli altri due tipi salvati.
	Log.warn("save", "WorldState v%d → v%d, nessuna migrazione definita" % [version, CURRENT_VERSION])
	version = CURRENT_VERSION
