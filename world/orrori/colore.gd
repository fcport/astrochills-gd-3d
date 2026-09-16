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
##   1. IL BOLIDE, davanti a chi guarda: una testa verdastra con la scia arancio, corta perché
##      viene verso di te, che cresce e scoppia in un lampo che accende il prato; dopo, per
##      qualche secondo, resta la traccia. (`world/shaders/orrore_bolide.gdshader`)
##   2. IL VOLO BUIO: un sasso che ha smesso di bruciare cade per qualche secondo senza luce.
##      Poi colpisce il prato, a una dozzina di metri dalla porta: una zolla di terra per
##      aria, l'erba schiacciata, la pietra mezza sepolta e calda.
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
## NIENTE SUONO, e non per dimenticanza: il progetto non tiene suoni sintetizzati, e il
## tonfo di una pietra non si inventa.
class_name OrroreColore
extends Orrore

const SHADER_BOLIDE := "res://world/shaders/orrore_bolide.gdshader"
const SHADER_BAGLIORE := "res://world/shaders/orrore_bagliore.gdshader"
const SHADER_PIETRA := "res://world/shaders/orrore_pietra.gdshader"
const SHADER_COLONNA := "res://world/shaders/orrore_colonna.gdshader"

## Dove cade, in pianta: una dozzina di metri dalla porta, nel prato, lontano dall'auto e
## dall'asse su cui scende il tentacolo.
const DOVE := Vector2(1.5, 20.5)

## IL BOLIDE: da dove a dove passa nel cielo di chi guarda (gradi di azimut in più rispetto a
## dove guarda, gradi d'altezza), in quanto tempo, quanto dura la traccia dopo.
const BOLIDE_DA := Vector2(26.0, 42.0)
const BOLIDE_A := Vector2(8.0, 24.0)
const BOLIDE_DURA := 3.0
const TRACCIA_DURA := 3.5
## Quanta luce fa il lampo sul prato, al massimo: più della Luna piena.
const LAMPO := 2.4
const COLORE_LAMPO := Color(0.82, 1.0, 0.86)

## Il volo buio, dal lampo all'impatto.
const VOLO := 2.4

## L'impatto: quanto erba schiaccia, per quanto la pietra resta calda.
const BUCA := 0.8
const CALDA := 3.0

## IL COLORE NELL'ERBA: dopo quanto dall'impatto compare, fin dove arriva e con che passo —
## si avvicina a `FIN_DOVE` metri senza arrivarci —, in quanto si accende, in quanto i ciuffi
## si tendono.
const COMPARE := 3.0
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

enum Fase { CADE, VOLA, BRILLA, SI_RACCOGLIE, SALE, CENERE, TORNA }

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

var _cielo: MeshInstance3D
var _mat_cielo: ShaderMaterial
var _testa := Vector3.UP
var _lampo: DirectionalLight3D
var _pietra: MeshInstance3D
var _mat_pietra: ShaderMaterial
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
		suolo = prato.position.y + FormaPrato.altezza(DOVE, prato.piatti, prato.recinto)
		var erba := prato.get_node_or_null("Erba") as GeometryInstance3D
		_erba = erba.material_override as ShaderMaterial if erba != null else null
	if _erba == null:
		push_warning("il colore: nel prato non c'è erba da accendere")
	_dove = Vector3(DOVE.x, suolo, DOVE.y)

	var az0 := azimut_di(_davanti())
	_mat_cielo = ShaderMaterial.new()
	_mat_cielo.shader = load(SHADER_BOLIDE) as Shader
	_mat_cielo.set_shader_parameter("inizio", verso(az0 + BOLIDE_DA.x, BOLIDE_DA.y))
	_mat_cielo.set_shader_parameter("fine", verso(az0 + BOLIDE_A.x, BOLIDE_A.y))
	_cielo = _cupola("Bolide", _mat_cielo)
	_cielo.top_level = true

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
	_pietra.mesh = _sasso()
	_pietra.material_override = _mat_pietra
	_pietra.visible = false
	add_child(_pietra)
	_pietra.global_position = _dove + Vector3.UP * 0.05

	_polvere = _zolla()
	add_child(_polvere)
	_polvere.global_position = _dove + Vector3.UP * 0.1

	_luce = OmniLight3D.new()
	_luce.name = "Luce"
	_luce.light_energy = 0.0
	_luce.omni_range = 5.0
	_luce.shadow_enabled = false
	add_child(_luce)
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
	_bolide(0.0)
	Log.debug("orrori", "il colore: cade una pietra in (%.1f, %.1f)" % [DOVE.x, DOVE.y])


func _congeda() -> void:
	# se il colore non è ancora nell'erba, si aspetta che la pietra cada
	if _fase == Fase.BRILLA:
		_vai(Fase.SI_RACCOGLIE)


func _avanza(delta: float) -> void:
	_t_fase += delta
	var cam := _camera()
	if cam != null:
		_cielo.global_position = cam.global_position
	var tinta := tinta_del_colore(_tempo)
	match _fase:
		Fase.CADE:
			_bolide(_t_fase / BOLIDE_DURA)
			if _t_fase >= BOLIDE_DURA:
				_mat_cielo.set_shader_parameter("luce", 0.0)
				_mat_cielo.set_shader_parameter("scia", 0.0)
				_lampo.light_energy = 0.0
				_vai(Fase.VOLA)
		Fase.VOLA:
			_traccia(_t_fase)
			if _t_fase >= VOLO:
				_impatto()
				_vai(Fase.BRILLA)
				if _in_uscita:
					_vai(Fase.SI_RACCOGLIE)
		Fase.BRILLA:
			_traccia(VOLO + _t_fase)
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
			_pietra.scale = Vector3.ONE * maxf(_cenere, 0.01)
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


## Il bolide alla frazione `f` della sua strada.
func _bolide(f: float) -> void:
	var t := clampf(f, 0.0, 1.0)
	# CRESCE, E ALLA FINE SCOPPIA
	var scoppio := exp(-pow((t - 0.93) / 0.045, 2.0))
	_mat_cielo.set_shader_parameter("testa", t)
	_mat_cielo.set_shader_parameter("luce", 0.35 + 1.6 * t * t + 5.0 * scoppio)
	_mat_cielo.set_shader_parameter("scia", 0.6 + 1.0 * t)
	_mat_cielo.set_shader_parameter("traccia", smoothstep(0.3, 0.95, t))
	var a := (_mat_cielo.get_shader_parameter("inizio") as Vector3)
	var b := (_mat_cielo.get_shader_parameter("fine") as Vector3)
	_testa = a.slerp(b, t).normalized()
	# IL LAMPO ACCENDE IL PRATO: una luce che arriva da dove sta la testa, e che cresce con lei
	_lampo.light_energy = LAMPO * (0.08 * t + scoppio)
	_lampo.global_basis = Basis.looking_at(-_testa, Vector3.UP if absf(_testa.y) < 0.99 else Vector3.BACK)


## La traccia che resta dopo, `t` secondi dopo lo scoppio.
func _traccia(t: float) -> void:
	var resta := exp(-t / TRACCIA_DURA * 3.0)
	_mat_cielo.set_shader_parameter("traccia", resta)
	_cielo.visible = resta > 0.01


func _impatto() -> void:
	_dall_impatto = 0.0
	_pietra.visible = true
	_mat_pietra.set_shader_parameter("calore", 1.0)
	_buca = BUCA
	_polvere.restart()
	_polvere.emitting = true
	_polverone.restart()
	_polverone.emitting = true
	_luce.light_color = Color(1.0, 0.55, 0.25)
	_luce.light_energy = 3.0
	Log.debug("orrori", "il colore: la pietra è nel prato")


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
	# prima il calore dell'impatto, poi il colore, fioco e mai fermo
	var tremola := 0.75 + 0.25 * sin(_tempo * 2.3) * sin(_tempo * 0.71 + 1.0)
	var caldo := 3.0 * exp(-t / 0.35) + 0.3 * calore
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


## LA ZOLLA: la terra che la pietra solleva entrando. Poca, scura, e ricade.
func _zolla() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Zolla"
	p.one_shot = true
	p.emitting = false
	p.amount = 90
	p.lifetime = 1.6
	p.explosiveness = 0.96
	p.visibility_aabb = AABB(Vector3(-6.0, -1.0, -6.0), Vector3(12.0, 10.0, 12.0))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 38.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 6.5
	pm.gravity = Vector3(0.0, -9.8, 0.0)
	pm.scale_min = 0.5
	pm.scale_max = 1.4
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.25
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(0.20, 0.16, 0.12)
	m.roughness = 1.0
	q.material = m
	p.draw_pass_1 = q
	return p


## IL POLVERONE: la terra fine che resta in aria dopo l'impatto, e si allarga piano.
func _nuvola_di_polvere() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Polverone"
	p.one_shot = true
	p.emitting = false
	p.amount = 28
	p.lifetime = 4.0
	p.explosiveness = 0.9
	p.visibility_aabb = AABB(Vector3(-8.0, -1.0, -8.0), Vector3(16.0, 8.0, 16.0))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 2.2
	pm.gravity = Vector3(0.0, -0.3, 0.0)
	pm.damping_min = 0.8
	pm.damping_max = 1.4
	pm.scale_min = 0.8
	pm.scale_max = 1.6
	var cresce := CurveTexture.new()
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.35))
	curva.add_point(Vector2(1.0, 1.0))
	cresce.curve = curva
	pm.scale_curve = cresce
	var sfuma := GradientTexture1D.new()
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 0.55))
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	sfuma.gradient = g
	pm.color_ramp = sfuma
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.4
	p.process_material = pm
	p.draw_pass_1 = _quadrato_morbido(1.4, Color(0.30, 0.26, 0.22))
	return p


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


## UN SASSO, non una palla: una sfera spostata dal rumore, larga una trentina di centimetri,
## mezza nel terreno.
func _sasso() -> ArrayMesh:
	var sfera := SphereMesh.new()
	sfera.radius = 0.17
	sfera.height = 0.28
	sfera.radial_segments = 18
	sfera.rings = 10
	var arr := sfera.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var rumore := FastNoiseLite.new()
	rumore.seed = 1882
	rumore.frequency = 5.0
	for i in v.size():
		v[i] = v[i] * (1.0 + 0.32 * rumore.get_noise_3dv(v[i]))
	arr[Mesh.ARRAY_VERTEX] = v
	var st := SurfaceTool.new()
	st.create_from_arrays(arr, Mesh.PRIMITIVE_TRIANGLES)
	st.generate_normals()
	return st.commit()


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


## Dove sta la testa del bolide, come verso del cielo.
func testa_del_bolide() -> Vector3:
	return _testa


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
