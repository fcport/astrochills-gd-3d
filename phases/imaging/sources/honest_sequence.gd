## La sorgente onesta della fase di imaging: dice sempre la verità.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente: il numero
## di frame acquisiti è esattamente quello che il tempo trascorso produce rispetto
## a `min_per_frame`. Modello: la sorgente onesta della fase di targeting.
##
## LOGICA PURA E DETERMINISTICA. Non legge `Tuning`, non tiene tempo per conto
## proprio, non ha stato fra una chiamata e l'altra: `min_per_frame` e il tempo
## trascorso arrivano nell'input. Stesso input, stesso output — è ciò che il banco
## collauda, ed è ciò che permette alla fase di tenersi il proprio orologio.
class_name HonestSequence
extends ImagingTruthSource


## Firma golden (spec § Tasks). Il conteggio dei frame nasce qui e solo qui: la
## fase ne fa una sola assegnazione.
func sample(input: ImagingInput) -> Dictionary:
	var frames_total := input.frames_total

	# `min_per_frame <= 0` NON è una scelta: è un Tuning corrotto (override esterno
	# battuto male). Dividere per zero o per un negativo darebbe INF o un conteggio
	# a ritroso; qui la sequenza si chiude subito — mai un'attesa infinita — e lo
	# dice una volta, non sessanta volte al secondo, perché `_process` chiama questo
	# a ogni frame.
	var frames_done: int
	if input.min_per_frame <= 0.0:
		push_error("[imaging] min_per_frame <= 0 (Tuning corrotto): chiudo la sequenza subito")
		frames_done = frames_total
	else:
		# `floori`: un frame è acquisito solo quando il suo tempo è TRASCORSO per
		# intero. A 2.5 * min_per_frame sono passati due frame, non due e mezzo.
		# `clampi`: mai sotto zero (tempo negativo non esiste), mai oltre il totale
		# (la sequenza non acquisisce più frame di quanti richiesti).
		frames_done = clampi(
			floori(input.elapsed_since_start_min / input.min_per_frame), 0, frames_total)

	var done := frames_done >= frames_total
	return {
		&"frames_done": frames_done,
		&"frames_total": frames_total,
		# `running` è il complemento di `done`: finché non ha finito, sta lavorando.
		&"running": not done,
		&"done": done,
	}
