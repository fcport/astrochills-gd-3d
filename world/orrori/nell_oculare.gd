## L'OCCHIO NELL'OCULARE — `Ctrl+F5`.
##
## A occhio nudo non c'è niente. Si mette l'occhio al telescopio, e il campo è pieno di un
## occhio: guarda di lato, poi scatta su di te, e la pupilla si stringe. È lo stesso occhio
## del cielo (`world/occhio.gd`), piccolo quanto un occhio vero di un polpo grande, e sta
## DAVANTI ALLA BOCCA DEL TUBO, a sessanta centimetri: qualcosa che guarda dentro il
## telescopio da fuori.
##
## LA PRIMA STESURA LO METTEVA IN CIELO, a tremila metri lungo l'asse del tubo, e non si è
## visto. Federico: «io semplicemente non vedo nulla, solo dopo un SACCO di tempo è
## comparso l'occhio, ma si capisce pochissimo». Tre ragioni, tutte e tre vere:
##   * IN CIELO SERVIVA LA CUPOLA APERTA E GIRATA SUL TUBO: con la fessura chiusa l'occhio
##     stava dietro la calotta come le stelle, e compariva quando la cupola finiva di
##     girare — minuti.
##   * LA PUPILLA ERA ORIZZONTALE NEL MONDO, com'è in un polpo, ma la vista di una
##     equatoriale è girata: nel campo era una fessura obliqua.
##   * LO ILLUMINAVA LA LUNA, che di rado sta dietro a chi guarda: l'occhio era una sagoma
##     scura con una falce di iride.
## Adesso sta alla bocca del tubo e non c'è cupola che lo copra, la pupilla è orizzontale
## nel campo (`Occhio.alto`), e ha una luce sua.
##
## PERCHÉ UN LAYER. A sessanta centimetri dal tubo, se esistesse, lo vedrebbe anche chi
## sta in cupola. Sta su un layer visivo (`STRATO`) che la camera dell'oculare disegna e
## quella del giocatore no: c'è solo quando lo si guarda attraverso lo strumento.
##
## LA LUCE È INVENTATA, e lo si dice: una lampadina fioca vicino alla bocca del tubo, che
## illumina SOLO quel layer. Senza, a cupola chiusa l'occhio è nero su nero; con la Luna,
## è un pezzo di notte che nessuno sa leggere. La luce viene da sopra la spalla di chi
## guarda, e il riflesso sul bulbo viene da lì — è il riflesso che fa di una sfera scura
## un occhio bagnato.
class_name OrroreNellOculare
extends Orrore

const SCENA := "res://world/occhio.tscn"

## Il layer visivo che solo l'oculare vede: il ventesimo, l'ultimo, che nessuno usa.
const STRATO := 1 << 19

## Quanto è lontano dalla camera dell'oculare, in metri, e quanto è grande il bulbo.
##
## SESSANTA CENTIMETRI, perché la cupola chiusa sta più in là: a un metro e mezzo, col tubo
## puntato sulla parete, l'occhio finiva dentro il muro. Il campo dell'oculare è alto dodici
## gradi e il cerchio del velo ne lascia vedere 5,5 di raggio: un bulbo di 4,3 centimetri a
## sessanta ne prende quattro, cioè tre quarti del cerchio, e attorno resta la pelle.
const DISTANZA := 0.6
const RAGGIO := 0.043

## Per quanto guarda altrove prima di trovarti, e dopo quanto la pupilla si stringe.
const ALTROVE := 1.3
const SI_ACCORGE := 0.35

## La luce: dove sta rispetto alla camera (destra, alto, avanti), quanto è forte e fin dove
## arriva.
const LUCE_DOVE := Vector3(-0.18, 0.22, -0.05)
const LUCE_ENERGIA := 0.16
const LUCE_PORTATA := 1.6

var _oculare: Oculare
var _occhio: Occhio
var _luce: OmniLight3D
var _camera_giocatore: Camera3D
var _maschera_prima := 0
var _abbaglia_fra := -1.0


func _comincia() -> void:
	_oculare = Oculare.find_in(get_tree())
	if _oculare == null or _oculare.camera() == null:
		push_warning("occhio nell'oculare: in scena non c'è un oculare")
		_chiudi()
		return
	var g := Player.find_in(get_tree())
	_camera_giocatore = g.camera() if g != null else null
	if _camera_giocatore != null:
		_maschera_prima = _camera_giocatore.cull_mask
		_camera_giocatore.cull_mask &= ~STRATO
	_oculare.guardato.connect(_su_guardato)
	# se qualcuno ha GIÀ l'occhio dentro, l'occhio c'è già
	if _oculare.dentro():
		_su_guardato(true)


func _congeda() -> void:
	if _oculare != null and _oculare.guardato.is_connected(_su_guardato):
		_oculare.guardato.disconnect(_su_guardato)
	if _occhio != null and _oculare != null and _oculare.dentro():
		# lo si sta guardando: si chiude, e poi se ne va
		_occhio.svanito.connect(_se_ne_va)
		_occhio.chiudi()
		return
	_se_ne_va()


func _avanza(delta: float) -> void:
	_segui_il_tubo()
	if _abbaglia_fra >= 0.0:
		_abbaglia_fra -= delta
		if _abbaglia_fra < 0.0 and _occhio != null:
			_occhio.abbaglia(4.0)


func _su_guardato(dentro: bool) -> void:
	if not dentro:
		return
	if _occhio == null:
		_occhio = (load(SCENA) as PackedScene).instantiate() as Occhio
		_occhio.raggio = RAGGIO
		_occhio.distanza = DISTANZA
		_occhio.strato = STRATO
		_occhio.name = "OcchioNellOculare"
		add_child(_occhio)
		_luce = OmniLight3D.new()
		_luce.name = "LuceOcchio"
		_luce.light_cull_mask = STRATO
		_luce.light_energy = LUCE_ENERGIA
		_luce.omni_range = LUCE_PORTATA
		_luce.shadow_enabled = false
		add_child(_luce)
		_occhio.riflesso_da = _luce
		_segui_il_tubo()
		_occhio.apri_subito(ALTROVE)
		_abbaglia_fra = ALTROVE + SI_ACCORGE
	else:
		# ti ha già trovato: ti riconosce, e si stringe subito
		_abbaglia_fra = SI_ACCORGE


## L'occhio e la sua luce stanno davanti alla camera dell'oculare, che è appesa al tubo:
## si rimettono lì a ogni passo, perché il tubo insegue il cielo e la montatura lo muove.
## Si scrive la posizione, non si richiama `colloca_verso()`, che rimetterebbe lo sguardo
## dritto avanti e cancellerebbe dove sta guardando.
func _segui_il_tubo() -> void:
	if _occhio == null or _oculare == null:
		return
	var cam := _oculare.camera()
	if cam == null or not cam.is_inside_tree():
		return
	var b := cam.global_basis.orthonormalized()
	var dove := cam.global_position - b.z * DISTANZA
	_occhio.alto = b.y
	_occhio.global_transform = Transform3D(Basis.looking_at(cam.global_position - dove, b.y), dove)
	_luce.global_position = cam.global_position + b * LUCE_DOVE


func _se_ne_va() -> void:
	# si rimette solo il bit che si era tolto: il resto della maschera non è nostro
	if _camera_giocatore != null and is_instance_valid(_camera_giocatore) \
			and _maschera_prima & STRATO:
		_camera_giocatore.cull_mask |= STRATO
	if _occhio != null:
		_occhio.queue_free()
		_occhio = null
	if _luce != null:
		_luce.queue_free()
		_luce = null
	_chiudi()


func occhio() -> Occhio:
	return _occhio


func luce() -> OmniLight3D:
	return _luce
