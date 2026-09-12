## LA LUNA È QUELLA DEL CALENDARIO? E ILLUMINA COME DICE DI ILLUMINARE?
##
## PERCHÉ SERVE UNA SONDA. Perché un modello lunare sbagliato non ha nessun
## sintomo. Qualunque formula plausibile produce una palla che cresce e cala in
## un mese, sorge, tramonta, e sembra giusta a chiunque la guardi — compreso a
## chi l'ha scritta. La differenza fra una Luna vera e una Luna verosimile non si
## vede a occhio: si vede solo confrontandola con un almanacco.
##
## LE DOMANDE:
##   0. LE COPIE. `core/luna.gd` non può dipendere da niente, quindi ricopia
##      l'ora d'inizio della notte, la latitudine e la formula dell'altezza. Tre
##      copie che divergano farebbero sorgere la Luna un'ora sbagliata, da un'altra
##      latitudine, e in un posto diverso da dove il planetario cerca le stelle.
##   1. L'ALMANACCO. Sei date lunari VERE del 1999 — tre noviluni e tre pleniluni,
##      fra cui l'eclissi totale dell'11 agosto, che è la data lunare più
##      verificabile del secolo. A quegli istanti l'angolo di fase deve valere 180
##      e 0. È l'unica domanda che dice se questo è un modello o un'invenzione.
##   2. LA SUPERLUNA. Il 22 dicembre 1999 la Luna piena è stata la più vicina del
##      secolo: 356 mila chilometri, un disco del sette per cento più grande del
##      solito. Un modello che ignorasse l'ellisse darebbe la stessa dimensione di
##      sempre, e la domanda 1 non se ne accorgerebbe.
##   3. IL CALENDARIO DEL MESE, che non è una prova: è la tabella da leggere. Per
##      trenta notti di fila, che luna c'è, quanto è alta, quanta luce fa e quanti
##      pixel misura sullo schermo vero.
##   4. LA LAMPADA. In scena: la direzionale punta davvero dove sta la Luna,
##      l'energia segue la fase, e a Luna tramontata resta solo il fondo.
##   5. LO SHADER LO SA. I parametri della Luna finiscono davvero nel materiale
##      del cielo. Fra il conto giusto e il disco disegnato c'è una
##      `set_shader_parameter`, ed è esattamente il punto in cui una Luna perfetta
##      può non arrivare da nessuna parte.
##
## IL DIFETTO SI RIMETTE, ed è l'interruttore che dice se questa sonda misura
## quello che crede:
##   FISSA=1   la luna torna com'era: una posa sola, un'energia sola, sempre. Le
##             domande 4 e 5 devono trovare tutto immobile — stessa direzione a
##             ogni ora, stessa energia in tutte le notti del mese.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_luna.tscn
##     FISSA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_luna.tscn
##
## GIRA IN HEADLESS, e può: qui non si guarda nessun pixel, si leggono numeri e
## parametri di materiale. Il disco DISEGNATO è un'altra domanda e ha un altro
## attrezzo — `tools/scatta_luna.gd`, che salva le fasi in PNG da guardare.
##
## IL TEMPO SI SCRIVE, e qui è lecito: la Luna è una funzione dell'istante e di
## nient'altro — nessun motore, nessuna inerzia, nessun accumulo. È il contrario
## di `prova_rotazione.gd`, dove scrivere l'ora falsava tutto perché lì di mezzo
## ci sono motori che si muovono a gradi al secondo.
extends Node

## Le date lunari vere del 1999, con l'ora della congiunzione o dell'opposizione
## in UT e l'angolo di fase che ci si aspetta lì: 180 al novilunio, 0 al
## plenilunio. Sono valori d'almanacco, non prodotti da questo codice.
const ALMANACCO := [
	["novilunio  11 ago 1999 11:09 UT (eclissi totale)", 1999, 8, 11, 11.15, 180.0],
	["plenilunio 26 ago 1999 23:48 UT", 1999, 8, 26, 23.80, 0.0],
	["novilunio   8 nov 1999 03:53 UT", 1999, 11, 8, 3.88, 180.0],
	["plenilunio 23 nov 1999 07:04 UT", 1999, 11, 23, 7.07, 0.0],
	["novilunio   7 dic 1999 22:32 UT", 1999, 12, 7, 22.53, 180.0],
	["plenilunio 22 dic 1999 17:31 UT (la piu' vicina del secolo)", 1999, 12, 22, 17.52, 0.0],
]

## Quanto si ammette di sbagliare sull'almanacco, in gradi di angolo di fase.
##
## MEZZO GRADO, E VUOL DIRE UN'ORA. La fase corre di dodici gradi al giorno,
## quindi mezzo grado sono sessanta minuti: è il limite oltre il quale un
## calendario lunare comincerebbe a sbagliare il GIORNO. Misurato, il modello sta
## fra 0,09 e 0,33 — cioè dentro la mezz'ora — e il margine serve a non far
## saltare la sonda per un arrotondamento.
const ERRORE_FASE_MAX := 0.5

## La distanza pubblicata della luna piena del 22 dicembre 1999, in chilometri, e
## quanto si ammette di sbagliarla. Duemila chilometri sono mezzo per cento:
## largo abbastanza per un modello troncato ai termini grossi, e strettissimo
## rispetto a quello che serve per arrivarci — il termine dell'ellisse ne vale
## VENTIMILA, quindi senza di lui questa prova salta di dieci volte la soglia.
const PERIGEO_VERO := 356654.0
const PERIGEO_TOLLERANZA := 2000.0

## Quante notti si stampano nella tabella: un mese sinodico e mezzo, così il ciclo
## si vede chiudersi e ricominciare.
const NOTTI := 30

## Le ore della notte in cui si guarda, in minuti dall'inizio (le 21:00).
const ORE := [0.0, 240.0, 480.0]

## Lo schermo vero su cui la Luna si disegna, e il campo visivo della camera del
## giocatore. Servono al conto in pixel della domanda 3: `main.tscn` mette il
## mondo in un SubViewport con `stretch_shrink = 2`, quindi 1280x720 diventano
## 640x360, e la camera del giocatore non dichiara `fov` — cioè sta al default.
const SCHERMO_ALTO := 360.0
const FOV := 75.0

## Quanto si ammette che la lampada guardi fuori dalla Luna, in gradi, quando la
## Luna è sopra i venti gradi d'altezza. QUASI ZERO, E DEVE ESSERLO: sopra i
## diciotto gradi il peso del chiarore di fondo è finito, e da lì in su la
## lampada È la Luna. Questa soglia è la ragione per cui questa sonda esiste:
## alla prima stesura la trovava a VENTOTTO gradi — la luna a sud-ovest e le
## ombre da sopra — e il difetto non si vedeva da nessun'altra parte.
const SCARTO_DIREZIONE_MAX := 1.5

var _guasti := 0
var _fissa := false


func _ready() -> void:
	_fissa = OS.get_environment("FISSA") == "1"
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[luna] GUASTO: " + msg)


func _prova() -> void:
	print("")
	print("=== LA LUNA DEL CALENDARIO ===")
	_copie()
	_almanacco()
	_superluna()
	_calendario()
	await _in_scena()
	print("")
	print("[luna] %s" % ("nessun guasto" if _guasti == 0 else "%d GUASTI" % _guasti))
	get_tree().quit(1 if _guasti > 0 else 0)


## --- 0. LE COPIE ------------------------------------------------------------
func _copie() -> void:
	print("")
	print("-- 0. le costanti ricopiate, e la formula ricopiata")
	var clock := preload("res://night/night_clock.gd")
	print("   ora d'inizio: Luna %d, NightClock %d" % [Luna.ORA_INIZIO, clock.NIGHT_START_HOUR])
	if Luna.ORA_INIZIO != clock.NIGHT_START_HOUR:
		_guasto("l'ora d'inizio della notte diverge: la Luna sorge a un'ora che il gioco non ha")
	print("   latitudine:   Luna %.2f, SkyGeometry %.2f" % [Luna.LATITUDINE, SkyGeometry.LATITUDINE])
	if not is_equal_approx(Luna.LATITUDINE, SkyGeometry.LATITUDINE):
		_guasto("la latitudine diverge: la Luna e le stelle stanno su due osservatori diversi")

	# LA FORMULA DELL'ALTEZZA, confrontata su un campione che copre tutto: est,
	# meridiano, ovest, e declinazioni da sotto l'equatore al circumpolare.
	var peggio := 0.0
	for ha in [-120.0, -90.0, -45.0, 0.0, 45.0, 90.0, 120.0]:
		for dec in [-25.0, -5.0, 20.0, 40.0, 60.0, 80.0]:
			var mia := Luna.alt_az(ha, dec).x
			var sua := SkyGeometry.altezza(ha, dec)
			peggio = maxf(peggio, absf(mia - sua))
	print("   altezza: Luna.alt_az contro SkyGeometry.altezza, scarto massimo %.6f gradi" % peggio)
	if peggio > 0.0001:
		_guasto("le due copie della trigonometria sferica non dicono la stessa cosa")


## --- 1. L'ALMANACCO ---------------------------------------------------------
func _almanacco() -> void:
	print("")
	print("-- 1. l'almanacco del 1999: sei date lunari vere")
	for riga in ALMANACCO:
		var jd: float = float(Luna.giuliano_di(riga[1], riga[2], riga[3])) - 0.5 + float(riga[4]) / 24.0
		var e := Luna.effemeridi(jd)
		var atteso: float = riga[5]
		# La differenza si prende sul cerchio: 359,9 e 0,1 distano due decimi,
		# non trecentosessanta.
		var scarto: float = absf(fposmod(float(e[&"fase"]) - atteso + 180.0, 360.0) - 180.0)
		# Dodici gradi di fase al giorno: lo scarto in gradi si legge in minuti.
		var minuti := scarto / 12.19 * 1440.0
		print("   %-58s fase %6.2f  scarto %.2f gradi (%.0f min)  k=%.3f"
			% [riga[0], e[&"fase"], scarto, minuti, e[&"illuminata"]])
		if scarto > ERRORE_FASE_MAX:
			_guasto("%s: la fase sbaglia di %.2f gradi" % [riga[0], scarto])


## --- 2. LA SUPERLUNA --------------------------------------------------------
func _superluna() -> void:
	print("")
	print("-- 2. la luna piena del 22 dicembre 1999: la piu' vicina del secolo")
	var jd := float(Luna.giuliano_di(1999, 12, 22)) - 0.5 + 17.52 / 24.0
	var e := Luna.effemeridi(jd)
	# IL CONFRONTO È CON LA DISTANZA MEDIA, non con un'altra luna piena a caso:
	# la piena di gennaio 2000 cadeva anch'essa vicino al perigeo, e paragonarle
	# avrebbe dato un misero uno per cento — un confronto che nasconde proprio
	# l'effetto che si vuole misurare.
	var medio := 2.0 * rad_to_deg(asin(Luna.RAGGIO_KM / 385000.56))
	print("   22 dic: %.0f km, disco %.4f gradi" % [e[&"distanza"], e[&"diametro"]])
	print("   distanza media: 385000 km, disco %.4f gradi -> %+.1f%% di diametro"
		% [medio, (float(e[&"diametro"]) / medio - 1.0) * 100.0])
	if absf(float(e[&"distanza"]) - PERIGEO_VERO) > PERIGEO_TOLLERANZA:
		_guasto("la distanza al perigeo sbaglia di %.0f km: manca l'ellisse dell'orbita"
			% absf(float(e[&"distanza"]) - PERIGEO_VERO))
	if float(e[&"diametro"]) <= medio * 1.03:
		_guasto("la superluna non e' piu' grande di una luna media: manca l'ellisse")


## --- 3. IL CALENDARIO -------------------------------------------------------
func _calendario() -> void:
	print("")
	print("-- 3. il mese di lavoro: che luna c'e', notte per notte")
	# Quanti gradi di cielo sta un pixel dello schermo vero: serve a dire se il
	# disco disegnato ha abbastanza pixel per avere una fase.
	var per_pixel := FOV / SCHERMO_ALTO
	var vero := Luna.effemeridi(Luna.istante(1, 0.0))
	print("   lo schermo: %.0fx%.0f a %.0f gradi -> %.3f gradi per pixel."
		% [SCHERMO_ALTO * 16.0 / 9.0, SCHERMO_ALTO, FOV, per_pixel])
	print("   il disco VERO misura %.1f pixel; ingrandito %.0f volte ne misura %.1f."
		% [float(vero[&"diametro"]) / per_pixel, LuceDiLuna.INGRANDIMENTO,
			float(vero[&"diametro"]) * LuceDiLuna.INGRANDIMENTO / per_pixel])
	print("")
	print("   notte  data                fase        k     disco    alt 21:00  01:00  05:00   energia")
	for n in range(1, NOTTI + 1):
		var e := Luna.effemeridi(Luna.istante(n, 0.0))
		var nome := Luna.fase_scritta(float(e[&"fase"]), Luna.crescente(float(e[&"eta"])))
		var alte := PackedFloat64Array()
		var energia_max := 0.0
		for m in ORE:
			var x := Luna.effemeridi(Luna.istante(n, m))
			alte.append(float(x[&"alt"]))
			energia_max = maxf(energia_max, _energia(x))
		print("   %4d   %-18s %-18s %.2f  %.4f   %+5.0f  %+5.0f  %+5.0f    %.3f"
			% [n, Luna.data_scritta(n), nome, e[&"illuminata"], e[&"diametro"],
				alte[0], alte[1], alte[2], energia_max])


## L'energia che la lampada produrrebbe con quelle effemeridi. RICOPIA la formula
## di `luce_di_luna.gd`, e lo fa apposta: le costanti si leggono dal nodo vero
## (`LuceDiLuna.ENERGIA_*`), quindi quello che si ricopia è solo la forma — e la
## domanda 4 confronta questo conto con quello che la lampada ha davvero in
## `light_energy`, che è il modo in cui la copia non può divergere in silenzio.
func _energia(e: Dictionary) -> float:
	var elev := clampf(sin(deg_to_rad(float(e[&"alt"]))), 0.0, 1.0)
	return LuceDiLuna.ENERGIA_CIELO + LuceDiLuna.ENERGIA_LUNA * float(e[&"illuminata"]) * elev


## --- 4 e 5. IN SCENA --------------------------------------------------------
func _in_scena() -> void:
	print("")
	print("-- 4. la lampada in scena, e 5. quello che arriva allo shader")
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().process_frame

	var luna := LuceDiLuna.find_in(get_tree())
	if luna == null:
		_guasto("non trovo la luna in scena: il copione non e' montato sul nodo")
		return
	if Game.run == null:
		_guasto("la notte non e' cominciata: non c'e' un calendario da seguire")
		return
	if _fissa:
		luna.fissa = true
		print("   FISSA=1: la luna torna com'era, e non si deve muovere piu' niente")

	var mat := _materiale_del_cielo()
	if mat == null:
		_guasto("non trovo il materiale del cielo: il disco non lo disegna nessuno")

	# LE NOTTI: si scorre il mese e si guarda l'energia. Serve a vedere il ciclo
	# arrivare fino in fondo alla lampada, non solo fino alla tabella.
	var minima := INF
	var massima := -INF
	var notte_min := 0
	var notte_max := 0
	for n in range(1, NOTTI + 1):
		Game.run.night_index = n
		var picco := 0.0
		for m in ORE:
			Game.run.elapsed_min = m
			await get_tree().process_frame
			picco = maxf(picco, luna.light_energy)
		if picco < minima:
			minima = picco
			notte_min = n
		if picco > massima:
			massima = picco
			notte_max = n
	print("   sul mese: notte piu' buia la %d (%.3f), piu' chiara la %d (%.3f)"
		% [notte_min, minima, notte_max, massima])
	if _fissa:
		if not is_equal_approx(minima, massima):
			_guasto("FISSA=1 e l'energia cambia lo stesso: l'interruttore non spegne niente")
	elif massima - minima < 0.15:
		_guasto("fra la notte piu' buia e la piu' chiara ci sono %.3f: il calendario non si vede"
			% (massima - minima))

	# UNA NOTTE SOLA, ORA PER ORA. Si torna alla notte 1 e si segue la Luna dal
	# tramonto in poi: è il caso in cui la lampada deve andare a fondo.
	Game.run.night_index = 1
	print("")
	print("   la notte 1, ora per ora:")
	var direzioni: Array[Vector3] = []
	var energie: Array[float] = []
	# NOVE LETTURE E NON DIECI, e il motivo è l'alba: alle 06:00 `elapsed_min`
	# vale 540, l'orologio della notte chiude la partita e `Game.run` cambia
	# sotto i piedi alla sonda. Si misura la notte, non il suo confine.
	for ora in range(0, 9):
		Game.run.elapsed_min = float(ora) * 60.0
		await get_tree().process_frame
		var e := luna.effemeridi()
		var atteso := _energia(e)
		var verso := -luna.global_basis.z
		var scarto := rad_to_deg((-verso).angle_to(Vector3(e[&"dir"])))
		direzioni.append(verso)
		energie.append(luna.light_energy)
		print("      %02d:00  alt %+5.1f  k %.2f  energia %.3f (attesa %.3f)  scarto dalla luna %5.1f gradi"
			% [(Luna.ORA_INIZIO + ora) % 24, e[&"alt"], e[&"illuminata"],
				luna.light_energy, atteso, scarto])
		if not _fissa:
			if not is_equal_approx(luna.light_energy, atteso):
				_guasto("l'energia della lampada non e' quella delle sue effemeridi")
			# La direzione si controlla SOLO quando la Luna conta davvero:
			# a Luna bassa o falce il peso del fondo domina, ed è giusto che
			# domini — la lampada in quel momento non è la Luna, è il cielo.
			if float(e[&"alt"]) > 20.0 and float(e[&"illuminata"]) > 0.5 and scarto > SCARTO_DIREZIONE_MAX:
				_guasto("con la luna alta e mezza illuminata la lampada guarda %.1f gradi fuori" % scarto)

	if _fissa:
		var mossa := 0.0
		for d in direzioni:
			mossa = maxf(mossa, rad_to_deg(d.angle_to(direzioni[0])))
		print("   FISSA=1: in nove ore la lampada si e' mossa di %.3f gradi" % mossa)
		if mossa > 0.001:
			_guasto("FISSA=1 e la lampada si muove lo stesso")
	else:
		var mossa := rad_to_deg(direzioni[0].angle_to(direzioni[direzioni.size() - 1]))
		print("   in nove ore la lampada si e' spostata di %.1f gradi" % mossa)
		if mossa < 5.0:
			_guasto("in nove ore la luce non si e' spostata: l'ombra sul prato sta ferma")

	# --- 5. LO SHADER --------------------------------------------------------
	if mat == null:
		return
	Game.run.elapsed_min = 0.0
	await get_tree().process_frame
	var e0 := luna.effemeridi()
	var scritta: Vector3 = mat.get_shader_parameter("luna_dir")
	var raggio: float = mat.get_shader_parameter("luna_raggio")
	var luce: float = mat.get_shader_parameter("luna_luce")
	var chiarore: float = mat.get_shader_parameter("luna_chiarore")
	var sole: Vector3 = mat.get_shader_parameter("sole_dir")
	print("")
	print("   nel materiale del cielo: dir(%.3f, %.3f, %.3f) raggio %.5f rad (%.2f gradi di disco)"
		% [scritta.x, scritta.y, scritta.z, raggio, rad_to_deg(raggio) * 2.0])
	print("   luce %.3f, chiarore %.3f, sole a %.1f gradi dalla luna (fase)"
		% [luce, chiarore, rad_to_deg(sole.angle_to(Vector3(e0[&"dir"])))])
	if scritta.distance_to(Vector3(e0[&"dir"])) > 0.001:
		_guasto("la direzione scritta nel cielo non e' quella delle effemeridi")
	if is_zero_approx(raggio):
		_guasto("il raggio del disco e' zero: in cielo non si disegna niente")
	# L'ANGOLO FRA SOLE E LUNA È L'ELONGAZIONE, e l'angolo di fase ne è il
	# supplemento: sono la stessa cosa detta da due parti, e se non tornassero il
	# disco sarebbe illuminato dalla parte sbagliata pur avendo la fase giusta.
	var elong := rad_to_deg(sole.angle_to(Vector3(e0[&"dir"])))
	if absf((180.0 - elong) - float(e0[&"fase"])) > 0.5:
		_guasto("la direzione del Sole non concorda con la fase: la falce guarda in la'")


func _materiale_del_cielo() -> ShaderMaterial:
	var we := get_tree().current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if we == null or we.environment == null or we.environment.sky == null:
		return null
	return we.environment.sky.sky_material as ShaderMaterial
