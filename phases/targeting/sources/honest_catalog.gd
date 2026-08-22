## La sorgente onesta della fase di targeting: dice sempre la verità.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente: la
## disponibilità che riporta è esattamente quella che l'ora corrente produce
## rispetto alla finestra di visibilità di ogni target. Modello: la sorgente
## onesta della fase polare.
##
## È QUI CHE I `.tres` DEI TARGET VENGONO LETTI, non nella fase (ADR-001): la
## fase riceve solo l'elenco già pronto da `sample()`. I dati sono `.tres`,
## iniettati via `@export`, mai JSON né `FileAccess`.
class_name HonestCatalog
extends TargetingTruthSource

## L'ora in cui comincia la notte. Duplicata dall'orologio (NightClock) e
## VERIFICATA in `test_bench` contro `NightClock.NIGHT_START_HOUR`, esattamente
## come la 2.1 fa per l'aritmetica della notte: una copia che diverga in silenzio
## collauderebbe un gioco che non esiste. Sta qui, e non in un import, perché
## `phases/` non può conoscere `night/` (regole di dipendenza).
const NIGHT_START_HOUR := 21

## Minuti in un giorno, per il modulo che chiude il wrap di mezzanotte.
const DAY_MIN := 1440

## I sei DSO di base, iniettati dal `.tres`. La sorgente li legge, la fase no.
@export var targets: Array[TargetData] = []


## Firma golden (spec § Design Notes). L'elenco e la disponibilità nascono qui e
## solo qui: la fase ne fa una sola assegnazione.
func sample(input: TargetingInput) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t in targets:
		out.append({
			&"id": t.id,
			&"short": t.short,
			&"full": t.full,
			&"type": t.type,
			&"diff": t.diff,
			&"min_exp": t.min_exp,
			&"desc": t.desc,
			&"available": _visible_at(t, input.now_min),
			&"window": "%s-%s" % [t.vis_from, t.vis_to],
		})
	return out


## Disponibile ⟺ `from_min <= now_min <= to_min`, tutti in minuti notte-relativi.
##
## La notte attraversa le 00:00, quindi non si confrontano ore da orologio: ogni
## "HH:MM" diventa minuti dall'inizio della notte con
## `((hh*60+mm) - NIGHT_START_HOUR*60 + DAY_MIN) % DAY_MIN`. Così le 04:00
## diventano 420 (dopo le 21:00) e non un numero negativo che romperebbe il
## confronto.
func _visible_at(t: TargetData, now_min: float) -> bool:
	var from_min := _to_night_min(t.vis_from)
	var to_min := _to_night_min(t.vis_to)
	return now_min >= from_min and now_min <= to_min


func _to_night_min(hhmm: String) -> int:
	# Una finestra malformata è un errore di PROGRAMMA (canale 1), non un esito
	# diegetico: i target sono `.tres` scritti a mano, e un "HH:MM" storto è un
	# dato rotto da correggere, non qualcosa che il giocatore debba vedere.
	# Degradare in silenzio a 0 direbbe «visibile alle 21:00» — sbagliato e
	# plausibile insieme, cioè il tipo di bug che il progetto vuole far urlare.
	var parts := hhmm.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		push_error("[targeting] finestra di visibilità malformata: '%s'" % hhmm)
		return 0
	var hh := int(parts[0])
	var mm := int(parts[1])
	return (hh * 60 + mm - NIGHT_START_HOUR * 60 + DAY_MIN) % DAY_MIN
