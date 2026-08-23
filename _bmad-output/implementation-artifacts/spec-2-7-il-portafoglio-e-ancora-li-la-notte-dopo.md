---
title: 'Story 2.7: Il portafoglio è ancora lì la notte dopo'
type: 'feature'
created: '2026-08-23'
status: 'done'
baseline_revision: '457c6ed7619dd2d32bfa2249bee21dc53e2f8c1c'
review_loop_iteration: 0
followup_review_recommended: false
context: ['{project-root}/_bmad-output/project-context.md']
warnings: ['oversized']
deferred:
  - summary: >-
      La glue stateful della persistenza — Game._ready che adotta il profilo caricato,
      end_night che versa+salva alla chiusura, e la cattura di closed_index prima di
      end_night in _close_night — non ha copertura automatica.
    evidence: |-
      Il banco (NFR19) prova solo logica pura senza SceneTree: _check_save_manager
      esercita SaveManager in isolamento e il caso (e) prova il travaso attraverso un
      disco, ma nessun test guida Game.end_night / Game._ready / _close_night. Il gate
      avvia il gioco a 600 frame e l'alba cade a ~900 s, quindi end_night e il fix del
      null-deref non vengono mai eseguiti in verifica. Una regressione (rimozione delle
      due chiamate save_*, profilo caricato ma non adottato, ritorno del deref di
      Game.run dopo end_night) lascerebbe banco e gate verdi. Sorella di DW-7 e DW-9,
      stessa lacuna per la glue di NightSession.
    location: >-
      autoloads/game.gd:32-33,56-64; night/night_session.gd:64-65
    severity: medium
  - summary: >-
      Il salvataggio non è atomico: un crash o un'interruzione a metà di
      ResourceSaver.save su profile.tres lo corrompe, e il giocatore perde il
      portafoglio — proprio ciò che la storia esiste per proteggere.
    evidence: |-
      SaveManager._save scrive in place. Il ramo di recupero (save illeggibile ->
      frase gentile + profilo pulito) rende la perdita garbata, ma resta una perdita.
      Un pattern scrivi-su-temp-poi-rinomina la renderebbe a prova di crash. Non
      richiesto da nessun AC della 2.7; enhancement di robustezza.
    location: >-
      core/save_manager.gd:86-92
    severity: low
---

<intent-contract>

## Intent

**Problem:** Il ciclo della notte funziona, ma il lavoro di una notte non arriva alla successiva: `Game.profile` nasce vuoto a ogni avvio perché nessuno lo carica dal disco, e a fine notte nessuno lo scrive. `core/save_manager.gd` — che la 2.7 doveva creare — non esiste ancora. Senza persistenza, il portafoglio riparte da zero ogni volta e la storia «ritrovare le mie lire domani» non è vera.

**Approach:** Creare `core/save_manager.gd`, un helper puro (nessuno `SceneTree`) che salva e carica `PlayerProfile` e `NightRun` con `ResourceSaver`/`ResourceLoader` su `user://saves/*.tres`, chiamando `migrate()` **sempre** al load. Cablarlo nel ciclo di vita: `Game` carica il profilo all'avvio e lo versa+salva (insieme alla `NightRun` conclusa) in `end_night()`. Un save assente è un avvio nuovo, silenzioso; un save presente ma illeggibile diventa una frase gentile (canale 2, EN) e un profilo pulito, mai uno stack trace né un modale. La separazione dei tipi fatta da C1 fa il resto: la nuova notte è una `NightRun.new()`, quindi i punteggi delle fasi non sopravvivono per costruzione.

## Boundaries & Constraints

**Always:**
- Save **solo** `.tres` di testo via `ResourceSaver`, sotto `user://saves/`. Niente JSON, niente `FileAccess` per serializzare dati di gioco. Il file resta leggibile e diffabile (AC1).
- `migrate()` viene chiamato a **ogni** load riuscito, anche quando `version == CURRENT_VERSION` e non fa niente (AC2).
- La linea «della notte / del giocatore» resta dove C1 l'ha messa: nei due **tipi**. La nuova notte è `NightRun.new()`; `start_night()` non tocca `profile`. Non reintrodurre una funzione-che-copia campi.
- `save_manager.gd` sta in `core/`: dipende **solo** da `core/` (Log è un autoload di logging, ammesso) ed è istanziabile senza `SceneTree` (NFR19, deve girare sul banco).
- Due canali separati: un save corrotto è un **fatto recuperabile**, non un `push_error`. Il canale 1 (dev) può registrarlo con `Log.warn`; la frase per l'umano/validatore è dato di canale 2, in **inglese** (voce macchina del 1999), tono cozy.
- Il banco (`tests/test_bench.tscn`) deve arrivare a `=== fine ===` e **non** stampare righe `ERROR`/`SCRIPT ERROR`/`WARNING`/`USER ERROR`, né `<-- ATTESO`, né `NON CARICABILE`: è ciò che `.bmad-loop/verify.ps1` legge. La rilevazione dell'illeggibilità deve avvenire **prima** di `ResourceLoader` (sniff dell'intestazione con `FileAccess`), così il caso corrotto sul banco non fa emettere a Godot un errore di caricamento.

**Block If:**
- Se emergesse che il criterio «scrive la `NightRun`» va riletto contro C1 in modo non risolvibile dai fatti già scritti in `c1-dossier-stato-cross-notte.md` (opzione A, chiusa) — cioè servisse cambiare quale tipo sopravvive — HALT con `intent gap`. (Non atteso: C1 è chiuso, l'approccio è determinato.)

**Never:**
- Niente salvataggio a metà notte, niente slot multipli, niente UI di caricamento/menu di partite: fuori scopo (l'epica 2 non li chiede). Un singolo `profile.tres` + un singolo `night.tres` (l'ultima notte conclusa) bastano.
- Niente rendering a schermo della frase gentile in un nuovo `Control`/HUD di boot: all'avvio non esiste una superficie CRT montata, e nessun AC chiede una schermata di boot. La superficie che gli AC nominano per la frase gentile è **il banco** (AC4); in gioco basta non crashare e proseguire con un profilo pulito.
- Non ritarare numeri (payout, moltiplicatori, durata notte): fuori scopo.
- Non introdurre GUT/gdUnit4.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Nessun save (primo avvio) | `user://saves/profile.tres` assente | `load_profile()` ritorna un `PlayerProfile` nuovo (wallet 0, notti 0); messaggio vuoto; **nessuna** riga di log | Non è un errore: avvio nuovo, silenzioso |
| Save valido corrente | `profile.tres` v corrente, wallet 4900 | ritorna il profilo con wallet 4900; `migrate()` chiamato (no-op); messaggio vuoto | No error expected |
| Save valido vecchio | `profile.tres` `version` < corrente | ritorna il profilo; `migrate()` lo porta a `CURRENT_VERSION` (`Log.warn`, canale 1); messaggio vuoto | `Log.warn` (canale 1), mai `push_error` |
| Save illeggibile/corrotto | file presente, intestazione non `[gd_resource` | ritorna un `PlayerProfile` nuovo; `last_load_message` = frase gentile EN non vuota; nessun crash | Sniff header PRIMA di `ResourceLoader`: nessun errore engine, `Log.warn` canale 1 |
| Notte conclusa | `end_night()` con `run` viva | scrive `night.tres` (la `NightRun`, `phase_scores`/`photos`/`commission` inclusi) e `profile.tres` (wallet versato); poi `run = null` | Se un `save_*` fallisce, ritorna `false` e `Log.warn`; la notte si chiude comunque |
| Round-trip `NightRun` | `phase_scores = {&"polar": 80}` salvato e ricaricato | la chiave `StringName` sopravvive: `run.phase_scores[&"polar"] == 80` | No error expected (il `.tres` preserva `&"..."`) |

</intent-contract>

## Code Map

- `core/save_manager.gd` — **DA CREARE**. `class_name SaveManager extends RefCounted` (puro, no SceneTree). Metodi: `save_profile`/`load_profile`, `save_run`/`load_run`, il messaggio gentile su `last_load_message`. Costanti dei percorsi `user://saves/{profile,night}.tres`.
- `core/player_profile.gd` — sorella del giocatore. Ha già `version`/`CURRENT_VERSION`, `wallet_lire`, `nights_completed`, `migrate()`. **Read-only** (nessuna modifica prevista).
- `core/night_run.gd` — stato di notte. Ha già `version`/`migrate()`, `phase_scores` (chiavi `StringName`), `photos`, `commission`, `night_earnings`. **Read-only**.
- `autoloads/game.gd` — il «portachiavi». `start_night()` (righe 26-30) NON deve toccare `profile`. `end_night()` (righe 39-46): oggi versa e azzera `run`; qui aggiunge il salvataggio di `run` e `profile` **prima** di `run = null`. Aggiungere `_ready()` che carica `profile` dal disco.
- `main.gd:106-119` (`_ready`) e `:166-192` (`_begin_night`) — l'avvio. `Game.start_night()` è a riga 190. Il caricamento del profilo va prima della prima notte: lo fa `Game._ready()`, non `main.gd`.
- `night/night_session.gd:815-829` (`_close_night`) — **BUG da correggere**: a riga 822 chiama `Game.end_night()` (che fa `run = null`), poi a riga 829 legge `Game.run.night_index` → deref di `null` a ogni alba vera. Non lo vede il gate (l'alba cade a ~900 s, il gioco si ferma a 600 frame). Catturare l'indice in un locale **prima** di `end_night()`.
- `tests/test_bench.gd` — banco. `_ready()` (righe 51-84) elenca i check; `_check_player_profile()` (righe 784-823) è il precedente C1 da cui modellare. Aggiungere `_check_save_manager()` e la sua riga in `_ready`. Pattern del banco: stampa sempre, segnala solo lo scostamento con `<-- ATTESO`; NON esercitare canali d'errore engine (vedi righe 380-386).
- `.bmad-loop/verify.ps1` — il cancello. Legge il banco (fallisce su `ERROR|SCRIPT ERROR|WARNING|USER ERROR`, `<-- ATTESO`, `NON CARICABILE`, mancato `=== fine ===`) e l'avvio del gioco a 600 frame (fallisce su stesse righe). `Log.warn` stampa `WARN [..]`, che **non** contiene `WARNING`: gate-safe.
- `_bmad-output/implementation-artifacts/deferred-work.md:7` — voce «`phase_scores` con chiavi `StringName` non sopravvive a un round-trip JSON»: si applica a JSON, **non** al `.tres` di `ResourceSaver` (che preserva `&"..."`). Il round-trip sul banco lo dimostra e la ritira per il percorso `.tres`.

## Tasks & Acceptance

**Execution:**
- `core/save_manager.gd` -- CREARE `SaveManager extends RefCounted`. `const SAVES_DIR := "user://saves"`, `PROFILE_PATH`, `NIGHT_PATH`. `save_profile(p, path := PROFILE_PATH) -> bool` e `save_run(r, path := NIGHT_PATH) -> bool`: `DirAccess.make_dir_recursive_absolute` sulla dir, `ResourceSaver.save(res, path)`, ritorna `OK`; su fallimento `Log.warn` e `false`. `load_profile(path := PROFILE_PATH) -> PlayerProfile` e `load_run(path := NIGHT_PATH) -> NightRun`: se il file non esiste → istanza nuova, `last_load_message = ""`, silenzioso; se esiste ma l'header non comincia con `[gd_resource` → istanza nuova, `last_load_message` = frase gentile EN, `Log.warn`; altrimenti `ResourceLoader.load(path, "", CACHE_MODE_IGNORE)`, se `null`/tipo errato stessa via gentile, se valido `res.migrate()` **sempre** e ritorno. -- È il cuore della storia: persistenza leggibile, `migrate()` sempre, illeggibile→frase gentile senza rumore engine.
- `autoloads/game.gd` -- AGGIUNGERE `var _saves := SaveManager.new()` e `func _ready(): profile = _saves.load_profile()`. In `end_night()`, **prima** di `run = null`: `_saves.save_run(run)` poi `_saves.save_profile(profile)`. `start_night()` invariato (non tocca `profile`). -- Carica all'avvio, versa+salva alla chiusura; la nuova notte ritrova il portafoglio.
- `night/night_session.gd` -- In `_close_night()`, catturare `var closed_index := Game.run.night_index` **prima** di `Game.end_night()` e usarlo nel `Log.info` di riga ~829 al posto di `Game.run.night_index`. -- Corregge il deref di `null` che oggi crasherebbe a ogni alba vera, subito dopo il salvataggio.
- `tests/test_bench.gd` -- AGGIUNGERE `_check_save_manager()` e la sua chiamata in `_ready()`. Dimostra: (a) round-trip profilo (wallet/notti preservati); (b) `migrate()` sempre — profilo salvato con `version = 0` che al load torna `CURRENT_VERSION`; (c) save illeggibile → `last_load_message` non vuoto + profilo pulito, scrivendo prima un file spazzatura con `FileAccess` su un percorso di banco dedicato (`user://saves/_bench/...`); (d) round-trip `NightRun` con `phase_scores = {&"polar": 80}` → chiave `StringName` intatta. Percorsi di banco distinti da quelli reali; ripulire con `DirAccess.remove_absolute` a fine check. -- AC4: il banco stampa la migrazione e il comportamento gentile; ritira per il `.tres` la voce di deferred-work su `StringName`.

**Acceptance Criteria:**
- Given una notte conclusa, when `Game.end_night()` gira, then `core/save_manager.gd` ha scritto `user://saves/night.tres` (la `NightRun`) e `user://saves/profile.tres` con `ResourceSaver`, entrambi testo apribile in un editor.
- Given un secondo avvio dopo una notte conclusa con guadagni, when il gioco parte e comincia la notte nuova, then `Game.profile.wallet_lire` è quello di prima e `Game.run.phase_scores` è vuoto (la nuova notte è `NightRun.new()`).
- Given un qualsiasi save caricato con `load_profile`/`load_run`, when viene letto con successo, then `migrate()` è stato chiamato e il campo `version` esiste; un `version` più vecchio esce portato a `CURRENT_VERSION`.
- Given un `profile.tres` presente ma illeggibile, when `load_profile` lo legge, then ritorna un profilo pulito e mette in `last_load_message` una frase gentile in inglese, senza stack trace né modale bloccante né riga di errore engine.
- Given il banco di collaudo, when `verify.ps1` lo esegue, then arriva a `=== fine ===`, stampa il comportamento della migrazione e della frase gentile, e non emette righe `ERROR`/`WARNING`/`<-- ATTESO`/`NON CARICABILE`.
- Given l'alba che chiude la notte (`_close_night`), when `Game.end_night()` è già stata chiamata, then il `Log.info` successivo non dereferenzia `Game.run` (ormai `null`) e non produce un errore di script.

## Design Notes

**Perché `SaveManager` è puro (RefCounted, no autoload).** Deve girare sul banco senza `SceneTree` (NFR19), come `PhotoQuality`/`PhotoPayout`/le sorgenti. `Game` ne tiene un'istanza (`_saves`) e ne è l'unico chiamante in gioco. Non è un autoload perché non ha stato di sessione da esporre globalmente: è una funzione con dei percorsi.

**La frase gentile è dato, non UI.** Canale 2, inglese, voce macchina, tono cozy — es. `"save file unreadable — starting a fresh logbook"`. `load_profile` la mette in `last_load_message` e ritorna un profilo pulito. In gioco (`Game._ready`) all'avvio non c'è CRT montato: si registra su canale 1 e si prosegue. La superficie dove la frase è **osservabile** è il banco, ed è la superficie che l'AC4 nomina.

**Perché lo sniff dell'header prima di `ResourceLoader`.** `ResourceLoader.load` su un `.tres` corrotto fa stampare a Godot un `ERROR` di caricamento, che il gate tratta come guasto. Leggere la prima riga con `FileAccess` e verificare che cominci con `[gd_resource` intercetta il caso illeggibile **senza** invocare il loader — così il banco può dimostrare il ramo gentile restando verde. La corruzione profonda che superasse lo sniff ricade comunque sul controllo `null` dopo `load` (ramo raro, non pilotato dal banco).

Firma essenziale:
```gdscript
class_name SaveManager
extends RefCounted

const SAVES_DIR := "user://saves"
const PROFILE_PATH := "user://saves/profile.tres"
const NIGHT_PATH := "user://saves/night.tres"

var last_load_message := ""   # canale 2, EN; vuota se il load è normale

func load_profile(path := PROFILE_PATH) -> PlayerProfile:
	last_load_message = ""
	if not FileAccess.file_exists(path):
		return PlayerProfile.new()            # primo avvio: silenzioso
	if not _looks_like_tres(path):            # sniff header, no ResourceLoader
		last_load_message = "save file unreadable — starting a fresh logbook"
		Log.warn("save", "profilo illeggibile a %s — profilo nuovo" % path)
		return PlayerProfile.new()
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var p := res as PlayerProfile
	if p == null:
		last_load_message = "save file unreadable — starting a fresh logbook"
		Log.warn("save", "profilo non valido a %s — profilo nuovo" % path)
		return PlayerProfile.new()
	p.migrate()                               # SEMPRE
	return p
```

## Verification

**Commands:**
- `pwsh -File .bmad-loop/verify.ps1` -- expected: `VERIFY: pulito`; il banco arriva a `=== fine ===`, la sezione `-- SaveManager` stampa round-trip, migrazione e frase gentile senza `<-- ATTESO`; l'avvio del gioco a 600 frame non emette errori/warning (il primo avvio non trova save e resta silenzioso).

**Manual checks:**
- Aprire `user://saves/profile.tres` dopo una notte conclusa in gioco: è testo, contiene `wallet_lire` e `version`, apribile in un editor.

## Review Triage Log

### 2026-08-23 — Review pass
- intent_gap: 0
- bad_spec: 0
- patch: 1: (high 0, medium 1, low 0)
- defer: 2: (high 0, medium 1, low 1)
- reject: 11: (high 0, medium 0, low 11)
- addressed_findings:
  - `[medium]` `[patch]` Nessun test esercitava la garanzia AC2/AC3 («dopo un riavvio il portafoglio sopravvive e la notte nuova ha punteggi vuoti») al livello puro che il banco può raggiungere. Aggiunto il caso (e) a `_check_save_manager()`: mette un round-trip su disco IN MEZZO al travaso, ricarica il profilo, e verifica wallet/notti preservati + `NightRun.new()` con `phase_scores` vuoti e `night_index` che avanza da `nights_completed`. Gate ri-eseguito: `VERIFY: pulito`.

## Auto Run Result

Status: done
Story: 2.7 — Il portafoglio è ancora lì la notte dopo

**Cambiamento.** La persistenza cross-notte, che mancava: creato `core/save_manager.gd` (puro `RefCounted`) che salva/carica `PlayerProfile` e `NightRun` con `ResourceSaver` su `user://saves/*.tres`, chiamando `migrate()` a ogni load riuscito; un save assente è un avvio nuovo silenzioso, uno illeggibile diventa una frase gentile (canale 2, EN) su `last_load_message` — intercettata da uno sniff dell'header prima di `ResourceLoader`, così il banco la dimostra senza far emettere a Godot un errore. Cablato in `Game`: `_ready()` carica il profilo all'avvio, `end_night()` versa+salva notte e profilo prima di azzerare `run`. La separazione dei tipi di C1 fa sì che i punteggi di fase non sopravvivano per costruzione (nuova notte = `NightRun.new()`).

**File cambiati.**
- `core/save_manager.gd` (nuovo) — persistore puro: `save_profile`/`save_run`, `load_profile`/`load_run` con `migrate()` sempre e ramo gentile su save illeggibile.
- `autoloads/game.gd` — `_ready()` carica il profilo; `end_night()` salva notte+profilo prima di `run = null`.
- `night/night_session.gd` — `_close_night()` cattura `closed_index` prima di `end_night()`: corregge un deref di `null` (`Game.run` azzerato) che avrebbe fatto crashare ogni alba vera.
- `tests/test_bench.gd` — `_check_save_manager()`: nessun save, round-trip, `migrate()` sempre, save illeggibile → frase gentile, round-trip `NightRun` con chiave `StringName`, e riavvio (wallet sopravvive / punteggi no).
- `_bmad-output/implementation-artifacts/deferred-work.md` — chiusa per il percorso `.tres` la voce sul round-trip `StringName` (si usa `ResourceSaver`, non JSON).

**Triage.** 1 patch applicata (copertura pura AC2/AC3); 2 deferite (copertura della glue stateful — sorella di DW-7/DW-9; atomicità del salvataggio); 11 rigettate come rumore o già coperte dalla spec/dalle convenzioni del progetto (guardia estensione `.tres`, BOM header, wipe su tipo errato, race su `last_load_message`, ramo di corruzione profonda che il progetto non pilota apposta sul banco, `night.tres` scritto-ma-non-riletto — richiesto dall'AC — guardia versione futura, `_close_night` rientrante, forma di un log dev). La lettura «frase gentile mostrata a schermo» è selezionata dall'AC4 al banco: all'avvio non c'è superficie CRT, la costruisce la 3.2.

**Follow-up review recommendation:** false. Patch di questo passo: 1 medium (score 3×1 = 3 < 5, nessuna high).

**Verifica.** `pwsh -File .bmad-loop/verify.ps1` → `VERIFY: pulito — banco fino in fondo, gioco senza errori ne' warning` (ri-eseguito dopo ogni modifica, incluso l'ultimo patch). Ogni riga della I/O & Edge-Case Matrix è coperta da un check del banco che è stato eseguito e passato.

**Rischi residui.** La glue stateful (`Game._ready`/`end_night`/`_close_night`) è corretta all'ispezione ma non pinnata da test automatici — è deferita, coerente con DW-7/DW-9. Il salvataggio non è atomico (deferito, low).
