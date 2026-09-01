## IL BANCO DELLE MANI: una stanza vuota, delle scatole, e niente altro.
##
## A COSA SERVE, visto che `prova_mani.gd` misura già tutto. A misurare non serve:
## serve a SENTIRE. Il peso di un oggetto, il momento in cui ti resta indietro
## girandoti, quanto è fastidioso che ti copra la vista, se posarlo su un ripiano
## riesce al primo colpo — sono tutte cose che un numero non dice e che si
## decidono con le mani. La sonda dice che la fisica c'è; questo dice se è bella.
##
## LE SCATOLE PESANO DIVERSO APPOSTA, ed è la cosa da provare per prima: mezzo
## chilo, due, sei e quindici. La più leggera segue la testa come se fosse
## incollata, la più pesante resta indietro e la si porta girandosi piano. Il peso
## non è simulato da nessuna parte — è solo il tetto di velocità che scende con la
## massa (vedi `Carryable._velocita_massima`), e basta.
##
## NON STA NEL GIOCO, e non è una dimenticanza. `gen_blockout.py` ha già deciso
## che l'osservatorio non ospita segnaposto grezzi: «fra un posto vuoto e un posto
## occupato male, vuoto legge meglio». Quattro cubi grigi nella stanza computer
## sarebbero esattamente quello. Qui invece i cubi sono la cosa giusta: un banco
## deve essere brutto e sgombro, o si finisce per giudicare l'arredamento.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/banco_mani.tscn
extends Node3D

## Le scatole: lato in metri e massa in chili. Il lato cresce col peso perché una
## cosa pesante e piccola non si legge — sembra leggera e delude quando la
## prendi.
const SCATOLE := [
	{"lato": 0.12, "massa": 0.5, "nome": "la scatoletta"},
	{"lato": 0.20, "massa": 2.0, "nome": "la scatola"},
	{"lato": 0.28, "massa": 6.0, "nome": "la cassetta"},
	{"lato": 0.36, "massa": 15.0, "nome": "il cassone"},
]

const RIPIANO := 0.80


func _ready() -> void:
	_stanza()
	_roba()
	var p := load("res://world/player/player.tscn").instantiate() as Player
	add_child(p)
	p.global_position = Vector3(0.0, 0.1, 2.0)


func _solido(nome: String, centro: Vector3, misura: Vector3, colore: Color) -> void:
	var corpo := StaticBody3D.new()
	corpo.name = nome
	corpo.collision_layer = Interactable.LAYER_WORLD
	var box := BoxShape3D.new()
	box.size = misura
	var forma := CollisionShape3D.new()
	forma.shape = box
	corpo.add_child(forma)
	var mesh := MeshInstance3D.new()
	var cubo := BoxMesh.new()
	cubo.size = misura
	mesh.mesh = cubo
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colore
	mesh.material_override = mat
	corpo.add_child(mesh)
	corpo.position = centro
	add_child(corpo)


func _stanza() -> void:
	_solido("Pavimento", Vector3(0, -0.5, 0), Vector3(12, 1, 12), Color(0.30, 0.29, 0.27))
	# Tre pareti e non quattro: la quarta serve solo a chiudere la vista, e chiusa
	# non si riesce a guardare il banco da fuori quando qualcosa va storto.
	_solido("Nord", Vector3(0, 1.5, -4.0), Vector3(12, 3, 0.12), Color(0.55, 0.54, 0.50))
	_solido("Ovest", Vector3(-4.0, 1.5, 0), Vector3(0.12, 3, 12), Color(0.55, 0.54, 0.50))
	_solido("Est", Vector3(4.0, 1.5, 0), Vector3(0.12, 3, 12), Color(0.55, 0.54, 0.50))
	# IL RIPIANO E' IL BANCO VERO. Prendere una cosa e' facile; POSARLA dove si
	# vuole e' il gesto che dice se il trasporto funziona, e serve un piano
	# all'altezza di un tavolo per provarci.
	_solido("Ripiano", Vector3(0, RIPIANO * 0.5, -2.0), Vector3(2.4, RIPIANO, 0.8),
		Color(0.42, 0.34, 0.26))
	# Un gradino basso: ci si sale sopra e si vede cosa fa un oggetto tenuto in
	# mano quando gli si passa sopra un ostacolo.
	_solido("Gradino", Vector3(2.4, 0.15, 1.0), Vector3(1.2, 0.3, 1.2),
		Color(0.36, 0.35, 0.33))

	var sole := DirectionalLight3D.new()
	sole.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(35.0), 0.0)
	sole.light_energy = 1.1
	sole.shadow_enabled = true
	add_child(sole)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.13, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.47, 0.52)
	env.ambient_light_energy = 0.6
	amb.environment = env
	add_child(amb)


func _roba() -> void:
	var x := -1.0
	for s in SCATOLE:
		var lato: float = s["lato"]
		var o := Carryable.new()
		o.name = "Scatola%d" % roundi(s["massa"] * 10.0)
		o.nome = s["nome"]
		o.mass = s["massa"]
		var box := BoxShape3D.new()
		box.size = Vector3(lato, lato, lato)
		var forma := CollisionShape3D.new()
		forma.shape = box
		o.add_child(forma)
		var mesh := MeshInstance3D.new()
		var cubo := BoxMesh.new()
		cubo.size = Vector3(lato, lato, lato)
		mesh.mesh = cubo
		var mat := StandardMaterial3D.new()
		# Più è pesante più è scura: si vuole poter dire a colpo d'occhio quale si
		# sta guardando senza leggere il prompt.
		var f: float = clampf(1.0 - s["massa"] / 18.0, 0.15, 1.0)
		mat.albedo_color = Color(0.75 * f + 0.12, 0.70 * f + 0.10, 0.62 * f + 0.10)
		mesh.material_override = mat
		o.add_child(mesh)
		add_child(o)
		o.global_position = Vector3(x, RIPIANO + lato * 0.5 + 0.02, -2.0)
		x += lato + 0.45
