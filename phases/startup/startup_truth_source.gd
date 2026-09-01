## Sotto-contratto tipizzato della fase dell'accensione (ADR-001, Pattern 1).
##
## `PhaseTruthSource` è un marker senza metodi, apposta: ogni fase dichiara qui la
## firma che le serve, e un nome sbagliato non compila invece di fallire in
## silenzio a runtime.
##
## Chi eredita: `HonestBus` (MVP, dice la verità). La forma della bugia è già
## scritta nel GDD ed è di questa firma: una maschera che contiene un apparecchio
## che nessuno ha collegato, o che perde quello che sta rispondendo.
class_name StartupTruthSource
extends PhaseTruthSource


## CHI RISPONDE, una maschera di bit, un bit per apparecchio.
##
## È l'unica cosa osservabile di questa fase: sullo schermo non c'è nient'altro
## che l'esito di questa riga. La fase non deduce mai «se è acceso allora
## risponde» — quella deduzione è del bus, e il bus qui dentro può mentire.
##
## Questa implementazione non va mai chiamata: è astratta. Chiamarla è un errore
## di programma (canale 1), non un esito diegetico.
func sample(_input: StartupInput, _delta: float) -> int:
	push_error("[startup] sorgente astratta: usa una sottoclasse")
	return 0
