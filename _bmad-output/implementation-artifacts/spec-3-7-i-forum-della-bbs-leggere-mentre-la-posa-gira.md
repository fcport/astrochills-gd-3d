---
title: "3.7 I forum della BBS — leggere mentre la posa gira"
type: 'feature'
created: '2026-08-24'
status: 'awaiting-operator'
review_loop_iteration: 0
followup_review_recommended: false
baseline_revision: '635532e180277d0b209800a2896b7fb39fc0adfa'
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
warnings: ['oversized']
deferred:
  - summary: >-
      Game.mark_forum_read (mutazione di forum_read + save sul path reale) non è esercitato end-to-end dal banco: solo PlayerProfile.mark_read/has_read e il round-trip su un path di override lo sono.
    evidence: |-
      tests/test_bench.gd (_check_forum) collauda ForumBoard.available(night), mark_read/has_read e il round-trip save/load su "user://saves/_bench_forum" (path di override, per non clobberare il save del giocatore). Ma Game.mark_forum_read salva su "user://saves/profile.tres" senza override: chiamarlo dal banco scriverebbe sul save reale. È la stessa limitazione della 3.2 (Game.spend_lire non esercitato end-to-end per l'accoppiamento ai path di save). La glue autoload (mutazione+save sul path reale) resta verificabile solo camminando il gioco.
    location: >-
      autoloads/game.gd (mark_forum_read) ; tests/test_bench.gd
    severity: low
operator_actions:
  - "Camminare il gioco durante l'attesa (menu post-foto vivo): sedersi al monitor, premere B per aprire la BBS, e ASCOLTARE l'handshake del modem 56k (qualche secondo, vista CONNECTING) — l'audio non è verificabile headless (driver Dummy nel cancello)."
  - "Verificare a 256×192 da seduti la leggibilità e che è LO STESSO COMPUTER del terminale: stessa cornice a linea singola, stesso fosforo verde, interfaccia EN (CYGNUS BBS, EQUIPMENT/DEEP SKY/OFF TOPIC) e messaggi IT. (Il rendering statico è già stato controllato con una sonda usa-e-getta via screenshot; qui serve il giudizio percettivo dal vero.)"
  - "Aprire il messaggio lungo (M42 vista da un balcone di città): confermare che lo scorrimento è ESPLICITO — i triangoli ▲/▼ con la scritta MORE compaiono in alto/in basso quando c'è altro sopra/sotto — e che nessuna riga è troncata in silenzio, scorrendo fino in fondo con ↑/↓."
  - "Provare la persistenza dei letti: leggere un messaggio (torna in DIM nell'elenco), andare a dormire e riaprire la BBS la notte dopo — il letto deve restare letto. Dopo la notte 2 deve comparire 'Perso un ortoscopico nel prato', dopo la notte 3 'Serata pubblica in piazza' (nuovi messaggi col passare delle notti)."
  - "Provare la mutua esclusione e l'integrazione della postazione: con il terminale aperto (T) la BBS (B) non deve aprirsi e viceversa; premere E chiude la BBS e alza dalla sedia ripristinando il contenuto della notte; se la posa finisce mentre si legge, il chime di fine sequenza si sente (è del luogo) e la BBS NON si chiude da sola; all'alba il riepilogo vince sulla BBS."
  - "Rifinire quando arriva il pack asset: il beep e l'handshake del modem sono onde sintetizzate in codice (nessun asset audio) e la cornice è un rettangolo di contorno (non caratteri box-drawing) — provvisori, da sostituire senza toccare la logica."
---

<intent-contract>

## Intent

**Problem:** L'attesa dell'epica 3 ha tre attività — *fare* (caffè, 3.3), *sistemare* (lampada, 3.4), *stare* (cupola, 3.5) — ma manca il registro del **leggere**. Federico, dopo aver giocato l'epica 2, ha giudicato l'attesa «inutile e noiosa»: serve qualcosa da leggere mentre la posa gira, e qualcuno che faccia questo mestiere oltre al giocatore.

**Approach:** Aggiungere la **BBS**, un secondo `Control` diegetico sul CRT — *lo stesso computer* del terminale (3.2): stessa cornice ASCII, stesso fosforo verde, aperto da seduti al monitor durante l'attesa con un tasto dedicato. Mostra messaggi di forum organizzati in almeno tre aree; la connessione col modem 56k (già arredo dalla 1.2) richiede qualche secondo con l'handshake udibile. I letti si distinguono e sopravvivono al save (`PlayerProfile.forum_read`), nuovi messaggi compaiono col passare delle notti, i messaggi lunghi si scorrono in modo esplicito. Nessun bonus meccanico, nessun aiuto a fotografare. All'apertura emette `Events.wait_activity_started(&"forum")`, alla chiusura `wait_activity_ended(&"forum")`.

## Boundaries & Constraints

**Always:**
- **È lo stesso computer del terminale (3.2):** stessa cornice a linea singola, stesso fosforo verde su nero, stesso font monospace, stesso beep sintetizzato in codice. Due estetiche diverse sullo stesso vetro sarebbero un errore di finzione.
- **Il CRT non sa cosa mostra:** la BBS è un `Control` consegnato con `CrtScreen.show_control()`, come il terminale e le schermate di `night/`. Vive in una cartella nuova `bbs/` che dipende **solo** da `core/`, `data/` e dagli autoload (`Game`, `Events`). Cercare `world/`, `night/`, `phases/` dentro `bbs/` deve dare zero — nemmeno nei commenti. Il ponte world↔night↔bbs è `main.gd`, l'unico che conosce entrambe le sponde.
- **La connessione è un'attesa piccola dentro l'attesa grande** (come la moka): all'apertura c'è un handshake che si sente e dura qualche secondo, e il tempo che ci vuole fa parte della cosa, non è un caricamento da nascondere. Il beep/handshake è sintetizzato in codice (nessun asset d'arte — provvisorio).
- **Leggere è gratis:** non costa lire, non richiede nessun acquisto. Le due attività a pagamento (moka, lampadina) ci sono già dal terminale.
- **Lingua (NFR10):** la cornice/interfaccia della BBS è in **inglese** (voce macchina, come le intestazioni EN del terminale: `WALLET`, `PERSONAL`); il **contenuto scritto da persone** — soggetto e corpo dei messaggi — è in **italiano**. Gli handle degli autori restano com'è (nickname scelti da persone).
- **Leggibilità CRT `256×192` da seduti:** nessun testo troncato in silenzio. I messaggi più lunghi del vetro si **scorrono**, e lo scorrimento è **esplicito**: un indicatore visibile dice che c'è dell'altro sopra o sotto. La verifica si fa **guardando**, non stimando.
- **Contenuti data-driven in `data/*.tres`:** niente JSON, niente `FileAccess` per i testi (anti-pattern #6). Almeno **tre aree** con voci diverse fra loro; i messaggi parlano di astronomia amatoriale, attrezzatura, cieli e notti perse — il mondo intorno all'osservatorio, non un tutorial travestito.
- **I letti si distinguono e persistono:** `PlayerProfile.forum_read: Array[StringName]` (default `[]`, nessun bump di `CURRENT_VERSION`, come `owned_items`); il salvataggio passa **solo** da `Game` (`Game.mark_forum_read(id)`, sul modello di `mark_lamp_fixed`). Un messaggio letto una notte resta letto la notte dopo.
- **Nuovi messaggi col passare delle notti:** ogni messaggio ha `appears_from_night: int` (default 1); è visibile solo quando la notte corrente (`Game.run.night_index`) lo raggiunge. Così tornarci ha senso.
- **Nessun bonus meccanico, mai:** leggere non dà nessun punteggio, sconto, target sbloccato o suggerimento redditizio; da nessuna parte è scritto che potrebbe. In particolare **nessun messaggio contiene informazioni che aiutino a fotografare meglio** (regola dichiarata di tutta l'epica).
- **Opzionale e senza fallimento:** nessun conto alla rovescia, nessun prompt che solleciti, **nessun contatore di non letti**. La distinzione letto/non-letto è visibile per riga (si trova se la si cerca), non un badge che chiede di essere svuotato.
- **Il suono di fine sequenza è del luogo, non dell'interfaccia:** se la posa finisce mentre si legge, il chime (2.3, `world/sequence_chime.gd`) si sente comunque. La BBS **non si chiude da sola** e non viene coperta da niente: si finisce di leggere la riga, poi si decide.

**Block If:**
- Tracciare i letti o far comparire nuovi messaggi richiederebbe di cambiare il **formato del save** in modo incompatibile con i profili esistenti (bump di `PlayerProfile.CURRENT_VERSION` + `migrate()` che tocca il contratto della 2.7): HALT `blocked`, condizione `read-tracking richiede un cambio di formato del save incompatibile`. (Con default `[]` non deve accadere — un save vecchio senza il campo è correttamente «niente letto».)

**Never:**
- Niente rete, niente networking (mai, in tutto il progetto): la «connessione BBS» è finzione locale, nessun socket, nessun `HTTPRequest`.
- La BBS non conosce `world/`, `night/`, `phases/`; `night/` non conosce `bbs/`. Nessun import fra Control diegetici e fasi.
- Niente moka/lampada/cupola qui: quelle sono 3.3/3.4/3.5. Questa storia costruisce solo la BBS.
- Niente modali di sistema, niente stack trace, niente codici d'errore Godot sul CRT: un contenuto mancante è canale 1 (`push_error`), il vetro resta pulito.
- Non toccare la coreografia ADR-003 (seduta/alzata), la fase polare, né le azioni `polar_*`. Non modificare il terminale (3.2) né le sue azioni.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Apertura BBS | Seduto al monitor, `is_waiting()` vero, terminale non aperto | `bbs_open` mostra la BBS sul CRT; handshake udibile per qualche secondo; emette `wait_activity_started(&"forum")` | Se non in attesa (fase/vendita/rivelazione a schermo) o terminale aperto, il tasto non apre nulla |
| Chiusura BBS | BBS aperta, `bbs_back`/`bbs_open`/`interact` | La BBS si chiude, `night/` ri-mostra il suo contenuto (menu post-foto o niente); emette `wait_activity_ended(&"forum")` | Idempotente: chiudere due volte non riemette |
| Lettura messaggio | Messaggio selezionato, `menu_confirm` | Si apre la vista di lettura; il messaggio è marcato letto (`Game.mark_forum_read`, salvato); corpo IT a schermo | Se già letto, nessuna doppia scrittura (idempotente) |
| Messaggio lungo | Corpo più alto del vetro, vista di lettura, `menu_up`/`menu_down` | Lo scorrimento è esplicito (indicatore ▲/▼); nessuna riga troncata in silenzio | Cursore di scroll clampato agli estremi |
| Nuova notte | `Game.run.night_index` cresce | Compaiono i messaggi con `appears_from_night <= night_index`; i letti restano marcati | — |
| Fine sequenza mentre si legge | `phase_finished(&"imaging")` con BBS aperta | Il chime del luogo si sente; la BBS resta aperta e in cima | La BBS non reagisce all'evento (indipendente dall'interfaccia) |
| Alba con BBS aperta | `dawn_reached` con BBS aperta | `main.gd` sgancia lo stato e riparcheggia la BBS senza ripristinare (il riepilogo vince); emette `wait_activity_ended(&"forum")` | Nessun conflitto sul viewport |
| Forum assente/illeggibile | `forum.tres` mancante o non parsabile | `load` torna `null`; la BBS mostra le aree vuote senza crash, avviso su canale 1 | Nessun crash |
| Sessione mai chiusa (quit) | BBS aperta, il gioco viene chiuso | `started` senza `ended`: è un abbandono, un dato per la telemetria (3.6), non un buco | — |

</intent-contract>

## Code Map

- `data/forum/forum_message.gd` -- **NEW.** Resource `ForumMessage` sul modello di `data/catalog/item_data.gd`: `id: StringName`, `author: String` (handle), `subject: String` (IT), `@export_multiline body: String` (IT), `appears_from_night: int = 1`. Solo dati.
- `data/forum/forum_board.gd` -- **NEW.** Resource `ForumBoard` sul modello di `data/catalog/item_catalog.gd`: `id: StringName`, `title: String` (EN, come le categorie del terminale), `@export messages: Array[ForumMessage] = []`, e `available(night: int) -> Array[ForumMessage]` (filtro **puro**: messaggi con `appears_from_night <= night`, ordine del `.tres`).
- `data/forum/forum_data.gd` -- **NEW.** Resource `ForumData` (il collettore, come `ItemCatalog` raccoglie gli item): `@export boards: Array[ForumBoard] = []`.
- `data/forum/*.tres` -- **NEW.** Almeno **tre** board (`.tres`) con voci diverse (es. `equipment.tres`, `deep_sky.tres`, `off_topic.tres`), ciascuna con più messaggi IT; **almeno un** messaggio con `appears_from_night > 1` per provare la comparsa nel tempo; **almeno un** messaggio lungo (corpo che eccede il vetro) per provare lo scroll. `forum.tres` raccoglie i board. Contenuto: astronomia amatoriale, attrezzatura, notti perse — **nessun** suggerimento su come fotografare meglio.
- `bbs/bbs.gd` + `bbs/bbs.tscn` -- **NEW.** Il `Control` della BBS. Riusa il modello di disegno/input di `terminal/terminal.gd`: `DESIGN_SIZE (256,192)`, colori `BG/FG/DIM/SEL`, `SystemFont` monospace, `_install_beep()`/`_play_beep()`, `_wrap()`, `_text()`, `_unhandled_input()`, `signal closed()`, `arm()`. Due viste: **elenco** (board come intestazioni, messaggi numerati con soggetto+autore, letti in `DIM`/non-letti in `FG`) e **lettura** (corpo scorribile con indicatore ▲/▼ esplicito). `activate()` emette `wait_activity_started(&"forum")`; `deactivate()` emette `wait_activity_ended(&"forum")` (idempotenti, guardia `_active`). Marca letto via `Game.mark_forum_read(id)` all'apertura del messaggio. Handshake: beep/rumore sintetizzato per ~qualche secondo all'`arm()`.
- `core/player_profile.gd` -- **estendere.** Aggiungere `forum_read: Array[StringName] = []` con `has_read(id) -> bool` e `mark_read(id)` (idempotente), sul modello esatto di `owned_items`/`owns()`/`mark_owned()` (righe 63-88). Default `[]`, **nessun** bump di `CURRENT_VERSION` (commento come per `owned_items`).
- `autoloads/game.gd` -- **estendere.** Aggiungere `mark_forum_read(id: StringName)` sul modello di `mark_lamp_fixed()` (righe 118-120): `profile.mark_read(id)` + `_saves.save_profile(profile)`. La persistenza resta di `Game`, unico chiamante di `SaveManager`.
- `main.gd` -- **estendere.** Aggiungere un secondo Control parallelo al terminale: `const BBS := preload("res://bbs/bbs.tscn")`, var `_bbs`/`_bbs_open`, `_setup_bbs()` (come `_setup_terminal`, righe 436-449), `_toggle_bbs()`/`_close_bbs()`/`_park_bbs()` (come le omologhe del terminale, 458-513), intercetta `bbs_open` in `_shortcut_input()` (accanto a `terminal_open`, riga 653). **Mutua esclusione:** aprire la BBS solo se `_terminal_open == false`, e aprire il terminale solo se `_bbs_open == false`. `interact` (654-665) chiude anche la BBS prima di alzarsi; `_on_dawn_reached()` (332-340) e `_start_new_night()` (259-269) sganciano/parcheggiano anche la BBS (con `deactivate()` per emettere `ended`).
- `night/night_session.gd` -- **riuso, nessuna modifica.** `is_waiting()` (278-279) e `reshow_current()` (291-298) sono già il gancio: `main.gd` li usa per la BBS come per il terminale. `night/` NON nomina `bbs/`.
- `crt/crt_screen.gd` -- **riuso.** `show_control()` reparenta il Control nel viewport; `push()` inoltra gli eventi. Nessuna modifica.
- `project.godot` -- **estendere `[input]`.** Aggiungere `bbs_open` (tasto dedicato, es. `B`) e `bbs_back` (ESC, come `terminal_back`). Riusare `menu_up`/`menu_down`/`menu_confirm` per navigazione/scroll/apertura. NON toccare le azioni esistenti (`terminal_*`, `polar_*`, ...).
- `tests/test_bench.gd` -- **estendere.** Nuovi `_check_*` (logica pura, no SceneTree): `ForumBoard.available(night)` (filtro per notte), `PlayerProfile.has_read/mark_read` + round-trip save/load con `forum_read`, e il conteggio righe di `_wrap` su un corpo lungo (nessuna perdita di testo). Pattern dei `_check_*` esistenti con righe «<-- ATTESO».

## Tasks & Acceptance

**Execution:**
- `data/forum/forum_message.gd`, `forum_board.gd`, `forum_data.gd` -- creare le tre Resource dati (soli `@export`), con `ForumBoard.available(night)` come funzione pura -- data-driven come catalogo/target/committenti.
- `data/forum/*.tres` (≥3 board + `forum.tres`) -- popolare con messaggi IT a voci diverse, ≥1 con `appears_from_night > 1`, ≥1 lungo per lo scroll; nessun aiuto a fotografare -- è il contenuto della storia.
- `core/player_profile.gd` -- aggiungere `forum_read` + `has_read()`/`mark_read()`; nessun bump di versione -- i letti attraversano le notti come il possesso (C1).
- `autoloads/game.gd` -- aggiungere `mark_forum_read()` (muta+salva) -- la persistenza passa da un punto solo.
- `bbs/bbs.gd` + `bbs.tscn` -- costruire il `Control`: handshake udibile, cornice ASCII + fosforo verde come il terminale, vista elenco (aree, messaggi numerati, letto/non-letto), vista lettura con **scroll esplicito** (indicatore ▲/▼), `256×192`, `closed()`, `activate()`/`deactivate()` che emettono la coppia `wait_activity_*(&"forum")` -- è il cuore della storia.
- `main.gd` -- possedere/mostrare la BBS parallela al terminale, `bbs_open` gated su `is_waiting()` e mutuamente esclusiva col terminale, ripristino via `reshow_current()`, sgancio difensivo all'alba e alla notte nuova con `deactivate()` -- l'unico che conosce entrambe le sponde.
- `project.godot` -- aggiungere `bbs_open` (B) e `bbs_back` (ESC), senza toccare le azioni esistenti -- input della BBS.
- `tests/test_bench.gd` -- aggiungere i check di logica pura (filtro `available`, round-trip `forum_read`, conteggio righe `_wrap`) -- il banco legge, il cancello guarda.

**Acceptance Criteria:**
- Given il giocatore seduto al monitor durante l'attesa, when apre la BBS con `bbs_open`, then la connessione richiede qualche secondo con l'handshake udibile, compare un `Control` sul CRT (il CRT non sa cosa mostra), non costa lire, ed è emesso `Events.wait_activity_started(&"forum")`.
- Given la BBS collegata, when il giocatore la guarda, then ha la stessa cornice ASCII e lo stesso fosforo verde del terminale (3.2), l'interfaccia è in inglese e i messaggi dei forum sono in italiano.
- Given un messaggio più lungo del vetro `256×192`, when il giocatore legge, then si scorre e lo scorrimento è esplicito (si vede che c'è dell'altro sopra o sotto), e nessun messaggio è troncato in silenzio.
- Given l'elenco dei messaggi, when il giocatore legge, then i contenuti stanno in `data/*.tres` (niente JSON/`FileAccess`), ci sono almeno tre aree con voci diverse, e i messaggi parlano del mondo intorno all'osservatorio senza aiutare a fotografare meglio.
- Given un messaggio letto, when finisce, then non dà nessun bonus meccanico, da nessuna parte è scritto che potrebbe, e nessun messaggio contiene informazioni utili a fotografare meglio.
- Given un messaggio letto una notte, when il giocatore torna la notte dopo, then si vede quali ha già letto (la distinzione sopravvive al save), ne compaiono di nuovi col passare delle notti, e non c'è nessun contatore di non letti che solleciti.
- Given la posa in corso, when il giocatore sta leggendo e la sequenza finisce, then il chime di fine sequenza si sente comunque (è del luogo, 2.3), e la BBS non si chiude da sola né viene coperta.
- Given la telemetria, when la lettura comincia e quando si conclude, then emette `wait_activity_started(&"forum")` all'apertura e `wait_activity_ended(&"forum")` alla chiusura, una sessione aperta e mai chiusa resta distinguibile (started senza ended), e l'emissione non produce nessun feedback visibile.
- Given le regole di dipendenza, when si cerca `world/`/`night/`/`phases/` dentro `bbs/`, o `bbs/` dentro `night/`, then non c'è nessuna occorrenza.

## Design Notes

**È lo stesso computer, ma un programma diverso (parallelo al terminale).** La 3.2 ha stabilito il pattern: un `Control` in `terminal/`, posseduto da `main.gd`, mostrato con `show_control()` sopra il contenuto della notte, gated su `is_waiting()`. La BBS è il gemello in `bbs/`: stessa lifecycle, stessa estetica (le costanti `BG/FG/DIM/SEL`, il font, il beep, `_wrap`/`_text` si replicano — duplicazione deliberata di costanti estetiche provvisorie, coerente con la memoria sugli asset; non si estrae una base condivisa ora). **Mutua esclusione** in `main.gd`: terminale e BBS non si aprono insieme, così due Control non si contendono il viewport. `bbs_open`/`terminal_open` si aprono solo se l'altro è chiuso; `interact`, alba e notte nuova chiudono/sganciano quello aperto.

**Chi emette `wait_activity_*`.** Come `world/interactables/moka.gd` e `world/dome_activity.gd` emettono la propria coppia, la BBS emette la sua: `activate()` all'apertura (started), `deactivate()` alla chiusura (ended), con guardia `_active` per l'idempotenza. `main.gd` chiama `deactivate()` in **ogni** percorso di chiusura (tasto, `interact`, alba, notte nuova difensiva) così la coppia è sempre bilanciata — tranne il quit del gioco a BBS aperta, che lascia uno `started` senza `ended`: è l'abbandono, un dato per la 3.6, non un buco.

**Scroll esplicito (l'AC che la 2.2 ha pagato).** La descrizione di M42 arrivava tagliata a metà e nessuno se n'era accorto finché non l'ha vista un umano. Qui il corpo si manda a capo con `_wrap(body, 42)` (conteggio caratteri, monospace, come il terminale) e si mostra una finestra di righe; se ci sono righe oltre la finestra, un indicatore esplicito (`▲`/`▼`, o `^ more`/`v more`) lo dice, e `menu_up`/`menu_down` scorrono. Nessun troncamento silenzioso. **Da verificare guardando, non stimando** (regola di Federico, project-context).

**Letto/non-letto senza sollecitare.** `PlayerProfile.forum_read` con default `[]` e nessun bump di versione: un save vecchio senza il campo è «niente letto», esatto (stessa contabilità di `owned_items`/`lamp_fixed`). La distinzione è **per riga** (soggetto in `DIM` se letto, `FG` se no) — visibile se la cerchi, non un badge che chiede di essere svuotato. La scrittura passa da `Game.mark_forum_read` (un save per messaggio aperto, come `spend_lire` salva per acquisto).

**Nuovi messaggi nel tempo.** `ForumMessage.appears_from_night` (default 1) filtrato da `ForumBoard.available(Game.run.night_index)` (fallback `profile.nights_completed + 1` se non c'è una notte). Puro e collaudabile: dato un board fisso e una notte, torna sempre gli stessi messaggi.

**EN chrome, IT contenuto.** Coerente col terminale, che ha intestazioni EN (`WALLET`, `PERSONAL`) e `blurb` IT: la cornice/menu/prompt e i titoli delle aree (`title`) sono EN (voce macchina); soggetto e corpo dei messaggi sono IT (scritti da persone). Gli handle degli autori restano com'è.

## Spec Change Log

_Nessuna modifica alla spec: nessun loopback bad_spec in questa passata._

## Review Triage Log

### 2026-08-24 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 1: (high 0, medium 0, low 1)
- defer: 1: (high 0, medium 0, low 1)
- reject: 21
- addressed_findings:
  - `[low]` `[patch]` Il commento di `_shortcut_input` in `main.gd` diceva che `_toggle_terminal` «non è vincolato», ma il diff gli ha aggiunto la guardia `if _bbs_open: return`: commento fuorviante su un invariante. Riscritto per dire che la mutua esclusione è simmetrica (ciascun toggle rifiuta se l'altro è aperto).
- reject (rumore o non-problemi verificati):
  - Timer dell'handshake non fermato a `deactivate()` (stray beep/redraw su BBS parcheggiata): NON raggiungibile — `_park_bbs` mette la BBS in `PROCESS_MODE_DISABLED`, che mette in PAUSA il `Timer` figlio (INHERIT); `_on_connected` non scatta da parcheggiata, e `arm()` riparte con `.start()`. `_stop_handshake()` in `deactivate` spegne comunque l'audio subito.
  - `wait_activity_*` senza test al banco: coerente col progetto — la cupola collauda PREDICATI STATICI (`should_emit_started/ended`) perché ha logica di gate; la BBS ha solo un toggle `_active` banale, senza predicato da estrarre, e istanziare il Control violerebbe il «no SceneTree» del banco. L'emissione è glue verificata d'operatore, come moka/cupola/lampada.
  - Marcare letto all'apertura del messaggio: è la lettura voluta (aprire = leggere); nessun «mark-unread» richiesto, nessun contatore da svuotare (l'AC è soddisfatto).
  - Save a ogni apertura, anche se già letto: coerente con `mark_lamp_fixed` (salva comunque, documentato innocuo); la lettura non è ad alta frequenza.
  - `_load_boards()` in `_ready` e in `arm()`: identico al terminale (`_load_rows` in entrambi), innocuo.
  - ESC condiviso (`bbs_back`/`terminal_back`/`ui_release_mouse`): coerente con l'uso di ESC già accettato dal terminale; un solo Control aperto per volta.
  - `bbs_open` come tasto «back» dentro `bbs._unhandled_input`: dead code innocuo (B è intercettato prima da `main._shortcut_input`), rete difensiva.
  - `_wrap` duplicato nel banco (`_bbs_wrap`): scelta deliberata e documentata (la BBS non espone `_wrap`; importarla vorrebbe dire montare il Control) — il banco collauda la FORMA dell'a-capo.
  - Guardie su dati d'autore (id vuoto/duplicato, `appears_from_night <= 0`, soggetto/corpo vuoto): nessun `.tres` attuale li viola; default sani; nessun difetto presente.
  - `_current_night()` fallback: la BBS si apre solo in `is_waiting()` (notte montata), quindi `Game.run` c'è e `night_index` è autoritativo; il fallback è rete difensiva.
  - `has_read` per riga a ogni `_draw` / `_check_forum` senza null-guard su `back` / banco senza exit code non-zero / id hardcoded nel banco: micro-perf e robustezza del banco coerenti con gli altri `_check_*`; il cancello sta fuori dal banco per scelta.

## Verification

**Commands:**
- `./Godot_v4.7.2-stable_win64.exe --path . --headless --import` -- expected: importa `bbs/`, `data/forum/`, e le modifiche a `main.gd`/`game.gd`/`player_profile.gd`/`project.godot` senza errori di parse/risorsa; registra i nuovi `class_name` (`ForumMessage`, `ForumBoard`, `ForumData`).
- `pwsh -NoProfile -File .bmad-loop/verify.ps1` -- expected: il cancello (banco + avvio) passa senza errori/warning; i nuovi `_check_*` non stampano righe «<-- ATTESO».
- `rg -n "world/|night/|phases/" bbs/` -- expected: nessun risultato (isolamento).
- `rg -n "bbs/" night/` -- expected: nessun risultato (isolamento).

**Manual checks (camminando nel gioco — richiedono un umano su una build):**
- Durante l'attesa, sedersi al monitor, aprire la BBS: sentire l'handshake (qualche secondo), vedere cornice/fosforo identici al terminale, interfaccia EN e messaggi IT; leggibilità a `256×192` da seduti.
- Aprire un messaggio lungo: verificare che lo scorrimento è esplicito (indicatore sopra/sotto) e che nulla è troncato.
- Leggere un messaggio, dormire, riaprire la BBS: il messaggio risulta già letto (persiste al save). Dopo più notti, compaiono nuovi messaggi.
- Con la posa in corso, leggere e lasciare finire la sequenza: il chime si sente e la BBS resta aperta.
- Verificare la mutua esclusione col terminale (uno solo aperto per volta) e che `interact`/alba chiudano la BBS ripristinando lo schermo giusto.

## Auto Run Result

Status: awaiting-operator

**Change implementato:** la **BBS** (3.7), il secondo programma diegetico del PC dell'osservatorio — gemello del terminale (3.2). Seduti al monitor durante l'attesa, il tasto `B` apre un `Control` sul CRT: un handshake del modem 56k udibile per qualche secondo (vista CONNECTING), poi l'elenco dei forum. Stessa cornice ASCII e stesso fosforo verde del terminale (è lo stesso computer), interfaccia EN e messaggi IT. Tre aree (EQUIPMENT, DEEP SKY, OFF TOPIC) con otto messaggi a voci diverse su astronomia amatoriale, attrezzatura e notti perse — nessun aiuto a fotografare. I messaggi lunghi si scorrono con indicatori ▲/▼ + MORE espliciti (poligoni, non glifi font). I letti restano marcati fra le notti (`PlayerProfile.forum_read`), e nuovi messaggi compaiono col passare delle notti (`appears_from_night`). All'apertura emette `Events.wait_activity_started(&"forum")`, alla chiusura `wait_activity_ended(&"forum")` — il condotto di misura per la 3.6.

**File cambiati:**
- `data/forum/forum_message.gd`, `forum_board.gd`, `forum_data.gd` — NEW: le tre Resource dati (soli `@export`); `ForumBoard.available(night)` è il filtro puro per notte.
- `data/forum/*.tres` — NEW: 3 board + 8 messaggi + `forum.tres`; 2 messaggi con `appears_from_night > 1` (notti 2 e 3), 1 messaggio lungo per lo scroll.
- `bbs/bbs.gd` + `bbs.tscn` — NEW: il `Control` (handshake udibile, cornice/fosforo come il terminale, vista elenco con letto/non-letto, vista lettura con scroll esplicito, `activate()`/`deactivate()` che emettono la coppia `wait_activity_*(&"forum")` con guardia `_active`).
- `core/player_profile.gd` — `forum_read: Array[StringName]` + `has_read()`/`mark_read()` (default `[]`, nessun bump di versione).
- `autoloads/game.gd` — `mark_forum_read()` (muta+salva, unico chiamante di `SaveManager`).
- `main.gd` — lifecycle BBS parallela al terminale (`_setup_bbs`/`_toggle_bbs`/`_close_bbs`/`_park_bbs`), `bbs_open` in `_shortcut_input`, mutua esclusione col terminale, sgancio difensivo con `deactivate()` all'alba/notte nuova/interact.
- `project.godot` — azioni `bbs_open` (B) e `bbs_back` (ESC), senza toccare le esistenti.
- `tests/test_bench.gd` — `_check_forum`: filtro `available(night)` (monotono), round-trip `forum_read` su path di override, a-capo senza perdite (parole in = parole out).

**Review findings:** 1 patch applicata (low: commento fuorviante sulla mutua esclusione in `main.gd`); 1 defer (low: `Game.mark_forum_read` non esercitato end-to-end dal banco per accoppiamento ai path di save reali, come lo `spend_lire` della 3.2); 0 intent_gap, 0 bad_spec; 21 reject (rumore o non-problemi verificati — in particolare lo stray-beep del timer, NON raggiungibile perché il park mette in pausa il `Timer`, e l'assenza di test sull'emissione, coerente col pattern della cupola). Follow-up review consigliata: **false** (patch per severità: high 0, medium 0, low 1; punteggio `3×0 + 1×1 = 1 < 5`).

**Verifica eseguita:** import headless pulito (registra `ForumMessage`/`ForumBoard`/`ForumData`); cancello `.bmad-loop/verify.ps1` pulito («banco fino in fondo, gioco senza errori né warning»), nessuna riga «<-- ATTESO»; isolamento confermato (`rg` — `bbs/` non nomina `world/`/`night/`/`phases/`; `night/` non nomina `bbs/`). Il subagent di implementazione ha inoltre reso la BBS in una finestra reale 256×192 con una sonda usa-e-getta (poi cancellata) e confermato via screenshot cornice, EN/IT e indicatori di scroll.

**Rischi residui / owed all'operatore (vedi `operator_actions`):** gli AC percettivi e interattivi non certificabili headless — l'audio dell'handshake (driver Dummy nel cancello), la leggibilità/estetica dal vero a 256×192 da seduti, e l'integrazione della postazione (apertura da seduti, mutua esclusione col terminale, `interact`/alba, chime durante la lettura, persistenza dei letti dopo il sonno). Estetica provvisoria (beep/handshake sintetizzati, cornice come rettangolo) da rifinire col pack asset senza toccare la logica.
