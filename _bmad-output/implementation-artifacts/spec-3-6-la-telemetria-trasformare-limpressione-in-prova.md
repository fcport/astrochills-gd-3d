---
title: "3.6 La telemetria — trasformare l'impressione in prova"
type: 'feature'
created: '2026-08-24'
status: 'awaiting-operator'
baseline_revision: '854125b0120e2a9084ee437d201b4833ce733fdd'
review_loop_iteration: 0
followup_review_recommended: true
operator_actions:
  - "Giocare una notte fino all'alba, poi aprire `%APPDATA%/Godot/app_userdata/Astrochill/telemetry/night-<i>.json`: confermare che è JSON leggibile con i sei campi (`night`, `tuning_hash`, `wait_total_min`, `wait_activities[]`, `menu_reopened`, `quit_mid_pose`), che `wait_activities[]` contiene voci `caffe`/`lampada`/`cupola`/`forum`/`idle` con `t`/`dur` in minuti di gioco, e che `quit_mid_pose` è `false` all'alba."
  - "Chiudere la finestra dell'applicazione MENTRE una posa è in corso e riaprire il file risultante: confermare che esiste e che `quit_mid_pose` è `true`. È il secondo momento di scrittura: la notifica `NOTIFICATION_WM_CLOSE_REQUEST` arriva solo con una finestra vera, non in headless."
  - "Giocare due notti con `tuning_override.cfg` diversi e confrontare i due file: `tuning_hash` presente in entrambi e diverso (senza, le notti non sono confrontabili)."
  - "Con l'overlay `F12` acceso e una posa in corso, confermare che appare la riga `posa … min   scoperti … min`, che mostra i minuti della finestra e quelli scoperti e cambia dal vivo; e che fuori da una posa la riga è assente."
  - "Provocare un abbandono (es. aprire la BBS e uscire senza chiuderla, oppure entrare in cupola oltre la soglia e uscire dal gioco) e confermare che nel file l'attività compare con `dur: null` e `abandoned: true`, non omessa; e che i tratti `idle` coprono il resto della finestra di posa."
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/c3-dossier-telemetria.md'
warnings: ['oversized']
deferred:
  - summary: >-
      Il cablaggio runtime della telemetria — le connessioni ai segnali del bus, gli
      handler `_on_*`, la chiusura della finestra aperta a `now` in `_write`, l'idempotenza
      per notte (gating su `_active`), il percorso `NOTIFICATION_WM_CLOSE_REQUEST`, la
      catena emit→conteggio di `photo_menu_opened`, e la riga dell'overlay F12 — NON è
      esercitato dal banco: lo sono solo le funzioni pure (`merge_intervals`,
      `idle_segments`, `build_report`, `uncovered_min`).
    evidence: |-
      `tests/test_bench.gd::_check_telemetry` chiama solo le statiche `TELEMETRY.merge_intervals`
      / `idle_segments` / `build_report` / `uncovered_min` (preload dello script, non
      l'autoload): nessuna connessione a `Events`, nessuna scrittura su disco, nessuna
      notifica di chiusura. Rompere una `.connect` in `_ready`, il conteggio in
      `_on_menu_opened`, la chiusura della posa aperta in `_write`, o il gate `_active`
      lascerebbe il banco verde. È la stessa classe di gap accettata per moka (DW-15),
      lampada (DW-16) e cupola (spec 3.5): la convenzione del banco è logica pura (NFR19).
      Il file su disco, il secondo momento di scrittura (`quit_mid_pose`, la cui notifica
      in headless non arriva) e la leggibilità della riga F12 sono verifiche d'operatore.
    location: >-
      autoloads/telemetry.gd:38-52 (connessioni), :84-138 (_on_*), :172-193 (_write/_notification) ; night/night_session.gd:_enter_menu ; tests/test_bench.gd::_check_telemetry
    severity: medium
---

<intent-contract>

## Intent

**Problem:** L'MVP esiste per misurare un'ipotesi — *l'attesa della posa è piacevole* — e finora non c'è nulla che la misuri: tre notti giocate restano tre impressioni, non tre dati confrontabili. I quattro emettitori dell'attesa (`caffe`, `lampada`, `cupola`, `forum`) mandano già le coppie `wait_activity_started/ended` sul bus, e la finestra della posa è già annunciata da `sequence_started/ended`, ma **nessuno ascolta**: il condotto è posato e non ha un capo (rilievo C3, chiuso il 2026-08-24 assegnando il proprietario).

**Approach:** Un **quinto autoload**, `autoloads/telemetry.gd`, che **ascolta il bus e basta**. Accumula, con timestamp in **minuti di gioco** (`Game.run.elapsed_min`), le finestre di posa (`sequence_started/ended`) e gli intervalli delle quattro attività (`wait_activity_started/ended`); conta le aperture del menu post-foto (nuovo segnale `Events.photo_menu_opened`); all'alba (`dawn_reached`) e alla chiusura dell'app a notte aperta (`NOTIFICATION_WM_CLOSE_REQUEST`) scrive un file JSON per notte in `user://telemetry/`. Il dato più importante — i tratti `idle` — si calcola **per differenza** sull'**unione** degli intervalli dentro le finestre di posa. Tutta l'aritmetica (unione intervalli, idle, assemblaggio del report) è in **funzioni pure statiche** collaudate sul banco; l'autoload è solo il cablaggio. L'overlay `F12` mostra dal vivo l'attesa della posa in corso e quanta ne è scoperta, leggendo **da** `Telemetry`, mai il contrario.

## Boundaries & Constraints

**Always:**
- La finestra della posa viene **SOLO** da `Events.sequence_started` / `sequence_ended`, **non** da `phase_started(&"imaging")`. È la correzione del 2026-08-24 (commit `854125b`, deferred-work.md §sequence): `phase_started` scatta al **montaggio** del pannello di configurazione, e usarlo farebbe misurare come attesa vissuta il tempo in cui **nessuna posa esiste** — l'errore che `sequence_started/ended` sono stati creati per chiudere. `sequence_ended` arriva **sempre e una volta sola** (fine posa, alba a posa in corso, *rifai setup*).
- `t` e `dur` sono **minuti di gioco** dall'inizio della notte (`Game.run.elapsed_min`), mai secondi reali: con `game_min_per_sec` diverso fra due notti i secondi non sarebbero confrontabili. È la ragione per cui `tuning_hash` (= `Tuning.profile_hash`) è **obbligatorio** nel file.
- L'identità della notte (`night` = `night_index`, `tuning_hash`) si **cattura all'inizio della notte** su `phase_started`, non alla scrittura: `Game.end_night()` azzera `Game.run` **prima** che `dawn_reached` sia emesso (night_session.gd:933→938), quindi all'alba `Game.run` è `null`. Ogni timestamp si legge all'**arrivo** dell'evento (posa/attività/menu emettono sempre a notte aperta), mai a fine notte.
- `idle` si calcola **per differenza sull'UNIONE** degli intervalli dentro le finestre di posa, non sulla somma: caffè sul fuoco mentre si sale in cupola è il caso normale; gli intervalli si **uniscono**. I tratti `idle` sono voci di `wait_activities[]` con `what: "idle"`.
- Un'attività `started` senza `ended` compare con `dur: null` e `abandoned: true`, **non viene omessa**. Una finestra di posa aperta alla scrittura (quit a metà) si chiude a `elapsed_min` corrente ai fini di `wait_total_min`/`idle`, e `quit_mid_pose` è `true`.
- Un'attività cominciata **fuori** da una finestra di posa è registrata lo stesso (con la sua `t`/`dur`); è solo `idle` che si calcola sulle sole finestre di posa.
- Il file si scrive in **due momenti**: all'alba (`quit_mid_pose: false`) e alla chiusura dell'app a notte aperta (`quit_mid_pose` vero se una posa era aperta). Scrittura idempotente per notte: chi ha già scritto la notte non riscrive.
- `wait_total_min` è la somma delle finestre di posa della notte, non la durata della notte.
- L'emissione/ascolto **non** produce mai feedback visibile nel gioco; l'unico lettore di `Telemetry` è `debug/` (dev-only, tagliato in release).

**Block If:**
- Nessuna decisione umana è richiesta: proprietario deciso (C3), segnali sorgente già sul bus, `tuning_hash`/`night_index`/`elapsed_min` già disponibili. Non bloccare.

**Never:**
- Nessuna rete, nessun dato personale, nessun `FileAccess` fuori da `autoloads/telemetry.gd` per la telemetria: offline per costruzione.
- **Nessun altro file di gameplay nomina `Telemetry`**: togliendolo dagli autoload il gioco resta identico. L'unica eccezione è `debug/debug_overlay.gd`, che **legge** da `Telemetry` (mai il contrario) — la dipendenza va nella direzione che si taglia in release senza toccare la misura (C3).
- La telemetria **non passa da `Log`**: `Log` è logging tecnico senza stato; questa è un oggetto JSON per notte con stato accumulato. Non aggiungere stato per-notte a `Log`.
- Nessun bonus/effetto di gioco: lo strumento di misura non deve poter cambiare ciò che misura. Non tocca `Game`/`NightRun`/punteggi, non emette nessun segnale sul bus (a parte il nuovo `photo_menu_opened`, che è emesso da `night/`, non da `Telemetry`).
- L'autoload **non assume di essere visibile**: niente `get_viewport()`, niente camera.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Notte normale all'alba | posa(e) + attività, `dawn_reached` | scrive `night-<i>.json`: `night`, `tuning_hash`, `wait_total_min`, `wait_activities[]`, `menu_reopened`, `quit_mid_pose:false` | `Game.run` è null all'alba → usa identità catturata |
| Attività dentro la posa | `wait_activity_started/ended(&"caffe")` durante `sequence_*` | voce `{what:"caffe", t, dur}` in minuti di gioco | ended senza started aperto → ignorato |
| Attività abbandonata | `started` senza `ended` alla scrittura | `{what, t, dur:null, abandoned:true}` — non omessa | — |
| Due attività sovrapposte | intervalli che si accavallano nella posa | idle = posa − **unione** (non somma); nessun idle negativo | — |
| Tratto vuoto nella posa | posa senza attività coperte in un segmento | voce `{what:"idle", t, dur}` per ogni segmento scoperto | — |
| Attività fuori posa | `started/ended` senza `sequence_*` attivo | voce registrata lo stesso; **non** conta per `idle` | — |
| Quit a posa in corso | chiusura app, `sequence_started` senza `ended` | file scritto, `quit_mid_pose:true`, posa chiusa a `elapsed_min` corrente | run ancora non-null al quit → leggibile |
| Menu post-foto presentato | `Events.photo_menu_opened` | `menu_reopened` += 1 | riapertura *chiudi ed esplora* conta ogni presentazione |
| Overlay F12 durante posa | posa in corso, overlay acceso | riga: minuti della finestra e minuti scoperti, dal vivo | nessuna posa → riga assente/neutra |
| Notte senza attività | posa(e), zero attività | file valido; `wait_activities[]` = solo `idle` che copre le pose | — |

</intent-contract>

## Code Map

- `autoloads/telemetry.gd` -- **NEW.** `extends Node`, nessun `class_name` (nessuno lo tipizza). `_ready()`: `DirAccess.make_dir_recursive_absolute("user://telemetry")`; connette `Events.phase_started` (solo cattura identità), `sequence_started`/`sequence_ended` (finestre posa), `wait_activity_started`/`wait_activity_ended` (attività), `photo_menu_opened` (conteggio), `dawn_reached` (scrittura). Stato per-notte: `_active:bool`, `_night:int`, `_tuning:String`, `_pose_windows:Array` (`[t,end]`), `_open_pose:float=-1`, `_activities:Array` (`{what,t,end}` con record aperti a `end=-1`), `_menu_count:int`. `_now() -> float` = `Game.run.elapsed_min if Game.run != null else <ultimo noto>`. `_begin_night()` (idempotente, su `phase_started` se `_active==false` o `night_index` cambiato): cattura `_night`/`_tuning`, azzera accumulatori. `_write(quit_mid_pose)`: `JSON.stringify(build_report(...), "  ")` → `FileAccess.open("user://telemetry/night-%d.json" % _night, WRITE)`; poi `_active=false`. `_notification(NOTIFICATION_WM_CLOSE_REQUEST)`: se `_active`, `_write(_open_pose >= 0.0)`. **Funzioni pure statiche** (per il banco): `merge_intervals(a:Array)->Array`, `idle_segments(windows:Array, covered:Array)->Array`, `build_report(night, tuning, windows, activities, menu, quit, now)->Dictionary`. Accessori per l'overlay: `current_pose_min()->float`, `current_pose_uncovered_min()->float` (−1 se nessuna posa).
- `autoloads/events.gd` -- **estendere.** Aggiungere `signal photo_menu_opened()` dopo `item_purchased` (riga 67). Doc: sul bus e non diretto per la stessa ragione di `wait_activity_*` (chi è misurato non conosce chi misura; senza ascoltatori cade nel vuoto). Gli altri segnali usati (`phase_started`:15, `sequence_started/ended`:55-56, `wait_activity_started/ended`:34-35, `dawn_reached`:19) **esistono già** — non toccarli.
- `project.godot` -- **estendere.** Sezione `[autoload]` (righe 20-23): aggiungere `Telemetry="*res://autoloads/telemetry.gd"` **dopo** `Tuning` (quinto). L'ordine conta: dipende da `Game`/`Events`/`Tuning`, che vanno prima.
- `night/night_session.gd` -- **estendere (una riga).** In `_enter_menu()`, **dopo** `set_player_present(_player_present)` (riga 640) e la guardia `_menu` (riga 626), aggiungere `Events.photo_menu_opened.emit()`. È il punto dove il menu è davvero presentato (`_crt.show_control(_menu)` a 636), incluso il caso *chiudi ed esplora* che riapre. Le emissioni di `phase_started`(772), `phase_finished`(800), `dawn_reached`(938) e l'azzeramento di `Game.run` in `end_night()` sono **read-only, evidenza**: la telemetria si aggancia senza toccarli.
- `debug/debug_overlay.gd` -- **estendere.** In `_lines()` (righe 63-93), dopo la riga `tuning` (86), aggiungere una riga che legge `Telemetry.current_pose_min()`/`current_pose_uncovered_min()` — mostrata solo se `>= 0`. Legge un autoload come già fa con `Game`/`Tuning`/`Engine`: nessuna dipendenza inversa. `debug/` legge `Telemetry`, mai viceversa.
- `autoloads/log.gd` -- **read-only, MODELLO** di scrittura file: `DirAccess.make_dir_recursive_absolute` (riga 19) + `FileAccess.open(..., WRITE)` + `f.close()` (45-52). La telemetria ricalca lo schema ma su `user://telemetry/` e con `WRITE` pieno (un file per notte, non append). **NON** passa da `Log`.
- `autoloads/tuning.gd` -- **read-only.** `profile_hash: String` (riga 31), calcolato in `_ready()` sul profilo effettivo (override incluso): `Tuning.profile_hash`.
- `autoloads/game.gd` -- **read-only.** `run: NightRun` (16); `run.night_index` (41); `end_night()` fa `run = null` (155). L'identità va catturata prima dell'alba.
- `night/night_clock.gd` -- **read-only.** `elapsed_min()` (111) = `Game.run.elapsed_min`: minuti di gioco dall'inizio della notte, azzerati ogni notte (nuova `NightRun`).
- `world/dome_activity.gd` / `world/telescope.gd` / `phases/imaging/phase_imaging.gd` -- **read-only, evidenza** che le pose usano già `sequence_started/ended` (imaging le emette a 294/309/356; la cupola le ascolta): la telemetria ascolta gli **stessi** segnali, coerente col mondo.
- `tests/test_bench.gd` -- **estendere.** Nuovo `_check_telemetry()` chiamato da `_ready()` (dopo `_check_dome_presence`): tavole di `merge_intervals`, `idle_segments`, `build_report`. Logica pura, no SceneTree, no autoload istanziati. Vedi Verification.

## Tasks & Acceptance

**Execution:**
- `autoloads/events.gd` -- aggiungere `signal photo_menu_opened()` con doc -- il condotto di `menu_reopened`: il menu `extends Control`, non `Phase`, e oggi nessun segnale annuncia che è stato aperto.
- `night/night_session.gd` -- emettere `Events.photo_menu_opened.emit()` in `_enter_menu()` dopo la presentazione del menu -- ogni presentazione (inclusa la riapertura *chiudi ed esplora*) è un conteggio; `night/` dichiara il fatto, non conosce chi conta.
- `autoloads/telemetry.gd` -- creare il quinto autoload: accumula finestre posa (`sequence_*`) e intervalli attività (`wait_activity_*`) con `t`/`dur` in minuti di gioco; cattura identità su `phase_started`; conta `photo_menu_opened`; scrive JSON all'alba e alla chiusura app (`quit_mid_pose`); funzioni pure `merge_intervals`/`idle_segments`/`build_report`; accessori `current_pose_min`/`current_pose_uncovered_min` -- è il capo del condotto C3, e ascolta il bus e basta.
- `project.godot` -- registrare `Telemetry` come quinto autoload dopo `Tuning` -- l'ordine rispetta le dipendenze (`Game`/`Events`/`Tuning` prima).
- `debug/debug_overlay.gd` -- aggiungere la riga F12 che legge da `Telemetry` i minuti della posa in corso e quanti ne sono scoperti -- il file confronta le notti, la riga fa sentire l'attesa mentre la si vive; `debug/` legge, mai il contrario.
- `tests/test_bench.gd` -- `_check_telemetry()`: tavole per unione intervalli, idle per differenza (con sovrapposizioni), assemblaggio del report (attività chiuse/abbandonate/idle/fuori-posa, `wait_total_min`, `quit_mid_pose`) -- il banco legge la logica pura; il file su disco, la scrittura al quit e la leggibilità F12 li verifica l'operatore.

**Acceptance Criteria:**
- Given una notte conclusa, when arriva `dawn_reached`, then è scritto `user://telemetry/night-<i>.json` — JSON leggibile a occhio, separato dal log, prodotto da `autoloads/telemetry.gd`; and nessun file di gameplay nomina `Telemetry` (`rg "Telemetry" --type gdscript` trova solo `telemetry.gd`, `debug_overlay.gd` e la registrazione autoload); and togliendo l'autoload il gioco resta identico.
- Given il file di una notte, when lo si apre, then contiene `night`, `tuning_hash`, `wait_total_min`, `wait_activities[]`, `menu_reopened`, `quit_mid_pose`; and ogni attività ha `what`, `t`, `dur` in minuti di gioco; and un `started` senza `ended` ha `dur:null` e `abandoned:true`; and i `what` sono `caffe`/`lampada`/`cupola`/`forum` più `idle`; and un'attività fuori posa è comunque registrata.
- Given due notti giocate con durate diverse, when si confrontano i file, then `tuning_hash` è presente in entrambi ed è diverso.
- Given un tratto d'attesa non riempito dentro una posa, when si scrive, then compare come `idle` con la sua `dur`, calcolato **per differenza sull'unione** delle attività nelle finestre di posa; and due attività sovrapposte non producono idle negativo né tempo doppio.
- Given una sessione chiusa a posa in corso, when la telemetria viene scritta (secondo momento, su `NOTIFICATION_WM_CLOSE_REQUEST`), then `quit_mid_pose` è `true`; and all'alba normale è `false`; and la finestra di posa aperta si chiude a `elapsed_min` corrente. Verifica d'operatore (serve una finestra da chiudere).
- Given il menu post-foto, when è presentato, then `night/` emette `Events.photo_menu_opened()` e `Telemetry` conta `menu_reopened`.
- Given l'overlay `F12` con una posa in corso, when acceso, then mostra dal vivo i minuti della finestra e quanti scoperti, leggendo da `Telemetry`; and `debug/` legge da `Telemetry`, mai il contrario. Verifica d'operatore.
- Given i dati, when la notte finisce, then restano su disco locale, non contengono nulla che identifichi una persona, e non è introdotta una riga di rete.

## Design Notes

**Perché `sequence_started/ended` e NON `phase_started(&"imaging")` per la posa.** È il cuore della correttezza di questa storia. Il C3 dossier e l'AC di `epics.md` (scritti il 2026-08-24) dicono `phase_started/finished`, ma il **codice è evoluto lo stesso giorno** (commit `854125b`): `phase_started(&"imaging")` scatta quando compare il **pannello di configurazione**, non quando il giocatore preme START, e la deferred-work.md dichiara testualmente che con quello «la telemetria della 3.6 avrebbe misurato come attesa vissuta del tempo in cui nessuna posa esisteva». `sequence_started/ended` sono nati per questo, senza chiave, e la cupola (3.5) è già migrata su di essi. La superficie esterna del concetto «la posa gira» è oggi `sequence_*`; la telemetria si ancora lì. `phase_started` resta usato **solo** per catturare `night_index`/`tuning_hash` a inizio notte (un fatto diverso: «una notte è in corso»), mai come finestra di posa.

**Il gate all'alba è un campo minato: `Game.run` è null.** `end_night()` (game.gd:155) azzera `run`, e `night_session.gd:933→938` chiama `end_night()` **prima** di emettere `dawn_reached` — con un commento che nomina esplicitamente la telemetria come ascoltatore che «deve trovare uno stato già fermo». Quindi la telemetria **non** legge `Game.run` all'alba: cattura `night`/`tuning_hash` su `phase_started`, e timbra ogni intervallo all'arrivo del suo evento (che è sempre a notte aperta). Al **quit** invece `run` è ancora non-null (`end_night` non è stato chiamato), quindi `elapsed_min` è leggibile per chiudere le finestre aperte.

**Tutta l'aritmetica è pura, il resto è cablaggio.** Come `Game.split_spend` e i predicati della cupola, la logica sta in statiche collaudabili sul banco senza SceneTree:
```
merge_intervals([[0,10],[5,12],[20,25]]) == [[0,12],[20,25]]   # unione, non somma
idle_segments(windows=[[0,30]], covered=[[0,12],[20,25]])
    == [{t:12.0,dur:8.0},{t:25.0,dur:5.0}]                      # posa − unione
build_report(...) -> {night,tuning_hash,wait_total_min,wait_activities,menu_reopened,quit_mid_pose}
```
`build_report` riceve finestre e attività grezze (con record aperti a `end=-1`) e `now`, e produce il dict esatto: attività chiuse → `{what,t,dur}`; aperte → `{what,t,dur:null,abandoned:true}`; `idle` dai segmenti scoperti; `wait_total_min` = somma delle finestre (aperte chiuse a `now`). L'autoload accumula gli eventi e chiama `build_report` alla scrittura — così il banco copre l'intera struttura, e a runtime restano solo le connessioni, la lettura di `elapsed_min` e l'I/O su file (verifiche d'operatore/probe).

**Il secondo momento di scrittura.** `NOTIFICATION_WM_CLOSE_REQUEST` sull'autoload scrive prima che la chiusura proceda; `quit_mid_pose = (_open_pose >= 0.0)`. Senza di esso `quit_mid_pose` non potrebbe mai valere `true`, perché la sessione che lo produce è proprio quella che all'alba non arriva. Il meccanismo del WM (fire della notifica) **va verificato eseguendolo** — chiudere la finestra a posa in corso e aprire il file — perché in headless la notifica non arriva; la **logica** di scrittura, invece, la copre il banco (`build_report(..., quit=true)`).

**`menu_reopened` conta le presentazioni.** `photo_menu_opened` è emesso in `_enter_menu` dopo la guardia che evita doppioni (night_session.gd:626) e dopo `show_control` (636): ogni presentazione reale — inclusa la riapertura di *chiudi ed esplora* — è un conteggio, come chiede l'AC.

## Verification

**Commands:**
- `Godot_v4.7.2-stable_win64.exe --headless --path . --import` -- expected: `telemetry.gd` importa senza errori di parse; l'autoload `Telemetry` si registra; nessun errore da `events.gd`/`night_session.gd`/`debug_overlay.gd` estesi.
- `Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/test_bench.tscn` -- expected: `_check_telemetry` stampa le tavole (unione intervalli; idle per differenza con sovrapposizioni; report con attività chiuse/abbandonate/idle/fuori-posa, `wait_total_min`, `quit_mid_pose`) senza righe `<-- ATTESO`/errore; si raggiunge `=== fine ===`.
- `pwsh -NoProfile -File .bmad-loop/verify.ps1` -- expected: `VERIFY: pulito` — banco fino in fondo, boot del gioco senza errori né warning dal nostro codice (l'autoload si cabla in `_ready`).
- `rg -n "Telemetry" --type gdscript` -- expected: solo `autoloads/telemetry.gd` (definizione) e `debug/debug_overlay.gd` (lettura dev-only); nessun file di gameplay lo nomina.
- `rg -n "phase_started|phase_finished" autoloads/telemetry.gd` -- expected: al più `phase_started` per la sola cattura d'identità; **nessun** uso di `phase_*` come finestra di posa (che è `sequence_*`).

**Manual checks (richiedono un umano e un binario Godot con display, `--headless` non li rende):**
- Giocare una notte, raggiungere l'alba, aprire `%APPDATA%/Godot/app_userdata/Astrochill/telemetry/night-<i>.json`: contiene i sei campi, `wait_activities[]` con `caffe`/`lampada`/`cupola`/`forum`/`idle`, `t`/`dur` in minuti di gioco, `quit_mid_pose:false`.
- Chiudere la finestra **a posa in corso**: il file esiste e ha `quit_mid_pose:true`.
- Confrontare due notti con `tuning_override.cfg` diversi: `tuning_hash` presente e diverso.
- `F12` con una posa in corso: la riga mostra i minuti della finestra e quanti scoperti, e cambia dal vivo.

## Spec Change Log

_Nessuna modifica alla spec: nessun loopback bad_spec in questa passata._

## Review Triage Log

### 2026-08-24 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 3: (high 0, medium 1, low 2)
- defer: 1: (high 0, medium 1, low 0)
- reject: 12
- addressed_findings:
  - `[medium]` `[patch]` La riga F12 «scoperti» (il dato più importante) non aveva copertura di banco: l'aritmetica era inline in `current_pose_uncovered_min` e poteva regredire in silenzio (es. sommare i coperti invece degli scoperti) mentre `build_report`/`idle_segments` restavano verdi. Estratta la pura statica `uncovered_min(open_pose, now, activities)` (legge `now` una volta sola), l'accessore la delega, e aggiunta la riga di banco in `_check_telemetry` (posa [0,18] con caffe[2,8]+cupola[12,→] → scoperti 6; nessuna posa → -1).
  - `[low]` `[patch]` `_write` inghiottiva in silenzio un `FileAccess.open == null` (disco pieno/permessi) e metteva comunque `_active = false`: lo strumento di misura perdeva una notte senza dirlo. Aggiunto `push_error` (canale 1, NON `Log`) con il codice d'errore prima del ritorno.
  - `[low]` `[patch]` Guardie `_active` incoerenti fra gli handler: `_on_sequence_*`/`_on_activity_*` mutavano lo stato anche a notte non attiva, a differenza di `_on_menu_opened`/`_on_dawn_reached`. In gioco non è raggiungibile (la posa parte sempre dopo il primo `phase_started`), ma una finestra orfana avrebbe potuto far mostrare all'overlay una posa di una notte mai cominciata. Aggiunto `if not _active: return` in testa ai quattro handler.

## Auto Run Result

Status: awaiting-operator

**Change implementato:** la **telemetria** (3.6), lo strumento di misura dell'MVP — l'ultima storia aperta dell'epica 3, sbloccata chiudendo il rilievo **C3** il 2026-08-24. Un **quinto autoload**, `autoloads/telemetry.gd`, che **ascolta il bus e basta**: accumula le finestre di posa e gli intervalli delle quattro attività dell'attesa con timestamp in **minuti di gioco**, e all'alba (o alla chiusura dell'app a notte aperta) scrive un file JSON leggibile per notte in `user://telemetry/`. Il dato più importante — i tratti `idle` (attesa non riempita) — è calcolato **per differenza sull'unione** degli intervalli dentro le finestre di posa. Tutta l'aritmetica è in funzioni pure statiche collaudate sul banco; l'autoload è solo cablaggio. La riga `F12` mostra dal vivo l'attesa della posa in corso e quanta ne è scoperta.

**Correzione di correttezza portante:** la finestra di posa viene da **`sequence_started`/`sequence_ended`**, NON da `phase_started(&"imaging")`. Il C3 dossier e l'AC di `epics.md` (scritti il 2026-08-24) dicevano `phase_*`, ma lo stesso giorno il codice è evoluto (commit `854125b`, deferred-work.md): `phase_started(&"imaging")` scatta al montaggio del pannello di configurazione, non allo START, e usarlo avrebbe fatto misurare come attesa vissuta il tempo in cui nessuna posa esiste — l'errore esatto che `sequence_*` è nato per chiudere. `phase_started` resta usato solo per catturare `night_index`/`tuning_hash` a inizio notte (`Game.run` è `null` all'alba: `end_night()` lo azzera prima di `dawn_reached`).

**File cambiati:**
- `autoloads/telemetry.gd` — NEW: quinto autoload, nessun `class_name`. Ascolta `phase_started` (solo identità), `sequence_started/ended` (finestre posa), `wait_activity_started/ended` (attività), `photo_menu_opened` (conteggio), `dawn_reached` (scrittura) e `NOTIFICATION_WM_CLOSE_REQUEST` (secondo momento, `quit_mid_pose`). Funzioni pure statiche `merge_intervals`/`idle_segments`/`build_report`/`uncovered_min`; accessori `current_pose_min`/`current_pose_uncovered_min` per l'overlay. Niente rete, niente dato personale, niente `Log`.
- `autoloads/events.gd` — nuovo `signal photo_menu_opened()` con doc (il condotto di `menu_reopened`: il menu `extends Control`, non `Phase`).
- `night/night_session.gd` — una riga: `Events.photo_menu_opened.emit()` in `_enter_menu()` dopo la presentazione (conta ogni presentazione, inclusa la riapertura *chiudi ed esplora*).
- `project.godot` — `Telemetry` registrato come quinto autoload dopo `Tuning`.
- `debug/debug_overlay.gd` — riga F12 che legge `Telemetry.current_pose_min()`/`current_pose_uncovered_min()`, mostrata solo a posa in corso; `debug/` legge, mai il contrario.
- `tests/test_bench.gd` — `_check_telemetry()`: tavole per unione intervalli, idle per differenza (con sovrapposizioni), `build_report` (attività chiuse/abbandonate/idle/fuori-posa, `wait_total_min`, `quit_mid_pose`, notte senza attività) e `uncovered_min` (riga F12).

**Review findings:** 0 intent_gap, 0 bad_spec; **3 patch** (1 medium: copertura di banco della riga F12 scoperti; 2 low: `push_error` su fallimento di scrittura, guardie `_active` coerenti); **1 defer** (medium: il cablaggio runtime — connessioni/handler/`_write`/idempotenza/`NOTIFICATION_WM_CLOSE_REQUEST`/emit-conteggio menu/riga F12 — non è esercitato dal banco, come DW-15/16 e la 3.5; vedi `deferred`); 12 reject (rumore o non raggiungibili sul target Windows/single-player: unione delle finestre già disgiunte per contratto `sequence_*`, intervalli degeneri, percorsi di quit oltre WM_CLOSE, scrittura non atomica, nit cosmetici del banco, overwrite del file a indice notte ripetuto, ecc.). Follow-up review consigliata: **true** — punteggio patch `3×1 + 1×2 = 5 ≥ 5`.

**Verifica eseguita (binario Godot presente nel repo — `Godot_v4.7.2-stable_win64.exe`):**
- `--headless --path . --import` → nessun errore di parse/risorsa; l'autoload `Telemetry` si registra.
- `--headless res://tests/test_bench.tscn` → `_check_telemetry` stampa tutte le tavole (unione ≠ somma; idle per differenza senza negativi con sovrapposizioni; `abandoned`/idle/fuori-posa; `quit_mid_pose`; notte senza attività = una sola voce idle; `uncovered_min` = 6.0 e -1.0) senza righe `<-- ATTESO`; si raggiunge `=== fine ===`.
- `.bmad-loop/verify.ps1` (il cancello del progetto) → **`VERIFY: pulito — banco fino in fondo, gioco senza errori ne' warning`**.
- `rg "Telemetry"` sui `.gd` → solo `autoloads/telemetry.gd` (definizione), `debug/debug_overlay.gd` (lettura dev-only) e menzioni in commenti; nessun file di gameplay lo nomina — togliendo l'autoload il gioco resta identico.

**Owed all'operatore (`operator_actions`):** gli AC che richiedono un umano su una build con display (`--headless` non li rende): l'apparire del file su disco a fine notte, il **secondo momento di scrittura** (`quit_mid_pose`: chiudere la finestra a posa in corso — la notifica `NOTIFICATION_WM_CLOSE_REQUEST` in headless non arriva), il confronto di `tuning_hash` fra due notti reali, e la riga `F12` dal vivo. La logica sottostante è coperta dal banco; la loro esecuzione reale è d'operatore. Vedi `operator_actions` nel frontmatter.

**Rischi residui:**
- AC percettivi/runtime non verificati qui (headless): owed all'operatore.
- Cablaggio runtime della telemetria non esercitato dal banco (vedi `deferred`): coperte solo le funzioni pure.
- La notifica di chiusura è gestita per `NOTIFICATION_WM_CLOSE_REQUEST` (target Windows desktop, come da C3 dossier); altri percorsi di uscita (quit programmatico, segnali di sistema) non scrivono — fuori scopo per la piattaforma dichiarata.
