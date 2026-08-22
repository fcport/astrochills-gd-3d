## L'iniettore di sorgente bugiarda — `F9`. Esiste solo nelle build di sviluppo.
##
## NON È CONTENUTO: È UN TEST. Sostituisce a caldo la `PhaseTruthSource` onesta
## della fase attiva con una che deriva da sola. Se la fase continua a funzionare
## senza essere stata modificata, il vincolo non negoziabile di ADR-001 regge; se
## per accogliere la bugia il codice della fase deve cambiare, l'architettura era
## sbagliata — e lo si scopre adesso invece che fra sei mesi.
##
## È la contromisura al rischio residuo dichiarato in ADR-001: nessuno verifica
## automaticamente che una fase non bari leggendo lo stato grezzo. Questo tasto
## non lo verifica per costruzione, ma lo mette alla prova dentro il gioco vero.
##
## `F9` È UN INTERRUTTORE, non un salto senza ritorno. La sorgente onesta viene
## messa da parte e la seconda pressione la rimette al suo posto: il confronto
## A/B — guarda come si comporta, premi, guarda di nuovo, premi e torna indietro
## — è tutto ciò per cui questo strumento esiste, e con un'iniezione sola
## avrebbe richiesto di riavviare il gioco ogni volta.
##
## `debug/` può dipendere da tutto, ed è l'unica cartella che può: la sola
## eccezione è il punto d'ingresso, che deve pur installare gli strumenti.
extends Node

## Una bugia per fase, indicizzata con `key()` — mai con `name`, che Godot
## rinomina. Aggiungere una fase qui è aggiungere una riga.
##
## Percorsi e non preload: un `const ... preload` risolve al caricamento dello
## script e si porterebbe `wandering_drift.tres` dentro l'export di release.
const LIE_PATHS := {
	&"polar": "res://phases/polar/sources/wandering_drift.tres",
}

var _main: Node

## La sorgente onesta messa da parte, per istanza di fase.
##
## La chiave è l'instance id e non `key()`: due fasi successive con la stessa
## chiave sono due oggetti diversi, e rimettere a una la sorgente dell'altra
## sarebbe un bug silenzioso di quelli che costano un pomeriggio.
var _honest := {}


func configure(main: Node) -> void:
	_main = main


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if key.pressed and not key.echo and key.keycode == KEY_F9 and not key.shift_pressed:
		_toggle()


func _toggle() -> void:
	var p: Phase = _main.current_phase() if _main != null else null
	if p == null:
		Log.debug("debug", "F9: nessuna fase attiva")
		return

	# `Object.set()` su una proprietà che non esiste è un no-op SILENZIOSO: non
	# solleva niente e non restituisce niente. Senza questo controllo l'iniettore
	# dichiarerebbe successo senza aver iniettato nulla, la fase si comporterebbe
	# identica — e la prova del seam «passerebbe» proprio perché non è mai stata
	# fatta. Lo strumento costruito per scoprire un seam rotto direbbe che regge.
	if not _has_truth(p):
		Log.warn("debug", "F9: la fase %s non espone 'truth', niente da iniettare" % p.key())
		return

	var id := p.get_instance_id()
	if _honest.has(id):
		p.set("truth", _honest[id])
		_honest.erase(id)
		Log.info("debug", "F9: %s torna alla sorgente onesta" % p.key())
		return

	var path: String = LIE_PATHS.get(p.key(), "")
	if path.is_empty():
		Log.debug("debug", "F9: nessuna bugia per la fase %s" % p.key())
		return

	var lie := load(path) as Resource
	if lie == null:
		Log.warn("debug", "F9: bugia non caricabile: %s" % path)
		return

	_honest[id] = p.get("truth")
	# duplicate(true) NON è opzionale: le Resource in Godot sono condivise per
	# riferimento, e senza copia due iniezioni successive — o due fasi in scena —
	# si passerebbero lo stesso accumulatore.
	p.set("truth", lie.duplicate(true))
	Log.info("debug", "F9: sorgente di %s sostituita con %s" % [
		p.key(), path.get_file()])


func _has_truth(p: Object) -> bool:
	for prop in p.get_property_list():
		if prop.name == "truth":
			return true
	return false
