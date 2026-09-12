## I colori e i font di Windows 98, in un posto solo.
##
## PROVVISORIO, E SOLO PER LE SONDE. Se la strada del desktop verrà presa, questo file
## è il candidato naturale a diventare il gemello di `core/phosphor.gd` — che nacque
## per la stessa ragione, cioè quattro colori copiati a mano in tredici file.
##
## IL CHROME E' WINDOWS, IL CONTENUTO NO — ed e' la divisione decisa guardando gli
## scatti. Le finestre, la taskbar, i pulsanti e i menu hanno i colori di Windows 98,
## quelli veri: teal e grigio 192. Il fosforo ambra resta DENTRO le applicazioni
## strumentali — la ripresa, la cupola, il plate solving — che sono programmi vecchi,
## scritti per terminali, e che nel 1999 giravano in finestra dentro il sistema nuovo.
##
## LA REGOLA, detta in un modo che si applica da solo: i programmi che parlano con le
## MACCHINE sono monocromatici e usano `core/phosphor.gd`; quelli che parlano con TE —
## il gestionale, gli errori di sistema — sono applicazioni Windows e usano questo
## file. Le fasi ricadono nella prima meta' e disegnano gia' cosi': non va cambiato
## niente, va solo messa loro una cornice attorno.
##
## E D-173 REGGE LO STESSO, che era il dubbio da cui si era partiti. Il desktop lo si
## guarda due secondi per aprire qualcosa; il software di ripresa lo si fissa per venti
## minuti. L'ambra resta dove si passa il tempo, e la parte chiara e' di passaggio.
extends RefCounted

var DESKTOP: Color
var FACE: Color
var HL: Color
var LIGHT: Color
var SHADOW: Color
var DARK: Color
var TITLE_A: Color
var TITLE_B: Color
## La barra del titolo della finestra SENZA fuoco: in Windows era grigia e spenta, ed
## è il segno con cui si legge quale finestra riceve i tasti.
var TITLE_OFF: Color
var TITLE_TX: Color
var TITLE_TX_OFF: Color
var INK: Color
var INK_SEL: Color
var GRAYTX: Color
## Il fondo dei campi che si leggono: liste, caselle di testo. È l'area PIÙ GRANDE
## della finestra, quindi è lei a decidere se il monitor è una lampada o no — e per
## questo non può essere lo stesso colore del testo chiaro, come sarebbe naturale
## scrivere. Sono due ruoli diversi che nello schema standard hanno lo stesso valore.
var FIELD: Color
var SELBG: Color
var ICONTX: Color
var ICONSH: Color
## Il giallo del triangolo d'avviso. È di Windows, come tutto il resto di questo
## file: l'avviso di sistema non è uno strumento, è il sistema che parla a te.
var WARN: Color

var font: SystemFont
## Il font delle CIFRE. Vedi `cifre()`: non è un vezzo.
var mono: SystemFont


## TAHOMA E NON MS SANS SERIF, e la scelta e stata misurata affiancando la stessa
## lista scritta nei due modi (`_confronto/24_*`). MS Sans Serif viene da un bitmap
## degli anni Ottanta e a 10 px sul vetro curvo le lettere si toccano: «Vixen nuova»
## si impastava. Tahoma e del 1994 ed era disegnato APPOSTA per essere letto piccolo
## su schermo — spaziatura piu larga, aste dritte, contatori aperti — e alla stessa
## misura le parole si staccano.
##
## ED E DEL 1999 LO STESSO: Tahoma arrivava con Windows 98, usato da Outlook Express e
## da Internet Explorer, e chiunque poteva sceglierlo dal pannello Aspetto. Non e una
## licenza presa sull epoca, e una preferenza che quel computer poteva davvero avere.
func _init(vecchio := false) -> void:
	if vecchio:
		font = _fatto(["Microsoft Sans Serif", "MS Sans Serif", "sans-serif"])
	else:
		font = _fatto(["Tahoma", "Verdana", "sans-serif"])
	mono = _fatto(["Consolas", "Courier New", "monospace"])
	_standard()


func _standard() -> void:
	DESKTOP = Color8(0, 128, 128)
	FACE = Color8(192, 192, 192)
	HL = Color8(255, 255, 255)
	LIGHT = Color8(223, 223, 223)
	SHADOW = Color8(128, 128, 128)
	DARK = Color8(0, 0, 0)
	TITLE_A = Color8(0, 0, 128)
	TITLE_B = Color8(16, 132, 208)
	TITLE_OFF = Color8(128, 128, 128)
	TITLE_TX = Color8(255, 255, 255)
	TITLE_TX_OFF = Color8(223, 223, 223)
	INK = Color8(0, 0, 0)
	INK_SEL = Color8(255, 255, 255)
	GRAYTX = Color8(128, 128, 128)
	FIELD = Color8(255, 255, 255)
	SELBG = Color8(0, 0, 128)
	ICONTX = Color8(255, 255, 255)
	ICONSH = Color8(0, 0, 0)
	WARN = Color8(255, 222, 60)


func _fatto(nomi: Array) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(nomi)
	# MS Sans Serif del '98 era un font BITMAP: i tratti stavano sul pixel, non a
	# cavallo di due. Con l'antialias di Godot si otterrebbe un grigio morbido che il
	# CRT poi sfoca ancora — più leggibile del vero, e quindi una risposta gentile a
	# una domanda severa.
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.hinting = TextServer.HINTING_NORMAL
	return f


## Il rilievo di Windows: due cornici concentriche di 1 px, chiara sopra-sinistra e
## scura sotto-destra. È QUI CHE SI GIOCA LA PARTITA — un pixel di differenza fra due
## grigi vicini è esattamente ciò che le scanline sono capaci di mangiare.
func rilievo(ci: CanvasItem, r: Rect2, tl: Color, br: Color,
		itl := Color(0, 0, 0, 0), ibr := Color(0, 0, 0, 0)) -> void:
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.position.x + r.size.x
	var y1 := r.position.y + r.size.y
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
func pulsante(ci: CanvasItem, r: Rect2, premuto := false) -> void:
	ci.draw_rect(r, FACE)
	if premuto:
		rilievo(ci, r, SHADOW, HL, DARK, LIGHT)
	else:
		rilievo(ci, r, HL, DARK, LIGHT, SHADOW)


func testo(ci: CanvasItem, pos: Vector2, s: String, c: Color, px := 11) -> void:
	ci.draw_string(font, pos + Vector2(0, px), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)


## Le cifre, in MONOSPACE, ed è il rimedio a un difetto misurato: a 11 px
## proporzionali lo zero è largo quattro pixel e sotto le scanline perde il buco in
## mezzo — «L. 8.000» leggeva «8.DDD». In un registro di prezzi è proprio ciò che deve
## leggersi. Vale ovunque compaia un numero: prezzi, saldo, orologio.
func cifre(ci: CanvasItem, pos: Vector2, s: String, c: Color, px := 11) -> void:
	ci.draw_string(mono, pos + Vector2(0, px), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)


func largo(s: String, px := 11) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
