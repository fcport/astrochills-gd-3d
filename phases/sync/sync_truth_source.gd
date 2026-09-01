## Sotto-contratto tipizzato della fase di sincronizzazione (ADR-001, Pattern 1).
##
## LE DUE DOMANDE SONO DIVERSE, e tenerle separate è ciò che rende la fase
## giocabile. `sample()` dice **dove appare la stella**: è quello che il giocatore
## vede, ed è lo stato osservabile. `aim()` dice **dove finisce il tubo**: non lo
## vede nessuno sullo schermo — è il ferro che si muove in cupola, e serve solo
## perché il telescopio in scena vada dove deve.
##
## LA BUGIA CHE IL GDD PROMETTE sta tutta qui dentro e non ha bisogno che la fase
## cambi di una riga: «la stella che ti chiede di centrare non è dove il catalogo
## dice che sia». Una sorgente bugiarda restituisce da `catalog_position()` una
## coordinata e da `sample()` una stella che si comporta come se fosse altrove.
class_name SyncTruthSource
extends PhaseTruthSource


## Come si chiama la stella di taratura. Va sullo schermo, in maiuscolo.
func star_label() -> String:
	push_error("[sync] sorgente astratta: usa una sottoclasse")
	return ""


## Dove il CATALOGO DEL SOFTWARE dice che stia la stella: angolo orario e
## declinazione, in gradi. È la coordinata su cui il software manda gli encoder,
## e dopo il SYNC diventa il punto in cui il puntamento è considerato buono.
func catalog_position() -> Vector2:
	push_error("[sync] sorgente astratta: usa una sottoclasse")
	return Vector2.ZERO


## Dove PUNTA DAVVERO il tubo quando gli encoder segnano `encoder_deg`.
##
## Non è lo stato osservabile della fase: è dove va il ferro, e serve alla scena.
## Con gli encoder sfasati questo numero non coincide con quello che segnano.
func aim(_encoder_deg: Vector2) -> Vector2:
	push_error("[sync] sorgente astratta: usa una sottoclasse")
	return Vector2.ZERO


## DOVE APPARE LA STELLA rispetto al centro del reticolo, in gradi: `x` in senso
## dell'angolo orario, `y` in declinazione. Zero vuol dire centrata.
##
## È L'UNICO STATO OSSERVABILE della fase, ed è una misura e non una posizione:
## il giocatore non sa di quanto siano sfasati gli encoder, vede una stella fuori
## centro e la porta al centro. Se ricevesse «lo scarto degli encoder» starebbe
## ricevendo la risposta.
func sample(_input: SyncInput, _delta: float) -> Vector2:
	push_error("[sync] sorgente astratta: usa una sottoclasse")
	return Vector2.ZERO
