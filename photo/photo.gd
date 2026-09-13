## Lo schema del record di una foto: l'unico contratto fra chi la produce (2.4) e
## chi la vende (2.5).
##
## LOGICA PURA. Nessun autoload, nessun nodo: si costruisce un record da un `ctx` e
## una qualità già calcolata, e si risponde alla domanda «c'è una foto in questo
## ctx?». Come `quality.gd`, vive in `photo/` e non conosce la cartella delle fasi
## né quella del mondo: un grep del loro nome qui dentro deve dare zero (confine
## game-architecture.md).
##
## LE CHIAVI SONO COSTANTI, non stringhe sparse. Il record è un `Dictionary` perché
## `NightRun.photos` è `Array[Dictionary]` (dato salvabile, diffabile), ma le chiavi
## vivono qui una volta sola: 2.5 le rileggerà da qui, non le riscriverà a mano.
class_name Photo
extends RefCounted

const KEY_ID := &"id"
const KEY_TARGET := &"target_id"
const KEY_EXPOSURE := &"exposure_sec"
const KEY_FRAMES := &"frame_count"
const KEY_QUALITY := &"quality"

## Le chiavi del `ctx` che segnano la presenza di una foto. `target_id` NON basta:
## lo emette anche il targeting (payload `{target_id}`), e una foto esiste solo
## dopo l'imaging, che aggiunge esposizione e conteggio frame. Richiedere queste
## due — e non `target_id` — è ciò che distingue «ho scelto un bersaglio» da «ho
## scattato» (spec: I/O matrix).
const CTX_EXPOSURE := &"exposure_sec"
const CTX_FRAMES := &"frame_count"

## La chiave del `ctx` per il bersaglio: la stessa stringa di `KEY_TARGET`, ma
## nominata come chiave d'INGRESSO. Non basta a dire che c'è una foto (vedi
## `is_photo`), ma quando la foto c'è il suo nome si legge da qui — nessuna stringa
## sparsa: le chiavi vivono in un posto solo.
const CTX_TARGET := &"target_id"

## Le soglie del LIVELLO DELL'IMMAGINE: sotto 50 la foto è la più rovinata delle tre, da 80
## in su la più pulita. Sono quelle del prototipo Phaser (`src/util/photos.js`,
## `stackTier`), che ha fatto le tre versioni di ogni soggetto su queste soglie:
## cambiarle qui vorrebbe dire usare le immagini con un criterio diverso da quello con
## cui sono state fatte.
const IMAGE_TIER_2 := 50
const IMAGE_TIER_3 := 80


## Quale delle tre immagini di un soggetto corrisponde a una qualità: 1, 2 o 3.
##
## NON È LO SCAGLIONE DEL PAGAMENTO, e la confusione è facile perché in inglese si
## chiamano tutti e due «tier». `Tuning.payout_tiers` ha cinque gradini tarabili e decide
## le lire; questo ne ha tre fissi e decide quale pagina esce dalla stampante (D-239).
## Vive qui perché «score → tier» è di `photo/` (tabella dei confini), e il mondo che
## stampa non può leggerlo: glielo si passa già deciso.
static func image_tier(quality: int) -> int:
	if quality >= IMAGE_TIER_3:
		return 3
	if quality >= IMAGE_TIER_2:
		return 2
	return 1


## Vero se nel `ctx` c'è una foto scattata: servono ESPOSIZIONE e CONTEGGIO FRAME.
##
## È il DATO a dire che c'è una foto, non il nome di una fase (spec: l'orchestratore
## non nomina l'imaging). Il ciclo che si esaurisce senza aver scattato — solo
## setup, o `photo_phases` vuoto — non lascia queste chiavi, e `is_photo` è false.
static func is_photo(ctx: Dictionary) -> bool:
	return ctx.has(CTX_EXPOSURE) and ctx.has(CTX_FRAMES)


## Costruisce il record dal `ctx`, dalla qualità aggregata e dall'indice.
##
## L'`id` deriva dall'indice della foto nella notte (`run.photos.size()` al momento
## della registrazione): un numero progressivo, stabile e senza collisioni finché
## si aggiunge in coda. Non è un UUID — l'MVP non ne ha bisogno, e un numero è
## leggibile nel `.tres` salvato.
##
## `target_id` PUÒ ESSERE VUOTO (DW-3): se si scatta senza aver scelto un bersaglio
## il ctx non porta `target_id`, e il record lo registra come stringa vuota invece
## di rompersi. La 2.5 deciderà cosa mostrare per una foto senza nome; qui si
## garantisce solo che il record esista e sia ben formato.
static func from_ctx(ctx: Dictionary, quality: int, index: int) -> Dictionary:
	return {
		KEY_ID: index,
		KEY_TARGET: String(ctx.get(CTX_TARGET, "")),
		KEY_EXPOSURE: int(ctx.get(CTX_EXPOSURE, 0)),
		KEY_FRAMES: int(ctx.get(CTX_FRAMES, 0)),
		KEY_QUALITY: quality,
	}
