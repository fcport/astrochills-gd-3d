## Lo stack: l'immagine emerge dal rumore, sotto gli occhi del giocatore.
##
## DOVE VIVE, E PERCHÉ QUI. Come `night_summary`, è un `Control` di `night/` mostrato
## sul CRT dall'orchestratore (UX-DR1: ogni interfaccia che non sia pausa o
## impostazioni vive sullo schermo del mondo). Lo stacking non è una fase — la
## tabella dei confini vieta a `phases/` di conoscere `photo/`, e l'aggregazione
## della qualità vive in `photo/quality.gd` — quindi è `night/` a condurlo, e questa
## è la sua scena.
##
## È UN'EMERSIONE, NON UNA BARRA (AC1). Il campo parte come rumore pieno e sfuma
## verso un segnale segnaposto col crescere di `progress`: l'immagine si forma sotto
## gli occhi, non compare in fondo a un caricamento. La differenza è l'AC.
##
## PRESENT-GATED (AC4). L'imaging può finire mentre il giocatore è in cucina: se
## l'emersione partisse nel vuoto la troverebbe già finita. `_process` avanza solo
## quando l'orchestratore lo tiene attivo (via `process_mode`), come gli schermi di
## fase. Questo file non sa nulla della postazione — è `night_session` a gestire il
## gating; qui `_process` semplicemente accumula il tempo che riceve.
##
## L'IMMAGINE NON DEGRADA CON LA QUALITÀ (semplificazione MVP dichiarata, AC3): la
## rivelazione è la stessa a punteggio alto o basso. La qualità vive SOLO nel numero
## `QUALITY <n>` e nel payout della 2.5 — niente rumore residuo, niente stelle
## allungate legate al punteggio.
##
## SEGNAPOSTO VISIVO. Non c'è nessun asset fotografico: il rumore e il blob centrale
## sono disegnati a schermo. Per decisione di progetto i segnaposto visivi non si
## rifiniscono finché non arriva il pack di texture.
##
## Il testo è in inglese perché è un'interfaccia software — la lingua delle macchine.
## Disegnato per 256x192, con i colori del fosforo, come il resto del CRT.
extends Control

## L'emersione è completa: l'orchestratore può passare alla vendita (2.5).
##
## Signal DIRETTO e non `Events`: l'ascoltatore è uno solo e si sa chi è —
## l'orchestratore che possiede questo Control. Emesso UNA SOLA VOLTA quando
## `_progress` raggiunge 1.0 (guardia a flag), mai a ogni frame dopo. La 2.4 resta
## verde: nient'altro cambia in questo file.
signal revealed()

const DESIGN_SIZE := Vector2(256, 192)

const BG := Phosphor.BG
const FG := Phosphor.FG
const DIM := Phosphor.DIM

## Durata dell'emersione, in secondi di gioco. SEGNAPOSTO (FR22): un tempo
## plausibile, non tarato. `_process` riceve il `delta` scalato da `Engine.time_scale`,
## quindi `F1`-`F4` accelerano l'emersione senza che questo file lo sappia.
const REVEAL_SECONDS := 4.0

## La griglia del campo di rumore. Celle grandi: è un segnaposto, e un grano grosso
## legge meglio del pixel fine sullo schermo curvo.
const CELL := 8
const FIELD_TOP := 52
const FIELD_HEIGHT := 104

var _font: SystemFont
var _target := ""
var _quality := 0

## Quanti frame ha davvero acquisito la posa: e' cio' che si somma a schermo.
var _frames := 0
var _elapsed := 0.0
var _progress := 0.0

## Che `revealed` sia già stato emesso. Present-gated, `_process` gira solo alla
## postazione: senza la guardia l'emersione completa lo riemetterebbe a ogni frame.
var _revealed_emitted := false

## Il rumore è pseudo-casuale ma STABILE: seminato una volta, così il campo non
## sfarfalla a ogni redraw. È un `RandomNumberGenerator` locale, non l'RNG globale —
## nessuno stato condiviso, nessuna dipendenza.
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Unico ingresso. Il target dà il titolo, la qualità il numero. Da qui in poi il
## Control avanza da sé col tempo che `_process` riceve.
func set_readout(target: String, quality: int, frames: int = 0) -> void:
	_target = target
	_quality = quality
	_frames = frames
	queue_redraw()


## Avanza l'emersione col tempo di gioco. Gira SOLO quando l'orchestratore lo tiene
## attivo (present-gating via `process_mode`): fermo, `_process` non viene chiamato,
## e l'immagine resta al punto in cui era — «sotto gli occhi del giocatore».
func _process(delta: float) -> void:
	if _progress >= 1.0:
		return
	_elapsed += delta
	_progress = clampf(_elapsed / REVEAL_SECONDS, 0.0, 1.0)
	queue_redraw()
	# L'emersione è finita: lo si dice UNA VOLTA. La guardia impedisce che il ramo
	# «>= 1.0» qui sopra — che al frame dopo esce subito — riemetta comunque: al
	# frame del completamento `_progress` diventa 1.0 e questo blocco scatta, poi mai
	# più. La transizione la differisce l'orchestratore: `revealed` nasce dentro
	# questo `_process`, e liberare un nodo dentro la propria callback è vietato.
	if _progress >= 1.0 and not _revealed_emitted:
		_revealed_emitted = true
		revealed.emit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)

	var title := "STACK"
	if not _target.is_empty():
		title = "STACK — %s" % _target.to_upper()
	_text(Vector2(8, 22), title, FG, 12)
	# FR19 dice «i frame acquisiti SI SOMMANO e l'immagine emerge progressivamente».
	# Qui c'era la stringa fissa "stacking frames": una posa da 5 frame e una da 40
	# producevano la stessa identica rivelazione, e il conteggio — che esiste, viaggia
	# nel payload e finisce nel record — non toccava mai il vetro. Ora sale con
	# l'emersione, che è la metà della storia che mancava.
	var shown := int(round(_frames * _progress))
	if _frames > 0:
		_text(Vector2(8, 38), "stacking %d/%d frames" % [shown, _frames], DIM, 12)
	else:
		_text(Vector2(8, 38), "stacking frames", DIM, 12)

	_draw_field()

	# IL NUMERO ARRIVA QUANDO L'IMMAGINE C'E', non al primo fotogramma. Il criterio
	# dice «when lo stack SI CONCLUDE, then il punteggio compare»: con `_progress > 0.0`
	# il voto appariva dopo sedici millesimi di secondo, sopra un campo ancora di solo
	# rumore, e ci restava per tutti e quattro i secondi. In una storia che si chiama
	# «vedere per la prima volta cosa hai preso», il verdetto non può precedere la cosa
	# vista. In inglese (AC3).
	if _progress >= 1.0:
		_text(Vector2(8, 182), "QUALITY %d" % _quality, FG, 12)


## Il campo: rumore che sfuma verso un segnale segnaposto col crescere di `progress`.
##
## Ogni cella è un misto fra un valore di rumore (pseudo-casuale, stabile) e il
## segnale — un blob luminoso centrale la cui intensità cala con la distanza dal
## centro. A `progress = 0` è tutto rumore; a `progress = 1` è tutto segnale. Non è
## una barra: l'immagine si FORMA, non si riempie da sinistra.
func _draw_field() -> void:
	_rng.seed = 20240823
	var cols := int(DESIGN_SIZE.x) / CELL
	var rows := FIELD_HEIGHT / CELL
	var center := Vector2(cols, rows) * 0.5
	var max_dist := center.length()
	for cy in rows:
		for cx in cols:
			var noise := _rng.randf()
			# Segnale: pieno al centro, spento ai bordi. È il segnaposto — non un
			# asset, un blob che «emerge» quando il rumore si ritira.
			var dist := (Vector2(cx, cy) - center).length() / max_dist
			# `signal` è una parola riservata in GDScript: qui è il valore del
			# segnale nella cella, il blob che emerge quando il rumore si ritira.
			var signal_value := clampf(1.0 - dist, 0.0, 1.0)
			# La miscela: da rumore (progress 0) a segnale (progress 1).
			var lum := lerpf(noise, signal_value, _progress)
			var col := BG.lerp(FG, lum)
			var pos := Vector2(cx * CELL, FIELD_TOP + cy * CELL)
			draw_rect(Rect2(pos, Vector2(CELL, CELL)), col)


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
