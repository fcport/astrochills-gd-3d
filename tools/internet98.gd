## La finestra «Internet»: il market, i forum, e dove si vendono le proprie foto.
##
## PROVVISORIO, E SOLO PER LE SONDE. Sta dentro una `cornice98`: non disegna né barra
## del titolo né bordi, quelli li mette la finestra.
##
## PERCHÉ UNA SOLA FINESTRA CON TRE SCHEDE e non tre programmi. Comprare, leggere e
## vendere sono la stessa cosa vista da tre lati — sono tutte «il mondo fuori che
## arriva per il filo del telefono» — e nel 1999 ci si arrivava tutte e tre dallo
## stesso posto: ci si collegava una volta, e poi si girava.
##
## È UN'APPLICAZIONE WINDOWS e usa `tema98`, non il fosforo: parla con te, non con una
## macchina. La regola sta in testa a `tools/tema98.gd`.
##
## I TRE VERBI FUNZIONANO DAVVERO: si ordina e il portafoglio cala, si vende e il
## portafoglio sale, si legge e si apre il messaggio. La stesura prima aveva un
## pulsante che scriveva «non implementato», che era onesto ma inutile.
##
## IL PORTAFOGLIO È DELLA SONDA, non del gioco. Parte dal saldo vero (`Game.wallet_now()`)
## così le cifre sono quelle della partita, ma spendere qui non scrive nel save: una
## prova dell'interfaccia non deve poter svuotare la cassa di chi gioca.
##
## OGNI SCHEDA RICORDA LA SUA RIGA. Il cursore era uno solo e tornava a zero a ogni
## cambio: si sceglieva una foto da vendere, si dava un'occhiata al market, e al
## ritorno la selezione era sparita. Sono tre elenchi diversi e vogliono tre segni.
extends Control

const TAB_H := 16.0
## L altezza di riga e la misura del testo del CONTENUTO. Stanno insieme perche' si
## regolano insieme: alzare il corpo senza dare respiro fra le righe le fa toccare, e
## dare respiro senza alzare il corpo lascia il testo piccolo in mezzo al vuoto.
var RIGA_H := 15.0
var CORPO := 11
## Quanto sta in basso: pulsante d'azione più barra di stato.
const PIEDE := 38.0

var tema: RefCounted
var sezione := 0
## Un cursore per scheda, non uno solo. Vedi la nota in testa.
var cursori := [0, 0, 0]
## Il thread aperto in lettura, o -1 se si sta guardando l'elenco.
var leggendo := -1

## Le tre schede. L'etichetta è in INGLESE come tutta l'interfaccia (NFR10).
var schede := ["MARKET", "FORUM", "SELL"]

## Il market: gli articoli del catalogo vero (`data/catalog/`), con lo stato
## dell'ordine — la colonna che trasforma il negozio in registro. Nome, prezzo, stato.
var market := [
	["Moka pot", 8000, "on order"],
	["Light bulb", 2000, "owned"],
	["Space heater", 3500, ""],
	["Dome grease", 5000, ""],
	["Bahtinov mask", 5000, ""],
]

## I forum. Titoli e testi sono ITALIANI perché li scrivono delle persone: l'inglese è
## la lingua delle macchine, non di chi posta su un newsgroup di astrofili.
var forum := [
	["Qualcuno ha provato la Vixen nuova?", 14,
		"Sto per prendere la GP-DX ma il rivenditore dice\nche per il carico che ho e' sovradimensionata.\nQualcuno la usa con un 200mm?"],
	["Seeing pessimo tutta la settimana", 31,
		"Terza notte di fila con le stelle che ballano.\nQualcuno in Appennino ha avuto di meglio?\nQui non tengo la posa oltre i 60 secondi."],
	["Vendo oculare 25mm, poco usato", 3,
		"Plossl 25mm, comprato a marzo, usato tre volte.\nVendo perche' passo al 32. Scrivetemi in privato."],
	["Luci strane sopra il crinale, qualcuno?", 47,
		"Non e' un aereo e non e' un satellite: si e' fermata.\nDue minuti buoni, poi si e' spenta e basta.\nHo tre pose ma non si vede niente di buono.\n\n> anche io le ho viste. non dal vostro versante pero'."],
	["Come pulire uno specchio senza rovinarlo", 9,
		"Acqua distillata e nient'altro, mai il panno.\nSe c'e' polvere secca si soffia, non si tocca."],
]

## Le proprie foto, con quanto le pagano.
var vendita := [
	["m42_001.fit", 7000],
	["m42_002.fit", 7000],
	["ngc891_004.fit", 15000],
]

## Il saldo. Si legge dal gioco all'apertura, poi vive qui.
var lire := 0
var stato := ""


func configura(t: RefCounted, dim: Vector2) -> void:
	tema = t
	custom_minimum_size = dim
	size = dim
	if lire == 0:
		lire = Game.wallet_now() if Game != null else 24500
	_aggiorna_stato()


func _righe() -> Array:
	match sezione:
		0: return market
		1: return forum
		_: return vendita


## Il pulsante in basso cambia mestiere con la scheda, perché il verbo cambia.
func _verbo() -> String:
	if leggendo >= 0:
		return "Back"
	return ["Order", "Read", "Sell"][sezione]


func _aggiorna_stato() -> void:
	match sezione:
		0: stato = "Wallet: L. %s" % _lire(lire)
		1: stato = "it.hobby.astronomia  -  %d thread" % forum.size()
		_: stato = "%d file(s)  -  Wallet: L. %s" % [vendita.size(), _lire(lire)]


## Le migliaia col punto, come si scrivevano le lire. `%d` da solo dà «14500», che a
## un occhio del 1999 non è una cifra, è una stringa.
func _lire(n: int) -> String:
	var s := str(absi(n))
	var fuori := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		fuori = s[i] + fuori
		c += 1
		if c % 3 == 0 and i > 0:
			fuori = "." + fuori
	return ("-" if n < 0 else "") + fuori


func rect_tab(i: int) -> Rect2:
	var w := size.x / float(schede.size())
	return Rect2(i * w, 0, w, TAB_H)


func rect_azione() -> Rect2:
	return Rect2(3, size.y - 32, 52, 17)


func _rect_lista() -> Rect2:
	return Rect2(2, TAB_H + 2, size.x - 4, size.y - TAB_H - PIEDE)


## Un click dentro la finestra: le schede, le righe, il pulsante. Torna vero se ha
## fatto qualcosa — chi chiama lo usa per sapere se ridisegnare.
func clic(p: Vector2) -> bool:
	for i in schede.size():
		if rect_tab(i).has_point(p):
			sezione = i
			leggendo = -1
			_aggiorna_stato()
			return true
	if rect_azione().has_point(p):
		_agisci()
		return true
	if leggendo >= 0:
		return false
	var lv := _rect_lista()
	if lv.has_point(p):
		var i := int((p.y - lv.position.y - 2) / RIGA_H)
		if i >= 0 and i < _righe().size():
			cursori[sezione] = i
			return true
	return false


## Il verbo della scheda, fatto per davvero.
func _agisci() -> void:
	if leggendo >= 0:
		leggendo = -1
		_aggiorna_stato()
		return
	var i: int = cursori[sezione]
	var righe := _righe()
	if i < 0 or i >= righe.size():
		return
	match sezione:
		0: _ordina(i)
		1: leggendo = i
		_: _vendi(i)


## Comprare: si controlla lo stato, poi il saldo, poi si scala. L'ordine dei due
## controlli conta — a un articolo già posseduto non si dice «non hai i soldi».
func _ordina(i: int) -> void:
	var voce: Array = market[i]
	if voce[2] != "":
		stato = "%s: already %s" % [voce[0], voce[2]]
		return
	if voce[1] > lire:
		stato = "NOT ENOUGH LIRE  -  need L. %s" % _lire(voce[1] - lire)
		return
	lire -= voce[1]
	# «on order» e non «owned»: si ordina, e la roba arriva dopo. È il modello di
	# consegna di cui si parlava — spendere adesso, ricevere fra una notte o due.
	voce[2] = "on order"
	stato = "Ordered %s  -  Wallet: L. %s" % [voce[0], _lire(lire)]


func _vendi(i: int) -> void:
	var voce: Array = vendita[i]
	lire += voce[1]
	vendita.remove_at(i)
	# Il cursore va rimesso dentro l'elenco accorciato, o resta a puntare una riga che
	# non c'è più e il prossimo click venderebbe il vuoto.
	cursori[2] = clampi(cursori[2], 0, maxi(0, vendita.size() - 1))
	stato = "Sold %s for L. %s" % [voce[0], _lire(voce[1])]


func _draw() -> void:
	if tema == null:
		return

	# --- le schede. Quella scelta è tutt'uno con la lista sotto: in Windows la scheda
	# attiva non ha il bordo inferiore, ed è così che si legge che è la stessa cosa.
	for i in schede.size():
		var r := rect_tab(i)
		var qui := i == sezione
		draw_rect(r, tema.FACE)
		if qui:
			tema.rilievo(self, r, tema.HL, tema.HL)
		else:
			tema.rilievo(self, Rect2(r.position + Vector2(0, 2), r.size - Vector2(0, 2)),
					tema.HL, tema.SHADOW)
		tema.testo(self, Vector2(r.position.x + (r.size.x - tema.largo(schede[i], 10)) * 0.5,
				r.position.y + (2 if qui else 4)), schede[i], tema.INK, 10)

	var lv := _rect_lista()
	draw_rect(lv, tema.FIELD)
	tema.rilievo(self, lv, tema.SHADOW, tema.HL, tema.DARK, tema.LIGHT)

	if leggendo >= 0:
		_disegna_thread(lv)
	else:
		_disegna_elenco(lv)

	var b := rect_azione()
	tema.pulsante(self, b)
	tema.testo(self, Vector2(b.position.x + (b.size.x - tema.largo(_verbo(), 10)) * 0.5,
			b.position.y + 3), _verbo(), tema.INK, 10)

	var sb := Rect2(1, size.y - 14, size.x - 2, 13)
	draw_rect(sb, tema.FACE)
	tema.rilievo(self, sb, tema.SHADOW, tema.HL)
	tema.testo(self, Vector2(sb.position.x + 3, sb.position.y + 1), stato, tema.INK, 9)


func _disegna_elenco(lv: Rect2) -> void:
	var righe := _righe()
	var cur: int = cursori[sezione]
	var ry := lv.position.y + 2
	for i in righe.size():
		if ry + RIGA_H > lv.position.y + lv.size.y - 2:
			break
		var sel := i == cur
		if sel:
			draw_rect(Rect2(lv.position.x + 2, ry, lv.size.x - 4, RIGA_H), tema.SELBG)
		var tc: Color = tema.INK_SEL if sel else tema.INK
		tema.testo(self, Vector2(lv.position.x + 5, ry + 1), str(righe[i][0]), tc, CORPO)

		# La colonna di destra allineata a DESTRA: sono prezzi e conteggi, e una
		# colonna di numeri che non finisce sulla stessa riga non si somma a occhio.
		var destra := ""
		match sezione:
			0: destra = "L. " + _lire(righe[i][1])
			1: destra = str(righe[i][1])
			_: destra = "L. " + _lire(righe[i][1])
		var x: float = lv.position.x + lv.size.x - 6 - tema.largo(destra, CORPO)
		tema.cifre(self, Vector2(x, ry + 1), destra, tc, CORPO)

		if sezione == 0 and righe[i][2] != "":
			tema.testo(self, Vector2(lv.position.x + lv.size.x * 0.50, ry + 1),
					str(righe[i][2]), tema.INK_SEL if sel else tema.GRAYTX, 9)
		ry += RIGA_H


## Il messaggio aperto. Il titolo in cima, poi il corpo riga per riga: gli a capo sono
## già nel testo, come in un post di newsgroup dove li metteva chi scriveva.
func _disegna_thread(lv: Rect2) -> void:
	var voce: Array = forum[leggendo]
	tema.testo(self, Vector2(lv.position.x + 5, lv.position.y + 2), str(voce[0]), tema.INK, CORPO)
	var y := lv.position.y + 16.0
	draw_line(Vector2(lv.position.x + 4, y), Vector2(lv.position.x + lv.size.x - 4, y),
			tema.SHADOW, 1.0)
	y += 3
	for riga in str(voce[2]).split("\n"):
		if y + 12 > lv.position.y + lv.size.y - 2:
			break
		tema.testo(self, Vector2(lv.position.x + 5, y), riga, tema.INK, CORPO)
		y += RIGA_H - 1
