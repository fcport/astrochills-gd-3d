## Sotto-contratto tipizzato della fase di targeting (ADR-001, Pattern 1).
##
## `PhaseTruthSource` è un marker senza metodi, apposta: ogni fase dichiara qui
## la firma che le serve, e un nome sbagliato non compila invece di fallire in
## silenzio a runtime. Modello: il sotto-contratto della fase polare.
##
## Chi eredita: `HonestCatalog` (MVP, dice sempre la verità) e `WanderingCatalog`,
## che falsa la disponibilità. La seconda NON è contenuto: esiste solo per essere
## iniettata da `F9` e provare che il vincolo regge anche qui, come
## `WanderingDrift` fa per la polare. Il seam esiste, le rotture giocabili no.
class_name TargetingTruthSource
extends PhaseTruthSource


## Il catalogo osservabile: un dizionario per target con i suoi campi e la
## disponibilità calcolata all'ora corrente (`input.now_min`).
##
## Questa implementazione non va mai chiamata: è astratta. Chiamarla è un errore
## di programma (canale 1), non un esito diegetico.
func sample(_input: TargetingInput) -> Array[Dictionary]:
	push_error("[targeting] sorgente astratta: usa una sottoclasse")
	return []
