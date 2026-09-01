## Sotto-contratto tipizzato della fase del GOTO (ADR-001, Pattern 1).
##
## TRE DOMANDE, E SOLO UNA È LO STATO OSSERVABILE. `target_position()` dice dove
## il catalogo mette il soggetto adesso — è la coordinata su cui il software manda
## gli encoder. `aim()` dice dove finisce il ferro. `sample()` dice **dove si vede
## l'oggetto nel campo**, che è l'unica cosa che il giocatore guarda.
##
## LA BUGIA CHE IL GDD PROMETTE AL PUNTAMENTO passa tutta di qui: «nel planetario
## compare un oggetto che non è in nessun catalogo, e ha coordinate precise».
## Una sorgente bugiarda restituisce una posizione plausibile e un oggetto che,
## quando ci si va, non è lì — senza che la fase cambi di una riga.
class_name GotoTruthSource
extends PhaseTruthSource


## Dove il CATALOGO mette il soggetto adesso: angolo orario e declinazione, in
## gradi. È la coordinata su cui il software manda gli encoder.
##
## `NAN` se il soggetto non si trova: un id che non è in catalogo è un dato rotto,
## e la fase deve poterlo dire invece di puntare a caso.
func target_position(_input: GotoInput) -> Vector2:
	push_error("[goto] sorgente astratta: usa una sottoclasse")
	return Vector2(NAN, NAN)


## L'ALTEZZA SULL'ORIZZONTE del soggetto adesso, in gradi.
##
## Non è una comodità di interfaccia: sotto una certa altezza questa cupola non
## vede fuori affatto — il raggio esce sotto la gronda e trova la falda del tetto
## (misurato, `tools/prova_orizzonte.gd`). Un GOTO là sotto punterebbe il tubo
## contro l'intonaco, e il software di un osservatorio vero rifiuta di farlo.
func target_altitude(_input: GotoInput) -> float:
	push_error("[goto] sorgente astratta: usa una sottoclasse")
	return NAN


## Dove PUNTA DAVVERO il tubo quando gli encoder segnano `encoder_deg`, in gradi.
##
## Non è lo stato osservabile: è dove va il ferro, e serve alla scena. Con il
## modello di puntamento imperfetto questo numero non coincide con gli encoder.
func aim(_input: GotoInput) -> Vector2:
	push_error("[goto] sorgente astratta: usa una sottoclasse")
	return Vector2.ZERO


## DOVE SI VEDE L'OGGETTO rispetto al centro del campo, in gradi. Zero vuol dire
## inquadrato al centro. È l'unico stato osservabile della fase.
func sample(_input: GotoInput, _delta: float) -> Vector2:
	push_error("[goto] sorgente astratta: usa una sottoclasse")
	return Vector2.ZERO
