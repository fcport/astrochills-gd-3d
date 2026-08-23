# Deferred work

Lavoro reale, rinviato con una ragione. Ogni voce dice da dove viene e cosa la sblocca.

## Deferred from: code review of 1-1-lallineamento-polare-e-la-prova-che-il-seam-regge (2026-08-22)

- **`phase_scores` con chiavi `StringName` non sopravvive a un round-trip JSON.** `Game.run.phase_scores[phase.key()]` usa `&"polar"`; in Godot 4 `dict[&"polar"]` e `dict["polar"]` sono due voci distinte. Una partita ricaricata da JSON avrebbe punteggi irraggiungibili tramite `phase.key()`, e un rigioco scriverebbe in silenzio una seconda voce parallela. *Rinviato: il sistema di save non esiste ancora — arriva con l'epica 2, ed è bloccato dalla decisione C1 (contenitore per lo stato che attraversa le notti).* [main.gd] **CHIUSA per il percorso `.tres` il 2026-08-23 dalla storia 2.7.** Il save NON usa JSON: `core/save_manager.gd` serializza con `ResourceSaver` su `.tres`, che preserva `&"..."` — la premessa della voce (round-trip JSON) non si applica. Il banco lo dimostra: `_check_save_manager()` salva `phase_scores = {&"polar": 80}` in una `NightRun`, la ricarica, e verifica che `run.phase_scores[&"polar"] == 80`. La voce vale solo se un giorno si introducesse JSON — che l'epica 2 non fa.

- **`_collect_materials` raccoglie solo `material_override`.** Salta i materiali per-superficie e `material_overlay`, e non deduplica: un `ShaderMaterial` condiviso fra N mesh viene scritto N volte e contato N volte, quindi il log `%d materiali` non permette di distinguere «non ho trovato niente» da «ho trovato la cosa sbagliata». *Sbloccato il 2026-08-22 dalla storia 1.2: la geometria 3D nel viewport adesso c'è, tutta su `material_override`, e i comandi di taratura hanno un bersaglio. Il salto dei materiali per-superficie NON è più un difetto: `crt/crt_screen.gd` usa `get_surface_override_material(0)` di proposito, perché il CRT non deve essere toccato dalla taratura del jitter del mondo. **Resta aperta la sola mancata deduplicazione**, che dalla 1.2 in poi è visibile davvero — la stanza condivide un materiale fra sei pareti — ma è innocua: scrivere N volte lo stesso parametro dà lo stesso risultato, e il conteggio nel log è ora documentato come «per mesh, non per materiale».* [debug/render_tuning.gd]

- **`_samples` salva il timestamp in float32 e lo confronta con un cutoff float64.** `Vector2` è `real_t` a 32 bit, `_elapsed` è un double GDScript: il timestamp memorizzato è una copia arrotondata del valore contro cui viene poi confrontato, quindi il confine di sfratto sbaglia fino a un ULP. `_elapsed` inoltre cresce senza limite e senza reset. *Rinviato: invisibile con la finestra di default da 8 s (±1 campione su ~480); degrada solo su sessioni molto lunghe.* [phases/polar/phase_polar.gd]

- **`set_anchors_preset(PRESET_FULL_RECT)` funziona per coincidenza.** Il default `keep_offsets = true` sposta solo le ancore e ricalcola gli offset per **preservare** il rect che il Control ha già: regge oggi soltanto perché `polar_screen._ready()` ha impostato `256×192` a (0,0), che combacia con il viewport. La chiamata che fa ciò che il commento intende è `set_anchors_and_offsets_preset`. *CHIUSA il 2026-08-22 dalla storia 1.3. La chiamata in `main.gd` non esiste più — quel mima temporaneo è stato sostituito da `crt.show_control()` — e quella in `crt/crt_screen.gd`, che è l'unica rimasta, adesso è `set_anchors_and_offsets_preset`. Il Control della fase polare arriva sul CRT a 256×192 perché il preset glielo impone, non perché le misure combaciano.* [crt/crt_screen.gd]

- **Dopo ENTER il ponte finisce nel vuoto.** `_advance()` svuota il viewport, libera la fase e si ferma: nessun riscontro che qualcosa si sia concluso, e il `reason` non lo legge nessuno. *(Correzione del 2026-08-22: questa voce diceva «schermo nero», e non lo è — il vetro torna al colore di pulizia del viewport, che attraverso lo shader è il grigio-verde di un CRT acceso senza segnale. Guardato in code review e giudicato migliore del nero, che fa sparire scanline e curvatura e trasforma il vetro in un buco nella scocca. Ma «nero» era una descrizione falsa di ciò che si vede, ed è così che nascono le sorprese.)* *Sbloccata a metà il 2026-08-22 dalla storia 1.3, e rinviata con un proprietario diverso. La SUPERFICIE adesso esiste: il `reason` è canale 2, lo legge il giocatore sul CRT, e fino a ieri non c'era un CRT su cui leggerlo. Manca CHI ci scriva dopo la fase, e non è questa storia: nessuno dei 5 AC lo chiede, `ui/` non esiste e la 1.3 dichiara di non creare cartelle nuove, e soprattutto lo schermo di esito lo disegnano davvero le storie 2.4 (lo stack), 2.5 (la vendita) e 2.6 (quanto rifare). Scriverne uno qui significherebbe fissare un precedente che tre storie rifarebbero — con quante domande aperte si vede subito: quanti secondi resta, con che tasto si salta, e cosa mostra quando il `reason` è vuoto. **Decisione presa consapevolmente da Federico il 2026-08-22**, non lasciata cadere.* [main.gd]

## Deferred from: verifica a schermo della storia 1.2 (2026-08-22)

- **La sensazione del movimento si tara giocando, non adesso.** `WALK_SPEED = 2.6`,
  `MOUSE_SENSITIVITY = 0.0022` e `ACCELERATION = 12.0` in `world/player/player.gd` sono
  valori di partenza plausibili, provati e giudicati accettabili da Federico il 2026-08-22
  aprendo il gioco. *Rinviato per decisione esplicita: «è fatica dire da così» — si
  correggono man mano che si gioca, quando ci sarà abbastanza stanza e abbastanza tempo di
  gioco per accorgersi di cosa non va. Non sono numeri da difendere in review: sono numeri
  in attesa di essere smentiti dall'uso.* [world/player/player.gd]

- **Uscire dalla fase la conclude, e rientrando l'allineamento riparte da capo.** Verificato
  da Federico a schermo il 2026-08-22. Nel ponte della 1.2 l'unica uscita dalla fase è
  `ENTER` = `polar_finish`, che per contratto **conclude** l'allineamento ed emette il
  punteggio; `main.gd` libera la fase, e la prossima interazione col monitor ne istanzia una
  nuova dal disallineamento iniziale. Non esiste un gesto per alzarsi senza finire.
  *Rinviato: è il contenuto della storia 1.3, il cui AC lo richiede alla lettera — «il
  giocatore si alza… la fase non viene interrotta e non viene liberata… al ritorno mostra lo
  stato vero, non uno stato ricostruito». Non si può anticipare a metà: tenere viva la fase
  mentre il giocatore cammina la lascerebbe in `_process`, dove `_turn_screws` legge WASD a
  ogni frame — cioè riaprirebbe la collisione che il Task 0 ha appena chiuso. Separare
  «seduto» da «finito» richiede la sequenza di ADR-003, che è precisamente la 1.3.*
  **CHIUSA il 2026-08-22 dalla storia 1.3.** `E` alza dalla postazione senza concludere
  niente: la fase resta nell'albero con il suo stato e viene SOSPESA
  (`process_mode = PROCESS_MODE_DISABLED` sulla fase **e** sul suo `Control`, che vive nel
  `SubViewport` del CRT e non eredita niente da lei). Al ritorno lo schermo mostra lo stato
  vero, perché non si è mai salvato né ricostruito niente. `ENTER` resta l'unico gesto che
  conclude. La collisione con WASD che rendeva impossibile anticiparlo è chiusa dalla stessa
  riga: fermare `_process` ferma `_turn_screws`.* [main.gd]

- **Le dimensioni della stanza computer restano indicative.** 4 × 5 m, soffitto 2,8.
  Verificate a schermo il 2026-08-22 e giudicate ragionevoli. *Rinviato: non è il momento di
  affinarle — la stanza è vuota, e la scala vera si giudica quando ci sarà dentro l'arredo
  che l'epica 3 porta (terminale, moka, lampada) e quando esisteranno le stanze accanto per
  fare da metro di paragone.* [world/rooms/computer_room.tscn]

## Deferred from: code review of 1-2-losservatorio-esiste-e-ci-sei-dentro (2026-08-22)

- **Un secondo `CrtMonitor` sarebbe inerte in silenzio.** `_connect_monitor()` usa
  `get_tree().get_first_node_in_group()` e collega un nodo solo, in `_ready`; il `push_error`
  scatta unicamente se il gruppo è vuoto. Un secondo CRT mostrerebbe comunque il prompt «[E]
  Usa il monitor» — il rilevamento non sa nulla del collegamento — e alla pressione di `E`
  `interact()` emetterebbe `interacted` senza che nessuno ascolti: un oggetto che promette
  un'azione e non la esegue, senza un errore da nessuna parte. *Rinviato: oggi il gruppo ha un
  membro solo, quindi non è raggiungibile nel gioco reale; morde quando l'epica 3 allarga
  l'osservatorio, ed è il meccanismo che questa storia stabilisce come precedente.* [main.gd]

- **Re-interagire col monitor riavvia la fase e sovrascrive il punteggio.** La guardia
  `_phase != null` copre il doppio ingresso, non il re-ingresso: completata la fase con un buon
  allineamento, il prompt ricompare al `_physics_process` successivo e un secondo `E` fa
  ripartire `PhasePolar` da capo. Un `ENTER` immediato produce punteggio 0 e
  `Game.run.phase_scores[&"polar"]` perde il risultato buono senza avviso. *Rinviato: il
  sistema di save non esiste ancora, e la voce sulle chiavi `StringName` di
  `phase_scores` è già in questo file dalla review della 1.1.* **Aggiornata il 2026-08-22
  dalla storia 1.3: il meccanismo è cambiato, il difetto no.** Con una fase VIVA il
  re-ingresso adesso fa risedere invece di non fare niente — è il flusso normale del gioco.
  Ma dopo `ENTER` la fase viene liberata, e da lì un secondo `E` istanzia una fase nuova dal
  disallineamento iniziale, esattamente come prima. Quello che manca è chi decida che la
  fase 3 di questa notte è già stata giocata, e quello è l'orchestratore dell'epica 2.
  **CHIUSA il 2026-08-23 dalla storia 2.1.** L'orchestratore esiste, ed è lui a decidere: le
  fasi arrivano da `data/night_plan.tres` e ogni indice avanza una volta sola, quindi finito
  il setup non c'è più niente da rigiocare. `main.gd::_on_monitor_interacted()` non istanzia
  più nulla — si limita a far sedere — e quando il piano si esaurisce `plan_exhausted` fa
  rialzare chi è alla postazione e `_refresh_monitor()` spegne l'interagibile: il prompt non
  ricompare nemmeno. Il difetto non è stato corretto, è stato tolto di mezzo per costruzione.
  [main.gd, night/night_session.gd]

- **`ESC` non consuma l'evento e coincide con `ui_cancel`.** `_unhandled_input` non chiama mai
  `get_viewport().set_input_as_handled()`, né per `interact` né per `ui_release_mouse`, e il
  `SubViewport` del mondo ha `handle_input_locally = false`, quindi lo stato «gestito» è
  condiviso col viewport padre. Quando arriverà la UI di pausa, un `ESC` libererà il cursore
  **e** aprirà la pausa nello stesso frame. *Rinviato: non esiste ancora nessuna UI di pausa —
  `ui/` è vuoto — quindi oggi non c'è collisione osservabile.* [world/player/player.gd]

- **Il tasto del prompt è scritto a mano e slegato dall'`InputMap`.** `_label.text = "[E]  %s"`
  ricopia il tasto invece di derivarlo da `InputMap.action_get_events(&"interact")`, mentre il
  commento sopra la funzione promette che «cambiarlo è cambiare una riga qui». Rebindare
  `interact` su `F` lascerebbe a schermo «[E] Usa il monitor». *Rinviato: non esiste rebinding
  dei comandi e non è previsto nell'MVP; la promessa del commento va però corretta o mantenuta
  quando il rebinding arriva.* [world/interactables/interaction_prompt.gd]

- **`.normalized()` annulla il `deadzone: 0.2` dichiarato sulle azioni di movimento.**
  `Input.get_vector` restituisce già un vettore con deadzone applicata e magnitudo analogica
  preservata; normalizzarlo di nuovo la butta via. Le sei azioni nuove dichiarano tutte
  `"deadzone": 0.2`, un valore che ha senso solo per un asse analogico: il giorno in cui a
  `move_forward` viene aggiunto un evento `JoyAxis`, la levetta a metà camminerà alla velocità
  piena. *Rinviato: nessun supporto gamepad oggi, e con la tastiera il comportamento è
  identico. O il deadzone è finto e va tolto, o `.normalized()` va sostituito con un clamp di
  lunghezza — la scelta si fa quando il gamepad esiste.* [world/player/player.gd]

- **Le scene sono state editate a mano e il formato non è quello che l'editor riscriverebbe.**
  In `computer_room.tscn` ogni nodo porta un `unique_id=` tranne i tre aggiunti in coda
  (`Door`, il suo `Mesh` e il suo `Collision`), e `observatory.tscn` dichiara `load_steps=6`
  per 3 `ext_resource` + 1 `sub_resource`. *Rinviato: nessuna conseguenza a runtime — Godot
  ignora `load_steps` in eccesso e rigenera gli `unique_id` al salvataggio — ma il primo
  salvataggio dall'editor riscriverà i file e il diff di quella sessione sarà rumore
  illeggibile. Vale la pena aprirle e risalvarle prima della prossima storia che le tocca.*
  [world/rooms/computer_room.tscn, world/observatory.tscn] **Vale anche per `project.godot`,
  scoperto il 2026-08-22 durante la 1.3: un `--headless --import` riordina le sezioni —
  `[rendering]` finisce dopo `[layer_names]` — senza cambiare un solo valore. Il diff che ne
  esce è rumore puro, ed è stato scartato con `git checkout` invece di essere committato.*

- **Il prompt di interazione è un HUD, non un elemento del mondo.** `InteractionPrompt`
  estende `CanvasLayer` e disegna una riga ancorata al fondo del viewport: condivide con la
  stanza la RESA — risoluzione, filtro, grana — non l'appartenenza alla finzione, mentre
  UX-DR9 e l'AC2 della 1.2 chiedono un prompt «diegetico». *Rinviato con decisione presa
  nella code review del 2026-08-22: a 640x360, con vertex snapping e filtro nearest, un
  testo montato nel mondo rischia di essere illeggibile alla distanza di interazione, e su
  questo progetto le cose di resa si decidono guardando. Con un interagibile solo non c'è
  niente da guardare: la verifica si fa nell'epica 3, con moka (3.3), lampada (3.4) e cupola
  (3.5) davanti. Il commento del file non rivendica più una diegeticità che il codice non
  ha.* [world/interactables/interaction_prompt.gd]

- **La geometria e i colori della stanza sono un segnaposto.** Kit-bashing di primitive e
  materiali a `albedo` piatto, senza una sola texture: `ps1.gdshader` espone solo il colore,
  e l'affine texture mapping — la deformazione delle texture che è metà dell'identità PS1 —
  non è implementato. *Rinviato per decisione di Federico il 2026-08-22: «probabilmente
  comprerò un qualche pack di texture o lo faccio». Finché il pack non c'è, rifinire
  proporzioni e colori di oggetti destinati a essere sostituiti è lavoro buttato. Quando
  arriverà, lo shader va esteso e questa voce si chiude insieme a quella dell'affine texture
  mapping. Va corretto solo ciò che ha conseguenze funzionali — un collider che non copre il
  suo oggetto, una misura che ne vincola un'altra — non ciò che riguarda l'aspetto.*
  [world/shaders/ps1.gdshader, world/rooms/computer_room.tscn]

## Deferred from: storia 1.3 — sedersi al monitor e lavorare sullo schermo (2026-08-22)

- **Il gesto per alzarsi non è scritto da nessuna parte.** Ci si alza con `E`, lo stesso
  tasto con cui ci si siede, e la simmetria è l'unica cosa che lo insegna: da seduti il
  prompt «[E] Usa il monitor» non c'è — il controller del giocatore è spento e il prompt
  segue lui — quindi lo schermo non lo annuncia e nemmeno l'HUD. *Rinviato con una ragione
  precisa: l'unico posto dove scriverlo oggi sarebbe il footer di
  `phases/polar/polar_screen.gd`, cioè la VISTA DI UNA FASE, e la ragione per cui lo si
  scriverebbe è di ORCHESTRAZIONE — la postazione, non l'allineamento. Una fase non deve
  spiegare i comandi di chi la ospita: il giorno in cui le fasi saranno otto, quella riga
  andrebbe copiata in otto viste. Si chiude quando esiste un posto che appartiene alla
  postazione e non alla fase — un prompt diegetico da seduti, o una riga che il CRT
  sovrappone e che le fasi non conoscono.* [main.gd, phases/polar/polar_screen.gd]

- **Da seduti il cursore del mouse resta visibile.** `Player.set_enabled(false)` rimette
  `Input.mouse_mode = MOUSE_MODE_VISIBLE`, ed è una decisione deliberata della 1.2 — chi non
  gira più la testa non deve restare col cursore prigioniero. Alla postazione però il
  risultato è un cursore di sistema che galleggia sopra una scena in cui il giocatore è
  seduto davanti a un monitor del 1999. *Rinviato: oggi non c'è niente da cliccare — il
  mouse non entra nemmeno nel `SubViewport` del CRT, perché le sue coordinate non sono
  mappate sul vetro finché non arriva il raycast di ADR-003 — quindi il cursore è solo
  brutto, non ambiguo. Si decide insieme al raycast: o il mouse serve sul CRT e allora va
  mappato, o non serve e allora da seduti va ricatturato.* [world/player/player.gd]

- **`Events.screen_registered` non ha ascoltatori, e chi nasce con la scena non può averne.**
  `CrtScreen` lo emette nel proprio `_ready()`, e l'albero si costruisce profondità-prima:
  quando il mondo è istanziato dentro `main.tscn` l'emissione avviene prima di
  `Main._ready()`, quindi chiunque nasca lì dentro si collega a segnale già passato. Per
  questo `main.gd` cerca per gruppo. *Corretto il 2026-08-22 in code review: la prima
  stesura di questa voce diceva «non può averne» senza condizioni, ed era falso — un
  autoload entra nell'albero PRIMA della scena principale e riceverebbe l'emissione senza
  problemi, come la riceverebbe qualunque nodo istanziato più tardi. La distinzione conta,
  perché è precisamente ciò che deciderà se il segnale vada rimosso o gli vada dato il
  destinatario che gli manca.* *Rinviato: il segnale è dichiarato in
  `game-architecture.md § Architectural Boundaries`, quindi toglierlo è una decisione di
  architettura e non di storia. Finché resta senza ascoltatori è codice che promette un
  canale che nessuno usa.* **CHIUSA come domanda il 2026-08-23 dalla storia 2.1**, che è la
  storia per cui il segnale era stato pensato: `night/night_session.gd` dichiara in
  intestazione perché NON lo usa — nasce dentro la scena principale e l'emissione gli è già
  passata sopra — e riceve il `CrtScreen` da `configure()`, che è il punto d'ingresso a
  passarglielo. La strada è decisa e scritta dove la cercherà chi verrà dopo. *Resta aperta la
  sola domanda di architettura: il segnale continua a non avere ascoltatori, e toglierlo o
  dargli un destinatario è una decisione di `game-architecture.md`, non di una storia.*
  [crt/crt_screen.gd, autoloads/events.gd]

## Deferred from: code review of 1-3-sedersi-al-monitor-e-lavorare-sullo-schermo (2026-08-22)

- **`_busy` incastrato lascerebbe il gioco sordo per sempre.** `main.gd::_input()` ingoia ogni
  evento finché `DeskCamera.is_busy()`, e `_busy` torna `false` solo dopo `await t.finished`. Un
  `Tween` che non emette `finished` — bersaglio liberato, `DeskCamera` tolta dall'albero,
  `Tween.kill()` — renderebbe il gioco sordo a ogni input per il resto della sessione: nessun
  timeout, nessuna via di rientro, nemmeno `ESC`. *Rinviato: oggi non raggiungibile, perché
  nessuno libera il `Player` né smonta la `DeskCamera`, e la guardia `is_inside_tree()` di
  `toggle()` copre l'unico modo di rompere il tween che il progetto sa produrre. Si richiude se
  qualcuno introduce un percorso che libera il corpo o la camera a partita in corso — o si
  chiude subito dando allo swallow una condizione di uscita che non dipenda solo dal tween.*
  [main.gd]

- **`_release_all_actions()` gira prima di un `set_enabled()` che può uscire subito.**
  `_set_world_active(true)` rilascia tutte le azioni e poi chiama `player.set_enabled(true)`, che
  esce immediatamente se il controller era già acceso — e in quel caso il rilascio ha comunque
  strappato i tasti di mano al giocatore, che deve alzare e ripremere. È il rovescio esatto del
  bug che `_release_all_actions()` esiste per prevenire. *Rinviato: preesistente alla 1.3
  (`_set_world_active` è della 1.2) e non raggiungibile finché nessuna fase gira in background —
  serve una fase che concluda da sola mentre il giocatore cammina con il controller già acceso.
  Morde insieme alla fase 10 dell'epica 3.* [main.gd, world/player/player.gd]

- **Gli strumenti di debug non distinguono una fase sospesa da una viva.** Da quando alzarsi
  sospende invece di concludere, `F12` mostra `polar NN [HONEST]` come se la fase stesse
  girando — `score()` è una chiamata diretta, che `process_mode` non ferma — e `F9` scambia
  davvero la sorgente di verità su una fase congelata: l'iniezione ha effetto solo quando ci si
  risiede, cioè quando è meno probabile ricordarsi di averla premuta. Chi tara si convince che
  la fase stia integrando mentre è ferma, e il confronto A/B che l'iniettore esiste per rendere
  possibile viene fatto davanti a uno schermo fermo. *Rinviato: la correzione tocca `debug/`,
  che non è fra i file di questa storia, e la forma giusta (l'overlay dichiara lo stato di
  sospensione) va decisa insieme a chi userà davvero l'iniettore sulle fasi lunghe — cioè
  nell'epica 3, dove la fase 10 rende la distinzione «viva / sospesa / in background» un
  concetto di prima classe.* [debug/debug_overlay.gd, debug/lie_injector.gd]

- **Il CRT vuoto dipende da un'impostazione globale che riguarda tutt'altro.** Un
  `SubViewport` con `transparent_bg = false` e nessun figlio si pulisce con
  `rendering/environment/defaults/default_clear_color`, che il progetto non sovrascrive e
  che vale 0,3 grigio: attraverso lo shader del CRT diventa il grigio-verde che si vede
  all'avvio e dopo ogni `ENTER`. *Guardato il 2026-08-22 in code review, confrontando due
  scatti dal gioco vero: il grigio-verde legge come un CRT a fosfori acceso senza segnale e
  conserva scanline, curvatura e vignettatura; col nero lo shader si annulla — nero
  moltiplicato per una scanline resta nero — e il vetro sembra un buco ritagliato nella
  scocca. Si tiene il grigio-verde e non si tocca niente: rifinire un oggetto che il pack di
  texture ritoccherà comunque è lavoro buttato. Ma il valore non è stato SCELTO per questo
  schermo, ci è arrivato: chi un giorno cambierà quel default per il menu, o per una
  schermata di caricamento, cambierà anche l'aspetto del monitor senza avere modo di
  collegare le due cose. Un `SubViewport` non ha un colore di pulizia proprio, quindi
  renderlo locale costa un fondo permanente dentro il viewport — e `show_control()` rimuove
  TUTTI i figli, per la regola di proprietà che è il cuore di questa storia: andrebbe
  insegnata un'eccezione alla funzione meno adatta a riceverne una.* [crt/crt_screen.gd,
  project.godot]

## Deferred from: code review of 2-1-un-turno-che-comincia-alle-21-00-e-finisce-da-solo-allalba (2026-08-23)

- **`NightClock` non valida le due manopole che legge dal `.tres`.** `autoloads/tuning.gd` applica `POSITIVE_KEYS` solo dentro `_apply_override()`: il profilo caricato da `data/tuning.tres` non passa da nessuna validazione. Con `night_length_min = 0` l'alba scatta al primo `_process`, mentre `_enter_phase` ha appena montato la polare; con `game_min_per_sec = 0` la notte non finisce mai. In entrambi i casi in silenzio — nessun `push_error`, nessuna riga di log. Il banco il controllo lo fa, ma il banco è un eseguibile a parte. *Rinviato: il difetto è pre-esistente e vive in `autoloads/tuning.gd`, che questa storia consuma e non costruisce; il valore lo batte a mano uno sviluppatore, e se ne accorge al primo avvio.* [night/night_clock.gd, autoloads/tuning.gd]

- **`_on_phase_finished` non ha un latch.** La guardia `if phase != _phase: return` protegge dai `finished` tardivi, non dai doppi: `_phase` si azzera dentro `_advance`, che è differita, quindi due `finished` nello stesso frame passano entrambi — punteggio riscritto, `phase_finished` emesso due volte, `_ctx.merge()` applicato due volte, e due `_advance` in coda che saltano una fase lasciandone una viva sotto `PhaseHost`. *Rinviato: oggi non raggiungibile, `phases/polar/phase_polar.gd` ha il proprio `_done` a riga 71. Ma il contratto `core/phase.gd` non impone il latch, e l'orchestratore deve sopravvivere a sette fasi che non esistono ancora — la 2.3 (la sequenza che si conclude da sola su timer) è la prima candidata.* [night/night_session.gd]

- **La lambda su `Events.phase_started` cattura `self` e non viene mai disconnessa.** `main.gd:173` connette una lambda dove la riga adiacente (`:174`) usa un `Callable` nominato. `Events` è un autoload e sopravvive a `main`. L'asimmetria fra due righe consecutive è il segnale: se una merita un metodo, le merita entrambe. *Rinviato: innocuo finché `_begin_night()` gira una volta sola per sessione. Diventa una doppia connessione — e quindi un doppio `_refresh_monitor()` — il giorno in cui la 2.6 o la 2.7 riapriranno la notte senza ricostruire la scena.* [main.gd]

- **Il riepilogo trabocca dal vetro oltre cinque punteggi.** `night_summary.gd::_draw()` parte da `y = 84` e cresce di 16 per riga, mentre «the sky is getting light» sta fissa a `y = 172` su un `DESIGN_SIZE` alto 192: la sesta riga cade a 164 e si sovrappone, dalla settima si disegna fuori dal `Control`. Nessuno scroll, nessun troncamento, nessun `min()`. *Rinviato: oggi `data/night_plan.tres` ha una fase sola. Il proprietario è la storia che aggiunge fasi al piano — 2.2 e 2.3 — perché è quella che saprà anche quante righe ha senso mostrare.* [night/night_summary.gd]

- **`phase_scores[key()]` sovrascrive invece di accumulare.** L'indicizzazione per `key()` è corretta ed è AC4, ma una fase di foto rieseguita a ogni scatto scriverà sempre sulla stessa chiave: il riepilogo mostrerà una riga sola con il punteggio dell'ultimo scatto. Né `night_session.gd` né `core/night_run.gd` dicono se sia la semantica voluta. *Rinviato: la decisione appartiene alla 2.3, che è la storia in cui una fase viene eseguita più volte nella stessa notte per la prima volta.* [night/night_session.gd, core/night_run.gd]

- **`_photo_index` non si riazzera: il ciclo delle foto non riapre.** `_next_scene()` percorre `photo_phases` una volta sola e non torna mai indietro, quindi «le fasi di **foto** a ogni scatto» dell'AC3 è implementato a metà. *Rinviato di proposito, e dichiarato in loco a `night/night_session.gd:193-198`: ciò che riapre il ciclo è il menu post-foto della storia 2.6, e con `photo_phases` vuoto la cosa è oggi inosservabile. La voce esiste perché il Change Log della 2.1 dichiara AC3 soddisfatto senza citare il rinvio.* [night/night_session.gd]

- **AC2, clausola «si chiude anche se è aperto un menu»: non verificabile in questa storia.** `night/night_clock.gd` è un `Node` lasciato a `PROCESS_MODE_INHERIT`, deliberatamente: è ciò che rende vera l'altra metà dell'AC1, «la pausa ferma il tempo davvero». Ma con l'albero in pausa `_process` non gira, quindi `dawn` non può arrivare: un menu che mette in pausa **impedisce** all'alba di chiudere la notte. Le due clausole sono in tensione per costruzione, e la domanda aperta 5 dello spec lo sapeva. *Rinviata per decisione di Federico del 2026-08-23: `ui/` è vuoto e nessuna storia prima della 2.6 crea un menu, quindi oggi non esiste niente da mettere in pausa e la clausola non è osservabile. La prova si sposta alla 2.6, insieme al menu post-foto — che è anche la storia in cui si dovrà decidere se quel menu mette davvero in pausa l'albero o si limita a coprire lo schermo.* [night/night_clock.gd, night/night_session.gd]

### DW-1: La striscia indice del targeting assume al massimo sei target (passo fisso di 40px): con l'arrivo dei cataloghi (riviste, epica 3+) le sigle oltre la sesta si disegnerebbero fuori dai 256px.
origin: spec-deferred 61f31966e59b
location: phases/targeting/targeting_screen.gd:113
source_spec: `spec-2-2-scegliere-cosa-fotografare-stanotte.md`
severity: low
reason: targeting_screen.gd::_draw_index_strip avanza `x += 40` per ogni voce da x=8; la settima cadrebbe a x=248 e le successive fuori schermo. Nessun clamp o wrap sul numero di voci. Non si innesca nell'MVP (catalogo fisso a 6 target), ma diventa reale quando il catalogo cresce.
status: open


## Deferred from: code review of spec-2-2-scegliere-cosa-fotografare-stanotte (2026-08-23)

- **Il catalogo viene ricampionato e ridisegnato a ogni frame, per uno stato che cambia
  solo sui tasti.** `_process` chiama `truth.sample(_input)` — sei Dictionary di nove
  chiavi allocati ex novo, piu' dodici `String.split()` dentro `_visible_at` — e poi
  `set_readout()`, che chiama sempre `queue_redraw()`. Su una schermata ferma per un
  minuto sono ~3.600 ridisegni completi di un Control che non e' cambiato di un pixel.
  Nella polare il campionamento per frame ha una ragione: la deriva e' una quantita'
  continua da integrare. Qui il catalogo cambia solo al movimento del cursore o al
  varcare di una finestra. *Rinviato perche' non rompe niente oggi e la fase e' corta;
  ma il project-context dice che una fase non fa lavoro pesante per frame, e nessuno ne
  ha discusso.* [phases/targeting/phase_targeting.gd:66-80, targeting_screen.gd:45-48]

- **Un solo `.tres` di target mancante spegne l'intera notte, e il messaggio accusa il
  posto sbagliato.** La catena e' di `ext_resource` duri risolti al caricamento:
  `night_plan.tres` carica la scena della fase, che carica `honest_catalog.tres`, che
  carica i sei target. Prima della 2.2 il piano dipendeva solo da `phase_polar.tscn`;
  adesso sei file-foglia di dati sono dipendenze di caricamento dell'orchestrazione
  intera. Se si rinomina `data/targets/m8.tres` (gli `ext_resource` usano `path=`, non
  `uid://`), `main.gd` vede `plan == null`, stampa «piano della notte assente o
  illeggibile» e la notte non comincia mai — niente polare, niente alba, monitor
  disabilitato. La causa vera non compare da nessuna parte. *Rinviato: la degradazione
  garbata che il codice ha gia' (`_phase_can_run` che salta una fase senza `truth`,
  `_next_scene` che salta una casella vuota) non copre questo, perche' il fallimento
  avviene a MONTE del piano.* [data/night_plan.tres, phases/targeting/phase_targeting.tscn]

- **Il cursore e' un indice posizionale su una lista che puo' cambiare sotto le dita.**
  `_cursor` non e' mai riconciliato con l'IDENTITA' del target: viene solo riclampato
  alla dimensione. Se una sorgente futura nascondesse i target non disponibili — che e'
  esattamente la bugia che ADR-001 rende sostituibile senza toccare la fase — il
  giocatore col cursore su M31 in posizione 3 vedrebbe M45 uscire dalla lista, tutto
  scalare di uno, e premendo ENTER confermerebbe M57. Nessun errore, nessun log, e la
  scelta sbagliata finisce nel save. *Rinviato: irraggiungibile con la sorgente onesta,
  che restituisce sempre tutti e sei i target nello stesso ordine.*
  [phases/targeting/phase_targeting.gd:79, :93, :115]

## Decisione CHIUSA dalla storia 2.3 (2026-08-23) — era «DA CHIUDERE PRIMA DELLA 2.3»

- **Cosa fa l'imaging di un bersaglio sotto l'orizzonte.** ~~Deciso in code review che la
  scelta resta LIBERA~~ **CHIUSA nella 2.3**: la posa **parte lo stesso e produce una foto
  normale** — nessuna attesa del sorgere, nessun degrado, nessun rifiuto. Nell'MVP la
  visibilità non tocca l'imaging: la segnalazione «not visible now» resta un fatto
  diegetico del *targeting*, e l'imaging la ignora. Le tre letture alternative (aspettare
  che sorga / rifiutare / foto peggiore) sono escluse dal design esistente — vedi
  `spec-2-3-la-posa-configurare-la-sequenza-e-lasciarla-lavorare.md` § Design Notes, che è
  la fonte della decisione. La scelta resta LIBERA nel targeting (`epics.md:663`); la
  visibilità non entra nemmeno in `phase_scores`.
  [phases/imaging/phase_imaging.gd, phases/targeting/phase_targeting.gd]

### DW-2: Nessuna copertura automatica del percorso config→run→finish della fase (runs_in_background, completamento mentre il giocatore è via, elapsed→frame dal clock).
origin: spec-deferred c8141306f567
location: phases/imaging/phase_imaging.gd:_process/_start/_finish
source_spec: `spec-2-3-la-posa-configurare-la-sequenza-e-lasciarla-lavorare.md`
severity: medium
reason: Il banco prova solo l'aritmetica pura della sorgente e il passaggio del target in setup(); il comportamento-bandiera «avvia, allontanati, si completa da solo» (AC2/AC4) è verificato solo dall'avvio-gioco di verify.ps1 (che si ferma a 600 frame e non raggiunge mai il completamento) e a schermo. È coerente col modello del progetto (il banco prova la matematica, non la fase in albero), ma la logica stateful di start/finish è nuova e non asserita.
status: open

### DW-3: L'imaging procede con ok=true e target_id vuoto quando il ctx non lo porta, propagando &"" nel payload verso 2.4/2.5.
origin: spec-deferred 0ef2e0f3f95e
location: phases/imaging/phase_imaging.gd:96-104,234-240
source_spec: `spec-2-3-la-posa-configurare-la-sequenza-e-lasciarla-lavorare.md`
severity: low
reason: A differenza del targeting (che emette ok=false su id vuoto), il guard del ctx mancante fa solo push_error e prosegue; cosa stacking/vendita facciano di un target_id vuoto è una domanda di contratto aperta per 2.4/2.5.
status: open

### DW-4: SequenceChime si collega a Events.phase_finished in _ready senza mai disconnettersi.
origin: spec-deferred a5b797288993
location: phases/imaging/sequence_chime.gd:12-14
source_spec: `spec-2-3-la-posa-configurare-la-sequenza-e-lasciarla-lavorare.md`
severity: low
reason: Innocuo oggi (la scena del mondo è istanziata una volta per sessione), ma diventa una doppia connessione — chime che suona più volte — il giorno in cui la scena dell'osservatorio venisse ricostruita. Rispecchia la voce rinviata dalla 2.1 sulla lambda di Events.phase_started mai disconnessa.
status: open

### DW-5: I parametri audio 3D del chime (unit_size=6, max_distance=30, max_db=3) sono segnaposto non documentati.
origin: spec-deferred 0f77000996ca
location: phases/imaging/sequence_chime.tscn
source_spec: `spec-2-3-la-posa-configurare-la-sequenza-e-lasciarla-lavorare.md`
severity: low
reason: Regolano la caduta «udibile da un'altra stanza» (AC4) ma sono numeri a occhio, non tarati su hardware — come i segnaposto visivi, chiedono un passaggio di ascolto-e-aggiusta.
status: open

### DW-6: Il filtro &"imaging" del chime e PhaseImaging.key() sono due letterali separati, senza nulla che li tenga in sync.
origin: spec-deferred b8ea454bc2a3
location: phases/imaging/sequence_chime.gd:31, phases/imaging/phase_imaging.gd:86-87
source_spec: `spec-2-3-la-posa-configurare-la-sequenza-e-lasciarla-lavorare.md`
severity: low
reason: Se key() cambiasse, il chime smetterebbe di suonare in silenzio; nessun controllo cross-file lega i due letterali.
status: open

### DW-7: Il flusso di vendita non ha copertura automatica: la composizione in _on_sale_confirmed (credito wallet_lire + emissione photo_sold), la logica UI di photo_sale (_fulfill_options, _declined / "decline
origin: spec-deferred 28d397b441df
location: night/night_session.gd:_on_sale_confirmed, night/photo_sale.gd
source_spec: `spec-2-5-qualcuno-la-compra-e-paga-subito.md`
severity: medium
reason: Il banco (NFR19) prova solo logica pura senza SceneTree: sale_lire/applies_to/ tier_payout sono coperti, ma la glue stateful e il Control non ospitato no. Rispecchia DW-2 (stessa lacuna per il flusso imaging della 2.3). Una regressione (chiave mult errata, credito omesso, emissione pre-moltiplicatore, ordine _fulfill_options invertito) lascerebbe il banco verde.
status: open

### DW-8: Events.photo_sold emette come photo_id l'indice per-notte del record (Photo.KEY_ID) coercito a StringName: due foto di notti diverse condividono l'indice 0, quindi l'id è ambiguo per un aggregatore cr
origin: spec-deferred ecf51b77654c
location: night/night_session.gd:_on_sale_confirmed
source_spec: `spec-2-5-qualcuno-la-compra-e-paga-subito.md`
severity: low
reason: night_session._on_sale_confirmed fa Events.photo_sold.emit(StringName(str(_sale_photo_id)), lire); _sale_photo_id = record[Photo.KEY_ID] = indice in run.photos. L'MVP non ne ha bisogno, ma va ricordato per la 2.7.
status: open

### DW-9: Il flusso del menu post-foto non ha copertura automatica: il rientro nel piano dei quattro rami (_on_menu_chosen), l'apertura via _sale.dismissed, il present-gating e la liberazione all'alba del _menu
origin: spec-deferred c485b3c5cf15
location: night/night_session.gd:_on_menu_chosen, night/post_photo_menu.gd
source_spec: `spec-2-6-decidere-quanto-rifare.md`
severity: medium
reason: Il banco (NFR19) prova solo logica pura senza SceneTree; la 2.6 è orchestrazione (NightSession) + UI (Control diegetico che gestisce input nel SubViewport), stateful. Rispecchia DW-2 (stessa lacuna per il flusso imaging della 2.3) e la lacuna della composizione di vendita della 2.5. Una regressione (indice foto errato, chiave di setup mancante in _setup_phase_keys, guardia _ended assente) lascerebbe il banco verde.
status: open

## Regola non applicata — rilevata il 2026-08-23 sulla fase imaging

- **Ogni fase porta la sua bugia, e `phases/imaging/` non ce l'ha.** La regola è stata
  decisa da Federico in code review il 2026-08-23 (seam di ADR-001 / FR34: `F9` deve avere
  qualcosa da iniettare su OGNI fase, perché una fase senza voce in `LIE_PATHS` è una fase
  su cui il vincolo non è mai stato messo alla prova). La 2.3 ha creato
  `phases/imaging/sources/honest_sequence.tres` e nessuna sorgente bugiarda, e
  `debug/lie_injector.gd:LIE_PATHS` non ha la chiave `&"imaging"`.
  *Non è colpa della 2.3: la regola era scritta in un commento dentro `lie_injector.gd`,
  un file che quella storia non aveva nessuna ragione di aprire. La stessa sessione ha
  invece RACCOLTO la domanda sul bersaglio sotto l'orizzonte, che era scritta qui nel
  ledger e accanto alla riga della 2.3 in sprint-status — e l'ha chiusa citandola per
  nome. Il ledger si legge, un commento in un file non toccato no: da qui in avanti ogni
  regola che deve valere per le storie future si scrive QUI, e il commento nel codice al
  massimo la ripete.*
  Servono: `phases/imaging/sources/wandering_sequence.gd`/`.tres` (mente su ciò che la
  fase osserva) e la riga in `LIE_PATHS`. Da fare prima di chiudere l'epica 2, così la
  regola vale davvero quando l'epica 3 porterà le fasi da cinque a dieci.
  [debug/lie_injector.gd, phases/imaging/sources/]

### DW-10: La glue stateful della persistenza — Game._ready che adotta il profilo caricato, end_night che versa+salva alla chiusura, e la cattura di closed_index prima di end_night in _close_night — non ha coper
origin: spec-deferred a883330e0b86
location: autoloads/game.gd:32-33,56-64; night/night_session.gd:64-65
source_spec: `spec-2-7-il-portafoglio-e-ancora-li-la-notte-dopo.md`
severity: medium
reason: Il banco (NFR19) prova solo logica pura senza SceneTree: _check_save_manager esercita SaveManager in isolamento e il caso (e) prova il travaso attraverso un disco, ma nessun test guida Game.end_night / Game._ready / _close_night. Il gate avvia il gioco a 600 frame e l'alba cade a ~900 s, quindi end_night e il fix del null-deref non vengono mai eseguiti in verifica. Una regressione (rimozione delle due chiamate save_*, profilo caricato ma non adottato, ritorno del deref di Game.run dopo end_night) lascerebbe banco e gate verdi. Sorella di DW-7 e DW-9, stessa lacuna per la glue di NightSession.
status: open

### DW-11: Il salvataggio non è atomico: un crash o un'interruzione a metà di ResourceSaver.save su profile.tres lo corrompe, e il giocatore perde il portafoglio — proprio ciò che la storia esiste per proteggere
origin: spec-deferred cf54b0fd8aa9
location: core/save_manager.gd:86-92
source_spec: `spec-2-7-il-portafoglio-e-ancora-li-la-notte-dopo.md`
severity: low
reason: SaveManager._save scrive in place. Il ramo di recupero (save illeggibile -> frase gentile + profilo pulito) rende la perdita garbata, ma resta una perdita. Un pattern scrivi-su-temp-poi-rinomina la renderebbe a prova di crash. Non richiesto da nessun AC della 2.7; enhancement di robustezza.
status: open

## Tre domande di GIOCO, aperte a fine epica 2 (2026-08-23)

**AGGIORNAMENTO DEL 2026-08-23, SERA — DQ-1 e DQ-3 sono CHIUSE, DQ-2 e' chiusa a
meta'.** Le ha chiuse Federico giocando: ha fatto una notte intera, poi altre tre, e
quello che ha visto (e il log della sua sessione) ha risposto a due domande su tre.
Chi legge questa sezione legga prima i tre riquadri qui sotto: il codice e' gia'
cambiato, e le descrizioni originali delle domande sono conservate solo come storia.

> ### DQ-1 — CHIUSA il 2026-08-23. Regola scelta: TEMPO TOTALE = FRAME x ESPOSIZIONE.
>
> Da quella regola discendono tutte e tre le cose che mancavano:
>
> - **Durata**: un frame dura quanto integra (`_game_min_per_frame()` =
>   `exposure_sec / 60 * Tuning.pose_time_scale`). `Tuning.min_per_frame` NON ESISTE
>   PIU': era una costante di 5 minuti a frame che rendeva l'esposizione inerte.
>   Al suo posto `pose_time_scale` (default 1.0), la manopola con cui l'epica 3
>   tara quanto pesa l'attesa senza toccare la fisica.
> - **Punteggio**: `PhaseImaging.exposure_score(total_min, min_exp)`, pura e statica.
>   Il minimo lo dichiara il target (`min_exp` nei `.tres`) e VIAGGIA NEL PAYLOAD del
>   targeting — una fase non conosce mai un'altra fase. Curva: 0 a zero, sale in
>   proporzione fino a `SCORE_AT_MINIMUM` (60) al minimo, poi fino a 100 al doppio
>   (`FULL_SCORE_RATIO`), e li' si ferma. Oltre il doppio non sale APPOSTA: premiare
>   chi aspetta di piu' renderebbe la scelta un'ottimizzazione con una sola risposta.
> - **Conseguenza a schermo**: il pannello di configurazione mostra totale contro
>   minimo, la qualita' che ne esce, e quanti minuti di notte costera' la sequenza.
>
> La strategia dominante `frames = 1` non esiste piu': un frame solo integra troppo
> poco per superare il minimo del target.
>
> **Cosa resta da tarare, e appartiene all'epica 3**: `pose_time_scale`. Con i valori
> di partenza (20 frame x 120s) la posa dura 40 minuti di notte su 540, cioe' circa
> 67 secondi reali. E' il numero che decide quanto dura l'attesa da riempire.

> ### DQ-2 — CHIUSA A META' il 2026-08-23.
>
> `PhaseImaging.PLACEHOLDER_SCORE` non esiste piu': l'imaging produce un punteggio
> vero (vedi DQ-1). `PhaseTargeting.NEUTRAL_SCORE = 100` RESTA, ed e' deliberato:
> scegliere un bersaglio non e' un'abilita' e non deve avere un voto. Se un giorno
> si vorra' che la scelta pesi — un target difficile che vale di piu' — il posto e'
> `diff` nei `.tres`, che oggi si mostra e non entra in nessun calcolo.
>
> **Effetto sull'economia**: la qualita' e' la media di polar + targeting(100) +
> imaging. Con due su tre variabili il payout ha finalmente un gradiente, ma le due
> costanti lo COMPRIMONO: una posa scadente (imaging 30) porta comunque a 3500 lire,
> una perfetta a 15000. La curva di `payout_tiers` non e' mai stata tarata contro
> punteggi veri, e adesso per la prima volta si puo' farlo.

> ### DQ-3 — CHIUSA il 2026-08-23. Si va a letto.
>
> Esiste `world/interactables/bed.tscn`, un `Interactable` che `main.gd` accende SOLO
> all'alba (`_dawn`). Premendo `E`: dissolvenza, il giocatore torna al punto di
> partenza, `Game.start_night()` e `_night.begin()` — l'orchestratore SI RIUSA, non si
> ricostruisce, perche' `begin()` e' scritta per essere richiamata e ricostruirlo
> perdeva i `Control` reparentati nel CRT (misurato: 16 istanze a notte).
>
> Scelta di Federico fra tre opzioni: un oggetto e non un pulsante sul riepilogo,
> perche' ADR-003 dice che i passaggi sono GESTI.
>
> **Regola da conoscere prima di toccare `world/interactables/`**: il raggio di
> interazione parte dall'occhio a 1,65 m e arriva a 1,2 m. Un oggetto la cui massa
> sta sotto i ~60 cm NON E' RAGGIUNGIBILE da nessuna posizione, e non lo si scopre
> guardando il codice. Il volume di collisione va progettato come cosa a se',
> abbastanza alto da stare nello sguardo — ma non piu' alto della geometria visibile,
> o il prompt compare guardando il muro dietro. Vale per la moka (3.3), la lampada
> (3.4) e qualunque cosa la 3.1 metta in cucina.

Non sono difetti di codice: l'aritmetica e' corretta ovunque e il banco e' verde. Sono
domande su come deve funzionare il gioco, emerse dalla review adversariale delle sette
storie. **Descrizioni originali, conservate come storia:**

- **DQ-1 — L'esposizione che il giocatore configura non influenza niente.** Non la
  durata (`frames_done = elapsed / min_per_frame`, e `min_per_frame` viene da `Tuning`),
  non la qualita' (imaging e targeting restituiscono sempre 100, quindi la qualita' di
  ogni foto dipende SOLO dal punteggio dell'allineamento polare, fatto una volta a
  inizio notte), non il prezzo. *Conseguenza misurabile: un frame invece di quaranta
  costa cinque minuti invece di duecento e produce una foto identica, che si vende allo
  stesso prezzo. La strategia dominante e' `frames = 1`, e la notte da 540 minuti
  diventa un distributore di foto uguali. E' il difetto piu' grosso emerso dalla review,
  e nessuna delle quattro sessioni poteva vederlo dalla propria storia.* La domanda:
  cosa deve rendere una foto migliore di un'altra? Il numero di frame? L'esposizione?
  Il tempo totale di integrazione (frame x esposizione, che e' la risposta fisicamente
  vera)? [phases/imaging/, photo/quality.gd]

- **DQ-2 — Il punteggio delle fasi foto e' un segnaposto, e regge tutta l'economia.**
  `PhaseTargeting.NEUTRAL_SCORE = 100` e `PhaseImaging.PLACEHOLDER_SCORE = 100` sono
  dichiarati segnaposto nei loro file, ma `PhotoQuality.aggregate` ne fa la media con
  il punteggio polare e da li' esce lo scaglione di payout. *Finche' valgono 100 fissi,
  meta' dell'economia e' costante.* Legata a DQ-1: rispondere alla prima probabilmente
  risponde anche a questa. [phases/targeting/phase_targeting.gd, phases/imaging/phase_imaging.gd]

- **DQ-3 — La notte finisce e nessuno chiede se vuoi continuare.** All'alba si vede il
  riepilogo, `end_night()` versa e salva, e il gioco resta li'. Non c'e' nessun modo,
  dentro il gioco, di cominciare la notte 2: il save c'e' e funziona, ma solo riavviando
  l'eseguibile si rilegge il profilo. *L'epica 2 chiude il ciclo di UNA notte; il ciclo
  fra le notti e' scritto su disco ma non ha un gesto che lo attraversi.* Non e' un
  criterio mancato — nessuna storia lo chiedeva — ma e' l'anello che manca perche' la
  persistenza appena costruita si veda giocando. [main.gd, night/night_summary.gd]
