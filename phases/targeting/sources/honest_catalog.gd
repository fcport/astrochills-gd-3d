## La sorgente onesta della fase di targeting: dice sempre la verità.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente: dove sta un
## soggetto, e se questa cupola lo raggiunge, lo dice il cielo vero di quella notte a
## quell'ora — ascensione retta e declinazione di catalogo, e il tempo siderale di
## `Luna` (D-261). Modello: la sorgente onesta della fase polare.
##
## È QUI CHE I `.tres` DEI TARGET VENGONO LETTI, non nella fase (ADR-001): la
## fase riceve solo l'elenco già pronto da `sample()`. I dati sono `.tres`,
## iniettati via `@export`, mai JSON né `FileAccess`.
##
## DUE COSE TENGONO UN SOGGETTO FUORI DALL'ELENCO, e nessuna delle due è una bugia.
##   - IL SUO CATALOGO NON È STATO COMPRATO. Un soggetto con `catalogo` compare solo
##     se quell'articolo è fra quelli del giocatore.
##   - DA QUI NON SI VEDE. Se in nessuna delle venti notti sta sopra l'orizzonte della
##     cupola per almeno `MINUTI_MINIMI`, il planetario non lo offre: M42, M13, M8 e
##     gli altri che a novembre da questo monte non si vedono. I loro dati restano,
##     perché li porteranno in cielo gli orrori cosmici — con un'altra sorgente, che
##     mente, e non con questa.
class_name HonestCatalog
extends TargetingTruthSource

## L'ora in cui comincia la notte. Duplicata dall'orologio (NightClock) e
## VERIFICATA in `test_bench` contro `NightClock.NIGHT_START_HOUR`, esattamente
## come la 2.1 fa per l'aritmetica della notte: una copia che diverga in silenzio
## collauderebbe un gioco che non esiste. Sta qui, e non in un import, perché
## `phases/` non può conoscere `night/` (regole di dipendenza).
const NIGHT_START_HOUR := 21

## Minuti in un giorno, per scrivere la finestra con l'ora dell'orologio.
const DAY_MIN := 1440

## Le notti della storia: un soggetto si offre se si vede almeno in una di queste.
const NOTTI := 20

## Quanto dura il turno, in minuti: dalle 21:00 alle 06:00.
const DURATA_TURNO_MIN := 540

## Ogni quanti minuti si guarda il cielo per trovare la finestra di una notte.
const PASSO_MIN := 5

## SOTTO UN'ORA NON È UN SOGGETTO. NGC 7000 la prima notte sta sopra la cupola
## venticinque minuti, e dalla quinta mai: offrirlo vorrebbe dire mandare il
## giocatore verso una posa che non comincia. M51, che sorge sopra la gronda solo
## all'alba, a fine mese ci resta un'ora e mezza, e resta.
const MINUTI_MINIMI := 60

## Tutti i soggetti, iniettati dal `.tres`: quelli dell'osservatorio e quelli dei
## cataloghi. La sorgente li legge, la fase no.
@export var targets: Array[TargetData] = []

## I target che hanno superato la validazione. Un target che non entra qui non
## esiste per il gioco.
var _valid: Array[TargetData] = []

## Le sigle dei soggetti che da questa cupola non si vedono mai.
var _nascosti := PackedStringArray()
var _validated := false

## Le finestre già calcolate: {night_index: {id: "HH:MM-HH:MM", o "" se mai}}.
## Il cielo di una notte non cambia mentre la si gioca, e rifarne il conto sessanta
## volte al secondo non lo renderebbe più vero.
var _finestre: Dictionary = {}


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
	for t in _valid:
		if not t.catalogo.is_empty() and not input.owned.has(t.catalogo):
			continue
		var alt := altezza_di(t, input.night_index, input.now_min)
		var finestra := _finestra(t, input.night_index)
		var available := alt >= SkyGeometry.ORIZZONTE_CUPOLA
		out.append({
			&"id": t.id,
			&"short": t.short,
			&"full": t.full,
			&"type": t.type,
			&"diff": t.diff,
			&"min_exp": t.min_exp,
			&"desc": t.desc,
			# DUE RAGIONI DIVERSE PER NON POTERLO FOTOGRAFARE, e il vetro le dice
			# diverse. «Non adesso» è un'attesa: stanotte passa sopra la cupola, e la
			# finestra dice quando tornarci. «Non stanotte» è un rifiuto: il raggio
			# esce sotto la gronda e trova la falda del tetto (misurato,
			# `tools/prova_orizzonte.gd`). Un planetario che le confondesse
			# manderebbe il giocatore ad aspettare una cosa che non arriva.
			&"in_window": available or finestra.is_empty(),
			&"available": available,
			&"alt": alt,
			&"window": finestra,
		})
	return out


## Quanto è alto sull'orizzonte il soggetto, la notte `night_index` dopo `now_min`
## minuti di turno, in gradi. Il GOTO lo chiede alla stessa `SkyGeometry`: un
## soggetto offerto dal planetario deve essere quello che il telescopio raggiunge.
static func altezza_di(t: TargetData, night_index: int, now_min: float) -> float:
	return SkyGeometry.altezza(
		SkyGeometry.angolo_orario(t.ar_gradi, night_index, now_min), t.dec_gradi)


## Le sigle dei soggetti che da questa cupola non si vedono in nessuna notte. Per il
## banco e per le sonde.
func nascosti() -> PackedStringArray:
	if not _validated:
		_validate()
	return _nascosti


## La finestra di stanotte, "HH:MM-HH:MM", o "" se il soggetto non passa mai sopra
## la cupola in questa notte.
func _finestra(t: TargetData, night_index: int) -> String:
	var notte: Dictionary = _finestre.get(night_index, {})
	if not notte.has(t.id):
		var sopra := _sopra(t, night_index)
		notte[t.id] = "" if sopra.x < 0 else "%s-%s" % [_orologio(sopra.x), _orologio(sopra.y)]
		_finestre[night_index] = notte
	return notte[t.id]


## Il primo e l'ultimo minuto di turno in cui il soggetto sta sopra la cupola, e per
## quanti minuti in tutto: (primo, ultimo, quanti). Il primo è -1 se non ci sta mai.
func _sopra(t: TargetData, night_index: int) -> Vector3i:
	var primo := -1
	var ultimo := -1
	var quanti := 0
	for m in range(0, DURATA_TURNO_MIN + 1, PASSO_MIN):
		if altezza_di(t, night_index, float(m)) >= SkyGeometry.ORIZZONTE_CUPOLA:
			if primo < 0:
				primo = m
			ultimo = m
			quanti += PASSO_MIN
	return Vector3i(primo, ultimo, quanti)


## Minuti di turno in ora dell'orologio.
static func _orologio(m: int) -> String:
	var assoluto := (NIGHT_START_HOUR * 60 + m) % DAY_MIN
	return "%02d:%02d" % [floori(assoluto / 60.0), assoluto % 60]


## IL FILTRO ALL'INGRESSO. Un target che non lo supera viene ESCLUSO, non
## degradato: un catalogo più corto è un guasto visibile, un catalogo pieno di
## voci sbagliate ma plausibili è il guasto che non si trova più.
func _validate() -> void:
	_validated = true
	_valid.clear()
	_nascosti.clear()

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

		# COORDINATE FUORI SCALA: un'ascensione retta in ore invece che in gradi, un
		# segno perso sulla declinazione. Il primo refuso mette un soggetto dall'altra
		# parte del cielo, e da lì non urla nessuno.
		if t.ar_gradi < 0.0 or t.ar_gradi >= 360.0 or absf(t.dec_gradi) > 90.0:
			push_error("[targeting] %s: coordinate fuori scala (AR %.2f, dec %.2f): saltato"
				% [t.short, t.ar_gradi, t.dec_gradi])
			continue

		if _meglio_del_mese(t) < MINUTI_MINIMI:
			_nascosti.append(t.short)
			continue

		_valid.append(t)

	if _valid.is_empty() and not targets.is_empty():
		push_error("[targeting] nessun target valido su %d: il catalogo è vuoto" % targets.size())


## Quanti minuti, nella notte migliore del mese, il soggetto sta sopra la cupola. Si
## ferma appena arriva a `MINUTI_MINIMI`: quello che serve sapere è se ci arriva.
func _meglio_del_mese(t: TargetData) -> int:
	var meglio := 0
	for n in range(1, NOTTI + 1):
		meglio = maxi(meglio, _sopra(t, n).z)
		if meglio >= MINUTI_MINIMI:
			break
	return meglio
