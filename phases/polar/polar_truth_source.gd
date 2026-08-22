## Sotto-contratto tipizzato della fase polare (ADR-001, Pattern 1).
##
## `PhaseTruthSource` è un marker senza metodi, apposta: ogni fase dichiara qui
## la firma che le serve, e un nome sbagliato non compila invece di fallire in
## silenzio a runtime.
##
## Chi eredita: `HonestDrift` (MVP, dice la verità) e `WanderingDrift` (esiste
## per esercitare il seam, non come contenuto — l'MVP non ha rotture).
class_name PolarTruthSource
extends PhaseTruthSource


## Deriva osservata della stella nel reticolo, in ARCOMINUTI.
##
## È lo scostamento accumulato da quando il giocatore ha corretto l'ultima volta,
## non una velocità: la fase lo usa direttamente come posizione della stella.
##
## Questa implementazione non va mai chiamata: è astratta. Chiamarla è un errore
## di programma (canale 1), non un esito diegetico.
func sample(_input: PolarInput, _delta: float) -> Vector2:
	push_error("[polar] sorgente astratta: usa una sottoclasse")
	return Vector2.ZERO
