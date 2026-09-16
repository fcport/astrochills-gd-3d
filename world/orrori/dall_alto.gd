## LA FOTO DALL'ALTO: nella stampa, al posto della galassia, l'osservatorio visto dal cielo.
##
## La posa è finita, la stampante la tira fuori, sotto c'è scritto M51 — e nella foto c'è
## la cupola, il tetto della casa, l'auto nel prato, di notte, dall'alto. Come le vede
## adesso qualcosa che sta lassù e guarda giù, nel momento in cui la foto esce: se la
## fessura è aperta è aperta, se la cupola è girata è girata.
##
## LA PRIMA STESURA ERA UN BRACCIO NERO DENTRO LA FOTO, e a Federico è sembrato «un po'
## becero, sembra che sto tentacolo faccia fotobombing». Aveva ragione: una sagoma che entra
## di lato e si arriccia davanti al soggetto è la gag di una foto ricordo. Questa non ha
## niente di disegnato. È il mondo vero, fotografato da un posto dove nessuno può stare, con
## la cosa che fa paura spostata dalla foto al PUNTO DI VISTA: il telescopio guardava su, e
## qualcuno guardava giù.
##
## SI FOTOGRAFA DAVVERO: una seconda camera nello stesso mondo, lontana e alta, che guarda
## giù DI SBIECO con un campo stretto, come un telescopio su un monte. Dritta dall'alto la
## prima prova era un rettangolo chiaro con un triangolo scuro: un tetto visto a piombo non
## è di nessuno. Di sbieco la cupola è una cupola, e la porta è la tua. Poi SI SVILUPPA come una posa lunga: il buio si stira finché il
## prato illuminato dalla Luna viene fuori (una posa di minuti al chiaro di Luna ha i colori
## del giorno), con la grana del sensore e l'angolo più scuro del campo.
##
## L'IMMAGINE SI SALVA IN `user://`, perché è di quella notte e non si rifà: ricaricata
## domani, la stampa deve avere la stessa foto, non quella del mondo di domani.
class_name VistaDallAlto
extends RefCounted

const CARTELLA := "user://stampe/"

## Quanto è grande la foto che si scatta, e quanto quella che si tiene: si scatta al doppio
## e si rimpicciolisce, così i puntini dell'erba diventano grana e non una griglia.
const SCATTO := Vector2i(480, 270)
const TENUTA := Vector2i(240, 135)

## Da dove: quanto lontano, quanto in alto (gradi sull'orizzonte), da che azimut (gradi da
## nord verso est: da nord-est, dove stanno la porta e il prato), e quanti metri di mondo
## stanno in altezza nella foto. Trenta metri: la cupola è larga sei, cioè una ventina di pixel
## della pagina stampata.
const LONTANO := 160.0
const ALTEZZA := 58.0
const AZIMUT := 30.0
const CAMPO := 30.0

## Dove sta la cupola in pianta, se non la si trova: il centro della calotta nel modello.
const CUPOLA_DI_RISERVA := Vector3(4.0, 0.0, 4.0)

## Lo sviluppo: a che luminosità va portato il chiaro — quello sotto cui sta il 95% dei
## pixel, non il massimo —, la curva, la grana, e quanto si scurisce l'angolo.
##
## IL 95 E NON IL 99,5: al 99,5 decideva la cupola, l'unica cosa bianca, e tutto il resto
## restava un verde scuro dove non si leggeva niente.
const CHIARO := 0.95
const BIANCO := 0.85
const CURVA := 0.7
const GRANA := 0.025
const VIGNETTA := 0.45


## Scatta la foto, la sviluppa e la restituisce; `null` se non si è potuto — in headless
## non c'è niente che disegni, e la stampa esce com'è.
static func scatta(mondo: Node, sopra: Vector3) -> Image:
	# in headless i fotogrammi non si disegnano, e `frame_post_draw` non arriverebbe mai
	if mondo == null or not mondo.is_inside_tree() or DisplayServer.get_name() == "headless":
		return null
	var vista := SubViewport.new()
	vista.name = "VistaDallAlto"
	vista.size = SCATTO
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var cam := Camera3D.new()
	cam.fov = rad_to_deg(2.0 * atan(CAMPO * 0.5 / LONTANO))
	cam.near = LONTANO * 0.5
	cam.far = LONTANO * 1.6
	vista.add_child(cam)
	mondo.add_child(vista)
	var bersaglio := Vector3(sopra.x, sopra.y + 2.0, sopra.z)
	var da := bersaglio + Luna.direzione(ALTEZZA, AZIMUT) * LONTANO
	cam.global_transform = Transform3D(Basis.looking_at(bersaglio - da, Vector3.UP), da)
	cam.current = true
	for _i in 3:
		await RenderingServer.frame_post_draw
	var img := vista.get_texture().get_image()
	vista.queue_free()
	if img == null or img.is_empty():
		return null
	return sviluppa(img, hash(sopra))


## Dove centrare la foto: fra la cupola e chi ha fatto la posa, così ci sono tutti e due.
static func centro(albero: SceneTree) -> Vector3:
	var cupola := CUPOLA_DI_RISERVA
	var d := DomeAzimuth.find_in(albero)
	if d != null and d.get("_centro") != null:
		cupola = d.get("_centro")
	var g := Player.find_in(albero)
	if g == null:
		return Vector3(cupola.x, 0.0, cupola.z)
	var p := g.global_position
	var c := cupola.lerp(p, 0.5)
	# non più lontano dalla cupola di mezza foto: la cupola resta dentro
	var scarto := Vector2(c.x - cupola.x, c.z - cupola.z).limit_length(CAMPO * 0.45)
	return Vector3(cupola.x + scarto.x, 0.0, cupola.z + scarto.y)


## LO SVILUPPO DI UNA POSA LUNGA: si rimpicciolisce, si stira, grana, vignetta.
static func sviluppa(grezza: Image, seme: int) -> Image:
	var img := grezza.duplicate() as Image
	img.convert(Image.FORMAT_RGB8)
	img.resize(TENUTA.x, TENUTA.y, Image.INTERPOLATE_BILINEAR)
	var w := img.get_width()
	var h := img.get_height()
	# il punto più chiaro, non il massimo: una finestra accesa non deve decidere per tutti
	var luci := PackedFloat32Array()
	luci.resize(w * h)
	for y in h:
		for x in w:
			luci[y * w + x] = img.get_pixel(x, y).get_luminance()
	luci.sort()
	var chiaro := maxf(luci[int((luci.size() - 1) * CHIARO)], 0.004)
	var guadagno := BIANCO / chiaro
	# IL BILANCIAMENTO DEL FONDO: ogni canale portato alla media degli altri, come si fa su
	# una posa vera per togliere la dominante del cielo. Senza, la luce della Luna stirata
	# faceva il prato color ciano. Limitato, perché un canale quasi vuoto non si inventa.
	var somma := Vector3.ZERO
	for y in h:
		for x in w:
			var c0 := img.get_pixel(x, y)
			somma += Vector3(c0.r, c0.g, c0.b)
	var media := (somma.x + somma.y + somma.z) / 3.0
	var bilancia := Vector3(
		clampf(media / maxf(somma.x, 1e-6), 0.8, 1.25),
		clampf(media / maxf(somma.y, 1e-6), 0.8, 1.25),
		clampf(media / maxf(somma.z, 1e-6), 0.8, 1.25))
	var rng := RandomNumberGenerator.new()
	rng.seed = seme
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var u := (float(x) / w - 0.5) * 2.0
			var v := (float(y) / h - 0.5) * 2.0
			var bordo := 1.0 - VIGNETTA * clampf((u * u * 0.6 + v * v) * 0.5, 0.0, 1.0)
			var grana := rng.randfn(0.0, GRANA)
			c.r = clampf(pow(clampf(c.r * bilancia.x * guadagno, 0.0, 1.0), CURVA) * bordo + grana, 0.0, 1.0)
			c.g = clampf(pow(clampf(c.g * bilancia.y * guadagno, 0.0, 1.0), CURVA) * bordo + grana, 0.0, 1.0)
			c.b = clampf(pow(clampf(c.b * bilancia.z * guadagno, 0.0, 1.0), CURVA) * bordo + grana, 0.0, 1.0)
			img.set_pixel(x, y, c)
	return img


## Salva la foto sviluppata e restituisce dove; stringa vuota se non si è potuto.
static func salva(foto: Image) -> String:
	if foto == null:
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CARTELLA))
	var via := CARTELLA + "dall_alto_%d_%d.png" % [int(Time.get_unix_time_from_system()),
		Time.get_ticks_usec() % 1000000]
	if foto.save_png(via) != OK:
		push_warning("vista dall'alto: non si salva %s" % via)
		return ""
	return via


static func carica(via: String) -> Image:
	if via == "" or not FileAccess.file_exists(via):
		return null
	return Image.load_from_file(via)


## LA PAGINA CON LA FOTO DALL'ALTO al posto della foto: la carta, i margini e la sigla
## restano quelli della pagina. La foto si ritaglia al centro per riempire il riquadro.
static func componi(pagina: Image, foto: Image) -> Image:
	var img := pagina.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	var r := riquadro_foto(img)
	if r.size.x < 16 or r.size.y < 16 or foto == null:
		return img
	var f := foto.duplicate() as Image
	if f.is_compressed():
		f.decompress()
	var scala := maxf(float(r.size.x) / f.get_width(), float(r.size.y) / f.get_height())
	var fw := maxi(int(ceil(f.get_width() * scala)), r.size.x)
	var fh := maxi(int(ceil(f.get_height() * scala)), r.size.y)
	f.resize(fw, fh, Image.INTERPOLATE_BILINEAR)
	f.convert(img.get_format())
	var da := Vector2i(int((fw - r.size.x) * 0.5), int((fh - r.size.y) * 0.5))
	img.blit_rect(f, Rect2i(da, r.size), r.position)
	return img


## Sotto questa luminanza un pixel è cielo della foto, non carta.
const SCURO := 0.35
## Quanta parte di una riga o colonna deve essere cielo perché sia dentro la foto.
const PIENA := 0.6


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
