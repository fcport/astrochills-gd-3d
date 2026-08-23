## Il riepilogo dell'alba, sul CRT come tutto il resto.
##
## DOVE VIVE, E PERCHÉ QUI. Il rilievo M2 lasciava aperta la scelta fra il CRT
## diegetico e un'eccezione dichiarata a UX-DR1. È il CRT: UX-DR1 vuole che ogni
## interfaccia che non sia pausa o impostazioni viva sullo schermo del mondo, e
## UX-DR10 ha già fissato lo stesso precedente per il payout — «evento diegetico,
## non popup di gioco sopra la scena».
##
## IL PREZZO, e va detto invece che scoperto. All'alba il giocatore può essere in
## cucina, e questo riepilogo non lo insegue: lo trova tornando al monitor.
## «L'alba mostra il riepilogo» significa che il riepilogo è lì, non che venga
## portato davanti agli occhi di chi è in un'altra stanza. Trascinare il giocatore
## alla scrivania sarebbe l'unica alternativa, e romperebbe ADR-003, che la
## sedersi lo costruisce come gesto volontario.
##
## Il testo è in inglese perché è un'interfaccia software: la lingua delle
## macchine. I commenti sono in italiano, che è la lingua di chi ci lavora.
##
## Disegnato per 256x192, come la vista della fase polare, e con gli stessi
## colori del fosforo: sono stati scelti guardando lo schermo curvo, non stimati.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)

var _font: SystemFont
var _night_index := 1
var _earnings := 0
var _photos := 0
var _clock_text := ""
var _scores: Array[Vector2i] = []
var _score_keys: PackedStringArray = PackedStringArray()

## Quanto c'è in cassa DOPO che stanotte sarà stata versata. Lo compone il
## chiamante e non questo Control: all'alba `Game.end_night()` non è ancora stata
## chiamata, quindi `Game.profile.wallet_lire` è ancora il saldo di ieri. Vedi
## `night_session._show_summary()`.
var _wallet := 0


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso. Si legge la `NightRun` una volta sola, all'alba: da qui in poi
## questo Control non guarda più niente, e non deve — la notte è finita.
func set_readout(run: NightRun, clock_text: String, wallet_lire: int) -> void:
	_clock_text = clock_text
	_wallet = wallet_lire
	if run == null:
		return
	_night_index = run.night_index
	_earnings = run.night_earnings
	_photos = run.photos.size()
	_score_keys = PackedStringArray()
	_scores = []
	for k in run.phase_scores:
		_score_keys.append(String(k).to_upper())
		_scores.append(Vector2i(int(run.phase_scores[k]), 0))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_text(Vector2(8, 22), "NIGHT %d — DAWN" % _night_index, FG, 12)
	_text(Vector2(8, 38), "21:00 → %s" % _clock_text, DIM, 12)

	# QUANTO HA RESO LA NOTTE. Prima non compariva da nessuna parte: le lire venivano
	# accreditate e nessuno le leggeva mai — `end_night()` non era chiamata, il segnale
	# `photo_sold` non aveva ascoltatori, e il riepilogo parlava solo di punteggi. Si
	# poteva lavorare una notte intera senza vedere una cifra.
	var plural := "" if _photos == 1 else "s"
	_text(Vector2(8, 54), "%d photo%s - %d lire tonight" % [_photos, plural, _earnings], DIM, 12)

	# IL TOTALE IN CASSA, ed è la riga per cui questo riepilogo esiste. Il guadagno
	# della notte da solo non dice niente: dice quanto ha reso una serata, non se il
	# lavoro sta arrivando da qualche parte. Le lire attraversano le notti (C1), e
	# fino a qui NON c'era un solo posto nel gioco in cui leggerle — si giocava alla
	# cieca sull'unica risorsa che si accumula. In FG, più grande delle altre: fra
	# le righe di questa schermata è quella che si guarda.
	_text(Vector2(8, 74), "WALLET  %d lire" % _wallet, FG, 14)

	var y := 104
	if _score_keys.is_empty():
		_text(Vector2(8, y), "NOTHING RECORDED", DIM, 12)
	else:
		_text(Vector2(8, 96), "PHASE SCORES", DIM, 12)
		for i in _score_keys.size():
			_text(Vector2(8, y), "%-14s %3d" % [_score_keys[i], _scores[i].x], DIM, 12)
			y += 15

	_text(Vector2(8, 172), "the sky is getting light", DIM, 12)


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
