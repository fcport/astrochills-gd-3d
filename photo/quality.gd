## L'aggregazione della qualità di una foto: dai punteggi delle fasi a un numero.
##
## LOGICA PURA (AC2). Nessun autoload, nessun nodo, nessun viewport: si costruisce
## con `PhotoQuality.new()` in un test senza SceneTree, esattamente come le sorgenti
## di verità. Legge un `Dictionary` e restituisce un `int`, niente altro.
##
## DOVE VIVE, E PERCHÉ QUI. La tabella dei confini (game-architecture.md) mette
## «score → stack → tier → vendita» qui dentro, e vieta alla cartella delle fasi di
## conoscere questa. Per questo lo stacking non è una fase: sarebbe la fase a dover
## chiamare questo file, e violerebbe il confine. È `night/` a condurre
## l'aggregazione, l'unica cartella che può dipendere sia dalle fasi (via il piano)
## sia da qui.
##
## L'EREDITARIETÀ È NELLA PERSISTENZA, NON IN UN RAMO. `run.phase_scores` sopravvive
## fra uno scatto e l'altro (lo azzera solo `start_night`), e tiene l'ultimo
## punteggio per `Phase.key()`. Quando la 2.6 rifarà solo l'imaging, polar e
## targeting resteranno con il loro valore vecchio: `aggregate` somma il dizionario
## com'è, e le fasi non rifatte contano con il punteggio precedente. Non c'è codice
## dell'ereditarietà da scrivere — è già nel dato.
class_name PhotoQuality
extends RefCounted

## Media intera (floor) dei punteggi di fase; `0` su dizionario vuoto.
##
## LA FORMULA È SEGNAPOSTO (FR22): la media dei punteggi è un numero plausibile,
## non tarato. La calibrazione — pesi diversi per fase, curve, soglie — è rinviata
## e non tocca la firma di questo metodo.
##
## L'indicizzazione è per `Phase.key()`, ma qui non serve saperlo: si sommano i
## VALORI, e le chiavi sono già quelle giuste perché `night_session` scrive
## `phase_scores[key()]`, mai `name`.
func aggregate(phase_scores: Dictionary) -> int:
	if phase_scores.is_empty():
		# Default segnaposto: nessun punteggio non è qualità zero mentita, è
		# assenza di dati. Restituire `0` evita la divisione per zero e non
		# inventa un numero. Il caso «foto senza nessuna fase scored» non dovrebbe
		# capitare nel flusso reale, ma il metodo resta puro e totale.
		return 0
	var total := 0
	for k in phase_scores:
		total += int(phase_scores[k])
	# Divisione intera: floor implicito. `@warning_ignore` non serve, sono int.
	return total / phase_scores.size()
