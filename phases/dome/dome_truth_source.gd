## Sotto-contratto tipizzato della fase della cupola (ADR-001, Pattern 1).
##
## `PhaseTruthSource` è un marker senza metodi, apposta: ogni fase dichiara qui la
## firma che le serve, e un nome sbagliato non compila invece di fallire in
## silenzio a runtime.
##
## Chi eredita: `HonestShutter` (MVP, dice la verità). Nessuna sorgente bugiarda
## esiste ancora — l'MVP non ha rotture — ma la forma della bugia è già chiara e
## sta scritta in `DomeInput`: un battente che rallenta, che si ferma a un
## capello dalla fine corsa, o che si muove senza che nessuno abbia dato corrente.
class_name DomeTruthSource
extends PhaseTruthSource


## Velocità del battente, in FRAZIONI DI CORSA AL SECONDO. Positiva apre.
##
## UNA VELOCITÀ E NON UNA POSIZIONE, come per la deriva polare, e per la stessa
## ragione: la fase la integra, e il giocatore vede il battente reagire al comando
## nello stesso istante in cui lo dà. Con una posizione la sorgente diventerebbe
## padrona anche del tempo, e una bugia sul tempo non si distingue da uno scatto.
##
## Questa implementazione non va mai chiamata: è astratta. Chiamarla è un errore
## di programma (canale 1), non un esito diegetico.
func sample(_input: DomeInput, _delta: float) -> float:
	push_error("[dome] sorgente astratta: usa una sottoclasse")
	return 0.0
