## La sorgente onesta della fase 5: la stella sta dove il catalogo dice.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente: l'unica
## ragione per cui la stella non è centrata è che gli encoder della montatura
## partono sfasati, e centrarla significa scoprire di quanto.
##
## LO SFASAMENTO È IL FATTO NASCOSTO, e nasce a ogni montaggio. Non è un difetto
## simulato per far fare qualcosa al giocatore: una montatura che si accende non
## sa dove sta guardando, punto. Chi ci lavorava lo dava per scontato come il
## fatto che l'auto vada messa in moto.
##
## LE STELLE SONO SEI E SONO VERE, con la loro declinazione di catalogo. Sono
## quelle che un osservatore alle nostre latitudini userebbe: luminose, note, e
## abbastanza alte da essere INQUADRABILI DA QUESTA CUPOLA — che è un vincolo
## severo, perché questo edificio non vede sotto una certa altezza (vedi
## `tools/prova_orizzonte.gd`).
##
## L'ANGOLO ORARIO NON È DI CATALOGO ed è giusto che non lo sia: dipende dall'ora,
## e una stella si sceglie perché è ALTA adesso. Si estrae vicino al meridiano,
## che è dove si sincronizza davvero — lì la rifrazione è minima e l'errore di
## puntamento non è mascherato dall'atmosfera.
class_name HonestStar
extends SyncTruthSource

## Nome e declinazione (gradi) delle stelle di taratura. Valori di catalogo.
const STELLE := [
	["VEGA", 38.78], ["DENEB", 45.28], ["CAPELLA", 45.99],
	["ARTURO", 19.18], ["POLLUCE", 28.03], ["ALDERAMIN", 62.59],
]

## Quanto lontano dal meridiano può capitare la stella, in gradi di angolo orario.
## Venticinque gradi sono un'ora e quaranta: si resta vicini al meridiano.
const MERIDIANO_SCARTO := 25.0

## Quanto possono essere sfasati gli encoder all'accensione, in gradi.
##
## FRA MEZZO GRADO E DUE, e i due estremi contano tutti e due. Sotto il mezzo
## grado la stella nascerebbe quasi centrata e la fase sarebbe una formalità;
## sopra i due gradi uscirebbe dal campo del cercatore e il giocatore non saprebbe
## da che parte cercarla — che è frustrazione, non difficoltà.
@export var scarto_minimo: float = 0.5
@export var scarto_massimo: float = 1.8

var _nome := ""
var _catalogo := Vector2.ZERO
var _sfasamento := Vector2.ZERO
var _pronta := false


## Si estrae al primo uso e non in `_init()`: una Resource caricata da `.tres`
## viene costruita anche dall'editor e dagli strumenti, e non è lì che va deciso
## come sarà la notte.
func _prepara() -> void:
	_pronta = true
	var s: Array = STELLE[randi() % STELLE.size()]
	_nome = String(s[0])
	_catalogo = Vector2(randf_range(-MERIDIANO_SCARTO, MERIDIANO_SCARTO), float(s[1]))
	# UNA DIREZIONE QUALUNQUE E UN MODULO NELLA FASCIA: estrarre le due componenti
	# separate darebbe uno sfasamento che preferisce le diagonali, e dopo qualche
	# notte il giocatore imparerebbe a cercare la stella in un angolo.
	var ang := randf() * TAU
	var modulo := randf_range(scarto_minimo, scarto_massimo)
	_sfasamento = Vector2(cos(ang), sin(ang)) * modulo


func star_label() -> String:
	if not _pronta:
		_prepara()
	return _nome


func catalog_position() -> Vector2:
	if not _pronta:
		_prepara()
	return _catalogo


## Il tubo sta dove segnano gli encoder, meno il loro sfasamento. È l'unica riga
## in cui lo sfasamento agisce sul ferro.
func aim(encoder_deg: Vector2) -> Vector2:
	if not _pronta:
		_prepara()
	return encoder_deg - _sfasamento


## La stella appare dove sta davvero, visto da dove punta il tubo.
##
## FUNZIONE PURA DI `input`, come la curva a V del fuoco: nessuno stato che
## cambi, `delta` mai usato. `sample(i, 0.016)` e `sample(i, 0.99)` danno lo
## stesso valore.
func sample(input: SyncInput, _delta: float) -> Vector2:
	if not _pronta:
		_prepara()
	return _catalogo - aim(input.encoder_deg)
