---
title: 'Storia 2.5: Qualcuno la compra, e paga subito'
type: 'feature'
created: '2026-08-23'
status: 'done'
baseline_revision: '45cfd90cf936c0d97838a48e8904c63de76e54cd'
review_loop_iteration: 0
followup_review_recommended: false
context: []
warnings: ['oversized']
deferred:
  - summary: >-
      Il flusso di vendita non ha copertura automatica: la composizione in
      _on_sale_confirmed (credito wallet_lire + emissione photo_sold), la logica UI di
      photo_sale (_fulfill_options, _declined / "declined — no harm") e il routing input
      via SubViewport del CRT sono verificati solo da un playthrough interattivo, non
      ancora eseguito.
    evidence: |-
      Il banco (NFR19) prova solo logica pura senza SceneTree: sale_lire/applies_to/
      tier_payout sono coperti, ma la glue stateful e il Control non ospitato no.
      Rispecchia DW-2 (stessa lacuna per il flusso imaging della 2.3). Una regressione
      (chiave mult errata, credito omesso, emissione pre-moltiplicatore, ordine
      _fulfill_options invertito) lascerebbe il banco verde.
    location: >-
      night/night_session.gd:_on_sale_confirmed, night/photo_sale.gd
    severity: medium
  - summary: >-
      Events.photo_sold emette come photo_id l'indice per-notte del record
      (Photo.KEY_ID) coercito a StringName: due foto di notti diverse condividono
      l'indice 0, quindi l'id è ambiguo per un aggregatore cross-notte (il collettore di
      save della 2.7).
    evidence: |-
      night_session._on_sale_confirmed fa
      Events.photo_sold.emit(StringName(str(_sale_photo_id)), lire); _sale_photo_id =
      record[Photo.KEY_ID] = indice in run.photos. L'MVP non ne ha bisogno, ma va
      ricordato per la 2.7.
    location: >-
      night/night_session.gd:_on_sale_confirmed
    severity: low
---

<intent-contract>

## Intent

**Problem:** Il ciclo notturno arriva fino allo stack (2.4) e poi si ferma: una foto viene rivelata ma non produce nulla, il portafoglio resta a zero e `Events.photo_sold` non viene mai emesso. Manca l'anello che chiude il valore di ogni scatto — la vendita per-foto, immediata, con la commessa di un committente che può essere rifiutata senza conseguenze.

**Approach:** Dopo la rivelazione dello stack, l'orchestratore mostra sul CRT un'**interfaccia di vendita** (un `Control` di `night/`, come lo stacking): calcola il payout da una curva a scaglioni sul punteggio aggregato, applica il moltiplicatore del committente **solo se il giocatore accetta la commessa**, accredita le lire sul portafoglio ed emette `Events.photo_sold`. La commessa (un committente + il soggetto richiesto + il moltiplicatore) è **determinata all'inizio della notte** e vive sulla `NightRun`. Curva e moltiplicatori stanno in `data/`, dichiarati segnaposto (FR22).

## Boundaries & Constraints

**Always:**
- La vendita è un `Control` di `night/` mostrato dall'orchestratore col pattern di `stacking_reveal`/`night_summary` (UX-DR1, UX-DR10): sullo schermo del mondo, **non** un popup di gioco sopra la scena. Il CRT non libera mai ciò che mostra; lo libera chi lo possiede (l'orchestratore).
- Payout **immediato e per-foto**: accreditato al momento della vendita di *quella* foto su `Game.run.wallet_lire`, non aggregato di fine notte.
- La logica economica pura (`photo/payout.gd`, `photo/commission.gd`) vive in `photo/` e si costruisce senza `SceneTree` (come `photo/quality.gd`): niente autoload, niente nodi, niente viewport. Le mutazioni di `Game.run` e le emissioni su `Events` restano nell'orchestratore.
- Curva a scaglioni in `data/tuning.tres`, letta **sempre** da `Tuning.payout_tiers` (mai `load()` diretto). Moltiplicatori nei `.tres` dei committenti in `data/clients/`. Entrambi con commento «SEGNAPOSTO (FR22): non tarare».
- Rifiutare la commessa non produce **nessuna** conseguenza: paga il base (×1.0), nessuna penalità, nessuna traccia differita. Il «niente» è reso percepibile a schermo (una riga gentile, tono cozy — NFR20).
- `privato_g` resta **disabilitato** (`enabled = false` nel suo `.tres`): esiste come file ma la selezione lo esclude.
- Testo dell'interfaccia in **inglese** (interfaccia software); disegnata per 256×192 coi colori del fosforo, come gli altri Control del CRT.
- Signal tipizzati, `snake_case` al passato (NFR22). Nessuno `push_error`/stack trace mostrato al giocatore (canale 1 vs canale 2 non si mescolano).

**Block If:**
- Nessuna condizione di blocco prevista: l'intento è risolto. (La vendita non dipende dal terminale gestionale dell'epica 3, e non richiede la persistenza cross-notte della 2.7.)

**Never:**
- Non toccare `Game.start_night()`/`end_night()` per la persistenza cross-notte: è la 2.7 (fuori scopo). Qui il portafoglio esiste già su `NightRun`.
- Non introdurre il menu post-foto (scatta ancora / cambia target / rifai setup / chiudi ed esplora): è la 2.6. Dopo la vendita la schermata «SOLD» resta e il giocatore si rialza con `E`, come oggi resta lo stack.
- Non far conoscere `phases/` a `photo/` o `night/`-sale: nessuna fase importa la vendita; nessun file di `phases/` cambia.
- Non calibrare i numeri (curva, moltiplicatori): sono segnaposto dichiarati (FR22).
- Non mostrare il payout come modale di gioco né fuori dal CRT.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Vendita senza commessa applicabile | foto stackata, `commission.target_id` ≠ target foto | schermata mostra il base; alla conferma `wallet_lire += base`, `photo_sold(id, base)`, «SOLD» a schermo | — |
| Vendita con commessa, accettata | target foto = `commission.target_id`, scelta FULFILL | `lire = round(base * mult)`, accredito + `photo_sold(id, lire)` | — |
| Vendita con commessa, rifiutata | target foto = `commission.target_id`, scelta SELL OPEN | `lire = base` (×1.0), accredito + `photo_sold(id, base)`, riga gentile «declined — no harm», nessuna penalità | — |
| Foto senza nome (DW-3) | `target_id` vuoto nel record | nessuna commessa applicabile → vendita a base; target mostrato come «UNTITLED» | non si rompe; nessun `push_error` diegetico |
| Curva a scaglioni | quality ai bordi 0/29/30/49/50/74/75/89/90/100 | lire = scaglione corretto (500/1500/3500/7000/15000 coi valori segnaposto) | — |
| Moltiplicatore | base=3500, mult=0.6 / 1.4 | 2100 / 4900 (round) | — |
| Selezione commessa | notte N, roster con 3 abilitati + `privato_g` disabilitato | un committente abilitato scelto in modo deterministico da `night_index`; `privato_g` mai scelto | — |
| Roster assente/vuoto | `data/clients/roster.tres` mancante o senza abilitati | `commission = {}`; ogni vendita a base ×1.0; nessun crash | warn su canale 1, il gioco prosegue |
| Curva assente/vuota | `Tuning.payout_tiers` vuoto | `tier_payout` restituisce 0 (come `quality` su vuoto), non inventa un numero | warn su canale 1 |

</intent-contract>

## Code Map

- `night/night_session.gd` -- **orchestratore**. `_enter_stacking()` (296-309) mostra la rivelazione; oggi dopo lo stack non succede altro. Qui si aggancia la vendita: connettere `revealed` → `_enter_sale()`. `begin()` (118-143) azzera lo stato e va esteso per determinare la commessa e liberare `_sale`. `has_phase()` (153-154), `set_player_present()` (185-214), `_close_night()` (462-483): includere `_sale` accanto a `_stacking`. Possiede le mutazioni di `Game.run` e le emissioni `Events`.
- `night/stacking_reveal.gd` -- la rivelazione dello stack. `_process` (80-85) porta `_progress` a 1.0. Aggiungere `signal revealed()` emesso **una volta** al completamento; nient'altro cambia (le AC della 2.4 restano verdi).
- `night/night_summary.gd` -- modello di `Control` di `night/` a 256×192 col fosforo: colori, font, `set_readout`, `_draw`. La vendita lo rispecchia.
- `photo/quality.gd` -- modello di logica pura in `photo/` (`aggregate`, 0 su vuoto). `payout.gd`/`commission.gd` seguono lo stesso stampo.
- `photo/photo.gd` -- schema del record foto: chiavi costanti `KEY_ID` (int, indice), `KEY_TARGET`, `KEY_QUALITY`. La vendita legge `Game.run.photos[-1]`. `target_id` può essere vuoto (DW-3).
- `core/night_run.gd` -- `wallet_lire` (21) già esiste; `photos` (23) porta il record. Aggiungere `@export var commission: Dictionary = {}` (stato di notte, salvabile per la 2.7).
- `core/tuning_profile.gd` + `autoloads/tuning.gd` + `data/tuning.tres` -- aggiungere `payout_tiers` (curva segnaposto) col suo getter `Tuning.payout_tiers`.
- `autoloads/events.gd` -- `signal photo_sold(photo_id: StringName, lire: int)` (21) già dichiarato: da emettere. `photo_id` è StringName ⇒ convertire l'indice int (`StringName(str(id))`).
- `phases/targeting/sources/honest_catalog.tres` -- **modello** per il roster: Resource con `@export Array` che referenzia i `.tres` figli. Il roster committenti lo rispecchia.
- `crt/crt_screen.gd` -- `push()` (170-183) inoltra al viewport (tastiera sì, mouse no); `set_input_enabled` è il cancello. La vendita è **il primo Control diegetico che gestisce input**, previsto dai commenti di `push()` e di `main._unhandled_input`.
- `main.gd` -- `_unhandled_input` (363-376) inoltra a `_crt.push()` da seduti; `_shortcut_input` (355-361) tiene `interact`/`E` per rialzarsi. **Non va modificato**: la vendita usa la strada già fatta.
- `tests/test_bench.gd` -- banco senza framework: `_ready` (50-75) elenca i check, `_check_photo_quality` (412-434) è il modello. Aggiungere `_check_payout()` e `_check_commission()`.
- `project.godot` -- sezione `[input]`: aggiungere `sale_up`/`sale_down`/`sale_confirm` (Freccia su / Freccia giù / Invio), come `targeting_*`.

## Tasks & Acceptance

**Execution:**
- `data/clients/client_data.gd` -- creare `class_name ClientData extends Resource` con `@export`: `id: StringName`, `name: String`, `multiplier: float`, `wanted_target: StringName`, `enabled: bool`. Solo dati (modello: `data/targets/target_data.gd`). Commento: `multiplier` è SEGNAPOSTO (FR22).
- `data/clients/coelum.tres`, `astrofili_marche.tres`, `bbs_cygnus.tres`, `privato_g.tres` -- 4 committenti. Moltiplicatori: Coelum 1.0, Astrofili Marche 0.6, BBS Cygnus 1.4 (segnaposto). Ognuno `wanted_target` fra i 6 id reali (`m42/m13/m45/m31/m57/m8`), distinti. `privato_g`: `enabled = false`.
- `data/clients/client_roster.gd` + `data/clients/roster.tres` -- `class_name ClientRoster extends Resource`, `@export var clients: Array[ClientData]`; il `.tres` referenzia i 4 committenti (modello: `honest_catalog.tres`).
- `photo/commission.gd` -- `class_name Commission extends RefCounted`. Chiavi costanti (`CLIENT_NAME`, `MULTIPLIER`, `TARGET_ID`). `static func choose(clients: Array, night_index: int) -> Dictionary`: filtra `enabled`, sceglie in modo **deterministico** (`enabled[(night_index - 1) % enabled.size()]`), restituisce il dict; `{}` se nessun abilitato. Pura.
- `photo/payout.gd` -- `class_name PhotoPayout extends RefCounted`. `func tier_payout(quality: int, tiers: Array) -> int`: dato un array di `{min_score, lire}`, ritorna il `lire` dello scaglione più alto con `min_score <= quality`; `0` su array vuoto (come `quality`). `func apply_multiplier(base: int, mult: float) -> int`: `int(round(base * mult))`. Pura.
- `core/tuning_profile.gd` -- aggiungere `@export var payout_tiers: Array[Dictionary]` con la curva segnaposto (0→500, 30→1500, 50→3500, 75→7000, 90→15000). Commento SEGNAPOSTO (FR22).
- `autoloads/tuning.gd` -- aggiungere il getter `payout_tiers` (superficie `Tuning.payout_tiers`).
- `data/tuning.tres` -- popolare `payout_tiers` con i valori segnaposto (così si legge il `.tres`, non i default dello script).
- `core/night_run.gd` -- aggiungere `@export var commission: Dictionary = {}`. Non toccare `CURRENT_VERSION`/`migrate()` (la 2.7 gestisce la persistenza).
- `night/photo_sale.gd` -- nuovo `Control` a 256×192 (modello: `night_summary.gd`). `set_readout(target: String, quality: int, base: int, commission: Dictionary)`: calcola se la commessa è applicabile (`target` non vuoto e uguale a `commission.TARGET_ID`) e disegna le opzioni. Menu: se applicabile → `[FULFILL name ×mult]` / `[SELL OPEN]`; altrimenti → `[SELL]`. `_unhandled_input` legge `sale_up`/`sale_down`/`sale_confirm` (guardato da un `_done`, come le fasi). Alla conferma emette `signal confirmed(fulfill: bool)` (fulfill true solo se scelto FULFILL). `func show_sold(lire: int)`: passa allo stato «SOLD — N LIRE», e se rifiutata mostra «declined — no harm». Nessun autoload.
- `night/stacking_reveal.gd` -- aggiungere `signal revealed()`, emesso una sola volta quando `_progress` raggiunge 1.0 (guardia a flag). Nessun'altra modifica.
- `night/night_session.gd` -- (1) `begin()`: dopo l'azzeramento, `Game.run.commission = Commission.choose(roster, night_index)` caricando `roster.tres` da un path const (fallback `{}` se assente); azzerare anche `_sale`. (2) aggiungere `var _sale: Control` e `_sale_mode`; includerlo in `has_phase()`, `set_player_present()` (present-gating come `_stacking`), `_close_night()` (liberazione). (3) in `_enter_stacking()` connettere `_stacking.revealed` a `_enter_sale` con `CONNECT_DEFERRED` (mai liberare un nodo dentro il proprio `_process`). (4) `_enter_sale()`: libera la rivelazione, calcola `base = PhotoPayout.tier_payout(quality, Tuning.payout_tiers)`, crea `photo_sale`, `set_readout(...)`, `show_control`, connette `confirmed` → `_on_sale_confirmed`, arma il present-gating. (5) `_on_sale_confirmed(fulfill)`: `lire = base` oppure `PhotoPayout.apply_multiplier(base, mult)`; `Game.run.wallet_lire += lire`; `Events.photo_sold.emit(StringName(str(photo_id)), lire)`; `_sale.show_sold(lire)`.
- `project.godot` -- aggiungere le azioni `sale_up` (Freccia su), `sale_down` (Freccia giù), `sale_confirm` (Invio) in `[input]`.
- `tests/test_bench.gd` -- aggiungere `_check_payout()` (bordi degli scaglioni + arrotondamento del moltiplicatore + array vuoto→0) e `_check_commission()` (scelta deterministica su `night_index`, esclusione di `privato_g`, roster vuoto→`{}`), caricando il roster con `_load_source`. Chiamarli da `_ready()`.

**Acceptance Criteria:**
- Given una foto stackata e nessuna commessa applicabile, when il giocatore conferma la vendita, then `Game.run.wallet_lire` aumenta esattamente del payout di scaglione e `Events.photo_sold(id, lire)` viene emesso una volta, con la stessa cifra mostrata come «SOLD — N LIRE» sul CRT.
- Given una commessa il cui soggetto richiesto è il target della foto, when il giocatore sceglie FULFILL, then il payout accreditato è `round(base * multiplier)` del committente; when sceglie SELL OPEN (rifiuta), then è `base` (×1.0), compare una riga gentile «declined» e **nulla** cambia oltre l'accredito base.
- Given il payout mostrato, when compare, then è un evento diegetico dentro l'interfaccia di vendita sul CRT, in inglese, e non un popup di gioco sopra la scena.
- Given l'inizio della notte con il roster dei committenti, when la notte comincia, then `Game.run.commission` porta un solo committente **abilitato** col suo moltiplicatore e il soggetto richiesto, e `privato_g` non viene mai scelto.
- Given una foto con `target_id` vuoto (DW-3), when si vende, then la vendita procede a base ×1.0 senza commessa applicabile e senza errore mostrato al giocatore.
- Given la curva e i moltiplicatori, when si leggono, then vengono da `data/` (`Tuning.payout_tiers` e i `.tres` dei committenti), con un commento che li dichiara segnaposto; nessun numero d'economia è una `const` sparsa nel codice.
- Given il banco di collaudo, when eseguito, then stampa il comportamento di `tier_payout` ai bordi degli scaglioni, dell'arrotondamento del moltiplicatore e della scelta deterministica della commessa.

## Design Notes

**Perché la vendita è un `Control` di `night/`, non una fase.** La tabella dei confini mette «score → stack → tier → vendita» in `photo/` e vieta a `phases/` di conoscerla; una fase che chiamasse `PhotoPayout` violerebbe il confine. Come lo stacking, è `night/` a condurre — l'unica cartella che può dipendere sia dalle fasi (via il piano) sia da `photo/`.

**Il salto stacking → vendita.** `stacking_reveal` è present-gated: `revealed` scatta solo mentre il giocatore guarda (da seduto), quindi la vendita compare sempre a portata di mano, mai nel vuoto. La connessione è `CONNECT_DEFERRED` perché `revealed` nasce dentro `_process` della rivelazione, e liberarla lì sarebbe liberare un nodo dentro la propria callback — lo stesso motivo per cui l'orchestratore differisce ogni transizione.

**L'input arriva davvero.** `main._unhandled_input` inoltra a `crt.push()`, che fa `push_input` sul SubViewport: un `Control` che implementa `_unhandled_input` lì dentro riceve i tasti (la tastiera passa, il mouse no — vedi `crt_screen.push()`). È la strada che i commenti di `push()` e di `main._unhandled_input` dichiarano fatta apposta per «il primo Button diegetico». Che il routing regga dentro il viewport va **verificato a run-time** (avvio del gioco), non solo al banco: è una frontiera che il progetto non aveva ancora attraversato.

**Golden — la curva come dato:**
```gdscript
# photo/payout.gd — puro, 0 su curva vuota (come quality.aggregate)
func tier_payout(quality: int, tiers: Array) -> int:
    var lire := 0
    for t in tiers:                      # t = {min_score, lire}
        if quality >= int(t.get(&"min_score", 0)):
            lire = int(t.get(&"lire", 0))
    return lire
```
`tiers` ordinato per `min_score` crescente; l'ultimo scaglione superato vince.

**Il «niente» materiale del rifiuto (NFR20).** Rifiutare non è un errore: è una scelta con esito diegetico. La schermata lo dice («declined — no harm»), paga il base, e non scrive da nessuna parte che una commessa è stata rifiutata. Nessuna penalità significa nessun ramo che sottrae, non un ramo che sottrae zero.

**`photo_id` StringName.** Il record porta un indice `int` (`Photo.KEY_ID`); il signal lo vuole `StringName`. Si converte all'emissione (`StringName(str(id))`) — l'MVP non ha bisogno di un UUID, e l'indice resta leggibile nel `.tres` salvato.

## Verification

**Commands:**
- `godot --headless --path . tests/test_bench.tscn` -- expected: il banco stampa i nuovi blocchi `PhotoPayout` e `Commission` senza righe `<-- ATTESO`, e chiude con `=== fine ===` (`get_tree().quit()`).
- `grep -rn "phases/" photo/ night/photo_sale.gd` -- expected: zero occorrenze (nessuna dipendenza da `phases/`).

**Manual checks (if no CLI):**
- Avviare il gioco (`verify.ps1` o avvio Godot), sedersi al monitor, completare polare → targeting → imaging, guardare emergere lo stack: deve comparire l'interfaccia di vendita sul CRT. Premere `sale_confirm`: il portafoglio si accredita e lo schermo mostra «SOLD — N LIRE». Con una commessa sul target scelto, verificare che FULFILL applichi il moltiplicatore e SELL OPEN paghi il base con la riga «declined». Confermare che l'input dentro il viewport risponda (frontiera non ancora misurata).

## Review Triage Log

### 2026-08-23 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 1: (high 0, medium 0, low 1)
- defer: 2: (high 0, medium 1, low 1)
- reject: 13
- addressed_findings:
  - `[low]` `[patch]` Copertura matrice «roster senza abilitati»: `_check_commission` provava solo `choose([], 1)` (input vuoto). Aggiunta al banco l'asserzione `choose([<ClientData enabled=false>], 1) == {}` — il percorso filtro→`is_empty` su input non vuoto, distinto dall'input vuoto, che la riga I/O matrix «Roster assente/vuoto (mancante o senza abilitati)» nomina esplicitamente.

## Auto Run Result

Status: done

**Cosa è stato implementato.** La fase di vendita per-foto che chiude il ciclo notturno: dopo la rivelazione dello stack, l'orchestratore mostra sul CRT un'interfaccia di vendita (Control di `night/`), calcola il payout da una curva a scaglioni sul punteggio aggregato, applica il moltiplicatore del committente solo se la commessa è accettata, accredita le lire su `wallet_lire` ed emette `Events.photo_sold`. La commessa (committente + soggetto + moltiplicatore) è determinata all'inizio della notte e vive su `NightRun`; è rifiutabile senza conseguenze. Curva e moltiplicatori in `data/`, dichiarati segnaposto (FR22).

**File cambiati.**
- `night/photo_sale.gd` (nuovo) — interfaccia di vendita CRT 256×192, menu FULFILL/SELL OPEN/SELL, stato «SOLD», input `sale_*`, riga «declined — no harm».
- `photo/payout.gd` (nuovo) — logica pura: `tier_payout`, `apply_multiplier`, `sale_lire`.
- `photo/commission.gd` (nuovo) — logica pura: `choose` (selezione deterministica), `applies_to`, chiavi commessa.
- `data/clients/client_data.gd`, `client_roster.gd` (nuovi) — Resource dati committente e roster.
- `data/clients/{coelum,astrofili_marche,bbs_cygnus,privato_g,roster}.tres` (nuovi) — 3 committenti abilitati + `privato_g` disabilitato + roster.
- `core/tuning_profile.gd`, `autoloads/tuning.gd`, `data/tuning.tres` — curva `payout_tiers` segnaposto + getter `Tuning.payout_tiers`.
- `core/night_run.gd` — campo `commission` (stato notte, salvabile per la 2.7).
- `night/night_session.gd` — commessa determinata a `begin()`; `stacking.revealed` → `_enter_sale` (deferred); `_enter_sale`/`_on_sale_confirmed` (credito wallet + `photo_sold`); `_sale` nel ciclo di vita/present-gating/alba.
- `night/stacking_reveal.gd` — `signal revealed()` emesso una sola volta a completamento.
- `project.godot` — azioni `sale_up`/`sale_down`/`sale_confirm`.
- `tests/test_bench.gd` — `_check_payout`/`_check_commission`/`_check_sale` (bordi scaglioni, moltiplicatore, selezione deterministica, roster vuoto e tutto-disabilitato, le 4 righe di flusso dell'I/O matrix).

**Review: 1 patch applicata (low), 2 deferite (1 medium, 1 low), 13 rifiutate.** Nessun `intent_gap`, nessun `bad_spec`, nessun loopback. Follow-up review recommended: **false** (patched: high 0, low 1; punteggio `3×0 + 1×1 = 1` < 5).

**Verifica.** Banco headless (`Godot_v4.7.2 --headless tests/test_bench.tscn`): 0 righe `<-- ATTESO`, 0 errori di script, chiude con `=== fine ===`. Grep di confine `phases/` in `photo/` e `night/photo_sale.gd`: 0 occorrenze. Matrix Test Audit soddisfatto (ogni riga coperta da un test eseguito e passato).

**Rischi residui.** (1) Il routing dell'input del Control dentro il SubViewport del CRT non è verificabile headless: è la frontiera dichiarata (primo Control diegetico che gestisce input) e richiede un playthrough interattivo. (2) Il flusso stateful di vendita (composizione→credito→emissione, logica UI) è coperto solo dai controlli manuali, coerente col modello del banco — vedi `deferred`.
