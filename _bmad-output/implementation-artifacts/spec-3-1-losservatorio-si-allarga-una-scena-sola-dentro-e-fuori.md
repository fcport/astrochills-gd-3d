---
title: "3.1 L'osservatorio si allarga — una scena sola, dentro e fuori"
type: 'feature'
created: '2026-08-23'
status: done
baseline_revision: '01fb10695a5d951273250ef7ea60b69aa061eca6'
review_loop_iteration: 0
followup_review_recommended: false
context:
  - '{project-root}/_bmad-output/project-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-context.md'
warnings: ['oversized']
deferred:
  - "Loop ambientali per luogo (cucina/cupola/esterno): dipendono da asset audio non ancora nel repo. Dichiarato SILENZIO come scelta attiva per ora — nessun AudioStreamPlayer3D ambientale aggiunto. Come le texture segnaposto, non si inventano asset. Il SequenceChime posizionale resta l'unico suono del luogo."
  - summary: >-
      Il telescopio segnaposto della cupola non ha volume di collisione: il giocatore ci cammina dentro.
    evidence: |-
      dome.tscn Telescope ha solo MeshInstance3D (Tube/LegA/LegB/LegC), nessun StaticBody3D.
      La fisicita' e l'eventuale volume di interazione del telescopio appartengono alla storia 3.5
      («La cupola — stare a guardare»), che possiede l'interagibile; la 3.1 ne colloca solo la massa
      visibile nella fascia occhio-portata. Aggiungere un collider ora anticiperebbe la 3.5.
    location: >-
      world/rooms/dome.tscn (Telescope)
    severity: low
operator_actions:
  - "Aprire il progetto in Godot 4.7.2 (editor) e confermare che world/observatory.tscn e le nuove scene (kitchen/dome/exterior) importano senza errori di parse/risorsa in console: nessun binario Godot era disponibile nell'ambiente di build, quindi le scene sono validate solo staticamente."
  - "Camminare la scena e verificare gli AC percettivi che l'ambiente headless non puo' controllare: stanza computer -> cucina in pochi secondi senza caricamenti; porta sud -> esterno di notte; ci si allontana fino a voltarsi a guardare l'edificio ma il bosco ferma; fessura della cupola mostra il cielo; nessuna caduta fuori mondo."
  - "Tarare all'occhio, guardando DA DENTRO E DA FUORI, la nebbia e il cielo dell'unico WorldEnvironment (fog_density 0,035, fog_light_color, colori del ProceduralSkyMaterial): i valori committati sono un punto di partenza geometrico, non trovati guardando come l'AC richiede. Verificare anche che la fessura della cupola non faccia entrare luce/cielo in modo da slavare l'interno."
  - "Chiudere l'AC audio «da fuori NON si sente»: con la sola distanza non e' raggiungibile (il punto appena fuori la porta sud, ~6,0 m, e' piu' vicino del centro cupola, ~7,7 m, che deve restare appena percettibile). Progettare un meccanismo location-aware — un Area3D che rileva il giocatore fuori e ammutolisce il SequenceChime, con default «udibile» come fallback sicuro (nessuna regressione del suono della 2.3) — e tararlo camminando/ascoltando. Vedi il commento in world/sequence_chime.tscn."
  - "Quando arriveranno il pack di texture e gli asset audio (vedi deferred): rifinire l'estetica segnaposto (cucina/cupola/telescopio/bosco/sterrata, silhouette esterna e cornice della porta sud) e aggiungere i loop ambientali per luogo."
---

<intent-contract>

## Intent

**Problem:** L'osservatorio oggi è una stanza sola (`world/rooms/computer_room.tscn`). L'epica 3 esiste per misurare se *l'attesa è piacevole*, e l'attesa ha bisogno di un posto dove succedere: la cucina, la cupola e il prato fuori. Il prototipo Phaser li teneva in tilemap separate; in 3D quella suddivisione non ha più ragione (due rettangoli 2D non si toccano, un edificio con un prato intorno sì).

**Approach:** Estendere `world/observatory.tscn` in **una scena sola** che contiene edificio (stanza computer + cucina + cupola, collegate a piedi) ed esterno (prato, sterrata, bosco perimetrale, porta sud), con **un solo `WorldEnvironment`** che unisce cielo notturno e nebbia dentro e fuori. Nessun cambio di scena, nessun caricamento, nessuna dissolvenza tranne quella del sonno (che esiste già). Geometria kit-bash segnaposto con lo stesso pattern della stanza computer, fino all'arrivo del pack di texture.

## Boundaries & Constraints

**Always:**
- **Una scena sola:** tutto vive dentro `world/observatory.tscn`. Nessun `change_scene`, nessun `ResourceLoader`/caricamento asincrono, nessuna seconda `SubViewport` del mondo. L'unica dissolvenza resta quella del sonno in `main.gd` (`_fade_to`), che è salto di TEMPO non di luogo — non toccarla e non aggiungerne altre.
- **Un solo `WorldEnvironment`:** riusare quello già in `observatory.tscn`. Cielo notturno e ambiente interno condividono lo stesso `Environment`; la nebbia che chiude le distanze fuori è la stessa che dà profondità dentro. La taratura di nebbia e cielo va trovata **guardandola da dentro E da fuori**, non stimata.
- **Isolamento cartelle:** in `world/` non deve comparire nessuna occorrenza di `phases/` né `night/`, nemmeno in un commento. Cercarle non deve dare risultati. `world/` può dipendere solo da `core/` e `crt/`.
- **Kit-bash come la stanza computer:** mesh box suddivise (la luce è per-vertice, `render_mode vertex_lighting`), `material_override` MAI `surface_material_override/0`, `ShaderMaterial` di `ps1.gdshader` **condivisi** fra superfici omogenee (una ritintura in un punto solo). Nessun mipmap, nessun filtro lineare, nessun AA (fuori periodo e fuori renderer).
- **La camera è la testa:** nessuna riga nuova sposta o riparenta la camera del giocatore. Il giocatore attraversa tutto a piedi.
- **Volume di interazione per ogni oggetto interagibile che questa storia colloca:** il raggio parte dall'occhio a 1,65 m e arriva a 1,20 m (`Player.INTERACT_RANGE`); una massa sotto i ~60 cm non è raggiungibile da nessuna posa. Il volume di interazione si progetta a parte dalla geometria visibile — alto abbastanza da stare nello sguardo, mai più alto di ciò che si vede — e si verifica misurando **da dove** l'oggetto è raggiungibile, non da un punto solo.
- **Il suono di fine sequenza (`SequenceChime`) NON si sposta:** la collocazione decisa dalla 2.3 resta (presso il monitor). La geografia sonora si ottiene tarando l'attenuazione (`unit_size`/`max_distance`) e disponendo le stanze alle distanze giuste, non muovendo il nodo.
- **Budget:** un edificio con asset PS1 sta in memoria. Se non ci stesse, la risposta è ridurre la geometria (segnaposto), MAI tornare a spezzare la scena o introdurre caricamento.

**Block If:**
- Il budget di memoria non regge nemmeno riducendo la geometria segnaposto (contraddirebbe l'invariante «una scena sola»): HALT `blocked`, condizione `budget di memoria incompatibile con scena unica`.

**Never:**
- Niente moka, lampadina, terminale funzionante o attività dell'attesa: quelli sono 3.2–3.7. Questa storia COSTRUISCE il posto, non le attività.
- Nessun muro invisibile in mezzo al prato: il confine è il bosco perimetrale, e si deve poter arrivare a voltarsi e guardare l'edificio, **non di più**.
- Nessun bonus meccanico, nessun contatore, nessun conto alla rovescia (regola dell'epica).
- Niente rete, niente networking (mai, in tutto il progetto).
- Non introdurre `CompositorEffect`/compute/`RenderingDevice`: Compatibility non li ha e non servono.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Uscita dalla stanza computer | Giocatore attraversa la porta est della stanza | Entra nell'atrio/cucina/cupola senza interruzione, caricamento o dissolvenza | Nessun errore atteso |
| Attraversamento porta sud | Giocatore attraversa la porta sud dell'edificio | Si trova fuori, di notte, e continua a camminare; l'edificio è visibile alle spalle | Nessun errore atteso |
| Bordo del mondo | Giocatore cammina verso il bosco perimetrale | Il bosco è un confine solido: ci si ferma lì, dopo essersi potuti voltare a guardare l'edificio | Il collider del bosco ferma il giocatore, nessuna caduta fuori mondo |
| Ascolto del chime da altrove | `Events.phase_finished("imaging", …)` mentre il giocatore è in cucina / cupola / fuori | Ovattato dalla cucina, appena percettibile dalla cupola, inudibile da fuori | Nessun errore atteso |
| Fine posa senza giocatore alla postazione | Chime suona mentre si è in giro | Suona comunque dal luogo (posizionale), attenuato dalla distanza | Nessun errore atteso |

</intent-contract>

## Code Map

- `world/observatory.tscn` -- **scena container da estendere.** Istanzia stanza computer, monitor, player, chime, letto e ha l'unico `WorldEnvironment`. Qui si appendono cucina, cupola ed esterno; qui si aggiungono nebbia e cielo all'`Environment`. L'intestazione documenta la catena di quote del monitor e la proprietà del chime: NON disturbare monitor, chime, letto, player.
- `world/rooms/computer_room.tscn` -- **pattern kit-bash da replicare** (mesh box suddivise, `ShaderMaterial` condivisi, `material_override`). Contiene già l'apertura est (WallRightA/B lasciano un varco a z∈[1.0,1.9], x=+2.075) chiusa da un nodo `Door` solido: questa storia rende quel varco **percorribile**. Header vieta di nominare il percorso degli strumenti di taratura anche nei commenti.
- `world/rooms/kitchen.tscn` -- **da creare.** Cucina kit-bash collegata all'edificio; segnaposto per il piano cottura/lampada (attività di 3.3/3.4, non qui).
- `world/rooms/dome.tscn` -- **da creare.** Cupola con **fessura** aperta sul cielo e **telescopio** segnaposto visibile da vicino.
- `world/rooms/exterior.tscn` -- **da creare.** Prato (piano di terra), sterrata (striscia di materiale diverso), bosco perimetrale (anello di geometria segnaposto con collisione = confine), guscio esterno dell'edificio visibile.
- `world/shaders/ps1.gdshader` -- materiale del mondo (`vertex_lighting`, snap 665). Compatibility applica la nebbia dell'`Environment` alle superfici spatial automaticamente: **verificare guardando** che le superfici ps1 sfumino nella nebbia; se non lo fanno, gestire la nebbia nel `fragment()` senza toccare snap/lighting. Nessun mipmap/AA.
- `world/player/player.gd` + `player.tscn` -- `EYE_HEIGHT=1.65`, `INTERACT_RANGE=1.2`, `walk_speed=2.0`/`sprint=4.0`, capsula raggio 0,3, `collision_mask=1` (mondo). Il raggio interazione cerca `LAYER_WORLD|LAYER_INTERACTABLE`. Solo lettura: serve a verificare percorribilità, tempi e la regola dei volumi di interazione.
- `world/sequence_chime.gd` + `.tscn` -- chime del luogo, filtra `Events.phase_finished` su `&"imaging"`. Oggi `unit_size=6.0`, `max_distance=30.0`, `max_db=3.0` a `(0, 1.1, -2.05)`. Tarare l'attenuazione; **non** cambiare la `transform` (posizione della 2.3).
- `world/interactables/interactable.gd` -- base `StaticBody3D` per eventuali interagibili (layer 1|3, prompt IT). Regola dei volumi di interazione.
- `main.gd` + `main.tscn` -- punto d'ingresso: trova player/monitor/letto **per gruppo**, monta il mondo dentro una `SubViewport` a bassa risoluzione, possiede la sola dissolvenza del sonno. Deve continuare a funzionare senza modifiche.
- `_bmad-output/project-context.md` -- vincoli PS1 (no mipmap/AA/filtro lineare, snap 665, un solo `WorldEnvironment`, budget `SubViewport`), tabella dipendenze cartelle (`world/`↛`phases/`,`night/`), «la nebbia è un vincolo, non una comodità».

## Tasks & Acceptance

**Execution:**
- `world/rooms/computer_room.tscn` -- rendere **percorribile** il varco est (rimuovere o aprire il nodo `Door` solido così che il giocatore possa uscire; il `DoorLintel` sopra resta) -- oggi la porta è un blocco solido e nel MVP nessuno usciva; ora si esce.
- `world/rooms/kitchen.tscn` -- creare la cucina kit-bash (pareti/pavimento/soffitto con mesh box suddivise, `ShaderMaterial` ps1 condivisi, `material_override`), collegata all'edificio da un varco percorribile, a **pochi secondi a piedi** dalla stanza computer -- il registro «fare» dell'attesa vive qui (3.3/3.4).
- `world/rooms/dome.tscn` -- creare la cupola: volume percorribile con una **fessura** aperta da cui si vede il cielo, e un **telescopio** segnaposto visibile da vicino; se il telescopio è collocato come futuro interagibile, il suo volume rispetta la regola occhio-1,65 → 1,20 m -- è il registro «stare».
- `world/rooms/exterior.tscn` -- creare l'esterno: piano di terra (prato), striscia sterrata, **bosco perimetrale** come anello con collisione (il confine), guscio esterno dell'edificio con la **porta sud** percorribile; ci si allontana quanto basta a voltarsi e guardare l'edificio, non di più -- «non ti allontani mai dall'edificio» (brief).
- `world/observatory.tscn` -- istanziare kitchen/dome/exterior e disporle in un'unica pianta coerente e percorribile senza soluzione di continuità; estendere l'unico `Environment` con **nebbia** e **cielo notturno** (`background_mode = Sky`, `fog_enabled`), tarati da dentro e da fuori; NON spostare monitor/chime/letto/player -- unifica dentro e fuori in un solo spazio e un solo ambiente.
- `world/sequence_chime.tscn` -- tarare `unit_size`/`max_distance` (senza muovere il nodo) perché il chime risulti ovattato dalla cucina, appena percettibile dalla cupola e inudibile da fuori -- geografia sonora della 3.1 sopra la collocazione della 2.3.
- Ambiente sonoro per luogo: dove esiste il **silenzio come scelta attiva** è sufficiente e va dichiarato; i loop ambientali per cucina/cupola/esterno dipendono da asset audio non ancora nel repo → registrare come **deferred** (come le texture segnaposto), non inventare asset.

**Acceptance Criteria:**
- Given il mondo di gioco, when si guarda com'è costruito, then è **una scena sola** (`world/observatory.tscn`) con edificio e terreno, senza nessun cambio di scena, caricamento o dissolvenza fra le aree (resta solo quella del sonno).
- Given il giocatore nella stanza computer, when esce, then cucina e cupola sono percorribili a piedi senza interruzione, e il tragitto stanza computer → cucina si copre in **pochi secondi** (a `walk_speed=2.0`).
- Given la porta sud, when il giocatore la attraversa, then si trova fuori, di notte, e continua a camminare; ci sono prato, sterrata e bosco perimetrale, l'edificio è lo stesso ed è visibile da fuori, e ci si può allontanare **solo** fino a voltarsi a guardarlo (il bosco è il confine).
- Given un solo `WorldEnvironment`, when si passa da dentro a fuori, then cielo notturno e ambiente interno convivono nello stesso `Environment` senza stacco, e la stessa nebbia chiude le distanze fuori e dà profondità dentro.
- Given il `SequenceChime` presso il monitor, when lo si ascolta da cucina/cupola/fuori, then è ovattato dalla cucina, appena percettibile dalla cupola, **inudibile da fuori**, e la sua posizione (2.3) non è stata spostata.
- Given la cupola, when il giocatore ci entra, then c'è una fessura da cui si vede il cielo e il telescopio è lì, visibile da vicino.
- Given la resa, when si guarda qualsiasi luogo, then usa `ps1.gdshader` e la nebbia dell'`Environment` come il resto del mondo (nessun mipmap/AA/filtro lineare introdotto).
- Given le regole di dipendenza, when si cerca `phases/` o `night/` dentro `world/`, then non c'è nessuna occorrenza (nemmeno nei commenti).
- Given la scena unica, when si avvia il gioco, then la sequenza esistente (postazione, fasi, sonno/risveglio di `main.gd`) continua a funzionare senza regressioni.

## Design Notes

**Pianta di riferimento (esempio, non vincolo esatto): l'implementatore la rifinisce camminando.** Misure in metri, la stanza computer resta dov'è (interno x∈[−2,+2], z∈[−2,5,+2,5], pavimento y=0; porta est a x=+2, z∈[1,0,1,9]). Orientamento: il giocatore parte guardando −z (monitor a nord); quindi −z=nord, +x=est, +z=sud.

- **Atrio** a est della stanza computer (x∈[+2,+5]): raccorda i tre ambienti; sul suo lato sud (+z) sta la **porta sud** verso il prato.
- **Cucina** a nord-est, ~3×3 m, aperta sull'atrio; ~7 m dal centro stanza computer (≈3,5 s a piedi, «pochi secondi»).
- **Cupola** a sud-est: pianta ottagonale/cilindrica ~Ø5 m, più alta (tetto ~4,5 m), **fessura** rettangolare aperta nel tetto verso il cielo, **telescopio** segnaposto (tubo su treppiede, kit-bash) al centro.
- **Esterno**: prato a sud/intorno; **sterrata** che si allontana; **bosco perimetrale** ad anello (r ≈ 12–16 m) con collisione = confine. Nessun muro invisibile: il bosco è la cosa che ti ferma.

Golden pattern (dal `computer_room.tscn`, da riusare per ogni superficie):
```
[node name="WallX" type="StaticBody3D" parent="."]
  collision_mask = 0            # ferma il giocatore, non insegue nulla
  [MeshInstance3D] material_override = SubResource("MatWall")  # MAI surface_material_override
                  mesh = BoxMesh(subdivide_* > 1)              # luce per-vertice
  [CollisionShape3D] shape = BoxShape3D
```

**Nebbia + cielo (Compatibility):** `Environment.background_mode = 2` (Sky) con `Sky` + `ProceduralSkyMaterial` scuro notturno (le stelle vere arrivano col pack di asset — segnaposto ora); `fog_enabled = true`, `fog_mode` a densità, `fog_light_color` freddo, `fog_density` bassa: leggibile in una stanza di 4–5 m, chiude le distanze a 10–16 m fuori. Tarare guardando da dentro e da fuori: se le superfici `ps1.gdshader` non ricevono la nebbia automaticamente, aggiungere la miscela nebbia nel `fragment()` senza toccare snapping/lighting.

**Asset segnaposto:** stanza e materiali sono segnaposto fino al pack di texture — geometria kit-bash grezza, non rifinire l'estetica adesso. Vale per cucina, cupola, telescopio, bosco, sterrata.

**Suono:** il chime si tara per distanza (nessuna occlusione da muri in Compatibility): cucina più vicina della cupola, esterno il più lontano; `max_distance` scelto perché fuori sia già sotto la soglia di udibilità. Verificare **camminando**, non leggendo numeri.

## Verification

**Commands:**
- `godot --headless --path . --quit` -- expected: il progetto importa le nuove scene senza errori di parse/risorsa (se `godot` 4.7.2 è nel PATH; altrimenti aprire il progetto nell'editor e controllare l'assenza di errori in console).
- `rg -n "phases/|night/" world/` -- expected: nessun risultato (isolamento cartelle).

**Manual checks (camminando nel gioco):**
- Uscire dalla stanza computer e raggiungere cucina e cupola senza mai un caricamento o una dissolvenza; cronometrare stanza computer → cucina: pochi secondi.
- Attraversare la porta sud, camminare sul prato, voltarsi e vedere l'edificio; provare a superare il bosco: ci si ferma.
- Guardare la fessura della cupola: si vede il cielo; il telescopio è lì vicino.
- Da dentro e da fuori: la nebbia e il cielo sono coerenti, il passaggio non stacca.
- Con `F9`/flusso della notte far scattare il fine-sequenza e ascoltarlo da cucina (ovattato), cupola (appena), esterno (niente).
- Avviare la notte, sedersi al monitor, dormire e risvegliarsi: nessuna regressione di `main.gd`.

## Spec Change Log

### 2026-08-23 — Rilievo audio (bad_spec) instradato all'operatore
- **Finding:** l'AC «il `SequenceChime` è inudibile da fuori» non è raggiungibile con la sola attenuazione per distanza prescritta dalle Design Notes/Tasks: il punto appena fuori la porta sud (~6,0 m dal chime) è più vicino del centro cupola (~7,7 m), che deve restare «appena percettibile», e Compatibility non offre occlusione dei muri. Nessun `max_distance` separa i due casi.
- **Amendment:** il commento di `world/sequence_chime.tscn` è stato reso onesto (dichiara il limite e indica il meccanismo location-aware necessario), ed è stato aggiunto un `operator_actions` che chiede di progettare+tarare un Area3D che ammutolisce il chime quando il giocatore è fuori, con default «udibile» come fallback sicuro.
- **Perché NON un loopback bad_spec classico:** la geometria implementata è corretta e verificata staticamente; un revert+ri-derivazione totale la rigenererebbe alla cieca (rischio di regressione su 60 alberi e transform precisi) e comunque NON potrebbe verificare l'audio, che richiede l'orecchio di un umano. Per la direttiva d'invocazione questa storia è «finita fin dove un agente può portarla»: il residuo audio è owed all'operatore, non un blocco.
- **KEEP:** mantenere l'intera geometria kit-bash (atrio inline, cucina/cupola/esterno), il singolo `WorldEnvironment` con cielo+nebbia, la posizione invariata del chime (contratto 2.3) e l'attenuazione tarata (`unit_size=2,5`, `max_distance=10`) come base per cucina/cupola.

## Review Triage Log

### 2026-08-23 — Review pass
- intent_gap: 0
- bad_spec: 1: (high 0, medium 1, low 0)
- patch: 2: (high 0, medium 0, low 2)
- defer: 1: (high 0, medium 0, low 1)
- reject: 12
- addressed_findings:
  - `[medium]` `[bad_spec]` AC audio «inudibile da fuori» non raggiungibile con la sola distanza (fuori è più vicino della cupola; niente occlusione in Compatibility) — commento di `sequence_chime.tscn` reso onesto + `operator_actions` per il meccanismo location-aware; instradato all'operatore invece del loopback distruttivo (vedi Spec Change Log).
  - `[low]` `[patch]` commento estensioni atrio in `observatory.tscn` impreciso e allarmante su un presunto seam pavimento — corretto: lastra 5,3 profonda che SOVRAPPONE la soglia cucina (nessun buco).
  - `[low]` `[patch]` commento geografia sonora in `sequence_chime.tscn` affermava «esterno >10 m inudibile» (falso: fuori è ~6 m) — reso onesto sul limite reale.
- **Reject (rumore o non-problemi verificati ricalcolando):** seam pavimento atrio↔cucina (in realtà overlap 7,5 cm, nessun gap); bosco attraversabile (caso peggiore edge-gap ~1 cm << capsula 0,6 m); caduta fuori dal piano 40×40 (il bosco ferma prima); `load_steps` da ricontrollare (corretti: 26/27/14/14/14); offset sterrata ~10 cm (cosmetico); z-fighting sterrata/prato (1 cm, segnaposto); silhouette esterna incompleta su cucina/cupola (hanno tetto/soffitto propri; segnaposto); cornice porta sud da fuori (segnaposto); mismatch albedo atrio/cucina (segnaposto); bleed luce Fill tra soglie aperte (voluto, ambiente unico); step 2 cm soglia interno/esterno (trascurabile per la capsula); slit end-caps cupola (segnaposto, aperto sul cielo è l'intento).

## Auto Run Result

Status: awaiting-operator

**Change implementato:** `world/observatory.tscn` diventa UNA scena sola, dentro e fuori. La stanza computer resta invariata; a est si aggiunge un atrio (geometria inline) che raccorda una **cucina** e una **cupola** (nuove scene kit-bash) e, per la porta sud, l'**esterno** (prato, sterrata, bosco perimetrale che è il confine). Un solo `WorldEnvironment` ora ha cielo notturno (`Sky`+`ProceduralSkyMaterial`) e **nebbia**, condivisi dentro e fuori. Nessun cambio di scena, nessun caricamento, nessuna dissolvenza nuova (resta solo quella del sonno). Il chime di fine posa non si sposta: solo l'attenuazione è tarata.

**File cambiati:**
- `world/observatory.tscn` — atrio inline + istanze cucina/cupola/esterno; `Environment` esteso con cielo+nebbia (`load_steps` 8→26); esistenti (monitor/chime/letto/player) non toccati.
- `world/rooms/computer_room.tscn` — porta est solida rimossa: il varco est è ora percorribile (`load_steps` 30→27); `DoorLintel` resta.
- `world/rooms/kitchen.tscn` — NEW: cucina kit-bash 3×3, aperta sull'atrio, piano d'appoggio segnaposto (moka/lampada sono 3.3/3.4).
- `world/rooms/dome.tscn` — NEW: cupola ottagonale ~Ø5, fessura sul cielo, telescopio segnaposto nella fascia occhio-portata.
- `world/rooms/exterior.tscn` — NEW: prato 40×40 + collider piatto, sterrata, bosco a 60 tronchi (collisori sovrapposti = confine solido), tetto segnaposto.
- `world/sequence_chime.tscn` — attenuazione tarata (`unit_size` 6→2,5, `max_distance` 30→10); posizione invariata; commento reso onesto sul limite audio.
- `world/sequence_chime.gd` — solo commento: rimosso il literal `phases/` (isolamento cartelle).

**Review findings:** 2 patch applicate (commenti fuorvianti resi onesti); 1 bad_spec (audio inudibile-da-fuori) instradato all'operatore con meccanismo prescritto; 1 defer (collisione telescopio → 3.5); 12 reject (cosmetici/segnaposto o non-problemi verificati ricalcolando).

**Verifica eseguita:** `rg "phases/|night/" world/` → nessuna occorrenza (isolamento cartelle OK). Validazione statica di tutte le scene: `load_steps` corretti, ogni `ExtResource`/`SubResource` risolve, nessun nome di nodo duplicato fra fratelli, geometria ricontrollata numericamente (varchi allineati, pavimenti che si sovrappongono senza seam, anello del bosco solido, telescopio nella fascia 1,35–1,75 m). **Nessun binario Godot nell'ambiente**: `godot --headless` non eseguibile, e gli AC percettivi (camminare/guardare/ascoltare) e la taratura all'occhio/orecchio di nebbia, cielo e audio non sono verificabili headless — vedi `operator_actions`.

**Rischi residui:**
- Nebbia/cielo/chime committati con valori di partenza geometrici, non «trovati guardando/ascoltando» come gli AC richiedono: taratura umana owed.
- L'AC audio «da fuori non si sente» resta non soddisfatto finché non si aggiunge il meccanismo location-aware (owed all'operatore).
- Estetica interamente segnaposto fino al pack di texture/audio (coerente con la memoria di progetto sugli asset provvisori).

## Operator Confirmation

Confirmed 2026-08-24: the external actions this story owed were carried out.

- Aprire il progetto in Godot 4.7.2 (editor) e confermare che world/observatory.tscn e le nuove scene (kitchen/dome/exterior) importano senza errori di parse/risorsa in console: nessun binario Godot era disponibile nell'ambiente di build, quindi le scene sono validate solo staticamente.
- Camminare la scena e verificare gli AC percettivi che l'ambiente headless non puo' controllare: stanza computer -> cucina in pochi secondi senza caricamenti; porta sud -> esterno di notte; ci si allontana fino a voltarsi a guardare l'edificio ma il bosco ferma; fessura della cupola mostra il cielo; nessuna caduta fuori mondo.
- Tarare all'occhio, guardando DA DENTRO E DA FUORI, la nebbia e il cielo dell'unico WorldEnvironment (fog_density 0,035, fog_light_color, colori del ProceduralSkyMaterial): i valori committati sono un punto di partenza geometrico, non trovati guardando come l'AC richiede. Verificare anche che la fessura della cupola non faccia entrare luce/cielo in modo da slavare l'interno.
- Chiudere l'AC audio «da fuori NON si sente»: con la sola distanza non e' raggiungibile (il punto appena fuori la porta sud, ~6,0 m, e' piu' vicino del centro cupola, ~7,7 m, che deve restare appena percettibile). Progettare un meccanismo location-aware — un Area3D che rileva il giocatore fuori e ammutolisce il SequenceChime, con default «udibile» come fallback sicuro (nessuna regressione del suono della 2.3) — e tararlo camminando/ascoltando. Vedi il commento in world/sequence_chime.tscn.
- Quando arriveranno il pack di texture e gli asset audio (vedi deferred): rifinire l'estetica segnaposto (cucina/cupola/telescopio/bosco/sterrata, silhouette esterna e cornice della porta sud) e aggiungere i loop ambientali per luogo.

_Appended by the bmad-loop orchestrator (`bmad-loop confirm`, #335): a human confirmed these external actions out of band, and the story was advanced from `awaiting-operator` to `done`._
