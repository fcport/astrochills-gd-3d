## LE BRACCIA ALL'ORIZZONTE — `Ctrl+F4`.
##
## Cinque braccia umane escono da dietro l'orizzonte, una dopo l'altra, davanti a chi le ha
## chiamate: prima le dita, poi la mano, poi l'avambraccio. Uscendo la mano si apre, e
## lassù le mani si allungano verso il cielo e si stringono, piano, ognuna per conto suo,
## come chi annega e cerca un appiglio. Chiamate di nuovo, tornano giù chiudendosi.
## Come si muove una mano sta in `world/orrori/braccio_umano.gd`.
##
## LA PRIMA STESURA ERA IL TENTACOLO DI `F5` CAPOVOLTO: cinque stecchi. La seconda, cinque
## braccia di polpo vere, con le ventose e il ricciolo. Federico: «io pensavo a braccia
## umane». Ed è l'immagine giusta: un polpo gigante è un mostro, una mano umana grande come
## una montagna è una cosa che non dovrebbe esistere.
##
## PERCHÉ SOTTO L'ORIZZONTE E NON SOPRA UNA COLLINA. Il prato è un'isola di quarantotto
## metri, e oltre il suo bordo non c'è terreno: il profilo che si vede all'orizzonte è il
## bordo del prato stesso. Visto dalla porta scende di quattro gradi; a millecinquecento
## metri vuol dire cento metri sotto quota zero, e la spalla di queste braccia ne sta
## trecento sotto: le braccia SPUNTANO, non stanno appoggiate.
##
## OGNI BRACCIO MOSTRA IL PALMO A CHI GUARDA: una mano vista di taglio è una lama, vista di
## piatto sono cinque dita. Le sinistre stanno a sinistra e le destre a destra: un gomito si
## piega dalla parte del pollice, e un destro a sinistra del quadro piegandosi attraversava
## il sinistro accanto. Ognuna pende un po' in fuori, come una folla che si sbraccia.
class_name OrroreBraccia
extends Orrore

## Ogni braccio: di quanti gradi è spostato dall'azimut di chi guarda, a che distanza, quanto
## è alto dalla spalla alla punta del medio, dopo quanti secondi comincia a salire, se è un
## sinistro, di quanti gradi pende di lato (positivo: verso destra di chi guarda) e in avanti.
const BRACCI := [
	[-46.0, 1450.0, 1150.0, 0.0, true, -5.0, 4.0],
	[-22.0, 1250.0, 1000.0, 5.0, true, -2.0, -3.0],
	[2.0, 1650.0, 1400.0, 1.5, false, 1.0, 5.0],
	[25.0, 1300.0, 1050.0, 8.0, false, 3.0, -2.0],
	[48.0, 1550.0, 1200.0, 11.0, false, 6.0, 3.0],
]

var _bracci: Array[BraccioUmano] = []
var _partenze: Array[float] = []
var _partiti: Array[bool] = []
var _tornati := 0


func _comincia() -> void:
	var cam := _camera()
	var da := cam.global_position if cam != null else Vector3.ZERO
	var az0 := azimut_di(_davanti())
	for i in BRACCI.size():
		var b: Array = BRACCI[i]
		var braccio := BraccioUmano.new()
		braccio.name = "Braccio%d" % (i + 1)
		braccio.altezza = float(b[2])
		braccio.sinistro = bool(b[4])
		braccio.sfasatura = 3.7 * i
		var via := verso(az0 + float(b[0]), 0.0)
		var dove := Vector3(da.x, 0.0, da.z) + via * float(b[1])
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
