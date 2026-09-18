## LE PORTE INTERNE, per GUARDARLE. Il battente tamburato (`porte_legno_blender.py`)
## passa tutti i controlli di misura anche montato al rovescio, con la maniglia sul
## lato del cardine o con una faccia nera: sono cose che dice solo un'immagine.
##
##     Godot_v4.7.2-stable_win64.exe --path . tools/scatta_porte.tscn
##
## SENZA `--headless`: lo scatto vuole la finestra. Per ogni porta tamburata salva
## `user://porta_<nome>_<lato>.png` da UN METRO E OTTANTA davanti a tutte e due le
## facce, chiusa, e `user://porta_<nome>_aperta.png` aperta, attraverso il vano.
## Una scena e non uno `--script`, come `scatta_soglie.gd`.
extends Node

## Quelle di `PORTE_TAMBURATE` in `geometria.py`, col nome che il generatore da' al nodo.
const PORTE := ["Porta_cucina", "Porta_corridoio_a_spazio", "Porta_pc_a_corridoio",
		"Porta_bagno", "Porta_disimpegno"]

## Meta' della luce di un'anta interna: il centro della porta sta qui, dal cardine.
const MEZZA_ANTA := 0.45

const DISTANZA := 1.8


func _ready() -> void:
	_scatta.call_deferred()


func _scatta() -> void:
	var scena: Node = load("res://world/blockout.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	var giocatore := scena.get_node_or_null("Player")
	if giocatore != null:
		giocatore.queue_free()
	var cam := Camera3D.new()
	cam.fov = 60.0
	scena.add_child(cam)
	cam.current = true
	for _i in 30:
		await get_tree().physics_frame
	_accendi_tutto(get_tree().root)
	for nome in PORTE:
		var porta := scena.get_node_or_null(nome) as Door
		if porta == null:
			print("[scatto] MANCA %s" % nome)
			continue
		porta.set_open(false, true)
		var t := porta.global_transform
		var centro := t.origin + t.basis.x * MEZZA_ANTA + Vector3(0.0, 1.05, 0.0)
		# LA MANIGLIA SI ABBASSA: quante leve ha trovato la porta, e di quanto scende
		# la punta del braccio premuto in fondo. Il verso giusto si legge dal segno:
		# una leva che gira al contrario SALE, e il numero esce negativo.
		var leve := porta.find_children("Leva*", "MeshInstance3D", true, false)
		var discese: Array[String] = []
		for n in leve:
			var su := _punta(n as MeshInstance3D)
			porta._posa_leve(1.0)
			var giu := _punta(n as MeshInstance3D)
			porta._posa_leve(0.0)
			discese.append("%.1f" % ((su.y - giu.y) * 100.0))
		print("[scatto] %s: %d leve, la punta scende di %s cm"
				% [nome, leve.size(), ", ".join(discese)])
		if nome == PORTE[0] and not leve.is_empty():
			var leva := leve[0] as Node3D
			var lato := signf((leva.global_position - t.origin).dot(t.basis.z))
			var vicino := leva.global_position + t.basis.z * lato * 0.55 \
					+ t.basis.x * 0.2 + Vector3(0.0, 0.12, 0.0)
			var mira := leva.global_position - t.basis.x * 0.06
			await _foto(cam, vicino, mira, "porta_%s_leva_su" % nome.trim_prefix("Porta_"))
			porta._posa_leve(1.0)
			await _foto(cam, vicino, mira, "porta_%s_leva_giu" % nome.trim_prefix("Porta_"))
			porta._posa_leve(0.0)
		for lato: float in [1.0, -1.0]:
			var da := centro + t.basis.z * DISTANZA * lato + Vector3(0.0, 0.55, 0.0)
			await _foto(cam, da, centro, "porta_%s_%s" % [nome.trim_prefix("Porta_"),
					"piu" if lato > 0.0 else "meno"])
		porta.set_open(true, true)
		# a porta aperta si guarda DAL LATO DA CUI SI SPINGE, attraverso il vano: e'
		# lo stesso punto delle foto a porta chiusa, che c'e' per tutte e cinque. Dal
		# lato verso cui si apre la camera finiva dentro un muro nelle stanze strette -
		# il disimpegno e la sala del pc davano un'immagine nera.
		var dentro := -t.basis.z * float(porta.verso)
		var da2 := centro - dentro * DISTANZA + Vector3(0.0, 0.55, 0.0)
		await _foto(cam, da2, centro + dentro * 0.6, "porta_%s_aperta" % nome.trim_prefix("Porta_"))
		porta.set_open(false, true)
	get_tree().quit()


func _foto(cam: Camera3D, da: Vector3, verso: Vector3, nome: String) -> void:
	cam.global_position = da
	cam.look_at(verso, Vector3.UP)
	for _i in 12:
		await get_tree().process_frame
	var fuori := "user://%s.png" % nome
	get_tree().root.get_texture().get_image().save_png(fuori)
	print("[scatto] salvato %s" % ProjectSettings.globalize_path(fuori))


## La punta del braccio in coordinate del mondo: l'estremo della leva lontano
## dall'asse, che sta nell'origine del nodo.
func _punta(m: MeshInstance3D) -> Vector3:
	var bb := m.get_aabb()
	var x := bb.position.x if absf(bb.position.x) > absf(bb.end.x) else bb.end.x
	return m.global_transform * Vector3(x, bb.get_center().y, bb.get_center().z)


func _accendi_tutto(n: Node) -> void:
	if n.name == "Accesa" and n is Node3D:
		(n as Node3D).visible = true
	for f in n.get_children():
		_accendi_tutto(f)
