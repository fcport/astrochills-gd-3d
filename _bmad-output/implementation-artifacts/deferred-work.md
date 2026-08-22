# Deferred work

Lavoro reale, rinviato con una ragione. Ogni voce dice da dove viene e cosa la sblocca.

## Deferred from: code review of 1-1-lallineamento-polare-e-la-prova-che-il-seam-regge (2026-08-22)

- **`phase_scores` con chiavi `StringName` non sopravvive a un round-trip JSON.** `Game.run.phase_scores[phase.key()]` usa `&"polar"`; in Godot 4 `dict[&"polar"]` e `dict["polar"]` sono due voci distinte. Una partita ricaricata da JSON avrebbe punteggi irraggiungibili tramite `phase.key()`, e un rigioco scriverebbe in silenzio una seconda voce parallela. *Rinviato: il sistema di save non esiste ancora — arriva con l'epica 2, ed è bloccato dalla decisione C1 (contenitore per lo stato che attraversa le notti).* [main.gd]

- **`_collect_materials` raccoglie solo `material_override`.** Salta i materiali per-superficie e `material_overlay`, e non deduplica: un `ShaderMaterial` condiviso fra N mesh viene scritto N volte e contato N volte, quindi il log `%d materiali` non permette di distinguere «non ho trovato niente» da «ho trovato la cosa sbagliata». *Sbloccato il 2026-08-22 dalla storia 1.2: la geometria 3D nel viewport adesso c'è, tutta su `material_override`, e i comandi di taratura hanno un bersaglio. Il salto dei materiali per-superficie NON è più un difetto: `crt/crt_screen.gd` usa `get_surface_override_material(0)` di proposito, perché il CRT non deve essere toccato dalla taratura del jitter del mondo. **Resta aperta la sola mancata deduplicazione**, che dalla 1.2 in poi è visibile davvero — la stanza condivide un materiale fra sei pareti — ma è innocua: scrivere N volte lo stesso parametro dà lo stesso risultato, e il conteggio nel log è ora documentato come «per mesh, non per materiale».* [debug/render_tuning.gd]

- **`_samples` salva il timestamp in float32 e lo confronta con un cutoff float64.** `Vector2` è `real_t` a 32 bit, `_elapsed` è un double GDScript: il timestamp memorizzato è una copia arrotondata del valore contro cui viene poi confrontato, quindi il confine di sfratto sbaglia fino a un ULP. `_elapsed` inoltre cresce senza limite e senza reset. *Rinviato: invisibile con la finestra di default da 8 s (±1 campione su ~480); degrada solo su sessioni molto lunghe.* [phases/polar/phase_polar.gd]

- **`set_anchors_preset(PRESET_FULL_RECT)` funziona per coincidenza.** Il default `keep_offsets = true` sposta solo le ancore e ricalcola gli offset per **preservare** il rect che il Control ha già: regge oggi soltanto perché `polar_screen._ready()` ha impostato `256×192` a (0,0), che combacia con il viewport. La chiamata che fa ciò che il commento intende è `set_anchors_and_offsets_preset`. *Rinviato: verificato funzionante oggi (256×192, offset zero); è fragilità latente che morde quando la 1.3 porta il Control sul CRT diegetico e le misure smettono di combaciare per caso.* [main.gd]

- **Dopo ENTER il ponte finisce nel vuoto.** `_advance()` svuota il viewport, libera la fase e si ferma: schermo nero, nessun riscontro che qualcosa si sia concluso, e il `reason` non lo legge nessuno. *Rinviato: limite dichiarato del ponte temporaneo, coperto dalla quarta clausola di AC6 — si chiude con la storia 1.3, quando il giocatore si siede al monitor. Registrato qui perché non venga scambiato per una regressione.* [main.gd]

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
  **Registrato perché non venga scambiato per una regressione.* [main.gd]

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
  `phase_scores` è già in questo file dalla review della 1.1.* [main.gd]

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
  [world/rooms/computer_room.tscn, world/observatory.tscn]

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
