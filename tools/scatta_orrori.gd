## GLI ORRORI COSMICI, fotografati da dove li si vedrebbe.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_orrori.tscn
##
## Serve una FINESTRA VERA, come `tools/scatta_occhio.gd`, con le stesse manopole: `LUNA=`
## alza l'energia della Luna (di base 0,70; `LUNA=vera` la lascia com'è stanotte) e
## `ATTESA=` sono i secondi che si aspettano prima di cominciare, perché l'occhio del
## giocatore si faccia al buio (di base 62). `SOLO=F3` fotografa un orrore solo.
##
## `tools/prova_orrori.gd` misura; questo guarda. Gli scatti finiscono in
## `_confronto/30_orrori_*.png`, e ogni orrore è fotografato come lo vedrebbe chi l'ha
## chiamato: dalla porta, guardando dove la cosa succede. Si tengono i tasti veri
## (`debug/orrori.gd`), così si fotografa quello che fa il tasto e non una scorciatoia.
extends Node

const CARTELLA := "res://_confronto/"
const DA := Vector3(10.6, 0.0, 10.6)

var _g: Player
var _orrori: Node
var _scena: Node
var _solo := ""


func _ready() -> void:
	_scatta.call_deferred()


func _aspetta(secondi: float) -> void:
	var fine := Time.get_ticks_msec() + int(secondi * 1000.0 / maxf(Engine.time_scale, 0.001))
	while Time.get_ticks_msec() < fine:
		await get_tree().process_frame


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var dove := CARTELLA + "30_orrori_%s.png" % nome
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(dove))
	print("[orrori] %s" % dove)


## I piedi lì, e gli occhi verso `punto`.
func _guarda(piedi: Vector3, punto: Vector3, campo := 75.0) -> void:
	_g.global_position = piedi
	var cam := _g.camera()
	cam.current = true
	cam.fov = campo
	var d := punto - cam.global_position
	_g.rotation = Vector3(0.0, atan2(-d.x, -d.z), 0.0)
	cam.rotation.x = atan2(d.y, Vector2(d.x, d.z).length())


## Dalla porta, verso un azimut e un'altezza.
func _dalla_porta(azimut: float, altezza: float, campo := 75.0) -> void:
	_g.global_position = DA
	var occhio := DA + Vector3.UP * 1.65
	_guarda(DA, occhio + Orrore.verso(azimut, altezza) * 100.0, campo)


func _vuole(tasto: String) -> bool:
	return _solo == "" or _solo == tasto


func _scatta() -> void:
	_solo = OS.get_environment("SOLO")
	_scena = load("res://main.tscn").instantiate()
	get_tree().root.add_child(_scena)
	get_tree().current_scene = _scena
	for _i in 30:
		await get_tree().physics_frame
	_g = Player.find_in(get_tree())
	_g.set_process(false)
	_g.set_physics_process(false)
	_g.set_process_unhandled_input(false)
	_orrori = _scena.get_node("Orrori")
	var luna := LuceDiLuna.find_in(get_tree())
	if luna != null:
		var forzatura := OS.get_environment("LUNA")
		if forzatura != "vera":
			luna.set_process(false)
			luna.light_energy = float(forzatura) if forzatura != "" else 0.70
	_dalla_porta(0.0, 30.0)
	var attesa := OS.get_environment("ATTESA")
	await _aspetta(float(attesa) if attesa != "" else 62.0)

	if _vuole("F1"):
		await _nubi()
	if _vuole("F2"):
		await _inchiostro()
	if _vuole("F3"):
		await _ventose()
	if _vuole("F4"):
		await _braccia()
	if _vuole("F8"):
		await _colore()
	if _vuole("F6"):
		await _posa()
	if _vuole("F5"):
		await _oculare()
	if _vuole("F7"):
		await _montatura()
	if _vuole("F9"):
		await _pianeta()
	get_tree().quit()


func _nubi() -> void:
	_dalla_porta(0.0, 35.0)
	var o: Orrore = _orrori.premi(KEY_F1)
	await _aspetta(9.0)
	await _foto("nubi_1")
	await _aspetta(3.5)
	await _foto("nubi_2")
	_dalla_porta(0.0, 80.0)
	await _aspetta(2.0)
	await _foto("nubi_allo_zenit")
	o.queue_free()


func _inchiostro() -> void:
	_dalla_porta(0.0, 40.0)
	var o: Orrore = _orrori.premi(KEY_F2)
	await _aspetta(4.0)
	await _foto("inchiostro_grumo")
	await _aspetta(26.0)
	await _foto("inchiostro_nube")
	o.queue_free()


func _ventose() -> void:
	_dalla_porta(0.0, 50.0)
	var o: OrroreVentose = _orrori.premi(KEY_F3)
	await _aspetta(30.0)
	await _foto("ventose_passa")
	# da vicino, mezzo braccio dietro la punta, dove le ventose sono grandi
	var mat := (o.get_node("Ventose") as MeshInstance3D).material_override as ShaderMaterial
	var inizio: Vector3 = mat.get_shader_parameter("inizio")
	var asse: Vector3 = mat.get_shader_parameter("asse")
	var a := o.testa() - 0.9
	var p := inizio * cos(a) + asse.cross(inizio) * sin(a)
	_guarda(DA, DA + Vector3.UP * 1.65 + p * 100.0, 32.0)
	await _aspetta(1.0)
	await _foto("ventose_da_vicino")
	_dalla_porta(0.0, 50.0)
	await _aspetta(20.0)
	await _foto("ventose_oltre")
	o.queue_free()


func _braccia() -> void:
	_dalla_porta(0.0, 12.0)
	var o: OrroreBraccia = _orrori.premi(KEY_F4)
	# LE BRACCIA NON ESCONO PER FORZA DOVE SI GUARDA: vanno dove l'orizzonte è libero
	# (`OrroreBraccia._dove_si_vede`), e dalla porta verso nord c'è il bosco. Si guarda loro.
	var centro := o.bracci()[2].global_position
	var az := Orrore.azimut_di(Vector3(centro.x - DA.x, 0.0, centro.z - DA.z))
	_dalla_porta(az, 12.0)
	await _aspetta(12.0)
	await _foto("braccia_escono")
	await _aspetta(14.0)
	await _foto("braccia_salgono")
	await _aspetta(14.0)
	await _foto("braccia")
	# DA VICINO, UNA MANO PER VOLTA: ognuna fa il suo gesto
	for k in o.bracci().size():
		var b := o.bracci()[k]
		var p := b.punte_nel_mondo()
		_guarda(DA, (p[2] + b.polso_nel_mondo()) * 0.5, 14.0)
		await _aspetta(0.6)
		await _foto("braccia_mano_%d_%s" % [k + 1, String(BraccioUmano.Gesto.keys()[b.gesto()]).to_lower()])
	await _aspetta(14.0)
	_dalla_porta(az, 12.0)
	await _aspetta(0.6)
	await _foto("braccia_dopo")
	_dalla_porta(az - 35.0, 14.0)
	await _aspetta(4.0)
	await _foto("braccia_di_lato")
	o.queue_free()


func _colore() -> void:
	var dove := Vector3(OrroreColore.DOVE.x, 0.0, OrroreColore.DOVE.y)
	var verso_caduta := Vector3(dove.x - DA.x, 0.0, dove.z - DA.z).normalized()
	var az := Orrore.azimut_di(verso_caduta)
	# si guarda verso dove arriva: alto, davanti
	_dalla_porta(az + 12.0, 22.0)
	var o: OrroreColore = _orrori.premi(KEY_F8)
	await _aspetta(2.0)
	await _foto("colore_arriva")
	await _aspetta(2.5)
	await _foto("colore_si_avvicina")
	# l'ultimo tratto sopra il prato: si guarda la buca, largo
	_guarda(DA, dove + Vector3.UP * 6.0, 80.0)
	while o.fase() == "CADE" and o.tempo() < OrroreColore.ARRIVO - 0.45:
		await get_tree().process_frame
	await _foto("colore_scende")
	while o.fase() == "CADE":
		await get_tree().process_frame
	await _aspetta(0.08)
	await _foto("colore_impatto")
	await _aspetta(1.2)
	await _foto("colore_polverone")
	await _aspetta(4.0)
	await _foto("colore_fuma")
	var vicino := dove - verso_caduta * 4.5 + Vector3(1.2, 0.0, 0.0)
	_guarda(vicino, dove + Vector3.UP * 0.2, 55.0)
	await _aspetta(1.0)
	await _foto("colore_pietra")
	await _aspetta(10.0)
	await _foto("colore_pietra_fredda")
	_dalla_porta(az + 12.0, 22.0)
	await _aspetta(1.0)
	await _foto("colore_scia")
	await _aspetta(28.0)
	_guarda(DA, dove + Vector3.UP * 0.3)
	await _aspetta(0.5)
	await _foto("colore_erba")
	_guarda(dove - verso_caduta * 6.0, dove + Vector3.UP * 0.2)
	await _aspetta(3.0)
	await _foto("colore_erba_vicino")
	# dal prato verso la porta: la luce del colore sull'osservatorio
	_guarda(dove + verso_caduta * 3.0, DA + Vector3.UP * 3.0, 75.0)
	await _aspetta(1.5)
	await _foto("colore_osservatorio")
	_guarda(DA, dove + Vector3.UP * 0.3)
	await _aspetta(1.0)
	_orrori.premi(KEY_F8)
	await _aspetta(OrroreColore.SI_TENDE + OrroreColore.SI_RITIRA * 0.6)
	await _foto("colore_si_raccoglie")
	while o.fase() != "SALE":
		await get_tree().process_frame
	var t0 := o.tempo()
	_dalla_porta(az, 32.0)
	while o.tempo() - t0 < OrroreColore.COLONNA_SALE + 0.5:
		await get_tree().process_frame
	await _foto("colore_colonna")
	# la base si stacca da terra: a tredici metri, dopo mezzo secondo è già a metà cielo
	_guarda(DA, dove + Vector3.UP * 12.0)
	while o.tempo() - t0 < OrroreColore.COLONNA_SALE + OrroreColore.COLONNA_VERSA + 0.3:
		await get_tree().process_frame
	_dove_sta(o, "Bagliore")
	await _foto("colore_si_stacca")
	_guarda(DA, dove + Vector3.UP * 0.3)
	await _aspetta(1.5)
	await _foto("colore_fiocchi")
	await _aspetta(4.0)
	await _foto("colore_cenere")
	_guarda(dove - verso_caduta * 6.0, dove + Vector3.UP * 0.2)
	await _aspetta(1.0)
	await _foto("colore_cenere_vicino")
	o.queue_free()
	await _aspetta(0.5)


## Dove sta una parte dell'orrore rispetto a quello che la camera inquadra: una luce di
## pochi pixel che non si vede può essere fuori campo, dietro, o spenta.
func _dove_sta(o: Orrore, nome: String) -> void:
	var n := o.get_node_or_null(nome) as Node3D
	var cam := _g.camera()
	if n == null:
		print("[orrori] %s: non c'è" % nome)
		return
	var d := n.global_position - cam.global_position
	print("[orrori] %s: fase %s, visibile %s, a %.0f m, a %.1f° dal centro dell'inquadratura" % [
		nome, o.call("fase"), n.visible, d.length(), rad_to_deg(d.angle_to(-cam.global_basis.z))])


func _posa() -> void:
	var stampante := Stampante.find_in(get_tree())
	stampante.secondi = 4.0
	var piedi := Vector3(6.46, 0.0, 1.10)
	var fessura: Transform3D = stampante.get("_uscita")
	_guarda(piedi, fessura.origin + Vector3.UP * 0.10)
	await _aspetta(0.5)
	_orrori.premi(KEY_F6)
	var s: Stampa = null
	var pazienza := 0
	while pazienza < 3000:
		for n in get_tree().get_nodes_in_group(Stampa.GRUPPO):
			if (n as Stampa).occhio:
				s = n as Stampa
		if s != null and s.stato == Stampa.Stato.ATTACCATA:
			break
		pazienza += 1
		await get_tree().physics_frame
	if s == null:
		print("[orrori] posa: nessuna stampa con l'occhio")
		return
	# LE PAGINE, ingrandite a quattro volte senza sfumare: una galassia, una nebulosa, un ammasso
	for pagina_di in [[&"m51", 2], [&"ic1396", 2], [&"m13", 3], [&"m42", 1]]:
		var pagina := (load(Stampa.PAGINA % pagina_di) as Texture2D).get_image()
		var composta := OcchioNellaPosa.componi(pagina, 7)
		composta.resize(composta.get_width() * 4, composta.get_height() * 4, Image.INTERPOLATE_NEAREST)
		composta.save_png(ProjectSettings.globalize_path(
			CARTELLA + "30_orrori_posa_pagina_%s.png" % pagina_di[0]))
	await _aspetta(0.5)
	await _foto("posa_stampa")
	_guarda(piedi, fessura.origin + fessura.basis.y * 0.14, 30.0)
	await _aspetta(0.5)
	await _foto("posa_stampa_da_vicino")
	_orrori.premi(KEY_F6)


## Dentro la cupola, accanto al telescopio: la montatura si gira e ti segue.
func _montatura() -> void:
	var m := TelescopeMount.find_in(get_tree())
	var tubo := m.apertura()
	var da := tubo + Vector3(1.6, 0.0, -1.2)
	da.y = 0.0
	_guarda(da, tubo)
	await _aspetta(1.0)
	await _foto("montatura_prima")
	var o: Orrore = _orrori.premi(KEY_F7)
	await _aspetta(3.0)
	await _foto("montatura_si_gira")
	var pazienza := 0
	while m.in_moto() and pazienza < 3000:
		pazienza += 1
		await get_tree().process_frame
	_guarda(da, m.apertura())
	await _aspetta(0.8)
	await _foto("montatura_ti_guarda")
	var altrove := tubo + Vector3(-1.5, 0.0, -1.3)
	altrove.y = 0.0
	_guarda(altrove, m.apertura())
	await _aspetta(OrroreMontatura.REAZIONE + 2.0)
	await _foto("montatura_ti_segue")
	pazienza = 0
	while m.in_moto() and pazienza < 3000:
		pazienza += 1
		await get_tree().process_frame
	_guarda(altrove, m.apertura())
	await _aspetta(0.8)
	await _foto("montatura_ti_ha_seguito")
	_orrori.premi(KEY_F7)
	pazienza = 0
	while is_instance_valid(o) and pazienza < 3000:
		pazienza += 1
		await get_tree().process_frame


## LA VISIONE DEL PIANETA: non serve guardare da nessuna parte, prende lo schermo. Gli
## scatti cadono uno per pezzo del racconto, coi tempi di `OrrorePianeta`.
func _pianeta() -> void:
	_orrori.premi(KEY_F9)
	var orologio := 0.0
	# i tempi sono ASSOLUTI da quando si preme, così si cade dentro il pezzo che si vuole
	# fotografare e non un secondo prima
	for quando: Array in [
		[OrrorePianeta.T_NERO + 0.4, "pianeta_nero"],
		[OrrorePianeta.T_GUARDA + 2.0, "pianeta_sei_li"],
		[OrrorePianeta.T_MANGIA + OrrorePianeta.MANGIA * 0.3, "pianeta_arrivano"],
		[OrrorePianeta.T_MANGIA + OrrorePianeta.MANGIA * 0.6, "pianeta_lo_mangia"],
		[OrrorePianeta.T_VOLTA - 0.3, "pianeta_mangiato"],
		[OrrorePianeta.T_TROVA + 1.2, "pianeta_ti_guarda"],
		[OrrorePianeta.T_VIA + OrrorePianeta.VIA * 0.55, "pianeta_via"],
	]:

		await _aspetta(maxf(float(quando[0]) - orologio, 0.05))
		orologio = float(quando[0])
		await _foto(String(quando[1]))
	var pazienza := 0
	while _orrori.aperto(KEY_F9) != null and pazienza < 3000:
		pazienza += 1
		await get_tree().process_frame


## Nell'oculare, a cupola chiusa: niente cielo, niente Luna — l'occhio c'è lo stesso.
func _oculare() -> void:
	var oc := Oculare.find_in(get_tree())
	_orrori.premi(KEY_F5)
	oc.call("_su_interazione", _g)
	await _aspetta(0.3)
	await _foto("oculare_altrove")
	await _aspetta(1.4)
	await _foto("oculare_ti_trova")
	await _aspetta(2.5)
	await _foto("oculare_stretta")
	oc.call("_su_interazione", _g)
	await _aspetta(0.3)
	oc.call("_su_interazione", _g)
	await _aspetta(1.5)
	await _foto("oculare_di_nuovo")
	oc.call("_su_interazione", _g)
	_orrori.premi(KEY_F5)
