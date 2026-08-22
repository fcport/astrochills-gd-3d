---
baseline_commit: 624b202
---

# Story 1.2: L'osservatorio esiste, e ci sei dentro

Status: done

Story key: `1-2-losservatorio-esiste-e-ci-sei-dentro`
Epic: 1 — Il primo pezzo di mestiere — l'allineamento polare, e il seam che regge

---

## Story

As a **gestore notturno appena assunto**,
I want **camminare in prima persona nella stanza computer e vedere il monitor acceso sulla scrivania**,
So that **quel posto esista come luogo prima ancora di esistere come interfaccia**.

> **Questa storia costruisce un luogo, non un sistema.** È la cerniera fra la 1.1, che ha
> fatto la fase senza un posto dove giocarla, e la 1.3, che le unisce sedendo il giocatore
> al monitor. Oggi nel progetto **non esiste una sola primitiva 3D**: `main.tscn` mostra il
> `Control` della fase dentro un viewport vuoto. Questa storia è la prima che mette un
> mondo dentro quel viewport.

**Perché la stanza sta nell'epica 1 e non nell'epica 3.** `epics.md § Churn sui file` lo
dichiara: «l'epica 1 **non può esistere** senza una stanza e un giocatore — non ci si siede
a un CRT dal vuoto — e spostare quel lavoro nell'epica 3 renderebbe l'epica 1 non
giocabile, cioè distruggerebbe il gate di rischio che è la sua unica ragione di essere».

---

## Acceptance Criteria

Riportati da `epics.md § Story 1.2`, numerati per riferimento dai task. **Non riscritti.**

### AC1 — Si cammina in prima persona, e la camera è la testa

**Given** la stanza computer costruita in `world/rooms/`
**When** il giocatore usa i comandi di movimento e il mouse
**Then** si muove in prima persona con un `CharacterBody3D` e guarda intorno
**And** la camera è **figlia del corpo e non se ne stacca mai**: non esiste nel progetto una riga che la riparenti o la sposti da sola
**And** la stanza è renderizzata con `ps1.gdshader` a `snap_resolution = 665`, dentro il `SubViewport` a bassa risoluzione

### AC2 — Il contratto di interazione

**Given** il contratto di interazione in `world/interactables/`
**When** il giocatore guarda un oggetto interagibile da vicino
**Then** appare un prompt diegetico e discreto, e l'interazione si esegue con **un tasto solo**
**And** il prompt non è un modale, non ferma il gioco e non copre la scena

### AC3 — Il monitor si annuncia, nessuno lo cerca

**Given** il monitor CRT come oggetto del mondo in `world/interactables/`
**When** entra in scena
**Then** emette `Events.screen_registered` con il proprio `CrtScreen`
**And** nessun altro sistema lo cerca per percorso di nodo, che si romperebbe al primo spostamento

### AC4 — Le regole di dipendenza

**Given** le regole di dipendenza dell'architettura
**When** si cerca `phases/` o `night/` dentro `world/`
**Then** non c'è nessuna occorrenza: `world/` conosce solo `core/` e `crt/`

---

## Tasks / Subtasks

### Task 0 — Risolvere la collisione WASD PRIMA di scrivere il movimento (AC1)

> **Questo task viene prima di tutto perché è l'unico modo in cui questa storia può
> fallire in silenzio.** Non è un dettaglio di input: è la ragione per cui il movimento
> non può essere scritto ingenuamente.

`project.godot` lega già questi tasti, generati dalla storia 1.1:

| Tasto | `physical_keycode` | Azione | Cosa fa |
|---|---|---|---|
| `W` | 87 | `polar_alt_inc` | vite di altitudine, su |
| `S` | 83 | `polar_alt_dec` | vite di altitudine, giù |
| `A` | 65 | `polar_az_dec` | vite di azimuth, giù |
| `D` | 68 | `polar_az_inc` | vite di azimuth, su |
| `ENTER` | 4194309 | `polar_finish` | chiude la fase |

`main.gd::_ready()` istanzia la fase all'avvio. Quando la stanza entrerà in scena, **gli
stessi quattro tasti muoveranno il giocatore e gireranno le viti nello stesso frame.**

- [x] **NON rinominare le azioni polari.** `phases/polar/phase_polar.gd` le nomina
      (`Input.get_axis(&"polar_az_dec", &"polar_az_inc")`, `event.is_action_pressed(&"polar_finish")`),
      e l'AC2 della storia 1.1 richiede che quel file **non cambi di una sola riga** — è
      la prova che ADR-001 regge, ed è rieseguibile con `git diff` da quando esiste il
      repository. Rinominare le azioni la distruggerebbe per una ragione di comodo.
- [x] Dichiarare le azioni nuove in `project.godot`, nomi in inglese, **sulle stesse
      lettere**: `move_forward` (W), `move_back` (S), `move_left` (A), `move_right` (D),
      `interact` (E). Convivere sugli stessi tasti va benissimo: è la sorgente che ascolta
      a dover essere una sola alla volta.
- [x] **Rendere fase e giocatore mutuamente esclusivi**, ed è il ponte dichiarato di questa
      storia. Il controller del giocatore è attivo quando la fase non lo è, e viceversa.
      Interagendo col monitor si entra nella fase e il controller si spegne; uscendo dalla
      fase, il controller torna attivo.
- [x] Lo scambio lo fa **`main.gd`**, non `world/`: il punto d'ingresso è l'unico che può
      conoscere sia `world/` sia `phases/` (vedi § Architectural Boundaries, riga «punto
      d'ingresso»). Il monitor si limita a emettere un signal generico; è `main.gd` a
      tradurlo in «entra nella fase».
- [x] **Spegnere il controller è lavoro che la 1.3 NON butta:** ADR-003 comincia
      testualmente con «il controller del giocatore si disabilita». Qui si costruisce il
      primo passo di quella sequenza; la 1.3 aggiunge gli altri.
- [x] Le azioni dell'`InputMap` **vanno generate da uno script eseguito dall'engine**, non
      scritte a mano: la serializzazione dei keycode nella sezione `[input]` è verbosa e
      facile da sbagliare a memoria. È il metodo che ha usato la 1.1. Cancellare lo script
      generatore a lavoro finito.
- [x] **Verifica:** in gioco, camminando, la stella nel reticolo non si muove; nella fase,
      girando le viti, il giocatore non cammina.

### Task 1 — Il giocatore (AC1)

- [x] `world/player/player.tscn` + `world/player/player.gd`, `class_name Player extends CharacterBody3D`
- [x] **Yaw sul CORPO, pitch sulla CAMERA. Non negoziabile.** `crt/desk_camera.gd` è già
      scritto e interpola `_player.global_transform` con la sola imbardata
      (`Basis(Vector3.UP, euler.y)`) e `_cam.rotation:x` separatamente. Un controller che
      mettesse il pitch sul corpo o lo yaw sulla camera **rompe la 1.3**, che non è ancora
      scritta e non potrà accorgersene finché non sarà tardi.
- [x] La `Camera3D` è **figlia** del `CharacterBody3D`, a una `position` locale costante —
      l'offset della testa. `desk_camera.gd` calcola
      `target.origin = seat_xf.origin - target.basis * _cam.position` e presume che quella
      `position` sia stabile e sia l'unica cosa che separa l'origine del corpo dall'occhio.
- [x] `clamp` del pitch a ±90°, altrimenti la testa si ribalta e `desk_camera` interpolerà
      da un angolo assurdo.
- [x] `Input.MOUSE_MODE_CAPTURED` mentre si cammina. Prevedere un modo di liberare il
      cursore che **non usi `F1`-`F4`** (riservati a FR35, storia 2.1) e non usi `F9`/`F12`.
- [x] Il controller deve essere **spegnibile dall'esterno** con un metodo o una proprietà
      esplicita (`set_enabled(bool)`), non solo con `set_physics_process(false)`: serve al
      Task 0 e servirà alla 1.3.
- [x] Movimento con `Input.get_vector` su azioni **dichiarate**. Niente polling di keycode
      grezzi: era la scorciatoia dello spike, dichiarata tale, e non va ereditata.
- [x] Gravità e `move_and_slide()`. Niente sprint, niente crouch, niente salto: «si
      cammina, non si combatte».
- [x] **Misure, e perché queste.** Il progetto lavora in metri. Sono ricavate a ritroso dal
      `Marker3D` `Seat` di `crt_screen.tscn`, che sta a `(0, 0.09, 0.44)` dal centro dello
      schermo: la camera seduta atterra lì, quindi il centro dello schermo sta all'altezza
      occhi da seduto **meno 9 cm**.

      | Misura | Valore proposto | Vincolo che lo genera |
      |---|---|---|
      | Altezza occhi in piedi | 1,65 m | nessuno — sceglierla qui la fissa per tutto il gioco |
      | Piano della scrivania | 0,75 m | misura reale di una scrivania |
      | Centro dello schermo CRT | ~1,10 m | il CRT poggia sulla scrivania |
      | Origine del `Seat` che ne risulta | ~1,19 m | 1,10 + 0,09 — è un'altezza occhi da seduto plausibile |

      Sono **proposte, non requisiti**: nessun documento le fissa. Vanno verificate
      guardando, non stimando, e una volta scelte vincolano la 1.3.

### Task 2 — Il contratto di interazione (AC2, FR24, UX-DR9)

> L'architettura fissa **solo il nome del file**: `world/interactables/interactable.gd # contratto interazione`.
> Nessuna classe base, nessun metodo, nessun signal è specificato. Quello che decidi qui
> diventa il precedente per la moka (3.3), la lampada (3.4) e la cupola (3.5).

- [x] `world/interactables/interactable.gd` — il contratto comune. Serve almeno: un testo
      di prompt, un modo per sapere se è interagibile adesso, e un signal emesso quando
      l'interazione avviene.
- [x] **L'interazione è un signal DIRETTO, non `Events`.** La tabella § Communication
      dell'architettura elenca `interazione → oggetto interagibile` nella colonna «Diretto».
      La regola: «se sai chi ascolta ed è uno solo → signal diretto». Il giocatore sa
      esattamente con quale oggetto sta interagendo. `Events` è per i fatti di notte con
      più di due ascoltatori, e «il bus senza regola diventa una discarica in tre mesi».
- [x] Il rilevamento: un `RayCast3D` dalla camera è la scelta più semplice e coerente con
      «guarda un oggetto interagibile **da vicino**». Serve un layer di collisione dedicato
      agli interagibili — **non ne esiste nessuno**, va creato e nominato.
- [x] **La portata dell'interazione deve essere compatibile con i 44 cm del `Seat`.**
      ADR-003 dice «sei già davanti al monitor, altrimenti non potresti interagirci»: se si
      potesse interagire da tre metri, la 1.3 teletrasporterebbe il corpo e lo spirito
      dell'ADR sarebbe violato. Tenerla corta — indicativamente sotto il metro e mezzo.
- [x] Il prompt: **diegetico e discreto** (UX-DR9). Non un modale, non ferma il gioco, non
      copre la scena, nessun pannello d'errore. Vive in `world/`, **non in `ui/`** — `ui/` è
      riservato a pausa e impostazioni (UX-DR1).
- [x] **La lingua del prompt è una decisione, non un dettaglio.** NFR10 dice «IT è la
      lingua del giocatore, EN è la lingua delle macchine». Un prompt di interazione lo
      legge il giocatore e non lo scrive una macchina del 1999: **italiano**. Il testo sul
      CRT resta inglese. Segnare la scelta in un commento dove il prompt si costruisce,
      perché è il precedente per tutti i prompt futuri.
- [x] Un tasto solo, `E`. È libero, ed era il tasto dello spike per sedersi — l'unico
      precedente esistente. Nessun documento lo prescrive.

### Task 3 — La stanza computer (AC1, FR23 parziale)

- [x] `world/rooms/computer_room.tscn`. **Solo la stanza computer**: cucina e cupola sono
      della storia 3.1 e completano FR23 lì.
- [x] **Cosa c'è dentro, dai documenti creativi.** `idea.md §3.1` è l'unica fonte che
      elenca il contenuto: «la postazione di lavoro reale. **PC con CCDOPS / MaxIm DL,
      monitor CRT, modem 56k. Adiacente al telescopio**, perché chi osserva deve essere a
      un passo dall'oculare/montatura. Qui passa la maggior parte del tempo di gioco.»
- [x] **La pianta.** `docs/idea/osservatorio/oss_2_2.png` mostra la «Stanza del computer»
      come un vano rettangolare più alto che largo, **con una sola porta** in alto a destra
      che dà su un corridoio, e la parete sinistra in comune con il grande vano del
      telescopio. Non ci sono quote, non c'è arredo disegnato, non ci sono finestre. La
      pianta dà **adiacenze e una porta**, non un ambiente: il resto è da inventare, e non
      c'è una fonte da tradire.
- [x] **Ambientazione 1999, nessun anacronismo** (NFR11): niente USB, niente Wi-Fi, niente
      cloud. Seriale e modem 56k. Un CRT, non un pannello piatto.
- [x] **Kit-bashing modulare** (`idea.md §14`): pareti, pavimenti, porte, infissi come
      pezzi ripetibili. Non modellare l'ambiente da zero.
- [x] Collisioni: il giocatore non attraversa i muri. Nessuna convenzione di layer esiste
      nel progetto — va inventata e scritta.
- [x] **La densità della mesh è una scelta di illuminazione, non solo di silhouette.**
      `ps1.gdshader` dichiara `render_mode vertex_lighting`: la luce è calcolata **per
      vertice**, quindi un muro fatto di due triangoli la riceve solo agli angoli.
      Suddividere dove la luce deve leggersi.
- [x] Atmosfera, da `idea.md §12`, ed è una direttiva tecnica travestita da frase evocativa:
      «**il freddo si vede, il buio ha texture.** In 3D questo si ottiene con
      **illuminazione (poche sorgenti calde in un volume freddo)**, non con la palette.»
- [x] Fuori scopo, e la tentazione è ovvia perché la pianta le mostra: **niente stanza
      segreta, niente bagno, niente ingresso, niente cucina, niente cupola, niente esterno,
      nessuna nota nascosta, nessun lore drop.**

### Task 4 — I materiali PS1 (AC1, NFR3, NFR4)

- [x] Ogni `MeshInstance3D` della stanza usa un `ShaderMaterial` su
      `world/shaders/ps1.gdshader`, con `snap_resolution = 665`.
- [x] **Usare `material_override`, non `surface_material_override/0`.** Non è una
      preferenza: `debug/render_tuning.gd::_collect_materials()` cerca **solo**
      `material_override`. Con i materiali per-superficie, `Shift+F5`/`F6`/`F7` non
      raggiunge la stanza e il log dirà «0 materiali» — cioè lo strumento con cui i valori
      PS1 sono stati tarati resterebbe cieco proprio sulla prima geometria che il progetto
      abbia mai avuto. È la voce di `deferred-work.md` che questa storia sblocca.
- [x] `crt/crt_screen.gd` usa invece `get_surface_override_material(0)`, ed **è giusto
      così**: il CRT non deve essere toccato dalla taratura del jitter del mondo.
- [x] Lo shader espone `albedo` e nient'altro: **oggi la stanza è a colori piatti**, senza
      texture. L'affine texture mapping «arriva quando ci saranno texture vere» — non è
      questa storia.
- [x] **Non «migliorare la resa».** Nessun filtro lineare, nessuna mipmap, nessun
      antialiasing, nessun bloom, nessuna ombra morbida (NFR4). `stretch_shrink = 2` e
      `snap_resolution = 665` sono valori **validati sul campo il 2026-08-21 guardando lo
      schermo**, non stimati: non cambiarli senza una ragione dichiarata.
- [x] Il dithering e la gradazione colore fredda sono indicati come desiderabili in
      `project-context.md` ma marcati «**Non ancora implementato**». Fuori da questa storia
      se non richiesti.

### Task 5 — Il monitor come oggetto del mondo (AC3, chiude il rilievo M5)

- [x] `world/interactables/crt_monitor.tscn` — la geometria del monitor, che **avvolge**
      l'istanza di `crt/crt_screen.tscn`. Il `QuadMesh` del CRT è `0,32 × 0,24 m`: è la
      misura reale del vetro. Costruire la scocca intorno, non sostituire il quad.
- [x] Il monitor è un `Interactable`: guardandolo da vicino compare il prompt.
- [x] **CHI EMETTE `screen_registered` — decisione da chiudere qui.**
      `crt/crt_screen.gd::_ready()` **emette già** `Events.screen_registered.emit(self)`.
      Lo snippet dell'architettura fa emettere `Events.screen_registered.emit($CrtScreen)` a
      `crt_monitor.gd`. **Applicare la storia alla lettera produce due registrazioni**, e la
      1.3 collegherebbe `_crt` due volte.
      **Decisione: emette `CrtScreen`, e `crt_monitor.gd` non emette nulla.** Ragione: il
      codice esistente ha già scelto; `crt/` è il sistema generico che possiede il tipo; e
      così `world/` non ha bisogno di conoscere `CrtScreen` per annunciarlo. L'AC3 resta
      soddisfatto — il monitor entra in scena e la registrazione parte — senza che
      `crt_monitor.gd` scriva una riga di `Events`.
      Il rilievo M5 del readiness report è assegnato a questa storia dal rendiconto della
      1.1. **Chiuderlo qui, e scriverlo nel Change Log.**
- [x] La firma è `signal screen_registered(screen: Node)`, non `(screen: CrtScreen)`.
      L'architettura scrive `func(s: CrtScreen)` nello snippet, ma `autoloads/events.gd` è
      già scritto e tipizza `Node` — probabilmente di proposito, perché tipizzare un
      autoload su `CrtScreen` accoppierebbe `autoloads/` a `crt/`. **Non «correggere» il
      signal.**
- [x] Nessun sistema cerca il monitor per percorso di nodo. Niente `get_node("../../Monitor")`,
      niente `%CrtMonitor` da fuori.

### Task 6 — Mettere il mondo dentro `main.tscn` senza buttare il ponte (AC1)

- [x] `world/observatory.tscn` — la scena contenitore. **Non è di nessuna storia**
      (rilievo m3): questa è la prima che ne ha bisogno, quindi la crea. Con una stanza
      sola sembrerà sovrastruttura: non lo è, la 3.1 ci appende cucina e cupola.
- [x] L'osservatorio va istanziato **dentro `%SubViewport`** di `main.tscn`, cioè dentro il
      viewport a bassa risoluzione — altrimenti il look PS1 non lo tocca.
- [x] `main.tscn` **non dichiara la misura del `SubViewport`**, ed è voluto: il
      `SubViewportContainer` con `stretch = true` la impone sempre a
      `container / stretch_shrink`. Un `size` scritto a mano è un numero morto. Non
      rimetterlo.
- [x] **Non smontare `ScreenHost`/`ScreenViewport`.** È il «CRT povero» del ponte della
      1.1, e la fase continua a mostrarsi lì finché la 1.3 non porta il `Control` sul CRT
      vero. Smontarlo adesso significa fare due volte il lavoro della 1.3.
- [x] Aggiornare il commento di intestazione di `main.gd`: oggi dice «Con `spike/`
      cancellata non esiste ancora una stanza: la storia 1.2 costruisce l'osservatorio».
      Dopo questa storia non è più vero.
- [x] **Il costo del secondo viewport, da dichiarare e non risolvere.**
      `crt/crt_screen.tscn` ha `render_target_update_mode = 4` (`UPDATE_ALWAYS`), contro
      NFR15. Questa storia porta per la prima volta un `CrtScreen` dentro il mondo, cioè
      rende quel render pass un costo reale. È il rilievo **M4**, che il rendiconto della
      1.1 marca «nessuna storia lo corregge — **non aprirlo qui**». **Non correggerlo di
      slancio.** Se la resa peggiora visibilmente, registrarlo in `deferred-work.md` invece
      di cambiare un valore che nessuno ti ha chiesto di cambiare.

### Task 7 — Le verifiche che l'AC4 promette (AC4, NFR8)

- [x] `grep -rn "phases/" world/` → **zero occorrenze**
- [x] `grep -rn "night/" world/` → **zero occorrenze**
- [x] `grep -rn "debug/" world/` → **zero occorrenze** (l'eccezione al confine di `debug/`
      vale solo per il punto d'ingresso)
- [x] Nessuna riga, in nessun file, riparenta o sposta la camera da sola. È letteralmente
      la formulazione dell'AC1: «non esiste nel progetto una riga che la riparenti o la
      sposti da sola». Cercare `reparent` e le assegnazioni a `camera.global_transform`
      fuori dal player.
- [x] Eseguire il gioco: **zero errori e zero warning** in console. È lo standard che la
      1.1 ha lasciato, ed è verificabile con
      `Godot_v4.7.2-stable_win64.exe --headless --path . --quit-after 300`.
- [x] `tests/test_bench.tscn` continua a girare pulito. **Non aggiungerci niente:** il
      banco accetta solo logica pura, e movimento, shader, prompt e viewport sono tutte
      cose di scena. Non introdurre GUT o gdUnit4.

### Review Findings

Code review del 2026-08-22, tre layer paralleli (Blind Hunter, Edge Case Hunter,
Acceptance Auditor) sul diff `624b202..9191a2b`. 33 rilievi grezzi, 2 scartati come rumore.
**Tutte le decisioni sono state prese e tutte le patch applicate nella stessa sessione**;
6 voci restano rinviate con una ragione, e vivono in `deferred-work.md`.

**Decisioni prese**

- [x] [Review][Decision] **La catena delle misure non chiudeva: sedersi avrebbe affondato il corpo 46 cm sotto il pavimento** — Il `Seat` sta a global y = 1,19 e l'occhio a 1,65 sopra l'origine del corpo, quindi `desk_camera.gd:57` porterà l'origine del `CharacterBody3D` a y = −0,46. **Deciso: è corretto che ci vada** — la camera atterra dove deve — e ciò che mancava era la garanzia che la fisica non lo risputasse fuori. `Player._physics_process()` adesso esce subito da spento: niente gravità, niente `move_and_slide()`, niente depenetrazione. La catena è scritta per esteso nell'intestazione di `player.gd` e in `observatory.tscn`, dove qualcuno la cercherà. Chiusa anche la compenetrazione del `Seat` nella scrivania: il monitor è passato da z = −2,10 a z = −2,05, e il corpo seduto ha adesso 3 cm di gioco invece di 1,9 cm di sovrapposizione.
- [x] [Review][Decision] **Il vetro del CRT sporgeva 11 cm sopra la scocca, e la metà superiore dello schermo non era mirabile** — La scocca era 0,40 × 0,36 × 0,38 e il vetro, alto 0,24 e montato a y = 0,35, ne usciva. **Deciso: si allarga la scocca, non si sposta il vetro**, così il centro dello schermo resta a 1,10 m e tutta la catena delle misure sopravvive. Scocca ora 0,42 × 0,50 × 0,38 con origine a y = 0,25: il vetro (0,23–0,47) sta dentro con 3 cm di cornice sopra e sotto e 5 cm per lato, e il collider — che è quello che il raggio colpisce — copre tutto lo schermo. Verificato dal vivo: mirando 8° più in alto del centro dello schermo il raggio trova ancora il monitor, dove prima usciva nel vuoto.
- [x] [Review][Decision] **Non esisteva una via d'uscita dalla fase, e in release poteva diventare un blocco totale** — **Deciso: guardia in `main.gd`, nessun comando nuovo.** `_phase_can_run()` interroga la fase PRIMA di toglierle il controllo del giocatore: una fase che dichiara una sorgente di verità e non l'ha ricevuta non riceverà mai l'input che la chiude, quindi non le si cede niente e il controllo resta al giocatore. La proprietà si interroga per nome — `&"truth" in p` — perché `phases/polar/phase_polar.gd` non si può toccare: è la prova dell'AC2 della storia 1.1. Verificato che il test distingua davvero: una proprietà inventata dà `false`.
- [x] [Review][Decision] **`Events.screen_registered` viene emesso durante la costruzione dell'albero e nessuno lo ascolta** — L'ordine profondità-prima fa emettere `CrtScreen` prima di `Main._ready()`, quindi chi nasce lì dentro si collega a segnale già passato. **Deciso: ripiego per gruppo**, cioè il meccanismo che questa storia ha già stabilito per il monitor. `CrtMonitor.find_in(tree)` è il modo in cui chi arriva tardi va a cercare invece di aspettare un annuncio; `crt/` non è stato toccato e il rilievo M5 resta chiuso com'era. Il perché è scritto nell'intestazione di `crt_monitor.gd`, dove chi si troverà senza registrazione lo cercherà.
- [x] [Review][Decision] **Il prompt è un HUD in screen space, non un prompt diegetico** — **Deciso: si tiene l'HUD e si corregge il commento**, che rivendicava una diegeticità che il codice non ha. A 640×360, con vertex snapping e filtro nearest, un testo montato nel mondo rischia di essere illeggibile alla distanza di interazione, e su questo progetto le cose di resa si decidono guardando e non stimando — con un interagibile solo non c'è niente da guardare. La verifica è rinviata all'epica 3, quando moka, lampada e cupola daranno un confronto vero.
- [x] [Review][Decision] **La stanza non conteneva il PC né il modem 56k che il Task 3 dichiara** — **Deciso: si aggiungono, e con loro la sedia.** `Pc` (tower a terra, con collisione), `Modem` (sulla scrivania, senza), `Chair` (seduta e schienale). La sedia **non ha collisione** deliberatamente: sta dove la 1.3 farà sedere il giocatore, e un corpo solido lì davanti impedirebbe di avvicinarsi al monitor a piedi — il prompt non comparirebbe mai.
- [x] [Review][Decision] **Il kit-bashing modulare dichiarato non c'era** — **Deciso: materiali e mesh condivisi**, l'opzione piena, perché la 3.1 duplica quello che trova: con 10 materiali distinti ne farebbe 30. I sei materiali identici delle pareti sono diventati un `MatWall` solo; pavimento e soffitto condividono `BoxSlab`, parete di fondo e di fronte `BoxWallLong`. Il colore delle pareti si cambia adesso in un punto.

**Patch applicate**

- [x] [Review][Patch] Entrando nella fase con W/A/S/D già premuti la vite girava da sola: ogni scambio adesso rilascia le azioni con `_release_all_actions()`, che itera l'`InputMap` invece di ricopiare i nomi delle azioni polari [main.gd]
- [x] [Review][Patch] Uscendo dalla fase con i tasti ancora premuti il giocatore partiva da solo; e `_advance` riabilitava il controller prima di liberare la fase. Adesso `_dispose()` toglie la fase dall'albero con `remove_child()` PRIMA di `queue_free()`, e il controllo torna dopo [main.gd]
- [x] [Review][Patch] `_set_world_active` risolve il giocatore prima di toccare qualunque cosa: sul percorso d'errore non resta più l'interfaccia della fase a schermo con il controller acceso sotto [main.gd]
- [x] [Review][Patch] `EYE_HEIGHT` e `INTERACT_RANGE` sono adesso le sorgenti di verità: `_ready()` le scrive nella camera e nel raggio, e la scena non le ripete più [world/player/player.gd, world/player/player.tscn]
- [x] [Review][Patch] `set_enabled(true)` non ricattura più il mouse se era stato il giocatore a liberarlo: `_mouse_free` ricorda la sua scelta e la distingue dal rilascio automatico all'ingresso in fase [world/player/player.gd]
- [x] [Review][Patch] Con il cursore libero il controllo è sospeso — niente passi, niente prompt, niente interazione: `_is_controlling()` è la condizione unica, perché camminare senza poter girare la testa è peggio che stare fermi [world/player/player.gd]
- [x] [Review][Patch] Solo la pressione del tasto sinistro ricattura il cursore: rotelle e rilasci non lo fanno più [world/player/player.gd]
- [x] [Review][Patch] `_look_at_interactable()` chiama `force_raycast_update()` prima di leggere, e la mira si riconferma al momento della pressione di `E`: non si interagisce più col monitor guardando la parete [world/player/player.gd]
- [x] [Review][Patch] Il raggio dell'interazione vede anche il mondo (`LAYER_WORLD | LAYER_INTERACTABLE`): ciò che colpisce e non è un `Interactable` fa da occlusore, quindi il primo oggetto appoggiato a un muro non sarà usabile dalla stanza accanto [world/player/player.gd]
- [x] [Review][Patch] I layer si aggiungono in `_enter_tree()` e in OR: nessuna sottoclasse deve più ricordarsi `super()`, e i valori scelti nell'ispettore non vengono più cancellati all'ingresso in albero [world/interactables/interactable.gd]
- [x] [Review][Patch] Lo stato iniziale si dichiara in `_ready()` con `_set_world_active(true)`, invece di dipendere da tre posti scollegati [main.gd]
- [x] [Review][Patch] Il commento di `_set_world_active` dice adesso la verità: si spegne il controllo, non il mondo, e il perché — alla 1.3 il giocatore seduto deve vedersi intorno la stanza [main.gd]
- [x] [Review][Patch] Il giocatore si trova per gruppo (`Player.GROUP`, `Player.find_in()`) come il monitor: la regola dell'AC3 vale per entrambi [main.gd, world/player/player.gd]
- [x] [Review][Patch] I layer di collisione hanno un nome: `layer_names/3d_physics` in `project.godot` («mondo», «giocatore», «interagibili») e le costanti `Interactable.LAYER_*` che il codice usa al posto dei numeri nudi [project.godot, world/interactables/interactable.gd]
- [x] [Review][Patch] I commenti di `debug/render_tuning.gd` non dicono più che la stanza non esiste, e spiegano che il conteggio nel log è per mesh e non per materiale distinto [debug/render_tuning.gd]
- [x] [Review][Patch] La voce di `deferred-work.md` su `_collect_materials` è aggiornata: sbloccata dalla 1.2, il salto dei materiali per-superficie non è più un difetto (il CRT lo sfrutta di proposito), resta aperta la sola mancata deduplicazione [deferred-work.md]
- [x] [Review][Patch] Il conteggio delle mesh è corretto in Completion Notes e Change Log [1-2-losservatorio-esiste-e-ci-sei-dentro.md]
- [x] [Review][Patch] La File List include `deferred-work.md` fra i modificati [1-2-losservatorio-esiste-e-ci-sei-dentro.md]

**Rinviati — reali, non azionabili adesso**

- [x] [Review][Defer] Un secondo `CrtMonitor` sarebbe inerte in silenzio: `_connect_monitor` collega solo il primo del gruppo, ma il prompt promette comunque l'azione [main.gd] — deferred, non raggiungibile oggi (un solo membro), morde nell'epica 3
- [x] [Review][Defer] Re-interagire col monitor dopo aver completato la fase la riavvia e sovrascrive `phase_scores` con il risultato nuovo [main.gd] — deferred, il save non esiste ancora
- [x] [Review][Defer] `ESC` non consuma l'evento e coincide con `ui_cancel`: quando arriverà la UI di pausa, un `ESC` libererà il cursore **e** aprirà la pausa nello stesso frame [world/player/player.gd] — deferred, morde quando esiste la pausa
- [x] [Review][Defer] Il tasto «[E]» è scritto a mano e slegato dall'`InputMap` [world/interactables/interaction_prompt.gd] — deferred, non esiste rebinding
- [x] [Review][Defer] `.normalized()` su `Input.get_vector` annulla il `deadzone: 0.2` dichiarato sulle sei azioni nuove [world/player/player.gd] — deferred, nessun asse analogico oggi
- [x] [Review][Defer] Le scene sono state editate a mano e il formato non è quello che l'editor riscriverebbe [world/rooms/computer_room.tscn, world/observatory.tscn] — deferred, nessuna conseguenza a runtime
- [x] [Review][Defer] Il prompt di interazione è un HUD e non un elemento del mondo: verificare a schermo nell'epica 3, con moka, lampada e cupola davanti [world/interactables/interaction_prompt.gd] — deferred per decisione presa in questa review

**Scartati come rumore (2)**

- «La sensibilità del mouse dipende dalla dimensione della finestra» — falso: `SubViewportContainer` riscala `relative` di `stretch_shrink`, che è fisso a 2. La sensibilità è costante, e il valore è stato tarato guardando. Il commento di `MOUSE_SENSITIVITY` è stato comunque reso preciso: sono radianti per pixel del **viewport**, non della finestra.
- «`CrtMonitor.screen()` e `Player.camera()` non sono chiamate da nessuno» — impalcatura per la 1.3, dichiarata tale nei commenti di entrambe.

**Verifiche eseguite dopo le patch**

- Gioco a zero errori e zero warning: `--headless --path . --quit-after 300`.
- Banco di collaudo `tests/test_bench.tscn` pulito, nessun framework di test aggiunto.
- Ciclo della stanza provato dal vivo con una sonda temporanea, poi rimossa: il raggio trova il monitor (maschera 5, layer del monitor 5), il prompt compare, mirando 8° più in alto il raggio tiene ancora il bersaglio, l'interazione entra nella fase e spegne il giocatore, uscendo dalla fase il controllo torna e la fase è liberata.
- La guardia `_phase_can_run()` distingue davvero: `&"truth" in p` è vero sulla fase polare, e una proprietà inventata dà falso.

**Da guardare a schermo, perché non si decide leggendo:** le misure della stanza, la scocca nuova del monitor (più alta di 14 cm) e l'arredo aggiunto sono verificati per aritmetica e per sonda, non per occhio. È esattamente il genere di cosa che i documenti di questo progetto dicono di verificare guardando.

---

## Dev Notes

### La regola numero uno, in questa storia

Nella 1.1 era ADR-001. Qui è il **confine di `world/`**, e si verifica con due `grep` che
l'AC scrive esplicitamente.

```gdscript
# SÌ — il monitor si annuncia, e non sa chi ascolta
Events.screen_registered.emit(self)     # in crt/crt_screen.gd, già scritto

# NO — world/ che conosce le fasi
const PhasePolar = preload("res://phases/polar/phase_polar.tscn")
```

`world/` può dipendere **solo** da `core/` e `crt/`. Gli autoload (`Game`, `Events`, `Log`,
`Tuning`) sono fuori tabella e usabili da chiunque: sono il modo in cui `world/` parla senza
importare.

### Cosa esiste già e non va riscritto

| File | Cosa contiene | Come si usa qui |
|---|---|---|
| `crt/crt_screen.tscn` | `CrtScreen`: `SubViewport` 256×192, `QuadMesh` 0,32×0,24 m con shader di curvatura/scanline/aberrazione, `Marker3D` `Seat` a `(0, 0.09, 0.44)` con ~11,5° di beccheggio | **istanziare** dentro `crt_monitor.tscn` |
| `crt/crt_screen.gd` | `show_control()`, `viewport_size()`, e **l'emissione di `screen_registered`** | non toccare |
| `crt/desk_camera.gd` | la transizione alla postazione, 0,5 s, FOV 42° | **non toccare: è della 1.3.** Ma la sua API vincola il player di questa storia |
| `world/shaders/ps1.gdshader` | vertex snapping + vertex lighting, `snap_resolution` e `albedo` | applicare a ogni mesh della stanza |
| `autoloads/events.gd` | `screen_registered(screen: Node)` già dichiarato | usare, non modificare |
| `debug/render_tuning.gd` | `Shift+F1/F2/F3/F5/F6/F7` | **acquista un bersaglio per la prima volta** con questa storia |
| `main.tscn` | `WorldViewport(stretch_shrink=2) → SubViewport → ScreenHost(256×192) → PhaseHost` | ci si appende l'osservatorio, senza smontare il ponte |

### `world/` oggi contiene solo lo shader

Verificato sul repo, non assunto: `world/` ha **soltanto** `shaders/ps1.gdshader`. Tutto
ciò che la storia nomina — `player/`, `rooms/`, `interactables/`, `observatory.tscn` — non
esiste e va creato.

Nota: l'albero delle cartelle in `game-architecture.md` **non elenca `world/shaders/`**, e
il comando di setup crea `world/{player,rooms,interactables}` senza `shaders`. Lo shader
c'è comunque ed è citato come autoritativo da NFR3. **L'albero dell'architettura è stale su
questo punto**, e più in generale i nomi che propone vanno presi come indicazione: il
rilievo m1 del readiness report documenta altre due derive fra albero e repo reale. Fanno
eccezione i nomi che gli AC citano testualmente — `world/rooms/`, `world/interactables/` —
che sono normativi.

### Le misure che questa storia fissa per tutto il gioco

Il `Seat` è già posizionato e nessuno può spostarlo senza rompere la 1.3. Ne discende una
catena: **centro dello schermo = altezza occhi da seduto − 9 cm**, e lo schermo poggia sulla
scrivania. Scegliere l'altezza della scrivania significa scegliere l'altezza occhi del
giocatore, e quella scelta non è più reversibile a costo zero dopo la 1.3.

Non c'è una fonte da consultare: nessun documento fissa altezze, dimensioni della stanza,
velocità di camminata o altezza del soffitto. **Sono decisioni di questa storia.** Vanno
prese guardando il risultato a schermo — è il metodo con cui sono stati scelti tutti i
valori PS1 validati — e scritte in un commento dove vivono.

### Fuori scopo, dichiarato

**Della storia 1.3, non toccare:** la transizione alla postazione seduta (`desk_camera.gd`
esiste già ed è suo), `crt.show_control(...)`, il routing dell'input al `SubViewport`, la
leggibilità del testo tecnico da seduti.

**Dell'epica 2:** orchestratore `night/`, `NightClock`, `NightPlan`, alba, menu post-foto,
`save_manager.gd`, persistenza. **Non «sistemare» `game.gd` cogliendo l'occasione.** I tasti
`F1`-`F4` sono riservati al controllo del tempo (FR35): non occuparli **nemmeno per poco**.

**Dell'epica 3:** cucina e cupola (3.1), terminale gestionale (3.2), moka (3.3), lampada
(3.4), cupola che insegue (3.5), telemetria (3.6). `world/interactables/coffee_maker.tscn`
compare nell'albero dell'architettura, ma **la moka non è di questa storia**.
`Events.wait_activity_started`/`_ended` esistono già, ma camminare **non è** un'attività
dell'attesa: non emetterli.

**Fuori dall'MVP per costruzione:** le altre sette fasi, le rotture e le anomalie — il seam
esiste, le bugie no — storia, metanarrazione, rete di osservatori, esplorazione esterna,
calibrazione economica.

### Se lo schermo diventa nero premendo ENTER, non è un bug tuo

`deferred-work.md` lo registra: «Dopo ENTER il ponte finisce nel vuoto: schermo nero,
nessun riscontro, il `reason` non lo vede nessuno. *Rinviato: limite dichiarato del ponte
temporaneo, coperto dalla quarta clausola di AC6 della 1.1, si chiude con la storia 1.3.*»

### Project Structure Notes

Struttura che questa storia crea, allineata all'albero dell'architettura salvo le note sopra:

```
world/
├── observatory.tscn          ← NUOVO (rilievo m3: non era di nessuna storia)
├── player/
│   ├── player.tscn           ← NUOVO
│   └── player.gd             ← NUOVO
├── rooms/
│   └── computer_room.tscn    ← NUOVO   (kitchen e dome sono della 3.1)
├── interactables/
│   ├── interactable.gd       ← NUOVO   il contratto
│   ├── crt_monitor.tscn      ← NUOVO
│   └── crt_monitor.gd        ← NUOVO
└── shaders/
    └── ps1.gdshader          ← esiste

main.tscn                     ← MODIFICATO: l'osservatorio dentro %SubViewport
main.gd                       ← MODIFICATO: scambio fase/giocatore, commento aggiornato
project.godot                 ← MODIFICATO: cinque azioni nuove nell'InputMap
```

Convenzioni: file e cartelle `snake_case`, `class_name` in `PascalCase`, costanti
`UPPER_SNAKE_CASE`, membri privati con `_`, la scena con **lo stesso nome dello script**.
Co-locare `.tscn`, `.gd` e `.tres` della stessa unità.

### Project Context Rules

Da `_bmad-output/project-context.md`, le regole che mordono in questa storia:

- **Godot 4.7.2 stable, renderer Compatibility.** GDScript con tipizzazione statica ovunque
  possibile. **Nessun codice di networking, mai.**
- **Compatibility non supporta:** `CompositorEffect`, compute shader, `RenderingDevice`,
  SSR/SSIL/SDFGI/VoxelGI, fog volumetrica, depth of field, decal, tutti gli AA
  post-process. **Non cercare workaround: quasi nulla di questo serve.** La nebbia che
  chiude le distanze è quella dell'`Environment`, ed è supportata.
- **L'istinto di «migliorare la resa» è l'errore più frequente su questo progetto.**
- **`@onready` si risolve dopo `_ready` dei figli.** Non usarlo per valori che servono in
  `_enter_tree`.
- **Mai liberare un nodo dentro la sua stessa callback.**
- **Il `name` di un nodo non è un'identità.**
- **`assert()` sparisce nelle build di release.** Per i contratti, mai per logica con
  effetti collaterali.
- **Signal** dichiarati e tipizzati, `snake_case` **al passato**: un signal racconta ciò che
  è successo, non ordina.
- **I due canali.** `push_error()`/`assert()` per gli errori di programma — con il prefisso
  `[sistema]`, come `push_error("[crt] ScreenMesh senza ShaderMaterial")`. Gli esiti
  diegetici non passano **mai** da `push_error`. Al giocatore non si mostrano mai stack
  trace, codici di errore Godot o modali bloccanti: è un gioco cozy.
  *Nota: il canale 2 è definito solo come `PhaseResult` restituito da una fase. Un oggetto
  del mondo che non si può usare non ha un canale definito — questa storia lo incontra solo
  se costruisce un interagibile diverso dal monitor.*
- **Performance:** il costo reale sono i `SubViewport`, un render pass ciascuno.
- **Tono creepy-cozy, mai horror.** Nessun jump scare, nessuna minaccia, non si muore.

### Previous Story Intelligence — cosa ha lasciato la 1.1

La storia 1.1 è `done` dal 2026-08-22, dopo una code review a tre layer che ha prodotto 30
correzioni. Quello che serve sapere qui:

- **`git` esiste da adesso.** `baseline_commit: 624b202`. La prova dell'AC2 della 1.1 è
  `git diff -- phases/polar/phase_polar.gd`, ed è rieseguibile: **quel file non deve
  cambiare.**
- **`Phase` libera il proprio `Control` su `NOTIFICATION_PREDELETE`, non su `_exit_tree()`.**
  La prima stesura usava `_exit_tree()`, che scatta anche su un'uscita **temporanea**
  dall'albero e uccideva l'interfaccia di una fase ancora viva. Se questa storia parcheggia
  o sposta nodi fra host, è la lezione da non ridimenticare.
- **Le `Resource` sono condivise per riferimento**, e `.duplicate(true)` non è opzionale.
- **`Object.set()` su una proprietà inesistente è un no-op silenzioso.** L'iniettore lo
  verifica esplicitamente da quando la review l'ha scoperto.
- **Un `SubViewportContainer` con `stretch = true` sovrascrive sempre la misura del proprio
  `SubViewport`.** Un `size` dichiarato nella scena è un numero morto — è la ragione per cui
  `main.tscn` non ne ha più uno.
- **`device:16` nell'`InputMap` è corretto**: su Godot 4.7 è il device di default di un
  `InputEventKey`. Su 4.6.x nessun tasto risponderebbe, senza un errore. Il pin di versione
  è in `.godot-version`.
- **Il metodo che ha funzionato:** valori scelti guardando lo schermo, non stimati; commenti
  che spiegano *perché* e non *cosa*; e — lezione della review — **un commento che promette
  più di quanto il codice mantenga è debito che scade in silenzio**. Se scrivi «non entra
  nessun altro termine», che sia vero.

### Git Intelligence

```
624b202  Allinea documenti e commenti a NOTIFICATION_PREDELETE
85c7301  Storia 1.1 chiusa: review completata, status done
92cc9c2  Baseline: storia 1.1 dopo la code review
```

Il repository è nato con la 1.1 e ha tre commit. `.gitignore` esclude `.godot/`,
l'eseguibile del motore e l'export. **Nota pratica:** git avvisa a ogni commit che
convertirà LF in CRLF; un `.gitattributes` con `* text=auto eol=lf` chiuderebbe il rumore,
ma nessuno l'ha ancora deciso.

### Latest Tech Information

- **Godot 4.7.2 stable**, pinned in `.godot-version`. Il binario è nella cartella del
  progetto ed è escluso dal versionamento.
- **`CharacterBody3D`** è l'unico nodo di fisica previsto dall'architettura: «serve
  pochissimo: si cammina, non si combatte».
- **`Input.get_vector`** su azioni dichiarate è la forma idiomatica per il movimento su due
  assi, come `Input.get_axis` lo è per una vite tenuta premuta.
- **`RayCast3D`** con `collision_mask` dedicata è la forma standard per il rilevamento
  dell'interagibile in prima persona; l'alternativa `Area3D` di prossimità non distingue
  «guardo» da «sono vicino», e l'AC dice «guarda un oggetto interagibile da vicino».
- **`set_anchors_and_offsets_preset`** e non `set_anchors_preset` quando si vuole davvero
  riempire un rettangolo: il default `keep_offsets = true` preserva il rect esistente. È in
  `deferred-work.md` come fragilità latente della 1.3 — non peggiorarla.

### References

- [epics.md § Story 1.2](../planning-artifacts/epics.md) — i 4 AC, verbatim
- [epics.md § Epic 1](../planning-artifacts/epics.md) — obiettivo e domanda dell'epica
- [epics.md § Requirements Inventory](../planning-artifacts/epics.md) — FR23 (parziale), FR24 · UX-DR9 · NFR1, NFR3, NFR4, NFR8, NFR10, NFR11, NFR15, NFR20, NFR21, NFR22
- [epics.md § Churn sui file](../planning-artifacts/epics.md) — perché la stanza sta nell'epica 1
- [epics.md § Cosa esiste già ed è keeper](../planning-artifacts/epics.md) — `world/` contiene solo lo shader
- [game-architecture.md § Architectural Boundaries](../game-architecture.md) — la tabella delle dipendenze e lo snippet di `screen_registered`
- [game-architecture.md § ADR-003](../game-architecture.md) — la camera è la testa, la sequenza della postazione
- [game-architecture.md § Project Structure](../game-architecture.md) — l'albero di `world/`
- [game-architecture.md § Communication](../game-architecture.md) — «interazione → oggetto interagibile» è signal diretto
- [game-architecture.md § Consistency Rules](../game-architecture.md) — le 10 regole verificabili
- [project-context.md](../project-context.md) — regole critiche, anti-pattern, valori PS1 validati
- [implementation-readiness-report-2026-08-21.md § M5](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — doppia registrazione dello schermo, **assegnata a questa storia**
- [implementation-readiness-report-2026-08-21.md § M4](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — `UPDATE_ALWAYS` in `crt_screen.tscn`, da non aprire qui
- [implementation-readiness-report-2026-08-21.md § m3](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — `observatory.tscn` non è di nessuna storia
- [implementation-readiness-report-2026-08-21.md § m1](../planning-artifacts/implementation-readiness-report-2026-08-21.md) — deriva fra albero e repo
- [deferred-work.md](deferred-work.md) — `_collect_materials`, `set_anchors_preset`, il ponte che finisce nel vuoto
- [1-1-lallineamento-polare-e-la-prova-che-il-seam-regge.md](1-1-lallineamento-polare-e-la-prova-che-il-seam-regge.md) — la storia precedente e i suoi 30 rilievi di review
- [idea.md §3.1](../../docs/idea/idea.md) — la stanza computer: cosa c'è dentro
- [idea.md §12](../../docs/idea/idea.md) — il freddo si vede, il buio ha texture; lo stile PS1 e perché
- [idea.md §14](../../docs/idea/idea.md) — kit-bashing modulare
- [riassunto-creativo.md](../../docs/idea/riassunto-creativo.md) — Montegrimano 1999, chill creepy
- [brief.md § Content](../planning-artifacts/briefs/brief-astrochills-gd-3d-2026-08-21/brief.md) — l'edificio a L, il volume di asset che una persona sola può finire
- `docs/idea/osservatorio/oss_2_2.png` — la pianta con la «Stanza del computer»
- Repository, letto il 2026-08-22: `main.gd`, `main.tscn`, `project.godot`, `crt/*`, `world/shaders/ps1.gdshader`, `autoloads/events.gd`, `debug/render_tuning.gd`

---

## Domande aperte

Non bloccano l'inizio del lavoro. Vanno risolte **dentro** la storia, e il dev le porta a
Federico quando ci arriva.

1. **Lo scambio fase ↔ giocatore è il ponte giusto per la 1.2?** Il Task 0 lo assume perché
   è l'unico modo di avere stanza e fase nello stesso progetto senza che WASD comandi
   entrambe, e perché spegnere il controller è il primo passo di ADR-003, quindi non è
   lavoro buttato. L'alternativa — non entrare più nella fase all'avvio — renderebbe la fase
   polare irraggiungibile fino alla 1.3, cioè una regressione di giocabilità dentro
   un'epica il cui scopo è restare giocabile a ogni storia.

2. **Le misure del giocatore e della stanza.** Nessun documento le fissa e la catena del
   `Seat` le vincola l'una all'altra. Le proposte del Task 1 sono un punto di partenza
   ragionevole, non una decisione presa: vanno guardate a schermo. **È la scelta di questa
   storia che meno si può disfare**, perché la 1.3 ci si aggancia.

3. **Il tasto dell'interazione, e la lingua del prompt.** `E` è libero ed era il tasto dello
   spike; l'italiano discende da NFR10 applicato a una superficie che legge il giocatore.
   Nessuno dei due è scritto in un documento: sono precedenti che questa storia crea per
   moka, lampada e cupola.

4. **La forma del contratto `interactable.gd`.** L'architettura ne fissa solo il nome del
   file. Classe base, metodi, signal, e come il player scopre l'oggetto sono tutti da
   decidere qui, e vincolano l'epica 3.

5. **`world/observatory.tscn` serve davvero adesso?** Con una stanza sola è sovrastruttura,
   e il rilievo m3 nota che non è di nessuna storia. Crearlo ora dà alla 3.1 un posto dove
   appendere cucina e cupola; non crearlo significa che la 3.1 dovrà anche riorganizzare.

---

## Dev Agent Record

### Agent Model Used

claude-opus-5 (Claude Code)

### Debug Log References

**I `class_name` nuovi non esistono finché il progetto non viene importato.** Le classi
globali vivono in `.godot/global_script_class_cache.cfg`, che si costruisce all'import: dopo
aver scritto `Player`, `Interactable`, `InteractionPrompt` e `CrtMonitor`, il gioco falliva
con `Parse Error: Identifier "CrtMonitor" not declared in the current scope`. Si chiude con
un `--headless --path . --import` prima di eseguire. Chi lavora dall'editor non lo incontra
mai; chi lavora da riga di comando lo incontra sempre.

**`albedo` scritto `null` nel `.tscn`.** `ps1.gdshader` dichiara
`uniform vec3 albedo : source_color`, e con il hint `source_color` Godot vuole un `Color`,
non un `Vector3`. Passando un `Vector3` il parametro finisce a `null` nel file salvato
**senza un errore né un warning**: la stanza sarebbe stata costruita con tutte le superfici
del colore di default dello shader, e sarebbe sembrata una scelta estetica.

**Falso allarme da `--check-only --script`.** Verificando `crt/crt_screen.gd` in isolamento
sono comparsi errori di compilazione. Non erano reali: quel controllo non registra gli
autoload, quindi ogni script che nomina `Events`, `Log`, `Game` o `Tuning` fallisce —
`main.gd`, che gira senza problemi, ne produce quattro. Non è uno strumento utilizzabile su
questo progetto.

**La sonda dell'interazione sbagliava, non il codice.** Con due frame di fisica il raggio
risultava non collidente; strumentando la sonda si vedeva `is_colliding() = true` e il
collider giusto. Serve qualche frame perché `RayCast3D` rifletta una trasformata cambiata a
mano: con otto, verde.

### Completion Notes List

**La collisione WASD era il cuore della storia, e si è risolta senza toccare la fase.**
`project.godot` legava già W/A/S/D alle due viti polari e ENTER alla chiusura della fase.
Rinominare quelle azioni avrebbe richiesto di modificare `phases/polar/phase_polar.gd`, cioè
di distruggere la prova dell'AC2 della storia 1.1 per una ragione di comodo. Le azioni nuove
stanno quindi **sulle stesse lettere**, e a comandare è chi ascolta: `main.gd` accende il
giocatore o la fase, mai tutti e due. Si entra nella fase interagendo col monitor, e il
controller si spegne — che è il primo passo della sequenza di ADR-003, quindi lavoro che la
1.3 estende invece di buttare.

**Rilievo M5 chiuso.** `Events.screen_registered` lo emette `CrtScreen`, che lo faceva già;
`crt_monitor.gd` non lo emette. Verificato dal vivo: **una emissione sola**. La storia
chiedeva che il monitor «emetta entrando in scena», e lo fa — attraverso il proprio schermo,
che è il pezzo che sa di essere pronto.

**Il monitor si trova per gruppo**, `&"crt_monitor"`, mai per percorso di nodo. Un gruppo
sopravvive a spostamenti e rinomine, che è ciò che l'AC3 chiede davvero.

**Ogni pezzo della stanza usa `material_override`** — 14 mesh, 14 `material_override` — e
nessuno usa `surface_material_override/0`: in tutto `world/` quella forma compare solo
dentro un commento, che spiega perché non va usata.
Così `Shift+F5`/`F6`/`F7` di `debug/render_tuning.gd` ha finalmente un bersaglio, e la voce
di `deferred-work.md` che aspettava questa storia è stata aggiornata.

> **Corretto dalla code review del 2026-08-22.** Qui c'era scritto «i 9 pezzi della stanza
> […] verificato contando: 9 su 9», e il numero era sbagliato già quando è stato scritto:
> le `MeshInstance3D` erano 10, perché la porta chiusa nella stessa sessione non era stata
> ricontata. Dopo la review sono 14 — si sono aggiunti PC, modem e i due pezzi della sedia —
> e `_collect_materials()` ne conta 15 con la scocca del monitor. Il conteggio nel log è per
> mesh e non per materiale distinto, ed è ora documentato in `render_tuning.gd`: la stanza
> condivide un solo `MatWall` fra sei pareti.

**Le misure scelte, e la catena che le lega.** Altezza occhi 1,65 m · piano della scrivania
0,75 m · centro dello schermo CRT 1,10 m · `Seat` che ne risulta a 1,19 m, che è un'altezza
occhi da seduto plausibile. La catena parte dal `Marker3D` `Seat` di `crt_screen.tscn`, che
nessuno può spostare senza rompere la 1.3.

**Da guardare sul gioco vero, perché non si decide leggendo.** In piedi, con gli occhi a
1,65 m e il monitor che arriva a 1,11 m, per far comparire il prompt bisogna guardare **in
basso di circa 60°**. È realistico e funziona, ma è ripido: se all'occhio risulta scomodo, i
candidati sono la portata dell'interazione (oggi 1,2 m), l'altezza della scrivania, o un
collisore del monitor più generoso della sua scocca. È esattamente il genere di cosa che i
documenti dicono di verificare guardando e non stimando.

**Trovato e chiuso durante la verifica: oltre la porta si cadeva nel vuoto.** Il vano
c'era, ma il pavimento finisce 7 cm dopo la soglia e il giocatore precipitava senza fondo. Il
corridoio è fuori scopo — arriva con la 3.1 — quindi la porta è stata **chiusa**: un pannello
pieno nel vano, che è anche la lettura diegetica giusta. Si aprirà quando ci sarà qualcosa
dietro. Verificato spingendo il giocatore contro la porta per 40 frame: si ferma e resta a
terra.

**Il ciclo della stanza è stato provato dal vivo**, non dedotto: il raggio trova il monitor,
il prompt legge «Usa il monitor», premere interagisce, la fase entra e il giocatore si
spegne. Uscendo dalla fase il controllo torna al giocatore.

**Le cinque domande aperte della storia si chiudono così:**

1. **Ponte fase ↔ giocatore** → implementato come proposto, con lo scambio in `main.gd`.
2. **Misure** → scelte quelle sopra. Restano da confermare a occhio.
3. **Tasto e lingua del prompt** → `E`, e italiano. Il tasto lo scrive
   `interaction_prompt.gd`, non i singoli oggetti: cambiarlo è cambiare una riga.
4. **Forma del contratto** → `Interactable extends StaticBody3D`, rilevamento con
   `RayCast3D` dalla camera su un layer dedicato, `interacted(by)` come **signal diretto**
   e non su `Events`, `can_interact()` che le sottoclassi possono stringere e mai allentare.
   `interact()` non va sovrascritta: ci si collega al signal, così un oggetto può avere più
   ascoltatori senza che nessuno debba ricordarsi di chiamare `super()`.
5. **`world/observatory.tscn`** → creato. Con una stanza sola sembra sovrastruttura; con
   cucina e cupola della 3.1 non lo sarà.

**Fuori scopo, rispettato.** Nessuna transizione seduta (`desk_camera.gd` non è stato
toccato), nessun `crt.show_control`, nessun orchestratore, nessuna cucina, nessuna cupola,
nessuna moka, nessuna stanza segreta. `crt/crt_screen.tscn` con `UPDATE_ALWAYS` (rilievo M4)
**non è stato aperto**, come il rendiconto della 1.1 chiedeva — ma da adesso quel render
pass è un costo reale, perché il CRT è dentro il mondo.

### Change Log

| Data | Cosa |
|---|---|
| 2026-08-22 | **Code review a tre layer, 33 rilievi: 7 decisioni prese, 18 patch applicate, 6 rinviate, 2 scartate.** Le tre cose che pesavano: la mutua esclusione WASD aveva un buco — `set_enabled(false)` spegne il lettore del giocatore, non lo stato fisico dei tasti, e chi entrava nella fase tenendo `W` si trovava la vite che girava da sola; **adesso ogni scambio rilascia le azioni**, e la fase esce dall'albero prima che il controllo torni. Il vetro del CRT sporgeva 11 cm sopra la scocca e la metà superiore dello schermo non era mirabile: **la scocca è stata allargata a 0,42 × 0,50 × 0,38**, il centro dello schermo resta a 1,10 m e la catena delle misure sopravvive. La catena non chiudeva per la 1.3 — `desk_camera` porterà l'origine del corpo a −0,46 m — ed è corretto che lo faccia, ma solo perché **da spento il controller non simula più fisica**. Aggiunti PC, modem 56k e sedia (senza collisione: sta dove la 1.3 farà sedere il giocatore). Materiali e mesh condivisi, come `idea.md §14` chiede. Layer di collisione nominati in `project.godot`. Guardia `_phase_can_run()`: una fase mal configurata non riceve più il controllo, che in release sarebbe stato un blocco senza ritorno. Gioco e banco di collaudo a zero errori e zero warning; ciclo della stanza riprovato dal vivo. |
| 2026-08-22 | Storia implementata per intero. Stanza computer, giocatore in prima persona con imbardata sul corpo e beccheggio sulla camera, contratto di interazione con prompt diegetico a un tasto, monitor CRT come oggetto del mondo, osservatorio innestato nel `SubViewport` a bassa risoluzione. **La collisione WASD fra movimento e viti della fase polare — che nessun documento di pianificazione aveva notato — è stata risolta senza toccare `phase_polar.gd`:** azioni nuove sulle stesse lettere, e fase e giocatore mutuamente esclusivi con lo scambio in `main.gd`. **Rilievo M5 chiuso:** `screen_registered` lo emette solo `CrtScreen`, verificato con una emissione sola. Tutti e 9 i pezzi della stanza usano `material_override`, quindi i comandi di taratura PS1 hanno per la prima volta un bersaglio. Gioco e banco di collaudo a zero errori e zero warning. |

### File List

**Nuovi**

- `world/observatory.tscn`
- `world/player/player.gd`
- `world/player/player.tscn`
- `world/rooms/computer_room.tscn`
- `world/interactables/interactable.gd`
- `world/interactables/interaction_prompt.gd`
- `world/interactables/interaction_prompt.tscn`
- `world/interactables/crt_monitor.gd`
- `world/interactables/crt_monitor.tscn`

I `.uid` corrispondenti agli script sono generati da Godot all'import e vanno versionati con
loro.

**Modificati**

- `main.gd` — il ponte: monitor trovato per gruppo, scambio fase ↔ giocatore, intestazione
  aggiornata perché la stanza adesso esiste
- `main.tscn` — `Observatory` istanziato dentro `%SubViewport`; `ScreenHost` parte nascosto
- `project.godot` — sei azioni nuove nell'`InputMap`: `move_forward`, `move_back`,
  `move_left`, `move_right`, `interact`, `ui_release_mouse`
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — stato della storia
- `_bmad-output/implementation-artifacts/deferred-work.md` — le voci rinviate di questa
  storia, e l'aggiornamento della voce su `_collect_materials` che la 1.2 sblocca
- `_bmad-output/implementation-artifacts/1-2-losservatorio-esiste-e-ci-sei-dentro.md`

**Modificati dalla code review del 2026-08-22**

- `world/interactables/interactable.gd` — layer nominati (`LAYER_WORLD`, `LAYER_PLAYER`,
  `LAYER_INTERACTABLE`) e assegnati in `_enter_tree()` in OR: niente `super()` obbligatorio,
  niente valori di scena cancellati
- `world/interactables/crt_monitor.gd` — `find_in()`, il ripiego per chi si è perso
  `Events.screen_registered`; niente `super()` in `_ready()`
- `world/interactables/crt_monitor.tscn` — scocca 0,42 × 0,50 × 0,38 che avvolge davvero il
  vetro, collider che copre tutto lo schermo
- `world/interactables/interaction_prompt.gd` — il commento non rivendica più una
  diegeticità che il codice non ha
- `world/player/player.gd` — misure come sorgente di verità, memoria del cursore libero,
  fisica ferma da spento, `force_raycast_update()`, mira riconfermata alla pressione,
  occlusori nel raggio, gruppo `player`
- `world/player/player.tscn` — le misure non sono più duplicate nella scena
- `world/rooms/computer_room.tscn` — materiali e mesh condivisi, PC, modem e sedia
- `world/observatory.tscn` — monitor a z = −2,05 perché il `Seat` esca dal volume della
  scrivania; la catena delle misure scritta dove qualcuno la cercherà
- `main.gd` — guardia `_phase_can_run()`, `_dispose()`, rilascio delle azioni allo scambio,
  stato iniziale dichiarato, giocatore per gruppo
- `project.godot` — `layer_names/3d_physics`: «mondo», «giocatore», «interagibili»
- `debug/render_tuning.gd` — i due commenti che dicevano che la stanza non esiste

**Temporanei, creati e rimossi nella stessa sessione**

- `_probe.gd` / `_probe.tscn` — sonda del ciclo della stanza dopo la code review: raggio,
  prompt, ingresso e uscita dalla fase, e la guardia `_phase_can_run()`
- `_input_setup.gd` — generatore delle azioni `InputMap`, stesso metodo della 1.1
- `_build_room.gd` — costruttore di `computer_room.tscn`: la stanza è fatta di pezzi
  ripetibili, e disporli da codice è il kit-bashing che `idea.md §14` chiede
- `_probe_interaction.gd` / `_probe_interaction.tscn` — sonda del ciclo di interazione
