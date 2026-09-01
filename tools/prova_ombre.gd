## PERCHÉ LE OMBRE SFARFALLANO ENTRANDO, E POI SI FERMANO.
##
## Il sintomo è arrivato così, senza altro: «quando entro nell'osservatorio le ombre
## sfarfallano e poi si stabilizzano, non riesco proprio a capire perché». È il tipo
## di difetto che a occhio non si diagnostica — «sfarfallio» è la firma di almeno
## quattro cause diverse, e guardandolo si sceglie sempre quella che si aveva già in
## mente — quindi qui non si guarda: si misura, e ogni misura chiude una porta.
##
## PRIMA PORTA, CHIUSA: succede stando fermi? NO. Piantato nello stesso punto per
## 556 fotogrammi — con la posa riscritta a ogni frame perché nemmeno l'assestamento
## della capsula potesse passare per sfarfallio — l'immagine non è cambiata di **un
## livello su 255**, e nessuna luce ha cambiato energia da sé. Cadono in un colpo
## solo le due cause che si sarebbero indagate per prime: non è una lampada che
## lampeggia per copione (in cucina ce n'è una, e con undici metri di portata arriva
## lontano) e non è il renderer che rimesta stando lì.
##
## SECONDA PORTA, CHIUSA: le ombre si assestano dopo essere arrivati? NO. Saltando
## di colpo dalla postazione alla cupola — il caso estremo dell'entrare — il primo
## fotogramma è ancora quello vecchio e **dal secondo in poi l'immagine è già quella
## a regime**, identica per due secondi e mezzo. Niente converge, niente si sistema
## col tempo.
##
## RESTA IL MOVIMENTO, e la domanda diventa: che cosa cambia **mentre** ci si
## muove, che non cambia né prima né dopo? Due sospetti, e questa sonda li separa
## girando la testa di 360 gradi DUE VOLTE.
##
##   1. IL TEMPO DI FOTOGRAMMA. In Godot la causa più comune di «sfarfalla e poi si
##      stabilizza» non è l'ombra: è la **compilazione delle pipeline**. Ogni
##      combinazione nuova di materiale e luce va compilata la prima volta che entra
##      in campo, e mentre compila il fotogramma dura decine di millisecondi. A
##      quel punto tutto scatta, e le ombre — che sono la cosa che si muove di più
##      guardandosi intorno — scattano più di tutto. Poi «si stabilizza» perché la
##      compilazione è finita e non si ripete mai più.
##      SI VEDE COSÌ: il primo giro è lento a scatti, il secondo è liscio.
##
##   2. L'ATLANTE DELLE OMBRE — SOSPETTO SCARTATO, e come si è scartato conta più
##      del sospetto. L'idea era: allo stesso angolo, due giri danno immagini
##      diverse, quindi quello che si vede dipende da come ci si è arrivati. La
##      sonda lo diceva forte — 72 pose su 89 diverse — e la foto sembrava
##      confermarlo, con le ombre sfocate al primo giro e nette al secondo.
##
##      **Era un difetto della sonda.** Tre indizi, in ordine di forza: cambiando i
##      quadranti dell'atlante in tre modi diversi lo scarto peggiore restava
##      12,744 livelli IDENTICO a tre decimali; restava identico anche mettendo il
##      gioco IN PAUSA; e due pose CONSECUTIVE dello stesso giro differiscono di
##      11,3 livelli, cioè lo stesso ordine di grandezza. Il conto torna: l'immagine
##      che si legge in `_process` è quella del fotogramma precedente, ma il ritardo
##      NON è sempre di uno — e un confronto disallineato di un fotogramma mette a
##      paragone due angoli diversi. La sonda misurava la propria rotazione.
##
##      Per questo il referto adesso stampa due numeri di controllo: la stessa posa
##      contro se stessa (dev'essere zero) e due pose vicine (dice quanto vale UN
##      passo). Finché il secondo è dell'ordine dello scarto fra giri, il confronto
##      fra giri NON DICE NIENTE, e va letto come rumore.
##
## UN NUMERO CHE NON CAMBIA QUANDO SI CAMBIA LA CAUSA NON STA MISURANDO QUELLA
## CAUSA. È la riga più utile di tutta questa indagine.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/prova_ombre.tscn
extends Node

## Quanto si aspetta prima di cominciare: la notte parte e le luci si accendono.
const RESPIRO := 1.0

## Dove ci si mette a girare: in cupola, davanti al comando.
const DOVE := Vector3(1.04, 0.0, 4.80)

## CAMMINA=1 attraversa l'edificio invece di girare sul posto, dalla postazione
## alla cupola. Serve a una domanda sola, che girando la testa non si puo' fare:
## quanto costa la PRIMA volta che un materiale entra in campo? Ogni combinazione
## di mesh, materiale e luce va compilata in una pipeline la prima volta che si
## disegna, e mentre compila il fotogramma dura decine di millisecondi. E' la causa
## piu' comune, in Godot, di «sfarfalla e poi si stabilizza» — e si vede solo
## confrontando il primo passaggio con il secondo, perche' la compilazione non si
## ripete mai.
const DA := Vector3(10.85, 0.0, 8.50)
const A := Vector3(1.04, 0.0, 4.80)

## Quante pose fa un giro completo. Novanta: quattro gradi per fotogramma, che è
## una girata di testa svelta ma non isterica.
const POSE := 90

## Sotto questa differenza media per canale due fotogrammi si considerano uguali.
## 1/255 è un livello: sotto, è il dithering del debanding, non sfarfallio.
const UGUALI := 1.0 / 255.0

## Un fotogramma più lungo di così, a 60 Hz, è uno scatto che si vede.
const SCATTO_MS := 20.0

var _scena: Node
var _t := 0.0
var _giro := 0
var _posa := 0
var _finito := false
var _immagini: Array[Array] = [[], [], []]
var _tempi: Array[PackedFloat32Array] = [PackedFloat32Array(),
		PackedFloat32Array(), PackedFloat32Array()]
var _luci: Array[Light3D] = []
var _energie: PackedFloat32Array = PackedFloat32Array()
var _ballerine: Dictionary = {}
var _pose_viste: Dictionary = {}
var _mossi: Dictionary = {}
var _pose_vere: Array[Array] = [[], [], []]
var _cammina := false


func _ready() -> void:
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
	var p := Player.find_in(get_tree())
	if p == null or _t < RESPIRO:
		return
	if _luci.is_empty():
		# CON PAUSA=1 il gioco si ferma: la notte non scorre, niente si aggiorna, e
		# quello che resta a cambiare puo' essere solo il renderer. E' il taglio piu'
		# netto fra «e' il gioco» e «e' il motore».
		_cammina = OS.get_environment("CAMMINA") == "1"
		if _cammina:
			print("[ombre] CAMMINA: dalla postazione alla cupola, %d passi" % POSE)
		if OS.get_environment("PAUSA") == "1":
			process_mode = Node.PROCESS_MODE_ALWAYS
			get_tree().paused = true
			print("[ombre] gioco IN PAUSA: si misura solo il renderer")
		_raccogli_luci(get_tree().root)
		print("[ombre] %d luci nella scena, %d con ombra"
			% [_luci.size(), _con_ombra()])
	_guarda_le_luci()

	var cam := p.camera()
	if cam == null:
		return
	if _cammina:
		var q := float(_posa) / float(POSE - 1)
		p.global_position = DA.lerp(A, q)
		cam.global_position = p.global_position + Vector3(0.0, 1.70, 0.0)
		cam.look_at(Vector3(A.x, 1.40, A.z), Vector3.UP)
	else:
		p.global_position = DOVE
		# La testa gira di quattro gradi per fotogramma, sempre sulle stesse pose: i
		# due giri devono essere confrontabili posa per posa.
		var ang := TAU * float(_posa) / float(POSE)
		cam.global_position = DOVE + Vector3(0.0, 1.70, 0.0)
		cam.look_at(cam.global_position
			+ Vector3(cos(ang), -0.12, sin(ang)), Vector3.UP)

	# IL TEMPO DEL FOTOGRAMMA PRECEDENTE, non di questo: `delta` è quanto è durato
	# quello prima, ed è esattamente il numero che serve — lo scatto lo fa il
	# fotogramma in cui il motore ha compilato, e lo si misura dopo.
	_tempi[_giro].append(d * 1000.0)
	_immagini[_giro].append(_scatto())
	# LA POSA VERA, non quella chiesta. Il giocatore ha un `_process` suo e la
	# telecamera e' sua: se la riscrive dopo di me, quello che finisce nel
	# fotogramma non e' l'angolo che ho ordinato — e allora questa sonda starebbe
	# misurando se stessa invece del renderer.
	_pose_vere[_giro].append(cam.global_transform)
	if _posa == 1:
		# CHI SI MUOVE, alla stessa posa di ogni giro. Le energie non cambiano, ma
		# una luce che RUOTA fa esattamente lo stesso effetto — e la luna, in una
		# notte che scorre, ruota. Si guardano le trasformate di TUTTO, non solo
		# delle luci: il colpevole potrebbe essere un oggetto che proietta.
		_istantanea(get_tree().root)

	_posa += 1
	if _posa >= POSE:
		_posa = 0
		_giro += 1
		print("[ombre] giro %d finito" % _giro)
		if _giro >= 3:
			_referto()


## Le trasformate di ogni Node3D, per confrontarle fra un giro e l'altro.
func _istantanea(n: Node) -> void:
	if n is Node3D:
		var chi := String(n.get_path())
		var t: Transform3D = (n as Node3D).global_transform
		if _pose_viste.has(chi):
			var prima: Transform3D = _pose_viste[chi]
			if not prima.is_equal_approx(t):
				var quanto := (t.origin - prima.origin).length()
				var giro := (t.basis.z - prima.basis.z).length()
				if quanto > 0.0005 or giro > 0.0005:
					_mossi[chi] = "%.4f m, %.4f di rotazione" % [quanto, giro]
		_pose_viste[chi] = t
	for f in n.get_children():
		_istantanea(f)


func _scatto() -> Image:
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return null
	# Un ottavo per lato: lo sfarfallio di un'ombra è una macchia larga decine di
	# pixel, e a piena risoluzione questo confronto costerebbe più del gioco.
	img.resize(img.get_width() / 8, img.get_height() / 8, Image.INTERPOLATE_BILINEAR)
	return img


func _raccogli_luci(n: Node) -> void:
	if n is Light3D:
		_luci.append(n)
		_energie.append(-1.0)
	for f in n.get_children():
		_raccogli_luci(f)


func _con_ombra() -> int:
	var q := 0
	for l in _luci:
		if l.shadow_enabled:
			q += 1
	return q


## Chi cambia da sé: una luce che varia energia mentre nessuno la tocca sarebbe la
## spiegazione più semplice, e va esclusa esplicitamente invece che dimenticata.
func _guarda_le_luci() -> void:
	for i in _luci.size():
		var l := _luci[i]
		if not is_instance_valid(l):
			continue
		var e := l.light_energy if l.is_visible_in_tree() else 0.0
		if _energie[i] >= 0.0 and absf(e - _energie[i]) > 0.001:
			var chi := String(l.get_parent().name) + "/" + String(l.name)
			_ballerine[chi] = int(_ballerine.get(chi, 0)) + 1
		_energie[i] = e


func _scarto(a: Image, b: Image) -> float:
	if a == null or b == null:
		return 0.0
	var somma := 0.0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			somma += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
	return somma / float(a.get_width() * a.get_height() * 3)


func _referto() -> void:
	_finito = true
	print("")
	print("[ombre] --- SOSPETTO 1: la compilazione delle pipeline ---")
	for g in 3:
		var t := _tempi[g]
		var somma := 0.0
		var peggio := 0.0
		var scatti := 0
		for v in t:
			somma += v
			peggio = maxf(peggio, v)
			if v > SCATTO_MS:
				scatti += 1
		print("[ombre] giro %d: %.1f ms in media, picco %.1f ms, %d fotogrammi sopra %.0f ms"
			% [g + 1, somma / float(t.size()), peggio, scatti, SCATTO_MS])
	print("[ombre] se il primo giro scatta e il secondo no, e' la compilazione:")
	print("[ombre]   succede una volta sola per materiale, ed e' il «poi si stabilizza».")

	print("")
	print("[ombre] --- SOSPETTO 2: l'atlante delle ombre ---")
	# SI SALTA LA POSA 0, e non e' comodo: l'immagine che si legge in `_process` e'
	# quella del fotogramma PRECEDENTE, quindi all'indice zero il primo giro porta
	# la vista d'ingresso e il secondo porta l'ultima posa del primo. Un solo
	# indice disallineato, e vale novantacinque livelli: lasciato dentro sarebbe
	# diventato «il picco», cioe' la prova di un difetto che non c'e'.
	# TRE GIRI E NON DUE, e il terzo e' quello che decide. Se la differenza fosse un
	# transitorio - qualcosa che si sistema la prima volta e poi resta - il secondo
	# e il terzo giro sarebbero IDENTICI. Se invece ogni giro differisce dal
	# precedente allo stesso modo, non si sta sistemando niente: c'e' qualcosa che
	# cambia di continuo, e «poi si stabilizza» e' un'altra cosa.
	var diverse := 0
	var peggior_scarto := 0.0
	var dove := 1
	for coppia in [[0, 1], [1, 2]]:
		var d := 0
		var somma := 0.0
		var peggio := 0.0
		var dv := 1
		for i in range(1, POSE):
			var s := _scarto(_immagini[coppia[0]][i], _immagini[coppia[1]][i])
			somma += s
			if s > UGUALI:
				d += 1
				if s > peggio:
					peggio = s
					dv = i
		print("[ombre] giro %d contro giro %d: %d pose diverse su %d, media %.3f livelli, peggio %.3f"
			% [coppia[0] + 1, coppia[1] + 1, d, POSE - 1, somma / float(POSE - 1) * 255.0,
				peggio * 255.0])
		if coppia[0] == 0:
			diverse = d
			peggior_scarto = peggio
			dove = dv
	print("[ombre] %d pose su %d danno un'immagine DIVERSA fra primo e secondo giro"
		% [diverse, POSE - 1])
	print("[ombre] scarto peggiore %.3f livelli, alla posa %d (%d gradi)"
		% [peggior_scarto * 255.0, dove, dove * 360 / POSE])
	if diverse > 0:
		_immagini[0][dove].save_png("user://ombre_giro1.png")
		_immagini[1][dove].save_png("user://ombre_giro2.png")
		# E LA DIFFERENZA, amplificata: dove cambia si vede solo cosi'. Uno scarto
		# di due livelli su un muro non lo distingue nessuno guardando le due foto
		# accanto, e la domanda «cosa cambia» resterebbe aperta.
		var da: Image = _immagini[0][dove]
		var a: Image = _immagini[1][dove]
		var diff := Image.create(da.get_width(), da.get_height(), false,
			Image.FORMAT_RGB8)
		for y in da.get_height():
			for x in da.get_width():
				var c1: Color = da.get_pixel(x, y)
				var c2: Color = a.get_pixel(x, y)
				var v := clampf((absf(c1.r - c2.r) + absf(c1.g - c2.g)
					+ absf(c1.b - c2.b)) * 24.0, 0.0, 1.0)
				diff.set_pixel(x, y, Color(v, v, v))
		diff.save_png("user://ombre_differenza.png")
		print("[ombre] salvati i due fotogrammi discordi in user://ombre_giro1.png e 2")
		print("[ombre] stessa posa, immagini diverse: quello che si vede dipende")
		print("[ombre]   da come ci si e' arrivati, ed e' la firma dell'atlante.")

	print("")
	print("[ombre] --- LA SONDA E' ONESTA? ---")
	var sbagliate := 0
	var peggior_posa := 0.0
	for i in POSE:
		var t1: Transform3D = _pose_vere[0][i]
		var t2: Transform3D = _pose_vere[1][i]
		peggior_posa = maxf(peggior_posa, (t1.basis.z - t2.basis.z).length())
		if not t1.is_equal_approx(t2):
			sbagliate += 1
	print("[ombre] telecamera: %d pose su %d diverse fra i due giri, scarto max %.6f"
		% [sbagliate, POSE, peggior_posa])
	print("[ombre] giro 1 contro se stesso: %.6f livelli (deve essere zero)"
		% (_scarto(_immagini[0][40], _immagini[0][40]) * 255.0))
	print("[ombre] pose vicine nello stesso giro (40 contro 41): %.3f livelli"
		% (_scarto(_immagini[0][40], _immagini[0][41]) * 255.0))
	print("")
	if _mossi.is_empty():
		print("[ombre] NIENTE si muove fra un giro e l'altro.")
	else:
		print("[ombre] --- CHI SI MUOVE fra un giro e l'altro (%d nodi) ---" % _mossi.size())
		var quanti := 0
		for chi in _mossi:
			print("[ombre]   %s   %s" % [chi, _mossi[chi]])
			quanti += 1
			if quanti >= 25:
				print("[ombre]   ... e altri %d" % (_mossi.size() - 25))
				break
	if _ballerine.is_empty():
		print("[ombre] nessuna luce cambia ENERGIA: non e' una lampada che lampeggia.")
	else:
		for chi in _ballerine:
			print("[ombre] la luce %s cambia %d volte" % [chi, _ballerine[chi]])
	get_tree().quit()
