## Uno scatto della cupola, per MISURARE gli anelli invece di indovinarli.
##
## Ho cambiato quattro cose diverse dando la colpa a quattro cause diverse -
## quantizzazione a otto bit, sfaccettatura della calotta, risoluzione della mappa
## d'ombra, bias - e ogni volta ho dedotto la causa da una fotografia guardata a
## occhio. Non si distingue a occhio una fascia di quantizzazione da un gradino
## d'ombra: si distinguono LEGGENDO I PIXEL.
##
## Salva un fotogramma da un punto fisso della sala telescopio. L'analisi la fa
## tools/leggi_anelli.py, che percorre una riga e stampa i salti.
##
##     Godot --path . --script tools/scatto_cupola.gd
extends SceneTree

const FUORI := "user://cupola.png"
const ASPETTA := 20          # qualche fotogramma perche' le ombre si assestino

var _conto := 0


func _init() -> void:
	var scena: Node3D = load("res://world/blockout.tscn").instantiate()
	get_root().add_child(scena)
	# il giocatore muoverebbe la camera: qui serve un punto d'osservazione fermo
	var p := scena.get_node_or_null("Player")
	if p != null:
		p.queue_free()
	var cam := Camera3D.new()
	scena.add_child(cam)
	# in mezzo alla sala telescopio, all'altezza dell'occhio, verso il muro ovest
	# illuminato dall'applique rossa: e' dove gli anelli si vedono meglio
	# il punto di ripresa si puo' spostare senza toccare il file: serve guardare la
	# stessa stanza da posti diversi - da terra, dalla passerella, all'oculare - e un
	# solo punto fisso costringeva a modificare lo strumento di misura ogni volta.
	cam.position = _numeri("SCATTO_DA", Vector3(2.60, 1.65, 5.90))
	cam.rotation_degrees = _numeri("SCATTO_VERSO", Vector3(-6, 0, 0))
	cam.fov = 55.0
	# SCATTO_FARO accende una lampada sulla camera. Guardare un pezzo di arredo in
	# una stanza a luce rossa non dice niente: un'anta verniciata e una di legno
	# sono lo stesso rettangolo nero. Non e' come si vedra' in partita - e' come si
	# vede una cosa quando la si deve GIUDICARE.
	if not OS.get_environment("SCATTO_FARO").is_empty():
		var faro := OmniLight3D.new()
		faro.light_energy = maxf(0.1, float(OS.get_environment("SCATTO_FARO")))
		faro.omni_range = 8.0
		faro.omni_attenuation = 1.0
		faro.shadow_enabled = false
		cam.add_child(faro)
	cam.current = true



func _accendi_tutto(n: Node) -> void:
	if n.name == "Accesa" and n is Node3D:
		(n as Node3D).visible = true
	for f in n.get_children():
		_accendi_tutto(f)


func _apri(n: Node, quali: String) -> void:
	var d := n as Door
	if d != null and quali in String(d.name):
		d.set_open(true, true)
	for f in n.get_children():
		_apri(f, quali)


func _numeri(chiave: String, difetto: Vector3) -> Vector3:
	var s := OS.get_environment(chiave)
	if s.is_empty():
		return difetto
	var p := s.split(",")
	if p.size() != 3:
		return difetto
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func _process(_d: float) -> bool:
	_conto += 1
	# LE ROSSE SI ACCENDONO QUI, NON IN _init. Accese subito dopo l'istanza
	# venivano rispente: `LightSwitch._ready()` riapplica il suo stato alle
	# lampade, e dentro `_init` di una SceneTree quel ready arriva DOPO. Lo scatto
	# usciva identico a luci spente e per un po' ho creduto che le lampade non
	# facessero luce - misurava una stanza al buio credendo di misurarla accesa.
	if _conto == ASPETTA - 4:
		# SCATTO_LUCI=tutte accende ogni lampada della scena. Serve a guardare un
		# pezzo di arredo per quello che e': la sala del telescopio ha solo le
		# rosse accese, e sotto quelle un'anta verniciata e una di legno sono due
		# rettangoli neri uguali.
		if OS.get_environment("SCATTO_LUCI") == "tutte":
			_accendi_tutto(get_root())
		else:
			for n in ["Luce_cupola1", "Luce_cupola2", "Luce_cupola3"]:
				var a := get_root().get_node_or_null("Blockout/" + n + "/Accesa") as Node3D
				if a != null:
					a.visible = true
	# SCATTO_APRI=pensile apre ogni porta il cui nome contiene quel pezzo di testo.
	# Un'anta si giudica APERTA: chiusa, un pensile con l'anta incollata e un pensile
	# con l'anta che gira sono lo stesso rettangolo, e l'unica cosa che si vede e' se
	# la fuga cade dove deve. Aperta si vede se dentro c'e' qualcosa, se il legno
	# della cassa e quello dell'anta sono lo stesso legno, e se la venatura gira con
	# l'anta invece di restare incollata alla stanza.
	if _conto == ASPETTA - 3:
		var quali := OS.get_environment("SCATTO_APRI")
		if not quali.is_empty():
			_apri(get_root(), quali)
	if _conto < ASPETTA:
		return false
	for n in ["Luce_cupola1", "Luce_cupola2", "Luce_cupola3", "Luce_corridoio", "Luce_pc"]:
		var L := get_root().get_node_or_null("Blockout/" + n + "/Accesa/L") as OmniLight3D
		print("LAMPADA %s -> %s" % [n, "assente" if L == null else "in albero=%s energia=%.2f" % [L.is_visible_in_tree(), L.light_energy]])
	var img := get_root().get_texture().get_image()
	img.save_png(FUORI)
	print("scatto salvato in ", ProjectSettings.globalize_path(FUORI))
	quit()
	return true
