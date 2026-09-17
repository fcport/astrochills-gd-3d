## LA FORMA DEL PRATO: quanto sale il terreno in ogni punto, e dove crescono i ciuffi.
##
## SOLO FUNZIONI PURE, sul modello di `QuadernoData`: niente nodi, niente SceneTree,
## niente caso che non venga da un seme. Il prato le usa per costruirsi, e il banco
## per collaudarle: un terreno che solleva l'auto o affonda sotto la soglia si scopre
## lì, non uscendo di notte.
##
## IL PRATO È LA TERRAZZA DEL POSTO VERO, e attorno il pendio vero. L'osservatorio sta
## su un ripiano ricavato nel versante: dentro la rete il terreno è quasi piano, sale
## appena verso la sterrata e scende appena verso la valle. Fuori dalla rete c'è il
## rilievo vero (`PanoramaDati`), MA NON PIÙ LONTANO DAL CIGLIO DI QUANTO SCENDE UNA
## SCARPATA: dove il pendio naturale sta molto più in basso, come verso la valle, dal
## ciglio si scende a `PENDIO_SCARPATA` finché lo si incontra, come un riporto vero.
## Sfumarci sopra su una distanza fissa faceva un muro del 125% dove la valle scende di
## tredici metri in quindici, proprio dove passa il viottolo.
##
## IL BORDO DELLA MAGLIA È IL TERRENO VERO, ALLA LETTERA. Prima il prato era un
## rettangolo a quota sua con sotto il rilievo trentacinque centimetri più giù, e tutto
## attorno si vedeva il gradino. Adesso lungo il bordo il prato legge la stessa
## superficie a triangoli che disegna la griglia del panorama, e la griglia sotto il
## prato non c'è: le due maglie si toccano su una linea, senza sovrapporsi.
##
## IL PRATO È PIATTO DOVE QUALCOSA CI POGGIA SOPRA: l'edificio, che ha i pavimenti a
## quota zero, e l'auto, sullo slargo della sterrata. Attorno a quelle impronte resta
## piatto per due metri, poi in tre metri torna alla forma del posto.
class_name FormaPrato
extends RefCounted

## Il lato della maglia del terreno, in metri.
const PASSO := 1.0
## Quanto sale al massimo il prato dentro il recinto, per le onde.
const MOSSO_DENTRO := 0.30
## Quanti metri restano piatti attorno a ciò che poggia a terra.
const PIATTO_ATTORNO := 2.0
## In quanti metri il piatto diventa mosso.
const RACCORDO := 3.0
## LA TERRAZZA: dentro la rete il pendio vero conta per questa frazione, e resta fra
## queste due quote. Il pendio lì è del quindici per cento; il ripiano delle foto sale
## appena verso la sterrata e il cordolo, e dal cancello si vede quasi piano.
const PENDENZA_DENTRO := 0.6
const TERRAZZA_GIU := -0.3
const TERRAZZA_SU := 1.0
## La pendenza di una scarpata di riporto o di scavo, fra il ciglio e il pendio naturale:
## quarantacinque gradi, il massimo a cui una scarpata erbosa sta ferma. Il versante verso la
## valle scende già al settanta per cento: con una scarpata meno ripida del pendio non lo
## raggiungerebbe mai, e il raccordo si farebbe tutto sul bordo della maglia.
const PENDIO_SCARPATA := 1.0
## In quanti metri dal bordo della maglia il terreno torna esattamente quello vero, se la
## scarpata non ci è già arrivata: il bordo deve combaciare con la griglia del panorama.
const BORDO := 4.0
## Di quanti metri fuori dalla rete le onde si spengono.
const ONDE_FUORI := 2.0
## Quante varianti di ciuffo stanno in fila nella texture di `tools/erba_blender.py`.
const VARIANTI := 4


## TUTTO QUELLO CHE DECIDE LA FORMA, messo insieme dal prato (`Prato.sito()`) o dal banco.
class Sito:
	## Il rettangolo della maglia, in pianta.
	var estensione := Rect2()
	## La rete, come poligono chiuso.
	var recinto := PackedVector2Array()
	## Le impronte piatte, e a che quota sta ciascuna (in coordinate del prato).
	var piatti: Array[Rect2] = []
	var quote_piatti := PackedFloat32Array()
	## Il terreno vero attorno; `null` se il panorama non c'è, e allora fuori resta la
	## terrazza.
	var rilievo: PanoramaDati = null
	## La quota del nodo del prato: il rilievo è in coordinate del mondo.
	var base := 0.0


## Le onde del prato, fra 0 e 1: tre sinusoidi con passi da undici a ventisette metri.
## NIENTE RUMORE CASUALE: la stessa gobba deve stare nello stesso posto a ogni avvio, e
## in una formula si legge dove.
static func onda(x: float, z: float) -> float:
	var s := 0.5 * sin(0.23 * x + 1.3) * cos(0.19 * z + 0.4) \
		+ 0.3 * sin(0.41 * x + 0.37 * z + 2.1) \
		+ 0.2 * cos(0.57 * z - 0.29 * x + 0.8)
	return clampf(0.5 + 0.5 * s, 0.0, 1.0)


## La distanza in pianta di un punto da un rettangolo: zero dentro.
static func distanza(p: Vector2, r: Rect2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dz := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return sqrt(dx * dx + dz * dz)


## La distanza in pianta di un punto dal bordo di un poligono chiuso: NEGATIVA DENTRO.
static func distanza_poligono(p: Vector2, poligono: PackedVector2Array) -> float:
	var n := poligono.size()
	if n < 3:
		return INF
	var vicino := INF
	for k in n:
		var q := Geometry2D.get_closest_point_to_segment(p, poligono[k], poligono[(k + 1) % n])
		vicino = minf(vicino, p.distance_to(q))
	return -vicino if Geometry2D.is_point_in_polygon(p, poligono) else vicino


## Il minimo e il massimo morbidi: una terrazza tagliata a spigolo farebbe una piega
## lunga tutto il prato, dove il pendio vero incrocia la quota di taglio.
static func _min_morbido(a: float, b: float, k: float) -> float:
	if k <= 1e-4:
		return minf(a, b)
	var h := maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * k * 0.25


static func _max_morbido(a: float, b: float, k: float) -> float:
	return -_min_morbido(-a, -b, k)


## Quanto sale il terreno nel punto `p` (x e z di gioco), in coordinate del prato.
static func altezza(p: Vector2, sito: Sito) -> float:
	var vero := 0.0
	if sito.rilievo != null:
		vero = sito.rilievo.quota_griglia(p) - sito.base
	var fuori := distanza_poligono(p, sito.recinto)
	var terrazza := _min_morbido(_max_morbido(PENDENZA_DENTRO * vero, TERRAZZA_GIU, 0.5),
		TERRAZZA_SU, 0.5)
	var h := terrazza + MOSSO_DENTRO * onda(p.x, p.y) * (1.0 - smoothstep(0.0, ONDE_FUORI, fuori))
	if sito.rilievo != null:
		# il terreno vero, dentro il cono che scende e sale dal ciglio
		var cono := PENDIO_SCARPATA * maxf(fuori, 0.0)
		var morbido := minf(cono, 0.8)
		h = _max_morbido(_min_morbido(vero, h + cono, morbido), h - cono, morbido)
		# e sul bordo della maglia, quello vero e basta
		var dal_bordo := minf(minf(p.x - sito.estensione.position.x, sito.estensione.end.x - p.x),
			minf(p.y - sito.estensione.position.y, sito.estensione.end.y - p.y))
		h = lerpf(vero, h, smoothstep(0.0, BORDO, dal_bordo))
	# il piatto più vicino decide
	var vicino := INF
	var in_piano := 0.0
	for k in sito.piatti.size():
		var d := distanza(p, sito.piatti[k])
		if d < vicino:
			vicino = d
			in_piano = sito.quote_piatti[k] if k < sito.quote_piatti.size() else 0.0
	if vicino < INF:
		h = lerpf(in_piano, h, smoothstep(PIATTO_ATTORNO, PIATTO_ATTORNO + RACCORDO, vicino))
	return h


## Quanti vertici ha la maglia: colonne lungo x, righe lungo z.
static func vertici(estensione: Rect2) -> Vector2i:
	return Vector2i(int(ceil(estensione.size.x / PASSO)) + 1,
		int(ceil(estensione.size.y / PASSO)) + 1)


## Le quote della maglia, riga per riga lungo z e dentro la riga lungo x.
static func quote(sito: Sito) -> PackedFloat32Array:
	var n := vertici(sito.estensione)
	var q := PackedFloat32Array()
	q.resize(n.x * n.y)
	for j in n.y:
		for i in n.x:
			q[j * n.x + i] = altezza(sito.estensione.position + Vector2(i, j) * PASSO, sito)
	return q


## La quota del terreno COME LO DISEGNA LA MAGLIA, non come dice la formula. Fra un
## vertice e l'altro la maglia è piana, e un ciuffo posato sulla formula starebbe
## qualche centimetro sopra o sotto il terreno che si vede. Ogni quadrato è diviso
## lungo la diagonale da (i, j) a (i+1, j+1): la stessa di `Prato._terreno()`.
static func quota(p: Vector2, estensione: Rect2, q: PackedFloat32Array) -> float:
	var n := vertici(estensione)
	var locale := (p - estensione.position) / PASSO
	var i := clampi(int(floor(locale.x)), 0, n.x - 2)
	var j := clampi(int(floor(locale.y)), 0, n.y - 2)
	var u := clampf(locale.x - i, 0.0, 1.0)
	var v := clampf(locale.y - j, 0.0, 1.0)
	var h00 := q[j * n.x + i]
	var h10 := q[j * n.x + i + 1]
	var h01 := q[(j + 1) * n.x + i]
	var h11 := q[(j + 1) * n.x + i + 1]
	if u >= v:
		return h00 + u * (h10 - h00) + v * (h11 - h10)
	return h00 + v * (h01 - h00) + u * (h11 - h01)


## Dove crescono i ciuffi: uno per casella di una griglia fitta, spostato a caso dentro
## la sua casella. In fila si vedrebbe la fila, a caso puro vengono radure e grumi.
##
## SOLO SUL PRATO DEL RECINTO, fino a `oltre` metri fuori dalla rete: la scarpata e il
## pendio attorno sono il terreno del panorama, che l'erba ce l'ha nella trama. E non
## sulla ghiaia.
##
## Ogni ciuffo è [posizione in pianta, angolo, scala, variante, quanto è secco]. I
## NUMERI SI ESTRAGGONO ANCHE PER LE CASELLE ESCLUSE, e non è uno spreco: così
## allargare l'edificio toglie i ciuffi che copre e non rimescola tutti gli altri.
static func ciuffi(seme: int, per_m2: float, estensione: Rect2, senza: Array[Rect2],
		recinto := PackedVector2Array(), oltre := INF,
		ghiaia: Array[PackedVector2Array] = []) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seme
	var lato := 1.0 / sqrt(per_m2)
	var fatti := []
	for j in int(estensione.size.y / lato):
		for i in int(estensione.size.x / lato):
			var p := estensione.position + Vector2(i + rng.randf(), j + rng.randf()) * lato
			var angolo := rng.randf() * TAU
			var scala := rng.randf_range(0.5, 1.2)
			var variante := rng.randi_range(0, VARIANTI - 1)
			var secco := rng.randf()
			if _escluso(p, senza):
				continue
			if recinto.size() >= 3 and distanza_poligono(p, recinto) > oltre:
				continue
			if _sulla_ghiaia(p, ghiaia):
				continue
			fatti.append([p, angolo, scala, variante, secco])
	return fatti


static func _escluso(p: Vector2, senza: Array[Rect2]) -> bool:
	for r in senza:
		if r.has_point(p):
			return true
	return false


static func _sulla_ghiaia(p: Vector2, ghiaia: Array[PackedVector2Array]) -> bool:
	for poligono in ghiaia:
		if Geometry2D.is_point_in_polygon(p, poligono):
			return true
	return false
