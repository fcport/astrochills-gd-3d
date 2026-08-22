---
baseline_commit: 15010f2
---

# Story 2.1: Un turno che comincia alle 21:00 e finisce da solo all'alba

Status: done

Story key: `2-1-un-turno-che-comincia-alle-21-00-e-finisce-da-solo-allalba`
Epic: 2 — Una notte di lavoro, dall'arrivo all'alba

---

## Story

As a **gestore notturno**,
I want **che il tempo scorra davvero mentre lavoro e che l'alba chiuda la notte al posto mio**,
So that **la notte sia un turno con un inizio e una fine, e non una scena senza bordi**.

> **Questa storia crea `night/`, che non esiste.** Fino a ieri l'orchestrazione era un ponte
> dichiarato temporaneo dentro `main.gd`, che si chiude con una riga scritta dalla 1.1 e mai
> tolta: «Qui finisce il ponte: senza orchestratore non c'è una fase successiva. **L'epica 2
> mette `night_session` a questo posto.**» Questo è quel momento.

**Il tempo è la variabile sperimentale dell'MVP.** `epics.md § Decisioni aperte` lo dichiara:
«**La durata della notte.** È per costruzione un valore di tuning ed è la variabile
sperimentale dell'MVP. Non si «decide»: si prova.» Questa storia costruisce lo strumento con
cui la si prova — l'orologio, l'alba, e i quattro tasti che accelerano la notte senza toccare
una riga di logica.

**È anche la storia che smette di far finta.** Finora una fase esisteva perché il giocatore
premeva `E` sul monitor. Da qui in avanti esiste perché **un piano dice che stanotte va
fatta**, e il piano è un `.tres`. È ADR-002 che si chiude: «gli upgrade che automatizzano una
fase tolgono una riga dal `.tres`. Nessun codice toccato.»

---

## Acceptance Criteria

Riportati da `epics.md § Story 2.1`, numerati per riferimento dai task. **Non riscritti.**

### AC1 — Il tempo scorre, e obbedisce

**Given** una notte avviata
**When** il tempo passa
**Then** `elapsed_min` cresce come `delta * Tuning.game_min_per_sec` su `_process`
**And** la pausa ferma il tempo davvero, e `Engine.time_scale` lo accelera senza che una riga di logica cambi
**And** l'ora di gioco parte dalle 21:00

### AC2 — L'alba non chiede il permesso

**Given** `Tuning.night_length_min` raggiunto
**When** l'alba arriva
**Then** la notte si chiude da sola e mostra il riepilogo
**And** si chiude anche se in quel momento è aperto un menu o una fase è in corso

### AC3 — Il piano è un dato, non codice

**Given** un `NightPlan` come `.tres`
**When** la notte comincia
**Then** l'orchestratore esegue le fasi di **setup** una volta sola e le fasi di **foto** a ogni scatto, leggendo quali e in che ordine dal `.tres`
**And** automatizzare una fase, in futuro, sarà cancellare una riga dal `.tres` — non modificare l'orchestratore

### AC4 — Le transizioni non si accorciano

**Given** una fase che finisce
**When** l'orchestratore avanza
**Then** la transizione passa **sempre** da `call_deferred`, mai da una chiamata diretta dentro la callback
**And** il punteggio viene indicizzato con `phase.key()`, **mai** con `phase.name`

### AC5 — L'apparato sperimentale, dal primo giorno

**Given** una build di sviluppo
**When** si premono `F1`-`F4`
**Then** `Engine.time_scale` cambia, e la notte ×10 è disponibile **dal primo giorno**, non aggiunta dopo
**And** l'overlay `F12` mostra ora corrente, minuti trascorsi e `time_scale` accanto a ciò che già mostrava

### AC6 — Si tara senza ricompilare

**Given** una build già esportata
**When** si scrive `user://tuning_override.cfg` e si riavvia
**Then** la durata della notte cambia senza riaprire l'editor e senza ricompilare
**And** nessun punto del codice legge `data/tuning.tres` con `load()`: si passa sempre dall'autoload `Tuning`

---

## Tasks / Subtasks

### Task 0 — Decidere che ore sono (AC1, e la 2.2 dipende dalla risposta)

> **Questo task viene prima perché nessuna riga di `night_clock.gd` si può scrivere senza la
> risposta, e perché la risposta decide un pezzo della storia 2.2.** Non è una rifinitura: è
> il significato di «ora di gioco».

`FR1` dice: «La notte comincia alle 21:00 e finisce all'alba. L'alba è raggiunta quando
`elapsed_min >= Tuning.night_length_min`, **non a un'ora reale**.» E
`core/tuning_profile.gd` commenta il default: «Durata della notte in minuti di gioco.
**21:00 → 06:00 = 540.**»

Le due frasi combaciano **solo con il default**. Con `night_length_min = 60` — che è
esattamente ciò che `user://tuning_override.cfg` esiste per fare, e che l'AC6 richiede
funzioni su build esportata — le due letture divergono:

| | lettura A: `ora = 21:00 + elapsed_min` | lettura B: le 9 ore si comprimono |
|---|---|---|
| con `night_length_min = 540` | alba alle 06:00 | alba alle 06:00 |
| con `night_length_min = 60` | **alba alle 22:00** | alba alle 06:00, ma un minuto di gioco vale 9 minuti di cielo |
| rapporto con `elapsed_min` | diretto, `elapsed_min` **è** l'ora | indiretto: `elapsed_min` non dice più che ore sono |
| FR1 «non a un'ora reale» | rispettato | rispettato |

- [x] **Decidere fra A e B, e scriverlo dove qualcuno lo cercherà.**
- [x] **La conseguenza che rende la decisione non rinviabile è nella 2.2.** FR11: «Il catalogo
      tiene conto dell'ora corrente della notte: un target fuori dalla propria finestra di
      visibilità è segnalato come non disponibile adesso.» Le finestre di visibilità sono
      **ore reali del cielo**. Con la lettura A e una notte da 60 minuti, l'orologio non
      arriva mai alle ore piccole e **metà catalogo resta permanentemente non disponibile** —
      mentre la durata della notte è il numero che verrà mosso di continuo.
- [x] **Decidere anche se «21:00» è una `const` o un valore di tuning.** `TuningProfile` non
      ha un campo per l'ora di inizio. `game-architecture.md § Naming Conventions` prescrive
      però il nome della costante: `NIGHT_START_HOUR`. La regola di § Configuration dice: «se
      un numero è stato *scelto* e potrebbe essere sbagliato, sta nel tuning. Se è una verità
      matematica, è una `const`». Le 21:00 sono una decisione, non un teorema — ma sono anche
      l'unica cosa che l'AC1 fissa alla lettera.
- [x] **Il formato dell'ora è già prescritto**, e non va inventato: `HH:MM` su 24 ore, con i
      minuti trascorsi accanto fra parentesi. Il mockup normativo dell'overlay lo mostra come
      `23:41  (elapsed 161 min)` — ed è internamente coerente con la partenza alle 21:00,
      perché 21:00 + 161 min = 23:41. È la prova più forte che l'architettura abbia in mente
      la lettura A.

### Task 1 — `NightClock`, che è tre righe e due trappole (AC1)

`game-architecture.md § System Location Mapping` prescrive il file: **`night/night_clock.gd`**,
descritto come «accumulatore su `_process`». La formula è scritta: «Un nodo che processa
accumula `run.elapsed_min += delta * tuning.game_min_per_sec`.»

- [x] **Il dato non è dell'orologio.** `elapsed_min` è un campo di `NightRun`
      (`core/night_run.gd:16`), che esiste già ed è **mai letto e mai scritto** da nessuno: la
      sua unica occorrenza nel repository è la dichiarazione. La divisione dei ruoli è
      dichiarata dall'architettura: **`NightClock` fa scorrere, `NightRun` conserva, `Game`
      possiede.** Non introdurre una seconda copia del tempo dentro l'orologio.
- [x] **Trappola 1 — la pausa.** L'AC dice «la pausa ferma il tempo davvero». È vero solo se
      l'orologio **non** è in `PROCESS_MODE_ALWAYS`: con quel modo `_process` continuerebbe a
      girare a albero in pausa e la seconda metà dell'AC sarebbe falsa. Il `delta` di
      `_process` è già la quantità su cui la pausa e `Engine.time_scale` agiscono — è tutto
      il meccanismo, e non ne serve altro.
- [x] **Trappola 2 — non leggere `Engine.time_scale`.** L'architettura dice che
      `Engine.time_scale = 10.0` accelera la notte «senza toccare una riga di logica». Se
      l'orologio moltiplicasse a mano per `time_scale`, l'accelerazione verrebbe applicata
      **due volte**. `time_control.gd` scrive su `Engine.time_scale`; `NightClock` non lo
      legge mai.
- [x] **Serve una lettura pubblica dell'ora, e non è un vezzo.** La 2.2 ne ha bisogno per le
      finestre di visibilità (FR11); la 3.6 misura le attività dell'attesa **in minuti di
      gioco** e deve poter leggere il tempo in qualunque istante senza passare da una fase
      (rilievo C3). Un `elapsed_min` privato dentro `night_session` lascia entrambe senza
      appiglio.
- [x] **`Tuning.game_min_per_sec` e `Tuning.night_length_min` esistono già** e valgono 0.6 e
      540.0 (`data/tuning.tres:7-8`). **Nessuna riga del progetto li legge**: questa storia è
      la prima. Si accede come `Tuning.<nome>`, mai `Tuning.profile.<nome>` — lo dichiara
      `autoloads/tuning.gd`.

### Task 2 — `NightSession`, e il piano che è un dato (AC3, AC4)

I nomi sono prescritti alla lettera da `game-architecture.md § Directory Structure`, e non
vanno inventati: **`night/night_session.tscn`**, **`night/night_session.gd`**,
**`night/night_clock.gd`**, **`night/post_photo_menu.tscn/.gd`** (quest'ultimo è della 2.6).
Il diagramma di § Pattern 2 prescrive anche i nodi in scena: `NightSession`, con figli
`PhaseHost` e `NightClock`.

- [x] **L'architettura scrive il codice dell'orchestratore in due blocchi normativi.** Non
      sono esempi: sono la forma attesa, e nominano `_instantiate_phase(scene)`,
      `_on_phase_finished(result, phase)`, `_advance(result, phase)`, `_enter_next(result)`,
      `_ctx`, `_crt`.
- [x] **`NightPlan` esiste già ed è vuoto**: `core/night_plan.gd` dichiara
      `setup_phases: Array[PackedScene]` e `photo_phases: Array[PackedScene]`, **nessun
      metodo**, e **nessun file del progetto lo nomina**. Non esiste nessun `.tres` di tipo
      `NightPlan`: `data/` contiene un solo file, `data/tuning.tres`.
- [x] **La distinzione setup/foto sta nei due array, non in un `if`.** Il commento già scritto
      in `core/night_plan.gd` lo dice: «Le fasi di setup si eseguono una volta per notte e
      restano valide fino all'alba; quelle di foto si rieseguono per ogni scatto».
- [x] **Il test operativo di AC3, e va tenuto verde:** in `night_session.gd` non deve comparire
      **nessun riferimento a una fase specifica** — né un `preload` di `phase_polar.tscn`, né
      un `match` sul `key()`. Se l'orchestratore nomina una fase, la promessa «automatizzare
      una fase sarà cancellare una riga dal `.tres`» è già rotta, ed è lo stesso errore che
      ADR-002 chiude: «`switch` sul `key` della fase … è una forma che non sopravvive al
      vincolo». Oggi quel riferimento c'è, ed è `main.gd` con
      `const PHASE_POLAR := preload(...)`: va tolto di lì, non copiato.
- [x] **Il ponte ha già le guardie che l'architettura non ha**, e sono correzioni di code
      review pagate: registra `result.score` invece di richiamare `phase.score()` (perché una
      fase con `score()` non idempotente scriverebbe nel save un numero diverso da quello
      emesso); scarta il `finished` di una fase non più corrente (`if phase != _phase`); fa
      `remove_child()` **prima** di `queue_free()`. Lo snippet dell'architettura non le ha.
      **Vanno trasferite, non riscritte da capo.**
- [x] **`call_deferred` e `key()` sono AC4**, e sono anche due delle dieci Consistency Rules.
      `phase.name` diventa `@PhasePolar@2` al secondo `add_child` con lo stesso nome — e con
      «rifai setup» (FR3, storia 2.6) succede davvero, con il risultato che finisce **nel
      save** con la chiave sbagliata.

### Task 3 — Dove vive l'orchestratore, che è il vero problema di questa storia (AC3, AC4, NFR8)

> **Da leggere prima di creare la cartella.** Questo task non ha una risposta scritta in
> nessun documento, e tutte le strade costano qualcosa.

La tabella dei confini è netta: «`night/` | può dipendere da `core/`, `phases/`, `photo/`,
`crt/` | **non deve mai conoscere `world/`** — parla via `Events`».

Ma `main.gd` oggi tiene insieme due cose che questa storia deve separare:

| Cosa | Tocca | Può stare in `night/`? |
|---|---|---|
| istanziare fasi, `finished`, punteggi, avanzamento | `core/`, `phases/`, `crt/` | **sì** |
| `show_control()` sul CRT | `crt/` | **sì** |
| `player.set_enabled()`, `_release_all_actions()`, `desk.toggle()`, la sequenza ADR-003 | **`world/`** | **no** |
| il `SubViewport` del mondo, la tecnica PS1 | `main.tscn` | no |
| installare `debug/` | `debug/` | sì, ma solo il punto d'ingresso |

- [x] **Decidere la forma, e dichiararla nell'intestazione del file.** Le due letture
      possibili: **(a)** `night_session` è un figlio di `main.tscn` e possiede `PhaseHost`,
      mentre `main.gd` resta il punto d'ingresso del mondo e gli passa il `CrtScreen` trovato
      per gruppo; **(b)** `night_session` diventa la radice e `main.gd` sparisce — ma allora
      la coreografia della postazione va da qualche parte, e `night/` non può ospitarla.
- [x] **Il ponte ha già dichiarato l'erede.** L'intestazione di `main.gd` dice: «CHI CHIAMA
      `crt.show_control()` È QUESTO FILE … Quando arriverà `night/night_session.gd` eredita
      questo punto di chiamata senza spostarlo». Era la chiusura del rilievo m6. Chi
      implementa deve decidere se «eredita» significa che `night_session` chiama
      `show_control()` **direttamente** — permesso dai confini, `crt/` è nella sua colonna —
      o se continua a passare da `main.gd`.
- [x] **`Events.screen_registered` non risolve il problema, e va saputo.** L'architettura
      propone `Events.screen_registered.connect(...)` in `night_session._ready()` come modo di
      raggiungere il monitor senza conoscere `world/`. **Non funziona se `night_session` nasce
      dentro `main.tscn`**: `CrtScreen` emette nel proprio `_ready()` e l'albero si costruisce
      profondità-prima, quindi l'emissione avviene prima. È il motivo per cui `main.gd` cerca
      per gruppo con `CrtMonitor.find_in()`, ed è già una voce di `deferred-work.md`. Un
      autoload lo riceverebbe; un nodo della scena principale no.
- [x] **Non spostare la coreografia della postazione.** `_sit_down()`, `_stand_up()`,
      `_on_seated()`, `_on_left()`, `_set_phase_running()` e `_input()`/`_shortcut_input()`
      sono il risultato della code review della 1.3, che ci ha chiuso dentro due blocchi senza
      ritorno. Tagliarli a metà li riapre. Se l'orchestratore deve sapere quando una fase è
      visibile, il canale è un signal o un metodo, non una divisione di quelle funzioni.
- [x] **`PhaseHost` oggi è un nodo di `main.tscn` con nome unico** (`%PhaseHost`).
      L'architettura lo disegna figlio di `NightSession`. Se si sposta, il nome unico non è
      più risolvibile da `main.gd`; se resta, `night_session` deve riceverlo per riferimento.
      È il rilievo minore m3, mai chiuso.

### Task 4 — L'alba, che è un secondo ingresso al flusso di controllo (AC2)

- [x] **L'alba non è un esito di fase.** Non arriva da `PhaseResult`, arriva dall'orologio:
      `elapsed_min >= Tuning.night_length_min`. È un secondo ingresso all'orchestratore,
      parallelo a quello delle fasi, e questa è tutta la difficoltà dell'AC2.
- [x] **«Anche se è aperto un menu o una fase è in corso» significa che l'alba smonta.** Una
      fase in corso all'alba va chiusa dall'orchestratore, non attesa. Valgono comunque, senza
      sconti: `call_deferred`, `show_control(null)` **prima** di liberare, e `key()` per il
      punteggio.
- [x] **`dawn_reached()` va emesso**, ed è il rimedio scritto per il rilievo M1: «aggiungendo
      alla 2.1 e alla 2.3 l'obbligo di emettere `phase_started`/`phase_finished` e
      `dawn_reached` sul bus. Sblocca la 3.5 senza che nessuno debba violare un boundary». Il
      signal è **già dichiarato** in `autoloads/events.gd:19` e non lo emette nessuno.
      `phase_started` e `phase_finished` invece sono già emessi dal ponte
      (`main.gd`): vanno trasferiti, non aggiunti.
- [x] **`hour_passed(hour: int)` è dichiarato e non lo chiede nessun AC.** Vedi la domanda
      aperta: emetterlo adesso o lasciarlo inerte è una scelta, e va fatta consapevolmente
      invece di scoprirla nella 3.5.
- [x] **Attenzione a `Game.run` che diventa nullo.** `autoloads/game.gd:17-19` ha
      `end_night()` che fa `run = null`, e **non lo chiama nessuno**. `main.gd` scrive
      `Game.run.phase_scores[...]` **senza guardia**: se l'alba chiama `end_night()` e una
      fase si conclude subito dopo, è un crash. Anche l'overlay F12 legge `Game.run` (e la
      guardia ce l'ha già).

### Task 5 — Il riepilogo, che non ha una casa (AC2)

> **Questo è il rilievo M2, aperto dal 2026-08-21, e il readiness report lo chiama «la
> decisione con più conseguenze sul gioco» fra quelle elencate.** La parola «riepilogo» non
> compare **mai** in `game-architecture.md`, e in `night/` non esiste un file per esso.

Il conflitto, per intero:

- **FR5:** «L'alba chiude la notte da sola, anche a menu aperto, e **mostra il riepilogo della
  notte**.»
- **UX-DR1:** ogni interfaccia di fase è un `Control` sul CRT diegetico; la UI non diegetica
  esiste **solo** per pausa e impostazioni. Il riepilogo non è una fase.
- **UX-DR5:** «Nessuna interfaccia deve richiedere di leggere il CRT da lontano o da in
  piedi» — e la 1.3 lo ha verificato guardando: da in piedi il CRT è illeggibile per
  costruzione.
- **All'alba il giocatore può essere in cucina.** È il punto dell'intero MVP.
- **UX-DR9/NFR20:** nessun popup di gioco sopra il mondo, nessun modale bloccante.

- [x] **Decidere: CRT diegetico o eccezione dichiarata a UX-DR1.** Il report scrive il bivio:
      «menu sul CRT (e allora «riaprire il menu» significa tornare a sedersi, che è una scelta
      di design legittima ma va detta), oppure un'eccezione dichiarata a UX-DR1».
- [x] **Decidere anche cosa contiene, adesso.** Nella 2.1 non esistono foto (2.4), né vendite
      (2.5), né commesse (2.5): un riepilogo onesto direbbe «0 foto, 0 lire». È lo stesso
      argomento con cui la voce «Dopo ENTER il ponte finisce nel vuoto» è stata **rinviata**
      il 2026-08-22 — inventare uno schermo di esito che tre storie riscriveranno. La
      differenza è che lì nessun AC lo chiedeva, e qui l'AC2 lo chiede.
- [x] **Se il riepilogo diventa un'eccezione a UX-DR1, va scritta come eccezione**, con la
      ragione, nel documento di architettura o in `deferred-work.md`. Una regola violata in
      silenzio è peggio di una regola cambiata.

### Task 6 — `F1`-`F4`, l'apparato sperimentale (AC5)

`game-architecture.md § Directory Structure` prescrive il file: **`debug/time_control.gd`**.
La tabella degli strumenti dice: «**Controllo del tempo** | `F1`–`F4` | Apparato sperimentale
per tarare la durata dell'attesa».

- [x] **I tasti sono liberi davvero, ed è stato pagato per tenerli tali.**
      `debug/render_tuning.gd` porta in intestazione: «TASTI — spostati sotto Shift rispetto
      allo spike. `F1`-`F4` sono riservati al controllo del tempo (FR35, storia 2.1) e non
      vanno occupati nemmeno per poco». Usa `Shift+F1/F2/F3` e `Shift+F5/F6/F7`. `F9` e `F12`
      pretendono `not shift_pressed`. **Il rilievo M3 del readiness report risulta quindi già
      chiuso in codice**, anche se il documento non è stato aggiornato.
- [x] **Nessun documento assegna un valore a ciascuno dei quattro tasti.** L'unico numero
      nominato è ×10 («la notte ×10 per collaudare è gratis», «disponibile dal primo
      giorno»). La mappatura è una decisione di questa storia: vedi le domande aperte.
- [x] **`Engine.time_scale` è globale, e va detto cosa comporta.** A ×10 la transizione della
      `DeskCamera` dura 50 ms invece di 0,5 s (e UX-DR6 dà quel mezzo secondo come valore
      validato), la camminata è dieci volte più veloce, e la finestra del punteggio polare —
      `polar_score_window_sec`, che è in **secondi reali** — diventa 0,8 s di gioco. Se è una
      scelta consapevole va scritto che **un punteggio misurato a ×10 non è confrontabile con
      uno misurato a ×1**.
- [x] **Il controllo del tempo è `debug/`, quindi non esiste in release**: `OS.is_debug_build()`
      e `load()` da costante-percorso, **mai** `preload` — FR37, e la forma corretta è già in
      `main.gd` con `DEBUG_OVERLAY_PATH`/`RENDER_TUNING_PATH`/`LIE_INJECTOR_PATH`.
- [x] **Usare keycode grezzi, non azioni dell'`InputMap`.** Gli altri tre strumenti lo fanno,
      e c'è una ragione nuova: `main.gd::_input()` ingoia **le azioni dell'`InputMap`** durante
      la transizione alla postazione. Un controllo del tempo legato a un'azione smetterebbe di
      rispondere per mezzo secondo a ogni seduta; con un keycode resta raggiungibile — che è
      esattamente la correzione fatta in code review della 1.3.

### Task 7 — L'overlay dice che ore sono (AC5)

Il mockup normativo di `game-architecture.md § Debug Tools` è questo, e le prime due righe
sono ciò che manca:

```
+-- DEBUG ------------------+
| 23:41  (elapsed 161 min)  |
| time_scale  1.0           |
| polar      82  [HONEST]   |
| ...
```

- [x] **`debug/debug_overlay.gd` ricostruisce le righe a ogni `_process`** in `_lines()`: una
      riga nuova è un `out.append(...)`. Le righe di stato sono in **inglese**, le righe di
      aiuto in **italiano** — è la regola delle due lingue dell'overlay, già rispettata dal
      file.
- [x] **La strada meno invasiva per il dato è `Game.run.elapsed_min`**, che l'overlay già
      raggiunge come raggiunge `Game.run.phase_scores`. L'alternativa — un terzo parametro di
      `configure()` — obbliga a toccare sia `debug/debug_overlay.gd` sia il punto d'ingresso.
- [x] **Nota che l'overlay ha già una voce rinviata aperta**: da quando alzarsi sospende una
      fase invece di concluderla, `F12` mostra una fase sospesa come se stesse girando. Questa
      storia tocca la stessa riga di stato: chiuderla per contiguità o rinviarla ancora è una
      scelta da fare, non da scoprire.

### Task 8 — L'override, che è già scritto (AC6)

> **Attenzione: questo AC è in gran parte già soddisfatto da codice della 1.1.** Il compito è
> verificarlo e non romperlo, non costruirlo.

- [x] `autoloads/tuning.gd` ha già: caricamento di `data/tuning.tres`, `duplicate(true)` per
      non mutare la risorsa condivisa, `_apply_override()` che legge
      `user://tuning_override.cfg` con `ConfigFile`, validazione delle chiavi sconosciute e dei
      valori non positivi (`POSITIVE_KEYS`), log di ogni valore applicato, e `profile_hash`
      per marcare con quali numeri una notte è stata giocata.
- [x] **`night_length_min` e `game_min_per_sec` sono entrambi in `POSITIVE_KEYS`**, quindi un
      override a zero o negativo viene rifiutato con un warning invece di produrre una notte
      infinita o istantanea.
- [x] **La verifica dell'AC6 va fatta su una build esportata, non nell'editor** — è ciò che
      NFR13 chiede: «deve funzionare **su build già esportata**: è lo strumento con cui si
      tara l'MVP, anche in mano a qualcun altro».
- [x] `grep -rn "tuning.tres" --include=*.gd .` deve trovare **solo** `autoloads/tuning.gd`.
      È la verifica scritta nelle Consistency Rules.

### Task 9 — Le verifiche che gli AC promettono

- [x] `grep -rn "world/" night/` → **zero occorrenze**. È NFR8, ed è il confine che questa
      storia inaugura.
- [x] `grep -rn "phases/" night/` → solo percorsi che arrivano dal `NightPlan`, **nessun
      `preload` di una fase specifica** e nessun `match` su `key()`. È AC3.
- [x] `git diff -- phases/polar/phase_polar.gd` → **vuoto**. Regge dalla 1.1 e questa storia
      non ha ragione di romperlo: l'orchestratore parla `Phase`, non `PhasePolar`.
- [x] I confini delle storie precedenti restano verdi: `phases/` in `crt/` → zero; `world/` in
      `crt/` → zero; `phases/`, `night/`, `debug/` in `world/` → zero. **`night/` adesso
      esiste davvero**, quindi il terzo grep smette di essere teorico.
- [x] `grep -rn "phase.name" .` → zero. AC4.
- [x] Gioco a **zero errori e zero warning**:
      `Godot_v4.7.2-stable_win64.exe --headless --path . --quit-after 300`.
- [x] `tests/test_bench.tscn` continua a girare pulito. **Qui invece qualcosa da aggiungere
      c'è**, ed è la prima volta in questa epica: il banco collauda logica pura, e
      «`elapsed_min` cresce come `delta * game_min_per_sec`» e «l'alba scatta a
      `night_length_min`» sono aritmetica verificabile senza aprire una finestra. Il banco non
      asserisce, stampa: seguirne la forma.
- [x] **La notte va giocata almeno una volta per intero**, a ×10 se serve, e va guardata: è
      l'unico modo di verificare che l'alba chiuda davvero e che l'ora mostrata abbia senso.

### Review Findings

Code review del 2026-08-23, tre layer adversariali (Blind Hunter, Edge Case Hunter,
Acceptance Auditor). 21 rilievi grezzi → 4 decisioni (tutte prese), 16 patch, 7 rinviati, 2 scartati.

**Decisioni — prese da Federico il 2026-08-23**

- [x] [Review][Decision] AC2, clausola «anche se è aperto un menu»: **dichiarata parzialmente rinviata**. `night_clock.gd` è a `PROCESS_MODE_INHERIT` — giustamente: è ciò che rende vera l'altra metà dell'AC1 — quindi in pausa `_process` non gira e `dawn` non può arrivare. Le due clausole sono in tensione per costruzione. *Rinviata perché la clausola non è verificabile finché un menu non esiste: `ui/` è vuoto e nessuna storia prima della 2.6 lo crea. La prova si sposta alla 2.6, insieme al menu post-foto che la rende osservabile.* → voce in `deferred-work.md`
- [x] [Review][Decision] AC4, l'alba come unica transizione sincrona: **si differisce il teardown**. `_on_dawn()` mette `_ended = true` e accoda il resto con `call_deferred`, così AC4 è vero alla lettera e il file non ha più un'eccezione da spiegare. Va progettato insieme alla patch della guardia `was_current`, perché sposta l'ordine fra i due ingressi al flusso di controllo. → patch
- [x] [Review][Decision] `F4` (×10) e la saturazione della fisica a ×8: **si corregge il commento e si dichiara il limite**, senza toccare `project.godot`. Va scritto in `debug/time_control.gd` che oltre ×8 la fisica satura (`max_physics_steps_per_frame` di default) e che una misura presa a ×10 non è confrontabile con una presa a ×1 — lo stesso argomento che il file già fa per `polar_score_window_sec`. → patch
- [x] [Review][Decision] Task 7, l'overlay che mostra una fase sospesa come viva: **si chiude adesso**. `night_session` espone lo stato di presenza e `_phase_line()` distingue una fase sospesa da una che gira. Il diff tocca già quel file e quella riga di stato. → patch

**Patch**

- [x] [Review][Patch] `_dispose()` svuota il CRT incondizionatamente: la guardia `was_current` del ponte non è stata trasferita, e all'alba cancella il riepilogo appena mostrato [night/night_session.gd:283-306]
- [x] [Review][Patch] Il riepilogo non arriva sul vetro se il giocatore non è alla postazione: `set_live(false)` lascia il viewport congelato e `show_control()` non chiede un ridisegno [night/night_session.gd:336-339, crt/crt_screen.gd:44-60]
- [x] [Review][Patch] Il banco legge `data/tuning.tres` con `load()`: viola la seconda clausola dell'AC6 e rompe la verifica del Task 8, che il Change Log dichiara superata [tests/test_bench.gd:26,172]
- [x] [Review][Patch] `_next_scene()` restituisce una casella vuota del `.tres` come «piano finito»: la notte si tronca in silenzio, senza un `push_error` [night/night_session.gd:175-190]
- [x] [Review][Patch] Una scena non-`Phase` nel piano ferma la notte invece di proseguire — al contrario del ramo gemello tre righe sotto — e l'istanza costruita resta orfana [night/night_session.gd:208-212]
- [x] [Review][Patch] `_begin_night()` monta l'orchestratore prima di `configure()` e non ripulisce sul fallimento: `Game.start_night()` non viene chiamata, `_refresh_monitor()` nemmeno, e ogni `E` stampa un errore che indica la causa sbagliata [main.gd:159-177]
- [x] [Review][Patch] `hour_passed` salta le ore quando un frame ne attraversa più d'una; il banco stampa «9 segnali» come se fossero garantiti [night/night_clock.gd:84-87]
- [x] [Review][Patch] L'alba non fissa `elapsed_min` alla soglia: dopo un frame lungo a ×10 il riepilogo e il log dicono `06:06` invece di `06:00` [night/night_clock.gd:89-95]
- [x] [Review][Patch] `time_control.scale()` è codice morto con una docstring che dichiara un consumatore inesistente: l'overlay legge `Engine.time_scale` da sé [debug/time_control.gd:55-57]
- [x] [Review][Patch] Il banco promette di segnalare la divergenza di `NIGHT_START_HOUR` e non confronta mai le due costanti, benché `NightClock.NIGHT_START_HOUR` sia leggibile staticamente [tests/test_bench.gd:28-30]
- [x] [Review][Patch] `begin()` si dichiara rieseguibile azzerando quattro campi ma lascia `_ctx` col payload della notte precedente e `_summary` non nullo, che fa mentire `has_phase()` [night/night_session.gd:101-111]
- [x] [Review][Patch] `p.queue_free()` senza `remove_child()` nel ramo della fase mal configurata: contraddice la dottrina che `_dispose()` documenta settanta righe sotto [night/night_session.gd:224-228]
- [x] [Review][Patch] L'alba smonta in modo sincrono dentro il `_process` dell'orologio: differire il teardown di `_on_dawn()` con `call_deferred`, progettandolo insieme alla guardia `was_current` [night/night_session.gd:316-339]
- [x] [Review][Patch] `debug/time_control.gd` promette che a ×10 il giocatore cammini dieci volte più in fretta: la fisica satura a ×8 (`max_physics_steps_per_frame` di default, `project.godot` non ha sezione `[physics]`). Correggere l'intestazione e dichiarare che una misura presa a ×10 non è confrontabile con una a ×1 [debug/time_control.gd:1-30]
- [x] [Review][Patch] `F12` mostra una fase sospesa come se stesse girando: esporre lo stato di presenza da `night_session` e distinguere le due nella riga di stato [debug/debug_overlay.gd:97-107, night/night_session.gd]
- [x] [Review][Patch] Documentazione: `deferred-work.md` non aggiornato benché questa storia chiuda due sue voci; `grep -rn "phases/" night/` non pulito per un commento che nomina `phase_polar.gd` [night/night_session.gd:247]; il Change Log dichiara AC3 senza citare che il ciclo delle foto non riapre; la domanda aperta 8 (`end_night()` mai chiamata) resta senza risposta scritta

**Rinviati**

- [x] [Review][Defer] AC2, clausola «anche se è aperto un menu»: non verificabile finché un menu non esiste [night/night_clock.gd] — rinviata per decisione di Federico del 2026-08-23, la prova si sposta alla 2.6
- [x] [Review][Defer] `NightClock` non valida `night_length_min` e `game_min_per_sec` letti dal `.tres`: `POSITIVE_KEYS` protegge solo l'override, non il profilo di base [night/night_clock.gd:77-95, autoloads/tuning.gd:47-53] — rinviato, difetto pre-esistente in `autoloads/tuning.gd`
- [x] [Review][Defer] `_on_phase_finished` non ha un latch: `_phase` si azzera solo in `_advance`, differita [night/night_session.gd:256-287] — rinviato, oggi non raggiungibile (`phase_polar` ha `_done`), ma il contratto `Phase` non impone il latch
- [x] [Review][Defer] La lambda su `Events.phase_started` cattura `self` e non viene mai disconnessa, a differenza della riga adiacente [main.gd:173] — rinviato, innocuo finché `_begin_night()` gira una volta sola
- [x] [Review][Defer] Il riepilogo trabocca dal vetro oltre cinque punteggi: `y` parte da 84 e cresce di 16, la riga fissa sta a 172 [night/night_summary.gd:66-75] — rinviato, oggi il piano ha una fase sola
- [x] [Review][Defer] `phase_scores[key()]` sovrascrive: una fase foto rieseguita a ogni scatto terrà solo l'ultimo punteggio [night/night_session.gd:267] — rinviato, la semantica la decide la 2.3
- [x] [Review][Defer] AC3, seconda metà: `_photo_index` non si riazzera, il ciclo delle foto non riapre [night/night_session.gd:175-198] — rinviato di proposito, lo riapre il menu post-foto della 2.6


---

## Dev Notes

### La regola numero uno, in questa storia

Nella 1.1 era ADR-001. Nella 1.2 il confine di `world/`. Nella 1.3 la proprietà del `Control`.
Qui è **ADR-002 letto al contrario**:

> «Ogni fase è un `.tscn` con il proprio script che estende `Phase`. L'orchestratore le
> istanzia, si collega a `finished(result)`, e **non sa cosa facciano dentro**.»

Un orchestratore che sa cosa fa una fase è un orchestratore che dovrà essere riscritto a ogni
fase nuova — e ne mancano sette. Il test è meccanico e sta nel Task 9: se `night_session.gd`
nomina una fase, la storia è sbagliata anche se funziona.

### Cosa esiste già e non va riscritto

| File | Cosa contiene oggi | Come si usa qui |
|---|---|---|
| `core/night_plan.gd` | `setup_phases`, `photo_phases`, nessun metodo, **zero riferimenti nel progetto** | è il piano: va istanziato come `.tres` |
| `core/night_run.gd` | `elapsed_min` **dichiarato e mai usato**, `phase_scores` funzionante, `wallet_lire` mai incrementato, `migrate()` mai chiamato | `elapsed_min` è il campo di questa storia |
| `autoloads/tuning.gd` | tutto: caricamento, `duplicate`, override da `user://`, validazione, `profile_hash` | **si consuma, non si costruisce** |
| `autoloads/game.gd` | `start_night()` crea una `NightRun` nuova; `end_night()` esiste e **non lo chiama nessuno** | attenzione a `run = null` |
| `autoloads/events.gd` | 8 signal; `hour_passed` e `dawn_reached` dichiarati e **mai emessi** | `dawn_reached` è di questa storia (M1) |
| `main.gd` | il ponte: `_enter_phase`, `_on_phase_finished`, `_advance`, `_dispose`, `_phase_can_run`, più la coreografia della postazione | l'orchestrazione migra, la postazione **resta** |
| `core/phase.gd` | il contratto, con `runs_in_background()` e `NOTIFICATION_PREDELETE` | non toccare |
| `core/phase_result.gd` | `ok`, `reason`, `score`, **`payload` mai usato da nessuno** | il `payload` è il canale della 2.2 |
| `debug/render_tuning.gd` | `Shift+F1/F2/F3`, `Shift+F5/F6/F7` | **non toccare**: ha già liberato `F1`-`F4` |
| `debug/debug_overlay.gd` | `_lines()` ricostruito ogni frame, guardia su `Game.run` | due righe nuove in cima |

### Le trappole che questa storia incontra per forza

**1. Il tempo che non si ferma.** `PROCESS_MODE_ALWAYS` sull'orologio rende falsa metà
dell'AC1. Il `delta` di `_process` è già tutto il meccanismo di pausa e `time_scale`: non
serve altro, e aggiungere altro rompe.

**2. La doppia accelerazione.** Leggere `Engine.time_scale` dentro l'orologio applica il
fattore due volte. `time_control.gd` scrive, `NightClock` non legge.

**3. `Game.run` nullo dopo l'alba.** `end_night()` fa `run = null`, e `main.gd` scrive
`Game.run.phase_scores[...]` senza guardia. L'ordine fra «chiudi la notte» e «una fase in
corso si conclude» va deciso, non subito.

**4. Le `Resource` condivise per riferimento.** «Ogni `PhaseTruthSource` si inietta con
`.duplicate()` (o `resource_local_to_scene = true`) … è un bug che costa un pomeriggio e **non
si manifesta finché non ci sono due fasi in scena insieme**.» Con l'epica 2 le fasi in scena
diventano tre, e con «rifai setup» la stessa fase viene istanziata due volte nella stessa
notte: **questa è la prima storia in cui quel bug può manifestarsi davvero.** Il banco di
collaudo verifica già che i `.tres` delle sorgenti abbiano `resource_local_to_scene = true`.

**5. `screen_registered` non arriva a chi nasce con la scena.** Vedi Task 3. L'architettura
propone quel segnale come il modo in cui `night/` raggiunge il CRT senza conoscere `world/`,
ma l'emissione precede `Main._ready()`. Chi nasce dentro `main.tscn` deve cercare per gruppo.

**6. Gli strumenti di debug perdono la fase.** `debug/debug_overlay.gd` e
`debug/lie_injector.gd` chiamano `_main.current_phase()` su un riferimento passato con
`configure(self)`. Se `_phase` migra in `night_session` e `Main.current_phase()` sparisce, è
un errore a ogni frame; se resta e restituisce sempre `null`, **l'iniettore che esiste per
provare ADR-001 mente in silenzio**. Due uscite oneste: `Main.current_phase()` delega alla
night session, oppure `configure()` riceve la night session — e allora si toccano entrambi i
file di `debug/`.

### Le misure e i numeri veri

| Numero | Valore | Dove vive |
|---|---|---|
| `night_length_min` | **540.0** (21:00 → 06:00) | `data/tuning.tres`, override-abile |
| `game_min_per_sec` | **0.6** → una notte in **15 minuti reali** | `data/tuning.tres`, override-abile |
| `min_per_frame` | 5.0 | `data/tuning.tres` — lo consuma la 2.3, non questa |
| ora di inizio | 21:00 | **nessun file**: è il Task 0 |
| `polar_score_window_sec` | 8.0 **secondi reali** | non scala con `time_scale` in modo innocuo |
| tasti liberi | `F1`-`F4`, `Shift+F4`, `F5`-`F8`, `F10`, `F11` | verificato file per file |

> Il commento di `core/tuning_profile.gd` dichiara la provenienza dello 0.6: «una notte in 15
> minuti reali (**il valore del prototipo Phaser**)». Il brief però parla di «venti notti di
> storia da **circa un'ora**» e di «sessioni di circa un'ora». Sono due numeri diversi per la
> stessa cosa: vedi le domande aperte.

### Fuori scopo, dichiarato

**Dell'epica 2:** il menu post-foto a quattro voci (2.6) — questa storia deve solo far sì che
l'alba non gli chieda il permesso; il catalogo dei target e `honest_catalog` (2.2); la
sequenza di imaging e il consumo di `min_per_frame` (2.3); lo stacking (2.4); payout, curva a
scaglioni e commesse (2.5); `core/save_manager.gd` e la persistenza (2.7).

**C1 resta chiuso a chiave.** `Game.start_night()` azzera il portafoglio a ogni notte, ed è il
rilievo C1 — **aperto, e da chiudere prima della 2.7**. Questa storia chiama `start_night()`
ma **non «sistema» `autoloads/game.gd` cogliendo l'occasione**: il contenitore per lo stato
che attraversa le notti (`PlayerProfile` o altro) è una decisione di design che vale per
FR31, 2.7 e 3.2 insieme. È la stessa istruzione che aveva la 1.3.

**Dell'epica 3:** cucina, cupola, terminale, moka, lampada, telemetria. `Events.wait_activity_*`
esistono e **non si emettono qui**.

**Il `reason` sul CRT.** La voce «Dopo ENTER il ponte finisce nel vuoto» è stata rinviata
consapevolmente il 2026-08-22, con il proprietario individuato nelle storie 2.4/2.5/2.6.
Questa storia non le dà una casa — ma deve costruire il riepilogo dell'alba, che è lo stesso
terreno: vedi Task 5 e la domanda aperta.

**L'aspetto della stanza.** Geometria e materiali restano un segnaposto in attesa di un pack
di texture.

### Previous Story Intelligence — cosa ha lasciato la 1.3

La 1.3 è `done` dal 2026-08-22, dopo una code review a tre layer: 31 rilievi grezzi, 20 dopo
triage, 16 patch applicate.

- **Il punto d'ingresso è l'unico che può conoscere tutti.** È scritto nell'intestazione di
  `main.gd` come chiusura del rilievo m6, e questa storia ne è l'erede designata.
- **Sospendere non è liberare, e sono due assi.** `_set_phase_running()` separa **ascoltare**
  (segue sempre la postazione) da **girare** (`runs_in_background()` esenta). È il precedente
  che la 2.3 userà per la fase 10.
- **`process_mode` si salva e si ripristina**, non si impone: una fase può aver dichiarato
  `PROCESS_MODE_ALWAYS` e sovrascriverlo la cancella in silenzio.
- **Il punto d'ingresso è sempre ultimo nella propagazione dell'input.** `E` per alzarsi vive
  in `_shortcut_input()`, che gira dopo `_input` e prima di ogni `_unhandled_input`. E
  `_shortcut_input()` **non riceve gli `InputEventAction` sintetici**: chi scrive una sonda
  deve premere l'evento vero dell'`InputMap`.
- **Un errore di configurazione deve fermare chi configura**, non solo loggare:
  `DeskCamera.configure()` restituisce `bool` e il chiamante guarda l'esito. È nato da un
  blocco senza ritorno trovato eseguendo il gioco.
- **Il metodo che ha funzionato:** sonde temporanee create, usate e cancellate nella stessa
  sessione; valori di resa scelti **guardando** e non stimando, catturando PNG dal gioco vero
  con i numeri stampati accanto; e — lezione delle due review — **un commento che promette più
  di quanto il codice mantenga è debito che scade in silenzio**.
- **Trappole già pagate:** i `class_name` nuovi non esistono finché il progetto non viene
  importato (`--headless --path . --import` prima di eseguire); `--check-only --script` non è
  utilizzabile perché non registra gli autoload; un `--import` riordina le sezioni di
  `project.godot` senza cambiare un valore, e quel diff è rumore da scartare.

### Git Intelligence

```
(la 1.3 non è ancora committata al momento della stesura)
e3e3037  Code review della 1.2: il controllo è di uno solo, davvero
9191a2b  Registra: uscire dalla fase la conclude, e rientrando riparte
8b6b2ca  Registra le due tarature rinviate della 1.2
ec5fe38  Chiude la porta della stanza computer
90305ca  Storia 1.2: l'osservatorio esiste, e ci sei dentro
```

Convenzioni osservate: titolo in italiano che dice il **senso** e non il file, nessun prefisso
`feat:`/`fix:`; corpo lungo che argomenta il perché con i numeri dentro; trailer
`Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`; commit tematici; il documento di
storia si aggiorna **nello stesso commit** del codice, insieme a `sprint-status.yaml`.

Rumore da mettere in conto: git avvisa a ogni commit che convertirà LF in CRLF, e le scene
editate a mano verranno riscritte dall'editor al primo salvataggio.

### Project Structure Notes

Questa storia **crea `night/`**, che è la prima cartella nuova dall'inizio del progetto.

```
night/                  ← NUOVA
├── night_session.tscn  ← NUOVO: l'orchestratore
├── night_session.gd    ← NUOVO
└── night_clock.gd      ← NUOVO: l'accumulatore

debug/
└── time_control.gd     ← NUOVO: F1-F4 (nome prescritto dall'architettura)

data/
└── night_plan.tres     ← NUOVO (posizione da decidere: vedi domande aperte)

core/night_run.gd       ← invariato, ma `elapsed_min` smette di essere impalcatura
debug/debug_overlay.gd  ← MODIFICATO: ora, minuti trascorsi, time_scale
main.gd / main.tscn     ← MODIFICATI: cedono l'orchestrazione, tengono la postazione
```

`photo/` e `ui/` restano inesistenti. Convenzioni: file e cartelle `snake_case`, `class_name`
in `PascalCase`, costanti `UPPER_SNAKE_CASE`, membri privati con `_`, la scena con lo stesso
nome dello script.

### Project Context Rules

Da `project-context.md`, le regole che mordono qui:

- **Godot 4.7.2 stable, renderer Compatibility.** GDScript tipizzato. **Nessun codice di
  networking, mai.**
- **Mai liberare un nodo dentro la sua stessa callback.** Transizioni sempre `call_deferred`.
- **`_exit_tree()` non si usa per liberare ciò che si è dato via.** «Costava un crash, e lo
  faceva.»
- **`@onready` si risolve dopo `_ready` dei figli.** Non usarlo per valori che servono in
  `_enter_tree`.
- **`assert()` sparisce nelle build di release.** Per i contratti, mai per logica con effetti
  collaterali.
- **Il `name` di un nodo non è un'identità.** Usare `phase.key()`.
- **Signal** dichiarati e tipizzati, `snake_case` **al passato**: un signal racconta ciò che è
  successo, non ordina.
- **La regola del bus:** se sai chi ascolta ed è uno solo → signal diretto. Se non lo sai, o
  sono più di due → `Events`. «Un bus senza regola diventa una discarica in tre mesi.»
- **I due canali.** `push_error()` con prefisso `[sistema]` per gli errori di programma; il
  `reason` del `PhaseResult` è contenuto, in inglese, e lo legge il giocatore sul CRT.
- **Il tuning si legge da `Tuning`, mai da `load()`.**
- **Nessun `FileAccess` e nessun JSON nel gameplay:** i dati sono `.tres` in `data/`.
- **Performance:** il costo reale sono i `SubViewport`, un render pass ciascuno. Una fase in
  background non fa lavoro pesante per frame.
- **Tono creepy-cozy, mai horror.**

### References

- [epics.md § Story 2.1](../planning-artifacts/epics.md) — i 6 AC, verbatim
- [epics.md § Epic 2](../planning-artifacts/epics.md) — «un anello alla volta alla stessa catena»
- [epics.md § Requirements Inventory](../planning-artifacts/epics.md) — FR1, FR2, FR5, FR6, FR18, FR35 (mappati alla 2.1); FR3, FR4, FR11, FR12, FR13, FR14, FR17, FR30, FR31 (a valle) · UX-DR1, UX-DR5, UX-DR9, UX-DR10 · NFR8, NFR12, NFR13, NFR16, NFR17, NFR22, NFR24
- [game-architecture.md § Directory Structure](../game-architecture.md) — i nomi di `night/`, prescritti alla lettera
- [game-architecture.md § Architectural Boundaries](../game-architecture.md) — la tabella: `night/` non conosce `world/`
- [game-architecture.md § Pattern standard](../game-architecture.md) — i due blocchi normativi dell'orchestratore, e `NightPlan` come dato
- [game-architecture.md § Novel Patterns → Pattern 2](../game-architecture.md) — `NightSession`/`PhaseHost`/`NightClock`, e il `PhaseHost` mai liberato prima dell'alba
- [game-architecture.md § Architectural Decisions → Time](../game-architecture.md) — l'accumulatore, la pausa, `time_scale`
- [game-architecture.md § Cross-cutting Concerns → Debug Tools](../game-architecture.md) — `F1`-`F4`, il mockup dell'overlay, le due lingue
- [game-architecture.md § Configuration](../game-architecture.md) — const contro tuning
- [game-architecture.md § Consistency Rules](../game-architecture.md) — le dieci regole
- [game-architecture.md § ADR-002](../game-architecture.md) — l'orchestratore non sa cosa fanno le fasi
- [implementation-readiness-report-2026-08-21.md § M1](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — l'obbligo di emettere `dawn_reached`, indirizzato a questa storia
- [implementation-readiness-report-2026-08-21.md § M2](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — il riepilogo senza casa, «la decisione con più conseguenze»
- [implementation-readiness-report-2026-08-21.md § C1](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — lo stato che attraversa le notti: **non qui**
- [implementation-readiness-report-2026-08-21.md § m3, m4](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — `PhaseHost` senza proprietario, e la pausa che non esiste
- [deferred-work.md](deferred-work.md) — il re-ingresso che riavvia la fase (questa storia lo chiude per costruzione), `phase_scores` e le chiavi `StringName`, il `reason` senza proprietario
- [1-3-sedersi-al-monitor-e-lavorare-sullo-schermo.md](1-3-sedersi-al-monitor-e-lavorare-sullo-schermo.md) — la storia precedente, l'eredità di `show_control()` e le 16 patch della review
- Repository, letto il 2026-08-22: `main.gd`, `main.tscn`, `core/*`, `autoloads/*`, `debug/*`, `data/tuning.tres`, `phases/polar/*`, `project.godot`

---

## Domande aperte

Non bloccano l'inizio del lavoro, tranne la prima. Vanno risolte **dentro** la storia, e il
dev le porta a Federico quando ci arriva.

1. **Che ore sono** (Task 0). `ora = 21:00 + elapsed_min`, oppure le nove ore si comprimono
   dentro `night_length_min`? **È l'unica che va risolta prima di scrivere codice**, perché
   decide la forma di `night_clock.gd` — e perché la 2.2 costruisce le finestre di visibilità
   dei target sull'ora corrente. E: «21:00» è una `const NIGHT_START_HOUR` o un campo nuovo di
   `TuningProfile`?

2. **Dove vive il riepilogo dell'alba** (Task 5, rilievo M2). Sul CRT diegetico — e allora
   l'alba trascina il giocatore a sedersi, cosa che ADR-003 costruisce come gesto volontario —
   oppure è un'eccezione dichiarata a UX-DR1? E cosa contiene in una storia dove non esistono
   ancora foto, vendite né commesse? Il readiness report la chiama «la decisione con più
   conseguenze sul gioco» fra quelle aperte.

3. **Dove vive `night_session` rispetto a `main.gd`** (Task 3). Figlio della scena principale,
   o nuova radice? `night/` non può conoscere `world/`, ma la coreografia della postazione —
   controller, corpo, camera, rilascio delle azioni — è tutta lì, ed è il risultato di due
   code review. Chi possiede `PhaseHost`? E chi chiama `crt.show_control()`?

4. **La mappatura di `F1`-`F4`** (Task 6). Nessun documento assegna un valore per tasto: solo
   il ×10 è nominato. E va deciso cosa si accetta che acceleri insieme al tempo — perché
   `Engine.time_scale` è globale e tocca la transizione della postazione, la camminata e la
   finestra del punteggio polare, che è in secondi reali.

5. **Due AC non sono verificabili nella propria storia** (rilievo m4). «La pausa ferma il tempo
   davvero» — ma non esiste una pausa: `ui/` è vuoto e nessuna storia la crea. «Si chiude
   anche se è aperto un menu» — ma il menu nasce nella 2.6. Si costruisce una pausa minima
   (riaprendo la voce rinviata su `ESC` che coincide con `ui_cancel`), si verifica dal banco
   con `get_tree().paused`, o si dichiara l'AC parzialmente rinviato con la prova nella 2.6?

6. **`hour_passed` si emette o resta inerte?** È dichiarato in `autoloads/events.gd`, elencato
   dall'architettura fra i fatti da bus, e **nessun AC lo richiede**. Oggi ha zero ascoltatori,
   e la regola del bus dice «più di due ascoltatori». Emetterlo adesso previene il problema
   che M1 descrive per `dawn_reached`; lasciarlo inerte lo aggiunge alla lista dei signal
   dichiarati e mai usati, che è già una voce di `deferred-work.md`.

7. **Come il `payload` diventa il `ctx` della fase successiva.** `Phase.setup(run, ctx)` esiste,
   `PhaseResult.payload` esiste, e **nessuno dei due è mai stato usato**. L'architettura mostra
   `_advance(result, phase)` che chiama `_enter_next(result)`, ma non dice come il payload
   entri nel `_ctx`. La 2.2 ci costruisce sopra (FR12: il target scelto viaggia nel payload).

8. **Cosa succede dopo l'alba.** `economia.md §13` dice «salta al giorno successivo», ma la
   persistenza è la 2.7 ed è bloccata da C1. Si ricomincia la notte 2? Si resta con il
   riepilogo a schermo? E `Game.run` diventa nullo — cosa mostra allora l'overlay F12, che lo
   legge?

9. **Dove vive il `.tres` del `NightPlan`, e come `night_session` lo riceve.** `data/` per la
   regola dei dati di contenuto, o accanto alla scena? `@export var plan: NightPlan` sulla
   scena, o un percorso costante? Nessuna delle due è scritta.

10. **Cosa significa «giocabile» per questa storia.** L'epica promette che «a ogni storia la
    notte è giocabile, semplicemente finisce un po' prima». Ma la 2.1 ha **una sola fase di
    setup e zero fasi di foto**: `photo_phases` è vuoto finché non arrivano 2.2 e 2.3. Cosa fa
    l'orchestratore quando la lista delle foto è vuota — aspetta l'alba? E cosa vede il
    giocatore fra l'`ENTER` che chiude l'allineamento e l'alba?

11. **Il default della notte: 15 minuti o un'ora?** `data/tuning.tres` dà 15 minuti reali
    (`game_min_per_sec = 0.6`, ereditato dal prototipo Phaser); il brief parla di «venti notti
    di storia da circa un'ora». Tre notti di validazione da 15 minuti e tre da un'ora misurano
    cose diverse. Se non si tocca, va detto che 15 è un punto di partenza consapevole.

12. **Se `night_session` eredita le guardie del ponte** o torna allo snippet dell'architettura.
    `result.score` invece di `phase.score()`, la guardia sulla fase stantia, `remove_child()`
    prima di `queue_free()`: sono correzioni di code review che l'architettura non contiene.
    Senza una scelta esplicita, l'orchestratore nuovo regredisce.

13. **`Engine.time_scale` e la misura.** Se a ×10 la finestra del punteggio polare diventa 0,8
    secondi di gioco, un punteggio misurato accelerato non è confrontabile con uno a velocità
    reale. Va scritto — o va deciso che qualcosa non scala.

14. **Una divergenza da dichiarare.** `economia.md §13` prevede che l'esplorazione consumi
    tempo **solo se il giocatore fa cose**; FR6 adotta un accumulatore puro, e il tempo scorre
    anche stando fermi. Per un MVP che misura l'attesa è la scelta giusta — stare fermi *deve*
    costare — ma la divergenza è registrata solo dentro un report di readiness, e questa storia
    è quella che la rende definitiva.

---

## Dev Agent Record

### Agent Model Used

claude-opus-5 (Claude Code, skill `gds-dev-story`)

### Debug Log References

Zero errori e zero warning: `--headless --path . --quit-after 600` esce con le sole tre righe
`INFO` di avvio.

**Sonde temporanee, create, usate e cancellate nella stessa sessione.** `tests/` contiene solo
`test_bench.*`.

- `tests/probe_2_1.*` — 32 verifiche sull'arco intero di una notte, tutte verdi: il piano
  caricato e la fase istanziata dal `.tres` prima che il giocatore tocchi qualcosa, l'ora che
  parte dalle 21:00, il tempo che scorre, **la pausa che lo ferma davvero e lo lascia
  ripartire**, la fase che gira solo da seduti, `ENTER` che registra il punteggio sotto
  `key()`, il piano che si esaurisce e fa rialzare il giocatore, l'alba che arriva da sola,
  `dawn_reached` emesso una volta sola, `hour_passed` lungo tutta la notte, e il riepilogo
  raggiungibile tornando al monitor. Le ore varcate sono `[22, 23, 0, 1, 2, 3, 4, 5, 6]`: la
  notte attraversa la mezzanotte e finisce alle 06:00.
- `tests/capture_2_1.*` — apre il gioco vero e salva tre PNG a 1280×720: la fase servita dal
  piano, il monitor a piano esaurito, e il riepilogo dell'alba letto da seduti.

**Due errori della sonda, entrambi istruttivi.** Il primo: con un ritmo di 1200 minuti al
secondo l'alba arrivava mentre i primi controlli erano ancora in corso e liberava la fase
sotto i piedi del test — la sonda misurava sé stessa invece del gioco. Il secondo:
`SceneTree.process_frame` è emesso **prima** dei `_process`, quindi il controllo «dopo la
pausa il tempo riparte» leggeva un valore non ancora aggiornato e falliva su codice corretto.

**Una sostituzione fallita in silenzio.** Una patch alla sonda cercava un `\n` reale dove il
file aveva i due caratteri letterali, e non trovando il pattern non cambiava nulla — senza
`assert` non se ne accorgeva nessuno, e il ritmo restava quello di prima. Da lì in poi ogni
sostituzione di questa sessione porta il proprio `assert`.

### Completion Notes List

**Le decisioni prese con Federico, e la loro ragione.**

1. **L'ora si ricava per somma diretta: `21:00 + elapsed_min`.** La domanda aperta ipotizzava
   un conflitto — con `night_length_min = 60` l'alba cadrebbe alle 22:00 — ma il conflitto
   nasceva dal presupporre che si accorci la notte con quella manopola. **Le manopole sono
   già due e fanno cose diverse**, e i commenti di `tuning_profile.gd` lo dicevano da sempre:
   `night_length_min` è quanto è lunga la notte *nel mondo* (540 minuti = le nove ore da
   21:00 a 06:00), `game_min_per_sec` è quanto in fretta scorre (0.15 → un'ora reale, 0.6 →
   quindici minuti, 1.8 → cinque). Per tarare l'attesa si gira il ritmo, e l'alba resta alle
   06:00. Nessuna compressione, `elapsed_min` **è** l'ora — ed è anche l'unica lettura
   coerente col mockup normativo dell'overlay, dove `23:41  (elapsed 161 min)` torna solo
   sommando.
2. **`21:00` è una `const NIGHT_START_HOUR`**, con il nome che l'architettura prescrive. Non
   è sola: sta in coppia con `night_length_min = 540`, e girarne una senza l'altra sposta
   l'alba. Un override che potesse farlo in silenzio sarebbe un modo di rompere il gioco
   senza accorgersene.
3. **`night_session` riceve il `CrtScreen` e lo usa.** `main.gd` trova il monitor per gruppo —
   può, è il punto d'ingresso — e lo consegna in `configure()`; da lì è l'orchestratore a
   chiamare `show_control()`, come i blocchi normativi dell'architettura. È l'eredità che la
   1.3 aveva dichiarato chiudendo il rilievo m6. Il confine regge perché `night/` conosce il
   **tipo** `CrtScreen`, che appartiene a `crt/`, e mai la cartella del mondo.
4. **Il riepilogo vive sul CRT**, come tutto il resto: nessuna eccezione a UX-DR1, nessuna
   cartella nuova, la stessa strada delle fasi. Chiude il rilievo M2, aperto dal 2026-08-21.
   Il prezzo è scritto nel file: all'alba il giocatore può essere in cucina, e il riepilogo
   non lo insegue — lo trova tornando al monitor. Trascinarlo alla scrivania romperebbe
   ADR-003, che il sedersi lo costruisce come gesto volontario.
5. **`hour_passed` si emette**, dall'orologio, a ogni ora varcata. Tre righe, e chiude in
   anticipo la metà del rilievo M1 che riguardava la 3.5: chi scriverà la cupola lo troverà
   già emesso invece di dover violare un confine o tornare indietro.

**Due difetti trovati durante il lavoro, e chiusi.**

- **Il giocatore restava seduto davanti al nulla.** Finito l'allineamento il piano non ha
  altre fasi — `photo_phases` è vuoto fino alla 2.2 — quindi l'orchestratore svuotava lo
  schermo. Ma chi fa rialzare il giocatore? Prima era `_advance`, che ora vive in `night/` e
  non sa nulla della postazione. Chiuso con `plan_exhausted`, un signal diretto verso il punto
  d'ingresso: l'orchestratore sa che non c'è più lavoro, il punto d'ingresso sa che qualcuno è
  seduto, e nessuno dei due deve sapere l'altra metà.
- **Il monitor prometteva e non manteneva.** Trovato guardando lo scatto: a piano esaurito il
  prompt «[E] Usa il monitor» restava a schermo su un oggetto che non rispondeva più. È la
  stessa classe di difetto che la review della 1.2 aveva registrato come non raggiungibile, e
  che adesso lo è diventata. Chiuso con `Interactable.enabled`, che era già nel contratto: da
  spento il monitor non mostra il prompt e non risponde. Lo decide il punto d'ingresso, perché
  è l'unico che vede entrambe le sponde.

**Cosa è stato fatto, per task.** Task 0: la decisione dell'orologio, con l'aritmetica delle
due manopole verificata prima di proporla. Task 1: `night/night_clock.gd`, che accumula e
basta — niente `PROCESS_MODE_ALWAYS` (la pausa deve fermarlo) e niente lettura di
`Engine.time_scale` (il motore l'ha già applicato al `delta`, leggerlo lo applicherebbe due
volte). Task 2: `night/night_session.gd` e `night/night_session.tscn` con `PhaseHost` e
`NightClock`, più `data/night_plan.tres`. Task 3: il confine, risolto come sopra. Task 4:
l'alba come secondo ingresso al flusso di controllo, che smonta la fase in corso senza
registrarne l'esito — un allineamento interrotto dall'alba non è un allineamento riuscito.
Task 5: `night/night_summary.gd`. Task 6: `debug/time_control.gd`, `F1` `F2` `F3` `F4` →
×1 ×2 ×5 ×10, con `F1` che riporta sempre alla realtà. Task 7: l'overlay mostra ora, minuti
trascorsi e `time_scale`. Task 8: l'override verificato in esecuzione. Task 9: le verifiche.

**Cosa NON è stato fatto, di proposito.** Nessun menu post-foto (2.6); nessun catalogo di
target (2.2); nessuna sequenza di imaging (2.3); nessun payout (2.5); nessun `save_manager` e
nessuna scrittura su disco (2.7). **`autoloads/game.gd` non è stato toccato**: `start_night()`
azzera ancora il portafoglio a ogni notte, ed è il rilievo C1 — una decisione di design che
vale per FR31, la 2.7 e la 3.2 insieme, e che non si prende di sfuggita da qui. Nessuna
cartella `ui/`, nessun `photo/`, nessun `wait_activity_*` emesso.

**Due cose che il record non diceva, trovate dalla code review del 2026-08-23.**

- **`Game.end_night()` non viene chiamato da nessuno, ed è deliberato.** La Trappola 3 del
  Task 4 avvertiva che `end_night()` fa `run = null` e che `phase_scores[...]` si scrive senza
  guardia: l'ordine fra «chiudi la notte» e «una fase si conclude» andava deciso. La decisione
  è stata prendere la strada che non ha il problema — la notte finisce, ma la `NightRun` resta
  in piedi, perché il riepilogo la legge e l'overlay `F12` pure. Chiuderla davvero è la 2.7,
  che è la storia in cui una notte deve lasciare qualcosa alla successiva (ed è bloccata da
  C1). Fino ad allora `Game.run` non diventa mai nullo, ed è per questo che le scritture senza
  guardia in `night_session.gd` non sono un difetto: è una precondizione, e adesso è scritta.
- **AC3, seconda metà: le fasi di foto NON si rieseguono a ogni scatto, per adesso.**
  `_next_scene()` percorre `photo_phases` una volta sola e `_photo_index` non si riazzera. È
  dichiarato in `night_session.gd`, ma il Change Log qui sotto diceva AC3 soddisfatto senza
  nominarlo. Ciò che riapre il ciclo è il menu post-foto della 2.6, e con `photo_phases` vuoto
  la cosa è oggi inosservabile — ma va detta, perché è metà di un criterio.

**Un limite dichiarato.** L'AC6 chiede che l'override funzioni «su build già esportata».
L'esportazione richiede i template di export, che questa macchina non ha: il meccanismo è
stato verificato eseguendo il gioco vero (non l'editor) con `user://tuning_override.cfg`
scritto a mano — valori applicati, valori non validi rifiutati con un warning, hash del
profilo che cambia da `5842c433` a `ad2db65d`. La metà «su build esportata» resta da provare
la prima volta che se ne farà una.

### File List

- `night/night_clock.gd` — NUOVO: l'accumulatore, `NIGHT_START_HOUR`, `hour_passed`, il signal
  diretto `dawn`.
- `night/night_session.gd` — NUOVO: l'orchestratore, il piano, i punteggi, l'alba,
  `plan_exhausted`.
- `night/night_session.tscn` — NUOVO: `NightSession` con `PhaseHost` e `NightClock`.
- `night/night_summary.gd` — NUOVO: il riepilogo dell'alba, sul CRT.
- `data/night_plan.tres` — NUOVO: una fase di setup (la polare), nessuna fase di foto.
- `debug/time_control.gd` — NUOVO: `F1`-`F4`.
- `main.gd` — MODIFICATO: cede l'orchestrazione, monta la notte, tiene la postazione;
  `current_phase()` delega, `clock()` è nuovo, `_refresh_monitor()` spegne il monitor senza
  lavoro.
- `main.tscn` — MODIFICATO: via `PhaseHost`, che ora vive sotto `NightSession`.
- `debug/debug_overlay.gd` — MODIFICATO: ora, minuti trascorsi, `time_scale`, e la riga di
  aiuto dei nuovi tasti.
- `tests/test_bench.gd` — MODIFICATO: l'aritmetica della notte, collaudata sul `.tres`.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFICATO.
- `_bmad-output/implementation-artifacts/2-1-un-turno-che-comincia-alle-21-00-e-finisce-da-solo-allalba.md`
  — MODIFICATO: questo documento.

### Change Log

| Data | Cosa | Prova |
|---|---|---|
| 2026-08-23 | **`night/` esiste**: `night_session`, `night_clock`, `night_summary`, con i nomi che l'architettura prescrive. Il ponte di `main.gd`, dichiarato temporaneo dalla 1.1, è chiuso. | `grep -rn "world/" night/` → zero |
| 2026-08-23 | Task 0 — l'ora è `21:00 + elapsed_min`. Le due manopole sono distinte: `night_length_min` è la lunghezza della notte nel mondo, `game_min_per_sec` il ritmo con cui la si attraversa. | Banco: alba alle 06:00, 15 minuti reali coi default |
| 2026-08-23 | Il piano della notte è un dato: `data/night_plan.tres`. In `night_session.gd` non compare nessun `preload` di fase né `match` su `key()`. | AC3, rieseguibile con grep |
| 2026-08-23 | L'alba chiude la notte da sola, smonta la fase in corso senza inventarle un punteggio, e mostra il riepilogo sul CRT. **Chiude il rilievo M2.** | Sonda + scatto dal gioco |
| 2026-08-23 | `Events.dawn_reached` e `Events.hour_passed` vengono emessi. **Chiude la metà di M1 che riguardava la 2.1.** | Sonda: `[22, 23, 0, 1, 2, 3, 4, 5, 6]` |
| 2026-08-23 | `F1`-`F4` → ×1 ×2 ×5 ×10 in `debug/time_control.gd`, dietro `OS.is_debug_build()` e con `load()`. I tasti erano stati tenuti liberi dalla 1.1. | FR35, FR37 |
| 2026-08-23 | **`plan_exhausted`**: finito il lavoro il giocatore si rialza da solo, invece di restare seduto davanti a uno schermo vuoto senza controllo. | Sonda; difetto trovato ragionando sul flusso |
| 2026-08-23 | **Il monitor si spegne quando non c'è lavoro** (`Interactable.enabled`): niente più prompt che invita a premere un tasto inerte. | Difetto trovato guardando uno scatto |
| 2026-08-23 | Il banco di collaudo verifica l'aritmetica della notte sul `.tres`: durata, ritmo, ora dell'alba, frame necessari, ore varcate. | `tests/test_bench.tscn` |
| 2026-08-23 | AC4 — `call_deferred` su ogni transizione, punteggi indicizzati con `key()`. | `grep "phase.name"` → zero |
| 2026-08-23 | AC2 della 1.1 — `git diff -- phases/polar/phase_polar.gd` ancora vuoto: l'orchestratore parla `Phase`, non `PhasePolar`. | Rieseguibile |
| 2026-08-23 | Gioco a zero errori e zero warning; i confini delle storie precedenti restano verdi. | `--headless --quit-after 600` |
| 2026-08-23 | **Code review a tre layer.** 21 rilievi grezzi → 4 decisioni prese, 16 patch applicate, 7 rinviati, 2 scartati. | § Review Findings |
| 2026-08-23 | La guardia `was_current` del ponte è tornata: `_dispose()` svuota il vetro solo per conto di chi lo possiede ancora. Senza, `ENTER` premuto nel frame dell'alba staccava dallo schermo il riepilogo appena montato, lasciando il monitor acceso su niente. | Sonda: `_advance` in ritardo, riepilogo ancora al suo posto |
| 2026-08-23 | Il teardown dell'alba passa da `call_deferred` come ogni altra transizione: AC4 adesso è vero alla lettera, e l'alba si mette in fila con la fase che si stesse concludendo invece di scavalcarla. | AC4 |
| 2026-08-23 | Mostrare qualcosa su uno schermo fermo gli concede un frame (`UPDATE_ONCE`). Il riepilogo dell'alba arriva mentre il giocatore è dall'altra parte della casa — cioè quando lo schermo è congelato — e prima compariva solo dopo essersi seduti. | `crt/crt_screen.gd::show_control()` |
| 2026-08-23 | L'alba fissa `elapsed_min` alla soglia invece di lasciarci lo sforamento dell'ultimo frame: a ×10 dopo uno stutter il riepilogo diceva `06:06`. | Sonda: alba a 06:00 con un frame da 60 minuti |
| 2026-08-23 | `hour_passed` annuncia **ogni** confine varcato, non solo l'ultimo del frame. | Sonda: un frame da 210 min emette 22, 23, 00 |
| 2026-08-23 | I tre percorsi di errore smettono di fallire in silenzio: casella vuota nel `.tres`, scena non-`Phase`, e `_begin_night()` che non ripulisce. Il monitor si spegne in ogni uscita anticipata invece di invitare a premere un tasto inerte. | Sonda: casella vuota saltata; monitor spento senza notte |
| 2026-08-23 | AC6 di nuovo verde: il banco legge da `Tuning` e non con `load()` sul `.tres` — e così collauda i numeri veri, override compreso. Confronta anche `NIGHT_START_HOUR` con quella dell'orologio, invece di limitarsi a prometterlo. | `grep -rn "tuning.tres" --include=*.gd .` → solo `autoloads/tuning.gd` |
| 2026-08-23 | `F12` distingue una fase sospesa da una che gira (`SUSP`/`RUN`). Chiude la voce rinviata riaperta dal Task 7. | `debug/debug_overlay.gd` |
| 2026-08-23 | `time_control.gd` non promette più un ×10 che la fisica non dà: `max_physics_steps_per_frame` vale 8 e satura. Tolto anche `scale()`, che era codice morto con una docstring che dichiarava un consumatore inesistente. | `grep -rn "\.scale()"` → zero |
| 2026-08-23 | `grep -rn "phases/" night/` → zero: il confine si tiene anche nei commenti, come già per il mondo. | Rieseguibile |
