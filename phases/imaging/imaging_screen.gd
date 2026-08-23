## L'interfaccia della fase di imaging, disegnata per un CRT da 256x192.
##
## È solo una vista: non calcola niente, non conosce `truth`, non sa cosa sia una
## sorgente di verità. La fase le passa un dizionario di stato con `set_readout()`
## e lei disegna. Modello/idioma: la vista della fase di targeting.
##
## DUE MODI, un dizionario solo. In CONFIG mostra i due campi da impostare —
## esposizione e numero di frame — con un selettore `>` sul campo attivo e il
## footer dei comandi. In RUN mostra la barra testuale `FRAME n/N` con il target.
## Quale dei due si disegna lo dice `state[&"running"]`, che la fase mette a true
## solo dopo l'avvio: nessun flag doppio da tenere in sync.
##
## Il testo dell'interfaccia è in INGLESE (la lingua delle macchine). Leggibile da
## seduti a 256x192.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

## Colori del fosforo verde, ripresi dalle altre viste del CRT: stessi valori.
const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)
const FAINT := Color(0.18, 0.34, 0.20)

## Il margine sinistro del testo, come nelle altre viste.
const MARGIN := 8

## Larghezza massima della barra di avanzamento, in colonne. Sta dentro i 256 px del
## CRT (con parentesi e margine) anche al numero massimo di frame; oltre questa
## soglia la barra scala invece di crescere carattere per carattere.
const BAR_COLS := 36

## I due campi del pannello di configurazione, nell'ordine in cui si scorrono con
## su/giù. L'indice `_field` seleziona una di queste righe.
const FIELD_EXPOSURE := 0
const FIELD_FRAMES := 1

## Lo stato che la fase passa. Vuoto finché `set_readout` non è chiamato: `_draw`
## non deve mai assumere una chiave presente.
var _state: Dictionary = {}

var _font: SystemFont


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso della vista. La fase chiama questo e basta.
##
## In config si attende `{running:false, field:int, exposure_sec:int,
## frame_count:int, target:String}`; in run `{running:true, frames_done:int,
## frames_total:int, target:String}`.
func set_readout(state: Dictionary) -> void:
	_state = state
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_text(Vector2(MARGIN, 15), "IMAGING / SEQUENCE", FG, 12)

	if bool(_state.get(&"running", false)):
		_draw_run()
	else:
		_draw_config()


## Il pannello di configurazione: i due campi con il selettore `>` sull'attivo, e
## il footer dei comandi. Il target si mostra come contesto: è ciò che si sta per
## fotografare.
func _draw_config() -> void:
	var target: String = _state.get(&"target", "")
	_text(Vector2(MARGIN, 33), "TARGET  %s" % (target if not target.is_empty() else "-"), DIM, 12)

	var field: int = _state.get(&"field", FIELD_EXPOSURE)
	var exposure: int = _state.get(&"exposure_sec", 0)
	var frames: int = _state.get(&"frame_count", 0)

	# Il `>` marca il campo attivo; una casella vuota lo allinea con l'altra riga
	# così i valori restano incolonnati.
	_field_row(58, field == FIELD_EXPOSURE, "EXPOSURE", "%ds" % exposure)
	_field_row(76, field == FIELD_FRAMES, "FRAMES", "%d" % frames)

	# LA CONSEGUENZA DEI DUE NUMERI, ed è la ragione per cui questo pannello esiste.
	# Prima mostrava solo i parametri: si potevano cambiare senza che cambiasse
	# niente di visibile, e alla domanda «perché dovrei?» il pannello non rispondeva.
	# Adesso queste due righe si muovono mentre si gira la manopola — quanto si
	# integra contro quanto il target chiede, e che foto ne esce.
	var total: float = _state.get(&"total_min", 0.0)
	var min_exp: int = _state.get(&"min_exp", 0)
	var score: int = _state.get(&"score", 0)

	if min_exp > 0:
		# Il totale in FG quando basta, in DIM quando no: il colore lo dice prima
		# che si legga il confronto.
		var enough := total >= float(min_exp)
		_text(Vector2(MARGIN, 108), "TOTAL    %dm  (min %dm)" % [roundi(total), min_exp],
			FG if enough else DIM, 12)
	else:
		_text(Vector2(MARGIN, 108), "TOTAL    %dm" % roundi(total), DIM, 12)
	_text(Vector2(MARGIN, 128), "QUALITY  %d" % score, FG, 12)

	# È anche quanto dura l'attesa: la posa occupa la notte per lo stesso tempo che
	# integra. Detto qui perché è il costo della scelta, non un dettaglio tecnico.
	_text(Vector2(MARGIN, 148), "the sequence will take %dm of the night" % roundi(total),
		DIM, 10)

	_text(Vector2(MARGIN, 168), "UP/DOWN FIELD  LEFT/RIGHT VALUE", DIM, 10)
	_text(Vector2(MARGIN, 184), "ENTER START", DIM, 12)


func _field_row(y: int, active: bool, label: String, value: String) -> void:
	var marker := ">" if active else " "
	var color := FG if active else DIM
	_text(Vector2(MARGIN, y), "%s %-10s %s" % [marker, label, value], color, 12)


## Il pannello in posa: la barra testuale `FRAME n/N` che cresce, più il target.
## Nessuna grafica pesante — è un CRT, e la fase può girare in background: si conta
## il tempo, non si anima.
func _draw_run() -> void:
	var target: String = _state.get(&"target", "")
	_text(Vector2(MARGIN, 33), "TARGET  %s" % (target if not target.is_empty() else "-"), DIM, 12)

	var done: int = _state.get(&"frames_done", 0)
	var total: int = _state.get(&"frames_total", 0)
	_text(Vector2(MARGIN, 66), "FRAME %d/%d" % [done, total], FG, 16)

	# Quanto manca, in minuti di notte. È la domanda che si fa chi sta aspettando, e
	# finché non c'era risposta l'unico modo di saperlo era guardare la barra e
	# indovinare.
	var left: float = _state.get(&"remaining_min", 0.0)
	if left > 0.0:
		_text(Vector2(MARGIN, 108), "about %dm left" % maxi(roundi(left), 1), DIM, 12)

	# Barra testuale: un blocco per frame acquisito, un trattino per quelli ancora
	# da fare. La larghezza è LIMITATA a `BAR_COLS` colonne perché stia nei 256 px del
	# CRT anche al massimo dei frame (FRAMES_MAX = 60): fino a quella soglia è un
	# blocco per frame (proporzione esatta), oltre si scala. Senza il tetto, a 60
	# frame la barra uscirebbe dal vetro — il difetto «metà schermo fuori» della 1.3.
	if total > 0:
		var cols := mini(total, BAR_COLS)
		var lit := clampi(roundi(float(done) / float(total) * cols), 0, cols)
		var filled := "#".repeat(lit)
		var empty := "-".repeat(cols - lit)
		_text(Vector2(MARGIN, 90), "[%s%s]" % [filled, empty], DIM, 10)

	if bool(_state.get(&"done", false)):
		_text(Vector2(MARGIN, 120), "SEQUENCE COMPLETE", FG, 12)
	else:
		_text(Vector2(MARGIN, 120), "working...", DIM, 12)

	_text(Vector2(MARGIN, 184), "YOU CAN WALK AWAY", DIM, 10)


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
