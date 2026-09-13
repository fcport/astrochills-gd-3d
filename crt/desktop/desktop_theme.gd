## I colori, i font e il rilievo di Windows 98, in un posto solo.
##
## È IL GEMELLO DI `core/phosphor.gd`, e nasce per la stessa ragione: quattro colori
## copiati a mano in più file sono quattro occasioni di dimenticarne uno.
##
## LA DIVISIONE CHE REGGE TUTTO IL DESKTOP. Il chrome — finestre, taskbar, menu,
## pulsanti — ha i colori di Windows 98, quelli veri: teal e grigio 192. Il fosforo
## ambra resta DENTRO i programmi strumentali, che sono vecchi e scritti per terminali.
## Detta in un modo che si applica da solo: ciò che parla con le MACCHINE usa
## `Phosphor`; ciò che parla con TE — le finestre, gli elenchi di file — usa questo.
##
## D-173 REGGE LO STESSO, che era il dubbio da cui si era partiti: il desktop lo si
## guarda due secondi per aprire qualcosa, il software di ripresa lo si fissa per venti
## minuti. L'ambra resta dove si passa il tempo.
class_name DesktopTheme
extends RefCounted

const DESKTOP := Color8(0, 128, 128)
const FACE := Color8(192, 192, 192)
const HL := Color8(255, 255, 255)
const LIGHT := Color8(223, 223, 223)
const SHADOW := Color8(128, 128, 128)
const DARK := Color8(0, 0, 0)
const TITLE_A := Color8(0, 0, 128)
const TITLE_B := Color8(16, 132, 208)
## La barra della finestra SENZA fuoco: grigia e spenta. È l'unico segno che dice a
## chi vanno a finire i tasti, e senza di lui due finestre sono due disegni sovrapposti.
const TITLE_OFF := Color8(128, 128, 128)
const TITLE_TX := Color8(255, 255, 255)
const TITLE_TX_OFF := Color8(223, 223, 223)
const INK := Color8(0, 0, 0)
const INK_SEL := Color8(255, 255, 255)
const GRAY_TX := Color8(128, 128, 128)
## Il fondo dei campi che si leggono. Non coincide per forza col testo chiaro, anche se
## nello schema standard hanno lo stesso valore: sono due ruoli diversi.
const FIELD := Color8(255, 255, 255)
const SEL_BG := Color8(0, 0, 128)
const ICON_TX := Color8(255, 255, 255)
const ICON_SH := Color8(0, 0, 0)

var font: SystemFont
## Il font delle CIFRE. Vedi `digits()`: non è un vezzo.
var mono: SystemFont


## TAHOMA E NON MS SANS SERIF, ed è stato misurato affiancando la stessa lista scritta
## nei due modi. MS Sans Serif viene da un bitmap degli anni Ottanta: a 10 px, sul vetro
## curvo e sotto le scanline, le lettere si toccano — «Vixen nuova» si impastava.
## Tahoma è del 1994 ed è disegnato apposta per essere letto piccolo su schermo, con
## spaziatura larga e contatori aperti. E arrivava con Windows 98, usato da Outlook
## Express e Internet Explorer: è una preferenza che quel computer poteva avere.
func _init() -> void:
	font = _make(["Tahoma", "Verdana", "sans-serif"])
	mono = _make(["Consolas", "Courier New", "monospace"])


func _make(names: Array) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	# Niente antialias: i tratti stanno sul pixel. Con l'antialias di Godot il testo
	# diventa un grigio morbido che lo shader del CRT sfoca ancora.
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.hinting = TextServer.HINTING_NORMAL
	return f


## Il rilievo: due cornici concentriche di 1 px, chiara sopra-sinistra e scura
## sotto-destra. Un pixel di differenza fra due grigi vicini è esattamente ciò che le
## scanline sanno mangiare, ed è per questo che il grigio d'ombra resta a 128.
func bevel(ci: CanvasItem, r: Rect2, tl: Color, br: Color,
		itl := Color(0, 0, 0, 0), ibr := Color(0, 0, 0, 0)) -> void:
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.end.x
	var y1 := r.end.y
	ci.draw_line(Vector2(x0, y0 + 0.5), Vector2(x1, y0 + 0.5), tl, 1.0)
	ci.draw_line(Vector2(x0 + 0.5, y0), Vector2(x0 + 0.5, y1), tl, 1.0)
	ci.draw_line(Vector2(x0, y1 - 0.5), Vector2(x1, y1 - 0.5), br, 1.0)
	ci.draw_line(Vector2(x1 - 0.5, y0), Vector2(x1 - 0.5, y1), br, 1.0)
	if itl.a > 0.0:
		ci.draw_line(Vector2(x0 + 1, y0 + 1.5), Vector2(x1 - 1, y0 + 1.5), itl, 1.0)
		ci.draw_line(Vector2(x0 + 1.5, y0 + 1), Vector2(x0 + 1.5, y1 - 1), itl, 1.0)
		ci.draw_line(Vector2(x0 + 1, y1 - 1.5), Vector2(x1 - 1, y1 - 1.5), ibr, 1.0)
		ci.draw_line(Vector2(x1 - 1.5, y0 + 1), Vector2(x1 - 1.5, y1 - 1), ibr, 1.0)


## Un pulsante col rilievo giusto: sporgente da fermo, incassato se premuto.
func button(ci: CanvasItem, r: Rect2, pressed := false) -> void:
	ci.draw_rect(r, FACE)
	if pressed:
		bevel(ci, r, SHADOW, HL, DARK, LIGHT)
	else:
		bevel(ci, r, HL, DARK, LIGHT, SHADOW)


func text(ci: CanvasItem, pos: Vector2, s: String, c: Color, px := 11) -> void:
	ci.draw_string(font, pos + Vector2(0, px), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)


## Le cifre in MONOSPACE, rimedio a un difetto misurato: a 11 px proporzionali lo zero
## è largo quattro pixel e sotto le scanline perde il buco — «L. 8.000» leggeva
## «8.DDD». Vale per ogni numero: prezzi, saldo, orologio.
func digits(ci: CanvasItem, pos: Vector2, s: String, c: Color, px := 11) -> void:
	ci.draw_string(mono, pos + Vector2(0, px), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)


func width(s: String, px := 11) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
