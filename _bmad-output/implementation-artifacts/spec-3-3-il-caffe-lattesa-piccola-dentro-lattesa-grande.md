---
title: "3.3 Il caffè — l'attesa piccola dentro l'attesa grande"
type: 'feature'
created: '2026-08-23'
status: done
baseline_revision: '73a236abdfc3dcc501f47f7df053b59dd083800b'
review_loop_iteration: 0
followup_review_recommended: true
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
warnings: ['oversized']
deferred:
  - summary: >-
      L'emissione runtime della coppia telemetria (`wait_activity_started/ended(&"caffe")` in `_on_interacted`) e il seam di comparsa (`_apply_presence`/`_on_item_purchased`) NON sono coperti dal banco: solo le funzioni pure di transizione lo sono.
    evidence: |-
      Il banco (`tests/test_bench.gd::_check_moka_ritual`) collauda `next_on_interact`/`is_interactive`/`prompt_for`/`starts_activity`/`ends_activity` come predicati puri, senza istanziare il nodo Moka né connettersi a `Events`. Il WIRING che trasforma quei predicati in emissioni reali (`interacted.connect(_on_interacted)` + le due `Events...emit`) e il toggle di presenza da `Game.profile.owns`/`item_purchased` non sono esercitati: una regressione che rompesse la connessione o spostasse un'emissione lascerebbe il banco verde. Collaudabile headless (il binario Godot c'è e la scena del banco gira sotto SceneTree), ma tenuto fuori per rispettare la convenzione pura del banco (NFR19) — stesso trattamento del deferral di `Game.spend_lire` end-to-end in 3.2.
    location: >-
      world/interactables/moka.gd:176-248 ; tests/test_bench.gd::_check_moka_ritual
    severity: medium
operator_actions:
  - "Aprire una build con display e audio e comprare la moka al terminale durante l'attesa: verificare che compare in cucina, che prima non c'era, e che c'è ancora dopo aver dormito (il possesso sopravvive al save)."
  - "Fare il caffè per intero: riempire → mettere sul fuoco → sentire il suono SALIRE per decine di secondi e BORBOTTARE alla fine → versare → bere; confermare che non ci sono conti alla rovescia né prompt di sollecito, e che il prompt segue i tempi mentre si guarda la moka."
  - "Verificare la RAGGIUNGIBILITÀ: la moka è mirabile e interagibile stando davanti al piano (occhio 1,65 m, piano 0,9 m), senza che il prompt compaia da lontano. Tarare la quota del volume di collisione guardando, se serve."
  - "Lasciare il rituale a metà, allontanarsi e tornare: niente si è rotto né è scaduto. Rifarlo più volte nella stessa notte e nelle notti successive."
  - "Con un log/telemetria manuale, confermare che `Events.wait_activity_started(&\"caffe\")` parte al primo tempo (riempire) e `wait_activity_ended(&\"caffe\")` al bere, senza feedback visibile, e che un rituale abbandonato resta uno `started` senza `ended`."
---

<intent-contract>

## Intent

**Problem:** Mentre la posa gira il giocatore si alza dal monitor, ma la cucina è vuota: il piano di appoggio segnaposto (3.1) aspetta la moka, e la moka comprata al terminale (3.2) esiste solo come possesso persistito — non c'è ancora niente da fare con lei. Manca l'attività del registro *fare*: il rituale del caffè, che è la battuta tematica del gioco messa in meccanica (un'attesa piccola dentro l'attesa grande).

**Approach:** Un interagibile autonomo `world/interactables/moka.gd` che compare in cucina solo quando l'articolo `&"moka"` è posseduto (all'avvio leggendo `Game.profile.owns`, a runtime ascoltando `Events.item_purchased`). Interagendo con `E` si avanza un rituale a più tempi (riempire → mettere sul fuoco → *attesa reale* → versare → bere); l'attesa dura decine di secondi e la si *sente* (un suono che sale e alla fine borbotta), senza conto alla rovescia visibile. Il primo tempo emette `Events.wait_activity_started(&"caffe")`, il bere emette `wait_activity_ended(&"caffe")`. Nessun bonus, nessun fallimento, ripetibile.

## Boundaries & Constraints

**Always:**
- La moka **compare perché comprata**: assente/invisibile e inerte finché `Game.profile.owns(&"moka")` non è vero; appare all'avvio se già posseduta e a runtime su `Events.item_purchased(&"moka")`.
- Il rituale è **a più tempi, ogni tempo un'azione separata** (`E`): riempire, mettere sul fuoco, [attesa], versare, bere. L'attesa fra fuoco e pronto è **tempo reale percepibile, decine di secondi**, tarabile e soggetto a `Engine.time_scale` (gli strumenti F1–F4 la accelerano).
- L'avanzamento **si sente**: durante l'attesa un `AudioStreamPlayer3D` posizionale sulla moka sale (volume/pitch), e alla fine borbotta. Suono **sintetizzato in codice** (segnaposto, come il beep del terminale 3.2) — nessun asset d'arte inventato.
- `world/` dipende solo da `core/`, `data/`, autoload (`Game`, `Events`). La moka **non nomina** `night/`, `phases/`, `terminal/`, e non passa da `main.gd`: è autonoma.
- La coppia telemetria: `wait_activity_started(&"caffe")` al **primo tempo** (riempire), `wait_activity_ended(&"caffe")` **al bere**. L'emissione non produce feedback visibile.

**Block If:**
- Nessuna decisione umana è richiesta: intento risolto da AC + seam di 3.2/3.1 + firma C4 già in `Events`. Non bloccare.

**Never:**
- **Nessun bonus meccanico**, e da nessuna parte scritto che potrebbe esisterne uno (né commenti, né campi, né TODO): un caffè fatto non alza né abbassa alcun punteggio, non tocca `Game`/`NightRun`.
- Nessun conto alla rovescia visibile, nessun prompt che solleciti, nessun contatore, nessun fallimento/scadenza: un rituale a metà lasciato lì non si rompe.
- Niente nuova azione di input (usa l'`interact` del giocatore, come letto/monitor), niente nuovo segnale su `Events`, niente stato del rituale nel save (solo il **possesso** persiste, ed è già di 3.2).
- Niente modellazione di un fornello separato: la geometria è segnaposto, «sul fuoco» è uno stato della moka.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Non posseduta | avvio, `owns(&"moka")` falso | moka invisibile, collisione disattivata, `can_interact()` falso, nessun prompt | — |
| Acquisto a runtime | `Events.item_purchased(&"moka")` | moka compare (visibile, collisione attiva, stato IDLE) | id diverso da `&"moka"`: ignorato |
| Già posseduta | avvio, `owns(&"moka")` vero | moka presente in stato IDLE, prompt «Riempi la moka» | — |
| Riempi (1° tempo) | stato IDLE + `E` | → FILLED, prompt «Metti la moka sul fuoco», **emette `wait_activity_started(&"caffe")`** | — |
| Sul fuoco | stato FILLED + `E` | → BREWING: parte il timer d'attesa e il suono che sale; `can_interact()` falso, nessun prompt | — |
| Attesa conclusa | timer BREWING scaduto | → READY: borbotta, prompt «Versa il caffè» | — |
| Versa | stato READY + `E` | → POURED, prompt «Bevi il caffè» | — |
| Bevi (ultimo tempo) | stato POURED + `E` | → IDLE (ripetibile), **emette `wait_activity_ended(&"caffe")`** | — |
| Abbandono | 1° tempo fatto, mai bevuto | `started` senza `ended`: l'abbandono resta un dato; niente si rompe, niente scade | — |
| Durante l'attesa | stato BREWING, `E` | inerte: nessun prompt, nessuna risposta (si aspetta e si ascolta) | — |

</intent-contract>

## Code Map

- `world/interactables/moka.gd` -- **NEW.** `class_name Moka extends Interactable`. Macchina a stati del rituale (enum `Step{ IDLE, FILLED, BREWING, READY, POURED }`), telemetria, suono. Modello di forma: `world/interactables/bed.gd` (interagibile spento all'avvio, si accende su condizione esterna) e `crt_monitor.gd`. **Logica pura estratta** per il banco (come `Game.split_spend` in 3.2): `next_on_interact(step)`, `is_interactive(step)`, `prompt_for(step)` — statiche, senza SceneTree. `_ready()`: `add_to_group`, connette `Events.item_purchased`/`Events.dawn_reached` e la propria `interacted`, poi legge `Game.profile.owns(&"moka")`. Emette via `Events.wait_activity_started/ended(&"caffe")` (bus, firma C4 già presente `autoloads/events.gd:34-35`).
- `world/interactables/moka.tscn` -- **NEW.** `StaticBody3D` (script), `prompt_text="Riempi la moka"`, `enabled=false` (nasce spento). Figli: `MeshInstance3D` segnaposto (moka-ish, ShaderMaterial `ps1.gdshader` come il resto dell'arredo), `CollisionShape3D` (BoxShape, alto abbastanza da essere mirabile dall'occhio 1,65 m sul piano a 0,9 m — lezione di raggiungibilità di `bed.tscn`), `AudioStreamPlayer3D` (suono posizionale, stream sintetizzato in codice), `Timer` (one-shot, durata d'attesa; il nodo `Timer` conta col tempo scalato → F1–F4 lo accelerano).
- `world/interactables/interactable.gd` -- **read-only.** Base `Interactable`: `enabled`, `can_interact()` (da stringere, mai allentare), `prompt()`, `interact()` che emette `interacted`. `_enter_tree` fa OR dei layer WORLD|INTERACTABLE. `moka.gd` override di `can_interact()` per spegnersi in BREWING e da non-posseduta.
- `world/rooms/kitchen.tscn` -- **estendere.** Istanziare `Moka` sul piano d'appoggio (`Counter` a kitchen-local `(2.7, 0.45, 1.5)`, size `(0.6,0.9,2.2)` → top a y=0,9). Collocare verso il bordo ovest del piano (lato da cui si entra), es. origine `(2.5, 0.9, 1.5)`. Aggiornare il commento di testa: il registro *fare* ora ha il suo interagibile (non più «nessun interagibile»).
- `autoloads/events.gd` -- **read-only.** `wait_activity_started/ended(what)` e `item_purchased(id)` già dichiarati; nessun segnale nuovo.
- `autoloads/game.gd` / `core/player_profile.gd` -- **read-only.** `Game.profile.owns(&"moka")` è il seam. `Game.profile` esiste prima della prima notte (init + `_ready` load): la moka lo legge in sicurezza.
- `tests/test_bench.gd` -- **estendere.** Nuovo `_check_moka_ritual()`: tavola delle transizioni `next_on_interact` per ogni stato, `is_interactive` (falso solo in BREWING), `prompt_for` per stato, e i punti d'emissione (started al 1° tempo, ended al bere). Logica pura, no SceneTree; il timer/suono e la raggiungibilità sono verifiche d'operatore.

## Tasks & Acceptance

**Execution:**
- `world/interactables/moka.gd` -- creare `Moka`: macchina a stati + funzioni pure di transizione; comparsa su possesso/`item_purchased`; timer d'attesa (decine di secondi, `Engine.time_scale`); suono posizionale sintetizzato che sale e borbotta; emissione `wait_activity_started/ended(&"caffe")` ai due estremi; **nessun accesso a punteggi** -- è l'attività del registro *fare*.
- `world/interactables/moka.tscn` -- costruire la scena: `StaticBody3D` spento, mesh segnaposto, collisione mirabile dal piano a 0,9 m, `AudioStreamPlayer3D`, `Timer` one-shot -- il posto c'era (3.1), ora c'è l'oggetto.
- `world/rooms/kitchen.tscn` -- istanziare la `Moka` sul piano d'appoggio e aggiornare il commento -- la moka nasce dove il terminale l'ha promessa.
- `tests/test_bench.gd` -- `_check_moka_ritual()`: transizioni, interattività per stato, prompt, punti d'emissione (I/O matrix) -- il banco legge la logica pura, la percezione la cammina l'operatore.

**Acceptance Criteria:**
- Given la moka non ancora comprata, when la notte comincia, then in cucina non c'è nessuna moka e nessun prompt; when l'articolo `&"moka"` viene comprato al terminale (`Events.item_purchased(&"moka")`), then la moka compare, visibile e interagibile, e c'è anche riaprendo dopo aver dormito (il possesso persiste, 3.2).
- Given la moka in cucina, when il giocatore la usa più volte, then il rituale è a più tempi e ogni tempo è un'azione separata (riempire, sul fuoco, versare, bere), con un'attesa reale di decine di secondi fra fuoco e pronto; l'avanzamento si sente (il suono sale e alla fine borbotta) e non c'è nessun conto alla rovescia a schermo.
- Given un rituale a metà, when il giocatore se ne va e torna più tardi, then non si rompe niente, non scade niente, nessun prompt sollecita; un rituale cominciato e mai concluso resta uno `started` senza `ended` — l'abbandono è un dato.
- Given un caffè portato a termine, when finisce, then non cambia nessun punteggio e da nessuna parte è scritto che potrebbe; e la moka torna disponibile per rifarlo, più volte per notte e tutte le notti.
- Given la telemetria, when comincia il rituale (riempire) e quando il caffè è bevuto, then partono rispettivamente `Events.wait_activity_started(&"caffe")` e `wait_activity_ended(&"caffe")`, senza feedback visibile, e la durata si ricava dalla coppia.
- Given le regole di dipendenza, when si cerca `night/`/`phases/`/`terminal/` dentro `world/interactables/moka.gd`, then non c'è nessuna occorrenza (isolamento delle cartelle).

## Design Notes

**Perché autonoma, senza `main.gd`.** Letto e monitor passano da `main.gd` perché il loro `enabled` dipende dallo stato della notte/fase, che solo `main.gd` vede. La moka no: la sua comparsa dipende solo dal **possesso** (`Game.profile`, autoload → `core/`) e il rituale è tutto interno. Quindi vive nella scena e si cabla da sé in `_ready()` — è la lettura letterale del seam scritto in `events.gd:37-46` («la moka nascerà ascoltando `item_purchased` e leggendo `Game.profile.owns(id)`»). Meno superficie, isolamento pulito.

**Le transizioni sono pure, il resto è effetto.** Come `split_spend` in 3.2, la tavola del rituale è statica e collaudabile senza SceneTree:
```
next_on_interact(IDLE)   -> FILLED   # + started(&"caffe")
next_on_interact(FILLED) -> BREWING  # il nodo avvia timer + suono
next_on_interact(BREWING)-> BREWING  # inerte (can_interact già falso)
next_on_interact(READY)  -> POURED
next_on_interact(POURED) -> IDLE     # + ended(&"caffe")
# BREWING -> READY è guidato dal Timer, non da un'interazione.
is_interactive(BREWING) == false; tutti gli altri true.
```
Il nodo mappa i marcatori started/ended sulle chiamate `Events.wait_activity_*` e gestisce timer/suono; la funzione pura non tocca né l'uno né l'altro.

**Il suono sale, poi borbotta (segnaposto).** `AudioStreamWAV` sintetizzato in codice (nessun asset d'arte, coerente con la memoria «asset provvisori» e col beep del terminale): un borbottio grave in loop. All'ingresso in BREWING un `Tween` alza `volume_db` e `pitch_scale` per la durata dell'attesa → «il suono sale»; allo scadere del `Timer` un breve picco più forte → «borbotta», poi tace. `Timer`/`Tween` seguono `Engine.time_scale`, così restano sincroni fra loro e con gli strumenti F1–F4.

**«Non scade niente» vale anche sul sonno.** Il rituale è stato runtime sul nodo, non persistito: lasciato a metà resta a metà (AC3). Non si auto-resetta all'alba né altrove, perché «non scade niente» è un AC: un rituale portato oltre un sonno emetterà la coppia a cavallo del confine, e sarà la finestra per-notte di 3.6 (non ancora costruita) a ritagliarla. Qui l'unico contratto è emettere la coppia onestamente. `Events.dawn_reached` viene connesso solo come gancio previsto per 3.6/telemetria, non per resettare.

**Raggiungibilità (lezione di `bed.tscn`).** L'occhio è a 1,65 m e il raggio arriva a 1,2 m; la moka sul piano a 0,9 m è ben sopra i ~60 cm irraggiungibili, ma il volume di collisione va reso abbastanza alto/mirabile da vicino, non grande al punto da far comparire il prompt da lontano. La quota esatta si tara **guardando**, ed è una verifica d'operatore (nessun binario Godot qui).

## Verification

**Commands:**
- `godot --headless --path . --quit` -- expected: il progetto importa `moka.gd`, `moka.tscn` e la `kitchen.tscn` estesa senza errori di parse/risorsa (se `godot` 4.7.2 è nel PATH; altrimenti aprire nell'editor e leggere la console).
- `godot --headless --path . tests/test_bench.tscn` (o aprire la scena) -- expected: `_check_moka_ritual` stampa la tavola delle transizioni, l'interattività per stato e i punti d'emissione senza righe `<-- ATTESO`/errore.
- `rg -n "night/|phases/|terminal/" world/interactables/moka.gd` -- expected: nessun risultato (isolamento).

**Manual checks (camminando nel gioco — richiedono un umano e un binario Godot):**
- Comprare la moka al terminale durante l'attesa: verificare che compare in cucina, che non c'era prima, e che c'è ancora dopo aver dormito.
- Fare il caffè per intero: riempire, mettere sul fuoco, sentire il suono salire per decine di secondi e borbottare alla fine, versare, bere; verificare che è mirabile/interagibile da davanti al piano (raggiungibilità), e che non compaiono conti alla rovescia né prompt di sollecito.
- Lasciare il rituale a metà, allontanarsi e tornare: niente si è rotto né è scaduto. Rifarlo più volte nella stessa notte e nelle notti successive.
- Verificare (log/telemetria manuale) che `wait_activity_started(&"caffe")` parte al primo tempo e `wait_activity_ended(&"caffe")` al bere, senza nulla a schermo.

## Spec Change Log

_Nessuna modifica alla spec: nessun loopback bad_spec in questa passata._

## Review Triage Log

### 2026-08-24 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 3: (high 0, medium 1, low 2)
- defer: 1: (high 0, medium 1, low 0)
- reject: 13
- addressed_findings:
  - `[medium]` `[patch]` `player.gd::_set_focus` non rileggeva `prompt()` a oggetto invariato: la moka (primo interagibile a più tempi) congelava il prompt su «Riempi la moka» per tutto il rituale (rompe AC2). Ora, a stesso `_focus`, ri-mostra il prompt corrente (`show_prompt` è idempotente) — il testo segue i tempi mentre si guarda la moka.
  - `[low]` `[patch]` `moka.gd::_start_brewing` non azzerava i livelli del suono prima della salita: un burst finale interrotto poteva lasciare volume/pitch a metà. Aggiunto `_reset_sound_levels()` come prima riga → la salita del Tween parte sempre dal baseline.
  - `[low]` `[patch]` `moka.tscn` portava `prompt_text = "Riempi la moka"` — dato morto, `prompt()` è overridden su `prompt_for(_step)`. Rimosso (una sola sorgente di verità), con commento che il prompt è code-driven.
- reject (rumore o autorizzati dall'intento, verificati): coppia `started`/`ended` «sbilanciata» su abbandono/alba (AC3/AC5 la VOGLIONO: «l'abbandono è un dato»; `_on_dawn_reached` no-op deliberato, «non scade niente»); prompt vuoto in BREWING (AC3: «nessun prompt che solleciti», l'avanzamento è udibile); «bere non dà nessun effetto» (AC4 vieta qualunque bonus); loop/click e divisione intera dell'onda quadra (audio segnaposto, verifica d'operatore); default `next_on_interact`→BREWING e guardia ridondante in `_on_interacted` (la base già filtra su `can_interact()`); assert null dei figli di scena (nessun altro interagibile lo fa); desync timer/audio su `time_scale` (Timer e Tween scalano identici, restano sincroni); `find_in`/singleton e id `&"caffe"` non validati (stessa convenzione di letto/monitor; id fissato dall'epica 3); collisione non-disabled nella scena (`enabled=false` blocca l'interazione e `_ready` disabilita prima del primo frame).

## Auto Run Result

Status: awaiting-operator

**Change implementato:** la **moka** (3.3), l'attività del registro *fare* dell'attesa — la battuta tematica del gioco messa in meccanica. Un interagibile autonomo in cucina che compare SOLO quando l'articolo `&"moka"` è posseduto (comprato al terminale 3.2), leggendo `Game.profile.owns` all'avvio e ascoltando `Events.item_purchased` a runtime — nessun passaggio da `main.gd`. Interagendo con `E` si avanza un rituale a più tempi: riempire → mettere sul fuoco → **attesa reale di decine di secondi** (un `Timer` scalato da `Engine.time_scale`) con un suono posizionale che **sale e alla fine borbotta** → versare → bere. Il primo tempo emette `Events.wait_activity_started(&"caffe")`, il bere emette `wait_activity_ended(&"caffe")`; un rituale abbandonato resta uno `started` senza `ended` (l'abbandono è un dato). Nessun bonus meccanico, nessun conto alla rovescia, nessun fallimento, ripetibile.

**File cambiati:**
- `world/interactables/moka.gd` — NEW: `class_name Moka extends Interactable`. Macchina a stati (`enum Step{IDLE,FILLED,BREWING,READY,POURED}`) con logica pura statica per il banco (`next_on_interact`/`is_interactive`/`prompt_for`/`starts_activity`/`ends_activity`, gemella di `split_spend`); comparsa su possesso/`item_purchased`; timer d'attesa + suono sintetizzato che sale/borbotta; emissione della coppia `wait_activity_*(&"caffe")`; nessun accesso ai punteggi.
- `world/interactables/moka.tscn` — NEW: `StaticBody3D` spento/invisibile, mesh segnaposto (base+serbatoio+manico), collisione mirabile dal piano a 0,9 m, `AudioStreamPlayer3D` posizionale, `Timer` one-shot.
- `world/rooms/kitchen.tscn` — istanziata la `Moka` sul piano d'appoggio a `(2,5, 0,9, 1,5)`; commenti di testa aggiornati.
- `world/player/player.gd` — patch di review: `_set_focus` ora rilegge/ri-mostra il prompt anche a oggetto invariato, così un interagibile a più tempi (la moka) aggiorna la riga mentre lo si guarda.
- `tests/test_bench.gd` — `_check_moka_ritual`: transizioni, interattività per tempo, prompt, punti d'emissione (logica pura, no SceneTree).

**Review findings:** 3 patch applicate (medium 1: prompt che segue i tempi; low 2: reset del suono, `prompt_text` morto); 1 defer (medium: emissione runtime della coppia e seam di comparsa non collaudati dal banco — come il deferral di `spend_lire` in 3.2); 0 intent_gap, 0 bad_spec; 13 reject (rumore o autorizzati dall'intento, riverificati). Follow-up review consigliata: **true** — patch per severità (high 0, medium 1, low 2), punteggio `3×1 + 1×2 = 5 ≥ 5`.

**Verifica eseguita (con binario Godot presente nel repo — `Godot_v4.7.2-stable_win64.exe`):**
- `--headless --path . --import` → exit 0, nessun errore di parse/risorsa (la classe `Moka` si registra, scene e `.tres` importano).
- `--headless res://tests/test_bench.tscn` → exit 0, raggiunge `=== fine ===`, zero righe `<-- ATTESO`/`NON CARICABILE`. La tavola della moka stampa esattamente la I/O matrix (IDLE→FILLED→BREWING→READY→POURED, inerte in BREWING, started@IDLE, ended@POURED, giro che torna a IDLE).
- `--headless --path .` (boot del gioco) → exit pulito, nessun errore dal nostro codice (la cucina estesa con la `Moka` carica e si cabla in `_ready`).
- `rg "night/|phases/|terminal/" world/interactables/moka.gd` → nessun risultato (isolamento delle cartelle intatto).

**Owed all'operatore (`operator_actions`):** le ACs percettive/interattive — sentire il suono salire e borbottare, vedere la moka comparire e la sua raggiungibilità, camminare il rituale, e confermare la coppia telemetria da un log — richiedono un umano su una build con display/audio: `--headless` non le può rendere né ascoltare, nemmeno col binario presente. Vedi `operator_actions` nel frontmatter.

**Rischi residui:**
- ACs percettive/interattive non verificate qui (headless): owed all'operatore.
- Emissione runtime della coppia telemetria e seam di comparsa non esercitati dal banco (vedi `deferred`): la logica pura di transizione è coperta, il wiring che la trasforma in emissioni/presenza no.
- Estetica/audio provvisori: mesh segnaposto e borbottio sintetizzato in codice (onda quadra grave in loop) — da sostituire col pack asset senza toccare la logica.
- Rituale portato oltre un sonno: emette la coppia a cavallo del confine per scelta («non scade niente») — la finestra per-notte di 3.6 (non ancora costruita) la ritaglierà.

## Operator Confirmation

Confirmed 2026-08-24: the external actions this story owed were carried out.

- Aprire una build con display e audio e comprare la moka al terminale durante l'attesa: verificare che compare in cucina, che prima non c'era, e che c'è ancora dopo aver dormito (il possesso sopravvive al save).
- Fare il caffè per intero: riempire → mettere sul fuoco → sentire il suono SALIRE per decine di secondi e BORBOTTARE alla fine → versare → bere; confermare che non ci sono conti alla rovescia né prompt di sollecito, e che il prompt segue i tempi mentre si guarda la moka.
- Verificare la RAGGIUNGIBILITÀ: la moka è mirabile e interagibile stando davanti al piano (occhio 1,65 m, piano 0,9 m), senza che il prompt compaia da lontano. Tarare la quota del volume di collisione guardando, se serve.
- Lasciare il rituale a metà, allontanarsi e tornare: niente si è rotto né è scaduto. Rifarlo più volte nella stessa notte e nelle notti successive.
- Con un log/telemetria manuale, confermare che `Events.wait_activity_started(&"caffe")` parte al primo tempo (riempire) e `wait_activity_ended(&"caffe")` al bere, senza feedback visibile, e che un rituale abbandonato resta uno `started` senza `ended`.

_Appended by the bmad-loop orchestrator (`bmad-loop confirm`, #335): a human confirmed these external actions out of band, and the story was advanced from `awaiting-operator` to `done`._
