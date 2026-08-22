## Un catalogo che mente: la disponibilità non viene dal cielo, viene dal tempo.
## Gli oggetti compaiono e scompaiono per conto proprio, e la finestra scritta nel
## `.tres` non c'entra più niente.
##
## NON È CONTENUTO. L'MVP non ha rotture — il seam esiste, le bugie no. Questa
## classe esiste per essere iniettata da `F9` e dimostrare che il vincolo di
## ADR-001 regge anche sulla seconda fase: se `phase_targeting.gd` continua a
## funzionare senza che una sua riga cambi, il seam tiene. Modello, e ragione per
## cui esiste: `WanderingDrift` della fase polare.
##
## LA BUGIA È SCELTA CON CURA. Mentire sull'ELENCO — nascondere target — sarebbe
## indistinguibile da un catalogo corto, e non proverebbe niente. Mentire sulla
## DISPONIBILITÀ colpisce esattamente lo stato che la fase osserva e disegna:
## `available` è il campo che decide «visible now» sul vetro e il dimming nella
## striscia indice. Se quello si muove da solo e la fase non se ne accorge, il
## seam è provato.
##
## Come la sorgente bugiarda della polare, accumula il proprio tempo da
## `input.now_min`: è deliberatamente slegata dalle finestre, ed è la differenza
## che si vuole poter vedere accanto a `HonestCatalog`.
class_name WanderingCatalog
extends TargetingTruthSource

## I target da mostrare: gli stessi sei. La bugia è nella disponibilità, non
## nell'elenco.
@export var targets: Array[TargetData] = []

## Periodo della finestra falsa, in minuti di gioco. Ogni target apre e chiude a
## un momento diverso, sfasato dal suo indice.
@export var period_min: float = 45.0


func sample(input: TargetingInput) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in targets.size():
		var t := targets[i]
		if t == null:
			continue
		out.append({
			&"id": t.id,
			&"short": t.short,
			&"full": t.full,
			&"type": t.type,
			&"diff": t.diff,
			&"min_exp": t.min_exp,
			&"desc": t.desc,
			# QUI STA LA BUGIA, e sta tutta in questa riga: la disponibilità è una
			# funzione del tempo e dell'indice, non della finestra del target.
			&"available": sin((input.now_min / maxf(period_min, 1.0) + float(i) * 0.37) * TAU) > 0.0,
			# La finestra dichiarata resta quella vera, e continua a essere scritta
			# sul vetro: è la contraddizione che rende la bugia VISIBILE — «not
			# visible now - 21:00-04:00» alle 22:00, con la finestra sotto gli occhi.
			&"window": "%s-%s" % [t.vis_from, t.vis_to],
		})
	return out
