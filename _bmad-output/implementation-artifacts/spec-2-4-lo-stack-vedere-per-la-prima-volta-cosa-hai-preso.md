---
title: 'Storia 2.4 — Lo stack: vedere per la prima volta cosa hai preso'
type: 'feature'
created: '2026-08-23'
status: 'done'
baseline_revision: '26b47f9624e78ba5975033077f2b6070470845ac'
review_loop_iteration: 0
followup_review_recommended: false
context: []
warnings: [oversized]
deferred: []
---

<intent-contract>

## Intent

**Problem:** Quando l'imaging (2.3) finisce, non succede più niente: la fase si smonta, lo schermo si svuota e il giocatore non vede mai *cosa ha preso*. Mancano tre cose che l'epica chiede insieme: la **rivelazione** (l'immagine che emerge dal rumore sotto gli occhi), la **qualità aggregata** della foto (calcolata dai punteggi delle fasi che la compongono), e la **registrazione** della foto per la vendita (2.5).

**Approach:** Lo stacking **non è una fase** — `phases/` non può dipendere da `photo/`, ma l'AC vuole l'aggregazione in `photo/quality.gd`. Quindi è l'orchestratore `night/` a condurlo, esattamente come già fa con `night_summary`: quando il ciclo delle foto si esaurisce e nel `ctx` c'è una foto, `night_session` calcola la qualità con `photo/quality.gd`, costruisce il record foto (`photo/photo.gd`) e lo aggiunge a `run.photos`, poi mostra sul CRT un `Control` di rivelazione (`night/stacking_reveal.gd`) che fa emergere l'immagine dal rumore e stampa il punteggio. La rivelazione avanza **solo mentre il giocatore è alla postazione** (present-gated come le fasi), così è davvero «sotto i suoi occhi».

## Boundaries & Constraints

**Always:**
- L'aggregazione della qualità vive in `photo/quality.gd`, è **logica pura** e istanziabile senza `SceneTree` (nessun accesso ad autoload, nodi, viewport). Legge `run.phase_scores` e restituisce un `int` (AC2).
- L'**ereditarietà** è automatica: `run.phase_scores` persiste fra gli scatti e tiene l'ultimo punteggio per `key()`; `quality.gd` aggrega ciò che c'è, quindi le fasi non rifatte contano con il loro punteggio precedente (AC2). L'indicizzazione è per `Phase.key()`, **mai** `name`.
- Confini di cartella (game-architecture.md): `night/` può dipendere da `core/`, `photo/`, `crt/`; `photo/` dipende solo da `core/` e **non conosce** `phases/` né `world/`. Un grep di `phases/` dentro `photo/` deve dare zero.
- La rivelazione è **messa in scena, non una barra**: l'immagine emerge progressivamente dal rumore (AC1). Il punteggio compare come numero **in inglese** accanto all'immagine (AC3, lingua delle macchine).
- Il `Control` della rivelazione è mostrato via `crt.show_control(...)`, di proprietà di `night/` (come `night_summary`): l'orchestratore chiama `show_control(null)`/lo libera **prima** di sostituirlo. La rivelazione avanza (`_process`) solo con `player_present == true`, gestito da `set_player_present` come per gli schermi di fase.
- Segnali tipizzati `snake_case` al passato; due canali separati (`push_error`/`assert` per errori di programma, contenuto diegetico sul CRT). GDScript tipizzato, Godot 4.7, renderer Compatibility.

**Block If:**
- (nessuna: la semplificazione «l'immagine non degrada con la qualità» è già decisa — 2026-08-21, vedi Design Notes — non è un intent gap.)

**Never:**
- **Nell'MVP l'immagine non si degrada con la qualità**: la rivelazione è la stessa a punteggio alto o basso; la qualità vive solo nel numero e nel payout (AC3, semplificazione dichiarata). Niente stelle allungate, niente rumore residuo legato al punteggio.
- Niente vendita, niente `Events.photo_sold`, niente curva di payout, niente committenti: sono la 2.5. Niente menu post-foto (scatta ancora / cambia target / …): è la 2.6. Niente save su disco: è la 2.7.
- Lo stacking **non** è una `Phase`, non entra in `data/night_plan.tres`, non emette `phase_finished`, non scrive in `run.phase_scores` (non è una fase che compone la foto: è dove la foto si aggrega).
- L'orchestratore non nomina nessuna fase: nessun `preload`/`match` su `key()` per riconoscere l'imaging. Che ci sia una foto lo dice il **dato** nel `ctx` (`photo/photo.gd::is_photo`), non il nome di una fase.
- Nessuna calibrazione dei numeri (formula di aggregazione, durata della rivelazione): sono segnaposto dichiarati (FR22).
- Niente asset fotografici veri: l'immagine rivelata è un **segnaposto** disegnato a schermo (rumore → segnale), non una texture da rifinire.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Aggregazione tipica | `phase_scores = {polar:80, targeting:60, imaging:100}` | `aggregate` → `80` (media intera, floor) | — |
| Punteggi ereditati (ri-scatto) | `phase_scores = {polar:80, targeting:60, imaging:40}` (solo imaging rifatto) | `aggregate` → `60` — polar/targeting ereditati contano | — |
| Fase sola | `phase_scores = {polar:80}` | `aggregate` → `80` | — |
| Nessun punteggio | `phase_scores = {}` | `aggregate` → `0` (default segnaposto, nessuna divisione per zero) | — |
| Foto presente nel ctx | `ctx` con `exposure_sec` e `frame_count` | `is_photo` → true; stacking parte; foto in `run.photos` | — |
| Ciclo senza foto | `ctx` senza quelle chiavi (o `photo_phases` vuoto) | `is_photo` → false; nessuno stacking, `plan_exhausted` come oggi | — |
| Rivelazione con giocatore assente | imaging finito mentre il giocatore è via | il `Control` è sul CRT ma **non avanza** finché non ci si risiede; al ritorno emerge sotto gli occhi | — |

</intent-contract>

## Code Map

- `night/night_session.gd` -- **cuore della modifica**. `_enter_next()` (:224) ramo `scene == null`: oggi fa `show_control(null)` + `plan_exhausted`. Da deviare verso lo stacking quando c'è una foto. `_on_phase_finished` (:311) accumula `_ctx.merge(payload)` e scrive `phase_scores[key()]` — la fonte dell'aggregazione. `has_phase()` (:130), `set_player_present()` (:162, gating via `process_mode`), `begin()` (:116 libera `_summary`), `_close_night()` (:386), `_show_summary()` (:402, modello di `Control` su CRT). `_crt.show_control(...)` è la via al vetro.
- `night/night_summary.gd` -- **modello da replicare** per la rivelazione: `Control` script-only (nessun `.tscn`), `DESIGN_SIZE (256,192)`, colori fosforo, `SystemFont` in `_ready`, `set_readout(...)` unico ingresso, `_draw()`. Istanziato con `.new()` e mostrato via `show_control`.
- `core/night_run.gd:19,23` -- `phase_scores: Dictionary` (input dell'aggregazione), `photos: Array[Dictionary]` (dove va il record foto). Solo dati; non modificare.
- `phases/imaging/phase_imaging.gd:234-240` -- il payload emesso: `{target_id, exposure_sec, frame_count}`. È il `ctx` che lo stacking consuma. `PLACEHOLDER_SCORE = 100` finisce in `phase_scores[&"imaging"]`.
- `phases/targeting/phase_targeting.gd:169-172` -- payload `{target_id}` soltanto: per questo `is_photo` deve richiedere `exposure_sec`+`frame_count`, non `target_id`.
- `main.gd:206` `_refresh_monitor()` -- `_monitor.enabled = _night.has_phase()`. Con lo stacking tracciato da `has_phase()`, lo stato «abilitato» dell'imaging si conserva fino allo stacking: nessun nuovo segnale verso `main` è necessario. `:222` `_on_plan_exhausted` fa rialzare — **non** deve scattare finché la rivelazione è a schermo.
- `tests/test_bench.gd:50-69` `_ready()` chiama i `_check_*`; `:162` `SOURCE_PATHS` per il controllo `resource_local_to_scene`. Aggiungere `_check_photo_quality()`. Nessuna sorgente nuova da registrare (lo stacking non ha sorgenti di verità).
- `game-architecture.md:725-729,756-763` -- `photo/` = «score → stack → tier → vendita»; tabella dei confini. Cartella `photo/` da creare.

## Tasks & Acceptance

**Execution:**
- `photo/quality.gd` -- `class_name PhotoQuality extends RefCounted`; metodo `aggregate(phase_scores: Dictionary) -> int` che restituisce la **media intera** (floor) dei valori, `0` su dizionario vuoto. Logica pura, deterministica, nessuna dipendenza. Commento: formula SEGNAPOSTO (FR22), l'ereditarietà è implicita nella persistenza di `phase_scores`. -- L'aggregazione dell'AC2, testabile sul banco.
- `photo/photo.gd` -- `class_name Photo extends RefCounted`; costanti-chiave dello schema del record (`KEY_ID`, `KEY_TARGET`, `KEY_EXPOSURE`, `KEY_FRAMES`, `KEY_QUALITY`); `is_photo(ctx: Dictionary) -> bool` (vero se ci sono `exposure_sec` **e** `frame_count`); `from_ctx(ctx: Dictionary, quality: int, index: int) -> Dictionary` che costruisce il record (id derivato da `index`, target/esposizione/frame dal ctx, qualità passata). Logica pura. -- Schema unico del record foto, condiviso da 2.4 (produce) e 2.5 (consuma); dà casa alla domanda «target_id vuoto» (DW-3).
- `night/stacking_reveal.gd` -- `extends Control` (script-only, come `night_summary`), `DESIGN_SIZE (256,192)`, colori fosforo. `set_readout(target: String, quality: int)` unico ingresso. `_process(delta)`: accumula il tempo trascorso e alza la **frazione di emersione** `progress = clampf(_elapsed / REVEAL_SECONDS, 0, 1)` (`REVEAL_SECONDS` costante segnaposto); `queue_redraw()`; quando `progress >= 1` smette di accumulare. `_draw()`: campo di rumore (celle a luminosità pseudo-casuale) che sfuma verso un **segnale segnaposto** (es. un blob luminoso centrale) col crescere di `progress` — emersione, non barra; titolo `STACK` e, a emersione avviata, `QUALITY <n>` in inglese. Nessun accesso a camera/viewport esterni. -- La rivelazione (AC1/AC3).
- `night/night_session.gd` -- (1) `const REVEAL := preload("res://night/stacking_reveal.gd")`; membro `_stacking: Control`; modi salvati per il gating. (2) `has_phase()` → include `_stacking != null`. (3) `_enter_next()`: se `scene == null`, chiamare `_finish_photo_cycle()` invece del ramo attuale. (4) `_finish_photo_cycle()`: se `Photo.is_photo(_ctx)` e `_stacking == null`, `_enter_stacking()`; altrimenti `show_control(null)` + `plan_exhausted.emit()` (comportamento di oggi). (5) `_enter_stacking()`: qualità via `PhotoQuality.new().aggregate(Game.run.phase_scores)`; record via `Photo.from_ctx(_ctx, quality, Game.run.photos.size())` aggiunto a `Game.run.photos`; crea `_stacking = REVEAL.new()`, `set_readout(String(target_id), quality)`, `_crt.show_control(_stacking)`, poi `set_player_present(_player_present)` per il gating. (6) `set_player_present()`: gestire `_stacking.process_mode` come per lo schermo di fase (assente → `DISABLED`, presente → modo salvato/`INHERIT`). (7) `begin()` e `_close_night()`: liberare `_stacking` (come `_summary`) e azzerarlo. -- L'orchestrazione dello stacking, senza nominare nessuna fase.
- `tests/test_bench.gd` -- `_check_photo_quality()` chiamato da `_ready()`: istanzia `PhotoQuality`, stampa `aggregate` su `{polar:80,targeting:60,imaging:100}` (atteso 80), sul caso ereditato `{polar:80,targeting:60,imaging:40}` (atteso 60, con nota che polar/targeting sono ereditati), sul caso a fase sola e sul dizionario vuoto (atteso 0). Segnala con `<-- ATTESO` gli scostamenti, come gli altri check. -- Il banco stampa il comportamento dell'aggregazione sul caso con punteggi ereditati (AC2).

**Acceptance Criteria:**
- Given una sequenza di imaging completata, when il ciclo delle foto si esaurisce, then `night_session` mostra sul CRT un `Control` di rivelazione in cui l'immagine **emerge progressivamente dal rumore** — non una barra con un risultato in fondo.
- Given i punteggi delle fasi in `run.phase_scores`, when si calcola la qualità della foto, then l'aggregazione vive in `photo/quality.gd`, è pura e istanziabile senza `SceneTree`, and le fasi non rifatte ereditano il punteggio dall'ultima esecuzione, and il banco stampa il comportamento su un caso con punteggi ereditati.
- Given la qualità aggregata, when lo stack si conclude, then il punteggio compare come numero **in inglese** accanto all'immagine, and l'immagine **non si degrada con la qualità** (semplificazione MVP dichiarata).
- Given l'imaging finito mentre il giocatore è in un'altra stanza, when la rivelazione è sul CRT, then non avanza finché non ci si risiede alla postazione; al ritorno l'immagine emerge sotto gli occhi (present-gated), and il monitor resta interagibile perché `has_phase()` conta lo stacking.
- Given la foto stackata, when la si registra, then finisce in `Game.run.photos` con target, esposizione, numero di frame e qualità (il canale-dati verso la 2.5), and lo stacking non scrive in `run.phase_scores` né emette `phase_finished`.
- Given lo stacking, when si cerca una dipendenza da `photo/` dentro `phases/` o da `phases/` dentro `photo/`, then non ce n'è nessuna (i confini reggono).

## Spec Change Log

## Review Triage Log

### 2026-08-23 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 2: (high 0, medium 0, low 2)
- defer: 0
- reject: 20
- addressed_findings:
  - `[low]` `[patch]` `Photo.from_ctx` leggeva il target con il letterale grezzo `&"target_id"`, contro il principio dichiarato del file stesso («le chiavi sono costanti»). Aggiunta la costante `CTX_TARGET` in `photo/photo.gd` e usata in `from_ctx`; `night_session._enter_stacking` ora legge `Photo.CTX_TARGET` invece del letterale. Comportamento invariato.
  - `[low]` `[patch]` `Photo.from_ctx` è pura e definisce il contratto del record verso la 2.5, ma il banco collaudava i suoi due fratelli (`aggregate`, `is_photo`) e saltava lei. Aggiunto `_check_photo_record()` al banco: verifica la mappatura dei campi su un ctx pieno e sul caso DW-3 senza `target_id` (stringa vuota). Gate verde.

## Design Notes

**Perché lo stacking è in `night/`, non una fase.** La tabella dei confini vieta a `phases/` di conoscere `photo/`. L'AC2 vuole l'aggregazione in `photo/quality.gd`. Una fase di stacking dovrebbe usarla e violerebbe il confine. `night/` invece può dipendere da `core/`, `photo/` e `crt/`: è l'unico posto legittimo. E c'è già il precedente — `night_summary` è un `Control` di `night/` mostrato sul CRT dall'orchestratore. Lo stacking lo ricalca.

**L'ereditarietà è già nei dati, non serve costruirla.** `night_session._on_phase_finished` scrive `phase_scores[key()] = score` a ogni fase; il dizionario **persiste** fra gli scatti (lo azzera solo `start_night`). Una fase non rifatta per il prossimo scatto lascia intatto il suo punteggio: quando la 2.6 rifarà solo l'imaging, polar e targeting resteranno lì con il valore vecchio. `quality.gd` aggrega il dizionario com'è: l'ereditarietà è la persistenza, non un ramo. Questo chiude anche l'angolo di aggregazione della voce rinviata dalla 2.1 («`phase_scores[key()]` sovrascrive») — sovrascrivere l'ultimo punteggio per chiave *è* l'ereditarietà voluta.

**La rivelazione è present-gated perché l'imaging è in background.** L'imaging può finire mentre il giocatore è in cucina (il chime lo richiama). Se la rivelazione partisse nel vuoto, la troverebbe già finita — contro «sotto gli occhi del giocatore». Gating via `process_mode` come per gli schermi di fase: `_process` avanza solo con `player_present`. Nessun nuovo segnale verso `main`: `has_phase()` conta lo stacking, quindi `_monitor.enabled` (già true dall'avvio dell'imaging) si conserva e il giocatore può risedersi.

**Segnaposto dichiarati.** La formula di aggregazione (media intera) e `REVEAL_SECONDS` sono numeri plausibili, non tarati (FR22). L'immagine emersa è un disegno procedurale di segnaposto: non ci sono asset fotografici, e per decisione (memoria progetto) i segnaposto visivi non si rifiniscono finché non arriva il pack di texture.

**ADR-001 non si applica allo stacking.** ADR-001 governa lo stato osservabile di una *fase* (da `truth.sample`). Lo stacking non è una fase: la qualità è aggregazione pura di output già passati da `truth` (i `phase_scores`), e l'emersione è pura scena. Non c'è bugia da iniettare nello stacking, coerente con «il seam esiste, le bugie no» e col fatto che lo stack non è una delle dieci fasi.

## Verification

**Commands:**
- `godot --headless --path . tests/test_bench.tscn` -- expected: stampa `_check_photo_quality` con 80 / 60 / 80 / 0 e nessuna riga `<-- ATTESO`; il resto del banco invariato fino a `=== fine ===`; nessuna riga `USER ERROR`; exit 0.
- `.bmad-loop/verify.ps1` (cancello dell'orchestratore) -- expected: `VERIFY: pulito`, exit 0 — banco fino in fondo, avvio del gioco senza errori né warning.
- `grep -rn "phases/" photo/` -- expected: zero occorrenze (confine `photo/`↛`phases/`). `grep -rn "photo/" phases/` -- expected: zero occorrenze (confine `phases/`↛`photo/`).

**Manual checks (a schermo):**
- Completato l'imaging, il CRT mostra l'emersione dell'immagine dal rumore, poi `QUALITY <n>` in inglese accanto all'immagine. Camminando via prima che l'imaging finisca e tornando, l'emersione parte al momento in cui ci si risiede, non prima. Con `F1`-`F4` (time_scale) l'emersione accelera.

## Auto Run Result

Status: done
Blocking condition: nessuna

**Sintesi della modifica.** Aggiunto lo stacking della storia 2.4: quando il ciclo delle foto si esaurisce e nel `ctx` c'è una foto, `night_session` calcola la qualità aggregata con `photo/quality.gd` (logica pura), registra il record foto (`photo/photo.gd`) in `Game.run.photos` — il canale-dati verso la 2.5 — e mostra sul CRT un `Control` di rivelazione (`night/stacking_reveal.gd`) in cui l'immagine emerge dal rumore, present-gated così che avvenga sotto gli occhi del giocatore, col punteggio `QUALITY <n>` in inglese. Lo stacking **non è una fase** (il confine `phases/`↛`photo/` lo impone): è `night/` a condurlo, sul modello di `night_summary`. L'immagine non degrada con la qualità (semplificazione MVP dichiarata).

**File nel diff dalla baseline `26b47f9`:**
- `photo/quality.gd` — `PhotoQuality.aggregate(phase_scores)`: media intera dei punteggi, `0` su vuoto; l'ereditarietà è la persistenza di `phase_scores`.
- `photo/photo.gd` — schema del record foto: costanti-chiave, `is_photo(ctx)` (esposizione + frame), `from_ctx(ctx, quality, index)`; `target_id` vuoto ammesso (DW-3).
- `night/stacking_reveal.gd` — `Control` 256×192 sul CRT: emersione rumore→segnale col tempo, `STACK`/`QUALITY <n>` in inglese, segnaposto visivo.
- `night/night_session.gd` — `_finish_photo_cycle`/`_enter_stacking`, `_stacking` tracciato da `has_phase()`, gating in `set_player_present`, liberazione in `begin()` e `_close_night()`; nessun nome di fase compare.
- `tests/test_bench.gd` — `_check_photo_quality`, `_check_photo_schema`, `_check_photo_record`: aggregazione (incl. caso ereditato), `is_photo`, e la mappatura del record.

**Findings della review (4 layer: Blind Hunter, Edge Case Hunter, Verification Gap, Intent Alignment).** Dopo deduplica e classificazione con l'intent come unica autorità di scope: intent_gap 0, bad_spec 0, patch 2 (low), defer 0, reject 20. Patch applicate: letterale `&"target_id"` → costante `CTX_TARGET`; copertura di banco per `from_ctx`. Il cluster più citato — «la qualità si contamina fra scatti» — è un falso positivo: `phase_scores` è indicizzato per `Phase.key()` e **sovrascritto**, mai accumulato, e azzerato da `start_night`; nella 2.4 c'è un solo scatto per notte, e anche con la 2.6 ogni chiave tiene l'ultimo punteggio (che *è* l'ereditarietà dell'AC2). Altri reject: «il giocatore resta bloccato / la notte si impianta sullo stack» (falso: `E` fa rialzare, l'alba chiude la notte e libera la rivelazione), scelte by-design dichiarate (media floor/`REVEAL_SECONDS` segnaposto FR22, `PhotoQuality` istanziabile per convenzione, log in italiano = canale dev, id posizionale append-only), voci già tracciate (DW-3 target vuoto), e concern di verifica inerenti al modello del progetto (il banco prova la matematica pura, non la fase in albero; il «messa in scena» è visivo e si guarda).

**Raccomandazione di follow-up review:** false. Findings `patch` in questo pass: 2 (0 high, 0 medium, 2 low); punteggio 3×0 + 1×2 = 2 < 5, nessuna high → `false`.

**Verifica eseguita:**
- `.bmad-loop/verify.ps1` — `VERIFY: pulito`, exit 0 (banco fino a `=== fine ===`, avvio del gioco senza errori né warning).
- Banco: `_check_photo_quality` stampa 80/60/80/0, `_check_photo_schema` true/false/false, `_check_photo_record` mappa tutti i campi (caso DW-3 con `target_id` vuoto incluso); nessuna riga `<-- ATTESO`.
- Confini: `grep -rn "phases/" photo/` e `grep -rn "photo/" phases/` entrambi a zero.

**Rischi residui:** la logica in-tree dello stacking (avvio della rivelazione, append a `run.photos`, present-gating — righe 5/6/7 della matrice) non è asserita dal banco, coerente col modello del progetto: la copre il cancello all'avvio del gioco più la verifica a schermo. La rivelazione è un segnaposto visivo (nessun asset fotografico) e `REVEAL_SECONDS`/formula di aggregazione sono numeri non tarati (FR22). Un segnale di «rivelazione conclusa» servirà alla 2.6 (menu post-foto), fuori scopo qui.
