## Il giro della prima notte (D-287): dove aspetta Gerardo, dove ha la macchina, le
## tappe, e la strada da cui se ne va.
##
## Sul modello di `data/quaderno/quaderno_data.gd`: una Resource con un `@export Array`
## di tappe, più la logica PURA che serve a leggerle — l'a capo dei sottotitoli. Pura
## vuol dire collaudabile al banco: una battuta troppo lunga si scopre lì, non ascoltando
## Gerardo in partita.
class_name GiroGerardo
extends Resource

## Quante lettere sta una riga di sottotitolo, e quante righe può prendere una battuta.
## Il sottotitolo è a spaziatura fissa come il prompt, a 14 punti su 640 pixel: sessanta
## colonne lasciano un margine per parte, due righe non coprono mezzo schermo.
const COLONNE := 60
const RIGHE := 2

## Le risposte del giocatore stanno su una riga sola della lista, col segno di scelta
## davanti; il nome che scrive, al più tanti caratteri.
const COLONNE_RISPOSTA := 40
const NOME_MAX := 20

## Dove sta il giocatore quando la notte comincia: accanto alla portiera della sua auto,
## sullo slargo, in pianta. Lo sguardo non si scrive: è verso Gerardo.
@export var arrivo := Vector2.ZERO

## Dove aspetta Gerardo, in pianta, prima che arrivi il giocatore.
@export var partenza := Vector2.ZERO

## La sua macchina, parcheggiata sullo slargo: `x`, `z` in pianta e `y` è l'imbardata
## in gradi, misurata come quella dell'auto del giocatore (zero vuol dire muso verso +x).
@export var auto := Vector3.ZERO

## Le tappe, in ordine. L'ultima finisce accanto alla portiera.
@export var tappe: Array[TappaGiro] = []

## LE DUE REAZIONI (D-291): cosa dice se gli chiudi una porta che deve riaprire, e se gli
## stai davanti e non lo lasci passare. Le dice solo a chi lo sente.
@export var se_chiudi_la_porta: String = ""
@export var se_lo_blocchi: String = ""

## Cosa ti ricorda se ti ha chiesto di aprire la cupola e non la apri (D-293).
@export var se_non_apri: String = ""

## La strada da cui se ne va, in pianta, a partire dal parcheggio. È la sterrata di
## OpenStreetMap che passa dallo slargo — la stessa che `tools/prendi_panorama.py`
## dipinge sul terreno — verso ovest, letta dalla cache `osm_vicino.osm`.
@export var strada: PackedVector2Array = PackedVector2Array()


## Una battuta spezzata in righe di sottotitolo. È l'a capo del quaderno, a un'altra
## larghezza: le parole non si spezzano, e la stessa funzione la usano lo schermo per
## disegnare e il banco per contare.
static func righe_battuta(testo: String) -> PackedStringArray:
	return QuadernoData.a_capo(testo, COLONNE)


## Le battute che non stanno in `RIGHE` righe, le risposte più lunghe di una riga e le
## battute che chiedono il nome E offrono risposte, come «tappa: inizio del testo». Vuoto se
## è tutto a posto. La usa il banco.
func battute_lunghe() -> PackedStringArray:
	var fuori := PackedStringArray()
	for tappa in tappe:
		if tappa == null:
			continue
		for b in tappa.battute:
			var testi := PackedStringArray([b.testo, se_chiudi_la_porta, se_lo_blocchi, se_non_apri])
			for ramo in b.rami:
				testi.append_array(ramo.battute)
				if ramo.risposta.length() > COLONNE_RISPOSTA:
					fuori.append("%s: risposta «%s»" % [tappa.nome, ramo.risposta.left(30)])
			for testo in testi:
				if righe_battuta(testo).size() > RIGHE:
					fuori.append("%s: %s" % [tappa.nome, testo.left(30)])
			if b.chiede_nome and not b.rami.is_empty():
				fuori.append("%s: chiede il nome e offre risposte insieme" % tappa.nome)
	return fuori
