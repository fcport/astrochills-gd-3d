## Sotto-contratto tipizzato della fase di imaging (ADR-001, Pattern 1).
##
## `PhaseTruthSource` è un marker senza metodi, apposta: ogni fase dichiara qui
## la firma che le serve, e un nome sbagliato non compila invece di fallire in
## silenzio a runtime. Modello: il sotto-contratto della fase di targeting.
##
## Chi eredita: `HonestSequence` (MVP, dice sempre la verità). Il seam per una
## sorgente bugiarda esiste — una che mentisse sul conteggio dei frame senza che
## questo file cambi — ma nell'MVP non serve incarnarlo.
class_name ImagingTruthSource
extends PhaseTruthSource


## Lo stato osservabile della sequenza a partire dal tempo trascorso: quanti frame
## sono stati acquisiti, quanti in totale, se sta ancora girando e se ha finito.
##
## Questa implementazione non va mai chiamata: è astratta. Chiamarla è un errore
## di programma (canale 1), non un esito diegetico.
func sample(_input: ImagingInput) -> Dictionary:
	push_error("[imaging] sorgente astratta: usa una sottoclasse")
	return {&"frames_done": 0, &"frames_total": 0, &"running": false, &"done": false}
