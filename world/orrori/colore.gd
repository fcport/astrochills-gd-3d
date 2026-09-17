## IL COLORE VENUTO DALLO SPAZIO — `Ctrl+F8`.
##
## Una citazione, dichiarata: H. P. Lovecraft, «The Colour Out of Space», 1927. Una pietra
## cade dal cielo in una fattoria a ovest di Arkham; dentro c'è un colore che non è di
## nessuno spettro; l'erba e gli alberi attorno cominciano a brillare di notte e a muoversi
## senza vento; alla fine il colore risale al cielo «come un razzo o una meteora, senza
## lasciare scia», e dove c'era la fattoria resta un deserto di polvere grigia. Il racconto
## è di pubblico dominio (pubblicato negli Stati Uniti nel 1927; l'autore è morto nel 1937),
## e le due frasi qui sotto sono tradotte da lì.
##
##   «Era solo per analogia che lo chiamavano un colore.»
##   «Era soltanto un colore venuto dallo spazio: un messaggero spaventoso da regni
##    informi dell'infinito, oltre tutta la Natura che conosciamo.»
##
## LA PRIMA STESURA ERA UNA MACCHIA COLORATA SULL'ERBA con una pallina sopra, e una pallina
## che saliva: per Federico, «realizzazione TERRIBILE». Aveva ragione su tutto: un cerchio di
## erba che cambia tinta è un faretto da discoteca, e una sfera colorata è una sfera. Questa
## stesura parte da come le cose si vedono davvero, e cita il racconto solo dove il vero
## finisce.
##
## COSA SUCCEDE, IN QUEST'ORDINE:
##   1. LA PIETRA ARRIVA, ed è la stessa dal primo istante all'ultimo. Un punto di luce alto
##      davanti a chi guarda, a cinque chilometri, che cresce: viene verso di te. Accende il
##      paesaggio e fa girare le ombre degli alberi, lascia dietro una scia di fumo, e negli
##      ultimi secondi la si vede scendere sopra il prato. (`world/shaders/orrore_scia.gdshader`)
##   2. L'IMPATTO, a una dozzina di metri dalla porta: un lampo, il terreno che trema, zolle e
##      terra per aria, un polverone, e un cratere bruciato col bordo di terra smossa. Dentro,
##      mezza sepolta, la meteorite incandescente che fuma, e si raffredda.
##   3. IL COLORE. Raffreddandosi, nelle crepe e nei globuli della pietra compare il colore; e
##      il colore entra nell'erba, a macchie, allargandosi fino a prendersi il prato. Brillano
##      i fili, il bagliore striscia fra un ciuffo e l'altro, i ciuffi tremano senza vento;
##      sopra l'erba l'aria stessa si accende, e la luce arriva sul muro, sull'auto,
##      sull'osservatorio. (`world/shaders/erba.gdshader`, `colore_fronte.gdshaderinc`)
##   4. AL SECONDO TASTO SE NE VA: i ciuffi si tendono verso il cielo, la luce si ritira nella
##      pietra, e il colore SI VERSA NEL CIELO in una colonna che accende il paesaggio; poi la
##      colonna si stacca da terra e sale, e sparisce senza scia.
##      (`world/shaders/orrore_colonna.gdshader`)
##   5. RESTA LA CENERE: erba afflosciata e grigia, polvere grigia per terra con lo stesso bordo,
##      e fiocchi grigi che ricadono. Nel racconto resta per sempre; qui, che è uno strumento,
##      torna prato.
##
## LA SECONDA STESURA ERA GIUSTA NEI PASSI E SBAGLIATA NELLA LUCE («da migliorare molto»): il
## colore stava in una chiazza di nove metri, fioco come una tinta, non illuminava niente, e se
## ne andava come una pallina. Un colore che brilla è una LUCE: si vede nell'aria, tocca le cose
## attorno, sbava nell'occhio. Per questo, finché c'è, l'orrore accende il bagliore dello schermo
## e la nebbia volumetrica dell'ambiente — con densità zero, così la sola nebbia è la sua — e
## alla fine li rimette come li ha trovati.
##
## LA TERZA STESURA HA RIFATTO L'ARRIVO. Il bolide era un segno dipinto sul cielo, poi il
## buio, e poi un sasso compariva nel prato: «la parte del meteorite è semplicemente idiotica,
## poi compare così magicamente sto sasso». Adesso non c'è niente di dipinto sul cielo: quello
## che vola è la pietra, nel mondo, e quello che resta nel prato è quella pietra. Ed è una
## meteorite VERA, GRO 17102,0, scansionata dalla NASA (`tools/meteorite_blender.py`) — la
## sfera deformata di prima era «una merda».
##
## NIENTE SUONO, e non per dimenticanza: il progetto non tiene suoni sintetizzati, e il
## tonfo di una pietra non si inventa.
class_name OrroreColore
extends Orrore

const SHADER_SCIA := "res://world/shaders/orrore_scia.gdshader"
const METEORITE := "res://assets/models/meteorite.glb"
const SHADER_BAGLIORE := "res://world/shaders/orrore_bagliore.gdshader"
const SHADER_PIETRA := "res://world/shaders/orrore_pietra.gdshader"
const SHADER_COLONNA := "res://world/shaders/orrore_colonna.gdshader"

## Dove cade, in pianta: una dozzina di metri dalla porta, nel prato, lontano dall'auto e
## dall'asse su cui scende il tentacolo.
const DOVE := Vector2(1.5, 20.5)

## LA PIETRA CHE ARRIVA: da che punto del cielo di chi guarda (gradi di azimut in più
## rispetto a dove guarda, gradi d'altezza visti dalla buca), da quanto lontano, in quanto
## tempo, e a che velocità tocca terra. Rallenta scendendo, come rallenta un sasso che
## attraversa l'aria: parte a milleduecento metri al secondo e arriva a duecentocinquanta,
## quindi l'ultimo centinaio di metri sopra il prato dura mezzo secondo e SI VEDE.
const ARRIVA_DA := Vector2(22.0, 30.0)
const PARTENZA := 5200.0
const ARRIVO := 7.0
const VELOCITA_ARRIVO := 250.0
## Quanto è ingrandita: il campione vero è lungo tredici centimetri, e qui ne fa novanta.
const SCALA := 7.0
## Di quanto sta sepolta, in frazione della sua altezza.
const SEPOLTA := 0.35
## Quanta luce fa sul paesaggio, al massimo, e di che colore: un metallo che brucia.
const LAMPO := 2.4
const COLORE_LAMPO := Color(1.0, 0.9, 0.72)

## L'impatto: quanto è largo il cratere, per quanto la pietra resta calda, e quanto trema chi
## guarda (in metri di spostamento della camera, al primo istante).
const BUCA := 2.2
const CALDA := 8.0
const SCOSSA := 0.06

## IL COLORE NELL'ERBA: dopo quanto dall'impatto compare, fin dove arriva e con che passo —
## si avvicina a `FIN_DOVE` metri senza arrivarci —, in quanto si accende, in quanto i ciuffi
## si tendono.
const COMPARE := 8.0
const FIN_DOVE := 20.0
const ALLARGA_TAU := 14.0
const SI_ACCENDE_IN := 10.0
const SI_TENDE_IN := 60.0

## Quanto brilla, al massimo, la luce che il prato acceso getta attorno, e l'aria sopra.
const CHIARORE := 1.4
const FOSCHIA := 0.05

## L'uscita: si tende, si ritira, e poi la colonna — sale fino al cielo, si versa, si stacca e
## se ne va —; resta cenere, torna prato.
const SI_TENDE := 1.6
const SI_RITIRA := 1.8
const COLONNA_SALE := 0.8
const COLONNA_VERSA := 1.8
const COLONNA_STACCA := 1.3
const SALE_IN := COLONNA_SALE + COLONNA_VERSA + COLONNA_STACCA
const SALE_FINO := 1800.0
## Quanto accende il paesaggio la colonna: meno del lampo del bolide, ma di quel colore.
const LAMPO_COLONNA := 1.3
const CENERE := 20.0
const TORNA := 8.0

## Quello che l'orrore cambia nell'ambiente, e rimette com'era.
const AMBIENTE := ["glow_enabled", "glow_intensity", "glow_strength", "glow_bloom",
	"glow_blend_mode", "glow_hdr_threshold", "volumetric_fog_enabled",
	"volumetric_fog_density", "volumetric_fog_ambient_inject", "volumetric_fog_emission_energy",
	"volumetric_fog_length"]

enum Fase { CADE, BRILLA, SI_RACCOGLIE, SALE, CENERE, TORNA }

var _fase := Fase.CADE
var _t_fase := 0.0
var _dall_impatto := 0.0
var _erba: ShaderMaterial
var _dove := Vector3.ZERO
var _raggio := 0.0
var _raggio_preso := 0.0
var _forza := 0.0
var _tende := 0.0
var _raccolta := 0.0
var _cenere := 0.0
var _buca := 0.0
var _forza_prima := 0.0
var _tende_prima := 0.0

var _testa := Vector3.UP
var _da_dove := Vector3.UP
var _mezza_altezza := 0.45
var _scia: MeshInstance3D
var _mat_scia: ShaderMaterial
var _cratere: Decal
var _fumo: GPUParticles3D
var _tempo_impatto := -1.0
var _scossa := 0.0
var _scossa_camera: Camera3D
var _rng := RandomNumberGenerator.new()
var _lampo: DirectionalLight3D
var _pietra: MeshInstance3D
var _mat_pietra: ShaderMaterial
## LA PIETRA È UN SOLIDO, da quando tocca terra a quando si sbriciola: prima ci si passava
## attraverso. La forma è l'involucro convesso della scansione, alla scala della pietra.
var _solido: StaticBody3D
var _forma_solido: CollisionShape3D
var _forma_pietra: Shape3D
var _polvere: GPUParticles3D
var _luce: OmniLight3D
var _bagliore: MeshInstance3D
var _mat_bagliore: ShaderMaterial
var _cenere_per_terra: Decal
var _chiarore: OmniLight3D
var _foschia: FogVolume
var _mat_foschia: FogMaterial
var _colonna: MeshInstance3D
var _mat_colonna: ShaderMaterial
var _polverone: GPUParticles3D
var _fiocchi: GPUParticles3D
var _ambiente: Environment
var _ambiente_prima := {}
var _colonna_alta := 0.0


func _comincia() -> void:
	var prato := trova(get_tree().root, "Prato") as Prato
	var suolo := 0.0
	if prato != null:
		suolo = prato.position.y + FormaPrato.altezza(DOVE, prato.sito())
		var erba := prato.get_node_or_null("Erba") as GeometryInstance3D
		_erba = erba.material_override as ShaderMaterial if erba != null else null
	if _erba == null:
		push_warning("il colore: nel prato non c'è erba da accendere")
	_dove = Vector3(DOVE.x, suolo, DOVE.y)

	_rng.seed = 1882
	var az0 := azimut_di(_davanti())
	_da_dove = verso(az0 + ARRIVA_DA.x, ARRIVA_DA.y)

	_lampo = DirectionalLight3D.new()
	_lampo.name = "Lampo"
	_lampo.light_color = COLORE_LAMPO
	_lampo.light_energy = 0.0
	_lampo.shadow_enabled = true
	add_child(_lampo)

	_mat_pietra = ShaderMaterial.new()
	_mat_pietra.shader = load(SHADER_PIETRA) as Shader
	_pietra = MeshInstance3D.new()
	_pietra.name = "Pietra"
	_pietra.material_override = _mat_pietra
	_pietra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pietra.extra_cull_margin = PARTENZA
	_meteorite(_pietra)
	add_child(_pietra)
	_pietra.top_level = true
	_solido = StaticBody3D.new()
	_solido.name = "Solido"
	# ci si sbatte e il raggio del giocatore ci si ferma; e ci si possono posare le cose
	_solido.collision_layer = Interactable.LAYER_WORLD | Corazza.LAYER_APPOGGI
	_solido.collision_mask = 0
	_forma_solido = CollisionShape3D.new()
	_forma_solido.shape = _forma_pietra
	_forma_solido.disabled = true
	_solido.add_child(_forma_solido)
	add_child(_solido)
	_solido.top_level = true

	_mat_scia = ShaderMaterial.new()
	_mat_scia.shader = load(SHADER_SCIA) as Shader
	_scia = MeshInstance3D.new()
	_scia.name = "Scia"
	_scia.mesh = _nastro()
	_scia.material_override = _mat_scia
	_scia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_scia.extra_cull_margin = PARTENZA
	add_child(_scia)
	_scia.top_level = true
	_scia.global_transform = Transform3D(Basis.IDENTITY, _dove + Vector3.UP * _mezza_altezza)
	_mat_scia.set_shader_parameter("direzione", _da_dove)
	_mat_scia.set_shader_parameter("lunghezza", PARTENZA)
	_mat_scia.set_shader_parameter("velocita_arrivo", VELOCITA_ARRIVO)
	_mat_scia.set_shader_parameter("velocita_partenza", velocita_partenza())

	_cratere = _scava_il_cratere()
	add_child(_cratere)
	_cratere.global_position = _dove
	_cratere.visible = false

	_fumo = _fumo_della_pietra()
	add_child(_fumo)
	_fumo.global_position = _dove + Vector3.UP * 0.5

	_polvere = _zolla()
	add_child(_polvere)
	_polvere.global_position = _dove + Vector3.UP * 0.1

	_luce = OmniLight3D.new()
	_luce.name = "Luce"
	_luce.light_energy = 0.0
	_luce.omni_range = 5.0
	# CON LE OMBRE: scendendo accende il prato e le ombre degli alberi girano
	_luce.shadow_enabled = true
	add_child(_luce)
	_luce.top_level = true
	_luce.global_position = _dove + Vector3.UP * 0.6

	_mat_bagliore = ShaderMaterial.new()
	_mat_bagliore.shader = load(SHADER_BAGLIORE) as Shader
	_mat_bagliore.set_shader_parameter("lato", 2.5)
	_mat_bagliore.set_shader_parameter("minimo", 0.05)
	_bagliore = MeshInstance3D.new()
	_bagliore.name = "Bagliore"
	_bagliore.mesh = QuadMesh.new()
	_bagliore.material_override = _mat_bagliore
	_bagliore.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bagliore.extra_cull_margin = SALE_FINO
	_bagliore.visible = false
	add_child(_bagliore)

	_polverone = _nuvola_di_polvere()
	add_child(_polverone)
	_polverone.global_position = _dove + Vector3.UP * 0.3

	# LA LUCE DEL PRATO ACCESO: non dalla pietra, dall'alto del prato, larga quanto il colore,
	# così arriva sulle pareti e non fa un cerchio attorno a un punto
	_chiarore = OmniLight3D.new()
	_chiarore.name = "Chiarore"
	_chiarore.light_energy = 0.0
	_chiarore.shadow_enabled = false
	add_child(_chiarore)

	_mat_foschia = FogMaterial.new()
	_mat_foschia.density = 0.0
	_mat_foschia.albedo = Color(0.2, 0.2, 0.2)
	_mat_foschia.edge_fade = 0.6
	_mat_foschia.height_falloff = 0.4
	var rumore := FastNoiseLite.new()
	rumore.seed = 1927
	rumore.frequency = 0.08
	var trama := NoiseTexture3D.new()
	trama.width = 48
	trama.height = 16
	trama.depth = 48
	trama.seamless = true
	trama.noise = rumore
	_mat_foschia.density_texture = trama
	_foschia = FogVolume.new()
	_foschia.name = "Foschia"
	_foschia.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	_foschia.material = _mat_foschia
	_foschia.visible = false
	add_child(_foschia)

	_mat_colonna = ShaderMaterial.new()
	_mat_colonna.shader = load(SHADER_COLONNA) as Shader
	_mat_colonna.set_shader_parameter("altezza", SALE_FINO)
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 5.0
	cilindro.bottom_radius = 0.7
	cilindro.height = 1.0
	cilindro.radial_segments = 32
	cilindro.rings = 12
	cilindro.cap_top = false
	cilindro.cap_bottom = false
	_colonna = MeshInstance3D.new()
	_colonna.name = "Colonna"
	_colonna.mesh = cilindro
	_colonna.material_override = _mat_colonna
	_colonna.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_colonna.visible = false
	add_child(_colonna)
	_colonna.global_transform = Transform3D(Basis.from_scale(Vector3(1.0, SALE_FINO, 1.0)),
		_dove + Vector3.UP * (SALE_FINO * 0.5))

	_fiocchi = _fiocchi_di_cenere()
	add_child(_fiocchi)
	_fiocchi.global_position = _dove + Vector3.UP * 4.0

	_accendi_ambiente()
	_vola(0.0)
	Log.debug("orrori", "il colore: cade una pietra in (%.1f, %.1f)" % [DOVE.x, DOVE.y])


func _congeda() -> void:
	# se il colore non è ancora nell'erba, si aspetta che la pietra cada
	if _fase == Fase.BRILLA:
		_vai(Fase.SI_RACCOGLIE)


func _avanza(delta: float) -> void:
	_t_fase += delta
	var tinta := tinta_del_colore(_tempo)
	_trema(delta)
	if _tempo_impatto >= 0.0:
		var dopo := _tempo - _tempo_impatto
		_mat_scia.set_shader_parameter("dopo", dopo)
		_scia.visible = dopo < 40.0
	match _fase:
		Fase.CADE:
			_vola(_t_fase)
			if _t_fase >= ARRIVO:
				_impatto()
				_vai(Fase.BRILLA)
				if _in_uscita:
					_vai(Fase.SI_RACCOGLIE)
		Fase.BRILLA:
			_brilla(delta)
		Fase.SI_RACCOGLIE:
			_dall_impatto += delta
			var f := smoothstep(0.0, 1.0, _t_fase / SI_TENDE)
			_tende = lerpf(_tende_prima, 1.0, f)
			_forza = lerpf(_forza_prima, 1.8, f)
			var g := smoothstep(0.0, 1.0, (_t_fase - SI_TENDE) / SI_RITIRA)
			_raccolta = g
			_mat_pietra.set_shader_parameter("colore", 1.0 + 2.5 * g)
			_mat_pietra.set_shader_parameter("calore", 0.0)
			_luce.light_energy = 0.35 + 2.4 * g
			_luce.omni_range = 5.0 + 4.0 * g
			_luce.light_color = tinta
			_accendi_il_prato(_raggio_preso * (1.0 - 0.8 * g), tinta, 1.0 + 0.4 * f)
			if _t_fase >= SI_TENDE + SI_RITIRA:
				# il bagliore torna quello della luce che sale, dopo essere stato la testa della pietra
				_mat_bagliore.set_shader_parameter("lato", 2.5)
				_mat_bagliore.set_shader_parameter("minimo", 0.05)
				_bagliore.visible = true
				_colonna.visible = true
				_vai(Fase.SALE)
		Fase.SALE:
			_sale(tinta)
			if _t_fase >= SALE_IN:
				_bagliore.visible = false
				_colonna.visible = false
				_foschia.visible = false
				_luce.light_energy = 0.0
				_chiarore.light_energy = 0.0
				_lampo.light_energy = 0.0
				_fiocchi.emitting = true
				_vai(Fase.CENERE)
		Fase.CENERE:
			_forza = 0.0
			_tende = 0.0
			_cenere = 1.0
			if _t_fase >= CENERE:
				_vai(Fase.TORNA)
		Fase.TORNA:
			_cenere = 1.0 - smoothstep(0.0, TORNA, _t_fase)
			_buca = BUCA * _cenere
			_pietra.scale = Vector3.ONE * SCALA * maxf(_cenere, 0.01)
			if _t_fase >= TORNA:
				_raggio = 0.0
				_raggio_preso = 0.0
				_cenere = 0.0
				_buca = 0.0
				_raccolta = 0.0
				_scrivi_erba()
				_spegni_ambiente()
				_chiudi()
				return
	if _cenere_per_terra != null:
		_cenere_per_terra.modulate.a = _cenere
	_scrivi_erba()


func _vai(fase: Fase) -> void:
	if fase == Fase.SI_RACCOGLIE:
		_forza_prima = _forza
		_tende_prima = _tende
		# LA CENERE SI PREPARA QUI, quando si preme il tasto e non succede ancora niente: è
		# un'immagine calcolata pixel per pixel, e fatta alla partenza della colonna la
		# fermava per un attimo proprio nel momento che conta
		if _raggio_preso > 0.5 and _cenere_per_terra == null:
			_stendi_la_cenere()
	# sbriciolandosi la pietra rimpicciolisce fino a sparire: il solido se ne va subito
	if fase == Fase.TORNA and _forma_solido != null:
		_forma_solido.set_deferred("disabled", true)
	_fase = fase
	_t_fase = 0.0


## LA COLONNA, `_t_fase` secondi dopo che il colore si è raccolto nella pietra.
func _sale(tinta: Color) -> void:
	var t := _t_fase
	# 1. SALE: la cima corre dalla pietra al cielo, sempre più veloce
	var cima := pow(clampf(t / COLONNA_SALE, 0.0, 1.0), 2.2)
	# 3. SI STACCA: la base se ne va verso l'alto come un razzo, e la cima con lei
	var s := clampf((t - COLONNA_SALE - COLONNA_VERSA) / COLONNA_STACCA, 0.0, 1.0)
	var stacco := pow(s, 2.6)
	var accesa := smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(0.7, 1.0, s))
	_mat_colonna.set_shader_parameter("cima", maxf(cima, stacco + 0.02))
	_mat_colonna.set_shader_parameter("stacco", stacco)
	_mat_colonna.set_shader_parameter("forza", 2.6 * accesa)
	_colonna_alta = maxf(_colonna_alta, SALE_FINO * cima)
	# la testa del razzo: sulla cima mentre sale, poi sulla base che si stacca
	var h := 0.3 + SALE_FINO * (stacco if s > 0.0 else cima)
	_bagliore.global_position = _dove + Vector3.UP * h
	_mat_bagliore.set_shader_parameter("tinta", tinta)
	_mat_bagliore.set_shader_parameter("forza", 4.0 * (1.0 - smoothstep(0.6, 1.0, s)))
	# IL PAESAGGIO SI ACCENDE DI QUEL COLORE, da sopra: la colonna è lì
	_lampo.light_color = tinta
	_lampo.light_energy = LAMPO_COLONNA * accesa * (0.85 + 0.15 * sin(_tempo * 23.0))
	_lampo.global_basis = Basis.looking_at(Vector3(0.05, -1.0, 0.03), Vector3.BACK)
	_luce.global_position = _dove + Vector3.UP * minf(h, 30.0)
	_luce.omni_range = 12.0
	_luce.light_energy = 3.0 * accesa
	_luce.light_color = tinta
	# la vita se ne va dall'erba e dalla pietra insieme a lei, mentre si versa
	var via := smoothstep(COLONNA_SALE * 0.5, COLONNA_SALE + COLONNA_VERSA, t)
	_forza = 1.8 * (1.0 - via)
	_tende = 1.0 - via
	_raccolta = 1.0
	_cenere = smoothstep(COLONNA_SALE, SALE_IN * 0.8, t)
	_accendi_il_prato(_raggio_preso * 0.2 * (1.0 - via), tinta, 1.0 - via)
	_mat_pietra.set_shader_parameter("colore", 3.5 * (1.0 - via))
	_mat_pietra.set_shader_parameter("grigia", _cenere)


## La luce del prato acceso e l'aria sopra, per un colore arrivato fino a `raggio` metri.
func _accendi_il_prato(raggio: float, tinta: Color, forza: float) -> void:
	var r := maxf(raggio, 0.01)
	var tremola := 0.8 + 0.2 * sin(_tempo * 1.9) * sin(_tempo * 0.53 + 2.0)
	_chiarore.light_color = tinta
	_chiarore.global_position = _dove + Vector3.UP * (2.0 + r * 0.35)
	_chiarore.omni_range = 6.0 + r * 1.8
	_chiarore.light_energy = CHIARORE * forza * smoothstep(0.0, 6.0, r) * tremola
	_foschia.visible = r > 0.5 and forza > 0.01
	_foschia.global_position = _dove + Vector3.UP * 0.6
	_foschia.size = Vector3(r * 2.2, 2.4, r * 2.2)
	_mat_foschia.density = FOSCHIA * clampf(forza, 0.0, 1.5)
	_mat_foschia.emission = tinta * 0.35 * forza * tremola


static func velocita_partenza() -> float:
	return 2.0 * PARTENZA / ARRIVO - VELOCITA_ARRIVO


## Quanti metri mancano alla buca `t` secondi dopo la partenza: la velocità scende in linea
## retta da quella di partenza a quella d'arrivo, e la strada fatta in `ARRIVO` secondi è
## esattamente `PARTENZA`.
static func strada(t: float) -> float:
	var v0 := velocita_partenza()
	var tt := clampf(t, 0.0, ARRIVO)
	return maxf(PARTENZA - (v0 * tt - (v0 - VELOCITA_ARRIVO) * tt * tt / (2.0 * ARRIVO)), 0.0)


## LA PIETRA IN VOLO, `t` secondi dopo la partenza.
func _vola(t: float) -> void:
	var s := strada(t)
	var dove := _dove + Vector3.UP * _mezza_altezza + _da_dove * s
	# rotola piano su se stessa, come un sasso lanciato
	var giro := Basis.from_euler(Vector3(t * 1.3, t * 0.7, t * 0.4))
	_pietra.global_transform = Transform3D(giro.scaled(Vector3.ONE * SCALA), dove)
	_mat_pietra.set_shader_parameter("calore", 1.0)
	_mat_scia.set_shader_parameter("testa", s)
	var cam := _camera()
	if cam != null:
		_testa = (dove - cam.global_position).normalized()
	# LA TESTA DI LUCE: il metallo e l'aria che bruciano attorno alla pietra. Da lontano è un
	# punto che non scende mai sotto qualche pixel; avvicinandosi cresce.
	_bagliore.visible = true
	_bagliore.global_position = dove
	_mat_bagliore.set_shader_parameter("tinta", Color(1.0, 0.82, 0.55))
	_mat_bagliore.set_shader_parameter("lato", 6.0)
	# TRE GRADI AL MINIMO: più piccolo, a tre chilometri il nucleo stava sotto il pixel e la
	# pietra in arrivo non si vedeva affatto
	_mat_bagliore.set_shader_parameter("minimo", 0.045)
	_mat_bagliore.set_shader_parameter("forza", clampf(pow(2500.0 / maxf(s, 1.0), 0.8), 2.0, 8.0))
	# IL PAESAGGIO SI ACCENDE: da lontano una direzionale che viene da dove sta la pietra, da
	# vicino una luce vera che scende sul prato e muove le ombre
	var vicino := clampf(pow(900.0 / maxf(s, 1.0), 1.5), 0.02, 1.0)
	_lampo.light_color = COLORE_LAMPO
	_lampo.light_energy = LAMPO * vicino * (1.0 - smoothstep(60.0, 20.0, s))
	_lampo.global_basis = Basis.looking_at(-_da_dove, Vector3.UP if absf(_da_dove.y) < 0.99 else Vector3.BACK)
	_luce.global_position = dove
	_luce.light_color = COLORE_LAMPO
	_luce.omni_range = 140.0
	_luce.light_energy = 9.0 * clampf(pow(140.0 / maxf(s, 1.0), 2.0), 0.0, 1.0)


func _impatto() -> void:
	_dall_impatto = 0.0
	_tempo_impatto = _tempo
	# MEZZA SEPOLTA, un po' storta, dove è arrivata
	var storta := Basis.from_euler(Vector3(0.35, 1.9, -0.2))
	_pietra.global_transform = Transform3D(storta.scaled(Vector3.ONE * SCALA),
		_dove + Vector3.UP * _mezza_altezza * (1.0 - 2.0 * SEPOLTA))
	# il solido non si scala: la sua forma è già grande quanto la pietra
	_solido.global_transform = Transform3D(storta, _pietra.global_position)
	_forma_solido.set_deferred("disabled", false)
	_mat_pietra.set_shader_parameter("calore", 1.0)
	_mat_scia.set_shader_parameter("testa", 0.0)
	_buca = BUCA
	_cratere.visible = true
	_polvere.restart()
	_polvere.emitting = true
	_polverone.restart()
	_polverone.emitting = true
	_fumo.emitting = true
	_lampo.light_energy = 0.0
	_luce.global_position = _dove + Vector3.UP * 1.5
	_luce.omni_range = 60.0
	_luce.light_color = Color(1.0, 0.8, 0.55)
	_luce.light_energy = 14.0
	_scossa = 1.0
	_testa = Vector3.ZERO
	Log.debug("orrori", "il colore: la pietra è nel prato")


## IL TERRENO TREMA: la camera di chi guarda si sposta a scatti per un attimo, e torna.
func _trema(delta: float) -> void:
	if _scossa <= 0.0:
		return
	var cam := _camera()
	if cam == null:
		return
	_scossa_camera = cam
	_scossa = maxf(_scossa - delta * 1.3, 0.0)
	var forza := SCOSSA * _scossa * _scossa
	if _scossa <= 0.0:
		forza = 0.0
	cam.h_offset = _rng.randf_range(-1.0, 1.0) * forza
	cam.v_offset = _rng.randf_range(-1.0, 1.0) * forza


func _brilla(delta: float) -> void:
	_dall_impatto += delta
	var t := _dall_impatto
	var dopo := maxf(t - COMPARE, 0.0)
	_raggio = FIN_DOVE * (1.0 - exp(-dopo / ALLARGA_TAU))
	_raggio_preso = maxf(_raggio_preso, _raggio)
	_forza = smoothstep(0.0, SI_ACCENDE_IN, dopo)
	_tende = 0.35 * smoothstep(0.0, SI_TENDE_IN, dopo)
	var calore := exp(-t / CALDA)
	var colore := smoothstep(COMPARE * 0.5, COMPARE + 4.0, t)
	_mat_pietra.set_shader_parameter("calore", calore)
	_mat_pietra.set_shader_parameter("colore", colore)
	# il lampo dell'impatto si allarga e si spegne; la luce torna sulla pietra
	_bagliore.visible = t < 1.5
	_bagliore.global_position = _dove + Vector3.UP * 0.8
	_mat_bagliore.set_shader_parameter("lato", 5.0)
	_mat_bagliore.set_shader_parameter("forza", 8.0 * exp(-t / 0.18))
	_luce.omni_range = lerpf(6.0, 60.0, exp(-t / 0.6))
	_luce.global_position = _dove + Vector3.UP * lerpf(2.6, 1.5, exp(-t / 0.6))
	_fumo.amount_ratio = clampf(calore * 1.4, 0.0, 1.0)
	# prima il calore dell'impatto, poi il colore, fioco e mai fermo
	var tremola := 0.75 + 0.25 * sin(_tempo * 2.3) * sin(_tempo * 0.71 + 1.0)
	# LA LUCE STA SOPRA LA PIETRA, non addosso: a novanta centimetri la bruciava di bianco, e la
	# pietra la sua luce la fa già da sola
	var caldo := 14.0 * exp(-t / 0.25) + 0.5 * calore
	var viola := 0.35 * colore * tremola
	_luce.light_energy = caldo + viola
	_luce.light_color = Color(1.0, 0.55, 0.25).lerp(tinta_del_colore(_tempo), clampf(viola / maxf(caldo + viola, 0.001), 0.0, 1.0))
	_accendi_il_prato(_raggio, tinta_del_colore(_tempo), _forza)


func _scrivi_erba() -> void:
	if _erba == null:
		return
	_erba.set_shader_parameter("colore_dove", DOVE)
	_erba.set_shader_parameter("colore_raggio", _raggio_preso)
	_erba.set_shader_parameter("colore_forza", _forza)
	_erba.set_shader_parameter("colore_tende", _tende)
	_erba.set_shader_parameter("colore_raccolta", _raccolta)
	_erba.set_shader_parameter("colore_cenere", _cenere)
	_erba.set_shader_parameter("colore_buca", _buca)


## Se il nodo se ne va prima di aver finito, il prato non resta acceso né grigio.
func _exit_tree() -> void:
	_raggio_preso = 0.0
	_forza = 0.0
	_tende = 0.0
	_raccolta = 0.0
	_cenere = 0.0
	_buca = 0.0
	_scrivi_erba()
	_spegni_ambiente()
	if _scossa_camera != null and is_instance_valid(_scossa_camera):
		_scossa_camera.h_offset = 0.0
		_scossa_camera.v_offset = 0.0


## IL BAGLIORE E LA NEBBIA DELL'AMBIENTE, accesi finché il colore c'è. L'ambiente è uno solo
## per tutto il gioco (`world/observatory.tscn`): si ricorda com'era e ci si torna.
func _accendi_ambiente() -> void:
	var mondo := get_world_3d()
	_ambiente = mondo.environment if mondo != null else null
	if _ambiente == null:
		var we := trova(get_tree().root, "WorldEnvironment") as WorldEnvironment
		_ambiente = we.environment if we != null else null
	if _ambiente == null:
		push_warning("il colore: non trovo l'ambiente — niente bagliore né foschia")
		return
	for p in AMBIENTE:
		_ambiente_prima[p] = _ambiente.get(p)
	# SOPRA L'UNITÀ, E SOLO LÌ: la notte resta com'è, e sbava solo quello che brilla davvero
	_ambiente.glow_enabled = true
	_ambiente.glow_hdr_threshold = 0.9
	_ambiente.glow_intensity = 1.6
	_ambiente.glow_strength = 1.0
	_ambiente.glow_bloom = 0.0
	_ambiente.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	_ambiente.volumetric_fog_enabled = true
	_ambiente.volumetric_fog_density = 0.0
	_ambiente.volumetric_fog_ambient_inject = 0.0
	_ambiente.volumetric_fog_emission_energy = 0.0
	_ambiente.volumetric_fog_length = 96.0


func _spegni_ambiente() -> void:
	if _ambiente == null:
		return
	for p in _ambiente_prima:
		_ambiente.set(p, _ambiente_prima[p])
	_ambiente_prima.clear()
	_ambiente = null


## LA CENERE PER TERRA: una decalcomania grigia sul prato, col bordo che ha l'erba grigia —
## lo stesso rumore di `colore_fronte.gdshaderinc`, rifatto qui.
func _stendi_la_cenere() -> void:
	var n := 96
	var lato := (_raggio_preso * 1.35 + 1.5) * 2.0
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var q := DOVE + (Vector2(x + 0.5, y + 0.5) / n - Vector2(0.5, 0.5)) * lato
			var a := fronte(q, DOVE, _raggio_preso)
			# una polvere: il granello per texel della prima stesura, da lontano, era ghiaia
			var g := 0.22 + 0.07 * _rumore(q * 1.7) + 0.03 * _rumore(q * 6.0)
			img.set_pixel(x, y, Color(g, g * 0.97, g * 0.92, a * 0.9))
	_cenere_per_terra = Decal.new()
	_cenere_per_terra.name = "Cenere"
	_cenere_per_terra.texture_albedo = ImageTexture.create_from_image(img)
	_cenere_per_terra.size = Vector3(lato, 2.0, lato)
	_cenere_per_terra.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_cenere_per_terra.cull_mask = 1
	# SOLO SUL TERRENO: una decalcomania proietta dall'alto su tutto quello che le sta nella
	# scatola, e il muro di cinta a sei metri si prendeva la polvere a strisce verticali
	_cenere_per_terra.normal_fade = 0.7
	add_child(_cenere_per_terra)
	_cenere_per_terra.global_position = _dove


## LE ZOLLE: la terra che la pietra solleva entrando, scura, che vola e ricade.
func _zolla() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Zolla"
	p.one_shot = true
	p.emitting = false
	p.amount = 320
	p.lifetime = 2.8
	p.explosiveness = 0.97
	p.visibility_aabb = AABB(Vector3(-25.0, -2.0, -25.0), Vector3(50.0, 25.0, 50.0))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 42.0
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 14.0
	pm.gravity = Vector3(0.0, -9.8, 0.0)
	pm.scale_min = 0.5
	pm.scale_max = 2.4
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.6
	var sparisce := CurveTexture.new()
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 1.0))
	curva.add_point(Vector2(0.85, 1.0))
	curva.add_point(Vector2(1.0, 0.0))
	sparisce.curve = curva
	pm.scale_curve = sparisce
	p.process_material = pm
	p.draw_pass_1 = _quadrato_morbido(0.16, Color(0.20, 0.15, 0.11))
	return p


## IL POLVERONE: la terra fine che resta in aria dopo l'impatto, si allarga e si posa piano.
## Non è una luce, è terra: prende la Luna e il rosso della pietra, e copre quello che ha
## dietro.
func _nuvola_di_polvere() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Polverone"
	p.one_shot = true
	p.emitting = false
	p.amount = 48
	p.lifetime = 10.0
	p.explosiveness = 0.92
	p.visibility_aabb = AABB(Vector3(-20.0, -1.0, -20.0), Vector3(40.0, 16.0, 40.0))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 80.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0.0, -0.15, 0.0)
	pm.damping_min = 0.9
	pm.damping_max = 1.6
	pm.scale_min = 0.8
	pm.scale_max = 1.6
	var cresce := CurveTexture.new()
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.35))
	curva.add_point(Vector2(1.0, 1.4))
	cresce.curve = curva
	pm.scale_curve = cresce
	var sfuma := GradientTexture1D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 0.75))
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	sfuma.gradient = g
	pm.color_ramp = sfuma
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.8
	p.process_material = pm
	p.draw_pass_1 = _quadrato_morbido(4.5, Color(0.42, 0.36, 0.30))
	return p


## IL FUMO DELLA PIETRA: finché è calda fuma, sempre meno.
func _fumo_della_pietra() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Fumo"
	p.emitting = false
	p.amount = 70
	p.lifetime = 8.0
	p.visibility_aabb = AABB(Vector3(-12.0, -1.0, -12.0), Vector3(24.0, 25.0, 24.0))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 14.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 1.8
	pm.gravity = Vector3(0.12, 0.2, 0.05)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.8
	pm.turbulence_noise_scale = 3.0
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	var cresce := CurveTexture.new()
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.3))
	curva.add_point(Vector2(1.0, 2.6))
	cresce.curve = curva
	pm.scale_curve = cresce
	var sfuma := GradientTexture1D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 0.5))
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	sfuma.gradient = g
	pm.color_ramp = sfuma
	p.process_material = pm
	p.draw_pass_1 = _quadrato_morbido(1.2, Color(0.46, 0.46, 0.48))
	return p


## IL CRATERE: una decalcomania sul terreno, fatta pixel per pixel. Al centro la terra
## bruciata e scura dove la pietra è entrata, attorno l'anello di terra smossa più chiara, e
## fuori i raggi di terra buttata, che si diradano. Le proporzioni sono quelle dei crateri
## piccoli: il bordo sta a poco più di metà del raggio, i raggi arrivano a due volte.
func _scava_il_cratere() -> Decal:
	var n := 192
	var lato := BUCA * 2.6
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var q := (Vector2(x + 0.5, y + 0.5) / n - Vector2(0.5, 0.5)) * 2.0
			var r := q.length()
			var giro := atan2(q.y, q.x)
			var grana := _rumore(q * 9.0) * 0.6 + _rumore(q * 23.0) * 0.4
			var c := Color(0.0, 0.0, 0.0, 0.0)
			# il fondo bruciato
			var fondo := 1.0 - smoothstep(0.34, 0.46, r + (grana - 0.5) * 0.08)
			# l'anello di terra smossa
			var anello := smoothstep(0.30, 0.44, r) * (1.0 - smoothstep(0.50, 0.66, r + (grana - 0.5) * 0.1))
			# i raggi: bande di terra lungo il giro, che si diradano allontanandosi
			var raggi := smoothstep(0.45, 0.8, _rumore(Vector2(giro * 4.0, 3.0)) * 0.7 + _rumore(Vector2(giro * 13.0, r * 3.0)) * 0.3)
			raggi *= smoothstep(0.5, 0.62, r) * (1.0 - smoothstep(0.62, 1.0, r)) * smoothstep(0.35, 0.6, grana)
			var terra := Color(0.26, 0.21, 0.16).lerp(Color(0.34, 0.28, 0.21), grana)
			var bruciata := Color(0.07, 0.055, 0.045).lerp(Color(0.13, 0.10, 0.08), grana)
			c = terra
			c.a = maxf(anello, raggi * 0.85)
			c = c.lerp(bruciata, fondo)
			c.a = maxf(c.a, fondo * 0.97)
			img.set_pixel(x, y, c)
	var d := Decal.new()
	d.name = "Cratere"
	d.texture_albedo = ImageTexture.create_from_image(img)
	d.size = Vector3(lato, 2.5, lato)
	d.cull_mask = 1
	d.normal_fade = 0.5
	return d


## LA METEORITE: la mesh del modello scansionato, con la sua texture passata allo shader.
func _meteorite(dentro: MeshInstance3D) -> void:
	var scena := load(METEORITE) as PackedScene
	if scena == null:
		push_warning("il colore: manca %s — lancia tools/meteorite_blender.py" % METEORITE)
		var sfera := SphereMesh.new()
		sfera.radius = 0.06
		sfera.height = 0.12
		dentro.mesh = sfera
		var palla := SphereShape3D.new()
		palla.radius = 0.06 * SCALA
		_forma_pietra = palla
		return
	var modello := scena.instantiate()
	var fonte: MeshInstance3D = null
	for n in modello.find_children("*", "MeshInstance3D", true, false):
		fonte = n as MeshInstance3D
		break
	if fonte != null:
		dentro.mesh = fonte.mesh
		var mat := fonte.mesh.surface_get_material(0) as BaseMaterial3D
		if mat != null:
			_mat_pietra.set_shader_parameter("pelle", mat.albedo_texture)
		_mezza_altezza = fonte.mesh.get_aabb().size.y * 0.5 * SCALA
		var involucro := fonte.mesh.create_convex_shape(true, true) as ConvexPolygonShape3D
		var punti := involucro.points
		for k in punti.size():
			punti[k] *= SCALA
		involucro.points = punti
		_forma_pietra = involucro
	modello.free()


## LA SCIA: un nastro lungo tutta la strada, dalla buca al punto di partenza. I pezzi sono più
## fitti vicino alla buca, dove la si guarda da pochi metri, e radi lassù.
func _nastro() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pezzi := 240
	for i in pezzi:
		var a := PARTENZA * pow(float(i) / pezzi, 2.2)
		var b := PARTENZA * pow(float(i + 1) / pezzi, 2.2)
		var pa := _da_dove * a
		var pb := _da_dove * b
		for v in [[pa, a, -1.0], [pb, b, -1.0], [pb, b, 1.0], [pa, a, -1.0], [pb, b, 1.0], [pa, a, 1.0]]:
			st.set_uv(Vector2(v[1], v[2]))
			st.add_vertex(v[0])
	var m := st.commit()
	m.custom_aabb = AABB(Vector3.ONE * -PARTENZA, Vector3.ONE * PARTENZA * 2.0)
	return m


## I FIOCCHI: la cenere che ricade dopo che il colore se n'è andato, lenta, a sbandate.
func _fiocchi_di_cenere() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Fiocchi"
	p.emitting = false
	p.one_shot = true
	p.amount = 500
	p.lifetime = 7.0
	p.explosiveness = 0.85
	p.visibility_aabb = AABB(Vector3(-30.0, -6.0, -30.0), Vector3(60.0, 14.0, 60.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(FIN_DOVE * 0.8, 2.5, FIN_DOVE * 0.8)
	pm.direction = Vector3.DOWN
	pm.spread = 25.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.6
	pm.gravity = Vector3(0.0, -0.35, 0.0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 2.0
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	p.process_material = pm
	p.draw_pass_1 = _quadrato_morbido(0.18, Color(0.55, 0.54, 0.52))
	return p


## Un quadrato che guarda la camera, con una macchia tonda e sfumata dentro.
func _quadrato_morbido(lato: float, tinta: Color) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(lato, lato)
	var macchia := GradientTexture2D.new()
	macchia.fill = GradientTexture2D.FILL_RADIAL
	macchia.fill_from = Vector2(0.5, 0.5)
	macchia.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	macchia.gradient = g
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_color = tinta
	m.albedo_texture = macchia
	m.roughness = 1.0
	q.material = m
	return q


## LA TINTA DEL COLORE A UN ISTANTE, per le luci: il magenta di `colore_tinta`, che scivola
## piano verso il viola e verso il rosa.
static func tinta_del_colore(t: float) -> Color:
	var a := 0.5 + 0.5 * sin(t * 0.37)
	var b := 0.5 + 0.5 * sin(t * 0.23 + 2.0)
	var c := Color(0.92, 0.26, 0.88).lerp(Color(0.52, 0.30, 1.0), a * 0.7)
	return c.lerp(Color(1.0, 0.36, 0.62), b * 0.35)


# --- la copia in GDScript di `colore_fronte.gdshaderinc` ------------------------------

static func _fract(x: float) -> float:
	return x - floor(x)


static func _hash(p: Vector2) -> float:
	var p3 := Vector3(_fract(p.x * 0.1031), _fract(p.y * 0.1031), _fract(p.x * 0.1031))
	var d := p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3.ONE * 33.33)
	p3 += Vector3.ONE * d
	return _fract((p3.x + p3.y) * p3.z)


static func _rumore(x: Vector2) -> float:
	var i := x.floor()
	var f := x - i
	f = f * f * (Vector2(3.0, 3.0) - 2.0 * f)
	return lerpf(lerpf(_hash(i), _hash(i + Vector2(1.0, 0.0)), f.x),
		lerpf(_hash(i + Vector2(0.0, 1.0)), _hash(i + Vector2(1.0, 1.0)), f.x), f.y)


## Fin dove è arrivato il colore: 1 dentro, 0 fuori. La stessa formula dello shader.
static func fronte(q: Vector2, dove: Vector2, raggio: float) -> float:
	if raggio <= 0.0:
		return 0.0
	var n := _rumore(q * 0.45) * 0.65 + _rumore(q * 1.3 + Vector2(17.0, 5.0)) * 0.35
	var r := raggio * (0.45 + 0.85 * n)
	return 1.0 - smoothstep(r - 0.9, r, q.distance_to(dove))


func fase() -> String:
	return Fase.keys()[_fase]


func dove() -> Vector3:
	return _dove


## Da che parte sta la pietra in volo, vista da chi guarda; zero quando è arrivata.
func testa_del_bolide() -> Vector3:
	return _testa


func pietra() -> MeshInstance3D:
	return _pietra


func solido() -> StaticBody3D:
	return _solido


func cratere() -> Decal:
	return _cratere


func raggio() -> float:
	return _raggio_preso


func cenere_per_terra() -> Decal:
	return _cenere_per_terra


## Fin dove è arrivata la colonna, in metri sopra la pietra: resta il massimo.
func colonna_alta() -> float:
	return _colonna_alta


## L'ambiente che l'orrore ha acceso, o null se non l'ha toccato o l'ha già rimesso.
func ambiente_acceso() -> Environment:
	return _ambiente
