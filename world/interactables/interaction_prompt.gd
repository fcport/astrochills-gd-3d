## La riga che compare guardando un oggetto interagibile (UX-DR9).
##
## DISCRETA PER COSTRUZIONE, non per buona volontà: una riga sola, in basso,
## sopra un fondo appena accennato. Non è un modale, non ferma il gioco, non
## copre la scena — e non può diventarlo, perché non c'è nessun pannello da far
## crescere.
##
## Vive DENTRO il `SubViewport` del mondo, quindi viene rimpicciolita e
## riscalata con nearest insieme a tutto il resto: il testo ha la stessa grana
## della stanza. Se stesse fuori sarebbe nitido come un'interfaccia moderna
## appiccicata sopra un gioco del 1999, che è precisamente l'effetto da evitare.
##
## Non vive in `ui/`: `ui/` è riservato alla UI non diegetica, cioè pausa e
## impostazioni (UX-DR1). Questo è arredo del mondo.
##
## MA NON CHIAMIAMOLO DIEGETICO, perché non lo è: un `CanvasLayer` disegnato
## sopra la scena sta nello spazio dello schermo, non dentro la finzione. Quello
## che condivide con la stanza è la RESA — risoluzione, filtro, grana — non
## l'appartenenza al mondo. UX-DR9 chiede un prompt diegetico e questa è una
## lettura minima di quella richiesta, presa consapevolmente: a 640x360, con
## vertex snapping e filtro nearest, un testo montato nel mondo rischia di essere
## illeggibile alla distanza di interazione, e su questo progetto le cose di resa
## si decidono guardando e non stimando. La verifica va fatta nell'epica 3, con
## moka, lampada e cupola davanti, quando ci sarà qualcosa da confrontare.
class_name InteractionPrompt
extends CanvasLayer

const FG := Color(0.92, 0.94, 0.90)
const SHADOW := Color(0, 0, 0, 0.75)

## Corpo del testo in pixel del viewport a bassa risoluzione, non della finestra.
const FONT_SIZE := 14

@onready var _label: Label = %Label


func _ready() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_label.add_theme_font_override("font", font)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", FG)
	_label.add_theme_color_override("font_shadow_color", SHADOW)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	hide_prompt()


## Mostra il prompt. Il tasto lo scrive questo nodo, non l'oggetto: così
## cambiarlo è cambiare una riga qui, invece di rincorrere ogni interagibile.
func show_prompt(text: String) -> void:
	_label.text = "[E]  %s" % text
	visible = true


func hide_prompt() -> void:
	visible = false
