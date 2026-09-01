## LA CAMERA E' AVVITATA AL TELESCOPIO, O SOLO APPOGGIATA LI'?
##
## LA DOMANDA, E PERCHE' NON E' OVVIA. Una camera CCD montata al fuoco e' un pezzo
## dello strumento: quando il tubo insegue il cielo, lei ci va insieme. Metterla
## nel posto giusto e' facile e sbagliato - per un fotogramma le due cose sono
## identiche, e nessun controllo statico le distingue. La differenza si vede solo
## MUOVENDO IL TELESCOPIO, ed e' esattamente quello che questa sonda fa: manda il
## tubo dall'altra parte del cielo e guarda se la camera c'e' ancora.
##
## E SI CONTROLLA ANCHE IL RITORNO, che e' la meta' che si dimentica: smontata
## deve tornare un corpo che cade, e riportata al fuoco deve riavvitarsi.
##
## IL DIFETTO SI RIMETTE: `CAMERA_APPOGGIATA=1` accende `appoggiata_e_basta`, che
## posa la camera sul fuoco senza appenderla. Senza quel confronto un referto che
## dice «la camera sta al fuoco» non direbbe se ci sta attaccata.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_ccd.tscn
##     CAMERA_APPOGGIATA=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_ccd.tscn
extends Node

var _guasti := 0
var _scena: Node
var _ccd: CcdCamera
var _fuoco: Node3D


func _ready() -> void:
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[ccd] GUASTO: " + msg)


func _tick() -> void:
	await get_tree().physics_frame


## Quanto la camera e' lontana da dove il focheggiatore la vuole. Non si guarda la
## posizione assoluta - il telescopio si muove, e un numero assoluto non direbbe
## niente - ma lo SCARTO dal fuoco, che deve restare quello che era.
func _scarto() -> float:
	return _ccd.global_position.distance_to(_fuoco.global_position)


func _prova() -> void:
	_scena = load("res://main.tscn").instantiate()
	get_tree().root.add_child(_scena)
	get_tree().current_scene = _scena
	for _i in 20:
		await _tick()

	_ccd = CcdCamera.find_in(get_tree())
	if _ccd == null:
		print("[ccd] la camera non si trova: la prova non vale")
		get_tree().quit(1)
		return
	if OS.get_environment("CAMERA_APPOGGIATA") == "1":
		# Si rimette il difetto e si rimonta da capo: la camera e' gia' nata
		# avvitata, e cambiare la bandiera dopo non la stacca.
		_ccd.appoggiata_e_basta = true
		_ccd.prendi(Player.find_in(get_tree()))
		_ccd.posa()
		await _tick()
	_fuoco = _ccd.get_node_or_null(_ccd.fuoco) as Node3D
	if _fuoco == null:
		_fuoco = _scena.find_child("Fuoco", true, false) as Node3D
	if _fuoco == null:
		print("[ccd] il fuoco del telescopio non si trova: la prova non vale")
		get_tree().quit(1)
		return

	# --- NASCE MONTATA. In un osservatorio la camera sta al suo posto: chi la
	# vuole in mano la va a smontare, e questo e' anche l'unico modo di scoprire
	# che si puo' fare.
	var partenza := _scarto()
	print("[ccd] all'avvio: montata=%s, a %.3f m dalla bocca del focheggiatore"
		% [_ccd.montata(), partenza])
	if not _ccd.montata():
		_guasto("la camera non nasce montata")
	if partenza > 0.20:
		_guasto("montata, la camera sta a %.3f m dal fuoco: non e' avvitata li'"
			% partenza)

	# --- IL CUORE: IL TELESCOPIO SI MUOVE E LEI CI VA INSIEME.
	var montatura := TelescopeMount.find_in(get_tree())
	if montatura == null:
		print("[ccd] la montatura non si trova: la prova non vale")
		get_tree().quit(1)
		return
	var dov_era := _ccd.global_position
	var fuoco_era := _fuoco.global_position
	montatura.punta(75.0, 55.0)
	for _i in 240:
		await _tick()
	var corsa_fuoco := fuoco_era.distance_to(_fuoco.global_position)
	var corsa := dov_era.distance_to(_ccd.global_position)
	var resta := _scarto()
	print("[ccd] dopo un GOTO: il focheggiatore si e' spostato di %.3f m, la "
		% corsa_fuoco + "camera di %.3f, e resta a %.3f dal fuoco"
		% [corsa, resta])
	# SONDA CIECA: si guarda quanto si e' mosso IL FOCHEGGIATORE, non la camera.
	# La prima stesura misurava la camera, ed era il controllo sbagliato nel modo
	# piu' insidioso: col difetto acceso la camera non si muove affatto, quindi la
	# guardia gridava «sonda cieca» proprio quando la sonda stava vedendo il
	# difetto. Chi non e' autorizzato a stare fermo e' il telescopio.
	if corsa_fuoco < 0.20:
		_guasto("SONDA CIECA: il focheggiatore si e' spostato di %.3f m, troppo "
			% corsa_fuoco + "poco per distinguere una camera avvitata da una appoggiata")
	if absf(resta - partenza) > 0.02:
		_guasto("inseguendo, la camera si allontana dal fuoco: %.3f m contro i "
			% resta + "%.3f di partenza - non e' avvitata, e' appoggiata" % partenza)

	# --- SI SMONTA, E TORNA UN OGGETTO. Presa in mano deve staccarsi da sola;
	# lasciata deve cadere, cioe' tornare un corpo del mondo.
	var giocatore := Player.find_in(get_tree())
	_ccd.prendi(giocatore)
	if _ccd.montata():
		_guasto("presa in mano, la camera risulta ancora montata")
	if _ccd.freeze:
		_guasto("smontata, la camera e' ancora congelata: non cadrebbe mai")
	_ccd.lascia()
	var alta := _ccd.global_position.y
	for _i in 180:
		await _tick()
	var scesa := alta - _ccd.global_position.y
	print("[ccd] smontata e lasciata: scende di %.3f m e si ferma" % scesa)
	if scesa < 0.10:
		_guasto("lasciata cadere da %.2f m la camera scende di %.3f m: resta "
			% [alta, scesa] + "appesa a mezz'aria")

	# --- E SI RIMONTA. Riportarla alla bocca deve bastare: e' il gesto vero, e il
	# prompt lo dice da solo quando ci si arriva.
	_ccd.prendi(giocatore)
	_ccd.global_position = _fuoco.global_position
	await _tick()
	var riga := _ccd.prompt_posa()
	print("[ccd] tenendola alla bocca il prompt dice: %s" % riga)
	if not riga.contains("Avvita"):
		_guasto("arrivati al focheggiatore il prompt non propone di avvitarla")
	_ccd.posa()
	await _tick()
	if not _ccd.montata():
		_guasto("riportata alla bocca, la camera non si rimonta")

	if _guasti == 0:
		print("[ccd] ok: la camera e' avvitata al fuoco e ci resta anche inseguendo")
	else:
		print("[ccd] GUASTO: %d controlli falliti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)
