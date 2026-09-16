## I CATALOGHI SI LEGGONO? Il planetario con i tre cataloghi e il terminale con la terza
## categoria, disegnati e ingranditi due volte (D-261).
##
## PERCHE' NON BASTA IL BANCO. Il banco dice che la sorgente elenca undici soggetti e
## che il terminale vende tre cataloghi; non puo' dire se la striscia in testa al
## planetario si legge con sigle da otto caratteri, ne' se la terza categoria del
## terminale sta sopra la riga del messaggio. Qui si disegnano e si guardano.
##
## LA FASE E' QUELLA VERA, e i cataloghi arrivano dal `ctx` come li manda
## l'orchestratore: se il filo fra il possesso e il planetario si stacca, nello scatto
## restano quattro soggetti invece di undici.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_cataloghi.tscn
##
## Scrive user://cataloghi.png, con i due schermi affiancati.
extends Node

const FUORI := "user://cataloghi.png"

## Quanti fotogrammi si lasciano passare prima dello scatto: i `Control` si
## disegnano su `queue_redraw`, che arriva al fotogramma dopo.
const RESPIRO := 4

const CATALOGHI: Array[StringName] = [&"messier_vol1", &"messier_vol2", &"atlante_ngc_ic"]

var _conto := 0


func _ready() -> void:
	_monta.call_deferred()


func _monta() -> void:
	var strato := CanvasLayer.new()
	strato.scale = Vector2(2, 2)
	add_child(strato)

	# IL PLANETARIO ALLE 02:00 DELLA PRIMA NOTTE, SUL SESTO SOGGETTO: e' il punto in cui
	# la striscia ha soggetti da tutte e due le parti, e deve dirlo con le frecce.
	var run := NightRun.new()
	run.elapsed_min = 300.0
	var fase: Node = load("res://phases/targeting/phase_targeting.tscn").instantiate()
	fase.setup(run, {Phase.CTX_OWNED_ITEMS: CATALOGHI.duplicate()})
	add_child(fase)
	fase._cursor = 5
	fase._process(0.016)
	var planetario: Control = fase.screen()
	planetario.get_parent().remove_child(planetario)
	planetario.position = Vector2(2, 2)
	strato.add_child(planetario)
	var sigle := PackedStringArray()
	for voce in fase._catalog:
		sigle.append(voce.get(&"short", "?"))
	print("[cataloghi] planetario: %d soggetti {%s}" % [sigle.size(), ", ".join(sigle)])

	# IL TERMINALE, con le tre categorie.
	var terminale: Control = load("res://terminal/terminal.tscn").instantiate()
	terminale.position = Vector2(262, 2)
	strato.add_child(terminale)
	if terminale.has_method("arm"):
		terminale.arm()
	print("[cataloghi] terminale montato")


func _process(_d: float) -> void:
	_conto += 1
	if _conto <= RESPIRO:
		return
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(FUORI)
	print("[cataloghi] scritto %s" % ProjectSettings.globalize_path(FUORI))
	get_tree().quit()
