## L'OCCHIO NELLA POSA — `Ctrl+F6`.
##
## La posa finisce, la stampa esce, sotto c'è scritto il soggetto — e nella foto, fra le
## stesse stelle, al posto della galassia c'è un occhio che sembra una nebulosa. Il telescopio
## guardava su, e qualcosa lassù guardava lui. Come ci entra, e perché è questo e non
## l'osservatorio visto dall'alto, sta in `world/orrori/occhio_nella_posa.gd`.
##
## DUE COSE, CON LO STESSO TASTO:
##   * LA PROSSIMA FOTO RIVELATA ESCE CON L'OCCHIO. È il modo in cui succederà nella storia:
##     la posa finisce, l'immagine emerge, e la stampa che esce non è la galassia.
##   * E UNA STAMPA ESCE SUBITO, della foto più recente che c'è nel registro (o di M51, se
##     non ce n'è ancora nessuna). Senza, per vedere l'orrore bisognerebbe giocare una
##     notte intera fino alla posa, e questo è uno strumento per guardare.
##
## LE STAMPE RESTANO QUANDO L'ORRORE SE NE VA: una foto stampata è carta nel mondo, e il
## tasto la seconda volta spegne solo la prossima foto. La si butta come le altre.
class_name OrrorePosa
extends Orrore

## Se non c'è ancora nessuna foto nel registro.
const DI_RISERVA := &"m51"
const LIVELLO_DI_RISERVA := 2

var _stampante: Stampante


func _comincia() -> void:
	_stampante = Stampante.find_in(get_tree())
	if _stampante == null:
		push_warning("occhio nella posa: in scena non c'è una stampante")
		_chiudi()
		return
	_stampante.infesta_la_prossima = true
	var soggetto := DI_RISERVA
	var livello := LIVELLO_DI_RISERVA
	var notte := Game.run.night_index if Game.run != null else 0
	var foto := 0
	var registro: Array = Game.profile.photo_prints if Game.profile != null else []
	if not registro.is_empty():
		var ultima: Dictionary = registro[registro.size() - 1]
		soggetto = StringName(ultima.get(&"target", DI_RISERVA))
		livello = int(ultima.get(&"livello", LIVELLO_DI_RISERVA))
		foto = int(ultima.get(&"foto", 0)) + 1
	_stampante.accoda(soggetto, livello, notte, foto, true)
	Log.debug("orrori", "occhio nella posa: stampa %s al livello %d, e la prossima foto" % [
		soggetto, livello])


func _congeda() -> void:
	if _stampante != null and is_instance_valid(_stampante):
		_stampante.infesta_la_prossima = false
	_chiudi()
