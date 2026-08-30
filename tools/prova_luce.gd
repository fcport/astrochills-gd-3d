## Banco degli interruttori: istanzia il blockout headless e prova ogni placca.
##
##     Godot_v4.7.2.exe --headless --script res://tools/prova_luce.gd
##
## PERCHE' NON SI GUARDA E BASTA. Un interruttore che non spegne niente e' invisibile
## finche' non ci si passa davanti e non lo si preme - cioe' mai, se le luci sono
## dieci e le placche sette. E ha trovato subito quello che l'occhio non avrebbe
## trovato: le due placche dello spazio divulgazione, sulle stesse tre lampade,
## andavano fuori fase alla prima pressione (D-059).
##
## Esce con 1 se qualcosa non torna: si puo' mettere in un cancello di verifica.
extends SceneTree

func _initialize() -> void:
	var scena: Node = (load("res://world/blockout.tscn") as PackedScene).instantiate()
	root.add_child(scena)
	var guasti := 0
	var quanti := 0
	for n in scena.get_children():
		if not (n is LightSwitch):
			continue
		quanti += 1
		var sw: LightSwitch = n
		if sw.luci.is_empty():
			print("  %s non comanda niente" % sw.name)
			guasti += 1
			continue
		for p in sw.luci:
			if sw.get_node_or_null(p) == null:
				print("  %s cita %s, che non esiste" % [sw.name, p])
				guasti += 1
		# due scatti: si prova che commuti E che torni indietro. Con una sola
		# pressione una placca fuori fase con l'altra sulle stesse lampade
		# sembrerebbe rotta, o - peggio - sembrerebbe sana scrivendo lo stato
		# che c'era già.
		# l'APPARECCHIO non deve mai sparire: si spegne la lampada, non la si
		# smonta dal soffitto. La prima versione nascondeva il nodo intero.
		var gruppo := sw.get_node(sw.luci[0]).get_parent()
		var corpo: Node3D = gruppo.get_node_or_null("Apparecchio")
		if corpo == null:
			print("  %s: %s non ha un Apparecchio" % [sw.name, gruppo.name])
			guasti += 1
			continue
		var prima: bool = sw.get_node(sw.luci[0]).visible
		sw.interact(null)
		var mezzo: bool = sw.get_node(sw.luci[0]).visible
		sw.interact(null)
		var dopo: bool = sw.get_node(sw.luci[0]).visible
		if not corpo.visible:
			print("  %s: spegnendo sparisce anche l'apparecchio" % sw.name)
			guasti += 1
		if prima == mezzo or dopo != prima:
			print("  %s non commuta: %s -> %s -> %s" % [sw.name, prima, mezzo, dopo])
			guasti += 1
	print("interruttori provati: %d, guasti: %d" % [quanti, guasti])
	quit(1 if guasti > 0 or quanti == 0 else 0)
