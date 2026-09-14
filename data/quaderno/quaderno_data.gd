## Il quaderno delle procedure: le pagine, e come stanno sulla carta.
##
## Sul modello di `data/forum/forum_board.gd`: una Resource con un `@export Array`
## di pagine, più la logica PURA che serve a leggerle — l'a capo e il conto delle
## righe. Pura vuol dire collaudabile al banco: niente autoload, niente SceneTree,
## niente font. Dato un testo e una larghezza, torna sempre le stesse righe.
##
## PERCHÉ L'A CAPO NON LO FA IL `Label`. `autowrap` va a capo in PIXEL, e i pixel
## li conosce solo il font montato: il banco non potrebbe mai sapere se una pagina
## sborda. Qui si va a capo in COLONNE, con un font a spaziatura fissa, e la stessa
## funzione la usano il quaderno per disegnare e il banco per contare. Una pagina
## che sborda si scopre al banco, non leggendo il quaderno in partita.
class_name QuadernoData
extends Resource

## Quante lettere stanno su una riga della pagina, e quante righe sta una pagina,
## titolo compreso. Li usano il quaderno per impaginare e il banco per collaudare:
## sono la misura della CARTA, e la carta è una sola.
const COLONNE := 38
const RIGHE := 20

@export var pagine: Array[PaginaQuaderno] = []


## Il testo di una pagina spezzato in righe da `colonne` lettere al massimo.
##
## Le parole non si spezzano: va a capo lo spazio prima. Una parola più lunga di
## una riga intera — non ce ne sono, ma un percorso di file potrebbe — si taglia,
## perché l'alternativa è una riga che esce dal foglio.
##
## UN A CAPO NEL TESTO È UN A CAPO VERO, e una riga vuota resta vuota: è così che
## si separano i paragrafi e si allineano gli elenchi.
static func a_capo(testo: String, colonne: int = COLONNE) -> PackedStringArray:
	var righe := PackedStringArray()
	for paragrafo in testo.split("\n"):
		# UNA RIGA CHE CI STA NON SI TOCCA, e non per risparmiare: le tabelle dei
		# tasti sono allineate con gli SPAZI, e rifluirle parola per parola li
		# ridurrebbe a uno solo. «W A S D     cammina» diventerebbe «W A S D
		# cammina», e la colonna sparirebbe.
		if paragrafo.length() <= colonne:
			righe.append(paragrafo.rstrip(" "))
			continue
		# IL RIENTRO SI TIENE, ed è quello che fa leggere un elenco come un elenco:
		# una riga che comincia con due spazi continua con due spazi anche sotto.
		var rientro := ""
		while rientro.length() < paragrafo.length() and paragrafo[rientro.length()] == " ":
			rientro += " "
		var corrente := ""
		for parola in paragrafo.strip_edges().split(" ", false):
			var candidata := parola if corrente.is_empty() else corrente + " " + parola
			if (rientro + candidata).length() <= colonne:
				corrente = candidata
				continue
			if not corrente.is_empty():
				righe.append(rientro + corrente)
			corrente = parola
			while (rientro + corrente).length() > colonne:
				var spazio := colonne - rientro.length()
				righe.append(rientro + corrente.substr(0, spazio))
				corrente = corrente.substr(spazio)
		righe.append(rientro + corrente)
	return righe


## Le righe che la pagina occupa sulla carta: il titolo, una riga bianca, il corpo.
static func righe_di(pagina: PaginaQuaderno, colonne: int = COLONNE) -> PackedStringArray:
	var righe := PackedStringArray()
	if pagina == null:
		return righe
	if not pagina.titolo.is_empty():
		righe.append_array(a_capo(pagina.titolo.to_upper(), colonne))
		righe.append("")
	if not pagina.testo.is_empty():
		righe.append_array(a_capo(pagina.testo, colonne))
	return righe


## Le righe della pagina `i` di questo quaderno: `righe_di()`, e per la pagina
## dell'indice anche l'elenco che le pagine dopo scrivono da sé.
func righe_pagina(i: int, colonne: int = COLONNE) -> PackedStringArray:
	if i < 0 or i >= pagine.size() or pagine[i] == null:
		return PackedStringArray()
	var pagina := pagine[i]
	var righe := righe_di(pagina, colonne)
	if pagina.indice:
		if not pagina.testo.is_empty():
			righe.append("")
		righe.append_array(righe_indice(i, colonne))
	return righe


## L'indice delle pagine che vengono DOPO la pagina `dopo` — quelle prima le si è già
## lette per arrivarci. Una riga per ogni pagina con un titolo, con il numero che il
## quaderno le stampa in fondo (`- n -`, da 1); le pagine senza titolo sono il seguito
## di quella prima, e non si elencano.
##
## SI COMPONE, NON SI SCRIVE: scritto a mano, il primo testo che si allunga su due
## pagine sposterebbe tutti i numeri, e l'indice mentirebbe in silenzio.
func righe_indice(dopo: int, colonne: int = COLONNE) -> PackedStringArray:
	var righe := PackedStringArray()
	var cifre := str(pagine.size()).length()
	for i in range(dopo + 1, pagine.size()):
		var p := pagine[i]
		if p != null and not p.indice and not p.titolo.is_empty():
			righe.append(voce_indice(p.titolo, i + 1, cifre, colonne))
	return righe


## Una riga dell'indice, lunga esattamente una colonna di carta: il titolo, i puntini,
## il numero allineato a destra. Un titolo che non ci sta si accorcia, perché
## l'alternativa è un numero che esce dal foglio.
static func voce_indice(titolo: String, numero: int, cifre: int, colonne: int = COLONNE) -> String:
	var n := str(numero).lpad(cifre)
	var t := titolo.left(colonne - n.length() - 3)
	return t + " " + ".".repeat(colonne - t.length() - n.length() - 2) + " " + n


## Le pagine che non ci stanno sulla carta, come coppie [indice, righe]. Vuoto se
## ci stanno tutte. È la domanda che il banco fa, e che non si può fare guardando.
func pagine_che_sbordano(colonne: int = COLONNE, righe: int = RIGHE) -> Array:
	var fuori := []
	for i in pagine.size():
		var n := righe_pagina(i, colonne).size()
		if n > righe:
			fuori.append([i, n])
	return fuori


## Le chiavi delle fasi che hanno una pagina, nell'ordine del quaderno.
func fasi_spiegate() -> Array[StringName]:
	var chiavi: Array[StringName] = []
	for p in pagine:
		if p != null and p.fase != &"" and not chiavi.has(p.fase):
			chiavi.append(p.fase)
	return chiavi
