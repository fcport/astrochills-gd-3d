# Epic 3 Context: L'attesa — l'osservatorio mentre la posa gira

<!-- Generated from planning artifacts. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Mentre la sequenza di imaging espone, il monitor non serve: il giocatore si alza e vive l'osservatorio. Mette su la moka e aspetta che borbotti, sale in cupola a guardare il cielo dalla fessura mentre il telescopio lavora da solo, cambia la lampada che lampeggia in cucina, e legge i forum della BBS. È l'epica che risponde alla domanda per cui l'MVP esiste — le altre due costruiscono l'apparato, questa produce il dato: finché non è finita, l'ipotesi centrale del gioco (*l'attesa è piacevole*) non è stata misurata. Le attività coprono di proposito registri diversi — *fare* (caffè), *sistemare* (lampada), *stare* (cupola), *leggere* (forum) — perché il piacere è personale, e chiudono col file di telemetria che rende tre notti confrontabili invece che tre impressioni.

## Stories

- Story 3.1: L'osservatorio si allarga — una scena sola, dentro e fuori
- Story 3.2: Il terminale — spendere quello che hai guadagnato
- Story 3.3: Il caffè — l'attesa piccola dentro l'attesa grande
- Story 3.4: La lampada che smette di lampeggiare
- Story 3.5: La cupola — stare a guardare
- Story 3.6: La telemetria — trasformare l'impressione in prova
- Story 3.7: I forum della BBS — leggere mentre la posa gira

## Requirements & Constraints

- **Nessuna attività dà un bonus meccanico.** È la regola che tiene insieme tutta l'epica: un bonus trasformerebbe un rituale in una faccenda da ottimizzare, e la telemetria misurerebbe l'obbedienza invece del piacere. Da nessuna parte deve essere scritto che un bonus potrebbe esistere.
- **Le attività sono opzionali e senza fallimento.** Nessun conto alla rovescia visibile, nessun prompt che solleciti, nessun contatore di "non letti". Un rituale lasciato a metà non si rompe e non scade. La differenza fra "lo trovo se lo cerco" e "mi viene chiesto di svuotarlo" è la differenza fra un piacere e un dovere.
- **Solo ciò che ha un effetto implementato è acquistabile/presente.** Il terminale vende solo moka e lampadina; le altre categorie di `economia.md` non compaiono affatto, nemmeno come voci disabilitate. Un menu che promette cose che non ci sono è peggio di un menu corto.
- **Ogni acquisto cambia il mondo subito e in modo permanente**, persistito nel save (portafoglio, flag, effetto visibile/udibile).
- **Telemetria locale e privata.** Un file JSON leggibile per notte in `user://telemetry/`, separato dal log. Contiene `night`, `tuning_hash` (obbligatorio: senza, le notti non sono confrontabili), `wait_total_min`, `wait_activities[]`, `menu_reopened`, `quit_mid_pose`. I tratti `idle` (attesa non riempita) sono il dato più importante del file, calcolati per differenza. Nessuna rete, nessun dato personale, offline per costruzione.
- **Leggibilità del CRT a `256×192` da seduti.** Nessun testo troncato in silenzio; lo scorrimento dei messaggi lunghi è esplicito. Verificare guardando, non stimando.
- **Lingua:** interfacce macchina (terminale, BBS) in inglese; contenuti scritti da persone (descrizioni prodotti, messaggi forum) in italiano.
- **Volume di collisione degli interagibili:** il raggio d'interazione parte dall'occhio a 1,65 m e arriva a 1,2 m — un oggetto sotto i ~60 cm non è raggiungibile. Il volume d'interazione si progetta a parte dalla geometria visibile e si verifica misurando da dove l'oggetto è raggiungibile.

## Technical Decisions

- **Il mondo è UNA scena sola:** `world/observatory.tscn` contiene stanza computer, cucina, cupola ed esterno insieme, senza nessun cambio di scena né caricamento asincrono. L'unica dissolvenza del gioco resta quella del sonno (salto di tempo, non di luogo). Se un giorno non ci sta in memoria, la risposta è ridurre la geometria (che è segnaposto), non tornare a spezzare la scena.
- **Un solo `WorldEnvironment`:** cielo notturno esterno e atmosfera interna condividono lo stesso `Environment`; la nebbia che chiude le distanze fuori è la stessa che dà profondità dentro. Resa con `ps1.gdshader`.
- **Isolamento delle cartelle (invarianti di architettura):** `world/` non conosce `phases/` né `night/`; `crt/` non conosce le fasi; `core/` non dipende da nulla. La cupola sa che una sequenza è in corso **solo tramite `Events`**, mai interrogando la fase.
- **Schermo diegetico:** terminale e BBS sono `Control` mostrati sul CRT; il CRT non sa cosa sta mostrando (stesso pattern del monitor, connessione via registrazione `Events.screen_registered`). Terminale e BBS condividono cornice ASCII e fosforo verde su nero — è lo stesso computer.
- **I suoni appartengono al luogo, non alla fase.** Il ronzio/segnale della sequenza è un `AudioStreamPlayer3D` nel luogo (es. cupola), così il fine-sequenza collocato in stanza computer (storia 2.3) si sente ovattato dalla cucina, appena dalla cupola, e da fuori non si sente. La geografia sonora si verifica camminando.
- **Condotto di misura — coppia di eventi:** `Events.wait_activity_started(what)` / `wait_activity_ended(what)` con `what` fra `&"caffe"`, `&"lampada"`, `&"cupola"`, `&"forum"`. La durata di ogni attività si ricava dalla coppia; un `started` senza `ended` è un abbandono (nel file: `dur: null`, `abandoned: true`) — un dato, non un buco. Gli intervalli sovrapposti si uniscono, non si sommano (caffè sul fuoco mentre si sale in cupola è il caso normale). L'emissione non produce mai feedback visibile.
- **La telemetria dell'attesa la raccoglie la fase in background**, ascoltando `Events`: è l'unica che sa quando l'attesa comincia e finisce. Le fasi in background non assumono mai di essere visibili (niente accesso a viewport/camera).
- **I contenuti dei forum stanno in `data/*.tres`** come ogni altro dato del gioco — niente JSON, niente `FileAccess` per i testi. Almeno tre aree con voci diverse; nuovi messaggi compaiono col passare delle notti; i letti si distinguono e la distinzione sopravvive al save. Nessun messaggio contiene informazioni che aiutino a fotografare meglio.

## Cross-Story Dependencies

- **3.6 (telemetria) è a valle di tutte le attività:** consuma le coppie `started`/`ended` emesse da 3.3, 3.4, 3.5, 3.7. Lo schema di `wait_activities[]` deve includere `caffe`, `lampada`, `cupola` e `forum`.
- **3.3, 3.4 dipendono da 3.2 (terminale):** moka e lampadina esistono nel mondo solo dopo essere state comprate.
- **3.5, 3.7 dipendono dall'ambiente sonoro/geografia di 3.1** per la resa corretta del fine-sequenza a distanza.
- **Dipendenze in avanti note dall'analisi di readiness (da chiudere a monte dell'implementazione):**
  - La cupola (3.5) ha bisogno che le fasi delle epiche 1-2 emettano gli eventi di stato sequenza (`phase_started`/`phase_finished`), che nessun criterio delle epiche 1-2 obbliga oggi a emettere (M1). Va aggiunto l'obbligo di emissione a 2.1/2.3.
  - Il terminale (3.2) e la persistenza degli acquisti dipendono da un contenitore per lo stato che attraversa le notti, non ancora definito (C1) — da chiudere prima della 2.7.
  - La firma `wait_activity` va portata alla coppia `started`/`ended` prima di implementare le attività (C4), e serve un proprietario esplicito per la telemetria (C3). **Deciso il 2026-08-24: `autoloads/telemetry.gd`, quinto autoload**, che ascolta il bus e non passa da `Log`; nessun altro file lo nomina. Vedi `c3-dossier-telemetria.md`.
