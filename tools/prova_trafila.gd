## DA DOVE VIENE QUELLA LUCE. Si spegne una lampada alla volta e si guarda chi
## manca.
##
## PERCHÉ ESISTE. «Nella sala, quando tutto è chiuso, ci sono queste luci dal
## nulla: quella riflessa per terra e quella riflessa nel muro.» Una macchia
## luminosa in una stanza spenta ha almeno quattro spiegazioni possibili — una
## lampada accesa che non si vede, una luce che passa attraverso un muro, un
## materiale emissivo, un riflesso speculare — e a occhio si sceglie sempre quella
## che si aveva già in mente. Qui non si sceglie: si spegne.
##
## IL METODO È L'ATTRIBUZIONE PER DIFFERENZA. Si fissa la telecamera, si scatta la
## foto di riferimento, poi si spegne UNA sorgente per volta e si riscatta. La
## sorgente che, spegnendosi, fa sparire la macchia È la macchia. Non è una
## deduzione: è una sottrazione.
##
## SI GUARDA ANCHE SOLO IL PAVIMENTO, in una finestra separata, perché la domanda
## non è «chi illumina la stanza» — quello lo so — ma «chi fa quella chiazza lì».
## Una lampada può cambiare pochissimo l'immagine intera e tutto il pavimento.
##
## SI RESTA FERMI E IN PAUSA: la notte non scorre, il giocatore non si assesta, e
## l'unica cosa che cambia fra uno scatto e l'altro è la lampada che ho toccato.
extends Node

## Quanti fotogrammi passano fra il tocco e lo scatto. La cattura arriva dalla GPU
## con un ritardo variabile, e confrontare due immagini disallineate è il modo in
## cui una sonda si inventa un risultato (già successo, D-179).
const RESPIRO := 6

## Dove si guarda. Le due viste sono quelle delle fotografie: VISTA=libreria è la
## sala divulgazione verso gli scaffali, VISTA=cucina è la stessa sala verso la
## porta della cucina.
const VISTE := {
	"libreria": [Vector3(9.60, 0.0, 7.30), Vector3(11.90, 1.10, 4.30)],
	"cucina": [Vector3(9.30, 0.0, 6.00), Vector3(10.20, 1.35, 2.60)],
	# Dentro la cucina, davanti al bancone: è la vista in cui la lampada da tavolo
	# bruciava l'alzatina, e quella in cui si verifica che non lo faccia più.
	"banco": [Vector3(10.90, 0.0, 3.40), Vector3(10.90, 1.15, 1.70)],
	# Davanti al CRT, in piedi: la luce che il monitor butta sulla cassa beige e
	# sulla consolle è l'unica cosa che dice «lo schermo è acceso».
	"monitor": [Vector3(6.55, 0.0, 2.00), Vector3(5.75, 1.16, 2.00)],
	# Sul prato a nord-est, il naso in su: si vede il cielo e mezzo edificio.
	"prato": [Vector3(13.00, 0.0, -3.50), Vector3(8.00, 6.00, 2.00)],
	# In cupola, sotto la fenditura, lo sguardo allo zenit: è la vista in cui si
	# giudica quanta luce entra quando i portelli si aprono.
	"cupola": [Vector3(2.60, 0.0, 4.60), Vector3(2.60, 5.20, 2.50)],
	# In cupola ma guardando il pavimento e la passerella: qui non c'è il cielo a
	# fare da attore, e si vede solo quello che la sua luce illumina.
	"cupola_giu": [Vector3(4.40, 0.0, 4.60), Vector3(2.20, 0.55, 2.20)],
	# Sulla passerella, all'altezza dell'oculare (2,29 m): è la posa in cui Federico
	# ha fotografato la propria ombra proiettata sul tubo del telescopio.
	"oculare": [Vector3(4.00, 0.59, 2.50), Vector3(2.60, 2.10, 2.50)],
	# Il quadro elettrico in facciata, da un metro: e' la distanza da cui lo si
	# guarda per premerlo.
	"quadro": [Vector3(11.55, 0.0, 10.70), Vector3(11.55, 1.45, 9.60)],
	# Mirando il fungo rosso, che e' un bersaglio suo e ha un prompt suo.
	"fungo": [Vector3(11.60, 0.0, 10.55), Vector3(11.597, 1.360, 9.845)],
	# Sul prato davanti all'ingresso, a sette metri e mezzo, voltati verso la
	# facciata: e' la vista di chi esce e si gira. La facciata guarda a nord (+Z),
	# cioe' dalla parte opposta alla Luna per tutta la notte.
	"uscita": [Vector3(11.00, 0.0, 17.00), Vector3(11.50, 1.80, 9.50)],
	# Appena fuori dalla porta, lo sguardo verso la macchina: il prato che si attraversa.
	"nord": [Vector3(10.50, 0.0, 11.00), Vector3(20.00, 0.80, 24.00)],
}

## Le lampade che nella fotografia erano spente: la sala e il corridoio. La cucina
## resta accesa, perché nella fotografia lo era — ed è metà della domanda.
const SPENTE := ["divulg1", "divulg2", "divulg3", "corridoio"]

var _scena: Node
var _cam: Camera3D
var _dove: Vector3
var _mira: Vector3
var _luci: Array[Light3D] = []
var _nomi: PackedStringArray = PackedStringArray()
var _rif: Image
var _controllo: Image
var _senza: Array[Image] = []
var _i := -1
var _montato := false
var _aperto := false
var _attesa := 0
var _t := 0.0
var _finito := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_monta.call_deferred()


func _monta() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	_scena = scena


func _process(d: float) -> void:
	if _scena == null or _finito:
		return
	_t += d
	if _t < 1.5:
		return
	var p := Player.find_in(get_tree())
	if p == null:
		return
	if not _montato:
		_montato = true
		var quale := OS.get_environment("VISTA")
		if not VISTE.has(quale):
			quale = "libreria"
		_dove = VISTE[quale][0]
		_mira = VISTE[quale][1]
		# LA SCENA DELLA FOTOGRAFIA, non quella di default. La domanda è su una sala
		# SPENTA: con le sue tre plafoniere accese non c'è nessuna macchia da
		# spiegare, e la sonda misurerebbe una situazione che non è quella vista.
		var spente := SPENTE
		if OS.get_environment("SPENTE") != "":
			spente = OS.get_environment("SPENTE").split(",")
		for n in spente:
			var l := get_tree().root.find_child("Luce_%s" % n, true, false)
			if l != null:
				l.get_node("Accesa").visible = false
		# ACCENDI=cupola1 fa il contrario, e serve a un controllo che altrimenti non
		# si potrebbe fare: le lampade della cupola nascono spente, quindi «con la
		# luce accesa l'occhio non si fa il buio» non si può verificare senza
		# accenderne una. È l'iniezione del difetto che il controllo esiste per
		# vedere: se l'adattamento resta a 1 con la rossa accesa, il patto è rotto.
		if OS.get_environment("ACCENDI") != "":
			for n in OS.get_environment("ACCENDI").split(","):
				var l := get_tree().root.find_child("Luce_%s" % n, true, false)
				if l != null:
					l.get_node("Accesa").visible = true
		# APERTURA=1 apre la cupola prima di guardare. Si annuncia il FATTO sul bus,
		# come farebbe la fase: così i battenti si muovono e la luce del cielo si
		# accende per la stessa strada che percorrono in gioco, non per una
		# scorciatoia che proverebbe soltanto che la scorciatoia funziona.
		#
		# E POI SI ASPETTA, perché i battenti INSEGUONO: `DomeShutter.FOLLOW_SPEED`
		# vale 0,30 di corsa al secondo, quindi da chiusa a spalancata ci mettono tre
		# secondi e un terzo. Fotografare subito vorrebbe dire fotografare una cupola
		# ancora chiusa e chiamarla aperta.
		if OS.get_environment("APERTURA") != "" and not _aperto:
			_aperto = true
			Events.dome_aperture_changed.emit(float(OS.get_environment("APERTURA")))
			print("[trafila] cupola annunciata aperta a %s, aspetto che i battenti arrivino"
				% OS.get_environment("APERTURA"))
		# LUNA=0.07 mette la notte di novilunio senza aspettare il calendario: la lampada
		# della Luna si ferma allo zenit con quell'energia. 0,07 è il fondo senza Luna,
		# 0,44 la piena più alta (`LuceDiLuna`).
		if OS.get_environment("LUNA") != "":
			var luna := get_tree().root.find_child("Luna", true, false) as DirectionalLight3D
			luna.set_process(false)
			luna.light_energy = float(OS.get_environment("LUNA"))
			luna.global_basis = Basis.looking_at(Vector3.DOWN, Vector3.FORWARD)
		print("[trafila] vista '%s' da %v verso %v, spente %s"
			% [quale, _dove, _mira, ", ".join(spente)])
		return

	# La posa si riscrive a ogni fotogramma: fermi davvero, o la differenza fra due
	# scatti sarebbe il giocatore che si assesta invece della lampada che ho spento.
	#
	# E SI RISCRIVE GIÀ DURANTE L'ATTESA, non solo al momento dello scatto: quello
	# che matura mentre si aspetta — i battenti che arrivano, l'occhio che si fa il
	# buio — dipende da DOVE STA il giocatore. Con il corpo fermo allo spawn,
	# l'adattamento non partirebbe mai e la sonda misurerebbe la sua stessa pigrizia.
	p.global_position = _dove
	_cam = p.camera()
	if _cam == null:
		return
	_cam.global_position = _dove + Vector3(0.0, 1.70, 0.0)
	_cam.look_at(_mira, Vector3.UP)

	# L'ATTESA A GIOCO ACCESO, prima di fermare tutto. Serve a due cose che hanno
	# tempi diversi: i battenti, che inseguono a 0,30 di corsa al secondo (tre secondi
	# e un terzo da chiusa a spalancata), e l'occhio che si fa il buio, che di secondi
	# ne vuole nove. Con ATTESA si allunga; il valore di partenza copre entrambe.
	if _luci.is_empty():
		var quanto := 16.0 if _aperto else 3.0
		if OS.get_environment("ATTESA") != "":
			quanto = float(OS.get_environment("ATTESA"))
		if _t < quanto:
			return
		_raccogli(get_tree().root)
		get_tree().paused = true
		_attesa = RESPIRO
		var occhio := get_tree().root.find_child("OcchioAlBuio", true, false)
		print("[trafila] %d sorgenti accese, occhio al buio %.2f, fuori %.2f, dopo %.1f s"
			% [_luci.size(), occhio.adaptation() if occhio != null else -1.0,
				occhio.outdoors() if occhio != null else -1.0, _t])
		var we := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
		var lu := get_tree().root.find_child("Luna", true, false) as DirectionalLight3D
		print("[trafila] luna %.3f, ambiente %.3f, esposizione %.2f, notte %s"
			% [lu.light_energy, we.environment.ambient_light_energy, we.environment.tonemap_exposure,
				"%d %.0f min" % [Game.run.night_index, Game.run.elapsed_min] if Game.run != null else "nessuna"])
		return

	if _attesa > 0:
		_attesa -= 1
		return

	if _rif == null:
		# A PIENA RISOLUZIONE, una volta sola. Il confronto fra scatti si fa a un
		# quarto per non costare più del gioco, ma un quarto NASCONDE le stelle —
		# sono punti larghi due pixel, e il ridimensionamento bilineare li spegne.
		# Per giudicare col mio occhio serve l'immagine vera; per misurare no.
		get_viewport().get_texture().get_image().save_png("user://trafila_00_pieno.png")
		_rif = _scatto()
		_rif.save_png("user://trafila_00_riferimento.png")
		_attesa = RESPIRO
		return

	# IL CONTROLLO DI SÉ, e serve: due scatti senza toccare NIENTE devono venire
	# uguali. La prima versione di questa sonda dava a ventitré lampade su ventitré
	# lo stesso identico scarto — segno che l'immagine di riferimento era diversa da
	# tutte per conto suo, e che stavo per attribuire alle lampade il ritardo della
	# mia cattura (D-179: un numero che non cambia quando cambi la causa non sta
	# misurando quella causa).
	if _controllo == null:
		_controllo = _scatto()
		var rumore := _scarto(_rif, _controllo, 0.0, 1.0)
		print("[trafila] rumore di fondo fra due scatti identici: %.3f livelli" % rumore)
		if rumore > 0.5:
			print("[trafila] SONDA INAFFIDABILE: il fondo è più grosso di quello che cerca")
		_prossima()
		return

	_senza.append(_scatto())
	if _i >= 0:
		_luci[_i].visible = true
	_prossima()


## Accende tutto quello che ha spento e passa alla lampada dopo.
func _prossima() -> void:
	_i += 1
	if _i >= _luci.size():
		_referto()
		return
	_luci[_i].visible = false
	_attesa = RESPIRO


func _scatto() -> Image:
	var img := get_viewport().get_texture().get_image()
	img.resize(int(img.get_width() / 4.0), int(img.get_height() / 4.0),
		Image.INTERPOLATE_BILINEAR)
	return img


func _raccogli(n: Node) -> void:
	if n is Light3D:
		var l: Light3D = n
		# Una lampada già spenta non può fare la macchia: si salta, così il referto
		# elenca solo quello che sta davvero illuminando.
		if l.is_visible_in_tree():
			_luci.append(l)
			_nomi.append(String(n.get_path()).replace("/root/Main/", ""))
	for f in n.get_children():
		_raccogli(f)


## Quanto due immagini differiscono, in livelli su 255, su una fascia di righe.
func _scarto(a: Image, b: Image, y0: float, y1: float) -> float:
	var h := a.get_height()
	var da := int(y0 * h)
	var a_ := int(y1 * h)
	var somma := 0.0
	for y in range(da, a_):
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			somma += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
	return somma / float(a.get_width() * maxi(a_ - da, 1) * 3) * 255.0


func _referto() -> void:
	_finito = true
	var righe: Array = []
	for i in _luci.size():
		righe.append([_scarto(_rif, _senza[i], 0.0, 1.0),
					  _scarto(_rif, _senza[i], 0.62, 1.0), _nomi[i], i])
	# Si ordina sul PAVIMENTO, che è la macchia di cui si parla.
	righe.sort_custom(func(a, b): return a[1] > b[1])
	print("[trafila] chi fa la luce, in livelli su 255 (tutta l'immagine / il pavimento):")
	for r in righe:
		if r[0] < 0.05 and r[1] < 0.05:
			continue
		print("  %6.2f  %6.2f   %s" % [r[0], r[1], r[2]])
	# Le tre che pesano di più si salvano: un numero dice quanto, una foto dice dove.
	for k in mini(3, righe.size()):
		var i: int = righe[k][3]
		_senza[i].save_png("user://trafila_%02d_senza_%s.png"
			% [k + 1, _nomi[i].get_file()])
		print("[trafila] salvato senza %s" % _nomi[i])
	get_tree().paused = false
	get_tree().quit()
