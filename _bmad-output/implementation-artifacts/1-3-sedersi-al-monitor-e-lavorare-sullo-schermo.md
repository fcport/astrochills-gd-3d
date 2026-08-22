---
baseline_commit: e3e3037
---

# Story 1.3: Sedersi al monitor e lavorare sullo schermo

Status: done

Story key: `1-3-sedersi-al-monitor-e-lavorare-sullo-schermo`
Epic: 1 — Il primo pezzo di mestiere — l'allineamento polare, e il seam che regge

---

## Story

As a **giocatore**,
I want **avvicinarmi al monitor, sedermi, e fare l'allineamento polare sullo schermo CRT**,
So that **il lavoro succeda dentro il mondo invece che sopra di esso**.

> **Questa storia non costruisce niente di nuovo: cabla ciò che esiste già.** La 1.1 ha fatto
> la fase e il suo `Control`. La 1.2 ha fatto la stanza, il giocatore e il monitor. `crt/`
> era keeper dal primo giorno e nessuno l'ha ancora toccato: `show_control()`, il `Marker3D`
> `Seat`, e `desk_camera.gd` con `TRANSITION := 0.5` e `SEATED_FOV := 42.0` — gli stessi
> numeri che l'AC chiede — **sono già scritti e non li istanzia nessuno**. Il lavoro è
> collegarli, e chiudere ADR-003.

**Perché non è un comfort.** `game-architecture.md § Spike già superati` lo dichiara:
«**ADR-003 non è un comfort, è un requisito di leggibilità.** Senza la transizione alla
scrivania il CRT è visto da lontano: la sua texture viene *rimpicciolita*, con filtro
nearest e senza mipmap, e il risultato è illeggibile. Non è una feature rimandabile.»

**È anche il secondo esercizio del seam.** La 1.1 ha provato che la fase non sa da dove
viene la verità. Questa prova che non sa dove finisce il proprio `Control`: lo stesso
`polar_screen` passa dal CRT povero al CRT vero **senza che `phases/` cambi di una riga**.

---

## Acceptance Criteria

Riportati da `epics.md § Story 1.3`, numerati per riferimento dai task. **Non riscritti.**

### AC1 — La sequenza della postazione, in quest'ordine

**Given** il giocatore davanti al monitor
**When** interagisce con esso
**Then** la sequenza è, nell'ordine: controller del giocatore disabilitato → corpo agganciato al `Marker3D` della postazione → tween della camera di circa mezzo secondo con il FOV che si stringe a 42°
**And** l'input passa al `SubViewport` **solo a interpolazione finita**, mai prima
**And** all'uscita accade l'inverso, e il controller torna attivo solo a transizione conclusa

### AC2 — La proprietà del `Control`

**Given** la fase polare in esecuzione
**When** il suo `Control` viene mostrato sullo schermo
**Then** arriva lì tramite `crt.show_control(...)`, e il CRT **non lo libera mai**
**And** la proprietà resta della fase, che lo libera alla propria distruzione se lo ha dato via — `NOTIFICATION_PREDELETE`, **mai** `_exit_tree()`, che scatta anche su un'uscita temporanea dall'albero e ucciderebbe l'interfaccia di una fase ancora viva (corretto il 2026-08-22 in code review della 1.1)
**And** l'orchestratore — quando esisterà — chiama `show_control(null)` **prima** di liberare la fase

### AC3 — Leggibile da seduti, e solo da seduti

**Given** lo schermo a `256×192`
**When** il giocatore è seduto alla postazione
**Then** il testo tecnico della fase è leggibile, verificato guardando e non stimando
**And** nessuna informazione necessaria alla fase richiede di leggere il CRT da in piedi o da lontano

### AC4 — Il CRT non sa cosa mostra

**Given** le regole di dipendenza
**When** si cerca `phases/` dentro `crt/`
**Then** non c'è nessuna occorrenza: il CRT riceve un `Control` e non sa quale

### AC5 — Alzarsi non è finire

**Given** l'allineamento polare in corso
**When** il giocatore si alza dalla postazione e torna in piedi nella stanza
**Then** la fase non viene interrotta e non viene liberata
**And** al ritorno alla postazione mostra lo stato vero, non uno stato ricostruito

> **Nota di progetto, non requisito.** Alzarsi mentre la deriva si accumula è già, in
> piccolo, l'esperienza che l'epica 3 misurerà: la fase 3 è essa stessa un'attesa. È la
> prima occasione informale per farsi un'idea dell'ipotesi, mesi prima che ci sia la
> telemetria a dirlo.

---

## Tasks / Subtasks

### Task 0 — Il beccheggio del `Seat` guarda dalla parte sbagliata (AC1, AC3)

> **Questo task viene prima perché è l'unico difetto che farebbe fallire l'AC3 per una
> ragione che non c'entra con la risoluzione.** È stato trovato calcolando, non a schermo:
> va deciso qui, non scoperto dopo aver scritto tutto il resto.

`crt/crt_screen.tscn:37` posiziona il `Marker3D` `Seat` con
`Transform3D(1, 0, 0, 0, 0.9799, -0.1994, 0, 0.1994, 0.9799, 0, 0.09, 0.44)`, cioè
**+11,50° attorno a X**. `crt/desk_camera.gd:61` impone alla camera `rotation.x = euler.x`
del seat, quindi **+11,50°**.

In Godot un `rotation.x` positivo **alza** lo sguardo — coerente con
`world/player/player.gd`, dove muovere il mouse in giù *decrementa* `rotation.x`. Ma dal
`Seat` il centro dello schermo sta **sotto**: la direzione dal seat `(0, 0.09, 0.44)` verso
l'origine del vetro è `(0, −0.2004, −0.9797)`, cioè **−11,56°**. **Il modulo è giusto, il
segno no.**

Cosa se ne vede, coi numeri veri (FOV verticale 42°, distanza 0,44 m, vetro alto 0,24 m):

| | gradi rispetto all'orizzonte |
|---|---|
| schermo, dal bordo basso al bordo alto | −26,82 … +3,69 |
| asse della camera com'è adesso (+11,50°), semi-FOV 21° | −9,50 … +32,50 |
| **porzione di schermo effettivamente inquadrata** | **−9,50 … +3,69**, cioè meno della metà superiore |
| asse col segno opposto (−11,50°) | −32,50 … +9,50 → **schermo intero, con margine** |

- [x] Decidere fra le due chiusure, e scriverla dove qualcuno la cercherà:
      **(a)** scambiare i due segni in `crt/crt_screen.tscn:37` — una riga, e il `Marker3D`
      punta finalmente allo schermo; **(b)** ignorare `euler.x` in `desk_camera.gd` e
      calcolare il beccheggio guardando il centro del vetro.
- [x] **La (a) NON sposta la catena delle misure.** L'origine del `Seat` resta
      `(0, 0.09, 0.44)`, che è ciò che la 1.2 dichiara intoccabile: cambia solo dove guarda.
      La (b) invece mette in `crt/` la conoscenza di dove sia il vetro — che il CRT ha
      legittimamente, essendo casa sua.
- [x] **Verifica:** da seduti si vede lo schermo intero, non la sua metà alta. Si guarda,
      non si stima.

### Task 1 — Montare `DeskCamera`, che oggi non esiste in nessun albero (AC1)

`crt/desk_camera.gd` è scritto, è keeper, e `grep -rn "DeskCamera\|desk_camera"` trova
**solo il file stesso e i commenti di `player.gd`**. Nessuno lo istanzia.

- [x] `DeskCamera extends Node` e **non ha un `.tscn`**: va istanziato da codice e
      `add_child`-ato. **Deve stare nell'albero**, altrimenti `create_tween()` restituisce un
      Tween non legato che non avanza mai e la transizione resta appesa per sempre.
- [x] `configure(player, cam, seat)` vuole tre nodi: il corpo, la camera, il `Marker3D`.
      `world/player/player.gd::camera()` esiste apposta per il secondo — è impalcatura
      dichiarata dalla 1.2 — e `crt/crt_screen.gd:11` espone `seat` come membro **pubblico**
      per il terzo.
- [x] **`configure()` non valida niente** e `toggle()` guarda solo `_player`: con `_cam` o
      `_seat` nulli si schianta dentro `_sit()`. Aggiungere le guardie di canale 1
      (`push_error("[crt] ...")`) è lavoro di questa storia, ed è `crt/`, che può farlo senza
      violare nessun confine.
- [x] L'API è tutta qui: `toggle()`, `is_seated`, e i due signal `seated` / `left`, emessi
      **dopo** `await tween.finished`. Sono l'unico aggancio possibile per «solo a
      interpolazione finita».

### Task 2 — Chi orchestra la sequenza, e chiude il rilievo m6 (AC1, AC2)

> Il readiness report lascia aperto un buco che questa storia deve tappare, **m6**: «la 1.3
> non dice **chi** chiama `crt.show_control(...)` prima che `night/` esista. Per i boundary
> non può essere `world/` né `crt/`; resta `main.gd`, ma non è scritto».

- [x] **La risposta è `main.gd`, e va dichiarata nel Change Log.** La tabella dei confini
      dà il permesso a uno solo: `world/` non può conoscere `phases/`, `crt/` non può
      conoscere `phases/`, `phases/` non può conoscere `world/`. Il punto d'ingresso può
      tutto. Quando arriverà `night/`, eredita questo punto di chiamata senza cambiarlo.
- [x] **La sequenza, nell'ordine dell'AC1 e non in un altro:**
      1. `player.set_enabled(false)` — è il primo passo di ADR-003 alla lettera, e la 1.2 lo
         ha già costruito;
      2. `desk.toggle()` — aggancia il corpo e interpola;
      3. su `seated` → l'input entra nel `SubViewport` (Task 4).
      All'uscita l'inverso: input fuori → `desk.toggle()` → su `left` → `set_enabled(true)`.
- [x] **`set_enabled(false)` PRIMA del tween non è ordine estetico.** Alla postazione
      `desk_camera` porta l'origine del corpo a **y = −0,46 m**, sotto il pavimento — è
      corretto, la camera atterra sul `Seat` — e regge **solo** perché da spento
      `Player._physics_process()` esce subito e non simula più fisica. Con il controller
      ancora acceso la depenetrazione risputa fuori il corpo e si porta via la camera. È una
      decisione della code review della 1.2: non disfarla.
- [x] Il ritorno del controllo passa già da `_set_world_active()`, che rilascia le azioni
      con `_release_all_actions()`. **Serve ancora**, e per la stessa ragione: chi si alza
      tenendo premuto `W` per girare la vite partirebbe camminando in avanti.
- [x] **Non rimuovere la guardia `_phase_can_run()`.** In release gli `assert` spariscono, e
      senza quella guardia una fase mal configurata lascia il giocatore senza controllo per
      sempre. Con la postazione il danno è peggiore: sarebbe seduto e cieco.

### Task 3 — Il `Control` sul CRT vero (AC2)

- [x] Sostituire `main.gd::_show()` con `crt.show_control(...)`. `_show()` era dichiarato
      fin dalla 1.1 come mima temporaneo — «Mima `crt/crt_screen.gd::show_control()`, e ne
      eredita la regola» — e la 1.1 aveva scritto che «la storia 1.3 dovrà solo sostituire
      quel viewport con `crt.show_control(...)`». Adesso è quel momento.
- [x] **Il `CrtScreen` si prende per gruppo, non per signal.** `crt/crt_screen.gd` emette
      `Events.screen_registered` nel proprio `_ready()`, e l'albero si costruisce
      profondità-prima: l'emissione avviene **prima** di `Main._ready()`, quindi chi nasce
      lì non la riceve mai. Il ripiego è `CrtMonitor.find_in(get_tree()).screen()`, scritto
      dalla code review della 1.2 esattamente per questo.
- [x] **Smontare `ScreenHost` / `ScreenViewport` da `main.tscn`.** La 1.2 li ha conservati
      deliberatamente — «la fase continua a mostrarsi lì finché la 1.3 non porta il `Control`
      sul CRT vero» — e adesso vanno via, insieme ai due `@onready` che li puntano.
- [x] **`show_control()` rimuove TUTTI i figli del viewport** prima di inserire: il
      `SubViewport` del CRT non è un posto dove parcheggiare altro. Se il Task 5 avrà bisogno
      di parcheggiare qualcosa, non è lì.
- [x] **`c.reparent()` richiede che il `Control` sia già nell'albero.** `show_control()` lo
      gestisce (`if c.get_parent() != null` … `else add_child`), ma è la ragione per cui
      l'ordine `_phase_host.add_child(p)` → `p.screen()` va mantenuto.
- [x] **`set_anchors_preset` è la fragilità che questa storia era destinata a incontrare.**
      `deferred-work.md` la registra da due review: il default `keep_offsets = true`
      **preserva** il rect esistente, quindi funziona solo perché `polar_screen._ready()`
      impone `256×192` a (0,0) e il viewport del CRT è `256×192`. La chiamata che fa ciò che
      il commento intende è `set_anchors_and_offsets_preset`. **Esiste in due posti** —
      `main.gd` (che sparisce con questo task) e `crt/crt_screen.gd`, che è quello che resta.
      Correggerlo qui è una riga e chiude la voce.

### Task 4 — L'input al `SubViewport`, e la clausola dell'AC1 che presume un'architettura diversa (AC1)

> **Da leggere prima di scrivere codice.** L'AC1 dice «l'input passa al `SubViewport` solo a
> interpolazione finita». Nel progetto, oggi, **non c'è input da passare**: la storia 1.1 ha
> messo la gestione dell'input nel nodo `Phase`, non nel `Control`, e l'ha dichiarato —
> «Il `Control` è pura vista e riceve solo `set_readout()`. Così l'instradamento dell'input
> **non passa dal `SubViewport`** — la trappola che `main.gd` dello spike documentava — e la
> cosa continuerà a funzionare quando il `Control` finirà sul CRT.» `polar_screen.gd` non ha
> un solo handler di input.

- [x] **Costruire comunque il cancello, e costruirlo in `crt/`.** La clausola dell'AC resta
      verificabile — «prima di `seated` nessun evento entra nel viewport, dopo sì» — e la
      fase successiva che metterà un `Button` sul CRT lo troverà pronto. Senza, sarà scoperto
      da qualcuno che non saprà perché non funziona.
- [x] **Fatti del motore, misurati su Godot 4.7.2 e non ricordati:**
      - un `SubViewport` **nudo**, cioè non figlio di un `SubViewportContainer`, **non riceve
        niente**: né tasti né mouse. Quello del CRT è figlio di un `Node3D`, quindi è nudo.
        L'unico modo di farci entrare eventi è `Viewport.push_input(event)`.
      - `gui_disable_input = true` blocca tutto — mouse e tasti — ed è l'interruttore più
        pulito: un booleano solo, commutato su `seated` e su `left`.
      - `handle_input_locally = false` (già impostato in `crt_screen.tscn`) fa sì che un
        evento consumato dentro il viewport risulti consumato **anche per il padre**. È il
        motivo per cui il giocatore non camminerà mentre digita.
- [x] La forma consigliata: un metodo in `crt/crt_screen.gd` che non nomini le fasi — per
      esempio `set_input_enabled(bool)` che scrive `gui_disable_input`, e/o un `push(event)`
      che inoltra a `push_input`, chiamato dal punto d'ingresso solo quando `desk.is_seated`.
      **Un accessore nudo al `SubViewport` funzionerebbe ma esporrebbe l'interno di `crt/`.**
- [x] **Non scrivere la catena raycast → UV → evento sintetico.** ADR-003 la rinvia
      esplicitamente, `physics_object_picking` è `false` ovunque, il mouse è catturato e la
      fase polare è interamente da tastiera. «L'upgrade al raycast tocca solo il routing
      dell'input, non il codice delle fasi.»

### Task 5 — Alzarsi senza finire, che è il vero lavoro di questa storia (AC5)

> `deferred-work.md` lo ha registrato dopo la verifica a schermo della 1.2, e ha già scritto
> dov'è la trappola: «tenere viva la fase mentre il giocatore cammina la lascerebbe in
> `_process`, dove `_turn_screws` legge WASD a ogni frame — cioè **riaprirebbe la collisione
> che il Task 0 della 1.2 ha appena chiuso**. Separare «seduto» da «finito» richiede la
> sequenza di ADR-003, che è precisamente la 1.3.»

- [x] **Oggi l'unica uscita dalla fase è `ENTER`, che per contratto la CONCLUDE.** Serve un
      gesto per alzarsi che non emetta `finished` e non liberi niente. `desk.toggle()` esiste
      già ed è simmetrico: manca solo chi lo chiama la seconda volta.
- [x] **Sospendere, non liberare.** La fase resta nell'albero con il suo stato: `_star`,
      `_truth_input` e `_samples` restano dove sono, e al ritorno lo schermo mostra lo stato
      vero senza ricostruire niente — che è la seconda clausola dell'AC5, alla lettera.
- [x] **Fermare `_process` della fase ferma insieme `_turn_screws` e la lettura di WASD.**
      È la leva che chiude la collisione senza toccare `phases/polar/phase_polar.gd`, che non
      deve cambiare di una riga.
- [x] **NON basta sospendere la fase, e questo è il dettaglio che si perde.**
      `phases/polar/polar_screen.gd` ha un `_process` **proprio** — depone un punto di scia
      ogni 0,08 s — e il `Control` vive nel viewport del CRT, **non sotto la fase**: fermare
      la fase non lo ferma. Continuerebbe a deporre punti nella stessa posizione, e «punti
      fitti vuol dire quasi fermo» racconterebbe una bugia mentre il giocatore è in cucina.
      Va sospeso anche lui.
- [x] **`runs_in_background()` è `false` per la polare, e va lasciato `false`.**
      `phase_polar.gd` lo commenta: «È la fase 10 a dover restare viva quando il giocatore se
      ne va, non questa». Sospendere non è girare in background: è restare vivi e fermi.
- [x] **Il re-ingresso non deve riavviare la fase.** Oggi `_on_monitor_interacted` esce se
      `_phase != null`, il che significa che con una fase viva non succede nulla — e con
      questa storia deve invece far *risedere*. È il rovescio della voce «Re-interagire col
      monitor riavvia la fase e sovrascrive il punteggio»: qui il ciclo
      «siediti → alzati → risiediti» diventa il flusso normale, non un caso limite.

### Task 6 — Che sia leggibile davvero (AC3)

- [x] **I numeri dicono che deve funzionare; l'AC chiede di guardare.** Da seduti, a 44 cm
      con FOV verticale 42°, il vetro (0,32 × 0,24 m) occupa il **71% dell'altezza** e il
      **53% della larghezza** del campo visivo: circa **341 × 256 px** dentro il viewport del
      mondo da 640×360. La texture è 256×192, quindi viene **ingrandita di 1,33×** — poi
      raddoppiata dallo `stretch_shrink = 2` verso la finestra. È l'opposto del
      «rimpicciolimento con filtro nearest» che l'architettura indica come causa di
      illeggibilità.
- [x] **`polar_screen.gd` è già disegnato per questa misura** e non va ritoccato senza
      ragione: corpo 12, «circa 34 caratteri prima che la curvatura del CRT se li mangi ai
      bordi. Ogni riga qui sotto sta sotto quella soglia, e non è una coincidenza: è il
      vincolo.»
- [x] **Verificare la seconda clausola, che è quella che si dimentica:** «nessuna
      informazione necessaria alla fase richiede di leggere il CRT da in piedi o da lontano».
      In piedi il CRT deve poter essere illeggibile — è il punto — ma allora niente di
      necessario può stare lì mentre si è in piedi.
- [x] **Nessun corpo minimo, nessuna densità di righe è prescritta in alcun documento.**
      UX-DR5 impone di deciderlo guardando. Quello che si sceglie qui diventa il precedente
      per il terminale gestionale della 3.2, che riusa lo stesso vincolo alla lettera.
- [x] **Non «migliorare la resa» per farlo leggere.** Niente filtro lineare, niente mipmap,
      niente aumento della risoluzione del viewport. Se non si legge, si avvicina la camera o
      si ingrandisce il testo — non si ammorbidisce la texture.

### Task 7 — La decisione su M4, che arriva qui senza proprietario (NFR15)

- [x] `crt/crt_screen.tscn` ha `render_target_update_mode = 4` (`UPDATE_ALWAYS`), contro
      NFR15 — «i `SubViewport` non usano `UPDATE_ALWAYS` per default: ogni schermo CRT è un
      render pass in più, ed è il costo reale del progetto». Il default del motore è `2`
      (`UPDATE_WHEN_VISIBLE`).
- [x] **Nessuna storia lo possiede.** La 1.1 lo ha dichiarato fuori scopo; la 1.2 ha scritto
      «questa storia rende quel render pass un costo reale — **non correggerlo di slancio**».
      Con la 1.3 quel viewport smette di essere un costo sprecato e **diventa la superficie
      di gioco**: è la prima storia che ha una ragione per guardarlo.
- [x] **Decidere, e in entrambi i casi scriverlo.** O si cambia con una ragione dichiarata,
      o si registra in `deferred-work.md` che è stato guardato per la terza volta e perché si
      lascia com'è. Quello che non va fatto è passarlo alla quarta storia in silenzio.

### Task 8 — Le verifiche che gli AC promettono (AC4, e lo standard delle due storie precedenti)

- [x] `grep -rn "phases/" crt/` → **zero occorrenze**. Verde già oggi: va tenuto verde, ed è
      il motivo per cui il Task 4 non può mettere in `crt/` niente che sappia di fasi.
- [x] `grep -rn "world/" crt/` → zero. `crt/` conosce solo `core/`.
- [x] `git diff -- phases/polar/phase_polar.gd` → **vuoto**. È la prova dell'AC2 della 1.1,
      rieseguibile da quando esiste il repository, e questa storia è quella che la mette più
      alla prova: sospendere una fase senza toccarla.
- [x] I tre grep dell'AC4 della 1.2 restano verdi: `phases/`, `night/`, `debug/` dentro
      `world/` → zero. **Anche nei commenti** — è già costato una correzione.
- [x] Nessuna riga riparenta o sposta la camera da sola (AC1 della 1.2). `desk_camera`
      interpola `_player.global_transform` e `_cam.rotation:x`/`fov`, e `_cam.position` la
      **legge soltanto**, per calcolare dove mettere il corpo: `target.origin =
      seat_xf.origin − target.basis * _cam.position`. Leggerla è ciò che lo rende conforme —
      scriverla romperebbe l'AC1 della storia precedente.
- [x] Gioco a **zero errori e zero warning**:
      `Godot_v4.7.2-stable_win64.exe --headless --path . --quit-after 300`.
- [x] `tests/test_bench.tscn` continua a girare pulito. **Non aggiungerci niente:** questa
      storia è camera, scene e input — non c'è logica pura da metterci. Niente GUT, niente
      gdUnit4.

### Review Findings

Code review adversariale del 2026-08-22, tre layer paralleli (Blind Hunter senza contesto,
Edge Case Hunter con lettura del repository ed esecuzione del gioco, Acceptance Auditor con
specifica e documenti). 31 rilievi grezzi, 20 dopo deduplica e triage, 3 scartati come rumore.

**Decisioni da prendere**

- [x] [Review][Decision] **Le viti girano durante la transizione** — `_sit_down()` riprende la fase col gesto, quindi per tutti i 0,5 s del tween `_turn_screws` legge `Input.get_axis()`. `Main._input()` ingoia l'evento, ma il polling non passa dagli eventi: lo stato delle azioni è aggiornato prima della propagazione. Misurato eseguendo il gioco: azimut da 1,4000 a 1,1935 in 0,35 s, con `crt_input=false` e controller spento. Anche `_record()` gira, quindi i secondi della transizione entrano nella finestra del punteggio. Non viola l'AC1 (che vincola l'input *al SubViewport*), ma smentisce «DURANTE LA TRANSIZIONE NESSUNO COMANDA» scritto venti righe sopra. Le strade si escludono a vicenda e hanno conseguenze diverse sulla resa. [main.gd:_sit_down, _input]
- [x] [Review][Decision] **Una fase in background non viene sospesa affatto, quindi resta in ascolto** — `_set_phase_running()` esce subito quando `runs_in_background()` è `true`: né `_process` né `_unhandled_input` si fermano. Un `ENTER` premuto dalla cucina concluderebbe quella fase con il giocatore in piedi, cioè precisamente il difetto che il commento sopra dichiara di chiudere. Oggi irraggiungibile — nessuna fase gira in background — ma è **il precedente che questa storia fissa per la fase 10 dell'epica 3**, ed è rotto nel punto che dichiara di risolvere. [main.gd:_set_phase_running]
- [x] [Review][Decision] **Il CRT senza contenuto non è nero** — `SubViewport` vuoto con `transparent_bg = false` si pulisce con `default_clear_color`, che il progetto non sovrascrive e che vale `(0.3, 0.3, 0.3)`; attraverso lo shader (brightness 1.15, tint verdina) il vetro resta un rettangolo grigio-verde uniforme. Vale dal primo fotogramma della partita e dopo ogni `ENTER`. La voce di `deferred-work.md` lo chiama «schermo nero»: non lo è. È resa, e su questo progetto la resa si decide guardando. [crt/crt_screen.gd:set_live, main.gd:_advance]

**Da correggere**

- [x] [Review][Patch] **`configure()` fallisce in silenzio e il giocatore resta senza controllo** — `configure()` esce con un `push_error` senza impostare niente; `_setup_desk()` non ne guarda l'esito, collega i signal e fa `add_child()` lo stesso, quindi da fuori `_desk != null` e la postazione risulta montata. Alla prima `E`: `_set_world_active(false)` spegne il controller, `toggle()` rifiuta di partire, nessun tween, nessun `seated`, nessun `left`. Il giocatore resta senza movimento, senza testa e senza prompt; `E` ed `ESC` sono inerti perché entrambi i lettori sono spenti. L'unica uscita è `ENTER`, che chiude l'allineamento — un tasto che nessuno ha ragione di provare. È lo stesso blocco senza ritorno che `_phase_can_run()` esiste per impedire, ricreato accanto: la guardia protegge `toggle()` dal crash, non il giocatore dal blocco. **Verificato eseguendo il gioco.** [main.gd:_setup_desk, crt/desk_camera.gd:configure]
- [x] [Review][Patch] **`_on_seated()` non rimette a posto niente, ma il commento dice di sì** — il commento delle «quattro strade» in `_advance()` promette che «il suo `seated` o `left` sta per arrivare, e sarà quello a rimettere le cose a posto». Vale per `left`; `_on_seated()` fa una cosa sola, aprire il cancello dell'input. Se una fase emette `finished` durante la transizione di andata, il giocatore resta seduto, senza controller, davanti a uno schermo svuotato e con l'input del CRT riaperto sul nulla. **Verificato eseguendo il gioco.** Oggi irraggiungibile perché `_input()` ingoia `polar_finish` durante la transizione — ma è esattamente il ramo che il commento dichiara di lasciare scoperto apposta, e la rete che nomina non esiste. [main.gd:_advance, _on_seated]
- [x] [Review][Patch] **`E` per alzarsi va letto in `_shortcut_input()`** — misurato su 4.7.2: la propagazione è in ordine di albero inverso, quindi il punto d'ingresso è **sempre ultimo**, sia in `_input` sia in `_unhandled_input`, perché è l'antenato di `PhaseHost`. Il giorno in cui una fase o un `Control` diegetico dentro il CRT consuma un evento — che è precisamente ciò per cui `crt.push()` è stato scritto — `E` smette di alzare dalla sedia e si ricade nel blocco qui sopra. `_shortcut_input()` gira dopo `_input` e prima di ogni `_unhandled_input`, e nessuna fase lo implementa: il punto d'ingresso vincerebbe per costruzione. [main.gd:_unhandled_input]
- [x] [Review][Patch] **`_input()` ingoia anche F9, F12, ESC e il click** — `set_input_as_handled()` è cieco al tipo di evento: per mezzo secondo a ogni seduta gli strumenti di debug sono sordi, e chi preme F9 non capisce perché non succede niente — proprio nel caso in cui il dubbio non si risolve da solo, visto che dopo l'iniezione la fase *deve* comportarsi identica. Nessuno dei sei paragrafi di commento sopra la funzione nomina questo effetto. **Verificato eseguendo il gioco.** [main.gd:_input]
- [x] [Review][Patch] **`_set_phase_running(true)` sovrascrive `process_mode` invece di ripristinarlo** — impone `PROCESS_MODE_INHERIT`, cancellando qualunque valore esplicito che una fase o il suo `Control` avesse dichiarato: `PROCESS_MODE_ALWAYS` è proprio ciò che dichiarerebbe un'interfaccia che deve sopravvivere alla UI di pausa dell'epica 2, o una fase che deve restare viva. Il primo sedersi la cancella in silenzio, e per una fase in background `_set_phase_running(false)` esce prima, quindi il valore imposto resta per tutta la partita. Sospendere salvando il valore precedente costa due righe. [main.gd:_set_phase_running]
- [x] [Review][Patch] **I due angoli dell'intestazione della scena sono sbagliati di ~1,3°** — «lo schermo va da -26,82° a +3,69°» nasce applicando il semiangolo `atan(0.12/0.44) = 15,2551°` **simmetricamente** attorno alla direzione centrale, cosa lecita solo se il vetro fosse perpendicolare alla linea di vista, e non lo è. I valori veri sono **-25,51° … +3,90°**. La prova che è quell'errore: la media dei due scritti è esattamente -11,5601° e la loro semidifferenza esattamente 15,2551°. **La decisione non cambia, si rafforza**: col segno vecchio si vedeva il 46% dello schermo, col nuovo il 100%. Ma è una giustificazione numerica sbagliata dentro un file di scena, e verrà riletta come verità. Sono numeri ereditati dal Task 0 della storia e ricopiati senza rifarli — la Completion Note dichiara «il calcolo è stato rifatto da zero», ed è vero solo per il segno. [crt/crt_screen.tscn:9-12]
- [x] [Review][Patch] **La documentazione portante di un segno sta in un `.tscn`, che l'editor riscriverà** — il parser tollera i commenti `;` ma nessun salvatore di risorse Godot li conserva: la scena viene rigenerata dallo stato in memoria. Chi apre `crt_screen.tscn`, sposta un nodo e salva cancella l'unico posto dove è scritto perché il `Seat` ha `rotation.x` negativo — e `desk_camera.gd` ci rimanda esplicitamente, lasciando un riferimento pendente. Lo stesso diff, in `deferred-work.md`, documenta che l'editor riscrive proprio questi file. La sostanza va in un `.gd`. [crt/crt_screen.tscn, crt/desk_camera.gd]
- [x] [Review][Patch] **`_enter_phase()` è l'unico punto che dereferenzia `_crt` senza guardia** — tutti gli altri cinque punti sono protetti da `if _crt != null`. O la guardia serve, e qui manca; o non serve, e altrove è rumore che insegna una falsa fragilità. [main.gd:_enter_phase]
- [x] [Review][Patch] **`_connect_monitor()` lascia il signal connesso quando fallisce** — `monitor.interacted.connect()` avviene prima di `_crt = monitor.screen()`: se lo schermo è nullo si esce con un `push_error` ma il collegamento resta, e da lì ogni pressione di `E` produce una riga d'errore. Una diagnosi che dovrebbe apparire una volta all'avvio diventa spam che seppellisce la causa. [main.gd:_connect_monitor]
- [x] [Review][Patch] **Quattro commenti affermano più di quanto il codice mantenga** — (a) «`_input` passa PRIMA di tutti» è vero fra stadi, non dentro lo stadio, dove la radice è ultima; (b) il «frame in più» di `_stand_up()` non cambia un pixel, perché la fase è già sospesa e nessun `queue_redraw()` è stato accodato — è vero solo in `_advance()`, ed è lo stesso commento riusato per due situazioni diverse; (c) «`_draw` NON si ferma» come spiegazione dell'AC5 è incompatibile con `set_live(false)`, che ferma il rendering: ciò che tiene lo stato a schermo è la conservazione del render target; (d) «focus e `ui_accept` funzionano. Misurato su Godot 4.7.2» è una misura che questa sessione non ha fatto, e che `main.gd` contraddice dicendo che nessun `Control` gestisce input. Su questo progetto un commento che promette più del codice è debito che scade in silenzio. [main.gd, crt/crt_screen.gd]
- [x] [Review][Patch] **`set_live()` dimentica in silenzio, `set_input_enabled()` ricorda** — due funzioni gemelle scritte nello stesso diff con trattamenti opposti di una chiamata anticipata: la seconda scrive lo stato prima della guardia e `_ready()` lo recupera, la prima esce e basta. Asimmetria non dichiarata. [crt/crt_screen.gd]
- [x] [Review][Patch] **La voce su `Events.screen_registered` afferma un impossibile che non lo è** — «non ha ascoltatori, **e non può averne**» è falso: gli autoload entrano nell'albero prima della scena principale e riceverebbero l'emissione. La parte vera è l'altra, che chi nasce dentro `main.tscn` è in ritardo. Anche «tutti e tre i consumatori cercano per gruppo» è impreciso. La voce propone implicitamente di rimuovere un signal dichiarato in architettura, sulla base di un'impossibilità che non c'è. [deferred-work.md]
- [x] [Review][Patch] **L'AC1 letterale è stato reinterpretato senza dichiararlo** — l'AC chiede «corpo agganciato al `Marker3D` → *poi* tween della camera»; `desk_camera.gd` usa un solo tween parallelo, quindi corpo e camera arrivano nello stesso istante. È l'unica implementazione compatibile con ADR-003 — agganciare il corpo prima significherebbe staccare la testa — e `desk_camera.gd` è keeper che la storia vieta di riscrivere. Ma nessun documento registra la reinterpretazione, ed è il tipo di clausola secondaria che si perde. [crt/desk_camera.gd:_sit]
- [x] [Review][Patch] **Tre imprecisioni nel documento** — la File List dà il documento di storia come «MODIFICATO» mentre `git status` lo dà come nuovo; il Change Log promette «commenti inclusi» per un grep (`night/`) che con la barra non li guarda — senza barra `world/interactables/crt_monitor.gd` nomina `night_session` in due commenti, preesistenti e non dipendenze; il Task 8 chiede `--quit-after 300` e il Debug Log dichiara 600. [story file]

**Rinviati**

- [x] [Review][Defer] **`_busy` incastrato lascerebbe il gioco sordo per sempre** [main.gd:_input] — rinviato, non raggiungibile oggi
- [x] [Review][Defer] **`_release_all_actions()` gira prima di un `set_enabled()` che può uscire subito** [main.gd:_set_world_active] — rinviato, preesistente alla 1.3
- [x] [Review][Defer] **Gli strumenti di debug non distinguono una fase sospesa da una viva** [debug/debug_overlay.gd, debug/lie_injector.gd] — rinviato, tocca `debug/`, fuori dai file di questa storia

**Scartati come rumore (3)**

L'AC3 verificato senza artefatti riproducibili nel repository (le sonde temporanee sono la
prassi dichiarata dalla 1.2); la tensione fra la «Nota di progetto» dell'AC5 e la sospensione
(la nota è dichiarata non requisito, e il meccanismo per l'altra lettura è
`runs_in_background()`, che il Task 5 ordina di lasciare `false`); `render_target_update_mode = 4`
sul `SubViewport` del mondo in `main.tscn` (NFR15 parla degli schermi CRT, e il viewport del
mondo deve aggiornare sempre — è il gioco).

**Cosa i tre layer hanno verificato e che regge** — il segno del `Seat` (Godot ha parsato la
trasformata: `euler.x = -11,5021°`, forward `(0, -0.1994, -0.9797)`, cioè la direzione dal
sedile al vetro); la sospensione, che ferma davvero tutto (un `Control` con
`PROCESS_MODE_DISABLED` dentro un `SubViewport` non riceve `_gui_input` nemmeno col focus e
`gui_disable_input = false`); `gui_disable_input`, che con `true` impedisce a `push_input()` di
consegnare qualunque cosa; `ENTER` ed `E` nello stesso frame, che si ricompongono; i cinque AC,
tutti soddisfatti; e tutti i vincoli non negoziabili, rieseguiti dall'Auditor invece che letti
dal Change Log.

---

## Dev Notes

### La regola numero uno, in questa storia

Nella 1.1 era ADR-001. Nella 1.2 era il confine di `world/`. Qui è **la proprietà del
`Control`**, e sono due regole che valgono solo insieme:

```gdscript
# in crt/crt_screen.gd — già scritto
for child in _viewport.get_children():
    _viewport.remove_child(child)      # MAI queue_free

# in core/phase.gd — già scritto
func _notification(what: int) -> void:
    if what != NOTIFICATION_PREDELETE: return   # MAI _exit_tree()
```

Il CRT non libera mai ciò che mostra, **e** la fase riprende il proprio `Control` alla
propria distruzione, **e** chi orchestra chiama `show_control(null)` prima di liberare la
fase. Una sola delle tre lascia un `Control` orfano a schermo o una fase viva senza
interfaccia. Sono già tutte e tre nel codice: il compito è non romperle.

**`NOTIFICATION_PREDELETE` è anche ciò che rende possibile l'AC5.** È stato scelto nella
review della 1.1 proprio perché un'uscita temporanea dall'albero non uccida l'interfaccia di
una fase viva. Se il Task 5 sposta o parcheggia nodi, quella scelta lo protegge — e
`core/phase.gd` ha pure la guardia `not is_ancestor_of(s)`, che copre il caso «Control
reparentato dentro il CRT».

### Cosa esiste già e non va riscritto

| File | Cosa contiene | Come si usa qui |
|---|---|---|
| `crt/desk_camera.gd` | `configure(player, cam, seat)`, `toggle()`, `is_seated`, signal `seated`/`left`, `TRANSITION := 0.5`, `SEATED_FOV := 42.0` | **istanziare e configurare**: non lo fa nessuno |
| `crt/crt_screen.gd` | `show_control()` con la regola di proprietà, `viewport_size()`, `seat` pubblico, emissione di `screen_registered` | usare `show_control()`; aggiungere il cancello dell'input |
| `crt/crt_screen.tscn` | `SubViewport` 256×192 `handle_input_locally = false`, `QuadMesh` 0,32×0,24, `Marker3D` `Seat`, shader tarato | il `Seat` ha il beccheggio invertito — Task 0 |
| `core/phase.gd` | il contratto, `screen()`, `runs_in_background()`, `_notification(PREDELETE)` | non toccare |
| `phases/polar/*` | la fase e la sua vista, disegnata per 256×192 | **non toccare: `phase_polar.gd` è la prova dell'AC2 della 1.1** |
| `world/player/player.gd` | `set_enabled()`, `camera()`, `Player.find_in()`, fisica ferma da spento | `camera()` è impalcatura fatta per questa storia |
| `world/interactables/crt_monitor.gd` | `CrtMonitor.find_in()`, `screen()`, il signal `interacted` | è così che `main.gd` raggiunge il CRT |
| `main.gd` | `_show()` (da sostituire), `_set_world_active()`, `_dispose()`, `_release_all_actions()`, `_phase_can_run()` | il ponte diventa la cosa vera |

### Le tre trappole di Godot che questa storia incontra per forza

**1. `create_tween()` fuori dall'albero non avanza.** `DeskCamera` è un `Node` senza scena e
oggi non è figlio di nessuno. Istanziarlo e non aggiungerlo all'albero produce una
transizione che parte e non finisce mai — e siccome `seated` è emesso dopo
`await t.finished`, il giocatore resterebbe seduto, senza controllo e senza input.

**2. Un `SubViewport` nudo non riceve input.** Quello del CRT è figlio di un `Node3D`, non
di un `SubViewportContainer`: nessun evento ci arriva da solo. Misurato, non ricordato.

**3. `Input.get_axis()` non passa da nessun viewport.** `phase_polar.gd` legge le viti con
polling globale. Instradare l'input al `SubViewport` **non impedisce alla fase di leggere
WASD**: ciò che separa davvero i due comandi è `Player.set_enabled(false)` più
`_release_all_actions()`, e per l'AC5 sospendere `_process`. Chi si aspetta che il routing
dell'input risolva la collisione perderà mezza giornata.

### Le misure, e quali non si possono toccare

| Misura | Valore | Chi la fissa |
|---|---|---|
| Altezza occhi in piedi | 1,65 m | `Player.EYE_HEIGHT`, verificata contro `player.tscn` |
| Piano della scrivania | 0,75 m | `computer_room.tscn` |
| Centro dello schermo CRT | 1,10 m | `observatory.tscn`, monitor a `(0, 0.75, −2.05)` |
| `Seat`, locale al vetro | `(0, 0.09, 0.44)`, pitch +11,50° | `crt_screen.tscn` — **l'origine è intoccabile, il pitch è il Task 0** |
| `Seat`, globale | `(0, 1.19, −1.419)` | derivata |
| **Origine del corpo da seduto** | **`(0, −0.46, −1.419)`** | `desk_camera.gd:57` — sotto il pavimento, ed è corretto |
| Gioco fra corpo seduto e scrivania | 3 cm | scelto nella review della 1.2 spostando il monitor a z = −2,05 |
| Vetro del CRT | 0,32 × 0,24 m | `crt_screen.tscn` — misura reale, non si tocca |
| Viewport del CRT | 256×192 | `crt_screen.tscn` — sotto questa soglia il testo non si legge |
| Viewport del mondo | 640×360 | `stretch_shrink = 2` su 1280×720 |
| Transizione | 0,5 s, FOV 42° | `desk_camera.gd` — combaciano con UX-DR6 |

> **Il `Seat` è già posizionato e nessuno può spostarlo senza rompere questa storia.** La 1.2
> lo ha scritto quando ancora non serviva. Adesso serve.

### Fuori scopo, dichiarato

**Dell'epica 2:** orchestratore `night/`, `NightClock`, `NightPlan`, alba, menu post-foto,
`save_manager.gd`, persistenza. `night/` non esiste e non lo crea questa storia: il punto
d'ingresso resta `main.gd`. **Non «sistemare» `game.gd` cogliendo l'occasione** — C1 è
aperto e blocca la 2.7. I tasti `F1`-`F4` sono riservati a FR35: non occuparli **nemmeno per
poco**. `F9`/`F12` sono dell'iniettore e dell'overlay.

**Dell'epica 3:** cucina e cupola, terminale gestionale, moka, lampada, cupola che insegue,
telemetria. `Events.wait_activity_started`/`_ended` esistono già, ma sedersi **non è**
un'attività dell'attesa: non emetterli.

**Il raycast sul mesh** — ADR-003 lo rinvia esplicitamente, e dichiara perché il rinvio è
accettabile: «l'upgrade tocca solo il routing dell'input, non il codice delle fasi».

**L'aspetto della stanza.** Geometria e materiali sono un segnaposto in attesa di un pack di
texture: si corregge solo ciò che ha conseguenze funzionali — un collider che non copre il
suo oggetto, una misura che ne vincola un'altra — non ciò che riguarda l'aspetto.

**Le altre sette fasi, le rotture e le anomalie:** il seam esiste, le bugie no.

### Se dopo `ENTER` lo schermo resta acceso e non succede niente

`deferred-work.md` registra dalla 1.1: «Dopo ENTER il ponte finisce nel vuoto: schermo nero,
nessun riscontro, il `reason` non lo vede nessuno. *Si chiude con la storia 1.3.*»

**Questa è quella storia**, e vale la pena sapere perché la voce esiste: `reason` è il
canale 2, quello che legge il giocatore, e finora non aveva una superficie su cui essere
letto. Adesso ce l'ha. Non è un AC — nessun criterio lo chiede — ma è il momento in cui
diventa possibile, e chiudere o rinviare quella voce è una scelta da fare consapevolmente.

### Previous Story Intelligence — cosa ha lasciato la 1.2

La 1.2 è `done` dal 2026-08-22, dopo una code review a tre layer che ha prodotto 25
correzioni su 33 rilievi.

- **`baseline_commit: e3e3037`.** La prova dell'AC2 della 1.1 resta
  `git diff -- phases/polar/phase_polar.gd`, e resta vuota.
- **Il controllo è di uno solo alla volta, e i tasti fisici non seguono il controllo.**
  `set_enabled(false)` spegne il lettore del giocatore, non lo stato della tastiera: per
  questo ogni scambio chiama `_release_all_actions()`, che itera l'`InputMap` invece di
  ricopiare i nomi delle azioni polari.
- **Da spento il giocatore non simula fisica.** È ciò che rende possibile agganciare il
  corpo al `Seat` sotto il pavimento. Non disfarlo.
- **Le fasi escono dall'albero con `remove_child()` prima di `queue_free()`**, perché
  `queue_free` è differita e lascerebbe la fase viva e in ascolto per il resto del frame.
- **Chi arriva tardi cerca per gruppo, non aspetta un annuncio.** `CrtMonitor.find_in()` e
  `Player.find_in()`; `Events.screen_registered` è già passato quando `main._ready()` gira.
- **I layer di collisione hanno un nome** in `project.godot` e costanti in `Interactable`.
- **La sedia della stanza non ha collisione, ed è deliberato:** sta dove questa storia farà
  sedere il giocatore, e un corpo solido lì davanti impedirebbe di avvicinarsi al monitor.
- **Il metodo che ha funzionato:** valori scelti guardando lo schermo, non stimati; commenti
  che spiegano *perché* e non *cosa*; sonde temporanee create, usate e cancellate nella
  stessa sessione; e — lezione delle due review — **un commento che promette più di quanto
  il codice mantenga è debito che scade in silenzio**.
- **Trappole già pagate:** i `class_name` nuovi non esistono finché il progetto non viene
  importato (`--headless --path . --import` prima di eseguire, altrimenti `Parse Error`);
  `--check-only --script` **non è utilizzabile** su questo progetto perché non registra gli
  autoload; `RayCast3D` ha bisogno di qualche frame per riflettere una trasformata cambiata a
  mano.

### Git Intelligence

```
e3e3037  Code review della 1.2: il controllo è di uno solo, davvero   ← baseline
9191a2b  Registra: uscire dalla fase la conclude, e rientrando riparte
8b6b2ca  Registra le due tarature rinviate della 1.2
ec5fe38  Chiude la porta della stanza computer
90305ca  Storia 1.2: l'osservatorio esiste, e ci sei dentro
```

Convenzioni osservate: titolo in italiano che dice il **senso** e non il file, nessun
prefisso `feat:`/`fix:`; corpo lungo che argomenta il perché con i numeri dentro; trailer
`Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`; commit tematici, anche solo per
registrare una voce rinviata; il documento di storia si aggiorna **nello stesso commit** del
codice, insieme a `sprint-status.yaml`.

Rumore da mettere in conto: git avvisa a ogni commit che convertirà LF in CRLF (nessuno ha
ancora deciso un `.gitattributes`), e le scene editate a mano verranno riscritte dall'editor
al primo salvataggio, gonfiando il diff.

### Project Structure Notes

Questa storia **non crea cartelle nuove**. `night/`, `photo/`, `ui/` restano inesistenti.

```
crt/
├── crt_screen.gd       ← MODIFICATO: cancello dell'input, set_anchors_and_offsets_preset,
│                          guardie di canale 1
├── crt_screen.tscn     ← MODIFICATO (Task 0): il beccheggio del Seat
└── desk_camera.gd      ← MODIFICATO: guardie su _cam/_seat

main.gd                 ← MODIFICATO: la sequenza di ADR-003, show_control al posto di _show,
                           alzarsi senza finire
main.tscn               ← MODIFICATO: via ScreenHost/ScreenViewport
```

Convenzioni: file e cartelle `snake_case`, `class_name` in `PascalCase`, costanti
`UPPER_SNAKE_CASE`, membri privati con `_`, la scena con lo stesso nome dello script.

### Project Context Rules

Da `project-context.md`, le regole che mordono qui:

- **Godot 4.7.2 stable, renderer Compatibility.** GDScript tipizzato. **Nessun codice di
  networking, mai.**
- **Compatibility non supporta** `CompositorEffect`, compute shader, `RenderingDevice`,
  SSR/SSIL/SDFGI/VoxelGI, fog volumetrica, depth of field, decal, tutti gli AA post-process.
  **Non cercare workaround.**
- **L'istinto di «migliorare la resa» è l'errore più frequente su questo progetto.** Filtro
  nearest, nessuna mipmap, nessun AA: l'aliasing crudo **è** il look.
- **`reparent()` trasferisce la proprietà.** Dopo che un `Control` è entrato nel
  `SubViewport` del CRT, liberare la fase non lo libera.
- **Mai liberare un nodo dentro la sua stessa callback.** Transizioni sempre `call_deferred`.
- **`@onready` si risolve dopo `_ready` dei figli.** Non usarlo per valori che servono in
  `_enter_tree`.
- **`assert()` sparisce nelle build di release.** Per i contratti, mai per logica con
  effetti collaterali.
- **Il `name` di un nodo non è un'identità.** Usare `phase.key()`.
- **Signal** dichiarati e tipizzati, `snake_case` **al passato**.
- **I due canali.** `push_error()` con prefisso `[sistema]` per gli errori di programma; il
  `reason` del `PhaseResult` è contenuto, lo legge il giocatore sul CRT, ed è in inglese. Al
  giocatore non si mostrano mai stack trace, codici di errore o modali bloccanti.
- **Performance:** il costo reale sono i `SubViewport`, un render pass ciascuno.
- **Tono creepy-cozy, mai horror.**

### References

- [epics.md § Story 1.3](../planning-artifacts/epics.md) — i 5 AC, verbatim
- [epics.md § Epic 1](../planning-artifacts/epics.md) — obiettivo: «seduto al monitor CRT»
- [epics.md § Requirements Inventory](../planning-artifacts/epics.md) — FR25 · UX-DR1, UX-DR2, UX-DR5, UX-DR6 · NFR3, NFR4, NFR8, NFR14, NFR15, NFR16, NFR20, NFR21
- [game-architecture.md § ADR-003](../game-architecture.md) — la sequenza, e perché il raycast è rinviato
- [game-architecture.md § Architectural Boundaries](../game-architecture.md) — la tabella: `crt/` conosce solo `core/`; il punto d'ingresso conosce tutto
- [game-architecture.md § Pattern 3 — Lo schermo diegetico](../game-architecture.md) — `show_control()` e le due regole di proprietà
- [game-architecture.md § Consistency Rules](../game-architecture.md) — «il CRT non libera mai», «`show_control(null)` prima di liberare»
- [game-architecture.md § Spike già superati](../game-architecture.md) — ADR-003 è un requisito di leggibilità
- [project-context.md](../project-context.md) — regole critiche, anti-pattern, valori PS1 validati
- [implementation-readiness-report-2026-08-21.md § m6](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — chi chiama `show_control()`, **da chiudere qui**
- [implementation-readiness-report-2026-08-21.md § M4](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — `UPDATE_ALWAYS`, senza proprietario
- [deferred-work.md](deferred-work.md) — `set_anchors_preset`, il ponte che finisce nel vuoto, alzarsi senza finire
- [1-2-losservatorio-esiste-e-ci-sei-dentro.md](1-2-losservatorio-esiste-e-ci-sei-dentro.md) — la storia precedente, la catena delle misure e i 33 rilievi della review
- [1-1-lallineamento-polare-e-la-prova-che-il-seam-regge.md](1-1-lallineamento-polare-e-la-prova-che-il-seam-regge.md) — `NOTIFICATION_PREDELETE`, il ponte dichiarato temporaneo
- [idea.md §12](../../docs/idea/idea.md) — «Ti avvicini, la camera si aggancia allo schermo, leggi» *(la formulazione creativa; in caso di conflitto vale ADR-003: si aggancia il corpo, la camera è la testa)*
- [minigiochi.md § 3](../../docs/idea/minigiochi.md) — la polare è «il più lungo e meditativo», pensato per stabilire il ritmo della notte
- Repository, letto il 2026-08-22: `crt/*`, `core/phase.gd`, `main.gd`, `main.tscn`, `phases/polar/*`, `world/player/player.gd`, `world/interactables/crt_monitor.gd`, `project.godot`
- Sonde su Godot 4.7.2 headless, eseguite il 2026-08-22 per misurare il comportamento dell'input nei `SubViewport` — i risultati sono nel Task 4 e nelle Dev Notes

---

## Domande aperte

Non bloccano l'inizio del lavoro. Vanno risolte **dentro** la storia, e il dev le porta a
Federico quando ci arriva.

1. **Il beccheggio del `Seat`** (Task 0). Correggere il `Marker3D` o ignorare `euler.x` in
   `desk_camera`? La prima è una riga e lascia il marker onesto — punta dove si guarda; la
   seconda mette in `crt/` il calcolo di dove sia il proprio vetro, cosa che ha diritto di
   sapere. **È l'unica delle domande che va risolta prima di scrivere il resto**, perché
   decide se l'AC3 è verificabile.

2. **Il gesto per alzarsi.** `E` di nuovo? `ESC`? Un tasto proprio? `E` è simmetrico e non
   aggiunge niente da imparare, ma `ESC` è già `ui_release_mouse` e da seduti il cursore non
   serve. Nessun documento lo prescrive. Vale anche la domanda se il CRT debba dirlo: il
   footer della fase scrive già «WASD TURN SCREWS ENTER DONE», e da seduti c'è spazio per una
   riga in più — ma quel file è `polar_screen.gd`, e cambiarlo è cambiare la vista di una
   fase per una ragione di orchestrazione.

3. **Come si sospende la fase** (Task 5). `set_process(false)` sul nodo `Phase`, o
   `process_mode`, o togliere la fase dall'albero? Le tre hanno conseguenze diverse su
   `_unhandled_input` e sul `Control`, che vive altrove e ha un `_process` proprio. Serve una
   forma sola, scritta dove si vede, perché la fase 10 dell'epica 3 dovrà fare l'opposto
   (restare viva **e** girare) e le due cose non devono confondersi.

4. **M4, `UPDATE_ALWAYS`** (Task 7). Da chiudere o da rinviare per la terza volta con una
   ragione. Con il CRT diventato superficie di gioco, «aggiorna sempre» potrebbe essere
   improvvisamente la scelta giusta — e allora NFR15 va annotato, non violato in silenzio.

5. **Il `reason` del `PhaseResult` adesso ha una superficie.** Mostrarlo sul CRT dopo `ENTER`
   chiuderebbe la voce «il ponte finisce nel vuoto». Nessun AC lo chiede, ed è il genere di
   cosa che l'epica 2 farebbe meglio — ma è la prima volta che è possibile, e vale la pena
   decidere consapevolmente invece di lasciarlo cadere.

---

## Dev Agent Record

### Agent Model Used

claude-opus-5 (Claude Code, skill `gds-dev-story`)

### Debug Log References

Nessun errore e nessun warning a fine lavoro:
`Godot_v4.7.2-stable_win64.exe --headless --path . --quit-after 600` esce pulito, con le sole
tre righe `INFO` di avvio. Il Task 8 ne chiede 300: si è girato più a lungo, non meno.

**Sonde temporanee, create, usate e cancellate nella stessa sessione.** Non sono entrate nel
repository: `tests/` contiene solo `test_bench.*`.

- `tests/probe_1_3.*` — 48 verifiche sulla sequenza, tutte verdi: stato iniziale, controllo
  tolto PRIMA del tween, input aperto SOLO su `seated`, **`ENTER` ed `E` inerti a metà
  transizione**, misure da seduti (corpo `(0, -0.46, -1.419)`, occhio a 1,19 m, beccheggio
  -11,50°, FOV 42,0), fase e `Control` sospesi all'alzarsi, stato che non avanza mentre si
  cammina, `ENTER` inerte da in piedi, stessa istanza di fase al rientro, `ENTER` da seduti
  che conclude e restituisce il controllo. In un giro separato, anche i tre controlli su
  `set_live()`: schermo non vivo all'avvio, vivo col gesto, fermato all'alzarsi.
- `tests/probe_cycle.*` — 5 cicli «siediti, alzati» di fila: sempre la stessa istanza di
  fase, occhio a 1,650 m e FOV 75,0 ogni volta che si torna in piedi, controllo restituito
  5 volte su 5. Serviva a escludere un'intermittenza sospettata da un primo scatto anomalo,
  che si è rivelato un artefatto della cattura e non del gioco.
- `tests/capture_1_3.*` — apre il gioco davvero e salva sei PNG a 1280x720, stampando a ogni
  scatto posizione del corpo, quota dell'occhio, beccheggio, FOV e `is_seated`, così che
  l'immagine e i numeri si controllino a vicenda.

### Completion Notes List

**Le cinque domande aperte, chiuse con Federico il 2026-08-22.**

1. **Beccheggio del `Seat`: chiusura (a).** Segni scambiati in `crt/crt_screen.tscn`; il
   `Marker3D` punta al vetro e `desk_camera.gd` non cambia nel modo in cui lo legge.
   L'origine `(0, 0.09, 0.44)` non si è mossa. Il calcolo è stato rifatto da zero prima di
   proporre la scelta: la basis nel `.tscn` è serializzata **per righe**, quindi
   `cos = 0.9799` con `sin = +0.1994` è davvero +11,50°, mentre la direzione sedile-vetro è
   -11,56°. Verificato guardando: da seduti si vede lo schermo intero, con margine.
2. **Gesto per alzarsi: `E`**, lo stesso con cui ci si siede. Nessuna azione nuova
   nell'`InputMap`, nessuna collisione, e una simmetria che non chiede di imparare niente.
   Lo legge `main.gd`, perché da seduti il controller del giocatore è spento. `ESC` è stato
   scartato: la review della 1.2 ha già registrato che collide con `ui_cancel` e con la UI
   di pausa dell'epica 2, e «annulla» è il contrario di quel che alzarsi fa. La scopribilità
   del gesto è registrata in `deferred-work.md`, con la ragione per cui non si risolve
   toccando `polar_screen.gd`.
3. **Sospensione: `process_mode = PROCESS_MODE_DISABLED`, sulla fase E sul `Control`.** Un
   interruttore solo, che ferma `_process`, `_physics_process` e `_unhandled_input` insieme;
   `_draw` resta, quindi lo schermo continua a mostrare lo stato vero, congelato.
   `runs_in_background()` è la clausola di esenzione, ed è **il precedente per la fase 10
   dell'epica 3**, che dovrà fare l'opposto: restare viva *e* girare. La forma vive tutta in
   `main.gd::_set_phase_running()`, commentata lì.
4. **M4, `UPDATE_ALWAYS`: chiuso legandolo alla postazione.** `CrtScreen.set_live()` mette
   `UPDATE_ALWAYS` da seduti e `UPDATE_ONCE` altrimenti. Spento è `ONCE` e non `DISABLED`
   perché concede ancora un frame: senza, uno `show_control(null)` seguito da
   `set_live(false)` lascerebbe a video l'interfaccia di una fase già liberata. Il valore
   scritto a mano è uscito da `crt_screen.tscn`, così la sorgente di verità è una sola.
   Verificato guardando che fermare il rendering **congela** il monitor e non lo annerisce.
5. **`reason` sul CRT: no, e scritto perché.** La superficie ora esiste, il proprietario no:
   lo schermo di esito lo disegnano le storie 2.4, 2.5 e 2.6. La voce di `deferred-work.md`
   è stata aggiornata da «manca la superficie» a «manca chi ci scriva».

**Cosa è stato fatto, per task.**

- **Task 0** — un segno scambiato nella scena, e il perché scritto in due posti: in testa a
  `crt_screen.tscn`, dove si guarda la scena, e accanto a `euler.x` in `desk_camera.gd`,
  dove quel numero viene letto.
- **Task 1** — `DeskCamera` istanziata, configurata e **aggiunta all'albero** da `main.gd`.
  `configure()` valida tutti e tre i nodi e non ne accetta mezzi; `toggle()` rifiuta di
  partire se la configurazione manca o se il nodo è orfano — è la trappola del
  `create_tween()` che non avanza, e la guardia la nomina per esteso.
- **Task 2** — rilievo **m6 chiuso**: chi chiama `crt.show_control()` è `main.gd`, e la
  ragione è dichiarata nella sua intestazione (la tabella dei confini dà il permesso a uno
  solo). La sequenza rispetta l'ordine dell'AC1; `set_enabled(false)` resta prima del tween;
  `_release_all_actions()` e `_phase_can_run()` sono intatti.
- **Task 3** — `_show()` sostituito da `crt.show_control()`; `ScreenHost` e `ScreenViewport`
  smontati da `main.tscn` insieme ai due `@onready`; il `CrtScreen` si prende per gruppo;
  `set_anchors_and_offsets_preset` chiude la voce di `deferred-work.md`.
- **Task 4** — il cancello vive in `crt/`: `set_input_enabled()` scrive `gui_disable_input`,
  `push()` inoltra a `push_input()` perché un `SubViewport` nudo non riceve niente. `main.gd`
  bussa solo da seduti. Gli eventi del **mouse non passano**: le loro coordinate non hanno
  relazione col vetro finché non arriva il raycast che ADR-003 rinvia, e un puntatore che si
  muove a caso è peggio di nessun puntatore. Nessuna riga di `crt/` nomina le fasi.
- **Task 5** — vedi la domanda 3. Lo schermo torna vivo e la fase riprende **col gesto**,
  mentre l'input aspetta `seated`: l'AC1 vincola l'input, e far aspettare anche la resa
  avrebbe significato guardare la transizione su un fermo immagine.
- **Task 6** — verificato **guardando**: sei scatti a 1280x720 presi dal gioco vero. Da
  seduti header, viti, reticolo, scia, stato e footer sono tutti nitidi e nessuna riga è
  tagliata; da in piedi il CRT è verde e illeggibile, che è il punto, e l'unica cosa
  necessaria in piedi è il prompt «[E] Usa il monitor», che è un HUD e non sta sul CRT.
  Nessun valore di `polar_screen.gd` è stato toccato: il corpo 12 su 256 px regge alla
  misura vera.
- **Task 7** — vedi la domanda 4.
- **Task 8** — tutte verdi, vedi il Change Log.

**Un blocco senza ritorno, trovato ragionando sul flusso e chiuso.** La fase riprende **col
gesto**, quindi nei mezzi secondi in cui la camera scivola verso la postazione è già viva e
già in ascolto: un `ENTER` premuto lì dentro la concludeva mentre il tween stava ancora
andando. `_advance()` trovava una postazione né in piedi né seduta, restituiva il controllo a
metà corsa — con il tween che continuava a trascinare il corpo e la fisica riaccesa che lo
risputava fuori — e alla fine `is_seated` restava `true` con il giocatore in piedi. Da lì il
monitor non rispondeva più, perché `_sit_down()` esce subito quando si crede già seduto: né
un tasto per uscirne, né un errore da nessuna parte. Chiuso in due punti:
`main.gd::_input()` ingoia gli eventi finché `DeskCamera.is_busy()` — in `_input` e non in
`_unhandled_input`, perché la propagazione parte dai nodi più profondi e la fase leggerebbe
`ENTER` per prima — e `_advance()` ha adesso quattro strade invece di due, così il controllo
torna una volta sola e mai a un corpo che un tween sta ancora muovendo. È la lettura più
fedele di ADR-003: «l'input passa solo a interpolazione finita» vale per il `SubViewport` e
non c'è ragione perché non valga per il resto.

**Una clausola dell'AC1 è stata reinterpretata, e va detto.** L'AC chiede «corpo agganciato
al `Marker3D` della postazione → tween della camera di circa mezzo secondo»: letto alla
lettera sono due passi in sequenza. `crt/desk_camera.gd` usa un solo tween parallelo, quindi
corpo e camera arrivano nello stesso istante. È l'unica forma compatibile con ADR-003 —
agganciare il corpo prima significherebbe staccare la testa dal corpo per mezzo secondo,
cioè rompere «la camera È la testa» — e `desk_camera.gd` è keeper, che il Task 1 chiede di
istanziare e non di riscrivere. Il Task 2 collassa infatti i due passi in «`desk.toggle()` —
aggancia il corpo e interpola». Registrato qui perché la reinterpretazione non resti
implicita: è il tipo di clausola secondaria che si perde. *(Rilievo dell'Acceptance Auditor,
code review del 2026-08-22.)*

**Cosa NON è stato fatto, di proposito.** Nessun raycast sul mesh; nessun ritocco alla resa
(niente filtro lineare, niente mipmap, niente risoluzione più alta); nessuna riga in
`phases/`; nessuna cartella nuova; nessuna aggiunta a `tests/test_bench.tscn`, che per
questa storia non ha logica pura da ospitare; nessun tasto `F1`-`F4` occupato.

### File List

- `crt/crt_screen.tscn` — MODIFICATO: beccheggio del `Seat` corretto (Task 0), rimosso il
  `render_target_update_mode` scritto a mano (M4), intestazione con le due ragioni.
- `crt/crt_screen.gd` — MODIFICATO: cancello dell'input (`set_input_enabled`,
  `is_input_enabled`, `push`), `set_live()` per M4, `set_anchors_and_offsets_preset`, stato
  iniziale dichiarato in `_ready()`.
- `crt/desk_camera.gd` — MODIFICATO: guardie su `configure()` e `toggle()` (nodi mancanti,
  nodo fuori dall'albero), `is_busy()`, nota sul perché il beccheggio viene dal marker.
- `main.gd` — MODIFICATO: la sequenza di ADR-003, `show_control()` al posto di `_show()`,
  `_setup_desk()`, `_sit_down()` / `_stand_up()` / `_on_seated()` / `_on_left()`,
  `_set_phase_running()`, `_unhandled_input()` per `E` e per l'inoltro al CRT, `_input()` che
  ingoia gli eventi durante la transizione.
- `main.tscn` — MODIFICATO: rimossi `ScreenHost` e `ScreenViewport`.
- `_bmad-output/implementation-artifacts/deferred-work.md` — MODIFICATO: due voci chiuse,
  due aggiornate, tre nuove.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFICATO: stato della storia.
- `_bmad-output/implementation-artifacts/1-3-sedersi-al-monitor-e-lavorare-sullo-schermo.md`
  — NUOVO (mai committato prima): questo documento.

### Change Log

| Data | Cosa | Prova |
|---|---|---|
| 2026-08-22 | Task 0 — il `Marker3D` `Seat` punta al vetro: -11,50° invece di +11,50°, origine invariata. | Schermo intero da seduti, verificato a schermo; sonda: beccheggio -11,5021° |
| 2026-08-22 | **Rilievo m6 chiuso: chi chiama `crt.show_control()` è `main.gd`**, il punto d'ingresso, per la tabella dei confini. `night/` erediterà il punto di chiamata senza spostarlo. | Dichiarato nell'intestazione di `main.gd` |
| 2026-08-22 | **Rilievo M4 chiuso**: `UPDATE_ALWAYS` solo alla postazione, `UPDATE_ONCE` altrove, deciso da `CrtScreen.set_live()`. NFR15 rispettato dove costa e violato dichiaratamente dove serve. | Un render pass in meno mentre si cammina; monitor congelato e non nero, verificato a schermo |
| 2026-08-22 | Alzarsi con `E` sospende la fase invece di concluderla (AC5): `PROCESS_MODE_DISABLED` su fase **e** `Control`, con `runs_in_background()` come esenzione. | Sonda: stella e scia ferme mentre si cammina, stessa istanza al rientro |
| 2026-08-22 | Voce di `deferred-work.md` **chiusa**: `set_anchors_preset` diventa `set_anchors_and_offsets_preset`, e il posto in cui era duplicata non esiste più. | `grep set_anchors` trova una sola occorrenza, in `crt/` |
| 2026-08-22 | Voce di `deferred-work.md` **chiusa**: «uscire dalla fase la conclude, e rientrando riparte». | AC5 |
| 2026-08-22 | Voci **aggiornate**: «il ponte finisce nel vuoto» (manca il proprietario, non la superficie) e «re-interagire riavvia la fase» (il meccanismo è cambiato, il difetto no). Tre voci **nuove**. | `deferred-work.md` |
| 2026-08-22 | **Blocco senza ritorno chiuso**: durante la transizione nessuno comanda (`main.gd::_input()` + `DeskCamera.is_busy()`), e `_advance()` non restituisce il controllo a un corpo che un tween sta ancora muovendo. | Sonda: `ENTER` ed `E` inerti a metà transizione; 5 cicli «siediti, alzati» senza deriva |
| 2026-08-22 | `project.godot` riordinato dall'`--import` (`[rendering]` dopo `[layer_names]`, nessun valore cambiato) scartato con `git checkout`: non è lavoro di questa storia. Il fenomeno è registrato in `deferred-work.md`. | `git status` non lo elenca |
| 2026-08-22 | AC4 — `grep -rn "phases/" crt/` a zero; `grep -rn "world/" crt/` a zero. | Rieseguibili |
| 2026-08-22 | AC2 della 1.1 — `git diff -- phases/polar/phase_polar.gd` vuoto. | Rieseguibile |
| 2026-08-22 | AC4 della 1.2 — `phases/`, `night/`, `debug/` dentro `world/` a zero. Il grep cerca il percorso con la barra: senza barra, `world/interactables/crt_monitor.gd` nomina `night_session` in due commenti — preesistenti alla 1.3, accettati dalla 1.2, e non dipendenze. | Rieseguibile |
| 2026-08-22 | AC1 della 1.2 — nessuna riga riparenta o sposta la camera: `desk_camera` scrive solo `rotation:x` e `fov`, e **legge** `_cam.position`. | `grep -n "_cam" crt/desk_camera.gd` |
| 2026-08-22 | Gioco a zero errori e zero warning; `tests/test_bench.tscn` gira pulito e non è stato toccato. | `--headless --quit-after 600`; `git status tests/` vuoto |
| 2026-08-22 | **Code review adversariale a tre layer**: 31 rilievi grezzi, 20 dopo triage. 3 decisioni risolte, 16 patch applicate, 3 rinviate, 3 scartate. | Sezione Review Findings |
| 2026-08-22 | **Blocco senza ritorno chiuso**: `configure()` restituisce l'esito e `_setup_desk()` lo guarda. Una postazione mal configurata non viene montata, e il rifiuto arriva prima di togliere il controllo al giocatore — non dopo. | Sonda: `configure(null)` torna `false`; verificato dal layer che ha eseguito il gioco |
| 2026-08-22 | `_on_seated()` fa rialzare se nel frattempo la fase è sparita, invece di lasciare il giocatore seduto davanti al nulla. La promessa scritta in `_advance()` adesso è vera. | Sonda; ramo oggi irraggiungibile ma non più scoperto |
| 2026-08-22 | `E` per alzarsi si legge in `_shortcut_input()`: il punto d'ingresso è sempre ultimo in `_unhandled_input`, e bastava una fase che consumasse l'evento perché il gesto smettesse di funzionare. | Misurato: propagazione in ordine di albero inverso |
| 2026-08-22 | `_input()` ingoia solo le azioni dell'`InputMap`: `F9`, `F12` e i tasti di taratura restano vivi a metà transizione. | `debug/` legge keycode grezzi, non azioni |
| 2026-08-22 | `_set_phase_running()` separa **ascoltare** da **girare**: l'ascolto segue sempre la postazione, `runs_in_background()` esenta solo dal fermarsi. E i `process_mode` si salvano e si ripristinano invece di essere imposti. | È il precedente per la fase 10 dell'epica 3, ora coerente |
| 2026-08-22 | I due angoli del Task 0 erano sbagliati di ~1,3°: il semiangolo era stato applicato simmetricamente attorno alla direzione centrale. I valori veri sono **-25,51° … +3,90°**, e la decisione si rafforza — 46% dello schermo col segno vecchio, 100% col nuovo. La spiegazione è uscita dal `.tscn`, che l'editor riscrive, ed è entrata in `desk_camera.gd`. | Ricalcolato; due layer indipendenti sullo stesso rilievo |
| 2026-08-22 | Quattro commenti ridimensionati a ciò che il codice mantiene: l'ordine di `_input`, il «frame in più», «`_draw` non si ferma», e una misura sul focus mai fatta. | Nessuna promessa non mantenuta lasciata nel repository |
| 2026-08-22 | Il CRT vuoto resta grigio-verde: guardato in confronto A/B col nero, che fa sparire scanline e curvatura. La voce che lo chiamava «schermo nero» è corretta, e la dipendenza da `default_clear_color` è registrata. | Due scatti dal gioco vero |
