## La commessa di una notte: quale committente, con quale moltiplicatore, per quale
## soggetto. Determinata all'inizio della notte e conservata su `NightRun`.
##
## LOGICA PURA (come `photo/quality.gd` e `photo/payout.gd`). Nessun autoload,
## nessun nodo: si costruisce la scelta da un array di `ClientData` e un indice di
## notte, senza SceneTree. Restituisce un `Dictionary` — dato salvabile, diffabile,
## il gemello di `Photo.from_ctx()` — così `NightRun.commission` è persistibile senza
## dipendere da un tipo di risorsa nel save (la 2.7 lo raccoglie così com'è).
##
## DOVE VIVE, E PERCHÉ QUI. La vendita vive in `photo/`; la cartella delle fasi non la
## conosce.
## Le CHIAVI sono costanti, non stringhe sparse: chi legge la commessa (la schermata
## di vendita, l'orchestratore) le rilegge da qui.
class_name Commission
extends RefCounted

const CLIENT_NAME := &"client_name"
const MULTIPLIER := &"multiplier"
const TARGET_ID := &"target_id"


## Sceglie la commessa della notte fra i committenti ABILITATI, in modo
## DETERMINISTICO da `night_index`.
##
## `enabled[(night_index - 1) % enabled.size()]`: la notte 1 prende il primo
## abilitato, la 2 il secondo, e così via a rotazione. Deterministico e senza RNG —
## il collaudo può prevederlo e `privato_g` (disabilitato) non entra mai nel filtro,
## quindi non viene mai scelto.
##
## `{}` se nessun abilitato (roster assente, vuoto, o tutti disabilitati): ogni
## vendita andrà a base ×1.0, senza commessa applicabile. È il ripiego cortese,
## non un crash — il chiamante avvisa su canale 1 e prosegue.
static func choose(clients: Array, night_index: int) -> Dictionary:
	var enabled: Array = []
	for c in clients:
		if c != null and c.enabled:
			enabled.append(c)
	if enabled.is_empty():
		return {}
	var picked = enabled[(night_index - 1) % enabled.size()]
	return {
		CLIENT_NAME: picked.name,
		MULTIPLIER: picked.multiplier,
		TARGET_ID: picked.wanted_target,
	}


## La commessa è applicabile a QUESTA foto: true solo se c'è una commessa, la foto ha
## un nome, e quel nome è esattamente il soggetto richiesto.
##
## UNICA SORGENTE DI VERITÀ. La schermata di vendita e l'orchestratore CHIAMANO questo
## metodo — non ne duplicano la logica inline — così il banco prova la regola vera. Una
## foto senza nome (DW-3, `target_id` vuoto) non è mai applicabile, nemmeno contro una
## commessa dal target anch'esso vuoto: il vuoto non combacia col vuoto.
static func applies_to(target_id: StringName, commission: Dictionary) -> bool:
	if commission.is_empty() or target_id.is_empty():
		return false
	return target_id == StringName(commission.get(TARGET_ID, &""))
