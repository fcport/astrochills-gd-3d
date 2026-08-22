# Epic 2 Context: Una notte di lavoro, dall'arrivo all'alba

<!-- Generated from planning artifacts. Regenerate with compile-epic-context if planning docs change. -->

## Goal

L'epica costruisce il ciclo completo di una notte di lavoro come un unico componente end-to-end (`night/night_session`): il giocatore arriva alle 21:00, esegue il setup una volta, sceglie un soggetto fra sei oggetti reali del cielo, configura la posa e la avvia, vede i frame sommarsi in un'immagine che emerge, la vende subito, e decide quanto rifare — finché l'alba non chiude la notte da sola. La notte successiva ritrova il portafoglio dov'era. Conta perché risponde alla domanda «il ciclo di una notte funziona?»: se no, il loop va ridisegnato prima di arredarlo (epica 3). Le storie aggiungono un anello alla volta alla stessa catena — a ogni storia la notte è giocabile, finisce solo un po' prima. È un'epica sola e non tre perché orchestrazione, fasi della foto, stacking e vendita costruiscono lo stesso file da capo a fondo, e spezzarla produrrebbe epiche che si riscrivono a vicenda.

## Stories

- Story 2.1: Un turno che comincia alle 21:00 e finisce da solo all'alba
- Story 2.2: Scegliere cosa fotografare stanotte (fase targeting)
- Story 2.3: La posa — configurare la sequenza e lasciarla lavorare (fase imaging)
- Story 2.4: Lo stack — vedere per la prima volta cosa hai preso
- Story 2.5: Qualcuno la compra, e paga subito

## Requirements & Constraints

- **La notte è a orologio, non a ora reale.** Comincia alle 21:00, l'alba scatta quando `elapsed_min >= Tuning.night_length_min`. Il tempo è un accumulatore su `_process` (`elapsed_min += delta * Tuning.game_min_per_sec`): rispetta pausa e `Engine.time_scale`, così la notte ×10 per collaudo è gratis.
- **L'alba chiude la notte da sola**, anche a menu aperto o con una fase in corso, e mostra il riepilogo.
- **Orchestrazione data-driven.** Un `NightPlan` (`.tres`) dice quali fasi e in che ordine: le fasi di **setup** girano una volta per notte, quelle di **foto** una volta per scatto. Automatizzare una fase in futuro = cancellare una riga dal `.tres`, non toccare l'orchestratore.
- **Menu post-foto a quattro voci:** scatta ancora (riparte dalla 10), cambia target (torna alla 6), rifai setup (torna alla 3, punteggi azzerati), chiudi ed esplora. «Chiudi ed esplora» conserva il setup: fino all'alba si può riaprire e scattare ancora senza rifare nulla.
- **Fase 6 (targeting):** catalogo dei 6 target base (M42, M13, M45, M31, M57, M8) con tipo (NEB/GAL/GLOB/OPEN/PLN), difficoltà, esposizione minima consigliata, finestra di visibilità oraria e descrizione IT già scritta. Un target fuori dalla sua finestra di visibilità all'ora corrente è segnalato non disponibile adesso (segnalazione diegetica, in inglese, non blocca la consultazione).
- **Fase 10 (imaging):** il giocatore imposta esposizione e numero di frame, poi avvia; la sequenza avanza in tempo reale consumando `Tuning.min_per_frame` per frame. **Non blocca:** resta viva sotto `PhaseHost` mentre il giocatore si allontana; al ritorno il CRT mostra lo stato vero (`frame 7/20`), mai ricostruito. La fine è annunciata da un suono percepibile da lontano nella stanza.
- **Stacking come rivelazione:** l'immagine emerge progressivamente dal rumore sotto gli occhi del giocatore — messa in scena, non una progress bar con un risultato in fondo. **Nell'MVP l'immagine non degrada con la qualità** (semplificazione dichiarata: la polare si vede solo nel numero/payout).
- **Qualità aggregata:** ogni foto ha un punteggio calcolato dai punteggi delle fasi che la compongono; le fasi non rifatte **ereditano** il punteggio dall'ultima esecuzione. Punteggi indicizzati con `Phase.key()`, **mai** `phase.name`.
- **Vendita:** payout immediato **per foto** (non aggregato di fine notte), da una curva a scaglioni sul punteggio aggregato; accredito sul portafoglio + `Events.photo_sold(photo_id, lire)`.
- **Commessa notturna:** uno dei 3 committenti chiede un soggetto e applica il suo moltiplicatore. Il giocatore **può rifiutarla e non succede niente** — nessuna penalità né conseguenza differita; il «niente» è materiale, va reso percepibile.
- **Persistenza:** save/load della `NightRun` con `ResourceSaver` su `.tres` in `user://saves/`, con campo `version` e `migrate()` chiamato al load **anche quando è vuoto**. Portafoglio e flag d'acquisto sopravvivono all'alba — sono ciò che collega una notte alla successiva. `core/save_manager.gd` va scritto (manca).
- **Numeri = segnaposto dichiarati.** Curva a scaglioni e moltiplicatori esistono come meccanismo; la calibrazione è rinviata per decisione. Non tararli ora.
- **Fuori scopo epica 2:** telemetria (`user://telemetry/`, `tuning_hash`), attività dell'attesa, terminale gestionale, cucina/cupola — sono epica 3. Le altre sette fasi, rotture/anomalie, `privato_g`, rete di osservatori: fuori scopo per costruzione.

## Technical Decisions

- **ADR-001 (vincolo non negoziabile), qui esteso a targeting e imaging.** Lo stato osservabile di ogni fase ha **una sola assegnazione** in tutto il file, e viene da `truth.sample(...)`. Per il targeting la sorgente è `honest_catalog` (`resource_local_to_scene = true`): la fase **non legge mai** `data/targets/*.tres` direttamente — i `.tres` sono la sorgente dei *dati*, la sorgente li legge e produce lo stato osservabile. Motivo: la rottura prevista della fase 6 è un catalogo falso, e una fase che legge il catalogo per conto proprio andrebbe riscritta per accoglierla. Nell'MVP le sorgenti dicono sempre la verità, ma non si salta la sorgente.
- **ADR-002 — fasi autonome.** Una scena per fase; una fase non importa **mai** da un'altra fase. Il target scelto viaggia nel `payload` del `PhaseResult` e raggiunge la fase 10 **come dato in ingresso**. Verificabile: `grep "phases/"` dentro `phases/targeting/` deve dare zero occorrenze.
- **Pattern 2 — la fase che non blocca.** `runs_in_background()` restituisce `true` per l'imaging; la fase resta viva sotto `PhaseHost` fuori dalla vista. Una fase in background **non assume mai** di essere visibile: niente `get_viewport().size`, niente accesso alla camera, nessun lavoro pesante per frame (conta il tempo, non simula). Il suono di fine sequenza è un `AudioStreamPlayer3D` che **appartiene al luogo** (collocato nella stanza), **non** figlio della fase — altrimenti si sentirebbe uguale ovunque; la collocazione deve reggere quando arriveranno cucina e cupola.
- **Transizioni di fase sempre `call_deferred`**, mai chiamata diretta dentro la callback (altrimenti si libera il nodo mentre esegue il proprio `_process`). Il CRT **non libera mai** il `Control`: la proprietà resta della fase; l'orchestratore chiama `crt.show_control(null)` **prima** di liberare la fase.
- **Aggregazione qualità in `photo/quality.gd`**: logica pura, istanziabile senza `SceneTree`. Legge `run.phase_scores`. Il banco `tests/test_bench.tscn` (nessun framework) deve stampare il comportamento su un caso con punteggi ereditati.
- **Tuning:** i valori scelti stanno in `data/tuning.tres` e si leggono **sempre** dall'autoload `Tuning`. Mai `load("res://data/tuning.tres")` (scavalcherebbe l'override in silenzio). L'override `user://tuning_override.cfg` deve funzionare **su build già esportata**.
- **Save versionato dal primo giorno** con `migrate()` sempre chiamato: è l'unica cosa che rompe partite già iniziate.
- **Confini fra cartelle:** `core/` non dipende da niente; `phases/` solo da `core/`; `night/` non conosce `world/`; `crt/` non conosce le fasi. Cartelle da creare: `phases/{targeting,imaging}/sources`, `night/`, `photo/`, `data/{targets,clients}`.
- **Due canali che non si toccano:** `push_error()`/`assert()` per errori di programma, `PhaseResult` per esiti diegetici — non si mescolano mai. Segnali tipizzati, `snake_case` al passato; `EventBus` solo per fatti di notte con più di due ascoltatori.
- **Dati:** solo `.tres` in `data/`, nessun JSON né `FileAccess` nel gameplay. Portare da `../phaser_astrochill/src/data/`: `dso_base.js` → `data/targets/` (6 target), `clients.js` → `data/clients/` (3 committenti: Coelum ×1.0, Astrofili Marche ×0.6, BBS Cygnus ×1.4; `privato_g` disabilitato). Attenzione: i committenti (comprano) non sono gli osservatori della rete — solo i primi esistono.
- **Strumenti di debug:** `F1`-`F4` controllano `Engine.time_scale` (notte ×10 dal primo giorno); l'overlay `F12` mostra ora corrente, minuti trascorsi e `time_scale`. Esistono solo con `OS.is_debug_build()`.
- **Vincoli tecnici di piattaforma:** Godot 4.7.2, renderer Compatibility, GDScript tipizzato. Estetica PS1 con valori validati (`stretch_shrink = 2`, `snap_resolution = 665`, CRT minimo `256×192`); nessun filtro lineare, mipmap, AA o bloom. Nessun networking, mai.

## UX & Interaction Patterns

- **Ogni interfaccia di fase è un `Control` mostrato sul CRT diegetico** via `crt.show_control(...)`, non UI a schermo. Il CRT non sa mai cosa mostra.
- **Leggibilità a `256×192`:** targeting e imaging devono essere leggibili da seduti, verificato guardando e non stimando. Testo software in inglese; descrizioni narrative dei target in italiano.
- **Feedback di fine sequenza udibile da un'altra stanza** (UX-DR8) — appartiene al luogo, non alla fase.
- **Il payout compare come evento diegetico** sullo schermo del terminale (UX-DR10), non come popup di gioco sopra la scena. Nessun modale bloccante, nessuno stack trace mostrato al giocatore, tono cozy.

## Cross-Story Dependencies

- **2.1 è il fondamento:** `night_session` + orologio + `NightPlan` reggono tutte le altre; senza, non c'è orchestratore che invochi targeting, imaging, stacking e vendita.
- **2.2 → 2.3 → 2.4 → 2.5** è una catena di dati: il target scelto (2.2) entra nel `payload` e alimenta la posa (2.3); i frame acquisiti alimentano lo stack (2.4); la qualità aggregata alimenta il payout (2.5).
- **Dipendenza dall'epica 1:** riusa i contratti `core/` (`Phase`, `PhaseResult`, `PhaseTruthSource`, `NightRun`), il pattern sorgente/verità stabilito nella 1.1, e la postazione seduta al CRT + `show_control` costruiti nelle storie 1.2/1.3. `save_manager.gd` è nuovo qui.
- **Verso l'epica 3:** il ritorno al CRT durante la posa (2.3) è già, in piccolo, l'esperienza dell'attesa che l'epica 3 misurerà; la collocazione del suono nel luogo (2.3) deve reggere all'arrivo di cucina e cupola.
