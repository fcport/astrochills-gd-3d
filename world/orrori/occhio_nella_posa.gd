## L'OCCHIO NELLA POSA: nella stampa, al posto del soggetto, un occhio.
##
## La posa finisce, la stampante la tira fuori, sotto c'è scritto M51 — e il campo è quello:
## le stesse stelle, lo stesso fondo, la stessa grana. Ma dove c'era la galassia c'è un'iride
## che sembra una nebulosa, filamenti azzurri e un bordo violaceo, e al centro una pupilla.
## Si guarda la stampa come si guarda una nebulosa, finché non ci si accorge che è lei che
## guarda. Gli astronomi chiamano davvero «l'occhio di Dio» la nebulosa Elica.
##
## LE STESURE PRIMA DI QUESTA. Un braccio nero dentro la foto («sembra che sto tentacolo faccia
## fotobombing»), poi l'osservatorio visto dall'alto da una seconda camera («un po'
## banalotto ormai»). L'occhio è il modello «Cosmic Eye of Horror» che Federico aveva messo fra
## i modelli, reso di fronte da `tools/occhio_cosmico_blender.py`.
##
## NIENTE SI APPOGGIA SULLA FOTO: CI ENTRA. Un'immagine incollata sopra una foto si riconosce
## da tre cose, e qui si tolgono tutte e tre:
##   * IL BORDO. L'iride sfuma nel fondo del cielo come l'alone di una nebulosa, invece di
##     finire con un taglio.
##   * LA LUCE. L'occhio si porta alla luminosità dell'oggetto che copre: su una foto buia
##     esce buio, su una foto chiara chiaro.
##   * LA GRANA E LE STELLE. Sopra ci va il rumore del fondo della STESSA foto, misurato, e le
##     stelle del campo che gli stavano davanti ci restano davanti: una stella è un punto più
##     chiaro dei suoi vicini, e la galassia che si copre non lo è.
##
## DOVE E QUANTO GRANDE SI MISURA SULLA FOTO: il centro è il baricentro della luce che sta
## sopra il fondo, il raggio quello che ne contiene i nove decimi. Così copre M51 con la
## compagna, una nebulosa che riempie il campo, un ammasso piccolo — le pagine di
## `assets/stampe/` sono una trentina, e nessuna ha il soggetto nello stesso posto.
##
## NON SI SALVA NIENTE: la composizione viene sempre uguale dalla stessa pagina e dallo stesso
## seme, quindi la stampa ricorda solo che è stata infestata.
class_name OcchioNellaPosa
extends RefCounted

const OCCHIO := "res://assets/textures/occhio_cosmico/occhio.png"

## Il raggio, in frazione del lato corto della foto: quanto dice la luce, dentro questi limiti.
const RAGGIO_MINIMO := 0.28
const RAGGIO_MASSIMO := 0.46
## Il raggio che contiene questa frazione della luce sopra il fondo, e di quanto lo si allarga.
const LUCE_COPERTA := 0.9
const ALLARGA := 1.15

## Il bordo: da che frazione del raggio l'iride comincia a sfumare nel cielo, e quanto resta
## della sua luce sul bordo prima di sparire.
const SFUMA_DA := 0.62
const BORDO_SPENTO := 0.3

## Sotto questa frazione della luce l'occhio non copre del tutto: resta un velo del cielo vero.
const COPRE := 0.94

## Una stella: più chiara dei suoi otto vicini di almeno tanto, e chiara almeno tanto.
const STELLA_SPICCA := 0.16
const STELLA_CHIARA := 0.3

## Sotto questa luminanza un pixel è cielo della foto, non carta.
const SCURO := 0.35
## Quanta parte di una riga o colonna deve essere cielo perché sia dentro la foto.
const PIENA := 0.6


## LA PAGINA CON L'OCCHIO al posto del soggetto. Se l'occhio non c'è (manca il file) o la
## pagina non ha un riquadro, la pagina esce com'è: meglio M51 che un foglio sbagliato.
static func componi(pagina: Image, seme: int) -> Image:
	var img := pagina.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var r := riquadro_foto(img)
	var occhio := _occhio()
	if r.size.x < 16 or r.size.y < 16 or occhio == null:
		return img
	var sogg := soggetto(img, r)
	var centro: Vector2 = sogg[&"centro"]
	var raggio: float = sogg[&"raggio"]
	var fondo: float = sogg[&"fondo"]
	var rumore: float = sogg[&"rumore"]

	var lato := maxi(int(ceil(raggio * 2.0)), 4)
	var o := occhio.duplicate() as Image
	o.resize(lato, lato, Image.INTERPOLATE_LANCZOS)
	# LA LUCE: l'iride portata alla luminosità di quello che copre
	var guadagno := clampf(float(sogg[&"picco"]) / maxf(_picco(o), 0.02), 0.45, 1.3)

	var originale := img.duplicate() as Image
	var rng := RandomNumberGenerator.new()
	rng.seed = seme
	var x0 := int(floor(centro.x - raggio))
	var y0 := int(floor(centro.y - raggio))
	for oy in lato:
		for ox in lato:
			var x := x0 + ox
			var y := y0 + oy
			if x < r.position.x or y < r.position.y or x >= r.end.x or y >= r.end.y:
				continue
			var c := o.get_pixel(ox, oy)
			if c.a <= 0.0:
				continue
			var d := Vector2(ox + 0.5 - raggio, oy + 0.5 - raggio).length() / raggio
			if d >= 1.0:
				continue
			var sfuma := smoothstep(1.0, SFUMA_DA, d)
			var luce := guadagno * lerpf(BORDO_SPENTO, 1.0, sfuma)
			var a := c.a * sfuma * COPRE
			var sotto := originale.get_pixel(x, y)
			var grana := rng.randfn(0.0, rumore) * a
			var fuori := Color(
				lerpf(sotto.r, maxf(c.r * luce, fondo), a) + grana,
				lerpf(sotto.g, maxf(c.g * luce, fondo), a) + grana,
				lerpf(sotto.b, maxf(c.b * luce, fondo), a) + grana, 1.0)
			# LE STELLE CHE GLI STAVANO DAVANTI ci restano davanti
			if _stella(originale, x, y):
				fuori = Color(maxf(fuori.r, sotto.r), maxf(fuori.g, sotto.g), maxf(fuori.b, sotto.b), 1.0)
			img.set_pixel(x, y, fuori.clamp())
	return img


## Dove sta il soggetto nella foto e com'è fatta la foto: il centro e il raggio in pixel della
## pagina, la luminanza del fondo, il suo rumore, e il chiaro del soggetto.
static func soggetto(img: Image, r: Rect2i) -> Dictionary:
	var luci := PackedFloat32Array()
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			luci.append(img.get_pixel(x, y).get_luminance())
	var ordinate := luci.duplicate()
	ordinate.sort()
	var fondo := ordinate[int(ordinate.size() * 0.3)]
	# il rumore del fondo: quanto oscillano i pixel che sono sicuramente cielo
	var somma := 0.0
	var quadri := 0.0
	var n := 0
	for v in ordinate:
		if v > ordinate[int(ordinate.size() * 0.5)]:
			break
		somma += v
		quadri += v * v
		n += 1
	var media := somma / maxf(n, 1)
	var rumore := sqrt(maxf(quadri / maxf(n, 1) - media * media, 0.0))

	# il baricentro della luce sopra il fondo
	var peso := 0.0
	var centro := Vector2.ZERO
	var w := r.size.x
	for i in luci.size():
		var sopra := maxf(luci[i] - fondo - rumore * 2.0, 0.0)
		peso += sopra
		centro += Vector2(i % w + r.position.x + 0.5, floori(float(i) / w) + r.position.y + 0.5) * sopra
	var corto := float(mini(r.size.x, r.size.y))
	if peso <= 0.0:
		centro = Vector2(r.position) + Vector2(r.size) * 0.5
	else:
		centro /= peso
	# il raggio che contiene i nove decimi di quella luce
	var anelli := PackedFloat32Array()
	anelli.resize(int(corto))
	for i in luci.size():
		var sopra := maxf(luci[i] - fondo - rumore * 2.0, 0.0)
		var p := Vector2(i % w + r.position.x + 0.5, floori(float(i) / w) + r.position.y + 0.5)
		var k := mini(int(p.distance_to(centro)), anelli.size() - 1)
		anelli[k] += sopra
	var raggio := corto * RAGGIO_MASSIMO
	var cumulata := 0.0
	for k in anelli.size():
		cumulata += anelli[k]
		if peso > 0.0 and cumulata >= peso * LUCE_COPERTA:
			raggio = (k + 1) * ALLARGA
			break
	raggio = clampf(raggio, corto * RAGGIO_MINIMO, corto * RAGGIO_MASSIMO)
	# e non fuori dalla foto: il centro si sposta dentro quanto serve
	centro.x = clampf(centro.x, r.position.x + raggio * 0.8, r.end.x - raggio * 0.8)
	centro.y = clampf(centro.y, r.position.y + raggio * 0.8, r.end.y - raggio * 0.8)

	var dentro := PackedFloat32Array()
	for i in luci.size():
		var p := Vector2(i % w + r.position.x + 0.5, floori(float(i) / w) + r.position.y + 0.5)
		if p.distance_to(centro) < raggio:
			dentro.append(luci[i])
	dentro.sort()
	var picco := dentro[int((dentro.size() - 1) * 0.97)] if not dentro.is_empty() else 0.5
	return {&"centro": centro, &"raggio": raggio, &"fondo": fondo, &"rumore": rumore, &"picco": picco}


static func _occhio() -> Image:
	if not ResourceLoader.exists(OCCHIO):
		push_warning("occhio nella posa: manca %s — lancia tools/occhio_cosmico_blender.py" % OCCHIO)
		return null
	var img := (load(OCCHIO) as Texture2D).get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Il chiaro dell'iride, come il `picco` della foto: il 97° percentile, dentro il disco.
static func _picco(o: Image) -> float:
	var luci := PackedFloat32Array()
	for y in o.get_height():
		for x in o.get_width():
			var c := o.get_pixel(x, y)
			if c.a > 0.5:
				luci.append(c.get_luminance())
	if luci.is_empty():
		return 1.0
	luci.sort()
	return luci[int((luci.size() - 1) * 0.97)]


static func _stella(img: Image, x: int, y: int) -> bool:
	if x <= 0 or y <= 0 or x >= img.get_width() - 1 or y >= img.get_height() - 1:
		return false
	var qui := img.get_pixel(x, y).get_luminance()
	if qui < STELLA_CHIARA:
		return false
	var vicini := 0.0
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx != 0 or dy != 0:
				vicini += img.get_pixel(x + dx, y + dy).get_luminance()
	return qui - vicini / 8.0 > STELLA_SPICCA


## IL RIQUADRO DELLA FOTOGRAFIA dentro la pagina di `assets/stampe/`: le righe e le colonne
## che sono quasi tutte cielo scuro. Non si scrive a mano, così vale per tutte le pagine.
static func riquadro_foto(img: Image) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var righe: Array[int] = []
	var colonne := PackedInt32Array()
	colonne.resize(w)
	for y in h:
		var scure := 0
		for x in w:
			if img.get_pixel(x, y).get_luminance() < SCURO:
				scure += 1
				colonne[x] += 1
		if scure > w * PIENA * 0.5:
			righe.append(y)
	if righe.is_empty():
		return Rect2i()
	var y0 := righe[0]
	var y1 := righe[righe.size() - 1]
	var x0 := -1
	var x1 := -1
	for x in w:
		if colonne[x] > (y1 - y0 + 1) * PIENA:
			if x0 < 0:
				x0 = x
			x1 = x
	if x0 < 0:
		return Rect2i()
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)
