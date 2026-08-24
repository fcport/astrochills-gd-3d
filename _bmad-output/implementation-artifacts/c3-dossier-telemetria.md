# C3 — La telemetria, cioè lo strumento di misura dell'MVP

> **CHIUSO il 2026-08-24, insieme a Federico.** Il rilievo era aperto dal
> `implementation-readiness-report-2026-08-21.md` §5 e bloccava la storia 3.6, ultima
> dell'epica 3. Questo documento contiene i fatti raccolti nel repository, la decisione
> presa, e le tre correzioni ai documenti che ne discendono.

Dossier preparato il 2026-08-24, come il gemello `c1-dossier-stato-cross-notte.md`. A
differenza di quello, questo si apre già chiuso: la parte da decidere era una sola e
Federico l'ha decisa (vedi «La domanda che era sua», in fondo).

---

## Il rilievo, testuale

> **C3 — La telemetria, cioè lo strumento di misura dell'MVP, ha tre collocazioni
> contraddittorie e nessun proprietario.**

| Documento | Dove dice che vive |
|---|---|
| `game-architecture.md:686` — albero delle cartelle | `log.gd  # logging + telemetria di sessione` |
| `game-architecture.md:1010` — Pattern 2, regola 3 | «la telemetria dell'attesa la raccoglie **la fase**, ascoltando `Events`» |
| `epics.md:1109` — storia 3.6 | «**non passa da `Log`**, perché non è un log» |

La prima e la terza si contraddicono alla lettera. La seconda dice una terza cosa ancora.
E nessuna delle tre dice chi apre il file, chi calcola `wait_total_min`, chi produce i
tratti `idle`, chi rileva `quit_mid_pose`.

---

## Cosa è già risolto dai fatti — verificato nel repository il 2026-08-24

Metà del rilievo si è chiusa da sola mentre l'epica 3 veniva costruita. Non richiede
nessuna decisione, solo di essere messo per iscritto.

- **`tuning_hash` esiste già.** È `Tuning.profile_hash` (`autoloads/tuning.gd:31`),
  calcolato da `_hash()` all'avvio sul profilo effettivo, override incluso.
- **I quattro emettitori esistono tutti e sono corretti.** `caffe`
  (`world/interactables/moka.gd:178,180`), `lampada` (`lamp.gd:185,215`), `cupola`
  (`world/dome_activity.gd:185,196`), `forum` (`bbs/bbs.gd:148,159`) — ognuno con la
  coppia `started`/`ended` che la chiusura di C4 aveva preteso.
- **Nessuno li ascolta.** Verificato con `grep -rn "wait_activity_" --include=*.gd`: solo
  emissioni e commenti. Il condotto è posato e non ha un capo.
- **La finestra della posa è già sul bus.** `Events.phase_started.emit(p.key())`
  (`night/night_session.gd:748`) e `phase_finished` (`:776`); la chiave dell'imaging è
  `&"imaging"` (`phases/imaging/phase_imaging.gd:96`).
- **`night`** è `Game.run.night_index`, che dalla chiusura di C1 avanza davvero.

Restano scoperti solo `menu_reopened` e `quit_mid_pose`. Sono in fondo.

---

## Perché NON la fase — la regola 3 dell'architettura è scorretta, non ambigua

Quattro ragioni, tutte misurabili nel codice che esiste oggi.

1. **La fase muore e rinasce più volte per notte.** `night_session.gd:720-735` istanzia
   ogni fase e la `queue_free`a all'uscita. L'imaging gira una volta per foto, più le
   repliche di *rifai setup* della 2.6. Uno stato che deve durare **tutta la notte** non
   può vivere in un oggetto costruito e distrutto quattro volte.
2. **Le attività non stanno nella fase.** Moka, lampada e cupola vivono in `world/`, il
   forum in `bbs/`. La fase non le vede mai — le vede il bus, che è esattamente perché il
   bus esiste.
3. **`phases/` può conoscere solo `core/`.** Un proprietario della telemetria non è
   `core/`. La fase dovrebbe quindi scriversi il file da sé — e allora nessuno fonderebbe
   le quattro pose di una notte in **un** file, che è ciò che l'AC chiede.
4. **`quit_mid_pose` non è osservabile da lì.** Un oggetto che sta venendo distrutto non
   è il posto da cui intercettare la chiusura dell'applicazione.

**Il punto vero che la regola 3 conteneva.** Diceva: «è l'unica che sa quando l'attesa è
cominciata e quando finisce». È vero, e la correzione lo conserva: **la fase non raccoglie,
dichiara la finestra** — e lo fa già, emettendo `phase_started(&"imaging")`. Chi misura la
ascolta, non la sostituisce.

## Perché NON `Log`

`autoloads/log.gd` sono 52 righe senza stato: `[sistema] messaggio`, quattro livelli,
append su `user://logs/AAAA-MM-GG.log`. La telemetria è **un oggetto JSON per notte con
stato accumulato**, che si apre all'inizio della notte e si chiude all'alba. Metterla lì
vuol dire dare stato mutabile per-notte a `Log`, e rendere falsa alla lettera l'AC della
3.6. La riga dell'albero è un residuo di quando la telemetria era un'idea di una riga.

---

## LA DECISIONE — `autoloads/telemetry.gd`, quinto autoload

Un nodo che **ascolta il bus e basta**. Non è raggiunto da nessuno: nessun altro file lo
nomina, e se lo si toglie dagli autoload il gioco continua a funzionare identico. È la
proprietà che lo rende sicuro — lo strumento di misura non deve poter cambiare ciò che
misura.

### Cosa ascolta

| Segnale | A cosa serve |
|---|---|
| `wait_activity_started(what)` / `wait_activity_ended(what)` | gli intervalli delle quattro attività |
| `phase_started(key)` / `phase_finished(key, score)` | apre e chiude la **finestra della posa** su `&"imaging"` |
| `dawn_reached()` | scrive il file e chiude la notte |
| `photo_menu_opened()` — **nuovo, vedi sotto** | conta `menu_reopened` |

### Come si calcolano i campi

- **`t` e `dur` sono minuti di gioco** dall'inizio della notte, come nell'esempio
  dell'architettura (`"t": 12.0`). Non secondi reali: altrimenti due notti giocate con
  `game_min_per_sec` diverso non sarebbero confrontabili, che è la ragione per cui
  `tuning_hash` è obbligatorio.
- **`idle` si calcola per differenza sull'UNIONE degli intervalli**, non sulla somma. Il
  caffè sul fuoco mentre si sale in cupola è il caso normale, e sommando si otterrebbe
  più attività che tempo.
- **Un'attività che comincia fuori da una posa viene registrata lo stesso**, con la sua
  `t` e la sua `dur`; è solo `idle` che si calcola sulle sole finestre di posa. Ometterla
  la renderebbe indistinguibile da una mai fatta — lo stesso argomento con cui l'AC
  pretende `abandoned: true` invece del silenzio.
- **`wait_total_min`** è la somma delle finestre di posa della notte, non la durata della
  notte: è l'attesa che l'MVP misura.

### I due momenti in cui si scrive

1. **L'alba** (`dawn_reached`) — il caso normale, `quit_mid_pose: false`.
2. **La chiusura dell'applicazione a notte aperta** — il file si scrive comunque, e
   `quit_mid_pose` è vero se in quel momento una finestra di posa era aperta.

Il secondo non è menzionato da nessun documento, ma senza di esso `quit_mid_pose` non può
mai valere `true`: la sessione che dovrebbe produrlo è precisamente quella che non arriva
all'alba. Il meccanismo (`NOTIFICATION_WM_CLOSE_REQUEST` sull'autoload, eventualmente con
`auto_accept_quit`) **va verificato eseguendolo**, non stimato: chiudere la finestra a posa
in corso e aprire il file che ne risulta.

### E una riga in `F12` — deciso il 2026-08-24

Oltre al file, l'overlay di debug mostra **dal vivo** l'attesa della posa in corso e quanta
ne è scoperta. Il dato è già in memoria, costa una riga, e serve **mentre** si gioca — che
è quando l'attesa si giudica. Il file resta per il confronto fra notti, che è un'altra cosa
e si fa dopo.

`debug/debug_overlay.gd` legge da `Telemetry`, mai il contrario: la dipendenza va nella
direzione che si può tagliare in release senza toccare la misura.

---

## I due buchi che nessun documento copriva

**`menu_reopened` non ha un condotto.** Il menu post-foto (`night/post_photo_menu.gd`)
`extends Control`, non `Phase`: non emette `phase_started`, e nessun altro segnale annuncia
che è stato presentato. Serve **un segnale nuovo sul bus**, `photo_menu_opened()`, emesso
da `night_session` dove monta il menu.

Sul bus e non diretto per la stessa ragione con cui ci sta `wait_activity_*`: chi è
misurato non deve conoscere chi misura, e togliendo l'autoload il segnale resta a cadere
nel vuoto senza rompere niente.

**`quit_mid_pose` implica un secondo momento di scrittura.** Vedi sopra.

---

## Le tre correzioni ai documenti

1. `game-architecture.md`, albero: `log.gd # logging + telemetria di sessione` →
   `log.gd # logging tecnico. La telemetria NON passa di qui`, e `telemetry.gd` aggiunto
   come quinto autoload.
2. `game-architecture.md`, Pattern 2 regola 3: la fase **dichiara** la finestra, non
   raccoglie.
3. `epics.md`, storia 3.6: il proprietario è nominato; aggiunti il segnale
   `photo_menu_opened`, il secondo momento di scrittura, `forum` fra le attività, e la
   riga in `F12`.

---

## La domanda che era sua

Tutto il resto qui sopra discende dai fatti. Una cosa sola non ne discendeva: **se un file
JSON su disco sia la forma giusta per l'unico giocatore che testerà questo gioco.**

Federico ha scelto **il file più una riga in `F12`**: il file per confrontare le notti fra
loro, la riga per sentire l'attesa mentre la vive. Le altre due strade erano «solo il file»
(la 3.6 come scritta) e «solo la riga, e il file si rimanda» — che avrebbe rinviato FR32.
