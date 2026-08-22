# Deferred work

Lavoro reale, rinviato con una ragione. Ogni voce dice da dove viene e cosa la sblocca.

## Deferred from: code review of 1-1-lallineamento-polare-e-la-prova-che-il-seam-regge (2026-08-22)

- **`phase_scores` con chiavi `StringName` non sopravvive a un round-trip JSON.** `Game.run.phase_scores[phase.key()]` usa `&"polar"`; in Godot 4 `dict[&"polar"]` e `dict["polar"]` sono due voci distinte. Una partita ricaricata da JSON avrebbe punteggi irraggiungibili tramite `phase.key()`, e un rigioco scriverebbe in silenzio una seconda voce parallela. *Rinviato: il sistema di save non esiste ancora — arriva con l'epica 2, ed è bloccato dalla decisione C1 (contenitore per lo stato che attraversa le notti).* [main.gd]

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
  [main.gd]

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
  canale che nessuno usa.* [crt/crt_screen.gd, autoloads/events.gd]

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
