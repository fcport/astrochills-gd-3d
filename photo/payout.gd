## Il payout di una foto: dallo scaglione della qualità alle lire, poi il moltiplicatore.
##
## LOGICA PURA (come `photo/quality.gd`). Nessun autoload, nessun nodo, nessun
## viewport: si costruisce con `PhotoPayout.new()` in un test senza SceneTree. Legge
## numeri e array e restituisce interi, niente altro. Le MUTAZIONI di `Game.run` e le
## emissioni su `Events` restano nell'orchestratore — qui non si tocca lo stato.
##
## DOVE VIVE, E PERCHÉ QUI. La tabella dei confini (game-architecture.md) mette
## «score → stack → tier → vendita» in `photo/`, e vieta alla cartella delle fasi di
## conoscerla.
## La curva è un DATO: arriva da `Tuning.payout_tiers`, mai `load()` diretto, mai una
## `const` d'economia sparsa nel codice. Questo file NON legge il tuning — lo riceve
## come argomento, così resta puro e collaudabile.
class_name PhotoPayout
extends RefCounted


## Lo scaglione più alto la cui soglia `min_score` è raggiunta dalla qualità.
##
## `0` su array vuoto — come `quality.aggregate` su dizionario vuoto: nessuna curva
## non è payout zero mentito, è assenza di dati, e non si inventa un numero.
##
## NON SI ASSUME L'ORDINE. La versione precedente scorreva l'array tenendo l'ultimo
## scaglione superato, il che dà il risultato giusto solo se le soglie sono crescenti
## — e `payout_tiers` è un `@export` in un `.tres` che si riordina trascinando una
## riga nell'inspector. Bastava spostare `{min_score: 0, lire: 500}` in fondo perché
## OGNI foto, qualità 100 compresa, valesse 500 lire senza un errore da nessuna parte.
## Qui la soglia più alta si cerca confrontandola, non fidandosi della posizione.
func tier_payout(quality: int, tiers: Array) -> int:
	var lire := 0
	var best := -1
	for t in tiers:
		var min_score := int(t.get(&"min_score", 0))
		if quality >= min_score and min_score > best:
			best = min_score
			lire = int(t.get(&"lire", 0))
	return lire


## Applica il moltiplicatore del committente al payout base, arrotondando.
##
## `round` e non `floor`: su un prodotto float un troncamento può restituire l'intero
## precedente per un errore di rappresentazione, e su un prezzo si vede. (Il commento
## precedente citava 3500×0.6 → 2099 come esempio: verificato in doppia precisione,
## quel prodotto vale 2100.0 esatto e anche il floor darebbe 2100. La scelta di
## `round` resta giusta, l'esempio no.)
##
## `maxi(0, ...)`: il payout non scende MAI sotto zero. `multiplier` è un `@export`
## float in un `.tres` scritto a mano, dichiarato segnaposto e destinato a essere
## tarato: un `-0.6` battuto al posto di `0.6` toglierebbe lire dal portafoglio, in un
## gioco che per NFR20 non punisce mai. Accettare una commessa non può costare denaro.
func apply_multiplier(base: int, mult: float) -> int:
	return maxi(0, int(round(base * mult)))


## Le lire di UNA vendita: `apply_multiplier(base, mult)` se la commessa è accettata
## (FULFILL), altrimenti il base ×1.0.
##
## UNICA SORGENTE DI VERITÀ. L'orchestratore CHIAMA questo metodo per comporre il
## payout — non ha un ramo `if fulfill` proprio — così il banco prova la logica vera,
## non una copia. Il rifiuto NON è un ramo che sottrae: paga il base come chi non aveva
## commessa (NFR20), ed è per questo che qui `fulfill = false` restituisce `base` secco
## invece di `apply_multiplier(base, 1.0)` — nessuna aritmetica dove non serve.
func sale_lire(base: int, mult: float, fulfill: bool) -> int:
	if fulfill:
		return apply_multiplier(base, mult)
	return base
