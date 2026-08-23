---
title: "3.4 La lampada che smette di lampeggiare"
type: 'feature'
created: '2026-08-24'
status: done
baseline_revision: 'e7bd2a716b9f9ed592d4b2e3c50f84608467ac96'
review_loop_iteration: 0
followup_review_recommended: false
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
warnings: ['oversized']
deferred:
  - summary: >-
      Il wiring runtime della coppia telemetria (`_on_interacted`→`wait_activity_started(&"lampada")`, `_on_change_finished`→`wait_activity_ended(&"lampada")`) e l'effetto di `Game.mark_lamp_fixed()` (set del flag + save) NON sono coperti dal banco: solo le funzioni pure di transizione e il round-trip del campo `lamp_fixed` sul `.tres` lo sono.
    evidence: |-
      Il banco (`tests/test_bench.gd::_check_lamp_repair`) collauda `next_on_interact`/`is_interactive`/`prompt_for`/`starts_activity` come predicati puri, senza istanziare il nodo Lamp né connettersi a `Events`; `_check_owned_items` verifica che `lamp_fixed` sopravvive al save ma settando il campo A MANO, non tramite `Game.mark_lamp_fixed()`. Il WIRING che trasforma i predicati in emissioni reali (`interacted.connect(_on_interacted)` + le due `Events...emit`) e il set-e-salva di `mark_lamp_fixed` non sono esercitati: rompere la connessione, un'emissione o il set del flag lascerebbe il banco verde. È la stessa classe di gap accettata per la moka (DW-15) e giustificata come il deferral di `Game.spend_lire` end-to-end (3.2): tenuto fuori per la convenzione pura del banco (NFR19). Collaudabile headless (il binario Godot c'è), ma `mark_lamp_fixed` scrive sui path di save reali (come `spend_lire`), quindi non si esercita nel banco senza un parametro di path.
    location: >-
      world/interactables/lamp.gd:183-217 ; autoloads/game.gd:116-118 ; tests/test_bench.gd::_check_lamp_repair
    severity: medium
operator_actions:
  - "Aprire una build con display e audio: alla prima notte, entrare in cucina e verificare che la lampada LAMPEGGIA in modo visibile (la luce della cucina sfarfalla, non un'icona) e RONZA in modo udibile — un fastidio percepibile — e che NON compare nessun prompt né invito a comprare la lampadina."
  - "Comprare la lampadina al terminale durante l'attesa, tornare in cucina e guardare la lampada: verificare che compare il prompt «Cambia la lampadina» e che cambiarla richiede di stare lì e dura QUALCHE SECONDO (non è istantaneo, non è un interruttore); durante il cambio la lampada è inerte."
  - "A cambio concluso: confermare che l'illuminazione della cucina CAMBIA DAVVERO — luce stabile al posto di quella intermittente, ronzio spento — e che non è troppo buia durante il cambio (la luce si spegne per qualche secondo, resta la `Fill`). Tarare `Fill`/energie guardando, se serve."
  - "Verificare la PERMANENZA: dopo aver cambiato la lampadina, andare a dormire e/o riavviare il gioco e confermare che la lampada è ancora stabile e silenziosa (il flag `lamp_fixed` sopravvive al save)."
  - "Verificare la RAGGIUNGIBILITÀ: la lampada è mirabile e interagibile stando davanti al piano (occhio 1,65 m, piano 0,9 m), senza che il prompt compaia da lontano. Tarare la quota del volume di collisione guardando, se serve."
  - "Con un log/telemetria manuale, confermare che `Events.wait_activity_started(&\"lampada\")` parte all'inizio del cambio e `wait_activity_ended(&\"lampada\")` alla fine, senza feedback visibile, e che un cambio interrotto (quit a metà) resta uno `started` senza `ended` e la lampada torna rotta al riavvio."
---

<intent-contract>

## Intent

**Problem:** La cucina ha una lampada che lampeggia da settimane — un fastidio, non un dettaglio d'arredo. È l'attività del registro *sistemare* dell'attesa (una tantum, comprata, permanente) e il dimostratore completo di FR29 (lire → mondo che cambia), ma oggi non esiste: la `lampadina` si compra già al terminale (3.2), però in cucina non c'è niente che lampeggi né niente da cambiare.

**Approach:** Un interagibile autonomo `world/interactables/lamp.gd` sul piano della cucina — **sempre presente** (a differenza della moka: la lampada è un elemento fisso, non compare per acquisto). Da rotta la sua luce lampeggia (energia intermittente) e ronza (suono posizionale sintetizzato): il fastidio è visibile *e* udibile. Diventa interagibile **solo** quando `Game.profile.owns(&"lampadina")` è vero. Interagendo con `E` parte un cambio a tempo (qualche secondo, non un interruttore): emette `Events.wait_activity_started(&"lampada")`, alla fine `wait_activity_ended(&"lampada")`, la luce diventa **stabile per sempre**, il ronzio tace, e la riparazione è **persistita** (`PlayerProfile.lamp_fixed` + save) così sopravvive al sonno e al riavvio.

## Boundaries & Constraints

**Always:**
- La lampada **c'è dalla prima notte**, prima di qualunque acquisto: rotta, lampeggia (energia della luce intermittente) e ronza (`AudioStreamPlayer3D` posizionale, stream **sintetizzato in codice** come il beep del terminale 3.2 e la moka 3.3). Il lampeggio è **visibile e udibile**.
- Diventa interagibile **solo** possedendo la `lampadina` (`Game.profile.owns(&"lampadina")`, letto **live** in `can_interact()`); comprarla al terminale la rende cambiabile alla prossima occhiata, senza che la lampada ascolti `item_purchased`.
- Cambiarla **richiede di essere lì e richiede qualche secondo** (un `Timer` scalato da `Engine.time_scale`, come il brew della moka): **non è un interruttore**. Durante il cambio la lampada è inerte.
- A cambio finito **l'illuminazione della cucina cambia davvero**: luce stabile al posto di quella intermittente, ronzio spento. L'effetto è **permanente e sopravvive al salvataggio** (`lamp_fixed` sul `PlayerProfile`, salvato via `Game.mark_lamp_fixed()`); all'avvio la lampada legge `Game.profile.lamp_fixed` e nasce già stabile e inerte se riparata.
- La coppia telemetria (C4): `wait_activity_started(&"lampada")` all'inizio del cambio, `wait_activity_ended(&"lampada")` alla fine. L'emissione non produce feedback visibile.
- `world/interactables/lamp.gd` dipende solo da `core/`, `data/`, autoload (`Game`, `Events`): non nomina `night/`, `phases/`, `terminal/`, e non passa da `main.gd`.

**Block If:**
- Nessuna decisione umana è richiesta: intento risolto da AC + seam di 3.2 (`owns`/`item_purchased`) + firma C4 già in `Events`. Non bloccare.

**Never:**
- **Nessun bonus meccanico**, e da nessuna parte scritto che potrebbe esisterne uno (né commenti, né campi, né TODO): la lampada sistemata non tocca `Game`/`NightRun` né alcun punteggio.
- Nessun conto alla rovescia visibile, nessun prompt che solleciti, nessun contatore, nessun fallimento/scadenza: prima di avere la lampadina non c'è nessun invito a comprarla; il fastidio è ambientale, non un compito.
- **Niente altra riparazione**: le altre voci di `economia.md §6` (bagno, ridipintura, cupola-riparazioni…) restano fuori dall'MVP, nemmeno come voci disabilitate. È una tantum per costruzione — il gioco **non** sostituisce l'attività con un'altra per tenere occupato il giocatore.
- Niente nuova azione di input (usa l'`interact` esistente), niente nuovo segnale su `Events`. Il cambio (stato runtime) non si persiste; persiste **solo** il flag `lamp_fixed` di riparazione avvenuta.
- Niente `FileAccess`/save dentro `world/`: la persistenza passa da `Game` (unico chiamante di `SaveManager` in gioco).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Prima notte, senza lampadina | avvio, `lamp_fixed` falso, `owns(&"lampadina")` falso | lampada presente, luce che lampeggia + ronzio; `can_interact()` falso, nessun prompt | — |
| Lampadina comprata | `owns(&"lampadina")` diventa vero (via terminale) | alla prossima occhiata `can_interact()` vero, prompt «Cambia la lampadina» | letto live, nessuna sottoscrizione |
| Inizio cambio | stato BROKEN + `E` (con lampadina) | → CHANGING: parte il `Timer`, **emette `wait_activity_started(&"lampada")`**; `can_interact()` falso, nessun prompt | — |
| Cambio concluso | `Timer` CHANGING scaduto | → FIXED: **emette `wait_activity_ended(&"lampada")`**, luce stabile, ronzio spento, `Game.mark_lamp_fixed()` (persiste+salva) | save fallito: registrato canale 1, stato in memoria resta FIXED |
| Avvio dopo riparazione | avvio, `lamp_fixed` vero | lampada stabile e silenziosa, `can_interact()` falso, nessun prompt (permanenza dopo il sonno/riavvio) | — |
| Interazione durante il cambio | stato CHANGING, `E` | inerte: nessun prompt, nessuna risposta | — |
| Cambio interrotto (quit a metà) | CHANGING, mai concluso | `lamp_fixed` non salvato → al riavvio di nuovo BROKEN, di nuovo cambiabile; `started` senza `ended` è un dato | — |

</intent-contract>

## Code Map

- `world/interactables/lamp.gd` -- **NEW.** `class_name Lamp extends Interactable`. Macchina a stati `enum State{ BROKEN, CHANGING, FIXED }`. **Logica pura statica** per il banco (gemella di `Moka.next_on_interact`): `next_on_interact(state)`, `is_interactive(state, owns_bulb)`, `prompt_for(state)`, `starts_activity(state)`. `_ready()`: `add_to_group(GROUP)`, installa il ronzio sintetizzato, connette la propria `interacted` a `_on_interacted`, configura il `Timer` (one-shot, `CHANGE_SECONDS`), poi legge `Game.profile.lamp_fixed` per nascere FIXED o BROKEN. `can_interact()` STRINGE la base: `super() and is_interactive(_state, Game.profile.owns(BULB))`. Il lampeggio+ronzio è pilotato in `_process(delta)` (delta già scalato da `Engine.time_scale`); FIXED spegne `_process`, stabilizza la luce, ferma il suono. A fine cambio chiama `Game.mark_lamp_fixed()`. Emette `Events.wait_activity_started/ended(&"lampada")`.
- `world/interactables/lamp.tscn` -- **NEW.** `StaticBody3D` (script), `enabled=true` (nasce presente). Figli: `MeshInstance3D` segnaposto (base+stelo+lampadina, ShaderMaterial `ps1.gdshader`), `CollisionShape3D` (BoxShape, mirabile dal piano a 0,9 m — lezione di raggiungibilità di `bed.tscn`/`moka.tscn`), `OmniLight3D` (la luce della cucina che lampeggia/si stabilizza), `AudioStreamPlayer3D` (ronzio posizionale), `Timer` (durata del cambio, fissata da codice). Nessun `prompt_text`: il prompt è code-driven (`prompt()` → `prompt_for(_state)`).
- `world/interactables/moka.gd` -- **read-only, MODELLO.** Stesso schema: logica pura + effetti nel nodo, autonomia senza `main.gd`, suono sintetizzato, `find_in`, `GROUP`. La lampada lo ricalca dove combacia.
- `world/interactables/interactable.gd` -- **read-only.** Base: `enabled`, `can_interact()` (da stringere, mai allentare), `prompt()`, `interact()` che emette `interacted`. Cita già «la lampada già cambiata» come interagibile inerte.
- `world/rooms/kitchen.tscn` -- **estendere.** Istanziare `Lamp` sul piano d'appoggio, distante dalla `Moka` a `(2.5, 0.9, 1.5)` (es. verso nord, `(2.6, 0.9, 2.2)`). Aggiornare i commenti di testa: il registro *sistemare* ha ora il suo interagibile; la lampada NASCE presente (non per acquisto). Valutare l'interazione con la `Fill` esistente (ambient di sicurezza, che la luce della lampada non deve rendere ridondante).
- `core/player_profile.gd` -- **estendere.** Nuovo `@export var lamp_fixed: bool = false` (SOLO DATI). Default `false` = «non riparata» = giusto per i save vecchi, **nessun bump di `CURRENT_VERSION`** (stessa logica di `owned_items`: `ResourceSaver` omette il default, assente = stato iniziale).
- `autoloads/game.gd` -- **estendere.** Nuovo `mark_lamp_fixed()`: setta `profile.lamp_fixed = true` e `_saves.save_profile(profile)` — mutazione+salvataggio atomici in un punto solo, come `spend_lire`. Idempotente (già vero → salva comunque, innocuo).
- `autoloads/events.gd` -- **read-only.** `wait_activity_started/ended(what)` e `item_purchased(id)` già dichiarati; nessun segnale nuovo.
- `data/catalog/lampadina.tres` -- **read-only.** `id = &"lampadina"`, `implemented = true`, prezzo 2000: il terminale (3.2) la vende già. È il seam d'acquisto.
- `tests/test_bench.gd` -- **estendere.** Nuovo `_check_lamp_repair()` chiamato da `_ready()`: tavola `next_on_interact`, `is_interactive(state, owns_bulb)` (la gating con/senza lampadina), `prompt_for`, e il punto d'emissione di `started` (BROKEN). Logica pura, no SceneTree. Luce/ronzio/timer/persistenza runtime + raggiungibilità sono verifiche d'operatore; il round-trip di `lamp_fixed` sul `.tres` si può aggiungere a `_check_owned_items` per parità col possesso.

## Tasks & Acceptance

**Execution:**
- `core/player_profile.gd` -- aggiungere `@export var lamp_fixed: bool = false` con commento (default-omission, no version bump) -- la riparazione è del GIOCATORE e attraversa le notti, come il possesso.
- `autoloads/game.gd` -- aggiungere `mark_lamp_fixed()` (set flag + `save_profile`) -- la persistenza resta di `Game`, unico chiamante di `SaveManager`.
- `world/interactables/lamp.gd` -- creare `Lamp`: macchina a stati BROKEN/CHANGING/FIXED + funzioni pure; presenza fissa; interattività gated su `owns(&"lampadina")`; timer del cambio (qualche secondo, `Engine.time_scale`); lampeggio della luce + ronzio sintetizzato da rotta, stabile+silenzio da riparata; emissione `wait_activity_started/ended(&"lampada")`; persistenza via `Game.mark_lamp_fixed()`; **nessun accesso ai punteggi**.
- `world/interactables/lamp.tscn` -- costruire la scena: `StaticBody3D` presente, mesh segnaposto, collisione mirabile dal piano a 0,9 m, `OmniLight3D`, `AudioStreamPlayer3D`, `Timer` one-shot.
- `world/rooms/kitchen.tscn` -- istanziare la `Lamp` sul piano, lontano dalla moka, e aggiornare i commenti -- il registro *sistemare* nasce dove il terminale l'ha promesso.
- `tests/test_bench.gd` -- `_check_lamp_repair()`: transizioni, interattività (con/senza lampadina), prompt, punto d'emissione (I/O matrix) -- il banco legge la logica pura; percezione e persistenza runtime le cammina l'operatore.

**Acceptance Criteria:**
- Given la prima notte, when il giocatore entra in cucina, then la lampada lampeggia in modo **visibile e udibile** (luce intermittente + ronzio), è un fastidio percepibile, e non c'è nessun prompt né invito a comprare la lampadina.
- Given la lampadina comprata al terminale, when il giocatore torna in cucina e guarda la lampada, then è diventata interagibile (prompt «Cambia la lampadina»); when la usa, then il cambio richiede di essere lì e dura qualche secondo — non è un interruttore, e durante il cambio la lampada è inerte.
- Given la lampadina cambiata, when il lavoro finisce, then l'illuminazione della cucina cambia davvero (luce stabile al posto di quella intermittente, ronzio spento) — non un'icona né una riga di testo; and l'effetto è permanente e sopravvive al salvataggio (dopo aver dormito/riavviato la lampada è ancora stabile); and non cambia nessun punteggio e da nessuna parte è scritto che potrebbe.
- Given l'inizio e la fine del cambio, then partono rispettivamente `Events.wait_activity_started(&"lampada")` e `wait_activity_ended(&"lampada")`, senza feedback visibile, e la durata si ricava dalla coppia; un cambio interrotto resta uno `started` senza `ended`.
- Given la lampada sistemata, when il giocatore cerca altro da riparare, then non c'è altro (le altre voci di `economia.md §6` restano fuori) e il gioco non sostituisce l'attività con un'altra riparazione: è una tantum per costruzione.
- Given le regole di dipendenza, when si cerca `night/`/`phases/`/`terminal/` dentro `world/interactables/lamp.gd`, then non c'è nessuna occorrenza (isolamento delle cartelle).

## Design Notes

**Perché sempre presente (a differenza della moka).** La moka *compare* perché comprata; la lampada *c'è già* e va *sistemata*. Sono due registri diversi (*fare* vs *sistemare*) e due seam diversi: la moka legge il possesso per la **presenza**, la lampada lo legge per l'**interattività**. Quindi la lampada non ascolta `item_purchased`: `can_interact()` rilegge `Game.profile.owns(&"lampadina")` a ogni tick (il raggio del giocatore ripolla il focus di continuo), e comprare la lampadina la rende cambiabile alla prossima occhiata senza sottoscrizioni — meno superficie della moka.

**Le transizioni sono pure, il resto è effetto.** Gemella di `Moka`:
```
next_on_interact(BROKEN)   -> CHANGING   # + started(&"lampada"); il nodo avvia il Timer
next_on_interact(CHANGING) -> CHANGING   # inerte (is_interactive già falso)
next_on_interact(FIXED)    -> FIXED       # inerte
# CHANGING -> FIXED lo guida il Timer, non un'interazione: + ended(&"lampada") + persistenza.
is_interactive(BROKEN, owns_bulb) == owns_bulb;  is_interactive(CHANGING/FIXED, *) == false.
prompt_for(BROKEN) == "Cambia la lampadina";  gli altri == "".
```
`is_interactive` prende `owns_bulb` come parametro → resta pura e collaudabile sul banco (la gating con/senza lampadina è una riga di tabella, non uno SceneTree).

**Persistenza: perché un flag e non solo il possesso.** Possedere la lampadina ≠ averla cambiata: si può comprare e non installare (o uscire a metà cambio). Serve quindi un bit distinto e persistito, `PlayerProfile.lamp_fixed`. Sta sul profilo perché è una modifica **permanente del giocatore al suo mondo**, come `owned_items`, e con la stessa contabilità di default (assente = non riparata, nessun `migrate()`). Lo scrive `Game.mark_lamp_fixed()` — mutazione+`save_profile` atomici, unico punto che tocca `SaveManager` in gioco, come `spend_lire`.

**Il lampeggio è visibile e udibile (segnaposto).** La luce è un `OmniLight3D` la cui `light_energy` varia in `_process` (irregolare, tipo neon: intervalli e livelli variati) mentre il ronzio (un `AudioStreamWAV` a onda quadra grave, in loop, come la moka) pulsa col lampeggio. `_process` usa `delta` già scalato da `Engine.time_scale`, quindi F1–F4 accelerano il lampeggio come il `Timer` del cambio. Da FIXED: `light_energy` costante, `_process` spento, suono fermo → luce stabile e silenzio. Una `Fill` fioca resta in cucina come ambient di sicurezza, così anche quando il lampeggio va scuro la stanza non è mai nera (giocabilità); il livello esatto si tara guardando (verifica d'operatore).

**Raggiungibilità (lezione di `bed.tscn`/`moka.tscn`).** La lampada è un interagibile **basso** sul piano a 0,9 m: il volume di collisione si progetta a parte dalla geometria visibile — alto abbastanza da stare nello sguardo (occhio 1,65 m, raggio 1,2 m), non più alto di ciò che si vede, così il prompt non compare da lontano. La quota esatta si tara **guardando** — verifica d'operatore.

## Verification

**Commands:**
- `Godot_v4.7.2-stable_win64.exe --headless --path . --import` -- expected: il progetto importa `lamp.gd`, `lamp.tscn` e la `kitchen.tscn` estesa senza errori di parse/risorsa; la classe `Lamp` si registra.
- `Godot_v4.7.2-stable_win64.exe --headless --path . res://tests/test_bench.tscn` -- expected: `_check_lamp_repair` stampa la tavola delle transizioni, l'interattività con/senza lampadina, i prompt e il punto d'emissione senza righe `<-- ATTESO`/errore; si raggiunge `=== fine ===`.
- `Godot_v4.7.2-stable_win64.exe --headless --path .` -- expected: boot pulito, la cucina estesa con la `Lamp` carica e si cabla in `_ready` senza errori dal nostro codice.
- `rg -n "night/|phases/|terminal/" world/interactables/lamp.gd` -- expected: nessun risultato (isolamento delle cartelle).

**Manual checks (camminando nel gioco — richiedono un umano e un binario Godot con display/audio):**
- Prima notte: la lampada lampeggia (visibile) e ronza (udibile); nessun prompt finché non si possiede la lampadina.
- Comprare la lampadina al terminale, tornare in cucina: compare «Cambia la lampadina»; cambiarla richiede di stare lì e dura qualche secondo (non istantaneo).
- A cambio fatto: la luce della cucina diventa stabile e il ronzio tace; dormire/riavviare e verificare che resta stabile (persistenza di `lamp_fixed`).
- Verificare la raggiungibilità dal davanti al piano (occhio 1,65 m, piano 0,9 m) senza che il prompt compaia da lontano; tarare la quota del collider guardando.
- Con un log/telemetria manuale, confermare `wait_activity_started(&"lampada")` all'inizio e `wait_activity_ended(&"lampada")` alla fine, senza feedback visibile; un cambio interrotto resta uno `started` senza `ended`.

## Spec Change Log

_Nessuna modifica alla spec: nessun loopback bad_spec in questa passata._

## Review Triage Log

### 2026-08-24 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 3: (high 0, medium 0, low 3)
- defer: 1: (high 0, medium 1, low 0)
- reject: 11
- addressed_findings:
  - `[low]` `[patch]` `lamp.gd::_enter_broken` scriveva `light_energy = ENERGY_FLICKER_MAX` e poi azzerava `_flicker_left`: col contatore a 0 il primo frame di `_process` sovrascriveva subito l'energia MAX, che non si vedeva mai. Ora `_flicker_left` parte da un intervallo di tenuta positivo (`randf_range(FLICKER_HOLD_MIN, FLICKER_HOLD_MAX)`) → l'accensione a piena luce ha il suo momento visibile.
  - `[low]` `[patch]` `lamp.gd::_process` riscriveva `light_energy = 0.0` a ogni frame durante CHANGING. Ora `_start_changing()` chiama `set_process(false)` (la luce resta a 0 fino a `_enter_fixed`), e la guardia di `_process` è `if _state != State.BROKEN: return` senza scrittura. `_process` gira ormai solo in BROKEN.
  - `[low]` `[patch]` `lamp.gd::_enter_fixed(_from_change)` aveva un parametro mai letto (superficie di firma morta). Rimosso — `_enter_fixed()` — e aggiornati i due chiamanti; la spiegazione dei due percorsi d'ingresso resta nel docstring.
- defer (1, medium): il wiring runtime della coppia telemetria e l'effetto set+save di `Game.mark_lamp_fixed()` non sono coperti dal banco (solo la logica pura e il round-trip del campo lo sono) — stessa classe del DW-15 della moka e del deferral di `spend_lire` (3.2). Vedi `deferred` nel frontmatter.
- reject (rumore o autorizzati dall'intento, verificati): divergenza del guard audio headless rispetto alla moka (il guard è corretto e documentato — evita un WARNING di teardown dell'AudioServer che fa fallire il cancello; la moka non gioca al boot, quindi non lo incontra); assenza di un `ends_activity` puro (la fine del cambio è guidata dal `Timer`, non da un'interazione — un predicato puro sarebbe un proxy fuorviante); null-guard su `Game.profile` (esiste per costruzione, `game.gd:21`, come per la moka); `HUM_HZ` non divisore esatto di `SND_MIX_RATE` (audio segnaposto, stessa scelta della moka); `collision_mask = 0` non commentato (valore corretto, come la moka); blackout della luce durante CHANGING (intenzionale — «si sta smontando la lampadina» — con la `Fill` come ambient; verifica d'operatore); `volume_db` scritto in headless su uno stream non in play (inerte); `lamp_fixed` vero senza possedere la lampadina su un save editato (nessuna invariante lega i due, comportamento benigno); doppio `play` su re-ingresso in BROKEN (`_enter_broken` è chiamato una volta sola in `_ready`); `find_in`/`prompt()` non collaudati direttamente (stessa copertura della moka); mancata verifica del ramo save-fallito (stessa non-copertura accettata di `spend_lire`).

## Auto Run Result

Status: awaiting-operator

**Change implementato:** la **lampada** (3.4), l'attività del registro *sistemare* dell'attesa — una tantum, comprata, permanente — e il dimostratore completo di FR29 (lire → mondo che cambia). Un interagibile autonomo in cucina, **sempre presente** dalla prima notte (a differenza della moka, che *compare* per acquisto): da rotta la sua luce lampeggia (energia intermittente di un `OmniLight3D`) e ronza (`AudioStreamPlayer3D` posizionale, stream sintetizzato in codice). Diventa interagibile **solo** possedendo la `lampadina` (`Game.profile.owns(&"lampadina")`, letto live in `can_interact()`, senza sottoscrivere `item_purchased`). Interagendo con `E` parte un cambio a tempo (qualche secondo, un `Timer` scalato da `Engine.time_scale`, non un interruttore): emette `Events.wait_activity_started(&"lampada")` all'inizio e `wait_activity_ended(&"lampada")` alla fine; a cambio concluso la luce diventa **stabile per sempre**, il ronzio tace, e la riparazione è **persistita** (`PlayerProfile.lamp_fixed` scritto+salvato da `Game.mark_lamp_fixed()`) così sopravvive al sonno e al riavvio. Un cambio interrotto resta uno `started` senza `ended` (l'abbandono è un dato). Nessun bonus meccanico, nessun conto alla rovescia, nessuna altra riparazione.

**File cambiati:**
- `world/interactables/lamp.gd` — NEW: `class_name Lamp extends Interactable`. Macchina a stati (`enum State{BROKEN,CHANGING,FIXED}`) con logica pura statica per il banco (`next_on_interact`/`is_interactive(state, owns_bulb)`/`prompt_for`/`starts_activity`, gemella di `Moka`); presenza fissa; interattività gated live sul possesso della lampadina; timer del cambio + lampeggio (`_process`) + ronzio sintetizzato da rotta, luce stabile+silenzio da riparata; emissione della coppia `wait_activity_*(&"lampada")`; persistenza via `Game.mark_lamp_fixed()`; nessun accesso ai punteggi.
- `world/interactables/lamp.tscn` — NEW: `StaticBody3D` presente, mesh segnaposto (base+stelo+lampadina), collisione mirabile dal piano a 0,9 m, `OmniLight3D`, `AudioStreamPlayer3D` posizionale, `Timer` one-shot.
- `world/rooms/kitchen.tscn` — istanziata la `Lamp` sul piano a `(2,6, 0,9, 2,2)` (a nord della moka); `Fill` abbassata da 0,9 a 0,35 perché il lampeggio/la stabilizzazione della lampada si veda davvero senza mai annerire la stanza; commenti di testa aggiornati (registri *fare* + *sistemare*; la lampada nasce presente).
- `core/player_profile.gd` — aggiunto `@export var lamp_fixed: bool = false` (SOLO DATI): modifica permanente del giocatore al suo mondo, come `owned_items`; default `false` = non riparata, nessun bump di `CURRENT_VERSION`.
- `autoloads/game.gd` — aggiunto `mark_lamp_fixed()`: set del flag + `save_profile`, mutazione+salvataggio atomici, unico punto che tocca `SaveManager` in gioco (come `spend_lire`).
- `tests/test_bench.gd` — nuovo `_check_lamp_repair` (transizioni pure, gating con/senza lampadina, prompt, punto d'emissione di `started`) ed esteso `_check_owned_items` col round-trip di `lamp_fixed` sul `.tres`.

**Review findings:** 3 patch applicate (tutte low: intervallo di tenuta iniziale del lampeggio, `set_process(false)` in CHANGING, parametro morto rimosso); 1 defer (medium: wiring runtime della telemetria + effetto di `mark_lamp_fixed` non coperti dal banco — come DW-15 della moka); 0 intent_gap, 0 bad_spec; 11 reject (rumore o autorizzati dall'intento, riverificati). Follow-up review consigliata: **false** — patch per severità (high 0, medium 0, low 3), punteggio `3×0 + 1×3 = 3 < 5` e nessun high.

**Verifica eseguita (con binario Godot presente nel repo — `Godot_v4.7.2-stable_win64.exe`):**
- `--headless --path . --import` → exit 0, nessun errore di parse/risorsa; la classe `Lamp` si registra.
- `--headless res://tests/test_bench.tscn` → exit 0, raggiunge `=== fine ===`, zero righe `<-- ATTESO`/`NON CARICABILE`. `_check_lamp_repair` stampa la tavola (BROKEN→CHANGING, gating vero solo BROKEN+lampadina, prompt «Cambia la lampadina», `started` da BROKEN); `lamp_fixed` fa round-trip sul `.tres` (true sopravvive, default false).
- `--headless --path .` (boot del gioco) → exit 0, nessun errore/warning/leak (il guard `_audio_is_audible()` evita il WARNING di teardown dell'AudioServer in headless).
- `rg "night/|phases/|terminal/" world/interactables/lamp.gd` → nessun risultato (isolamento delle cartelle intatto; le due occorrenze in commento contrastano con `main.gd`/`NightRun`, non vi dipendono).

**Owed all'operatore (`operator_actions`):** le AC percettive/interattive — vedere la lampada lampeggiare e sentirla ronzare, vedere l'illuminazione cambiare davvero, camminare il cambio a tempo, confermare la permanenza dopo sonno/riavvio, la raggiungibilità, e la coppia telemetria da un log — richiedono un umano su una build con display/audio: `--headless` non le può rendere né ascoltare, nemmeno col binario presente. Vedi `operator_actions` nel frontmatter.

**Rischi residui:**
- AC percettive/interattive non verificate qui (headless): owed all'operatore.
- Wiring runtime della coppia telemetria e effetto set+save di `mark_lamp_fixed` non esercitati dal banco (vedi `deferred`): la logica pura e il round-trip del campo sono coperti, il wiring che li trasforma in emissioni/persistenza no.
- Estetica/audio provvisori: mesh segnaposto e ronzio sintetizzato in codice (onda quadra grave in loop) — da sostituire col pack asset senza toccare la logica.
- La `Fill` a 0,35 e le energie del lampeggio sono valori di taratura: durante il cambio la luce va a 0 per qualche secondo — l'operatore conferma che la stanza non è troppo buia e ritara guardando.

## Operator Confirmation

Confirmed 2026-08-24: the external actions this story owed were carried out.

- Aprire una build con display e audio: alla prima notte, entrare in cucina e verificare che la lampada LAMPEGGIA in modo visibile (la luce della cucina sfarfalla, non un'icona) e RONZA in modo udibile — un fastidio percepibile — e che NON compare nessun prompt né invito a comprare la lampadina.
- Comprare la lampadina al terminale durante l'attesa, tornare in cucina e guardare la lampada: verificare che compare il prompt «Cambia la lampadina» e che cambiarla richiede di stare lì e dura QUALCHE SECONDO (non è istantaneo, non è un interruttore); durante il cambio la lampada è inerte.
- A cambio concluso: confermare che l'illuminazione della cucina CAMBIA DAVVERO — luce stabile al posto di quella intermittente, ronzio spento — e che non è troppo buia durante il cambio (la luce si spegne per qualche secondo, resta la `Fill`). Tarare `Fill`/energie guardando, se serve.
- Verificare la PERMANENZA: dopo aver cambiato la lampadina, andare a dormire e/o riavviare il gioco e confermare che la lampada è ancora stabile e silenziosa (il flag `lamp_fixed` sopravvive al save).
- Verificare la RAGGIUNGIBILITÀ: la lampada è mirabile e interagibile stando davanti al piano (occhio 1,65 m, piano 0,9 m), senza che il prompt compaia da lontano. Tarare la quota del volume di collisione guardando, se serve.
- Con un log/telemetria manuale, confermare che `Events.wait_activity_started(&"lampada")` parte all'inizio del cambio e `wait_activity_ended(&"lampada")` alla fine, senza feedback visibile, e che un cambio interrotto (quit a metà) resta uno `started` senza `ended` e la lampada torna rotta al riavvio.

_Appended by the bmad-loop orchestrator (`bmad-loop confirm`, #335): a human confirmed these external actions out of band, and the story was advanced from `awaiting-operator` to `done`._
