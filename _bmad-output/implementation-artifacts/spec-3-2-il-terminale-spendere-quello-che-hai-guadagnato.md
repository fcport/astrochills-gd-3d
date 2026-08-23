---
title: "3.2 Il terminale — spendere quello che hai guadagnato"
type: 'feature'
created: '2026-08-23'
status: done
baseline_revision: '0b3ff39557a5310609f9231945810f9439898c1b'
review_loop_iteration: 0
followup_review_recommended: true
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
warnings: ['oversized']
deferred:
  - summary: >-
      Game.spend_lire (mutazione dei due contatori + save) non è esercitato end-to-end dal banco: solo lo split puro (split_spend) e can_afford lo sono.
    evidence: |-
      tests/test_bench.gd copre split_spend (4 casi + decremento esatto) e can_afford (soglia), ma non chiama Game.spend_lire su un run/profile reali per verificare che applichi lo split ai due contatori e salvi. Un test end-to-end scriverebbe sui path di save reali (user://saves/profile.tres|night.tres), che spend_lire usa senza override, clobberando il save del giocatore durante un run del banco. Serve o un override dei path in spend_lire o un backup/restore del profilo su disco.
    location: >-
      autoloads/game.gd (spend_lire) ; tests/test_bench.gd
    severity: low
operator_actions:
  - "Aprire il progetto in Godot 4.7.2 (editor) e confermare che terminal/, data/catalog/ e le modifiche a main.gd/night_session.gd/game.gd/player_profile.gd/events.gd/project.godot importano senza errori di parse/risorsa in console: nessun binario Godot era disponibile nell'ambiente di build, quindi tutto è validato solo staticamente."
  - "Eseguire il banco (tests/test_bench.tscn, es. `godot --headless --path . tests/test_bench.tscn`) e verificare che nessuna riga stampi «<-- ATTESO»: copre filtro catalogo, possesso+round-trip su disco, split della spesa e can_afford (logica pura). Il banco non ha potuto girare qui."
  - "Camminare il gioco durante l'attesa (menu post-foto vivo): sedersi al monitor, premere T per aprire il terminale, verificare cornice, header WALLET/NIGHT TAKE coerenti con le lire, navigazione ↑↓/ENTER/ESC col beep, descrizione IT con TAB, e leggibilità a 256×192 da seduti (AC percettivi non verificabili headless)."
  - "Comprare la lampadina con fondi sufficienti: il portafoglio cala, la voce passa a OWNED, ed è emesso Events.item_purchased. Dormire e riaprire il terminale: possesso e saldo devono sopravvivere al save. Provare senza fondi: messaggio EN «NOT ENOUGH LIRE», nessuna spesa, nessun modale."
  - "Chiudere il terminale (ESC/T/E): il CRT torna al menu post-foto e SHOOT AGAIN funziona ancora. Verificare che il terminale NON si apra mentre una fase interattiva o la vendita/rivelazione è a schermo (gate is_waiting())."
  - "Rifinire quando arriva il pack asset: la cornice è un rettangolo di contorno (non caratteri di box-drawing veri) e il beep è un'onda quadra sintetizzata in codice (nessun asset audio) — entrambi provvisori, da sostituire senza toccare la logica."
---

<intent-contract>

## Intent

**Problem:** Il lavoro della notte produce lire (2.5), ma non c'è ancora nessun posto dove spenderle: la vendita non ha conseguenze e l'attesa dell'epica 3 non ha di che riempirsi. L'osservatorio ha un PC diegetico (il monitor CRT) e un momento morto — la finestra fra il piano esaurito e l'alba, dove oggi il post-photo menu resta vivo ma non c'è altro da fare.

**Approach:** Aggiungere un **terminale gestionale** — un `Control` mostrato sul CRT, software MS-DOS verde-fosforo del 1999 — raggiungibile da seduti al monitor durante l'attesa. Vende **solo** ciò che ha un effetto implementato (moka e lampadina), da due categorie (`PERSONAL`, `FACILITIES`). Un acquisto scala il portafoglio, persiste il possesso nel save e **annuncia** il cambiamento del mondo via `Events` (l'oggetto visibile lo costruiscono 3.3/3.4). Il portafoglio del giocatore e il possesso vivono sul `PlayerProfile` (attraversano le notti, C1); la spesa passa da un unico punto su `Game`.

## Boundaries & Constraints

**Always:**
- **Il CRT non sa cosa mostra:** il terminale è un `Control` consegnato con `CrtScreen.show_control()`, esattamente come le schermate di `night/`. Nessuna dipendenza del terminale da `world/`, `night/`, `phases/`.
- **Isolamento cartelle:** il terminale vive in una cartella nuova `terminal/` che dipende **solo** da `core/`, `data/`, e dagli autoload (`Game`, `Events`). NON conosce `world/`, `night/`, `phases/`. Cercare quei nomi dentro `terminal/` deve dare zero. `night/` **non** conosce `terminal/`: il ponte è il punto d'ingresso `main.gd`, l'unico che può conoscere entrambe le sponde.
- **La spesa passa da un punto solo (`Game`), come la somma del portafoglio:** `Game.wallet_now()` è già l'unica somma; la spesa aggiunge `Game.can_afford()` e `Game.spend_lire()`. Nessuna schermata scala lire per conto proprio.
- **Possesso e lire sono del GIOCATORE (C1):** il flag di acquisto e il saldo vivono su `PlayerProfile` (attraversano le notti), MAI su `NightRun`. La spesa deduce prima da `run.night_earnings` (la presa non ancora versata), poi da `profile.wallet_lire`: così una notte abbandonata non lascia un portafoglio negativo, e il possesso resta comunque persistito.
- **Solo l'implementato è presente e acquistabile:** il terminale mostra e vende **solo** gli articoli con `implemented == true` (moka, lampadina). Le altre categorie di `economia.md` (equipment, catalogs, messages) **non compaiono affatto**, nemmeno disabilitate. Gli articoli non implementati restano nei `.tres` ma non si mostrano né si comprano.
- **Ogni acquisto è immediato e permanente:** scala il portafoglio, marca il possesso, salva, ed emette `Events.item_purchased(id)` **subito**. L'effetto è persistito nel save.
- **Lingua (NFR10):** interfaccia del terminale in **inglese**; le descrizioni narrative dei prodotti in **italiano**, dietro un tasto dedicato.
- **Leggibilità CRT `256×192` da seduti:** nessun testo troncato in silenzio; disegno con font monospace e fosforo verde su nero, come `night/post_photo_menu.gd`. Beep sui movimenti del cursore.
- **Nessun bonus meccanico, mai:** comprare la moka o la lampadina non altera nessun punteggio, e da nessuna parte è scritto che potrebbe (regola dell'epica).

**Block If:**
- Il modello di raggiungibilità richiede di modificare il contratto di input o lo stato della fase polare (`phases/polar/phase_polar.gd`, azioni `polar_*`), che non deve cambiare (prova AC2 storia 1.1): HALT `blocked`, condizione `raggiungibilità terminale in conflitto col contratto della fase polare`.

**Never:**
- Niente moka come oggetto interagibile in cucina, niente rituale del caffè, niente lampada che lampeggia o cambio lampadina, niente illuminazione che muta: **quelli sono 3.3 e 3.4.** Questa storia costruisce il terminale e l'acquisto, non l'oggetto nel mondo. Il terminale annuncia via `Events.item_purchased`; chi ascolta arriva dopo.
- Nessuna categoria oltre `PERSONAL` e `FACILITIES`; nessuna voce disabilitata.
- Niente rete, niente networking (mai, in tutto il progetto).
- Non toccare la coreografia di ADR-003 (seduta/alzata, `desk_camera`), la fase polare, né le azioni `polar_*`.
- Niente modali di sistema, niente popup di gioco sopra la scena: l'esito (payout, "fondi insufficienti") è **diegetico**, sul vetro del CRT (UX-DR10).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Apertura terminale | Giocatore seduto al monitor, notte in attesa (nessuna fase interattiva; menu post-foto vivo o schermo vuoto) | Il tasto dedicato mostra il terminale sul CRT; alla chiusura il CRT torna a ciò che `night/` mostrava | Se non si è in attesa (fase interattiva a schermo), il tasto non apre nulla |
| Acquisto con fondi sufficienti | Articolo implementato selezionato, `wallet_now() >= price` | Portafoglio cala di `price`, possesso marcato e salvato, `Events.item_purchased(id)` emesso, la voce passa a `OWNED` | Nessun errore atteso |
| Acquisto già posseduto | Articolo con possesso già marcato | La voce mostra `OWNED` e non è ri-acquistabile (nessuna spesa) | Nessuna doppia spesa |
| Fondi insufficienti | Articolo implementato, `wallet_now() < price` | Messaggio in inglese sul terminale (es. `NOT ENOUGH LIRE`), nessuna spesa, nessun modale, nessun rimprovero | Il portafoglio non cambia |
| Descrizione narrativa | Voce selezionata, tasto descrizione | Mostra il testo italiano del prodotto (`blurb`); ri-premendo torna alla vista prezzi | Nessun errore atteso |
| Catalogo assente/illeggibile | `catalog.tres` mancante o non parsabile | `load` torna `null`; il terminale mostra le categorie vuote senza crash, avviso su canale 1 | Nessun crash |
| Alba durante il terminale | Il giocatore sta usando il terminale quando scatta l'alba | `night/` mostra il riepilogo sul CRT; `main.gd` scarta lo stato "terminale aperto" senza ripristinare (il riepilogo vince) | Nessun conflitto sullo schermo |

</intent-contract>

## Code Map

- `core/player_profile.gd` -- **estendere.** Aggiungere `owned_items: Array[StringName]` (default `[]` — assente = vuoto, nessun bump di `CURRENT_VERSION`: un save vecchio senza il campo è correttamente "niente posseduto"), con `owns(id) -> bool` e `mark_owned(id)`. Il commento in testa spiega perché il possesso sta qui e non su `NightRun` (C1): riusarlo.
- `autoloads/game.gd` -- **estendere.** `wallet_now()` (righe 57-59) resta l'unica somma. Aggiungere `can_afford(amount) -> bool` (= `wallet_now() >= amount`) e `spend_lire(amount) -> bool`: deduce da `run.night_earnings` prima, resto da `profile.wallet_lire`; marca il possesso è compito del chiamante; salva `save_run`+`save_profile` (stesso `_saves` di `end_night`). NON toccare `start_night`/`end_night`.
- `autoloads/events.gd` -- **estendere.** Aggiungere `signal item_purchased(id: StringName)` (passato, tipizzato). È il seam verso 3.3/3.4 (moka/lampadina nel mondo). Nessun altro segnale cambia.
- `data/catalog/item_data.gd` -- **NEW.** Resource `ItemData` sul modello di `data/targets/target_data.gd`/`data/clients/client_data.gd`: `id: StringName`, `category: StringName` (&"personal"/&"facilities"), `label: String` (EN, per il menu), `price: int`, `blurb: String` (IT, narrativa), `implemented: bool`.
- `data/catalog/item_catalog.gd` -- **NEW.** Resource `ItemCatalog` sul modello di `data/clients/client_roster.gd`: `@export var items: Array[ItemData] = []`. Metodo `for_category(cat, only_implemented := true) -> Array[ItemData]`.
- `data/catalog/*.tres` -- **NEW.** `moka.tres` (personal, implemented, prezzo segnaposto, blurb IT), `lampadina.tres` (facilities, implemented, 2000 lire da economia §6, blurb IT), più `stufetta.tres` (personal, implemented=false) e `lubrificare_cupola.tres` (facilities, implemented=false) per provare il filtro. `catalog.tres` li raccoglie.
- `terminal/terminal.gd` + `terminal.tscn` -- **NEW.** Il `Control` del terminale. Modello di disegno e input: `night/post_photo_menu.gd` (SystemFont Consolas/Courier, `_draw`, azioni `menu_*`, `_done`/`arm()`, colori fosforo). Legge il catalogo, mostra header WALLET/NIGHT TAKE (da `Game`), due categorie, lista voci implementate con stato OWNED, gestisce acquisto/fondi/descrizione. Emette `closed()` (diretto) quando il giocatore esce col tasto back/quit. Beep: `AudioStreamWAV` sintetizzato in codice (nessun asset esterno — provvisorio).
- `main.gd` -- **estendere.** Il ponte world↔night↔terminal. Possiede l'istanza del terminale; nella finestra d'attesa (seduto + `_night.is_waiting()`) un tasto dedicato apre/chiude il terminale sul CRT; alla chiusura chiede a `night/` di ri-mostrare il proprio contenuto. Vedi Design Notes per il flusso esatto. Riusa `_shortcut_input` (già intercetta `interact` da seduti), `_crt.show_control`, il gating input già montato.
- `night/night_session.gd` -- **estendere (minimo).** Aggiungere `is_waiting() -> bool` (nessuna fase/rivelazione/vendita/riepilogo interattivo a schermo: `_phase == null and _stacking == null and _sale == null and _summary == null`) e `reshow_current() -> void` (ri-`show_control()` del contenuto corrente — menu o niente — e ri-asserisce il gating). NON nomina `terminal/`.
- `project.godot` -- **estendere `[input]`.** Aggiungere `terminal_open` (tasto dedicato per aprire/chiudere, es. `T`), `terminal_back` (ESC, per uscire da una sotto-vista / chiudere), `terminal_desc` (tasto descrizione, es. TAB). Riusare `menu_up`/`menu_down`/`menu_confirm` per navigazione/acquisto.
- `tests/test_bench.gd` -- **estendere.** Nuovi `_check_*` (logica pura, no SceneTree): filtro catalogo (solo implementati per categoria), `PlayerProfile.owns/mark_owned` + round-trip save/load con `owned_items`, aritmetica della spesa (deduzione earnings-prima-poi-wallet, `can_afford`, `wallet_now` cala esatto). La logica di split della spesa va estratta in una funzione pura testabile.

## Tasks & Acceptance

**Execution:**
- `core/player_profile.gd` -- aggiungere `owned_items`, `owns()`, `mark_owned()`; nessun bump di versione (assente = vuoto) -- il possesso attraversa le notti (C1), come il portafoglio.
- `autoloads/game.gd` -- aggiungere `can_afford()` e `spend_lire()` (deduci earnings-prima, poi wallet; salva entrambi); estrarre lo split in una funzione pura per il banco -- la spesa vive dove vive la somma.
- `autoloads/events.gd` -- aggiungere `signal item_purchased(id)` -- il seam verso 3.3/3.4.
- `data/catalog/item_data.gd`, `item_catalog.gd`, `moka.tres`, `lampadina.tres`, `stufetta.tres`, `lubrificare_cupola.tres`, `catalog.tres` -- creare il modello dati e le istanze (2 implementate + 2 no) -- data-driven come target/committenti; il filtro `implemented` è reale e collaudabile.
- `terminal/terminal.gd` + `terminal.tscn` -- costruire il `Control`: header WALLET/NIGHT TAKE, due categorie, lista voci implementate con OWNED, acquisto (via `Game`), fondi insufficienti in EN, descrizione IT dietro tasto, beep, `256×192` fosforo verde, `closed()` -- è il cuore della storia.
- `night/night_session.gd` -- aggiungere `is_waiting()` e `reshow_current()` -- danno a `main.gd` il gancio per sovrapporre e ripristinare senza che `night/` conosca `terminal/`.
- `main.gd` -- possedere/mostrare il terminale nella finestra d'attesa; tasto `terminal_open` apre/chiude gated da `_night.is_waiting()`; ripristino via `reshow_current()`; chiusura difensiva all'alba e alla notte nuova -- l'unico che conosce entrambe le sponde.
- `project.godot` -- aggiungere le azioni `terminal_open`/`terminal_back`/`terminal_desc` -- input del terminale, senza toccare le azioni esistenti.
- `tests/test_bench.gd` -- aggiungere i check di logica pura sopra descritti (I/O matrix: righe acquisto/fondi/posseduto/catalogo-assente) -- il banco legge, il cancello guarda.

**Acceptance Criteria:**
- Given il giocatore seduto al monitor durante l'attesa, when apre il terminale col tasto dedicato, then compare un `Control` sul CRT e il CRT non sa cosa sta mostrando (stesso `show_control()` delle schermate di `night/`); alla chiusura il CRT torna a ciò che `night/` mostrava.
- Given il terminale aperto, when il giocatore lo guarda, then ha cornice ASCII, monospace verde-fosforo su nero, intestazione con `WALLET` e `NIGHT TAKE`, menu numerato, si naviga con `↑↓`/`ENTER`/`ESC` con un beep sui movimenti, l'interfaccia è in inglese e le descrizioni prodotto sono in italiano dietro un tasto dedicato, ed è leggibile a `256×192` da seduti.
- Given il mockup di `economia.md §4` con cinque categorie, when il terminale dell'MVP viene costruito, then ne esistono due (`PERSONAL`, `FACILITIES`) e le altre non compaiono affatto, nemmeno disabilitate.
- Given i cataloghi in `data/catalog/*.tres`, when il terminale li mostra, then sono in vendita solo gli articoli implementati (moka, lampadina); gli altri restano nei `.tres` ma non compaiono e non si comprano.
- Given un acquisto con fondi sufficienti, when viene confermato, then il portafoglio cala di `price`, il possesso è marcato e persistito nel save, `Events.item_purchased(id)` è emesso subito, e la voce passa a `OWNED`.
- Given un acquisto con fondi insufficienti, when il giocatore prova a comprare, then il terminale lo dice in inglese senza modali e senza rimprovero, e il portafoglio non cambia.
- Given `PlayerProfile`, when una notte si chiude e la successiva comincia, then `owned_items` e `wallet_lire` sono quelli di prima (attraversano le notti), e `run.phase_scores` no (C1).
- Given le regole di dipendenza, when si cerca `world/`/`night/`/`phases/` dentro `terminal/`, o `terminal/` dentro `night/`, then non c'è nessuna occorrenza.

## Spec Change Log

_Nessuna modifica alla spec: nessun loopback bad_spec in questa passata._

## Review Triage Log

### 2026-08-23 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 8: (high 0, medium 3, low 5)
- defer: 1: (high 0, medium 0, low 1)
- reject: 14
- addressed_findings:
  - `[medium]` `[patch]` AC2 «cornice ASCII» non disegnata — aggiunta una cornice a linea singola nel `_draw` del terminale.
  - `[medium]` `[patch]` AC2 «menu numerato» mancante — voci ora numerate (`1.`, `2.`, …) iterando `CATEGORIES`.
  - `[medium]` `[patch]` segnale `closed` connesso diretto: `_close_terminal` faceva `reparent`/`show_control` dentro l'`_unhandled_input` del terminale (viola la convenzione NFR16 che tutta la notte rispetta) — connesso con `CONNECT_DEFERRED`.
  - `[low]` `[patch]` `_draw_catalog` faceva sparire una categoria senza voci — ora itera `CATEGORIES`, entrambe sempre a schermo (AC3), `(none)` se vuota.
  - `[low]` `[patch]` header «OSSERVATORIO DOS» (italiano) violava NFR10 — reso «ASTROCHILL INVENTORY v1.0» in inglese.
  - `[low]` `[patch]` possibile OOB in `_draw_desc` (`_rows[_cursor]`) — aggiunta guardia `_rows.is_empty()`.
  - `[low]` `[patch]` prezzo moka 800 L (più economico di un caffè, `economia.md §15`) — portato a 8000 L (segnaposto meno stonato).
  - `[low]` `[patch]` `Game.can_afford` senza copertura — aggiunto `_check_can_afford` al banco (lettura pura, senza side-effect su disco).
- reject (rumore o non-problemi verificati): collisione input col menu post-foto (`show_control` RIMUOVE il menu dal viewport → orfano, non riceve input); contratto di ritorno di `spend_lire` (letto male: `true` anche a save fallito è intenzionale, come `end_night`); rollback del possesso «codice morto» (rete voluta e innocua); `terminal_desc` disallineato con «tab» (4194306 È KEY_TAB — reviewer errato); dati controllati (prezzo ≤0, `amount`/`night_earnings`/`id` anomali, parola >42 char, categoria vuota); `Game.profile` mai null (inizializzato e ricaricato in `_ready`); ridondanza di `arm()` che ricarica il catalogo (innocua).

## Design Notes

**Modello di spesa (perché earnings-prima-poi-wallet).** `wallet_now() = profile.wallet_lire + run.night_earnings`. La spesa non può dedurre solo da `wallet_lire`: se la presa di stanotte non è ancora versata (il travaso è in `end_night`, C1), `wallet_lire` andrebbe negativo. Dedurre prima da `night_earnings` (fino a 0) e il resto da `wallet_lire` tiene entrambi ≥ 0 e `wallet_now()` cala esatto; a fine notte `end_night` versa il residuo. Conseguenza voluta: `NIGHT TAKE` (=`run.night_earnings`) cala man mano che spendi — è "la presa che ti resta", non un totale lordo. `WALLET` = `wallet_now()`. Split puro per il banco:
```
# amount <= wallet_now() garantito dal chiamante (can_afford)
from_earnings := min(amount, night_earnings)
from_wallet   := amount - from_earnings
```

**Raggiungibilità (perché passa da main.gd, non da night/).** Ogni notte è una notte-foto (`night_plan.tres`: targeting+imaging), quindi l'attesa finisce col post-photo menu **vivo** (`has_phase()` resta true fino all'alba): non esiste una finestra "nessuna fase". Il terminale è allora un secondo programma del PC, aperto **sopra** il menu con un tasto e chiuso ripristinando il menu. `night/` non può conoscere `terminal/` (tabella dei confini), e `main.gd` è l'unico che conosce entrambe le sponde — come già fa per il mondo e la fase. Flusso in `main.gd`, da seduti:
- `terminal_open` premuto e `_night.is_waiting()` e terminale non aperto → `_crt.show_control(_terminal)`, `_terminal.arm()`, marca "terminale aperto". Intercettato in `_shortcut_input` (gira prima di `_unhandled_input`, come già `interact`), così il tasto non raggiunge il Control sotto.
- terminale aperto: gli eventi passano dal solito `_unhandled_input`→`_crt.push`, e il Control mostrato è il terminale; `terminal_open` di nuovo, o `closed()` del terminale → `_night.reshow_current()` e sgancia "terminale aperto".
- `interact` (E) da seduti alza sempre; se il terminale è aperto, prima sgancia lo stato.
- `Events.dawn_reached` mentre il terminale è aperto: `night/` ha già mostrato il riepilogo; `main.gd` sgancia lo stato senza ripristinare (il riepilogo vince). La notte nuova (dopo il sonno) parte con lo stato già sganciato; `_start_new_night` lo sgancia difensivamente.
Il terminale è gated su `is_waiting()`: mai sovrapposto a una fase interattiva o alla vendita/rivelazione (dove aprirlo e ripristinare rischierebbe di disturbare uno stato vivo).

**Cartella nuova `terminal/`.** L'architettura anticipa "il negozio o il terminale" come contenuto CRT distinto dalle fasi (game-architecture §confini). Regole della cartella, da rispettare come per `night/`: dipende da `core/`, `data/`, autoload; **mai** `world/`/`night/`/`phases/`. È `main.gd` (punto d'ingresso) a istanziarla e mostrarla.

**Prezzi/asset provvisori.** Lampadina 2.000 lire (economia §6, esplicito). Moka: prezzo segnaposto modesto (attinabile in poche notti) — è un dato nel `.tres`, tarabile. Il beep è un `AudioStreamWAV` sintetizzato in codice (nessun asset d'arte inventato, coerente con la memoria sugli asset provvisori); si può sostituire quando arriva il pack audio.

**Il seam verso 3.3/3.4.** L'AC "effetto nel mondo immediato" per 3.2 si concreta in: possesso persistito + `Events.item_purchased(id)` emesso subito. L'oggetto **visibile/udibile** (moka in cucina, lampada che cambia) lo costruiscono 3.3/3.4, che ascoltano quel segnale e leggono `profile.owns(id)`. 3.2 non lo simula (niente moka finta): consegna il contratto, non il suo consumatore.

## Verification

**Commands:**
- `godot --headless --path . --quit` -- expected: il progetto importa terminale, scene e `.tres` nuovi senza errori di parse/risorsa (se `godot` 4.7.2 è nel PATH; altrimenti aprire il progetto nell'editor e controllare l'assenza di errori in console — nessun binario Godot potrebbe esserci nell'ambiente).
- `godot --headless --path . tests/test_bench.tscn` (o aprire `tests/test_bench.tscn`) -- expected: i nuovi check stampano senza righe `<-- ATTESO`.
- `rg -n "world/|night/|phases/" terminal/` -- expected: nessun risultato (isolamento).
- `rg -n "terminal/" night/` -- expected: nessun risultato (isolamento).

**Manual checks (camminando nel gioco — richiedono un umano e un binario Godot):**
- Durante l'attesa, sedersi al monitor, aprire il terminale, verificare header WALLET/NIGHT TAKE coerenti con `Game.wallet_now()`; navigare con ↑↓/ENTER/ESC col beep; leggere una descrizione IT col tasto dedicato; verificare leggibilità a `256×192`.
- Comprare la lampadina con fondi sufficienti: il portafoglio cala, la voce passa a OWNED; riaprire dopo aver dormito e verificare che il possesso e il saldo sopravvivono al save.
- Provare a comprare senza fondi: messaggio EN, nessuna spesa, nessun modale.
- Verificare che PERSONAL/FACILITIES mostrano solo moka/lampadina e nient'altro; nessun'altra categoria.
- Chiudere il terminale: il CRT torna al post-photo menu; SHOOT AGAIN funziona ancora.

## Auto Run Result

Status: awaiting-operator

**Change implementato:** un **terminale gestionale** diegetico (3.2). Seduti al monitor durante l'attesa (menu post-foto vivo), il tasto `T` apre un `Control` sul CRT — software MS-DOS verde-fosforo — dove il giocatore spende le lire guadagnate. Vende **solo** l'implementato (moka, lampadina) da due categorie (`PERSONAL`, `FACILITIES`); ogni acquisto scala il portafoglio, marca il possesso, salva ed emette `Events.item_purchased(id)` — il seam che 3.3/3.4 consumeranno per far comparire moka e lampadina nel mondo (3.2 consegna il contratto, non l'oggetto visibile). Possesso e lire vivono sul `PlayerProfile` e attraversano le notti (C1); la spesa passa da un unico punto su `Game`.

**File cambiati:**
- `core/player_profile.gd` — `owned_items: Array[StringName]` + `owns()`/`mark_owned()` (default `[]`, nessun bump di versione).
- `autoloads/game.gd` — `can_afford()`, `spend_lire()` (deduce earnings-prima-poi-wallet, salva run+profilo), e lo `split_spend()` puro/statico per il banco.
- `autoloads/events.gd` — `signal item_purchased(id)` (seam verso 3.3/3.4).
- `data/catalog/` — NEW: `ItemData`, `ItemCatalog.for_category()`, e le istanze `moka`/`lampadina` (implementate) + `stufetta`/`lubrificare_cupola` (non implementate, per provare il filtro), raccolte in `catalog.tres`.
- `terminal/terminal.gd` + `.tscn` — NEW: il `Control` del terminale (cornice, header WALLET/NIGHT TAKE, due categorie con voci numerate e stato OWNED, acquisto/fondi/descrizione IT, beep sintetizzato, `256×192` fosforo, `closed()`).
- `night/night_session.gd` — `is_waiting()` e `reshow_current()` (il gancio per sovrapporre/ripristinare; `night/` non nomina `terminal/`).
- `main.gd` — possiede/mostra il terminale, `terminal_open` gated su `is_waiting()`, ripristino via `reshow_current()`, sgancio difensivo all'alba e alla notte nuova; `closed` connesso `CONNECT_DEFERRED`.
- `project.godot` — azioni `terminal_open` (T), `terminal_back` (ESC), `terminal_desc` (TAB).
- `tests/test_bench.gd` — check di logica pura: filtro catalogo, `owns`/`mark_owned` + round-trip su disco, split della spesa, `can_afford`.

**Review findings:** 8 patch applicate (medium 3: cornice ASCII, menu numerato, `closed` differito; low 5: categoria sempre visibile, header EN, guardia OOB, prezzo moka, copertura `can_afford`); 1 defer (`spend_lire` end-to-end non collaudato per accoppiamento ai path di save); 0 intent_gap, 0 bad_spec; 14 reject (rumore o non-problemi verificati ricalcolando). Follow-up review consigliata: **true** — patch per severità (high 0, medium 3, low 5), punteggio `3×3 + 1×5 = 14 ≥ 5`.

**Verifica eseguita:** isolamento confermato con `rg` sui file nuovi e tracciati (`terminal/` non nomina `world/`/`night/`/`phases/`; `night/` non nomina `terminal/`); nessun riferimento morto residuo. **Nessun binario Godot nell'ambiente**: `godot --headless` (import) e il banco `tests/test_bench.tscn` NON hanno potuto girare — la logica pura (catalogo/possesso/split/can_afford) è scritta come check leggibili ma non eseguiti, e gli AC percettivi/interattivi (leggibilità 256×192, beep, apertura/acquisto/persistenza dopo il sonno) richiedono un umano su una build. Vedi `operator_actions`.

**Rischi residui:**
- Import, banco e AC percettivi/interattivi non verificati qui (nessun binario Godot): owed all'operatore.
- `Game.spend_lire` (mutazione + save) non esercitato end-to-end dal banco per accoppiamento ai path di save reali (vedi `deferred`); lo split puro e `can_afford` sono coperti.
- Estetica provvisoria: cornice come rettangolo di contorno (non caratteri box-drawing) e beep sintetizzato in codice — da rifinire col pack asset, senza toccare la logica.
- Integrazione input/seduta in `main.gd` (apertura/chiusura terminale, `reshow_current`, sgancio all'alba) validata solo staticamente: è la parte più delicata e va camminata.

## Operator Confirmation

Confirmed 2026-08-24: the external actions this story owed were carried out.

- Aprire il progetto in Godot 4.7.2 (editor) e confermare che terminal/, data/catalog/ e le modifiche a main.gd/night_session.gd/game.gd/player_profile.gd/events.gd/project.godot importano senza errori di parse/risorsa in console: nessun binario Godot era disponibile nell'ambiente di build, quindi tutto è validato solo staticamente.
- Eseguire il banco (tests/test_bench.tscn, es. `godot --headless --path . tests/test_bench.tscn`) e verificare che nessuna riga stampi «<-- ATTESO»: copre filtro catalogo, possesso+round-trip su disco, split della spesa e can_afford (logica pura). Il banco non ha potuto girare qui.
- Camminare il gioco durante l'attesa (menu post-foto vivo): sedersi al monitor, premere T per aprire il terminale, verificare cornice, header WALLET/NIGHT TAKE coerenti con le lire, navigazione ↑↓/ENTER/ESC col beep, descrizione IT con TAB, e leggibilità a 256×192 da seduti (AC percettivi non verificabili headless).
- Comprare la lampadina con fondi sufficienti: il portafoglio cala, la voce passa a OWNED, ed è emesso Events.item_purchased. Dormire e riaprire il terminale: possesso e saldo devono sopravvivere al save. Provare senza fondi: messaggio EN «NOT ENOUGH LIRE», nessuna spesa, nessun modale.
- Chiudere il terminale (ESC/T/E): il CRT torna al menu post-foto e SHOOT AGAIN funziona ancora. Verificare che il terminale NON si apra mentre una fase interattiva o la vendita/rivelazione è a schermo (gate is_waiting()).
- Rifinire quando arriva il pack asset: la cornice è un rettangolo di contorno (non caratteri di box-drawing veri) e il beep è un'onda quadra sintetizzata in codice (nessun asset audio) — entrambi provvisori, da sostituire senza toccare la logica.

_Appended by the bmad-loop orchestrator (`bmad-loop confirm`, #335): a human confirmed these external actions out of band, and the story was advanced from `awaiting-operator` to `done`._
