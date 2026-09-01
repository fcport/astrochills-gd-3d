## L'interfaccia della fase dell'accensione, disegnata per un CRT da 256x192.
##
## È solo una vista: non calcola niente, non conosce `truth`, non sa chi alimenta
## chi. La fase le passa quattro maschere di bit e una riga di testo, e lei
## disegna. Modello e idioma: la vista della fase del fuoco.
##
## I NOMI DEGLI APPARECCHI ARRIVANO DALLA FASE, non stanno qui: scritti in due
## posti, il giorno in cui ne cambia uno lo schermo direbbe una cosa e il
## messaggio d'errore un'altra, e nessun collaudo se ne accorgerebbe.
##
## UNA TABELLA E NON UN DISEGNO, ed è l'unica scelta di stile che questa vista
## fa: è ciò che mostrerebbe il software di controllo di un osservatorio nel '99,
## perché è ciò che serve — quattro colonne che dicono chi c'è, dove sta, se ha
## corrente e se risponde. Le due fasi vicine (cupola e fuoco) disegnano una
## sezione e un grafico; questa non ha niente da disegnare, e fingere il contrario
## vorrebbe dire mettere un'illustrazione al posto di un'informazione.
##
## Il testo dell'interfaccia è in INGLESE: è la lingua delle macchine.
extends Control

const DESIGN_SIZE := Vector2(256, 192)

## Colori del fosforo verde, gli stessi delle altre viste.
const BG := Color(0.02, 0.06, 0.03)
const FG := Color(0.62, 1.0, 0.68)
const DIM := Color(0.30, 0.58, 0.34)
const FAINT := Color(0.18, 0.34, 0.20)

const MARGIN := 8

## Le colonne, in pixel. Fisse e non calcolate: sono tre righe, e un incolonnatore
## automatico sarebbe più codice di quello che risolve.
const COL_NAME := 22
const COL_PORT := 104
const COL_POWER := 160
const COL_LINK := 208

## La prima riga della tabella e il passo fra una e l'altra.
const ROW_TOP := 62
const ROW_STEP := 18

var _font: SystemFont

var _names: Array[String] = []
var _ports: Array[String] = []
var _switched: Array[bool] = []

var _powered := 0
var _attempted := 0
var _answering := 0
var _cursor := 0
var _busy := -1
var _message := ""
var _log: Array[String] = []


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


## Chi sono gli apparecchi. La fase lo dice una volta sola, appena montata.
func set_devices(names: Array[String], ports: Array[String],
		switched: Array[bool]) -> void:
	_names = names
	_ports = ports
	_switched = switched
	queue_redraw()


## Unico ingresso di stato. La fase chiama questo e basta.
func set_readout(powered: int, attempted: int, answering: int,
		cursor: int, busy: int, message: String, log_lines: Array[String]) -> void:
	_powered = powered
	_attempted = attempted
	_answering = answering
	_cursor = cursor
	_busy = busy
	_message = message
	_log = log_lines
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	_text(Vector2(MARGIN, 15), "STARTUP", FG, 12)
	var quanti := "%d/%d LINKED" % [_quanti(_answering), _names.size()]
	_text(Vector2(DESIGN_SIZE.x - MARGIN - _width(quanti), 15), quanti, DIM, 12)
	draw_line(Vector2(MARGIN, 22), Vector2(DESIGN_SIZE.x - MARGIN, 22), FAINT, 1.0)

	_intestazione()
	for i in _names.size():
		_riga(i)

	_registro()
	if _message != "":
		_text(Vector2(MARGIN, 164), _message, FG, 11)
	_piede()


## Il registro del software: quello che è successo, dal più vecchio al più nuovo.
##
## SCORRE VERSO L'ALTO e la riga nuova sta in fondo, come su una telescrivente e
## come in ogni console che il giocatore abbia mai visto. Le vecchie sbiadiscono:
## contano meno, e un blocco di quattro righe tutte uguali di peso si legge come
## un muro invece che come una storia.
func _registro() -> void:
	var y := 124
	var quante := _log.size()
	for i in quante:
		var eta := quante - 1 - i
		var colore := FG if eta == 0 else (DIM if eta == 1 else FAINT)
		_text(Vector2(MARGIN, y + i * 11), "> " + _log[i], colore, 11)


func _intestazione() -> void:
	var y := 44
	_text(Vector2(COL_NAME, y), "DEVICE", FAINT, 11)
	_text(Vector2(COL_PORT, y), "PORT", FAINT, 11)
	_text(Vector2(COL_POWER, y), "PWR", FAINT, 11)
	_text(Vector2(COL_LINK, y), "LINK", FAINT, 11)


## Una riga della tabella.
##
## LA SPIA DELLA CORRENTE È UN QUADRATO E NON UNA PAROLA: sono tre righe da
## scorrere con l'occhio mentre si cerca quale non risponde, e tre quadratini
## accesi si contano senza leggere. La riga della ruota portafiltri non ne ha:
## non ha un interruttore, e disegnarle una spia spenta vorrebbe dire dire una
## bugia — che c'è un interruttore, e che qualcuno l'ha lasciato giù.
func _riga(i: int) -> void:
	var y := ROW_TOP + i * ROW_STEP
	var bit := 1 << i
	var qui := i == _cursor
	if qui:
		_text(Vector2(MARGIN, y), ">", FG, 12)
	var colore := FG if qui else DIM
	_text(Vector2(COL_NAME, y), _names[i], colore, 12)
	_text(Vector2(COL_PORT, y), _ports[i], DIM, 12)

	var ha_interruttore := _switched[i] if i < _switched.size() else true
	if not ha_interruttore:
		_text(Vector2(COL_POWER, y), "-", FAINT, 12)
	else:
		var acceso := _powered & bit != 0
		var box := Rect2(COL_POWER, y - 9, 9, 9)
		draw_rect(box, FG if acceso else BG)
		draw_rect(box, FG if acceso else FAINT, false, 1.0)

	_text(Vector2(COL_LINK, y), _stato_link(i, bit), _colore_link(i, bit), 12)


func _stato_link(i: int, bit: int) -> String:
	if _busy == i:
		return "WAIT"
	if _attempted & bit == 0:
		return "--"
	return "OK" if _answering & bit != 0 else "NONE"


func _colore_link(i: int, bit: int) -> Color:
	if _busy == i:
		return DIM
	if _attempted & bit == 0:
		return FAINT
	return FG


func _piede() -> void:
	_text(Vector2(MARGIN, 176), "UP/DOWN SELECT   ENTER ACT", DIM, 12)
	_text(Vector2(MARGIN, 188), "R RESET PORT", DIM, 12)


func _quanti(maschera: int) -> int:
	var n := 0
	for i in _names.size():
		if maschera & (1 << i) != 0:
			n += 1
	return n


func _width(s: String) -> float:
	return _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x


func _text(pos: Vector2, s: String, color: Color, px: int) -> void:
	draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)
