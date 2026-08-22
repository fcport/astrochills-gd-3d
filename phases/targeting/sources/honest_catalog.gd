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

## I target che hanno superato la validazione, con la loro finestra già in minuti
## notte-relativi. Un target che non entra qui non esiste per il gioco.
var _valid: Array[TargetData] = []
var _window: Array[Vector2i] = []
var _validated := false


## Firma golden (spec § Design Notes). L'elenco e la disponibilità nascono qui e
## solo qui: la fase ne fa una sola assegnazione.
func sample(input: TargetingInput) -> Array[Dictionary]:
	# LA VALIDAZIONE STA FUORI DAL PERCORSO CALDO, e non per prestazioni: è ciò
	# che rende leggibile la diagnosi. `sample()` viene chiamata da `_process`,
	# quindi un `push_error` qui dentro si ripeterebbe sessanta volte al secondo
	# e seppellirebbe qualunque altro errore nel log. Un dato rotto va detto una
	# volta, forte, all'ingresso.
	if not _validated:
		_validate()

	var out: Array[Dictionary] = []
	for i in _valid.size():
		var t := _valid[i]
		out.append({
			&"id": t.id,
			&"short": t.short,
			&"full": t.full,
			&"type": t.type,
			&"diff": t.diff,
			&"min_exp": t.min_exp,
			&"desc": t.desc,
			&"available": _visible_at(i, input.now_min),
			&"window": "%s-%s" % [t.vis_from, t.vis_to],
		})
	return out


## Disponibile ⟺ `from_min <= now_min <= to_min`, tutti in minuti notte-relativi.
##
## Nessuna riconversione qui: gli estremi sono già stati calcolati e validati una
## volta sola da `_validate()`. Se un target è arrivato fin qui, la sua finestra
## è esprimibile.
func _visible_at(i: int, now_min: float) -> bool:
	var w := _window[i]
	return now_min >= w.x and now_min <= w.y


## IL FILTRO ALL'INGRESSO. Un target che non lo supera viene ESCLUSO, non
## degradato: un catalogo più corto è un guasto visibile, un catalogo pieno di
## voci sbagliate ma plausibili è il guasto che non si trova più.
##
## I `.tres` dei DSO sono scritti a mano e in crescita (arrivano da `dso_base.js`,
## e i cataloghi dell'epica 3 ne porteranno altri): ogni forma di dato rotto qui
## sotto è un refuso che qualcuno commetterà davvero.
func _validate() -> void:
	_validated = true
	_valid.clear()
	_window.clear()

	for t in targets:
		# Una casella vuota nell'array: l'inspector la crea da sola quando si
		# incrementa la dimensione per aggiungere un target, e si salva prima di
		# riempirla. Saltarla è la stessa cortesia che `night_session` fa a una
		# casella vuota del piano della notte.
		if t == null:
			push_error("[targeting] casella vuota nell'elenco dei target: saltata")
			continue

		# L'id viaggia nel payload verso l'imaging. Senza, la 2.3 riceverebbe una
		# scelta vuota da una fase che si è dichiarata riuscita, e il guasto
		# emergerebbe una fase più in là di dove è nato.
		if t.id.is_empty():
			push_error("[targeting] target senza id ('%s'): saltato" % t.short)
			continue

		var from_min := _to_night_min(t.vis_from, t.short)
		var to_min := _to_night_min(t.vis_to, t.short)
		if from_min < 0 or to_min < 0:
			continue

		# Una finestra che attraversa l'inizio della notte NON È ESPRIMIBILE in
		# minuti notte-relativi: `from` finisce in fondo alla giornata e `to`
		# all'inizio, quindi `from <= now <= to` è falsa per ogni istante e il
		# target sparirebbe dal cielo per tutta la notte, in silenzio. Succede
		# con qualunque `vis_from` precedente alle 21:00 — un DSO circumpolare
		# «05:00-22:00» è esattamente questo caso, e non è un dato assurdo.
		if from_min > to_min:
			push_error(
				"[targeting] %s: la finestra %s-%s attraversa l'inizio della notte (%02d:00) e non è rappresentabile: saltato"
				% [t.short, t.vis_from, t.vis_to, NIGHT_START_HOUR])
			continue

		_valid.append(t)
		_window.append(Vector2i(from_min, to_min))

	if _valid.is_empty() and not targets.is_empty():
		push_error("[targeting] nessun target valido su %d: il catalogo è vuoto" % targets.size())


## "HH:MM" da orologio -> minuti dall'inizio della notte. `-1` significa dato
## rotto, e chi chiama deve escludere il target invece di usare il numero.
##
## Il valore di ripiego NON è zero. Zero è un'ora legittima — «disponibile dalle
## 21:00» — e un dato rotto che si traveste da dato valido è precisamente il tipo
## di guasto che questo progetto vuole far urlare invece che sussurrare.
func _to_night_min(hhmm: String, who: String) -> int:
	var parts := hhmm.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		push_error("[targeting] %s: finestra malformata '%s' (atteso HH:MM)" % [who, hhmm])
		return -1

	var hh := int(parts[0])
	var mm := int(parts[1])
	# `is_valid_int()` accetta "25", "-1" e "75": senza questo controllo un refuso
	# di una cifra diventa un'ora plausibile e sbagliata — "25:00" si trasforma
	# nell'01:00 e il target si spegne quattro ore prima del previsto.
	if hh < 0 or hh > 23 or mm < 0 or mm > 59:
		push_error("[targeting] %s: ora fuori scala '%s' (atteso 00:00-23:59)" % [who, hhmm])
		return -1

	return (hh * 60 + mm - NIGHT_START_HOUR * 60 + DAY_MIN) % DAY_MIN
