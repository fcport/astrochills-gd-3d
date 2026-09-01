## Quello che il monitor mostra quando NON C'È NIENTE DA MOSTRARE: il prompt.
##
## PERCHÉ ESISTE. Una fase può non avere schermo — quella della cupola non ce l'ha,
## perché il PC del '99 non sa che la cupola esista (D-171) — e per un giro intero
## questo ha voluto dire CRT nero. **Nero e guasto si somigliano troppo**: chi si
## siede alla postazione prima di essere salito in cupola vede un monitor morto e
## conclude che il gioco è rotto. È successo, ed è stato segnalato con quelle
## parole: «non va più il computer, posso solo sedermi lì».
##
## E NON È UNA TOPPA: è quello che c'era davvero. La macchina è accesa, nessuno ha
## ancora avviato il programma della notte, e un PC del '99 acceso e fermo mostra un
## prompt con il cursore che lampeggia. Il monitor adesso dice la verità — «io
## funziono, non sto facendo niente» — invece di non dire niente.
##
## NON NOMINA LA CUPOLA E NON DICE COSA FARE, e la rinuncia è deliberata. Il PC non
## sa che la cupola esista: se scrivesse «apri la cupola» saprebbe di lei, e la
## decisione per cui la sera comincia alzandosi invece che sedendosi salterebbe da
## qui, di sbieco, senza che nessuno l'abbia riaperta.
##
## IL CURSORE LAMPEGGIA, e vale metà del lavoro. Un prompt fermo è un'immagine; un
## cursore che batte è una macchina viva, ed è l'unica cosa in questa vista che
## distingua «acceso» da «bloccato».
##
## Il testo è in inglese come tutte le altre viste: è la lingua delle macchine, e un
## MS-DOS italiano non è mai esistito.
class_name IdleScreen
extends Control

const DESIGN_SIZE := Vector2(256, 192)

const BG := Phosphor.BG
const FG := Phosphor.FG
const DIM := Phosphor.DIM

const MARGIN := 8
const RIGA := 11.0
const CORPO := 10

## Mezzo secondo acceso, mezzo spento: è la cadenza del cursore di MS-DOS.
const LAMPEGGIO := 0.53

## Le righe che stanno sopra il prompt. Sono quelle di un avvio finito da un pezzo:
## nessuno le ha guardate, sono ancora lì.
const SCROLLBACK: Array[String] = [
	"Starting MS-DOS...",
	"",
	"HIMEM is testing extended memory...done.",
	"",
	"C:\\>CD OSSERV",
	"",
]

const PROMPT := "C:\\OSSERV>"

var _font: SystemFont
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])


func _process(delta: float) -> void:
	var prima := int(_t / LAMPEGGIO)
	_t += delta
	# SI RIDISEGNA SOLO QUANDO IL CURSORE CAMBIA, non a ogni fotogramma: questa
	# vista sta accesa per tutto il tempo in cui il giocatore è in cupola, che sono
	# minuti, e ridisegnarla sessanta volte al secondo per un quadratino che batte
	# due volte sarebbe il costo peggio speso del gioco.
	if int(_t / LAMPEGGIO) != prima:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), BG)
	var y := MARGIN + RIGA
	for riga in SCROLLBACK:
		if riga != "":
			_testo(Vector2(MARGIN, y), riga, DIM)
		y += RIGA
	_testo(Vector2(MARGIN, y), PROMPT, FG)
	if int(_t / LAMPEGGIO) % 2 == 0:
		var x := MARGIN + _font.get_string_size(
			PROMPT, HORIZONTAL_ALIGNMENT_LEFT, -1, CORPO).x
		draw_rect(Rect2(x + 1.0, y - CORPO + 1.0, CORPO * 0.55, CORPO), FG)


func _testo(dove: Vector2, s: String, c: Color) -> void:
	draw_string(_font, dove, s, HORIZONTAL_ALIGNMENT_LEFT, -1, CORPO, c)
