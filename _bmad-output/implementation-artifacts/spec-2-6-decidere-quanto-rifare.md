---
title: 'Storia 2.6: Decidere quanto rifare'
type: 'feature'
created: '2026-08-23'
status: 'done'
review_loop_iteration: 0
followup_review_recommended: false
baseline_revision: '8e751f6885ab434b64f73396887418e269cde7d7'
context: []
warnings: ['oversized']
deferred:
  - summary: >-
      Il flusso del menu post-foto non ha copertura automatica: il rientro nel piano dei
      quattro rami (_on_menu_chosen), l'apertura via _sale.dismissed, il present-gating e
      la liberazione all'alba del _menu, e l'azzeramento dei punteggi di setup per key()
      sono verificati solo da un playthrough interattivo, non ancora eseguito.
    evidence: |-
      Il banco (NFR19) prova solo logica pura senza SceneTree; la 2.6 è orchestrazione
      (NightSession) + UI (Control diegetico che gestisce input nel SubViewport), stateful.
      Rispecchia DW-2 (stessa lacuna per il flusso imaging della 2.3) e la lacuna della
      composizione di vendita della 2.5. Una regressione (indice foto errato, chiave di
      setup mancante in _setup_phase_keys, guardia _ended assente) lascerebbe il banco verde.
    location: >-
      night/night_session.gd:_on_menu_chosen, night/post_photo_menu.gd
    severity: medium
---

<intent-contract>

## Intent

**Problem:** Il ciclo notturno arriva fino alla vendita (2.5) e poi si ferma: dopo lo «SOLD» la schermata resta e il giocatore si rialza con `E` — un vicolo cieco che la 2.5 aveva dichiarato temporaneo. Manca l'anello che chiude il ciclo e lo riapre: il **menu post-foto** con cui il giocatore decide quanto rifare (scattare ancora, cambiare soggetto, rifare il setup) o smettere per ora, finché l'alba non chiude la notte.

**Approach:** Dopo lo «SOLD», l'orchestratore mostra sul CRT un **menu post-foto** (un `Control` di `night/`, come la vendita e lo stacking) con quattro scelte. Ogni scelta è un rientro nel piano della notte a un punto diverso: *scatta ancora* rientra saltando la selezione del target (stesso target e stessa configurazione), *cambia target* rientra dal targeting, *rifai setup* riparte dalla fase di setup azzerandone i punteggi, *chiudi ed esplora* lascia il menu valido e fa rialzare il giocatore. Il rientro non nomina nessuna fase: usa gli indici del `NightPlan` (ADR-002). I punteggi delle fasi non rifatte sono ereditati dalla persistenza (FR17), quelli di setup si azzerano solo su *rifai setup* (FR18, per `key()`).

## Boundaries & Constraints

**Always:**
- Il menu è un `Control` di `night/` mostrato dall'orchestratore col pattern di `photo_sale`/`stacking_reveal`/`night_summary` (UX-DR1): sullo schermo del mondo, present-gated, posseduto e liberato dall'orchestratore. Il CRT non libera mai ciò che mostra.
- **L'orchestratore non nomina nessuna fase** (ADR-002): il rientro dei quattro rami usa `_in_setup` e gli indici di `NightPlan` (`_setup_index`/`_photo_index`), mai un `preload` o un `match` su `key()`. Il file `night_session.gd` non deve contenere il nome di una cartella di fasi nemmeno in un commento.
- **FR17 — eredità:** i punteggi delle fasi non rieseguite restano in `Game.run.phase_scores` e vengono riletti da `PhotoQuality.aggregate` (l'eredità è già persistenza, come nella 2.4). Nessun ramo copia punteggi a mano.
- **FR18 — azzeramento per `key()`:** *rifai setup* azzera **solo** i punteggi delle fasi di setup, identificate da `key()` (mai `name`) imparata a runtime — non con un elenco di nomi. Le fasi foto non si toccano: le riscrive la riesecuzione.
- *scatta ancora* riparte dalla fase di imaging con lo **stesso target e la stessa configurazione**: il target e i parametri (`exposure_sec`, `frame_count`) restano nel `_ctx` e la fase di imaging li ripresenta come valori di partenza.
- *chiudi ed esplora* **non libera il menu**: lo lascia valido fino all'alba, così risedendosi ricompare e si può scattare ancora senza rifare nulla (FR4). Avverte il punto d'ingresso via `plan_exhausted` di far rialzare il giocatore.
- L'alba (`_on_dawn`/`_close_night`) chiude la notte anche a menu aperto: libera il menu e mostra il riepilogo, esattamente come fa già con vendita e stacking. Ogni rientro è guardato da `_ended`.
- Testo del menu in **inglese** (interfaccia software, NFR10), 256×192, colori del fosforo come gli altri Control del CRT. Navigazione con azioni proprie `menu_*` (Su/Giù/Invio), non `ui_*`.
- Transizioni sempre differite (`call_deferred`/`CONNECT_DEFERRED`): non si libera un nodo dentro la propria callback (NFR16). Signal tipizzati, `snake_case` (NFR22).

**Block If:**
- Nessuna condizione di blocco prevista: l'intento è risolto.

**Never:**
- Non introdurre la persistenza cross-notte né toccare `Game.start_night()`/`migrate()`: è la 2.7. Qui si lavora dentro la notte in corso.
- Non far conoscere `phases/` a `night/`: nessun file di `phases/` cambia **tranne** `phase_imaging.gd`, che legge dal `ctx` i parametri già emessi (target/esposizione/frame) — sono dati in ingresso (ADR-002), non import.
- Non degradare la vendita della 2.5: il payout continua a comparire nell'interfaccia di vendita (`photo_sale.show_sold`). Il menu è il passo **successivo**, non la sostituisce.
- Non dare un bonus/penalità a nessuna scelta: rifare o non rifare non muove punteggi se non per riesecuzione.

</intent-contract>

## Code Map

- `night/night_session.gd` -- **orchestratore**. `_on_sale_confirmed` (407-424): oggi termina su «SOLD»; qui la vendita si collega a `dismissed` → `_enter_menu`. `_next_scene` (274-295) / `_enter_next` (305-312): il ciclo del piano su cui i rientri poggiano — i rami del menu impostano `_in_setup`/`_setup_index`/`_photo_index` e chiamano `_enter_next`. `_on_phase_finished` (492-516): scrive `phase_scores[phase.key()]`; qui si impara quali `key()` sono di **setup** (`_in_setup` è ancora true quando una fase di setup conclude). `has_phase` (195-196), `set_player_present` (227-263), `begin` (143-185), `_close_night` (578-606): includere `_menu` accanto a `_sale`. Possiede mutazioni di `Game.run` ed emissioni `Events`.
- `night/photo_sale.gd` -- interfaccia di vendita (2.5). Stato «SOLD» in `show_sold` (107-112) e `_draw_sold` (168-174): aggiungere `signal dismissed()` emesso quando, in stato `_sold`, si preme `sale_confirm`; footer da «press E to stand up» a «press enter for options». Modello 256×192 per il menu.
- `night/night_summary.gd` -- altro modello di `Control` di `night/` (colori, font, `_draw`, `_text`).
- `phases/imaging/phase_imaging.gd` -- `setup` (96-104) legge `target_id` dal `ctx`. Aggiungere la lettura opzionale di `exposure_sec`/`frame_count` dal `ctx` (con `clampi` ai limiti) per «stessa configurazione». `_finish` (234-240) già emette quelle chiavi nel payload → sono in `_ctx`. Nessun import da altre fasi: sono dati in ingresso.
- `photo/photo.gd` -- `is_photo(ctx)` (42-43) richiede `exposure_sec`+`frame_count`: dopo ogni rientro, l'imaging le riemette e il ciclo ristacka correttamente. `KEY_ID` = indice progressivo: ogni scatto è un record distinto in `run.photos`.
- `main.gd` -- `_on_plan_exhausted` (222-226) fa rialzare chi è seduto; *chiudi ed esplora* riusa questa strada. `_on_monitor_interacted` (273-282) risiede se `has_phase()`: col menu vivo il monitor resta usabile. `_unhandled_input` (363-376) inoltra al CRT — la strada dell'input del menu, come per la vendita. **Non va modificato.**
- `crt/crt_screen.gd` -- `push()`/`set_input_enabled`: la strada dell'input diegetico nel `SubViewport` (già usata dalla vendita).
- `project.godot` -- sezione `[input]`: aggiungere `menu_up`/`menu_down`/`menu_confirm` (Su `4194320` / Giù `4194322` / Invio `4194309`), come `sale_*` (105-121).
- `tests/test_bench.gd` -- banco senza framework, solo logica pura: la 2.6 è orchestrazione + UI (stateful, con `SceneTree`), senza logica pura nuova da collaudare al banco — vedi Verification.

## Tasks & Acceptance

**Execution:**
- `night/post_photo_menu.gd` -- creare un nuovo `Control` a 256×192 (modello: `photo_sale.gd`). Enum a livello di script `OPTION_SHOOT_AGAIN=0`, `OPTION_CHANGE_TARGET=1`, `OPTION_REDO_SETUP=2`, `OPTION_CLOSE=3`; `_options: PackedStringArray` con etichette inglesi (`"SHOOT AGAIN"`, `"CHANGE TARGET"`, `"REDO SETUP"`, `"CLOSE & EXPLORE"`); `_cursor`; `signal chosen(option: int)`. `_unhandled_input` guardato da `_done`: `menu_up`/`menu_down` muovono il cursore, `menu_confirm` imposta `_done = true` ed emette `chosen(_cursor)` (`set_input_as_handled`). `_draw`: titolo (es. `"WHAT NEXT?"`), le 4 opzioni con cursore `>` e colore `SEL` sulla selezionata, footer `"up/down choose — enter confirm"`. `func arm() -> void`: `_done = false`, `_cursor = 0`, `queue_redraw()` — per riaprire il menu dopo *chiudi ed esplora*. Nessun autoload, nessuna logica d'economia, nessun nome di fase.
- `night/photo_sale.gd` -- aggiungere `signal dismissed()`. In `_unhandled_input`, quando `_sold` è true, `sale_confirm` emette `dismissed()` (invece di essere inerte). Footer di `_draw_sold` da «press E to stand up» a «press enter for options». Non toccare la logica di vendita/rifiuto.
- `phases/imaging/phase_imaging.gd` -- in `setup`, dopo `target_id`: se `ctx.has(&"exposure_sec")` → `_exposure = clampi(int(ctx["exposure_sec"]), EXPOSURE_MIN, EXPOSURE_MAX)`; idem `frame_count` → `_frames_total` con i suoi limiti. Commento: «2.6 — scatta ancora ripresenta la STESSA configurazione». Assenti (primo scatto) → i default restano. Chiavi grezze (nessun import da `photo/`).
- `night/night_session.gd` --
  (1) `const MENU := preload("res://night/post_photo_menu.gd")`; `var _menu: Control`; `var _menu_mode := Node.PROCESS_MODE_INHERIT`; `var _setup_phase_keys: Dictionary = {}`.
  (2) `has_phase()`: includere `or _menu != null`. `set_player_present()`: sospendere/riprendere `_menu` come `_sale` (present-gating). `begin()`: liberare `_menu` stantìo e `_setup_phase_keys.clear()`. `_close_night()`: liberare `_menu` come `_sale`.
  (3) `_on_phase_finished`: dopo `phase_scores[phase.key()] = result.score`, se `_in_setup` allora `_setup_phase_keys[phase.key()] = true` (impara le chiavi di setup a runtime, senza nominare fasi).
  (4) `_enter_sale`: connettere `_sale.dismissed` a `_on_sale_dismissed`. `_on_sale_dismissed()`: `_enter_menu.call_deferred()`.
  (5) `_enter_menu()`: `if _ended: return`; liberare `_sale`; creare `_menu = MENU.new()`, registrare `_menu_mode`, `show_control(_menu)`, `_menu.chosen.connect(_on_menu_chosen, CONNECT_DEFERRED)`, `set_player_present(_player_present)`.
  (6) `_on_menu_chosen(option: int)`: `if _ended: return`; `match option` →
     `OPTION_SHOOT_AGAIN`: liberare `_menu`; `_in_setup = false`; `_photo_index = 1`; `_enter_next()` (`_ctx` intatto).
     `OPTION_CHANGE_TARGET`: liberare `_menu`; `_in_setup = false`; `_photo_index = 0`; `_enter_next()`.
     `OPTION_REDO_SETUP`: `for k in _setup_phase_keys: Game.run.phase_scores.erase(k)`; liberare `_menu`; `_ctx.clear()`; `_in_setup = true`; `_setup_index = 0`; `_photo_index = 0`; `_enter_next()`.
     `OPTION_CLOSE`: **non** liberare `_menu`; `_menu.arm()`; `plan_exhausted.emit()`.
- `project.godot` -- aggiungere `menu_up` (Su), `menu_down` (Giù), `menu_confirm` (Invio) in `[input]`, sul modello di `sale_*`.

**Acceptance Criteria:**
- Given una foto venduta con «SOLD» a schermo, when il giocatore preme conferma, then compare il menu post-foto con esattamente quattro voci: SHOOT AGAIN, CHANGE TARGET, REDO SETUP, CLOSE & EXPLORE.
- Given *scatta ancora*, when scelto, then si riparte dalla fase di imaging con lo stesso target e la stessa configurazione (esposizione e frame ripresentati), e i punteggi delle fasi precedenti sono ereditati senza rieseguirle.
- Given *cambia target*, when scelto, then si torna al targeting e da lì all'imaging, e i punteggi delle fasi di setup restano ereditati.
- Given *rifai setup*, when scelto, then si torna alla fase di setup e i punteggi delle fasi di setup vengono azzerati; due esecuzioni della stessa fase nella stessa notte non si sovrascrivono sotto una chiave sbagliata, perché l'identità è `key()` e non `name`.
- Given *chiudi ed esplora*, when scelto, then il setup resta valido e il giocatore torna nell'osservatorio; finché non è l'alba può risedersi, il menu ricompare, e può scattare ancora senza rifare nulla.
- Given l'alba che arriva mentre il menu è aperto, when scatta, then il menu si chiude e la notte si conclude comunque col riepilogo.
- Given l'orchestratore, when si cerca il nome di una cartella di fasi in `night_session.gd`, then non ce n'è nessuna occorrenza (ADR-002 resta verde).

## Spec Change Log

### 2026-08-23 — Rimossa la I/O & Edge-Case Matrix (correzione di categorizzazione, step-03)
- **Triggering:** la matrice conteneva solo comportamenti di sistema (apertura menu, i quattro rientri, alba a menu aperto, doppia conferma) — nessuno unit-testabile sul banco a logica pura (NFR19: banco = solo logica pura, niente scene). Ogni riga era già ripetuta come Acceptance Criterion. Tenerla avrebbe forzato un Matrix Test Audit insoddisfabile e un HALT `blocked` falso su una storia completa e verificata.
- **Amended:** rimossa la sezione dall'`<intent-contract>` (il template la dichiara cancellabile quando non esistono scenari I/O significativi). Il contratto di build resta invariato: tutti i comportamenti sopravvivono come AC.
- **Known-bad avoided:** un blocco dell'intero run per un difetto di categorizzazione in fase di pianificazione, non per un problema di implementazione.
- **KEEP:** la copertura playthrough-only del flusso menu è registrata sotto `deferred` (come fece la 2.5 per la glue di vendita), non nella matrice.

## Review Triage Log

### 2026-08-23 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 1: (high 0, medium 1, low 0)
- defer: 0
- reject: 18
- addressed_findings:
  - `[medium]` `[patch]` La rehydration pura di `PhaseImaging.setup()` (`exposure_sec`/`frame_count` da `ctx`, clampati) — il meccanismo di «stessa configurazione» (AC2) — non era coperta: `_check_imaging_setup` passava solo `{target_id}`. Esteso il check del banco con tre casi (pass-through in range, clamp a MAX, default preservati), stesso stile e ciclo di vita del check esistente, nessuna SceneTree. Invertire la rehydration o rompere i limiti ora tinge il banco di rosso.

## Design Notes

**Perché il rientro per indice e non per nome.** L'orchestratore non può nominare una fase (ADR-002, provato con `grep`). I quattro rami del menu sono quindi punti di rientro nel `NightPlan`: *rifai setup* riparte da `_in_setup = true, _setup_index = 0`; *cambia target* da `_in_setup = false, _photo_index = 0`; *scatta ancora* da `_photo_index = 1`. Questo codifica un'invariante del piano: **la prima fase foto seleziona il target, le successive lo catturano**. Il `NightPlan` dell'MVP è `[polar]` / `[targeting, imaging]`, quindi indice foto 1 = imaging (scatta ancora salta il targeting), indice 0 = targeting (cambia target lo include). L'invariante vale finché `photo_phases` ha la selezione del target come prima voce.

**Come si imparano le chiavi di setup senza nominarle.** Quando una fase conclude, `_on_phase_finished` gira mentre `_in_setup` riflette ancora il tratto in corso: è true finché lo scan del piano non esaurisce `setup_phases`. Le fasi di setup concludono con `_in_setup == true`, le foto con `false`. Registrare `_setup_phase_keys[phase.key()]` sotto quella guardia dà l'insieme delle chiavi di setup **per `key()`**, senza un elenco di nomi — ed è esattamente ciò che *rifai setup* cancella (FR18).

**Perché il menu è un passo dopo lo «SOLD», non al posto suo.** La 2.5 mostra il payout dentro l'interfaccia di vendita (UX-DR10): tenerlo lì mantiene verde quell'AC. Il menu è la continuazione diegetica dello stesso momento — hai venduto, ora decidi. `dismissed` (una nuova conferma sullo «SOLD») porta al menu; è deferito perché nasce nell'input del `_sale` che stiamo per liberare.

**Perché *chiudi ed esplora* non libera il menu.** FR4 chiede che si possa riaprire il menu e scattare ancora senza rifare nulla. Liberarlo renderebbe `has_phase()` falso, il monitor si spegnerebbe e non ci si potrebbe risedere. Lasciarlo vivo e present-gated (sospeso quando si è via, ripreso al ritorno) lo fa ricomparire risedendosi — la stessa meccanica di ogni Control del CRT. `arm()` lo ripulisce (`_done`, cursore) così alla riapertura è di nuovo interattivo.

**Golden — imparare le chiavi di setup:**
```gdscript
# night_session._on_phase_finished, dopo phase_scores[phase.key()] = result.score
if _in_setup:                              # true SOLO mentre lo scan è nelle fasi di setup
    _setup_phase_keys[phase.key()] = true  # key(), MAI name (FR18)
```

## Verification

**Commands:**
- `Godot_v4.7.2 --headless --path . tests/test_bench.tscn` -- expected: 0 righe `<-- ATTESO`, chiude con `=== fine ===`. `_check_imaging_setup` copre la rehydration pura della config (pass-through in range, clamp a MAX, default preservati); il resto della 2.6 è orchestrazione + UI stateful, fuori dal banco (NFR19).
- `grep -rnE "\b(polar|targeting|imaging)\b" night/night_session.gd night/post_photo_menu.gd` -- expected: zero occorrenze come identificatori di codice (ADR-002). Nota: la stringa `phases/` compare solo in commenti che spiegano la regola, non come nome di fase.

**Manual checks (if no CLI):**
- Avviare il gioco, completare polare → targeting → imaging → stack → vendita, confermare la vendita: dopo «SOLD», premere Invio → compare il menu a 4 voci.
- *scatta ancora*: rientra nell'imaging col target e i parametri precedenti; venduta la seconda foto, il portafoglio è cresciuto due volte.
- *cambia target*: rientra nel targeting; scelto un altro soggetto, prosegue fino a una nuova vendita.
- *rifai setup*: rientra nella polare; l'overlay `F12` mostra il punteggio della polare azzerato e ricalcolato alla riesecuzione, sotto la stessa `key()`.
- *chiudi ed esplora*: il giocatore si rialza; camminando e risedendosi il menu ricompare; scatta ancora funziona senza rifare nulla.
- Con `F1`-`F4` accelerare fino all'alba con il menu aperto: il menu sparisce e compare il riepilogo della notte.

## Auto Run Result

Status: done

**Cosa è stato implementato.** Il menu post-foto che chiude e riapre il ciclo notturno. Dopo la vendita, sullo «SOLD» premere conferma apre un `Control` di `night/` con quattro scelte: *scatta ancora*, *cambia target*, *rifai setup*, *chiudi ed esplora*. Ogni scelta è un rientro nel `NightPlan` a un punto diverso — per indice, mai per nome di fase (ADR-002): *scatta ancora* riparte dall'imaging (indice foto 1) con lo stesso target e la stessa configurazione (l'imaging ripresenta esposizione/frame dal `ctx`); *cambia target* dal targeting (indice foto 0); *rifai setup* dal setup azzerando i punteggi delle fasi di setup (per `key()` imparata a runtime, FR18) e svuotando il `ctx`; *chiudi ed esplora* lascia il menu vivo e present-gated (risedendosi ricompare, FR4) e fa rialzare il giocatore via `plan_exhausted`. L'alba libera il menu e mostra il riepilogo anche a menu aperto. I punteggi non rifatti sono ereditati dalla persistenza (FR17).

**File cambiati.**
- `night/post_photo_menu.gd` (nuovo) — Control CRT 256×192 col menu a 4 voci, enum `OPTION_*`, `signal chosen(option)`, input `menu_*`, `arm()` per la riapertura dopo *chiudi ed esplora*.
- `night/photo_sale.gd` — `signal dismissed()` emesso da «SOLD» su conferma; footer «press enter for options». Logica di vendita invariata.
- `phases/imaging/phase_imaging.gd` — `setup()` reidrata esposizione/frame dal `ctx` (clampati) per «stessa configurazione»; chiavi grezze, nessun import da `photo/`.
- `night/night_session.gd` — `MENU` preload, `_menu`/`_menu_mode`/`_setup_phase_keys`; `_enter_menu`/`_on_menu_chosen`/`_free_menu`/`_on_sale_dismissed`; `_menu` in `has_phase`/`set_player_present`/`begin`/`_close_night`; apprendimento delle `key()` di setup in `_on_phase_finished`. Nessun nome di fase.
- `project.godot` — azioni `menu_up`/`menu_down`/`menu_confirm`.
- `tests/test_bench.gd` — `_check_imaging_setup` esteso con la rehydration della config (pass-through, clamp, default).

**Review: 1 patch (medium), 0 deferite in questo pass, 18 rifiutate.** Nessun `intent_gap`, nessun `bad_spec`, nessun loopback. Il pass ha anche corretto una categorizzazione della fase di pianificazione: la I/O matrix (comportamenti di sistema, non unit-testabili sul banco a logica pura) è stata rimossa dall'intent-contract e la sua copertura playthrough registrata sotto `deferred` — vedi Spec Change Log. Follow-up review recommended: **false** (patched: high 0, medium 1, low 0; punteggio `3×1 + 1×0 = 3` < 5).

**Verifica.** Banco headless (`Godot_v4.7.2-stable_win64.exe --headless tests/test_bench.tscn`): 0 righe `<-- ATTESO`, 0 errori di script, chiude con `=== fine ===`; i nuovi casi della config stampano `300/40`, `600/60`, `120/20`. ADR-002: `grep -E "\b(polar|targeting|imaging)\b"` in `night_session.gd` e `post_photo_menu.gd` → 0 identificatori di fase.

**Rischi residui.** Il flusso stateful del menu (rientri nel piano, present-gating e liberazione all'alba del `_menu`, apertura via `dismissed`, azzeramento dei punteggi di setup per `key()`) è verificato solo da playthrough interattivo, non eseguito headless — vedi `deferred`. Una regressione (indice foto errato, chiave di setup mancante, guardia `_ended` assente) lascerebbe il banco verde.
