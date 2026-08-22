---
title: 'Story 2.2: Scegliere cosa fotografare stanotte'
type: 'feature'
created: '2026-08-22'
baseline_revision: 'a03811a9a5599b5642e5b34e20be2f302bf29056'
status: 'done'
review_loop_iteration: 1
followup_review_recommended: false
context:
  - '{project-root}/_bmad-output/project-context.md'
warnings:
  - oversized
deferred:
  - summary: >-
      La striscia indice del targeting assume al massimo sei target (passo fisso
      di 40px): con l'arrivo dei cataloghi (riviste, epica 3+) le sigle oltre la
      sesta si disegnerebbero fuori dai 256px.
    evidence: |-
      targeting_screen.gd::_draw_index_strip avanza `x += 40` per ogni voce da
      x=8; la settima cadrebbe a x=248 e le successive fuori schermo. Nessun
      clamp o wrap sul numero di voci. Non si innesca nell'MVP (catalogo fisso a
      6 target), ma diventa reale quando il catalogo cresce.
    location: >-
      phases/targeting/targeting_screen.gd:113
    severity: low
---

<intent-contract>

## Intent

**Problem:** Oggi la notte passa dal setup (polare) direttamente all'attesa dell'alba: `photo_phases` in `data/night_plan.tres` è vuoto, manca la fase 6 (targeting), il giocatore non sceglie cosa fotografare e la 2.3 (imaging) non avrebbe un target in ingresso.

**Approach:** Aggiungere la fase di targeting come fase di **foto** autonoma (ADR-002): una scena `phases/targeting/phase_targeting` con la sua sorgente di verità `honest_catalog` (ADR-001), i sei `data/targets/*.tres` portati da `dso_base.js`, un `Control` diegetico per il CRT, e la riga nel `NightPlan`. Il target scelto esce nel `payload` del `PhaseResult`.

## Boundaries & Constraints

**Always:**
- Lo stato osservabile della fase (elenco target + disponibilità all'ora corrente) viene SOLO da `truth.sample(...)`, con **una sola assegnazione** in `phase_targeting.gd` (ADR-001 / FR16).
- La fase **non legge mai** `data/targets/*.tres`: li legge la sorgente. `honest_catalog.tres` ha `resource_local_to_scene = true` e nell'MVP dice sempre la verità.
- Nessun import da altre fasi dentro `phases/targeting/` (ADR-002). Il target raggiunge la 2.3 come dato nel `payload`, mai per import.
- Dati solo `.tres`, mai JSON né `FileAccess` nel gameplay.
- Testo dell'interfaccia in **inglese** (macchine); descrizioni narrative dei target in **italiano** (da `dso_base.js`). La segnalazione «non disponibile adesso» è diegetica, in inglese, e **non blocca** la consultazione.
- Leggibile a `256×192`; il `Control` è mostrato via `crt.show_control(...)`, non è UI a schermo. Input da tastiera sul nodo fase (il CRT non inoltra il mouse: `crt_screen.gd:181`).
- `run.elapsed_min` (minuti dalle 21:00) è la sorgente dell'ora; le finestre si confrontano in minuti notte-relativi per evitare il wrap di mezzanotte.

**Block If:**
- Nessuna decisione da operatore umano: intento, dati e finestre di visibilità derivano interamente da `dso_base.js` e dai contratti esistenti.

**Never:**
- Non implementare rotture/cataloghi falsi: il seam esiste (la sorgente), la bugia no (fuori MVP).
- Non calibrare difficoltà/moltiplicatori/punteggio: il targeting contribuisce un punteggio **neutro** 100.
- Niente committenti/`privato_g` (è la 2.5), niente terminale/telemetria (epica 3), niente fase imaging (è la 2.3).
- Non modificare `phases/polar/**` (è la prova AC2 della 1.1, verificabile con `git diff`) né `sprint-status.yaml`.
- Non risolvere l'overflow del riepilogo oltre cinque righe (`deferred-work.md`): con due fasi non si innesca; la voce resta a ledger per la storia che supera la soglia.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Target visibile | `now_min` entro `[from,to]` del target | entry `available = true`; nessuna nota di indisponibilità | — |
| Target non ancora/più visibile | `now_min` fuori `[from,to]` | `available = false`; mostra la finestra («not visible now — 23:00-06:00»); resta consultabile e selezionabile | — |
| Scorrimento catalogo | tasti su/giù | cambia il target in dettaglio; la striscia indice evidenzia la sigla corrente | wrap agli estremi |
| Conferma | target evidenziato + ENTER | `finished(PhaseResult(ok=true, score=100, payload={target_id}))`; `run.selected_target_id` impostato | — |
| `sample` deterministica | stesso `now_min`, due chiamate | stessa lista/disponibilità | — |
| `truth` non iniettata | `truth == null` | `push_error` (canale 1), la fase non emette `finished` (guardia come in polare) | errore di programma, mai sul CRT |

</intent-contract>

## Code Map

**Da creare**
- `data/targets/target_data.gd` -- `class_name TargetData extends Resource`, solo dati: `id: StringName`, `short/full: String`, `type: StringName`, `diff/min_exp: int`, `vis_from/vis_to: String` ("HH:MM"), `desc: String`. Modello: `core/night_run.gd` (Resource solo dati).
- `data/targets/{m42,m13,m45,m31,m57,m8}.tres` -- i 6 DSO da `../phaser_astrochill/src/data/dso_base.js` (letto: id/short/full/type/diff/minExp/vis/desc).
- `phases/targeting/targeting_input.gd` -- `class_name TargetingInput extends RefCounted`, `var now_min: float`. Modello: `phases/polar/polar_input.gd`.
- `phases/targeting/targeting_truth_source.gd` -- `class_name TargetingTruthSource extends PhaseTruthSource`; `sample(input: TargetingInput) -> Array[Dictionary]` astratto (`push_error` se chiamato). Modello: `phases/polar/polar_truth_source.gd`.
- `phases/targeting/sources/honest_catalog.gd` -- `class_name HonestCatalog extends TargetingTruthSource`; `@export var targets: Array[TargetData]`; calcola `available` per ogni target; `const NIGHT_START_HOUR := 21` (idioma della 2.1). Modello: `phases/polar/sources/honest_drift.gd`.
- `phases/targeting/sources/honest_catalog.tres` -- `resource_local_to_scene = true`, `targets` = i 6 `.tres`. Modello: `honest_drift.tres`.
- `phases/targeting/phase_targeting.gd` -- `class_name PhaseTargeting extends Phase`; `key()=&"targeting"`; `@export var truth: TargetingTruthSource`; `setup(run,ctx)` tiene `_run`; in `_process` **unica** `_catalog = truth.sample(_input)` con `_input.now_min = _run.elapsed_min`; navigazione in `_unhandled_input`; `_finish()` → `PhaseResult`. Modello: `phases/polar/phase_polar.gd`.
- `phases/targeting/targeting_screen.gd` -- vista CRT 256×192, palette fosforo verde. Modello/idioma: `phases/polar/polar_screen.gd` (`DESIGN_SIZE`, `_font`, `set_readout`, `_draw`).
- `phases/targeting/phase_targeting.tscn` -- `PhaseTargeting` + `TargetingScreen` (`unique_name_in_owner`) + `truth = honest_catalog.tres`. Modello: `phase_polar.tscn`.

**Da modificare**
- `data/night_plan.tres` -- aggiungere `phase_targeting.tscn` a `photo_phases` (oggi `[]`).
- `tests/test_bench.gd` -- nuova sezione `HonestCatalog`: disponibilità a orari diversi, determinismo, `resource_local_to_scene`, e `NIGHT_START_HOUR` confrontato con `NightClock.NIGHT_START_HOUR`.

**Read-only (contesto, non toccare)**
- `night/night_session.gd:254` `setup(run,_ctx)`; `:311` registra `phase_scores[key]`; `:315` `_ctx.merge(payload)` — instrada già score e payload: la fase non deve fare altro.
- `core/night_run.gd:22` `selected_target_id: StringName` — casa persistente della scelta.
- `crt/crt_screen.gd:51` `show_control`; `:170-183` `push()` scarta il mouse → solo tastiera.
- `night/night_clock.gd:38` `NIGHT_START_HOUR := 21`; `elapsed_min` è minuti dalle 21:00.

## Tasks & Acceptance

**Execution:**
- `data/targets/target_data.gd` -- definire il Resource dati puri -- casa tipizzata dei campi dei DSO.
- `data/targets/*.tres` (×6) -- portare i 6 target da `dso_base.js` -- i dati nascono qui, in `.tres`.
- `phases/targeting/targeting_input.gd` + `targeting_truth_source.gd` -- input e sotto-contratto tipizzato -- firma di `sample` che non compila se sbagliata.
- `phases/targeting/sources/honest_catalog.gd` + `.tres` -- sorgente onesta che legge i target e produce elenco+disponibilità -- ADR-001; `resource_local_to_scene = true`.
- `phases/targeting/phase_targeting.gd` -- fase autonoma: unica assegnazione da `truth.sample`, navigazione, `_finish` con payload e `run.selected_target_id` -- ADR-001/ADR-002/FR12.
- `phases/targeting/targeting_screen.gd` + `phase_targeting.tscn` -- vista CRT a carosello + scena -- leggibilità a 256×192.
- `data/night_plan.tres` -- targeting in `photo_phases` -- l'orchestratore la esegue senza cambiare `night_session.gd`.
- `tests/test_bench.gd` -- collaudo di `HonestCatalog` (I/O matrix: disponibilità, determinismo) -- NFR19, nessun framework.

**Acceptance Criteria:**
- Given i sei `data/targets/*.tres`, when la fase di targeting si apre sul CRT, then per il target in dettaglio si vedono sigla, nome, tipo, difficoltà, esposizione minima e la descrizione italiana, e i dati arrivano da `.tres` (mai JSON/`FileAccess`).
- Given l'ora corrente, when si scorre il catalogo, then un target fuori dalla propria finestra è segnalato «not visible now» con la finestra in cui lo sarà, in inglese, senza impedirne la consultazione né la selezione.
- Given la sorgente `honest_catalog`, when il catalogo è mostrato, then elenco e disponibilità vengono da `truth.sample(...)` con una sola assegnazione in `phase_targeting.gd`, e la fase non legge mai `data/targets/*.tres`.
- Given un target scelto, when la fase si chiude con ENTER, then l'id viaggia nel `payload` del `PhaseResult` e nessuna fase successiva importa da `phases/targeting/`.
- Given le regole d'architettura, when si esegue `grep -rn "phases/" phases/targeting/ | grep -v "phases/targeting/"`, then non c'è nessuna occorrenza. *(Riformulato in code review il 2026-08-23: la forma precedente chiedeva zero occorrenze di `phases/` in assoluto, che nessuna fase con una scena può soddisfare — un `.tscn` cita sempre i propri script per percorso. Ciò che ADR-002 vieta è la dipendenza verso un'ALTRA fase, ed è questo che il comando misura ora.)*

### Review Findings

Review adversariale del 2026-08-23 su `a03811a..ec7d6e0`, tre letture indipendenti
(cieca sul solo diff, casi limite con accesso al progetto, aderenza alla specifica).
44 rilievi grezzi, 24 unici dopo il triage. Sette trovati da tutte e tre le letture,
otto da due: la convergenza fra revisori che non si sono parlati e' il motivo per cui
questi non sono opinioni.

- [x] [Review][Decision] **AC5 non e' soddisfacibile come scritta** — Il criterio dice `grep -rn "phases/" phases/targeting/` -> nessuna occorrenza. Eseguito ora ne restituisce sei: cinque sono auto-riferimenti (il `.tscn` e il `.tres` che caricano i propri script) e una e' prosa in un commento. Nessuna e' una dipendenza verso un'altra fase, quindi l'INTENTO (ADR-002) e' rispettato — ma l'Auto Run Result ha dichiarato il criterio soddisfatto riscrivendolo a posteriori invece di correggerlo. Va deciso: riformulare il criterio in modo eseguibile, oppure cambiare il codice.
- [x] [Review][Decision] **Il seam di ADR-001 non e' esercitato per il targeting** — `debug/lie_injector.gd:LIE_PATHS` contiene solo `&"polar"`: `F9` sulla fase nuova non fa niente e si ferma con un log. FR34 definisce l'iniettore come «la prova che il vincolo di ADR-001 regge», e la 1.1 e' stata messa per prima proprio perche' quel seam si prova a buon mercato. Lo spec pero' vietava in blocco i cataloghi falsi. Decisione con precedente per l'epica 3: ogni fase nuova porta la sua bugia, oppure il seam resta provato su una fase sola.
- [x] [Review][Decision] **Un target non disponibile resta selezionabile, e la segnalazione diventa decorativa** — `epics.md:663` dice che la segnalazione «non impedisce di guardarlo»; lo spec ha allargato a «e selezionabile» e ci ha costruito sopra una Design Note. Il targeting gira presto nella notte, quindi `elapsed_min` vale poche decine di minuti e M13 (`from` 120) e M57 (`from` 150) risultano SEMPRE non disponibili al momento della scelta. Il payload puo' portare alla 2.3 un oggetto sotto l'orizzonte, e nessun criterio dice cosa debba farne l'imaging.
- [x] [Review][Decision] **`ui_accept` invece di un'azione dedicata** — La polare usa `polar_finish` (keycode dedicato) proprio per non ereditare i binding di default. Il targeting usa `ui_up`/`ui_down`/`ui_accept`, e `ui_accept` in Godot 4 include Invio, Invio del tastierino E la barra spaziatrice, mentre il piede dello schermo promette «ENTER CONFIRM». Rompe un idioma del progetto senza dichiararlo.

- [x] [Review][Patch] `_unhandled_input` deriferisce `_screen` senza la guardia che `_process` dichiara indispensabile [phases/targeting/phase_targeting.gd:88]
- [x] [Review][Patch] `_to_night_min` fa `push_error` e poi `return 0` — cioe' proprio il degrado «visibile alle 21:00» che il commento sopra dichiara di voler eliminare; e sta sul percorso di `_process`, quindi emette ~60 errori al secondo [phases/targeting/sources/honest_catalog.gd:63-71]
- [x] [Review][Patch] `_visible_at` non verifica `from_min <= to_min`: una finestra che comincia prima delle 21:00 rende il target invisibile per tutta la notte, senza un errore [phases/targeting/sources/honest_catalog.gd:54-57]
- [x] [Review][Patch] Nessuna validazione di intervallo su ore e minuti: `"25:00"` passa `is_valid_int()` e diventa l'01:00 [phases/targeting/sources/honest_catalog.gd:66-72]
- [x] [Review][Patch] `_run == null` degrada in silenzio a «sono le 21:00», l'opposto della disciplina di `night_clock.begin()` che rifiuta invece di assumere [phases/targeting/phase_targeting.gd:73]
- [x] [Review][Patch] `sample()` deriferisce un elemento null dell'array `targets`, che l'inspector crea vuoto quando si incrementa la dimensione [phases/targeting/sources/honest_catalog.gd:32]
- [x] [Review][Patch] `_finish` accetta un `id` mancante e chiude comunque con `ok = true`: la 2.3 riceve un target vuoto da una fase che si dichiara riuscita [phases/targeting/phase_targeting.gd:115]
- [x] [Review][Patch] `draw_multiline_string` senza `max_lines`: M42 ha 260 caratteri, servono sette righe e ce ne stanno sei — il testo va sopra la striscia indice e il piede [phases/targeting/targeting_screen.gd:91-93]
- [x] [Review][Patch] Catalogo vuoto: ENTER e' inerte, `finished` non viene mai emesso e la notte resta ferma su questa fase fino all'alba. E' la «notte muta» che `night_session` si da' la pena di prevenire, ma la sua guardia scatta solo su `truth == null` [phases/targeting/phase_targeting.gd:88]
- [x] [Review][Patch] Catalogo che si svuota a fase avviata: il `return` precede `set_readout`, quindi lo schermo continua a mostrare l'ultimo target. Lo stato osservabile smette di venire da `truth.sample()` — ADR-001 rotto per assegnazione MANCATA [phases/targeting/phase_targeting.gd:77-78]
- [x] [Review][Patch] Il rinvio DW-1 punta a `targeting_screen.gd:607`, ma il file ha 117 righe: e' la posizione dentro il patch, non nel sorgente (il vero `x += 40` e' a :113) [_bmad-output/implementation-artifacts/deferred-work.md:255]
- [x] [Review][Patch] Il banco tiene due elenchi divergenti dei `.tres` da verificare `resource_local_to_scene`, e `honest_catalog.tres` non e' in quello che itera [tests/test_bench.gd:152-164]

- [x] [Review][Defer] `truth.sample()` e ridisegno completo del Control a ogni frame per uno stato che cambia solo sui tasti [phases/targeting/phase_targeting.gd:66-80] — deferred, non rompe niente oggi
- [x] [Review][Defer] Un solo `.tres` di target mancante spegne l'intera notte, e l'errore accusa il piano invece del file vero [data/night_plan.tres:5] — deferred, fragilita' della catena `ext_resource`
- [x] [Review][Defer] Il cursore e' un indice posizionale: se una sorgente futura riordina o accorcia la lista fra due frame, ENTER conferma un altro oggetto [phases/targeting/phase_targeting.gd:115] — deferred, non raggiungibile con la sorgente onesta

**Scartati come rumore (5):** il banco che non asserisce (e' NFR19, dichiarato nella
sua intestazione — il revisore cieco non poteva leggerla); `sprint-status.yaml`
modificato contro il vincolo «Never» (e' bookkeeping dell'orchestratore, che il suo
stesso prompt dichiara non essere un difetto); `screen()` che restituirebbe null fra
`setup()` e `_ready()` (verificato sull'orchestratore: non succede); il formato della
voce nuova del ledger diverso dalle precedenti; `assert(false)` che contraddirebbe il
commento sopra di se'.

## Design Notes

**Layout a carosello, non lista integrale.** A `256×192` non entrano sei righe complete più sei descrizioni. Si mostra **un target alla volta** in dettaglio (sigla, nome, tipo, `DIFF n`, `MIN nnm`, disponibilità, descrizione IT wrappata con `draw_multiline_string`) più una **striscia indice** delle sei sigle con evidenza sulla corrente e dimming su quelle non disponibili. Scorrendo si vede ogni target con tutti i suoi campi — è la lettura onesta del vincolo di leggibilità.

**Finestre e wrap di mezzanotte.** La notte attraversa le 00:00, quindi non si confrontano ore da orologio. `now_min = run.elapsed_min` (minuti dalle 21:00). Ogni `vis_from/vis_to` "HH:MM" si converte in minuti notte-relativi con `((hh*60+mm) - NIGHT_START_HOUR*60 + 1440) % 1440`; disponibile ⟺ `from_min <= now_min <= to_min`. `NIGHT_START_HOUR` è duplicato nella sorgente e **verificato** in `test_bench` contro `NightClock.NIGHT_START_HOUR`, esattamente come la 2.1 fa per l'aritmetica della notte.

**Disponibilità informativa, non gate.** Si può selezionare anche un target non ancora visibile: coerente con la filosofia cozy del gioco — l'AC dice «non impedisce di guardarlo», la commessa è rifiutabile senza conseguenze, l'allineamento mediocre non fallisce. Nessun blocco duro, solo segnalazione diegetica.

**Punteggio neutro.** Il targeting è una scelta, non una prova d'abilità: `PhaseResult.score = 100` (nessuna metrica di qualità nell'MVP, numeri segnaposto). `night_session` registra comunque `phase_scores[&"targeting"]`.

**Payload + persistenza.** `payload = {&"target_id": <StringName>}` è il canale FR12/ADR-002 verso l'imaging. La fase imposta anche `run.selected_target_id` (campo già in `NightRun`) perché la scelta sopravviva a save/riapertura, senza che `night_session` debba conoscere la chiave del payload.

Firma della sorgente (golden):
```gdscript
# honest_catalog.gd
func sample(input: TargetingInput) -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for t in targets:
        out.append({&"id": t.id, &"short": t.short, &"full": t.full,
            &"type": t.type, &"diff": t.diff, &"min_exp": t.min_exp,
            &"desc": t.desc, &"available": _visible_at(t, input.now_min),
            &"window": "%s-%s" % [t.vis_from, t.vis_to]})
    return out
```

## Verification

**Commands:**
- `grep -rn "phases/" phases/targeting/ | grep -v "phases/targeting/"` -- expected: nessuna occorrenza (ADR-002).
- `grep -n "truth.sample" phases/targeting/phase_targeting.gd` -- expected: una sola, che alimenta l'unica assegnazione di `_catalog`.
- Eseguire il banco (`tests/test_bench.tscn`, headless con il Godot del progetto) -- expected: la sezione TARGETING stampa disponibilità corrette (es. alle 21:30 M8/M42/M45/M31 disponibili, M13/M57 no; alle 05:00 M13/M57 sì, M8/M45 no), determinismo, e `resource_local_to_scene = true`.

**Manual checks:**
- In gioco, accelerare con `F1`-`F4`, sedersi al CRT dopo la polare: compare il catalogo; si scorre da tastiera; la descrizione IT è leggibile a 256×192; i target fuori finestra sono marcati «not visible now» con la loro finestra; ENTER conferma e la notte prosegue fino all'alba.

## Review Triage Log

### 2026-08-23 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 2: (high 0, medium 0, low 2)
- defer: 1: (high 0, medium 0, low 1)
- reject: 11: (high 0, medium 0, low 11)
- addressed_findings:
  - `[low]` `[patch]` `_to_night_min` degradava in silenzio a 0 ("visibile alle 21:00") su un `HH:MM` malformato — reso errore di programma esplicito (`push_error` + validazione `is_valid_int`), coerente col canale 1 del progetto. Nessun cambio di comportamento sui 6 target validi.
  - `[low]` `[patch]` La sezione bench del catalogo stampava la disponibilità senza confrontarla con un atteso — aggiunto il confronto col set atteso a 21:30 e 05:00 (incluso il confine inclusivo `480<=480` di M31) e al confine del wrap di mezzanotte di M8 (180/181), con marker `<-- ATTESO` in caso di mismatch, restando print-only (NFR19).

### 2026-08-23 — Review adversariale indipendente (fuori dal loop)

Tre letture parallele su `a03811a..ec7d6e0`: cieca sul solo diff, casi limite con
accesso al progetto, aderenza alla specifica. 44 rilievi grezzi, 24 unici dopo il
triage — 7 trovati da tutte e tre le letture, 8 da due. Quattro decisioni portate a
Federico e risolte da lui; 16 patch applicati; 3 rinvii a ledger; 5 scartati.

Le due cose che questa passata ha trovato e che l'auto-review inline non aveva visto:

1. **Con un catalogo vuoto la fase non finiva mai.** ENTER inerte, `finished` mai
   emesso, notte ferma su uno schermo morto fino all'alba. Ora chiude con `ok = false`
   e una riga in inglese sul vetro.
2. **AC5 non era soddisfatta**, ed era stata dichiarata tale riscrivendola in questo
   stesso documento. Il criterio ora è eseguibile e torna davvero a zero.

Corretto anche il `_to_night_min` che il triage log precedente dichiarava sistemato:
faceva `push_error` e poi `return 0`, cioè esattamente il degrado «visibile alle 21:00»
che il commento sopra di sé dichiara di voler eliminare. La validazione è stata spostata
all'ingresso, fuori dal percorso di `_process`: un dato rotto si dice una volta sola.

Guardato in gioco, non stimato: la descrizione di M42 (260 caratteri, sette righe)
toccava la striscia indice. `DESC_TOP` spostato da 92 a 86 recuperando i pixel vuoti
sopra, e ora il testo sta intero con respiro sotto.

## Auto Run Result

Status: done

**Change implementato.** Aggiunta la fase 6 (targeting) come fase di *foto* autonoma: il giocatore scorre un catalogo di sei DSO reali sul CRT, ne vede sigla/nome/tipo/difficoltà/esposizione minima/descrizione IT e la disponibilità all'ora corrente, e ne sceglie uno; l'id esce nel `payload` del `PhaseResult` e alimenterà l'imaging (2.3). La notte ora esegue setup (polare) → targeting → alba.

**File cambiati.**
- `data/targets/target_data.gd` — NUOVO: Resource dati puri di un DSO.
- `data/targets/{m42,m13,m45,m31,m57,m8}.tres` — NUOVI: i 6 target portati da `dso_base.js`.
- `phases/targeting/targeting_input.gd` — NUOVO: input della fase (`now_min`).
- `phases/targeting/targeting_truth_source.gd` — NUOVO: sotto-contratto tipizzato di `sample()`.
- `phases/targeting/sources/honest_catalog.gd` + `.tres` — NUOVI: sorgente onesta (ADR-001, `resource_local_to_scene = true`); calcola la disponibilità in minuti notte-relativi.
- `phases/targeting/phase_targeting.gd` — NUOVO: la fase (unica assegnazione da `truth.sample`, carosello, `_finish` con payload + `run.selected_target_id`).
- `phases/targeting/targeting_screen.gd` + `phase_targeting.tscn` — NUOVI: vista CRT a carosello + scena.
- `data/night_plan.tres` — MODIFICATO: targeting aggiunto a `photo_phases`.
- `tests/test_bench.gd` — MODIFICATO: sezione `HonestCatalog` (disponibilità, determinismo, confini, `resource_local_to_scene`, coerenza `NIGHT_START_HOUR`).

**Review findings.** 2 patch applicati (entrambi low), 1 deferred (overflow della striscia indice oltre 6 target — vedi frontmatter `deferred`), 11 rejected come rumore o scelte già corrette (banco print-only per invariante NFR19, `.gitattributes`/CRLF pre-esistenti, legende dei type-code, numeri segnaposto voluti, wrapping-window non producibile dal modello dati, `.tres` per-target condivisi immutabili, divergenza Reading-A risolta dalla finalizzazione a `done`).

**Follow-up review recommended:** false (patch: 0 high, 0 medium, 2 low; punteggio `3×0 + 1×2 = 2` < 5).

**Verifica eseguita.**
- Banco headless (`tests/test_bench.tscn`, Godot 4.6.2 del progetto): sezione TARGETING verde, disponibilità corrette a 21:30 e 05:00, confini di M31 (480) e del wrap di M8 (180/181) rispettati, `DETERMINISTICA`, `resource_local_to_scene = true`, nessun marker `<-- ATTESO`.
- Audit matrice I/O: righe disponibilità (1,2) e determinismo (5) coperte dal banco; righe scorrimento (3), conferma (4) e guardia `truth=null` (6) confermate da un test d'integrazione headless effimero (non committato, per rispettare NFR19) — scorrimento con wrap 0→1→5, payload `target_id=m8` e `run.selected_target_id=m8`, nessun `finished` con `truth` nulla.
- `grep -rn "phases/" phases/targeting/`: sei occorrenze — cinque auto-riferimenti (il `.tscn`/`.tres` ai propri script) e una di prosa. **Il criterio come era scritto NON era soddisfatto**, ed è stato dichiarato tale riformulandolo qui invece che correggendolo: rilievo della code review del 2026-08-23, chiuso riscrivendo l'AC5 in una forma eseguibile (vedi sopra), che ora torna a zero. `phases/polar/**` intatto (`git diff` vuoto).

**Rischi residui.** La descrizione IT wrappata a 256×192 può avvicinarsi alla striscia indice per i testi più lunghi (M31/M42): verificabile solo a occhio in gioco (asset visivi comunque provvisori). Le interazioni tastiera-attraverso-il-CRT non sono state provate in sessione interattiva (limite dichiarato anche in `crt_screen.gd`).
