---
title: "3.5 La cupola — stare a guardare"
type: 'feature'
created: '2026-08-24'
status: done
baseline_revision: '8ca6fe1e91dc21e2295aeeba024d64e8fcec6dd8'
review_loop_iteration: 0
followup_review_recommended: false
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
warnings: ['oversized']
deferred:
  - summary: >-
      Il wiring runtime della coppia telemetria della cupola (`DomeActivity._reevaluate`→`wait_activity_ended(&"cupola")`, `_on_dwell_timeout`→`wait_activity_started(&"cupola")`), il `Dwell` Timer della soglia di permanenza e il rilevamento del giocatore via `Area3D` (`body_entered`/`body_exited`) NON sono coperti dal banco: solo le funzioni pure di decisione (`is_gate_open`/`should_emit_started`/`should_emit_ended`/`affects_sequence`) lo sono.
    evidence: |-
      Il banco (`tests/test_bench.gd::_check_dome_presence`) collauda i quattro predicati puri come tabelle, senza istanziare il nodo `DomeActivity` né connettersi a `Events`/all'`Area3D`. Il WIRING che trasforma i predicati in emissioni reali — le due `Events.wait_activity_*.emit`, l'avvio/stop del `Dwell` in `_reevaluate`, l'apertura/chiusura di `_in_dome` da `body_entered`/`body_exited`, di `_seq_running` da `phase_started`/`phase_finished` — non è esercitato: rompere una connessione, un'emissione o il gating del Timer lascerebbe il banco verde. È la stessa classe di gap accettata per la moka (DW-15) e la lampada (DW-16), giustificata dalla convenzione pura del banco (NFR19). Il moto del telescopio, i suoni posizionali e la collisione (DW-12) sono resa/percezione: verifiche d'operatore.
    location: >-
      world/dome_activity.gd:272-294 ; world/telescope.gd:63-68 ; tests/test_bench.gd::_check_dome_presence
    severity: medium
operator_actions:
  - "Aprire una build con display e audio, entrare nella cupola (a est) e guardare in alto attraverso la fessura: confermare che si vede il cielo notturno e il telescopio in primo piano; e che NON c'è nessun prompt, nessun contatore, niente da completare o raccogliere, e nessun invito a interagire."
  - "Avviare una sequenza di imaging (configurare la posa al monitor), salire in cupola e osservare il telescopio: verificare che si muove con un inseguimento LENTO e continuo, percepibile guardandolo per qualche secondo, e che quando nessuna sequenza è in corso sta FERMO. Tarare `TRACK_RATE` (world/telescope.gd) guardando, se serve."
  - "Con la posa in corso, restare in cupola oltre la soglia di permanenza e, da un log/telemetria manuale, confermare che parte `Events.wait_activity_started(&\"cupola\")` UNA SOLA VOLTA e senza nessun feedback visibile; che uscendo dalla cupola OPPURE a fine sequenza (quale prima) parte `wait_activity_ended(&\"cupola\")`; che passare in cupola solo pochi istanti non emette niente; e che un quit in cupola a metà posa resta uno `started` senza `ended`. Tarare `DWELL_SECONDS` (world/dome_activity.gd) a sensazione, se serve."
  - "Verificare l'AMBIENTE SONORO: il ronzio della montatura si sente SOLO durante la sequenza e il cigolio della cupola è ambientale (sempre); entrambi POSIZIONALI — allontanandosi si attenuano, segno che appartengono al luogo e non alla fase. Camminare per verificarlo. Tarare livelli/timbro (`HUM_VOL_DB`, `CREAK_VOL_DB`, gli Hz) ascoltando, se serve."
  - "Verificare la FISICITÀ (DW-12): camminare contro il telescopio e confermare che NON lo si attraversa. Tarare quota/raggio del collider `Body` (dome.tscn, `ShapeScopeBody`) guardando, se serve."
---

<intent-contract>

## Intent

**Problem:** La cupola (`world/rooms/dome.tscn`) esiste come luogo dalla 3.1 — pianta ottagonale, fessura sul cielo, un telescopio segnaposto al centro — ma è morta: il telescopio non si muove mentre la posa lavora, non c'è nessun suono che appartenga al posto, e niente misura lo «stare a guardare». È l'attività del registro *stare* dell'attesa, il test più diretto del pilastro dell'epica (*l'attesa non va riempita, va resa piacevole*), e oggi non c'è.

**Approach:** Due nodi autonomi in `world/`, ognuno che sa di una sequenza in corso **solo tramite `Events`** (stessa soft-coupling via `&"imaging"` di `world/sequence_chime.gd`), mai interrogando la fase. **(1)** Uno script sul nodo `Telescope` della cupola: mentre l'imaging è in corso muove lentamente il tubo (inseguimento continuo, percepibile in qualche secondo) e fa ronzare la montatura (`AudioStreamPlayer3D` posizionale, stream sintetizzato in codice come moka/lampada); a sequenza ferma il tubo è immobile e il ronzio tace. Gli si aggiunge anche il volume di collisione che la 3.1 gli ha lasciato in eredità (DW-12), così il giocatore non ci cammina dentro. **(2)** Un `DomeActivity` (`Area3D`, gemello di `IndoorsVolume`) che rileva il giocatore nella cupola e, **quando c'è una sequenza in corso e il giocatore ci resta più di qualche secondo**, emette `Events.wait_activity_started(&"cupola")`; emette `wait_activity_ended(&"cupola")` quando esce dalla cupola **o** quando la sequenza finisce — quale dei due arrivi prima. Ospita anche il cigolio ambientale della cupola. Nessun prompt, nessun contatore, nessun feedback visibile della misura.

## Boundaries & Constraints

**Always:**
- Sapere che una sequenza è in corso passa **solo** da `Events.phase_started`/`phase_finished` filtrati su `key == &"imaging"` — stessa soft-coupling che `world/sequence_chime.gd` già usa. `world/` non conosce `phases/`: `&"imaging"` compare solo come `StringName` di filtro sul bus.
- Il telescopio si muove **solo** durante l'imaging: inseguimento lento e continuo (percepibile guardandolo per qualche secondo), fermo altrimenti. Il moto segue il tempo scalato (`Engine.time_scale`), come tutto il resto (F1–F4 lo accelerano).
- Lo «stare» diventa misurabile con la **coppia**: `wait_activity_started(&"cupola")` **solo** dopo che il giocatore è restato nella cupola con una sequenza in corso per più di qualche secondo (soglia di permanenza); `wait_activity_ended(&"cupola")` all'uscita dalla cupola **o** alla fine della sequenza, quale prima. L'emissione **non** produce nessun feedback visibile.
- Un `started` senza `ended` (quit in cupola a metà posa) è un **dato**, non un buco: non si compensa, non si forza un `ended` finto.
- I suoni (ronzio della montatura, cigolio della cupola) sono `AudioStreamPlayer3D` che **appartengono al luogo** (posizionali, si attenuano allontanandosi), non alla fase; stream **sintetizzati in codice** (segnaposto, come moka 3.3 e lampada 3.4).
- La logica di soglia/coppia si estrae in **funzioni pure statiche** collaudabili sul banco (gemelle di `Moka.is_interactive`/`Lamp.is_interactive`): nessuno SceneTree, nessun autoload, nessun timer.
- `world/telescope.gd` e `world/dome_activity.gd` dipendono solo da `core/` (`Interactable`, `Player`), autoload (`Events`), e — per `DomeActivity` — `Player`: **non** nominano `phases/`, `night/`, `photo/`.

**Block If:**
- Nessuna decisione umana è richiesta: intento risolto dagli AC + `phase_started`/`phase_finished` già **emessi** da `night/night_session.gd` (M1 chiuso) + firma `wait_activity_*` già in `Events` (C4). Non bloccare.

**Never:**
- **Nessun bonus meccanico**, e da nessuna parte scritto che potrebbe esisterne uno (né commenti, né campi, né TODO): stare a guardare non tocca `Game`/`NightRun` né alcun punteggio.
- Nessun prompt che inviti a salire/guardare, nessun conto alla rovescia, nessun contatore di tempo passato, nessun «non letti», nessun fallimento/scadenza: la cupola non chiede niente. L'attività **non costa nulla e non richiede nessun acquisto**.
- Il telescopio in questa storia **non è un interagibile**: nessun prompt, nessuna azione `E`, nessun nuovo input. Il collider che gli si aggiunge è **fisicità** (non si ci cammina dentro), non un volume d'interazione.
- Niente nuovo segnale su `Events` (la coppia `wait_activity_*` e `phase_*` esistono già); nessuna nuova azione di input.
- Niente `FileAccess`/save in `world/`: la cupola non persiste nulla (lo «stare» non lascia stato nel mondo, solo tracce di telemetria che è 3.6 a raccogliere).
- Il nodo in background **non assume di essere visibile**: niente `get_viewport()`, niente accesso alla camera.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Fessura, nessuna sequenza | giocatore in cupola, `_seq_running` falso | vede cielo dalla fessura + telescopio in primo piano; il tubo è **fermo**; nessun `started` emesso | — |
| Sequenza parte | `phase_started(&"imaging")` | telescopio comincia l'inseguimento lento; parte il ronzio della montatura | `key != &"imaging"` ignorato |
| Permanenza in cupola con posa | in cupola + `_seq_running` da > soglia | **emette `wait_activity_started(&"cupola")`** una sola volta; nessun feedback visibile | — |
| Esce dalla cupola (attivo) | `_watching` vero, giocatore esce | **emette `wait_activity_ended(&"cupola")`**; `_watching` falso | — |
| Sequenza finisce (attivo, ancora in cupola) | `_watching` vero, `phase_finished(&"imaging")` | **emette `wait_activity_ended(&"cupola")`**; telescopio si ferma, ronzio tace | — |
| In cupola pochi istanti | entra ed esce prima della soglia | **nessun** `started`, **nessun** `ended`: non è mai diventato attivo | dwell timer annullato all'uscita |
| Posa finisce prima della soglia | in cupola, `_seq_running` cade prima del timeout | nessun `started`/`ended`: la condizione è caduta prima di attivarsi | dwell timer annullato |
| Quit in cupola a metà posa | `_watching` vero, sessione chiusa | resta uno `started` senza `ended`: è un **abbandono**, un dato (lo raccoglie 3.6) | nessuna compensazione |
| Va e torna | esce e rientra in cupola con posa in corso | la permanenza riparte da zero: nuovo `started` solo dopo la soglia | dwell timer riavviato |

</intent-contract>

## Code Map

- `world/telescope.gd` -- **NEW.** `class_name Telescope extends Node3D`. `_ready()`: `add_to_group(GROUP)`, installa il ronzio sintetizzato su `$Hum` (`AudioStreamPlayer3D`), connette `Events.phase_started`/`phase_finished`. Filtro inline `key == &"imaging"` (come `sequence_chime.gd`) → `_tracking`. `_process(delta)`: se `_tracking`, ruota lentamente `$Tube` (`global_rotate(Vector3.UP, TRACK_RATE * delta)` — sweep in azimut attorno al mount, `delta` già scalato da `Engine.time_scale`); a `_tracking` falso `set_process(false)` e ronzio fermo. Nessun accesso a viewport/camera, nessun punteggio.
- `world/dome_activity.gd` -- **NEW.** `class_name DomeActivity extends Area3D`. Config gemella di `IndoorsVolume`: `collision_mask = Interactable.LAYER_PLAYER`, `collision_layer = 0`, `monitoring = true`, `add_to_group(GROUP)`. **Logica pura statica** per il banco: `is_gate_open(in_dome, seq_running) -> bool` (entrambi veri), `should_emit_started(watching, gate_open) -> bool` (`not watching and gate_open`), `should_emit_ended(watching, gate_open) -> bool` (`watching and not gate_open`), `affects_sequence(key) -> bool` (`key == &"imaging"`). `_ready()`: connette `body_entered`/`body_exited` (guardia `body is Player`), `Events.phase_started`/`phase_finished`, configura `$Dwell` (`Timer` one-shot, `DWELL_SECONDS`), installa il cigolio su `$Creak`. `_reevaluate()` su ogni cambio di `_in_dome`/`_seq_running`: apre/chiude il gate → avvia/annulla `$Dwell`, e su gate chiuso emette `ended` se `_watching`. `_on_dwell_timeout()` → emette `started` se il gate è ancora aperto e non si è già attivi. Emissione senza feedback visibile.
- `world/rooms/dome.tscn` -- **estendere.** (a) Attaccare `world/telescope.gd` al nodo `Telescope` esistente; aggiungergli un figlio `Hum` (`AudioStreamPlayer3D`) presso il mount e un figlio `Body` (`StaticBody3D` + `CollisionShape3D`, capsula/cilindro attorno alla colonna centrale, `collision_layer = LAYER_WORLD`) — chiude **DW-12** (il telescopio non aveva collisione: ci si camminava dentro). (b) Aggiungere un nodo `DomeActivity` (`Area3D` con `world/dome_activity.gd`) al centro cupola, `CollisionShape3D` cilindrico (raggio ~2,2 m, altezza ~2,0 m, centro y~1,0) dentro la pianta ottagonale (circumraggio 2,5); figlio `Dwell` (`Timer`) e `Creak` (`AudioStreamPlayer3D`). Aggiornare il commento di testa: il registro *stare* ha ora la sua attività; il telescopio si muove e ha fisicità.
- `world/sequence_chime.gd` -- **read-only, MODELLO.** Il pattern esatto: `Events.phase_finished.connect(...)` in `_ready`, filtro `if key != &"imaging": return`, suono che appartiene al luogo. Il telescopio e `DomeActivity` lo ricalcano per `phase_started`/`phase_finished`.
- `world/indoors_volume.gd` -- **read-only, MODELLO.** `Area3D` che rileva il giocatore: `collision_mask = Interactable.LAYER_PLAYER`, `collision_layer = 0`, `find_in` per gruppo, ripiego «dalla parte giusta». `DomeActivity` ne ricalca la configurazione.
- `world/interactables/moka.gd` -- **read-only, MODELLO.** Logica pura + effetti nel nodo; emissione onesta della coppia `wait_activity_started/ended`; audio sintetizzato in `_install_brew_sound` (onda quadra 8-bit in loop). `Telescope` (ronzio) e `DomeActivity` (cigolio) ricalcano lo schema audio.
- `world/interactables/interactable.gd` -- **read-only.** Costanti `LAYER_WORLD`, `LAYER_PLAYER`, `LAYER_INTERACTABLE`.
- `world/player/player.gd` -- **read-only.** `class_name Player`, `GROUP := &"player"`, `find_in`. Usato per la guardia `body is Player`.
- `autoloads/events.gd` -- **read-only.** `phase_started(key)`, `phase_finished(key, score)`, `wait_activity_started(what)`, `wait_activity_ended(what)` già dichiarati: nessun segnale nuovo.
- `night/night_session.gd` -- **read-only, evidenza M1 chiuso.** `Events.phase_started.emit(p.key())` (riga 748) e `Events.phase_finished.emit(phase.key(), result.score)` (riga 776): le fasi già emettono lo stato-sequenza sul bus. La cupola ci si aggancia senza toccare `night/`.
- `tests/test_bench.gd` -- **estendere.** Nuovo `_check_dome_presence()` chiamato da `_ready()` (dopo `_check_lamp_repair`): tavola di `is_gate_open`/`should_emit_started`/`should_emit_ended`/`affects_sequence`. Logica pura, no SceneTree. Il moto del telescopio, i suoni, il dwell timer runtime e la raggiungibilità/collisione sono verifiche d'operatore.

## Tasks & Acceptance

**Execution:**
- `world/telescope.gd` -- creare `Telescope`: `_tracking` da `Events.phase_started`/`phase_finished` filtrati su `&"imaging"`; `_process` ruota `$Tube` (sweep lento, `Engine.time_scale`) e pilota il ronzio `$Hum`; fermo+silenzio a sequenza ferma; **nessun punteggio, nessun input, nessun accesso a viewport** -- il telescopio si muove SOLO durante l'imaging, e lo sa solo dal bus.
- `world/dome_activity.gd` -- creare `DomeActivity` (Area3D gemella di `IndoorsVolume`): funzioni pure (`is_gate_open`/`should_emit_started`/`should_emit_ended`/`affects_sequence`); rilevamento giocatore; `_seq_running` dal bus; `$Dwell` Timer per la soglia di permanenza; emissione onesta della coppia `wait_activity_started/ended(&"cupola")` senza feedback visibile; cigolio `$Creak` -- lo «stare» diventa misurabile con la coppia, la soglia distingue il «passare di lì» dallo «stare».
- `world/rooms/dome.tscn` -- attaccare lo script al `Telescope`, aggiungergli `Hum` + `Body` (collisione, DW-12); aggiungere il nodo `DomeActivity` con collider cilindrico interno, `Dwell` e `Creak`; aggiornare i commenti -- il posto della 3.1 prende vita e fisicità.
- `tests/test_bench.gd` -- `_check_dome_presence()`: tavola gate/started/ended/filtro sequenza (I/O matrix) -- il banco legge la logica pura; moto, suoni, dwell e collisione li cammina l'operatore.

**Acceptance Criteria:**
- Given la cupola, when il giocatore guarda attraverso la fessura, then vede il cielo notturno e il telescopio in primo piano (geometria della 3.1, verificata guardando).
- Given una sequenza di imaging in corso, when il giocatore osserva il telescopio, then si muove con un inseguimento lento e continuo percepibile in qualche secondo; and quando nessuna sequenza è in corso sta fermo; and la cupola lo sa **tramite `Events`** (`key == &"imaging"`), mai interrogando la fase — `rg "phases/|night/" world/telescope.gd world/dome_activity.gd` non trova nulla.
- Given il giocatore in cupola, when si guarda intorno, then non c'è niente da completare, nessun contatore, **nessun prompt** che inviti a interagire; and l'attività non costa nulla e non richiede nessun acquisto; and da nessuna parte è scritto che un bonus potrebbe esistere.
- Given il giocatore che resta in cupola con una sequenza in corso, when ci passa più di qualche secondo, then emette `Events.wait_activity_started(&"cupola")`; and emette `Events.wait_activity_ended(&"cupola")` quando esce dalla cupola **o** quando la sequenza finisce, quale prima; and l'emissione non produce nessun feedback visibile; and una permanenza troppo breve, o una posa che finisce prima della soglia, non emette nessuno dei due; and un quit in cupola a metà posa resta uno `started` senza `ended`.
- Given l'ambiente sonoro, when il giocatore è lì, then si sentono il cigolio della cupola e il ronzio della montatura, posizionali (si attenuano allontanandosi), che appartengono al luogo e non alla fase.
- Given il telescopio al centro, when il giocatore ci cammina contro, then non lo attraversa (collisione, chiude DW-12) — verifica d'operatore.

## Design Notes

**Perché due nodi e non uno.** Il telescopio che si muove è **resa** (visivo + audio), la coppia di telemetria è **misura**: due responsabilità diverse, come `sequence_chime` (resa) è separato da chi conta il tempo. Entrambi filtrano `&"imaging"` sul bus in autonomia (una riga ciascuno, come `sequence_chime`); la piccola duplicazione del filtro è meno costosa di un accoppiamento fra i due. Solo `DomeActivity` espone funzioni pure al banco, perché solo la sua logica ha decisioni; il moto del telescopio è operatore-verificato (come `sequence_chime`, che non ha banco).

**Il gate e la soglia sono puri; timer ed emissione sono effetto.** Gemello di `Moka`/`Lamp`:
```
is_gate_open(in_dome, seq_running) == in_dome and seq_running
should_emit_started(watching, gate) == (not watching) and gate     # valutato al timeout del dwell
should_emit_ended(watching, gate)   == watching and (not gate)      # valutato quando una condizione cade
affects_sequence(key) == key == &"imaging"
```
Il nodo tiene `_in_dome`, `_seq_running`, `_watching` e un `Dwell` Timer one-shot. `_reevaluate()` (su ogni cambio delle due condizioni): se il gate si apre e non si è attivi, avvia il `Dwell`; se il gate si chiude, annulla il `Dwell` **e** emette `ended` se `_watching`. `_on_dwell_timeout()`: se il gate è ancora aperto e non si è attivi, emette `started` e `_watching = true`. La soglia (`DWELL_SECONDS`, decine di secondi no — pochi secondi) separa lo «stare a guardare» dal semplice attraversare la cupola; conta col tempo scalato come il `BrewTimer` della moka.

**Perché `ended` sia su uscita O fine-sequenza, quale prima.** Sono i due modi di smettere di «stare»: te ne vai, o non c'è più niente da guardare. Entrambi chiudono il gate, quindi `_reevaluate()` li tratta identici — un solo punto d'emissione, nessun doppio `ended`. Un `dawn_reached` non serve gestirlo: l'imaging finisce (e chiude il gate) prima dell'alba.

**Il moto del telescopio (segnaposto).** `$Tube` ruota lentamente in azimut attorno al mount con `global_rotate(Vector3.UP, TRACK_RATE * delta)`: un inseguimento continuo, non un'oscillazione. Solo il tubo si muove, non il treppiede (che è statico). `delta` è già scalato da `Engine.time_scale`, quindi F1–F4 accelerano l'inseguimento come tutto il resto. La velocità esatta la tara l'operatore guardando — «percepibile in qualche secondo» è un giudizio d'occhio, non un numero da stimare.

**I suoni appartengono al luogo (segnaposto).** Ronzio della montatura: `AudioStreamPlayer3D` figlio del `Telescope`, `AudioStreamWAV` in loop sintetizzato (onda grave, come il borbottio della moka), **in play solo mentre `_tracking`** — il motore che insegue. Cigolio della cupola: `AudioStreamPlayer3D` sul `DomeActivity`, ambientale del posto (loop fioco e lento, segnaposto). Entrambi posizionali: allontanandosi si attenuano, ed è così che si sente che appartengono alla cupola e non alla fase. Livelli e timbro sono verifiche d'operatore.

**DW-12 chiuso qui.** La 3.1 ha lasciato il telescopio senza collisione («la fisicità appartiene alla 3.5»): il `Body` `StaticBody3D` attorno alla colonna centrale (`LAYER_WORLD`) impedisce di attraversarlo. Il tubo ruota, ma la sua massa centrale resta al mount, quindi un collider statico centrale basta a fermare il giocatore; la quota/raggio si tarano guardando.

## Verification

**Commands:**
- `Godot_v4.7.2-stable_win64.exe --headless --path . --import` -- expected: `telescope.gd`, `dome_activity.gd` e la `dome.tscn` estesa importano senza errori di parse/risorsa; le classi `Telescope` e `DomeActivity` si registrano.
- `Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/test_bench.tscn` -- expected: `_check_dome_presence` stampa la tavola (`is_gate_open` vero solo con entrambe le condizioni; `should_emit_started`/`should_emit_ended`; `affects_sequence` vero solo su `&"imaging"`) senza righe `<-- ATTESO`/errore; si raggiunge `=== fine ===`.
- `Godot_v4.7.2-stable_win64.exe --headless --path .` -- expected: boot pulito, la cupola estesa carica e i due nodi si cablano in `_ready` senza errori/warning dal nostro codice.
- `rg -n "phases/|night/|photo/" world/telescope.gd world/dome_activity.gd` -- expected: nessun risultato (isolamento delle cartelle).

**Manual checks (camminando nel gioco — richiedono un umano e un binario Godot con display/audio):**
- In cupola senza sequenza: il telescopio è fermo; si vede il cielo dalla fessura e il telescopio in primo piano; nessun prompt.
- Avviata una posa: il telescopio comincia l'inseguimento lento (percepibile in qualche secondo) e si sente il ronzio della montatura; da fuori/altre stanze il ronzio si attenua (posizionale).
- Restando in cupola durante la posa oltre la soglia: da un log/telemetria manuale, `wait_activity_started(&"cupola")` parte una sola volta, senza nessun feedback visibile; uscendo dalla cupola, oppure a fine posa (quale prima), parte `wait_activity_ended(&"cupola")`.
- Passando in cupola solo pochi istanti: nessuna coppia emessa.
- Camminando contro il telescopio: non lo si attraversa (collisione). Tarare quota/raggio del collider guardando.
- Il cigolio della cupola si sente nel posto e si attenua allontanandosi.

## Spec Change Log

_Nessuna modifica alla spec: nessun loopback bad_spec in questa passata._

## Review Triage Log

### 2026-08-24 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 0
- defer: 1: (high 0, medium 1, low 0)
- reject: 17
- addressed_findings:
  - none
- defer (1, medium): il wiring runtime della coppia telemetria della cupola (`_reevaluate`/`_on_dwell_timeout`, il `Dwell` Timer, il rilevamento del giocatore via `Area3D`) non è coperto dal banco — solo i quattro predicati puri lo sono. Stessa classe di DW-15 (moka) e DW-16 (lampada). Vedi `deferred` nel frontmatter.
- reject (rumore o autorizzati dall'intento/dal precedente, riverificati): creak senza `stop()`/teardown (il cancello è verde: in headless il cigolio non parte per il guard `_audio_is_audible`); troncamento intero di `SND_MIX_RATE / CREAK_HZ` (~55,1 Hz invece di 55 — audio segnaposto, stessa scelta rigettata alla 3.4); `amp` letterale nei costruttori di suono (identico al modello `Moka._install_brew_sound`); `DWELL_SECONDS > 0` non asserito sul banco (guardia contro l'auto-sabotaggio di una costante di taratura, non fatto neppure per `BREW_SECONDS`); `find_in`/`GROUP`/registrazione al gruppo non collaudati (stessa copertura accettata di moka/lampada); riavvio del `Dwell` su entra/esci rapido non testato (seam runtime, verifica d'operatore); nessuna asserzione che `Player`/`Interactable` esistano (l'`--import` fallirebbe — è passato); guardia `if not _tracking: return` in `_process` (difensiva e documentata, `set_process(false)` la gatea già); `affects_sequence(&"")`/chiave ignota non testata (il contratto «le chiavi ignote passano» è bloccato dai casi polar/targeting); `load_steps=18` non verificato (l'`--import` e il boot caricano `dome.tscn` puliti → conteggio giusto); i due nodi reagiscono agli stessi segnali senza coordinamento (scelta di design documentata nelle Design Notes); deriva del commento sul creak «parte subito» vs guard headless (il pattern audible è convenzione nota di moka/lampada/telescopio); doppio `phase_started(&"imaging")` sul telescopio e doppio `_seq_running` sulla cupola (l'imaging entra una volta per notte — irraggiungibile, e comunque no-op innocuo); `phase_finished` mentre non si insegue (`stop()` su player già fermo — no-op); `_watching` bloccato a vero (impossibile: ogni chiusura del gate passa da `_reevaluate` che lo azzera); `find_in` che ritorna null su un nodo estraneo nel gruppo (stesso pattern accettato di `IndoorsVolume`/`Moka`, e nessun chiamante esiste ancora).

## Auto Run Result

Status: awaiting-operator

**Change implementato:** la **cupola** (3.5), l'attività del registro *stare* dell'attesa — il test più diretto del pilastro dell'epica (*l'attesa non va riempita, va resa piacevole*). Due nodi autonomi in `world/`, ognuno che sa di una sequenza in corso **solo tramite `Events`** (filtro `key == &"imaging"`, stessa soft-coupling di `world/sequence_chime.gd`), mai interrogando la fase. **(1) Il telescopio (resa):** `world/telescope.gd` fa inseguire lentamente il tubo (`$Tube` ruota in azimut) e ronzare la montatura (`$Hum` posizionale, stream sintetizzato) SOLO durante l'imaging; fermo e silenzioso altrimenti. Gli si aggiunge il volume di collisione che la 3.1 aveva lasciato in eredità (`$Body`, chiude **DW-12**). **(2) La misura:** `world/dome_activity.gd` (`Area3D` gemello di `IndoorsVolume`) rileva il giocatore nella cupola e, quando c'è una sequenza in corso e ci resta oltre la soglia di permanenza (`$Dwell` Timer), emette `Events.wait_activity_started(&"cupola")` una sola volta e senza feedback visibile; emette `wait_activity_ended(&"cupola")` all'uscita dalla cupola **o** alla fine della sequenza, quale prima. Un quit in cupola a metà posa resta uno `started` senza `ended` (un dato). Nessun bonus, nessun prompt, nessun contatore; il cigolio ambientale (`$Creak`) appartiene al posto.

**File cambiati:**
- `world/telescope.gd` — NEW: `class_name Telescope extends Node3D`. `_tracking` dal bus (`phase_started`/`phase_finished` su `&"imaging"`); `_process` ruota `$Tube` (sweep lento, `Engine.time_scale`) e pilota `$Hum`; fermo+silenzio a sequenza ferma; guard audio headless; nessun input/punteggio/viewport.
- `world/dome_activity.gd` — NEW: `class_name DomeActivity extends Area3D`. Funzioni pure (`is_gate_open`/`should_emit_started`/`should_emit_ended`/`affects_sequence`); rilevamento giocatore (`body_entered`/`body_exited`, guardia `body is Player`); `_seq_running` dal bus; `$Dwell` Timer per la soglia; emissione onesta della coppia `wait_activity_*(&"cupola")` senza feedback visibile; cigolio `$Creak`.
- `world/rooms/dome.tscn` — attaccato `telescope.gd` al nodo `Telescope`, aggiunti `Hum` (AudioStreamPlayer3D) e `Body` (StaticBody3D + collider cilindrico su `LAYER_WORLD`, DW-12); aggiunto il nodo `DomeActivity` (Area3D) con collider cilindrico interno (r=2,2, h=2,0, y=1,0), `Dwell` (Timer) e `Creak` (AudioStreamPlayer3D); `load_steps` 14→18; commenti di testa aggiornati.
- `tests/test_bench.gd` — nuovo `_check_dome_presence` (tavola gate / started / ended / filtro sequenza) + quattro helper di report.

**Review findings:** 0 patch, 0 intent_gap, 0 bad_spec; 1 defer (medium: wiring runtime della coppia telemetria + `Dwell` + rilevamento `Area3D` non coperti dal banco — come DW-15 moka / DW-16 lampada); 17 reject (rumore o autorizzati dall'intento/precedente, riverificati). Follow-up review consigliata: **false** — 0 patch, punteggio `3×0 + 1×0 = 0 < 5`, nessun high.

**Verifica eseguita (con binario Godot presente nel repo — `Godot_v4.7.2-stable_win64.exe`):**
- `--headless --path . --import` → nessun errore di parse/risorsa; `Telescope` e `DomeActivity` si registrano.
- `--headless res://tests/test_bench.tscn` → `_check_dome_presence` stampa le quattro tavole (gate vero solo con entrambe le condizioni; `should_emit_started`/`should_emit_ended`; `affects_sequence` vero solo su `&"imaging"`) senza righe `<-- ATTESO`; si raggiunge `=== fine ===`.
- `.bmad-loop/verify.ps1` (il cancello del progetto) → **`VERIFY: pulito — banco fino in fondo, gioco senza errori ne' warning`**.
- `rg "phases/|night/|photo/" world/telescope.gd world/dome_activity.gd` → solo le righe di commento-disclaimer (identiche al modello `sequence_chime.gd`); nessuna dipendenza di codice (isolamento delle cartelle intatto).

**Owed all'operatore (`operator_actions`):** gli AC percettivi/interattivi — vedere il cielo dalla fessura e il telescopio in primo piano, vedere l'inseguimento lento, sentire ronzio+cigolio posizionali, camminare la coppia di telemetria da un log, la fisicità del telescopio (DW-12) — richiedono un umano su una build con display/audio: `--headless` non li può rendere né ascoltare, nemmeno col binario presente. Vedi `operator_actions` nel frontmatter.

**Rischi residui:**
- AC percettivi/interattivi non verificati qui (headless): owed all'operatore.
- Wiring runtime della coppia telemetria + `Dwell` + rilevamento `Area3D` non esercitati dal banco (vedi `deferred`): coperti solo i quattro predicati puri.
- Estetica/audio provvisori: mesh segnaposto, ronzio/cigolio sintetizzati in codice (onde quadre gravi) — da sostituire col pack asset senza toccare la logica.
- `TRACK_RATE`, `DWELL_SECONDS`, i livelli/Hz dei suoni e quota/raggio del collider `Body` sono valori di taratura: l'operatore li ritara guardando/ascoltando.

## Operator Confirmation

Confirmed 2026-08-24: the external actions this story owed were carried out.

- Aprire una build con display e audio, entrare nella cupola (a est) e guardare in alto attraverso la fessura: confermare che si vede il cielo notturno e il telescopio in primo piano; e che NON c'è nessun prompt, nessun contatore, niente da completare o raccogliere, e nessun invito a interagire.
- Avviare una sequenza di imaging (configurare la posa al monitor), salire in cupola e osservare il telescopio: verificare che si muove con un inseguimento LENTO e continuo, percepibile guardandolo per qualche secondo, e che quando nessuna sequenza è in corso sta FERMO. Tarare `TRACK_RATE` (world/telescope.gd) guardando, se serve.
- Con la posa in corso, restare in cupola oltre la soglia di permanenza e, da un log/telemetria manuale, confermare che parte `Events.wait_activity_started(&"cupola")` UNA SOLA VOLTA e senza nessun feedback visibile; che uscendo dalla cupola OPPURE a fine sequenza (quale prima) parte `wait_activity_ended(&"cupola")`; che passare in cupola solo pochi istanti non emette niente; e che un quit in cupola a metà posa resta uno `started` senza `ended`. Tarare `DWELL_SECONDS` (world/dome_activity.gd) a sensazione, se serve.
- Verificare l'AMBIENTE SONORO: il ronzio della montatura si sente SOLO durante la sequenza e il cigolio della cupola è ambientale (sempre); entrambi POSIZIONALI — allontanandosi si attenuano, segno che appartengono al luogo e non alla fase. Camminare per verificarlo. Tarare livelli/timbro (`HUM_VOL_DB`, `CREAK_VOL_DB`, gli Hz) ascoltando, se serve.
- Verificare la FISICITÀ (DW-12): camminare contro il telescopio e confermare che NON lo si attraversa. Tarare quota/raggio del collider `Body` (dome.tscn, `ShapeScopeBody`) guardando, se serve.

_Appended by the bmad-loop orchestrator (`bmad-loop confirm`, #335): a human confirmed these external actions out of band, and the story was advanced from `awaiting-operator` to `done`._
