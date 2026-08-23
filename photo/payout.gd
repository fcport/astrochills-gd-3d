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
## `tiers` è un array di `{min_score, lire}` ordinato per `min_score` crescente:
## l'ultimo scaglione superato vince. `0` su array vuoto — come `quality.aggregate`
## su dizionario vuoto: nessuna curva non è payout zero mentito, è assenza di dati,
## e non si inventa un numero.
func tier_payout(quality: int, tiers: Array) -> int:
	var lire := 0
	for t in tiers:
		if quality >= int(t.get(&"min_score", 0)):
			lire = int(t.get(&"lire", 0))
	return lire


## Applica il moltiplicatore del committente al payout base, arrotondando.
##
## `round` e non `floor`: 3500×1.4 = 4900 esatto, ma 3500×0.6 = 2100 e un floor su un
## prodotto float darebbe 2099 per un errore di rappresentazione. `int(round(...))`
## è l'aritmetica che l'I/O matrix della spec attende.
func apply_multiplier(base: int, mult: float) -> int:
	return int(round(base * mult))


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
