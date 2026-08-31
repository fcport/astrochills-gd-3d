## Sotto-contratto tipizzato della fase del fuoco (ADR-001, Pattern 1).
##
## `PhaseTruthSource` è un marker senza metodi, apposta: ogni fase dichiara qui la
## firma che le serve, e un nome sbagliato non compila invece di fallire in
## silenzio a runtime.
##
## Chi eredita: `HonestVCurve` (MVP, dice la verità). Le bugie di questa fase sono
## già scritte nel GDD e sono due, tutte e due esprimibili senza toccare la fase:
## un minimo che non scende mai abbastanza, e — più avanti, quando le stelle
## avranno una forma e non solo un diametro — stelle che a fuoco diventano
## qualcos'altro.
class_name FocusTruthSource
extends PhaseTruthSource


## Il DIAMETRO DELLE STELLE osservato adesso, in pixel dello schermo.
##
## In astrofotografia si chiama HFD — half flux diameter, il cerchio dentro cui
## cade metà della luce della stella — ed è la misura con cui si mette a fuoco
## davvero: piccolo è meglio, e non scende mai a zero perché l'atmosfera non lo
## permette.
##
## UNA MISURA E NON UNA POSIZIONE, ed è ciò che rende la fase giocabile senza che
## nessuno spieghi niente: il giocatore non sa dove sia il fuoco, vede solo quanto
## sono grosse le stelle, e cerca il minimo. Se la fase ricevesse «la distanza dal
## fuoco» starebbe ricevendo la risposta.
##
## Questa implementazione non va mai chiamata: è astratta. Chiamarla è un errore
## di programma (canale 1), non un esito diegetico.
func sample(_input: FocusInput, _delta: float) -> float:
	push_error("[focus] sorgente astratta: usa una sottoclasse")
	return 0.0
