## LE BRACCIA ALL'ORIZZONTE — `Ctrl+F4`.
##
## Cinque braccia umane escono da dietro l'orizzonte, una dopo l'altra, davanti a chi le ha
## chiamate: prima le dita, poi la mano, poi l'avambraccio. Uscendo la mano si apre, e
## lassù ogni mano fa i suoi gesti — una si tende, una ti chiama con l'indice, una ti indica,
## una graffia il cielo — ognuna per conto suo. Chiamate di nuovo, tornano giù chiudendosi.
## Come si muove una mano sta in `world/orrori/braccio_umano.gd`.
##
## LA PRIMA STESURA ERA IL TENTACOLO DI `F5` CAPOVOLTO: cinque stecchi. La seconda, cinque
## braccia di polpo vere, con le ventose e il ricciolo. Federico: «io pensavo a braccia
## umane». Ed è l'immagine giusta: un polpo gigante è un mostro, una mano umana grande come
## una montagna è una cosa che non dovrebbe esistere.
##
## ESCONO DAL TERRENO VERO, DOVE LO SI VEDE LONTANO. Da quando attorno c'è Monte San Lorenzo
## (D-273) il nodo di ogni braccio sta sulla quota del terreno dove spunta, e la spalla
## sotto di lui: le braccia SPUNTANO dalla valle, non stanno appoggiate a una quota zero
## che là non c'è.
##
## E NON PER FORZA DOVE SI GUARDA. Dalla porta verso nord la collina e il bosco coprono il
## cielo fino a undici gradi, e delle braccia restavano le mani sopra gli alberi del recinto:
## a trenta metri, grandi quanto loro, sembravano mani di persona dietro la siepe. Federico:
## «le mani fanno cose ridicole». Una cosa si legge grande se si vede la terra da cui esce,
## lontana. Allora le braccia vanno verso la direzione più vicina a quella dello sguardo in
## cui l'orizzonte - il terreno e gli alberi del panorama - lascia fuori l'avambraccio; e se
## lo spicchio libero è stretto si stringono fra loro. Dalla porta il bosco attorno copre il
## cielo fino a quaranta gradi, e resta libera una settantina di gradi verso la valle: le
## cinque braccia larghe ne prendono novanta. E L'EDIFICIO CONTA: la valle sta dietro la
## casa, e la prima stesura, che guardava solo terreno e alberi, le mandava lì.
##
## OGNI BRACCIO MOSTRA IL PALMO A CHI GUARDA: una mano vista di taglio è una lama, vista di
## piatto sono cinque dita. Le sinistre stanno a sinistra e le destre a destra: un gomito si
## piega dalla parte del pollice, e un destro a sinistra del quadro piegandosi attraversava
## il sinistro accanto. Ognuna pende un po' in fuori, come una folla che si sbraccia.
##
## A SINISTRA VUOL DIRE AZIMUT PIÙ GRANDE. Il mondo del gioco è allo specchio (D-272): da nord
## l'est sta a sinistra. Contati come in una bussola, le sinistre finivano a destra, piegavano
## il gomito verso il centro, e strette nello spicchio fra la casa e il bosco due braccia si
## incrociavano a X.
class_name OrroreBraccia
extends Orrore

## Ogni braccio: di quanti gradi è spostato verso destra di chi guarda, a che distanza, quanto
## è alto dalla spalla alla punta del medio, dopo quanti secondi comincia a salire, se è un
## sinistro, di quanti gradi pende di lato (positivo: verso destra di chi guarda) e in avanti.
const BRACCI := [
	[-46.0, 1450.0, 1150.0, 0.0, true, -5.0, 4.0],
	[-22.0, 1250.0, 1000.0, 5.0, true, -2.0, -3.0],
	[2.0, 1650.0, 1400.0, 1.5, false, 1.0, 5.0],
	[25.0, 1300.0, 1050.0, 8.0, false, 3.0, -2.0],
	[48.0, 1550.0, 1200.0, 11.0, false, 6.0, 3.0],
]

## Da che gesto comincia ogni braccio, nell'ordine di `BRACCI`: il più vicino a chi guarda
## (il secondo) chiama con l'indice, quello in mezzo indica.
const PRIMI_GESTI := [BraccioUmano.Gesto.TENDE, BraccioUmano.Gesto.CHIAMA,
	BraccioUmano.Gesto.INDICA, BraccioUmano.Gesto.ARTIGLIO, BraccioUmano.Gesto.STRINGE]

## L'orizzonte che lascia vedere un braccio, in gradi. Salito, un braccio di un chilometro a
## un chilometro e mezzo ha il gomito fra zero e cinque gradi e il polso sopra i quattordici:
## sotto i quattro fuori restano la mano e buona parte dell'avambraccio.
const ORIZZONTE_LIBERO := 4.0
## Quanto si stringono le braccia, dal ventaglio largo di `BRACCI`, per stare nello spicchio
## libero: si prova prima larghe, e fino a poco più di metà.
const STRETTE := [1.0, 0.85, 0.7, 0.55]
## Il passo con cui si guarda l'orizzonte attorno, in gradi, e fin dove: il braccio più vicino.
const PASSO_ORIZZONTE := 5.0
## Gli alberi del panorama contano fin qui, in metri; oltre un albero sotto il gradino di
## terreno davanti non si alza. E quanto sono alti e larghi, in metri per scala uno
## (`tools/alberi_blender.py`, ALTEZZE: da nove a tredici).
const ALBERI_FINO_A := 300.0
const ALBERO_ALTO := 12.0
## quanto la chioma sporge dal tronco
const ALBERO_LARGO := 4.0
## Fin dove si cerca con i raggi quello che si vede e non è terreno - l'edificio, la cupola,
## la rete - in metri, sulla geometria come si vede (`Corazza.LAYER_APPOGGI`).
const OSTACOLI_FINO_A := 150.0

var _bracci: Array[BraccioUmano] = []
var _partenze: Array[float] = []
var _partiti: Array[bool] = []
var _tornati := 0


func _comincia() -> void:
	var cam := _camera()
	var da := cam.global_position if cam != null else Vector3.ZERO
	var terreno := trova(get_tree().root, "Panorama") as Panorama
	var az0 := azimut_di(_davanti())
	var stretta := 1.0
	if terreno != null:
		var scelta := _dove_si_vede(da, az0, terreno, get_world_3d().direct_space_state)
		az0 = scelta.x
		stretta = scelta.y
	for i in BRACCI.size():
		var b: Array = BRACCI[i]
		var braccio := BraccioUmano.new()
		braccio.name = "Braccio%d" % (i + 1)
		braccio.altezza = float(b[2])
		braccio.sinistro = bool(b[4])
		# UN GESTO DIVERSO PER COMINCIARE, e un dado suo per continuare
		braccio.primo_gesto = PRIMI_GESTI[i % PRIMI_GESTI.size()]
		braccio.seme = 1999 + 7919 * i
		var via := verso(az0 - float(b[0]) * stretta, 0.0)
		var dove := Vector3(da.x, 0.0, da.z) + via * float(b[1])
		if terreno != null:
			dove.y = terreno.quota(Vector2(dove.x, dove.z))
		add_child(braccio)
		# il +Z del braccio, dove guarda il palmo, verso chi guarda: il -Z guarda lontano.
		# Girare attorno a Z lo fa pendere nel quadro; attorno a X, avanti e indietro.
		var base := Basis.looking_at(via, Vector3.UP)
		base = base * Basis(Vector3.BACK, deg_to_rad(-float(b[5]))) * Basis(Vector3.RIGHT, deg_to_rad(-float(b[6])))
		braccio.global_transform = Transform3D(base, dove)
		braccio.sceso.connect(_su_tornato)
		_bracci.append(braccio)
		_partenze.append(float(b[3]))
		_partiti.append(false)


func _congeda() -> void:
	for k in _bracci.size():
		_partiti[k] = true
		# UN BRACCIO CHE NON È MAI USCITO È GIÀ TORNATO: `sceso` lo emette chi scende, e chi
		# non è salito non scende da nessuna parte
		if _bracci[k].uscito() <= 0.0:
			_tornati += 1
		else:
			_bracci[k].scendi()
	if _tornati >= _bracci.size():
		_chiudi()


func _avanza(_delta: float) -> void:
	if _in_uscita:
		return
	for k in _bracci.size():
		if not _partiti[k] and _tempo >= _partenze[k]:
			_bracci[k].sali()
			_partiti[k] = true


func _su_tornato() -> void:
	if not _in_uscita:
		return
	_tornati += 1
	if _tornati >= _bracci.size():
		_chiudi()


func bracci() -> Array[BraccioUmano]:
	return _bracci


## Dove escono le braccia: in x l'azimut, in gradi, attorno a cui si aprono; in y quanto si
## stringono (`STRETTE`). Il più vicino a `az0` da cui, per tutte e cinque, l'orizzonte
## resta sotto `ORIZZONTE_LIBERO`, larghe se si può. Se non ce n'è uno - dalla porta, fra la
## casa e il bosco, lo spicchio libero è di una trentina di gradi - quello dove l'orizzonte
## copre meno, sommando braccio per braccio i gradi di troppo.
func _dove_si_vede(da: Vector3, az0: float, terreno: Panorama,
		spazio: PhysicsDirectSpaceState3D) -> Vector2:
	var alto := orizzonte(da, terreno, spazio)
	var meglio := Vector2(az0, 1.0)
	var meglio_quanto := INF
	var passi := int(180.0 / PASSO_ORIZZONTE)
	for k in range(0, 2 * passi):
		# 0, +1, -1, +2, -2...: prima i più vicini a dove si guarda
		var scarto := PASSO_ORIZZONTE * ceili(k / 2.0) * (1.0 if k % 2 == 1 else -1.0)
		var c := az0 + scarto
		for stretta: float in STRETTE:
			var troppo := 0.0
			for br in BRACCI:
				troppo += maxf(0.0, orizzonte_verso(alto, c - float(br[0]) * stretta) - ORIZZONTE_LIBERO)
			if troppo <= 0.0:
				return Vector2(c, stretta)
			if troppo < meglio_quanto:
				meglio_quanto = troppo
				meglio = Vector2(c, stretta)
	return meglio


## Quanto è alto l'orizzonte visto da `da`, in gradi, ogni `PASSO_ORIZZONTE` gradi di azimut
## a partire da nord: il terreno fino al braccio più vicino, sopra gli alberi del panorama
## entro `ALBERI_FINO_A`, e quello che i raggi trovano entro `OSTACOLI_FINO_A`.
static func orizzonte(da: Vector3, terreno: Panorama,
		spazio: PhysicsDirectSpaceState3D) -> PackedFloat32Array:
	var n := int(360.0 / PASSO_ORIZZONTE)
	var alto := PackedFloat32Array()
	alto.resize(n)
	alto.fill(-90.0)
	var fino := INF
	for b in BRACCI:
		fino = minf(fino, float(b[1]))
	var qui := Vector2(da.x, da.z)
	for i in n:
		var v := verso(i * PASSO_ORIZZONTE, 0.0)
		var d := Vector2(v.x, v.z).normalized()
		var r := 10.0
		while r < fino:
			var h := terreno.quota(qui + d * r)
			alto[i] = maxf(alto[i], rad_to_deg(atan2(h - da.y, r)))
			r *= 1.06
		if spazio != null:
			alto[i] = maxf(alto[i], _sopra_gli_ostacoli(da, i * PASSO_ORIZZONTE, spazio))
	var dati := terreno.dati
	if dati != null:
		for k in dati.alberi.size():
			var a := dati.alberi[k]
			var p := Vector2(a.x, a.z)
			var r := p.distance_to(qui)
			if r > ALBERI_FINO_A or r < 1.0:
				continue
			var cima := rad_to_deg(atan2(terreno.quota(p) + ALBERO_ALTO * a.y - da.y, r))
			var az := azimut_di(Vector3(p.x - qui.x, 0.0, p.y - qui.y))
			var largo := rad_to_deg(atan2(ALBERO_LARGO * a.y, r))
			for j in range(floori((az - largo) / PASSO_ORIZZONTE), ceili((az + largo) / PASSO_ORIZZONTE) + 1):
				var jj := posmod(j, n)
				alto[jj] = maxf(alto[jj], cima)
	return alto


## Il gradino più basso, in gradi, da cui un raggio verso `az` non trova niente entro
## `OSTACOLI_FINO_A`. Cercato a metà ogni volta: quello che sta in piedi, se copre un'altezza,
## copre anche tutte quelle sotto.
static func _sopra_gli_ostacoli(da: Vector3, az: float, spazio: PhysicsDirectSpaceState3D) -> float:
	var giu := -15.0
	var su := 85.0
	for _k in 8:
		var e := (giu + su) * 0.5
		var domanda := PhysicsRayQueryParameters3D.create(da, da + verso(az, e) * OSTACOLI_FINO_A,
			Corazza.LAYER_APPOGGI)
		if spazio.intersect_ray(domanda).is_empty():
			su = e
		else:
			giu = e
	return su


## L'orizzonte verso un azimut, dai due passi più vicini.
static func orizzonte_verso(alto: PackedFloat32Array, az: float) -> float:
	var f := fposmod(az, 360.0) / PASSO_ORIZZONTE
	var i := floori(f)
	return maxf(alto[i % alto.size()], alto[(i + 1) % alto.size()])
