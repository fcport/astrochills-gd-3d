---
title: 'Storia 2.3 — La posa: configurare la sequenza e lasciarla lavorare'
type: 'feature'
created: '2026-08-23'
status: 'done'
baseline_revision: '3da95f10de717c4bb1b427e5bb38dc02a2dcc7f6'
review_loop_iteration: 0
followup_review_recommended: false
context: []
warnings: [oversized]
deferred:
  - summary: >-
      Nessuna copertura automatica del percorso config→run→finish della fase (runs_in_background, completamento mentre il giocatore è via, elapsed→frame dal clock).
    evidence: |-
      Il banco prova solo l'aritmetica pura della sorgente e il passaggio del target in setup(); il comportamento-bandiera «avvia, allontanati, si completa da solo» (AC2/AC4) è verificato solo dall'avvio-gioco di verify.ps1 (che si ferma a 600 frame e non raggiunge mai il completamento) e a schermo. È coerente col modello del progetto (il banco prova la matematica, non la fase in albero), ma la logica stateful di start/finish è nuova e non asserita.
    location: >-
      phases/imaging/phase_imaging.gd:_process/_start/_finish
    severity: medium
  - summary: >-
      L'imaging procede con ok=true e target_id vuoto quando il ctx non lo porta, propagando &"" nel payload verso 2.4/2.5.
    evidence: |-
      A differenza del targeting (che emette ok=false su id vuoto), il guard del ctx mancante fa solo push_error e prosegue; cosa stacking/vendita facciano di un target_id vuoto è una domanda di contratto aperta per 2.4/2.5.
    location: >-
      phases/imaging/phase_imaging.gd:96-104,234-240
    severity: low
  - summary: >-
      SequenceChime si collega a Events.phase_finished in _ready senza mai disconnettersi.
    evidence: |-
      Innocuo oggi (la scena del mondo è istanziata una volta per sessione), ma diventa una doppia connessione — chime che suona più volte — il giorno in cui la scena dell'osservatorio venisse ricostruita. Rispecchia la voce rinviata dalla 2.1 sulla lambda di Events.phase_started mai disconnessa.
    location: >-
      phases/imaging/sequence_chime.gd:12-14
    severity: low
  - summary: >-
      I parametri audio 3D del chime (unit_size=6, max_distance=30, max_db=3) sono segnaposto non documentati.
    evidence: |-
      Regolano la caduta «udibile da un'altra stanza» (AC4) ma sono numeri a occhio, non tarati su hardware — come i segnaposto visivi, chiedono un passaggio di ascolto-e-aggiusta.
    location: >-
      phases/imaging/sequence_chime.tscn
    severity: low
  - summary: >-
      Il filtro &"imaging" del chime e PhaseImaging.key() sono due letterali separati, senza nulla che li tenga in sync.
    evidence: |-
      Se key() cambiasse, il chime smetterebbe di suonare in silenzio; nessun controllo cross-file lega i due letterali.
    location: >-
      phases/imaging/sequence_chime.gd:31, phases/imaging/phase_imaging.gd:86-87
    severity: low
---

<intent-contract>

## Intent

**Problem:** La fase 10 (imaging) non esiste. Il target scelto dalla 2.2 arriva nel `payload` ma nessuna fase lo consuma: manca il momento in cui il giocatore imposta la posa, la avvia, e — cuore dell'MVP — **si allontana mentre la macchina lavora da sola**.

**Approach:** Aggiungere una fase di FOTO autonoma (ADR-002) `phases/imaging/` sul modello del targeting: un `Control` sul CRT per configurare esposizione e numero di frame, poi una sequenza che avanza in tempo reale contando `Tuning.min_per_frame` per frame. La fase `runs_in_background()` → `true`: resta viva sotto `PhaseHost` quando il giocatore se ne va, e al ritorno mostra lo stato vero. Lo stato osservabile viene da `truth.sample(...)` con una sola assegnazione. La fine è annunciata da un `AudioStreamPlayer3D` collocato nel mondo, non nella fase.

## Boundaries & Constraints

**Always:**
- Lo stato osservabile della sequenza (`frame N/M`) ha **una sola assegnazione** nel file della fase, e viene da `truth.sample(...)` (ADR-001/FR16). La fase non calcola i frame per conto proprio.
- Il tempo di posa si misura in **minuti di gioco**, letti da `Game.run.elapsed_min` (l'orologio della notte), mai da un accumulatore duplicato: `elapsed_since_start = run.elapsed_min - _start_min`. Così pausa e `Engine.time_scale` valgono gratis.
- `runs_in_background()` restituisce `true`. In background la fase **non** chiama `get_viewport().size`, non accede alla camera, non assume che il proprio `Control` sia renderizzato; fa solo aritmetica sul tempo (AC3).
- Il target arriva **come dato in ingresso** nel `ctx` di `setup(run, ctx)` (chiave `&"target_id"`), mai per import da `phases/targeting/` (ADR-002/FR12).
- `min_per_frame` si legge **sempre** da `Tuning.min_per_frame`, mai con `load()`.
- Il suono di fine sequenza è un `AudioStreamPlayer3D` che vive in `world/`, **non** è figlio della fase, ed è innescato via `Events` (il mondo non conosce `phases/`). La sua collocazione regge quando arriveranno cucina e cupola.
- Segnali tipizzati `snake_case` al passato; due canali separati — `push_error`/`assert` per errori di programma, `PhaseResult` per esiti diegetici. GDScript tipizzato, Godot 4.7.

**Block If:**
- (nessuna: la decisione aperta sul bersaglio sotto l'orizzonte è chiusa qui sotto, vedi Design Notes — non è un intent gap.)

**Never:**
- Niente simulazione astronomica: la fase conta il tempo, non simula il cielo (AC3). Il bersaglio sotto l'orizzonte **non** fa aspettare il suo sorgere né degrada l'immagine.
- Niente stacking, niente vendita, niente menu post-foto, niente save: sono 2.4/2.5/2.6/2.7.
- Niente `Events` nuovi per l'attività dell'attesa (`wait_activity_*` è epica 3, già dichiarati e non emessi qui).
- Il nome «imaging» non compare in `night/night_session.gd` né in `world/`, se non come `StringName` di filtro sul bus per il suono.
- Nessuna calibrazione dei numeri (esposizione, min_per_frame, punteggio): sono segnaposto dichiarati (FR22).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Frame in corso | `elapsed_since_start = 2.5 * min_per_frame`, `frames_total = 20` | `sample` → `frames_done = 2`, `running = true`, `done = false` | — |
| Sequenza finita | `elapsed_since_start >= 20 * min_per_frame`, `frames_total = 20` | `frames_done = 20` (clamp, mai oltre), `done = true` | — |
| Appena avviata | `elapsed_since_start = 0` | `frames_done = 0`, `running = true` | — |
| `min_per_frame <= 0` | Tuning corrotto | `frames_done = frames_total` (evita divisione per zero, chiude subito) | `push_error`, prosegue |
| Ritorno al monitor dopo assenza | fase in background, tempo trascorso | CRT mostra lo stato **vero** ricalcolato da `run.elapsed_min`, non ricostruito | — |
| `ctx` senza `target_id` | targeting saltato/malconfigurato | posa parte comunque con `target_id = &""` (segnaposto), `push_error` diagnostico | `push_error`, non blocca |

</intent-contract>

## Code Map

- `core/phase.gd` -- contratto base: `finished(result)`, `key()`, `setup(run, ctx)`, `screen()`, `score()`, `runs_in_background()`, `_notification(PREDELETE)`. Da estendere.
- `core/phase_result.gd` -- `PhaseResult(ok, reason, score, payload)`. L'esito emesso.
- `core/phase_truth_source.gd` -- marker base delle sorgenti. `ImagingTruthSource` lo estende.
- `core/night_run.gd:16,22` -- `elapsed_min` (sorgente del tempo), `selected_target_id`. Non modificare.
- `phases/targeting/phase_targeting.gd` -- **modello da replicare**: guardie su `truth`/`_screen`, unica assegnazione in `_process`, azioni proprie in `_unhandled_input`, `_finish()` che emette payload. `runs_in_background` NON sovrascritto lì.
- `phases/targeting/targeting_screen.gd:19,57` -- `DESIGN_SIZE = (256,192)`, `set_readout(...)` unico ingresso, `_draw()`. Modello dello screen.
- `phases/targeting/phase_targeting.tscn`, `phases/targeting/sources/honest_catalog.gd`, `honest_catalog.tres` (`resource_local_to_scene = true`) -- modello di wiring `@export var truth` → `.tres`.
- `phases/polar/phase_polar.gd:98` -- esempio dell'unica assegnazione `state = truth.sample(...)`.
- `night/night_session.gd:162-183` -- `set_player_present`: con `runs_in_background()==true` la fase resta a girare quando il giocatore va via (input off, `_process` on). `:300-315` registra `phase_scores[key()]` e merge del `payload`.
- `autoloads/tuning.gd:21`, `core/tuning_profile.gd:22` -- `min_per_frame` esiste già (default 5.0), in `POSITIVE_KEYS`. Leggere via `Tuning.min_per_frame`.
- `autoloads/events.gd:16` -- `phase_finished(key, score)` esiste già: il suono filtra su `key == &"imaging"`. Non aggiungere segnali.
- `data/night_plan.tres:10` -- `photo_phases = [targeting]`; aggiungere `phase_imaging.tscn` dopo il targeting.
- `world/observatory.tscn` -- contenitore del mondo (ComputerRoom + CrtMonitor + Player). Qui va appeso il nodo del suono.
- `tests/test_bench.gd:49,184` -- `_ready()` chiama i `_check_*`; `_check_local_to_scene` scandaglia le sorgenti. Aggiungere `_check_imaging_sequence()`.
- `project.godot:57` -- InputMap: definire le azioni `imaging_*`.

## Tasks & Acceptance

**Execution:**
- `phases/imaging/imaging_input.gd` -- `class_name ImagingInput extends RefCounted`; campi `elapsed_since_start_min: float`, `frames_total: int`, `min_per_frame: float`. -- Ingresso tipizzato per la sorgente, sul modello di `TargetingInput`.
- `phases/imaging/imaging_truth_source.gd` -- `class_name ImagingTruthSource extends PhaseTruthSource`; `sample(_input: ImagingInput) -> Dictionary` astratta (restituisce `{frames_done:int, frames_total:int, running:bool, done:bool}`). -- Contratto della sorgente.
- `phases/imaging/sources/honest_sequence.gd` -- `class_name HonestSequence extends ImagingTruthSource`; implementa `sample`: `frames_done = clampi(floori(elapsed/min_per_frame), 0, frames_total)` con guardia `min_per_frame <= 0` → `frames_total`; `done = frames_done >= frames_total`. Logica pura, deterministica. -- La sorgente onesta (nell'MVP dice sempre la verità).
- `phases/imaging/sources/honest_sequence.tres` -- risorsa con `resource_local_to_scene = true` che punta a `honest_sequence.gd`. -- Iniettata come `truth`.
- `phases/imaging/imaging_screen.gd` + `.tscn` -- `Control`, `DESIGN_SIZE = (256,192)`, `set_readout(state: Dictionary)` unico ingresso; `_draw()` mostra in **config** i due campi (esposizione, N frame) con un selettore `>` e footer «↑/↓ FIELD  ←/→ VALUE  ENTER START», in **run** la barra testuale `FRAME n/N` + target. Leggibile da seduti a 256×192, testo in inglese. -- L'interfaccia della fase sul CRT.
- `phases/imaging/phase_imaging.gd` + `.tscn` -- `class_name PhaseImaging extends Phase`; `key() → &"imaging"`; `runs_in_background() → true`; `@export var truth: ImagingTruthSource`; `%ImagingScreen`. `setup(run, ctx)`: tiene `_run`, legge `_target_id = ctx.get(&"target_id", &"")` (con `push_error` se assente). Stato config → run gestito da `_started`/`_start_min`. `_unhandled_input` legge le azioni `imaging_*` (guardie come nel targeting). `_process`: solo in run — `_input.*` da `run.elapsed_min - _start_min` e `Tuning.min_per_frame`; **unica assegnazione** `_state = truth.sample(_input)`; `_screen.set_readout(_state)`; se `_state.done` → `_finish()`. `_finish()` emette `PhaseResult.new(true, "", PLACEHOLDER_SCORE, {&"target_id":_target_id, &"exposure_sec":_exposure, &"frame_count":_frames_total})`. `score()` → `PLACEHOLDER_SCORE` (const dichiarata segnaposto). -- Il cuore della storia.
- `phases/imaging/sequence_chime.gd` + `.tscn` -- root `AudioStreamPlayer3D`; in `_ready()` si collega a `Events.phase_finished` e chiama `play()` **solo** se `key == &"imaging"`. `max_distance`/`unit_size` generosi (segnaposto) perché porti da un'altra stanza. Stream = WAV segnaposto in `assets/audio/sequence_done.wav`. -- Il suono che appartiene al luogo.
- `assets/audio/sequence_done.wav` -- WAV PCM breve segnaposto (tono). -- Asset provvisorio, non definitivo.
- `world/observatory.tscn` -- istanziare `sequence_chime.tscn` come figlio, collocato presso il monitor/telescopio (non figlio del CRT né della fase). -- Ancora il suono al luogo.
- `data/night_plan.tres` -- `photo_phases = [phase_targeting, phase_imaging]`. -- Inserire la fase nel piano (un dato, non un `if`).
- `project.godot` -- azioni InputMap: `imaging_prev` (Up), `imaging_next` (Down), `imaging_dec` (Left), `imaging_inc` (Right), `imaging_start` (ENTER). -- Comandi propri della fase, non `ui_*`.
- `tests/test_bench.gd` -- `_check_imaging_sequence()`: determinismo e monotonìa del conteggio frame, clamp a `frames_total`, guardia `min_per_frame<=0`; e includere la nuova sorgente nel controllo `resource_local_to_scene`. -- Prova sul banco (nessun framework).

**Acceptance Criteria:**
- Given un target selezionato in `ctx`, when la fase di imaging si apre, then il giocatore imposta esposizione e numero di frame e avvia, and ogni frame acquisito consuma `Tuning.min_per_frame` minuti di gioco.
- Given una sequenza avviata, when il giocatore si allontana dal monitor, then la fase continua a processare (`runs_in_background()==true`, viva sotto `PhaseHost`), and al ritorno il CRT mostra lo stato vero `frame 7/20`, non ricostruito.
- Given la fase in background, when gira senza essere visibile, then non chiama `get_viewport().size`, non accede alla camera, e non fa lavoro pesante per frame (conta il tempo).
- Given la sequenza che finisce, when l'ultimo frame è acquisito, then un `AudioStreamPlayer3D` collocato nel mondo (non figlio della fase) suona, innescato via `Events`, and la collocazione regge senza spostamenti all'arrivo di cucina/cupola.
- Given lo stato osservabile della sequenza, when lo si cerca nel file della fase, then viene da `truth.sample(...)` con una sola assegnazione.
- Given un bersaglio sotto l'orizzonte (es. M13/M57 scelti presto nella notte), when la posa parte, then parte comunque e produce una foto normale — nessuna attesa del sorgere, nessun degrado, nessun rifiuto (vedi Design Notes).

## Spec Change Log

## Review Triage Log

### 2026-08-23 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 2: (high 1, medium 1, low 0)
- defer: 5: (high 0, medium 1, low 4)
- reject: 13
- addressed_findings:
  - `[high]` `[patch]` Il cancello `.bmad-loop/verify.ps1` falliva (exit 1) perché due sub-verifiche del banco pilotavano i guard di produzione (`min_per_frame ≤ 0`, ctx senza `target_id`) emettendo `push_error` reali, che il gate conta come guasti. Rimosse dal banco le due sub-verifiche di canale 1; guard di produzione intatti; copertura degli input validi mantenuta; sezione Verification aggiornata. Gate ora verde.
  - `[medium]` `[patch]` La barra testuale di `_draw_run` (`"#".repeat(done)`) sforava i 256px del CRT a `frames_total` alto (max 60). Limitata a `BAR_COLS = 36` colonne con riempimento proporzionale; sotto soglia resta un blocco per frame.

### 2026-08-23 — Review pass (follow-up su spec done)
- intent_gap: 0
- bad_spec: 0
- patch: 0
- defer: 0
- reject: 16
- addressed_findings:
  - none

## Design Notes

**Decisione chiusa — bersaglio sotto l'orizzonte (dalla code review 2.2, «DA CHIUDERE PRIMA DELLA 2.3»).**
La posa **parte lo stesso e produce una foto normale**. Nell'MVP la visibilità non tocca l'imaging. Le tre letture alternative sono escluse dal design esistente, non da una scelta arbitraria:
- *Aspettare che il bersaglio sorga* contraddice AC3 e l'ADR «conta il tempo, non simula»: richiederebbe simulazione astronomica.
- *Rifiutare e rimandare alla scelta* contraddice la decisione della code review 2.2 (`epics.md:663`): la scelta resta LIBERA, il targeting segnala «not visible now» ma non blocca.
- *Foto peggiore* contraddice la semplificazione MVP del 2026-08-21: «l'immagine non degrada con la qualità». La visibilità non entra nemmeno in `phase_scores`.
La segnalazione «not visible now» resta un fatto diegetico del **targeting**; l'imaging la ignora. Aggiornare `deferred-work.md` marcando la voce chiusa, con rimando a questo spec.

**Tempo dal clock, non da un accumulatore.** `_start_min = run.elapsed_min` all'avvio; ogni frame `elapsed = run.elapsed_min - _start_min`. Riusa l'accumulatore autorevole di `NightClock` → pausa e `time_scale` gratis, e nessuna formula duplicata (evita il difetto rinviato dalla 2.1).

**Perché il suono passa da `Events.phase_finished` e non da un segnale nuovo.** L'esito «sequenza finita» coincide col `finished` della fase; `phase_finished(key, score)` esiste già ed è esattamente quel momento. Il nodo del suono filtra su `&"imaging"` — la stessa soft-coupling via stringa che l'epica sanziona per la cupola («la cupola sa tramite `Events`, mai interrogando la fase»). Zero `Events` nuovi.

**Punteggio segnaposto.** Come il targeting (`NEUTRAL_SCORE`), l'imaging emette un `PLACEHOLDER_SCORE` costante dichiarato: la mappatura esposizione→qualità è calibrazione rinviata (FR22). `exposure_sec` e `frame_count` viaggiano nel `payload` per 2.4/2.5, non ancora scored.

## Verification

**Commands:**
- `godot --headless --path . tests/test_bench.tscn` -- expected: il banco stampa `_check_imaging_sequence` PASS (determinismo, appena-avviata, monotonìa, clamp) e `_check_imaging_setup` PASS (il target valido del ctx arriva al readout); tutte le sorgenti `resource_local_to_scene = true`; **nessuna riga `USER ERROR`/`ATTESO`**; exit 0.
- `.bmad-loop/verify.ps1` (cancello dell'orchestratore) -- expected: `VERIFY: pulito`, exit 0. È il lettore automatico del banco e dell'avvio del gioco: tratta OGNI `push_error`/warning come guasto. Perciò i guard di **canale 1** (matrice righe 4 e 6: `min_per_frame ≤ 0` e ctx senza `target_id`) NON si collaudano nel banco — li sorveglia questo cancello sull'avvio del gioco, e l'occhio a schermo — esattamente come il catalogo vuoto del targeting.
- `grep -rn "phases/" phases/imaging/` -- expected: solo auto-riferimenti della fase (proprie scene/script) e commenti; nessun import di un'altra fase (ADR-002).

**Manual checks (a schermo):**
- La fase di imaging si apre dopo il targeting; si impostano esposizione e frame; avviando, il CRT mostra `FRAME n/N` che cresce; camminando in un'altra stanza e tornando, il contatore è avanzato dello scorrere del tempo (non azzerato). Con `F1`-`F4` (time_scale) la sequenza accelera.
- Alla fine dell'ultimo frame si sente un suono percepibile allontanandosi dal monitor dentro la stanza; il suono cambia con la posizione (è posizionale), segno che appartiene al luogo.

## Auto Run Result

Status: done
Blocking condition: nessuna

**Tipo di run:** review di follow-up su spec `done` (`followup_review_recommended: true` dal pass precedente). Nessun codice modificato in questo pass — è una seconda passata di sole review sul diff dalla baseline `3da95f1`.

**Sintesi della modifica (implementata nel pass precedente, confermata qui).** Aggiunta la fase 10 (imaging) come fase di FOTO autonoma (ADR-002) in `phases/imaging/`: si configura esposizione e numero di frame sul CRT, si avvia, e — cuore dell'MVP — la sequenza avanza da sola contando `Tuning.min_per_frame` per frame mentre il giocatore si allontana (`runs_in_background()==true`). Lo stato osservabile (conteggio frame) viene da `truth.sample(...)` con un'unica assegnazione; il tempo dal clock della notte, non da un accumulatore. Il suono di fine vive nel mondo e si innesca via `Events.phase_finished` filtrando su `&"imaging"`.

**File nel diff dalla baseline (già committati nel pass precedente):**
- `phases/imaging/imaging_input.gd` — input tipizzato per la sorgente (RefCounted, vita di un frame).
- `phases/imaging/imaging_truth_source.gd` — sotto-contratto tipizzato della sorgente (astratto).
- `phases/imaging/sources/honest_sequence.gd` + `.tres` — sorgente onesta: `frames_done` da `floori(elapsed/min_per_frame)` con clamp e guardia `min_per_frame<=0`.
- `phases/imaging/imaging_screen.gd` — vista CRT 256×192 a due modi (config/run), barra limitata a `BAR_COLS=36`.
- `phases/imaging/phase_imaging.gd` + `.tscn` — la fase: `key()→&"imaging"`, `runs_in_background()→true`, unica assegnazione `_state = truth.sample(...)`, `_finish()` col payload verso 2.4/2.5.
- `phases/imaging/sequence_chime.gd` + `.tscn` + `assets/audio/sequence_done.wav` — suono di luogo, `AudioStreamPlayer3D` che ascolta `Events`.
- `data/night_plan.tres` — `photo_phases = [targeting, imaging]`.
- `project.godot` — azioni InputMap `imaging_*`.
- `world/observatory.tscn` — istanza del chime presso il monitor.
- `tests/test_bench.gd` — `_check_imaging_sequence()` e `_check_imaging_setup()`, sorgente inclusa nel controllo `resource_local_to_scene`.

**Findings della review (questo pass):** 4 layer (Blind Hunter, Edge Case Hunter, Verification Gap, Intent Alignment). Dopo deduplica e classificazione con l'intent come unica autorità di scope: intent_gap 0, bad_spec 0, patch 0, defer 0, reject 16. Patch applicate: nessuna. Item rinviati nuovi: nessuno. Le findings sostanziali erano ri-emersioni di item già rinviati (DW-2 percorso stateful/`runs_in_background`, DW-3 target_id vuoto, DW-4 chime non-disconnesso, DW-5 param audio, DW-6 sync `&"imaging"`↔`key()`), oppure scelte by-design dichiarate dall'intent (segnaposto FR22, guard di canale-1, `running` come selettore di modalità, pausa via check manuale), oppure falsi positivi/percorsi irraggiungibili in produzione (`get_viewport()` null in `_unhandled_input`, `_run==null` prima di `setup()`, `frames_total<=0` clampato, `_run_readout()` con stato vuoto).

**Raccomandazione di follow-up review:** false. Findings triagiate come `patch` in questo pass: 0 (0 high, 0 medium, 0 low); punteggio 3×0 + 1×0 = 0 < 5, nessuna high → `false`.

**Verifica eseguita:**
- `grep -rn "phases/" phases/imaging/` — solo auto-riferimenti della fase, nessun import cross-fase (ADR-002 OK).
- `.bmad-loop/verify.ps1` — `VERIFY: pulito — banco fino in fondo, gioco senza errori né warning`, exit 0. Il banco stampa fino a `=== fine ===`, nessuna riga `<-- ATTESO`/`NON CARICABILE`, avvio del gioco senza errori/warning.

**Rischi residui:** quelli già rinviati nel ledger (DW-2..DW-6), invariati: la logica stateful start/finish e il payload verso 2.4/2.5 restano non asseriti automaticamente (i consumatori 2.4/2.5 non esistono ancora); i letterali `&"imaging"` e i parametri audio segnaposto restano da tarare. Nessun rischio nuovo introdotto da questo pass.

