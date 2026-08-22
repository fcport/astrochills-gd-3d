---
project_name: 'astrochills-gd-3d'
user_name: 'Federico'
date: '2026-08-21'
sections_completed:
  [
    'technology_stack',
    'engine_rules',
    'performance',
    'code_organization',
    'testing',
    'platform_build',
    'dont_miss',
  ]
source: '_bmad-output/game-architecture.md'
---

# Project Context for AI Agents

Regole critiche per implementare codice in **Astrochill**. Contiene solo ciò che un agente
sbaglia per default: dettagli non ovvi, anti-pattern specifici del progetto, e vincoli che
sembrano bug ma sono scelte.

**Fonte autoritativa:** [game-architecture.md](game-architecture.md). Questo file è il
promemoria, non il sostituto.

---

## Technology Stack & Versions

| | |
|---|---|
| Godot | **4.7.2 stable** — renderer **Compatibility** (OpenGL 3.3 / ES 3.0) |
| Linguaggio | **GDScript**, tipizzazione statica ovunque possibile |
| Piattaforma | PC Windows, single player offline |
| Rete | **nessuna** — non introdurre codice di networking, mai |
| Arte | 3D low-poly, estetica PS1, prima persona |

---

## Critical Implementation Rules

### La regola numero uno

**Lo stato osservabile di una fase viene SOLO da `truth.sample(...)`.**

```gdscript
# SÌ
_drift = truth.sample(_input, delta)

# NO — anche se sembra più diretto, più pulito, più veloce
_drift = Vector2(_screw_a, _screw_b) * DRIFT_RATE
```

Se una variabile osservabile ha più di un'assegnazione, o se una di quelle assegnazioni
non passa da `truth`, il vincolo del progetto è rotto. Non è uno stile: è la ragione per
cui il progetto è strutturato così ([ADR-001](game-architecture.md)).

Nell'MVP la sorgente dice sempre la verità. **Questo non autorizza a saltarla.**

---

### Regole Godot non ovvie

**Le `Resource` sono condivise per riferimento.** Due nodi che caricano lo stesso `.tres`
ricevono la **stessa istanza**. Ogni `.tres` di sorgente di verità deve avere
`resource_local_to_scene = true`; ogni iniezione a runtime usa `.duplicate(true)`.

**`assert()` sparisce nelle build di release.** Va usato per i contratti (`truth != null`),
mai per logica con effetti collaterali: in release quella riga non esiste.

**`reparent()` trasferisce la proprietà.** Dopo che un `Control` è entrato nel
`SubViewport` del CRT, liberare la fase **non** lo libera. Vedi la regola del CRT sotto.

**Il `name` di un nodo non è un'identità.** Godot rinomina in `@PhasePolar@2` quando due
nodi omonimi finiscono sotto lo stesso padre. Usa sempre `phase.key()`.

**Mai liberare un nodo dentro la sua stessa callback.** Le transizioni di fase passano
sempre da `call_deferred`.

**`@onready` si risolve dopo `_ready` dei figli.** Non usarlo per valori che servono in
`_enter_tree`.

**Signal:** dichiarati e tipizzati, `snake_case` al passato — `phase_finished`,
`photo_sold`. Mai stringhe generiche con payload `Dictionary`.

---

### Estetica PS1 — quello che sembra un difetto e non lo è

**L'istinto di «migliorare la resa» è l'errore più frequente su questo progetto.** Il gioco
è ambientato nel 1999 e imita deliberatamente la grafica di quell'anno.

| Non fare | Perché |
|---|---|
| Attivare filtri di texture lineari | il `Nearest` è la metà dell'estetica |
| Generare mipmap | ammorbidiscono la texture in lontananza: uccidono il crunch |
| Cercare un antialiasing | l'aliasing crudo **è** il look. Compatibility non ne offre comunque |
| Aumentare la risoluzione del `SubViewport` del mondo | la bassa risoluzione è voluta |
| Aggiungere ombre morbide, riflessi, bloom | fuori periodo e fuori renderer |

**Valori validati sul campo il 2026-08-21** (spike su RTX 3080, OpenGL 3.3 Compatibility).
Non cambiarli senza una ragione dichiarata: sono stati scelti guardando, non stimati.

| Valore | Dove | Significato |
|---|---|---|
| `stretch_shrink = 2` | `main.tscn` | risoluzione interna 640×360 su finestra 1280×720 |
| `snap_resolution = 665` | `world/shaders/ps1.gdshader` | jitter dei vertici **sub-pixel**: circa mezzo pixel di passo a 640 di larghezza. È un tremolio appena percepibile, non il wobble pieno della PlayStation — scelta deliberata |
| `scanline_count = altezza / 2` | calcolato in `crt_screen.gd` | **non** scegliere questo numero a mano: un valore pari all'altezza del viewport dà un ciclo di seno per pixel, cioè rumore di aliasing, non righe |
| CRT viewport `256×192` | `crt_screen.tscn` | sotto questa soglia il testo tecnico smette di essere leggibile |

### Riferimenti di direzione artistica

**Principale — [Creature Kitchen](https://store.steampowered.com/app/3097300/Creature_Kitchen/)**
(The Rat Zone, 6 feb 2026). Scelto da Federico il 2026-08-21. È anche il comparabile di
posizionamento del brief: stesso riferimento per l'occhio e per lo scaffale.

**Secondario — [Meat Grinder: Hotdog Simulator](https://store.steampowered.com/app/3994680/Meat_Grinder_Hotdog_Simulator/)**
(Panic Panda / PlayWay, 11 ago 2026). Utile come estremo "leggero" della scala.

**Cosa hanno in comune, ed è la lezione:**

| Asse | Entrambi |
|---|---|
| Geometria | **stabile.** Nessun vertex jitter percepibile in nessuno dei due |
| Texture | risoluzione bassa, filtro nearest, aliasing pieno lasciato visibile |
| Illuminazione | piatta, poche sorgenti, nessuna ombra morbida |

**Il retro viene dalle texture e dalla gradazione colore, non dalla geometria instabile.**
Due riferimenti indipendenti dicono la stessa cosa. È la conferma che `snap_resolution = 665`
— jitter sub-pixel, quasi spento — è il valore giusto e non un ripiego.

**Dove Creature Kitchen va oltre, e Astrochill dovrebbe seguirlo:**

- **Dithering.** Nelle zone scure si vede un reticolo regolare che sembra dithering
  ordinato. È tecnica di periodo e in Compatibility si fa nello shader del materiale o su
  un quad full-screen — nessun `CompositorEffect` richiesto. **Non ancora implementato.**
- **Gradazione colore forte.** Dominante calda malaticcia su tutta la scena, non colori
  neutri. Su Astrochill la dominante sarà fredda, ma il principio è lo stesso: la scena ha
  un colore, non è "corretta".
- **Crunch delle texture più spinto** di quanto verrebbe spontaneo. Il muro non è una
  texture di muro: sono pixel che suggeriscono un muro.

**Attenzione a cosa NON si prende da Creature Kitchen:** il tono cute e il
creature-collecting (brief § References). Il riferimento è visivo e di posizionamento,
non di contenuto.

**Compatibility non supporta:** `CompositorEffect`, compute shader, `RenderingDevice`,
buffer normal/roughness, SSR/SSIL/SDFGI/VoxelGI, fog volumetrica, depth of field, decal,
tutti gli AA post-process. Non cercare workaround: quasi nulla di questo serve.

Il post-effect a schermo intero passa dal `SubViewport` a bassa risoluzione riscalato con
nearest, non da un `CompositorEffect`.

---

### Lingua e ambientazione — 1999, Montegrimano

**IT è la lingua del giocatore, EN è la lingua delle macchine.**

| In italiano | In inglese |
|---|---|
| narrativa, log, lettere, giornali, dialoghi | **ogni interfaccia software**, messaggi del terminale, esiti diegetici |
| commenti nel codice | identificatori nel codice |

```gdscript
# SÌ — l'esito diegetico è inglese: lo scrive una macchina del 1999
return PhaseResult.new(false, "guide star lost", 41)

# NO
return PhaseResult.new(false, "stella guida persa", 41)
```

**Coerenza storica:** siamo a sei mesi dall'euro — i prezzi sono in **lire**. Il software
citato è quello che esisteva davvero: *Cartes du Ciel*, *CCDOPS*, *MaxIm DL*, *Giotto*.
Nessun anacronismo tecnico: niente USB, niente Wi-Fi, niente cloud. Seriale e modem 56k.

**Tono: creepy-cozy, mai horror.** Nessun jump scare, nessuna minaccia, non si muore, non
c'è niente che insegua. La stranezza è informativa e cresce dentro il lavoro.

---

### I due canali: errore vero contro fallimento diegetico

**Non confonderli mai.** Quando arriveranno le rotture, questa separazione è l'unica cosa
che permetterà di distinguere un bug da una feature.

```gdscript
# CANALE 1 — errore di programma: solo per lo sviluppatore
push_error("[polar] truth source non iniettata")

# CANALE 2 — contenuto: lo legge il giocatore sul CRT
return PhaseResult.new(false, "guide star lost", 41)
```

Un fallimento diegetico non passa **mai** da `push_error` o `push_warning`. Un errore di
programma non appare **mai** sul CRT.

Al giocatore non si mostrano mai stack trace, codici di errore Godot o modali bloccanti:
è un gioco cozy.

---

### Performance

Nessun target di frame rate dichiarato: geometria low-poly su Compatibility non è il
problema. **Il costo reale sono i `SubViewport`** — ogni schermo CRT è un render pass in
più.

- Imposta `render_target_update_mode` per aggiornare solo quando serve, mai
  `UPDATE_ALWAYS` per default
- Una fase in background non fa lavoro pesante per frame: sta contando il tempo, non
  simulando
- Nessun object pooling necessario: non ci sono entità spawnate in quantità

---

### Organizzazione del codice

**Struttura:** feature-first per il gameplay (una cartella per fase, con `.tscn`, `.gd` e
`.tres` insieme), per tipo per asset e dati.

**Regole di dipendenza — non violarle:**

| Cartella | Può dipendere da | Non deve mai conoscere |
|---|---|---|
| `core/` | **niente** | tutto il resto |
| `phases/` | `core/` | `world/`, `night/`, `photo/`, **altre fasi** |
| `night/` | `core/`, `phases/`, `photo/`, `crt/` | `world/` |
| `world/` | `core/`, `crt/` | `phases/`, `night/` |
| `crt/` | `core/` | `phases/` |
| `photo/` | `core/` | `phases/`, `world/` |

**Nomi:** file e cartelle `snake_case`, `class_name` in `PascalCase`, costanti
`UPPER_SNAKE_CASE`, membri privati con `_`.

Una fase si chiama `phase_<nome>`, **mai** `phase_<numero>`: i numeri cambiano se se ne
aggiunge una in mezzo.

Una sorgente si chiama `<aggettivo>_<cosa>` — `honest_bubble`, `drifting_bubble`.
L'aggettivo dice **se e come mente**.

**Comunicazione:** se sai chi ascolta ed è uno → signal diretto. Se non lo sai o sono più
di due → `Events`.

---

### Testing

`tests/test_bench.tscn` — banco di collaudo, **nessun framework**. Istanzia a mano la
logica pura e ne stampa il comportamento.

Sul banco va solo logica pura, niente scene: sorgenti di verità, aggregazione della qualità
delle foto, migrazione del save.

Non introdurre GUT o gdUnit4 senza chiedere.

---

## Critical Don't-Miss Rules

### Anti-pattern — non farlo mai

```gdscript
# 1. Calcolare lo stato osservabile senza passare da truth
_drift = _from_screws(...)                    # ROTTO: vedi ADR-001

# 2. Un flag booleano per la bugia
if is_lying: ... else: ...                    # ROTTO: la rottura NON è un ramo

# 3. Liberare un Control dentro il SubViewport del CRT
_viewport.get_child(0).queue_free()           # distrugge una fase viva

# 4. Usare il nome del nodo come identità
run.phase_scores[phase.name] = s              # diventa @PhasePolar@2

# 5. Caricare il tuning direttamente
load("res://data/tuning.tres").night_length_min   # scavalca l'override esterno

# 6. Leggere dati con FileAccess nel gameplay
FileAccess.open("res://data/targets.json", READ)  # i dati sono .tres

# 7. Importare da un'altra fase
const Targeting = preload("res://phases/targeting/...")  # rompe ADR-002

# 8. Un suono del luogo attaccato a una fase in background
$AudioStreamPlayer3D  # figlio della fase → lo senti dalla cucina
```

### Regole di ambito — l'MVP è tre fasi, non dieci

I documenti di design descrivono un gioco molto più grande di quello che va costruito
adesso. Un agente che li legge implementerà volentieri cose fuori scopo.

**Nell'MVP:** fase 3 (allineamento polare), fase 6 (targeting), fase 10 (sequenza di
imaging), stacking, vendita, gestione leggera dell'osservatorio durante la posa.

**Fuori dall'MVP — non implementare senza che venga chiesto:**

- le altre sette fasi (livellamento, bilanciamento, accensione PC, plate solving, focus,
  dark/flat, autoguida)
- **le rotture e le anomalie** — il seam esiste, le bugie no
- storia, metanarrazione, rete di osservatori, esplorazione esterna
- calibrazione economica: i prezzi non si tarano ora

Il seam va **esercitato** (iniettore `F9`), non riempito di contenuto.

### Gotcha finali

**Il CRT non libera mai ciò che mostra**, ma la fase riprende il proprio `Control` alla
propria distruzione (`NOTIFICATION_PREDELETE`) e l'orchestratore chiama `show_control(null)`
prima di liberare. Le due regole insieme, mai una sola.

**Non usare `_exit_tree()` per liberare ciò che si è dato via.** Scatta anche su un'uscita
temporanea dall'albero — un `remove_child()` per parcheggiare un nodo, uno spostamento fra
host, la distruzione del viewport che lo ospitava — e distruggerebbe l'interfaccia di una
fase ancora viva, che il frame dopo la dereferenzia. Costava un crash, e lo faceva.

**Una fase in background non assume di essere visibile.** Niente
`get_viewport().size`, niente accesso alla camera: il suo `Control` potrebbe non essere
renderizzato in questo istante.

**In prima persona la camera è la testa.** Non staccarla mai dal corpo: si muovono
insieme. Guardare la stanza da un punto dove il giocatore non è rompe l'unica cosa che il
gioco vende, cioè la presenza in quel luogo.

**La durata della notte è un valore di tuning, non una costante.** È la variabile che
l'MVP esiste per misurare: deve restare cambiabile senza ricompilare.
