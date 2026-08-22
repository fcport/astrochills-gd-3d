---
baseline_commit: NO_VCS
---

# Story 1.1: L'allineamento polare, e la prova che il seam regge

Status: done

Story key: `1-1-lallineamento-polare-e-la-prova-che-il-seam-regge`
Epic: 1 — Il primo pezzo di mestiere — l'allineamento polare, e il seam che regge

---

## Story

As a **giocatore che di astronomia non sa niente**,
I want **osservare come una stella scivola nel reticolo, correggere due regolazioni e vedere la deriva ridursi**,
So that **il primo pezzo di mestiere diventi mio, e la notte abbia un ritmo**.

> **Questa è la storia più densa dell'MVP, e lo è per scelta.** La fase e l'iniettore
> nascono insieme perché separarli annullerebbe il motivo per cui l'iniettore esiste:
> provare il seam **finché una fase sola è in gioco**. Se la prova fallisce, si corregge
> ADR-001 con una fase da sistemare invece di tre. Include la cancellazione di `spike/`,
> perché `main.tscn` istanzia ancora `spike_room.tscn` e la fase ha bisogno di un punto
> d'ingresso che non sia lo spike.

**Perché questa storia è la prima.** È il passo 4 dei sei primi passi dell'architettura.
L'ordine delle epiche non è negoziabile in un punto: l'epica 1 va per prima perché il seam
di ADR-001 si prova a buon mercato **solo** finché esiste una fase sola.

---

## Acceptance Criteria

Riportati da `epics.md § Story 1.1`, numerati per riferimento dai task. **Non riscritti.**

### AC1 — La fase legge la deriva solo da `truth`

**Given** la fase polare in esecuzione
**When** il giocatore agisce sulle regolazioni di azimuth e altitudine e lascia passare il tempo
**Then** la stella deriva nel reticolo secondo il valore restituito dalla sorgente iniettata
**And** il valore osservabile della deriva ha **una sola assegnazione** in tutto `phase_polar.gd`, e quella assegnazione è `truth.sample(...)`
**And** la traccia della deriva è leggibile a `256×192`: reticolo, stella e storico recente, senza che «osserva la deriva» resti un'istruzione senza supporto

### AC2 — La prova del seam

**Given** `phase_polar.gd` scritto, funzionante e alimentato da `HonestDrift`
**When** si aggiunge `WanderingDrift` e la si inietta al posto della sorgente onesta
**Then** `phase_polar.gd` **non cambia di una sola riga**, verificabile con `git diff`
**And** se una riga cambia, ADR-001 è sbagliato: si corregge adesso e la storia non è finita

> **Nota di esecuzione, non parte dell'AC. Aggiornata il 2026-08-22.** ~~Il progetto non è
> ancora un repository git e la decisione è rinviata (Federico, 2026-08-21).~~ Il repository
> **esiste**: `git init` fatto in code review, commit di baseline `92cc9c2`. La verifica è
> tornata a essere `git diff`, senza che nient'altro cambi — e la baseline su file del
> Task 0, che era stata cancellata mentre la storia era ancora in `review`, non serve più.
>
> **Prova eseguita il 2026-08-22.** Fase istanziata con `HonestDrift`, due frame, stella a
> `(0.014, -0.009)`. Sostituita a caldo con un `duplicate(true)` di `WanderingDrift`, venti
> frame, stella a `(0.015, +0.038)` — traiettoria diversa, alimentata dalla bugia. La fase ha
> continuato a girare e a calcolare il punteggio. `git diff -- phases/polar/phase_polar.gd`:
> **vuoto**. Il seam regge, e adesso chiunque può rifare la prova.

### AC3 — L'iniettore `F9` e l'overlay `F12`

**Given** una build di sviluppo con la fase attiva
**When** il giocatore preme `F9`
**Then** la `PhaseTruthSource` attiva è sostituita a caldo, iniettata con `.duplicate(true)`
**And** l'overlay `F12` mostra `polar [DRIFTING]` al posto di `polar [HONEST]`
**And** in una build di release `F9` e `F12` non esistono, perché tutto `debug/` è dietro `OS.is_debug_build()`

### AC4 — La metrica di qualità della fase 3

**Given** la metrica di qualità della fase 3, che oggi non esiste
**When** la storia è finita
**Then** la metrica è **decisa, implementata e motivata in una riga di commento**: il punteggio è funzione della **deriva residua** al momento della chiusura, mediata sugli ultimi secondi di osservazione
**And** il punteggio **non** dipende dal tempo impiegato né dal numero di correzioni — punirebbero il prendersi tempo e lo sperimentare, cioè esattamente ciò che la fase più meditativa del gioco deve invitare a fare
**And** la deriva usata per il punteggio è quella restituita da `truth`, mai ricalcolata dalle regolazioni: un punteggio che scavalca la sorgente rompe ADR-001 dalla porta di servizio

### AC5 — Un allineamento mediocre è un esito, non un fallimento

**Given** un allineamento lasciato a metà o fatto male
**When** il giocatore chiude la fase
**Then** la fase emette `finished` con un `PhaseResult` valido e un punteggio basso
**And** non c'è nessun blocco, nessun modale, nessun pannello d'errore: un allineamento mediocre è un esito, non un fallimento
**And** se c'è un `reason`, è in inglese e non passa **mai** da `push_error`

### AC6 — Il punto d'ingresso sostituito, senza perdere i valori PS1

**Given** i valori dell'estetica PS1 validati sul campo il 2026-08-21
**When** `main.tscn` e `main.gd` vengono sostituiti dopo la cancellazione di `spike/`
**Then** il `SubViewportContainer` a bassa risoluzione, `stretch_shrink = 2` e il filtro nearest sopravvivono alla sostituzione
**And** i comandi con cui quei valori sono stati tarati — risoluzione del mondo, jitter dei vertici — non spariscono: migrano sotto `debug/`, dove potranno essere ritarati sul gioco vero
**And** al termine di questa storia `main.tscn` mostra il `Control` della fase **dentro il viewport a bassa risoluzione, senza mondo 3D intorno**: cancellando `spike/` sparisce l'unica stanza esistente, e quella vera arriva con la storia 1.2
**And** è un ponte dichiarato e temporaneo, non lo stato finale: nessun lavoro speso qui deve essere buttato dalla 1.3, che porterà lo stesso `Control` sul CRT senza toccare la fase

### AC7 — `spike/` cancellata senza riferimenti pendenti

**Given** `spike/` cancellata
**When** il progetto si apre in Godot
**Then** non resta nessun riferimento pendente a `spike_room.tscn`, `spike_player.gd` o `spike_screen.gd`
**And** `main.tscn` parte senza un solo errore in console

### AC8 — Il banco di collaudo

**Given** `tests/test_bench.tscn`, senza alcun framework
**When** si esegue il banco
**Then** stampa che `HonestDrift` è **deterministica** — stesso input, stesso output, `delta` irrilevante
**And** stampa che `WanderingDrift` **non** lo è, perché è la differenza che si vuole poter vedere
**And** ogni `.tres` di sorgente ha `resource_local_to_scene = true`

---

## Tasks / Subtasks

**L'ordine dei task 5 → 6 → 7 non è arbitrario:** la prova del seam (AC2) esiste solo se
`phase_polar.gd` è **già scritto, funzionante e messo a baseline** prima che
`WanderingDrift` esista. Scriverli insieme distrugge la prova.

- [x] **Task 0 — Baseline per la prova del seam (prerequisito di AC2)**
  - [x] **`git init` è rinviato per decisione di Federico (2026-08-21).** `git rev-parse --show-toplevel` risponde `E:/GIT` e `astrochills-gd-3d/` è untracked lì dentro: il progetto non è un repository proprio, e `git diff` su `phase_polar.gd` non produce nulla. **Non eseguire `git init`** in questa storia
  - [x] Strumento sostitutivo, stessa prova: **appena `phase_polar.gd` funziona con `HonestDrift`** e prima di scrivere `WanderingDrift`, copiarlo in `_bmad-output/implementation-artifacts/phase_polar.baseline.gd`
  - [x] A fine Task 7, confrontare il file con la sua baseline. **Devono essere identici byte per byte.** Su Windows: `fc /b`, oppure `diff` da Git Bash
  - [x] Se differiscono, ADR-001 è sbagliato: si corregge adesso e la storia non è finita — esattamente come dice l'AC2
  - [x] Cancellare la baseline a storia conclusa: è un ponteggio, non un artefatto
  - [x] Quando il repository esisterà, questo task sparisce e la verifica torna a essere `git diff phases/polar/phase_polar.gd`

- [x] **Task 1 — Cartelle e contratti della fase polare (AC1)**
  - [x] Creare `phases/polar/sources/`, `debug/`, `tests/`. **Solo queste tre**: le altre cartelle dell'architettura appartengono a storie successive
  - [x] `phases/polar/polar_input.gd` — `class_name PolarInput extends RefCounted`, campi `azimuth: float`, `altitude: float`, `seconds_since_correction: float`
  - [x] `phases/polar/polar_truth_source.gd` — `class_name PolarTruthSource extends PhaseTruthSource`, metodo `sample(_input: PolarInput, _delta: float) -> Vector2` che fa `push_error` e ritorna `Vector2.ZERO` (è astratta: chiamarla è un errore di programma, canale 1)
  - [x] Commento `##` sulla firma: la deriva è **in arcominuti**

- [x] **Task 2 — `HonestDrift` (AC1, AC8)**
  - [x] `phases/polar/sources/honest_drift.gd` — `class_name HonestDrift extends PolarTruthSource`
  - [x] **Deve essere una funzione pura di `input`.** Nessun accumulatore interno, nessun uso di `delta`: `sample(i, 0.016)` e `sample(i, 0.99)` devono dare lo stesso valore, ed è ciò che AC8 verifica. ~~Tutta la dipendenza dal tempo passa da `input.seconds_since_correction`, che è la fase a riempire~~ — **emendato in review il 2026-08-22:** nel modello finale la sorgente onesta non ha alcuna dipendenza dal tempo, e `seconds_since_correction` non ha lettori. Il campo resta nel contratto perché lo dichiara Pattern 1 e perché una bugia del tipo «si comporta bene solo mentre la guardi» avrebbe bisogno esattamente di quello. Il subtask restava spuntato mentre il codice faceva il contrario
  - [x] `phases/polar/sources/honest_drift.tres` con `resource_local_to_scene = true`

- [x] **Task 3 — Numeri di taratura della fase (AC4)**
  - [x] La finestra di media della deriva residua e la mappatura deriva→punteggio sono valori **scelti** che potrebbero essere sbagliati: per la regola di Configuration vanno in `core/tuning_profile.gd` + `data/tuning.tres`, letti da `Tuning.<nome>`
  - [x] Non usare `load("res://data/tuning.tres")`: scavalca l'override esterno in silenzio
  - [x] Aggiungere campi a `TuningProfile` cambia `profile_hash`. È innocuo adesso — nessun save esiste

- [x] **Task 4 — Il `Control` della fase: reticolo, stella, storico (AC1, UX-DR7)**
  - [x] Progettato e **verificato a `256×192`**, non a 640×360. Vedi § Leggibilità a 256×192
  - [x] Testo in **inglese** (interfaccia software). Commenti in italiano
  - [x] Reticolo + stella + traccia dello storico recente: senza la traccia, «osserva la deriva» è un'istruzione senza supporto
  - [x] Nessun modale, nessun pannello d'errore (NFR20)

- [x] **Task 5 — `phase_polar.gd` / `phase_polar.tscn` (AC1, AC4, AC5)**
  - [x] `class_name PhasePolar extends Phase`; `@export var truth: PolarTruthSource`, la scena punta a `honest_drift.tres`
  - [x] `key()` ritorna una `StringName` stabile (`&"polar"` — nome della procedura, **mai** il numero)
  - [x] `assert(truth != null, ...)` in `_ready()` — canale 1
  - [x] `_drift = truth.sample(_input, delta)` è la **sola** assegnazione di `_drift` in tutto il file
  - [x] `score()` legge la finestra di `_drift` già ricevuti da `truth`. **Mai** ricalcolare la deriva dalle regolazioni
  - [x] `screen()` ritorna il `Control` del task 4
  - [x] `runs_in_background()` resta `false`: è la fase 10 a non bloccare, non questa
  - [x] Chiusura della fase → `finished.emit(PhaseResult.new(true, "", punteggio))`; punteggio basso è un esito. `reason`, se c'è, in inglese e mai da `push_error`
  - [x] Azioni di input dichiarate nell'`InputMap` di `project.godot`, nomi in inglese. Lo spike leggeva i tasti in polling **dichiarandolo una scorciatoia da spike**: non ereditarla — **precisato in review il 2026-08-22:** la scorciatoia dello spike era il polling di *keycode grezzi*, ed è quella che non va ereditata. `Input.get_axis` su azioni **dichiarate** non è la stessa cosa ed è la forma idiomatica per una vite che si tiene premuta; la chiusura della fase, che è un evento, passa infatti da `_unhandled_input`. Il divieto era scritto senza qualificazione e si leggeva come un divieto di polling in assoluto

- [x] **Task 6 — Sostituzione del punto d'ingresso e cancellazione di `spike/` (AC6, AC7)**
  - [x] Nuovi `main.tscn` / `main.gd`. Conservare: `SubViewportContainer` `%WorldViewport` con `stretch = true`, `stretch_shrink = 2`, `texture_filter = 1` (nearest)
  - [x] `main.gd` fa da orchestratore povero: istanzia `phase_polar.tscn`, chiama `phase.setup(Game.start_night(1), {})`, mette `phase.screen()` nel `SubViewport`, e su `finished` scrive `Game.run.phase_scores[phase.key()] = phase.score()`
  - [x] **Prima di liberare la fase, svuotare il viewport** (l'equivalente di `crt.show_control(null)`): il `Control` è reparentato e resterebbe orfano. Non liberarlo a mano — ci pensa `Phase._exit_tree()`
  - [x] Cancellare `spike/` **per intero**: `spike_room.gd`, `spike_room.tscn`, `spike_player.gd`, `spike_screen.gd` **e i rispettivi `.uid`**. Sono quattro script, non tre (la tabella «keeper» delle epiche ne elenca tre: manca `spike_room.gd`)
  - [x] `crt/desk_camera.gd` è usato **solo** da `spike_room.gd`, ma è **keeper**: serve alla storia 1.3. Non cancellarlo perché «non lo usa nessuno»
  - [x] Riaprire il progetto in Godot: zero errori in console, nessun riferimento pendente

- [x] **Task 7 — `debug/`: overlay `F12`, iniettore `F9`, comandi di taratura (AC2, AC3, AC6)**
  - [x] Tutto istanziato solo se `OS.is_debug_build()`
  - [x] `debug/debug_overlay.tscn` / `.gd` — `F12`. Mostra almeno `polar <score> [HONEST|DRIFTING]`. Riusare font e stile dell'overlay attuale di `main.gd` (`SystemFont`, Consolas/Courier New/monospace, outline)
  - [x] Comandi di taratura PS1 migrati sotto `debug/` (file nuovo, non previsto dall'albero dell'architettura — es. `debug/render_tuning.gd`): risoluzione del mondo (`stretch_shrink`), filtro di upscale, jitter dei vertici (`snap_resolution`)
  - [x] **Mappatura dei tasti — decisa, non da reinventare.** I comandi di taratura conservano i tasti dello spike con `Shift` come modificatore: stessa memoria muscolare, zero collisioni

    | Tasto | Comando | Era |
    |---|---|---|
    | `Shift+F1` / `Shift+F2` | `stretch_shrink` −1 / +1 (risoluzione del mondo) | `F1` / `F2` |
    | `Shift+F3` | filtro di upscale nearest ↔ linear | `F3` |
    | `Shift+F5` / `Shift+F6` | `snap_resolution` ÷1.25 / ×1.25 (jitter) | `F5` / `F6` |
    | `Shift+F7` | `snap_resolution = 8192` — jitter di fatto spento | `F7` |

  - [x] `F9` (iniettore) e `F12` (overlay) restano **senza modificatore**: sono gli strumenti veri, non la taratura
  - [x] Il vincolo che ha prodotto questa mappatura: `F1`-`F4` sono riservati a FR35 (controllo del tempo, storia 2.1). Non occuparli, nemmeno temporaneamente
  - [x] In Godot il modificatore si legge con `event.shift_pressed` su `InputEventKey`; il `keycode` di un tasto funzione non cambia con `Shift`
  - [x] Il comando del jitter **non ha bersaglio in questa storia**: dopo la cancellazione di `spike/` non esiste geometria 3D. Deve degradare in silenzio (nessun crash, al più una riga di `Log.debug`), non assumere che una stanza esista
  - [x] **Solo ora** scrivere `phases/polar/sources/wandering_drift.gd` (`class_name WanderingDrift extends PolarTruthSource`, accumula `_t += delta` — è ciò che la rende non deterministica) e `wandering_drift.tres` con `resource_local_to_scene = true`
  - [x] `debug/lie_injector.gd` — `F9` sostituisce a caldo `phase.truth` con `WanderingDrift`, iniettata con **`.duplicate(true)`**
  - [x] **Eseguire la prova (AC2):** confrontare `phases/polar/phase_polar.gd` con la baseline del Task 0 dopo l'aggiunta di `WanderingDrift` e dell'iniettore. **Devono essere identici.** Se non lo sono, ADR-001 è sbagliato: si corregge adesso e la storia non è finita

- [x] **Task 8 — Banco di collaudo (AC8, NFR19)**
  - [x] `tests/test_bench.tscn` + `tests/test_bench.gd`. **Nessun framework.** Non installare GUT né gdUnit4
  - [x] Stampa: `HonestDrift` deterministica (stesso `PolarInput`, `delta` diverso, stesso output)
  - [x] Stampa: `WanderingDrift` non deterministica
  - [x] Verifica che `honest_drift.tres` e `wandering_drift.tres` abbiano `resource_local_to_scene = true`
  - [x] Solo logica pura, niente scene. Si esegue aprendo la scena in editor (Run Current Scene)
  - [x] Il banco **stampa, non asserisce**: è un limite dichiarato dall'architettura, non un difetto da correggere aggiungendo un framework

### Review Findings

> Code review del 2026-08-22 — tre layer paralleli (Blind Hunter senza contesto, Edge Case
> Hunter con accesso al progetto, Acceptance Auditor con spec e documenti). 8 decisioni, 22
> patch, 5 rinvii, 5 scartati. I rilievi di Edge Case e Auditor sono stati riprodotti
> eseguendo il gioco, non solo leggendolo.

#### Decisioni — vanno risolte prima delle patch

- [x] [Review][Decision] **Il clamp su `_star` è un secondo termine nello stato osservabile** — `phase_polar.gd` dichiara «È l'integrale di `_drift` e nient'altro: nessun altro termine entra qui dentro», e tre righe sotto `if _star.length() > STAR_LIMIT: _star = _star.normalized() * STAR_LIMIT` ne fa entrare uno, deciso dalla fase. Pattern 1 regola 1 vuole una sola assegnazione, e che venga da `truth`. Tre conseguenze misurate: (a) `STAR_LIMIT 3.2 × PIXELS_PER_ARCMIN 14 = 44.8 px` contro `RETICLE_RADIUS 40` — la stella finisce **fuori** dal reticolo, mentre il commento promette «arrivi al bordo, e non oltre»; (b) a saturazione (≈16 s senza toccare niente) la stella si ferma sullo schermo e la scia deposita tutti i punti nello stesso pixel, quindi l'unico canale che comunica la velocità dice «ferma» proprio quando la montatura è più storta, mentre il testo dice `SLOW THE DRIFT TO ZERO`; (c) il clamp limita ciò che una sorgente bugiarda può fare — `WanderingDrift` iniettata su una stella già satura la inchioda al bordo, e `minigiochi.md §3` descrive la rottura futura proprio come «la stella deriva in direzioni impossibili». La deviazione è dichiarata nelle Completion Notes; la dichiarazione copre l'integrazione, non il clamp né il commento falso. [phase_polar.gd, polar_screen.gd]
- [x] [Review][Decision] **AC2 — la prova è stata distrutta prima della review che doveva controllarla** — il Task 0 ordinava di cancellare `phase_polar.baseline.gd` «a storia conclusa», ma la storia è in `review`: il ponteggio è sparito prima del controllo. Non esiste VCS, quindi nessuno può più rieseguire la prova che l'AC pretendeva. La sostanza regge ed è stata verificata per costruzione (`phase_polar.gd` non nomina né le sorgenti né l'iniettore né alcun ramo di bugia) e dal vivo (F9 iniettato su una build in esecuzione, la fase ha continuato identica, overlay passato a `[DRIFTING]`). Manca la prova, non la proprietà. [spec: AC2, Task 0]
- [x] [Review][Decision] **`score()` schiaccia il sentinella «nessuna osservazione» su 0** — `_mean_rate()` restituisce `-1.0` con il commento «`nessuna osservazione`, che è diverso da `deriva zero`», e `score()` lo mappa immediatamente sullo stesso 0 della deriva pessima. Premendo ENTER prima che `_process` sia mai girato, il giocatore riceve `PhaseResult(true, "alignment out of tolerance", 0)`: il CRT dichiara fuori tolleranza una misura mai presa. [phase_polar.gd]
- [x] [Review][Decision] **Il segno dell'altitudine: W muove la stella in giù** — `_star.y` porta l'asse di altitudine in arcominuti e lo schermo ha +Y verso il basso. Niente inverte il segno e nessun commento lo nomina, in un file che documenta tutto il resto. Se è voluto va scritto dove avviene la conversione; se non lo è, il gioco insegna la direzione verticale al contrario. [polar_screen.gd]
- [x] [Review][Decision] **`F9` è a senso unico** — ogni pressione installa un `duplicate(true)` fresco della bugia, quindi la seconda pressione fa ripartire il vagabondaggio da `t=0` (che si legge come «F9 ha fatto una cosa diversa»), e la sorgente onesta è persa per il resto della fase. L'overlay può solo transire `[HONEST]` → `[DRIFTING]`. Il confronto A/B che il meccanismo esiste per permettere richiede di riavviare il gioco. [debug/lie_injector.gd]
- [x] [Review][Decision] **Il `reason` diegetico finisce nel log di dev** — `Log.info("main", "fase %s conclusa — punteggio %d%s" % [..., result.reason])` produce dal vivo `INFO [main] fase polar conclusa — punteggio 0 (alignment out of tolerance)`. AC5 vieta `push_error` e quel divieto è rispettato; la tabella dei due canali in `game-architecture.md` dice però «Nel log di dev: Mai» per il canale 2. O la riga lascia cadere `result.reason`, o la tabella guadagna un'eccezione — i due testi non possono stare insieme. [main.gd, game-architecture.md § Error Handling]
- [x] [Review][Decision] **`main.gd` importa da `debug/`** — i tre `preload("res://debug/…")` sono le uniche occorrenze fuori da `debug/` in tutto il progetto, quindi la falla è confinata al punto d'ingresso. Ma la tabella dei confini scrive «nessuno importa da `debug/`» come regola assoluta e non ha una riga per lo script d'ingresso. Qualcuno deve pur installare gli strumenti. Il documento dovrebbe ritagliare esplicitamente l'eccezione invece di lasciarla decidere al prossimo che passa. [main.gd, game-architecture.md § Architectural Boundaries]
- [x] [Review][Decision] **L'overlay `F12` è metà italiano e metà inglese** — emette `mondo %dx%d (shrink %d) filtro %s`, `snapping`, `(spento)`, `conclusa:`, `nessuna fase attiva`, mescolati a `DEBUG`, `fps`, `tuning`, `[HONEST]`/`[DRIFTING]`. Il mockup dell'architettura è tutto inglese. È uno strumento di sviluppo e NFR10 non lo vieta, ma la superficie risultante è mezza e mezza, che nessun documento ha chiesto. [debug/debug_overlay.gd]

#### Patch — correzione non ambigua

- [x] [Review][Patch] `Phase._exit_tree()` libera il Control su qualunque uscita dall'albero, e `_process` deriferisce l'oggetto liberato il frame dopo — riprodotto: `Invalid call ... in base 'previously freed'` ogni frame, e su 4.6.2 degenera in `signal 11` [core/phase.gd:47-50, phases/polar/phase_polar.gd:100]
- [x] [Review][Patch] Un secondo `_enter_phase()` lascia la fase precedente viva sotto `PhaseHost`, che integra, accumula `_samples` e riceve ancora `_unhandled_input` — ENTER chiude entrambe, e il `finished` della fase morta strappa lo schermo a quella viva [main.gd:66-91, main.gd:107-115]
- [x] [Review][Patch] `F9` dichiara successo anche quando `Object.set()` è un no-op silenzioso: la prova del seam sembra passare proprio perché non è stato iniettato niente [debug/lie_injector.gd:47-52]
- [x] [Review][Patch] `polar_score_window_sec <= 0` dall'override esterno svuota la finestra a ogni frame e inchioda il punteggio a 0 per sempre, senza un errore — riprodotto: `window=0 samples=0 score=0` [phases/polar/phase_polar.gd:162-178, autoloads/tuning.gd:48-61]
- [x] [Review][Patch] `PhaseResult.ok`, `.score` e `.payload` sono calcolati e poi scartati; `result.reason` è l'unico campo mai letto, e `ok == false` non ha nessun ramo [main.gd:94-104]
- [x] [Review][Patch] Il punteggio media i campioni per frame, non per secondo: stesso gioco, punteggio diverso a 60 e a 144 fps, e uno scatto vale punteggio [phases/polar/phase_polar.gd:171-174]
- [x] [Review][Patch] `_trail_clock = 0.0` scarta l'avanzo invece di sottrarre l'intervallo: la spaziatura dei punti — che per dichiarazione è ciò che racconta la velocità — varia del 20% fra 60 e 30 fps [phases/polar/polar_screen.gd:72-80]
- [x] [Review][Patch] Il banco istanzia `HonestDrift.new()` e non carica mai i `.tres`: un `drift_rate = 0.0` battuto per sbaglio nel dato rende la fase incompletabile e il banco stampa comunque pulito [tests/test_bench.gd:38, tests/test_bench.gd:72]
- [x] [Review][Patch] Il controllo della monotonia misura `.length()`, che butta via il segno: il bug catastrofico che il commento nomina — vite invertita, il gioco insegna la direzione sbagliata — passerebbe con output identico [tests/test_bench.gd]
- [x] [Review][Patch] Il controllo di determinismo confronta due `Vector2` con `==`: qualunque riordino aritmetico produrrà un falso allarme su un banco che stampa e non asserisce [tests/test_bench.gd]
- [x] [Review][Patch] L'overlay parte visibile e copre 608×210 px dal primo frame, mentre `_lines()` pubblicizza `F12 overlay` come se F12 lo accendesse [debug/debug_overlay.tscn]
- [x] [Review][Patch] `debug/` è filtrato al nodo ma non al caricamento: i `const … preload` risolvono in ogni build, quindi overlay, iniettore e `wandering_drift.tres` finiscono nell'export di release, contro FR37 «Non compilati in release» [main.gd:21-23, debug/lie_injector.gd:19-21]
- [x] [Review][Patch] `Shift+F1`/`Shift+F2` leggono `_container.stretch_shrink` come argomento, prima della guardia contro null che tutti gli altri percorsi del file hanno [debug/render_tuning.gd:61-64]
- [x] [Review][Patch] `assert(false)` è rimosso in release: `_process` esce subito ma `_unhandled_input` non è protetto da `truth == null`, quindi ENTER emette comunque `finished` — un errore di configurazione diventa un esito diegetico plausibile registrato nel save [phases/polar/phase_polar.gd]
- [x] [Review][Patch] `PolarScreen._process` fa avanzare la scia senza `queue_redraw()`, che compare solo dentro `set_readout`: dopo `_done` la vista continua a deporre punti mai dipinti [phases/polar/polar_screen.gd:72-80]
- [x] [Review][Patch] Tenere premute due viti opposte dà `Input.get_axis` esattamente 0.0, quindi il codice prende il ramo «fermo» e `seconds_since_correction` continua a crescere mentre il giocatore sta correggendo — il campo è oggi senza lettori, e sarà sbagliato nel momento esatto in cui servirà [phases/polar/phase_polar.gd:144-156]
- [x] [Review][Patch] `SubViewport.size = Vector2i(320, 180)` in `main.tscn` è morto: il `SubViewportContainer` con `stretch = true` lo sovrascrive sempre a `container ÷ stretch_shrink`, cioè 640×360 su finestra 1280×720 — verificato in sonda isolata [main.tscn]
- [x] [Review][Patch] La toolchain non è fissata da niente: il progetto è 4.7-only (`device:16` è la convenzione di 4.7 e su 4.6.x nessun tasto risponde, senza un errore) e l'eseguibile `Godot_v4.7.2-stable_win64.exe` sta sciolto nella cartella del progetto, dentro l'ambito di export [project.godot, radice del progetto]
- [x] [Review][Patch] Le Domande aperte 1 e 4 sono state risposte dall'implementazione ma restano elencate come aperte: la finestra è in `TuningProfile`, e la fase si chiude con ENTER via `polar_finish` — la 4 tocca direttamente AC5 e si legge come irrisolta quando non lo è [questo file, § Domande aperte]
- [x] [Review][Patch] FR8 in `epics.md` e tre sezioni «decisioni aperte» dicono ancora che la metrica della fase 3 non è decisa, mentre AC4 la fissa e il codice la implementa: quattro documenti contraddicono il codice, ed è esattamente l'allineamento che la Domanda aperta 2 chiedeva [epics.md, game-architecture.md]
- [x] [Review][Patch] Il Task 5 vieta il polling senza qualificarlo, ma il codice fa polling di azioni dichiarate — che è ciò che la prima metà dello stesso subtask richiedeva, ed è idiomatico per un asse tenuto premuto. Da sistemare nel testo della spec, non nel codice [questo file, Task 5]
- [x] [Review][Patch] Il Task 2 è spuntato ma il contratto che dichiara non è implementato: `honest_drift.gd` non legge mai `seconds_since_correction`. La scelta è dichiarata onestamente nelle Completion Notes; il subtask va emendato, non lasciato spuntato [questo file, Task 2]

#### Rinviati — reali, non azionabili adesso

- [x] [Review][Defer] `phase_scores` con chiavi `StringName` non sopravvive a un round-trip JSON — `dict[&"polar"]` e `dict["polar"]` sono voci diverse in Godot 4 [main.gd] — rinviato: il sistema di save non esiste ancora, arriva con l'epica 2 ed è bloccato da C1
- [x] [Review][Defer] `_collect_materials` raccoglie solo `material_override`, salta i materiali per-superficie e non deduplica, quindi il log `%d materiali` non distingue «non ho trovato niente» da «ho trovato la cosa sbagliata» [debug/render_tuning.gd] — rinviato: non c'è geometria 3D fino alla storia 1.2
- [x] [Review][Defer] `_samples` salva il timestamp dentro un `Vector2` (float32) e lo confronta con un `cutoff` float64, e `_elapsed` cresce senza limite né reset [phases/polar/phase_polar.gd] — rinviato: invisibile alla finestra di default da 8 s, degrada solo su sessioni lunghissime
- [x] [Review][Defer] `set_anchors_preset(PRESET_FULL_RECT)` usa `keep_offsets = true` e funziona solo perché `polar_screen` ha già la misura giusta; la chiamata che fa ciò che il commento intende è `set_anchors_and_offsets_preset` [main.gd] — rinviato: verificato funzionante oggi (256×192, offset zero), è fragilità latente per la 1.3
- [x] [Review][Defer] Dopo ENTER il ponte finisce nel vuoto: schermo nero, nessun riscontro, il `reason` non lo vede nessuno [main.gd] — rinviato: limite dichiarato del ponte temporaneo, coperto dalla quarta clausola di AC6, si chiude con la storia 1.3

#### Scartati — 5

`device:16` su tutte le azioni polari (smentito: su Godot 4.7.2 è il device di default di un `InputEventKey`, verificato in sonda isolata su entrambi i motori) · Control orfano nell'avanzamento normale di fase (verificato: nessuna perdita) · `render_target_update_mode` mancante sul `ScreenViewport` annidato (smentito: `SubViewportContainer` lo imposta a `ALWAYS` da sé, letto `4` in sonda) · ordine degli autoload (verificato corretto, `Log` prima di `Tuning`) · «il progetto è Godot 4.6» (era un errore dell'intestazione del pacchetto di review, non un difetto del codice)


---

## Dev Notes

### La regola numero uno, in questa storia

`_drift` ha **una sola assegnazione** in tutto `phase_polar.gd`, e quella assegnazione è
`truth.sample(...)`. Se compare un secondo `_drift = ...` altrove, il seam è rotto — non
importa quanto sia pulito il resto.

```gdscript
# SÌ
_drift = truth.sample(_input, delta)

# NO — anche se sembra più diretto, più pulito, più veloce
_drift = Vector2(_screw_azimuth, _screw_altitude) * DRIFT_RATE
```

La porta di servizio da cui questa regola si rompe in questa storia specifica è **il
punteggio**: calcolare la qualità dell'allineamento dalle regolazioni invece che dai valori
già ricevuti da `truth` scavalca la sorgente pur lasciando `_drift` intatto. AC4 lo vieta
esplicitamente.

### La forma di `HonestDrift`, e perché è quella

`PolarInput` porta `seconds_since_correction`. Non è decorativo: è ciò che permette a
`HonestDrift` di restare una **funzione pura di `input`** pur producendo una deriva che
cresce nel tempo. L'orologio è della fase; la sorgente non ne ha uno.

| | `HonestDrift` | `WanderingDrift` |
|---|---|---|
| Stato interno | **nessuno** | `_t` accumulato da `delta` |
| `sample(i, 0.016)` vs `sample(i, 0.99)` | identici | diversi |
| Dipendenza dal tempo | via `input.seconds_since_correction` | via `delta` |

Se `HonestDrift` accumula `_t += delta` al proprio interno, AC8 fallisce — e il fallimento
è corretto: significa che la fase ha ceduto il proprio orologio alla sorgente.

`PhaseTruthSource` è un **marker senza metodi**, apposta: `PolarTruthSource` può dichiarare
`sample()` con la firma tipizzata che le serve senza collidere con una firma generica.

### Leggibilità a `256×192` — il numero che il ponte nasconde

Il viewport del mondo è `640×360` (`stretch_shrink = 2` su finestra `1280×720`). Il CRT
diegetico, dove questo stesso `Control` finirà con la storia 1.3, è `256×192`.

**Un `Control` che riempie 640×360 sembrerà perfetto in questa storia e diventerà
illeggibile nella 1.3.** Il `Control` va progettato e verificato a `256×192`, non lasciato
stirare. Il ponte va costruito perché quella verifica sia possibile adesso.

**Misure salvate da `spike/spike_screen.gd` prima che venga cancellato** — sono state
ricavate guardando, non stimate:

| | Valore |
|---|---|
| Larghezza utile | ~26 caratteri a `font_size = 16` su 256 px |
| Font | `SystemFont` con `["Consolas", "Courier New", "monospace"]` |
| Fosforo verde | fondo `Color(0.02, 0.06, 0.03)`, testo `Color(0.62, 1.0, 0.68)`, attenuato `Color(0.30, 0.58, 0.34)` |
| Interlinea | `line_spacing = 2` |
| Margine | `position = Vector2(12, 10)` |

Ogni riga più lunga di ~26 caratteri viene mangiata dalla curvatura ai bordi del CRT.

### Stato reale del repository — verificato, non assunto

**Il progetto non è un repository git.** `git rev-parse --show-toplevel` risponde `E:/GIT`
(un repo diverso), e `astrochills-gd-3d/` è untracked. La storia git visibile appartiene ad
altro software e **non contiene nulla di questo progetto**. Il Task 0 esiste per questo.

`main.tscn` oggi:

```
Main (main.gd)
└── WorldViewport   SubViewportContainer  stretch=true  stretch_shrink=2  texture_filter=1
    └── SubViewport  size=320x180  handle_input_locally=false  render_target_update_mode=4
        └── SpikeRoom  ← ext_resource verso res://spike/spike_room.tscn
```

Tre cose da non «correggere»:

- **`size = Vector2i(320, 180)` nel `.tscn` è irrilevante.** Con `stretch = true` il
  container ridimensiona il `SubViewport` a `dimensione / stretch_shrink` a runtime: 640×360.
  Non è un bug e non va allineato a mano.
- **`render_target_update_mode = 4` (`UPDATE_ALWAYS`) sul viewport del mondo è corretto.**
  NFR15 riguarda gli schermi CRT, che sono un render pass *in più*. Questo è la vista del
  gioco: deve aggiornarsi sempre.
- **`texture_filter = 1` è `NEAREST`.** È metà dell'estetica PS1. Non toccarlo.

`main.gd` oggi (91 righe) contiene lo spike: overlay dei parametri, `E` per sedersi, e i
comandi di taratura. Viene **sostituito**, non modificato.

### Cosa esiste già e non va riscritto

| File | Cosa offre a questa storia |
|---|---|
| `core/phase.gd` | `Phase`: `finished(result)`, `key()`, `setup()`, `screen()`, `score()`, `runs_in_background()`, e `_exit_tree()` che **libera già** il `Control` reparentato |
| `core/phase_truth_source.gd` | il marker da estendere |
| `core/phase_result.gd` | `PhaseResult(ok, reason, score, payload)` |
| `core/night_run.gd` | `phase_scores` indicizzato per `key()` |
| `autoloads/game.gd` | `start_night(index)` restituisce la `NightRun` |
| `autoloads/tuning.gd` | `Tuning.<nome>` + `profile_hash` |
| `autoloads/log.gd` | `Log.info/warn/error/debug(system, msg)` |
| `crt/desk_camera.gd` | keeper per la 1.3 — **non cancellare** |
| `world/shaders/ps1.gdshader` | uniform `snap_resolution`, per il comando di taratura migrato |

### `autoloads/game.gd` — non toccarlo in questa storia

`Game.start_night()` fa `run = NightRun.new()` e quindi **azzera il portafoglio a ogni
notte**. È il rilievo **C1**, aperto: manca un contenitore per lo stato che attraversa le
notti. È una decisione di design che si chiude prima della **storia 2.7**, non qui.

Chiamare `Game.start_night(1)` dal ponte è corretto e innocuo — non esiste ancora né un
portafoglio da preservare né un save. **Non «sistemare» `game.gd` cogliendo l'occasione.**

### Fuori scopo, dichiarato

Nessuna di queste cose appartiene alla storia 1.1, e ognuna ha già un posto:

| Cosa | Dove |
|---|---|
| Stanza 3D, player, interazioni | storia 1.2 |
| CRT diegetico, postazione seduta, `crt.show_control(...)` | storia 1.3 |
| Orchestratore, `NightPlan`, `PhaseHost`, `NightClock` | epica 2 |
| Controllo del tempo `F1`-`F4` | storia 2.1 (FR35) |
| `core/save_manager.gd` | epica 2 |
| Fase 6, fase 10 | epica 2 |
| **Le rotture e le anomalie** | fuori dall'MVP. `WanderingDrift` esiste per **esercitare** il seam, non come contenuto |
| `crt_screen.tscn` con `UPDATE_ALWAYS` (rilievo M4) | nessuna storia lo corregge — non aprirlo qui |
| Doppia registrazione di `screen_registered` (rilievo M5) | storia 1.2 |

### Project Structure Notes

Cartelle create da questa storia — **solo tre**:

```
phases/polar/
├── phase_polar.tscn
├── phase_polar.gd
├── polar_input.gd
├── polar_truth_source.gd
└── sources/
    ├── honest_drift.gd / .tres
    └── wandering_drift.gd / .tres

debug/
├── debug_overlay.tscn / .gd
├── lie_injector.gd
└── render_tuning.gd        ← nuovo, non previsto dall'albero dell'architettura

tests/
├── test_bench.tscn
└── test_bench.gd
```

**Deriva di naming fra i documenti — usare `honest_drift`.** L'albero delle cartelle
dell'architettura chiama la sorgente della fase polare `honest_bubble.gd/.tres`, e
`project-context.md` la ripete come esempio di naming. È il nome della **livella** (fase 1,
fuori scopo). Il Pattern 1 dell'architettura e gli AC di questa storia dicono
`honest_drift` / `wandering_drift`, e sono quelli giusti: la fase 3 osserva una **deriva**,
non una bolla.

Analogamente, ADR-001 mostra `HonestBubbleSource` / `DriftingBubbleSource` come esempio
generico. Le classi di questa storia sono **`HonestDrift`** e **`WanderingDrift`**.

**Regole di dipendenza — verificabili:**

| Cartella | Può dipendere da | Non deve mai conoscere |
|---|---|---|
| `phases/` | `core/` | `world/`, `night/`, `photo/`, **altre fasi** |
| `debug/` | tutto | — nessuno importa da `debug/` |
| `core/` | niente | tutto il resto |

`grep "phases/" phases/` deve restare vuoto, a parte i riferimenti interni alla cartella
`polar/` stessa.

### Project Context Rules

Estratte da `_bmad-output/project-context.md`. Sono le cose che un agente sbaglia per
default su **questo** progetto.

**Framework di terze parti: nessuno.** Nessun addon, nessun plugin, nessun package manager.
NFR19 è esplicito: banco di collaudo, nessun framework di test. Non introdurre GUT o
gdUnit4.

**MCP:** GoPeak e Context7 sono *raccomandati e non installati* — nessun `.mcp.json` sul
progetto. Non assumerli disponibili.

**Godot, regole non ovvie che questa storia tocca tutte:**

- Le `Resource` sono **condivise per riferimento**. Due nodi che caricano lo stesso `.tres`
  ricevono la **stessa istanza**. Da qui `resource_local_to_scene = true` sui `.tres` e
  `.duplicate(true)` sull'iniezione a runtime
- `assert()` **sparisce** nelle build di release: solo contratti (`truth != null`), mai
  logica con effetti collaterali
- `reparent()` **trasferisce la proprietà**. Dopo che il `Control` è entrato nel viewport,
  liberare la fase non lo libera — ci pensa `Phase._exit_tree()`, che è già scritto
- Il `name` di un nodo **non è un'identità**: Godot rinomina in `@PhasePolar@2`. Usare
  sempre `key()`
- Mai liberare un nodo dentro la sua stessa callback: transizioni sempre `call_deferred`
- `@onready` si risolve dopo `_ready` dei figli: non usarlo per valori che servono in
  `_enter_tree`
- Signal dichiarati e tipizzati, `snake_case` al passato

**Estetica PS1 — «migliorare la resa» è l'errore più frequente su questo progetto:**

| Non fare | Perché |
|---|---|
| Filtri di texture lineari | il nearest è metà dell'estetica |
| Mipmap | ammorbidiscono in lontananza: uccidono il crunch |
| Cercare un antialiasing | l'aliasing crudo **è** il look, e Compatibility non ne offre |
| Alzare la risoluzione del `SubViewport` del mondo | la bassa risoluzione è voluta |
| Ombre morbide, riflessi, bloom | fuori periodo e fuori renderer |

Valori validati sul campo il 2026-08-21, non stimati: `stretch_shrink = 2`,
`snap_resolution = 665`, `scanline_count = altezza / 2` (calcolato, mai scelto), CRT
`256×192`. Non cambiarli senza una ragione dichiarata.

**Lingua — IT per il giocatore, EN per le macchine:**

```gdscript
# SÌ — l'esito diegetico è inglese: lo scrive una macchina del 1999
return PhaseResult.new(false, "guide star lost", 41)

# NO
return PhaseResult.new(false, "stella guida persa", 41)
```

Commenti in italiano, identificatori in inglese, testo del `Control` in inglese.

**I due canali, che in questa storia si incrociano:**

```gdscript
# CANALE 1 — errore di programma: solo per lo sviluppatore
push_error("[polar] truth source non iniettata")

# CANALE 2 — contenuto: lo legge il giocatore sul CRT
return PhaseResult.new(false, "guide star lost", 41)
```

Un allineamento riuscito male è **canale 2**. Non deve produrre nemmeno un `push_warning`.

**Tono cozy:** nessun modale bloccante, nessuno stack trace mostrato, nessun pannello
d'errore, non si muore.

**Anti-pattern da non commettere, nell'ordine in cui sono tentanti qui:**

```gdscript
_drift = _from_screws(...)                       # 1. ROTTO: scavalca truth (ADR-001)
if is_lying: ... else: ...                       # 2. ROTTO: la rottura NON è un ramo
_viewport.get_child(0).queue_free()              # 3. distrugge il Control di una fase viva
run.phase_scores[phase.name] = s                 # 4. diventa @PhasePolar@2
load("res://data/tuning.tres").night_length_min  # 5. scavalca l'override esterno
FileAccess.open("res://data/...json", READ)      # 6. i dati sono .tres
const T = preload("res://phases/targeting/...")  # 7. rompe ADR-002
```

### Git Intelligence

**Nessuna intelligence disponibile, e il motivo conta.** Il repository git che copre questa
cartella è `E:/GIT` — un repo diverso — dentro cui `astrochills-gd-3d/` compare come
directory **untracked**. `git ls-files` sul progetto non restituisce nulla: nessun file di
questo progetto è mai stato committato.

Conseguenze operative:

1. **AC2 non è eseguibile finché non c'è una baseline**, e `git init` è **rinviato per
   decisione di Federico (2026-08-21)**. Il Task 0 definisce lo strumento sostitutivo: una
   copia di `phase_polar.gd` presa prima di scrivere `WanderingDrift` e confrontata dopo.
   La prova è la stessa — il file non cambia — con un altro strumento di misura
2. Non esiste una storia precedente da cui imparare: questa è la prima storia del progetto
3. I commit visibili nel log appartengono ad altro software e vanno **ignorati**: non
   contengono pattern, convenzioni o dipendenze di questo progetto
4. **Nessun comando git va eseguito in questa storia.** Non `git init`, non `git add`, non
   `git commit`: il progetto resta untracked finché Federico non decide

### Latest Tech Information

**Nessun pacchetto di terze parti, nessuna API esterna, nessuna versione da verificare.**
Il progetto non ha dipendenze: solo Godot e GDScript.

**Godot 4.7.2 stable, renderer Compatibility (OpenGL 3.3 / ES 3.0), PC Windows.** Rilasciata
il 18 agosto 2026. I vincoli del renderer sono già stati verificati contro la documentazione
ufficiale 4.7 e poi **provati sul campo** con lo spike del 2026-08-21 su RTX 3080:
`SubViewport` a bassa risoluzione riscalato nearest, `SubViewport` su mesh 3D con shader,
vertex snapping — tutti superati. Quei risultati sono la fonte, non la memoria di un modello.

Compatibility **non** offre: `CompositorEffect`, compute shader, `RenderingDevice`, buffer
normal/roughness, SSR/SSIL/SDFGI/VoxelGI, fog volumetrica, depth of field, decal, tutti gli
AA post-process. Non cercare workaround: quasi nulla di questo serve, e il post-effect a
schermo intero passa dal `SubViewport` a bassa risoluzione riscalato nearest.

**Avvertenza sulla versione.** 4.7.2 è più recente della conoscenza addestrata di un modello
LLM: per qualunque dettaglio d'API che non compaia già nel codice di questo repository,
consultare la documentazione Godot o l'editor, **non la memoria**.

**Nota sull'input, dal codice che viene cancellato.** `main.gd` documenta che «con il mouse
catturato gli eventi arrivano al viewport radice, non dentro il `SubViewport`», e per lo
spike li inoltrava a mano. In questa storia il mouse **non** è catturato — non c'è player 3D
— quindi il `SubViewportContainer` dovrebbe inoltrare normalmente gli eventi GUI. Va
**verificato che il `Control` li riceva davvero**, non assunto.

### References

- [epics.md § Story 1.1](../planning-artifacts/epics.md) — gli 8 AC, verbatim
- [epics.md § Epic 1](../planning-artifacts/epics.md) — obiettivo dell'epica, FR e UX-DR coperti
- [epics.md § Requirements Inventory](../planning-artifacts/epics.md) — FR7, FR8, FR9, FR16, FR23 (parziale), FR24, FR25, FR34, FR36, FR37 · NFR3, NFR5, NFR6, NFR7, NFR9, NFR19, NFR20, NFR21, NFR23, NFR24 · UX-DR1, UX-DR2, UX-DR5, UX-DR6, UX-DR7, UX-DR9, UX-DR11
- [epics.md § Additional Requirements](../planning-artifacts/epics.md) — keeper verificati, `spike/` usa e getta, i sei primi passi dell'architettura
- [game-architecture.md § ADR-001](../game-architecture.md) — l'indirezione della sorgente di verità
- [game-architecture.md § ADR-002](../game-architecture.md) — una scena per fase
- [game-architecture.md § Pattern 1](../game-architecture.md) — `PolarInput`, `PolarTruthSource`, `HonestDrift`, `WanderingDrift`, e le tre regole del pattern
- [game-architecture.md § Debug Tools](../game-architecture.md) — `F9`, `F12`, mockup dell'overlay
- [game-architecture.md § Testing](../game-architecture.md) — banco di collaudo, e il suo limite dichiarato
- [game-architecture.md § Architectural Boundaries](../game-architecture.md) — regole di dipendenza
- [game-architecture.md § Consistency Rules](../game-architecture.md) — le 10 regole verificabili
- [game-architecture.md § Error Handling](../game-architecture.md) — i due canali
- [project-context.md](../project-context.md) — regole critiche, anti-pattern, valori PS1 validati
- [implementation-readiness-report-2026-08-21.md § M3](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — collisione di tasti su `F1`-`F4`
- [implementation-readiness-report-2026-08-21.md § M6](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — la zavorra della 1.1 e la storia 1.0 proposta
- [implementation-readiness-report-2026-08-21.md § m1, m2](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — deriva di naming, `spike/` ha quattro file
- [minigiochi.md § 3](../../docs/idea/minigiochi.md) — il design della fase: due viti, la stella nel reticolo, «il più lungo e meditativo»
- Repository, letto il 2026-08-21: `main.gd`, `main.tscn`, `project.godot`, `core/*.gd`, `autoloads/*.gd`, `crt/*`, `spike/*`, `world/shaders/ps1.gdshader`, `data/tuning.tres`

---

## Domande aperte

Non bloccano l'inizio del lavoro. Vanno risolte **dentro** la storia, e il dev le porta a
Federico quando ci arriva.

**Chiuse il 2026-08-21 da Federico, prima dell'implementazione:**

- **Tasti dei comandi di taratura** (rilievo M3) → decisi: gli stessi dello spike con
  `Shift`. Tabella nel Task 7.
- ~~**`git init`** → rinviato. La prova dell'AC2 usa una baseline su file. Task 0.~~
  **Riaperta e chiusa in senso opposto il 2026-08-22**, in code review: la baseline su file
  era stata cancellata dal Task 0 «a storia conclusa» mentre la storia era ancora in
  `review`, quindi la prova dell'AC2 non era più rieseguibile da nessuno. `git init` fatto.
  La prova torna a essere `git diff`, come l'AC la voleva.

**Chiuse il 2026-08-22 dalla code review:**

1. **La finestra di media della deriva residua e la mappatura deriva→punteggio vanno in
   `TuningProfile`?** → **Sì, e sono lì.** `polar_score_window_sec` e `polar_max_drift_rate`
   stanno in `core/tuning_profile.gd`, i valori in `data/tuning.tres`, i getter sulla
   superficie `Tuning.<nome>`. La review ha aggiunto la validazione mancante: un override
   esterno non positivo viene rifiutato con un warning invece di azzerare il punteggio in
   silenzio.

2. **FR8 e `epics.md § Decisioni aperte` dicono che la metrica della fase 3 «non è
   decisa».** → **Allineati il 2026-08-22.** La metrica è decisa, implementata e motivata:
   velocità di deriva residua media su una finestra, indipendente da tempo e correzioni.
   FR8 in `epics.md`, `epics.md § Decisioni aperte` e `game-architecture.md § Decisioni di
   design aperte` sono stati corretti perché non contraddicano più il codice.

4. **Come si chiude la fase?** → **ENTER**, via l'azione dichiarata `polar_finish`. La
   chiusura emette un `PhaseResult` valido con `ok = true` anche su un allineamento
   mediocre, come vuole AC5. Nella 1.3, seduto al monitor, sarà un altro gesto.

**Ancora aperte:**

3. **Storia 1.0 — non decisa, e non decisa qui.** Il readiness report (M6) propone di
   estrarre dalla 1.1 la sostituzione del punto d'ingresso (Task 6) e la migrazione dei
   comandi di taratura, lasciando alla 1.1 fase + `F9` + metrica + overlay. **Questa storia
   pianifica sulle 16 storie che esistono**, quindi il Task 6 è dentro. Se la 1.0 venisse
   estratta, i Task 0 e 6 e la parte «comandi di taratura» del Task 7 si spostano lì di peso,
   senza riscrivere il resto.

---

## Dev Agent Record

### Agent Model Used

claude-opus-5 (Claude Code)

### Debug Log References

Verifiche eseguite con l'eseguibile del progetto, `Godot_v4.7.2-stable_win64.exe`, in
headless. `--fixed-fps 60` rende il `delta` deterministico, quindi le prove a tempo sono
ripetibili. Le sonde premono **tasti fisici veri** (`InputEventKey` con `physical_keycode`)
e non azioni sintetiche: le prime versioni usavano `InputEventAction`, che scavalca
l'`InputMap` e quindi non provava affatto che i tasti fossero legati alle azioni.

**Avvio pulito (AC7)** — `--headless --fixed-fps 60 --quit-after 200`:

```
INFO [tuning] profilo 5842c433 — notte 540 min, 0.60 min/s
INFO [game] notte 1 avviata
INFO [main] avvio — renderer
```

Zero errori, zero warning, nessun riferimento pendente a `spike/`.

**Il ciclo della fase (AC1, AC4, AC5)** — la stella scivola, le viti la rallentano, si ferma
dove si trova:

```
t=  3.0  velocita= 0.200'/s  spostata=0.403'  stella=(+0.50,-0.32)  score=  0
>>> tengo A e W: la stella deve RALLENTARE
t=  7.0  velocita= 0.023'/s  spostata=0.207'  stella=(+1.03,-0.62)  score= 14
>>> viti ferme a (-0.0, 0.0)
t=  9.1  velocita= 0.001'/s  spostata=0.001'  stella=(+1.04,-0.62)  score= 37  FERMA
t= 15.1  velocita= 0.001'/s  spostata=0.002'  stella=(+1.03,-0.62)  score= 99  FERMA
t= 19.1  velocita= 0.001'/s  spostata=0.002'  stella=(+1.02,-0.62)  score= 99  FERMA
```

La stella si ferma a `(+1.03, -0.62)` — **dove si trovava**, non al centro. Il punteggio sale
piano mentre la finestra di media si svuota dei campioni di quando era storta: è la proprietà
anti-trucco della metrica, vista funzionare.

**La prova del seam (AC2, AC3)** — `F9` iniettato a caldo sulla stessa esecuzione:

```
>>> F9
INFO [debug] F9: sorgente di polar sostituita con wandering_drift.gd
t= 21.1  velocita= 0.310'/s  spostata=0.327'  stella=(+1.08,-0.30)  score= 79
t= 25.1  velocita= 0.357'/s  spostata=0.727'  stella=(+1.99,+0.73)  score=  0
t= 27.1  velocita= 0.274'/s  spostata=0.650'  stella=(+2.56,+1.03)  score=  0
>>> con la bugia: la stella si muove di nuovo, e le viti non servono
```

Confronto con la baseline presa prima dell'iniezione:

```
$ diff -q phase_polar.baseline.gd phases/polar/phase_polar.gd
AC2 OK — phase_polar.gd identico prima e dopo l'iniezione F9
```

Evidenza strutturale, che sopravvive alla cancellazione della baseline:

```
$ grep -n "Honest\|Wandering\|F9\|debug" phases/polar/phase_polar.gd
NESSUNA OCCORRENZA

$ grep -n "_drift *=" phases/polar/phase_polar.gd
92:  _drift = truth.sample(_truth_input, delta)   # unica assegnazione
```

**Banco di collaudo (AC8)** — `--headless res://tests/test_bench.tscn`:

```
-- HonestDrift: deve essere DETERMINISTICA
   sample(i, 0.016) = (0.06, -0.024)
   sample(i, 0.99 ) = (0.06, -0.024)      -> DETERMINISTICA
   montatura allineata, dopo 60 s: (0.0, 0.0)
   girando la vite verso lo zero la velocità deve calare:
      vite +1.40 -> 0.1680 arcmin/s
      vite +1.00 -> 0.1200 arcmin/s
      vite +0.60 -> 0.0720 arcmin/s
      vite +0.20 -> 0.0240 arcmin/s
      vite +0.00 -> 0.0000 arcmin/s
-- WanderingDrift: deve essere NON deterministica
   sample(i, 0.5) 1a volta = (0.044831, 0.298917)
   sample(i, 0.5) 2a volta = (0.088656, 0.295675)   -> NON deterministica
-- honest_drift.tres      resource_local_to_scene = true
-- wandering_drift.tres   resource_local_to_scene = true
```

**Verifica dei binding** — letti da `project.godot` e poi premuti come tasti fisici:
`A`=65, `D`=68, `S`=83, `W`=87, `ENTER`=4194309. Cinque azioni, nessuna orfana.


### Completion Notes List

**Un bug vero, trovato eseguendo e non leggendo.** `var _input` su un `Node` **ombreggia il
metodo virtuale `Node._input(event)`**: dentro la classe compila, ma dall'esterno
`phase._input` si risolve come `Callable`. Rinominato in `_truth_input`. Sarebbe rimasto
latente fino al giorno in cui la fase avesse voluto gestire l'input da `_input()`.

**Il modello della deriva è cambiato tre volte, e le prime due erano mie e sbagliate.**
Vale la pena che resti scritto, perché la cosa che ha deciso quale fosse giusto non è stata
un'analisi: è stato Federico che apriva il gioco e provava.

| | Cosa restituiva `truth` | Perché è caduto |
|---|---|---|
| 1 | scostamento = `errore × rate × secondi_dall_ultima_correzione` | Girando una vite il contatore dei secondi tornava a 0 a ogni fotogramma, quindi durante tutta la correzione la deriva era 0 e la stella restava incollata al centro. Mollando ripartiva identica. **Il giocatore non vedeva mai l'effetto di ciò che faceva.** |
| 2 | lo stesso, più uno spostamento meccanico `(viti − osservata) × mount_throw`, con ricentraggio esplicito su `R` | Giocabile, ma con una trappola: chi non premeva `R` girava le viti a vuoto **per sempre**, con punteggio 0 qualunque cosa facesse. Provato: viti a `(-0.01, 0.00)`, cioè perfette, e deriva che continuava a crescere `0.07 → 1.13 → 2.33 → 4.14`. Una barra lampeggiante che diceva «premi R» era una toppa su un problema di modello. |
| 3 | **la velocità di deriva**, e la fase la integra | Giri la vite e la stella rallenta mentre hai ancora il dito sul tasto. Quando è ferma è ferma, e resta dov'è. Nessun gesto intermedio, nessuna trappola, e `R` è sparito insieme al problema che risolveva. |

**Come sono arrivate qui le sonde, e perché non bastavano.** Le prime misuravano `score` e
`drift.length()` — numeri corretti in tutte e tre le versioni — e non potevano accorgersi che
il ciclo «premo, vedo, capisco» non si chiudeva. Peggio: premevano le *azioni* con
`InputEventAction`, che scavalca l'`InputMap`, quindi non provavano nemmeno che i tasti
fossero legati a qualcosa. Le sonde finali premono `InputEventKey` con `physical_keycode`.
**Una verifica automatica può dire che i numeri sono giusti; non può dire che il gioco si
capisce.**

**Il ciclo, come è adesso:**

| Gesto | Cosa succede |
|---|---|
| Non fai niente | La stella scivola. In basso leggi la sua velocità in arcominuti al secondo, e la scia la mostra a occhio: punti radi = veloce, punti fitti = quasi ferma |
| `WASD` | Le viti girano e la velocità cala **nello stesso istante**. Nel verso sbagliato, sale |
| — | Quando la velocità è sotto `STEADY` compare `HOLDING STEADY`. La stella resta dov'è, che non è per forza il centro |
| `ENTER` | Chiude, col punteggio della finestra corrente |

**Una lettura più larga di ADR-001, dichiarata e non nascosta.** Con questo modello lo stato
osservabile che viene da `truth` è la **velocità**, e la posizione della stella è la sua
accumulazione tenuta dalla fase (`_star += _drift * delta`, unico termine, nessun altro
ingresso). L'esempio del Pattern 1 nell'architettura mostrava invece la posizione che veniva
direttamente da `truth`. La sostanza del vincolo regge — la fase non calcola mai niente a
partire dalle viti, le passa a `truth` e integra ciò che torna, e `F9` fa ancora derivare la
stella in modo impossibile senza che il file cambi — ma **è un precedente per le altre nove
fasi** ed è scritto in testa a `phase_polar.gd` perché la revisione possa contestarlo invece
di scoprirlo.

**La metrica della fase 3, decisa qui.** Il punteggio è la **velocità di deriva residua**
media sugli ultimi `Tuning.polar_score_window_sec` secondi, mappata su 0-100 con
`Tuning.polar_max_drift_rate` come velocità che vale zero. Non dipende dal tempo impiegato né
dal numero di correzioni, e viene dal valore restituito da `truth` — mai dalle viti. La media
su una finestra, invece del valore istantaneo, è ciò che impedisce di azzerare le viti un
attimo prima di premere `ENTER` e portarsi via 100: la finestra si ricorda ancora com'era. È
anche il motivo per cui il punteggio sale piano dopo una correzione riuscita, cosa che si
vede nelle tracce del Debug Log.

**Numeri finali, tutti in file di dati e non nel codice.** `honest_drift.tres`:
`drift_rate = 0.12` arcmin/s per arcminuto di errore. `data/tuning.tres`:
`polar_score_window_sec = 8.0`, `polar_max_drift_rate = 0.2`. Si cambiano senza ricompilare,
e l'override `user://tuning_override.cfg` funziona anche su build esportata.

**Deviazioni dal testo dei task, dichiarate perché il testo dei task non è mio da riscrivere.**
Il Task 2 diceva «tutta la dipendenza dal tempo passa da `input.seconds_since_correction`»:
nel modello finale la sorgente onesta **non ha alcuna dipendenza dal tempo**, perché
restituisce una velocità. `PolarInput.seconds_since_correction` resta nel contratto — è
dichiarato dall'architettura e servirebbe a una bugia del tipo «si comporta bene solo mentre
la guardi» — ma nessuna sorgente dell'MVP lo usa, ed è documentato così nel file.


**Come l'overlay sa se la sorgente mente.** Non tiene un elenco di classi note: legge il
nome del file della sorgente e guarda se comincia per `honest_`. La convenzione di NFR23
(«l'aggettivo dice se e come mente») diventa così portante, e una sorgente futura comparirà
da sola senza che `debug/debug_overlay.gd` venga toccato.

**Il ponte a 256×192, e perché non è 640×360.** `main.tscn` monta un `SubViewport` da
esattamente `256×192` — la misura del CRT vero — dentro il viewport del mondo. Un `Control`
lasciato riempire 640×360 sarebbe sembrato finito e sarebbe diventato illeggibile nella
storia 1.3. La storia 1.3 dovrà solo sostituire quel viewport con `crt.show_control(...)`.

**Input della fase gestito dal nodo `Phase`, non dal `Control`.** Il `Control` è pura vista
e riceve solo `set_readout()`. Così l'instradamento dell'input non passa dal `SubViewport` —
la trappola che `main.gd` dello spike documentava — e la cosa continuerà a funzionare quando
il `Control` finirà sul CRT.

**Azioni di `InputMap` generate da Godot, non scritte a mano.** I keycode nella sezione
`[input]` di `project.godot` hanno una serializzazione verbosa e facile da sbagliare a
memoria: sono state prodotte da uno script temporaneo eseguito dall'engine stesso, poi
cancellato. Frecce per le due viti, `ENTER` per chiudere.

**Verifiche a occhio, fatte da Federico sul gioco vero il 2026-08-22.** Ha aperto la build
quattro volte durante l'implementazione, ed è così che sono venuti fuori i due difetti di
modello descritti sopra. Alla quarta ha approvato la fase: *«ok questa fase, poi sistemiamo
la parte grafica ma per ora va bene così, è un MVP»*.

**Cosa Federico ha rinviato esplicitamente:** la resa grafica dello schermo della fase.
Il layout a `256×192` è leggibile e il ciclo si capisce — che è ciò che AC1 e UX-DR7
chiedono — ma il trattamento visivo non è finito e non pretende di esserlo. Non è un debito
nascosto: è una scelta di ambito, dichiarata qui.

**L'unica verifica che resta senza riscontro:** che `F9` e `F12` non esistano in una build di
release (AC3). Il meccanismo è `OS.is_debug_build()` in `main.gd::_install_debug_tools()`,
verificato per lettura — i nodi di `debug/` non entrano mai nell'albero — ma non è stato
provato esportando davvero, perché nessun export preset esiste ancora.

**Cosa non è stato toccato, per decisione della storia:** `autoloads/game.gd` (rilievo C1,
aperto, si chiude prima della storia 2.7), `crt/desk_camera.gd` (keeper per la 1.3, oggi
senza utilizzatori), `crt/crt_screen.tscn` con `UPDATE_ALWAYS` (rilievo M4, nessuna storia lo
corregge). Nessun comando git è stato eseguito.

**Le quattro domande aperte** in fondo a questa storia restano tali. La 3 — se estrarre una
storia 1.0 — non è mia da decidere.

### Change Log

| Data | Cosa |
|---|---|
| 2026-08-22 | **Code review a tre layer, e le sue 30 correzioni.** 8 decisioni e 22 patch applicate, 5 voci rinviate in `deferred-work.md`, 5 rilievi scartati come falsi positivi. Le tre correzioni che contano: il clamp su `_star` è passato alla vista, così lo stato osservabile torna a essere l'integrale puro di `truth` e ADR-001 regge alla lettera; `Phase._exit_tree()` è diventato `NOTIFICATION_PREDELETE`, perché su un'uscita temporanea dall'albero liberava l'interfaccia di una fase ancora viva e il frame dopo si deriferiva un oggetto morto; il banco di collaudo carica i `.tres` invece dei default dello script e guarda il segno invece del modulo — verificato invertendo `drift_rate`, che prima passava pulito e adesso viene catturato. **`git init` fatto**: la prova dell'AC2 è tornata a essere `git diff` ed è stata rieseguita. Metrica della fase 3 allineata in FR8, `epics.md` e `game-architecture.md`, che la dichiaravano ancora non decisa. |
| 2026-08-21 | Storia implementata per intero. Fase 3 polare con `HonestDrift`, metrica di qualità decisa e implementata, `WanderingDrift` + iniettore `F9` + overlay `F12`, punto d'ingresso sostituito e `spike/` cancellata, comandi di taratura migrati sotto `debug/` con `Shift`, banco di collaudo. Prova di ADR-001 superata: `phase_polar.gd` identico byte per byte prima e dopo l'arrivo della bugia. |
| 2026-08-22 | **Modello della deriva rifatto una seconda volta, su proposta di Federico: la sorgente restituisce la velocità e la fase la integra.** Il ricentraggio esplicito era una toppa: chi non premeva `R` girava le viti a vuoto per sempre. Con la velocità il riscontro è immediato — giri e la stella rallenta — e `R` è sparito insieme al problema. Rimossi l'azione `polar_recenter` dall'`InputMap`, il termine `mount_throw` da `HonestDrift` e i campi `screw_*` da `PolarInput`. Ritarato: `drift_rate = 0.12`, `polar_max_drift_rate = 0.2`. Baseline ripresa e prova del seam rieseguita: `phase_polar.gd` ancora identico prima e dopo `F9`. Fase approvata da Federico sul gioco vero; resa grafica rinviata per decisione. |
| 2026-08-21 | **Il ciclo della fase era ingiocabile, trovato da Federico aprendo il gioco.** Girare una vite azzerava `seconds_since_correction` a ogni fotogramma, quindi durante la correzione la deriva era sempre 0 e la stella restava inchiodata al centro; mollando, ripartiva identica. Nessuna correzione era percepibile. Rifatto il ciclo su decisione di Federico (ricentraggio esplicito): le viti muovono solo il proprio valore, l'osservazione non si interrompe mai, e `R` comincia una nuova osservazione con la montatura come sta adesso. Comandi passati da frecce a **WASD**, sempre su richiesta di Federico. Baseline ripresa e prova del seam rieseguita sulla fase riscritta: ancora identica. |

### File List

**Nuovi**

- `phases/polar/polar_input.gd`
- `phases/polar/polar_truth_source.gd`
- `phases/polar/polar_screen.gd`
- `phases/polar/phase_polar.gd`
- `phases/polar/phase_polar.tscn`
- `phases/polar/sources/honest_drift.gd`
- `phases/polar/sources/honest_drift.tres`
- `phases/polar/sources/wandering_drift.gd`
- `phases/polar/sources/wandering_drift.tres`
- `debug/debug_overlay.gd`
- `debug/debug_overlay.tscn`
- `debug/lie_injector.gd`
- `debug/render_tuning.gd`
- `tests/test_bench.gd`
- `tests/test_bench.tscn`

I `.uid` corrispondenti agli script sono generati da Godot all'import e vanno versionati con
loro.

**Modificati**

- `main.gd` — sostituito: da script dello spike a orchestratore povero
- `main.tscn` — sostituito: `SubViewport` del mondo conservato con `stretch_shrink = 2` e
  filtro nearest, più `ScreenViewport` a `256×192` e `PhaseHost`
- `project.godot` — nuova sezione `[input]` con cinque azioni della fase polare
- `core/tuning_profile.gd` — `polar_score_window_sec`, `polar_max_drift_rate`
- `data/tuning.tres` — i due valori
- `autoloads/tuning.gd` — i due getter sulla superficie `Tuning.<nome>`
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — stato della storia
- `_bmad-output/implementation-artifacts/1-1-lallineamento-polare-e-la-prova-che-il-seam-regge.md`

**Cancellati**

- `spike/spike_room.gd` + `.uid`
- `spike/spike_room.tscn`
- `spike/spike_player.gd` + `.uid`
- `spike/spike_screen.gd` + `.uid`

**Nuovi dalla code review del 2026-08-22**

- `.gitignore` — esisteva già; ripristinato dalla cronologia locale dopo una sovrascrittura
  in review, e ampliato con `.godot/`, l'esclusione funzionante dell'eseguibile del motore
  (`./Godot*` non filtrava niente: git ignora il prefisso `./` in un pattern) e l'export
- `.godot-version` — `4.7.2-stable`. Il progetto è 4.7-only e su 4.6.x nessun tasto della
  fase risponde, senza un errore: `device:16` nell'`InputMap` è la convenzione di 4.7
- `_bmad-output/implementation-artifacts/deferred-work.md` — le 5 voci rinviate

**Temporanei, creati e rimossi nella stessa sessione**

- `_input_setup.gd` — generatore delle azioni `InputMap`
- `_probe.gd` / `_probe.tscn`, `_probe2.gd` / `_probe2.tscn` — sonde di verifica
- `_bmad-output/implementation-artifacts/phase_polar.baseline.gd` — baseline dell'AC2
