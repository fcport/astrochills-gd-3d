---
title: 'Game Architecture'
project: 'astrochills-gd-3d'
date: '2026-08-21'
author: 'Federico'
version: '1.0'
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9]
status: 'complete'
engine: 'Godot 4.7.2 (Compatibility)'
platform: 'PC Windows'
scope: 'MVP — una notte, tre fasi (3 allineamento polare, 6 targeting, 10 imaging) + stacking + vendita + gestione osservatorio durante la posa'

# Source Documents
gdd: null
epics: null
brief: '_bmad-output/planning-artifacts/briefs/brief-astrochills-gd-3d-2026-08-21/brief.md'
addendum: '_bmad-output/planning-artifacts/briefs/brief-astrochills-gd-3d-2026-08-21/addendum.md'
---

# Game Architecture

## Executive Summary

L'architettura di **Astrochill** è progettata per Godot 4.7.2 (renderer Compatibility) su
PC Windows, per un MVP che valida una sola ipotesi: *l'attesa è piacevole*.

**Le decisioni che la reggono:**

- **Ogni fase espone il proprio stato dietro un `PhaseTruthSource` iniettabile.** È il
  vincolo non negoziabile del progetto: nell'MVP quella indirezione dice sempre la verità,
  ma esiste — e la fase non cambierà mai quando comincerà a mentire. (ADR-001)
- **Una scena autonoma per fase**, con contratto comune `Phase`. Le sette fasi mancanti
  diventano contenuto additivo invece di modifiche a un monolite. (ADR-002)
- **Interfacce diegetiche su `SubViewport`** montate su mesh 3D, con la camera che transita
  alla scrivania. È il grosso del gameplay e la cosa dimostrabile per il portfolio. (ADR-003)
- **La fase di imaging non blocca:** resta viva mentre il giocatore è in un'altra stanza,
  perché l'attesa deve essere reale per poter essere misurata.
- **Il ritmo della notte vive in un file di tuning con override esterno**, perché è la
  variabile sperimentale dell'MVP e va cambiata senza ricompilare.

**Struttura:** organizzazione feature-first per il gameplay, per tipo per il resto, con
9 sistemi core e regole di dipendenza esplicite.

**Pattern:** 3 novel e 6 standard, ciascuno con codice concreto, più 9 regole di
consistenza verificabili.

**Pronto per:** inizializzazione del progetto e implementazione.

---

## Document Status

**Completo.** Prodotto tramite il GDS Architecture Workflow, 9 step su 9.

**Nota sul GDD:** assente. Brief + addendum sono stati assunti come sorgente di design
autoritativa su decisione esplicita di Federico. L'ambito è MVP: le sette fasi
rimanenti, storia, anomalie, rotture, metanarrazione, rete di osservatori, esplorazione
esterna e calibrazione economica sono fuori scopo.

**Steps Completed:** 9 of 9

---

---

## Project Context

### Game Overview

**Astrochill** — creepy-cozy work simulator in prima persona. Osservatorio astronomico
sul Monte San Lorenzo, Montegrimano (PU), 1999. Il giocatore esegue la procedura reale
dell'astrofotografia CCD amatoriale, vende le foto — e aspetta.

### Technical Scope

| | |
|---|---|
| **Piattaforma** | PC Windows, target unico |
| **Engine** | Godot 4.7.2, renderer Compatibility |
| **Genere** | work simulator in prima persona, a sessioni notturne |
| **Team** | uno sviluppatore, non artista 3D né musicista |
| **Arte** | 3D low-poly, estetica PS1 (nearest filtering, vertex snapping, nebbia) |
| **Rete** | nessuna — single player offline. L'intera categoria di decisioni di networking è fuori scopo. |

### MVP Scope

Una notte completa con **3 fasi delle 10 previste**:

| Fase | Cosa testa |
|---|---|
| 3 — allineamento polare | la pazienza |
| 6 — targeting | la scelta |
| 10 — sequenza di imaging | **l'ipotesi** — il tempo morto |

Più **stacking** (la rivelazione), **vendita** (il payout) e la **gestione leggera
dell'osservatorio durante la posa** — che non è un extra: è lo strumento di misura.

**Ipotesi da validare: _l'attesa è piacevole_.**
**Criterio di superamento:** giocare tre notti di fila perché va, non per collaudo.

**Fuori scopo:** le altre 7 fasi, storia, anomalie, rotture, metanarrazione, rete di
osservatori, esplorazione esterna, calibrazione economica.

### Core Systems

| Sistema | Complessità | Fonte |
|---|---|---|
| Framework delle fasi — la fase come unità autonoma e sostituibile | **alta / novel** | addendum §3 |
| Indirezione della sorgente di verità — lo stato della fase dietro un provider | **alta / novel** | addendum §3 — vincolo non negoziabile |
| UI diegetiche CRT — `Control` su `SubViewport` + shader sul monitor 3D | **alta** | brief §Scope — la cosa dimostrabile per il portfolio |
| Orchestrazione della notte — setup una volta, loop foto, menu post-foto, alba | media | economia §12 |
| Tempo di gioco e alba — orologio, consumo minuti, fine notte | media | economia §13, prototipo `util/time.js` |
| Pipeline foto — quality score per fase → aggregato → stack → tier → payout | media | economia §12, prototipo `util/photos.js` |
| Osservatorio durante la posa — movimento 1ª persona, interazioni, comfort/cura | media | brief §pilastro 2, economia §5-6 |
| Persistenza — save della notte, wallet, flag acquisto | bassa-media | prototipo `util/save.js` |
| Contenuto data-driven — catalogo target, committenti, upgrade | bassa | prototipo `data/*.js` |

### Complexity Drivers

**1. L'indirezione della sorgente di verità.** Nessun pattern standard copre «questa
meccanica deve poter essere alimentata dal tempo invece che dall'input, senza
riscriverla». È il vincolo non negoziabile del progetto e va risolto esplicitamente
nello step 7.

**2. L'interfaccia diegetica _è_ il gameplay.** Non è UI sopra il gioco: è il gioco
dentro il mondo 3D. Cambia dove vive l'input, come si gestisce il focus, cosa
significa «pausa».

**3. L'attesa come loop di prima classe.** L'MVP deve risultare piacevole _mentre non
succede niente_. Architetturalmente: la fase 10 non blocca — cede il controllo al mondo
e resta viva in sottofondo.

### Technical Risks

**Alto — il monolite delle fasi.** Nel prototipo Phaser `src/scenes/ImagingScene.js` è
un unico file di 3.822 righe con tutte e dieci le fasi: `PHASES[]` come array di
metadati, `_computePhaseScore(key)` come `switch`, e ogni fase che scrive su campi della
scena condivisa (`this.level`, `this.focus`, `this.autoguide`). Per validare il design
in 2D è stata la scelta giusta. Ma è esattamente la forma che rende **irrealizzabile**
il vincolo di indirezione: una fase che vive come metodo di una scena condivisa non può
avere una sorgente di verità propria e sostituibile. Da chiudere negli step 6-7.

**Medio — Compatibility + SubViewport + shader.** Compatibility è la scelta giusta per
PS1 e per la compatibilità hardware, ma i limiti su viewport annidati e shader vanno
verificati, non assunti. Ogni schermo CRT è un render pass in più: vanno aggiornati solo
quando serve.

### Decisioni di design aperte (tracciate, non bloccanti)

~~**La fase 3 non ha una metrica di qualità.**~~ **CHIUSA il 2026-08-22, storia 1.1.**
La metrica è la **velocità di deriva residua**, mediata sugli ultimi `polar_score_window_sec`
secondi di osservazione e mappata linearmente su 0-100 con `polar_max_drift_rate` come
peggior caso. Non dipende né dal tempo impiegato né dal numero di correzioni: punirli
scoraggerebbe il prendersi tempo, che è l'unica cosa che la fase più meditativa del gioco
chiede davvero. La media su una finestra, e non il valore istantaneo, è ciò che impedisce di
azzerare le viti un attimo prima di chiudere. La deriva usata è quella restituita da `truth`,
mai ricalcolata dalle regolazioni. Implementata in `phases/polar/phase_polar.gd::score()`.

**La durata della notte non è decisa.** Il prototipo usa 15 minuti reali → 9 ore in-game
(`util/time.js`); il brief parla di sessioni di circa un'ora. Se l'ipotesi da validare è
_l'attesa è piacevole_, la durata dell'attesa **è la variabile sperimentale dell'MVP**.
Requisito architetturale che ne deriva: il ritmo del tempo deve vivere in un file di
tuning modificabile senza toccare codice, altrimenti non è possibile provare tre valori
diversi in una serata.

---

## Engine & Framework

### Selected Engine

**Godot 4.7.2 stable** (rilasciata il 18 agosto 2026) — renderer **Compatibility**
(OpenGL 3.3 / ES 3.0).

**Rationale:** 3D con export Windows a costo zero, GDScript adatto a uno sviluppatore
solo, e `SubViewport` come meccanismo nativo per gli schermi diegetici — che è dove vive
il grosso del gameplay. Compatibility perché nessuna delle feature che perde serve
all'estetica PS1, e il requisito hardware minimo si abbassa parecchio.

Nessuna valutazione di engine alternativi: la decisione era già presa e regge.

### Project Initialization

**Nessuno starter template.** Nel mondo Godot non esiste un equivalente di
`create-next-app` che convenga; i boilerplate in circolazione portano convenzioni
estranee a un progetto con vincoli molto specifici. Si parte da un progetto Godot vuoto;
la struttura delle cartelle è definita nello step 6.

### Engine-Provided Architecture

| Categoria | Soluzione | Note |
|---|---|---|
| Rendering | Compatibility (OpenGL 3.3 / ES 3.0) | scelto, non default |
| Scene management | `SceneTree` + `PackedScene` + istanziazione | |
| UI | nodi `Control` + `Theme` | |
| **Render-to-texture** | `SubViewport` + `ViewportTexture` | **il meccanismo degli schermi CRT** |
| Audio | `AudioStreamPlayer` + bus di `AudioServer` | |
| Input | `InputMap` con azioni nominate | |
| Fisica 3D | `CharacterBody3D` | serve pochissimo: si cammina, non si combatte |
| Serializzazione | `Resource` + `.tres`, oppure `ConfigFile` / JSON | **quale, è decisione dello step 4** |
| Build | export template + preset | |

### Vincoli del renderer Compatibility

Verificati sulla [documentazione ufficiale 4.7](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html).

**Non disponibili:** `CompositorEffect`, compute shader, accesso a `RenderingDevice`,
buffer normal/roughness, tutti gli antialiasing post-process (TAA, FXAA, SMAA, MSAA 2D),
debanding, SSR, SSIL, SDFGI, VoxelGI, fog volumetrica, depth of field, sub-surface
scattering, decal, PCSS, particle trails, VRS, HDR.

**Quasi tutto è irrilevante o desiderabile:** il PS1 non ha global illumination, e
l'aliasing crudo *è* l'estetica. Vertex snapping e affine texture mapping sono shader di
vertice/frammento per-materiale — funzionano ovunque. La nebbia a chiudere le distanze è
la fog dell'`Environment`, supportata. Il nearest filtering è un'impostazione di import.

**L'unico costo reale:** un post-effect a schermo intero (dithering, riduzione a 15 bit,
resa a bassa risoluzione) su Forward+ si farebbe con un `CompositorEffect`, e in
Compatibility quella strada è chiusa.

**Strada scelta:** renderizzare il mondo 3D dentro un `SubViewport` a bassa risoluzione e
mostrarlo scalato con nearest. È anche la tecnica PS1 più fedele — il vincolo spinge
nella direzione giusta.

**Spike da fare:** verificare il comportamento di `hint_screen_texture` in uno shader
`spatial` sotto Compatibility. Necessario solo se si sceglie la strada alternativa
(`CanvasLayer` + `ColorRect` full-screen). Con la strada del SubViewport la domanda non
si pone.

**ESITO DELLO SPIKE — 2026-08-21: superato.**

Verificato su OpenGL 3.3 Compatibility (NVIDIA RTX 3080). Entrambe le strade critiche
reggono:

- **Mondo in `SubViewport` a bassa risoluzione riscalato con nearest** — funziona. Punto
  scelto dopo confronto a schermo: `stretch_shrink = 2`, cioè 640×360 interni su finestra
  1280×720.
- **CRT diegetico: `SubViewport` su mesh 3D con shader di curvatura, scanline, aberrazione
  e vignettatura** — funziona, e il testo tecnico è leggibile a 256×192 **una volta
  seduti alla scrivania**.
- **Vertex snapping PS1** — funziona. Valore scelto: `snap_resolution = 665`, un jitter
  sub-pixel deliberatamente contenuto.

**Due lezioni che l'architettura non prevedeva:**

1. **Le scanline vanno derivate dalla risoluzione, non scelte.** Un numero di scanline
   pari all'altezza del viewport produce un ciclo di seno per pixel: non righe, rumore di
   campionamento. `crt_screen.gd` ora calcola `altezza / 2`.
2. **ADR-003 non è un comfort, è un requisito di leggibilità.** Senza la transizione alla
   scrivania il CRT è visto da lontano: la sua texture viene *rimpicciolita*, con filtro
   nearest e senza mipmap, e il risultato è illeggibile. La postazione seduta non serve
   solo all'immersione — è ciò che rende il testo leggibile. Implementata in
   `crt/desk_camera.gd`.

### Remaining Architectural Decisions

L'engine non decide nulla di ciò che conta per questo progetto:

1. Come si struttura una fase — il framework
2. **L'indirezione della sorgente di verità** — il vincolo non negoziabile
3. Dove vive lo stato della notte — autoload globale o posseduto da una scena
4. Come si renderizzano gli schermi CRT e come passa il focus di input fra mondo 3D e schermo
5. Come scorre il tempo di gioco e chi lo possiede
6. Formato di salvataggio e cosa si salva davvero
7. Dove vivono i numeri di tuning — incluso il ritmo della notte, variabile sperimentale dell'MVP
8. Come comunicano i sistemi — signal diretti o event bus
9. GDScript o C#
10. Struttura delle cartelle

### AI Tooling (MCP Servers)

Raccomandati, **non ancora installati** (nessun `.mcp.json` sul progetto). La scelta
resta aperta: la sezione documenta la raccomandazione, non un'installazione avvenuta.

| MCP | Repo | Install | Requisiti |
|---|---|---|---|
| **GoPeak** | [HaD0Yun/Gopeak-godot-mcp](https://github.com/HaD0Yun/Gopeak-godot-mcp) — risulta rinominato in `Doyunha-Gopeak`, il vecchio URL redirige | `npx -y gopeak`, nessun plugin Godot | Godot 4.x, Node.js |
| **Context7** | [upstash/context7](https://github.com/upstash/context7) | `claude mcp add context7 -- npx -y @upstash/context7-mcp` | Node.js |

**GoPeak** — attivo, ~95 strumenti sul ciclo edit → run → inspect → fix: gestione scene,
LSP GDScript, debugger DAP, cattura screenshot, injection di input, introspezione
ClassDB, libreria asset CC0. Con un progetto che è per metà UI dentro viewport, far
*vedere* la scena all'agente invece di fargliela descrivere è una differenza concreta.

**Context7** — documentazione Godot corrente invece della memoria del modello. Con la
4.7.2 uscita tre giorni fa, non è un dettaglio.

---

## Architectural Decisions

### Decision Summary

| Categoria | Decisione | Versione | Rationale |
|---|---|---|---|
| Engine | Godot, renderer Compatibility | 4.7.2 stable | vedi § Engine & Framework |
| Linguaggio | **GDScript** | — | Nessun carico CPU-bound; `@export` e `Resource` senza attrito; iterazione immediata |
| Struttura fase | **Una scena autonoma per fase**, contratto `class_name Phase` | — | Le 7 fasi mancanti si aggiungono senza toccare le 3 esistenti. È anche la precondizione dell'indirezione |
| **Indirezione della verità** | **`PhaseTruthSource` come `Resource`**, iniettata via `@export`, interrogata con `sample(input, delta)` | — | Sostituzione a livello di dati; testabile senza `SceneTree`; lo stato della bugia è salvabile perché è già una `Resource` |
| Stato della notte | **`NightRun` (`Resource`) tenuta da un autoload sottile `Game`** | — | Dati puri e isolati, accesso comodo. Si incastra con il save e con la sorgente di verità |
| Schermi CRT | **`SubViewport` + camera che transita alla scrivania** | — | Diegetico senza scrivere la catena raycast → UV → `push_input`. Aggiornabile al raycast senza toccare le fasi |
| Tempo di gioco | **Accumulatore su `_process`**, `rate` da tuning | — | Rispetta pausa e `Engine.time_scale`: la notte ×10 per collaudare è gratis |
| Comunicazione | **Misto con regola scritta**: signal diretti in gerarchia, `EventBus` per fatti di notte | — | Il bus senza regola diventa una discarica in tre mesi |
| Persistenza | **`ResourceSaver` su `.tres`** + `ConfigFile` per le impostazioni | — | `NightRun` è già `Resource`. Il save è leggibile — durante la validazione conta |
| Numeri di tuning | **`TuningProfile.tres` + override `.cfg` esterno** | — | La durata della notte si cambia in una build già esportata |
| Caricamento asset | **Scene-based con `preload`** | — | Un edificio, asset PS1: sta in memoria |

### State Management

**Approccio:** `NightRun` come `Resource` di soli dati (indice notte, minuti trascorsi,
punteggi delle fasi, target selezionato, portafoglio, foto della notte), tenuta da un
autoload sottile `Game` che la espone e ne gestisce il ciclo di vita.

`Game` è un portachiavi, non un cervello: non contiene logica di gioco. La logica sta
nelle fasi e nell'orchestratore della notte. `NightRun` si costruisce con `NightRun.new()`
in un test, senza caricare alcun autoload.

### Data Persistence

**Save system:** `ResourceSaver.save()` di `NightRun` su `.tres` in `user://saves/`.
Campo `version: int` presente **dal primo giorno**, con un `_migrate()` chiamato al load
anche quando è vuoto.

**Impostazioni:** `ConfigFile` separato — risoluzione, volumi, binding. Non sta nel save
della partita.

**Nota:** un `.tres` è testo modificabile dal giocatore. Per un single player offline
cozy non è un problema; è anzi un vantaggio durante la validazione, perché il save si
apre e si legge.

### Asset Management

**Strategia:** `preload()` per ciò che serve sempre (scene delle fasi, UI), `load()` per
il resto, caricamento per scena. Nessun caricamento asincrono: il progetto non ha il
volume che lo giustifichi, e lo stato asincrono si paga ovunque.

### Time

Un nodo che processa accumula `run.elapsed_min += delta * tuning.game_min_per_sec`.
L'alba è raggiunta quando `elapsed_min >= tuning.night_length_min`.

Conseguenza voluta: `Engine.time_scale = 10.0` accelera la notte per il collaudo senza
toccare una riga di logica, e la pausa ferma davvero il tempo.

### Communication

**La regola:** se sai chi ascolta ed è uno solo → **signal diretto**. Se non lo sai, o
sono più di due → **`EventBus`**.

| Diretto | Bus |
|---|---|
| `phase.finished(result)` → orchestratore | `photo_sold(photo, lire)` |
| `phase.score_changed(v)` → HUD della fase | `hour_passed(h)` |
| interazione → oggetto interagibile | `dawn_reached()` |

### Tuning

`TuningProfile` è una `Resource` versionata in git (`data/tuning.tres`). All'avvio, se
esiste `user://tuning_override.cfg`, i suoi valori sovrascrivono il profilo caricato.

**Perché l'override esterno:** l'MVP esiste per stabilire quanto deve durare l'attesa.
Senza override, ogni valore da provare richiede l'editor; con l'override, una build
esportata si tara sul posto — anche in mano a qualcun altro.

---

## Le tre regole che non si negoziano

**1. Una fase non legge mai il proprio stato grezzo.** Se `phase_polar.gd` calcola dove
sta la bolla partendo dalle viti, il vincolo è già rotto — non importa quanto sia pulito
il resto. La fase chiede sempre a `truth`.

**2. Ogni `PhaseTruthSource` si inietta con `.duplicate()`** (o
`resource_local_to_scene = true`). Le `Resource` in Godot sono condivise per riferimento:
due fasi che caricano lo stesso `.tres` ricevono **la stessa istanza**. È un bug che costa
un pomeriggio e non si manifesta finché non ci sono due fasi in scena insieme.

**3. La regola dell'`EventBus`** sopra, scritta qui e non lasciata all'intuito.

---

## Architecture Decision Records

### ADR-001 — L'indirezione della sorgente di verità

**Contesto.** L'addendum §3 stabilisce che ogni fase deve poter cambiare la propria
sorgente di verità senza essere riscritta. Il test concreto: la bolla della livella deve
poter smettere di essere `f(viti)` e diventare `f(tempo)`.

**Decisione.** Contratto `PhaseTruthSource extends Resource` con un solo metodo,
`sample(input, delta) -> Variant`. La fase dichiara `@export var truth: PhaseTruthSource`
e non calcola mai il proprio stato osservabile. Nell'MVP si inietta sempre una sorgente
onesta.

```gdscript
class_name PhaseTruthSource extends Resource
func sample(input: Dictionary, delta: float) -> Variant:
    return null

# MVP — dice sempre la verità
class_name HonestBubbleSource extends PhaseTruthSource
func sample(input: Dictionary, _delta: float) -> Variant:
    return _from_screws(input.screws)

# Più avanti — stessa meccanica, altra sorgente
class_name DriftingBubbleSource extends PhaseTruthSource
var _t := 0.0
func sample(_input: Dictionary, delta: float) -> Variant:
    _t += delta
    return _from_time(_t)

# La fase: identica nei due casi, per sempre
@export var truth: PhaseTruthSource
func _process(delta: float) -> void:
    bubble = truth.sample(_gather_input(), delta)
```

**Alternative scartate.** *Provider come nodo:* la sostituzione dall'esterno richiede di
manipolare l'albero di una scena non posseduta, e il test richiede il `SceneTree`.
*Flag `is_lying` nella fase:* è la rottura come contenuto sopra la meccanica — esattamente
ciò che l'addendum vieta — e ogni bugia futura raddoppia i rami.

**Obiezione considerata e respinta.** «Una `Resource` non ha `_process`, la bolla che
deriva ha bisogno di vivere da sola.» Falso: la fase passa il `delta` a ogni `sample()`,
e la sorgente accumula per conto proprio. In più si guadagna che **quando la fase non è
attiva la bugia si ferma da sola** — nessun nodo orfano che deriva in sottofondo.

**Conseguenze.** Il codice della fase non cambia mai quando arriva la bugia. Prezzo:
disciplina sulla regola 1 e `.duplicate()` obbligatorio. **Rischio residuo:** nessuno
verifica automaticamente che una fase non bari leggendo lo stato grezzo — è una regola di
revisione, non un vincolo del compilatore.

### ADR-002 — Una scena per fase invece del monolite

**Contesto.** Il prototipo Phaser tiene dieci fasi in `ImagingScene.js`: 3.822 righe,
`switch` sul `key` della fase, stato su campi condivisi della scena. Ha funzionato per
validare il design in 2D e non è un errore — è una forma che non sopravvive al vincolo.

**Decisione.** Ogni fase è un `.tscn` con il proprio script che estende `Phase`.
L'orchestratore le istanzia, si collega a `finished(result)`, e non sa cosa facciano
dentro.

**Conseguenze.** Le sette fasi mancanti diventano contenuto additivo. Ogni fase è
provabile in isolamento aprendo la sua scena. Prezzo: più file, e i dati vanno passati
esplicitamente all'ingresso della fase invece di essere letti dal padre.

### ADR-003 — Camera alla scrivania invece del raycast sul mesh

**Contesto.** Le interfacce diegetiche sono la cosa dimostrabile per il portfolio. Come
ci si interagisce non è un dettaglio di comodo.

**Decisione.** Per l'MVP: interagendo con il monitor la camera transita a un `Marker3D`
davanti alla scrivania, e il `SubViewport` riceve l'input direttamente. La stanza resta
visibile intorno; lo schermo conserva curvatura, scanline e aberrazione.

**In prima persona la camera è la testa**, quindi la transizione non riguarda solo la
visuale. La sequenza è: il controller del giocatore si disabilita, il `CharacterBody3D`
viene agganciato al `Marker3D` (non ci cammina da solo: sei già davanti al monitor, altrimenti
non potresti interagirci), la camera interpola da dove sta a `Marker3D` in un tween breve, e
solo a interpolazione finita l'input passa al `SubViewport`. All'uscita, l'inverso.

La camera non si stacca mai dal corpo: si muovono insieme. Staccarla renderebbe possibile
guardare la stanza da un punto dove il giocatore non è, e su un gioco costruito sulla
presenza in un luogo è precisamente la cosa da non fare.

**Conseguenze.** Si ottiene la resa diegetica senza scrivere la catena
raycast → UV → evento sintetico, e senza gestire hover, drag e focus a mano.

**Il punto che rende accettabile il rinvio:** l'upgrade al raycast tocca **solo il routing
dell'input**, non il codice delle fasi — che parlano `Control` e non sanno da dove arrivi
il click.

---

## Cross-cutting Concerns

Questi pattern valgono per **tutti** i sistemi e ogni implementazione deve rispettarli.

### Error Handling

**Strategia: due canali che non si toccano mai.**

Astrochill ha una categoria di eventi che quasi nessun progetto ha: il **fallimento
diegetico**. Quando il software del 1999 dice `DEVICE NOT RESPONDING`, o il plate solve
non trova nulla, quello non è un errore — è contenuto. E più avanti diventerà una
*bugia*. Se viaggia sullo stesso canale di un errore vero, quando arriveranno le rotture
non sarà più possibile distinguere un bug da una feature.

| | Canale 1 — errore di programma | Canale 2 — esito diegetico |
|---|---|---|
| Cos'è | Un bug: `truth` non iniettata, save corrotto, scena mancante | Contenuto: `GUIDE STAR LOST`, `DEVICE NOT RESPONDING` |
| Meccanismo | `push_error()` + `assert()` in sviluppo | `PhaseResult` restituito dalla fase |
| Chi lo vede | Solo lo sviluppatore: console e `user://logs/` | Il giocatore, sul CRT, in inglese |
| Nel log di dev | Sempre | **Mai** |
| Ferma il gioco | In sviluppo sì (`assert`), in release mai | No: è gameplay |

**La regola:** un fallimento diegetico non passa mai da `push_error`. Un errore di
programma non appare mai sul CRT.

**Mai mostrato al giocatore:** stack trace, codici di errore Godot, modali bloccanti. È un
gioco cozy — un caricamento fallito diventa una frase gentile, non un pannello rosso.

```gdscript
# CANALE 1 — errore di programma
if truth == null:
    push_error("[polar] truth source non iniettata")
    assert(false, "phase senza truth source")

# CANALE 2 — esito diegetico: NON è un errore
return PhaseResult.new(false, "guide star lost", 41)
```

### Logging

**Formato:** `[sistema] messaggio`. Livelli: `ERROR` / `WARN` / `INFO` / `DEBUG`.
**Destinazione:** console in sviluppo, `user://logs/AAAA-MM-GG.log` sempre.
**Livello in release:** `INFO`. `DEBUG` compilato via, non solo filtrato.

**Telemetria di sessione — file separato, non è un log.**

Il criterio di superamento dell'MVP («giocare tre notti di fila perché va») è un giudizio
soggettivo, e va bene che lo sia. Ma da solo non dice *dove* l'attesa si rompe. Un file
per notte in `user://telemetry/` trasforma l'impressione in prova:

```json
{
  "night": 3, "tuning_hash": "a3f1",
  "wait_total_min": 47.5,
  "wait_activities": [
    {"t": 12.0, "what": "caffe",   "dur": 4.5},
    {"t": 19.5, "what": "idle",    "dur": 11.5},
    {"t": 31.0, "what": "cupola",  "dur": 8.0},
    {"t": 39.0, "what": "lampada", "dur": null, "abandoned": true}],
  "menu_reopened": 4,
  "quit_mid_pose": false
}
```

**Ogni voce porta la propria durata, e la porta perché il condotto la produce.**
`Events` espone la coppia `wait_activity_started(what)` / `wait_activity_ended(what)`, non un
evento solo: da lì vengono le `dur`, e i tratti `idle` si calcolano per differenza unendo gli
intervalli sulla finestra della posa — unendo, non sommando, perché il caffè sul fuoco mentre si
sale in cupola è il caso normale. Un'attività cominciata e mai conclusa resta nel file con
`dur: null` e `abandoned: true`: **ometterla la renderebbe indistinguibile da un'attività mai
fatta, e sono due cose opposte.** *(Coppia introdotta il 2026-08-21, al posto del signal unico:
con un evento solo né le durate né `idle` erano ricavabili.)*

**`tuning_hash` non è opzionale:** senza sapere con quali numeri è stata giocata quella
notte, i dati di tre notti diverse non sono confrontabili e l'esperimento non conclude
niente.

### Configuration

Tre livelli, tre posti, nessuna sovrapposizione:

| Tipo | Dove | Modificabile da |
|---|---|---|
| Costanti che non cambiano mai | `const` nel codice | nessuno |
| **Valori di bilanciamento** | `data/tuning.tres` + override `user://tuning_override.cfg` | lo sviluppatore, anche in build esportata |
| Impostazioni del giocatore | `user://settings.cfg` (`ConfigFile`) | il giocatore |

**Regola:** se un numero è stato *scelto* e potrebbe essere sbagliato, sta nel tuning. Se
è una verità matematica, è una `const`. La durata della notte sta nel tuning per
definizione — è la variabile sperimentale dell'MVP.

### Event System

**Signal tipizzati**, dichiarati con firma esplicita: l'editor li verifica, un nome
sbagliato non fallisce in silenzio. `EventBus` autoload solo per i fatti di notte,
secondo la regola dello step 4.

**Naming:** `snake_case` al passato — `phase_finished`, `photo_sold`, `dawn_reached`. Mai
al presente, mai imperativo: un signal racconta ciò che è successo, non ordina.

**Transizioni sempre deferite:**

```gdscript
signal finished(result: PhaseResult)

func _on_phase_finished(r: PhaseResult) -> void:
    _advance.call_deferred(r)      # mai diretto

func _advance(r: PhaseResult) -> void:
    current_phase.queue_free()
    _enter_next(r)
```

Senza `call_deferred` si libera il nodo mentre sta ancora eseguendo il proprio `_process`.
È il crash che appare a caso, di solito sulla macchina di qualcun altro.

### Debug Tools

Attivi solo se `OS.is_debug_build()`. Non compilati in release.

| Strumento | Tasto | Perché esiste |
|---|---|---|
| **Iniettore di sorgente bugiarda** | `F9` | Dimostra che il vincolo non negoziabile regge davvero |
| Controllo del tempo | `F1`–`F4` | Apparato sperimentale per tarare la durata dell'attesa |
| Overlay di stato | `F12` | Rende visibile **quale sorgente alimenta quale fase** |

**L'iniettore di bugia non è contenuto.** L'MVP non ha rotture. È un test: `F9` sostituisce
a caldo la `PhaseTruthSource` onesta con una che deriva. Se la fase continua a funzionare
senza modifiche, il seam regge. Se il codice della fase deve cambiare, l'architettura era
sbagliata — e lo si scopre adesso invece che fra sei mesi.

**`F9` è un interruttore**, non un salto senza ritorno: la sorgente onesta viene messa da
parte e la seconda pressione la rimette al suo posto. Il confronto A/B — guarda, premi,
guarda, premi e torna indietro — è tutto ciò per cui lo strumento esiste. L'iniettore
verifica inoltre che la fase esponga davvero una proprietà `truth`: `Object.set()` su una
proprietà inesistente è un no-op silenzioso, e senza il controllo lo strumento costruito per
scoprire un seam rotto direbbe che regge proprio perché non ha iniettato niente.

Questa è la contromisura al rischio residuo dichiarato in ADR-001.

**L'overlay** mostra la sorgente attiva per ogni fase (`[HONEST]` / `[DRIFTING]`): è il
dato che altrimenti sfugge, e l'unico modo per accorgersi che `F9` ha fatto qualcosa. **Parte
spento**, e `F12` lo accende: partendo acceso coprirebbe l'angolo dello schermo proprio sopra
il CRT che i comandi di taratura servono a guardare.

**Le due lingue dell'overlay** seguono la stessa divisione che vale in tutto il progetto: le
voci di **stato** sono superfici macchina e stanno in inglese (`DEBUG`, `fps`, `tuning`,
`shrink`, `[HONEST]`/`[DRIFTING]`), le **etichette e le righe di aiuto** sono in italiano,
come i commenti, perché le legge una persona sola ed è la lingua di chi ci lavora. Il mockup
qui sotto mostra la parte di stato, che è quella normativa.

```
+-- DEBUG ------------------+
| 23:41  (elapsed 161 min)  |
| time_scale  1.0           |
| polar      82  [HONEST]   |
| targeting 100  [HONEST]   |
| imaging    --  [DRIFTING] |
| fps 60                    |
+---------------------------+
```

**Rinviato:** salto di fase con stato iniziale. Conseguenza accettata: ogni iterazione
sulla fase 10 richiede di rigiocare polare e targeting. Il controllo del tempo mitiga, non
elimina. È la prima cosa da aggiungere se l'attrito diventa fastidioso.

---

## Project Structure

### Organization Pattern

**Pattern:** feature per il gameplay, tipo per il resto.

**Rationale.** L'ADR-002 stabilisce che una fase è un'unità sostituibile. Se i suoi file
vivono in alberi separati (`scenes/phases/` e `scripts/phases/`), l'accoppiamento appena
eliminato dal codice rientra dal filesystem: per aggiungere una fase si toccano tre
cartelle, per rimuoverla bisogna ricordarsi dove sono sparsi i pezzi. Co-locare `.tscn`,
`.gd` e `.tres` di una stessa unità rende additivo anche il lavoro sui file.

Asset condivisi, dati di contenuto e infrastruttura restano organizzati per tipo, perché
non appartengono a una feature sola.

### Directory Structure

```
astrochills-gd-3d/
├── project.godot
├── main.tscn                     # SubViewport low-res → il look PS1
├── main.gd
│
├── autoloads/
│   ├── game.gd                   # portachiavi: possiede la NightRun corrente
│   ├── events.gd                 # EventBus — solo fatti di notte
│   ├── log.gd                    # logging + telemetria di sessione
│   └── tuning.gd                 # carica tuning.tres + override .cfg
│
├── core/                         # contratti e infrastruttura. ZERO gameplay
│   ├── phase.gd                  # class_name Phase
│   ├── phase_result.gd           # esito diegetico (canale 2)
│   ├── phase_truth_source.gd     # IL contratto
│   ├── night_run.gd              # Resource: stato della notte
│   ├── tuning_profile.gd
│   └── save_manager.gd
│
├── phases/                       # una cartella per fase — ADR-002
│   ├── polar/
│   │   ├── phase_polar.tscn
│   │   ├── phase_polar.gd
│   │   └── sources/
│   │       ├── honest_bubble.gd
│   │       └── honest_bubble.tres
│   ├── targeting/
│   │   ├── phase_targeting.tscn
│   │   ├── phase_targeting.gd
│   │   └── sources/
│   │       └── honest_catalog.gd/.tres
│   └── imaging/
│       ├── phase_imaging.tscn
│       ├── phase_imaging.gd
│       └── sources/
│           └── honest_sequence.gd/.tres
│
├── night/                        # orchestrazione: setup → loop foto → alba
│   ├── night_session.tscn
│   ├── night_session.gd
│   ├── night_clock.gd
│   └── post_photo_menu.tscn/.gd
│
├── crt/                          # il sistema di schermi diegetici
│   ├── crt_screen.tscn           # SubViewport + mesh + materiale
│   ├── crt_screen.gd
│   ├── desk_camera.gd            # la transizione alla scrivania
│   └── shaders/
│       ├── crt_curvature.gdshader
│       └── scanlines.gdshader
│
├── world/                        # l'osservatorio in 3D
│   ├── observatory.tscn
│   ├── player/
│   │   └── player.tscn/.gd
│   ├── rooms/
│   │   ├── computer_room.tscn
│   │   ├── kitchen.tscn
│   │   └── dome.tscn
│   └── interactables/
│       ├── interactable.gd       # contratto interazione
│       ├── crt_monitor.tscn
│       └── coffee_maker.tscn
│
├── photo/                        # score → stack → tier → vendita
│   ├── photo.gd
│   ├── quality.gd                # aggregazione dei punteggi di fase
│   ├── stacker.gd
│   └── market.gd
│
├── ui/                           # UI NON diegetica: pausa, impostazioni
│
├── data/
│   ├── tuning.tres
│   ├── targets/                  # catalogo DSO
│   └── clients/                  # committenti
│
├── assets/
│   ├── models/  textures/  fonts/
│   └── audio/
│       ├── ambient/
│       └── sfx/
│
├── debug/
│   ├── debug_overlay.tscn/.gd
│   ├── lie_injector.gd
│   └── time_control.gd
│
└── tests/
```

### Architectural Boundaries

Le regole di dipendenza sono ciò che impedisce all'architettura di sciogliersi.

| Cartella | Può dipendere da | Non deve mai conoscere |
|---|---|---|
| `core/` | **niente** | tutto il resto |
| `phases/` | `core/` | `world/`, `night/`, `photo/`, altre fasi |
| `night/` | `core/`, `phases/`, `photo/`, `crt/` | `world/` — parla via `Events` |
| `world/` | `core/`, `crt/` | `phases/`, `night/` |
| `crt/` | `core/` | `phases/` — riceve un `Control`, non sa quale |
| `photo/` | `core/` | `phases/`, `world/` |
| `debug/` | **tutto** | — nessuno importa da `debug/`, tranne il punto d'ingresso |
| punto d'ingresso (`main.gd`, poi `night/`) | **tutto**, `debug/` incluso | — |

**L'unica eccezione, e perché è stretta.** Gli strumenti di debug qualcuno deve pur
installarli, e l'unico posto che può farlo è il punto d'ingresso: `main.gd` oggi,
`night/night_session.gd` domani. L'eccezione vale **solo** per l'installazione dietro
`OS.is_debug_build()`, e va fatta con `load()` e non con `preload()` — un `const … preload`
risolve al caricamento dello script in ogni build e si porterebbe `debug/` dentro l'export di
release, che è precisamente ciò che FR37 vieta. Nessun altro file, in nessuna cartella, nomina
`debug/`.

**Le tre che contano davvero:**

**1. Una fase non conosce un'altra fase.** Se `phase_imaging.gd` importa qualcosa da
`phases/targeting/`, l'ADR-002 è morto: le fasi non sono più additive. Ciò che serve alla
fase 10 dalla fase 6 arriva come **dato in ingresso**, non come `preload`.

**2. `crt/` non conosce le fasi.** Uno schermo CRT riceve un `Control` da mostrare e non
sa se è una fase, il negozio o il terminale. È questo che rende indolore l'upgrade al
raycast previsto da ADR-003.

**3. `core/` non dipende da niente.** È il test che dice se un contratto è davvero un
contratto. Il giorno in cui `phase_truth_source.gd` dovesse importare qualcosa da
`phases/`, non era un contratto.

**Come `night/` raggiunge il monitor senza conoscere `world/`.** Il monitor CRT vive in
`world/interactables/`, ma la fase da mostrarci sopra vive sotto `night/`. La connessione
passa da una **registrazione**, non da un percorso:

```gdscript
# world/interactables/crt_monitor.gd
func _ready() -> void:
    Events.screen_registered.emit($CrtScreen)

# night/night_session.gd
func _ready() -> void:
    Events.screen_registered.connect(func(s: CrtScreen) -> void: _crt = s)
```

Così `night/` conosce il **tipo** `CrtScreen` — che appartiene a `crt/`, un sistema generico
— e mai `world/`. E non lo cerca per percorso, che si romperebbe al primo spostamento di
nodo.

### Naming Conventions

| Elemento | Convenzione | Esempio |
|---|---|---|
| File e cartelle | `snake_case` | `phase_polar.gd`, `honest_bubble.tres` |
| Scene | `snake_case`, stesso nome dello script | `phase_polar.tscn` + `phase_polar.gd` |
| Classi (`class_name`) | `PascalCase` | `PhasePolar`, `PhaseTruthSource` |
| Funzioni e variabili | `snake_case` | `sample()`, `elapsed_min` |
| Costanti | `UPPER_SNAKE_CASE` | `NIGHT_START_HOUR` |
| Signal | `snake_case` al passato | `phase_finished`, `photo_sold` |
| Membri privati | prefisso `_` | `_gather_input()`, `_t` |
| Shader | `snake_case.gdshader` | `crt_curvature.gdshader` |

**Regola sulle fasi.** Una fase si chiama `phase_<nome>` in file, scena e classe. Il nome
è quello della procedura reale, **non il numero**: `phase_polar`, non `phase_03`. I numeri
cambiano se se ne aggiunge una in mezzo; i nomi no.

**Regola sulle sorgenti di verità.** `<aggettivo>_<cosa>.gd` — `honest_bubble`,
`drifting_bubble`, `honest_catalog`. L'aggettivo dice **se e come mente**, ed è la prima
cosa che si vuole leggere.

### System Location Mapping

| Sistema | Posizione | Responsabilità |
|---|---|---|
| Framework delle fasi | `core/phase.gd` + `phases/` | contratto e implementazioni |
| **Indirezione della verità** | `core/phase_truth_source.gd` + `phases/*/sources/` | contratto in core, implementazioni nella fase |
| UI diegetiche CRT | `crt/` | `SubViewport`, shader, camera scrivania |
| Orchestrazione notte | `night/` | setup → loop foto → alba |
| Tempo di gioco | `night/night_clock.gd` | accumulatore su `_process` |
| Pipeline foto | `photo/` | punteggio, stack, tier, vendita |
| Osservatorio | `world/` | movimento, stanze, interazioni |
| Persistenza | `core/save_manager.gd` | `ResourceSaver` su `NightRun` |
| Contenuto data-driven | `data/` | target, committenti, tuning |
| Strumenti di debug | `debug/` | iniettore di bugia, controllo tempo, overlay |

---

## Implementation Patterns

Questi pattern garantiscono che implementazioni diverse — umane o di agenti — restino
compatibili fra loro. Il principio: **ogni volta che due agenti potrebbero prendere la
stessa decisione in modo diverso, qui c'è la regola che la fissa.**

---

## Novel Patterns

### Pattern 1 — Truth Source Indirection

**Scopo.** Una fase deve poter cambiare la sorgente del proprio stato osservabile senza
essere riscritta. È il vincolo non negoziabile del progetto (addendum §3, ADR-001).

**Forma.** `PhaseTruthSource` è il **tipo di iniezione comune** — un marker senza metodi.
Ogni fase dichiara il proprio sotto-contratto tipizzato, coerentemente con la scelta dei
signal tipizzati: un nome sbagliato non compila.

```gdscript
# core/phase_truth_source.gd
class_name PhaseTruthSource extends Resource
# Marker. Non ha metodi: esiste per essere il tipo di @export.
# Ogni fase dichiara la sottoclasse con la firma che le serve.

# phases/polar/polar_input.gd
class_name PolarInput extends RefCounted
var azimuth: float
var altitude: float
var seconds_since_correction: float

# phases/polar/polar_truth_source.gd
class_name PolarTruthSource extends PhaseTruthSource
## Deriva osservata della stella nel reticolo, in arcominuti.
func sample(_input: PolarInput, _delta: float) -> Vector2:
    push_error("[polar] sorgente astratta: usa una sottoclasse")
    return Vector2.ZERO

# phases/polar/sources/honest_drift.gd — MVP
class_name HonestDrift extends PolarTruthSource
func sample(input: PolarInput, _delta: float) -> Vector2:
    return Vector2(input.azimuth, input.altitude) * DRIFT_RATE

# phases/polar/sources/wandering_drift.gd — NON nell'MVP, ma già possibile
class_name WanderingDrift extends PolarTruthSource
var _t := 0.0
func sample(_input: PolarInput, delta: float) -> Vector2:
    _t += delta
    return Vector2(sin(_t * 0.3), cos(_t * 0.17)) * 0.4
```

**Come la usa la fase.** Questo file non cambierà mai, nemmeno quando arriveranno le
rotture:

```gdscript
# phases/polar/phase_polar.gd
class_name PhasePolar extends Phase

@export var truth: PolarTruthSource

var _input := PolarInput.new()
var _drift := Vector2.ZERO

func _ready() -> void:
    assert(truth != null, "[polar] truth source non iniettata")

func _process(delta: float) -> void:
    _input.azimuth = _screw_azimuth
    _input.altitude = _screw_altitude
    _drift = truth.sample(_input, delta)          # UNICA fonte di _drift
    _reticle.position = _drift * PIXELS_PER_ARCMIN
```

**Le tre regole del pattern:**

1. **Lo stato osservabile ha una sola assegnazione in tutto il file, e viene da `truth`.**
   Se compare un secondo `_drift = ...` altrove, il seam è rotto — non importa quanto sia
   pulito il resto.
2. **Ogni `.tres` di sorgente ha `resource_local_to_scene = true`.** Altrimenti due fasi in
   scena condividono la stessa istanza, e la seconda eredita la deriva accumulata dalla
   prima.
3. **Iniezione a runtime sempre con `.duplicate(true)`.** Vale in particolare per
   l'iniettore di debug (`F9`).

### Pattern 2 — La fase che non blocca

**Scopo.** L'ipotesi dell'MVP è che l'attesa sia piacevole. Perché l'attesa esista
davvero, la fase 10 deve restare viva mentre il giocatore è in un'altra stanza: la
sequenza gira sul serio, e il CRT in stanza computer mostra lo stato vero.

Nel prototipo Phaser la fase 10 gestiva l'attesa dentro di sé, aprendo l'esplorazione
sopra il proprio stack. In 3D non funziona uguale: il giocatore cammina fisicamente
altrove, e «dove vive la sequenza mentre non la guardi» diventa una domanda reale.

**Il contratto della fase:**

```gdscript
# core/phase.gd
class_name Phase extends Node

signal finished(result: PhaseResult)

## Identità stabile della fase. NON usare mai `name`: Godot lo rinomina
## in @PhasePolar@2 quando due nodi omonimi finiscono sotto lo stesso padre,
## e con «rifai setup» succede davvero.
func key() -> StringName:
    push_error("phase senza key()")
    return &""

func setup(run: NightRun, ctx: Dictionary) -> void: pass
func screen() -> Control: return null
func score() -> int: return 100

## true se la fase continua a girare quando il giocatore si allontana.
func runs_in_background() -> bool: return false

## Il Control mostrato sul CRT appartiene alla fase, anche dopo il reparent.
##
## PREDELETE e non _exit_tree(): _exit_tree() scatta anche su un'uscita
## TEMPORANEA dall'albero, e libererebbe l'interfaccia di una fase ancora viva.
## Corretto il 2026-08-22 in code review della storia 1.1.
func _notification(what: int) -> void:
    if what != NOTIFICATION_PREDELETE:
        return
    var s := screen()
    if s != null and is_instance_valid(s) and not is_ancestor_of(s):
        s.queue_free()
```

Le fasi vivono sotto un `PhaseHost` che **non viene mai liberato prima dell'alba**:

```
NightSession
├── PhaseHost
│   └── PhaseImaging       ← continua a processare: frame 7/20
└── NightClock

World
└── Player → cucina        ← il giocatore è altrove
```

**Le tre regole delle fasi in background:**

1. **Non assumono mai di essere visibili.** Niente `get_viewport().size`, niente accesso
   alla camera: il loro `Control` potrebbe non essere renderizzato in questo istante.
2. **I suoni appartengono al luogo, non alla fase.** Il ronzio della sequenza è un
   `AudioStreamPlayer3D` nella cupola, non un figlio della fase — altrimenti in cucina si
   sente come se si fosse lì dentro.
3. **La telemetria dell'attesa la raccoglie la fase**, ascoltando `Events`. È l'unica che
   sa quando l'attesa è cominciata e quando finisce.

### Pattern 3 — Lo schermo diegetico

**Scopo.** Un `Control` finisce su un `SubViewport` montato su un mesh 3D e riceve input,
senza che nessuno dei due sappia cosa sta mostrando l'altro.

```gdscript
# crt/crt_screen.gd
class_name CrtScreen extends Node3D

@onready var _viewport: SubViewport = %Viewport

func show_control(c: Control) -> void:
    for child in _viewport.get_children():
        _viewport.remove_child(child)       # MAI queue_free
    if c != null:
        c.reparent(_viewport)
```

**La regola che salva un pomeriggio:** *il CRT non libera mai ciò che mostra.* Il `Control`
appartiene alla fase, che vive sotto `PhaseHost`. Un `queue_free()` qui distrugge
l'interfaccia di una fase che sta ancora girando in background.

È l'errore che si commette per default, perché «pulire prima di mostrare» è l'istinto
giusto ovunque tranne qui.

**Il contrappeso, senza il quale la regola perde memoria.** Dopo `reparent()` il `Control`
non è più figlio della fase: liberare la fase non lo libera, e resterebbe a schermo
appartenendo a qualcosa che non esiste più. La proprietà resta della fase e si esercita in
due punti:

- la fase libera il proprio `Control` alla propria distruzione — `NOTIFICATION_PREDELETE`,
  **non** `_exit_tree()`, che scatterebbe anche su un'uscita temporanea dall'albero e
  ucciderebbe l'interfaccia di una fase ancora viva (vedi `core/phase.gd`);
- l'orchestratore chiama `_crt.show_control(null)` **prima** di liberare la fase.

---

## Pattern standard

### Creazione delle fasi — `NightPlan` come dato

```gdscript
# core/night_plan.gd
class_name NightPlan extends Resource
@export var setup_phases: Array[PackedScene]   # una volta per notte
@export var photo_phases: Array[PackedScene]   # per ogni foto

# night/night_session.gd
func _instantiate_phase(scene: PackedScene) -> Phase:
    var p := scene.instantiate() as Phase
    p.setup(Game.run, _ctx)
    p.finished.connect(_on_phase_finished.bind(p))
    return p
```

Gli upgrade che automatizzano una fase tolgono una riga dal `.tres`. Nessun codice toccato.

### Transizioni di stato — sempre deferite

```gdscript
func _on_phase_finished(result: PhaseResult, phase: Phase) -> void:
    Game.run.phase_scores[phase.key()] = phase.score()     # key(), mai name
    _advance.call_deferred(result, phase)

func _advance(result: PhaseResult, phase: Phase) -> void:
    if not phase.runs_in_background():
        _crt.show_control(null)      # PRIMA di liberare: il Control e' reparentato
        phase.queue_free()
    _enter_next(result)
```

### Comunicazione

Signal diretti in gerarchia, `EventBus` per i fatti di notte. Regola completa nella
sezione Cross-cutting Concerns.

```gdscript
# Diretto: si sa chi ascolta, ed è uno
phase.finished.connect(_on_phase_finished)

# Bus: interessa a HUD, audio, autosave, telemetria
Events.photo_sold.emit(photo, lire)
```

### Accesso ai dati — nessun `FileAccess` nel gameplay

```gdscript
Tuning.night_length_min                              # sì
load("res://data/tuning.tres").night_length_min      # no: bypassa l'override
FileAccess.open("res://data/targets.json", READ)     # no, mai
```

I dati di contenuto sono `.tres` in `data/`, caricati con `preload`/`load`. Il tuning passa
**sempre** dall'autoload `Tuning`, altrimenti l'override esterno — cioè lo strumento con
cui si tara l'MVP — viene scavalcato in silenzio.

### `PhaseResult` — il canale diegetico

```gdscript
# core/phase_result.gd
class_name PhaseResult extends RefCounted

var ok: bool
var reason: String        # diegetico, in inglese, mostrato sul CRT
var score: int            # 0-100
var payload: Dictionary   # dati per le fasi successive

func _init(p_ok := true, p_reason := "", p_score := 100, p_payload := {}) -> void:
    ok = p_ok
    reason = p_reason
    score = p_score
    payload = p_payload
```

`reason` è **inglese**: è la lingua delle macchine (brief §Content & Direction). Non passa
mai da `push_error`.

---

### Testing — banco di collaudo, nessun framework

`tests/test_bench.tscn` è una scena che istanzia a mano le parti a logica pura e ne stampa
il comportamento. Nessun addon, nessuna dipendenza, nessun setup.

```gdscript
# tests/test_bench.gd
func _ready() -> void:
    _check_honest_drift()
    _check_save_migration()

func _check_honest_drift() -> void:
    var src := HonestDrift.new()
    var i := PolarInput.new()
    i.azimuth = 0.5
    i.altitude = -0.2
    # Deterministica: stesso input, stesso output, delta irrilevante
    print("[drift] ", src.sample(i, 0.016), " == ", src.sample(i, 0.99))
```

**Cosa vale la pena mettere sul banco** — solo logica pura, niente scene:

| Area | Perché |
|---|---|
| Sorgenti di verità | l'onesta dev'essere deterministica; la bugiarda no. È la differenza da vedere |
| Aggregazione qualità foto | punteggi ereditati fra foto della stessa notte: facile sbagliare |
| Migrazione del save | l'unica cosa che rompe partite già iniziate |

**Il limite, dichiarato.** Un banco stampa, non asserisce: nessuna regressione viene
rilevata da sola, ogni verifica resta un atto di lettura. L'argomento della testabilità che
ha motivato la sorgente come `Resource` e `NightRun` come dati puri resta quindi onorato a
metà — quelle parti *sono* istanziabili in isolamento, ed è ciò che rende possibile il
banco, ma nulla impedisce a una regressione di passare inosservata.

**Il seam ha comunque una verifica.** L'iniettore `F9` esercita l'indirezione dentro il
gioco vero: se la fase continua a funzionare con una sorgente bugiarda senza essere
modificata, il vincolo di ADR-001 regge. Non è un test automatico, ma è una prova.

Se in futuro il banco non basta più, GUT copre queste tre aree senza cambiare nulla del
codice di produzione: sono già tutte istanziabili senza `SceneTree`.

## Consistency Rules

| Regola | Perché | Come si verifica |
|---|---|---|
| Lo stato osservabile di una fase viene **solo** da `truth` | ADR-001 | una sola assegnazione per variabile, verificabile a vista |
| Ogni `.tres` di sorgente ha `resource_local_to_scene = true` | istanze condivise per riferimento | ispezione del `.tres` |
| Transizioni di fase sempre `call_deferred` | nodo liberato dentro la propria callback | revisione |
| Il CRT non libera mai il `Control` che mostra | distrugge fasi ancora vive | revisione |
| Una fase non importa da un'altra fase | ADR-002: le fasi restano additive | `grep "phases/"` dentro `phases/` |
| Il tuning si legge da `Tuning`, mai da `load()` | bypassa l'override esterno | `grep "tuning.tres"` |
| I fallimenti diegetici non usano `push_error` | separazione dei due canali | revisione |
| Le fasi in background non assumono di essere visibili | il `Control` può non essere renderizzato | revisione |
| L'identità di una fase è `key()`, mai `name` | Godot rinomina in `@Nome@2` | `grep "phase.name"` |
| `crt.show_control(null)` prima di liberare una fase | il `Control` è reparentato, resterebbe orfano | revisione |

---

## Architecture Validation

Validazione eseguita il **2026-08-21** sul documento reale, non a memoria.

### Validation Summary

| Verifica | Esito | Note |
|---|---|---|
| Placeholder / TODO | ✅ | nessuno |
| Specificità delle versioni | ✅ | Godot 4.7.2, verificata sul sito ufficiale il 21/08/2026 |
| Compatibilità delle decisioni | ✅ | 3 incoerenze trovate e risolte — sotto |
| Copertura dei sistemi | ✅ | 9 su 9 mappati a una posizione |
| Completezza dei pattern | ✅ | lacuna sul testing trovata e colmata |
| Struttura del documento | ✅ | tutte le sezioni obbligatorie presenti |
| Mappatura epiche | N/A | non esistono epiche: nessun GDD, workflow epiche mai eseguito |
| Sicurezza | N/A | single player offline: nessuna superficie di attacco |
| Networking | N/A | fuori scopo per costruzione |

### Coverage Report

**Decisioni prese:** 14 · **Pattern:** 3 novel + 6 standard · **ADR:** 3 ·
**Regole di consistenza:** 9

### Issues Resolved

**1. Le regole di dipendenza si contraddicevano.** `night/` non poteva conoscere `world/`
e `world/` non poteva conoscere `phases/`, ma qualcuno doveva chiamare
`crt.show_control(phase.screen())` — e il monitor vive in `world/`, la fase sotto `night/`.
Come scritto, nessuno poteva farlo.
→ Risolto: `night/` può dipendere da `crt/`; il monitor si registra via
`Events.screen_registered` invece di essere cercato per percorso.

**2. Il `Control` di una fase liberata restava orfano.** Dopo `reparent()` nel
`SubViewport`, il `Control` non è più figlio della fase: `phase.queue_free()` non lo
liberava, e restava a schermo appartenendo a qualcosa che non esisteva più.
→ Risolto: la fase lo libera alla propria distruzione (`NOTIFICATION_PREDELETE`);
l'orchestratore chiama `_crt.show_control(null)` prima di liberare. La prima stesura usava
`_exit_tree()`, che scattava anche su un'uscita temporanea: corretto il 2026-08-22.

**3. I punteggi usavano `phase.name` come chiave.** Godot rinomina in `@PhasePolar@2`
quando due nodi omonimi finiscono sotto lo stesso padre — e con «rifai setup»
([economia.md §12](docs/idea/economia.md)) succede davvero. Risultato: punteggi accumulati
sotto chiavi diverse, salvati così nel file di salvataggio.
→ Risolto: `Phase.key()` come identità stabile; `name` non si usa mai.

**4. Il pattern di test non esisteva.** La testabilità aveva motivato due decisioni
(sorgente come `Resource`, `NightRun` come dati puri), poi `tests/` compariva nell'albero
senza che il documento dicesse con cosa, dove né cosa.
→ Risolto: banco di collaudo definito, con il suo limite dichiarato.

### Document Quality Score

| Dimensione | Esito |
|---|---|
| Completezza architetturale | **Completa** |
| Specificità delle versioni | **Tutte verificate** |
| Chiarezza dei pattern | **Cristallina** — ogni pattern ha codice concreto |
| Pronto per gli agenti | **Pronto** |

### Decisioni di design ancora aperte

Nessuna delle due blocca l'implementazione.

- **Metrica della fase 3** — è contenuto della fase, si decide scrivendola.
- **Durata della notte** — è per costruzione un valore di tuning, ed è la variabile che
  l'MVP esiste per misurare.

---

## Development Environment

### Prerequisites

| | |
|---|---|
| **Godot 4.7.2 stable** | già presente nel repo: `Godot_v4.7.2-stable_win64.exe` |
| Blender | per telescopio e montatura, gli unici modelli da fare a mano |
| Node.js | solo se si attivano gli MCP |
| Asset CC0 | Kenney, Quaternius, Poly Pizza — per il resto dell'arredo |

### AI Tooling (MCP Servers)

Raccomandati e **non ancora installati** — nessun `.mcp.json` sul progetto.

```bash
# GoPeak — ciclo edit → run → inspect → fix dentro Godot
claude mcp add gopeak -- npx -y gopeak

# Context7 — documentazione Godot corrente invece della memoria del modello
claude mcp add context7 -- npx -y @upstash/context7-mcp
```

Dettagli e capacità nella sezione **Engine & Framework**.

### Setup Commands

Nessuno starter template: il progetto si crea vuoto e si popola secondo l'albero definito
in **Project Structure**.

```bash
# 1. Progetto Godot vuoto, renderer Compatibility
#    (Project Settings → Rendering → Renderer → Compatibility)

# 2. Import: filtro nearest come default di progetto — è metà dell'estetica PS1
#    Project Settings → Rendering → Textures → Canvas Textures → Default Texture Filter: Nearest

# 3. Struttura delle cartelle
mkdir -p autoloads core phases/{polar,targeting,imaging}/sources \
         night crt/shaders world/{player,rooms,interactables} \
         photo ui data/{targets,clients} \
         assets/{models,textures,fonts,audio/{ambient,sfx}} debug tests

# 4. Autoload da registrare, in quest'ordine
#    Game → Events → Log → Tuning
```

### First Steps

L'ordine non è arbitrario: **i primi due passi esistono per far fallire presto le due cose
che, se non funzionano, cambiano l'architettura.**

**1. Il look PS1.** `main.tscn` con il mondo 3D dentro un `SubViewport` a bassa
risoluzione, riscalato con nearest. È anche la strada scelta per aggirare l'assenza di
`CompositorEffect` in Compatibility: se non rende, si scopre adesso.

**2. Spike CRT.** Un mesh con `SubViewport`, shader di curvatura e scanline, un `Control`
qualunque sopra. Verifica sul campo il rischio dichiarato nella sezione Engine.

**3. I contratti in `core/`.** `Phase`, `PhaseResult`, `PhaseTruthSource`, `NightRun`,
`TuningProfile`, `NightPlan`. Nient'altro: `core/` non dipende da niente, e si vede subito
se è vero.

**4. La fase 3 completa, con l'iniettore `F9` insieme.** Non dopo.

Questo è il passo che conta. Costruire `HonestDrift`, poi `WanderingDrift`, poi premere
`F9` e guardare cosa succede — **con una sola fase esistente**. Se il codice della fase
deve cambiare per accogliere la bugia, l'architettura è sbagliata e va corretta ora, quando
c'è una fase da sistemare invece di tre.

È l'unico momento in cui il rischio residuo dichiarato in ADR-001 costa poco da chiudere.

**5. `night_session` + `NightClock` + `NightPlan`.** L'orchestrazione, con la notte ×10
attiva dal primo giorno.

**6. Fase 6, fase 10, l'osservatorio, stacking, vendita.** Da qui in poi è contenuto
additivo sopra un'architettura già provata.
