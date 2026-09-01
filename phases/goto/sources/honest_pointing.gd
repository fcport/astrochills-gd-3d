## La sorgente onesta del GOTO: il soggetto sta dove il catalogo dice.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente: l'unica
## ragione per cui l'oggetto non arriva al centro è che il modello di puntamento
## della montatura è imperfetto — e lo è per due motivi veri, che si sommano.
##
## PRIMO: L'ERRORE RESIDUO DELLA FASE 5. Chi ha centrato male la stella di
## taratura ha agganciato gli encoder al cielo con quello scarto dentro, e se lo
## porta dietro tutta la notte.
##
## SECONDO, E PIÙ INTERESSANTE: L'ASSE POLARE STORTO. Sincronizzare su una stella
## raddrizza il puntamento LÌ, non dappertutto. Con l'asse polare fuori squadra
## l'errore ricresce man mano che ci si allontana dal punto sincronizzato — ed è
## proprio quello che succede a questa montatura, il cui asse misura 43,1 gradi
## contro una latitudine di 43,9 (la misura è in `world/telescope_mount.gd`). È il
## motivo per cui gli osservatori sincronizzano di nuovo prima di ogni soggetto, e
## per cui vale la pena comprare il plate solving.
##
## DOVE STA L'OGGETTO: L'ANGOLO ORARIO SI RICAVA DALLA FINESTRA. I sei soggetti
## portano la declinazione vera di catalogo ma non l'ascensione retta, perché le
## loro finestre di visibilità non appartengono alla stessa notte e le due cose si
## contraddirebbero (vedi `data/targets/target_data.gd`). Il modello è dichiarato
## e sta in una riga: **il centro della finestra è il passaggio in meridiano**, e
## ci si allontana di quindici gradi per ogni ora. Un oggetto è al meglio quando è
## alto, la finestra dice quando è al meglio, quindi la finestra dice quando passa
## in meridiano. È coerente con i dati che ci sono invece di aggiungerne di
## incompatibili.
class_name HonestPointing
extends GotoTruthSource

## L'ora in cui comincia la notte. Duplicata dall'orologio (`NightClock`) e
## VERIFICATA nel banco contro `NightClock.NIGHT_START_HOUR`, esattamente come fa
## `HonestCatalog`: `phases/` non può conoscere `night/`, e una copia che diverga
## in silenzio collauderebbe un gioco che non esiste.
const NIGHT_START_HOUR := 21

## Minuti in un giorno, per il modulo che chiude il wrap di mezzanotte.
const DAY_MIN := 1440

## Gradi di angolo orario per ogni minuto di tempo. Il cielo gira di quindici
## gradi all'ora, cioè un quarto di grado al minuto.
const GRADI_AL_MINUTO := 0.25

## I sei DSO, iniettati dal `.tres`. Gli stessi che legge il targeting: la
## sorgente li legge, la fase no.
@export var targets: Array[TargetData] = []

## DI QUANTO RICRESCE L'ERRORE allontanandosi dal punto sincronizzato: gradi di
## errore per grado di spostamento.
##
## NOVE MILLESIMI, E IL NUMERO NON È DI GUSTO: viene dagli otto decimi di grado di
## disallineamento polare misurati su questa montatura. Un asse storto di 0,8°
## produce, attraversando novanta gradi di cielo, fino a 0,8° di errore di
## puntamento — cioè 0,8/90 per grado. Il giorno in cui l'asse verrà raddrizzato
## questo numero scenderà con lui, ed è giusto che sia così.
@export var deriva: float = 0.009

## QUANTO SBAGLIA UNA MONTATURA MAI SINCRONIZZATA, in gradi.
##
## SERVE PERCHE' ZERO SAREBBE UNA BUGIA AL CONTRARIO. Senza la fase 5 gli encoder
## non sono agganciati a niente: il GOTO va dove va, e quanto sbaglia lo sa solo
## la montatura. Restituire zero direbbe che saltare la sincronizzazione non costa
## niente — cioe' esattamente il contrario di quello che la fase 5 esiste per
## insegnare. Un grado e mezzo e' il centro della fascia in cui `HonestStar`
## estrae lo sfasamento all'accensione.
##
## Con il piano di stanotte questo ramo non si raggiunge: la fase 5 e' di setup e
## viene sempre prima. Vale se un upgrade un giorno la togliera' dal piano.
@export var errore_senza_sync: float = 1.5

var _indice: Dictionary = {}
var _indicizzato := false
var _cieco := Vector2(INF, INF)


func _indicizza() -> void:
	_indicizzato = true
	for t in targets:
		if t == null or t.id == &"":
			# Un dato rotto si dice UNA VOLTA, all'ingresso, e non a ogni
			# fotogramma da dentro `sample()`: stessa regola di `HonestCatalog`.
			push_error("[goto] un target del catalogo non ha id: lo salto")
			continue
		_indice[t.id] = t


func _cerca(id: StringName) -> TargetData:
	if not _indicizzato:
		_indicizza()
	return _indice.get(id, null) as TargetData


## "HH:MM" da orologio in minuti dall'inizio della notte. Stessa conversione di
## `HonestCatalog`, e per lo stesso motivo: le finestre attraversano mezzanotte.
func _notte_relativo(hhmm: String) -> float:
	var parti := hhmm.split(":")
	if parti.size() != 2:
		return NAN
	var m := int(parti[0]) * 60 + int(parti[1])
	return float(posmod(m - NIGHT_START_HOUR * 60, DAY_MIN))


func target_position(input: GotoInput) -> Vector2:
	var t := _cerca(input.target_id)
	if t == null:
		return Vector2(NAN, NAN)
	var da := _notte_relativo(t.vis_from)
	var a := _notte_relativo(t.vis_to)
	if is_nan(da) or is_nan(a) or a <= da:
		return Vector2(NAN, NAN)
	# Il centro della finestra è il meridiano: da lì, un quarto di grado al minuto.
	var meridiano := (da + a) * 0.5
	return Vector2((input.now_min - meridiano) * GRADI_AL_MINUTO, t.dec_gradi)


## La formula sta in `SkyGeometry` e non qui: la usa anche il planetario, e
## scritta due volte offrirebbe soggetti che poi il GOTO non raggiunge.
func target_altitude(input: GotoInput) -> float:
	var p := target_position(input)
	if is_nan(p.x):
		return NAN
	return SkyGeometry.altezza(p.x, p.y)


## L'errore del modello di puntamento nel punto `dove`, in gradi.
##
## Prima della fase 5 non c'è nessun modello: gli encoder sono agganciati al
## niente, e l'errore è quello che è — cioè grande e sconosciuto. Dopo, è il
## residuo della sincronizzazione più quanto è ricresciuto allontanandosi.
func _errore(input: GotoInput, dove: Vector2) -> Vector2:
	if not input.sync_done:
		if is_inf(_cieco.x):
			# Una direzione qualunque, estratta una volta: e' dove la montatura
			# si e' svegliata, e nessuno l'ha misurato.
			var ang := randf() * TAU
			_cieco = Vector2(cos(ang), sin(ang)) * errore_senza_sync
		return _cieco
	return input.sync_error_deg + (dove - input.sync_point_deg) * deriva


func aim(input: GotoInput) -> Vector2:
	return input.encoder_deg - _errore(input, input.encoder_deg)


## L'oggetto si vede dove sta davvero, visto da dove punta il tubo.
##
## FUNZIONE PURA DI `input`: nessuno stato che cambi, `delta` mai usato.
func sample(input: GotoInput, _delta: float) -> Vector2:
	var p := target_position(input)
	if is_nan(p.x):
		return Vector2.ZERO
	return p - aim(input)
