---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - '_bmad-output/game-architecture.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/planning-artifacts/briefs/brief-astrochills-gd-3d-2026-08-21/brief.md'
  - '_bmad-output/planning-artifacts/briefs/brief-astrochills-gd-3d-2026-08-21/addendum.md'
  - 'docs/idea/economia.md'
  - 'docs/idea/minigiochi.md'
  - '../phaser_astrochill/src/data/ (dso_base.js, clients.js, comforts.js, facilities.js)'
gdd: null
gddNote: 'Nessun GDD esiste. I requisiti sono DERIVATI da brief + addendum + architettura + economia.md, non estratti. Ogni requisito porta la propria fonte.'
uxDoc: null
scope: 'MVP - una notte, tre fasi (3 polare, 6 targeting, 10 imaging) + stacking + vendita + gestione leggera osservatorio durante la posa'
hypothesis: "l'attesa e piacevole"
---

# astrochills-gd-3d - Epic Breakdown

## Overview

Questo documento contiene la scomposizione in epiche e storie di **Astrochill**, per il
solo MVP: **una notte con tre fasi delle dieci**, più stacking, vendita e la gestione
leggera dell'osservatorio durante la posa.

**L'MVP esiste per validare una sola ipotesi: _l'attesa è piacevole_.** Ogni requisito qui
sotto va letto con quella domanda in mano. Le attività durante la posa non sono un
contorno: sono lo strumento di misura.

**Criterio di superamento:** giocare tre notti di fila perché va, non per collaudo.

### Nota sulle fonti — leggere prima di usare questo documento

Non esiste un GDD. Il workflow che ha prodotto questo file è scritto per estrarre requisiti
da un GDD; qui i requisiti sono **derivati** da brief, addendum, `game-architecture.md` ed
`economia.md`. La colonna *fonte* di ogni requisito dice da dove viene.

`docs/idea/` descrive un gioco molto più grande di questo. Un requisito che non compare qui
è **fuori scopo per costruzione**, non dimenticato.

### Fuori scopo — non implementare senza che venga chiesto

Le altre sette fasi (livellamento, bilanciamento, accensione PC, plate solving, focus,
dark/flat, autoguida) · le rotture e le anomalie — **il seam esiste, le bugie no** · storia
· metanarrazione · rete di osservatori · esplorazione esterna · calibrazione economica: i
prezzi non si tarano ora.

---

## Requirements Inventory

### Functional Requirements

#### A — La notte e la sua orchestrazione

| # | Requisito | Fonte |
|---|---|---|
| **FR1** | La notte comincia alle 21:00 e finisce all'alba. L'alba è raggiunta quando `elapsed_min >= Tuning.night_length_min`, non a un'ora reale. | economia §12-13, arch § Time |
| **FR2** | L'orchestratore esegue le fasi di **setup** una volta per notte e le fasi di **foto** una volta per scatto, leggendo quali e in che ordine da un `NightPlan`, che è un dato e non codice. | arch § Pattern standard, economia §12 |
| **FR3** | Alla fine di ogni foto si apre un **menu post-foto** con quattro scelte: *scatta ancora* (riparte dalla fase 10), *cambia target* (torna alla 6), *rifai setup* (torna alla 3, punteggi azzerati), *chiudi ed esplora*. | economia §12.3 |
| **FR4** | *Chiudi ed esplora* mantiene valido il setup: finché non è l'alba il giocatore può riaprire il menu e scattare ancora senza rifare nulla. | economia §12.3 |
| **FR5** | L'alba chiude la notte da sola, anche a menu aperto, e mostra il riepilogo della notte. | economia §13 |
| **FR6** | Il tempo di gioco è un accumulatore su `_process` (`elapsed_min += delta * game_min_per_sec`): rispetta la pausa e `Engine.time_scale`, così la notte ×10 per collaudo è gratis. | arch § Time |

#### B — Le tre fasi

| # | Requisito | Fonte |
|---|---|---|
| **FR7** | **Fase 3 — allineamento polare col metodo della deriva.** Una stella nel reticolo, due regolazioni (azimuth e altitudine). Il giocatore osserva la deriva, corregge, aspetta, riosserva. È la fase più lunga e meditativa: stabilisce il ritmo della notte. | minigiochi §3, brief §MVP |
| **FR8** | La fase 3 produce un punteggio di qualità 0-100. **Metrica decisa nella storia 1.1 (2026-08-22):** velocità di deriva residua media sulla finestra `polar_score_window_sec`, mappata su 0-100 con `polar_max_drift_rate` come peggior caso. Indipendente da tempo impiegato e numero di correzioni. La deriva è quella restituita da `truth`, mai ricalcolata dalle regolazioni. | arch § Debug/Testing, `phase_polar.gd::score()` |
| **FR9** | Un allineamento mediocre **non blocca**: la fase si chiude comunque e il punteggio basso si propaga alla qualità della foto. Le lire non sono mai un gate. | economia §Principi 3 |
| **FR10** | **Fase 6 — targeting.** Catalogo di oggetti selezionabili con tipo (NEB/GAL/GLOB/OPEN/PLN), difficoltà, esposizione minima consigliata, finestra di visibilità oraria e descrizione. | minigiochi §6, `dso_base.js` |
| **FR11** | Il catalogo tiene conto dell'ora corrente della notte: un target fuori dalla propria finestra di visibilità è segnalato come non disponibile adesso. | `dso_base.js` (`vis.from/to`) |
| **FR12** | Il target scelto entra nel `payload` del `PhaseResult` e raggiunge la fase 10 **come dato in ingresso**, mai come import fra fasi. | arch ADR-002 |
| **FR13** | **Fase 10 — sequenza di imaging.** Il giocatore configura esposizione e numero di frame, poi avvia. La sequenza avanza in tempo reale consumando minuti di gioco (`min_per_frame` per frame). | minigiochi §10, arch § Tuning |
| **FR14** | La fase 10 **non blocca**: resta viva e continua a processare mentre il giocatore cammina in un'altra stanza. Al ritorno al monitor il CRT mostra lo stato vero (`frame 7/20`), non uno stato ricostruito. | arch Pattern 2 |
| **FR15** | La fine della sequenza è annunciata da un segnale percepibile **da un'altra stanza**, e il segnale appartiene al luogo, non alla fase. | arch Pattern 2, regola 2 |
| **FR16** | Ogni fase espone il proprio stato osservabile **solo** attraverso la propria `PhaseTruthSource` iniettata. Nell'MVP la sorgente dice sempre la verità. **È cross-cutting:** ogni storia che costruisce una fase lo esercita — 1.1 per la polare, 2.2 per il targeting, 2.3 per l'imaging. Non è un requisito dell'epica 1. | arch ADR-001 |

#### C — Foto, stacking, vendita

| # | Requisito | Fonte |
|---|---|---|
| **FR17** | Ogni foto ha un punteggio aggregato calcolato dai punteggi delle fasi che la compongono. Le fasi non rifatte **ereditano** il punteggio dall'ultima esecuzione. | economia §12.4 |
| **FR18** | I punteggi si indicizzano con `Phase.key()`, mai con `phase.name` — e finiscono nel save con quella chiave. | arch Issue 3 |
| **FR19** | **Stacking.** I frame acquisiti si sommano e l'immagine emerge progressivamente a schermo. È il momento della rivelazione: va messo in scena, non risolto con una barra di avanzamento. | minigiochi §Stacking, brief §core loop |
| **FR20** | **Vendita.** Payout immediato **per foto**, non aggregato di fine notte, secondo una curva a scaglioni sul punteggio aggregato. Accredito sul portafoglio ed emissione di `photo_sold`. | economia §2, §12.1 |
| **FR21** | **Commessa notturna.** Un committente chiede un soggetto; il suo moltiplicatore si applica al payout. Il giocatore **può rifiutarla** e non succede niente — e il fatto che non succeda niente è materiale, non un buco. | brief §core loop, `clients.js` |
| **FR22** | I numeri della curva e dei moltiplicatori sono **segnaposto dichiarati**: il meccanismo è nell'MVP, la calibrazione no. | brief §Rinviato, addendum §7 |

#### D — L'osservatorio e l'attesa

| # | Requisito | Fonte |
|---|---|---|
| **FR23** | Movimento in prima persona nell'osservatorio, con le stanze che l'MVP usa — stanza computer, cucina, cupola — e i collegamenti fra loro. | brief §Content, arch § world/ |
| **FR24** | Sistema di interazione con gli oggetti: un contratto comune, un prompt diegetico e discreto, un tasto solo. | arch `world/interactables/interactable.gd` |
| **FR25** | Interagendo col monitor la camera transita alla postazione seduta e l'input passa al `SubViewport`; uscendo, l'inverso. La camera non si stacca **mai** dal corpo. | arch ADR-003 |
| **FR26** | **Attività dell'attesa.** Durante la posa esiste un insieme **piccolo e chiuso** di cose da fare, ciascuna con una durata reale e un effetto percepibile nel mondo. Meglio due o tre fatte bene che sei abbozzate. *Quali siano, si decide nelle epiche.* | addendum §8, brief §pilastro 2 |
| **FR27** | Ogni attività dell'attesa emette `Events.wait_activity_started(what)` quando comincia e `Events.wait_activity_ended(what)` quando finisce — **sempre entrambi, sempre in coppia**. Dalla coppia si ricavano la **durata** di ogni attività e, per differenza sulla finestra della posa, i tratti `idle`; un'attività cominciata e mai conclusa è uno `started` senza `ended`, quindi l'abbandono si legge senza conteggi di parità. È lo strumento con cui si misura l'ipotesi: senza, l'MVP produce un'impressione e non un dato. | `autoloads/events.gd`, arch § Logging |
| **FR28** | **Terminale gestionale sul CRT**: portafoglio, categorie, acquisto, descrizioni. È il posto dove le lire diventano qualcosa — senza, la vendita non ha conseguenze e l'attesa non ha di che riempirsi. | economia §4 |
| **FR29** | Ogni acquisto ha un effetto **visibile o interattivo nel mondo**: la lampada smette di lampeggiare, la moka compare in cucina ed è usabile. Un acquisto che non si vede non esiste. | economia §5-6 |

#### E — Persistenza, tuning, strumenti

| # | Requisito | Fonte |
|---|---|---|
| **FR30** | Save e load della `NightRun` con `ResourceSaver` su `.tres` in `user://saves/`, con campo `version` e `migrate()` chiamato al load **anche quando è vuoto**. | arch § Data Persistence |
| **FR31** | Portafoglio e flag di acquisto sopravvivono alla fine della notte: sono ciò che collega una notte alla successiva. | economia §Persistenza |
| **FR32** | **Telemetria di sessione**, un file per notte in `user://telemetry/`, separata dal log: `tuning_hash`, `wait_total_min`, `wait_activities[]`, `menu_reopened`, `quit_mid_pose`. | arch § Logging |
| **FR33** | Il `tuning_hash` è obbligatorio: senza sapere con quali numeri è stata giocata una notte, tre notti diverse non sono confrontabili e l'esperimento non conclude niente. | arch § Logging |
| **FR34** | **Iniettore di sorgente bugiarda su `F9`**: sostituisce a caldo la `PhaseTruthSource` onesta con una che deriva, iniettata con `.duplicate(true)`. Non è contenuto — è la prova che il vincolo di ADR-001 regge. | arch § Debug Tools |
| **FR35** | **Controllo del tempo su `F1`-`F4`**: apparato sperimentale per tarare la durata dell'attesa senza rigiocare la notte a velocità reale. | arch § Debug Tools |
| **FR36** | **Overlay su `F12`** che mostra ora, minuti trascorsi, `time_scale`, punteggio per fase e — la cosa che altrimenti sfugge — **quale sorgente alimenta quale fase** (`[HONEST]` / `[DRIFTING]`). | arch § Debug Tools |
| **FR37** | Gli strumenti di debug esistono solo con `OS.is_debug_build()` e non sono compilati in release. | project-context |

---

### NonFunctional Requirements

| # | Requisito | Fonte |
|---|---|---|
| **NFR1** | Godot **4.7.2 stable**, renderer **Compatibility** (OpenGL 3.3 / ES 3.0), PC Windows. GDScript con tipizzazione statica ovunque possibile. | arch § Engine |
| **NFR2** | **Nessun codice di networking, mai.** Single player offline: l'intera categoria è fuori scopo per costruzione. | project-context |
| **NFR3** | **Estetica PS1 — valori validati sul campo il 2026-08-21, non stimati.** `stretch_shrink = 2` (640×360 interni), `snap_resolution = 665` (jitter sub-pixel), `scanline_count = altezza / 2` (calcolato, mai scelto a mano), CRT viewport minimo `256×192`. Non cambiarli senza una ragione dichiarata. | project-context, arch § Spike |
| **NFR4** | Nessun filtro lineare, nessuna mipmap, nessun antialiasing, nessun bloom, nessuna ombra morbida. L'aliasing crudo **è** il look: «migliorare la resa» è l'errore più frequente su questo progetto. | project-context |
| **NFR5** | **ADR-001 — il vincolo non negoziabile.** Lo stato osservabile di una fase ha **una sola assegnazione** in tutto il file e viene da `truth.sample(...)`. Nell'MVP la sorgente dice sempre la verità: questo non autorizza a saltarla. | arch ADR-001 |
| **NFR6** | Ogni `.tres` di sorgente ha `resource_local_to_scene = true`; ogni iniezione a runtime usa `.duplicate(true)`. Le `Resource` sono condivise per riferimento. | arch, regola 2 |
| **NFR7** | **ADR-002.** Una scena autonoma per fase. Una fase non importa **mai** da un'altra fase: ciò che le serve arriva come dato in ingresso. Verificabile con `grep "phases/"` dentro `phases/`. | arch ADR-002 |
| **NFR8** | Le regole di dipendenza fra cartelle si rispettano: `core/` non dipende da niente; `phases/` solo da `core/`; `night/` non conosce `world/`; `crt/` non conosce le fasi. | arch § Boundaries |
| **NFR9** | **Due canali che non si toccano mai.** `push_error()`/`assert()` per gli errori di programma, `PhaseResult` per gli esiti diegetici. Un fallimento diegetico non passa **mai** da `push_error`; un errore di programma non appare **mai** sul CRT. | arch § Error Handling |
| **NFR10** | **IT è la lingua del giocatore, EN è la lingua delle macchine.** Narrativa, log di gioco e commenti in italiano; ogni interfaccia software, messaggio del terminale ed esito diegetico in inglese. Identificatori in inglese. | project-context |
| **NFR11** | Prezzi in **lire**, ambientazione 1999: nessun anacronismo tecnico — niente USB, niente Wi-Fi, niente cloud. Seriale e modem 56k. Software citato realmente esistente. | project-context |
| **NFR12** | I valori **scelti** stanno in `data/tuning.tres` e si leggono sempre dall'autoload `Tuning`. Mai `load("res://data/tuning.tres")`: scavalcherebbe l'override in silenzio. | arch § Configuration |
| **NFR13** | L'override `user://tuning_override.cfg` deve funzionare **su build già esportata**: è lo strumento con cui si tara l'MVP, anche in mano a qualcun altro. | arch § Tuning |
| **NFR14** | Una fase in background non assume **mai** di essere visibile: niente `get_viewport().size`, niente accesso alla camera. I suoni appartengono al luogo, non alla fase. | arch Pattern 2 |
| **NFR15** | I `SubViewport` non usano `UPDATE_ALWAYS` per default: ogni schermo CRT è un render pass in più, ed è il costo reale del progetto. | project-context § Performance |
| **NFR16** | Transizioni di fase sempre `call_deferred`. Il CRT non libera **mai** il `Control` che mostra. `show_control(null)` **prima** di liberare una fase. | arch § Consistency Rules |
| **NFR17** | I dati di contenuto sono `.tres` in `data/`. Nessun `FileAccess` e nessun JSON nel gameplay. | project-context |
| **NFR18** | Save versionato **dal primo giorno**, con `migrate()` chiamato al load anche quando non fa niente. È l'unica cosa che rompe partite già iniziate. | arch § Data Persistence |
| **NFR19** | Test sul banco `tests/test_bench.tscn`, **nessun framework**. Solo logica pura: sorgenti di verità, aggregazione qualità, migrazione del save. Non introdurre GUT o gdUnit4 senza chiedere. | arch § Testing |
| **NFR20** | **Tono cozy.** Nessun modale bloccante, nessuno stack trace o codice d'errore Godot mostrato al giocatore, nessun jump scare, nessuna minaccia, non si muore. Un caricamento fallito diventa una frase gentile. | project-context |
| **NFR21** | In prima persona **la camera è la testa**: non si stacca mai dal corpo. | project-context |
| **NFR22** | Signal dichiarati e tipizzati, `snake_case` al passato. `EventBus` solo per i fatti di notte con più di due ascoltatori; altrimenti signal diretto. | arch § Communication |
| **NFR23** | Nomi: una fase è `phase_<nome>`, **mai** `phase_<numero>`. Una sorgente è `<aggettivo>_<cosa>` — l'aggettivo dice **se e come mente**. | arch § Naming |
| **NFR24** | L'identità di una fase è `key()`, mai `name`: Godot rinomina in `@PhasePolar@2` e con «rifai setup» succede davvero. | arch Issue 3 |

---

### Additional Requirements

Requisiti tecnici che vengono dall'architettura e dallo stato reale del repository, e che
condizionano l'ordine e il contenuto delle storie.

#### Inizializzazione — nessuno starter template, e il progetto è già avviato

- **Nessuno starter template.** Nel mondo Godot non esiste un equivalente di
  `create-next-app` che convenga. Il progetto si parte vuoto — **ed è già stato partito**.
- `project.godot` esiste, con renderer `gl_compatibility`, `default_texture_filter=0`
  (Nearest) e i quattro autoload registrati nell'ordine giusto: `Game → Events → Log → Tuning`.

#### Cosa esiste già ed è **keeper** — verificato sul repo, non assunto

| Cartella | Contenuto | Stato |
|---|---|---|
| `core/` | `phase.gd`, `phase_result.gd`, `phase_truth_source.gd`, `night_run.gd`, `night_plan.gd`, `tuning_profile.gd` | keeper, gira pulito |
| `autoloads/` | `game.gd`, `events.gd`, `log.gd`, `tuning.gd` | keeper |
| `crt/` | `crt_screen.gd/.tscn`, `desk_camera.gd`, `shaders/crt.gdshader` | keeper |
| `world/` | `shaders/ps1.gdshader` | keeper (solo lo shader) |
| `data/` | `tuning.tres` | keeper |

- **`core/save_manager.gd` manca** rispetto all'albero dell'architettura. Va scritto.
- `autoloads/events.gd` dichiara già `wait_activity_started(what)` e `wait_activity_ended(what)`:
  il condotto della misura esiste prima delle attività che lo useranno. **La coppia è stata
  introdotta il 2026-08-21**, al posto del signal unico `wait_activity(what)` che c'era prima:
  con un solo evento la durata di un'attività non era ricavabile, i tratti `idle` nemmeno, e un
  rituale abbandonato si sarebbe distinto da uno concluso solo per parità di conteggio — che la
  cupola, che emetteva una volta sola, avrebbe rotto al primo utilizzo. Cambiata finché nessuno
  la usava ancora.

#### Cosa è usa e getta — e la conseguenza che va vista adesso

- `spike/` contiene `spike_room.tscn`, `spike_player.gd`, `spike_screen.gd`.
- **`main.tscn` istanzia ancora `spike_room.tscn`, e `main.gd` è lo script dello spike**
  (overlay dei parametri, `F5`/`F6` sul jitter, `E` per sedersi). Cancellare `spike/` non è
  una `rm`: significa **sostituire il punto d'ingresso**, e i tasti di debug dello spike
  vanno rifusi negli strumenti veri (`F1`-`F4`, `F12`) invece di sparire.

#### Spike già superati — non ridiscutere

- **2026-08-21, OpenGL 3.3 Compatibility su RTX 3080.** Mondo in `SubViewport` a bassa
  risoluzione riscalato nearest: funziona. CRT diegetico con curvatura, scanline e
  aberrazione: funziona, e il testo tecnico è leggibile a `256×192` **una volta seduti**.
- **ADR-003 non è un comfort, è un requisito di leggibilità.** Senza la transizione alla
  scrivania il CRT è illeggibile. Non è una feature rimandabile.

#### I sei primi passi dell'architettura — stato

| # | Passo | Stato |
|---|---|---|
| 1 | Look PS1 in `SubViewport` | ✅ fatto (`main.tscn`, `world/shaders/ps1.gdshader`) |
| 2 | Spike CRT | ✅ fatto (`crt/`) |
| 3 | I contratti in `core/` | ✅ quasi — manca `save_manager.gd` |
| 4 | **Fase 3 completa, con l'iniettore `F9` insieme. Non dopo.** | ⬜ è la prima storia |
| 5 | `night_session` + `NightClock` + `NightPlan` | ⬜ |
| 6 | Fase 6, fase 10, osservatorio, stacking, vendita | ⬜ |

Il passo 4 è quello che conta: costruire `HonestDrift`, poi `WanderingDrift`, poi premere
`F9` **con una sola fase esistente**. Se il codice della fase deve cambiare per accogliere
la bugia, l'architettura è sbagliata e si corregge quando c'è una fase da sistemare invece
di tre. È l'unico momento in cui il rischio residuo di ADR-001 costa poco da chiudere.

#### Cartelle da creare

`phases/{polar,targeting,imaging}/sources` · `night/` · `world/{player,rooms,interactables}` ·
`photo/` · `ui/` · `data/{targets,clients}` · `assets/{models,textures,fonts,audio/{ambient,sfx}}` ·
`debug/` · `tests/`

#### Dati da portare — design validato, non codice da riusare

Da `../phaser_astrochill/src/data/`, in `.tres`:

| File | Contenuto | Destinazione |
|---|---|---|
| `dso_base.js` | **6 target**: M42, M13, M45, M31, M57, M8 — con `type`, `diff`, `minExp`, finestra `vis{from,to}` e descrizione **in italiano già scritta** | `data/targets/` |
| `clients.js` | **3 committenti attivi** (Coelum ×1.0, Astrofili Marche ×0.6, BBS Cygnus ×1.4) più `privato_g` **disabilitato** — gancio già predisposto per la vena creepy | `data/clients/` |
| `comforts.js` | catalogo comfort personale con prezzi, descrizione IT e EN — moka 3.000, stufetta 6.000, coperta 4.000, mangiacassette 7.000, … | `data/` |
| `facilities.js` | catalogo riparazioni — lampada cucina 2.000, bagno 4.000, ridipintura 5.000, cupola 8.000, … con `loreNote` e `effect` | `data/` |

**Attenzione:** i **committenti** (comprano) non sono gli **osservatori della rete**
(corroborano e poi si corrompono). Sono due sistemi diversi, nessun documento li distingue,
e solo i primi esistono.

#### Rinviato in architettura, con conseguenza accettata

- **Salto di fase con stato iniziale** (debug): non c'è. Conseguenza: ogni iterazione sulla
  fase 10 richiede di rigiocare polare e targeting. Il controllo del tempo mitiga, non
  elimina. È la prima cosa da aggiungere se l'attrito diventa fastidioso.
- **MCP GoPeak e Context7**: raccomandati, non installati. Nessun `.mcp.json`.

#### Decisioni aperte che vanno chiuse dentro le storie, non prima

1. ~~**La metrica di qualità della fase 3.**~~ **CHIUSA il 2026-08-22 scrivendo la fase**,
   come previsto: velocità di deriva residua media su una finestra, indipendente da tempo e
   correzioni. Vedi FR8 e `phases/polar/phase_polar.gd::score()`.
2. **Quali sono le attività dell'attesa.** `economia.md §5-6` le elenca come *spese*, ma non
   dice quali entrano nell'MVP né come ci si interagisce. Sono lo strumento di misura
   dell'ipotesi: vanno decise nelle epiche, non rinviate.
3. **La durata della notte.** È per costruzione un valore di tuning ed è la variabile
   sperimentale dell'MVP. Non si «decide»: si prova.

---

### UX Design Requirements

**Nessun documento UX esiste.** Questi requisiti sono derivati da `economia.md §4`, ADR-003
e dai valori validati dallo spike. Sono elencati a parte perché le interfacce diegetiche non
sono contorno: sono **il grosso del gameplay e la cosa dimostrabile per il portfolio**.

| # | Requisito |
|---|---|
| **UX-DR1** | Ogni interfaccia di fase è un `Control` mostrato sul **CRT diegetico**, non UI a schermo. La UI non diegetica esiste solo per pausa e impostazioni, e vive in `ui/`. |
| **UX-DR2** | Il CRT non sa mai cosa mostra: riceve un `Control` e basta. È questo che rende indolore l'upgrade futuro al raycast sul mesh. |
| **UX-DR3** | **Terminale gestionale** secondo il mockup di `economia.md §4`: cornice ASCII a linee singole, monospace **verde fosforo su nero**, intestazione con `WALLET` e `NIGHT TAKE`, menu numerato, navigazione `↑↓` / `ENTER` / `ESC`, beep sui movimenti. |
| **UX-DR4** | Testo di ogni interfaccia software **in inglese**; le descrizioni narrative dei prodotti **in italiano**, dietro un tasto dedicato (`?` / `H`). |
| **UX-DR5** | **Leggibilità a `256×192`.** Nessuna interfaccia deve richiedere di leggere il CRT da lontano o da in piedi. Il corpo minimo del font e la densità di righe si verificano guardando, non stimando. |
| **UX-DR6** | **La sequenza della transizione alla scrivania è precisa** e va rispettata: controller del giocatore disabilitato → corpo agganciato al `Marker3D` → tween della camera (≈0,5 s) con FOV che si stringe a 42° → **solo a interpolazione finita** l'input passa al `SubViewport`. All'uscita, l'inverso. Il FOV che si stringe non è un vezzo: legge come «mi avvicino a guardare». |
| **UX-DR7** | La fase 3 ha bisogno di una lettura visiva della deriva **leggibile a `256×192`**: reticolo, stella, e una traccia dello storico — altrimenti «osserva la deriva» è un'istruzione senza supporto. |
| **UX-DR8** | Il feedback di fine sequenza è **udibile da un'altra stanza** e appartiene al luogo (un `AudioStreamPlayer3D` nella cupola o nella stanza computer), non alla fase. |
| **UX-DR9** | Prompt di interazione diegetico e discreto. Nessun modale bloccante, nessun pannello d'errore, nessun popup di gioco sopra il mondo. |
| **UX-DR10** | Il payout compare come **evento diegetico** sullo schermo del terminale, non come popup di gioco sopra la scena. |
| **UX-DR11** | L'overlay di debug `F12` mostra `[HONEST]` / `[DRIFTING]` per ogni fase: è l'unico modo di accorgersi che `F9` ha fatto qualcosa. |

---

### FR Coverage Map

| FR | Epica | In una riga |
|---|---|---|
| FR1 | Epica 2 | la notte comincia alle 21:00 e finisce all'alba per orologio |
| FR2 | Epica 2 | `NightPlan` come dato: setup una volta, fasi foto a ogni scatto |
| FR3 | Epica 2 | menu post-foto a quattro voci |
| FR4 | Epica 2 | «chiudi ed esplora» conserva il setup fino all'alba |
| FR5 | Epica 2 | l'alba chiude la notte da sola, anche a menu aperto |
| FR6 | Epica 2 | tempo come accumulatore: rispetta pausa e `time_scale` |
| FR7 | **Epica 1** | fase 3, metodo della deriva: stella, reticolo, due regolazioni |
| FR8 | **Epica 1** | punteggio della fase 3 — **metrica decisa nella 1.1, 2026-08-22** |
| FR9 | **Epica 1** | un allineamento mediocre non blocca |
| FR10 | Epica 2 | fase 6, catalogo dei sei target con tipo, difficoltà, visibilità |
| FR11 | Epica 2 | i target fuori finestra oraria sono segnalati non disponibili |
| FR12 | Epica 2 | il target passa alla fase 10 come dato, mai come import |
| FR13 | Epica 2 | fase 10: esposizione e frame, poi la sequenza consuma tempo |
| FR14 | Epica 2 | la fase 10 non blocca e mostra lo stato vero al ritorno |
| FR15 | Epica 2 | la fine sequenza si sente da un'altra stanza |
| FR16 | **Epica 1** + Epica 2 | lo stato osservabile viene solo da `truth.sample()` — **cross-cutting: vale per tutte e tre le fasi**, non solo per la polare |
| FR17 | Epica 2 | punteggio aggregato per foto, con eredità fra scatti |
| FR18 | Epica 2 | i punteggi si indicizzano con `key()`, mai con `name` |
| FR19 | Epica 2 | lo stacking come rivelazione, non come barra di avanzamento |
| FR20 | Epica 2 | payout immediato per foto, curva a scaglioni, `photo_sold` |
| FR21 | Epica 2 | commessa notturna rifiutabile, col moltiplicatore del committente |
| FR22 | Epica 2 | i numeri sono segnaposto dichiarati: la calibrazione è rinviata |
| FR23 | **Epica 1** (parziale) + Epica 3 (completo) | stanza computer e movimento nell'1; cucina e cupola nella 3 |
| FR24 | **Epica 1** | contratto di interazione, prompt diegetico, un tasto solo |
| FR25 | **Epica 1** | transizione alla scrivania, input al `SubViewport` a tween finito |
| FR26 | Epica 3 | **le tre attività dell'attesa** — caffè, lampada, cupola |
| FR27 | Epica 3 | ogni attività emette `wait_activity_started` / `_ended` in coppia: è la misura |
| FR28 | Epica 3 | terminale gestionale sul CRT |
| FR29 | Epica 3 | ogni acquisto si vede o si usa nel mondo |
| FR30 | Epica 2 | save della `NightRun` su `.tres`, con `version` e `migrate()` |
| FR31 | Epica 2 | portafoglio e acquisti sopravvivono alla notte |
| FR32 | Epica 3 | telemetria per notte in `user://telemetry/` |
| FR33 | Epica 3 | `tuning_hash` obbligatorio: senza, l'esperimento non conclude |
| FR34 | **Epica 1** | iniettore `F9` — la prova che il seam regge |
| FR35 | Epica 2 | controllo del tempo `F1`-`F4` |
| FR36 | **Epica 1** | overlay `F12` con la sorgente attiva per fase |
| FR37 | **Epica 1** | il debug esiste solo con `OS.is_debug_build()` |

**Copertura: 37 FR su 37.** Nessun requisito resta fuori da un'epica.

---

## Epic List

Tre epiche, e ognuna esiste per rispondere a una domanda che le altre non possono
rispondere:

| Epica | Domanda | Se la risposta è no |
|---|---|---|
| 1 — L'allineamento polare e il seam | **il vincolo di ADR-001 regge?** | l'architettura cambia adesso, con una fase da sistemare invece di tre |
| 2 — Una notte di lavoro | **il ciclo di una notte funziona?** | il loop va ridisegnato prima di arredarlo |
| 3 — L'attesa | **l'attesa è piacevole?** | l'MVP ha fatto il suo lavoro: la risposta è quella che si cercava |

**L'ordine non è negoziabile in un punto solo:** l'epica 1 va per prima perché il seam si
prova a buon mercato **solo** finché esiste una fase sola.

---

### Epic 1: Il primo pezzo di mestiere — l'allineamento polare, e il seam che regge

Sei nella stanza computer dell'osservatorio. Ti avvicini al monitor, ti siedi, e sullo
schermo CRT esegui l'allineamento polare col metodo della deriva: guardi come la stella
scivola nel reticolo, correggi azimuth e altitudine, aspetti, riguardi. Quando smetti, hai
un punteggio. È il primo pezzo di mestiere vero del gioco, ed è la fase che stabilisce il
ritmo di tutte le notti.

**E poi premi `F9`, e la stella comincia a derivare da sola** — alimentata dal tempo invece
che dalle viti — **senza che una riga di `phase_polar.gd` sia stata toccata**. Se per
accogliere la bugia il codice della fase deve cambiare, ADR-001 è sbagliato e lo si scopre
adesso. È l'unico momento in cui quel rischio costa poco da chiudere, e per questo
l'iniettore si costruisce **insieme** alla fase, non dopo.

Qui si chiudono due cose che oggi sono aperte: la **metrica di qualità della fase 3**, che
non è mai stata decisa, e il **punto d'ingresso del progetto**, perché `main.tscn` istanzia
ancora `spike_room.tscn` e cancellare `spike/` significa sostituirlo.

**FRs covered:** FR7, FR8, FR9, FR16, FR23 (parziale), FR24, FR25, FR34, FR36, FR37
**UX-DRs:** UX-DR1, UX-DR2, UX-DR5, UX-DR6, UX-DR7, UX-DR9, UX-DR11

---

### Epic 2: Una notte di lavoro, dall'arrivo all'alba

Fai un turno intero. Arrivi alle 21:00, il tempo scorre davvero, fai il setup una volta
sola. Apri il planetario e scegli fra sei oggetti reali del cielo quale fotografare —
tenendo conto che alcuni stanotte sono già tramontati. Configuri esposizione e numero di
frame, avvii. La sequenza gira. Quando finisce, i frame si sommano e l'immagine emerge:
vedi per la prima volta cosa hai preso. Qualcuno te la paga, subito. Decidi se scattarne
un'altra, cambiare soggetto o rifare il setup — finché l'alba non chiude la notte da sola.
E la notte dopo ritrovi il tuo portafoglio dov'era.

C'è una **commessa**: qualcuno chiede un soggetto specifico e paga di più. Puoi rifiutarla,
e non succede niente — e in un gioco sull'isolamento il fatto che non succeda niente è
materiale, non un buco.

**Perché è un'epica sola e non tre.** Orchestrazione, fasi della foto, stacking e vendita
costruiscono lo stesso componente da capo a fondo, `night_session`, e la forma del ciclo è
già decisa in `economia.md §12` fin nei nomi delle voci di menu. Spezzarla produrrebbe
epiche che si riscrivono a vicenda lo stesso file senza che in mezzo si impari niente.

**I numeri di questa epica sono segnaposto dichiarati.** La curva a scaglioni e i
moltiplicatori dei committenti esistono come meccanismo; la calibrazione è rinviata per
decisione, e va rinviata sul serio: tararla ora significa tararla su un gioco che non si è
ancora giocato.

**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR10, FR11, FR12, FR13, FR14, FR15, FR16
(targeting e imaging), FR17, FR18, FR19, FR20, FR21, FR22, FR30, FR31, FR35
**UX-DRs:** UX-DR8, UX-DR10

---

### Epic 3: L'attesa — l'osservatorio mentre la posa gira

Mentre la sequenza espone, il monitor non ti serve. Ti alzi e vai in giro per
l'osservatorio: metti su la moka e aspetti che borbotti, sali in cupola a guardare il cielo
dalla fessura mentre il telescopio si muove da solo, e a un certo punto ti stufi di quella
lampada che lampeggia in cucina e ordini una lampadina al terminale per cambiarla. Quando
torni al monitor, la sequenza è a frame 14 su 20.

**È l'epica che risponde alla domanda per cui l'MVP esiste.** Le altre due costruiscono
l'apparato; questa produce il dato. Finché non è finita, l'ipotesi non è stata misurata —
ed è questo l'argomento per non lasciare che l'epica 2 si allarghi.

#### Le tre attività dell'attesa — decise qui, non rinviate

`economia.md §5-6` le elenca come spese e non dice quali entrino nell'MVP. Queste tre, e
sono scelte per **coprire tre registri diversi**, perché l'ipotesi riguarda il piacere e le
persone lo trovano in cose diverse:

| Attività | Registro | Cos'è |
|---|---|---|
| **Il caffè** | **fare** — un rituale a più tempi, ripetibile | Riempi la moka, la metti sul fuoco, aspetti che borbotti, versi. È un'attesa piccola dentro l'attesa grande: è la battuta tematica del gioco messa in meccanica. Richiede la moka, comprata al terminale. |
| **La lampada della cucina** | **sistemare** — una tantum, comprata, permanente | La lampada lampeggia e dà fastidio. Ordini la lampadina al terminale, vai in cucina, la cambi, e la luce diventa stabile per sempre. È il modo in cui quel posto diventa tuo — che è la condizione perché faccia effetto quando smetterà di esserlo. Ed è il dimostratore completo di FR29: lire → mondo che cambia. |
| **La cupola** | **stare** — gratis, sempre disponibile, zero meccanica | Sali, guardi il cielo dalla fessura, e il telescopio si muove da solo mentre lo guardi. Nessun oggetto da comprare, niente da completare. È il test diretto del pilastro: *l'attesa non va riempita di attività, va resa piacevole.* |

**La regola che le tiene insieme: nessuna dà un bonus meccanico.** `economia.md §5` assegna
al caffè un +5% sulla messa a fuoco, ma la messa a fuoco è la fase 7 e non esiste
nell'MVP — quindi la questione va decisa comunque. La si decide così: **niente bonus.** Un
bonus trasformerebbe un rituale in una faccenda da ottimizzare, tutti lo farebbero per
convenienza, e la telemetria misurerebbe l'obbedienza invece del piacere — cioè
contaminerebbe esattamente la misura per cui queste attività esistono. È una decisione
reversibile a costo quasi nullo se le tre notti dicono il contrario.

**Escluso, e va detto perché:** il *grafico dell'autoguida*, che il brief cita tre volte fra
le cose che fai mentre aspetti, **non può entrare**: l'autoguida è la fase 9 ed è fuori
scopo. Il suo posto lo prende il ritorno al CRT della sequenza, che mostra lo stato vero.

**Il quarto candidato, se ne servisse uno:** il *mangiacassette* (`comforts.js`, 7.000
lire). Costa quasi nulla — un `AudioStreamPlayer3D` e qualche traccia — e cambia il colore
di tutta l'attesa invece di aggiungerle un compito. È la prima cosa da aggiungere, e la
prima da togliere se tre sono troppe.

**FRs covered:** FR23 (completo), FR26, FR27, FR28, FR29, FR32, FR33
**UX-DRs:** UX-DR3, UX-DR4

---

## Epic 1: Il primo pezzo di mestiere — l'allineamento polare, e il seam che regge

Il giocatore esegue la prima procedura vera del mestiere — l'allineamento polare col metodo
della deriva — dentro l'osservatorio, seduto al monitor CRT. Ed è qui che il vincolo non
negoziabile del progetto viene messo alla prova quando costa poco: con **una fase sola**
esistente, l'iniettore `F9` sostituisce la sorgente onesta con una che deriva, e il codice
della fase non deve cambiare di una riga.

**FRs:** FR7, FR8, FR9, FR16, FR23 (parziale), FR24, FR25, FR34, FR36, FR37 ·
**UX-DRs:** UX-DR1, UX-DR2, UX-DR5, UX-DR6, UX-DR7, UX-DR9, UX-DR11 ·
**NFRs rilevanti:** NFR3, NFR5, NFR6, NFR7, NFR9, NFR19, NFR20, NFR21, NFR23, NFR24

---

### Story 1.1: L'allineamento polare, e la prova che il seam regge

As a **giocatore che di astronomia non sa niente**,
I want **osservare come una stella scivola nel reticolo, correggere due regolazioni e vedere la deriva ridursi**,
So that **il primo pezzo di mestiere diventi mio, e la notte abbia un ritmo**.

> **Questa è la storia più densa dell'MVP, e lo è per scelta.** La fase e l'iniettore
> nascono insieme perché separarli annullerebbe il motivo per cui l'iniettore esiste:
> provare il seam **finché una fase sola è in gioco**. Se la prova fallisce, si corregge
> ADR-001 con una fase da sistemare invece di tre. Include la cancellazione di `spike/`,
> perché `main.tscn` istanzia ancora `spike_room.tscn` e la fase ha bisogno di un punto
> d'ingresso che non sia lo spike.

**Acceptance Criteria:**

**Given** la fase polare in esecuzione
**When** il giocatore agisce sulle regolazioni di azimuth e altitudine e lascia passare il tempo
**Then** la stella deriva nel reticolo secondo il valore restituito dalla sorgente iniettata
**And** il valore osservabile della deriva ha **una sola assegnazione** in tutto `phase_polar.gd`, e quella assegnazione è `truth.sample(...)`
**And** la traccia della deriva è leggibile a `256×192`: reticolo, stella e storico recente, senza che «osserva la deriva» resti un'istruzione senza supporto

**Given** `phase_polar.gd` scritto, funzionante e alimentato da `HonestDrift`
**When** si aggiunge `WanderingDrift` e la si inietta al posto della sorgente onesta
**Then** `phase_polar.gd` **non cambia di una sola riga**, verificabile con `git diff`
**And** se una riga cambia, ADR-001 è sbagliato: si corregge adesso e la storia non è finita

**Given** una build di sviluppo con la fase attiva
**When** il giocatore preme `F9`
**Then** la `PhaseTruthSource` attiva è sostituita a caldo, iniettata con `.duplicate(true)`
**And** l'overlay `F12` mostra `polar [DRIFTING]` al posto di `polar [HONEST]`
**And** in una build di release `F9` e `F12` non esistono, perché tutto `debug/` è dietro `OS.is_debug_build()`

**Given** la metrica di qualità della fase 3, che oggi non esiste
**When** la storia è finita
**Then** la metrica è **decisa, implementata e motivata in una riga di commento**: il punteggio è funzione della **deriva residua** al momento della chiusura, mediata sugli ultimi secondi di osservazione
**And** il punteggio **non** dipende dal tempo impiegato né dal numero di correzioni — punirebbero il prendersi tempo e lo sperimentare, cioè esattamente ciò che la fase più meditativa del gioco deve invitare a fare
**And** la deriva usata per il punteggio è quella restituita da `truth`, mai ricalcolata dalle regolazioni: un punteggio che scavalca la sorgente rompe ADR-001 dalla porta di servizio

**Given** un allineamento lasciato a metà o fatto male
**When** il giocatore chiude la fase
**Then** la fase emette `finished` con un `PhaseResult` valido e un punteggio basso
**And** non c'è nessun blocco, nessun modale, nessun pannello d'errore: un allineamento mediocre è un esito, non un fallimento
**And** se c'è un `reason`, è in inglese e non passa **mai** da `push_error`

**Given** i valori dell'estetica PS1 validati sul campo il 2026-08-21
**When** `main.tscn` e `main.gd` vengono sostituiti dopo la cancellazione di `spike/`
**Then** il `SubViewportContainer` a bassa risoluzione, `stretch_shrink = 2` e il filtro nearest sopravvivono alla sostituzione
**And** i comandi con cui quei valori sono stati tarati — risoluzione del mondo, jitter dei vertici — non spariscono: migrano sotto `debug/`, dove potranno essere ritarati sul gioco vero
**And** al termine di questa storia `main.tscn` mostra il `Control` della fase **dentro il viewport a bassa risoluzione, senza mondo 3D intorno**: cancellando `spike/` sparisce l'unica stanza esistente, e quella vera arriva con la storia 1.2
**And** è un ponte dichiarato e temporaneo, non lo stato finale: nessun lavoro speso qui deve essere buttato dalla 1.3, che porterà lo stesso `Control` sul CRT senza toccare la fase

**Given** `spike/` cancellata
**When** il progetto si apre in Godot
**Then** non resta nessun riferimento pendente a `spike_room.tscn`, `spike_player.gd` o `spike_screen.gd`
**And** `main.tscn` parte senza un solo errore in console

**Given** `tests/test_bench.tscn`, senza alcun framework
**When** si esegue il banco
**Then** stampa che `HonestDrift` è **deterministica** — stesso input, stesso output, `delta` irrilevante
**And** stampa che `WanderingDrift` **non** lo è, perché è la differenza che si vuole poter vedere
**And** ogni `.tres` di sorgente ha `resource_local_to_scene = true`

---

### Story 1.2: L'osservatorio esiste, e ci sei dentro

As a **gestore notturno appena assunto**,
I want **camminare in prima persona nella stanza computer e vedere il monitor acceso sulla scrivania**,
So that **quel posto esista come luogo prima ancora di esistere come interfaccia**.

**Acceptance Criteria:**

**Given** la stanza computer costruita in `world/rooms/`
**When** il giocatore usa i comandi di movimento e il mouse
**Then** si muove in prima persona con un `CharacterBody3D` e guarda intorno
**And** la camera è **figlia del corpo e non se ne stacca mai**: non esiste nel progetto una riga che la riparenti o la sposti da sola
**And** la stanza è renderizzata con `ps1.gdshader` a `snap_resolution = 665`, dentro il `SubViewport` a bassa risoluzione

**Given** il contratto di interazione in `world/interactables/`
**When** il giocatore guarda un oggetto interagibile da vicino
**Then** appare un prompt diegetico e discreto, e l'interazione si esegue con **un tasto solo**
**And** il prompt non è un modale, non ferma il gioco e non copre la scena

**Given** il monitor CRT come oggetto del mondo in `world/interactables/`
**When** entra in scena
**Then** emette `Events.screen_registered` con il proprio `CrtScreen`
**And** nessun altro sistema lo cerca per percorso di nodo, che si romperebbe al primo spostamento

**Given** le regole di dipendenza dell'architettura
**When** si cerca `phases/` o `night/` dentro `world/`
**Then** non c'è nessuna occorrenza: `world/` conosce solo `core/` e `crt/`

---

### Story 1.3: Sedersi al monitor e lavorare sullo schermo

As a **giocatore**,
I want **avvicinarmi al monitor, sedermi, e fare l'allineamento polare sullo schermo CRT**,
So that **il lavoro succeda dentro il mondo invece che sopra di esso**.

> Questa storia unisce ciò che la 1.1 e la 1.2 hanno costruito separatamente, e chiude
> ADR-003 — che non è un comfort: senza la postazione seduta il testo tecnico sul CRT è
> illeggibile, perché la sua texture viene rimpicciolita con filtro nearest e senza mipmap.

**Acceptance Criteria:**

**Given** il giocatore davanti al monitor
**When** interagisce con esso
**Then** la sequenza è, nell'ordine: controller del giocatore disabilitato → corpo agganciato al `Marker3D` della postazione → tween della camera di circa mezzo secondo con il FOV che si stringe a 42°
**And** l'input passa al `SubViewport` **solo a interpolazione finita**, mai prima
**And** all'uscita accade l'inverso, e il controller torna attivo solo a transizione conclusa

**Given** la fase polare in esecuzione
**When** il suo `Control` viene mostrato sullo schermo
**Then** arriva lì tramite `crt.show_control(...)`, e il CRT **non lo libera mai**
**And** la proprietà resta della fase, che lo libera alla propria distruzione se lo ha dato via — `NOTIFICATION_PREDELETE`, **mai** `_exit_tree()`, che scatta anche su un'uscita temporanea dall'albero e ucciderebbe l'interfaccia di una fase ancora viva (corretto il 2026-08-22 in code review della 1.1)
**And** l'orchestratore — quando esisterà — chiama `show_control(null)` **prima** di liberare la fase

**Given** lo schermo a `256×192`
**When** il giocatore è seduto alla postazione
**Then** il testo tecnico della fase è leggibile, verificato guardando e non stimando
**And** nessuna informazione necessaria alla fase richiede di leggere il CRT da in piedi o da lontano

**Given** le regole di dipendenza
**When** si cerca `phases/` dentro `crt/`
**Then** non c'è nessuna occorrenza: il CRT riceve un `Control` e non sa quale

**Given** l'allineamento polare in corso
**When** il giocatore si alza dalla postazione e torna in piedi nella stanza
**Then** la fase non viene interrotta e non viene liberata
**And** al ritorno alla postazione mostra lo stato vero, non uno stato ricostruito

> **Nota di progetto, non requisito.** Alzarsi mentre la deriva si accumula è già, in
> piccolo, l'esperienza che l'epica 3 misurerà: la fase 3 è essa stessa un'attesa. È la
> prima occasione informale per farsi un'idea dell'ipotesi, mesi prima che ci sia la
> telemetria a dirlo.

---

## Epic 2: Una notte di lavoro, dall'arrivo all'alba

Il giocatore fa un turno intero: arriva alle 21:00, esegue il setup una volta sola, sceglie
un soggetto fra sei oggetti reali del cielo, configura la posa e la avvia. La sequenza gira
davvero. Alla fine i frame si sommano e l'immagine emerge, qualcuno la paga subito, e un
menu chiede quanto rifare — finché l'alba non chiude la notte da sola. La notte dopo, il
portafoglio è dove era stato lasciato.

Le storie aggiungono **un anello alla volta alla stessa catena**: a ogni storia la notte è
giocabile, semplicemente finisce un po' prima.

**FRs:** FR1-FR6, FR10-FR22 (incluso **FR16**, che vale per targeting e imaging come vale per la
polare), FR30, FR31, FR35 · **UX-DRs:** UX-DR8, UX-DR10 ·
**NFRs rilevanti:** NFR5, NFR7, NFR8, NFR12, NFR13, NFR14, NFR15, NFR16, NFR17, NFR18, NFR22, NFR24

---

### Story 2.1: Un turno che comincia alle 21:00 e finisce da solo all'alba

As a **gestore notturno**,
I want **che il tempo scorra davvero mentre lavoro e che l'alba chiuda la notte al posto mio**,
So that **la notte sia un turno con un inizio e una fine, e non una scena senza bordi**.

**Acceptance Criteria:**

**Given** una notte avviata
**When** il tempo passa
**Then** `elapsed_min` cresce come `delta * Tuning.game_min_per_sec` su `_process`
**And** la pausa ferma il tempo davvero, e `Engine.time_scale` lo accelera senza che una riga di logica cambi
**And** l'ora di gioco parte dalle 21:00

**Given** `Tuning.night_length_min` raggiunto
**When** l'alba arriva
**Then** la notte si chiude da sola e mostra il riepilogo
**And** si chiude anche se in quel momento è aperto un menu o una fase è in corso

**Given** un `NightPlan` come `.tres`
**When** la notte comincia
**Then** l'orchestratore esegue le fasi di **setup** una volta sola e le fasi di **foto** a ogni scatto, leggendo quali e in che ordine dal `.tres`
**And** automatizzare una fase, in futuro, sarà cancellare una riga dal `.tres` — non modificare l'orchestratore

**Given** una fase che finisce
**When** l'orchestratore avanza
**Then** la transizione passa **sempre** da `call_deferred`, mai da una chiamata diretta dentro la callback
**And** il punteggio viene indicizzato con `phase.key()`, **mai** con `phase.name`

**Given** una build di sviluppo
**When** si premono `F1`-`F4`
**Then** `Engine.time_scale` cambia, e la notte ×10 è disponibile **dal primo giorno**, non aggiunta dopo
**And** l'overlay `F12` mostra ora corrente, minuti trascorsi e `time_scale` accanto a ciò che già mostrava

**Given** una build già esportata
**When** si scrive `user://tuning_override.cfg` e si riavvia
**Then** la durata della notte cambia senza riaprire l'editor e senza ricompilare
**And** nessun punto del codice legge `data/tuning.tres` con `load()`: si passa sempre dall'autoload `Tuning`

---

### Story 2.2: Scegliere cosa fotografare stanotte

As a **gestore notturno**,
I want **aprire il planetario e scegliere un oggetto fra quelli visibili stanotte**,
So that **decidere che tipo di notte sarà sia una scelta mia, e pesi**.

**Acceptance Criteria:**

**Given** i sei target di base portati in `data/targets/*.tres`
**When** la fase di targeting si apre sul CRT
**Then** ogni target mostra sigla, nome, tipo, difficoltà, esposizione minima consigliata e la descrizione in italiano
**And** i dati arrivano da `.tres`, mai da JSON e mai da `FileAccess`

**Given** l'ora corrente della notte
**When** il giocatore scorre il catalogo
**Then** un target fuori dalla propria finestra di visibilità è segnalato come non disponibile adesso, con la finestra in cui lo sarà
**And** la segnalazione è diegetica e in inglese, e non impedisce di guardarlo

**Given** la fase di targeting e la sua sorgente `honest_catalog`
**When** il catalogo viene mostrato e il giocatore lo scorre
**Then** l'elenco dei target e la loro disponibilità a quest'ora vengono da `truth.sample(...)`, con **una sola assegnazione** in tutto `phase_targeting.gd`
**And** la fase non legge **mai** `data/targets/*.tres` direttamente: i `.tres` sono la sorgente dei *dati*, non lo stato osservabile della *fase* — è la sorgente a leggerli
**And** `honest_catalog.tres` ha `resource_local_to_scene = true`, e nell'MVP dice sempre la verità
**And** è lo stesso vincolo della 1.1 e della 2.3, e vale qui per la stessa ragione: l'addendum §3 prevede come rottura della fase 6 **un catalogo falso invece di quello vero**, e una fase che legge il catalogo per conto proprio va riscritta per accoglierla

**Given** un target scelto
**When** la fase si chiude
**Then** l'identificativo del target viaggia nel `payload` del `PhaseResult`
**And** nessuna fase successiva importa qualcosa da `phases/targeting/`: ciò che serve arriva come dato in ingresso

**Given** le regole dell'architettura
**When** si cerca `phases/` dentro `phases/targeting/`
**Then** non c'è nessuna occorrenza

---

### Story 2.3: La posa — configurare la sequenza e lasciarla lavorare

As a **gestore notturno**,
I want **impostare esposizione e numero di frame, avviare, e potermi allontanare**,
So that **la macchina lavori mentre io faccio altro — che è come funziona davvero questo mestiere**.

> È la fase che l'MVP esiste per misurare. Il requisito che conta non è che funzioni: è che
> **non blocchi**.

**Acceptance Criteria:**

**Given** un target selezionato
**When** la fase di imaging si apre
**Then** il giocatore imposta tempo di esposizione e numero di frame, e avvia
**And** ogni frame acquisito consuma `Tuning.min_per_frame` minuti di gioco

**Given** una sequenza avviata
**When** il giocatore si allontana dal monitor
**Then** la fase continua a processare: `runs_in_background()` restituisce `true` e la fase resta viva sotto `PhaseHost`
**And** tornando al monitor il CRT mostra lo **stato vero** — `frame 7/20` — non uno stato ricostruito al ritorno

**Given** la fase in background
**When** gira senza essere visibile
**Then** non chiama mai `get_viewport().size`, non accede alla camera, e non assume che il proprio `Control` sia renderizzato in questo istante
**And** non fa lavoro pesante per frame: sta contando il tempo, non simulando

**Given** la sequenza che finisce
**When** l'ultimo frame è acquisito
**Then** un segnale sonoro lo annuncia, ed è percepibile **da lontano dentro la stanza**, non solo davanti al monitor
**And** il suono è un `AudioStreamPlayer3D` che appartiene **al luogo** — collocato nella stanza — e **non** è figlio della fase: altrimenti si sentirebbe uguale da ogni punto dell'osservatorio
**And** la collocazione regge quando arriveranno cucina e cupola, senza doverla spostare

**Given** lo stato osservabile della sequenza
**When** lo si cerca nel codice della fase
**Then** viene da `truth.sample(...)` come per ogni altra fase, con una sola assegnazione

---

### Story 2.4: Lo stack — vedere per la prima volta cosa hai preso

As a **gestore notturno**,
I want **vedere i frame sommarsi e l'immagine emergere dal rumore**,
So that **ci sia un momento in cui scopro cosa ho catturato, e valga la pena averlo aspettato**.

**Acceptance Criteria:**

**Given** una sequenza completata
**When** lo stacking parte
**Then** l'immagine **emerge progressivamente**: il segnale sale dal rumore sotto gli occhi del giocatore
**And** non è una barra di avanzamento con un risultato in fondo: è la rivelazione, ed è messa in scena

**Given** i punteggi delle fasi della notte in `run.phase_scores`
**When** si calcola la qualità della foto
**Then** l'aggregazione vive in `photo/quality.gd`, è logica pura e istanziabile senza `SceneTree`
**And** le fasi non rifatte per questa foto **ereditano** il punteggio dall'ultima esecuzione
**And** il banco di collaudo stampa il comportamento dell'aggregazione su un caso con punteggi ereditati, perché è il punto in cui è facile sbagliare

**Given** la qualità aggregata
**When** lo stack si conclude
**Then** il punteggio della foto compare come numero accanto all'immagine, in inglese
**And** **nell'MVP l'immagine non si degrada con la qualità**: è una semplificazione decisa il 2026-08-21, non una dimenticanza
**And** la conseguenza è dichiarata e va tenuta d'occhio: l'allineamento polare — la fase più lunga della notte — si vede solo nel numero e nel payout, mai nell'immagine. Se le tre notti di validazione dicono che la fase 3 sembra inutile o gratuita, **questa è la prima cosa da guardare**, e la versione non semplificata è stelle allungate nello stack quando l'allineamento è scarso

---

### Story 2.5: Qualcuno la compra, e paga subito

As a **gestore notturno senza stipendio**,
I want **essere pagato per la foto appena l'ho fatta**,
So that **ogni scatto conti da solo, e le lire entrino mentre la notte è ancora in corso**.

**Acceptance Criteria:**

**Given** una foto completata e stackata
**When** viene venduta
**Then** il payout è **immediato e per-foto**, non un aggregato di fine notte
**And** si calcola da una curva a scaglioni sul punteggio aggregato
**And** l'accredito emette `Events.photo_sold(photo_id, lire)`

**Given** i tre committenti portati in `data/clients/*.tres`
**When** la notte comincia
**Then** uno di loro chiede un soggetto specifico, con il proprio moltiplicatore
**And** il giocatore **può rifiutare la commessa**, e rifiutandola non succede assolutamente niente: nessuna penalità, nessun rimprovero, nessuna conseguenza differita
**And** `privato_g` resta disabilitato: è il gancio della vena creepy e non entra nell'MVP

**Given** il payout mostrato al giocatore
**When** compare a schermo
**Then** compare come **evento diegetico sullo schermo CRT**, dentro l'interfaccia della vendita, in inglese, e non come popup di gioco sopra la scena
**And** **non** richiede il terminale gestionale, che appartiene all'epica 3: nessuna storia dell'epica 2 dipende da una storia futura

**Given** i numeri della curva e dei moltiplicatori
**When** si scrivono nel codice o nei dati
**Then** stanno in `data/`, non in `const` sparse, e sono **dichiarati segnaposto** in un commento
**And** nessuna storia di questo MVP tenta di calibrarli: la curva si tara quando il gioco si è giocato

---

### Story 2.6: Decidere quanto rifare

As a **gestore notturno**,
I want **scegliere se scattarne un'altra, cambiare soggetto, rifare il setup o smettere**,
So that **sia io a decidere che forma ha la notte, e quanto ci tengo a quello che sto facendo**.

**Acceptance Criteria:**

**Given** una foto venduta
**When** il menu post-foto si apre
**Then** offre quattro scelte: *scatta ancora*, *cambia target*, *rifai setup*, *chiudi ed esplora*

**Given** *scatta ancora*
**When** viene scelto
**Then** si riparte dalla fase di imaging con lo stesso target e la stessa configurazione
**And** i punteggi delle fasi precedenti sono ereditati senza rieseguirle

**Given** *cambia target*
**When** viene scelto
**Then** si torna al targeting, e da lì all'imaging
**And** i punteggi delle fasi di setup restano ereditati

**Given** *rifai setup*
**When** viene scelto
**Then** si torna all'allineamento polare e i punteggi delle fasi di setup vengono azzerati
**And** due esecuzioni della stessa fase nella stessa notte non si sovrascrivono a vicenda sotto una chiave sbagliata, perché l'identità è `key()` e non `name`

**Given** *chiudi ed esplora*
**When** viene scelto
**Then** il setup **resta valido** e il giocatore torna nell'osservatorio
**And** finché non è l'alba può riaprire il menu e scattare ancora senza rifare nulla

**Given** l'alba che arriva mentre il menu è aperto
**When** scatta
**Then** il menu si chiude e la notte si conclude comunque

---

### Story 2.7: Il portafoglio è ancora lì la notte dopo

As a **giocatore che tornerà domani**,
I want **ritrovare le mie lire e quello che ho comprato**,
So that **il lavoro di una notte serva a qualcosa nella notte successiva**.

**Acceptance Criteria:**

**Given** una notte conclusa
**When** viene salvata
**Then** `core/save_manager.gd` scrive la `NightRun` con `ResourceSaver` su `user://saves/*.tres`
**And** il file è testo leggibile e apribile in un editor — durante la validazione è un vantaggio, non un rischio

**Given** un save caricato
**When** viene letto
**Then** `migrate()` viene chiamato **sempre**, anche quando non ha niente da fare
**And** il campo `version` esiste dal primo salvataggio mai scritto

**Given** una notte nuova
**When** comincia
**Then** portafoglio e flag di acquisto sono quelli di prima
**And** i punteggi delle fasi della notte precedente non lo sono: appartengono alla notte, non al giocatore

**Given** il banco di collaudo
**When** viene eseguito
**Then** stampa il comportamento della migrazione del save, perché è l'unica cosa che rompe partite già iniziate
**And** un save illeggibile o corrotto non mostra al giocatore uno stack trace né un modale bloccante: diventa una frase gentile

---

## Epic 3: L'attesa — l'osservatorio mentre la posa gira

Mentre la sequenza espone, il monitor non serve. Il giocatore si alza e va per l'osservatorio:
mette su la moka e aspetta che borbotti, sale in cupola a guardare il cielo dalla fessura
mentre il telescopio lavora, e prima o poi si stufa di quella lampada che lampeggia in cucina
e ordina una lampadina per cambiarla.

**È l'epica che risponde alla domanda per cui l'MVP esiste.** Le altre due costruiscono
l'apparato; questa produce il dato. Finché non è finita, l'ipotesi non è stata misurata — ed
è per questo che l'epica 2 non deve allargarsi.

**Le tre attività coprono tre registri diversi** — *fare*, *sistemare*, *stare* — perché
l'ipotesi riguarda il piacere, e le persone lo trovano in cose diverse. E **nessuna delle tre
dà un bonus meccanico**: un bonus le trasformerebbe in faccende da ottimizzare, tutti le
farebbero per convenienza, e la telemetria misurerebbe l'obbedienza invece del piacere.

**FRs:** FR23 (completo), FR26, FR27, FR28, FR29, FR32, FR33 · **UX-DRs:** UX-DR3, UX-DR4 ·
**NFRs rilevanti:** NFR2, NFR10, NFR11, NFR14, NFR17, NFR20, NFR21

---

### Story 3.1: L'osservatorio si allarga — la cucina e la cupola

As a **gestore notturno con venti minuti di posa davanti**,
I want **potermi allontanare dalla stanza computer e andare in cucina o salire in cupola**,
So that **l'attesa abbia un posto dove succedere**.

**Acceptance Criteria:**

**Given** l'osservatorio
**When** il giocatore esce dalla stanza computer
**Then** cucina e cupola esistono come stanze percorribili a piedi, collegate alla stanza computer
**And** il tragitto dalla stanza computer alla cucina si copre in pochi secondi: **andare a fare il caffè non deve diventare un tragitto da subire**, o l'attività misura la pazienza invece del piacere

**Given** il suono di fine sequenza collocato nella stanza computer dalla storia 2.3
**When** il giocatore lo ascolta da altrove
**Then** si sente ovattato dalla cucina e appena dalla cupola
**And** la geografia sonora si verifica camminando, non leggendo il codice
**And** la collocazione decisa nella 2.3 non ha dovuto essere spostata

**Given** ogni stanza
**When** il giocatore ci si trova dentro
**Then** ha il proprio ambiente sonoro, e il silenzio è un elemento attivo — non l'assenza di un suono che manca
**And** la resa usa `ps1.gdshader` e la nebbia dell'`Environment` come il resto del mondo

**Given** la cupola
**When** il giocatore ci entra
**Then** c'è una fessura da cui si vede il cielo, e il telescopio è lì, visibile da vicino

**Given** le regole di dipendenza
**When** si cerca `phases/` o `night/` dentro `world/`
**Then** non c'è nessuna occorrenza

---

### Story 3.2: Il terminale — spendere quello che hai guadagnato

As a **gestore notturno con delle lire in tasca**,
I want **ordinare qualcosa dal terminale del computer**,
So that **il lavoro di stanotte cambi qualcosa in questo posto**.

**Acceptance Criteria:**

**Given** il giocatore seduto al monitor
**When** apre il terminale gestionale
**Then** è un `Control` sul CRT come ogni altra interfaccia, e il CRT non sa cosa sta mostrando

**Given** il terminale aperto
**When** il giocatore lo guarda
**Then** ha cornice ASCII, monospace **verde fosforo su nero**, intestazione con `WALLET` e `NIGHT TAKE`, menu numerato
**And** si naviga con `↑↓`, `ENTER` ed `ESC`, con un beep sui movimenti
**And** il testo dell'interfaccia è **in inglese**; le descrizioni narrative dei prodotti sono **in italiano**, dietro un tasto dedicato
**And** è leggibile a `256×192` da seduti

**Given** il mockup di `economia.md §4`, che elenca cinque categorie
**When** il terminale dell'MVP viene costruito
**Then** ne esistono **due**: `PERSONAL` e `FACILITIES`
**And** le altre **non compaiono affatto**, nemmeno come voci disabilitate: un menu che promette cose che non ci sono è peggio di un menu corto

**Given** i cataloghi portati da `comforts.js` e `facilities.js` in `data/*.tres`
**When** il terminale li mostra
**Then** sono in vendita **solo gli articoli che hanno un effetto implementato** — la moka e la lampadina
**And** gli altri restano nel `.tres` per quando serviranno, ma non si possono comprare: un acquisto che non si vede violerebbe la regola per cui esiste questa epica

**Given** un acquisto
**When** viene confermato
**Then** il portafoglio cala, il flag di acquisto è persistito nel save, e l'effetto nel mondo è immediato
**And** se le lire non bastano, il terminale lo dice in inglese, senza modali e senza toni di rimprovero

---

### Story 3.3: Il caffè — l'attesa piccola dentro l'attesa grande

As a **gestore notturno alle tre di notte**,
I want **mettere su la moka e aspettare che borbotti**,
So that **dentro l'attesa ci sia un rituale che mi va di rifare**.

> È l'attività del registro **fare**. È anche la battuta tematica del gioco messa in
> meccanica: un'attesa piccola dentro un'attesa grande.

**Acceptance Criteria:**

**Given** la moka comprata al terminale
**When** il giocatore entra in cucina
**Then** la moka è lì, visibile, ed è interagibile
**And** prima dell'acquisto non c'è: l'oggetto compare perché è stato comprato

**Given** la moka sul piano
**When** il giocatore la usa
**Then** il rituale è **a più tempi**, e ogni tempo è un'azione separata: riempirla, metterla sul fuoco, aspettare, versare, bere
**And** l'attesa della moka dura un tempo reale percepibile, nell'ordine delle decine di secondi
**And** l'avanzamento si sente: il suono sale, e alla fine borbotta

**Given** il rituale a metà
**When** il giocatore se ne va e torna più tardi
**Then** non si rompe niente, non scade niente, non c'è nessun fallimento
**And** non c'è nessun conto alla rovescia visibile e nessun prompt che solleciti

**Given** un caffè fatto
**When** finisce
**Then** **non dà nessun bonus meccanico**: non alza né abbassa alcun punteggio
**And** da nessuna parte è scritto che potrebbe darne uno, perché non c'è niente da dire

**Given** la telemetria
**When** il rituale comincia e quando si conclude
**Then** emette `Events.wait_activity_started(&"caffe")` al primo tempo del rituale e `Events.wait_activity_ended(&"caffe")` quando il caffè è bevuto
**And** un rituale cominciato e mai concluso resta distinguibile da uno concluso — è uno `started` che non ha il suo `ended`: **l'abbandono è un dato, non un buco**
**And** la durata del rituale si ricava dalla coppia, senza che nessuno debba cronometrarla a parte

**Given** una notte qualsiasi
**When** il giocatore vuole rifarlo
**Then** è ripetibile, più volte per notte e tutte le notti

---

### Story 3.4: La lampada che smette di lampeggiare

As a **gestore notturno infastidito da una lampada che lampeggia**,
I want **ordinare una lampadina e andarla a cambiare**,
So that **questo posto cominci a essere un po' mio**.

> È l'attività del registro **sistemare**: una tantum, comprata, permanente. Ed è il
> dimostratore completo della catena lire → mondo che cambia.

**Acceptance Criteria:**

**Given** la prima notte
**When** il giocatore entra in cucina
**Then** la lampada lampeggia, e il lampeggio è **visibile e udibile**: è un fastidio percepibile, non un dettaglio d'arredo

**Given** la lampadina comprata al terminale
**When** il giocatore torna in cucina
**Then** la lampada è diventata interagibile
**And** cambiarla richiede di essere lì e richiede qualche secondo: non è un interruttore

**Given** la lampadina cambiata
**When** il lavoro finisce
**Then** **l'illuminazione della cucina cambia davvero** — luce stabile al posto di quella intermittente — non un'icona e non una riga di testo
**And** l'effetto è permanente e sopravvive al salvataggio
**And** emette `Events.wait_activity_started(&"lampada")` quando il giocatore comincia a cambiarla e `Events.wait_activity_ended(&"lampada")` quando ha finito — i «qualche secondo» che ci vogliono sono un'attesa piccola come le altre, e vanno misurati come le altre
**And** non dà nessun bonus meccanico

**Given** la lampada sistemata
**When** il giocatore cerca altro da riparare
**Then** non c'è altro: le altre voci di `economia.md §6` restano fuori dall'MVP
**And** il gioco non sostituisce l'attività con un'altra riparazione per tenerlo occupato — **è una tantum per costruzione**, e questo fa parte di ciò che si sta misurando

---

### Story 3.5: La cupola — stare a guardare

As a **gestore notturno**,
I want **salire in cupola e guardare il cielo dalla fessura mentre il telescopio lavora**,
So that **ci sia un modo di passare l'attesa senza fare niente, e che quel niente sia bello**.

> È l'attività del registro **stare**, ed è il test più diretto del pilastro: *l'attesa non va
> riempita di attività, va resa piacevole.* Se funziona solo questa, l'ipotesi è confermata
> più forte che se funzionassero solo le altre due.

**Acceptance Criteria:**

**Given** la cupola
**When** il giocatore guarda attraverso la fessura
**Then** vede il cielo notturno, e il telescopio in primo piano

**Given** una sequenza di imaging in corso
**When** il giocatore osserva il telescopio
**Then** si muove: un inseguimento lento e continuo, percepibile guardandolo per qualche secondo
**And** quando nessuna sequenza è in corso, sta fermo
**And** la cupola sa che una sequenza è in corso **tramite `Events`**, mai interrogando la fase: `world/` non conosce `phases/`

**Given** il giocatore in cupola
**When** si guarda intorno
**Then** non c'è niente da completare, niente da raccogliere, nessun contatore, e **nessun prompt che inviti a interagire**
**And** l'attività non costa nulla e non richiede nessun acquisto

**Given** il giocatore che resta in cupola con una sequenza in corso
**When** ci passa più di qualche secondo
**Then** emette `Events.wait_activity_started(&"cupola")`, e `Events.wait_activity_ended(&"cupola")` quando esce dalla cupola o quando la sequenza finisce — quale dei due arrivi prima
**And** **è la coppia a rendere misurabile lo «stare»**: di un'attività che non si completa, il solo dato è quanto è durata, e senza `ended` quel dato non esiste
**And** l'emissione non produce nessun feedback visibile: il giocatore non deve sapere di essere misurato

**Given** l'ambiente sonoro
**When** il giocatore è lì
**Then** si sentono il cigolio della cupola e il ronzio della montatura, che appartengono al luogo

---

### Story 3.6: La telemetria — trasformare l'impressione in prova

As a **sviluppatore che deve decidere se l'ipotesi regge**,
I want **che ogni notte lasci un file su come è stata passata l'attesa**,
So that **tre notti diverse siano confrontabili, invece di essere tre impressioni**.

> Il criterio di superamento dell'MVP — «giocare tre notti di fila perché va» — è un giudizio
> soggettivo, e va bene che lo sia. Ma da solo non dice **dove** l'attesa si rompe.

**Acceptance Criteria:**

**Given** una notte conclusa
**When** viene scritta la telemetria
**Then** finisce in `user://telemetry/`, un file per notte, **separato dal log**: non passa da `Log`, perché non è un log
**And** è JSON leggibile a occhio

**Given** il file di una notte
**When** lo si apre
**Then** contiene `night`, `tuning_hash`, `wait_total_min`, `wait_activities[]`, `menu_reopened`, `quit_mid_pose`
**And** ogni voce di `wait_activities[]` ha `what`, l'istante `t` in cui è cominciata e la sua `dur` in minuti di gioco, ricavata dalla coppia `started`/`ended`
**And** un'attività cominciata e mai conclusa compare con `dur: null` e `abandoned: true` — **non viene omessa**: un abbandono taciuto si legge come un'attività mai fatta, e sono due cose opposte

**Given** due notti giocate con durate diverse
**When** si confrontano i due file
**Then** `tuning_hash` è presente in entrambi ed è diverso
**And** senza di esso i due file non sarebbero confrontabili e l'esperimento non concluderebbe niente: è obbligatorio, non opzionale

**Given** un tratto di attesa in cui il giocatore non ha fatto niente
**When** viene registrato
**Then** compare come `idle` con la sua durata, calcolato **per differenza**: la finestra della posa meno gli intervalli coperti dalle coppie `started`/`ended`
**And** **i tratti vuoti sono il dato più importante del file**, non una lacuna: sono la misura diretta dell'ipotesi
**And** il calcolo regge anche quando due attività si sovrappongono — il caffè sul fuoco mentre si sale in cupola è il caso normale, non l'eccezione: si uniscono gli intervalli, non si sommano

**Given** una sessione chiusa mentre una posa era in corso
**When** la telemetria viene scritta
**Then** `quit_mid_pose` è vero
**And** è il segnale più forte che l'attesa non regge, e va potuto leggere senza ambiguità

**Given** i dati raccolti
**When** la notte finisce
**Then** restano sul disco locale e non vengono inviati da nessuna parte
**And** non contengono nulla che identifichi una persona
**And** non viene introdotta una sola riga di codice di rete: il progetto è offline per costruzione

---

### Story 3.7: I forum della BBS — leggere mentre la posa gira

As a **gestore notturno con un'ora di posa davanti e un modem sulla scrivania**,
I want **collegarmi alla BBS e leggere cosa si dicono gli altri astrofili**,
So that **l'attesa abbia anche qualcosa da leggere, e questo mestiere abbia qualcuno che lo fa oltre a me**.

> È la **quarta** attività dell'attesa, aggiunta il 2026-08-23 su richiesta di Federico dopo
> aver giocato l'epica 2: «ovviamente ora così è inutile, e noioso. Faremo sì che ci siano i
> forum da leggere ecc...». Le altre tre coprono i registri *fare*, *sistemare* e *stare*;
> questa ne apre un quarto — **leggere** — che è passivo come lo «stare» ma occupa la testa
> invece degli occhi, e non richiede di essere in nessun posto particolare.
>
> Il numero è 3.7 e non 3.6 solo per non rinumerare ciò che esiste: appartiene al gruppo
> delle attività (3.3, 3.4, 3.5), non al blocco della telemetria. **La storia 3.6 deve
> includere `forum` nello schema di `wait_activities[]`.**

**Acceptance Criteria:**

**Given** il modem 56k che è già sulla scrivania come arredo dalla storia 1.2
**When** il giocatore apre la BBS dal monitor
**Then** la connessione **richiede qualche secondo**, con l'handshake che si sente
**And** è un'attesa piccola dentro l'attesa grande, come la moka: il tempo che ci vuole fa parte della cosa, non è un caricamento da nascondere
**And** non costa lire e non richiede nessun acquisto: leggere è gratis, e le due attività a pagamento ci sono già

**Given** la BBS collegata
**When** il giocatore la guarda
**Then** è un `Control` sul CRT come ogni altra interfaccia, e il CRT non sa cosa sta mostrando
**And** ha la stessa cornice ASCII e lo stesso fosforo verde del terminale della 3.2 — **è lo stesso computer**, e due estetiche diverse sullo stesso vetro sarebbero un errore di finzione
**And** l'interfaccia è **in inglese** (voce macchina); i messaggi del forum sono **in italiano**, perché li scrivono delle persone

**Given** i 256×192 del vetro
**When** un messaggio è più lungo di quanto ci stia
**Then** si scorre, e lo scorrimento è **esplicito**: si vede che c'è dell'altro sopra o sotto
**And** nessun messaggio viene troncato in silenzio — **è il difetto che la 2.2 ha pagato**: la descrizione di M42 arrivava tagliata a metà e nessuno se n'era accorto finché non l'ha vista un umano
**And** la leggibilità si verifica **guardandola**, non stimandola

**Given** l'elenco dei messaggi
**When** il giocatore legge
**Then** i contenuti stanno in `data/*.tres` come ogni altro dato del gioco: niente JSON, niente `FileAccess`
**And** ci sono almeno **tre aree** con voci diverse fra loro — non un unico muro di testo dallo stesso autore
**And** i messaggi parlano di astronomia amatoriale, di attrezzatura, di cieli e di notti perse: sono il mondo intorno all'osservatorio, non un tutorial travestito

**Given** un messaggio letto
**When** finisce
**Then** **non dà nessun bonus meccanico**: nessun punteggio, nessuno sconto, nessun target sbloccato, nessun suggerimento che convenga seguire
**And** da nessuna parte è scritto che potrebbe darne uno
**And** in particolare **nessun messaggio contiene informazioni che aiutino a fotografare meglio**: se leggere fosse redditizio smetterebbe di misurare il piacere e comincerebbe a misurare l'obbedienza, che è la regola dichiarata di tutta l'epica

**Given** un messaggio letto una notte
**When** il giocatore torna la notte dopo
**Then** si vede **quali ha già letto**, e la distinzione sopravvive al salvataggio
**And** ne compaiono di nuovi col passare delle notti, così tornarci ha senso
**And** **non c'è nessun contatore di non letti che solleciti**: la differenza fra «lo trovo se lo cerco» e «mi viene chiesto di svuotarla» è la differenza fra un piacere e un dovere

**Given** la posa in corso
**When** il giocatore sta leggendo e la sequenza finisce
**Then** il suono di fine sequenza si sente comunque: è del luogo (storia 2.3), non dell'interfaccia
**And** la BBS non si chiude da sola e non viene coperta da niente — **si finisce di leggere la riga**, e poi si decide

**Given** la telemetria
**When** la lettura comincia e quando si conclude
**Then** emette `Events.wait_activity_started(&"forum")` all'apertura e `Events.wait_activity_ended(&"forum")` alla chiusura
**And** una sessione aperta e mai chiusa resta distinguibile — è uno `started` senza il suo `ended`, e l'abbandono è un dato
**And** l'emissione non produce nessun feedback visibile: il giocatore non deve sapere di essere misurato

**Given** le regole di dipendenza
**When** si cerca `phases/` dentro `crt/`, o `world/` dentro `night/`
**Then** non c'è nessuna occorrenza, come per ogni altra interfaccia diegetica


---

## Validation

Eseguita il **2026-08-21** sul documento reale, non a memoria.

### Copertura dei requisiti — FR per storia

| Storia | FR coperti |
|---|---|
| 1.1 | FR7, FR8, FR9, FR16, FR34, FR36, FR37 |
| 1.2 | FR23 (parziale), FR24 |
| 1.3 | FR25 |
| 2.1 | FR1, FR2, FR5, FR6, FR18, FR35 |
| 2.2 | FR10, FR11, FR12, FR16 (targeting) |
| 2.3 | FR13, FR14, FR15, FR16 (imaging) |
| 2.4 | FR17, FR19 |
| 2.5 | FR20, FR21, FR22 |
| 2.6 | FR3, FR4, FR17 (eredità esercitata), FR18 (caso «rifai setup») |
| 2.7 | FR30, FR31 |
| 3.1 | FR23 (completo), FR15 (verifica sul campo) |
| 3.2 | FR28, FR29 |
| 3.3 | FR26, FR27, FR29 |
| 3.4 | FR26, FR27, FR29 |
| 3.5 | FR26, FR27 |
| 3.6 | FR32, FR33 |

**37 FR su 37 coperti.** Nessuno resta senza almeno una storia, e nessuno è coperto da un
solo accenno: ogni FR ha almeno un criterio di accettazione verificabile.

**11 UX-DR su 11 coperti** — UX-DR1/2 (1.3, 3.2), UX-DR3/4 (3.2), UX-DR5 (1.3, 3.2),
UX-DR6 (1.3), UX-DR7 (1.1), UX-DR8 (2.3, 3.1), UX-DR9 (1.2), UX-DR10 (2.5), UX-DR11 (1.1).

### Verifiche di struttura

| Verifica | Esito | Note |
|---|---|---|
| Starter template | **N/A, verificato** | L'architettura dichiara esplicitamente *nessuno starter template*, e il progetto è già inizializzato. Al suo posto la storia 1.1 si fa carico della **sostituzione del punto d'ingresso**, che è il lavoro di setup realmente necessario |
| Risorse dati create solo dove servono | ✅ | I target nascono in 2.2, i committenti in 2.5, comfort e riparazioni in 3.2. Nessuna storia crea tutti i `.tres` in anticipo |
| Dipendenze in avanti fra storie | ✅ dopo correzione | Una violazione trovata e corretta — vedi sotto |
| Indipendenza delle epiche | ✅ | L'epica 2 funziona senza l'epica 3; l'epica 3 usa 1 e 2 e sta in piedi da sola |
| Churn sugli stessi file | ✅ con motivazione | Vedi sotto |
| Placeholder residui | ✅ | nessuno |
| Aderenza al template | ✅ | 16 storie, 16 nel formato *As a / I want / So that*, 16 blocchi di criteri, **81** blocchi `Given` (erano 80: +1 dalla revisione del 2026-08-21, vedi sotto) |

### Churn sui file — l'unica sovrapposizione, accettata con motivazione

`world/` è toccato dall'epica 1 (giocatore, stanza computer, contratto di interazione) e
dall'epica 3 (cucina, cupola, oggetti delle attività). **È estensione, non riscrittura:**
l'epica 3 aggiunge file accanto a quelli dell'epica 1 senza modificarli.

Il consolidamento è stato considerato e rifiutato: l'epica 1 **non può esistere** senza una
stanza e un giocatore — non ci si siede a un CRT dal vuoto — e spostare quel lavoro
nell'epica 3 renderebbe l'epica 1 non giocabile, cioè distruggerebbe il gate di rischio che
è la sua unica ragione di essere.

Il caso opposto era già stato risolto a monte: orchestrazione e ciclo foto erano stati
abbozzati come due epiche e sono stati **fusi nell'epica 2**, perché avrebbero riscritto a
vicenda `night_session` senza che in mezzo si imparasse niente.

### Problemi trovati e risolti durante la validazione

**1. Dipendenza in avanti dall'epica 2 all'epica 3.** La storia 2.5 chiedeva che il payout
comparisse «sul terminale» — ma il terminale gestionale nasce nella storia 3.2. Una storia
dell'epica 2 dipendeva da una storia futura di un'altra epica.
→ Risolto: il payout compare sullo schermo CRT dentro l'interfaccia della vendita, che esiste
già nell'epica 2, e la storia lo dichiara esplicitamente.

**2. La storia 1.1 non diceva cosa mostra `main.tscn` dopo la cancellazione di `spike/`.**
La conseguenza — cancellando lo spike sparisce l'unica stanza esistente — era stata discussa
ma non era finita nel documento. Un agente che legge solo questo file non l'avrebbe saputa.
→ Risolto: la 1.1 dichiara il ponte temporaneo e dichiara che la 1.3 non butterà via niente
di quel lavoro.

**3. La degradazione visiva dello stack era una decisione aperta travestita da requisito.**
La storia 2.4 chiedeva che una foto di bassa qualità producesse un'immagine visibilmente
peggiore.
→ Risolto con una decisione esplicita di Federico il 2026-08-21: **nell'MVP l'immagine non si
degrada**, si semplifica. La conseguenza è annotata dentro la storia come prima cosa da
guardare se la fase 3 risultasse gratuita.

### Revisione del 2026-08-21 — due difetti chiusi dopo la verifica di prontezza

`implementation-readiness-report-2026-08-21.md` ha ricontrollato questa sezione trattandola come
**non verificata**, ed è stato giusto: due dei suoi rilievi critici erano difetti reali che
l'autovalutazione non poteva vedere, perché verifica ciò che il documento dice di sé e non ciò
che tace. Entrambi sono chiusi qui.

**C2 — la fase 6 era l'unica delle tre senza sorgente di verità.** La storia 2.2 non nominava
`truth` da nessuna parte, mentre 1.1 e 2.3 avevano l'AC corretto. La tabella di copertura qui
sopra mappava FR16 alla sola storia 1.1, il che rendeva il buco invisibile — ma FR16 dice «ogni
fase», e l'addendum §3 prevede come rottura della fase 6 proprio *un catalogo falso invece di
quello vero*.
→ Risolto: la storia 2.2 ha ora il suo blocco su `honest_catalog`; FR16 è dichiarato
cross-cutting e mappato a 1.1, 2.2 e 2.3.

**C4 — il condotto della misura non reggeva i criteri che ci poggiavano sopra.**
`Events.wait_activity(what)` portava un solo argomento: la durata di un'attività non era
ricavabile, i tratti `idle` nemmeno, e un rituale abbandonato si sarebbe distinto da uno
concluso solo contando la parità delle emissioni — che la cupola, emettendo una volta sola,
avrebbe rotto subito.
→ Risolto: `wait_activity_started(what)` / `wait_activity_ended(what)`, due signal in coppia.
Cambiato in `autoloads/events.gd` finché nessuno lo usava ancora. Aggiornate FR27, le storie
3.3, 3.4, 3.5 e 3.6, e lo schema di telemetria in `game-architecture.md § Logging`, che ora
porta `dur` per ogni voce e `abandoned: true` per le attività interrotte.

**Restano aperti** i due critici che non riguardano la prima storia: **C1** — non esiste un
contenitore per lo stato che attraversa le notti, e `Game.start_night()` azzera il portafoglio —
da chiudere prima della storia 2.7; e **C3** — la telemetria ha tre collocazioni contraddittorie
e nessun proprietario — da chiudere prima della 3.6. Più sei rilievi maggiori, nel report.

### Cosa questo documento non contiene, per costruzione

Le altre sette fasi · le rotture e le anomalie · storia, metanarrazione, rete di osservatori,
esplorazione esterna · la calibrazione economica.

E due decisioni che restano deliberatamente aperte, perché non si decidono a tavolino:
**quanto deve durare la notte** — è la variabile sperimentale, si prova — e **se le tre
attività dell'attesa bastano**, che è precisamente ciò che l'MVP esiste per scoprire.

### Pronto per

Implementazione, a partire dalla **storia 1.1**, che è anche il quarto dei sei primi passi
dell'architettura: *la fase 3 completa, con l'iniettore `F9` insieme. Non dopo.*
