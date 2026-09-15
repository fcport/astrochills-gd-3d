## LA FORMA DEL PRATO: quanto sale il terreno in ogni punto, e dove crescono i ciuffi.
##
## SOLO FUNZIONI PURE, sul modello di `QuadernoData`: niente nodi, niente SceneTree,
## niente caso che non venga da un seme. Il prato le usa per costruirsi, e il banco
## per collaudarle: un terreno che solleva l'auto o affonda sotto la soglia si scopre
## lì, non uscendo di notte.
##
## IL PRATO È PIATTO DOVE QUALCOSA CI POGGIA SOPRA: l'edificio, che ha i pavimenti a
## quota zero, e l'auto. Attorno a quelle impronte resta piatto per due metri, poi in
## tre metri diventa mosso. Dentro il recinto le onde sono basse; fuori il terreno
## sale, ed è l'Appennino che comincia. Non scende MAI sotto zero: il recinto e l'auto
## poggiano a quota zero, e un terreno più basso li lascerebbe sospesi.
class_name FormaPrato
extends RefCounted

## Il lato della maglia del terreno, in metri.
const PASSO := 1.0
## Quanto sale al massimo il prato dentro il recinto.
const MOSSO_DENTRO := 0.45
## Quanto sale in più fuori dal recinto, a regime.
const MOSSO_FUORI := 0.90
## In quanti metri, uscendo dal recinto, la salita arriva a regime.
const SALITA_FUORI := 10.0
## Quanti metri restano piatti attorno a ciò che poggia a terra.
const PIATTO_ATTORNO := 2.0
## In quanti metri il piatto diventa mosso.
const RACCORDO := 3.0
## In quanti metri il piatto lascia salire la collina di fuori. È PIÙ LUNGO DEL
## RACCORDO DELLE ONDE, e non per gusto: con tre metri anche per la collina, appena
## fuori dal cancello e accanto all'auto il prato saliva del 45%. Misurato al banco.
const RACCORDO_FUORI := 8.0
## Quante varianti di ciuffo stanno in fila nella texture di `tools/erba_blender.py`.
const VARIANTI := 4


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


## Quanto sale il terreno nel punto `p` (x e z di gioco), sopra la quota del prato.
static func altezza(p: Vector2, piatti: Array[Rect2], recinto: Rect2) -> float:
	var vicino := INF
	for r in piatti:
		vicino = minf(vicino, distanza(p, r))
	var libero := smoothstep(PIATTO_ATTORNO, PIATTO_ATTORNO + RACCORDO, vicino)
	var libero_fuori := smoothstep(PIATTO_ATTORNO, PIATTO_ATTORNO + RACCORDO_FUORI, vicino)
	var fuori := smoothstep(0.0, SALITA_FUORI, distanza(p, recinto))
	return libero * MOSSO_DENTRO * onda(p.x, p.y) + libero_fuori * MOSSO_FUORI * fuori


## Quanti vertici ha la maglia: colonne lungo x, righe lungo z.
static func vertici(estensione: Rect2) -> Vector2i:
	return Vector2i(int(ceil(estensione.size.x / PASSO)) + 1,
		int(ceil(estensione.size.y / PASSO)) + 1)


## Le quote della maglia, riga per riga lungo z e dentro la riga lungo x.
static func quote(estensione: Rect2, piatti: Array[Rect2], recinto: Rect2) -> PackedFloat32Array:
	var n := vertici(estensione)
	var q := PackedFloat32Array()
	q.resize(n.x * n.y)
	for j in n.y:
		for i in n.x:
			q[j * n.x + i] = altezza(estensione.position + Vector2(i, j) * PASSO, piatti, recinto)
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
## Ogni ciuffo è [posizione in pianta, angolo, scala, variante, quanto è secco]. I
## NUMERI SI ESTRAGGONO ANCHE PER LE CASELLE ESCLUSE, e non è uno spreco: così
## allargare l'edificio toglie i ciuffi che copre e non rimescola tutti gli altri.
static func ciuffi(seme: int, per_m2: float, estensione: Rect2, senza: Array[Rect2]) -> Array:
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
			if not _escluso(p, senza):
				fatti.append([p, angolo, scala, variante, secco])
	return fatti


static func _escluso(p: Vector2, senza: Array[Rect2]) -> bool:
	for r in senza:
		if r.has_point(p):
			return true
	return false
