---
title: 'Implementation Readiness Assessment'
project: 'astrochills-gd-3d'
date: '2026-08-21'
assessor: 'Game Producer / Scrum Master (gds-check-implementation-readiness)'
stepsCompleted: [1, 2, 3, 4, 5, 6]
scope: 'Allineamento ARCHITETTURA ↔ EPICHE. GDD e documento UX assenti per decisione.'
inputDocuments:
  - '_bmad-output/game-architecture.md'
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/planning-artifacts/briefs/brief-astrochills-gd-3d-2026-08-21/brief.md'
  - '_bmad-output/planning-artifacts/briefs/brief-astrochills-gd-3d-2026-08-21/addendum.md'
  - 'docs/idea/economia.md (§12-13, per verificare i requisiti derivati)'
  - 'repository reale: project.godot, main.tscn, main.gd, core/, autoloads/, crt/, world/, data/, spike/'
verdict: 'NEEDS WORK — 4 critici, 6 maggiori, 7 minori. Nessuno rimette in discussione architettura o scomposizione.'
resolved: ['C2', 'C4']
resolvedOn: '2026-08-21'
---

# Implementation Readiness Assessment Report

> **Stato dei rilievi, aggiornato il 2026-08-21 dopo la stesura.**
> **C2 e C4 sono chiusi.** La storia 2.2 ha il suo AC su `honest_catalog` e FR16 è dichiarato
> cross-cutting; `Events.wait_activity(what)` è diventato la coppia
> `wait_activity_started` / `wait_activity_ended`, con FR27, le storie 3.3-3.6 e lo schema di
> telemetria dell'architettura aggiornati di conseguenza. Dettaglio in `epics.md § Revisione del
> 2026-08-21`.
> **Restano aperti:** C1 (da chiudere prima della storia 2.7), C3 (prima della 3.6) e i sei
> maggiori. Il corpo del report qui sotto è lasciato **com'era al momento della verifica**: è la
> fotografia che ha prodotto le correzioni, e riscriverla cancellerebbe il motivo per cui sono
> state fatte.

**Data:** 2026-08-21 · **Progetto:** astrochills-gd-3d (Astrochill)
**Ambito:** MVP — una notte, tre fasi (3 polare, 6 targeting, 10 imaging), stacking,
vendita, gestione leggera dell'osservatorio durante la posa.
**Ipotesi da validare:** *l'attesa è piacevole*.

---

## 0. Metodo — cosa è stato verificato e cosa non è stato assunto

Non esistono GDD né documento UX: sono **assenze decise**, e questa verifica non le tratta
come lacune. L'asse della revisione è quindi quello reale: **architettura ↔ epiche**, con il
brief e l'addendum come sorgente di design a monte.

Tre scelte di metodo, perché cambiano il peso dei risultati:

1. **La sezione «Validation» di `epics.md` è stata trattata come non verificata** e
   ricontrollata voce per voce (§6). È un'autovalutazione scritta dallo stesso agente che ha
   prodotto le epiche.
2. **Le affermazioni sullo stato del repo sono state riverificate leggendo il repo**, non
   accettate dalla tabella «keeper — verificato sul repo, non assunto». Sono stati letti:
   `project.godot`, `main.tscn`, `main.gd`, tutti i file di `core/` e `autoloads/`,
   `crt/crt_screen.gd`, `crt/crt_screen.tscn`, `crt/desk_camera.gd`, `world/shaders/ps1.gdshader`,
   `data/tuning.tres`, `spike/`.
3. **I conteggi strutturali sono stati contati**, non letti (16 storie, 80 blocchi
   `Given`/`When`/`Then`).

**Nota di sequenza, rilevante per leggere tutto il resto:** l'architettura è stata scritta
*prima* delle epiche (`game-architecture.md` 20:34, `epics.md` 22:05) e dichiara nel proprio
frontmatter `epics: null`, con la voce di validazione «Mappatura epiche — N/A, non esistono
epiche». **L'architettura non è mai stata riletta contro le epiche che ora esistono.** Tutti i
disallineamenti qui sotto stanno esattamente in quel varco.

---

## 1. Document Discovery

### Documenti trovati

| Tipo | File | Dim. | Stato |
|---|---|---|---|
| Architettura | `_bmad-output/game-architecture.md` | 55 KB, 1271 righe | completa, 9/9 step, spike validati |
| Epiche e storie | `_bmad-output/planning-artifacts/epics.md` | 71 KB, 1175 righe | 3 epiche, 16 storie |
| Contesto progetto | `_bmad-output/project-context.md` | 13 KB | completo, 7 sezioni |
| Brief | `.../briefs/brief-astrochills-gd-3d-2026-08-21/brief.md` | 15 KB | draft |
| Addendum | `.../briefs/brief-astrochills-gd-3d-2026-08-21/addendum.md` | 9,7 KB | draft |
| Log decisioni | `.../briefs/.../.decision-log.md` | 14 KB | supporto |
| Design a monte | `docs/idea/{idea,economia,minigiochi,riassunto-creativo}.md` | — | descrive un gioco più grande dell'MVP |

**GDD:** assente per decisione. **UX:** assente per decisione. **Duplicati whole/sharded:**
nessuno. **Report di readiness precedenti:** nessuno.

**Nessun problema bloccante in questo step.** L'inventario è pulito e non c'è ambiguità su
quale versione di un documento usare.

---

## 2. Requirements Analysis (in assenza di GDD)

Il workflow standard estrarrebbe i requisiti da un GDD. Qui i requisiti sono **derivati**, e
l'inventario vive dentro `epics.md`. La verifica è quindi diventata: *l'inventario derivato è
fedele a ciò che architettura, brief e addendum impongono davvero?*

### Inventario dichiarato nelle epiche

| Categoria | Conteggio | Origine dichiarata |
|---|---|---|
| Functional Requirements | **37** (FR1-FR37) | brief, addendum, architettura, `economia.md` |
| NonFunctional Requirements | **24** (NFR1-NFR24) | architettura, project-context |
| UX Design Requirements | **11** (UX-DR1-UX-DR11) | `economia.md §4`, ADR-003, valori dello spike |
| Additional Requirements | sezione narrativa | stato reale del repo |

### Fedeltà dell'inventario — verificata

**Ciò che regge.** Ogni FR porta la propria fonte, e i campioni controllati sono corretti:
FR1/FR3/FR17 corrispondono a `economia.md §12-13` letto direttamente (payout per-foto additivo,
menu a quattro voci, punteggi ereditati dalle fasi non rifatte); FR16/NFR5 riportano ADR-001
senza ammorbidirlo; NFR3 riporta i valori dello spike (`stretch_shrink = 2`,
`snap_resolution = 665`, `scanline_count = altezza/2`, CRT `256×192`) e **tutti e quattro
corrispondono al codice sul disco**.

**Due divergenze dalla fonte, entrambe corrette ma non dichiarate.**

- `economia.md §12` prevede il payout come **popup** `"+ L. XXX"`. Le epiche lo trasformano in
  evento diegetico sul CRT (UX-DR10) — scelta giusta e coerente con NFR20, ma la divergenza
  dalla fonte non è annotata.
- `economia.md §13` prevede che l'esplorazione consumi tempo **solo se il giocatore fa cose**.
  FR6 adotta un accumulatore puro: il tempo scorre anche se si sta fermi. Per un MVP che deve
  misurare l'attesa è la scelta corretta — stare fermi *deve* costare tempo, altrimenti l'attesa
  non è misurabile — ma anche questa divergenza non è dichiarata.

Nessuna delle due è un difetto. Sono annotate perché `docs/idea/` resta la fonte per le sette
fasi future, e chi tornerà a leggerla non troverà traccia del fatto che due decisioni sono state
sovrascritte di proposito.

### Requisiti dell'architettura che l'inventario non ha catturato

Sono la materia dei difetti critici C1 e C3 (§5):

- l'architettura elenca fra i sistemi core «Persistenza — save della notte, **wallet, flag
  acquisto**», ma l'unico modello dati che definisce è `NightRun`, che è **della notte**. Nessun
  FR e nessuna storia definiscono dove viva lo stato che attraversa le notti;
- la telemetria compare in tre punti dell'architettura con **tre collocazioni diverse** e nessun
  proprietario.

---

## 3. Epic Coverage Validation

### Matrice di copertura — 37 FR

Copertura verificata storia per storia contro i criteri di accettazione reali, non contro la
tabella riassuntiva.

| FR | Storia/e | Esito |
|---|---|---|
| FR1, FR2, FR5, FR6 | 2.1 | ✓ |
| FR3, FR4 | 2.6 | ✓ |
| FR7, FR8, FR9 | 1.1 | ✓ — FR8 chiude una decisione aperta dell'architettura (metrica = deriva residua) |
| FR10, FR11, FR12 | 2.2 | ✓ |
| FR13, FR14 | 2.3 | ✓ |
| FR15 | 2.3 + 3.1 | ⚠️ completo solo dopo 3.1 — vedi m7 |
| **FR16** | 1.1, 2.3 | ⚠️ **incompleto: manca in 2.2** — vedi C2 |
| FR17 | 2.4, 2.6 | ✓ |
| FR18 | 2.1, 2.6 | ✓ |
| FR19 | 2.4 | ✓ |
| FR20, FR21, FR22 | 2.5 | ✓ |
| FR23 | 1.2 (parziale) + 3.1 (completo) | ✓ |
| FR24 | 1.2 | ✓ |
| FR25 | 1.3 | ✓ |
| FR26, FR27 | 3.3, 3.4, 3.5 | ⚠️ il condotto di misura non regge gli AC — vedi C4 |
| FR28, FR29 | 3.2, 3.3, 3.4 | ✓ |
| FR30 | 2.7 | ✓ |
| **FR31** | 2.7 | ⚠️ **AC presente, modello dati inesistente** — vedi C1 |
| FR32, FR33 | 3.6 | ⚠️ nessun proprietario — vedi C3 |
| FR34, FR36, FR37 | 1.1 | ✓ |
| FR35 | 2.1 | ⚠️ collisione di tasti — vedi M3 |

### Statistiche

- **FR totali:** 37 · **FR con almeno una storia:** 37 · **copertura formale: 100 %**
- **FR con copertura sostanziale piena:** 32 su 37 (**86 %**)
- **FR nominalmente coperti ma non implementabili come scritti:** 5 (FR16, FR26/27, FR31, FR32/33)

**Nessun FR è stato dimenticato.** Il problema non è la copertura: è che cinque requisiti hanno
un criterio di accettazione senza il pezzo di design che lo rende eseguibile.

---

## 4. UX Alignment Assessment

### Stato del documento UX

**Non esiste, per decisione.** Il posto degli UX requirement è preso da 11 UX-DR dentro
`epics.md`, derivati da `economia.md §4`, da ADR-003 e dai valori dello spike.

**Questa è una scelta difendibile su questo progetto**, e non solo per economia: le interfacce
diegetiche *sono* il gameplay e *sono* la cosa dimostrabile per il portfolio (brief §Scope), e
sono già state validate sul campo — lo spike del 2026-08-21 ha verificato guardando, non
stimando, che il testo tecnico è leggibile a `256×192` una volta seduti. Un documento UX avrebbe
descritto ciò che il codice già dimostra.

### Allineamento UX-DR ↔ architettura — verificato

| UX-DR | Supporto architetturale | Esito |
|---|---|---|
| UX-DR1, UX-DR2 | ADR-003, `crt/crt_screen.gd::show_control()` | ✓ — l'API sul disco fa esattamente quello che serve |
| UX-DR3, UX-DR4 | `economia.md §4`, NFR10 | ✓ |
| UX-DR5 | spike: CRT `256×192`, leggibile da seduti | ✓ verificato sul campo |
| UX-DR6 | ADR-003 + `crt/desk_camera.gd` | ✓ **allineamento esatto**: la storia 1.3 chiede tween ≈0,5 s e FOV 42°; il codice ha `const TRANSITION := 0.5` e `const SEATED_FOV := 42.0` |
| UX-DR7 | nessun supporto specifico | ✓ ma è un requisito nuovo, non derivato: la lettura visiva della deriva si decide scrivendo la 1.1 |
| UX-DR8 | Pattern 2, regola 2 | ⚠️ l'architettura colloca il suono della sequenza **in cupola**, la storia 2.3 il segnale di fine **in stanza computer**. Sono due suoni diversi e non è una contraddizione, ma vedi m7 |
| UX-DR9, UX-DR10, UX-DR11 | NFR20, `debug/` | ✓ |

**11 su 11 hanno una storia.** La verifica della copertura regge.

### Il buco UX vero

**Il menu post-foto e il riepilogo dell'alba non hanno una casa** (M2). UX-DR1 vincola tutta la
UI non-pausa al CRT diegetico; FR3/FR4 richiedono che il menu si possa **riaprire** dopo «chiudi
ed esplora»; FR5 richiede che l'alba mostri il riepilogo anche a menu aperto. Nessuna storia dice
dove queste due interfacce compaiano né come ci si torni — mentre l'intero MVP è costruito sul
fatto che il giocatore, in quei momenti, **è fisicamente in un'altra stanza**.

Non è un dettaglio di presentazione: è la sola parte del gioco in cui la regola diegetica e il
loop di gioco si contraddicono, ed è anche la parte che un revisore di portfolio guarda.

---

## 5. Epic Quality Review

### Struttura delle epiche — conforme

| Verifica | Esito | Evidenza |
|---|---|---|
| Le epiche danno valore al giocatore, non sono milestone tecniche | ✅ | Tutte e tre sono scritte come esperienza: «il primo pezzo di mestiere», «una notte di lavoro», «l'attesa». L'epica 1 *potrebbe* leggersi come milestone tecnica (provare il seam) ma consegna una fase giocabile in una stanza percorribile: il valore c'è |
| Indipendenza delle epiche | ✅ con due eccezioni | Nessuna epica richiede una successiva **per funzionare**; ma due storie dell'epica 3 dipendono da pezzi che le epiche 1-2 non sono tenute a produrre (M1, C1) |
| Ordine motivato | ✅ | «L'epica 1 va per prima perché il seam si prova a buon mercato solo finché esiste una fase sola» — è un argomento di rischio, non di comodo, ed è corretto |
| Creazione dei dati quando servono | ✅ | Target in 2.2, committenti in 2.5, comfort e riparazioni in 3.2. Nessuna storia crea tutti i `.tres` in anticipo |
| Starter template | ✅ N/A corretto | L'architettura dichiara *nessuno starter template*; `project.godot` esiste già, con `gl_compatibility`, `default_texture_filter=0` e i quattro autoload nell'ordine `Game → Events → Log → Tuning` — **verificato sul file**. La 1.1 si fa carico della sostituzione del punto d'ingresso, che è il lavoro di setup realmente necessario |
| Formato As a / I want / So that | ✅ | 16 storie, 16 blocchi — contati |
| Criteri di accettazione BDD | ✅ | 80 `Given` / 80 `When` / 80 `Then` — contati |
| Placeholder residui | ✅ nessuno | `grep TODO/TBD/FIXME`: nessuna occorrenza |

### Qualità dei criteri di accettazione

Sono **sopra la media per specificità**: quasi tutti sono verificabili come atto concreto
(«verificabile con `git diff`», «`grep phases/` dentro `world/`», «verificato guardando e non
stimando», «il banco stampa…»). Tre eccezioni, in m4, m6 e M2.

Un pregio da non perdere in eventuali riscritture: diverse storie dichiarano la **conseguenza
accettata** invece di nasconderla — la 2.4 dichiara che nell'MVP l'immagine non si degrada con la
qualità e annota che, se la fase 3 risultasse gratuita, quella è la prima cosa da guardare. È
esattamente il tipo di annotazione che salva una decisione dal diventare un bug misterioso.

### Difetti trovati

#### 🔴 Critici — da chiudere prima di scrivere il codice che li tocca

**C1 — Non esiste un contenitore per lo stato che attraversa le notti.**
FR31 e la storia 2.7 richiedono che portafoglio e flag d'acquisto sopravvivano alla notte; la
storia 3.2 richiede che «il flag di acquisto sia persistito nel save». L'unico modello dati
definito è `NightRun`, che è **della notte** — la 2.7 lo dice esplicitamente: «i punteggi delle
fasi della notte precedente non lo sono: appartengono alla notte, non al giocatore». Non esiste
un `PlayerProfile` né in `core/` reale, né nell'albero dell'architettura, né in una storia. In
più:

- `core/night_run.gd` **non ha alcun campo per i flag d'acquisto** (ha `version`, `night_index`,
  `elapsed_min`, `phase_scores`, `wallet_lire`, `selected_target_id`, `photos`);
- `autoloads/game.gd::start_night()` fa `run = NightRun.new()`, quindi **azzera il portafoglio a
  ogni notte** — e le epiche classificano `autoloads/` come «keeper, gira pulito», senza rilevarlo.

*Conseguenza:* chi implementa la 2.7 inventa il modello di persistenza; chi implementa la 3.2 lo
trova inventato male, o lo re-inventa. È l'unica decisione di questo elenco che, presa tardi,
costringe a riaprire il save — cioè la cosa che NFR18 esiste per proteggere.

*Rimedio:* decidere ora dove vive lo stato persistente (es. `core/player_profile.gd`, `Resource`
separata salvata accanto alla `NightRun`) e dichiarare nella 2.7 che `autoloads/game.gd` va
modificato, togliendolo dalla lista dei keeper intoccati.

**C2 — La fase 6 (targeting) è l'unica delle tre senza sorgente di verità.**
FR16 e NFR5 dicono «ogni fase». L'architettura prevede `phases/targeting/sources/honest_catalog.gd/.tres`.
L'addendum §3 — il documento che *motiva* ADR-001 — nomina esplicitamente la bugia del targeting:
«un catalogo falso invece di quello vero». Ma nella storia 2.2 **la parola `truth` non compare**:
i criteri parlano di `.tres`, di `payload` e di boundary. La storia 2.3 (imaging) ha invece l'AC
corretto («viene da `truth.sample(...)` come per ogni altra fase, con una sola assegnazione»).
La tabella di Validation mappa FR16 alla sola storia 1.1, il che **nasconde il buco**.

*Conseguenza:* la fase 6 verrà scritta leggendo il catalogo direttamente. È esattamente la forma
che ADR-001 esiste per impedire, e la si scoprirà con tre fasi in piedi invece di una — cioè
proprio ciò che l'epica 1 serve a evitare.

*Rimedio:* una riga. Aggiungere a 2.2 l'AC gemello di quello della 2.3, con il nome che
l'architettura ha già scelto: `honest_catalog`.

**C3 — La telemetria, cioè lo strumento di misura dell'MVP, ha tre collocazioni contraddittorie
e nessun proprietario.**

| Documento | Dove dice che vive |
|---|---|
| architettura, albero delle cartelle | `autoloads/log.gd  # logging + telemetria di sessione` |
| architettura, Pattern 2 regola 3 | «la telemetria dell'attesa la raccoglie **la fase**, ascoltando `Events`» |
| epiche, storia 3.6 | «**non passa da `Log`**, perché non è un log» |

Nessuna delle tre dice chi apre il file, chi calcola `wait_total_min`, chi produce i tratti
`idle`, chi rileva `quit_mid_pose` — che richiede di intercettare la chiusura dell'applicazione
(`NOTIFICATION_WM_CLOSE_REQUEST`, `auto_accept_quit`), cosa che nessun documento menziona. La
storia 3.6 elenca i campi del file e non assegna un file di codice.

*Conseguenza:* l'MVP esiste per produrre quel file. È la parte che non può restare ambigua.

*Rimedio:* assegnare un proprietario esplicito — `autoloads/telemetry.gd` come quinto autoload è
la lettura più coerente con «non passa da `Log`» — e nominarlo nella 3.6.

**C4 — `Events.wait_activity(what: StringName)` non regge i criteri che ci poggiano sopra.**
La firma è già nel repo (`autoloads/events.gd`) e le epiche la citano come prova che «il condotto
della misura esiste prima delle attività che lo useranno». Ma con il solo `what`:

- la 3.3 richiede che «un rituale cominciato e mai concluso resti distinguibile da uno concluso»
  — con un solo argomento la distinzione è solo per parità di conteggio, e si rompe al primo
  abbandono;
- la 3.5 (cupola) emette **una sola volta**, quindi la parità non è nemmeno un'invariante del
  sistema;
- la 3.6 richiede `idle` **con la sua durata**, che richiede un inizio e una fine, mentre lo
  schema di telemetria dell'architettura è `{"t": 12.0, "what": "caffe"}`: nessuna durata,
  nessuna fase.

*Conseguenza:* il dato che le epiche stesse definiscono «il più importante del file» non è
ricavabile da ciò che il condotto trasporta.

*Rimedio:* oggi è una riga — `wait_activity(what: StringName, phase: StringName)` con
`&"started"`/`&"ended"`, o due signal distinti. Dopo tre storie è un refactor che tocca ogni
attività.

#### 🟠 Maggiori

**M1 — Nessuna storia richiede l'emissione degli eventi su cui altre storie poggiano.**
Le epiche citano in tutto tre eventi: `photo_sold`, `screen_registered`, `wait_activity`. Ma la
storia 3.5 richiede che la cupola sappia di una sequenza in corso «**tramite `Events`**, mai
interrogando la fase: `world/` non conosce `phases/`». I signal adatti esistono già in
`autoloads/events.gd` (`phase_started`, `phase_finished`, `dawn_reached`, `hour_passed`) ma
**nessun criterio di accettazione delle epiche 1-2 richiede di emetterli**. Chi implementa 2.1 e
2.3 non ha motivo di farlo; chi implementa 3.5 li trova assenti e o viola il boundary o torna
indietro. È una dipendenza in avanti reale, dello stesso tipo di quella che l'autovalutazione ha
già corretto per il terminale.

**M2 — Il menu post-foto e il riepilogo dell'alba non hanno una casa diegetica.** Vedi §4.
Decidere: menu sul CRT (e allora «riaprire il menu» significa tornare a sedersi, che è una scelta
di design legittima ma va detta), oppure un'eccezione dichiarata a UX-DR1.

**M3 — Collisione di tasti su `F1`-`F4`.** FR35 e la storia 2.1 assegnano `F1`-`F4` al controllo
del tempo. `main.gd` oggi usa `F1`/`F2` per la risoluzione del mondo, `F3` per il filtro di
upscale, `F5`/`F6`/`F7` per il jitter — **verificato sul file** — e la storia 1.1 richiede che
quei comandi «non spariscano: migrano sotto `debug/`». Nessun documento assegna loro nuovi tasti.
Due implementazioni divergeranno, e una perderà gli strumenti con cui i valori PS1 sono stati
tarati.

**M4 — `crt/crt_screen.tscn`, dichiarato «keeper», viola già NFR15.** Il `SubViewport` ha
`render_target_update_mode = 4`, cioè `UPDATE_ALWAYS`, mentre NFR15 dice che i `SubViewport` non
usano `UPDATE_ALWAYS` per default perché «ogni schermo CRT è un render pass in più, ed è il costo
reale del progetto». Nessuna storia lo corregge. È una riga, ma è l'unico requisito di performance
del progetto e nasce violato dal codice che le epiche marcano come acquisito.

**M5 — Doppia registrazione dello schermo.** `crt/crt_screen.gd::_ready()` emette **già**
`Events.screen_registered.emit(self)`. La storia 1.2 chiede che sia **il monitor**
(`world/interactables/`) a emettere `Events.screen_registered` con il proprio `CrtScreen` — com'è
scritto anche nell'esempio dell'architettura. Applicando la storia alla lettera si ottengono due
registrazioni per schermo, e `night_session` connette l'ultima che arriva. Va scelto chi emette;
il codice esistente ha già scelto.

**M6 — La storia 1.1 porta zavorra che non è ciò che la rende densa per una buona ragione.**
La 1.1 ha 8 blocchi `Given` e contiene: la fase polare, la metrica di qualità mai decisa, la
sorgente onesta, la sorgente bugiarda, l'iniettore `F9`, l'overlay `F12`, la cancellazione di
`spike/`, la sostituzione del punto d'ingresso, la migrazione dei comandi di taratura e il banco
di collaudo.

**L'accoppiata fase 3 + iniettore `F9` non va toccata**: è argomentata, ed è l'argomento giusto —
il seam si prova a buon mercato solo con una fase sola. Ma *la cancellazione dello spike e la
sostituzione del punto d'ingresso* non c'entrano con la prova del seam: sono lavoro preparatorio
che allunga la prima storia del progetto e ne ritarda il segnale.

*Rimedio suggerito, che non separa la fase dall'iniettore:* una storia **1.0** «il punto
d'ingresso non è più lo spike» che sostituisce `main.tscn`/`main.gd`, migra i comandi di taratura
sotto `debug/` (chiudendo anche M3) e allestisce `tests/test_bench.tscn` vuoto. La 1.1 resta
fase + `F9` + metrica + overlay.

#### 🟡 Minori

**m1 — Deriva fra albero dell'architettura e repo reale.** L'architettura elenca
`crt/shaders/{crt_curvature,scanlines}.gdshader`; sul disco c'è un solo `crt/shaders/crt.gdshader`.
E l'albero chiama la sorgente della fase polare `honest_bubble.gd/.tres` — che è il nome della
*livella* (fase 1, fuori scopo) — mentre il Pattern 1 e la storia 1.1 usano `honest_drift`.
`project-context.md` ripete `honest_bubble` come esempio di naming. Chi implementa la 1.1 legge
due nomi per la stessa cosa.

**m2 — La tabella «keeper — verificato sul repo, non assunto» è incompleta.** Elenca tre file in
`spike/`; ce ne sono quattro (manca `spike_room.gd`). Il resto della tabella è corretto, incluso
il rilievo che `core/save_manager.gd` manca. Segnalato solo perché la tabella si presenta come
verificata.

**m3 — `world/observatory.tscn` e `PhaseHost` non hanno una storia che li crea.** Le stanze
nascono in 1.2 e 3.1, ma la scena contenitore dell'osservatorio non è mai assegnata; la 2.3 assume
`PhaseHost` come già esistente, mentre la 2.1 — che costruisce l'orchestratore — non lo nomina.

**m4 — Pausa e impostazioni non sono di nessuno.** `ui/` compare fra le cartelle da creare e
UX-DR1 le riserva pausa e impostazioni, ma nessuna storia crea una pausa né il `user://settings.cfg`
previsto dall'architettura. Conseguenza immediata: l'AC della 2.1 «la pausa ferma il tempo
davvero» **non è verificabile nella sua storia**, perché non c'è una pausa da premere.

**m5 — Il tipo del dato foto non è deciso.** `core/night_run.gd` dichiara
`photos: Array[Dictionary]`; l'architettura prevede `photo/photo.gd`. La 2.4 e la 2.5 non
scelgono.

**m6 — Un AC della 1.3 non è verificabile nella propria storia.** «L'orchestratore — quando
esisterà — chiama `show_control(null)` prima di liberare la fase» è un obbligo futuro travestito
da criterio di accettazione. Collegato: la 1.3 non dice **chi** chiama `crt.show_control(...)`
prima che `night/` esista. Per i boundary non può essere `world/` né `crt/`; resta `main.gd`, ma
non è scritto — e la 1.1 aveva invece dichiarato con precisione il proprio ponte temporaneo.

**m7 — FR15 contro la storia 3.5.** FR15 chiede un segnale di fine sequenza percepibile **da
un'altra stanza**; la 3.1 accetta «ovattato dalla cucina e **appena** dalla cupola» — cioè appena
percepibile proprio dove la 3.5 vuole che il giocatore stia, ed è l'attività che l'epica 3 indica
come test più diretto del pilastro. Vale la pena decidere se il segnale debba portare fin lassù.

---

## 6. Ricontrollo della sezione «Validation» di `epics.md`

Trattata come non verificata e ricontrollata voce per voce.

| Voce autovalutata | Esito del ricontrollo |
|---|---|
| «16 storie, 16 nel formato As a/I want/So that, 16 blocchi di criteri, **80 blocchi `Given`**» | ✅ **vero** — contato: 16/16/16, 80 `Given`, 80 `When`, 80 `Then` |
| «**37 FR su 37 coperti**» | ✅ vero come mappatura formale |
| «nessuno è coperto da un solo accenno: ogni FR ha almeno un criterio verificabile» | ❌ **falso per FR16.** FR16 è cross-cutting («ogni fase»); è esercitato in 1.1 e 2.3 ma **non in 2.2**. La tabella lo mappa alla sola 1.1, il che rende invisibile il buco (C2). Da sola, questa riga è il motivo per cui l'autovalutazione non basta |
| «11 UX-DR su 11 coperti» | ✅ vero. UX-DR1 è temporaneamente violato nella 1.1 (ponte senza mondo 3D) ma la violazione è **dichiarata e datata**, il che è la forma corretta |
| «Starter template — N/A, verificato» | ✅ **vero, riverificato sul repo.** `project.godot` esiste con renderer, filtro e i quattro autoload nell'ordine giusto |
| «Risorse dati create solo dove servono» | ✅ vero, ricontrollato: target in 2.2, committenti in 2.5, comfort/facilities in 3.2 |
| «**Dipendenze in avanti — ✅ dopo correzione**» | ⚠️ **da ✅ a parziale.** La correzione dichiarata (2.5 non dipende più dal terminale della 3.2) è **reale e verificata**. Ma restano due dipendenze in avanti non rilevate: la 3.5 dipende da eventi che nessuna storia delle epiche 1-2 è tenuta a emettere (M1), e la 3.2 dipende da un modello di persistenza che la 2.7 non definisce (C1) |
| «Churn sui file — ✅ con motivazione» | ✅ l'argomento regge: l'epica 3 aggiunge file accanto a quelli dell'epica 1 senza modificarli, e il consolidamento è stato considerato e rifiutato con una ragione valida (l'epica 1 non può esistere senza una stanza) |
| «Placeholder residui — ✅ nessuno» | ✅ vero, verificato con `grep` |
| «Problemi trovati e risolti durante la validazione» (3 voci) | ✅ **tutte e tre reali e realmente risolte nel testo.** Il payout della 2.5 è diegetico e non passa dal terminale; la 1.1 dichiara il ponte temporaneo; la 2.4 dichiara la semplificazione sulla degradazione dell'immagine e ne annota la conseguenza |

**Giudizio complessivo sull'autovalutazione.** È onesta e in gran parte accurata — non è una
spunta di comodo: ha trovato e corretto tre problemi veri, e i conteggi sono esatti. Il suo limite
è strutturale e prevedibile: **verifica ciò che il documento dice di sé, non ciò che il documento
tace.** Tutti i critici di questo report stanno in ciò che tace — un modello dati mai definito, un
proprietario mai assegnato, una firma di signal che non regge, un FR cross-cutting mappato come se
fosse locale.

---

## 7. Summary and Recommendations

### Stato di prontezza complessivo

## ⚠️ NEEDS WORK — a poca distanza da READY

**Il giudizio va letto con la giusta proporzione.** Architettura ed epiche sono coerenti su tutto
ciò che conta: i tre ADR sono rispettati dalle storie, i boundary fra cartelle sono verificabili
con `grep` e le storie li verificano davvero, i valori dello spike sono nel codice e nei requisiti
con gli stessi numeri, la copertura formale è completa, l'ordine delle epiche è motivato dal
rischio e non dal comodo, e la prima storia è la cosa giusta al posto giusto.
**Nulla di ciò che segue rimette in discussione l'architettura o la scomposizione in epiche.**

I quattro difetti critici sono tutti dello stesso tipo: **un criterio di accettazione esiste, il
pezzo di design che lo rende eseguibile no.** Sono decisioni piccole, non lavoro grosso — ma tre
su quattro costano molto di più se prese dopo, perché toccano il save (C1), il condotto di misura
(C4) e il vincolo non negoziabile del progetto (C2).

### Difetti per severità

| Severità | N. | Quali |
|---|---|---|
| 🔴 Critici | 4 | C1 persistenza cross-notte · C2 fase 6 senza sorgente di verità · C3 telemetria senza proprietario · C4 firma di `wait_activity` insufficiente |
| 🟠 Maggiori | 6 | M1 eventi mai emessi · M2 menu e riepilogo senza casa diegetica · M3 collisione `F1`-`F4` · M4 `crt_screen.tscn` viola NFR15 · M5 doppia registrazione schermo · M6 zavorra nella 1.1 |
| 🟡 Minori | 7 | m1…m7 |

### Prossimi passi, nell'ordine in cui conviene farli

1. **Prima di scrivere una riga: chiudere C2.** È una riga di AC nella storia 2.2
   (`honest_catalog`, il nome che l'architettura ha già scelto). Costa un minuto adesso e vale una
   fase riscritta dopo.
2. **Prima di scrivere una riga: chiudere C4.** Cambiare la firma di `wait_activity` in
   `autoloads/events.gd` finché nessuno la usa ancora, e aggiornare 3.3/3.5/3.6 di conseguenza.
3. **Prima della storia 2.7: chiudere C1.** Decidere dove vive lo stato che attraversa le notti,
   dichiarare che `autoloads/game.gd` va modificato, e toglierlo dai keeper intoccati.
4. **Prima della storia 3.6: chiudere C3.** Assegnare un proprietario alla telemetria e
   riconciliare le tre collocazioni nell'architettura.
5. **Insieme al punto 3: chiudere M1**, aggiungendo alla 2.1 e alla 2.3 l'obbligo di emettere
   `phase_started`/`phase_finished` e `dawn_reached` sul bus. Sblocca la 3.5 senza che nessuno
   debba violare un boundary.
6. **Decidere M2** — menu post-foto e riepilogo dell'alba sul CRT, oppure eccezione dichiarata a
   UX-DR1. È la decisione con più conseguenze sul gioco fra quelle elencate qui.
7. **Valutare M6**: estrarre una storia 1.0 per il punto d'ingresso, che assorbe anche M3 e
   accorcia il tempo che separa oggi dalla prima prova del seam. **Fase 3 e iniettore `F9`
   restano insieme.**
8. I minori si possono chiudere lungo la strada. `m1` conviene farlo subito perché tocca
   `project-context.md`, che è il file che gli agenti leggono per primo.

### Cosa non è stato trovato — vale quanto ciò che è stato trovato

- **Nessun FR dimenticato.** 37 su 37 hanno una storia.
- **Nessuna epica tecnica travestita da epica.**
- **Nessuna storia sovradimensionata** oltre la 1.1, che lo è per scelta argomentata.
- **Nessun placeholder, nessuna sezione abbozzata, nessun numero inventato**: dove i numeri sono
  segnaposto (curva a scaglioni, moltiplicatori dei committenti) le epiche lo dichiarano e
  vietano esplicitamente di calibrarli ora.
- **Nessuna deriva di scopo.** Il documento resiste a `docs/idea/`, che descrive un gioco molto
  più grande, e dichiara che ciò che non compare è fuori scopo per costruzione.
- **Nessuna contraddizione con i tre ADR.** Sono il punto più solido dell'intero impianto.

### Nota finale

Questa verifica ha esaminato **17 difetti su 3 categorie** (copertura, allineamento
architettura ↔ epiche, qualità di epiche e storie), riverificando sul repository reale ogni
affermazione sullo stato del codice e ricontrollando voce per voce l'autovalutazione contenuta in
`epics.md`. I quattro critici vanno chiusi prima di toccare il codice che riguardano; i sei
maggiori vanno decisi, non necessariamente subito. Con C2 e C4 chiusi — venti minuti di editing su
due documenti — **la storia 1.1 è pronta per essere implementata così com'è**.
