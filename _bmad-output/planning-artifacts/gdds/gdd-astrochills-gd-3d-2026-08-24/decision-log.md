# Decision log — GDD Astrochill

Ogni decisione, cambiamento e transizione di stato, in tempo reale. Il GDD è il documento;
questo è come ci si è arrivati.

---

## 2026-08-24 — Apertura

**Stato:** `draft` · versione 0.1 · workspace creato.

**Fonti d'ingresso lette:**

- `_bmad-output/planning-artifacts/briefs/brief-astrochills-gd-3d-2026-08-21/brief.md`
- `.../addendum.md`
- `_bmad-output/planning-artifacts/cosa-ha-insegnato-il-prototipo.md`
- Telemetria reale: `%APPDATA%/Godot/app_userdata/Astrochill/telemetry/night-{2,3}.json`
- Da leggere alla bisogna: `docs/idea/{idea,economia,minigiochi}.md`, `epics.md`, `game-architecture.md`

---

### D-001 — Game type: Simulation con innesto Adventure

**Decisione.** Lo scheletro del GDD è **Simulation** (alta complessità: mappa dei sistemi,
bilanciamento a lungo termine, confini dell'emergenza, definizione dello stato finale),
esteso con le sezioni **Adventure** (esplorazione, integrazione narrativa, narrazione
ambientale) per le venti notti di storia e i finali.

**Perché.** Il gioco è per metà un sistema (fasi, economia, upgrade, ciclo notte) e per
metà una linea narrativa a venti tappe. Il solo scheletro Simulation lascerebbe la
metanarrazione senza casa; il solo Adventure lascerebbe scoperto tutto ciò che il
prototipo ha già costruito.

**Conseguenza.** Il fragment Adventure porta il flag `narrative-workflow-recommended` →
**`needs_narrative: true`**. A GDD chiuso va offerto `gds-create-narrative`.

---

### D-002 — Il bivio del §5 è sciolto: aspettare annoia, l'automazione è il premio

**Decisione di Federico**, presa davanti al dato di telemetria.

**Il dato.** Due notti misurate, `tuning_hash` identico (`1b7b29b2`):

| Notte | `wait_total_min` | Tratti dentro la finestra della posa |
|---|---|---|
| 2 | 39,0 | un solo tratto `idle` da 39,0 min — **100% vuota** |
| 3 | 40,0 | un solo tratto `idle` da 40,0 min — **100% vuota** |

Nella notte 3 forum (3 visite) e lampada compaiono a `t=210s`+, cioè **dopo** la fine
della posa (finestra t=59→99); un caffè risulta `abandoned`. Le attività dell'attesa
sono state usate fuori dalla finestra che dovevano riempire.

**Conseguenza.** Il **pilastro 2 del brief — «L'attesa è il gioco»** — non sopravvive nella
forma attuale. L'albero degli upgrade di `idea.md §7` (si compra automazione per liberarsi
delle fasi) **regge com'è**. Le quattro attività dell'epica 3 vanno riqualificate: non sono
più lo strumento centrale di validazione dell'ipotesi cozy.

**Tensione aperta da lavorare in sessione 1.** Se aspettare annoia, cosa regge il *chill*
del titolo e del posizionamento cozy? La conversione «lire → tempo che si svaluta»
(`addendum §4`) presuppone che il tempo restituito valga qualcosa: va detto cosa lo riempie.

**Riserva metodologica registrata (non annulla la decisione).** Il collaudo è stato fatto
dall'autore, non da un playtester, e il §4 del dossier documenta che le attività non si
annunciano a schermo. Il dato è quindi contaminato dalla scopribilità. Federico ha deciso
comunque, avendo visto il numero.

---

### D-003 — Modalità di lavoro: facilitativa

Le sezioni che richiedono pensiero di design — pilastri, core loop, meccaniche, sezioni di
genere — si camminano una alla volta prima di stendere il documento.


---

## Sessione 1 — I pilastri

### D-004 — Quattro pilastri, con la fusione del cozy

**Decisione.** I pilastri sono quattro:

1. **Il lavoro è vero** (invariato dal brief)
2. **L'osservatorio è un rifugio** (nuovo)
3. **Gli strumenti mentono** (invariato dal brief)
4. **Il tempo liberato ti espone** (promosso da comprimario a motore)

**Il pilastro 2 nasce fondendo due scelte di Federico** — «Il posto diventa tuo» (cura e
comfort: lampada, moka, stufetta, cigolio) e «Non si perde mai» (no-fail, nessuna
pressione, commessa rifiutabile). Fusi invece che tenuti a cinque perché dicono la stessa
cosa da due lati — il posto è sicuro — e soprattutto perché **fusi hanno una sola rottura
narrativa**: il rifugio che ti sei costruito ha un ospite. Separati, quella rottura si
sdoppia e si indebolisce.

**Conseguenza sull'epica 3.** Caffè, lampada, cupola e forum non sono più «le attività
dell'attesa» (ruolo caduto con D-002): sono **il lato attivo del pilastro 2**, cioè il modo
in cui il posto diventa tuo. Restano nel gioco con una giustificazione diversa e migliore.

**Stato del pilastro 3.** Registrato nel GDD come **mai dimostrato**: il seam esiste
(`PhaseTruthSource` + `F9`), zero rotture sono implementate. è l'unico pilastro-promessa.

---

### D-005 — Il tempo liberato ha quattro destinazioni

Esplorare i dintorni · l'edificio che si apre stanza dopo stanza · indagare le anomalie
prodotte dagli strumenti · fotografare ancora.

Le prime tre sono **esposizione** e vanno **scaglionate lungo le venti notti** (da definire
nella sessione Progressione: quale serbatoio si apre quando). La quarta non espone a
niente ed è il fallback sempre disponibile.

---

### D-006 — Il grind resta permesso, senza limiti

**Decisione di Federico**, presa davanti al conflitto sollevato in sessione.

**Il conflitto.** Ammettere «più foto» come destinazione del tempo liberato chiude il
ciclo `tempo -> pose -> lire -> upgrade -> tempo`, che rende di nuovo razionale macinare
durante la storia. L'`addendum §4` costruiva l'argomento opposto («il grind si punisce da
solo», la conversione lire->tempo si svaluta a ogni notte) e chiedeva esplicitamente di non
romperlo in fase di tuning.

**Decisione.** Il grind è permesso e non limitato. **L'argomento dell'`addendum §4` esce
quindi dal canone** e va rimosso dai documenti sorgente, non lasciato in contraddizione
(vedi voce di manutenzione sotto).

**Cosa il GDD guadagna in cambio.** Messa accanto alla commessa rifiutabile e al no-fail,
la scelta produce una regola trasversale, ora scritta in fondo alla sezione Pilastri:
**Astrochill offre e non obbliga mai.** Il gioco mette a disposizione e sta a guardare —
che è, a conti fatti, anche la descrizione di ciò che lo abita.

**Vincolo che ne discende, da rispettare nella sessione Progressione.** La progressione
narrativa avanza **per notte, non per foto**. Senza questo, macinare lire ritarderebbe la
storia e diventerebbe una punizione mascherata — contro il pilastro 2.

---

### Manutenzione dei documenti sorgente - debito aperto

Da riportare a valle del GDD, altrimenti i documenti divergono (si aggiunge alla lista
già presente in `addendum §1`):

| File | Cosa correggere | Origine |
|---|---|---|
| `addendum §4` | L'intero argomento «perché il grind si punisce da solo» è superato | D-006 |
| `brief.md` | Il pilastro 2 «L'attesa è il gioco» è caduto; i pilastri sono i quattro di D-004 | D-002, D-004 |
| `brief.md` | L'MVP dichiara come ipotesi da validare «l'attesa è piacevole»: validata come **falsa** | D-002 |
| `idea.md §7` | L'albero degli upgrade regge, ma il tempo liberato ha quattro destinazioni dichiarate | D-005 |


---

## Sessione 2 — Il core loop

### D-007 — Una notte dura un'ora reale: `game_min_per_sec = 0,15`

**Il conflitto trovato.** Il brief dichiara notti da «circa un'ora»; il prototipo gira a
`0,6`, cioè 540 minuti di gioco in **15 minuti reali**. Fattore 4 sulla durata del gioco:
5 ore contro 20.

**Decisione.** Vale il brief: `game_min_per_sec = 0,15`, notte = **60 minuti reali**, venti
notti ≈ **20 ore** più il free play.

**Perché.** Non è taratura, è ciò da cui dipende se D-005 sta in piedi. A `0,6` una posa da
20×120s dura **67 secondi reali**: in 67 secondi non si esplora un bosco, non si legge una
lettera, non si indaga un'anomalia. A `0,15` la stessa posa dura **4 minuti e mezzo**, che è
il tempo di un giro fuori o di una stanza. Le tre destinazioni-esposizione richiedono la
finestra lunga.

**Conseguenza di produzione.** Venti ore di gioco vanno riempite: il fabbisogno di contenuto
quadruplica rispetto all'ipotesi implicita del prototipo. Da guardare in Progressione.

**Chiude l'esperimento dell'MVP.** Il commento in `core/tuning_profile.gd` definisce
`night_length_min` e `game_min_per_sec` «LA variabile sperimentale dell'MVP». Il valore è
ora fissato dal GDD.

---

### D-008 — La posa ti aspetta

Quando la posa finisce mentre il giocatore è altrove, lo stack **resta pronto** finché non
torna al monitor. Nessun minuto perduto, nessuna corsa, nessuna penalità economica
implicita per essere usciti.

**Perché.** Le alternative (la notte che scorre mentre il telescopio è fermo, oppure la
sequenza che riparte da sola) reintroducono rispettivamente una punizione morbida per chi
esplora — contro il pilastro 2 — e un'automazione del targeting, che è una delle due cose
che per regola invariante non si automatizzano mai.

---

### D-009 — L'ora è sempre conoscibile: orologio da polso, a richiesta

**Richiesta esplicita di Federico in sessione:** «deve sempre essere possibile sapere che
ora è, altrimenti non si capisce nulla».

**Stato trovato.** `night/night_clock.gd` produce già `clock_text()`, ma l'unico consumatore
è `debug/debug_overlay.gd`: **nel gioco vero l'ora non è visibile da nessuna parte.**

**Decisione.** Orologio da polso digitale, consultabile con un tasto: il personaggio alza il
polso, l'ora compare per qualche secondo. Diegetico al cento per cento — nessuna eccezione
alla regola che ogni interfaccia vive nel mondo — e copre ogni punto raggiungibile, bosco
compreso. Restano in aggiunta gli orologi del mondo dove esistono già (taskbar Windows 98
sul CRT).

**Rischio accettato e tracciato.** La consultazione a richiesta dipende dalla scopribilità
del tasto, e il dossier §4 documenta che il primo giocatore non ha trovato nemmeno i tasti
esistenti. **Un orologio che si consulta con un tasto mai nominato equivale a non avere un
orologio.** Il problema va risolto nella sezione Controlli e input, per tutte le azioni.

---

### D-010 — Il segnale di fine posa viene dall'edificio

Un suono dalla stanza computer più una luce alla finestra, visibile dal prato. Non un
avviso al giocatore: una cosa che l'osservatorio fa.

**Perché non l'allarme al polso.** Un segnale con una **sorgente fisica nel mondo può
partire quando non doveva**, e questo lo rende materiale per il pilastro 3: una luce che si
accende mentre la posa non è finita è narrazione, mentre un allarme al polso che suona da
solo sarebbe letto come un bug.

**Aperto:** che il segnale raggiunga il bosco va verificato guardando, non a tavolino. Se
non arriva, serve un secondo vettore o il bosco esce dalle destinazioni raggiungibili
durante una posa.


---

### D-011 — Il monitor CRT sarà rifatto: la sua risoluzione è una decisione di design

**Comunicato da Federico in sessione:** «sicuro comunque rifaremo il monitor CRT».

**Perché entra nel GDD e non nella lista degli asset.** La risoluzione del CRT non è una
scelta estetica: è **il vincolo che decide quanto contenuto sta in una schermata**. A
256×192 la descrizione di M42 ha già costretto a rifare un layout una volta. Ogni schermata
di ogni fase, il terminale e la BBS dipendono da quel numero.

**Vincolo di sequenza.** La risoluzione target va fissata **con il rifacimento del monitor,
prima** che siano scritte le sette fasi mancanti. Sette schermate progettate su una
risoluzione e poi riportate su un'altra sono sette layout da rifare — lo stesso errore già
pagato una volta, moltiplicato per sette.

**Registrato anche:** i materiali e la stanza attuali sono segnaposto in attesa di un pack
di texture e non vanno rifiniti.


---

### D-012 — Italiano e inglese selezionabili, con tre livelli di testo

**Decisione di Federico:** lingua selezionabile nelle impostazioni, IT ed EN; fanno
eccezione gli oggetti del mondo con testo dipinto (poster e simili).

**La regola completa, come è finita nel GDD** (*Specifiche tecniche → Lingue e
localizzazione*):

| Livello | Cosa | Comportamento |
|---|---|---|
| 1 — la voce del gioco | narrativa, log, lettere, giornali, descrizioni dei target, committenti, BBS, negozio, menu | localizzato IT/EN |
| 2 — la lingua delle macchine | interfacce dei software tecnici, campi `EXPOSURE` / `FRAMES` / `TARGET` | sempre inglese |
| 3 — gli oggetti del mondo | poster, insegne, targhe, etichette, riviste | sempre italiano, dentro le texture |

**Il confine 1/2 non è «software sì / software no».** Il criterio è **chi ha scritto quel
testo nella finzione**: la BBS Cygnus, il negozio del terminale e le e-mail dei committenti
sono roba scritta da italiani nel 1999, quindi livello 1 anche se compare su uno schermo. I
menu della camera CCD no.

**Cosa risolve.** Chiude la questione di mercato aperta in sessione: il pubblico primario
dello scaffale cozy è in larga parte anglofono e questo è un gioco molto testuale.

**Stato trovato nel progetto.** Nessuna infrastruttura: niente `internationalization/locale`
in `project.godot`, nessun file di traduzione, nessun `tr()`, testi come stringhe fisse nel
codice. I testi già in inglese delle schermate (`EXPOSURE`, `FRAMES`, `TARGET`) sono però
**corretti così** — sono livello 2 e non vanno toccati.

**Due conseguenze da non perdere.**

1. Nessun testo di livello 1 può restare una stringa fissa nel codice. Ogni testo scritto da
   qui in avanti senza infrastruttura di localizzazione è debito moltiplicato per due lingue.
2. **Cambia il calcolo di D-011.** L'italiano occupa il 15-20% di caratteri in più
   dell'inglese: la risoluzione del CRT va scelta **sul testo più lungo delle due lingue**, e
   ogni layout va verificato in entrambe.


---

### D-013 — Anche le interfacce degli strumenti seguono la lingua scelta (supera il livello 2 di D-012)

**Decisione di Federico:** «anche la lingua delle macchine la voglio dipendente da IT/EN in
settings».

**Cosa cambia rispetto a D-012.** Il livello 2 passa da «sempre inglese» a «localizzato
IT/EN». I livelli 1 e 3 restano come stabiliti.

**Rilievo sollevato in sessione e superato.** Nel 1999 CCDOPS, MaxIm DL e Cartes du Ciel non
esistevano in italiano: un software tradotto è un software che non è mai esistito, e la
credibilità tecnica è ciò su cui poggia il pilastro 1.

**Perché la decisione regge comunque.** Le schermate CRT non sono atmosfera, sono
**l'interfaccia funzionale del gioco**: chi non legge l'inglese non perde colore, non può
giocare. E un'impostazione su «Italiano» che lascia in inglese metà del testo da leggere è
un'impostazione rotta. L'accessibilità qui pesa più della fedeltà.

**La mitigazione adottata, che recupera quasi tutto il pilastro 1.** Si traduce *come
traduceva un astrofilo italiano del 1999*: il gergo tecnico resta in inglese dentro la frase
italiana, perché è così che si parlava davvero — **dark, flat, stacking, seeing, guiding,
plate solving, tracking**. `FRAMES` diventa `POSE`, non `FOTOGRAMMI`; `PLATE SOLVING` e
`STACKING` restano tali. Il GDD porta la tabella del registro corretto.

**Costi che ne discendono.**

1. Le tre schermate già scritte (`imaging`, `targeting`, `polar`) hanno i campi come stringhe
   inglesi fisse nel codice: vanno rifatte passando da chiavi.
2. **Il vincolo di D-011 si aggrava.** Sulle etichette dei campi la differenza di lunghezza è
   brutale: `EXPOSURE` 8 caratteri, `ESPOSIZIONE` 11. Ogni schermata va progettata sulla
   stringa più lunga fra le due lingue. La risoluzione del CRT non decide più solo la
   leggibilità: decide **se le etichette italiane ci stanno**.

---

## Sessione 3 — Meccaniche e controlli

### D-014 — Il budget della notte in minuti di gioco

**Il numero che nessun documento aveva.** `minigiochi.md` descrive le dieci fasi con
minigioco, rottura e upgrade, ma non dice quanto ciascuna costa in minuti di notte — cioè
manca proprio il dato che rende concreta la promessa «l'automazione ti restituisce tempo».
Costruito in sessione e confermato da Federico come base da tarare sul campo.

Notte = 540 minuti di gioco = 60 reali (9 minuti di gioco per minuto reale).

| Blocco | Notte 1 | Notte 20 |
|---|---|---|
| Setup (fasi 1-5), una volta a notte | 130 | 19 |
| Ciclo foto (fasi 6-10 + stacking + vendita), ripetibile | 150 | 88 |

**Cosa producono.** Notte 1: setup + 2 foto = 430 min; restano 110, più gli 80 delle pose →
**21 minuti reali liberi su 60**. Notte 20: setup + 3 foto = 283 min; restano 257, più i 120
delle pose → **42 minuti reali su 60**. L'automazione raddoppia il tempo libero.

---

### D-015 — L'automazione compra tempo pagando in qualità

**Regola generale, estesa a tutte le fasi** a partire da un caso singolo di `economia.md §3`
(«auto-allineamento sw: skip parziale, qualità fissa al 70%»).

Ogni upgrade che automatizza una fase **fissa il punteggio di quella fase a un valore
garantito ma non ottimo**. Chi quella fase la sa fare bene ottiene di più a mano.

**Perché conta.** È il contrappeso di D-006: automatizzare tutto massimizza il tempo e
abbassa il valore di ogni singola foto. La scelta resta al giocatore, ogni notte, e nessuna
delle due strade è quella «giusta».

**Da confermare:** la regola è stata generalizzata in sessione, non è scritta così in
nessun documento sorgente. Se una fase non deve seguirla, va detto.

---

### D-016 — La posa è insieme il costo e il tempo libero

**Non è una decisione presa: è una proprietà emersa facendo i conti**, e viene registrata
perché non vada persa e perché il bilanciamento non la rompa per sbaglio.

Allungare la posa (più frame, più esposizione) **alza il punteggio e allarga la finestra
libera**, ma consuma notte e quindi toglie foto. Posa lunga = qualità e storia; posa corta =
quantità e lire.

È D-006 in miniatura, presa dal giocatore a ogni singola posa. **Da non rompere in
taratura:** qualsiasi calibrazione che renda una delle due strade sempre superiore elimina
la scelta.

---

### D-017 — Scopribilità a tre livelli, e i tasti globali scendono a cinque

**Il problema, che è misurato e non teorico.** Il primo giocatore ha chiesto «non so dove
sia la moka?», «cupola cosa vuol dire?», «BBS?». Due delle quattro attività stavano dietro
tasti che il gioco non nomina da nessuna parte.

**Scelta di Federico: tre meccanismi sovrapposti.** Scartato invece l'elenco delle azioni
disponibili.

1. **Prompt contestuali sugli oggetti** — l'unico che *garantisce* la scoperta. Compaiono
   solo su oggetto inquadrato e a portata; **si spengono dopo che l'oggetto è stato usato
   un paio di volte**, così alla notte 20 la stanza è pulita. Sono l'unico elemento non
   diegetico del gioco: deroga consapevole, perché costa meno di un giocatore che non trova
   metà del contenuto.
2. **Il foglio di procedura appeso al monitor** — insegna la *sequenza* delle dieci fasi,
   che i prompt non possono spiegare. Diegetico e storicamente esatto. Seconda vita: è un
   oggetto che invecchia, con annotazioni a penna — canale narrativo già in posizione.
3. **I biglietti della prima notte** — introducono una cosa alla volta e insegnano i cinque
   tasti globali, incluso `Q` dell'orologio, che nessun prompt potrebbe annunciare perché
   l'orologio non è un oggetto da avvicinare. Sono anche la prima voce umana del gioco.

**Conseguenza sui controlli: `T` e `B` spariscono come tasti globali.** Terminale e BBS
diventano **programmi del PC**: ci si avvicina, `E`, e si sceglie fra software di controllo,
negozio online e BBS. Più scopribile e più vero — nel 1999 si aprivano programmi diversi
sullo stesso computer.

**I tasti globali sono cinque:** `WASD` muoversi, `Shift` correre, `E` interagire, `Q`
orologio, `Esc` menù. Tutto il resto è un oggetto nel mondo.

---

## Sessione 4 — Progressione ed economia

### D-018 — Comfort e cura non danno mai bonus meccanici

**La contraddizione trovata.** `economia.md §5` assegna effetti numerici agli oggetti di
comfort — moka +5% sulla fase 7, coperta pesante +5% su tutta la notte sotto i 10°, stufetta
che «sblocca una fase in più senza fatica». Il GDD aveva appena scritto l'opposto, ereditando
la regola dichiarata dell'epica 3.

**Decisione di Federico: nessun bonus meccanico.** Moka, stufetta, mangiacassette, coperta,
lampada riparata, cupola lubrificata e ridipintura cambiano solo come il posto si vede, si
sente e si abita.

**Perché.** Un caffè che conviene farsi smette di essere un caffè e diventa un compito. Il
pilastro 2 esiste per misurare se al giocatore piace stare lì, e un bonus renderebbe la
misura impossibile — si misurerebbe l'obbedienza invece del piacere.

**Conseguenza:** `economia.md §5` è superato e va corretto (aggiunto alla tabella di
manutenzione).

---

### D-019 — Prezzi e guadagni moltiplicati per dieci

**Il conflitto sciolto con l'aritmetica.** Due tabelle di prezzi divergenti di 7-14×:

| | Totale albero | Guadagno in 20 notti |
|---|---|---|
| `economia.md §3` | 228.000 lire | 140.000 giocando in modo ordinario, 280.000 giocando bene |
| `minigiochi.md` | 1.460.000 lire | *idem* |

`economia.md` vince numeri alla mano: con quei prezzi si compra il 60-100% dell'albero in
venti notti, quindi **si deve scegliere**. Con l'altra tabella non si compra quasi nulla e
il pilastro 4 non si accende mai.

**Decisione: rapporti di `economia.md`, valori assoluti ×10.**

- Payout: 5.000 / 15.000 / 35.000 / 70.000 / 150.000 lire
- Albero upgrade: da 50.000 (maschera di Bahtinov) a 600.000 (camera CCD raffreddata),
  **totale 2.280.000**
- Guadagno su venti notti: ~1.400.000 ordinario, ~2.800.000 giocando bene

**Perché.** Il bilanciamento non cambia — è lo stesso rapporto — ma le cifre diventano
credibili per il 1999 su **entrambi** i lati: una rivista che paga 150.000 lire uno scatto da
copertina è plausibile, e una CCD a 600.000 lire è molto meno assurda che a 60.000. Resta
sotto il reale (una SBIG raffreddata costava 3-5 milioni), ma l'irrealismo è ora una
sfumatura invece di un salto.

**Conseguenza di produzione:** i valori nel prototipo (`core/tuning_profile.gd`, i `.tres`
del catalogo, moka a 8.000 e lampadina a 2.000) vanno moltiplicati per dieci.

---

### D-020 — Tutto è visitabile da subito: si scaglona il contenuto, non lo spazio

**Decisione di Federico**, che sostituisce lo scaglionamento spaziale proposto in sessione.

**Nessuna stanza si sblocca col passare delle notti, e i dintorni si percorrono dalla notte
1.** Unica eccezione, fisica e non narrativa: la stanza dietro la pannellatura, che si apre
pagando per smontarla come una qualsiasi cura dell'osservatorio.

**Quello che si scaglona è cosa ci trovi dentro**, allineato alle quattro fasi di
`idea.md §9`: niente nelle notti 1-5; cose piccole nei dintorni e artefatti nelle foto dalla
6; log e cartelle che cambiano dalla 11; metanarrazione attiva dalla 16.

**Perché è la versione migliore.** L'emozione dichiarata nella Vision è una *familiarità
sbagliata*, e la familiarità non si sblocca: si costruisce camminandoci. Un bosco che si apre
alla notte 11 è un posto nuovo dove trovare cose strane; un bosco percorso venti volte in cui
alla dodicesima c'è un'impronta è tutt'altra cosa.

---

### D-021 — La notte finisce andando alla macchina, non andando a letto

**Decisione di Federico:** «per far finire la giornata uno deve andare in macchina e
tornare, non andare a letto».

**Cosa stabilisce.** Il protagonista **non abita** l'osservatorio: è il gestore notturno,
arriva in macchina alle 21:00 e all'alba torna a casa. Chiudere il turno è un gesto fisico —
attraversare l'osservatorio, uscire, raggiungere l'auto — non una voce di menù.

**Le due conseguenze, scritte nel GDD come lettura coerente della decisione:**

1. **L'alba non caccia nessuno.** Alle 06:00 il cielo si schiarisce e non c'è più lavoro
   possibile, ma nessuno spinge fuori il giocatore, che può restare a guardare quanto vuole.
2. **Si può andare via quando si vuole**, anche a mezzanotte, senza che accada nulla. È il
   pilastro 2 applicato alla fine della sessione.

**Perché è meglio del letto.** Dice qualcosa sul personaggio senza raccontarlo: quel posto
diventa tuo pur non essendo casa tua — il che rende più strano, non meno, il momento in cui
si scopre che qualcun altro lo stava imparando insieme a te.

**Conseguenze su cose già scritte, già allineate nel GDD:** il ciclo 1 del core loop non
finisce più con «l'alba chiude la notte da sola», e la sezione vittoria/sconfitta non dice
più che una notte vuota «finisce comunque all'alba».

**Conseguenza sul prototipo:** il letto che oggi fa passare la notte perde quel ruolo.

---

### Manutenzione dei documenti sorgente — aggiornamento

| File | Cosa correggere | Origine |
|---|---|---|
| `economia.md §5` | Gli effetti meccanici del comfort (moka +5%, coperta +5%, stufetta) sono superati | D-018 |
| `economia.md §3` | I prezzi valgono come rapporto, moltiplicati ×10 in valore assoluto | D-019 |
| `minigiochi.md` | La tabella upgrade in fondo è superata da `economia.md §3` ×10 | D-019 |
| `idea.md §9` | La progressione resta valida, ma non implica sblocco di spazi: tutto è visitabile da subito | D-020 |
| `core/tuning_profile.gd` e `.tres` del catalogo | Payout e prezzi da moltiplicare ×10 | D-019 |

---

## Sessione 5 — Level design dell'osservatorio

Aperta su richiesta di Federico («rivedere l'architettura dell'osservatorio»), con due
disegni forniti in sessione: mappa dall'alto del recinto e prospetto frontale.

**Stato trovato.** L'osservatorio è costruito con `BoxMesh` a mano, stanze come scene Godot
separate (`computer_room` 37 nodi, `dome` 44, `kitchen` 22, `exterior` 247) composte per
coordinate in `observatory.tscn`. Ingombro reale: **12,2 × 8,4 m** — 102 m² per otto
ambienti. La sovrapposizione già pagata si legge nei numeri: la cucina occupa X 1,5→3,1
mentre la stanza computer occupa X −2,1→2,1, in due file che non si sono mai guardati.

---

### D-022 — L'edificio è 34 × 24 m, a L, ~650 m² coperti

> **SUPERATA da D-028** (sessione 6): descrive un edificio che non esiste.
> La pianta reale fornita da Federico l'ha sostituita. Conservata per la traccia del ragionamento.

Scelta di Federico fra tre scale proposte con le conseguenze in secondi di camminata.
Triplica l'ingombro attuale.

**Criterio di dimensionamento dichiarato:** *nessun percorso ricorrente supera i 10 secondi
di sola andata* (passo 2,5 m/s). Monitor → telescopio 4 s; monitor → cucina 9 s. Se in
produzione una stanza sfonda quella soglia, l'errore è la pianta.

**Il dato controintuitivo che governa la sezione:** una camminata di 40 m costa 16 secondi
reali ma solo 2,4 minuti di gioco su 540. **Le distanze non si pagano nel budget della
notte, si pagano nella pazienza del giocatore**, moltiplicate per quante volte quel percorso
si ripete. Tre caffè per notte per venti notti = ~18 minuti reali di sola camminata.

---

### D-023 — L'ala est: sala divulgazione più archivio, divisi da una vetrata

> **SUPERATA da D-029** (sessione 6): descrive un edificio che non esiste.
> La pianta reale fornita da Federico l'ha sostituita. Conservata per la traccia del ragionamento.

Il grande volume mai etichettato nelle piante originali diventa **sala divulgazione (56 m²)
con l'archivio in fondo (40 m²)**.

- La sala è pronta e mai usata: sedie accatastate, un proiettore ancora imballato. Un posto
  costruito per un pubblico che non è mai arrivato.
- L'archivio dà **una casa fisica ai log di chi ci sarebbe stato prima**, che è il materiale
  centrale della metanarrazione e finora non stava da nessuna parte.
- Ci si va apposta, non ci si capita.

---

### D-024 — L'auto si ferma dentro il recinto, appena oltre il cancello

**Corretto rispetto alla scelta iniziale** («piazzola fuori dal cancello»): il disegno
dall'alto fornito da Federico mostra l'auto **dentro il perimetro**, nell'angolo sud-est dove
arriva la sterrata. Vale il disegno.

La sostanza non cambia: la piazzola è all'estremità del prato opposta all'edificio, **~40
metri dall'ingresso**. Arrivare e andarsene restano una traversata del prato al buio,
ripetuta quaranta volte in venti notti. Il cancello si apre dalla macchina all'arrivo — e che
una notte lo si trovi già aperto è una possibilità che la disposizione lascia in mano al
pilastro 3 senza costare nulla.

---

### D-025 — Porta diretta fra stanza computer e sala del telescopio

> **SUPERATA da D-045**: la porta non c'è più. Il conto sul percorso più battuto
> resta valido, la conclusione no — quel percorso si fa con gli occhi.

**Difetto trovato nelle piante originali.** `idea.md §3.1` dice che le due stanze sono
adiacenti *«perché chi osserva deve essere a un passo dall'oculare»*, ma nel disegno la
stanza computer si apre **solo sul corridoio**: per raggiungere il telescopio si doveva
uscire, girare e rientrare.

Era **il percorso più battuto del gioco** — decine di volte per notte, per venti notti — e il
giro lungo lo raddoppiava. Corretto: porta diretta. Non richiedeva una decisione, solo di
essersene accorti.

---

### D-026 — Il contatore della corrente, all'esterno

**Elemento nuovo**, comparso nei disegni di Federico e assente da ogni documento. In
facciata, lato sud, accanto al corpo della cupola.

**Perché è più di un dettaglio d'arredo.** Governa tutta l'elettricità dell'osservatorio: PC,
monitor, montatura motorizzata, luci. Nel 1999 un contatore che scatta si riarma a mano — **e
per farlo bisogna uscire al buio.** Si aggancia direttamente alla fase 4 (accensione e
collegamento PC), e regala al pilastro 3 un canale che non richiede di inventare niente: la
corrente che va via mentre una posa è in corso è la cosa più banale e più credibile del
mondo.

**Registrati insieme a lui, dagli stessi disegni:** la **rampa d'accesso disabili** davanti
alla porta (edificio pubblico a norma che nessuno ha mai visitato — dice l'isolamento senza
raccontarlo, e costa un asset) e la **fenditura della cupola**, che si apre mentre la cupola
ruota.

---

### D-027 — Le quote verticali sono dichiarate

> **SUPERATA da D-030** (sessione 6): descrive un edificio che non esiste.
> La pianta reale fornita da Federico l'ha sostituita. Conservata per la traccia del ragionamento.

Federico ha fornito il prospetto dichiarando di non avere le altezze precise. **Proposte dal
GDD e vincolanti finché non corrette**, perché il tetto complanare al soffitto già pagato
nasce esattamente dall'assenza di quote verticali scritte.

Soffitto interno 3,0 m · gronda 4,0 m · cupola ø 10 m con base a 4,0 e **colmo a 9,0** ·
sala del telescopio alta 9,0 al colmo, dove la cupola *è* il soffitto · fenditura larga 1,6 m
· porta 2,1 m · finestre davanzale 1,0 e altezza 1,4 · rampa con dislivello 0,3 m all'8%.

**Regola scritta perché non si ripeta in Blender:** la cupola **poggia** sulla quota di
gronda e non ci affonda dentro; il tetto piano del corpo si interrompe sul perimetro
dell'anello.

---

## Sessione 6 — La pianta vera, e il blockout che la verifica

Aperta perché Federico non si fidava della planimetria generata («vorrei vedere come ha
fatto sta planimetria, non mi fido») e aveva ragione: **era inventata**. Ha fornito il
disegno della pianta reale, e da lì è ripartito tutto.

### D-028 — Vale il disegno di Federico: l'edificio è 19 × 9,5 m, ~164 m² coperti (**supera D-022**)

La pianta di D-022 — 34 × 24 m, ~650 m², con un'ala sud — **non è mai esistita**: era una
proposta del GDD scambiata per un rilievo. Sostituita dal disegno fornito in sessione, poi
**dimezzata in pianta** su richiesta di Federico dopo aver camminato dentro il blockout
(«le stanze vanno bene ma è TROPPO grande, dimezza tutte le dimensioni»).

L'ingombro finale è **19 × 9,5 m**, ~164 m² coperti, ~150 calpestabili. Il criterio di
dimensionamento di D-022 resta valido e ora ha margine: nessun percorso ricorrente supera i
10 secondi, il più lungo interno ne costa 4.

**Il metodo che ha reso possibile la correzione, ed è la cosa da tenere.** La scala non è
stata decisa a tavolino ma **entrandoci a piedi**: la pianta genera un blockout Godot
navigabile, e il giudizio è stato dato camminando. Una pianta si guarda dall'alto, un
edificio si attraversa — e l'errore di scala era invisibile dall'alto.

### D-029 — L'archivio non c'è: al suo posto libreria e cucina (**supera D-023**)

D-023 assegnava all'ala est *sala divulgazione + archivio*. Nel disegno reale l'archivio non
esiste: c'è la **cucina** (dietro la libreria, come precisato da Federico) e la **libreria di
astronomia** addossata al muro della sala.

**Resta aperto il problema che D-023 risolveva:** i log di chi c'era prima — materiale
centrale della metanarrazione — non hanno più una casa fisica. Candidati naturali: il
magazzino, le due stanze segrete, o la libreria stessa. **Va deciso, non dimenticato.**

### D-030 — Le quote: gronda 3,00, cupola ø 5,00, colmo 5,50 (**supera D-027**)

D-027 proponeva gronda 4,0 e cupola ø 10 con colmo a 9,0 — quote coerenti con l'edificio da
34 × 24 che non esiste. Alla scala vera diventano: **soffitto e gronda 3,00 · cupola ø 5,00
poggiata sulla gronda · colmo 5,50 · fenditura 1,60**.

**La regola di D-027 sulla cupola che poggia e non affonda è confermata, e ha già chiesto
due correzioni in codice.** La seconda è istruttiva: una calotta di 5 m copre 20 m² di una
sala che ne misura 34, e la sala è rimasta **aperta al cielo per 14 m²** finché non è
esistito un tetto piano forato attorno al cerchio. Da dentro non si vedeva; da fuori era una
lastra grigia lunga tutto l'edificio.

### D-031 — Due famiglie di misure: architettoniche e antropometriche

**La regola nata da un errore.** Dimezzando l'edificio ho dimezzato anche le porte,
riducendole a 70 cm. Le due famiglie si comportano in modo opposto e non vanno mai scalate
insieme:

| Famiglia | Cosa comprende | Comportamento |
|---|---|---|
| **Architettoniche** | lunghezze, larghezze, superfici, distanze | scelta di design, si scalano in blocco |
| **Antropometriche** | porte, soffitti, davanzali, gradini, l'auto, il passo | fissate dal corpo umano, **non si scalano mai** |

Il giocatore è alto 1,80 m a qualunque scala stia l'edificio. Confondere le due produce un
modellino invece di un luogo.

### D-032 — La geometria si verifica da sola, non a occhio

**Decisione di metodo, presa dopo tre difetti trovati dal giocatore e non dall'autore.**
Il generatore della pianta ora controlla da sé, a ogni rigenerazione:

- **le aperture** — ogni porta e finestra deve entrare in un muro, lasciare almeno 30 cm di
  montante sui due bordi e altrettanti dall'apertura vicina;
- **la copertura** — ogni metro quadro di pavimento deve avere sopra un soffitto o la calotta;
- **gli ingombri** — nessun blocco interno può sporgere dalla sagoma dell'edificio.

Le verifiche hanno trovato difetti che l'occhio non vedeva: una **vetrata interna scartata
in silenzio** dal generatore perché non entrava più nel muro accorciato (sarebbe
semplicemente sparita dal gioco), un montante da 15 cm, e i 14 m² di sala scoperta di D-030.

**Il caso che ha dettato la terza verifica.** Il pilastro del telescopio era l'unico nodo
scritto a mano invece che generato, e prendeva la sua mesh con `idx[dims[0]]` — "la prima
dimensione della lista", che è ordinata per larghezza. Si prendeva quindi il blocco più
sottile esistente, cioè **il recinto: 0,15 × 1,40 × 30 metri**, piantato al centro della
cupola e sporgente dai due lati dell'edificio. Due lezioni, entrambe generali:

- **il caso speciale scritto a mano è il posto dove si annidano i difetti** — il pilastro era
  l'unico oggetto fuori dalla pipeline, ed era l'unico rotto. Ora passa dal generatore come
  tutti gli altri, e la classe di difetto non esiste più;
- **un indice implicito è un'ipotesi non dichiarata**: `dims[0]` significava "una mesh
  piccola qualsiasi", e ha smesso di essere vero senza che nulla protestasse.

**Il criterio generale:** un generatore che scarta in silenzio ciò che non gli torna produce
difetti invisibili per costruzione. Ogni scarto va dichiarato. Vale per la geometria e vale
per il resto della pipeline.

### D-033 — Il corridoio è profondo 2,10 m, non 1,50

Federico ha segnalato **due volte** un montante ridicolo di fianco alla porta del corridoio,
e le prime due volte ho spostato la porta. **Non era la posizione, era la stanza:** un
corridoio profondo 1,50 m con una porta da 1,40 lascia sette centimetri di muro per lato,
ovunque la si metta.

Corridoio portato a **2,10 m**, controllo PC da 15 a 12 m² netti. **Quando un elemento non
sta da nessuna parte, il difetto è la stanza, non l'elemento.**

### D-034 — Il varco fra corridoio e sala del telescopio non ha porta

L'anello di lavoro (sala telescopio → controllo PC → corridoio → sala telescopio) si chiude
su un **varco senza infisso**: il giro si percorre senza aprire niente. Rende l'anello un
anello davvero, invece di tre stanze con una scorciatoia da aprire.

### [NOTE FOR DESIGNER] — le due stanze segrete alla scala vera

Il dimezzamento le ha ridotte a: **ovest 1,8 m² su 60 cm di larghezza** — non una stanza, uno
spessore di muro in cui non ci si gira — e **est 1,00 × 3,00 m**, al limite ma leggibile come
ripostiglio dimenticato. La ovest **va allargata a mano** ad almeno 1,20 m di luce, rubando
spazio al magazzino o al disimpegno: è un ambiente il cui senso non sopravvive alla scala.

### D-035 — Le coperture in ordine costruttivo, e la cupola sale a 3,38

**Due difetti trovati guardando il modello in assonometria, invisibili in pianta e da
dentro il blockout.**

- **I due tetti non erano complanari**: quello della sala del telescopio stava a 3,00-3,18 e
  gli altri a 3,23-3,41, con 23 cm di scalino in mezzo alla copertura.
- **La cupola affondava nel tetto.** Poggiava a 3,00, la quota di gronda — corretta finché la
  sala del telescopio era scoperta. Dandole un tetto (D-030) il piano d'appoggio si è alzato
  a 3,38 e **nessuno ha alzato la cupola**, che è rimasta 38 cm dentro la copertura.

Ordine costruttivo ora dichiarato e unico: **muri fino a 3,00 · solaio 3,00-3,20 · tetto
3,20-3,38 · cupola appoggiata a 3,38**, colmo a **5,88** (era 5,50 in D-030).

**La lezione, che è la stessa di D-032 vista da un'altra angolazione:** una quota derivata da
un'altra va *calcolata*, non copiata. `H_DOME_BASE` era il numero 3,00 scritto a mano; ora è
`H_TETTO + SP_TETTO`, e cambiare il tetto muove la cupola da sola.

### D-036 — Blender legge dalla fonte unica, non ridisegna

Il modello dell'osservatorio **non è disegnato a mano**: `osservatorio_blender.py` chiama
`blocchi_edificio()` di `geometria.py`, la stessa funzione che genera il blockout Godot. La
logica che traduce muri e aperture in volumi è stata spostata nella fonte proprio perché
vivesse in un posto solo.

Blender è quindi il **terzo consumatore** della stessa geometria, accanto alla pianta
disegnata e al blockout navigabile. Cambiare la pianta li aggiorna tutti e tre; nessuno dei
tre può divergere dagli altri.

Restano di competenza di Blender le cose che da una pianta non si derivano: la cupola con la
fenditura e i portelli, la passerella, il telescopio, gli arredi.

### D-037 — La segreta ovest sale a 1,20 m di luce, e la porta del magazzino scende a 90 cm

La [NOTE FOR DESIGNER] aperta in sessione 6 è chiusa. La stanza passa da **60 cm a 1,20 m
di luce netta** (da 1,8 a 3,4 m²), prendendo **30 cm al disimpegno e 25 al magazzino**: da un
lato solo non si poteva, perché ciascuna delle due stanze deve restare abbastanza larga da
ospitare la propria porta con i montanti a norma.

Il magazzino, sceso a 1,55 m, **non regge più una porta da 1,30**: è passato a **90 cm**, che
per un ripostiglio è la misura giusta e che con 1,30 non era mai stata.

### D-038 — I montanti si misurano sulle stanze, non sui muri

**Lacuna trovata nella verifica, non nel disegno.** `verifica_aperture` misurava i montanti
sugli estremi del muro fisico. Ma il muro sud dell'ala ovest è **un unico segmento di 8
metri** attraversato da tre tramezzi: una porta poteva avere due metri di muro davanti e
venti centimetri dal tramezzo, e la verifica non se ne accorgeva.

Ora i montanti si misurano sui **vincoli più vicini** — estremi del muro *e* intersezioni con
i muri perpendicolari. Al primo colpo ha trovato un difetto che era lì da sempre: la **porta
del magazzino a 20 cm dal tramezzo del bagno**, chiusa insieme a D-037.

**Il criterio generale:** una verifica che misura sull'oggetto sbagliato dà sempre esito
positivo, e la sua approvazione vale zero. La domanda giusta non è «il muro è abbastanza
lungo» ma «lo spazio in cui questa cosa deve stare è abbastanza largo».

### D-039 — Le porte si aprono, e il verso è un dato dichiarato

Ogni porta ha ora **cardine e verso di apertura** scritti in `geometria.py`, non lasciati al
modellatore. L'**ingresso si apre verso il prato**: è un edificio pubblico e una via di fuga
non può aprirsi verso l'interno — la stessa norma che ha già messo lì la rampa d'accesso.
Le interne si aprono verso il locale servito, tranne dove il locale è troppo stretto per
contenere l'anta: il corridoio (2,10 m) e il magazzino (1,55 m) le respingono verso fuori.

**Oltre 1,60 m di luce la porta diventa a due ante.** L'ingresso ne ha due da 1,02: un
battente da due metri non esiste, e il GDD dichiarava «due ante» da sempre senza che il
modello lo rispettasse.

**Un pezzo che ruota si modella dal perno.** Le ante non sono volumi centrati come il resto
dell'edificio: hanno l'origine **sul cardine**, esattamente come i portelli della cupola.
Con l'origine al centro, aprire la porta la stacca dal telaio.

### D-040 — Un varco non è un muro: la falla in `punto_libero`

La verifica nuova — *l'anta spalancata non deve sbattere* — al primo giro ha **bocciato sette
porte su otto**, tutte «ferme a 8 gradi». Un esito troppo sistematico per essere vero.

La causa non era nel disegno ma nel controllo: `punto_libero` trattava come muro **anche la
luce delle aperture**. Nei primi gradi di rotazione l'anta è ancora dentro il proprio vano,
quindi ogni porta risultava bloccata dal buco in cui è montata.

**E il primo tentativo di verifica era anche troppo debole:** campionava due soli punti
dell'arco, e una porta poteva passare libera a metà corsa per trovare il tramezzo poco più
avanti. Ora spazza tredici angoli su due raggi.

**Provata contro un caso impossibile** — una porta da 2 m che si apre dentro un magazzino
largo 1,55 — la verifica la ferma a 38 gradi. Un controllo che non è stato visto fallire non
si sa se funziona: è il seguito naturale di D-038.

### D-041 — L'ingresso è a un'anta sola, con maniglione antipanico (**supera parte di D-039**)

Scelta di Federico. La porta a due ante di D-039 diventa **un battente unico**, e la luce
scende da 2,20 a **1,20 m**: un'anta da 2,04 non esiste, mentre 1,20 è la misura di una porta
antipanico a un battente — la stessa che la norma chiede per un'uscita di sicurezza fino a
120 persone. La regola «oltre 1,60 servono due ante» resta scritta nel codice come vincolo,
ma ora nessuna porta la supera.

**Il maniglione sta sul lato interno**, a 1,05 m, su due supporti. Non è un dettaglio
d'arredo: è la controparte fisica di D-039, dove l'apertura verso il prato era stata decisa
perché una via di fuga non si apre verso l'interno. Si spinge da dentro, e si esce.

**Come è modellato:** barra e supporti stanno nel **sistema locale dell'anta**, non in
coordinate del mondo. Ruotano quindi con la porta senza un solo calcolo aggiuntivo — che è
poi il motivo per cui l'anta è imperniata sul cardine.

### D-042 — Il foro della cupola è tondo nel modello, a strisce nel blockout

Il tetto della sala del telescopio nasce da `blocchi_edificio()` come **21 strisce da 25 cm**
che approssimano il cerchio: nel blockout Godot va bene — è fatto di scatole per definizione
— ma nel modello il bordo del foro si vede a gradini.

In Blender la lastra è quindi **una sola, con il foro tagliato da una booleana**. Ed è il caso
in cui la booleana è lo strumento giusto: la fenditura della cupola, che sta su due piani
verticali, si taglia meglio con `bisect` (D-036), mentre un cerchio in una lastra no.

**Una booleana può fallire senza dire niente**, quindi il foro si misura invece di darlo per
fatto: lo script conta i vertici che cadono sul cerchio di raggio 2,50 e si ferma se sono
meno di sessanta. Ne trova 192.

**Il principio, di nuovo:** i due consumatori della stessa geometria non devono per forza
ricevere la stessa mesh. Il blockout vuole scatole che si generano in un millisecondo, il
modello vuole un bordo pulito. La *pianta* resta unica, la sua traduzione in volumi no.

### D-043 — Le porte si aprono con `E`, sul contratto che esiste già

Le otto porte del blockout sono ora `Interactable` ([`world/interactables/door.gd`](../../../../world/interactables/door.gd)),
la stessa classe base di moka, lampada e monitor CRT. **Nessun secondo meccanismo per lo
stesso gesto:** stesso raggio dalla camera — che distingue «la guardo» da «ci sono accanto»
— stesso prompt italiano, stesso tasto. Il prompt cambia con lo stato, `Apri` / `Chiudi`,
perché il player rilegge il testo a ogni sguardo.

**Il verso di apertura non è riscritto nella scena:** il generatore lo calcola dalla stessa
`APERTURA_PORTE` di `geometria.py` che governa pianta e modello Blender. L'ingresso si apre
verso il prato in gioco senza che nessuno l'abbia dichiarato una seconda volta.

**Il nodo sta sul cardine** — terza applicazione della stessa regola dopo i portelli della
cupola (D-036) e le ante del modello (D-039). Mesh e collisione sono spostate di mezza anta
lungo `+X` locale; aprire è ruotare il nodo attorno a `Y`.

**Un limite dichiarato, non nascosto.** `Interactable` estende `StaticBody3D`, che non spinge
un `CharacterBody3D` fermo nel vano: chi sta sulla soglia mentre la porta si chiude può
restare incastrato. Nel blockout è accettabile; la risposta in produzione è un
`AnimatableBody3D` a parte, **non** un secondo contratto di interazione.

### D-044 — La sala del telescopio è modellata sulle foto dell'osservatorio reale

Federico ha fornito tre foto dell'osservatorio. Da quelle, e non da un'idea generica di
telescopio, vengono: la **fenditura che si allarga salendo** (1,60 alla base, 2,40 allo
zenit — non ha i lati paralleli), l'**ossatura interna** con sedici costoloni radiali, due
anelli orizzontali e i tiranti incrociati, il **telescopio a forcella** con cella del
primario, due tubi guida affiancati e focheggiatore, e la **passerella con parapetto
tubolare a due correnti** e scala a gradini.

**La gerarchia del telescopio è il pezzo che conta di più**, e non si vede:
`AssePolare → AsseDec → Tubo`, con l'asse polare inclinato di 46 gradi, cioè 90 meno la
latitudine di Montegrimano. Con quella catena **inseguire è ruotare un nodo solo a velocità
costante**; con un asse verticale servirebbero due motori coordinati. È il motivo per cui le
montature equatoriali esistono, ed è già pronto per «il telescopio insegue, non gira».

**La calotta si costruisce, non si taglia.** Il primo tentativo la bucava con una booleana e
ha cancellato l'intera mesh. Ora la superficie si **genera già con il bordo sulla sagoma**,
punto per punto: tagliare una sfera fatta lascia il bordo dove capitano i suoi meridiani, e
su una luce che cambia larghezza il gradino si vedrebbe — proprio sul bordo che il giocatore
ha davanti dalla passerella.

**Il parapetto si interrompe dove arriva la scala.** Non è grafica: una ringhiera continua
chiuderebbe l'unico accesso alla passerella.

**La mesh a gradini, la collisione a rampa.** La scala ha cinque alzate vere nel modello e
resta un piano inclinato per la fisica: si vede una scala e si cammina su una rampa (D-033).

### D-045 — Fra controllo PC e sala del telescopio si guarda, non si passa (**supera D-025**)

**Decisione di Federico.** La porta diretta sparisce. Il muro resta — regge il solaio e
separa una stanza riscaldata da una sala che d'inverno sta alla temperatura di fuori — ma
l'unica apertura è **una vetrata sola, larga 2,80 m**, centrata sul telescopio.

D-025 aveva aperto quella porta per accorciare *«il percorso più battuto del gioco»*. Il
conto era giusto e la conclusione no: quello che si fa decine di volte per notte non è
**andare** al telescopio, è **guardarlo**. Per guardarlo la porta non serve, e averla
significava tenere due collegamenti fra due stanze che si toccano, quando il corridoio ne
fa già uno.

**Quello che questo costa, detto per intero.** La sala del telescopio aveva due accessi e
ora ne ha uno: il varco sul corridoio (D-034). L'anello di D-023bis (*«la zona di lavoro è
un anello, non un ramo»*) non esiste più — la sala del telescopio è un fondo cieco, e chi
sale sulla passerella dà le spalle all'unica via d'uscita invece che a una di due. Non è
detto sia un peggioramento per un gioco che vuole mettere a disagio, ma **è un cambiamento
di pilastro 3, non un dettaglio di pianta**, e il GDD è stato riscritto di conseguenza
invece di lasciare in piedi la frase vecchia.

---

### D-046 — Il vetro è una lastra dentro un telaio, non un pieno di vetro

**Difetto visto da Federico:** *«è come se tutto l'infisso fosse fatto in vetro»*. Era
esatto: il pezzo `Vetro` riempiva tutto lo spessore del muro (0,22 m), quindi ogni finestra
era un parallelepipedo di vetro alto quanto il vano.

Ora la lastra è spessa **16 mm** e sta **al centro** del telaio, che continua a occupare
tutto lo spessore. E oltre **1,10 m di luce** il serramento si divide in campate con i
montanti intermedi: la vetrata da 2,80 ne ha tre. Non è decorazione — è quello che fa
leggere un infisso come un infisso invece che come un buco nel muro.

Le quote della vetrata interna sono sue e non quelle delle finestre: **davanzale 0,90,
sommità 2,60** invece di 1,00 / 2,40. Sotto ci passa la consolle (0,75), sopra restano
40 cm di architrave.

---

### D-047 — L'arredo nasce dall'impronta, e cinque controlli dicono se è abitabile

`geometria.ARREDI_PC` elenca **i rettangoli in pianta** di ogni mobile della sala di
controllo, con la sua altezza. Da quella lista escono due cose che devono coincidere: le
scatole di collisione del blockout e i volumi dentro cui il modellatore Blender può
costruire. Un controllo conta i vertici fuori dall'impronta, quindi **non si può disegnare
un monitor più grande di quello contro cui si sbatte**.

I controlli su una stanza arredata sono cinque, e sono i cinque modi in cui un arredo la
rovina: sta dentro un muro, compenetra un altro mobile, finisce sotto un'anta che si apre,
**tappa un vetro** (davanti a una finestra ci può stare solo roba più bassa del davanzale),
oppure isola un pezzo di pavimento — misurato erodendo lo spazio libero del raggio del
giocatore, 0,30 m, e verificando che quel che resta sia tutto collegato.

Tutti e cinque sono stati provati contro casi impossibili costruiti apposta, e due hanno
trovato difetti veri alla prima disposizione: il rack compenetrava il mobile per 5 cm e
tappava l'angolo della finestra nord. **Un controllo che non ha mai fallito non è un
controllo** (D-032).

---

### D-048 — La cucina è in linea, perché la stanza è un corridoio

**Misura, non gusto.** La cucina è **4,95 × 2,40 m**: quasi cinque metri per due e
quaranta. Con i mobili su un lato (0,60 di profondità) restano **1,80 m** di passaggio, e
un tavolo al centro con le sedie intorno ne mangerebbe 1,50 lasciando 15 cm per lato.
Quindi: tutto su un lato — basi, lavello, cottura, frigo, dispensa — e il tavolino spinto
nell'angolo sud-est, che è l'unico che la porta d'ingresso non spazza.

**Le sedie stanno ai capi del tavolo, non sul lato lungo.** Messe davanti, fra loro e il
bancone restavano **65 cm**: cinque centimetri sopra il minimo del giocatore, cioè un
passaggio che il controllo accetta e le gambe no. Ai capi, il corridoio nord passa da 0,65
a **1,15 m**. Il controllo aveva già segnalato 0,06 m² di pavimento irraggiungibile — un
sintomo piccolo di una disposizione sbagliata.

**La moka sta sul fuoco, ed è un oggetto di trama.** Il GDD dice che per il caffè si
attraversa lo spazio aperto al pubblico: il caffè è un gesto dichiarato del gioco, e questa
è l'estremità di quel percorso. Il posto dove finisce va mostrato.

**La cucina non ha finestre**, e non è una dimenticanza di modellazione: nessuno dei suoi
quattro muri ne ha una in pianta. Il muro nord è perimetrale e libero, quindi una finestra
sopra il lavello si potrebbe aprire — ma è una modifica alla pianta, e non era quello che
era stato chiesto. **In sospeso, in attesa di Federico.**

---

### D-049 — Le primitive di modellazione stanno in un posto solo

`tools/modellare.py` tiene la conversione fra assi di gioco e assi di Blender —
`(x, y, z) → (x, -z, y)` — le primitive (scatola, cilindro, prisma), i materiali e il banco
di posa per i render.

**Perché non due copie, una per stanza.** Quella conversione è il punto in cui questo
progetto ha già sbagliato più volte: un segno invertito ha mandato una camera dentro un
muro e ha puntato un telescopio dalla parte opposta. Due stanze arredate significavano due
copie della stessa formula, cioè la garanzia di vederle divergere. Ora chi arreda una
stanza non la vede: dichiara i pezzi in **coordinate di gioco**, comprese le camere dei
render, che prima erano le uniche a essere scritte in coordinate di Blender.

La riscrittura della sala di controllo su questo modulo ha prodotto **le stesse identiche
mesh** — stesso conto di facce per ogni materiale. È il modo in cui si verifica che un
riordino non ha cambiato niente.

---

### D-050 — La cucina ha una finestra sopra il lavello (**scioglie il sospeso di D-048**)

**Decisione di Federico**: una cucina senza finestre non è realistica. Aperta sul muro
nord, che è perimetrale e libero: **1,20 m di luce da x 9,10 a 10,30**, esattamente sopra
il lavello, davanzale 1,00 e sommità 2,40 come le altre finestre.

**Ha cambiato i mobili, non solo il muro.** I due pensili coprivano tutta la parete fino
alla cappa, ed erano proprio dove ora c'è il vano: fra la finestra e la cappa restano
38 cm, che non sono un pensile. Ne è rimasto uno solo, a giorno, a ovest della finestra —
e il paraschizzi si interrompe sotto il vano invece di attraversarlo.

---

### D-051 — Il controllo sulle impronte è cieco a quello che sta in alto, e serviva un secondo controllo

**Difetto trovato in un controllo, non nel modello.** «Non tappare un vetro» era verificato
sulle **impronte**, che dichiarano l'altezza di collisione. Ma la mesh può crescere sopra
l'impronta quanto vuole: il bancone della cucina è alto 0,90 e i suoi pensili arrivano a
2,10. Per quel controllo la finestra era libera.

`modellare.verifica_luce` la misura sulle **mesh**, e misurarla ha richiesto due tentativi:

1. **Contando i vertici** dentro il vano. Sbagliato, e in modo istruttivo: *una tavola che
   attraversa tutta la finestra non ha nemmeno un vertice lì dentro* — i suoi vertici stanno
   ai due lati. Messo apposta un pensile sopra il lavello, il controllo lo promuoveva con il
   4%.
2. **Proiettando le facce.** Ogni faccia getta il suo ingombro sulla larghezza del vano.
   Lo stesso pensile ora copre il 100% e viene bocciato.

E si misura **a due quote**: sopra il davanzale finiscono anche il rubinetto e lo
scolapiatti, che davanti a un lavello ci stanno di mestiere. Contandoli, la cucina dava
29% contro una soglia del 30 — un controllo che passava per un centimetro e sarebbe
cambiato al primo piatto spostato. La soglia si applica a 40 cm sopra il davanzale, dove
un pensile c'è e un rubinetto no. Là la cucina dà 4%.

---

### D-052 — Lo spazio divulgazione: i libri davanti, le teche dietro, e il vuoto in mezzo

**Disposizione chiesta da Federico.** La **libreria di astronomia** (già nel GDD) sta sul
muro della cucina, dalla parte della sala, e comincia dopo la porta: 3,00 m, sei ripiani,
pieni. Le **teche di vetro con i meteoriti** stanno in fondo — due addossate al muro est,
due a isola nel volume grande, più la vetrina lunga sul muro sud, che è la *bacheca dei
meteoriti* del GDD.

**La parte più a est è la sala proiezioni**, e questa è una correzione: le sedie le avevo
messe al centro della sala, e Federico ha detto che stanno a destra, con un proiettore. Ha
ragione, e il motivo è che il volume lo diceva già: l'ala est, oltre la stanza segreta, è un
blocco chiuso di **4,15 × 7,80 m** con un solo lato aperto verso il resto della sala. Al
centro erano sedie appoggiate in mezzo a niente; lì sono **una sala dentro la sala**.

Schermo avvolgibile sul **muro nord** — l'unico tratto di parete di quel blocco senza
aperture, perché uno schermo davanti a una finestra è un modo di non poter proiettare mai —
**un tavolo davanti**, **due** file da quattro rivolte allo schermo, e il **proiettore per
diapositive su carrello** dietro l'ultima fila. È un carosello, non un videoproiettore: nel
1999, in una sala così, c'era quello.

**Il tavolo è la ragione delle sedie**, e viene da com'è fatto l'osservatorio vero. Due file
davanti a un muro sono sedie appoggiate; due file davanti a un tavolo sono una sala dove
qualcuno parla. Le file erano tre, e sono diventate due per fargli posto: la terza toglieva
al tavolo lo spazio che gli serve per essere un tavolo.

**Il vuoto è il contenuto.** Sono 65 m² di sala aperta al pubblico in un osservatorio dove
il pubblico non viene: riempirla la smentirebbe. Le sedie sono **apparecchiate**, non
impilate in un angolo — una pila dice «questa stanza non si usa», tre file rivolte a uno
schermo abbassato dicono che qualcuno le ha messe per una serata a cui non è venuto
nessuno. Una sedia per fila è girata di sette gradi.

**Le file sono larghe 2,20 e non 2,60**, e la differenza sono i due corridoi laterali. A
2,60 fra le sedie e la teca est restavano 30 cm, e dietro la teca si apriva un metro e
settanta di pavimento raggiungibile solo strisciando: il controllo l'ha misurato in
**0,48 m² di sacca isolata**, che è il modo in cui una disposizione sbagliata si fa vedere
prima di essere camminata.

**Lo spazio non è un rettangolo**, ed è la prima stanza per cui non lo è: è quel che resta
dell'ala est tolte cucina e segreta, cioè una elle. I controlli ora lavorano sull'**unione**
di più rettangoli. Provati contro il caso che conta — una teca piazzata dentro la cucina,
che sta nel rettangolo circoscritto ma non nella sala — e lo bocciano.

---

### D-053 — L'asse di un'inclinazione va dichiarato, o metà delle sedie sono storte

**Difetto visto da Federico:** *«le sedie hanno tutte lo schienale inclinato, troppo
storto»*. Non era la misura, era l'asse.

`modellare.scatola_inclinata` prometteva nel suo nome una rotazione attorno all'asse X di
gioco e ne faceva una attorno a Z. **Per metà dei suoi usi la differenza non si vede**: una
sedia rivolta lungo X si reclina nel piano X-Y, ed è esattamente quello che quel codice
faceva — le poltroncine della sala di controllo e le sedie della cucina erano giuste per
caso. Per una sedia rivolta lungo **Z** lo stesso codice piega lo schienale **di lato**: è
il caso delle sedie della sala proiezioni, che guardano a nord, ed erano tutte inclinate a
sinistra.

Ora l'asse è un parametro e va detto. Erano sbagliati per lo stesso motivo anche i
cartellini delle teche, che invece di reclinarsi all'indietro stavano storti su un fianco.

**Perché è successo.** Il nome della funzione affermava una cosa che il corpo non faceva, e
nessun controllo guarda gli angoli: i controlli misurano ingombri, passaggi e occlusioni,
cioè quello che si urta e quello che si tappa. Una sedia storta non urta niente. Questa
classe di difetti la vede solo qualcuno che guarda, e finora l'ha vista Federico.

---

### D-054 — Una vetrina si descrive in «lungo e profondo», non in X e Z

**Difetto visto da Federico:** i meteoriti *«rispetto alla bacheca stanno verticale, ma
dovrebbero essere displayati in orizzontale»*.

I reperti si disponevano **sempre lungo l'asse X**, qualunque fosse l'orientamento della
teca. Per la bacheca sul muro sud — lunga 2,60 in X — andava bene per caso. Per le due
vetrine del muro est — lunghe 1,90 in **Z** e profonde 0,60 in **X** — significava
incolonnarli nella *profondità*, uno dietro l'altro: da fuori si vedeva un grumo di sassi
in mezzo a un ripiano vuoto, invece di una fila lungo il vetro.

**È lo stesso errore di D-053, in un altro punto**: un pezzo di codice che assume un
orientamento e funziona per metà dei casi. Là era l'asse di una rotazione, qui è l'asse di
una distribuzione, e in entrambi i casi il caso che funzionava nascondeva quello che no.

La vetrina ora si descrive in coordinate sue — *lungo la teca* e *dal fronte al fondo* — e
una funzione le riporta agli assi di gioco.

**Mappare la posizione non bastava: vanno mappate anche le misure.** Al primo tentativo i
reperti si allineavano bene ma i cartellini no, ed è il difetto dritto dentro la stessa
buca: la posizione passava per la mappa, le dimensioni restavano scritte in X e Z. Un
cartellino largo 8,5 cm **in profondità** invece che lungo la vetrina fa insieme le due
cose che Federico ha visto — stando davanti alla teca lo si guarda **di taglio**, e
coricandosi all'indietro la sua dimensione lunga scende e **entra nel ripiano**. La regola
che lo tiene dritto: la larghezza deve stare sull'asse attorno a cui il pezzo si corica. Ne è venuto fuori che erano girati male anche
il vetro frontale e il pannello dei testi: nelle vetrine est il vetro «davanti» stava su un
fianco, e il pannello che va sul fondo stava **davanti al pubblico**.

**Le teche a isola al centro della sala sono state tolte**, per decisione di Federico.
Restano le due sul muro est e la bacheca sul muro sud. Il centro dello spazio divulgazione
resta vuoto, il che è coerente con quello che quella sala deve dire.

---

### D-055 — Il distributore è fatto per bene, e le due cose che lo rendevano finto

L'impronta sale a **0,78 × 0,85 × 1,83**, che sono le misure di una macchina da snack
vera: a 0,75 × 0,75 era un distributore in scala. Dentro ci stanno la cassa, l'anta con la
vetrina, quattro ripiani con le **spirali** e la merce, la colonna dei comandi (display,
tastiera 4 × 3, fessura monete, fessura banconote, pulsante e vaschetta del resto), lo
sportello di erogazione e l'insegna luminosa.

**Due difetti, e nessuno dei due era dove sembrava.**

1. **La cassa era una scatola piena.** Volevo un guscio e ho scritto un blocco: ripiani,
   spirali e merce erano sepolti dentro il metallo, e da fuori il vetro sembrava una lastra
   grigia opaca. Stavo per andare a cercare il difetto nel materiale del vetro — che invece
   funzionava benissimo, come si vedeva nelle teche. **Non era il vetro a non far vedere:
   era che dietro non c'era niente da vedere.** Ora la cassa è schiena, fianchi, cielo e
   basamento pieno.

2. **Dentro era buio.** Anche a cassa svuotata, un contenitore chiuso senza luce propria
   resta nero dietro un vetro. Un distributore vero è illuminato dentro: c'è un tubo acceso
   sotto il cielo dell'anta. È anche l'unica cosa accesa nella sala divulgazione quando
   tutto il resto è spento, e questo vale più di un dettaglio d'arredo — vedi la nota sulla
   luce rossa in fondo.

**Le spirali sono eliche vere**, segmenti lungo un'elica, non anelli sovrapposti: dietro un
vetro la differenza si nota subito, perché una pila di anelli è una molla schiacciata e non
tiene niente. Da qui `modellare.barra`, un cilindro fra due punti qualsiasi, che stava per
essere riscritto a mano per la terza volta (passerella, telescopio, e ora questo).

**Le corsie non sono piene uguali.** Una mezza vuota dice di più di tre piene.

---

### D-056 — Le UV si generano, e stanno in metri

Le mesh uscivano dall'export con `POSITION` e `NORMAL` e basta: nessuna `TEXCOORD_0`, cioè
nessuna texture poteva appoggiarsi da nessuna parte. `modellare.uv_a_scatola` proietta ogni
faccia sul piano perpendicolare alla sua normale dominante, e la chiamano tutti e sei i
modellatori.

**Non `smart_project`.** Questa geometria è fatta di scatole e cilindri generati di cui
conosco le misure: la proiezione a scatola dà densità di texel **costante e
deterministica**, mentre lo smart project impacchetta a caso e cambia a ogni
rigenerazione — cioè ogni volta che tocco la pianta.

**Le UV sono in metri, e la scala della texture non sta lì**: sta nel materiale, dove
ognuno la vuole diversa (l'intonaco ripete ogni 2 m, il laminato ogni 0,5). Cablata nelle
UV, cambiarla vorrebbe dire rigenerare i modelli.

Il prezzo è una cucitura sugli spigoli e un po' di stiramento sulle facce oblique: per
texture ripetitive e senza disegno non si vede. Per un'etichetta o una scritta servirà una
UV a mano su quel pezzo.

Le texture verranno da **ambientCG** (CC0). Vale la solita cautela del glTF: passano solo
baseColor, metallicRoughness, normal, occlusion ed emissive.

---

### D-057 — La luce ha un apparecchio e un comando

Fino a ieri le stanze erano illuminate da dieci `OmniLight3D` sospese a mezz'aria: nessuna
lampada sopra, nessun interruttore su un muro. In un gioco che si regge tutto sull'essere un
posto vero era l'unica cosa senza una causa, e Federico l'ha chiamata «magia nera».

Adesso ogni punto luce ha una **plafoniera a neon** sopra e — dove c'è una porta che lo serve —
una **placca a due tasti** sul muro, a 1,10 m. Le posizioni stanno in `geometria.py`
(`PUNTI_LUCE`, `punti_interruttori()`): le leggono sia il modellatore sia il generatore del
blockout, che è l'unico modo perché la lampada e la luce non finiscano in due posti diversi.

**La lampada e la sua `OmniLight` stanno sotto lo stesso nodo**, e per questo la plafoniera
esce in un `.glb` suo invece che insieme alle placche: qui si esporta una mesh per materiale,
e dentro un file unico le dieci lampade sarebbero diventate due mesh sole. Spegnerne una
avrebbe voluto dire spegnerle tutte — oppure lasciare acceso un diffusore emissivo sopra una
stanza al buio, che è peggio di non avere la lampada.

### D-058 — L'interruttore sta dal lato della maniglia, e non «a destra di chi entra»

Prima regola scritta: la placca va **a destra di chi entra**, con la destra calcolata dalla
direzione d'ingresso. È la regola che tutti dicono, e su sette porte ne sbagliava tre —
mandava la placca contro il tramezzo del magazzino, contro quello del disimpegno, e dietro il
distributore di snack.

La regola vera è un'altra: **la mano che apre è la mano che accende**, cioè la placca sta dal
lato della maniglia, che è l'opposto del cardine. E il cardine era già dichiarato in
`APERTURA_PORTE` da quando esistono le porte. Non si dichiara più niente di nuovo: sette
scelte ripetute sono diventate un dato solo letto sette volte. Resta una sola eccezione, e va
detta — dal lato della maniglia della porta di cucina c'è la bacheca alta 1,90.

`verifica_interruttori()` controlla tre cose: che sotto la placca ci sia un muro e che ci
stia (misurando dal **tramezzo più vicino**, non dall'estremo del segmento — su un muro lungo
i vincoli veri sono i muri che lo incrociano); che davanti ci si possa stare; che non ci sia
un mobile addossato.

**Cupola e corridoio non hanno comando**, ed è dichiarato invece che dimenticato: nessuna
porta ci si affaccia dal lato giusto. `luci_senza_comando()` lo stampa a ogni generazione,
perché una dimenticanza e una scelta si somigliano troppo.

### D-059 — Lo stato di un interruttore sono le sue luci, non una sua variabile

Lo spazio divulgazione ha due placche sulle stesse tre lampade — una alla porta d'ingresso,
una a quella del corridoio. Con uno stato locale (`accesa` come verità) la seconda va fuori
fase alla prima pressione della prima, e da quel momento serve premerla due volte.

`LightSwitch._accesa()` rilegge lo stato **dalle lampade**. Sono deviatori, e un deviatore non
sa in che posizione sta l'altro: sa solo com'è la luce adesso.

Non l'ho trovato guardando: l'ha trovato `tools/prova_luce.gd`, che istanzia il blockout
headless e prova ogni placca con **due** scatti. Con un solo scatto una placca fuori fase
sembra rotta o — peggio — sembra sana riscrivendo lo stato che c'era già.

### D-060 — Il proiettore viene da fuori, il carrello no

`filmstrip_projector_8mm` (Poly Haven, CC0): un 8 mm con bobine, obiettivo, manopole e carter.
Il nostro era una scatola con un cono davanti, ed è il pezzo che si guarda entrando in sala.
Il **carrello** resta nostro: sei tubi e due ripiani non valgono un download.

**La rotazione non l'ho dedotta: l'ho provata.** Avevo ricavato 90° guardando dove sta
l'obiettivo nel glTF, e mi ero sbagliato di un quarto di giro — dal render sembrava giusto lo
stesso. Il controllo in fondo a `divulgazione_blender.py` misura di quanto il pezzo `focus`
**sbalza** verso lo schermo rispetto al corpo, e delle quattro rotazioni ne passa una sola. Con
un confronto di solo segno sarebbero passate due: la ghiera è piccola e vicina al centro.

### D-061 — La plafoniera è nostra, e non per mancanza di alternative

`mounted_fluorescent_lights` (Poly Haven, CC0) l'ho scaricato e poi tolto: è un **tubo nudo**
da quattro centimetri con due staffe. Montato a tre metri sparisce, e soprattutto non ha il
diffusore — cioè non ha la superficie che si accende, che è l'unico pezzo che conta di una
lampada. Otto scatole fatte in casa la danno, con il diffusore emissivo che dice da dove
viene la luce. È il secondo modello di fuori scartato dopo `old_computer`, e per la stessa
ragione: preso da fuori non vuol dire migliore.

Il file porta anche una lezione generale, ora in `posa_modello(tieni=...)`: **un modello
esterno non contiene sempre un oggetto solo**. Quello delle plafoniere ne portava sette,
sette varianti dello stesso apparecchio impilate nella stessa posizione, e importarlo intero
dava un pettine di sette lampade sovrapposte che scalato sull'ingombro complessivo diventava
una fila di striscioline.

### D-062 — Il lavello era piatto perché due lastre intere gli passavano sopra

La vasca c'era da sempre: fondo, quattro pareti, sedici centimetri di incavo. Ma sopra ci
passavano il piano in formica **e** il top in acciaio, tutti e due interi, e dall'alto era
una tavola. È lo stesso errore del distributore di D-051: *non era il vetro a non far vedere,
era che dietro il vetro non c'era niente*.

Bucata una lastra sola, il foro mostrava il fianco di legno del mobile — peggio di prima,
perché prima almeno sembrava un lavello chiuso. **Va bucata anche la carcassa**: la vasca
scende dentro il mobile. Il foro è dichiarato una volta (`FORO`) e lo leggono tutti e tre.

Il controllo nuovo non guarda la vasca: guarda **cosa c'è dentro**. Qualunque materiale che
non sia acciaio, dentro il volume dell'incavo, è un pezzo che la sta tappando. È il controllo
che mancava, perché a guardare la vasca la vasca c'era.

**E sotto un lavello non ci vanno cassetti**: lì c'è il sifone e un cassetto non ci passa.
Erano tre, ora sono due ante — due e non una perché il modulo è largo 88 cm, e a un'anta sola
servirebbe una cerniera che non esiste.

---

### D-063 — La placca sta dal lato da cui si arriva, ed è a 1,45

Tre correzioni allo stesso oggetto, tutte e tre da un uso reale.

**Il lato era rovesciato.** Il codice metteva ogni placca *dentro* la stanza servita, che è
l'opposto di quello che il commento accanto dichiarava di fare: la normale era la direzione
d'ingresso invece del suo contrario. In cucina voleva dire aprire la porta, entrare al buio,
richiudere e tornare indietro. Adesso la regola è dichiarata — dal lato **opposto** alla
stanza illuminata — con una sola eccezione, l'ingresso, perché dall'altra parte c'è il prato.

**L'altezza è 1,45 e non 1,10.** Quella vera è 1,10, ma l'occhio del giocatore sta a 1,65 e
il raggio di interazione parte dalla camera e va dritto: per accendere la luce bisognava
accovacciarsi. Fra la quota da manuale e un gesto che funziona vince il gesto, e 1,45 è
comunque un'altezza che esiste — quella dei comandi negli edifici pubblici accessibili.

**Vecchio stile vuol dire una forma precisa:** non la placca a moduli stretti di oggi, ma la
cornice rettangolare svasata con dentro *un* basculante grande, bombato in due falde. Più il
colore: avorio ingiallito, non bianco.

### D-064 — Le placche che non nascono da una porta

La sala divulgazione è grande come tre stanze e ha due porte: da dentro non c'era modo di
spegnere niente di preciso. `INTERRUTTORI_LIBERI` dichiara placche con coordinate proprie —
quattro, tre accanto all'ingresso (libreria, proiezioni, corridoio) e una in cupola.

Erano nate accanto alla porta del corridoio, che sembrava il posto giusto. **Il controllo le
ha bocciate tutte e tre**: lì il muro della cucina incrocia a 4,40 e lo stipite comincia a
4,75, e in trentacinque centimetri lordi non ci sta neanche una placca. Spostate a est
dell'ingresso, il controllo le ha bocciate di nuovo — dopo trenta centimetri comincia la
teca dei meteoriti. Stanno a ovest, dove il montante è libero da 8,25 a 10,00.

Al controllo mancava un pezzo che si è visto solo ora: guardava i muri e non le **aperture**.
Una placca in mezzo a un vano non sta su niente, e nessuno se ne sarebbe accorto finché non
ci si fosse passati davanti.

### D-065 — La cupola ha luce rossa, e di solito non ce l'ha accesa

Chiude il `[NOTE FOR DESIGNER]` che stava in fondo a questo file: **Federico ha deciso, ed è
sì**. La luce bianca brucia l'adattamento al buio dell'occhio e per rifarlo servono venti
minuti — in una sala telescopio o si sta al rosso o si sta al buio.

Il buio è lo **stato normale**: la placca della cupola nasce spenta (`PARTE_SPENTA`), e
quello che si vede entrando è la luce riflessa dalle stanze accanto, attraverso la vetrata.
Accendere il rosso è un gesto; accendere il bianco non è proprio possibile, perché lì la
lampada bianca non c'è. La plafoniera rossa è un `.glb` a parte e non un colore cambiato in
Godot: il materiale porta anche l'emissione, e cambiarla nel motore vorrebbe dire riscrivere
a mano un materiale che in Blender esiste già.

Resta aperto — e stavolta è davvero una domanda di design, non di impianto — se accendere la
luce sbagliata debba *costare* qualcosa al giocatore.

### D-066 — Otto luci per oggetto, e le plafoniere sono dieci

Federico ha visto una plafoniera accesa che non illuminava niente. Non era la lampada: in
OpenGL Compatibility — il renderer scelto dall'architettura — ogni superficie considera al
massimo **otto** luci, e il pavimento dell'ala est è un pezzo solo. Le due in eccesso venivano
scartate in silenzio.

`rendering/limits/opengl/max_lights_per_object=12`, che è sotto il tetto di quindici e lascia
margine. Non si cambia renderer per un difetto che ha una manopola.

### D-067 — Il cubo di default nel .glb, e cosa insegna

Le prime dieci plafoniere sono comparse in gioco come dieci **lastroni azzurri da due metri**
sospesi sopra le stanze: `impianti_blender.py` era l'unico dei cinque modellatori a non
chiamare `pulisci()` in testa, e il cubo di default di Blender è finito nell'export.

Adesso `esporta()` **stampa cosa sta scrivendo**. Un `.glb` non si apre a occhio, ma quello
che ci finisce dentro per sbaglio ha quasi sempre un nome che si riconosce al volo — e
`Cube` in fondo a una riga di nomi di materiali si vede subito.

---

### D-068 — Un comando per locale, e il prompt dice quale

L'impianto era arrivato a undici placche: due sulle stesse tre lampade, una batteria di tre
accanto all'ingresso per accendere separatamente le zone della sala. Federico l'ha guardato e
ha detto la cosa giusta — *non si capisce quale interruttore comanda cosa*. È un difetto
peggiore di una stanza senza interruttore, perché una stanza senza interruttore almeno non
promette niente.

Otto placche, **una per locale, alla porta di quel locale**, e la placca accende la stanza in
cui quella porta entra. Non c'è niente da ricordare. Meglio una sala che si accende tutta
insieme che tre comandi che nessuno riesce ad associare a niente.

E il prompt **nomina il locale**: «Accendi la cucina», «Spegni il corridoio». Con dieci placche
identiche su dieci muri, «Accendi» non dice niente e le si prova a caso.

### D-069 — L'apparecchio non si spegne: si spegne la lampada

Spegnendo una luce spariva la plafoniera dal soffitto. `LightSwitch` nascondeva il nodo
intero, apparecchio compreso.

Ogni lampada adesso è due cose: l'**apparecchio**, che c'è sempre, e la parte **accesa** —
`OmniLight3D` più il pannello del diffusore — sotto un nodo che l'interruttore commuta.

Il pannello acceso sta **nella scena e non nel `.glb`**: in Godot il materiale di un modello è
condiviso fra tutte le sue istanze, e spegnere il diffusore di una plafoniera le avrebbe
spente tutte e nove. Nel modello il diffusore resta, opaco e un po' ingiallito: è come si vede
una plafoniera spenta.

### D-070 — In un `.tscn` le proprietà appartengono all'ultimo `[node]` dichiarato

La luce rossa della cupola non illuminava niente. Non era l'energia e non era la posizione:
il generatore scriveva `visible = false` **in fondo** al gruppo di righe della lampada, cioè
dopo l'intestazione dell'`OmniLight3D` — e quella riga finiva sulla luce invece che sul nodo.
Risultato: la luce nasceva spenta *dentro* un nodo che l'interruttore accendeva senza
accorgersi di niente, perché il nodo era già visibile.

Un errore che il formato non segnala e che nessun controllo vedeva, perché tutto il resto
funzionava: la placca commutava, il test contava due scatti buoni. Adesso lo stato iniziale si
scrive **subito dopo** l'intestazione del nodo che lo porta, e `tools/prova_luce.gd` verifica
anche che l'apparecchio resti visibile a luce spenta.

### D-071 — La notte è buia, e la luna fa ombra

Con `ambient_light_energy` a 0,45 spegnere una stanza non cambiava niente: restava tutto
leggibile, e un interruttore che non fa differenza è un interruttore rotto. Ora è 0,02.

La direzionale — che si chiamava «Sole» in un gioco che si svolge di notte — è una luna a
0,07, **con le ombre**. Senza `shadow_enabled` una direzionale attraversa i muri: illuminava
il pavimento delle stanze interne passando dal tetto, e si vedeva una luce che non veniva da
nessuna parte. Lo specular quasi a zero, perché faceva sul terrazzo una macchia bianca che
seguiva il giocatore.

Ombre anche sulle plafoniere, e non per bellezza: senza, la luce della cucina attraversa il
muro e illumina il corridoio. Premere un interruttore cambiava mezzo edificio, ed è metà della
ragione per cui non si capiva chi comandasse cosa.

### D-072 — In cupola la luce è a parete

La plafoniera della cupola pendeva a mezz'aria sotto la volta: lì il soffitto non c'è, c'è la
calotta, e una plafoniera a soffitto non ha niente a cui attaccarsi. Due **applique** a muro —
nord e ovest — con il vetro rosso, comandate dalla stessa placca. È come si illumina una sala
telescopio, e regge anche l'umidità che lì dentro è quella di fuori.

---

### D-073 — I muri arrivano sotto il tetto, e un controllo guarda l'alzato

Uscendo dall'edificio di notte si vedeva una fascia di luce rossa sopra la facciata, e
sotto il tetto un pezzo di muro mancante. Non era un difetto di resa: era un buco.

I muri finivano a `H` = 3,00 e il tetto comincia a `H_TETTO` = 3,20. Dove il solaio arriva
la fessura è chiusa dal solaio stesso; nella **sala del telescopio** il solaio non c'è —
sopra ha il tetto forato con la calotta — e restavano venti centimetri di feritoia lungo
tutto il perimetro. Ora i muri salgono a `H_TETTO`: da dentro non cambia niente, il soffitto
è sempre a 3,00.

`verifica_fessure()` campiona l'asse di ogni muro perimetrale e cerca, sopra ogni campione,
il pezzo di copertura più basso. **Ha trovato subito un secondo caso** che a occhio non avevo
visto: il foro del tetto aveva lo stesso raggio della cupola, quindi sul muro nord arrivava a
filo, e lì sopra non c'era né tetto né calotta — la calotta comincia diciotto centimetri più
su. Il foro adesso è trenta centimetri più stretto: la cupola poggia su un anello di tetto,
che è anche come poggia una cupola vera.

Gli altri otto controlli non potevano vederlo. Guardano tutti la **pianta** — cosa sta dentro
cosa, cosa si sovrappone, cosa resta scoperto visto dall'alto — e questa era una fessura in
**alzato**.

### D-074 — Il tonemapping, ovvero perché il pavimento accecava

Federico: *sul pavimento vedo bianco in certi punti, da quanto sono forti*. Non erano le
lampade: era la curva di esposizione. Con `tonemap_mode` lineare — il default — tutto quello
che supera l'unità diventa **bianco piatto**, e su un terrazzo chiaro la zona sotto ogni
plafoniera ci arrivava. Lo stesso difetto slavava il rosso della cupola, che nel punto più
intenso virava al rosa: tre canali saturi fanno bianco, qualunque colore avesse la luce.

ACES (`tonemap_mode = 3`) comprime le alte luci invece di tagliarle, quindi un colore saturo
resta il suo colore anche dove è forte. È la correzione che ha reso possibili tutte le altre:
prima di averla, abbassare l'energia era l'unico modo di non sbiancare, e abbassandola le
stanze diventavano buie.

Nello stesso giro: `light_specular` basso sulle plafoniere (la chiazza bianca che seguiva chi
cammina era il riflesso speculare, non l'illuminazione) e a zero sulla luce rossa.

### D-075 — Cosa rende inquietante una luce rossa

Non quanta ne fai. Una sorgente **piccola e accesa in mezzo al nero**, con la luce che cade in
fretta: `omni_attenuation` a 2,2 invece di 0,9, e il vetro dell'apparecchio che brilla oltre
l'unità. Con l'attenuazione bassa la sala diventava uniformemente rosa e non faceva né paura
né luce.

E **rosso puro**: zero verde e zero blu. Avevo messo cinque centesimi di blu per avvicinarmi
al rosso delle uscite di sicurezza, e su una parete chiara facevano virare al viola tutto
quello che la luce toccava di sfuggita.

Il buio attorno è parte dell'effetto quanto la luce: `ambient_light_energy` a 0,007 e la luna
a 0,035. Senza lampade accese non si legge più la stanza — che è la ragione per cui esistono
gli interruttori.

---

### D-076 — Forward+ al posto di gl_compatibility

**Cambia una scelta dell'architettura**, e non per gusto: era il vincolo che rendeva
impossibile la cosa chiesta. In OpenGL Compatibility le luci puntiformi con ombra sono poche
e si **escludono a vicenda** — accendendo la luce rossa della cupola si spegnevano quelle
della sala divulgazione, che restavano accese a vedersi e non illuminavano più niente.
Nessuna manopola lo risolveva: `max_lights_per_object` era già al massimo (15) e l'atlante
delle ombre a 8192.

Forward+ raggruppa le luci in cluster e non ha quel tetto. Si torna indietro cambiando una
riga in `project.godot`, che è il motivo per cui la riga ha accanto il perché.

### D-077 — Le modifiche a un generatore possono fallire in silenzio

Per tre giri ho riferito a Federico di aver abbassato la luce ambientale mentre nel `.tscn`
restava a 0,45 — una stanza spenta continuava a essere perfettamente leggibile. Le
sostituzioni cercavano un testo che finiva con `'']` mentre il sorgente prosegue con `'',`,
e una `str.replace` che non trova niente **non è un errore**: restituisce la stringa
identica e il programma continua.

`gen_blockout.py` adesso **rilegge il file che ha scritto** e controlla che i valori che
contano ci siano davvero — ambiente, tonemapping, bias, prompt dei locali — e lo stampa. Il
principio è quello di tutti gli altri controlli del progetto: non fidarsi di aver fatto una
cosa, guardare il risultato.

### D-078 — Il buio ha un limite inferiore, e lo detta il gesto

Tre giri per trovarlo. A 0,45 di ambiente spegnere non cambiava niente; a 0,0025 non si
trovava l'interruttore per riaccendere, e un buio in cui non si può fare la cosa che toglie
il buio non è atmosfera, è un muro. Sta a **0,035**, con la luna a 0,22 — perché di notte da
una finestra si vede attraverso solo se dall'altra parte c'è qualcosa da vedere.

Il vetro ha smesso di essere lattiginoso: 6% di opacità invece di 16, che era troppo per una
lastra sottile e diventava il doppio con due lastre in fila (davanti e dietro una teca).

**Il buio non si risolve con più lampade.** Ne avevo aggiunte due in sala per togliere
l'ombra fra l'una e l'altra: cinque plafoniere in una sala di servizio sono un negozio, e
Federico l'ha detto subito. Il vuoto fra le lampade si toglie con portata ed energia, che
sono numeri, non con altri apparecchi appesi al soffitto.

### D-079 — La spia di localizzazione

Al buio la placca non si vede: è avorio su intonaco avorio, alta quindici centimetri, in una
stanza dove per definizione non arriva luce. La risposta non me la sono inventata — gli
interruttori italiani di quegli anni avevano la **spia arancione**, e ce l'avevano
esattamente per questo. Il problema che risolve nel gioco è lo stesso che risolveva in casa.

### D-080 — Il mirino è un punto, e si apre

Un punto di due pixel al centro: serve a sapere dove guarda il raggio dell'interazione, che
parte dal centro esatto della camera — senza riferimento si mira a tentoni un interruttore da
undici centimetri. Una croce da sparatutto direbbe una cosa che questo gioco non fa.

Guardando un interagibile il punto **si apre** in quattro trattini invece di cambiare colore:
a 640x360 un punto di due pixel che cambia tinta non lo si vede, uno che cambia forma sì. È
la stessa notizia del prompt in basso, ma dove sta già l'occhio, e la scrive lo stesso punto
del codice — `_set_focus` — perché due posti divergono.

Vive nel `SubViewport` come `InteractionPrompt`, per la stessa ragione: la grana della stanza
e non quella di un'interfaccia moderna appiccicata sopra.

**Nota che vale oltre il mirino:** `%Nome` si risolve nel **proprietario** della scena.
Marcare unico un nodo dentro `crosshair.tscn` non lo rende raggiungibile come `%Mirino` dal
giocatore che la istanzia, e nemmeno ridichiararlo unico nell'istanza: il risultato è un
errore a ogni avvio e un mirino che non c'è. Dentro una scena istanziata si va per percorso.

---

### [DECISA] — la luce rossa, che nel GDD non c'era

In tutte le foto notturne l'osservatorio è **illuminato di rosso**, e il documento non lo
dice da nessuna parte. Non è un'atmosfera scelta: è una necessità di mestiere, perché la luce
bianca brucia l'adattamento al buio dell'occhio e per rifarlo servono venti minuti.

**Perché varrebbe più di un dettaglio d'arredo:** darebbe al giocatore una regola vera —
accendere la luce sbagliata *rovina* qualcosa e costa tempo reale — in un gioco che è fatto
di attesa e di notte. Aggancia il pilastro 2 senza inventare nulla, e la lampada di D-018
(registro SISTEMARE) è già lì. **Decisa il 30 agosto 2026: si fa.** Vedi D-065 — la cupola ha la plafoniera rossa
e nasce spenta. Quello che resta aperto e' se accendere la luce sbagliata debba
*costare* qualcosa: quella e' una domanda di design, non di impianto.

---

### D-081 — In un `.tscn` la matrice si legge per RIGHE

I dodici numeri di `Transform3D` in un file di scena sono le **righe** della base. La
colonna X — l'asse che il modello segue — è `(r0[0], r1[0], r2[0])`, non la prima terna.
Averla letta per colonne ha montato al contrario ogni apparecchio su un muro orientato
lungo Z: le due applique esterne finivano **dentro** l'edificio (lente a z 9,47 dentro il
muro, faretto a 9,38 in sala) e la rossa della cupola finiva **fuori**, con la lampada a
z −0,40 sulla facciata nord.

**Il difetto non si presentava come "montata al contrario".** Si presentava come luce che
attraversa i muri, e su quella ho speso mezza giornata di bias delle ombre, sfocature e
atlanti. Non attraversava niente: la lampada era già dall'altra parte. Una diagnosi
sbagliata sopravvive finché il sintomo resta plausibile.

La stessa firma ha colpito una porta sola — quella fra corridoio e divulgazione, l'unica su
muro verticale. Sulle porte orizzontali `dz` è zero e il segno non si vede: **la metà che
funziona nasconde la metà rotta**, che in questo progetto è la terza volta.

`verifica_orientamenti()` rilegge il `.tscn` scritto e confronta ogni asse con quello
dichiarato in `geometria.py`.

### D-082 — Le chiavi dentro `[rendering]` non ripetono la sezione

`use_debanding`, l'atlante delle ombre a 8192, i quadranti, il limite di luci per oggetto:
scritti come `rendering/anti_aliasing/...` **dentro** la sezione `[rendering]`, diventano
`rendering/rendering/...`. Godot li registra, non protesta, e non li legge mai. Per tre
sessioni ho riferito acceso quello che era spento — e ho controllato ogni volta il file,
mai il motore:

    prima:  DEBANDING false  ATLANTE 4096  q3 4
    dopo:   DEBANDING true   ATLANTE 8192  q3 3

**Un'impostazione si verifica chiedendola a chi la usa.** `ProjectSettings.get_setting()`
in un `--script` di tre righe costa dieci secondi e avrebbe risparmiato una giornata.

### D-083 — `omni_attenuation` è un ESPONENTE, non uno smorzamento

Vale `distanza^(-attenuation)`. Alzarlo per "spegnere" una lampada la rende più forte, e in
modo violento: a sette centimetri da un muro `0,07^(-3,5)` vale undicimila, contro i
duecento di un normale inverso del quadrato. Abbassare l'energia di mille volte contro un
guadagno di undicimila lascia una lampada accesa — ed è quello che si vedeva alle spie degli
interruttori, tre giri di seguito, mentre io continuavo ad alzare l'esponente.

Corollario sul rosso della cupola: **il nucleo bianco non veniva dalla potenza ma
dall'esponente**. Sceso a 1,5 il centro cala di più della metà e il campo lontano sale — la
stanza si illumina invece di avere un punto bruciato e il resto scuro.

### D-084 — Gli anelli concentrici si misurano, non si guardano

Quattro cause raccontate, quattro rimedi applicati, tutte e quattro dedotte da una
fotografia guardata a occhio. A occhio non si distingue una fascia di quantizzazione da un
gradino d'ombra. `tools/scatto_cupola.gd` salva un fotogramma da un punto fisso e se ne
leggono i pixel: **fasce di 20-40 pixel identici che differiscono di UN livello su 255** —
quantizzazione, non ombre.

Da lì i due rimedi veri: il debanding acceso davvero (D-082) e la calotta con la texture
della lamiera. Una superficie perfettamente liscia è la tela ideale per il banding, perché
il gradiente non ha niente che lo interrompa; la grana di una lamiera lo rompe con una cosa
che c'è davvero invece di mascherarlo. Sulla cupola la fascia più lunga è passata da 41
pixel a 13.

### D-085 — Un modello che ne importa un altro va ricostruito dopo

`osservatorio.glb` incorpora `cupola.glb` e `telescopio.glb` al momento della costruzione.
Rifatta la cupola con lo shading liscio, reimportata da Godot, in gioco continuava a girare
quella sfaccettata — e io davo la colpa alle ombre. `verifica_freschezza()` confronta le
date e lo dice.

---

### D-086 — Avviare il gioco non reimporta i modelli

Godot reimporta i `.glb` cambiati solo in una passata da **editor**. Avviando la
scena si usa quello che sta in `.godot/imported`, che resta il vecchio — senza un errore,
senza un avviso. Ho ricostruito la cupola con lo shading liscio, l'ho vista scritta su
disco, e in gioco continuava a girare quella sfaccettata mentre davo la colpa alle ombre.

La sequenza di ricostruzione ha adesso un quinto passo obbligatorio in `assets/LEGGIMI.txt`:

    Godot --headless --editor --quit --path .

E `verifica_freschezza()` copre il caso gemello: `osservatorio.glb` incorpora `cupola.glb`
e `telescopio.glb` al momento della costruzione, quindi rifare il pezzo senza rifare il
contenitore lascia in gioco il pezzo vecchio.

### D-087 — La passerella si rifà, non si toglie

Quattro difetti, una causa sola: `aggiungi()` non sapeva ruotare attorno a Y. L'anello era
sedici scatole **allineate agli assi** su una circonferenza — copriva l'arco dove correva
dritto e lo lasciava scoperto in diagonale. `verifica_passerella()` percorre la mezzeria
ogni due gradi: con la geometria vecchia trova **40 punti su 180 sospesi nel vuoto**.

E la larghezza che conta non è quella dell'impalcato ma **quella netta fra gli ostacoli**:
0,85 meno due parapetti da 7 cm fa 0,71 contro una capsula da 0,60, cioè undici centimetri
di gioco. L'impalcato è passato a 1,05 e il parapetto interno è sparito — non per far
posto, ma perché non ha più niente da proteggere: il pozzo centrale è pieno fino a filo
del calpestio. Una ringhiera davanti a un muro è solo una cosa contro cui incastrarsi.

**Il numero sbagliato era uno solo, e stava fuori dalla sua fonte.** `telescopio_blender.py`
teneva `PASSERELLA = 0.99` scritto a mano mentre `geometria.py` dice 0,59: il controllo
dell'oculare girava contro il numero sbagliato e approvava.

### D-088 — Una porta non cambia verso per far comodo

I cardini stanno da una parte sola, e girarli secondo dove sta il giocatore renderebbe
l'ingresso una porta che si apre verso l'interno — che è esattamente quello che una via di
fuga non può fare. Chi apre una porta verso di sé fa un passo indietro: lo fa la porta per
lui, spingendolo fuori dal settore spazzato con `move_and_collide`, così un muro alle
spalle lo ferma invece di farlo attraversare.

Dove il muro c'è davvero — il magazzino è largo 1,55 — la spinta si ferma prima, e allora
**la porta si apre di meno**, fermandosi a filo di chi l'ha aperta.

`tools/prova_porte.gd` lo verifica su tutte e sette, e prova anche il contrario: un corpo
dal lato opposto non deve muoversi di un millimetro, o ogni porta diventa un pistone.

### D-089 — Il nero non era un materiale, era il controluce

Passerella, ringhiera e telescopio erano sagome nere anche a luce rossa accesa. Ho seguito
la pista del metallico — una lamiera verniciata con la mappa metallica collegata diventa
uno specchio, e uno specchio in una stanza senza niente da riflettere è nero — e **non era
quella**: misurato, il metallico effettivo era già zero. La correzione resta perché era
sbagliata comunque, ma la causa era la disposizione: le due lampade rosse stavano
tutte e due sui muri in fondo, quindi chi entrava aveva la luce in faccia e la platea
davanti. Una terza applique sul muro d'ingresso, e si vede.

Il tubo restava scuro dopo, e lì il colpevole era il colore: albedo blu (0,09 di rosso)
sotto una luce rossa pura restituisce il nove per cento. Schiarito.

**Il banco di misura mentiva.** `scatto_cupola.gd` accendeva le rosse in `_init`, ma
`LightSwitch._ready()` riapplica il proprio stato alle lampade e dentro `_init` di una
`SceneTree` quel ready arriva dopo: ogni scatto misurava una stanza al buio credendo di
misurarla accesa. Uno strumento di misura si verifica prima di credergli — è la stessa
lezione di D-082, e l'ho imparata due volte nello stesso giorno.

### D-090 — Il telescopio si prende da fuori, e montarlo è un mestiere diverso dal modellarlo

Fatto a mano era cinquanta fra cilindri e scatole, ed era la cosa più brutta della stanza:
un tubo liscio senza un bullone. Le minuzie — viti, collari, manopole, cavi flessibili —
sono esattamente quello che fa leggere uno strumento come uno strumento, e non si
modellano in una serata.

I candidati scaricabili li ho **aperti e misurati**, non guardati in anteprima: il Dobson
CC0 di OpenGameArt è 310 facce di primitive chiamate `Cylinder.003`, il rifrattore CC-BY è
924 triangoli senza materiali su un treppiede fotografico, Poly Haven non ha telescopi e
Poly Pizza vuole una chiave. Quello giusto — newtoniano su equatoriale tedesca, 13.272
facce, texturizzato — sta su Sketchfab, la cui API di ricerca è aperta e quella di
download no: **è l'unico asset del progetto che va scaricato a mano**, e `A_MANO` in
`prendi_modello.py` tiene versionata la scelta anche se il file non lo è.

È CC-BY, e questa è la prima licenza del progetto che chiede qualcosa. `assets/models/` è
gitignorato, quindi un credito scritto in un `FONTE.txt` lì dentro non viaggerebbe col
gioco: da qui `CREDITI.md` in radice.

Montarlo non è modellarlo. Il treppiede si butta — in una cupola lo strumento sta su un
pilastro di cemento — e la gerarchia si ricostruisce, perché il modello arriva come
cinquantacinque oggetti piatti in una lista: è una scultura, non una macchina.

### D-091 — Gli assi di una montatura si misurano, non si leggono dai nomi

I pezzi si chiamano `Xaxis`, `Yaxis`, `Load`, `Main`: nomi parlanti, e fidarsene sarebbe
stato comodo. L'analisi delle componenti principali dei vertici dice invece **dove punta
davvero ogni pezzo**, e i numeri sono usciti perfetti: asse di declinazione ortogonale al
polare a meno di 1e-4, le due rette incidenti a mezza unità, asse polare a 43,2 gradi
contro i 43,9 di Montegrimano — sette decimi, si raddrizza.

Da lì la divisione in fermo / ascensione retta / declinazione, con due controlli che la
verificano invece di darla per buona: ogni pezzo del file dev'essere nominato in un
gruppo (se il modello cambia, la costruzione si ferma invece di lasciare un pezzo per
terra), e ogni pezzo dichiarato solidale al tubo deve stare dalla parte del tubo rispetto
all'asse di declinazione — che è la definizione di equatoriale tedesca.

**Il pilastro va sotto l'incrocio degli assi, non sotto la colonna.** Sembra la stessa
cosa e non lo è: l'asse polare è inclinato, e il punto attorno a cui la testa gira sta
ventun centimetri di lato. Centrando la colonna, tutto ciò che ruota spazzava un cerchio
scentrato di altrettanto — e sfondava la passerella.

### D-092 — Le quattro rotazioni sono quattro nodi, e zero è il riposo

`Polo` e `Declinazione` portano solo l'orientamento degli assi; `AssePolare` e `AsseDec`
ruotano solo attorno al proprio Z. Con orientamento e rotazione sullo stesso nodo sarebbe
l'ordine degli angoli di Eulero a decidere il risultato, e inseguire diventerebbe un
problema di convenzioni invece che una rotazione sola.

**La posa si applica dopo aver appeso le mesh ai perni.** Prima non si vedeva:
`matrix_parent_inverse` viene calcolata sul genitore com'è in quel momento e annulla
esattamente la rotazione che il genitore aveva già. Costruito nell'altro ordine il
telescopio restava a riposo qualunque angolo si scrivesse, e nessuno se ne accorgeva
perché il riposo è a sua volta una posa sensata. Ne segue il contratto per l'inseguimento:
**AssePolare e AsseDec a zero danno il telescopio in posizione di riposo.**

### D-093 — Non «urta o non urta», ma fino a che altezza può scendere

Il primo controllo sulla passerella vietava allo strumento di sporgere sopra l'anello a
qualunque quota sotto i due metri e mezzo, e sbagliava la domanda: la passerella **esiste**
per arrivare all'oculare, quindi il telescopio ci deve passare vicino per forza. Il difetto
vero è solido contro solido — il tubo dentro l'impalcato o il parapetto.

E anche così la risposta binaria non serve: combinando le due rotazioni il tubo copre la
sfera intera, e a puntamenti bassi la culatta scende e si allarga. Urta sempre, in ogni
cupola, anche in quelle vere. Il numero che conta è **il puntamento più basso a cui resta
libero** — 26 gradi — che non è un difetto ma un dato di progetto: l'altezza sotto la quale
in questo osservatorio non si osserva, e che l'inseguimento dovrà rispettare.

Si misura la **distanza**, non si risponde sì/no. Con una soglia si arriva sempre allo
stesso vicolo: il numero passa o non passa e non si sa di quanto, e per tre giri di seguito
ho stretto e allargato un margine credendo di spostare il telescopio mentre spostavo solo
la mia soglia.

Nello stesso giro sono saltati fuori tre numeri della passerella ribattuti a mano qui
dentro — 0,975, 1,825, 0,99 — e **nessuno dei tre era più vero**: l'anello era stato
allargato a 1,05 e abbassato a 0,59, e il controllo continuava a dire che andava tutto bene
misurando una passerella che non esisteva. Ora arrivano da `geometria.py`, come tutto il
resto.

### D-094 — La mappa metallica di un modello scaricato si stacca, sempre

Il 93% della superficie del telescopio è dichiarata metallica a 0,93. Dentro una cupola
dove non c'è niente da riflettere, quello è il modo esatto in cui un oggetto diventa nero —
lo stesso difetto che avevo già corretto sul telescopio fatto a mano, che arriva gratis con
ogni modello preso da fuori perché chi lo ha fatto lo guardava in uno studio con
un'illuminazione a 360 gradi. Metallico costante a 0,2: la vernice a fuoco di uno strumento
riflette un poco, uno specchio no.

Le texture arrivano a 4096 e diventano 1K: ventidue megabyte dentro il `.glb` della stanza,
per un tubo che si guarda da un metro.

### D-095 — Scostare non è sparare indietro: il limite non è sullo spazio, è sulla velocità

La cura di D-088 — la porta che si apre verso di te ti sposta invece di attraversarti —
era giusta nel principio e sbagliata nel modo: **un `move_and_collide` solo, al momento
dell'interazione**. Mezzo metro abbondante in un fotogramma, cioè trentasei metri al
secondo. Non si legge come farsi da parte, si legge come un calcio.

Lo spostamento non si può ridurre: lo impone la geometria del settore, e per uscire da
sotto un'anta lunga novanta centimetri bisogna spostarsi di ottanta. Quello che si può
fare è **distribuirlo**. Adesso l'anta gira un fotogramma alla volta, scosta di quel tanto
che serve in quel fotogramma, e non supera mai 1,1 m/s — la velocità di una camminata.

Il freno vincola anche l'anta, ed è la parte che non era ovvia: la stessa rotazione, a un
metro dal cardine, sposta il doppio che a mezzo. Quindi la porta rallenta in funzione del
raggio a cui sta chi si sta scostando, e la spinta resta sotto il tetto qualunque sia la
posizione. Costa mezzo secondo in più e vale tutto il resto.

**Distanza dal segmento, non angolo.** Il primo tentativo decideva chi era «nel giro»
dall'angolo rispetto al cardine, e un corpo a mezzo metro dal cardine ne sottende trentotto
di gradi: chi stava *dietro* la porta, dalla parte opposta, risultava comunque dentro il
settore e veniva spinto. L'anta è un segmento, e ciò che conta è la distanza da quel
segmento.

Il conto si rifà a ogni fotogramma, e da questo viene un guadagno che non avevo cercato:
la porta che si è fermata contro un muro **finisce la corsa da sola** appena ci si sposta,
invece di restare mezza aperta finché non la si richiude.

### D-096 — Il banco passava anche col difetto rimesso apposta

Tre difetti nello strumento di misura, e nessuno visibile guardando i risultati.

Il primo: **misurava lo spostamento leggendo la posizione due volte nello stesso istante.**
Il callback del banco gira prima dei nodi, quindi fra le due letture la porta non aveva
ancora mosso niente e la velocità risultava zero sempre. Rimessa la spinta istantanea,
il banco diceva zero guasti.

Il secondo: **metteva la persona «dalla parte opposta» addosso al battente** — trentacinque
centimetri dal filo dell'anta chiusa, meno del margine. La porta la sfiorava chiudendosi e
il banco la chiamava pistone. Non era un difetto della porta, era il banco che pretendeva
che una porta non toccasse chi le sta appiccicato.

Il terzo, ed è il più insidioso: **una porta che non si apre non fa male a nessuno.**
Tolta del tutto la spinta, l'anta si ferma a sei gradi contro chi ha davanti e tutti i
controlli di sicurezza passano — nessuna compenetrazione, nessuno strappo, nessun pistone.
Serviva il controllo opposto: se non si è aperta, allora qualcuno si DEVE essere mosso.

Nessuno dei tre si vedeva leggendo il codice del banco. Si sono visti tutti e tre
**iniettando il difetto che il banco esiste per trovare** e guardandolo passare.

### D-097 — Il mouse era già a destra: era il modello a essere vecchio

Due volte mi è stato detto che il mouse sta a sinistra della tastiera, e due volte l'ho
spostato — nello stesso file, che nessuno ricostruiva. `controllo_pc.glb` era di due ore
prima della modifica, e in gioco c'era ancora quello.

E non era nemmeno una dimenticanza. Lo spostamento **faceva fallire un controllo**: con la
sedia in mezzeria a 1,59 e la consolle che finisce a 1,20, a destra di chi si siede
restano trentanove centimetri, e la tastiera da sola ne occupa quarantasette. Il mouse
finiva a sbalzo oltre il bordo, `verifica_impronte` lo diceva, e lo script usciva con
`sys.exit(1)` **prima di esportare**. Il controllo ha funzionato perfettamente: ha impedito
di scrivere un modello sbagliato. Poi però il modello vecchio è rimasto lì, valido,
caricabile, indistinguibile — e il gioco ha continuato a mostrarlo.

Quindi la cura non è spostare il mouse, è **spostare la postazione**: la sedia va a 2,00 e
a destra restano ottanta centimetri, che è quanto serve per posarci un mouse. Una scrivania
di due metri e ottanta con la postazione schiacciata in fondo era un difetto suo,
indipendente da tutto questo.

E la destra è −Z, non +Z: chi si siede guarda la vetrata, cioè −X, e ruotando di novanta
gradi il suo +X finisce su −Z. L'avevo dedotto giusto la prima volta e poi rimesso in
discussione guardando una fotografia — che era la fotografia del modello vecchio.

### D-098 — Un modello vecchio non dà errore: va chiesto a chi lo legge

Tre modi diversi di giocare con un modello che non esiste più, e li ho fatti tutti e tre:

1. **un modello che ne incorpora un altro** e non viene rifatto dopo (la cupola sfaccettata);
2. **uno script modificato e mai rilanciato**, o rilanciato e fermato da un controllo (il mouse);
3. **un .glb non reimportato**, perché avviare il gioco non reimporta niente.

Da fuori sono identici: si guarda il gioco e si vede roba vecchia. Nessuno dei tre dà
errore. `verifica_freschezza` adesso li copre tutti e tre — c'era solo il primo — e la
tabella `SCRIVONO` dice quale script produce quale modello, così chi aggiunge una stanza
aggiunge una riga.

**Il terzo controllo confronta gli MD5, non le date, perché è l'MD5 che guarda Godot.**
Con le date gridava «da reimportare» su cucina e impianti, che erano già esattamente
quelli in partita: ricostruire senza cambiare niente riscrive il file con lo stesso
contenuto, la data avanza e Godot giustamente salta l'import. Un controllo che grida
quando va tutto bene si impara a ignorare, ed è il modo migliore di non accorgersi di
quando ha ragione.

Validato iniettando i due difetti — uno script toccato dopo il suo modello, un modello
cambiato e non reimportato — e guardandoli comparire.

### D-099 — Un angolo fra due muri non è la somma di due muri

Un muro va da asse ad asse ed è spesso SP centrato sull'asse. Dove due muri
**finiscono entrambi** nello stesso punto, il quadrato di SP/2 × SP/2 dalla parte
esterna dell'angolo non lo copre nessuno dei due: resta un intaglio di dieci
centimetri alto quanto il muro. Otto angoli su ventiquattro incroci — tre dentro,
cinque sulla facciata.

Non si legge come un buco: ci si vede attraverso solo di sguincio, e da dentro l'angolo
sembra fatto a scalino invece che a spigolo. È esattamente come mi è stato descritto:
«molti muri non fanno un angolo a 90 ma quasi un gradino».

Nessuno degli altri controlli lo vedeva, e non per distrazione: `verifica_fessure` cerca
l'aria fra il muro e ciò che gli sta **sopra**, `verifica_raccordi` gli scalini fra
pavimenti, `verifica_ingombri` ciò che sborda dalla sagoma. Questo è un pezzo di spigolo
che manca in **pianta**, e non somigliava a nessuno dei difetti già noti.

La cura è allungare ogni muro di mezzo spessore **su quell'estremo e solo lì**: il pezzo
in più cade dentro l'ingombro del muro che gli sta di traverso, quindi non sporge da
nessuna parte. Dove invece un muro ne **incrocia** un altro senza finirci — la T di un
tramezzo — l'angolo è già pieno, e allungare farebbe spuntare un moncone nella stanza di
là. La distinzione fra «due muri finiscono qui» e «uno passa e l'altro finisce» è tutto
il contenuto della correzione.

`verifica_angoli` guarda i quattro quadranti attorno a ogni incrocio e segnala quello
vuoto che ha pieni tutti e due i vicini — perché quello è un angolo, non una fine.
Validato riaprendo gli angoli: ne trova otto, e con la cura zero.

### D-100 — Una porta di magazzino non è un'anta grigia

In un edificio pubblico italiano di fine anni Novanta il magazzino ha una porta in
lamiera pressopiegata: è quella che dice «qui dentro non ci sta un ufficio, ci stanno
le casse». Con l'anta di legno come tutte le altre, il locale non si distingueva da un
bagno.

E la differenza non è il colore. Una lastra grigia liscia resta una porta di legno
dipinta di grigio: sono le **nervature** stampate, la **griglia di aerazione** in basso
e il **portalucchetto** a farla leggere come lamiera. Il portalucchetto sta su una
faccia sola — un magazzino si chiude da fuori — ed è il pezzo che, da solo, dice che
locale c'è dietro.

Le nervature erano alte otto millimetri e non si vedevano: senza occlusione ambientale
un rilievo così basso non fa ombra, e l'anta tornava a leggere come una lastra. A
quindici si vedono, ed è anche la bugna vera di una porta pressopiegata.

`PORTE_METALLO` sta in `geometria.py` accanto a `MANIGLIONE` e `APERTURA_PORTE`: quali
porte sono di lamiera è un dato della pianta, non una scelta del modellatore. Se ne
segue anche il controtelaio — un'anta di lamiera non sta in un telaio di legno.

### D-101 — Lo stesso 0,50 vale 0,50 in Blender e 0,21 in Godot

La stessa lamiera è tinta in due file: il telaio in Blender, l'anta nel `.tscn`. Tinta
dichiarata identica, 0,50. **Misurate, uscivano 100 e 52 su 255** — l'anta la metà del
suo telaio.

`albedo_color` di Godot è in **sRGB** e viene convertita in lineare per illuminare; il
Base Color di Blender è **già lineare**. Lo stesso numero vale 0,21 di qua e 0,50 di là,
cioè due volte e mezzo. 0,73 in sRGB è 0,50 in lineare, e con quello anta e telaio
misurano 96 e 100.

Sotto c'era un secondo difetto che il primo nascondeva: `applica_texture` prende la
tinta dalla tavolozza di `modellare.py`, dove i nomi dei materiali di
`osservatorio_blender.py` non esistono. Non trovandoli moltiplicava per bianco, cioè
**non tingeva affatto** — il telaio usciva color alluminio. Dichiarare un materiale
«tinto» in `TINTI` non basta se poi la tinta non c'è: adesso la passa chi la conosce.

Nessuno dei due si vede leggendo il codice, e nemmeno guardando la porta: si vedono
misurando i pixel di anta, telaio e muro nello stesso scatto. Per farlo serviva poter
guardare una stanza a luce rossa come la si guarda quando la si deve giudicare, e da lì
`SCATTO_FARO` in `scatto_cupola.gd` — una lampada sulla camera.

## D-102 — Le porte si aprono a 90°, e gli 80 erano una paura mai misurata

**Contesto.** Giocando, le porte «non si aprono mai del tutto»: restano socchiuse.

**Cosa c'era.** `apertura_gradi = 80.0`, con una motivazione scritta ma mai
verificata — «una porta aperta a filo di muro sembra smontata». Nessuno aveva mai
misurato *dove* l'anta sbatte davvero.

**La misura.** Il banco adesso prova la sagoma dell'anta grado per grado contro
tutta la scena (`intersect_shape`, box stretta di 2 cm per lato perché sfiorare il
telaio non è sbattere). Nessuna porta tocca niente prima di **102°**; la più
generosa arriva a 118. Gli ottanta gradi non proteggevano da nulla.

**Decisione.** 90°. Resta un margine di dodici gradi sulla porta peggiore.

**Perché è una voce di log.** Il numero da solo si cambia in un secondo; quello che
vale è il controllo che adesso lo tiene onesto: alzarlo a 125 fa fallire il banco su
tutte e sette. Un tetto d'apertura senza una misura dello spazio disponibile è un
numero inventato, e c'è rimasto per mesi.

## D-103 — Chi apre una porta in corridoio fa un passo indietro, non si appiattisce al muro

**Contesto.** Tre porte su sette (magazzino, corridoio→spazio, disimpegno) si
fermavano fra i 58 e i 68 gradi con chi le apre davanti, e sembravano rotte.

**La causa.** La spinta di D-088 scosta **perpendicolarmente all'anta**, ed è la
direzione giusta — è come spinge una porta vera. Ma `move_and_collide` non scivola:
in corridoio, dopo mezzo metro c'è la parete opposta, la spinta muore lì e l'anta si
ferma a filo. Funzionava in mezzo a una stanza e falliva esattamente dove serviva.

**La cura.** Il residuo dell'urto si gira lungo il muro (`get_remainder().slide()`).
Chi apre una porta in corridoio non si appiattisce contro la parete: fa un passo
indietro *lungo* il corridoio, ed è quello che adesso succede. Corridoio→spazio passa
da 66 a 90 gradi, disimpegno da 68 a 74. Il tetto di velocità non cambia: il residuo
scivolato è più corto della spinta, quindi resta sotto `SPINTA_MASSIMA`.

**Cosa NON è cambiato.** Il magazzino resta a 58 gradi con qualcuno piantato davanti:
lì la spinta arriva quasi perpendicolare al muro e lo scivolamento non produce niente.
È corretto così — davanti a una porta stretta che si apre verso di te, un passo di
lato lo devi fare tu. Appena ti muovi la porta finisce da sola.

## D-104 — Il banco non chiedeva alla porta di finire la corsa

**Contesto.** `door.gd` promette dal commento che fermarsi a filo di chi apre è una
*pausa* e non una posa: «il conto si rifà a ogni fotogramma, quindi appena ci si
sposta la porta finisce di aprirsi da sola». Nessuno lo verificava.

**Perché conta.** È la promessa che rende accettabile tutto il resto. Se fosse falsa,
ogni porta stretta resterebbe socchiusa per sempre — cioè esattamente ciò che si
vedeva giocando, e non avrei saputo distinguere le due cause.

**Il controllo.** Dopo la corsa il banco toglie di mezzo il corpo e pretende che
l'anta arrivi ad `apertura_gradi`. Validato iniettando la resa: basta spegnere il
`_physics_process` quando l'anta è bloccata e tutte e sette si fermano a 8 gradi.

## D-105 — Una lampada addosso al giocatore: si vede quello che sfiori, non la stanza

**Richiesta.** Il nero molto nero resta — è deciso, è l'atmosfera — ma stando vicino
a qualcosa si deve vedere un pochino di più. È una convenzione reale dei giochi al
buio, e la sua assenza si legge come un difetto: si cammina sbattendo contro
rettangoli invisibili.

**Cosa NON si è fatto.** Alzare la luce ambientale. Sarebbe stata la strada di due
righe, e avrebbe schiarito il fondo della stanza — cioè avrebbe pagato la
prossimità con l'unica cosa che il buio doveva dare.

**Cosa si è fatto.** Una `OmniLight3D` sul giocatore, 40 cm sotto l'occhio, energia
0,3, portata 3 m, caduta 1,8, `light_specular = 0`. La posizione bassa non è un
dettaglio: una lampada sull'occhio illumina solo ciò che vedi e da lì non fa ombra,
quindi appiattisce tutto come un flash. Dal petto arriva radente e la forma si legge.

**Le ombre sono accese, e sembrava uno spreco.** Sono metà del lavoro: senza, la
luce attraversa i muri (misurato: +173 livelli sul pavimento della stanza accanto) e
soprattutto un oggetto vicino viene illuminato senza proiettare ombra, cioè resta
una sagoma piatta. La forma di quello che hai accanto è tutto il punto.

**Numeri.** Una parete passa da 7 a 73 su 255 a settanta centimetri, da 7 a 29 a un
metro e mezzo, e da 2,5 m in poi non cambia di un livello. Il buio comincia dove
cominciava prima.

## D-106 — Il banco della luce ha sbagliato bersaglio tre volte, e ogni volta diceva che andava tutto bene

Vale come voce a sé, perché è la parte che ha richiesto quasi tutto il lavoro e
perché tre volte su tre il banco **passava** mentre misurava la cosa sbagliata.

1. **Misurava una stanza illuminata.** Le plafoniere erano accese: la lampada
   aggiungeva pochi livelli su una parete che ne aveva già centoventi. Adesso il
   banco spegne tutto: la domanda è cosa fa questa luce *in una stanza al buio*.

2. **Misurava un battente di noce credendo fosse un muro.** Il criterio geometrico
   («parete piana e verticale») accetta benissimo una porta. Con l'albedo del noce la
   stessa lampada dava +30 livelli invece di +215: la taratura ne usciva sbagliata di
   dieci volte, e sembrava prudente. Ora il punto di misura si cerca partendo dalle
   plafoniere — stanno al centro dei locali per costruzione — e si pretende un metro e
   mezzo di campo libero per parte, altrimenti si sta misurando un angolo. Il primo
   bersaglio accettato aveva uno stipite a venti centimetri, e quel pezzo di muro si
   prendeva da solo tutta la luce.

3. **Diceva che la luce non passava i muri, e la sua spia guardava il retro della
   parete.** Quella faccia dà le spalle alla lampada: resta nera che la luce le arrivi
   o no. Con la lampada a quaranta di energia il banco riportava fuga zero. Si misura
   il **pavimento** della stanza accanto — sempre a un metro e mezzo dalla lampada,
   sempre rivolto verso di lei, in qualunque stanza — e lì la fuga è saltata fuori:
   +173 livelli.

**Il controllo che ha retto tutto** è il quarto: non il valore al centro
dell'inquadratura ma il **98º percentile** dell'immagine, cioè la superficie più
chiara che la lampada illumina. È quello che ha smascherato il bersaglio di noce —
il centro leggeva 37, e nella stessa foto l'intonaco lì accanto era a 239.

Tutti e quattro validati per iniezione: energia 0,02 fa fallire «da vicino non si
vede niente», 2,0 fa fallire «è una stanza illuminata», portata 12 m fa fallire «sta
schiarendo il fondo», e la fuga risponde all'energia in modo monotòno (+0,0 / +0,2 /
+4,3 a 0,3 / 1 / 3,5).

**Limite dichiarato.** La fuga si misura dietro *una* parete. Nel punto che il banco
sceglie oggi la stanza accanto è profonda abbastanza che, all'energia scelta, la fuga
non sia misurabile nemmeno a ombre spente: le ombre restano accese per la resa e
perché in una stanza più stretta quel margine non c'è.

## D-107 — La lampada di prossimità esiste solo dove è buio

**Difetto visto giocando.** «Anche quando la luce c'è io emetto luce.» Avvicinandosi
a una parete illuminata compariva un alone che segue la testa: il modo più rapido di
ricordare a chi gioca che sta guardando un motore grafico. In una stanza accesa si
deve vedere la stanza, non la propria luce riflessa addosso alle cose.

**Come si decide se è buio.** Non leggendo lo schermo: la luminosità
dell'inquadratura dipende da dove guardi, e girando la testa la lampada si
accenderebbe e spegnerebbe da sola. Si chiede alle lampade — per ognuna, energia per
la sua curva di caduta alla distanza del giocatore. È un conto esatto e costa dieci
raggi ogni decimo di secondo.

**Il raggio è metà del lavoro.** Una plafoniera accesa nella stanza accanto non
illumina questa: senza quel controllo, il corridoio acceso lascerebbe al buio pesto
chi è chiuso nel magazzino, cioè il difetto opposto e peggiore. La luna, che è una
direzionale e illumina ovunque, si tratta allo stesso modo al contrario: da qui si
vede il cielo, o c'è il tetto?

**E scorre, non scatta.** `RIPRESA` porta l'energia al valore voluto in poco più di
un terzo di secondo — attraversare la soglia di una stanza illuminata non deve essere
un lampo.

**Numeri.** Al buio la parete a 70 cm passa da 7 a 73 su 255; con la plafoniera
accesa da 57,5 a 57,5, cioè zero. Con una plafoniera accesa **di là dal muro** torna
a +66: la lampada non si lascia spegnere da una luce che da qui non si vede.

## D-108 — Due controlli che passavano mentre il difetto c'era

Il primo è nato dal difetto stesso: con la plafoniera accesa la lampada non deve
alzare la parete di più di un livello e mezzo. Validato disattivando lo spegnimento —
accusa +47,9, che è esattamente l'alone che si vedeva.

**Il secondo è quello interessante, perché nasceva già rotto.** Il controllo
simmetrico («una luce di là dal muro non deve smorzarla») confrontava con
`ALZATA_MINIMA`. Togliendo dallo script il controllo dell'occlusione, la lampada
scendeva **a metà** — 26 livelli invece di 66 — e il banco taceva, perché 26 è
comunque sopra la soglia di «si vede qualcosa». Una stanza buia illuminata a metà
perché il corridoio di là è acceso è lo stesso difetto, solo più educato. Adesso il
confronto è con quanto quella stessa lampada alza al buio, alla stessa distanza.

Un controllo che tollera metà del difetto non è un controllo lasco: è un controllo
che verifica un'altra cosa.

**E il banco aspetta.** `ASSESTO` è passato da 8 fotogrammi a 40: l'energia adesso ci
arriva scorrendo, e a otto fotogrammi il banco fotografava a metà salita, leggendo
numeri che nel gioco non esistono.

## D-109 — La lampada sale in tre secondi e scende in un quarto

**Richiesta.** «Sarebbe bello se ci mettesse di più: dà l'idea degli occhi che si
abituano al buio.» È giusta anche fisiologicamente, e va fatta **asimmetrica**:
l'occhio si adatta al buio in minuti e all'abbagliamento in un istante.

**Decisione.** `SI_ABITUA = 0,30` (poco più di tre secondi per accendersi del tutto),
`ABBAGLIA = 4,0` (un quarto di secondo per spegnersi). Entrando in una stanza spenta
non si vede subito quel che si ha accanto: lo si vede emergere.

**La discesa rapida non è solo fisiologia, è necessità.** Una lampada che ci mettesse
tre secondi a spegnersi lascerebbe vedere il proprio alone entrando in una stanza
accesa — cioè il difetto di D-107, ripreso dalla porta di servizio.

## D-110 — L'attesa del banco non è più un numero scritto a mano

`ASSESTO` valeva 8 quando la lampada saliva in un terzo di secondo; è diventato 40; e
alla prima salita da tre secondi il banco ha **accusato un guasto che non c'era** —
«una lampada di là dal muro la smorza» — mentre la lampada stava soltanto ancora
salendo. Un errore nella direzione giusta, per una volta, ma solo per fortuna: un
banco che fotografa a metà transitorio può altrettanto facilmente dare per buono un
difetto.

Adesso l'attesa si calcola da `SI_ABITUA`, letta dallo script della lampada. Chi la
rallenta non deve venire a ricordarsi del banco. La costante si legge dal `GDScript`
caricato e non dal `class_name`: quel nome vive nella cache che scrive l'editor, e un
banco lanciato con `--script` su un progetto appena clonato quella cache non ce l'ha.

## D-111 — Il bagno: quello che lo data non sono i sanitari

**Richiesta.** Un bagno come quello della foto — italiano, anni Novanta, non moderno
— ma **senza vasca**.

**La cosa da capire prima di modellare.** Un water è un water in ogni paese e in ogni
decennio: i sanitari non datano niente. Quello che sposta la stanza di trent'anni
sono tre cose, e sono geometria e materiale:

1. **Il rivestimento si ferma a 1,60** e sopra c'è intonaco. Piastrellare fino al
   soffitto è un gesto di oggi.
2. **Il listello.** La fascia di losanghe azzurrine che chiude il rivestimento è il
   pezzo che data il bagno più di tutto il resto messo insieme.
3. **Il bidet.** Un bagno senza bidet non è italiano. Interasse dal water 75 cm:
   sotto i 55 non ci si siede, sopra gli 80 la parete sembra vuota in mezzo.

**Il listello non si scarica: lo si disegna.** Le librerie CC0 sono piene di
piastrelle e non hanno un listello, perché un listello è un pezzo di gusto e il gusto
non si fotografa in una libreria di materiali generici. `tools/fai_listello.py` lo
genera: fondo crema, due filetti, una losanga col cuore caldo. Ed è **una tessera
quadrata con un motivo solo**, non una 4:1 con quattro — le UV di questo progetto si
cuociono con una scala sola per le due direzioni, e una tessera larga quattro volte
l'altezza si sarebbe schiacciata sulla fascia mostrandone un quarto.

**Sporge di dieci millimetri**, come le nervature della porta del magazzino: a filo
sarebbe un disegno stampato sul muro.

**Senza vasca**: doccia 90×90 nell'angolo sud-est, piatto alto 12 cm col bordo — i
piatti a filo pavimento sono di adesso. In un osservatorio è anche più credibile
della vasca: ci si sciacqua dopo una notte in cupola.

## D-112 — Un modellatore che non si rifiuta di girare

I tre sanitari sono superfici curve continue: fatti con le scatole vengono mobili,
non ceramiche, e vanno presi da fuori (CC-BY, vedi `CREDITI.md`). Ma Sketchfab
consegna solo a un account autenticato, quindi passano per il registro `A_MANO`.

**Se i modelli non ci sono, `bagno_blender.py` NON fallisce**: mette i suoi
segnaposto, li dichiara a schermo, e produce comunque il `.glb`. È una scelta, non
una scorciatoia — un bagno con tre segnaposto è comunque una stanza da guardare e da
attraversare, mentre un modellatore che si rifiuta di girare blocca anche tutto il
lavoro che con quei modelli non c'entra: il rivestimento, il listello, la doccia, il
mobiletto. Quando i file arrivano, la stessa riga li monta al posto dei segnaposto.

**Due materiali sbagliati, visti solo nel render.** Applique e termosifone erano di
`Lamiera`, che in questo progetto è la lamiera segnata delle plafoniere industriali:
sopra uno specchio da bagno e sotto una finestra leggevano come pezzi arrugginiti.
Sono metallo smaltato bianco, cioè `Ceramica`.

## D-113 — Trenta secondi, e un banco che li cronometra

**Richiesta.** La lampada del giocatore deve metterci trenta secondi ad accendersi al
buio. È lentissimo ed è anzi **più veloce del vero**: un occhio umano ci mette dai
venti ai trenta minuti ad adattarsi davvero.

**Conseguenza da sapere, perché non è un difetto ma lo sembra.** Passando accanto a
una lampada accesa la luce si spegne in un quarto di secondo e poi ci rimette trenta a
tornare. Camminando per un osservatorio mezzo illuminato la si vedrà quasi sempre a
metà strada, e piena solo restando fermi al buio.

**Il banco non aspetta trenta secondi per presa**: gira con `Engine.time_scale = 25`,
quindi il `delta` che arriva alla lampada è quello di trenta secondi mentre ne passa
poco più di uno. Si misura la stessa curva, srotolata in fretta. Accorciare l'attesa
invece avrebbe misurato una lampada a metà salita chiamandola a regime — l'errore già
fatto due volte qui.

**E adesso qualcuno cronometra la salita.** Nessuno dei controlli fotografici misura
*quanto* ci mette: aspettano il regime e guardano quello. Rimettendo 0,30 al posto di
1/30 tutte le foto resterebbero identiche e il banco tacerebbe.

## D-114 — Il cronometro ha accusato la lampada, e sbagliava lui

Alla prima misura il banco ha riportato **2,9 secondi su 30 dichiarati**, che sembrava
la prova che la costante non avesse effetto. Non era così: il criterio di arrivo era
«smette di crescere», e basta un fotogramma in cui l'energia non cambia. Ce n'è più
d'uno, perché il bersaglio si ricalcola dieci volte al secondo e non a ogni
fotogramma: il cronometro dichiarava arrivata una lampada ferma al dieci per cento.

Adesso aspetta che raggiunga il 99% del suo massimo. Misura 30,0 s.

**Vale come voce a sé** perché è il rovescio dei difetti raccolti finora: qui un
controllo ha accusato del codice sano. Un banco che sbaglia in questa direzione è meno
pericoloso di uno che tace, ma costa lo stesso — e per un momento ho creduto che la
lampada fosse rotta.

## D-115 — In un osservatorio il bagno non ha la doccia

**Correzione.** La doccia era il primo rimpiazzo della vasca e non reggeva: «è un
osservatorio, non una camera d'albergo». Ha ragione — lì non ci si lava, ci si lavora.
L'angolo sud-est lo prende un **armadio di lamiera da locale tecnico**: detersivi,
ricambi, il camice.

**Tre dettagli che sono geometria, non arredamento.** Le feritoie di aerazione in alto
(un armadio chiuso senza sfiato ammuffisce, e chi li fabbrica lo sa), le maniglie
verticali a bastone, lo zoccolo rientrato che lo stacca dal pavimento bagnato. Senza
quei tre, una scatola grigia resta una scatola grigia.

**Due errori, entrambi visti solo nel render.** La cassa aveva fianchi e fronte
scambiati di asse — ne usciva un armadio aperto di lato, con le ante appiccicate sopra
il pannello che avrebbero dovuto essere. E portava il materiale `Lamiera`, che in
questo progetto è quella scrostata delle plafoniere industriali: sembrava un rudere.
Un armadio di servizio di un osservatorio in funzione è vecchio, non abbandonato.

## D-116 — I sanitari devono essere vecchi, e il bidet non esiste vecchio

**Correzione.** La forma dei sanitari andava bene, la ceramica no: bianca di
fabbrica. Un sanitario nuovo in un bagno del 1999 legge come un rendering di
catalogo. Sostituiti lavabo e water con due modelli **già ingialliti e segnati**
(vedi `CREDITI.md`) — meglio lo sporco vero di chi li ha fatti che una tinta
uniforme passata sopra.

**Il bidet no.** Di bidet vecchi non esiste **nemmeno uno** con licenza libera, e non
è un caso: il bidet è un oggetto italiano e francese, e le librerie 3D sono
anglosassoni. Quindi si prende quello pulito e lo si invecchia in casa —
moltiplicando la sua mappa colore per una tinta calda, non sostituendola: quella mappa
porta le ombre e i dettagli del modello, e buttarla via per un colore piatto sarebbe
un peggioramento travestito da invecchiamento.

**E la ceramica vecchia perde il lucido**, non solo il bianco: `CeramicaVecchia` sta
a 0,38 di rugosità contro i 0,25 della nuova. È metà di quello che la fa leggere
vecchia — uno smalto di vent'anni non specchia più.

## D-117 — Provare oggi il codice che scatterà fra giorni

`ingiallisci()` gira solo quando il bidet sarà stato scaricato, cioè fra giorni. Un
pezzo di codice che nessuno esegue è un pezzo di codice che non funziona, e nessuno lo
eseguirebbe fino al giorno in cui serve — che è il giorno peggiore per scoprire che
sbaglia il nome di un socket.

Quindi il modellatore lo prova **a ogni build**, su un cubo di prova: costruisce un
materiale con texture, lo invecchia, e controlla che il Base Color sia passato per un
nodo Mix in MULTIPLY con la tinta nel socket giusto. Validato per iniezione:
scambiando i due socket il controllo accusa.

## D-118 — L'orientamento di un modello preso da fuori si misura

Un modello scaricato non conosce il nostro nord. L'angolo si trova per tentativi
guardando un render alla volta — tre modelli per quattro angoli fa dodici render, e
il rischio di fermarsi al primo che *sembra* giusto.

`tools/verso_sanitari.py` lo misura: posa ogni modello alle quattro rotazioni e conta
quanti vertici finiscono a filo di ciascun lato dell'impronta. Il lato che ne
raccoglie di più è il retro, e il retro va contro il muro. Lavabo: 67% a ovest con
270°, contro il 6% dei 90° che aveva — era girato di mezzo giro.

**Per il water quel conteggio non bastava**: dava zero contro est e contro ovest a
tutte e quattro le rotazioni, e sembrava un modello senza retro. Non lo era —
`posa_modello` scala sull'altezza e poi rimpicciolisce finché l'ingombro in pianta ci
sta, quindi un pezzo orientato male viene ridotto e non arriva più a nessun muro. Il
secondo criterio è **dove pende la metà alta**: un water ha la cassetta in alto e
dietro.

**E l'altezza di posa non è quella dell'impronta.** L'impronta del lavabo è alta 1,90
perché comprende specchio, mensola e applique; il lavabo è alto 86 cm. Passando 1,90
il lavabo veniva scalato a quasi un metro.

## D-119 — Il bagno pesava 33 MB, più dell'intero edificio

`prendi_modello.riduci()` porta le mappe scaricate a 1024 e le rinomina. **Nessuno le
usava.** `_collega_texture_vicine` tocca solo i modelli che arrivano *senza* texture,
e un glTF le sue ce le ha: i file ridotti stavano nella cartella accanto mentre i
sanitari restavano attaccati agli originali a 4096.

Niente lo segnalava. Il modello era giusto, tutti i controlli passavano, e il numero
si vede solo guardando la cartella.

**Due difetti sotto, non uno.** `riduci()` riconosceva solo i `.png`: il baseColor del
water è `M_Toilet_baseColor.jpeg` e non veniva nemmeno ridotto. Adesso si guarda il
*nome* della mappa e si accetta qualunque formato.

**La cura sta in `modellare.usa_le_ridotte()`, ed è la terza volta che serve** — le
prime due erano rattoppi dentro un singolo modellatore. Sostituisce il **datablock**
dell'immagine, non il `filepath`: l'importatore glTF imballa le immagini nel .blend, e
cambiare percorso più `reload()` ricarica i dati imballati ignorando il file nuovo, in
silenzio. Da 33,3 a 15,5 MB.

**E forza la metallicità a zero.** Una mappa metallicRoughness su una ceramica la fa
specchiare, e uno specchio in una stanza chiusa senza niente da riflettere è nero. È
il difetto ricorrente di questo progetto: quarta volta.

**Adesso il modellatore rilegge il file scritto e ne guarda il peso**: sopra i 20 MB
fallisce, dicendo dove guardare. Validato per iniezione — togliendo la riduzione
riporta 33,3 MB e si ferma.

## D-120 — «Vecchio» non vuol dire «sporco», ed è stato l'errore

**Correzione.** Il lavabo era «una vergogna schifosa», il bidet nero, e le piastrelle
pulite stonavano con tutto. La causa è una sola, ed è a monte: chiesto un bagno
d'epoca, ho cercato modelli *degradati*. Ma un osservatorio in funzione nel 1999 ha
sanitari **puliti di forma datata**, non da rudere.

**La direzione della cura conta.** Si poteva sporcare le piastrelle o pulire i
sanitari, e non è simmetrico: sporcare tutto avrebbe trasformato un posto di lavoro in
un edificio abbandonato, che è un altro gioco. Le piastrelle restano pulite e sono i
sanitari ad allinearsi a loro. Il pavimento resta lievemente segnato: un pavimento si
consuma più di un muro, e quella è la gerarchia naturale dell'usura, non un'incoerenza.

**Il bidet nero era colpa mia.** Arrivava a 227 su 255 — l'unico dei tre già bianco —
e D-116 lo invecchiava moltiplicandolo per una tinta calda: 186 con una dominante,
cioè il più scuro dei tre. L'invecchiamento in casa è stato tolto.

## D-121 — Tre ceramiche in una stanza devono essere lo stesso bianco

**Il problema non era che uno fosse brutto: è che erano tre.** Misurati: bidet 227,
water 174 con una dominante calda, lavabo 130. Nessuno sbagliato da solo; in una
stanza sola la differenza non legge come «ceramiche di età diverse» ma come un errore.

**E non si può schiarire nel materiale.** Il colore di base di un glTF è un *fattore*
che moltiplica la mappa, e un fattore sta fra zero e uno: si scurisce, non si
schiarisce. L'unico posto dove si schiarisce è la mappa, quindi
`tools/pareggia_ceramica.py` riscrive quella — ripartendo sempre dall'originale
scaricato, perché applicare due volte la correzione porterebbe al bianco assoluto e la
seconda volta il numero misurato sarebbe già giusto.

**La dominante si toglie per canale**, non con un fattore solo: il water arriva
180/179/164, e scalando i tre canali insieme il giallo resta, solo più chiaro.

**Chi sfora va sostituito, non corretto.** Il lavabo avrebbe richiesto 1,73× di
schiarimento contro l'1,45 ammesso: oltre quella soglia le ombre dipinte dentro la
texture diventano grigio uniforme e l'oggetto perde il volume. Lo strumento lo dice
**e lo scrive su disco** — `DA_SOSTITUIRE.txt` — e il modellatore torna al segnaposto
finché non arriva il buono. Un modello sbagliato che resta montato è peggio di un
segnaposto: il segnaposto si vede che è provvisorio, il modello sbagliato sembra una
scelta.

## D-122 — La stessa immagine, misurata due volte, dava due numeri

Il controllo che verifica il pareggio gira dentro Blender, dove PIL non c'è, e
misurava **234** dove `pareggia_ceramica.py` misura **212** sulla stessa mappa:
accusava due ceramiche perfettamente pareggiate.

Due cause, cercate nell'ordine sbagliato. La prima ipotesi era il ridimensionamento a
64×64 — `img.scale()` media in spazio lineare, e la media lineare riportata in sRGB
viene più chiara — ma toglierlo non ha cambiato il numero. La vera causa era **una
conversione applicata due volte**: i pixel arrivavano già nei valori del file e io li
riconvertivo in sRGB. Forzando `Non-Color` e leggendoli così come sono, le due misure
combaciano.

Vale come voce perché è il difetto di misura più insidioso di questa sessione: non
un controllo che tace, ma un controllo che **grida su codice sano**. Costa la stessa
fiducia.

## D-123 — Il colore non sta sempre in una mappa

Il lavabo di ricambio arriva **senza texture**: tre materiali a tinta piatta e
nessuna immagine. `pareggia_ceramica.py`, che lavora sui file delle mappe, non aveva
niente da correggere — e il pareggio sarebbe semplicemente non avvenuto, in silenzio.

Il caso senza mappa è però anche il più facile: il colore di base non è un fattore che
moltiplica qualcosa, è **il** colore, e glielo si scrive. Con due accortezze:

- **Qual è la ceramica fra i tre materiali**: quello con più facce. Il corpo di un
  lavabo ha dieci volte i triangoli del suo rubinetto.
- **Il bianco va convertito in lineare.** I 212 sono in sRGB, Blender lavora in
  lineare: scritti tali e quali darebbero una ceramica molto più chiara. È lo stesso
  scarto di fattore 2,4 che fece uscire l'anta del magazzino a metà della tinta del
  suo telaio.

**E metallicità a zero su tutto.** In glTF `metallicFactor` vale 1.0 se non è
dichiarato, e due dei tre materiali non lo dichiarano: sarebbero arrivati metallici
pieni e lisci come specchi, cioè neri in una stanza chiusa. **Quinta volta** che
questo progetto ci inciampa.

## D-124 — Un controllo che salta quello che non sa misurare

`ceramiche_pari()` verificava il bianco leggendo `color.jpg`, e se il file non c'era
faceva `continue`. Col lavabo nuovo — che di mappe non ne ha — controllava **due
sanitari su tre e dichiarava pari anche il terzo**.

È la forma più educata di controllo inutile: non sbaglia la misura, semplicemente non
la fa, e il verde che stampa è indistinguibile da quello di una verifica vera. Adesso
se la mappa non c'è il bianco si legge dal materiale del corpo e si riconverte in
sRGB. Validato per iniezione: pareggiando il lavabo a 150 invece che a 212, il
controllo lo accusa.

**Tre modi di sbagliare, tutti visti oggi**: un controllo che tace (D-119, il peso), un
controllo che grida su codice sano (D-122, la conversione doppia), e un controllo che
salta il caso che non sa gestire. L'ultimo è il più difficile da notare, perché
assomiglia a un successo.

## D-125 — Il radiatore è di ghisa a colonne, e non si scarica

**Correzione.** Il termosifone era fatto di lastre piatte: quello è un radiatore
d'acciaio a piastre, cioè degli anni Duemila. In un bagno del 1999 c'è la ghisa a
colonne.

**Perché modellato e non preso da fuori.** Su Sketchfab ce ne sono, e sono tutti
*arrugginiti* — la stessa trappola che è già costata due giri con i sanitari: vecchio
non vuol dire sporco. Ma soprattutto un radiatore a colonne è **geometria regolare**,
non una superficie curva continua come un lavabo: dodici elementi identici fatti di
cilindri e raccordi. È il caso in cui modellare costa meno che scaricare, e dà una
verniciatura coerente col resto della stanza invece che una ruggine da correggere.

**Tre cose lo fanno leggere come ghisa**, e sono tutte geometria: le colonne tonde due
per elemento (le piastre d'acciaio sono un muro liscio, la ghisa è una fila di tubi);
il cappello e il piede di ogni elemento, il cui profilo affiancato fa l'onda che si
riconosce da lontano; i nippli fra un elemento e l'altro, che dicono «questo si
smonta». Più valvola, detentore e sfiato: un radiatore senza rubinetti è un mobile.

**Due difetti visti solo nel render.** Gli era stata data la trama del metallo, che è
grigio azzurra: collegata al Base Color ne prende il posto — il colore serve solo dove
la mappa viene *moltiplicata* — e il radiatore usciva grigio ferro invece che bianco.
Una ghisa smaltata è liscia: la texture non ce l'ha. E non era fra i materiali
sfumati, quindi le colonne tonde uscivano sfaccettate.

**E il bianco era dalla parte sbagliata.** Scritto 0,84 usciva a 236 in sRGB, cioè
ventiquattro livelli **più chiaro** dei sanitari invece che appena più scuro: quei
numeri finiscono nel Base Color di Blender, che è lineare, mentre i 212 dei sanitari
sono in sRGB. 0,62 lineare fa 202. Stesso fattore 2,4 dell'anta del magazzino — e
nessuno se ne accorge finché non li si mette accanto.
