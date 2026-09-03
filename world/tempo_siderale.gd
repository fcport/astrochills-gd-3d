## IL CIELO CHE GIRA: quanto ha girato, attorno a cosa, e chi lo deve sapere.
##
## COSA FA, IN UNA RIGA: trasforma i minuti della notte in gradi di cielo, e li
## scrive nello shader del fondo.
##
## PERCHÉ NON C'ERA E DOVEVA ESSERCI. Federico: «hai messo la rotazione del cielo?».
## No: `cielo.gdshader` era una funzione della sola direzione dello sguardo, e le
## stelle stavano inchiodate all'edificio. Il resto del gioco però il cielo lo faceva
## girare da sempre — `HonestCatalog` ricava l'angolo orario dall'ora, `DomeAzimuth`
## esiste perché la fessura va riportata, `TelescopeMount.partenza_gradi` è tarata
## sul fatto che «il cielo deriva di un sesto di grado al secondo». Tutto il gioco
## diceva che il cielo gira e la fenditura mostrava un fondale dipinto.
##
## QUINDICI GRADI L'ORA, E NON È UNA COSTANTE DI GIOCO. È il giro della Terra, e in
## questo progetto sta già scritta due volte — `HonestCatalog.GRADI_AL_MINUTO` e la
## gemella in `HonestPointing` — perché `phases/` non può nominare `world/` né il
## contrario. Questa è la terza copia dello stesso quarto di grado al minuto, ed è
## dichiarata come tale: il banco confronta le due che può vedere, e questa riga
## esiste per essere confrontata a occhio con loro il giorno che una cambi.
##
## L'ASSE È IL POLO CELESTE, E LA MONTATURA CI STA SOPRA — misurato, e non era
## quello che ci si aspettava. `telescope_mount.gd` dichiara da sempre un
## disallineamento polare di otto decimi di grado, quindi l'inseguimento avrebbe
## dovuto perdere la stella di un grado e mezzo per notte. Non la perde: zero.
##
## `tools/prova_rotazione.gd` ha misurato l'asse VERO della montatura come bisettrice
## fra due puntamenti opposti — 43,900 gradi d'altezza, azimut 0,000, cioè il polo
## celeste esatto — e ha trovato che quello che sta storto è il TUBO, che a
## declinazione 90 guarda 0,951 gradi fuori dal proprio asse. Sono due difetti
## diversissimi con lo stesso numero: un asse storto rovina l'INSEGUIMENTO e non si
## può correggere puntando; un tubo storto sposta il PUNTAMENTO e si corregge con una
## sincronizzazione su una stella nota, che è precisamente la fase 3 di questo gioco.
##
## Quindi il cielo gira attorno alla stessa retta attorno a cui gira il telescopio, e
## una posa può durare tutta la notte senza che il soggetto scivoli.
##
## IL TEMPO NON È SUO. `elapsed_min` vive in `NightRun`, lo fa scorrere `NightClock`,
## lo possiede `Game`. Qui si legge e si converte: una seconda copia del tempo
## sarebbe la prima cosa a divergere, ed è la stessa regola per cui l'orologio non
## legge `Engine.time_scale`.
class_name TempoSiderale
extends Node

## Chi ha bisogno di sapere dove sta il cielo lo trova per GRUPPO, mai per percorso
## di nodo: stessa regola della montatura, della cupola e del monitor (D-196).
const GROUP := &"tempo_siderale"

## Gradi di cielo per ogni minuto di gioco: quindici gradi l'ora. Gemella delle
## costanti omonime in `HonestCatalog` e `HonestPointing`. Vedi l'intestazione.
const GRADI_AL_MINUTO := 0.25

## Il nodo che porta l'ambiente col cielo dentro. Lo scrive `gen_blockout.py`.
@export var ambiente: NodePath

## L'altezza del polo celeste sull'orizzonte, in gradi: È la latitudine, ed è la
## stessa cosa detta due volte. Il numero arriva da `LATITUDINE` in `geometria.py`,
## che è anche la riga da cui il modellatore inclina l'asse del telescopio.
@export var latitudine := 43.9

## L'azimut del polo, in gradi, misurato come `atan2(x, z)` — la convenzione di
## `DomeAzimuth`. Zero è il nord, che in questo modello sta verso +Z: lo dice la
## misura del telescopio, che a declinazione 90 punta ad azimut -1.
@export var azimut_del_polo := 0.0

## A VERO IL CIELO STA FERMO, com'era prima che questo file esistesse.
##
## È IL DIFETTO CHE SI RIMETTE, e c'è qualcosa che lo vede: a cielo fermo la cupola
## non parte più. `tools/prova_rotazione.gd` conta le partenze del motore, e con
## questa a vero il conto va a zero — che è esattamente il gioco di ieri, dove la
## calotta si muoveva solo dopo un GOTO e poi stava zitta fino al successivo.
##
## E IL VERSO NON È UN INTERRUTTORE. Che una stella sorga a est, culmini a sud e
## tramonti a ovest non si può capovolgere qui: il verso non è un numero di questo
## file, è la stessa rotazione che la montatura usa per inseguire (`giro()`), e
## girarne una sola vorrebbe dire un cielo e un telescopio che non parlano più.
## Che il verso sia quello giusto lo dicono due cose diverse: la tabella misurata in
## `telescope_mount.gd` (angolo orario -90 a est, 0 a sud, +90 a ovest) e i due
## fotogrammi di controllo che `prova_rotazione.gd` salva a un'ora di distanza.
@export var fermo := false

var _mat: ShaderMaterial
var _polo := Vector3.UP
var _gradi := 0.0
var _scritto := INF


func _ready() -> void:
	add_to_group(GROUP)
	# L'ASSE SI CALCOLA UNA VOLTA SOLA: è la latitudine, e la latitudine non cambia
	# durante la notte. Altezza sull'orizzonte = latitudine, azimut = nord.
	var alt := deg_to_rad(latitudine)
	var az := deg_to_rad(azimut_del_polo)
	_polo = Vector3(sin(az) * cos(alt), sin(alt), cos(az) * cos(alt)).normalized()

	var we := get_node_or_null(ambiente) as WorldEnvironment
	var sky: Sky = we.environment.sky if we != null and we.environment != null else null
	_mat = sky.sky_material as ShaderMaterial if sky != null else null
	if _mat == null:
		# SI GRIDA MA NON CI SI FERMA. Il numero che questo nodo produce è un fatto
		# del mondo — il cielo HA girato — e la montatura ci insegue sopra. Un cielo
		# che non si vede girare è un guasto di resa; un cielo che il telescopio non
		# sa più dov'è sarebbe un guasto di meccanica, e sarebbe peggio.
		push_error("[system] tempo siderale: non trovo il materiale del cielo (%s)" % ambiente)
		return
	_mat.set_shader_parameter("polo_celeste", _polo)


func _process(_delta: float) -> void:
	# NIENTE NOTTE, NIENTE CIELO: prima di `Game.start_night()` non c'è un tempo da
	# convertire, e inventarne uno vorrebbe dire un cielo che gira nel menu.
	var minuti: float = Game.run.elapsed_min if Game.run != null else 0.0
	_gradi = 0.0 if fermo else minuti * GRADI_AL_MINUTO
	if _mat == null or is_equal_approx(_gradi, _scritto):
		return
	_scritto = _gradi
	_mat.set_shader_parameter("giro", deg_to_rad(_gradi))


## Di quanto il cielo ha girato da inizio notte, in gradi.
func gradi() -> float:
	return _gradi


## L'asse: il polo celeste nord, versore in coordinate del mondo.
func polo() -> Vector3:
	return _polo


## La rotazione che porta una direzione DEL CIELO dove il cielo la mostra ADESSO.
## Chi vuole sapere dove è finita una stella la moltiplica per questa.
func giro() -> Basis:
	return Basis(_polo, deg_to_rad(_gradi))


static func find_in(tree: SceneTree) -> TempoSiderale:
	return tree.get_first_node_in_group(GROUP) as TempoSiderale
