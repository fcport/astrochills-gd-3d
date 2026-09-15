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

## D-126 — Sopra il lavabo non c'è più niente

Specchio, mensola di cristallo, i suoi due reggi-mensola e l'applique: tolti tutti e
quattro su richiesta. I reggi-mensola erano il sintomo — «due cosi grigi che non si
capisce cosa siano» — e un oggetto che da un metro e mezzo non si riconosce è un
oggetto che non serve. È il bagno di servizio di un osservatorio, non una stanza da
bagno di casa; lo specchio in stanza resta comunque, sull'anta del pensile.

**E il pensile partiva dentro le piastrelle.** Il rivestimento è spesso poco più di un
centimetro e il mobile era attaccato al filo del muro: in gioco si vedeva la fuga
passare attraverso il suo fianco. Un pensile si appende *sopra* il rivestimento. Stessa
correzione sulla schiena dell'armadio.

## D-127 — L'asciugamano non è una lastra

Era una scatola: quattro centimetri di spessore e spigoli vivi. Un telo appeso ha tre
cose che una scatola non ha, e sono tutte geometria: **la piega** sopra la barra, che è
un mezzo tubo e non uno spigolo; **due falde di lunghezza diversa**, perché chi lo
appende non le pareggia mai; e **l'onda** — cinque strisce con la faccia spostata di
pochi millimetri una dall'altra. È quel poco che lo fa leggere come stoffa.

## D-128 — La striscia nera nel lavabo: tre ipotesi, e la terza era quella giusta

Dentro il catino compariva una striscia nera a spigolo vivo che sembrava un pezzo di
modello mancante. **In Blender non c'era.**

1. *Ombra dura della plafoniera.* Le ombre sono state ammorbidite — `light_size = 0.35`,
   perché una plafoniera è un rettangolo di plastica largo mezzo metro e non un punto —
   e ha risolto l'acne sotto il rubinetto. La striscia è rimasta **identica**. Quello che
   non cambia quando cambi la luce non è un'ombra.
2. *Normali invertite.* Godot, col culling disattivato, disegna una faccia vista da
   dietro ma la illumina con la normale che ha: viene nera. Blender invece la gira lui
   prima di illuminarla, ed è per questo che lì non si vedeva niente. Il lavabo ne
   aveva **5620** e il water 456: raddrizzate. La striscia è rimasta.
3. *È un'ombra, ma di una superficie girata via dalla luce.* Il test decisivo è stato
   illuminarla con una lampada in mano: sparisce. Quindi geometria sana, ombra vera.

**Cosa si è fatto e cosa no.** Ogni plafoniera ha adesso una **lampada di rimbalzo** —
una seconda luce nello stesso punto, debole e senza ombre, portata corta perché senza
ombre attraversa i muri — che simula la luce riflessa dalle pareti. Il contrasto passa
da 1:4,5 a 1:4,0. **Non basta**: alzando l'ambiente notturno di sei volte arriva solo a
1:3,2, e quello sarebbe un prezzo troppo alto per il buio. Quella superficie è girata
via da *tutte* le sorgenti, e l'unica cura piena è luce indiretta vera. Resta aperta.

## D-129 — Sesta volta: il metallo che riflette il nero

La barra dell'asciugamano usciva marrone scuro. `Inox` sta fra i materiali metallici,
con metallicità 0,85: in una sala grande, con qualcosa da riflettere, funziona; in un
bagno chiuso non c'è niente da riflettere e un metallo liscio riflette il nero.

Il bagno usa adesso `Cromo`: metallicità zero, rugosità 0,14, il mestiere lo fa lo
speculare. Legge come cromo lucido senza dipendere dall'ambiente.

## D-130 — Il termosifone si scarica, non si modella

Il radiatore fatto a mano aveva la forma giusta — ghisa a colonne, cappelli, nippli,
valvola e detentore, centoventi cilindri in tutto — ed è stato sostituito lo stesso da
*Old Radiator* di thethieme (CC-BY, Sketchfab). **La forma si fa a mano, i sessant'anni
no.** La ruggine attorno alla valvola e lo smalto scrostato sono texture, e una texture
di quel tipo non la si disegna: la si fotografa. Il segnaposto resta in
`termosifone_segnaposto()` e regge se il modello non c'è.

**Il verso non l'ha deciso `verso_sanitari.py`.** Quel banco sceglie l'angolo che appoggia
più vertici al muro, e sul radiatore vinceva 90° con il 51% — solo che a 90° il modello
veniva schiacciato a **2 cm** di larghezza per stare nei 20 di fondo dell'impronta. È la
stessa trappola del water: `posa_modello` rimpicciolisce finché il pezzo ci sta, e da
rimpicciolito tocca il muro dappertutto. Il numero che smaschera il caso è l'ingombro
(*largo 0,02, alto 0,13*), non la percentuale. Restavano 0 e 180, che per un radiatore
sono lo stesso pezzo specchiato, e lì ha deciso il render.

`metallicFactor` non è dichiarato nel suo glTF: il valore predefinito è **1,0**, cioè
metallo pieno. Settima volta in questo progetto. Azzerato.

## D-131 — Le ante dei mobili sono `Door`, non un tipo nuovo

Pensile e armadio del bagno si aprono. Il meccanismo **non è nuovo**: sono nodi `Door`,
gli stessi delle sette porte dell'edificio.

Un'anta di armadietto ha esattamente i bisogni di un'anta di porta — gira su un cardine,
si guarda e si preme `E`, non deve passare dentro chi l'ha aperta — e `door.gd` li
risolve già tutti, compreso il pezzo difficile: scostare chi ha davanti *un po' per
fotogramma* invece di sparargli mezzo metro in uno. Un `CabinetDoor` scritto a parte
avrebbe rifatto quel pezzo peggio, e — cosa che conta di più — **il banco delle porte non
lo avrebbe nemmeno visto**. Così invece `prova_porte.gd` misura dieci ante senza sapere
che tre sono mobili.

L'unica differenza vera è la **quota**: una porta parte dal pavimento, un pensile appeso a
1,45. Sta nell'origine del nodo, non nelle mesh.

**Conseguenze sul modello.** Un pezzo che ruota non può stare dentro il `.glb`, che è una
mesh sola: le ante escono dal modellatore ed entrano in `ANTE_MOBILI` di `geometria.py`,
di fianco ai dati delle porte. E tolta l'anta, **il mobile va svuotato** — finché l'anta
era incollata davanti il pensile poteva essere un blocco pieno e non se ne accorgeva
nessuno; aprendolo si vedrebbe il pieno. Adesso ha fianchi, schiena, cielo, fondo e un
ripiano; l'armadio è passato da uno a tre ripiani.

Il piano su cui batte l'anta lo legge `filo_anta()` dalla stessa tabella che genera il
nodo in gioco, invece di riscriverlo: cassa e anta le disegnano due programmi diversi, e
un numero scritto due volte prima o poi diventa due numeri.

**E l'armadio resta fatto in casa.** Erano stati cercati due candidati su Sketchfab — un
*Old Locker* di lamiera con specchio sull'anta, e un *Medical Cabinet* da laboratorio con
ante a vetro — e la scelta è stata tenere quello che c'è. Le ragioni reggono anche a
freddo: il primo è arrugginito e ha lo specchio crepato, cioè ricadrebbe nell'errore già
fatto una volta (*vecchio non vuol dire sporco*); il secondo è un mobile diverso, e
ante a vetro in una stanza al buio sono un problema noto. In più un modello scaricato è
comunque una mesh sola: le sue ante andrebbero **tolte** e rifatte qui, quindi il
download avrebbe portato solo la texture, non il meccanismo.

**E il fianco del pensile era ancora dentro le piastrelle.** Il difetto era stato
corretto solo sulla schiena; sul muro ovest il mobile partiva da 5,00 mentre il
rivestimento arriva a 5,012. La metà corretta nascondeva la metà rotta — la quarta volta
in questo progetto.

## D-132 — Il banco che accusava le ante del proprio errore

Aggiunte le tre ante, `prova_porte.gd` ha dichiarato due guasti: *«scosta a 3,5 m/s, che
non è un passo indietro»*. **Non era vero, ed è il tipo di bugia peggiore** — manda a
cercare un difetto dove non c'è.

Due errori distinti, tutti e due del banco:

1. **Ostacolo che non è un ostacolo.** `_quanto_girano()` provava la sagoma dell'anta
   grado per grado e la trovava già in compenetrazione a zero gradi, dichiarando tutte e
   tre le ante bloccate in partenza. Ovvio a dirlo: un'anta di armadietto **sta dentro
   l'impronta del suo armadio**, da chiusa è il fronte del mobile. Adesso quello che
   l'anta tocca da chiusa viene escluso dal giro. Che la correzione sia giusta lo dice il
   fatto che i numeri delle sette porte **non sono cambiati di un grado**: nessuna tocca
   il proprio telaio.
2. **La persona nasceva dentro il termosifone.** Il corpo di prova veniva posato a 45 cm
   dal cardine e 42 dal battente — misure buone per una porta larga 90 in un vano libero,
   sbagliate per un'anta larga 43 in un angolo. Al primo `move_and_collide` la fisica lo
   espelle, e l'espulsione è istantanea per definizione: il banco misurava la spinta del
   *motore* e la scriveva a carico della porta. Adesso prova più punti dentro il settore
   e tiene il primo **vuoto**; se non ne trova nessuno lo dice e salta la prova, invece di
   inventare un guasto.

**Validato iniettando il difetto**, e il primo tentativo di iniezione è servito a
capire qualcosa. Togliendo il tetto sulla spinta (`SPINTA_MASSIMA`) il banco continuava a
passare: perché il freno che conta davvero è l'altro, quello che **rallenta l'anta**
quando sta scostando qualcuno. Tolto quello, 176 guasti, le nuove ante comprese
(*«Anta_pensile_bagno: scosta a 2,0 m/s»*). Rimesso, zero.

## D-133 — L'arretramento dalle piastrelle diventa una regola

Il fianco sud dell'armadio era **dentro le piastrelle**, come lo erano stati la schiena
del pensile e poi il suo fianco ovest. Tre volte lo stesso difetto, corretto tre volte
una faccia alla volta, e ogni volta la metà giusta nascondeva la metà rotta.

Adesso lo fa `geometria.impronta_utile()`: **ogni** lato di un'impronta che coincide con
un muro della stanza si arretra dello spessore della piastrella. Un lato che *non* tocca
il muro non si arretra — se l'impronta dichiara un mobile staccato, quello stacco è
voluto. Non resta una faccia da dimenticare.

Nello stesso giro **i cardini delle ante hanno smesso di essere scritti a mano**. Erano
numeri uguali in due posti — la tabella delle ante e il modellatore della cassa — e
bastava spostare l'armadio di quattro centimetri per staccargli l'anta, il giorno in cui
nessuno guarda quella tabella. Adesso `ante_mobili()` li calcola dall'impronta: si
dichiara solo quello che dall'impronta non si ricava (da che parte guarda il fronte,
quante ante, di che tipo, fra che quote).

## D-134 — Il termosifone non può crescere, e i due limiti sono misurati

Richiesto più grande. Può crescere del 6% e non di più, e **i due muri contro cui va a
sbattere sono stati misurati, non temuti**:

- **verso est** c'è l'anta dell'armadio, che aperta arriva a *x = 7,226*: oltre 7,20 il
  radiatore glielo mette davanti;
- **verso ovest** c'è il passaggio fra il lavabo e il radiatore. A `x0 = 6,08` il
  controllo delle sacche dice *«0,01 m² non raggiungibili a piedi»*; a **6,14** tace. Fra
  i due c'è il mezzo centimetro che separa una stanza percorribile da un angolo murato.

E siccome `posa_modello` scala tutto insieme, senza larghezza non c'è altezza. Quello che
restava era **alzarlo**: un ghisa a colonne sta su mensole, non per terra. Dieci
centimetri di stacco portano la sua cima da 0,67 a **0,81** — che da un metro si vede
molto più di sei centimetri di larghezza, ed è anche giusto.

**Il controllo delle sacche adesso dice anche DOVE.** *«0,01 m² non raggiungibili»* è un
numero che non si può andare a guardare: costringe a rifare a mano il conto della griglia
per sapere in che angolo cercare. Con le coordinate ci si va, e in questo caso è servito
a capire in tre tentativi qual era il limite invece di indovinarlo.

## D-135 — Le porte interne sono tutte da 90, e il perché non era generosità

Erano fra **1,30 e 1,40 di vano** — da 1,14 a 1,24 di luce netta — e in gioco leggevano
come vani da capannone. Adesso sono tutte **1,06 di vano, 0,90 di luce**: la *porta 90*,
misura di serie di un edificio pubblico italiano.

La causa non era una scelta sbagliata in pianta: **la pianta di questo edificio è
dimezzata (D-028) mentre le altezze sono vere.** Le stanze si sono ristrette, le porte
no. 2,10 di altezza per 1,24 di luce fa un rapporto di 1,7; una porta vera sta sopra il
2,3. In pianta 1,30 è un numero ragionevole, ed è per questo che il difetto si vede solo
camminandoci dentro.

Restano fuori le due che una misura ce l'hanno per un motivo: l'**ingresso** (via di fuga
col maniglione) e il **magazzino** (porta di servizio da 90 di vano). I vani si sono
stretti tenendo fermo il **centro** e non il bordo: lasciando la coordinata dichiarata,
ogni porta sarebbe scivolata di dieci-quindici centimetri verso il suo montante.

Effetto collaterale misurato: tutte le porte adesso girano libere fino a **118°** invece
che fra 102 e 117.

E il vano della porta del bagno era **ricopiato a mano** dentro `bagno_blender.py`
(`PORTA = (5.80, 7.10)`), insieme a quello della finestra. Adesso li legge da
`geometria`: senza, il rivestimento sarebbe rimasto tagliato dov'era la porta prima —
una striscia di intonaco in mezzo alle piastrelle, che in un render notturno non si
distingue da un difetto della texture.

## D-136 — Lo stesso legno disegnato da due programmi dava due legni

Il pensile aperto era un buco nero con dentro un ripiano nero, e le cause erano tre,
tutte e tre reali:

1. **La mappa era la più scura del progetto.** `LegnoTeche` — noce verniciato per le
   teche — sta a **65 su 255** di media. Su una libreria in una sala illuminata funziona;
   appesa in un bagno al buio sparisce. Il pensile usa adesso `LegnoBagno`, cioè
   `legno-porte`, un legno medio che a mezza luce si legge ancora come legno.
2. **La tinta veniva moltiplicata di qua e non di là.** In Blender quel materiale non sta
   fra i `TINTI`: la mappa parla da sola. Nel `.tscn` invece `albedo_color` moltiplica
   sempre. Lo stesso legno, disegnato da due programmi con due formule diverse, dava due
   legni — e l'anta usciva più scura della cassa a cui è attaccata. **Lo stesso difetto
   c'era su tutte e sette le porte**: battente quasi nero (`0,38`) incastrato in una
   mostra color miele. Bianco pieno da tutte e due le parti.
3. **Dentro un pensile non entra luce.** Un mobile di quegli anni è impiallacciato fuori
   e melamminico bianco dentro, e quella verità è anche l'unica cosa che rende
   l'apertura leggibile.

**E un pensile vuoto è un pensile che non vale la pena aprire.** Il meccanismo può essere
perfetto — e lo è, il banco lo misura — ma se dietro l'anta non c'è niente, aprirla è una
cosa che si fa una volta. Quattro oggetti, e devono essere di quel posto: alcol, garze,
sapone, rotoli. L'alcol è **rosa**, perché per legge italiana lo è dal 1926, e quel
colore da solo dice il paese.

Erano di `Carta` e `Plastica`, che una mappa ce l'hanno: quattro oggetti da pochi
centimetri, visibili solo ad anta aperta, avevano portato il `.glb` da 13,9 a **18,5 MB**
— 3,9 MB di texture per una scatola di garze. Adesso sono tinte piatte: 14,1 MB. Su un
rotolo largo undici centimetri la mappa non si vede, si vede il colore. E la bottiglia,
che era di vetro con alpha 0,06, dentro un mobile in ombra non si vedeva affatto: **un
oggetto trasparente al buio non è un oggetto trasparente, è un oggetto assente.**

## D-137 — Il controllo di freschezza guardava il file sbagliato

Ristrette le porte, in gioco è comparsa un'anta stretta dentro un buco largo, con la
luce che passava di fianco. Il modello del guscio — `osservatorio.glb`, che contiene i
**vani nei muri** — era rimasto quello di sei ore prima, mentre le **ante** nascono nella
scena e si erano già ristrette.

`verifica_freschezza` esiste apposta per questo e **ha taciuto**, che è il modo peggiore
in cui un controllo può sbagliare. Confrontava la data del `.glb` con quella del
*modellatore*, e io non avevo toccato nessun modellatore: avevo cambiato `geometria.py`.
Ogni modellatore legge `geometria.py` e `modellare.py`, e quelle sono sorgenti dei loro
modelli quanto lo script stesso.

Adesso le guarda. **Validato iniettando il difetto**: toccando `geometria.py` il
controllo elenca tutti e otto i modelli da rifare; rimessa la data vera, tace.

È il terzo modo in cui un controllo può essere inutile, e in questo progetto li ho ormai
visti tutti e tre: **tacere** (il peso da 33 MB), **gridare su codice sano** (la doppia
conversione di colore), e **saltare il caso che non sa trattare** (le ceramiche senza
mappa). Questo era il primo.

## D-138 — I sanitari erano giusti, sbagliato era il righello

*«Sia il bidet che il cesso che il lavandino sono MICROSCOPICI.»* Misurati, non lo erano:
water **0,78** di altezza, lavabo **0,86**, bidet **0,52** — i numeri veri, al centimetro.

A mentire erano **le piastrelle del muro**. La mappa contiene dieci piastrelle per lato e
la ripetizione era a **0,75 m**: ogni piastrella veniva **7,5 cm**, cioè un mosaico. E le
piastrelle non sono un dettaglio di texture, sono **il righello della stanza**: non si
giudica a occhio quanto è grande un water, si contano le piastrelle che gli stanno
dietro. Sbagliato il righello di due volte e mezzo, sanitari di misura esatta leggono
come giocattoli.

Portate a **2,00 m di ripetizione**, cioè 20×20 — il rivestimento di un bagno italiano di
quegli anni. Il pavimento da 1,20 a 1,80: piastrelle da 30 invece che da 20.

## D-139 — Scrivere zero in un ingresso collegato non fa niente

Corretto il righello, è saltata fuori la cosa vera: **il bidet era grigio-oliva accanto a
un water bianco.** Ed era il difetto ricorrente di questo progetto, alla settima
comparsa — il metallo che in una stanza chiusa riflette il nero.

`usa_le_ridotte(..., metallico=0.0)` esiste apposta per impedirlo, e **non faceva niente**.
Scriveva `default_value = 0` sull'ingresso Metallic; ma quell'ingresso era **COLLEGATO**
al canale blu della mappa metallicRoughness, e in Blender un ingresso collegato ignora il
suo `default_value`. Nessun errore, nessun avviso: la riga che doveva togliere la
metallicità la lasciava esattamente dov'era. Adesso stacca il filo *prima* di scrivere il
valore.

**E il controllo che c'era guardava la cosa sbagliata.** `ceramiche_pari` diceva 212 su
255 per tutti e tre i sanitari — il numero giusto, misurato bene — perché misura la
**mappa colore**, mentre a scurire il bidet era il metallico. Un controllo che guarda la
cosa sbagliata è muto quanto un controllo che non c'è, e questo pezzo ha avuto per tre
sessioni due controlli e zero coperture.

`niente_metallo_addosso()` guarda adesso **il filo oltre al valore**, perché è il filo che
decide. Validato iniettando il difetto: rimessa la vecchia riga, accusa water e bidet per
nome; rimessa quella giusta, tace.

## D-140 — Il battente del magazzino è un modello, e sta in un .glb suo

*«Quello che hai messo ora è una merda.»* Era otto scatole — nervature, griglia,
portalucchetto — e i pezzi erano quelli giusti; solo che erano scatole, e da un metro
si vedeva. **Una porta di lamiera la fa la vernice, cioè la texture, non il rilievo.**

Sostituito con *Metal door* di tboiston (CC-BY, **338 facce**). Poly Haven non aveva
niente di adatto — solo portoni e serrande — quindi Sketchfab e download a mano.

**Quello che rende il modello usabile è che i pezzi sono separati**: `Main_Low`,
`Handle_Low`, `HandleBase_Low`, `Frame_Low`, `Hinges_Low`. Il telaio ce l'abbiamo già,
lo disegna `osservatorio_blender.py` dai vani, e montarne un secondo darebbe due mostre
incastrate; si tiene il solo battente. Con tutto fuso in una mesh sola non si sarebbe
potuto separare senza tagliare a mano.

**E sta in un `.glb` tutto suo** perché *ruota*: un pezzo che gira ha bisogno di un nodo
con l'origine sul cardine, e dentro `osservatorio.glb` — che è una mesh sola —
girerebbe l'edificio. Il modellatore lo posa nella stessa convenzione di
`geometria.pezzi_anta` (X dal cardine al bordo libero, Y l'altezza, Z lo spessore
centrato), così in scena si istanzia **senza trasformazione** e il nodo `Door` non sa
nemmeno che questa anta è diversa dalle altre nove. Il banco continua a misurarla:
113° liberi, si ferma a 90.

Il nome degli oggetti **non sopravvive all'import**: l'importatore glTF chiama gli
oggetti come la *mesh*, e qui tutte e cinque si chiamano `defaultMaterial`. Si
riconoscono dalla geometria — il pannello è il pezzo largo e sottile, il telaio quello
che lo contiene, i cardini una striscia sul filo — che è comunque il criterio più
solido di un nome.

**L'ordine delle operazioni è costato un giro.** Il modello ha UNA maniglia, sulla faccia
da cui l'autore l'ha fotografata; una porta vera ce l'ha su tutte e due, e senza, la
faccia verso il corridoio — quella da cui la porta si apre davvero — è una lastra liscia
e il giocatore preme `E` davanti a niente. Lo specchio era stato fatto subito dopo
l'import, **prima** della scala: la correzione uniforme delle maniglie riscrive
`o.scale` per intero e cancellava il `-1` che faceva lo specchio. Le due copie finivano
sovrapposte sulla stessa faccia. Adesso prima si cuoce la posa nella mesh, poi si
specchia una mesh ferma — e `raddrizza_normali` dopo lo specchio non è un di più:
specchiare inverte l'avvolgimento delle facce, e in Godot una faccia avvolta al
contrario si illumina con la normale sbagliata, cioè esce nera.

`metallicFactor` non dichiarato, quindi 1,0: **ottava volta**. Azzerato.

## D-141 — I sanitari sono più grandi del vero, e la colpa è dell'ottica

Seconda lamentela sulla stessa cosa: «water, bidet e lavandino sono microscopici».
La prima volta (D-138) i sanitari si erano **misurati** — 0,78, 0,52, 0,86, i numeri
veri al centimetro — e il colpevole era il rivestimento, che a 7,5 cm per piastrella
faceva da righello sbagliato. Corretto quello, sembrano piccoli lo stesso.

Rimisurati adesso, uno per uno, con `posa_modello` che li schiaccia dentro
l'impronta: altezza esatta, ingombro in pianta al millimetro di quanto dichiarato.
La stanza è 3,15 × 2,80 e il giocatore ha l'occhio a 1,65: tutto giusto. Quello che
resta è il **campo visivo**. La camera di `player.tscn` sta al valore di fabbrica, 75
gradi, che in Godot è il *verticale*: su 16:9 fanno 107 gradi in orizzontale. A
quell'apertura tutto quello che sta al centro dello schermo si allontana, e sotto tre
metri di soffitto una ceramica di misura esatta legge come una ceramica da bambole.

Si è scelto di **sbagliare la misura invece che l'impressione**: water 1,00, bidet
0,75, lavabo 1,04 — un quarto abbondante sopra il vero. Chi ci gioca non ha il metro
in mano.

Due mosse insieme, non una: `posa_modello` prende il **minore** fra la scala che
verrebbe dall'altezza e quella che verrebbe dall'ingombro in pianta, e alzare solo
l'altezza non muove niente — il water era già a 0,456 su 0,46 di impronta. Le
impronte di `ARREDI_BAGNO` sono cresciute con le altezze, e il bidet ha avuto un
secondo giro: a 0,67 restava il fratello piccolo del water, a 0,75 sono una coppia.

Il campo visivo resta com'è: cambiarlo è una decisione su tutto il gioco, non sul
bagno.

## D-142 — La colonna del lavabo erano due difetti, e uno solo era un difetto

Sotto il catino c'era un cilindro grigio e ammaccato come una lattina schiacciata, in
mezzo a una ceramica bianca. Sembrava una cosa sola. Erano due, e vanno separate
prima di curarle.

**L'ammaccatura era `raddrizza_normali`.** Un glTF non porta solo l'avvolgimento delle
facce: porta le **normali di taglio scritte dall'autore**, ed è con quelle che la
superficie si sfuma. Ribaltare l'avvolgimento lasciandole dov'erano non dà una faccia
nera — dà una faccia **a chiazze**, che è peggio del nero perché sembra una texture
sbagliata invece di un errore di geometria. Sul corpo del lavabo si giravano 5.620
facce, e la semicolonna era quasi tutta lì dentro.

Il primo rimedio è stato buttarle, quelle normali, e tornare allo sfumato calcolato: la
colonna torna liscia, ma dentro il catino compare una fila di trattini scuri dove il
modello ha facce complanari che l'autore aveva sfumato a mano. Il rimedio giusto era
l'operazione giusta e basta: **la normale di una faccia girata è la sua, cambiata di
segno**. Si legge prima, indicizzata per (faccia, vertice) — l'ordine dei *loop* dentro
una faccia girata si rovescia, quello delle facce e dei vertici no — e si riscrive dopo.
Colonna liscia, catino pulito.

**Il grigio non era un difetto del modello, e il modo di saperlo è stato accendere una
luce.** `SCATTO_FARO=30` da mezzo metro: la colonna **satura di bianco**. Materiale,
metallicità e normali sono a posto — è il catino che le fa ombra, e in questa scena non
c'è luce indiretta, quindi quello che sta in ombra scende all'ambiente e basta. In un
bagno vero quella colonna la illuminano le piastrelle bianche tutt'intorno. Resta
com'è: mettere un rimbalzo (VoxelGI, o l'ambiente alzato) è una decisione su tutta
l'atmosfera del gioco, non sul lavabo, e va presa guardando le stanze buie.

**Terzo:** la guardia in `finisci()` guardava `objects.active`, che sopravvive a chi
l'ha reso attivo. A selezione vuota restava puntato sull'ultimo sanitario importato e
`shade_smooth_by_angle` falliva col contesto sbagliato invece di essere saltato. È
bastato togliere l'ultimo oggetto cromato dal bagno per piantare il modellatore. Adesso
si conta quello che si è selezionato, che è la cosa che si voleva sapere.

## D-143 — Il distributore di carta, al posto di un asciugamano senza stoffa

L'asciugamano appeso era geometria buona: la piega sopra la barra era un mezzo tubo,
le falde erano due e di lunghezza diversa, cinque strisce sfalsate di sei millimetri
gli davano l'onda di un telo. Tutto vero e tutto invisibile, perché sopra ci stava una
**tinta piatta**: `Spugna` non compare in `TEXTURE`. Da un metro leggeva come un
cartoncino verde appeso a un filo.

È l'errore speculare a quello della porta del magazzino, dove si era fatto col rilievo
quello che andava fatto con la vernice: qui si era fatta con la piega la stoffa, che è
fatta di trama.

Cercare una texture di spugna era la via corta. Quella giusta è chiedersi cosa ci sta
**davvero** in un bagno di servizio di un osservatorio in turno di notte: non
l'asciugamano di casa, che qualcuno dovrebbe lavare, ma il distributore di carta a
muro. Che è lamiera verniciata, cioè `Armadietto`, cioè lo stesso materiale
dell'armadio a due metri — e una mappa vera ce l'ha già.

Il frontale sporge di quindici millimetri dalla cassa per la stessa ragione per cui il
listello sporge di dieci: a filo sarebbe una scatola, sporgendo prende una riga d'ombra
e diventa uno sportello.

**E sta a 1,42 e non a 1,55 perché l'ha detto il banco delle porte.** L'anta del
pensile parte da 1,45 e spazza quel tratto di muro fino a z 7,52: col distributore più
alto si fermava a 75 gradi invece di 90. È lo stesso conto che farebbe chi lo avvita
davvero, guardando l'anta del pensile aprirsi.

## D-144 — Il cardine del pensile stava dalla parte del muro

Il pensile è appoggiato all'angolo nord-ovest e l'anta era incernierata sul capo
**ovest**, cioè proprio quello contro il muro. Un'anta incernierata lì non ruota nella
stanza: ruota **dentro il piano del rivestimento**, e a novanta gradi il battente sta
nelle piastrelle. Aprendolo si vedeva il legno attraversare il listello.

**Il banco delle porte diceva 90 gradi liberi, e non stava mentendo.** Le piastrelle
del bagno sono mesh, non collisione — lo spessore che si vede di taglio non è un
corpo — e `prova_porte.gd` misura la fisica. Un battente che passa attraverso dodici
millimetri di ceramica non urta niente. È il terzo modo in cui un controllo può essere
inutile, quello che misura la cosa sbagliata, e stavolta non c'è una misura da
correggere: è un difetto che si vede solo aprendo l'anta e guardando.

Cardine dal capo **est**: l'anta gira nella stanza, dove non c'è niente. Il banco è
passato da 90 gradi liberi (col muro escluso perché "già toccato da chiusa") a 130
liberi veri.

E siccome il vincolo che teneva il distributore di carta a 1,42 era proprio quell'anta
che spazzava il muro ovest, il distributore torna alla quota che gli spetta per
ergonomia — 1,20-1,55 — invece che a quella imposta da un difetto.

## D-145 — La plafoniera del magazzino era dentro il muro, e nessuno la guardava

Alzando la testa nel magazzino, l'apparecchio a soffitto era infilato nella parete
ovest. Il conto è banale e proprio per questo è stato saltato: il magazzino ha **un
metro e trentacinque netti in X**, la plafoniera ne misura **uno e ventotto**. Anche
centrata al millimetro resterebbero tre centimetri e mezzo per parte — e centrata non
era, perché il punto luce sta a 4,00 e il centro della stanza a 4,125. Sfondava di
nove centimetri.

`GIRATE_PLAFONIERA` esisteva già proprio per questo — «le stanze profonde in Z e
strette in X: lì la plafoniera va girata di novanta gradi, o sporge dai muri» — e il
magazzino non ci era dentro. Adesso sì: la stanza è profonda tre metri in Z, girata ci
sta con quasi un metro di margine.

**Il pezzo che serviva era il controllo, non la rotazione.** A soffitto non ci si
cammina, quindi nessuna verifica di ingombro guardava lassù: l'unico modo di
accorgersene era alzare la testa in quella stanza. `verifica_plafoniere()` misura ogni
apparecchio contro le quattro facce della sua stanza e lo dice in millimetri. Provato
rimettendo il difetto — «magazzino: dentro il muro ovest di 90 mm», che è esattamente
la misura fatta a mano — e spostandone un secondo contro il muro est.

`L_PLAF, P_PLAF, H_PLAF` si spostano in `geometria.py`: chi disegna l'apparecchio e
chi controlla che ci stia devono leggere lo stesso numero, o il giorno che la
plafoniera diventa da un metro e mezzo il controllo continua a dire che va bene.

## D-146 — Il distributore era grigio perché la sua mappa è un grigio

Appena montato, il distributore di carta era un rettangolo grigio uniforme — e usava
`Armadietto`, che una texture ce l'ha. Il punto è **quale**: il set `metallo` è
Metal032, un metallo **nudo**, e la sua mappa colore è un azzurrino piatto senza un
segno. Tutto il suo carattere sta nella normale, e su un oggetto da ventisette
centimetri visto da un metro la normale non si legge. È la stessa lezione della porta
del magazzino, dalla parte opposta: lì il rilievo faceva il lavoro della vernice, qui
la vernice non c'era proprio.

Materiale suo, con la mappa `lamiera` — lamiera **verniciata e scrostata**, che di
carattere ne ha nel colore — a **0,34 metri per ripetizione** e non 0,60 come la
carpenteria: su ventisette centimetri, a 0,60 se ne vedrebbe meno di mezza
ripetizione, cioè una macchia sola, e a seconda di dove cade è tutta ruggine o tutta
vernice. A 0,34 il pezzo prende quasi tutta la mappa e legge come un oggetto piccolo e
vecchio invece che come un ritaglio.

## D-147 — Il pensile non doveva cambiare cardine, doveva uscire dall'angolo

Spostare il cardine da ovest a est (D-144) toglieva il taglio nel rivestimento e ne
faceva un altro difetto: un mobiletto che si apre al contrario di come lo aprirebbe
chiunque ci stia davanti. Le due opzioni sembravano due, e invece la domanda era
un'altra — **perché il pensile sta incastrato nell'angolo?**

Ventotto centimetri a est, e il cardine torna a ovest dove deve stare. **Ventotto e non
trenta**: il vano della porta del bagno comincia a 5,92, e a trenta il mobile andrebbe
a filo dello stipite. L'anta gira nel vuoto — il banco misura 102 gradi liberi contro
90 di apertura, e a fermarla oltre è il distributore di carta sul muro ovest, che è
esattamente il pezzo che ci si aspetta di trovare lì.

Vale la pena dirlo perché è un modo di sbagliare che si ripete: davanti a un difetto,
la prima cura è quasi sempre quella che sposta il sintomo di un posto. Il cardine era
il sintomo; la posizione era la causa.

## D-148 — Del distributore si prende la forma, non la pelle

Il segnaposto a scatole aveva la vernice giusta (D-146) e la silhouette sbagliata: un
distributore vero ha la **calotta arrotondata**, il **labbro** sotto da cui esce il
foglio e il **fondo rastremato**, e sono tre curve — cioè proprio la cosa che con le
scatole non si fa. Stessa lezione della porta del magazzino, e stessa forma di rimedio:
il pezzo viene da fuori.

Ma qui la divisione del lavoro è **opposta a quella del radiatore**. Del radiatore si è
preso proprio lo sporco: la ruggine attorno alla valvola e lo smalto scrostato sono
texture, e a mano non si fanno i sessant'anni. Questo modello arriva **bianco di
fabbrica e senza mappe**, e in un bagno del 1999 sarebbe l'unica cosa nuova della
stanza: lui dà la forma, la lamiera verniciata e scrostata gliela diamo noi.

**Le UV si rifanno, e non è un dettaglio.** Quelle del modello sono impacchettate per
la sua texture: una mappa ripetitiva ci finisce sopra a una scala che non ha scelto
nessuno, e la stessa vernice viene a grana grossa su un pezzo e fine su quello accanto.
`vernicia()` le riproietta a scatola come tutto il resto del progetto, alla scala che
il materiale dichiara — e **cuoce la posa nella mesh prima di proiettare**, perché
`posa_modello` scala l'oggetto padre e proiettare sulle coordinate locali darebbe una
grana che dipende da quanto il modello è stato rimpicciolito per stare nell'impronta.

`vernicia()` girerà solo il giorno in cui il modello sarà scaricato, quindi si prova
oggi su un cubo scalato — stesso patto di `prova_ingiallisci`. **E la prova, alla prima
stesura, misurava la cosa sbagliata:** presa su tutto l'oggetto, l'escursione delle U
mette insieme facce proiettate su piani diversi — una legge la y del mondo, quella
accanto la x — e veniva 44 invece di 2,94. Accusava `vernicia` di un difetto suo.
Corretta a misurare una faccia alla volta, e validata togliendo la cottura della posa:
dice 1,47 invece di 2,94, cioè esattamente il fattore di scala mancante.

Il modello sta su Sketchfab, che vuole il login: come il radiatore e la porta del
magazzino, la voce è in `A_MANO` e lo zip va messo a mano in
`assets/models/_da_scaricare/`. Finché non c'è, il segnaposto resta e il modellatore lo
dice invece di fallire.

## D-149 — Il righello ce l'avevamo scritto sopra, e nessuno lo leggeva

«Qui è tutto sbarellato», davanti alla consolle della sala di controllo. Ed era vero,
ma non per il motivo che sembrava: nessun oggetto era della misura sbagliata. Era la
**venatura del legno** a essere grande un terzo di troppo, ed è la terza volta in
questo progetto che il difetto è il righello e non la cosa misurata.

**ambientCG la misura la pubblica.** Wood048 — il rovere della consolle — copre 80×80
cm; noi lo ripetevamo ogni 1,10, cioè il 38% più grande del vero. Wood066, il legno
della cucina, copre 40 cm e lo ripetevamo ogni 80: il **doppio**. Wood049 delle porte,
80 cm, ripetuto a 1,00 sulle ante e a 0,55 nel bagno — sbagliato nei due versi opposti
nello stesso edificio. Nessuno di questi numeri era stato *scelto*: erano stati
indovinati a occhio, uno alla volta, guardando un render.

Adesso `prendi_texture.py` scrive la misura dichiarata dentro il `FONTE.txt` accanto
a ogni cartella, e `verifica_ripetizioni()` confronta ogni voce di `TEXTURE` con
quella. Chi vuole discostarsene lo può fare, ma lo scrive in `RIGHELLO_A_PARTE` col
motivo — i dorsi dei libri usano una tela da 40 cm a 6, perché un dorso è largo cinque
centimetri e alla misura vera non ci starebbe dentro un filo di trama. Provato
rimettendo l'1,10: «LegnoUfficio si ripete ogni 1.10 m ma legno-ufficio copre 0.80 m
(x1.38)».

Dove la fonte la misura non la dichiara — l'intonaco, il terrazzo, la lamiera — non c'è
niente da controllare, e allora si sceglie guardando il disegno. **La graniglia passa
da 0,90 a 0,55**: a 0,90 la scaglia più grossa veniva otto centimetri, cioè una
palladiana da atrio di banca. Il seminato di un edificio pubblico italiano di
quegli anni ha scaglie da mezzo a due centimetri e mezzo, con qualche pezzo fino a
quattro — a 0,55 la tipica viene 1,3 cm e la più grossa 4,8.

**E il monitor scendeva a 0,75 di emissione.** A 1,6 il canale verde usciva a 1,15,
cioè oltre il bianco, e dopo il tonemapping lo schermo non era più un fosforo: era un
rettangolo bianco-azzurro, una scatola luminosa appoggiata sul piano, che sbiancava
anche il legno attorno. Un colore che satura smette di essere un colore.

## D-150 — Il distributore è a rotolo, e il portarotolo esisteva già

Arrivato il modello, la prima cosa che ha detto è che il segnaposto aveva sbagliato
oggetto: non è il distributore piatto da salviette piegate, è quello a **rotolo con la
leva**, e dentro ci deve stare una bobina. Largo 0,30, alto 0,36, **profondo 0,23** —
e la profondità l'ha imposta lui, non l'abbiamo scelta noi.

Il verso è misurato posandolo alle quattro rotazioni e guardando: a 90 si vede la
schiena, un quadrato liscio; a 0 e 180 il profilo di fianco; a **270** c'è il fronte,
ed è l'unica delle quattro in cui l'oggetto dice a cosa serve.

Più profondo, entrava nel giro dell'anta del pensile — che dal cardine a 5,28 arriva
fino a z 7,51 — quindi è sceso di ventidue centimetri verso sud. Da 7,60 in giù quel
giro non ci arriva.

**Il foglio che pende non è lamiera.** `vernicia` passa la stessa vernice su tutto, ed
è quello che deve fare, ma il pezzo che sporge sotto la feritoia è carta: con le
macchie di ruggine addosso non leggeva come un foglio, leggeva come un lembo di
lamiera. Si riconosce dalla geometria — è il pezzo che scende più in basso di tutti —
perché i nomi che sopravvivono all'import sono `Box003_Material #60_0` e simili.

Col distributore è arrivato anche un **portarotolo**, e va bene che sia arrivato: un
water senza portarotolo accanto legge come un sanitario da catalogo, non come un cesso
in servizio. Sta sul muro **nord** e non su quello est — il muro est è tutto occupato,
fra water e bidet restano ventidue centimetri — e seduti si guarda a ovest, quindi il
nord cade a portata di mano destra. Questo non si vernicia: arriva già fatto, e
l'unica cosa da correggere è `metallicFactor`, non dichiarato quindi uno. Nona volta.

## D-151 — La ruggine si toglie sulla mappa, non sull'oggetto

Il distributore di carta sembrava ammuffito. E ammuffito non è vecchio: è sporco.

La causa è di **scala**, non di gusto. `PaintedMetal012` è vernice bianca con chiazze
di ruggine grandi come le ha fotografate chi ha fatto la texture: su una carcassa di
plafoniera vista da due metri e settanta non si notano nemmeno; su un apparecchio da
trenta centimetri, guardato da un metro mentre ci si lava le mani, quelle chiazze
diventano **il** disegno dell'oggetto. È lo stesso problema del righello, visto da
un'altra faccia: non è la mappa a essere sbagliata, è il rapporto fra la mappa e la
cosa su cui finisce.

Si toglie **sul file**, come già si tinge — così quello che vede Blender è quello che
riceve Godot, e la scelta resta un dato in `prendi_texture.SET` invece che una
correzione a mano su un jpg che nessuno saprebbe più rifare.

`smacchia_ruggine()` non sfoca e non schiarisce: prende per base il colore della
**vernice** — la media dei pixel più chiari, quelli che la macchia non ha toccato — e
tira ogni pixel verso quella base **in proporzione a quanto se ne discosta**. Le righe
leggere restano quasi intatte, le chiazze grosse sbiadiscono. Una sfocatura avrebbe
fatto l'opposto: via il dettaglio fine, le chiazze intere.

Il numero che torna è la frazione di pixel che contava come macchia — il 24,2% qui — e
serve a sapere se il passo ha fatto qualcosa: a zero non c'era niente da togliere e la
riga in `SET` è rumore.

## D-152 — Il monitor era sfasato per una ragione scaduta

Monitor e tastiera stavano su due mezzerie diverse, a venti centimetri l'una
dall'altra: ci si siede diritti sulla tastiera e lo schermo è di sbieco.

Accanto a quello scostamento c'era il suo motivo, scritto: «al centro esatto occupava
il posto che serve al mouse». **Era vero il giorno in cui è stato scritto** — allora il
mouse stava a +0,38, cioè dallo stesso lato. Poi il mouse è passato a destra, a −0,38,
con una sua nota che spiega perché («chi si siede guarda la vetrata, quindi la sua
destra cade su −Z»), e nessuno è tornato a rileggere la nota del monitor.

Il mouse adesso occupa z 1,53-1,71 e il monitor centrato va da 1,76 a 2,24: **non si
toccano nemmeno**. Il vincolo non esiste più da mesi.

È il modo tipico in cui questo progetto sbaglia, ed è diverso dal numero preso a caso:
un numero **giusto quando è stato scritto**, sopravvissuto alla ragione che lo teneva
su. Un commento che spiega un valore lo protegge dal caso e non lo protegge da questo —
anzi lo peggiora, perché chi passa legge la spiegazione, la trova sensata e tira
dritto. L'unica difesa è che il vincolo lo misuri qualcosa: dove esiste un banco (le
porte, le plafoniere, le ripetizioni) questo non succede.

## D-153 — La luce passava davvero attraverso i muri, e la colpa era di una lampada finta

«A me sembra che la luce passi attraverso i muri». Passava.

**Misurato, non dedotto.** Aggiunto a `scatto_cupola.gd` un `SCATTO_SPENTE=<lista>` che
spegne le lampade nominate — serve a vedere una cosa che a luci tutte accese non si
vede: quanta luce arriva in una stanza che ha la **sua** lampada spenta. Con tutte
spente il magazzino sta a 0,06 di media su 255. Accendendo solo il bagno, di là dal
muro: **24,15**. Il colpevole era uno solo.

Il primo sospettato era `shadow_blur`, e aveva le sue colpe (vedi sotto), ma i numeri
l'hanno scagionato: 1,6 → 1,2 sposta il massimo da 143 a 120 e la media di un decimo.
Anche `shadow_normal_bias` da 0,45 a 0,10 e la portata da 11 a 6,5: **fuga 24,15
identica al centesimo in tutti e tre i casi**. Quando tre leve diverse non spostano un
numero, quel numero non viene da lì.

Il colpevole è la **lampada di rimbalzo**: una seconda luce nello stesso punto, debole e
**senza ombre**, messa perché quello che sta in ombra non fosse nero assoluto. Tolta:
la fuga passa da 24,15 a 0,06. È lei, per intero.

**E non è un numero da correggere — è una cosa impossibile.** Accanto le stava scritto
«portata corta, la caduta a 1,6 la fa morire prima del muro». Non è vero e non poteva
esserlo: la lampada sta a 2,42 dal pavimento e a 1,40-1,65 dai muri della sua stanza.
Una portata che arrivi al pavimento arriva ai muri **prima**. Non esiste il valore
giusto: esiste solo la scelta fra una stanza con le ombre nere e un edificio con i muri
trasparenti.

Il prezzo è misurato: la colonna sotto il catino del lavabo scende da 92 a 63 su 255.
L'ambiente notturno sale da 0,035 a 0,11 e ne recupera tre — non ventotto, ma non
attraversa niente, perché non viene da nessun punto. Il rimedio vero è la luce
indiretta calcolata, che è una decisione sull'atmosfera di tutto il gioco.

**Il controllo che mancava** è `verifica_luci_cieche()`, e la regola è geometrica, non
di gusto: dentro l'edificio una lampada proietta ombra. Attenzione al default — in
Godot `shadow_enabled` vale **falso** se non è scritto, quindi una luce cieca non lo
dice a nessuno. Le spie arancioni degli interruttori restano cieche e vanno bene: 0,008
di energia su 35 cm. Non le assolve il nome, le assolvono i loro numeri.

## D-154 — Due righe uguali nello stesso nodo, e vince l'ultima

Trovato di passaggio: `shadow_blur` compariva **due volte** su tutte e nove le
plafoniere. In cima alla lista 1,2, con tre righe di motivo — «oltre questa soglia
l'ombra rientra e su un muro di venti centimetri la luce ricomincia a passare
dall'altra parte» — e in fondo un 1,6 aggiunto dopo per ammorbidire l'ombra nel catino
del lavabo. In vigore c'era 1,6, cioè proprio il valore che il commento vieta, e il
commento restava lì a dire il contrario a chiunque lo leggesse.

È un modo di sbagliare tipico di un file **generato**: le proprietà di una lampada
vengono da una lista costruita a pezzi, e aggiungere una riga in fondo non somiglia
affatto a cancellarne una in mezzo, anche se è quello che fa.

`verifica_doppioni()` legge il testo **generato** e non il generatore: le due righe
possono nascere a cinquanta righe di distanza, da due rami diversi, e finire comunque
nello stesso nodo. Quello che conta è cosa arriva a Godot.

## D-155 — Tastiera, mouse, telefono e carta smettono di essere scatole

Della consolle erano fatti a mano, ed erano fatti bene: la tastiera aveva **ottanta
tasti veri**, cinque righe per sedici colonne, con la base a cuneo; il telefono aveva
base, forcella, tastierino e cornetta; la pila di stampati erano cinque fogli sfalsati.
Tutti e tre da un metro erano scatole — e sono tre cose che con le scatole non si
fanno:

* **un tasto** ha la faccia concava, gli spigoli smussati e le file di altezza diversa;
* **un mouse** è l'oggetto più curvo che ci sia su una scrivania;
* **un blocco di fogli** non è un parallelepipedo: i fogli non sono pari, dietro c'è il
  cartone, la costa è incollata in rosso.

È la terza volta che la stessa lezione torna dopo la porta del magazzino e il
distributore di carta, e ormai la regola è chiara: **la geometria si fa a mano quando è
fatta di piani, e si prende da fuori quando è fatta di curve.**

**Del PC retro si prendono SOLO tastiera e mouse.** Il monitor resta quello di prima,
perché ha lo schermo staccato dalla cassa e questo no — e uno schermo che il gioco non
può comandare è un adesivo. I nomi non sopravvivono all'import (sono tutti
`Object_<n>`): i due pezzi si riconoscono dal **posto** — il modello guarda verso +x
come la nostra consolle, e tastiera e mouse sono i due più avanti, appoggiati al piano
— e fra loro dal conto delle facce, 1.088 contro 124.

**Il telefono non si scala sull'altezza.** Il suo ingombro verticale lo fa il filo a
spirale, che sale in un'ansa: passandogli l'altezza vera di un telefono verrebbe grande
la metà. Si scala sulla pianta — trenta per trentadue, un telefono da tavolo con la
cornetta accanto — e l'altezza esce da sé.

**E i fogli non sono più tutti uguali**, che era l'altro difetto: cinque scatole
identiche sfalsate di quattro millimetri sono un *motivo regolare*, e niente su una
scrivania è regolare. Adesso c'è un blocco A4, due fogli scappati di sopra girati di
pochi gradi, un blocco giallo con la penna sopra e il portapenne. La carta e la
cancelleria sono CC0 (Poly Haven) e le scarica `prendi_modello.py` da solo; in quel set
i nomi **sopravvivono** all'import, perché l'autore ha dato lo stesso nome alla mesh e
al nodo, e i pezzi si possono chiedere per nome.

## D-156 — La cornetta non volava: era di scorcio

Due difetti trovati guardando, e vale la pena separarli perché uno era vero e l'altro
no.

**La tastiera dentro il monitor: due millimetri.** Misurati — il monitor arriva a x
5,773 e la tastiera cominciava a 5,771. La tastiera fatta a mano cominciava dove finiva
l'*impronta* del monitor e non lo toccava mai; quella di fuori è più profonda, e i due
si sono trovati. Il monitor arretra di tre centimetri (sta comunque a 5,7 cm dal muro,
che è dove sta un monitor) e la tastiera avanza di uno: restano quasi quattro
centimetri di aria.

**La cornetta invece non volava.** Misurato: il punto più basso del telefono è
esattamente il piano della consolle, 0,750, e i vertici entro due centimetri dal fondo
sono 390 — la base è appoggiata. Quello che si vedeva era la cornetta **di scorcio**: è
posata di fianco alla base, e a 90 gradi il suo asse puntava dritto verso chi siede.
Da lì si accorciava in un moncone verticale con l'ombra sotto, e leggeva come un
oggetto sospeso a mezz'aria.

A 270 gradi sta di traverso, piatta e intera, e il tastierino guarda comunque chi
siede. Le quattro rotazioni si sono guardate una per una, dal punto di vista di chi è
seduto e non dall'alto — perché è di lì che il difetto si vedeva.

**La lezione è sul verso.** Per i sanitari e per il distributore il verso decideva dove
guarda il fronte, e si misurava contando i vertici a filo del muro. Qui il fronte era
già giusto a 90 gradi: quello che il verso decideva era se un pezzo si LEGGE, e questo
non lo dice nessun conteggio. Lo dice guardare l'oggetto da dove lo guarderà il
giocatore.

## D-157 — L'ambiente non è il ripiego della luce indiretta

Tolta la lampada di rimbalzo (D-153), avevo alzato l'ambiente notturno da 0,035 a 0,11
per recuperare qualcosa delle ombre. Guardando una sala spenta: **troppo**. E i numeri
dicono perché, meglio di quanto lo dica l'occhio.

| | colonna del lavabo (in ombra, stanza accesa) | sala divulgazione (spenta) |
|---|---|---|
| ambiente 0,035 | 63,3 | 4,37 |
| ambiente 0,11 | 66,8 | 7,86 |

**+3,5 di qua e +3,5 di là.** È uno scambio alla pari, e alla pari nel verso sbagliato:
la luce ambientale non distingue fra un'ombra dentro una stanza illuminata e una stanza
spenta — schiarisce tutte e due allo stesso modo, e la seconda è quella che deve
restare nera. In più la media sottostima quello che si vede: su una parete grande e
piatta tre livelli di azzurro uniforme si notano benissimo, e il nero diventa latte.

Rimesso a 0,035. Resta il debito, scritto per intero: la colonna sotto il catino e il
sottopiano della consolle stanno a 63 su 255 invece che a 92, e l'unico strumento che
alza il primo numero senza alzare il secondo è la luce indiretta calcolata. Non c'è una
terza via: una luce finta attraversa i muri, l'ambiente schiarisce anche il buio.

## D-158 — La consolle smette di essere un mobile: ci si siede

Il monitor della sala di controllo era arredo. Adesso è una **postazione**: `E` ci si
siede, la camera scivola avanti mezzo secondo stringendo il campo da 55 a 42 gradi, il
vetro si accende, `E` ci si rialza.

Il meccanismo non è nuovo — `crt/crt_screen.gd`, `crt/desk_camera.gd` e
`world/interactables/crt_monitor.gd` esistono dalla storia 1.3 — ma viveva soltanto in
`world/observatory.tscn`, il mondo vecchio fatto di scatole. Nel blockout la consolle
aveva porte, interruttori e ante, e un monitor che non faceva niente.

**Tre numeri sono una misura e non una decisione**, ed è l'eccezione di `geometria.py`.
Dove sta la cassa del tubo e dove sta il vetro non discendono dalla pianta: discendono
dal modello, che `posa_modello` scala finché entra nell'impronta. Solo Blender sa dove
sia finito il vetro. Stanno in `geometria.py` lo stesso, perché il generatore deve
poterli leggere anche a modelli assenti — `assets/models/` è fuori da git — e un
generatore che si ferma perché manca un `.glb` non genera più niente. Ma non sono un
atto di fede: `verifica_postazione()` li rimisura a ogni passata di `arredi_blender.py`
e si ferma a mezzo centimetro di scarto. Provato spostando il vetro di due centimetri:
*«geometria.py dice 5.721, il modello dà 5.741 (20 mm)»*.

**L'immagine è meno del vetro, e quella invece è una decisione.** Il tubo è quasi
quadrato — 30,9 × 27,4 — e l'immagine è 4:3 come il viewport. Presa a tutta larghezza
restano ventitré millimetri sopra e sotto: non sono un errore, sono la **maschera nera**
che su un tubo vero c'è sempre. L'alternativa era stirare l'immagine per riempire il
vetro, cioè allungare ogni carattere del 18%.

**Il beccheggio del sedile non si scrive: si calcola.** `SEDILE_MONITOR` dice quanto la
testa sta avanti al vetro (42 cm) e quanto sopra il suo centro (17,2 cm); l'angolo esce
da quei due numeri. È l'unico modo di non rifare il difetto che `crt/desk_camera.gd`
racconta per esteso — il marcatore col modulo giusto e il segno invertito, che ha
inquadrato metà schermo per due storie. Misurato: la testa atterra sul sedile a **0,0
mm**, l'immagine occupa **28,2 gradi su 42 di campo, il 67%**.

**Spegnere il fosforo ha lasciato in piedi la sua ombra.** Il vetro del modello era
`Acceso` — verde emissivo, un adesivo luminoso — e la luce finta che gli stava davanti
ne copiava il colore, (0,24 0,72 0,36) a energia 0,45. Messo il display vero, l'adesivo
è diventato la maschera nera, e la luce ha continuato a imitare una cosa che non c'era
più: cassa beige verde fluo, e la maschera a 48 111 49, cioè una **cornice verde
luminosa attorno all'immagine**.

Il colore nuovo è misurato sul vetro con la sonda: 156 178 166, che normalizzato è
(0,88 1,00 0,93) — a due centesimi il `tint` dichiarato in `crt/shaders/crt.gdshader`.
I due numeri si sono incontrati da soli. L'energia l'ha scelta la misura, non l'occhio:

| energia | maschera | cassa |
|---|---|---|
| 0,00 | 38 31 16 | 189 144 68 (il fondo, solo la plafoniera) |
| 0,14 | 77 90 77 | 224 214 168 |
| 0,26 | 103 123 112 | 236 233 201 |

A 0,26 la maschera esce a 123 contro i 178 dello schermo — 1,4 a 1, e a quel punto non
è più una cornice. A 0,14 il rapporto è 2 a 1. A occhio una cassa illuminata e una
bruciata sono tutte e due «chiare».

**Il debito è dichiarato, non nascosto.** `world/desk_station.gd` è una seconda copia
della sequenza che `main.gd` fa da marzo: là è intrecciata con l'orchestratore della
notte — si siede solo se c'è una fase, avverte la notte, apre terminale e BBS — e qui
non c'è nessuna notte. Due copie di una verità sola invecchiano male. Quando il gioco
traslocherà nel blockout devono tornare una sola, e il file destinato a sopravvivere è
quello che non conosce la notte. Nel frattempo una guardia impedisce che si pestino i
piedi: `desk_station` si monta solo se il blockout è la scena che sta girando.

**E lo schermo non mostra ancora niente**, perché non c'era niente da mostrare: nel
blockout non gira nessuna fase. Si vede il grigio-verde di un tubo acceso senza segnale,
che è esattamente ciò che una postazione senza programma deve sembrare. Il contenuto
dipende da D-011 — la risoluzione del CRT va fissata prima di scrivere le sette fasi
mancanti — e quella resta aperta.

**Una sonda che contava fotogrammi non era una misura.** `tools/prova_postazione.gd`
aspettava sessanta fotogrammi «perché mezzo secondo a 60 fps sono trenta»: solo che
quella finestra non ha il vsync e ne macina cinquecento al secondo. Ha fotografato la
camera a metà corsa e ha riferito `seduti: false` con la testa a 14 cm dal sedile, cioè
ha dato per rotta una postazione che funzionava. Adesso aspetta il fatto — `is_seated` —
con un limite di tre secondi. Tre passate di fila: 0,0 mm.

## D-159 — Due schermi non possono coincidere: quindi ne resta uno

Federico, guardando: *«lo vedete solo, vero che il monitor, quello dietro e quello
davanti non coincidono? non mi sto drogando»*. Non si stava drogando.

**C'erano davvero due rettangoli.** Il quad dell'immagine era 4:3 — 30,4 × 22,8 — e il
vetro del tubo no: 30,9 × 27,4, quasi quadrato, perché è un modello preso da fuori e
misurato, non disegnato attorno al viewport. Restavano ventitré millimetri di mesh del
modello scoperti sopra e sotto, illuminati dalle luci della stanza: **un secondo schermo
dietro il primo**.

E i due non potevano coincidere, per un motivo che nessuna misura in metri avrebbe mai
mostrato. Da seduti la camera guarda in basso di 22 gradi: ventitré millimetri in cima
al tubo stanno a 42,4 cm dall'occhio e ventitré in fondo a 50,8, e la faccia è inclinata
di 34 gradi rispetto al raggio in basso e di 8 in alto. **Le due bande uguali
proiettavano 56 pixel sopra e 19 sotto.** Simmetriche nel modello, tre a uno sullo
schermo.

**La misura che ha deciso è stata una sagoma magenta.** Con lo shader acceso i bordi
sono curvi, sfumati e vignettati, e non si distingue un quad fuori posto dalla curvatura
del tubo. Dipinto di magenta piatto — `SAGOMA=1` in `tools/prova_postazione.gd` — si
vede in un colpo dove cade il rettangolo: a 30,4 × 22,8 gli angoli in alto arrivavano a
toccare la cornice della cassa mentre in basso restava un dito di scuro; **a misura
piena del vetro, 30,9 × 27,4, riempie il foro esattamente**, senza sbordare da nessuna
parte. Il foro della cassa e il vetro sono la stessa apertura, e nessuno dei due lo
sapeva.

**Quindi il quad è il vetro, e la cornice la disegna lo shader.** Le tre vie erano:

1. *stirare l'immagine* fino a riempire il vetro — allunga ogni carattere del 18%, ed è
   testo che si deve leggere;
2. *rimpicciolire il quad* al 4:3 — è quello che c'era, e lascia scoperto il secondo
   rettangolo;
3. *far disegnare la cornice all'immagine stessa*.

La terza. `crt.gdshader` aveva già una maschera che annerisce tutto ciò che cade fuori
dal vetro curvato: adesso quella maschera delimita l'IMMAGINE dentro il vetro, non il
vetro dentro il quad. La cornice è fatta della stessa cosa dell'immagine, sullo stesso
oggetto, e con `unshaded` è nera davvero — nessuna luce la tocca. **Due rettangoli che
non possono scollarsi perché sono uno.**

**Il rapporto non si dichiara: si calcola**, come le scanline e per la stessa ragione.
`crt_screen.gd` legge la misura del quad e quella del viewport e ne ricava `image_scale`
nel proprio `_ready()`. Chi cambierà il tubo, o la risoluzione quando D-011 verrà
sciolta, non deve ricordarsi che questo file esiste. Con un tubo 4:3 e un viewport 4:3
viene (1, 1), cioè il comportamento di prima esatto: il monitor del mondo vecchio non si
è accorto di niente.

**Resta una scelta, e non è mia.** Le bande nere ci sono perché il tubo è 1,13 e
l'immagine 1,33. Sparirebbero cambiando la risoluzione del viewport al rapporto del
vetro — che è precisamente la decisione che D-011 vuole presa *insieme al rifacimento
del monitor e prima* delle sette fasi mancanti. Finché quella è aperta, le bande
restano, e sono la cosa giusta: un'immagine che non riempie il tubo è un CRT, un
carattere allungato del 18% è un difetto.

## D-160 — Il vetro del tubo lo disegna il gioco, e il modello lo perde

Federico: *«puoi arrotondare un po' il monitor? è veramente un quadrato incollato e
spiaccicato»*. Aveva ragione sulla parola: **incollato**. Il quad dello schermo era una
lastra piana davanti a un cinescopio, e una lastra piana davanti a un tubo si legge come
un adesivo, per quanto bene la si illumini — tanto più che lo shader è `unshaded` e
l'illuminazione non c'entra nulla. Il profilo era dritto, e in un tubo non lo è mai.

**La cassa invece non era il problema, e valeva la pena scoprirlo prima di rifarla.** Il
sospetto era che fosse un cubo — e in pianta lo è quasi: 43 di largo, 42 di alto, 38 di
profondo, mentre un monitor da scrivania del 1999 si rastrema all'indietro. Ma guardata
da vicino ha gli spigoli tondi, il chiaroscuro sul bordo superiore e la feritoia di
sfiato. Ho anche messo a confronto il cinescopio del set retro — quello da cui vengono
tastiera e mouse — con questo, uno accanto all'altro alla stessa impronta: il retro ha
la silhouette più giusta e 224 facce contro 1402, ma la differenza non ripaga un cambio
di asset. **Il difetto era il vetro, non la scatola.**

**La calotta è misurata, non scelta:** 12,7 mm di rientro fra il centro e gli angoli.
Lo shader la fa nel vertex, su un quad suddiviso 16 × 16 — su due triangoli soli non c'è
niente da spostare. `dot(d, d) * 0.5` e non `clamp`: agli angoli il prodotto scalare vale
2 e a metà di un lato 1, quindi con la metà gli angoli rientrano di tutto e i lati della
metà. Con il clamp rientrerebbero uguale, e sarebbe una scodella a fondo piatto.

**Poi il vetro del modello è tornato a farsi vedere, ed è la stessa lezione di D-159 una
riga più in là.** Con il quad bombato, in partita spuntava davanti allo schermo una
fascia grigia a botte, con tanto di riflesso speculare. Non era prospettiva: erano di
nuovo due superfici che si contendono gli stessi pixel. Misurato il profilo del tubo,
vertice per vertice:

| r² | tubo | la mia parabola da 12,7 |
|---|---|---|
| 0,16 | 0,5 mm | 1,0 mm |
| 0,89 | 4,4 mm | 5,8 mm |
| 1,58 | 9,7 mm | 10,3 mm |
| 2,00 | 12,7 mm | 13,0 mm |

**Le due curve non hanno la stessa forma.** La faccia di un cinescopio è più piatta al
centro e più ripida al bordo; una parabola scende subito. A metà raggio il quad era già
un millimetro e mezzo più profondo del vetro, e ci sprofondava dentro — con la stessa
profondità totale, che è la ragione per cui confrontare le due *profondità* non avrebbe
mai trovato niente.

Si può inseguire il profilo dell'altro per sempre, o togliere l'altro. **La faccia del
tubo, in partita, è il quad**: è lui che si accende, che mostra qualcosa e che si spegne.
La mesh del modello serviva solo a dire dov'è, e quello l'ha già detto — la misura sta in
`geometria.py` e `verifica_postazione()` la ricontrolla a ogni passata, prima che
`sfila_il_vetro()` la butti. Nel render di Blender resta un buco, ed è giusto così: il
modello non ha uno schermo, e fingere che ce l'abbia è esattamente l'errore da cui
veniamo.

**Una via scartata, e il motivo per cui è stata scartata:** tenere tutti e due e abbassare
la calotta a 10 mm perché il quad restasse davanti a ogni raggio. Funzionava, misurato —
franco minimo 0,8 mm — e ho perfino scritto il controllo che lo verificava vertice per
vertice, provandolo rimettendo i 13 mm (*«a r2 0.89 il franco è −0,3 mm»*). Ma era una
tolleranza fra due cose che non devono coesistere: il giorno che il modello del tubo
cambia, quel numero è di nuovo sbagliato e nessuno se lo ricorda. Tolto il vetro, il quad
può permettersi la misura vera.

## D-161 — Il telaio della porta non esisteva per la fisica

Federico: *«se passo davanti a una porta la cui luce dietro è accesa, quindi porta
chiusa, mi si resetta»*. Vero, e la causa non era nell'adattamento.

`world/player/luce_prossimita.gd` decide se è buio **chiedendo alle lampade**: per
ognuna, quanta ne arriva qui e se da qui si vede. La seconda metà è un raggio, e un
raggio che non incontra quello che dovrebbe è invisibile — la lampada torna a contare,
l'adattamento si azzera, e si vede solo l'effetto, mai la causa.

**Il telaio morde otto centimetri di vano su ogni lato e sopra il battente, e in gioco
era mesh e basta.** Lo dice `blocchi_infissi()` stesso, in cima: *«il blockout vuole i
vani VUOTI, per poterci passare. Gli infissi servono al modello, non alla camminata»*.
Era vero, ed è la stessa forma di errore che questo progetto raccoglie da settimane: una
frase giusta il giorno che è stata scritta, sopravvissuta al giorno in cui il buio è
diventato una cosa che si misura.

**Misurato**, mettendo il giocatore su una griglia di settanta punti attorno a ogni porta
chiusa con una sola stanza accesa: il raggio verso la plafoniera attraversava il piano
della porta a **2,059 m** — fra la cima dell'anta (2,02) e quella del vano (2,10) — e a
1,930 con scostamento 0,925, cioè oltre il bordo libero dell'anta. Sopra il battente e di
fianco: le due strade che il telaio dovrebbe chiudere.

**La prima cura ha rotto le porte**, e vale la pena scriverlo. Dati i montanti interi, il
banco delle porte è passato da 118 gradi liberi a 41: il battente ci sbatteva dentro. Il
motivo, coi conti, perché ci ho sbagliato due volte: l'anta ruota attorno a un asse che
sta a **metà del suo spessore** — non sulla faccia, come una porta vera — quindi
aprendosi una parte di lei finisce dietro il piano del cardine. Un punto a distanza `x`
dal cardine e scostamento `z` ci finisce quando `z·sin(a) > x·cos(a)`, cioè **solo se `z`
è positivo**: solo la faccia dal lato verso cui la porta si apre. E dopo la rotazione il
suo scostamento, `x·sin(a) + z·cos(a)`, è positivo anche lui.

**Dietro il cardine l'anta sta sempre dalla parte dell'apertura, a ogni angolo.** Quindi
il montante è solido nella metà opposta, e lì l'anta non arriva mai. Il buco che resta non
lascia passare niente: un raggio che attraversa il muro deve percorrere tutta la
profondità del telaio, e per restare in quella metà dovrebbe uscire di lato — finendo
nell'anta, che è solida, o nella muratura.

**Il vetro non diventa solido, ed è il punto della funzione.** Una finestra deve lasciar
passare la luna: dare un solido al vetro spegnerebbe la luna dentro casa, scambiando un
difetto con un altro. Passano solo i telai, che sono legno.

**Provato per iniezione, come si deve.** Con i telai: 0 perdite, 5565 raggi fermati, porte
libere fino a 113-118 gradi contro i 90 di apertura. Senza: **29 perdite**. E la sonda
stessa ha dato un falso «zero» per due giri prima che me ne accorgessi — non partiva
affatto, un errore di sintassi, e stampava zero perché non stampava niente. Un controllo
che tace non è un controllo che passa.

**Una cosa in più che adesso il banco dice:** *chi* ferma l'anta, non solo a quanti gradi.
Senza il nome si sa che qualcosa non va e non si sa dove guardare, ed è costato tre
tentativi buttati su un montante che non era il colpevole.

**Resta scritta l'asimmetria dell'adattamento**, che non è un difetto ma va saputa: la
lampada di prossimità cade in un quarto di secondo e risale in trenta secondi. Qualunque
spiraglio momentaneo — un raggio che passa per un istante — costa mezzo minuto di buio. È
la ragione per cui una perdita di pochi centimetri si nota tanto, ed è anche la ragione
per cui vale la pena chiuderle tutte invece di ammorbidire la soglia.

## D-162 — La notte comincia aprendo la cupola

**31 agosto 2026.** Le dieci fasi del GDD partono dal livellamento e dal bilanciamento:
due gesti sulla montatura, cioè due cose che in gioco non si possono ancora fare, perché
la montatura non si tocca. Federico chiede di cambiare l'ordine e di mettere per prima una
fase **che si fa al computer**: aprire la cupola.

**È la fase più giusta da fare per prima proprio perché non ha bisogno di niente.** Il
pannello sta sul CRT, dove il giocatore è già seduto; il meccanismo esiste già nel modello
(`cupola_blender.py` esporta `PortelloBasso` e `PortelloAlto` da marzo, con l'origine nel
centro della sfera, apposta perché ruotino sul guscio); e il gesto è vero — una cupola si
apre prima di osservare, sempre, ed è la prima cosa che si fa arrivando.

**Comando a uomo presente.** Si tiene premuto e il motore va; si lascia e si ferma dov'è.
Non è una scelta di comodo: le cupole vere si aprono così, perché un battente da qualche
quintale che si muove mentre nessuno guarda è un modo di rompere un telescopio. Ed è anche
l'idioma già stabilito dalla fase polare — «le viti si girano, non si scattano». Corsa
intera: **6,25 secondi**, misurati dal banco integrando il `.tres` invece di fidarsi del
numero (`motor_speed = 0,16` corsa/s).

**Nessun punteggio, e dichiarato.** È il caso della fase 4 del GDD: «si passa o si
ripete». Non c'è niente da fare bene o male, c'è solo da farlo, e inventare una metrica
qui vorrebbe dire inventare una bravura che il gesto non contiene.

**Come la fase parla alla cupola, che sta in una cartella che le è vietata.** `phases/`
non può nominare `world/`. Il condotto è `Events.dome_aperture_changed(fraction)`, e porta
un **fatto** — «l'apertura vale 0,37» — non un comando: la fase dice dov'è arrivata la
corsa, e chi nel mondo ha un battente lo mette lì. Il giorno in cui la cupola la aprirà un
interruttore in loco o un temporizzatore, quel qualcosa dirà lo stesso fatto e
`world/dome_shutter.gd` non cambierà di una riga. È lo stesso verso di `sequence_started`.

**Porta la POSIZIONE e non «aperta/chiusa»:** il battente si vede muovere, e un booleano
lo farebbe scattare.

**Un solo nodo per due cupole diverse, e servivano entrambe.** Il mondo in cui il gioco
gira oggi (`main.tscn` → `observatory.tscn`) ha la cupola segnaposto: due lastre di tetto
che **scorrono**. Il blockout ha quella modellata: due gusci che **ruotano** sul guscio.
`dome_shutter.gd` dichiara per ogni battente uno scostamento in metri **e** uno in gradi, e
li interpola tutti e due dalla posa di scena — che è la cupola CHIUSA. Un solo meccanismo
avrebbe voluto dire riscrivere il file al trasloco.

**Perché i portelli modellati non si aprono allargandosi**, che sarebbe il gesto ovvio. Il
portello basso copre già da −2 gradi, e i portelli scorrono a raggio 2,60 mentre il foro
nel tetto ha raggio 2,50: ruotandolo in giù non trova aria, trova la falda. Sopra lo zenit
invece non c'è niente. Quindi **novanta gradi tutti e due nello stesso verso**: è uno
scorrimento, non due ante, e i battenti finiscono accavallati dall'altra parte.

**All'alba la cupola si chiude.** Senza, resterebbe aperta per sempre: la notte dopo la
fase ricomincerebbe da un pannello che dice CLOSED con il cielo già in vista, e il
giocatore avrebbe ragione a non credere più al pannello.

**Provato per iniezione, su tutti e due i mondi.** Segnaposto: luce netta 0,000 m da
chiusa, **1,000 m** da aperta. Modellato: i due gusci ruotano di 90,0 gradi e i loro
baricentri percorrono 3,15 e 3,40 m. Con la corsa azzerata la sonda grida «2 LASTRE
FERME»; con un `NodePath` sbagliato il nodo grida il percorso che non ha trovato.

**La sonda misurava la cosa sbagliata, e lo diceva con sicurezza.** Prima versione:
spostamento dell'ORIGINE del nodo. Per le lastre che scorrono va bene; per due gusci che
ruotano attorno al proprio centro l'origine non si muove di un millimetro, e la sonda
dichiarava fermi due portelli che si erano appena girati di un quarto di giro. Adesso
misura il **baricentro della mesh**, che si muove in tutti e due i casi. È la terza volta
in questo progetto che un controllo sbagliato è più pericoloso di nessun controllo.

**E la luce netta si stampa solo quando vuol dire qualcosa.** Fra due gusci che ruotano
sullo stesso sferoide la distanza è negativa sempre, prima e dopo: metterla in tabella
sarebbe mettere in tabella una misura che non misura niente.

**Cosa resta aperto, ed è la sola cosa che questa decisione non chiude.** Le fasi vivono
al monitor, e il monitor con la notte sta in `main.tscn`, cioè nel vecchio osservatorio.
Nel blockout la cupola vera si muove, ma non c'è ancora nessuno che gliela dica: manca la
notte. **Il trasloco del mondo** — `main.tscn` che punta al blockout — è il passo che fa
combaciare le due metà, ed è già in coda da prima di questa storia.

## D-163 — I toni continui si spengono, i beep restano

**31 agosto 2026, giudizio d'operatore: «il suono è un incubo».**

Il ronzio della lampada, il cigolio della cupola, la montatura del telescopio, il
borbottio della moka: quattro onde quadre generate in GDScript, nate come segnaposto —
nessun asset d'arte, coerenti con un progetto che aspetta un pack. **Ognuna era
ragionevole scritta da sola.** Tutte insieme, in loop, per un'ora di notte, non fanno un
ambiente: fanno un'onda quadra continua sotto ogni cosa.

**Si spengono quelle CONTINUE, non tutte.** I suoni brevi restano: il beep del terminale,
quello della BBS, la portante del modem, il campanello di fine sequenza. Durano un
istante, dicono che qualcosa è successo, e nessuno li tiene in testa. **Il problema non
era il timbro, era la durata.**

Un interruttore solo, `world/toni_segnaposto.gd`, e con lui è confluita la guardia
`_audio_is_audible()` che stava ricopiata in quattro file — quella che impedisce di
avviare un suono in headless, dove il driver è `Dummy` e un playback spento a forza lascia
un WARNING che fa fallire il cancello di verifica. Quattro copie di una verità sola: una
adesso.

Si riaccende con `CONTINUI = true`, una riga. Il giorno in cui arriveranno i campioni veri
ogni nodo ha già il proprio posto dove metterli — `_install_*_sound()` — e questo file
sparisce con un `git rm`.

## D-164 — Il gioco trasloca nell'edificio vero

**31 agosto 2026.** `main.tscn` non punta più a `world/observatory.tscn` — il kit-bash di
scatole con cui l'epica 1 aveva fatto esistere un posto — ma a `world/blockout.tscn`, cioè
all'osservatorio modellato: quindici locali, la cupola, gli infissi, gli impianti.

**La spinta è arrivata da una domanda di Federico, ed era la domanda giusta:** «ma che
cupola stai aprendo, mi sembra quella del vecchio osservatorio». Lo era. La fase 1 apriva
due lastre di tetto che scorrono, non i due gusci del cinescopio— pardon, del *tubo* —
modellati a marzo. Il meccanismo funzionava in tutti e due i mondi (D-162); solo che quello
in cui il gioco girava era il vecchio.

**Cosa ha traslocato con lui.** Il letto, la moka, la lampada da riparare, il campanello di
fine sequenza, il volume «dentro l'edificio» e il registro «stare a guardare» della cupola.
Sono gli stessi nodi di prima, con le stesse scene: quello che cambia è dove stanno.

**Cosa NON ha traslocato, e va detto:** la vita del telescopio. `world/telescope.gd`
pretende tre figli — `$Tube`, `$Hum`, `$Body` — e il telescopio del mondo nuovo arriva
dentro `osservatorio.glb`, dove quella struttura non c'è. Finché non gliela si dà, la
montatura non insegue e non ronza durante la posa. È l'unico pezzo dell'epica 3 rimasto
indietro, ed è un lavoro suo.

**Il letto in magazzino, e non l'ho deciso io.** L'avevo messo nella sala di controllo —
dove stava nel vecchio mondo, «a un paio di passi dalla scrivania» — e i controlli di
`verifica_stanza` lo hanno rifiutato al primo giro, prima che la scena esistesse: finiva
sotto l'anta della porta del corridoio, che si apre in dentro e spazza un quarto di cerchio
da 1,06, e quel che restava di pavimento si spezzava in due con quasi un metro quadro
irraggiungibile a piedi. Nel magazzino ci sta: la porta è metà e spazza mezzo metro appena.

**È il motivo per cui il letto è finito FRA GLI ARREDI di `geometria.py`** invece che in un
angolo di scena: là dentro lo guardano cinque controlli — dentro la stanza, non dentro un
mobile, non sotto un'anta, non davanti a un vetro, e il resto ancora percorribile — e
nessuno dei cinque sa aprire una scena di Godot. Un letto messo a occhio li avrebbe saltati
tutti.

**Il volume «dentro» è in due scatole e non in una.** La pianta è una elle: una scatola
sola coprirebbe anche il prato davanti alla facciata, e chi ci passeggia risulterebbe
dentro — il campanello di fine sequenza suonerebbe come se fosse in corridoio. Gli spigoli
delle due scatole sono LETTI dal perimetro, non ricopiati.

**La sonda ha misurato per tre giri la cosa sbagliata.** In partita la cupola sembrava
aprirsi a metà velocità: 0,08 di corsa al secondo contro 0,16. Ho cercato il guasto nel
tempo di gioco, nella sospensione della fase, nello stato dell'input. Non c'era: la sonda
aveva DUE punti in cui sommava il proprio orologio, e dopo la pressione ci passava da tutti
e due nello stesso fotogramma. Il meccanismo era giusto e la misura no — la stessa forma di
guasto di D-162, due volte in un giorno.

**Come sta adesso, misurato in partita vera** (`PARTITA=1` in `tools/prova_cupola.tscn`:
carica `main.tscn`, si siede al monitor, tiene premuto): seduti dopo mezzo secondo,
apertura piena a 6,75 s, i due portelli ruotati di 90,0 gradi con i baricentri che
percorrono 3,15 e 3,39 m, la fase `dome` chiusa con 100, e subito dopo la fase `polar`
montata. La notte va avanti.

**E che il letto si possa USARE non l'ho dedotto: l'ho misurato.** `bed.tscn` porta
scritto in testa un difetto già pagato — il primo letto di questo progetto non si poteva
usare, per una geometria che nessuno aveva provato guardandola — e il magazzino è stretto
abbastanza da rifarlo. `tools/prova_letto.tscn` accende il letto, gira attorno con il corpo
del giocatore e, da ogni punto in cui si sta in piedi, guarda la spalliera **col raggio del
giocatore**: portata, maschera e altezza dell'occhio sono i suoi, non copie. Referto: due
punti buoni, il più vicino a 0,72 m, tutti e due davanti alla porta. Stretto, ma vero.

**Anche questa sonda ha mentito una volta prima di dire il vero,** e vale la pena scriverlo
perché è sempre lo stesso errore: al primo giro dichiarava occupati tutti e
centosessantanove i punti — «il letto è irraggiungibile». La capsula del giocatore è alta
1,80 e sta a 0,90 dai piedi, quindi il suo fondo tocca il pavimento esattamente; il
pavimento è sul layer 1 come tutto il resto, e un contatto tangente conta come
intersezione. Cinque centimetri di sollevamento, e la stanza è tornata quella che è.

**Il debito della postazione è scaduto e non è stato pagato.** `world/desk_station.gd`
dichiarava che al trasloco sarebbe dovuto diventare una cosa sola con la parte
corrispondente di `main.gd`. Non è successo: da oggi quel file TACE per tutta la partita —
la sua guardia vede che non è lui la scena corrente — e resta acceso solo per le sonde, che
montano il blockout da solo per provare una cosa alla volta. Metterci dentro una
riscrittura della postazione nello stesso commit che cambia il mondo sotto i piedi sarebbe
stato un modo di non sapere più quale delle due cose ha rotto cosa. Sta scritto in testa a
quel file, com'è e perché.

## D-165 — Il quadro della cupola ha due pulsanti

**31 agosto 2026.** «Dal PC devi darmi l'opzione di aprire e chiudere la cupola.» Aveva
ragione, e la prima stesura aveva una scusa sola: la fase serviva ad aprire, quindi apriva.

**Una cupola che si apre e basta non è una cupola: è una cerniera.** Il quadro adesso ha i
due pulsanti che ha un quadro vero — **SU apre, GIÙ chiude** — tutti e due a uomo presente,
tutti e due che si fermano dove li lasci.

**Il comando smette di essere un interruttore e diventa un VERSO.** `DomeInput.motor_on`
(booleano) è diventato `command` (+1, 0, −1), e `HonestShutter` restituisce
`motor_speed × verso`. È il cambio che rende la chiusura una proprietà del meccanismo
invece di un caso speciale nella fase: una sorgente bugiarda che un giorno volesse far
chiudere la cupola da sola non deve inventarsi niente, le basta restituire un numero
negativo.

**Tenere premuti tutti e due i pulsanti vale zero,** ed è l'interblocco che i quadri veri
hanno. Si ottiene con `Input.get_axis`, non con due `if` in fila: con due `if` vincerebbe
l'ultimo che ho battuto a tastiera, cioè il caso.

**Si esce ancora solo a cupola aperta, e adesso il pannello DICE perché.** Da lì in poi la
notte punta, mette a fuoco ed espone: con il tubo sotto un guscio chiuso sono tre fasi
giocate contro un coperchio. Prima INVIO semplicemente non rispondeva; adesso al suo posto
c'è scritto `OPEN FULLY TO CONTINUE`, perché un tasto che tace è indistinguibile da una
macchina rotta.

**APERTURA e CHIUSURA sono due parole diverse sul display,** e non per pedanteria: con una
parola sola — «in movimento» — chi ha sbagliato pulsante lo scoprirebbe solo guardando la
barra scendere.

**Provato aprendo, chiudendo e riaprendo in partita vera:** apertura piena a 6,76 s, due
secondi di pulsante GIÙ portano da 1,000 a 0,680 — cioè 0,32, esattamente due secondi alla
velocità del motore — riapertura in 2,01 s, INVIO, fase chiusa con 100 e `polar` montata.
Il banco misura anche la corsa di ritorno: 6,25 s, la stessa dell'andata.

**Iniettato il difetto che i due controlli esistono per prendere** — una sorgente che
ignora i comandi negativi — e gridano tutti e due: la sonda «NON SI RICHIUDE», il banco
«ATTESO: negativa, il battente torna».

## D-166 — Da seduti ci si guarda intorno, e la sedia gira

**31 agosto 2026, suggerimento di Federico:** «se uno vuole vedere la cupola che si apre
sarebbe bello poter muovere la visuale liberamente». Aveva colto una contraddizione che era
nel disegno e che non avevo visto: **il comando è a uomo presente, quindi per aprire la
cupola devi restare seduto; e da seduti la testa era inchiodata allo schermo.** L'unica
cosa che il giocatore poteva vedere della fase 1 era una barra che si riempie.

**La cupola dalla postazione SI VEDE**, ed è la ragione per cui questa correzione è piccola
invece che grande: fra la sala di controllo e la sala del telescopio c'è una vetrata, e il
monitor ci sta proprio davanti. Mancava solo poter alzare lo sguardo. Fotografato da
seduti, testa a 6,16 · 1,15 · 2,00, imbardata 98°, alzata 32°: si vede la calotta con la
sua ossatura e, dentro la fenditura, il cielo.

**Imbardata sul corpo, beccheggio sulla testa,** identico a quando si è in piedi. E girare
il corpo da seduti non sposta la testa di un millimetro: il marcatore del sedile sta dritto
sopra l'origine del corpo, quindi ruotare attorno alla verticale è **esattamente una sedia
girevole**. Non serve nessuna aritmetica in più.

**Si torna com'era alzandosi, senza una riga apposta:** `_leave()` rimetteva già il corpo
nella posa di prima e la testa al beccheggio di prima, che sono precisamente le due cose
che il guardarsi intorno cambia.

**Il cursore si ricattura sedendosi, e non c'è un tasto per liberarlo da seduti.** È una
scelta: ESC da seduti è già il tasto che chiude il terminale e la BBS, e prenderlo qui
vorrebbe dire rubarglielo — questo nodo è figlio di chi orchestra, e in `_unhandled_input`
i figli passano prima. La via d'uscita è `E`: ci si alza, il controller torna acceso, e da
lì ESC fa quel che ha sempre fatto. Due tasti invece di uno, in cambio di nessun conflitto.

**Sensibilità e limite di beccheggio sono ricopiati da `world/player/player.gd`,** e la
copia è deliberata: `crt/` non conosce `world/` — è un sistema generico che riceve un
`Control` e non sa nemmeno di stare in un osservatorio. Importare il giocatore per due
costanti aprirebbe una porta che la tabella dei confini tiene chiusa. Il giorno in cui la
sensibilità diventerà un'impostazione, sarà un dato che arriva a tutti e due da fuori.

## D-167 — La fase 8: si mette a fuoco cercando, non eseguendo

**31 agosto 2026.** «Vai con la prossima fase, quale potrebbe essere?» Fra le sette non
implementate, **il fuoco** è quella da fare adesso, e per tre ragioni che si sommano.

**Vive tutta sul CRT.** Livellamento e bilanciamento sono gesti sulla montatura, e la
montatura in gioco non si tocca. Il focheggiatore invece è un motore con due pulsanti e un
numero: sta dove il giocatore è già seduto.

**È la prima fase in cui si CERCA.** L'allineamento polare si esegue — c'è una deriva, la
si annulla. Il targeting si sceglie. Qui nessuno dice dove sia il fuoco: si vedono sette
stelle e quanto sono grosse, e si stringono. Il traguardo è visibile a occhio senza che
nessuno lo scriva, che è la stessa proprietà per cui la fase polare funziona.

**Cade nel posto giusto del ciclo.** Il ciclo foto era targeting → posa, cioè scegli e
aspetti. Adesso è targeting → fuoco → posa: fra la scelta e l'attesa c'è un mestiere.

**LA CURVA A V SI DISEGNA DA SOLA, ed è la cosa che insegna la fase.** Ogni posizione
visitata lascia un punto sul grafico in basso; dopo due passate il giocatore vede la forma
— due rami che scendono verso un minimo — e capisce da che parte andare. È come si mette a
fuoco davvero, e non c'è tutorial che lo spieghi meglio del grafico stesso. Il grafico si
scala **sui punti visitati** e non sulla corsa meccanica: scalato sulla corsa metterebbe il
fuoco sempre nello stesso punto dello schermo, e la fase si giocherebbe guardando il centro
del riquadro invece delle stelle.

**Non è una V, è un'iperbole,** `sqrt(min² + (pendenza·Δ)²)`, e la differenza si sente
giocando. Una V vera ha il vertice a punta: ci passi sopra e non senti niente. La curva
vera dell'ottica lontano è indistinguibile da una retta e vicino si arrotonda, e
quell'arrotondamento **è** la sensazione di «ci sono quasi». È anche la formula con cui gli
autofocus veri interpolano il minimo.

**Il minimo non è zero, ed è giusto così:** a fuoco perfetto una stella resta un dischetto,
perché l'atmosfera la allarga. È il seeing, e per questo il punteggio pieno non chiede
diametro nullo ma `focus_best_hfd`, un filo sopra il minimo dell'ottica: **chiedere il
minimo esatto vorrebbe dire chiedere un passo esatto su milleottocento**, cioè trasformare
una fase di mestiere in una lotteria di precisione.

**Più le stelle sono larghe più sono fioche,** ed è la sola ragione per cui il campo si
legge a colpo d'occhio: la luce di una stella è sempre la stessa, e spalmarla su un disco
più grande la diluisce. Un campo in cui i dischi crescono restando luminosi sembrerebbe
migliorare mentre peggiora.

**Il numero sul display non aiuta, e non deve.** L'encoder mostra passi veri con uno
scostamento estratto a caso a ogni montaggio. Senza, il giocatore imparerebbe un numero
invece di una curva, e la fase diventerebbe «porta il display a zero», cioè niente.

**Il limite è dichiarato:** il fuoco sta al centro della corsa meccanica e ci resta. Chi
gioca molte notti può impararlo. La cura non è un numero casuale — è la **deriva termica**,
che nella realtà sposta il fuoco di qualche decina di passi per grado mentre la notte si
raffredda. Quando ci sarà una temperatura, `best_position` diventerà il suo punto di
partenza e la fase non cambierà di una riga: continuerà a chiedere quanto sono grosse le
stelle.

**Due misure che nessun file conteneva, e che adesso il banco stampa.** La zona di
punteggio pieno è larga **124 passi**, cioè **0,62 secondi di dito** a 200 passi/s: nasce da
tre numeri che stanno in due posti diversi (`min_hfd` e `slope` nel .tres, `focus_best_hfd`
in `Tuning`), e se qualcuno ne cambia uno la fase diventa una lotteria o un regalo senza che
una riga di codice cambi. E al fermo meccanico il diametro è 9,31 contro una soglia dello
zero a 6,50: anche il peggio possibile vale zero, come deve.

**Che si possa VINCERE l'ho misurato giocandola.** `tools/prova_fuoco.tscn` cerca il minimo
come lo cercherebbe una persona la prima notte — vai da una parte, se peggiora torna
indietro — e resta deliberatamente stupida: con la formula della curva troverebbe il minimo
al primo colpo e non proverebbe niente. Referto: **punteggio 100 in quattro secondi e
mezzo**, cinque inversioni.

**Nessuna misura non è misura perfetta.** Prima del primo `_process` il diametro vale zero,
e zero è più piccolo del minimo possibile: chi premesse INVIO nel fotogramma in cui la fase
compare si porterebbe via 100 senza aver toccato niente. `score()` restituisce 0 finché non
c'è un campione — la stessa clausola che la fase polare scrive al contrario.


## D-168 — Un telescopio sul pilastro non si allinea ogni notte

**1 settembre 2026.** «Un telescopio fisso ha bisogno della polare?» La domanda è arrivata
mentre stavo per costruire la fase successiva, e la risposta è **no**. C'è voluto un GDD
intero per non accorgersene, e una riga di Federico per vederlo.

**Che cosa era sbagliato.** L'allineamento polare col metodo della deriva è la fase più
lunga del setup — sessanta minuti della prima notte — ed è un'operazione che si fa **una
volta**, quando la montatura la si installa sul pilastro, con le chiavi in mano. Poi resta
allineata per anni. Il rito serale della deriva è di chi il telescopio se lo carica in
macchina e lo rimonta ogni volta sul prato. In un osservatorio con la montatura imbullonata
su una colonna di cemento, rifarlo ogni sera è come rifare le fondamenta prima di entrare in
casa. Lo stesso vale per il **livellamento** (si livella la colonna, non la notte) e per il
**bilanciamento** (si bilancia quando si cambia il carico, cioè quando si monta un'altra
camera).

**Che cosa si fa davvero.** All'accensione una montatura non sa dove sta guardando: si punta
una stella brillante e nota, la si centra, si preme SYNC, e da lì il GOTO va dove gli dici.
È la prima cosa della sera in ogni osservatorio, ed è un gesto migliore di quello che
sostituisce — nella polare fermi la stella dov'è, nella sincronizzazione la porti al centro:
il traguardo è più leggibile, e lo stesso reticolo racconta due mestieri diversi.

**Il nuovo elenco, dieci fasi.** Setup: apertura della cupola, accensione e collegamento,
raffreddamento della CCD, dark e flat, sincronizzazione del puntamento. Ciclo foto:
targeting, rotazione della cupola, fuoco, autoguida, posa. Il **plate solving** smette di
essere una fase e diventa l'**upgrade della sincronizzazione**: è la regola 2 del GDD
applicata alla lettera — compri tempo e paghi in qualità.

**Che cosa entra, e perché è vero.** Il *raffreddamento della CCD* è quello che fa chi
accende una ST-8 nel '99: imposti il setpoint e aspetti, e il mestiere sta nello scegliere
quanto freddo chiedere alla notte che c'è — troppo, e il Peltier va al 100% senza tenerlo, la
temperatura balla e i dark non corrispondono più. La *rotazione della cupola* è la cosa che
rende una cupola una cupola: la fessura va portata sull'azimut del telescopio, e ci va
riportata durante la posa, perché il cielo gira e la cupola no. È l'unica fase che fa alzare
il giocatore dalla sedia mentre la macchina lavora, ed è un regalo per un gioco che si gioca
camminando.

**Il rischio dichiarato.** La rotazione della cupola e la sua apertura sono lo stesso gesto —
tieni premuto — e due fasi con lo stesso gesto sono una ripetizione finché non si dimostra il
contrario. Qui la differenza c'è (un bersaglio da centrare, e l'obbligo di tornarci) ma va
verificata in gioco: se annoia, la via d'uscita è fonderla con la fase 1.

**Che cosa NON è successo.** Le tre fasi tolte non sono state cancellate: sono manutenzione,
e torneranno quando qualcuno avrà messo le mani sulla montatura. `phases/polar/` resta nel
repository e non cambia di una riga — è ancora la prova dell'AC2 della storia 1.1,
rieseguibile con `git diff` da quando esiste il progetto. È uscita dal piano della notte
(`data/night_plan.tres`), che è esattamente il posto in cui ADR-002 dice che si decide chi
gioca stanotte: nessun file di codice ha dovuto sapere che la polare non c'è più.

**Il conto della notte cambia, e si dichiara.** Il setup della prima notte passa da 140 a 110
minuti, e il tempo libero da 20 a 28 minuti reali: l'automazione non raddoppia più il tempo
libero, ne aggiunge dodici. Il rituale serale di un osservatorio fisso è più corto di quello
di chi lavora sul prato, e truccare i numeri per far tornare una frase scritta prima sarebbe
stato il modo peggiore di scoprirlo.


## D-169 — La fase 2: si accende leggendo, non ricordando

**1 settembre 2026.** Prima fase del nuovo elenco (D-168): accensione e collegamento della
strumentazione.

**Il pericolo era la filastrocca.** Il GDD la descriveva come «sequenza nell'ordine giusto:
montatura, camera, guida, software; l'ordine sbagliato non fa riconoscere i dispositivi», e
scritta così sarebbe stata la fase peggiore del gioco: un ordine da imparare a memoria e poi
ripetere venti notti, cioè una tassa travestita da mestiere. La prima notte si sbaglia, si
legge da qualche parte come si fa, e da lì in poi si esegue senza guardare.

**Che cosa c'è al suo posto: diagnosi.** Non c'è nessun ordine scritto da nessuna parte. C'è
un bus che risponde o non risponde, una tabella che dice quale porta è muta, e un registro
che racconta che cosa hai fatto. Chi legge quello che c'è scritto arriva in fondo la prima
notte senza sapere niente — che è quello che fa chi accende un osservatorio davvero.

**L'ordine conta lo stesso, ma come conseguenza.** Aprire la porta a un apparecchio spento la
lascia in mano a un driver che ci ha già parlato e non ci riprova: accendere l'interruttore
dopo non serve, ci vuole il RESET. È il comportamento di un bus seriale vero, ed è l'unica
ragione per cui questa fase si può sbagliare. Cade fuori dalla sorgente **senza un caso
speciale**: `HonestBus` guarda `powered_when`, cioè com'era l'alimentazione nell'istante del
tentativo, e quel bit non torna indietro da solo.

**Il solo pezzo da dedurre.** La ruota portafiltri non ha un interruttore: prende i suoi
dodici volt dalla camera. Lo schermo non lo scrive da nessuna parte — dice solo che la sua
porta è muta — e il giocatore lo mette insieme. Un messaggio che dicesse «accendi prima la
camera» trasformerebbe la deduzione in una lettura, ed è per non scriverlo che questa fase ha
un mestiere.

**Che si possa sbagliare e rimediare l'ho misurato giocandola.**
`tools/prova_accensione.tscn` fa lo sbaglio naturale — collega per prima la ruota, che è
l'ultima riga e sembra la più facile — accende la camera dopo, e verifica che la porta sia
**ancora muta**; poi resetta, ricollega, e verifica che risponda. Sette verifiche, tutte
verdi. E il controllo che conta l'ho validato iniettando il difetto che esiste per prendere:
con `HonestBus` che ignora `powered_when` — cioè con la porta che guarisce da sola — la sonda
grida su due righe.

**Il registro riempie lo schermo con una cosa vera.** La prima stesura lasciava metà pannello
vuoto. Invece di allargare la tabella ho messo quello che un software di controllo ha
davvero: quattro righe di log che scorrono, `POWER ON: CAMERA`, `NO RESPONSE ON CFW`, `PORT
CFW RELEASED`. Si scrivono **dopo** aver sentito `truth`, mai nel momento in cui il driver
finisce: il registro racconta i fatti e non le intenzioni, e il giorno in cui il bus mentirà
il registro mostrerà la bugia invece di coprirla.

**Un tasto solo fa due mestieri**, e va detto perché è il genere di scorciatoia che si paga:
INVIO agisce sulla riga sotto il cursore finché c'è qualcosa da fare, e chiude la fase quando
rispondono tutti. Un tasto in più solo per uscire sarebbe un tasto che si usa una volta a
notte e si dimentica in tutte le altre. Che le due cose non si mangino a vicenda è una delle
sette verifiche della sonda.

**Il pannello finisce dentro il monitor, e non l'ho dedotto.** `tools/prova_vetro.tscn` è
nato da una domanda di Federico — «ste cose le stai mettendo dentro il monitor, vero?» — e
gioca la notte vera dal PC fino alla fase che gli si chiede, poi fotografa la finestra: si
vede il CRT sulla scrivania, e dentro il vetro il pannello. Tre errori miei che quella sonda
ha trovato, tutti nella sonda e nessuno nel gioco: si collegava al bus **dopo** aver
istanziato il gioco (la prima fase era già partita), mandava un `InputEventAction` chiamato
`dome_confirm` a una fase che aspettava `polar_finish` (gli eventi d'azione si riconoscono
dal nome, non dal tasto), e premeva il comando una volta sola — ma quando la finestra perde
il fuoco Godot rilascia da sé tutte le azioni, e il referto diceva «battente fermo, tasto non
premuto, fase che gira»: il meccanismo era sano, era la mano della sonda ad aprirsi.


## D-170 — La dotazione ha un nome, e l'economia dichiara di essere finzione

**1 settembre 2026.** Tre incoerenze trovate rileggendo il GDD dopo D-168, tutte
nella stessa zona: che cosa c'è in cupola, e quanto costa.

**Il telescopio non era mai stato deciso.** Il GDD non diceva né tipo né diametro, e da
quei due numeri discende tutto il resto: la scala in arcosecondi per pixel, il campo
inquadrato, quanto è critico il fuoco, quanto dura una posa sensata. Avevo proposto un
Newton da 40 cm f/4,5, e **il modello mi ha corretto**: `telescopio_blender.py` dichiara il
tubo lungo **1,50 m**, e il vincolo non è la cupola ma il pozzo della passerella, che lascia
0,87 m di raggio. Un 40 cm f/4,5 ha 1800 mm di focale e due metri di tubo: non ci passa.
Quello che ci passa, ed è altrettanto tipico di un osservatorio comunale italiano degli anni
'80, è un **Newton da 30 cm f/5** — 1500 mm di focale, tubo 1,55. Con la **SBIG ST-8** (pixel
da 9 micron) fa **1,24"/pixel** e **32'x21'** di campo: campionamento giusto per un seeing di
2-3", e un campo più generoso di quello che avrebbe dato il 40 cm.

**La camera raffreddata era in vendita, e la fase 3 la dava per presente.** Federico ha
scelto: la ST-8 è raffreddata dalla prima notte, e l'upgrade diventa un **raffreddamento
migliorato** — ventola supplementare e dissipatore, che scende più giù e ci resta anche nelle
notti tiepide. Una fase che esiste solo dopo un acquisto sarebbe stata la prima del gioco a
non esistere all'inizio.

**L'albero degli upgrade comprava fasi che non ci sono più.** Livella motorizzata,
contrappesi calibrati, software di polar align: tre acquisti su dieci per le tre fasi tolte
da D-168. Rifatto sulle dieci fasi nuove, con due chicche: il **comando del portello dalla
sala** (l'automazione che D-171 ha appena tolto di mano al giocatore, e che qui si può
ricomprare) e l'**encoder di azimut** che fa inseguire la fessura. E una correzione di
periodo: la maschera per il fuoco era una **Bahtinov**, inventata nel 2005 — nel '99 si usava
la **maschera di Hartmann**, che è vecchia di un secolo.

**I prezzi: due scale diverse, e adesso è scritto.** Federico ha scelto la via di mezzo, e
ha ragione. Moka, stufetta, cataloghi su CD, abbonamenti: prezzi veri del 1999, e lo erano
già. L'attrezzatura grossa no — una ST-7 stava sui cinque milioni di lire, e le foto
astronomiche amatoriali in Italia non le pagava quasi nessuno: le riviste pubblicavano
quelle dei lettori gratis. Ai prezzi veri servirebbero diciassette notti su venti per un solo
upgrade, e l'albero morirebbe. La cura vera non sarebbe alzare i ricavi ma **cambiare la
fonte** — stipendio del Comune, commesse a qualità, usato sulla BBS — ed è una riscrittura
dell'economia che non si fa di passaggio. Nel frattempo il GDD **dichiara** di tenere due
scale, invece di lasciar credere che sia ricostruzione: chi conosce il periodo se ne
accorgerebbe comunque, e una finzione dichiarata non è un errore.


## D-171 — Il portello si apre dal quadro in cupola, non dal computer

**1 settembre 2026.** «Sistema entrambe le cose: metti una pulsantiera a muro con due
bottoni.» La fase 1 lascia il CRT dopo tre giorni di vita.

**Perché era sbagliata.** Comandare una cupola dal PC della sala controllo, nel 1999, si
poteva fare: si chiamava Digital Dome Works, ed era roba da osservatorio ricco. A Monte San
Lorenzo il portello si apre da un quadro a muro, sotto il portello che si muove. Era il
punto meno vero di tutto l'impianto, e l'avevo dichiarato tale prima che me lo chiedesse.

**Che cosa si guadagna, oltre alla verità.** La sera comincia **alzandosi**, non sedendosi. Il
CRT resta spento finché la cupola non è aperta — questa è la prima fase del gioco che
restituisce `null` da `screen()` — e il giocatore vede la cupola aprirsi sopra la propria
testa mentre tiene premuto, che è un indicatore di corsa migliore di qualunque barra. La fase
si chiude **da sola** a fine corsa: non c'è più niente da confermare, perché quello che si
vede è già la conferma.

**Il pannello disegnato non è stato buttato.** `dome_screen.gd` resta nel repository: è
esattamente ciò che comparirà sul CRT il giorno in cui si comprerà il comando del portello
dalla sala controllo — l'upgrade della fase 1 nel nuovo albero (D-170). Il lavoro fatto
diventa il contenuto di un acquisto, non codice morto.

**Come si chiude il giro senza rompere i confini.** `world/` non può nominare `phases/`, e la
fase non può cercare un oggetto del mondo. Sul bus viaggiano due FATTI e nessun comando: il
quadro dice che una mano tiene premuto (`dome_button_changed`), la fase dice dove sta il
battente (`dome_aperture_changed`). Il quadro non sa che esista una fase; la fase non sa che
esista un quadro. `runs_in_background()` diventa `true`, e qui è obbligatorio: il giocatore è
in cupola, non alla postazione, e una fase sospesa a sedia vuota non riceverebbe mai niente.

**Il vincolo che fa esistere il quadro** è che non lo si possa usare da lontano: si prende
con `E`, e chi si allontana oltre due metri se lo ritrova lasciato. Senza, si prende il
quadro, si scende in sala controllo e si comanda la cupola da seduti — cioè si riottiene
gratis l'automazione che questa decisione ha appena tolto.

**Due difetti trovati misurando, e nessuno dei due si vedeva dal codice.**

*Il quadro era finito dentro il vano della porta.* L'avevo messo a x = 1,20 deducendo la
posizione della porta dalle tuple di `geometria.py` — che dicono dove un vano **comincia**,
non dove finisce. Il montante sta a 1,47. La sonda adesso stampa che cosa c'è **intorno** al
quadro e a che distanza, e da lì il numero giusto (2,10) è uscito in un colpo: interruttore
della luce a 1,63, quadro a mezzo metro più in là, così la mano che cerca la luce non trova
il comando della cupola.

*Il vincolo di distanza misurava in linea d'aria.* Il quadro sta a 1,35 di altezza e il
giocatore ha l'origine ai piedi: chi gli stava davanti **a un metro e mezzo** risultava a
2,02 metri, e il quadro gli si staccava di mano mentre lo stava guardando. Il dislivello fra
i piedi di uno e un oggetto appeso al muro non è distanza, è altezza: si misura sul
pavimento. Trovato solo perché la sonda ha provato a scattare da un metro e mezzo invece che
da novanta centimetri.

**La sonda ha sbagliato due volte a fotografare, e vale la pena scriverlo** perché è lo
stesso errore in due forme: la prima foto guardava in orizzontale e ha inquadrato la porta
accanto; la seconda, corretta con un `look_at` sul quadro, ha inclinato tutto il corpo del
giocatore e ha fotografato il **soffitto** — la camera sta un metro e settanta sopra i piedi,
e un beccheggio di quindici gradi lassù diventa un tetto. Un bersaglio alla quota del corpo,
e il quadro entra in campo da sé.

**Il modello vero arriverà col pack di texture.** Per adesso il quadro è tre primitive nel
blockout, con la cassa chiara e i pulsanti scuri — un quadro che ha lo stesso valore del muro
è una macchia che non si trova. Il riferimento visivo è su Sketchfab: *Old Soviet Electrical
Junction Box (220V)* di uliana (CC-BY, 1712 facce), che è esattamente la scatola verniciata
grigio-verde con la targa e il triangolo che starebbe su quel muro. Sta in CREDITI.md come
riferimento, non come asset: non è stato scaricato né usato.


## D-172 — La fase 3: il mestiere non è aspettare, è scegliere quanto chiedere

**1 settembre 2026.** Terza fase del nuovo elenco (D-168): il raffreddamento della camera.

**Il pericolo era l'attesa vuota.** «Imposti la temperatura e aspetti» è una fase che si
gioca da sola, e le fasi che si giocano da sole sono tempo che il giocatore paga senza
decidere niente. La decisione c'è, ed è una sola: **quanto freddo chiedere**. Il rumore del
chip si dimezza ogni sei gradi in meno, quindi più giù è meglio; ma un Peltier scende di
trentotto gradi sotto l'ambiente e non di più, e quello che gli chiedi oltre non lo ottiene —
resta al massimo, non ci arriva, e la temperatura ondeggia. Una temperatura che ondeggia non
è un dettaglio: i dark si scattano alla stessa temperatura delle pose, e una serie presa
mentre il sensore balla non corrisponde più a niente.

**Come si capisce dov'è il limite: guardando la percentuale, non la temperatura.** Il
pannello mostra quanto sta lavorando la cella, ed è l'unica lettura che dice se quello che
hai chiesto si può TENERE. Nessuno scrive da nessuna parte che sopra il novanta per cento non
si regge — non c'è nemmeno una tacca sulla barra — e si impara vedendo la temperatura
ballare. È la stessa diagnosi della fase 2, con un numero al posto di una porta muta.

**`runs_in_background()` è `true`, e questa è la fase che se lo merita.** Imposti il setpoint
e mentre il sensore scende vai a fare il caffè. È quello che fa chiunque abbia mai
raffreddato una camera.

**Il punteggio conta i gradi scesi DALLA PARTENZA, non una temperatura assoluta**, e questa
è la scelta che rende la fase a prova di meteo. La fase non sa quanto faccia freddo in
cupola — non ha nessun campo che lo contenga: chiede a `truth` la temperatura di partenza,
che con la cella spenta è quella dell'ambiente, e conta da lì. Il giorno in cui la notte
avrà un tempo atmosferico, questa fase non cambierà di una riga.

**Due fattori che si moltiplicano, e non si sommano.** Freddo per stabilità. Una temperatura
bassissima che balla non vale «un po' meno» di una buona: non vale niente, perché i dark non
corrisponderanno. Il prodotto è l'unica forma che dice questo.

**Tre difetti trovati misurando, e nessuno si vedeva dal codice.**

*Il sensore nasceva a zero gradi.* `_temperature` partiva dal valore di default della
variabile invece che dall'ambiente, e il punteggio contava i gradi scesi da uno zero
inventato: chiedendo meno ventotto ne mancavano tre per il pieno, e il referto diceva 87
invece di 100. La cura non è stata scrivere il numero nella fase — sarebbe stata la fase a
decidere un'osservazione — ma aggiungere `ambient_temperature()` al contratto della
sorgente. È il termometro della camera, ed è la prima cosa che una sorgente bugiarda vorrà
falsificare.

*Chiedere troppo non si pagava.* La prima stesura faceva ondeggiare la temperatura di mezzo
grado ogni undici secondi, e il referto diceva «cella al 100%, temperatura ferma, punteggio
pieno» — il contrario di quello che la fase deve insegnare. Il colpevole non era la soglia
ma la fisica: il sensore ha una costante di tempo di sei secondi e si comporta da filtro, e
un'oscillazione più rapida della propria inerzia la smorza a un quarto. La cura è anche più
vera: una cella satura non oscilla per conto suo, **segue l'ambiente** — il vento gira, la
cupola si muove di un grado in mezzo minuto, e senza margine di regolazione il sensore se lo
porta dietro tutto. Un grado e due ogni ventisei secondi, e adesso si vede.

*La finestra di stabilità era troppo corta.* A sei secondi, chi confermava mentre la
temperatura passava per il massimo la trovava ferma e si portava via il pieno di una camera
che stava ballando. Dieci secondi, e non c'è più nessun istante del ciclo in cui sembri
stabile. Il numero non è a gusto: viene dal periodo della deriva.

**Le misure, dalla sonda `tools/prova_freddo.tscn`.** Chiedendo **meno ventotto** — cella
all'89%, dentro i margini — si arriva a **100 in quaranta secondi**. Chiedendo **meno
quarantacinque** — cella al 100%, impossibile — nei venticinque secondi successivi alla
stabilizzazione il punteggio oscilla **fra 0 e 55**: non si prende un buon voto nemmeno
scegliendo l'istante migliore. Ed è così che la sonda deve giudicare una cosa che ondeggia:
non «quanto vale adesso» ma «quanto può valere al massimo», che è ciò che farebbe un
giocatore che aspetta il momento buono per premere INVIO.

**Il limite dichiarato, ed è lo stesso del fuoco:** finché l'ambiente è fisso nel `.tres`, il
setpoint migliore è sempre lo stesso e chi gioca molte notti lo impara. La cura non è un
numero casuale, è il meteo — e quando ci sarà, arriverà da lì con una riga sola.


## D-173 — Il fosforo diventa ambra, e smette di stare in tredici posti

**1 settembre 2026.** «Mettilo ambra, e anche la luce che emette deve essere di quel
colore.» Federico ha guardato tre scatti dello stesso pannello dentro il monitor — verde,
blu DOS, ambra — e ha scelto.

**Perché ambra, e non è gusto.** Chi lavora di notte non guarda uno schermo luminoso:
l'occhio ci mette venti minuti ad adattarsi al buio e un lampo di bianco glieli azzera. È
per questo che le sale di controllo degli osservatori hanno le luci rosse, ed è per questo
che un monitor monocromatico caldo era la scelta di chi poi doveva salire in cupola e vedere
qualcosa. Il fosforo P3, l'ambra, esisteva ed era comune quanto il P1 verde. Il blu DOS era
il più leggibile dei tre e il più vero come *software* — nel '99 quello girava in DOS — ma è
anche il più luminoso, e in una stanza buia è la scelta peggiore.

**La palette stava in tredici file.** Sei fasi, terminale, BBS, menu post-foto, riepilogo,
vendita, stacking: ognuno dichiarava le stesse quattro `Color` copiate a mano. Finché la
palette non cambia sono solo tredici copie brutte; il giorno in cui cambia sono tredici
occasioni di dimenticarne una, e la schermata dimenticata resta di un altro colore per
sempre senza che nessun collaudo se ne accorga. Adesso c'è `core/phosphor.gd`, e sta in
`core/` e non in `crt/` per la tabella dei confini: `phases/` può vedere solo `core/`.

**La luce che il monitor butta nella stanza è cambiata con lui**, e la regola era già
scritta: la luce di un monitor è quello che il monitor emette. Il colore passa
dal grigio-verde all'ambra pallido, e l'energia da 0,14 a 0,17 — un colore più saturo ha
meno luminanza (0,81 contro 0,97), quindi a parità di energia illumina un quinto in meno.

**Il difetto che ha richiesto due ore invece di dieci minuti: il colore giusto usciva
sbagliato.** Un ambra scritto come lo si vuole — `Color(1.0, 0.75, 0.32)` — dentro il
monitor appariva **giallo crema**. Ho provato ad abbassare il guadagno dello shader, a
saturare di più, a cambiare il tint del vetro: tutto inutile, perché stavo curando il
sintomo. La diagnosi è arrivata da due immagini della stessa cosa: **il pannello fotografato
fuori dal mondo 3D era ambra perfetto**, lo stesso pannello dentro il monitor era crema. Il
colpevole è il **tonemapping ACES** della scena, che comprime i valori alti e nel farlo
sposta gli arancioni verso il giallo. La cura è pre-compensare — i numeri in `phosphor.gd`
sono più rossi e meno verdi di quello che si vuole ottenere — e la riga che lo spiega sta in
testa al file, perché senza qualcuno li «correggerà» e rifarà tutto il giro.

**Il guadagno dello shader scende da 1,15 a 1,0**, e non è cosmesi: sopra 1 il canale rosso
dell'ambra saturava, e ACES trasformava la saturazione in giallo. Con il rosso sotto la
soglia il colore resta quello che è.

**Come si giudica questa palette:** sempre dentro il monitor, mai a schermo pulito. Le due
viste non sono la stessa immagine, e la differenza fra loro è esattamente il difetto che ha
mangiato il tempo.


## D-174 — Due pulsanti veri, e la sonda che saltava il pezzo che si rompeva

**1 settembre 2026.** «Stavo testando il quadro della cupola: non funziona, e non si
capisce.» Aveva ragione su tutti e due i punti, e i due difetti erano lo stesso difetto.

**Non funzionava, e la sonda diceva di sì.** `tools/prova_quadro.tscn` chiamava
`interact()` sul quadro **a mano**, saltando il raggio con cui il giocatore trova le cose.
Verde su tutta la linea, e in gioco niente. Le due cause, misurate dopo aver rifatto la
sonda con un raggio vero: il raggio dell'interazione arriva a **1,20 m** e il quadro stava a
**1,35 m di altezza**, cioè sotto la linea di mira di chi guarda avanti — per trovarlo
bisognava abbassare lo sguardo di venti gradi; e la fase 1, finita dopo la prima apertura,
si portava via il comando, quindi tornando in cupola più tardi i pulsanti erano inerti.

**Una sonda che salta il pezzo che si rompe non è una sonda.** È la lezione che vale più del
resto: chiamare direttamente il metodo che il gioco raggiunge attraverso una catena — raggio,
prompt, azione — collauda il metodo e non la catena. La sonda nuova mette la testa del
giocatore davanti al pulsante, gli fa mirare, e tiene premuto `E`. Ha trovato subito anche un
terzo difetto che nessuno aveva visto: dopo il teletrasporto la capsula si assesta sul
pavimento di un centimetro, e una mira fatta un fotogramma prima passa **quattro gradi**
sopra il bersaglio.

**Non si capiva, ed era un giudizio giusto.** «Un quadrato con due pallini»: due cilindri
grigi su una scatola grigia, senza scritte e senza colore. Nessuno ci vedrebbe un comando.
Adesso i pulsanti sono **due oggetti distinti**, si mirano uno per uno, e ciascuno ha:

- un **colore** — verde per APRE, rosso per CHIUDE, con un filo di emissione perché in una
  cupola al buio un verde spento e un rosso spento sono due dischi neri;
- una **targhetta scritta**, `Label3D`, perché un pulsante senza targhetta è un pallino e un
  pallino non dice che cosa fa;
- un **prompt suo** — «Apri la cupola», «Chiudi la cupola» — invece di un generico «usa il
  quadro»;
- e il **cappello che rientra di dodici millimetri** mentre lo tieni premuto: è l'unico modo
  che ha di dire «ti ho sentito» a chi lo guarda da mezzo metro.

**Il gesto cambia, ed è quello standard**: miri il pulsante e tieni premuto `E`. Prima
bisognava «prendere» il quadro con `E` e poi comandarlo con le frecce della tastiera — un
comando che sta nel mondo si preme dove sta, non da tastiera.

**Il quadro adesso funziona anche a fase finita**, e per farlo il battente ha dovuto
prendersi una responsabilità in più: quando nessuna fase della cupola è viva, è
`world/dome_shutter.gd` a integrare il comando dei pulsanti. Questo file **nomina la chiave
di una fase** — l'unica eccezione alla regola per cui `world/` non sa che `phases/` esista —
e la ragione è concreta: finché la fase è viva è lei a possedere l'apertura (ADR-001), e due
integratori sullo stesso motore vorrebbero dire una cupola che va a doppia velocità. Si
nomina la chiave e non si chiama niente. Il prezzo dichiarato è che la velocità del motore
adesso è scritta in due posti, e il banco ne misura uno solo.

**E le scritte uscivano specchiate.** «ERPA» invece di «APRE»: un `Label3D` si legge dal
proprio +Z, e lasciato dritto guarda dalla parte sbagliata. Non lo dice nessun errore e non
lo prende nessun collaudo numerico: si vede guardando la foto, ed è per questo che la sonda
scatta una foto invece di limitarsi a contare.


## D-175 — Non un quadro a muro: una pulsantiera che penzola

**1 settembre 2026.** «Nessuno dei due modelli funziona. Mi servono altri siti oltre a
Sketchfab. Forse ho cercato male?» Aveva cercato male tutti e due — io per primo.

**La parola sbagliata era «panel».** Cercavo «control panel» e «industrial button», e quelle
due parole restituiscono scatoloni da parete. L'oggetto che serviva ha un altro nome: è una
**pulsantiera pensile**, quella dei paranchi e dei montacarichi, e in inglese la si trova
sotto *elevator*, *lift call button*, *pendant station*. Cambiata la parola, i risultati
cambiano del tutto. È il difetto di ricerca più banale che ci sia, e mi è costato due giri.

**Sui siti alternativi, il referto onesto.** Poly Haven non ha niente (interrogata: solo
`Power Box 01` e `Utility Box`, scatole elettriche senza pulsanti). Free3D risponde 403,
Open3DModel dà zero risultati. Fab e BlenderKit — le due alternative vere — bloccano il
browser automatico con Cloudflare, quindi da lì non ho potuto verificare nulla e non ho
mandato link. Quello che **ha** funzionato è un tipo di fonte diverso: **TraceParts**, il
CAD dei costruttori, dove la Schneider Harmony **XAC-A (XACA271)** c'è con le sue quote.

**E allora si è modellata, che è l'eccezione e non la regola.** Su Sketchfab la pulsantiera
pensile non esiste: sei formulazioni diverse dell'interrogazione — «crane pendant control»,
«hoist remote control», «pendant station», «winch remote» — danno zero risultati pertinenti.
Ma qui modellare è lecito per una ragione precisa: **la forma non è inventata**. È un
oggetto documentato di cui ho la foto di catalogo e le quote, ed è fatto di quattro volumi —
scatola stondata, soffietto, due tasti Ø22, cavo. Trecentoventi facce. La differenza fra
questo e il «quadrato con due pallini» di D-174 non è l'abilità: è che quello copiava
un'idea vaga di quadro, questo copia un pezzo che esiste.

**Perché pensile è meglio di murale, e non è una resa.** Un quadro avvitato obbliga a stare
dove sta lui. La cupola la si guarda aprire da sotto, muovendosi: una pulsantiera la si
prende in mano e la si porta dove si guarda. È esattamente il motivo per cui nei capannoni
si usa quella.

**Verde e rosso contro il vero.** Sull'oggetto reale i due cappucci sono neri tutti e due, e
li distingue solo la freccia. Qui APRE è verde e CHIUDE è rosso: è una bugia deliberata,
perché due dischi neri identici a un metro e mezzo sono la stessa incomprensibilità di
prima. Le frecce restano — sono loro a dire **quale verso**, il colore dice solo **quale dei
due**.

**IL TASTO VERDE NON C'ERA, E SEMBRAVA UN PROBLEMA DI COLORE.** Nel primo scatto in gioco
APRE era invisibile: un buco nero nella targhetta nera. La prima diagnosi — «il verde sotto
la luce ambrata non riflette niente» — era vera e non era la causa. La causa è che
`TRAVEL` valeva **12 mm su un cappuccio che ne sporgeva 8**: premuto, il tasto rientrava
*dietro* la propria targhetta e spariva. Nessun controllo lo vedeva — risultava schiacciato,
si rialzava, la cupola si apriva — perché la corsa era giusta come *comportamento* e
sbagliata come *geometria*. Adesso la sonda misura sulle mesh quanto il cappuccio avanza
oltre il pezzo nero più avanzato e pretende che sia più della corsa; alzando `TRAVEL` a 12
il controllo grida. La luce ambrata resta un problema vero, e si paga con un filo di
emissione sui due cappucci: 0,45, che legge come colore e non come spia accesa.

**E il verso era di nuovo sbagliato, al contrario di prima.** Il quadro vecchio aveva la
faccia sul proprio −Z, il modello importato ce l'ha sul +Z: copiando la riga di rotazione
di D-174 la pulsantiera si è trovata rivolta verso l'intonaco, con i tasti sepulti nel muro
— **e si premevano lo stesso**, perché il raggio del giocatore li colpiva da dietro. Tutti i
controlli passavano. Adesso la sonda tira un raggio dal centro del tasto nel verso in cui il
cappuccio sporge e pretende di trovare aria: con la rotazione sbagliata trova il muro a un
centimetro. Terza volta che un comando montato al contrario passa i collaudi: il difetto non
è la rotazione, è che nessuno chiedeva mai **da che parte guarda**.

**Dondola, e non serve a niente.** Un pendolo smorzato vero — ω' = −(g/L)·sin θ − c·ω,
integrato in tre sottopassi perché a trenta fotogrammi Eulero esplicito *guadagna* energia e
invece di fermarsi sbandiera. Oscilla parallela al muro e non perpendicolare, o a metà corsa
entrerebbe nell'intonaco. Non cambia nessun esito ed è esattamente per questo che si nota:
è l'unica cosa nella stanza che risponde a chi la tocca.


## D-176 — Il dettaglio che ruba l'attenzione è un difetto

**1 settembre 2026, poche ore dopo D-175.** Provata in gioco: «il dondolare è una roba
atroce, uno crede di dover continuare a guardare e premere ogni volta».

**Il pendolo era realistico e sbagliato, e la differenza sta in dove va a finire il
bersaglio.** Oscillando, il tasto si sposta sotto il mirino: il raggio lo perde e lo
ritrova, e a ogni oscillazione il prompt sparisce e ricompare. Quel lampeggio il giocatore
lo legge come «non ha funzionato, ripremi» — così molla, ripreme, e intanto la cupola si
stava già aprendo. Un dettaglio che porta via l'attenzione dalla cosa per cui la stanza
esiste non è un dettaglio riuscito, è un difetto con una bella motivazione.

**Al suo posto un tremito, ed è stato Federico a proporlo.** La differenza non è di
ampiezza, è di natura: il dondolio sposta il centro, e dopo un secondo bisogna rimirare; il
tremito oscilla **attorno** al centro di un millimetro e mezzo, e il bersaglio resta dov'è.
E trema **solo mentre il motore gira**, che è anche l'unica cosa vera — la vibrazione non ce
l'ha la pulsantiera, ce l'ha il motore, e le arriva su per il cavo. Quindi il momento in cui
un tremito darebbe fastidio alla mira, cioè quando si mira, è esattamente quello in cui non
c'è. Due frequenze non commensurabili (17 e 23,5 Hz) perché una sola si riconosce come
animazione dopo mezzo secondo.

**IL PROMPT SPARISCE MENTRE TIENI.** «[E] Apri la cupola» scritto mentre la cupola si sta
già aprendo è una riga che chiede di fare quello che stai facendo: l'interfaccia contraddice
il mondo. Sparendo dice l'unica cosa vera — adesso tocca a te tenere e guardare. Si ottiene
stringendo `can_interact()`, che è quello che `Interactable` chiede alle sottoclassi, e la
riga torna da sé al rilascio perché è funzione del raggio, non uno stato.

**Il quadrato giallo, e cosa lo fa smettere di esserlo.** Non è la geometria grossa: sono le
giunzioni e le viti. Quattro viti agli angoli della targhetta (una placca senza viti è un
adesivo), la targhetta del costruttore rientrata — senza scritte, perché da mezzo metro
nessuna scritta si legge e quello che si legge è che una targhetta *c'è* —, la linea di
giunzione dei due semigusci dello stampo, il collare del soffietto. Ottocento facce invece
di trecento.

**LA TRAMA VA MOLTIPLICATA, MA NON QUESTA.** La mappa `plastica` è beige carico: in lineare
(0,61 0,52 0,29). Una plastica **colorata in massa** non ha disegno, ha superficie, e
moltiplicare quella mappa vira tutto verso il caldo — la scatola di derivazione, che è PVC
grigio, è uscita olivastra. Per riportarla neutra il canale blu avrebbe dovuto valere 1,02,
cioè saturare: **quando la correzione supera l'uno, la mappa è quella sbagliata**. Adesso
esiste `SOLO_RILIEVO`, che collega normale e ruvidezza e lascia stare il colore — il granulo
dello stampo sta lì, ed è neutro per costruzione.

**Il cubo grigio in cima è diventato l'impianto.** Scatola di derivazione con coperchio
riportato, quattro viti, pressacavo di gomma sotto, corrugato flessibile che sale e poi
prosegue in tubo rigido fino alla gronda, con due collari di fissaggio. La prima versione
del tubo piegava dentro il muro dopo venti centimetri: giusto sulla carta, e invisibile in
gioco, perché **il muro sta dietro la pulsantiera** e la piega è rivolta via dalla camera. In
gioco restava un tubo tagliato a metà in aria. Un dettaglio che regge solo da
un'angolazione è un difetto.

**E la sonda adesso scatta due foto.** La scatola sta un metro sopra i tasti: inquadrando il
pulsante non ci si vede mai, ed è per questo che è rimasta un cubo grigio per un giro intero
— nessuna foto la conteneva.

**UN CONTROLLO SI È INDEBOLITO DA SOLO, ed è la cosa più istruttiva del giro.** Il controllo
sulla sporgenza del cappuccio misurava contro il materiale `Gomma`, che *era* la targhetta.
Separando i neri — soffietto di mescola, targhetta di ABS — la targhetta è diventata
`PlasticaNera` e il confronto è scivolato sul soffietto, trenta centimetri più in su: la
«sporgenza» è passata da 9 mm a 23, e il controllo continuava a dire ok senza più guardare
niente. Un controllo che si indebolisce da solo è peggio di uno che manca: quello che manca
almeno si vede. Se ne è accorto solo il numero stampato nel referto, che è il motivo per cui
i referti stampano i numeri e non solo «ok».


## D-177 — Un transitorio non e' un moto

**1 settembre 2026, subito dopo D-176.** «Una leggerissima vibrazione e solo all'inizio,
non sti spasmi come se stesse per avere un ictus.» Terza versione dello stesso dettaglio, e
le prime due sbagliavano per la stessa ragione: **il movimento durava**.

Il pendolo di D-175 durava per sempre e spostava il bersaglio. Il tremito di D-176 durava
tutti i sei secondi dell'apertura con ampiezza dieci volte questa, e a schermo era una
convulsione. Quello che serviva non era un moto piu' piccolo: era un **evento**. Un motore
che parte da' uno strappo e poi si regolarizza - mezzo millimetro, tre decimi di secondo,
sparito. Un evento non ha il tempo di dare fastidio a niente.

**E si spegne anche se tieni premuto**, che e' la differenza che conta: la vibrazione non
racconta «il motore sta girando», racconta «il motore e' partito». Del fatto che stia
girando se ne accorge gia' chi guarda la cupola aprirsi, che e' dove deve stare l'occhio -
ed e' l'intera ragione per cui questo comando esiste in cupola e non sul PC.

**IL CONTROLLO CHE MANCAVA ERA LA SECONDA META'.** La sonda pretendeva che il comando
tremasse mentre il motore girava, e la versione buttata quel controllo lo passava: tremava
eccome. Adesso ci sono due finestre - deve muoversi nei primi quattro decimi e deve stare
fermo dopo un secondo, col tasto ancora premuto - e sono i due lati della stessa domanda.
Allungando lo spegnimento da 0,085 a 8,5 secondi il secondo controllo grida.

E' la stessa forma del controllo «a riposo sta fermo» accoppiato a «alla partenza da' uno
scatto»: un solo controllo su un movimento e' quasi sempre meta' della specifica, perche'
un movimento si descrive con quando c'e' **e** con quando non c'e'.


## D-178 — Nero e guasto si somigliano troppo

**1 settembre 2026.** «Non va piu' il computer: posso solo sedermi li' e c'e' il monitor
blank che non fa niente.»

**Il gioco non era rotto, ed e' questa la parte interessante.** La fase della cupola non ha
schermo per una decisione presa apposta (D-171): il PC del '99 non sa che la cupola esista,
quindi finche' non e' aperta il CRT non ha niente da mostrare. Chi si siede prima di essere
salito in cupola vede quindi un monitor **nero** — e nero, per chi guarda, e' esattamente
quello che fa un computer guasto. La decisione era giusta e la sua conseguenza visiva era
indistinguibile da un difetto.

**Al posto del nero c'e' il prompt.** La macchina e' accesa, nessuno ha ancora avviato il
programma della notte, e un PC del '99 acceso e fermo mostra `C:\OSSERV>` col cursore che
batte. Non e' una toppa: e' quello che c'era davvero. Il monitor adesso dice «io funziono,
non sto facendo niente» invece di non dire niente.

**E non nomina la cupola, deliberatamente.** Lo schermo di riposo vive in `crt/`, non in
`phases/`, e non sa quale fase stia girando: e' una proprieta' del monitor. Se scrivesse
«apri la cupola» il PC saprebbe della cupola, e la decisione D-171 salterebbe da qui di
sbieco senza che nessuno l'abbia riaperta. Resta aperta la domanda se il gioco debba
insegnare al giocatore che la sera comincia in cupola: quella e' una scelta di
accompagnamento, e va presa guardandola in faccia.

**E LA SONDA DEL VETRO ERA CIECA DA DUE GIRI.** `prova_vetro` si piazzava davanti al
pulsante usando `-basis.z`, il verso del quadro di primitive; la pulsantiera modellata ha la
faccia sul `+Z` (D-175). Con il segno vecchio la sonda finiva **dentro il muro**, il raggio
del giocatore sbatteva nell'intonaco, il pulsante non veniva premuto mai, la fase 1 non
finiva e il referto diceva «battente 0.000, pulsante premuto false» per novanta secondi. Due
sonde con lo stesso difetto: l'avevo corretto in una sola.

**IL CONTROLLO NUOVO E' PASSATO COL DIFETTO DENTRO, ed e' la lezione del giro.** Scritto
come soglia — «almeno l'uno per cento di pixel accesi» — rimettendo il vetro nero ha
risposto «acceso, 100%». Un `SubViewport` senza nessun Control dentro **non e' nero**: e' il
colore di sfondo del progetto, cioe' un campo uniforme e chiaro. Quello che distingue uno
schermo che disegna da uno che non disegna non e' la luce, e' il **contrasto**: del testo su
fosforo accende qualche punto per cento e lascia scuro il resto. Adesso il controllo pretende
una BANDA, fra l'uno e il sessanta per cento, e un campo uniforme lo fallisce da tutte e due
le parti.

Sono due iniezioni nello stesso giro — questa e quella del tremito che non si spegneva — e
tutte e due hanno trovato un controllo che diceva ok. Un controllo va provato contro il
difetto per cui esiste, sempre: quello scritto e non provato e' una riga che rassicura.


## D-179 — Un numero che non cambia quando si cambia la causa non sta misurando quella causa

**1 settembre 2026.** «Quando entro nell'osservatorio le ombre sfarfallano e poi si
stabilizzano, non riesco proprio a capire perche'.» Non l'ho capito nemmeno io, e questa
voce serve a scrivere che cosa **non** e', perche' il prossimo che ci mette le mani non
rifaccia le stesse quattro misure.

**Tre porte chiuse, con i numeri.**

*Succede stando fermi?* No. Piantato nello stesso punto per **556 fotogrammi**, con la posa
riscritta a ogni frame perche' nemmeno l'assestamento della capsula potesse passare per
sfarfallio, l'immagine non e' cambiata di **un livello su 255**. Cadono la lampada della
cucina che lampeggia per copione — con undici metri di portata arriva in mezzo edificio — e
il renderer che rimesta stando li'.

*Le ombre si assestano dopo essere arrivati?* No. Saltando di colpo dalla postazione alla
cupola, il primo fotogramma e' ancora quello vecchio e **dal secondo in poi l'immagine e'
gia' quella a regime**, identica per due secondi e mezzo. Niente converge.

*E' la compilazione delle pipeline?* No, e sarebbe stata la risposta piu' probabile:
in Godot e' la causa piu' comune di «sfarfalla e poi si stabilizza», perche' ogni
combinazione nuova di mesh, materiale e luce va compilata la prima volta che entra in campo.
Attraversando l'edificio tre volte, il **primo** passaggio e' il piu' liscio di tutti (7,0 ms
di media, picco 7,8) e gli scatti isolati stanno nel secondo e nel terzo. E' il contrario
esatto della firma della compilazione.

**E UN SOSPETTO SCARTATO, che e' la parte che vale.** La sonda diceva che allo stesso
angolo due giri di testa danno immagini diverse — **72 pose su 89** — e la foto sembrava
confermarlo in modo spettacolare: le ombre sul muro sfocate al primo giro, nette al secondo.
Sembrava l'atlante delle ombre che riassegna le tessere, e la spiegazione era buona:
diciassette luci fanno ombra, e le tessere grandi sono quattro per quadrante.

Era la sonda. Tre indizi, in ordine di forza:

- cambiando i quadranti dell'atlante in **tre modi diversi**, lo scarto peggiore restava
  **12,744 livelli identico a tre decimali**;
- restava identico anche mettendo il gioco **in pausa**, con la logica ferma;
- due pose **consecutive** dello stesso giro differiscono di **11,3 livelli**, cioe' lo
  stesso ordine di grandezza dello scarto fra i giri.

Il conto torna: l'immagine che si legge in `_process` e' quella del fotogramma precedente, ma
il ritardo **non e' sempre di uno**, e un confronto disallineato di un fotogramma mette a
paragone due angoli diversi. La sonda stava misurando la propria rotazione e chiamandola
sfarfallio.

**LA REGOLA CHE NE ESCE:** un numero che non cambia quando si cambia la causa non sta
misurando quella causa. Ho cambiato l'atlante tre volte e ho messo il gioco in pausa: quattro
interventi enormi, e il numero non si e' mosso di un millesimo. Quello e' il momento in cui
si smette di credere alla propria misura, non quello in cui si cerca una spiegazione piu'
ingegnosa. Il referto adesso stampa da se' i due numeri di controllo — la stessa posa contro
se stessa (dev'essere zero) e due pose vicine (quanto vale un passo) — cosi' che chi legge
veda subito quando il confronto non dice niente.

**Cosa resta da provare**, e non si puo' fare da qui: la camminata vera con la fisica e il
mouse, e i parametri delle ombre morbide. Ogni plafoniera ha `light_size = 0.35` con
`shadow_blur = 1.2`: la penombra viene stimata cercando gli occlusori, e una stima che cambia
col punto di vista da' ombre che nuotano mentre ci si muove e si fermano quando ci si ferma —
che e' il sintomo, parola per parola. E' il primo esperimento da fare, ed e' un numero solo.


## D-180 — «Solo al primo ingresso» e' un'informazione, non un contorno

**1 settembre 2026, seguito di D-179.** Alla domanda «succede ogni volta o solo la prima?»
la risposta e' stata: **solo al primo ingresso**. Quella riga vale piu' di tutte le misure
del giro precedente, perche' dice che il costo si paga UNA VOLTA per sessione — e le cause
che si pagano una volta sola sono poche e conosciute.

**E ha smontato la mia conclusione precedente.** In D-179 avevo scritto «non e' la
compilazione delle pipeline» perche', attraversando l'edificio tre volte, il primo passaggio
era il piu' liscio. Sbagliato, e per un motivo imbarazzante: la sonda aspettava **un secondo**
prima di cominciare a misurare, e in quel secondo la compilazione era gia' avvenuta.
Misuravo il secondo passaggio chiamandolo primo. Tolto il riscaldamento:

    giro 1: 10,0 ms di media, quattro fotogrammi sopra i 20: 120, 97, 34, 21
    giro 2:  7,0 ms, nessuno
    giro 3:  7,0 ms, nessuno

Un fotogramma da 120 ms mentre la telecamera si muove e' un decimo di secondo di immagine
ferma: tutto salta, e la cosa che salta in modo piu' vistoso sono le ombre, che sono macchie
larghe e sfumate. Poi non succede mai piu'. E' il sintomo, parola per parola.

**IL RIMEDIO OVVIO NON FUNZIONA, e l'ho misurato invece di darlo per buono.** Un
riscaldamento all'avvio — telecamera nascosta che guarda i centri di otto vani in quattro
direzioni, `force_draw(false)` cosi' non si presenta niente a schermo — costa **2.255 ms** e
compila davvero. Poi:

    entrando nel bagno (che dalla postazione non si vede), a motore caldo:
      col riscaldamento:     39 ms di picco
      senza riscaldamento:   38 ms di picco

Due secondi e mezzo di avvio in piu' per un millisecondo. **Buttato.** Un rimedio che non si
misura e' un rimedio che si spera, e la tentazione di tenerlo — «male non fa» — e' esattamente
il modo in cui un progetto accumula peso senza accumulare qualita'.

Il perche' e' istruttivo: dopo un secondo e mezzo dall'avvio **tutto e' gia' compilato**, che
si sia guardato o no. La cache degli shader su disco fa il resto fra una sessione e l'altra.
Quello che resta caro sono i **primi fotogrammi in assoluto** — 96, 137, 57 ms ai passi 0, 1,
12 — cioe' l'accensione del motore, non l'ingresso in una stanza.

**E quindi lo strumento si sposta dove sta il sintomo.** `tools/guardia_fotogrammi.gd`
scrive nel log ogni fotogramma sopra i venti millisecondi con la posizione del giocatore e i
secondi dall'avvio, nelle sole build di debug, al massimo venti volte. Una sonda sintetica
arriva fin dove arriva; quando il difetto lo vede una persona e non una misura, si mette la
misura addosso alla persona.

## D-181 — Una luce senza ombra non sta nella stanza dove l'hai messa

Federico, due fotografie: «perche' nella sala, quando tutto e' chiuso, ci sono queste luci
dal nulla? Quella riflessa per terra e anche quella riflessa nel muro. Ma poi che cazzo hai
messo in cucina».

Tre domande e due colpevoli, e nessuno dei due era quello che avrei indagato per primo.

**IL METODO E' LA SOTTRAZIONE, non l'ipotesi.** «Una macchia luminosa in una stanza spenta»
ha almeno quattro spiegazioni — una lampada accesa che non si vede, una luce che passa un
muro, un materiale emissivo, un riflesso speculare — e a occhio si sceglie sempre quella che
si aveva gia' in testa. `tools/prova_trafila.gd` non sceglie: fissa la telecamera, spegne
**una sorgente per volta** e riscatta. Quella che spegnendosi fa sparire la macchia *e'* la
macchia.

    dalla sala divulgazione, a luci spente, verso la libreria:
      Lampada/Light            19,13 su tutta l'immagine   32,03 sul pavimento
      tutte le altre 18        sotto 0,05                  sotto 0,05

Una sola sorgente, e non e' nella stanza: e' la **lampada da tavolo del bancone della
cucina**, di la' dal muro. Nata senza `shadow_enabled`, con 2,2 di energia e sei metri di
portata: venti centimetri di muro non la fermavano affatto.

**LO SBAGLIO ERA GIA' SCRITTO, in questo repository, in italiano, a venti righe di distanza
da dove serviva.** In `gen_blockout.py` c'e' un blocco intitolato «LA LAMPADA DI RIMBALZO NON
C'E' PIU', E NON SI PUO' RIMETTERE», che spiega per trenta righe che una luce senza ombre
attraversa un muro come se non ci fosse — misurato: il magazzino passava da 0,06 a 24,15
spegnendo tutto tranne il bagno. La lampada della cucina e' arrivata dal vecchio mondo col
trasloco e nessuno le ha applicato la lezione, perche' era una lezione **sulle plafoniere**.
Una regola scritta accanto al caso che l'ha generata non protegge il caso successivo.

**E LA SECONDA DOMANDA AVEVA LA STESSA RISPOSTA.** «Che cazzo hai messo in cucina» era la
stessa lampadina vista da vicino: `LAMPADA_CUCINA` la metteva a meta' del bancone, cioe' a
**trenta centimetri** dall'alzatina. A trenta centimetri l'irraggiamento porta tutti e tre i
canali oltre l'unita', e tre canali saturi fanno una macchia bianca. E' — di nuovo alla
lettera, alla stessa distanza — il difetto gia' misurato e corretto sull'applique rossa della
cupola, dove passare da 0,30 a 0,50 aveva fatto calare il picco di quattro volte.

Rimedio: ombre accese con bias piccoli (0,05 e 0,02: il muro e' venti centimetri, e il
default di `shadow_normal_bias` e' **un metro**), portata da 6,0 a 3,0, energia da 2,2 a 0,9
— che sono i numeri di una lampada da tavolo e non di una plafoniera, visto che la vera
plafoniera della cucina sta a 2,1 — e diciotto centimetri dal bordo del piano invece di
trenta dal muro. L'energia sta in `lamp.gd` e non nella scena: `_enter_fixed()` la riscrive,
e cambiarla solo nel `.tscn` non avrebbe fatto niente.

    dopo, stessa vista, stessa sonda:
      Lampada/Light            sotto 0,05                  sotto 0,05
      Luce_cucina (dalla porta) 0,04                        0,12

**LA TERZA LUCE NON ERA UN DIFETTO, e va detto perche' e' la meta' interessante.** Il velo
arancione sul muro e' la **spia dell'interruttore**: 0,008 di energia su 35 cm, misurata a
0,22 livelli su 255. Un interruttore italiano di quegli anni la spia ce l'ha, e si accende
quando la luce e' **spenta** — serve a trovarlo al buio. Letto da chi gioca e' diventato «una
luce dal nulla», il che dice che il pezzo funziona e la sua **grammatica** no: nessuno ha mai
spiegato al giocatore che quel puntino e' un interruttore. Non si tocca la lampada; semmai si
insegna a leggerla.

**LA SONDA HA MENTITO AL PRIMO GIRO, ed e' stata la sua stessa autoverifica a dirlo.** La
prima passata dava a ventitre' lampade su ventitre' lo stesso identico scarto — 68,35 —
perche' l'immagine di riferimento era stata scattata prima che la telecamera fosse in posa, e
tutte le altre erano confrontate con quella. E' D-179 parola per parola: *un numero che non
cambia quando cambi la causa non sta misurando quella causa*. Adesso la sonda scatta due volte
senza toccare niente e stampa lo scarto fra i due — deve essere zero, e lo e'.

## D-182 — La luce che descrive la sua sorgente batte quella che la misura

Federico, guardando le stesse fotografie: «il monitor dovrebbe fare luce ambra, non bianca».
E in mezzo c'e' stato un giro a vuoto che vale la pena tenere scritto, perche' e' istruttivo
piu' della conclusione.

Il colore del `LuceMonitor` non era stato scelto: era stato **misurato**. Col CRT vero nel
`SubViewport`, la sonda leggeva 156 178 166 su 255 — un grigio-verde pallidissimo — e
normalizzato veniva (0,88 1,00 0,93), che a due centesimi e' il `tint` del vetro del tubo
dichiarato nello shader. Due numeri indipendenti che si erano incontrati da soli: sembrava la
prova che la luce descrivesse esattamente quello che si vedeva.

E invece era sbagliato, perche' **misurare l'emissione non e' rendere leggibile la sorgente**.
Un bianco-verde pallidissimo, addosso a una cassa beige, non dice «lo schermo e' acceso»: dice
«c'e' un'altra lampada accesa da qualche parte» — ed e' letteralmente cosi' che e' stato
letto, nella stessa frase delle luci dal nulla di D-181.

**IL GIRO A VUOTO.** La prima correzione e' stata *magenta*, perche' magenta e' quello che mi
e' stato chiesto — e l'ho fatto senza fermarmi a chiedermi di che colore sia lo schermo. Poi:
«non so se ho detto io il colore sbagliato, ma lo schermo fa luce viola, non dovrebbe. Avevamo
detto ambra». Aveva ragione, e la risposta stava gia' scritta nel repository: `core/phosphor.gd`,
fosforo P3, **ambra e non verde** (D-173), con dentro il motivo — chi lavora di notte non
guarda uno schermo che gli azzera l'adattamento al buio. Un monitor ambra proietta ambra, e
non c'e' una seconda risposta possibile.

La lezione non e' «l'utente aveva ragione». E' che una richiesta di colore va **verificata
contro la sorgente** prima di eseguirla: se avessi guardato `phosphor.gd` invece della parola,
il magenta non sarebbe mai stato scritto. Un'istruzione su una conseguenza (la luce) si
controlla sempre risalendo alla causa (lo schermo).

**PRE-COMPENSATO COME IL FOSFORO**, e per la stessa ragione gia' scritta in testa a
`phosphor.gd`: la scena usa ACES, che comprime gli alti e sposta gli arancioni verso il
giallo, quindi un ambra scritto come lo si vuole vedere esce crema. La luce si scrive piu'
rossa e meno verde del bersaglio — (1,0 0,46 0,10) — che e' la stessa famiglia della spia al
neon degli interruttori, (1 0,44 0,12), che e' arancione e si vede arancione.

**E L'ENERGIA NON COMPENSA TUTTO IL DOVUTO.** Luminanza del bianco-verde: 0,97; dell'ambra:
0,55. Per fare la stessa *luce* servirebbe 0,25, e a quel livello — guardato, non calcolato —
la cassa beige e la tastiera si tingono anche con la plafoniera accesa: e' lo stesso difetto
del verde saturo di prima, cambiato di tinta. **Con un colore saturo l'energia giusta e' meno
di quella equivalente, perche' quello che si nota non e' quanto illumina ma quanto tinge.**
0,18: al buio la consolle e' ambra e non c'e' dubbio da dove venga; a luci accese resta un
velo sul beige invece di una mano di vernice.

## D-183 — Fra un posto vuoto e un posto occupato male, vince vuoto

Federico: «tutte le cose vecchie come la moka, la lampada, falle sparire. Fanno cagare, e
danno un gran fastidio».

Erano due segnaposti a scatole sul bancone della cucina — `moka.tscn` e `lamp.tscn`, arrivati
dal vecchio mondo col trasloco — e la lampada per giunta faceva la luce che attraversava il
muro di D-181. Fuori tutti e due.

**COSA ESCE E COSA RESTA, che e' la parte che conta.** Escono i due **nodi dalla scena** e le
loro coordinate da `geometria.py`. Restano intatti i due `.tscn` con dentro tutta la loro
logica — la macchina a stati della lampada, il timer del cambio, il ronzio, la persistenza di
`lamp_fixed`, il borbottio della moka — e restano i due `.tres` del catalogo. Non e' stato
cancellato niente di quello che qualcuno ha pensato: e' stato tolto di scena quello che
qualcuno ha *disegnato male*. Rimetterli e' due righe.

**E LA CONSEGUENZA SI PAGA SUBITO INVECE DI NASCONDERLA.** Moka e lampadina erano gli unici
due articoli con `implemented = true`, e `implemented` — lo dice `item_data.gd` da sempre —
significa «esiste davvero la' fuori», non «il codice c'e'». Con gli oggetti fuori scena
tornano a `false`, e **il terminale adesso non vende niente**. E' un buco, ed e' dichiarato in
tre posti (qui, in `terminal.gd`, nel banco): un negozio vuoto e' un buco che si vede e si
riempie, un negozio che vende cose che non compaiono da nessuna parte e' un buco che non si
vede. Fra i due si sceglie sempre il primo.

Il controllo del banco e' stato aggiornato al vero — due categorie che tornano l'insieme vuoto
— ma quello sul **prezzo** della lampadina e' passato a leggere il catalogo *senza* filtro: col
filtro acceso non avrebbe trovato l'articolo e avrebbe taciuto, e un controllo che si spegne da
solo quando cambia il contorno e' il modo peggiore di sbagliare. Il prezzo e' un dato del
`.tres` e resta giusto anche mentre l'articolo non si vende.

## D-184 — Il cielo non e' uno sfondo, e la sua luce non e' l'ambiente

Federico: «mi piacerebbe che mettessi al cielo le stelle e che il cielo in generale offrisse
un minimo di luminosita'. Se sono dentro e' tutto super buio, ma quando apro la cupola un po'
di luce da li' riesce a penetrare — ma sempre nella stessa modalita', non e' una vera luce di
quelle che mi toglie l'abituazione dell'occhio al buio».

Due cose, e la seconda e' quella che aveva una trappola dentro.

**IL CIELO C'ERA E NON ERA UN CIELO.** `background_mode = 1`, tinta unita (0,004 0,005 0,010).
Dalla vetrata della sala di controllo e dalla fenditura della cupola non si vedeva il cielo: si
vedeva il **vuoto**, e la differenza fra le due cose non salta all'occhio come un errore —
sembra soltanto notte fonda. In un gioco che si fa in un osservatorio, quello e' il soggetto.

Adesso c'e' `world/shaders/cielo.gdshader`. **Procedurale e non una fotografia**, e la ragione
e' pratica prima che estetica: una panoramica stellata equirettangolare alla risoluzione che
serve per non avere stelle sfocate pesa decine di megabyte, mentre qui le stelle sono punti
esatti a qualunque ingrandimento e costano un pugno di istruzioni sul solo fondo.

Il come, in due righe, perche' il trucco ha una parte che si sbaglia sempre: la direzione di
vista si moltiplica per una scala e si divide in celle cubiche; ogni cella tira i dadi e, se li
passa, mette una stella in un punto casuale del suo **quarto centrale**. Il quarto centrale non
e' un dettaglio decorativo — e' cio' che permette di guardare UNA cella invece di ventisette,
perche' una stella confinata nel mezzo non sborda mai il bordo e quindi non viene mai tagliata
a meta'. Le stelle tagliate si allineano in file, e una volta viste non si smette piu'.

Due strati a scale non commensurate (150 e 233 celle per radiante), perche' con un passo solo
tutte le stelle stanno alla stessa distanza minima e il cielo si legge come una texture. La
magnitudine e' sorteggiata alla quarta potenza: poche forti, molte deboli, che e' quello che si
vede alzando la testa. E si spengono verso l'orizzonte, perche' l'aria che si attraversa
guardando basso e' molte volte quella che si attraversa guardando su — senza, la vetrata della
sala di controllo mostrava le stelle piu' brillanti esattamente dove nella realta' non se ne
vede quasi nessuna.

**LA TRAPPOLA ERA LA SECONDA META'.** La strada ovvia per «il cielo dia un minimo di
luminosita'» e' `ambient_light_source = SKY`, adesso che un cielo c'e'. E' sbagliata, ed e'
gia' stato misurato in questo progetto: **la luce ambientale non sa niente dei muri**. Alzandola
da 0,035 a 0,11, l'ombra sotto il lavabo del bagno saliva di 3,5 livelli su 255 e la sala
divulgazione **spenta** saliva esattamente di 3,5. Un ambiente piu' alto non fa entrare la luce
dalla cupola: schiarisce tutto insieme, e la stanza che deve restare nera diventa latte. La
richiesta di Federico dice *dentro super buio, dalla cupola un po' di luce*: e' una richiesta
di **occlusione**, e l'ambiente e' proprio l'attrezzo che non occlude.

Quindi: `world/sky_light.gd`, un proiettore sopra la calotta. Sta a nove metri dal pavimento,
guarda in giu', e **proietta ombra**: fra lui e la sala c'e' il guscio, e passa da dove il
guscio non c'e'. E' la stessa cosa che fa il cielo vero, fatta con l'unico attrezzo che un
rasterizzatore ha per farla. L'energia segue `Events.dome_aperture_changed` — il fatto sul bus,
la stessa strada dei battenti, nessuna scorciatoia.

**I NUMERI, misurati con `tools/prova_trafila.gd` a lampade tutte spente** (livelli su 255,
dalla passerella verso il pavimento):

    energia   cupola chiusa   cupola aperta
      0,42        niente          0,38     invisibile: non e' poca luce, e' zero
      1,20        niente          6,27     il telescopio si staglia, il parapetto si
                                           legge, il resto resta silhouette

**E LA PROVA CHE CONTA E' L'ALTRA**, quella che dice che il rimedio non ha rifatto il difetto
che stava rimediando: a cupola **spalancata**, dalla sala divulgazione questa luce misura meno
di 0,05. Non esce dalla cupola. D-181 era una luce senza ombra che stava in tutte le stanze
insieme; questa sta in una sola.

**LA PORTATA E' VENTISEI CON LA LAMPADA A NOVE**, e sembra un errore di battitura. Non lo e':
un cielo non ha una distanza, quindi non deve avere un decadimento. Con la portata a dieci —
appena oltre il pavimento — il decadimento mordeva dentro la stanza, la calotta prendeva tre
volte il pavimento e la luce moriva a mezz'aria. Tenendo il limite lontano, fra il punto piu'
vicino e il piu' lontano restano meno di dieci punti percentuali. L'energia si alza di
conseguenza e **non vuol dire piu' forte**: un'energia si legge solo insieme a portata e
attenuazione, e da sola non e' un numero.

**UNA COSA CHE NON HO CORRETTO, E PERCHE'.** Ad apertura 0,5 la luce del cielo sul pavimento
vale ancora meno di 0,05: i due portelli a meta' corsa stanno proprio **sopra**, attorno allo
zenit, dove sta il proiettore. Comincia a passare qualcosa solo quando si scostano davvero.
Sembra un difetto e non lo e' — e' quello che fa una cupola vera, e dice una cosa vera sul
gioco: aprire a meta' non serve a vedere, serve a puntare.

**E IL VINCOLO DICHIARATO RESTA VINCOLO.** «Non una vera luce di quelle che mi toglie
l'abituazione dell'occhio al buio» non e' un gusto: e' la stessa ragione per cui in cupola la
luce e' rossa e per cui le due lampade esterne valgono un decimo di una plafoniera. A cupola
spalancata il pavimento della cupola resta ampiamente sotto quello che una plafoniera accesa
da' a una stanza vuota. Il cielo fa **comparire le sagome**, non illumina.

## D-185 — L'adattamento al buio e' una proprieta' dell'occhio, non della stanza

Federico: «con la cupola aperta e le luci spente, per lo stesso principio per cui si attiva
l'abituamento degli occhi, alziamo leggermente il punto di nero — sembra che vedi un po'
meglio, una leggera diffusione, solo nella sala telescopio. Che ne pensi? A me sembra una
buona idea».

E' una buona idea, e la parte migliore e' quella che non ha detto: e' l'unico effetto di
questo gioco che ha un INSEGNAMENTO dentro. Tutto il resto dell'illuminazione notturna qui
dice al giocatore come stanno le cose; questo gli dice **cosa gli conviene fare**.

**PERCHE' E' UN AGGIUSTAMENTO DI CAMERA E NON UNA LAMPADA.** La strada per abitudine sarebbe
stata una sorgente fioca dentro la cupola. Sbagliata due volte: illuminerebbe le superfici
secondo la loro normale e la loro distanza — cioe' farebbe una LUCE, con un centro e un fuori
— e per non entrare nelle stanze accanto avrebbe bisogno di ombre, cioe' sarebbe la seconda
copia dell'attrezzo che D-184 ha appena messo li' per il cielo. L'adattamento non e' una cosa
della stanza: e' una cosa dell'occhio. Non arriva piu' luce — cambia la risposta a quella che
c'e'. L'attrezzo giusto e' quello che agisce sull'IMMAGINE:
`Environment.adjustment_color_correction`, una rampa che parte da un grigio-blu invece che dal
nero. Il LUT a una dimensione mappa ogni canale, quindi `fuori = alzata + dentro * (1 -
alzata)`: i neri salgono, i bianchi restano dove sono, e in mezzo la curva resta dritta. Non e'
contrasto abbassato — e' esattamente e solo il fondo che si stacca dal nero.

**L'ALZATA E' AZZURRA E NON GRIGIA**, e non e' un gusto: al buio la visione passa ai
bastoncelli, che sono ciechi al rosso e spostano tutto verso il blu. E' l'effetto Purkinje, ed
e' la stessa fisiologia che sta dietro a D-011 — la ragione per cui le sale di controllo hanno
la luce rossa. Un'alzata neutra fa cenere; questa fa notte.

**CINQUANTA SECONDI, E LI HA CHIESTI LUI CONTRO I MIEI NOVE.** «Non e' che appena apre la
cupola, proprio nel primo secondo — dai almeno cinquanta secondi, miglioriamo la luminosita' in
maniera graduale; niente di estremizzante, altrimenti diventa tutto uno scattone.» Aveva
ragione, e la ragione e' piu' generale del caso: **un effetto che arriva in nove secondi lo si
vede arrivare**, e a quel punto non e' piu' l'occhio che si abitua, e' il gioco che accende
qualcosa. A cinquanta non c'e' nessun istante in cui succede: ci si accorge solo, dopo un po',
di stare vedendo cose che prima non c'erano. Misurato: 0,17 dopo dieci secondi, 0,37 dopo
venti, 0,67 dopo trentacinque, pieno a cinquantaquattro.

E la discesa e' un secondo e mezzo — un trentatreesimo della salita. **L'asimmetria e' il
messaggio**: farsi l'occhio costa, perderlo no. Accendere la luce in cupola non e' gratis, e lo
si impara accendendola una volta. Non un fotogramma pero': anche il crollo istantaneo sarebbe
«uno scattone», e per giunta sarebbe indistinguibile da un difetto di rendering.

**TRE CANCELLI, E TUTTI E TRE PROVATI FACENDOLI FALLIRE** (`tools/prova_trafila.gd`, con la
sonda che stampa l'adattamento invece di dedurlo dallo schermo):

    in cupola, aperta, al buio, 58 s        1,00
    in cupola, CHIUSA, al buio, 16 s        0,00
    in cupola, aperta, ROSSA ACCESA         0,00
    in cucina, cupola aperta, al buio       0,00

Il terzo ha richiesto di aggiungere alla sonda un modo di ACCENDERE una lampada: le tre rosse
della cupola nascono spente, quindi «con la luce accesa l'occhio non si fa» non si poteva
verificare senza accenderne una. Un cancello che non si puo' far fallire non e' un cancello.

**E UN CONTROLLO E' NATO CIECO, scoperto solo perche' gli ho iniettato il difetto.** Il
generatore verifica che il nodo dell'occhio abbia scritto l'elenco delle sue lampade, e la
stringa attesa era `luci = [NodePath("../Luce_cupola1/Accesa")`. Svuotato l'elenco, il controllo
**passava lo stesso**: quella riga, identica carattere per carattere, ce l'ha anche
l'interruttore che comanda le tre rosse. E' D-176 rifatto — un controllo che misura la cosa
sbagliata e tace — e la cura e' la stessa: ancorare la stringa a qualcosa che appartenga a un
nodo solo, cioe' la riga dello script che la precede. Non l'avrei mai saputo senza iniettare:
il controllo era verde in tutti e due i mondi.

## D-186 — Alzare il fondo e alzare il guadagno sembrano la stessa cosa e sono opposte

Federico, dopo aver provato l'adattamento al buio di D-185: «a me sembra di vedere uguale e
solo leggermente piu' chiaro, cioe' i neri sono leggermente meno neri. In realta' vorrei
vedere leggermente di piu'. Quindi piuttosto fai tornare i neri come erano prima, pero' che
veda un po' piu' di forme, di cose».

**AVEVA RAGIONE, E LA RAGIONE E' PIU' GRANDE DEL CASO.** Alzare il punto di nero e alzare la
sensibilita' si somigliano sullo schermo e fanno cose opposte:

- **Il punto di nero** ADDIZIONA. Alza il fondo e lascia tutto il resto dov'e': il nero
  diventa grigio e quello che era appena visibile resta appena visibile. Il contrasto locale —
  che e' l'unica cosa che fa emergere una forma — non si muove di un livello. Si vede piu'
  CHIARO e non si vede piu' NIENTE. E' esattamente quello che Federico ha visto e descritto.
- **L'esposizione** MOLTIPLICA. Il nero e' zero e resta zero, mentre tutto quello che stava fra
  l'invisibile e il visibile sale sopra la soglia: il corrimano, il bordo della passerella, la
  curva del tubo. Si vedono piu' COSE e i neri restano neri — che e' la richiesta, parola per
  parola.

Ed e' anche quello che fa la retina: al buio non aggiunge un fondo, cambia il **guadagno**.
Avevo scelto l'addizione perche' l'idea era arrivata con le parole «alziamo il punto di nero» e
ho implementato le parole invece della cosa. E' lo stesso errore del magenta (D-182): eseguire
la descrizione di una conseguenza senza risalire alla causa.

`GUADAGNO = 2.4`, poco piu' di un diaframma e un quarto, e sembra tanto solo finche' non si
tiene conto di ACES: la curva comprime gli alti, quindi quello che era gia' chiaro sale
pochissimo mentre quello che stava sul fondo — dove la curva e' ancora dritta — sale di tutto
il fattore. E' il moltiplicatore giusto per far emergere il debole senza bruciare il forte, ed
e' per quel comportamento che ACES sta su questa scena fin dall'inizio.

**E SI RIMETTE A POSTO USCENDO.** `Environment` e' una RISORSA, e le risorse sopravvivono alla
scena che le ha caricate: sparendo con l'esposizione moltiplicata, la notte dopo lo stesso nodo
leggerebbe 2,4 come valore di riposo e ci moltiplicherebbe sopra un altro 2,4. E' un difetto
che si manifesta solo alla seconda notte, cioe' mai mentre lo si sviluppa.

## D-187 — Una lampada che spegne l'aiuto al buio dev'essere una lampada che acceca

Sempre Federico, stessa sessione, due difetti che sembravano tre e avevano una radice sola: la
lampada di prossimita' — quella che il giocatore si porta addosso perche' cio' che sfiora non
sia una macchia nera.

**PRIMO: la luce del cielo la spegneva.** «Se mi avvicino alla luce che viene proiettata dentro
la cupola dal cielo, perdo di nuovo la capacita' di adattamento al buio, mi si spegne proprio
come se fossi esposto a una luce normale — e non e' quello che vogliamo.»

Aveva ragione due volte, perche' non era nemmeno l'adattamento: era `luce_prossimita.gd`, che
somma le lampade che arrivano dove sta il giocatore e si spegne dove la stanza e' gia'
illuminata. Regola giusta — esiste per non vedere il proprio alone su una parete accesa — con
il risultato sbagliato: il proiettore del cielo (D-184) vale **1,04** alla quota della testa
contro una soglia di **0,30**, quindi bastava entrare in cupola con la fenditura aperta perche'
la prossimita' si spegnesse del tutto. In cupola, che e' dove serve di piu'.

La cura non e' una deroga, e' la regola detta meglio: **una lampada che spegne l'aiuto al buio
dev'essere una lampada che ACCECA**, e il chiarore delle stelle sul pavimento non e' una parete
illuminata — e' il buio, misurato bene. Il cielo entra in un gruppo (`SkyLight.GROUP`) e il
conto lo salta. Il gruppo, e non un controllo di tipo, perche' il giorno che ci sara' una
seconda luce «che non conta» — un lumino, una spia, il monitor visto da lontano — la si aggiunge
al gruppo invece di allungare un `if`.

**SECONDO: il giocatore proiettava la propria ombra.** «Una cosa veramente ridicola: facendo
luce io, quando mi avvicino all'oculare del telescopio proietto un'ombra della stessa» — con
screenshot, e lo screenshot fa ridere: un disco nero a bordo vivo disegnato sul tubo, proiettato
da una lampada che nella finzione non esiste.

«Ridicola» e' la parola esatta, ed e' anche la diagnosi. Il difetto non e' l'ombra: e' che
l'ombra **denuncia la sorgente**, cioe' manda a monte le tre scelte che `player.tscn` documenta
da sempre per nasconderla (sta sotto l'occhio, non ha speculare, muore a due metri e mezzo).
Una lampada invisibile che proietta un'ombra visibile e' una lampada che si e' scoperta.

**E NON SI PUO' SPEGNERE L'OMBRA E BASTA**, che sarebbe la reazione naturale: e' gia' misurato
in questo repository che senza ombre questa lampada attraversa i muri e alza il pavimento della
stanza accanto di **173 livelli su 255**. Il rimedio non e' togliere l'ombra, e' renderla
illeggibile: `light_size = 0.55` le da' la dimensione che dovrebbe avere — non un punto sul
petto ma mezzo metro di chiarore diffuso — e la penombra diventa piu' larga dell'ombra. A mezzo
metro non c'e' piu' niente da leggere; a due, dove la lampada serve davvero, la forma resta.

Rimisurato col banco `tools/prova_prossimita.gd`, che e' esattamente il posto dove questa
taratura si verifica:

    distanza    spenta   accesa   alzata
      0,7 m        7,0     66,6    +59,7
      1,5 m        6,9     28,3    +21,3
      2,5 m        6,9      7,4     +0,5
      5,0 m        6,9      6,9     +0,0
    di la' dal muro  6,6      6,6     +0,0

Quattro distanze, zero guasti: la lampada rivela ancora quello che si sfiora, muore ancora a
due metri e mezzo, e ancora non passa i muri. E' cambiata solo la cosa che si era scoperta.

## D-188 — La cupola non copia l'azimut del telescopio, e non ci va nemmeno vicino

Federico: «il telescopio deve effettivamente ruotare assieme alla cupola quando facciamo il
go to. Soprattutto la rotazione della cupola secondo me non e' scontatissima, dobbiamo
capirla».

Aveva ragione, e i numeri lo dicono meglio di qualunque intuizione. **Non e' una correzione
all'azimut del telescopio: e' un altro numero.**

Il conto giusto non parte dal telescopio, parte dall'**apertura**: si prende la retta di vista
e si chiede dove incontra la sfera della cupola. Le due cose coincidono solo se l'apertura sta
nel centro della sfera, e su una equatoriale tedesca non ci sta mai — il tubo lavora **di
fianco** al pilastro. Sulla geometria vera di questo osservatorio (sfera di raggio 2,50 col
centro a 3,38 m, apertura a 1,86 m e fino a un metro fuori asse):

    apertura 1,05 m fuori asse   azimut telescopio   azimut cupola   scarto
      puntando a 30° di altezza         180°             155°         -25°
                 60°                    180°             147°         -33°
                 75°                    180°             130°         -50°
                 88°                    180°              96°         -84°

Due cause si sommano: il braccio della declinazione, e il fatto che l'apertura stia **un metro
e mezzo sotto** il centro della sfera. Nessuna delle due si vede guardando la scena, ed e' per
questo che il difetto sarebbe stato invisibile: da dentro la cupola il proprio raggio non si
vede.

**DUE CONSEGUENZE GIOCABILI, dagli stessi numeri.** Dopo un ribaltamento al meridiano la cupola
deve saltare di cinquanta-ottanta gradi, perche' il tubo passa dall'altra parte del pilastro. E
**sotto i quaranta gradi di altezza il telescopio non vede fuori affatto** — non per colpa
della cupola, ma perche' il raggio esce sotto la linea di gronda e trova il tetto e i muri.
Misurato: due pose su dodici, a 28 e 30 gradi, finiscono contro `M5_1` e `M7_1`. E' l'orizzonte
di questo edificio, ed e' un dato che il targeting dovra' conoscere.

**ASSERVITA E NON A MANO, contro il GDD.** La fase 7 diceva «porti la fessura sull'azimut del
telescopio, e ce la riporti durante la posa». Federico: «ho paura che farlo a mano sia una
rottura di coglioni». Ha ragione, e la regola che decide il progetto ce l'ha gia': *se una fase
nessuno la farebbe davvero, si cambia il documento*. Con scarti che cambiano di continuo mentre
il cielo gira, girare la cupola a mano non e' un rituale — e' un metronomo. **Il ciclo foto
perde i suoi dieci minuti di fase 7 e il budget della notte va rifatto.** La pulsantiera resta
come comando manuale.

**LA POSA DEL MODELLO ANDAVA TOLTA, e la taratura si e' fatta misurando.** Il `.glb` non nasce
a zero: porta la posa dei render di controllo (-60° e -20°). Il nodo la sottrae per ritrovare
lo zero — che e' il polo. Poi restava da capire quanto valesse un angolo orario, e invece di
ragionarci si e' portato il telescopio a valori noti leggendo dove finiva la mira:

    asse ar   dec      altezza   azimut    che vuol dire
       0       90       +43,1      -1      il POLO (l'altezza vale la latitudine)
      90        0       +46,6     178      il meridiano a sud: angolo orario ZERO
       0        0        -0,6      89      l'orizzonte a est: angolo orario -90
     180        0        +1,3     -90      l'orizzonte a ovest: angolo orario +90

Tre righe indipendenti, stesso scarto: novanta gradi. Non ha nessun significato fisico — e'
dove il modello aveva il tubo — ed e' esattamente per questo che andava misurato.

**E LA MIRA E' UN PEZZO DEL MODELLO, non un indovinello del gioco.** `telescopio_blender.py`
appende ad AsseDec un empty sull'asse ottico, all'altezza dell'apertura: il modello DICHIARA
dove guarda. Indovinarlo dalla mesh del tubo era gia' stato provato e sta scritto li': la retta
di regressione della nuvola di vertici dava 62 gradi dove il tubo ne faceva 43, perche' in
quella nuvola ci sono anche cercatore, anelli e bulloni.

## D-189 — Una sonda che spara contro un oggetto senza collisione dice sempre che va bene

La prova che la cupola punti dove serve non e' «la calotta ha girato» (girerebbe anche col
conto sbagliato) e non «l'azimut e' quello atteso» (sarebbe il mio conto ricopiato in due
posti, cioe' un controllo che si da' ragione da solo). E' una sola: si tira il raggio del
telescopio e si guarda se incontra il guscio.

**E per due giri interi non ha incontrato niente, perche' il guscio NON ESISTE.** Calotta e
portelli arrivano dal `.glb` come sole `MeshInstance3D`: in gioco nessuno ci sbatte contro,
quindi nessuno gli ha mai dato un corpo. Il raggio passava attraverso la cupola come se non ci
fosse, e il referto diceva soddisfatto «nessun puntamento guarda il guscio».

**L'ha scoperto solo il difetto iniettato.** La sonda nasce con un interruttore che BLOCCA la
cupola, e con la cupola bloccata la maggior parte dei puntamenti deve finire contro la lamiera.
Passavano tutte e dodici. Un controllo che dice «va bene» in tutti e due i mondi non e' un
controllo, ed e' la terza volta in questo progetto (D-176, D-178, D-185): **il collaudo di un
collaudo e' fargli vedere il difetto**.

La cura: il corpo glielo si da' per la durata della prova, con la MESH VERA
(`create_trimesh_shape`). Non una sfera con un buco parametrico — quella sarebbe di nuovo il
mio conto ricopiato, e la fenditura vera si allarga salendo e i portelli aperti si accavallano
oltre lo zenit.

Col guscio che finalmente esiste:

    cupola asservita     12 pose: 10 libere, 2 sotto la gronda, 0 contro la cupola
    cupola BLOCCATA      12 pose:  1 libera,  2 sotto la gronda, 9 contro la cupola

**E ANCHE LE POSE DI PROVA ERANO SBAGLIATE, per una ragione geometrica che vale la pena
sapere**: le prime otto stavano quasi tutte in alto, e attorno allo zenit la fenditura si
allarga (1,60 m in basso, 2,40 allo zenit) mentre i portelli aperti si accavallano oltre la
verticale. Li' c'e' un buco largo sessanta gradi e qualunque puntamento esce comunque, con la
cupola girata bene o girata male. Le pose che misurano qualcosa sono quelle a mezza altezza e
sparse in azimut.

## D-190 — Una cupola chiusa non si slega

Federico, tre parole e uno screenshot: «e' tutto spostato aiuto».

L'asservimento partiva al primo fotogramma della notte e portava la fessura sull'azimut del
telescopio a riposo — quasi centottanta gradi. Il giocatore entrava in cupola e vedeva la
calotta girare mezzo giro sotto i piedi, per allineare una fenditura **ancora chiusa**.

Non e' solo estetica, ed e' la ragione per cui la riga si scrive senza rimpianti: una cupola
vera non si slega mentre e' chiusa. Non c'e' niente da allineare, e il motore lo si accende
quando serve. Adesso l'inseguimento ascolta `Events.dome_aperture_changed` e sta fermo sotto il
cinque per cento di apertura; la calotta nasce dove il modello l'ha messa.

## D-191 — La fase 5 non e' una schermata: e' un numero che sopravvive alla schermata

Federico: «fai il plate solving e go to prima nella maniera di merda e poi dopo con gli
upgrade andiamo con la versione piu' figa».

La maniera di merda e' quella vera del 1999, e sta in una riga: **una montatura che si
accende non sa dove sta guardando.** Gli encoder partono da un valore qualunque, e chiederle
M13 la porta un paio di gradi in la'. Non e' un guasto simulato per dare da fare al
giocatore — e' come funzionano le montature, e chi ci lavorava lo dava per scontato come
mettere in moto l'auto. Sincronizzare vuol dire dirle «quello che stai inquadrando adesso e'
la tale stella».

**LA PARTE FACILE E' LA SCHERMATA; LA PARTE CHE CONTA E' CHE L'ERRORE SOPRAVVIVA.** Il GDD
promette che l'errore residuo «si vede DOPO: e' l'oggetto scentrato nel campo». Una fase 5
che desse un voto e morisse li' sarebbe un giocattolo: si gioca, prende cento, e non cambia
niente. Percio' il residuo non finisce in un `payload` — finisce su `NightRun`, dove
sopravvive fino allo spegnimento e dove il GOTO va a leggerlo.

**DUE CAMPI E NON UNO, e il secondo e' quello interessante.** Non basta «di quanto ho
sbagliato»: serve anche «DOVE ho sincronizzato». Sincronizzare su una stella raddrizza il
puntamento LI', non dappertutto — con l'asse polare fuori squadra l'errore ricresce
allontanandosi. Ed e' proprio il caso di questa montatura: l'asse misura 43,1 gradi contro
una latitudine di 43,9. Otto decimi di grado, che su quaranta gradi di cielo diventano venti
primi d'arco di errore di puntamento. E' il motivo per cui negli osservatori si sincronizza
di nuovo prima di ogni soggetto, ed e' il motivo per cui il plate solving varra' i suoi soldi.

**L'INQUADRATURA DELLA CAMERA E' PICCOLA, e vederlo disegnato e' meta' di quello che questa
fase insegna.** Il cercatore mostra cinque gradi; il chip della ST-8 dietro i 1500 mm del
Newton da 30 cm ne inquadra 0,53 x 0,35. Un GOTO sbagliato di mezzo grado — che sembra poco —
lascia il soggetto ben dentro il campo e ben fuori dalla foto. Il rettangolino al centro
della schermata del GOTO e' quel mezzo grado, ed e' l'unica spiegazione che serve.

**MISURATO, SU VENTI NOTTI PER PARTE** (`tools/prova_sync.gd`):

    sincronizzazione CENTRATA     errore  3,6'  ->  soggetto a  28' dal centro
    sincronizzazione TIRATA VIA   errore 81,3'  ->  soggetto a  76' dal centro

**E il numero che sorprende e' il primo**: anche centrando bene, il soggetto arriva a mezzo
grado dal centro e va portato dentro l'inquadratura a mano. Non e' un difetto della fase: e'
quegli otto decimi di grado di asse storto. Finche' non si raddrizza, **ogni GOTO chiede una
centratura**, e la differenza fra sincronizzare bene e male e' quanto tempo ci vuole.

**QUELLO CHE NON E' STATO FATTO, e va detto.** Il plate solving comprabile non c'e' ancora:
c'e' la fase manuale e c'e' il posto dove il plate solving si innestera' — sostituire la
centratura con una misura automatica e' cambiare la sorgente di verita', non la fase. E il
prezzo in minuti di notte non e' tarato: il GDD lo dichiara gia' come intento di progetto.

## D-192 — Questo edificio non vede sotto i 48 gradi, e non e' una regola di gioco

Costruendo il GOTO serviva sapere dove il telescopio PUO' guardare. La risposta e' stata
molto peggiore del previsto, ed e' una misura: si spara il raggio vero contro la geometria
vera (`tools/prova_orizzonte.gd`, undici angoli orari, un grado di declinazione alla volta).

    AR  -75   scende fino a dec +72   =  45,8 gradi di altezza
    AR    0   scende fino a dec  -3   =  43,1
    AR  +75   scende fino a dec +61   =  44,2
    limite: 43,1 gradi nel punto migliore, 47,7 nel peggiore

**LA CAUSA NON E' LA CUPOLA, E' IL RAPPORTO.** L'apertura del tubo sta a 1,86 m da terra e il
foro del tetto a 3,20: il telescopio guarda fuori da due metri SOTTO il proprio oblo'.
Puntando basso il raggio esce dalla fenditura, scende, e trova la falda. In un osservatorio
vero l'incrocio degli assi sta accanto al centro della sfera — ed e' esattamente per questo
che le cupole hanno il piano di calpestio rialzato e il pilastro alto. Qui il pilastro e'
alto 75 cm e la passerella 59.

**COSA COSTA, MISURATO** (`ALZA=` nella stessa sonda):

    strumento com'e'     limite  43-48 gradi     M42 e M8 irraggiungibili sempre
    alzato di 0,8 m      limite  30-33 gradi
    alzato di 1,4 m      limite  17-19 gradi     un osservatorio normale
    alzato di 2,0 m      limite   1-11 gradi

**DUE SOGGETTI SU SEI SPARISCONO.** M42 (dec -5) culmina a 40,7 gradi, M8 (-24) a 21,7: da
questa cupola non si vedono mai. Il planetario adesso lo dice — «too low for the dome, alt
41» — invece di scrivere la finestra di visibilita' e mandare il giocatore ad aspettare una
cosa che non arrivera'.

**NON L'HO RISOLTO IO, ed e' deliberato.** Alzare lo strumento vuol dire alzare la passerella,
la scala e il parapetto: e' una modifica all'edificio, e l'edificio e' documentato. La misura
sta qui, il costo di ciascuna alternativa sta qui, la decisione e' di Federico. Nel frattempo
il gioco non mente: quattro soggetti su sei, e il perche' scritto sullo schermo.

## D-193 — Due modi diversi in cui un controllo dice il falso, tutti e due incontrati oggi

**IL PRIMO: CONFONDERE IL COMANDO CON LO STATO.** La sonda del puntamento ha un controllo
nuovo — «il bus muove davvero il tubo?» — perche' quel collegamento e' il piu' silenzioso di
tutto lo strato: se si stacca non succede niente di visibile, solo un telescopio fermo mentre
lo schermo dice che sta puntando. Al primo giro il controllo ha gridato «IL BUS NON MUOVE IL
TUBO» su un collegamento perfettamente sano: guardava `dove()`, cioe' dove il tubo SI TROVA,
un fotogramma dopo aver dato un comando che il motore esegue in dieci secondi. La domanda
giusta era `in_moto()`. Un comando non e' uno stato, e un controllo che li scambia trova
guasti dove non ce ne sono — che e' l'altra meta' del problema di un controllo cieco.

**IL SECONDO: GIUDICARE SU UNA NOTTE SOLA.** La sonda della sincronizzazione confrontava un
sync fatto bene con uno tirato via, una volta per parte, e ogni tanto dichiarava il guasto: la
sincronizzazione tirata via atterrava PIU' VICINO di quella fatta bene. Non era un bug — i due
errori possono elidersi, lo sfasamento degli encoder in un verso e la deriva dell'asse polare
nell'altro. Su una notte capita; su venti no. Adesso la sonda ne simula venti per parte e
giudica le medie, che e' anche cio' che il giocatore vive.

**E UNO EVITATO PER UN PELO: UN CONTROLLO CHE SMETTE DI COLLAUDARE CIO' PER CUI ESISTEVA.**
Il banco pinna quali soggetti sono disponibili a certe ore, e quei set esistono per collaudare
il wrap di mezzanotte e il confine inclusivo delle finestre. Da quando il planetario tiene
conto anche dell'orizzonte della cupola, `available` mescola due fatti diversi — «e' nella sua
finestra» e «questa cupola lo raggiunge» — e adeguare i set attesi avrebbe fatto passare il
banco togliendogli i denti proprio dove servivano. La sorgente adesso pubblica i due fatti
separati: il banco pinna la finestra, e per l'orizzonte controlla la COERENZA
(`available == in_window AND alt >= orizzonte`) invece delle sigle — cosi' resta vero anche il
giorno in cui lo strumento verra' alzato.

## D-194 — Le stelle non cambiavano: si accendevano e si spegnevano

Federico: «una cosa che ha poco senso sono le stelle che cambiano se muovo la
visuale».

Non era scintillio. Le stelle vere tremolano di INTENSITA' — l'aria che si muove — e
quello sarebbe stato un pregio; queste si accendevano e si spegnevano, di esistenza,
tutte insieme, mentre la camera ruotava.

**LA CAUSA E' ARITMETICA E NON ARTISTICA.** Il dischetto di una stella misura poco
piu' di mezzo pixel: girando, il suo centro passa da una parte all'altra del confine
fra due pixel e la stella o viene campionata o non viene campionata. E' l'aliasing
piu' vecchio del mondo, ed e' invisibile A FERMO — che e' esattamente il motivo per
cui non era stato notato quando il cielo e' stato scritto e guardato in uno scatto.

**LA CURA NON E' INGRANDIRE, E' ALLARGARE CONSERVANDO LA LUCE.** Si porta il raggio
della stella ad almeno un pixel e si divide la luminosita' per l'area guadagnata:
copre sempre lo stesso numero di fotoni, distribuiti su almeno un pixel. Ingrandire e
basta darebbe un cielo di palline; cosi' le stelle stanno ferme e cambiano solo di
intensita', che e' quello che fanno davvero.

**QUANTO CIELO STA IN UN PIXEL SI MISURA, non si dichiara**: dipende dalla
risoluzione e dal campo visivo, e una costante scritta nello shader sarebbe giusta su
un solo schermo. `dFdx`/`dFdy` sulla direzione di vista dicono di quanto cambia il
cielo fra un pixel e il suo vicino, che e' esattamente la domanda.

**MISURATO** (`tools/prova_cielo.gd`): si gira la camera di un ventesimo di grado
alla volta — meno di un pixel — e si guarda quanta luce cambia fra due fotogrammi
consecutivi. Il fondo non cambia a quella scala, quindi tutto quello che si muove
sono le stelle.

    stelle allargate a un pixel   tremolio medio 0,31%   peggiore 0,73%
    stelle sotto il pixel (CRUDO) tremolio medio 1,13%   peggiore 3,44%

E la luce totale del fotogramma SALE con la correzione (3768 contro 2219): le stelle
sotto il pixel non erano solo instabili, per meta' del tempo non venivano disegnate
affatto.

**IL DIFETTO SI PUO' RIMETTERE**, e questa e' la parte che rende la sonda una sonda:
lo shader ha un `antialias` che a zero riporta le stelle sotto il pixel. Senza quel
confronto il referto avrebbe detto «tremolio 0,31%» e nessuno avrebbe saputo se e'
poco o tanto.

## D-195 — Il quadro elettrico, e tre modi di sbagliare che si assomigliano

Federico voleva il quadro in facciata: si apre, si chiude, e il pulsante rosso stacca
o da' corrente a tutto. Il GDD lo aveva gia' scritto — «il contatore, in facciata,
governa PC, monitor, montatura e luci, e nel 1999 si riarma a mano, e per farlo
bisogna uscire al buio».

**STACCARE NON GIRA GLI INTERRUTTORI.** Quando la corrente torna si riaccende quello
che era acceso PRIMA: non tutto, e non niente. E' come funziona un impianto vero ed
e' anche l'unica versione che non irrita — chi aveva spento la sala divulgazione non
se la ritrova accesa al ritorno. E una placca girata durante il blackout non si
perde: la lampada resta spenta (non c'e' corrente) ma la POSIZIONE cambia, e si vede
quando la corrente torna.

**IL PULSANTE ROSSO NON C'ERA NEL MODELLO.** Il .gltf ha due mesh — cassa e anta — e
dentro c'e' il cablaggio, sull'anta un cartello di pericolo, e basta. Il fungo lo
mettiamo noi, ed e' la stessa regola del pilastro sotto il telescopio: si modella il
pezzo che manca e che deve muoversi, non si reinventa quello che c'e'. A fungo e non
a leva perche' e' un arresto d'emergenza: si preme col palmo, al buio, ed e'
esattamente il gesto di chi esce di notte ad armare il quadro.

**L'ANTA ARRIVA APERTA E IL CARDINE SI DEDUCE.** Nel modello l'anta e' ruotata di 58
gradi — l'autore l'ha fotografata cosi' — e la si chiude PER COSTRUZIONE (parallela
alla faccia, appoggiata sopra) invece di sottrarre l'angolo dichiarato: cosi' il
risultato non dipende da quanto era spalancata. Il cardine invece e' un dato che il
modello porta senza dichiararlo: chiudendo, uno dei due spigoli verticali fa un arco
di 27 cm e l'altro di 21 — quello fermo e' la cerniera. Sceglierlo a caso avrebbe
funzionato la meta' delle volte.

### I tre errori, che sono lo stesso errore visto da tre parti

**UNO: DUE SISTEMI DI COORDINATE NELLO STESSO FILE.** I mattoni di `modellare`
lavorano in coordinate DI GIOCO (x e z in pianta, y in alto) e le convertono da sole;
il resto dello script lavora in coordinate di BLENDER, perche' maneggia matrici di
oggetti importati. Il fungo e' stato costruito con le seconde passate alla prima: e'
finito sottoterra, dietro il muro, con l'asse verticale. Nel provino non c'era, e non
c'era nessun errore.

**DUE: SPOSTARE UN'ORIGINE E' DUE MOSSE CHE SI ANNULLANO** — la mesh indietro nelle
sue coordinate, l'oggetto avanti nel mondo. Farne una sola, o scrivere `location`
DOPO aver assegnato `matrix_world`, sposta l'oggetto per davvero: l'anta e' finita
mezzo metro sopra la cassa, con il quadro spalancato sul proprio cablaggio.

**TRE: IL RIDUTTORE DI TEXTURE FONDE TUTTI I SET IN UNO.** `prendi_modello.riduci()`
rinomina ogni mappa in `color.jpg`/`normal.png`/`roughness.jpg`, il che va benissimo
finche' il modello ha UN materiale. Il quadro ne ha due — cassa e anta — e finivano
negli stessi tre file: il primo arrivato vinceva, il secondo veniva scartato in
silenzio (`if os.path.exists: continue`), e in gioco cassa e anta si ritrovavano la
stessa faccia. Adesso, con piu' di un set, ognuno tiene il proprio prefisso; con un
set solo i nomi restano quelli di sempre e nessun modello gia' fatto cambia. E il
suffisso `_rid_` non e' un vezzo: senza, il file ridotto si sarebbe chiamato come il
proprio sorgente (`fuse_box_door` + `normal.png` = `fuse_box_door_normal.png`), quindi
«esisteva gia'» e non veniva ridotto — le mappe di colore uscivano perche' cambiano
estensione, le normali no.

**Tutti e tre hanno la stessa forma**: nessun errore, nessun avviso, e un modello
plausibile che e' sbagliato. Li ha trovati il PROVINO, che e' l'unica cosa che
guarda.

## D-196 — Un nodo del modello e un nodo del gioco possono chiamarsi uguale

Due volte di fila, nella stessa ora: `find_child("Fungo")` trovava la mesh rossa
dentro il modello invece del corpo che la comanda, e `find_child("Anta")` trovava la
lamiera invece dell'interagibile. In tutti e due i casi il cast falliva, e il referto
diceva **«il pulsante non si trova»** con il pulsante montato e funzionante.

E' la stessa lezione gia' scritta per il monitor, la cupola e la montatura, arrivata
da una direzione nuova: **i nomi non sono indirizzi**. Qui pero' non e' nemmeno
questione di spostamenti — sono due nodi diversi che si chiamano uguale a ragione,
perche' uno E' il fungo e l'altro lo comanda. Adesso `MainsButton` e `PanelDoor`
hanno il loro gruppo e il loro `find_in`, come tutto il resto di `world/`.

E la sonda della rete guarda anche una cosa che sembrava scontata: **il raggio del
giocatore, mirando il fungo, prende il fungo**. Un bersaglio coperto da un altro non
da' nessun errore — davanti al quadro semplicemente non compare il prompt.

## D-197 — Il quadro spegne quello che ha in elenco, quindi l'elenco non si controlla

La prova che il fungo stacchi la corrente non e' chiedere al quadro se ha spento le
lampade del quadro: quella e' la sua stessa lista ricopiata in due posti, cioe' un
controllo che si da' ragione da solo. `tools/prova_rete.gd` cerca invece per conto
proprio OGNI luce dell'albero e pretende che dopo lo scatto siano tutte spente.

**E ne ha trovate nove dimenticate al primo colpo**: la luce che il monitor getta
sulla scrivania e le otto spie al neon delle placche. Sono esattamente il tipo di
oggetto che si dimentica — non illuminano niente, e una spia accesa a corrente
staccata e' il primo dettaglio che tradisce un impianto finto.

**TRE LUCI RESTANO ACCESE PER FORZA**, ed e' scritto nella sonda invece che dedotto:
la Luna e il cielo stanno fuori dal contatore, e la luce di prossimita' non e' una
lampada — e' l'aiuto di lettura che segue la testa del giocatore, e non ha un
interruttore da nessuna parte. Ogni altra luce che sopravviva allo scatto e' un
difetto.

    a corrente data       20 luci accese nella scena
    a corrente staccata    0
    a corrente ridata     20, le stesse

## D-198 — «SLEWING» lampeggiava perche' era una domanda, non uno stato

Federico: «spesso vedo comparire e scomparire in maniera spasmodica la scritta
SLEWING sul monitor».

**NON ERA UN PROBLEMA DI SCRITTA.** `telescope_slewing_changed` non muove solo sette
lettere: a tubo in viaggio lo schermo NON DISEGNA il soggetto (a meta' slew il campo
inquadrato non e' quello, e mostrare la stella dove sara' inviterebbe a premere SYNC
prima dell'arrivo) e INVIO non conferma. Una montatura che si dichiarava in viaggio
per un fotogramma ogni tre decimi di secondo faceva lampeggiare l'oggetto e ignorava
in silenzio una pressione ogni venti.

**LA CAUSA: TRE NUMERI CHE NON SI PARLAVANO.** La fase riannuncia il puntamento ogni
centesimo di grado (per non riempire il bus); la montatura si dichiarava arrivata
sotto mezzo decimo, e dentro quella banda i motori NON si muovevano affatto. Il
cielo intanto gira di 0,15 gradi al secondo vero. Quindi: il tubo restava piantato,
il bersaglio scappava, il residuo cresceva fino a superare il mezzo decimo, il
motore recuperava tutto in un fotogramma, e si ricominciava. Un termostato senza
isteresi, con il cielo al posto della temperatura.

**IL VIAGGIO E' UNO STATO, NON UNA DOMANDA CHE SI RIFA' OGNI FOTOGRAMMA.** Adesso
comincia quando qualcuno manda il tubo lontano davvero (`partenza_gradi`, mezzo
grado) e finisce quando ci e' arrivato (`ARRIVATO`, mezzo decimo). Due soglie
diverse: e' l'isteresi di qualunque termostato, e serve qui per la stessa ragione —
perche' la grandezza misurata attraversa la soglia avanti e indietro da sola.

**MEZZO GRADO NON E' UN NUMERO DI GUSTO.** La pulsantiera muove il tubo di mezzo
grado al secondo contro i dodici del motore: centrando a mano il residuo resta sotto
il centesimo. Il cielo deriva di 0,15 gradi al secondo. Un GOTO sposta il tubo di
decine di gradi. Fra il caso piu' grande che NON deve accendere la scritta e il piu'
piccolo che DEVE c'e' un fattore cento, e mezzo grado sta comodamente in mezzo.

**E LA BANDA MORTA E' SPARITA, che e' l'altra meta' della cura.** Una equatoriale
insegue il cielo di continuo: ogni fotogramma `move_toward` copre un
quattrocentesimo di grado, esattamente quanto serve. Prima non inseguiva —
rincorreva a scatti, ed e' quello che alimentava il lampeggio.

**MISURATO** (`tools/prova_slew.gd`): si guida la montatura a mano, un fotogramma
simulato alla volta, con gli stessi numeri delle fasi, e si contano i CAMBI DI STATO
sul bus per tre gesti diversi.

                          prima            adesso
    GOTO di 40 gradi      2 cambi          2 cambi      giusto tutte e due le volte
    inseguendo, 20 s      95 cambi         0            2,4 lampeggi al secondo
    centrando a mano, 4 s 96 cambi         0            12 lampeggi al secondo

**IL DIFETTO SI RIMETTE**, ed e' per questo che le due soglie sono `@export` e non
`const`: `SENZA_ISTERESI=1` riporta `partenza_gradi` a zero e la banda morta a mezzo
decimo, cioe' la montatura di prima, e la sonda rivede lo sfarfallio. La colonna
«prima» qui sopra e' misurata cosi', non ricordata.

**E LA SONDA CONTROLLA ANCHE CHE IL TUBO SI MUOVA**: una montatura ferma darebbe
zero cambi in tutte e tre le prove e passerebbe a pieni voti. A fine centraggio il
residuo dev'essere sotto la soglia di arrivo, e lo e' — zero.

## D-199 Prendere in mano un oggetto senza toglierlo dal mondo

Federico: «una cosa che mi piacerebbe sarebbe poter raccogliere alcuni oggetti e che
ti restano in mano e ci sia la fisica».

**IL MODO OVVIO E' SBAGLIATO, E NON LO DICE NESSUNO.** Tenere qualcosa in mano in
prima persona si fa in una riga: si riparenta l'oggetto alla camera. Da quel momento
non e' piu' un corpo, e' un pezzo di testa - ti segue perfetto, e attraversa i muri,
i tavoli e il telescopio. Nessun errore, nessun avviso: solo la moka dentro
l'intonaco quando ti avvicini troppo a una parete.

**QUI L'OGGETTO NON VIENE PORTATO, VIENE RINCORSO.** Resta un corpo libero, e a ogni
passo di fisica gli si assegna la velocita' che lo condurrebbe dove sta la mano. Se
in mezzo c'e' un muro, vince il muro. E' la differenza fra appoggiare una cosa su un
ripiano e infilarcela dentro.

**TRE ACCORGIMENTI, E TUTTI E TRE SONO STATI MISURATI PRIMA DI ESSERE SCRITTI.**

1. **Il tetto alla velocita'.** La velocita' che «porta la' in un tick» e' enorme, e
   a quella velocita' un corpo salta oltre un tramezzo prima che il motore se ne
   accorga.
2. **La collisione lungo il percorso** (`continuous_cd`), perche' anche sei metri al
   secondo sono dieci centimetri per fotogramma: quanto uno spessore di intonaco.
3. **La mano non spinge dentro cio' che si tocca gia'.** Questa e' la meno ovvia e ha
   fatto la differenza piu' grande. Il motore le compenetrazioni le risolve DOPO
   averle viste, e va benissimo per un oggetto che cade; ma la mano ogni tick
   riassegna la velocita' che punta dentro il muro, quindi il solver ricomincia da
   capo sessanta volte al secondo e l'affondamento diventa uno STATO. Tolta la
   componente entrante - la stessa cosa che `move_and_slide` fa per il giocatore -
   la mano contro un muro scivola invece di attraversarlo.

                                    dentro un tramezzo da 10 cm
    appesa alla camera              33,0 cm   cioe' nella stanza accanto
    rincorsa, senza i punti 2 e 3    8,9 cm
    piu' collisione sul percorso     6,8 cm
    piu' la componente entrante      0,9 cm   appoggiata alla superficie

**IL PESO SI SENTE PERCHE' IL TETTO SCENDE CON LA MASSA**, e non c'e' nessun'altra
simulazione di sforzo: alla radice della massa, cosi' a quattro chili la mano va a
meta' velocita' e a sedici a un quarto. Diviso per la massa netta, una cassa da dieci
chili non si sposterebbe affatto; con la radice resta faticosa ma trasportabile - che
e' la differenza fra pesante e inchiodata al pavimento.

**LO STRAPPO VUOLE DUE NUMERI COME IL VIAGGIO DEL TELESCOPIO** (D-198). Un oggetto
che sbatte contro uno stipite resta indietro per qualche centesimo di secondo, ed e'
giusto; uno rimasto DIETRO un muro ci resta. Con la sola distanza cadrebbe di mano a
ogni urto: e' il TEMPO a distinguere l'urto dalla separazione. Un metro e dieci per
piu' di un terzo di secondo, e la mano molla.

**E NON SI AZZERA LA VELOCITA' POSANDO**, che e' il lancio: l'oggetto se ne va con
quella che aveva in mano. Girarsi di scatto e mollare lo scaglia, posarlo fermo lo
posa. Non c'e' nessun comando «lancia» da nessuna parte - c'e' la fisica, che e'
quello che era stato chiesto.

**CON LE MANI PIENE `E` POSA, SEMPRE**, anche guardando una porta. L'alternativa lo
spiega: se `E` aprisse la porta quando ne guardo una e posasse quando non ne guardo
nessuna, lo stesso tasto farebbe due cose a seconda di dove sto guardando, e posare
qualcosa vicino a una porta diventerebbe una lotta. Chi deve aprire una porta posa
quello che ha in mano, come nella vita.

**`Carryable` NON EREDITA DA `Interactable`, e non e' una scelta.** Quella e' la
classe di cio' che si usa STANDO DOV'E': uno `StaticBody3D`, che ferma il giocatore
proprio perche' non si sposta. Un oggetto che si porta in giro dev'essere un
`RigidBody3D`. In GDScript l'ereditarieta' e' singola e fra i due non esiste un
antenato comune: il giocatore li tiene in due variabili tipizzate invece che in una
sola con un cast fortunato. Un raggio solo, due letture.

**LA SPINTA COL CORPO ERA MEZZA MECCANICA MANCANTE.** `CharacterBody3D` non sposta i
corpi rigidi che urta - il cinematico scivola e prosegue, il rigido non se ne accorge
- e una scatola che non si smuove quando ci cammini dentro e' un sasso dipinto.
L'impulso e' proporzionale alla massa, cosi' da' a tutti la stessa velocita': un
valore fisso manderebbe le cose leggere in orbita e non muoverebbe le pesanti.

**MISURATO** (`tools/prova_mani.gd`): si costruisce un banco con un muro, si prende
la scatola e SI CAMMINA DENTRO IL MURO - il corpo si ferma, la mano no, quindi ogni
tick chiede all'oggetto di stare dove non puo' stare. E' l'unico momento in cui le
due implementazioni danno risultati diversi.

    mirandola                 il prompt dice «Raccogli la scatola»
    presa                     0,000 m da dove la mano la vuole
    camminando nel muro       0,009 m dentro l'intonaco, su 10 cm di spessore
    posata                    si ferma sul pavimento a y=0,072 (attesi 0,080)
    allontanandosi di 6 m     la mano molla dopo 0,37 s (la soglia dice 0,35)
    camminandoci contro       si sposta di 0,218 m

**IL DIFETTO SI RIMETTE**, ed e' per questo che `mano_rigida` e' `@export` e non una
costante: `MANO_RIGIDA=1` torna al teletrasporto, e la sonda vede la scatola finire a
33 cm dentro un muro spesso 10 - cioe' dall'altra parte. Senza quel confronto il
referto direbbe «non e' entrata nel muro» e nessuno saprebbe se il merito e' della
fisica o del fatto che il muro non e' mai stato toccato.

**GLI OGGETTI VERI NON CI SONO ANCORA, e la ragione sta scritta in `gen_blockout.py`:
«fra un posto vuoto e un posto occupato male, vuoto legge meglio».** La minutaglia
sulla consolle - penne, fogli, telefono - e' fusa nella mesh della stanza e non e'
raccoglibile senza rifare il generatore; e quattro cubi grigi posati in giro sarebbero
esattamente il segnaposto che quella decisione rifiuta. Il meccanismo si prova su
`tools/banco_mani.tscn`, una stanza vuota con quattro scatole da mezzo chilo, due, sei
e quindici: li' i cubi sono la cosa giusta, perche' un banco dev'essere brutto e
sgombro o si finisce per giudicare l'arredamento. Il GDD, al paragrafo «Inventario e
oggetti», e' ancora DA SCRIVERE: quali oggetti si raccolgono e' una decisione che non
si prende scrivendo codice.

## D-200 La camera CCD si avvita al fuoco, e il fuoco lo dice il modello

Federico: «fai la camera CCD da attaccare al telescopio, qualunque prop in giro,
bicchieri, bottiglie ecc...» - e prima, sul trasporto: «non servono le mani, le
teniamo sospese in aria a dx».

**LA MANO STA IN BASSO A DESTRA, E NON AL CENTRO.** Non ci sono braccia da
disegnare e non ce ne saranno: al centro l'oggetto resta sospeso in mezzo alla
faccia, copre il mirino e meta' di dove si sta andando, e la mancanza del braccio
si nota. Nell'angolo in basso a destra legge come «lo sto portando» e lascia
libera la stanza. E' dove ogni gioco in prima persona tiene quello che hai in
mano, da trent'anni e per questa ragione.

**LA CAMERA NON E' INVENTATA, E NEMMENO SCELTA.** Il GDD la nomina per modello -
«SBIG ST-8, chip KAF-1600 da 1530x1020 pixel di 9 micron» con la «SBIG CFW-8,
cinque posizioni» - e dice che va modellata a mano perche' la si guarda da vicino.
Le quote vengono dal SITO DI SBIG DI ALLORA, ripescato dall'archivio del web:

    testa ottica   5 pollici di diametro x 3 di profondita' = 12,5 x 7,5 cm
    peso           2,2 libbre / 1 kg
    attacco        T-Thread, nasi da 1,25" e 2" in dotazione
    back focus     0,92 pollici / 2,3 cm
    CFW-8          cinque filtri da 1,25", aggiunge un pollice di back focus

**E LA FOTO DI CATALOGO DICE QUELLO CHE NESSUNA TABELLA DICE**: cilindro NERO -
alluminio anodizzato - con cinque alette anulari di raffreddamento, base squadrata
col pannello dei connettori dietro, e in cima, DECENTRATO, un blocchetto quadrato
con la ghiera filettata. Trecentocinquanta facce.

**IL PROVINO HA BOCCIATO DUE VOLTE, e tutte e due le volte per un motivo che il
codice non poteva sapere.** Al primo giro il corpo nero usciva GRIGIO CHIARO: non
era il colore, erano le lampade. Le potenze erano copiate dal provino della
pulsantiera - mezzo metro di oggetto, luci a mezzo metro - e qui stavano a venti
centimetri da una camera di dodici, cioe' arrivavano sei volte piu' forti. Un
provino bruciato risponde sempre di si'. Al secondo giro le proporzioni: base,
alette e naso spartiti in parti quasi uguali facevano tre dischi impilati, mentre
nella foto il pacco delle alette prende piu' di meta' dell'altezza.

**IL PUNTO DI ATTACCO NON E' UNA QUOTA, E' UNA DEDUZIONE.** Il focheggiatore nel
modello del telescopio C'E' GIA': i pezzi `Scope1..5` sono cinque cilindri in fila,
tutti alla stessa quota lungo l'asse ottico, che escono dal tubo a **89,8 gradi**
da quell'asse. Novanta gradi e vicino all'apertura vuol dire focheggiatore di
newtoniano; un cercatore starebbe parallelo. Da li' escono la bocca del
portaoculare e il verso in cui esce dal tubo, e `telescopio_blender.py` li scrive
in un Empty `Fuoco` appeso ad `AsseDec` - come gia' faceva per la `Mira`. Se un
domani il modello cambia, la camera si monta dove sta il nuovo focheggiatore senza
che nessuno tocchi il codice di gioco. **E c'e' il controllo che lo pretende**: se
quei pezzi escono a meno di 75 gradi dall'asse, il generatore si ferma invece di
far nascere la camera in mezzo al tubo.

**IL CALCOLO STA VENTI RIGHE PIU' SU DI DOVE SEMBRAVA**, ed e' l'unico posto
possibile: subito dopo i cinquantacinque pezzi vengono FUSI in tre, e `Scope1..5`
smettono di esistere. La prima stesura lo faceva insieme alla Mira e trovava una
lista vuota - divisione per zero, che e' la fortuna: un risultato sbagliato non
avrebbe detto niente.

**MONTATA NON SIMULA, E SMONTATA SI'.** Una camera avvitata al fuoco e' solidale
al tubo: `freeze` e appesa al nodo del fuoco. E' l'unica riparentatura del
progetto, e ha una ragione fisica - la vite - invece che di comodo: un corpo
rigido che inseguisse il focheggiatore a mezz'aria oscillerebbe, sbatterebbe
contro gli anelli e finirebbe per cadere. Staccata torna un `Carryable` come gli
altri, che cade se lo molli.

**IL PROMPT INSEGNA DA SOLO.** Nessun tutorial dice che la camera va avvitata:
tenendola in mano la riga dice «Posa la camera CCD», e quando ci si avvicina al
focheggiatore diventa «Avvita la camera al fuoco». Il cambio E' l'istruzione. Per
farlo senza che il giocatore debba conoscere il telescopio, `Carryable.posa()` e'
un metodo virtuale: il caso speciale sta nella classe che lo conosce, e il
giocatore non nomina ne' la camera ne' lo strumento.

**MISURATO** (`tools/prova_ccd.gd`): non basta guardare che la camera stia al
fuoco - per un fotogramma l'avvitata e l'appoggiata sono identiche. Si MUOVE IL
TELESCOPIO e si guarda se lei c'e' ancora.

                              focheggiatore   camera    scarto dal fuoco
    avvitata (giusto)            +0,573 m     +0,535 m      0,111 m, invariato
    appoggiata (difetto)         +0,574 m      0,000 m      0,626 m

**IL DIFETTO SI RIMETTE** con `CAMERA_APPOGGIATA=1`, che posa la camera sul fuoco
senza appenderla. **E LA GUARDIA DELLA SONDA CIECA ERA SBAGLIATA**: misurava
quanto si e' mossa la CAMERA, cioe' gridava «non ho visto niente» proprio quando
stava vedendo il difetto - col difetto acceso la camera non si muove affatto. Chi
non e' autorizzato a stare fermo e' il telescopio, e adesso la guardia guarda lui.

**I PROP SONO SCARICATI E NON ANCORA POSATI.** Da Poly Haven, CC0: un TERMOS -
in un osservatorio d'Appennino a novembre e' l'oggetto personale per definizione -
delle BOTTIGLIE vuote e un SERVIZIO DA TE'. Non sono decorazioni scelte a caso:
sono le tre cose che uno porta con se' o si lascia dietro passando una notte
sveglio in un edificio freddo. Manca il generatore che li riduce e li posa, ed e'
il passo successivo.

## D-201 Il termos, la bottiglia e la tazza — e un cilindro che non stava fermo

I primi tre oggetti raccoglibili che stanno nel mondo di gioco, da Poly Haven, CC0.
Non sono decorazioni scelte a caso: sono le cose che uno porta con se' o si lascia
dietro passando una notte sveglio in un edificio freddo. **Il termos** e' l'oggetto
personale per definizione di chi sta in un osservatorio d'Appennino a novembre - e
quello arrivato e' smaltato verde con manico e fascette, del tutto giusto per il
1999. **La bottiglia** vuota e **la tazza** sono la traccia che qualcuno ci ha
passato delle ore.

**DOVE STANNO NON E' ARREDAMENTO.** Termos e tazza sulla consolle, all'estremita'
libera: e' il posto dove si passa la notte, ed e' li' che si posa quello che si
beve. La bottiglia PER TERRA di fianco - vuota, messa giu' e dimenticata - perche'
una bottiglia allineata sul piano sarebbe una natura morta, e per terra e' una
traccia.

**SI DECIMANO, ed e' il lavoro vero.** Arrivano da undicimila facce l'uno: sono
fatti per un rendering fermo, non per una scena dove tre di loro rotolano per terra.
Il rapporto si CALCOLA da un budget invece di sceglierlo a occhio - un `ratio` fisso
su modelli da quattromila e da dodicimila facce da' due risultati diversi, e quello
sbagliato e' silenzioso.

    termos      11576 -> 900 facce    308 mm
    bottiglia    6520 -> 700 facce    299 mm
    tazza        4156 -> 499 facce     68 mm

**IL PROVINO GUARDAVA DAL SOFFITTO**, ed e' di nuovo lo scambio di sistemi di
D-195: `scatta()` vuole coordinate DI GIOCO - x e z in pianta, y in alto - mentre i
pezzi erano stati importati e disposti in coordinate di Blender, dove in alto c'e'
z. Nessun errore, e tre oggetti visti a volo d'uccello.

### UN CILINDRO SCHIACCIATO NON STA FERMO, e ci sono volute quattro prove

La tazza appoggiata sulla consolle **girava su se stessa a un giro e mezzo al
secondo, per sempre**. Non si spostava - sedici millimetri in otto secondi - ma non
si fermava e non si addormentava mai. In partita sarebbe stata una tazza che ruota
da sola su una scrivania.

**Le prime tre cure erano ragionevoli e tutte e tre sbagliate**, e vale la pena
elencarle perche' ognuna sembrava LA causa:

1. **`can_sleep = false` tolto.** Era vero che impediva il sonno - e la correzione
   resta, perche' il sonno va escluso solo mentre l'oggetto e' in mano, dove
   `_integrate_forces` deve girare. Ma non era la causa: la tazza restava sopra la
   soglia di sonno comunque.
2. **Smorzamento angolare a 4.** Una rotazione libera con quel valore si spegne in
   un quarto di secondo. La tazza girava uguale, il che diceva una cosa precisa:
   **qualcosa la ri-accelerava a ogni tick**.
3. **Collisione continua accesa solo in mano.** Correzione giusta per altri motivi -
   serve solo quando la mano spinge a sei metri al secondo - ma i numeri sono usciti
   IDENTICI a tre decimali, che e' il modo in cui una misura dice «non e' questo».

**LA CAUSA ERA LA FORMA.** Un `CylinderShape3D` alto sette centimetri e largo dieci
e' la peggiore che si possa dare a un solutore a punti di contatto: appoggiato,
affondava fino al margine di compenetrazione consentito e le correzioni cadevano su
contatti mai perfettamente simmetrici, cioe' sommavano una COPPIA. Con una
`BoxShape3D` la tazza si assesta a **zero millimetri di discesa, velocita' zero, e
si addormenta**. La bottiglia, che e' un cilindro ALTO E STRETTO, non ha mai avuto
il problema: e' il rapporto schiacciato a rompere, non il cilindro.

    con il cilindro   scende 10 mm, va a 0,086 m/s, gira 1,508 rad/s, non dorme mai
    con la scatola    scende  0 mm, ferma,          ferma,            dorme

**E POSARLI UN CENTIMETRO SOPRA IL PIANO ERA UN ERRORE PICCOLO CON UN EFFETTO
LUNGO**: cadendo acquistano velocita' e sfondano il margine del solutore,
assestandosi un centimetro DENTRO il piano invece che sopra. Un millimetro di gioco
basta.

**MISURATO** (`tools/prova_prop.gd`): la sonda non controlla un elenco, cerca da
sola OGNI `Carryable` dell'albero - stessa regola di `prova_rete.gd`, perche'
chiedere al generatore se ha posato bene quello che ha posato lui e' ricopiare la
sua lista in due posti. Di ognuno guarda quanto e' sceso, quanto e' scivolato in
pianta, se si e' fermato, e se sta sul layer che il raggio del giocatore cerca.

**IL DIFETTO SI RIMETTE** con `PROP_IN_ARIA=1`, che alza tutto di un metro prima di
far girare la fisica: tutti e tre scendono di quasi un metro e la sonda li vede.
Senza quel confronto un referto che dice «sono tutti fermi» non direbbe se la sonda
saprebbe accorgersi di uno che se n'e' andato in cantina.

## D-202 La roba disegnata dentro il muro diventa roba

Federico, provando: «sarebbe bello poter prendere ogni oggetto, ogni prop. Ad
esempio le tazze in cucina, la bottiglia in cucina, la radiolina in cucina».

**ERANO DISEGNATE DENTRO LA STANZA.** La bottiglia contro il paraschizzi, la
radiolina di fianco, la tazza sul tavolo: tre gruppi di primitive fusi nella mesh
della cucina. Fusi vuol dire che non erano oggetti - erano rilievi del piano di
lavoro. Si vedevano, e non si potevano toccare nemmeno volendo.

Adesso sono corpi, e stanno negli stessi punti in cui stavano disegnate: le quote
vengono da `CucinaBase` e `Tavolo` in `geometria.py`, le stesse che usava
`cucina_blender.py`. **Spostare il bancone sposta la bottiglia**, che e' il punto
di prenderle da li' invece di ribatterle.

**LA RADIOLINA SI E' TRASFERITA, NON RIFATTA**: `tools/radiolina_blender.py`
riporta le stesse quattro primitive con le stesse quote - ventidue centimetri di
cassa, l'altoparlante forato, la manopola, l'antenna telescopica - attorno a
un'origine propria. Trentasei facce.

**LA TAZZA HA IL SUO PIATTINO, E SONO DUE CORPI**: si prendono uno alla volta,
come nella vita. Una tazza senza piattino su un tavolo di servizio non e'
apparecchiata - e' stata usata.

**DUE BOTTIGLIE DIVERSE E NON DUE VOLTE LA STESSA**: dallo stesso set esce anche
la borgognona, spalla dolce e pancia larga, che va in cucina; la bordolese resta
in sala di controllo. Due sagome identiche in due stanze diverse sono la cosa che
fa sembrare un edificio un catalogo, e costano una riga.

    in sala controllo   termos, tazza, bottiglia (bordolese)
    in cucina           bottiglia (borgognona), radiolina, tazza, piattino
    in cupola           la camera CCD, avvitata al fuoco

**MISURATO**: tutti e sette si assestano dove sono stati posati - il piu' mosso
scende di nove millimetri - e sei su sette si addormentano.

## D-203 Le hitbox sono blocchi pieni, e gli oggetti che cadono lo hanno rivelato

Federico ha fotografato un termos **sospeso a mezz'aria** in mezzo alla sala
proiezioni, e ha scritto: «tocchera' mettere a posto le hitbox». Ha ragione, e la
cosa interessante e' PERCHE' NON SI ERA MAI VISTO.

**PER UN ANNO IN QUESTA SCENA SI E' POTUTO SOLO CAMMINARE.** La collisione degli
arredi la genera `gen_blockout.py` da `geometria.py`, e ogni mobile e' UN BLOCCO
PIENO alto quanto il suo pezzo piu' alto. Per camminare e' perfetto: non si
attraversa una fila di sedie, non si passa dentro un carrello. Il difetto - che il
blocco e' pieno dove il mobile e' vuoto - non si sente, perche' non c'e' niente
che possa appoggiarcisi.

Poi sono arrivati gli oggetti che cadono, e tutte le superfici finte sono diventate
visibili in una volta sola. Misurate nella sala proiezioni:

    FilaSedie1, FilaSedie2   blocco pieno 2,20 x 0,54, TOP A 0,90
                             cioe' un muretto all'altezza degli schienali; un
                             oggetto posato sta a novanta centimetri, sopra il
                             vuoto fra uno schienale e l'altro
    Proiettore               blocco pieno 0,80 x 0,60, TOP A 1,05
                             il carrello ha il piano a 0,75 e il proiettore
                             sopra: la superficie a 1,05 e' aria
    TavoloSala               top 0,78 - giusto, e' un tavolo
    TecaEst1, TecaEst2       top 1,85 - giusto, sono armadi chiusi

**NON E' UN NUMERO DA CORREGGERE, E' UNA FORMA DA DICHIARARE.** Un tavolo e un
armadio sono blocchi pieni davvero; una sedia e' un sedile a 0,45 piu' uno
schienale sottile; un carrello e' due ripiani. Finche' la collisione la fa
l'ingombro, le cose si appoggeranno all'ingombro.

Il lavoro non e' stato fatto qui - tocca la collisione di tutto l'edificio, ed e'
una decisione su come si dichiarano gli arredi, non un rattoppo. **Quello che e'
stato fatto e' isolare la causa con un numero**, cosi' chi ci mette mano sa che
cosa sta guardando.

**E UNA SONDA E' STATA BUTTATA VIA**, che vale la pena raccontare. La prima
versione cercava i blocchi «senza niente da vedere dentro» confrontandoli con i
VERTICI delle mesh visibili: ne ha trovati 1758 su 78 superfici, quasi tutti
falsi. Il motivo e' banale e istruttivo - una superficie piana grande ha vertici
solo AGLI ANGOLI, quindi in mezzo a un pavimento non c'e' nessun vertice entro
quindici centimetri e ogni pavimento risultava invisibile. Uno strumento che grida
millesettecento volte non e' uno strumento: e' rumore con un referto. La diagnosi
vera e' venuta da dieci righe usa-e-getta che, stanza per stanza, dicono a che
quota si appoggia un oggetto e su quale corpo.

## D-204 Quello che si prende in mano si raddrizza, e la ragione contraria era sbagliata

Federico, dopo la prima cura: «l'ho raccolto di nuovo nella stessa posizione in cui
l'ho raccolto e non si era drizzato».

**LA MOTIVAZIONE SCRITTA IN D-199 ERA SBAGLIATA, e vale la pena lasciarla scritta
com'era**: «si conserva com'era invece di raddrizzarlo; raccogliendo, l'oggetto
scatterebbe all'orientamento canonico - la moka che si gira da sola col beccuccio
in avanti - e quello scatto dice "sono un gioco" a voce alta». Suona bene, ed e'
falso: quello che dice «sono un gioco» e' una bottiglia che, caduta di traverso,
resta di traverso in mano per sempre, e per rimetterla in piedi bisogna sperare
che cada bene.

**CHI RACCOGLIE UNA BOTTIGLIA CORICATA LA METTE DRITTA.** Non e' una concessione:
e' quello che fa il polso, senza pensarci, e non farlo e' la cosa che si nota.

E' costato due giri perche' il primo ha curato la meta' sbagliata. Il difetto
originale - «se lo prendo guardandolo dall'alto verso il basso, quando lo sollevo
lo sollevo guardandolo sempre dall'alto verso il basso» - sembrava un problema
della TESTA, e la cura (conservare la sola imbardata invece di tutta la testa) ha
tolto l'inclinazione dello SGUARDO lasciando quella dell'OGGETTO. Con l'oggetto
gia' dritto per terra non si vedeva piu' niente; con l'oggetto caduto tornava
tutto.

**ADESSO NON C'E' NESSUNA VARIABILE DA CONSERVARE**: in mano l'orientamento e'
quello canonico del modello - dritto, col fronte verso chi guarda - ruotato della
sola imbardata della testa. Gira con te quando ti volti, e non si inclina mai. Il
codice e' `_imbardata()` e basta, ed e' piu' corto di quello che sostituisce.

**MISURATO** (`tools/prova_mani.gd`): la scatola viene coricata di novanta gradi e
raccolta con lo sguardo quarantanove gradi sotto l'orizzonte - i due difetti
insieme, che e' il caso che li mostra tutti e due.

    con la vecchia presa   in mano pende di 90,0 gradi
    adesso                 in mano pende di  0,0 gradi

## D-205 Due collisioni: gli ingombri per il corpo, i triangoli per le cose

Federico, seconda foto e tre parole: «hitbox non sistemate». Una radiolina a
mezz'aria sopra il carrello del proiettore, dopo il termos di ieri.

**IL DIFETTO E' STRUTTURALE E HA UN'ETA'.** La collisione di questa scena la
genera `gen_blockout.py` da `geometria.py`, e ogni mobile e' UN BLOCCO PIENO alto
quanto il suo pezzo piu' alto. Per camminare e' perfetto: non si attraversa una
fila di sedie, non si passa dentro un carrello, e il giocatore non ha mai avuto
modo di accorgersi che quel blocco e' pieno dove il mobile e' vuoto. **Per un anno
in questa scena si e' potuto solo camminare.** Poi sono arrivati gli oggetti che
cadono, e ogni cima finta e' diventata un posto dove la roba resta sospesa.

    misurato su 84 blocchi di arredo: 31 fanno appoggiare dove non c'e' niente
    FilaSedie1, FilaSedie2   cima a 0,90 - ZERO per cento di materiale
    Proiettore               cima a 1,05 - ZERO per cento (il ripiano e' a 0,78)
    SediaC1, SediaC2         cima a 0,92 - ZERO per cento (il sedile e' a 0,45)
    Lavabo                   cima a 1,90 - e' l'altezza dello specchio

**PERCHE' NON SI CORREGGONO I BLOCCHI.** Si potrebbe dichiarare, mobile per
mobile, la forma vera: sedile piu' schienale, carrello a due ripiani. Sono trenta
mobili, ognuno con la sua forma, e ogni numero sarebbe indovinato guardando un
modello che ha fatto qualcun altro - trenta occasioni di sbagliare in silenzio, e
un lavoro da rifare a ogni modello nuovo.

**SI FA IL CONTRARIO: SI DA' AL MOTORE LA GEOMETRIA CHE SI VEDE.** `world/corazza.gd`
costruisce all'avvio una collisione a triangoli di ogni mesh visibile, su un layer
suo, e gli oggetti che si posano cadono su quella invece che sugli ingombri. Da
quel momento la regola e' una sola e non ha eccezioni: **ci si appoggia dove si
vede**. Nessun numero da tarare, nessun mobile da dichiarare, e un modello nuovo
porta con se' la propria collisione.

    233 mesh, 240.287 triangoli, costruiti in 331 ms all'avvio

**IL GIOCATORE RESTA SUGLI INGOMBRI, ED E' VOLUTO.** Camminare su una geometria a
triangoli vuol dire incastrarsi fra le gambe di una sedia, salire su una pila di
libri, restare appesi a uno spigolo: problemi che i blocchi grezzi non hanno, e
che risolverli costerebbe piu' di quanto valgano. I blocchi sono giusti per il
corpo e sbagliati per gli oggetti; adesso ognuno ha i suoi.

**E LA COLLISIONE CONTINUA TORNA ACCESA SEMPRE.** Era stata tolta a corpo libero
per curare una tazza che non si fermava mai, e la causa era un'altra - la forma
del suo collisore (D-201). Riaccenderla non era facoltativo: i triangoli hanno
SPESSORE ZERO, e un corpo lasciato cadere da un metro e mezzo copre nove
centimetri per fotogramma. Misurato: senza, una sonda lasciata cadere sul carrello
ha attraversato il carrello, il pavimento e le fondamenta, fermandosi a
ventitre metri sottoterra.

**MISURATO** (`tools/prova_appoggi.gd`), e nel modo in cui il difetto e' comparso:
lasciando cadere qualcosa. I bersagli non si scelgono a mano - si cercano i
blocchi la cui cima e' quasi tutta aria e si lascia cadere una sonda proprio li',
nel punto piu' lontano dalla cima finta.

                         cima del blocco   geometria vera   dove si ferma
    Proiettore                1,05             0,98            0,78
    FilaSedie1                0,90             0,77            0,45
    FilaSedie2                0,90             0,75            0,40
    SediaC1                   0,92             0,83            0,47
    Lavabo                    1,90             0,95            0,80

**IL DIFETTO SI RIMETTE** con `SUGLI_INGOMBRI=1`, che riporta la sonda a cadere
sui blocchi grezzi: si ferma esattamente a 1,05, a 0,90, a 1,90 - cioe' sulla cima
finta, che e' il termos e la radiolina delle due fotografie.

**E DUE SONDE SONO STATE BUTTATE VIA PRIMA DI QUESTA**, per lo stesso errore
commesso due volte: cercavano la geometria visibile guardando i VERTICI. Una
superficie piana ha vertici solo AGLI ANGOLI - in mezzo alla cima di un frigo non
ce n'e' nessuno - e cosi' la prima versione ha bocciato 82 blocchi su 84, frigo e
teche compresi. La geometria vera si chiede al motore, costruendo la collisione e
tirandoci un raggio: e' lui a sapere dove ci si posa.

---

## D-206 La camera CCD rifatta sulle sue fotografie, e un provino che mentiva

Federico, con in mano la foto di una SBIG rossa: «ti ho aperto blender, vorrei che
mi facessi una camera ccd fatta meglio rispetto a quella che abbiamo messo ora.
prendi questa come riferimento».

**LA FOTO DI RIFERIMENTO ERA DI UN'ALTRA CAMERA, e valeva la pena dirlo.** Il
corpo rosso squadrato con la piastra nera e il barilotto e' una SBIG della serie
STF/STT-8300: e' del 2011, e questo gioco e' ambientato nel 1999 con una ST-8
nominata per modello e per chip nel GDD. Le due strade erano davvero diverse - una
camera bella e anacronistica, oppure la ST-8 vera fatta bene - e la scelta l'ha
fatta lui: la ST-8. Del riferimento resta quello che era il vero motivo per cui
piaceva, e che non ha eta': le viti a vista, gli spigoli netti, il contrasto fra
corpo opaco e metallo lucido.

**LA PRIMA ST-8 ERA COPIATA DA UNA FOTO SOLA, ED ERA SBAGLIATA.** Era un cilindro
in piedi su una base quadrata, e nel provino leggeva come una scatola di biscotti.
Cercandole, di fotografie ne sono uscite tre, e ognuna diceva una cosa che le
altre non dicevano:

    catalogo SBIG (Company Seven, ST-7.jpg)   la piastra frontale circolare con
                                              le sei brugole, il pacco alettato,
                                              il vano quadrato che sporge dagli
                                              angoli, il naso decentrato
    ST-8E su un C14 (Pedro Re')               il RETRO: ventola avvitata fuori,
                                              griglia di feritoie, etichetta
                                              bianca col marchio CE, una spia
    catalogo CFW-8 (Company Seven)            la ruota e' un disco piatto con la
                                              GOBBA TONDA del motore sul bordo

**IL NASO DECENTRATO NON E' UN VEZZO.** La CFW-8 e' un carosello che gira attorno
al proprio perno, e l'asse ottico passa per UNA delle cinque posizioni: e' per
questo che il naso non e' in mezzo al disco, ne' nel modello ne' in catalogo.
Saperlo ha cambiato la geometria: prima ruota e naso erano concentrici, e il pezzo
non poteva funzionare.

**IL PROVINO MENTIVA, E NON PER COLPA DEL MODELLO.** Due giri sono stati giudicati
su un'inquadratura sbagliata: la camera nasce con l'asse ottico in su - lo vuole il
montaggio - e fotografata in quella posa sembra una torta a strati qualunque cosa
ci sia sotto. Coricata, che e' come sta in catalogo ED e' come sta in gioco -
avvitata a un telescopio che punta il cielo - lo stesso identico modello legge come
una camera CCD. La rotazione sta dopo `esporta()`: il .glb non se ne accorge.
E' lo stesso errore di D-174 fatto un piano piu' su: non «non l'ho guardato», ma
«l'ho guardato da dove non lo si guarda mai».

**DUE DIFETTI TROVATI SOLO GUARDANDO.** La ventola era una scatola PIENA con
dentro il suo pozzetto, e una scatola piena non ha un dentro: e' uscita una
piastrina liscia con quattro viti. Ora la cornice sono quattro barre attorno a un
buco. E l'etichetta usava `Carta`, che porta la trama della carta a trenta
centimetri per ripetizione: su una targhetta da tre centimetri se ne vede un
decimo, cioe' un rettangolo beige rigato che leggeva come compensato incollato
dietro la camera. Una targhetta stampata e' una tinta piatta.

**IL NASO E' DI TRE CENTIMETRI, E LA CAMERA E' 12,7.** Un barilotto da un
centimetro e mezzo legge come un tappo. Il numero che NON e' cambiato e' `ALTA` in
`ccd_camera.gd`, che resta 0,111: non e' l'altezza dell'oggetto, e' di quanto si
arretra per montarla - il centimetro e mezzo di differenza e' il pezzo di naso che
sta DENTRO il portaoculare, che e' come si avvita davvero. Il collisore invece
segue l'ingombro e passa a 0,127.

**MISURATO.** 617 facce in cinque pezzi (il tetto e' 3.000), e le tre prove che
toccano questo oggetto passano: `prova_ccd` - montata, resta al fuoco dopo un GOTO,
smontata cade e si riavvita - piu' `prova_mani` e `prova_prop`.

### E POI, IN PARTITA: «non mi sembra attaccata bene»

Il modello era giusto e il montaggio no. Avviato il gioco, la camera stava
appiccicata al FIANCO del tubo invece che avvitata al focheggiatore, e la
sequenza per cui questo e' arrivato fino a li' vale piu' del difetto:

**UNA CONVENZIONE DATA PER BUONA.** `ccd_camera.gd` posava la camera lungo il -Z
del nodo `Fuoco`, «che e' la convenzione di Godot per dove guarda un nodo». Vero
per i nodi che scrive Godot: il `Fuoco` pero' lo esporta Blender, dove `perno()`
allinea al verso del focheggiatore il proprio **+Z** - e il +Z di Blender,
attraversato il glTF, diventa il **+Y** di Godot. La camera finiva quindi
spostata di undici centimetri in una direzione perpendicolare a quella giusta, e
girata di conseguenza.

**E LA PROVA DICEVA OK, perche' misurava la cosa sbagliata.** `prova_ccd.gd`
controllava lo SCARTO dalla bocca - 0,111 m - e lo scarto di una camera montata
di traverso e' identico a quello di una montata dritta. E' D-176 un'altra volta:
un controllo che tace non perche' sia debole, ma perche' guarda un numero che il
difetto non cambia.

**«FUORI DAL TUBO» ORA SI MISURA, NON SI DICHIARA.** La Mira sta sull'asse ottico
del tubo, il Fuoco sulla bocca del focheggiatore: la componente della bocca
perpendicolare all'asse E' la direzione in cui si monta, e non dipende da nessuna
convenzione. La prova adesso chiede due cose che prima non chiedeva:

                                        prima         adesso
    retro fuori dalla bocca            -0,009 m      +0,106 m
    naso che guarda dentro (1 = dritto) -0,08         +0,95

Lo 0,95 e non 1,00 e' giusto: il focheggiatore di un newtoniano non esce
esattamente perpendicolare all'asse ottico, e il modello del telescopio lo
accetta fino a quindici gradi di obliquita'.

**LA LEZIONE E' LA STESSA DEL PROVINO, un piano piu' su.** Il provino mentiva per
l'inquadratura, la prova taceva per la grandezza misurata: in tutti e due i casi
il difetto era visibile a chiunque avviasse il gioco, e nessuno aveva avviato il
gioco. La costante `POSA` adesso sta scritta una volta sola e la usano tutti e
due i rami, quello vero e quello col difetto rimesso.

### E ANCORA: «non mi sembra della dimensione giusta»

Montata dritta, la camera continuava a non convincere. Aveva ragione, e la causa
non era la camera:

    la camera CCD, misurata in scena     0,125 x 0,126 x 0,125 m, scala 1,00
    il tubo del telescopio, all'apertura 0,54 m di diametro
    quanto dovrebbe essere              ~0,35 m (il Newton da 30 cm del GDD)

**IL TELESCOPIO E' UN QUARTO PIU' GROSSO DEL SUO NOME.** Il modello e' un asset
Sketchfab scalato perche' il tubo sia lungo 1,50 m - la quota del GDD, quella che
deve passare nel pozzo della passerella - ma il modello di partenza e' tozzo, e
con quella scala il diametro viene 54 cm invece di 35. Su un tubo cosi', un
oggetto in scala VERA sembra piccolo: il rapporto giusto e' 1 a 2,8, li' era 1 a
4,3.

**RIDURRE TUTTO IL TELESCOPIO NON SI POTEVA** senza perdere l'altra quota: il
modello e' sproporzionato, e portandolo a 35 cm di diametro il tubo scenderebbe a
un metro scarso di lunghezza. Nessuna scala uniforme lo rende un 30 cm f/5.

**SI E' RIDOTTO IL SOLO FOCHEGGIATORE**, i pezzi `Scope1..5`, PRIMA che il
modellatore li fonda e prima che calcoli la bocca - cosi' il nodo `Fuoco` si
sposta da solo e la camera lo segue senza che nessuna quota sia scritta due volte.
Tubo, montatura, collisioni e pozzo della passerella non si muovono.

**E IL NUMERO NON L'HA SCELTO LO SBRACCIO, L'HA SCELTO IL DIAMETRO.** La
contrazione e' uniforme, quindi accorciare assottiglia: a 22 cm di sbraccio il
focheggiatore restava piu' LARGO della camera avvitata in cima, che e' il
contrario di qualunque fotografia vera - la camera e' il pezzo grosso, il
focheggiatore quello che ci si infila dentro. A 16 cm il porta-oculare viene sugli
otto centimetri, cioe' un due pollici, e il rapporto si ribalta nel verso giusto.
E' un numero deciso GUARDANDO, non calcolando.

**UNA MISURA SBAGLIATA, DETTA COM'E' ANDATA.** Il primo conto diceva che il
focheggiatore sporgeva 82 cm: era la distanza della bocca dal nodo `Mira`, presa
per distanza dall'asse del tubo. Ma su una montatura alla tedesca il tubo e'
appeso DI LATO alla barra di declinazione, e la Mira sta sull'asse ottico che
passa per quel perno, mezzo metro sotto l'asse vero del tubo. La misura onesta e'
la lunghezza della catena `Scope1..5`, che il modellatore stampa: **32 cm**,
ridotti a 16. Il difetto era reale e il rimedio e' lo stesso, ma il numero da cui
ero partito no.

**MISURATO**: `prova_ccd`, `prova_fuoco`, `prova_puntamento` e `prova_slew`
passano tutte dopo il cambio. I due provini d'assieme stanno in
`_confronto/13d_ccd_sul_telescopio.png` e `13e_ccd_al_fuoco.png`.

### «era la versione vecchia, non hai cambiato nulla no?»

Aveva ragione lui. Il focheggiatore era stato ridotto, le prove passavano, i
provini in Blender lo mostravano corto - e in partita il telescopio era ancora
quello di prima.

**IL GIOCO NON CARICA `telescopio.glb`.** Lo carica dentro `osservatorio.glb`:
`osservatorio_blender.py` importa il telescopio e la cupola e li ESPORTA DENTRO il
proprio .glb, e la scena istanzia solo quello (`ExtResource("2_modello")`).
Rigenerare il telescopio senza rigenerare l'osservatorio lascia in partita una
copia del vecchio, e nessuno se ne accorge: i due file esistono tutti e due, hanno
entrambi il nodo `Fuoco`, e tutte le prove passano - perche' passano su una
geometria coerente con se stessa, solo che e' quella sbagliata.

**IL CONTROLLO C'ERA GIA', E AVREBBE PARLATO.** `gen_blockout.py` ha in cima
proprio questa regola - «chi incorpora chi»: se `telescopio.glb` e' piu' nuovo di
`osservatorio.glb`, stampa MODELLO VECCHIO. Non ha taciuto: non l'ho RICHIAMATO.
L'avevo eseguito prima di toccare il telescopio, per il collisore della camera, e
poi non piu'. Un controllo che si esegue una volta sola all'inizio del lavoro e'
un controllo che verifica lo stato in cui il lavoro e' cominciato.

**E LE DATE DICEVANO CHE ERA TUTTO A POSTO.**

    assets/models/telescopio.glb              09:50:47
    .godot/imported/telescopio.glb-....scn    09:51:25   piu' recente: importato
    assets/models/osservatorio.glb            del giorno prima   <- il file vero

Guardando le date del file che avevo cambiato, la catena sembrava perfetta. Era il
file sbagliato.

**QUELLO CHE HA SVELATO IL TRUCCO E' UNA MISURA FATTA DUE VOLTE**: la stessa
distanza `Mira`-`Fuoco`, presa nel .glb con Blender e nella scena con Godot.

                          prima          dopo aver rifatto l'osservatorio
    Blender (il .glb)     0,9691 m       0,9691 m
    Godot (il gioco)      1,1150 m       0,9691 m

Una data dice quando un file e' stato scritto, non che cosa contiene ne' chi lo
legge. Due misure della stessa grandezza in due posti diversi dicono se i due
posti hanno la stessa cosa - ed e' l'unico modo che ho trovato per rispondere a
«ma l'hai davvero cambiato?» senza chiedere di fidarsi.

**MISURATO** dopo la rigenerazione: `prova_ccd`, `prova_puntamento`, `prova_slew`
e `prova_appoggi` passano, e `gen_blockout.py` non segnala piu' la coppia
telescopio/osservatorio (restano i sei modelli piu' vecchi di `geometria.py`, che
sono di un'altra storia).

### Il focheggiatore ridotto e' stato RIMESSO COM'ERA

Visto in partita con il modello finalmente aggiornato, il giudizio e' stato
«peggio di prima», e la riduzione e' stata annullata su richiesta:
`telescopio_blender.py` e' tornato alla sua versione, il telescopio e
l'osservatorio sono stati rigenerati, e in gioco `Mira`-`Fuoco` e' di nuovo
1,1150 m.

**LA RIDUZIONE CURAVA IL SINTOMO SBAGLIATO.** Il focheggiatore accorciato avvicina
la camera al tubo, ma quello che non torna sta un piano sopra: il tubo e' largo 54
cm dove un Newton da 30 ne vuole 35, e su un tubo cosi' la camera CCD - che e'
giusta al millimetro, 12,5 cm - vale un quarto del diametro invece di un terzo.
Accorciare il focheggiatore sposta la camera senza cambiare quel rapporto: prima
sembrava lontana, dopo sembrava piccola e appiccicata. Il difetto non era dove lo
stavo curando.

**LA CAUSA VERA HA UNA MANOPOLA SOLA**, `L_TUBO` in `telescopio_blender.py`: la
scala dell'intero strumento esce da li' (`SCALA = L_TUBO / lungo_tubo`), e il
pilastro e' l'unico pezzo che modelliamo noi, quindi si puo' rimpicciolire il
telescopio e ALZARE il pilastro per lasciare il fuoco alla stessa quota - che e'
poi come si dimensiona il pilastro di un osservatorio vero. E il GDD lo
permetterebbe: il suo vincolo sul pozzo della passerella («un 40 cm f/4,5 non ci
passerebbe») e' un MASSIMO, non una misura da rispettare.

**NON SI FA ORA, ED E' UNA SCELTA SUA.** Fra rimpicciolire lo strumento e lasciare
tutto com'e' ha scelto di lasciare: il telescopio grosso resta, e resta scritto
qui che cosa lo renderebbe giusto, se un giorno tornera' a dare fastidio. Quello
che resta fatto e' la camera - modellata sulle sue fotografie, montata dritta - e
la prova che adesso guarda anche il verso.

### Alla fine: il focheggiatore SI STRINGE, e non si accorcia

«Non puoi solo restringere il focheggiatore?» - ed era la domanda giusta, quella
che io non avevo fatto. Accorciarlo avvicinava la camera al tubo e perdeva il
fatto che una camera CCD sta in fondo a un braccio; stringerlo lascia tutto dov'e'
e cambia l'unica cosa che non tornava.

**IL NUMERO CHE NON TORNAVA ERA IL DIAMETRO.** Misurato sul .glb: il porta-oculare
di questo modello e' un tubo da 11-13 cm, e la camera CCD che ci si avvita in cima
ne misura 12,5. Sono LA STESSA COSA - ed e' per questo che la camera non leggeva
come una camera ma come un tappo in fondo a un tubo largo uguale. Su uno strumento
vero il rapporto e' il doppio: un focheggiatore da due pollici sta sui sette
centimetri. Stretto in sezione per 0,62, il rapporto si ribalta nel verso giusto e
la camera torna a essere il pezzo grosso dei due.

**TRE MODI SBAGLIATI DI SCALARE ATTORNO A UN ASSE.** La scala non uniforme attorno
a una retta obliqua si scrive `T(c) R S R-1 T(-c)`, ed e' esattamente li' che ho
sbagliato due volte di fila:

    con to_track_quat("Z","Y")   il focheggiatore esce lungo Y, e passare "Y"
                                 come «in su» e' il caso degenere: la rotazione
                                 che torna e' arbitraria
    con una base a mano          misurato: il raggio massimo passava da 8,8 cm a
                                 72,7 - non stringeva, ALLARGAVA
    spostando i vertici          per ogni vertice, la parte lungo l'asse resta e
                                 la perpendicolare si moltiplica. 8,8 -> 5,5 cm,
                                 baricentro immobile

Cinque righe che si leggono battono una matrice elegante che non si riesce a
verificare a occhio. E la verifica non e' stata guardare il codice: e' stato
stampare il raggio massimo prima e dopo.

**E C'ERA GIA' UN CONTROLLO CHE GRIDAVA.** Con le due versioni sbagliate il
telescopio non scendeva piu' sotto i 44 gradi senza toccare la passerella (contro
i 25 di sempre): il modellatore lo dice da solo, ed era il sintomo dello
spostamento, non un caso. Con la stretta giusta e' tornato a 25 gradi. Un
controllo che urla per una ragione diversa da quella che stai cercando resta un
controllo che ha ragione.

**MISURATO**: fuoco a 2,45 m e a 90 gradi dall'asse ottico come prima della
stretta, passerella libera sopra 25 gradi, e `prova_ccd`, `prova_puntamento`,
`prova_mani`, `prova_appoggi` e `prova_prop` passano tutte.

---

## D-207 Il muro invisibile sulle porte era la fotografia di un'anta chiusa

Federico, mentre guardava il telescopio: «ho provato a prendere in mano la
borraccia nello studio ma letteralmente non puo' uscire dalla porta a causa di un
muro invisibile».

**LE DUE COLLISIONI SI SONO SFASATE.** Da D-205 questo mondo ne ha due: gli
INGOMBRI, blocchi grezzi su cui cammina il giocatore, e gli APPOGGI, la geometria
vera a triangoli con cui collide la roba che si prende in mano. La corazza degli
appoggi si costruiva mettendo tutte le forme sotto UN corpo statico e copiando la
`global_transform` di ogni mesh AL MOMENTO DELL'AVVIO. Per un muro va benissimo.
Per un'ANTA no: all'avvio le porte sono chiuse, e da li' in poi nel vano restava
la sagoma dell'anta chiusa, ferma per tutta la partita, mentre l'anta vera girava
via.

**E IL DIFETTO ERA CIECO PER CHI CAMMINA.** Il giocatore attraversa il vano
perche' lui sta sugli ingombri, dove il buco c'e'; la borraccia che tiene in mano
sta sugli appoggi, e sbatteva contro una porta che sullo schermo era spalancata.
Un difetto che si vede solo tenendo qualcosa in mano, e solo passando una porta.

**MISURATO** (`tools/prova_varchi.gd`, nuovo): si apre ogni porta e si tira un
raggio nel centro esatto del vano - centro preso PRIMA di aprire, dalla mesh
dell'anta chiusa, che e' per definizione il buco che l'anta riempie - su tutti e
due i mondi.

                            ingombri      appoggi
    prima, 7 porte su 7     liberi        OSTRUITI
    dopo,  7 porte su 7     liberi        liberi

**LA CURA E' UNA RIGA DI PARENTELA.** Ogni forma non sta piu' sotto un corpo
unico: sta appesa alla PROPRIA MESH, dentro uno `StaticBody3D` figlio a
trasformata identita'. Cosi' eredita le trasformazioni di chi la porta - l'anta
gira e la sua sagoma gira con lei - e non c'e' niente da aggiornare a mano.
Costa 233 corpi statici invece di uno; nel BVH e' la stessa cosa.

**E NON RIGUARDAVA SOLO LE PORTE.** Con la corazza congelata all'avvio, ogni cosa
che si muove lasciava una crosta dov'era: la cupola che ruota, i portelli, il
telescopio che insegue. Nessuno ci aveva ancora sbattuto contro perche' l'unica
cosa che tocca gli appoggi e' la roba che si porta in giro, e la si porta in giro
al piano terra.

**IL DIFETTO SI RIMETTE** con `CORAZZA_FERMA=1`, che riporta la corazza al corpo
unico. Non e' un vezzo: senza, `prova_varchi` direbbe «va bene» anche in un mondo
dove il raggio non colpisce niente perche' la corazza non e' stata costruita - ed
e' successo davvero, alla prima sonda che ho scritto. Girava con `--script`, dove
gli autoload non esistono, `corazza.gd` non compilava (`Log` mancante), il layer
degli appoggi era VUOTO e ogni vano risultava libero. La sonda diceva «tutto a
posto» misurando un mondo senza corazza. Col difetto rimesso la prova pretende di
trovare 7 vani murati su 7: se non li trova, dichiara se stessa cieca.

---

## D-208 Il pilastro stava sotto il punto sbagliato

Federico, guardando la sala dall'alto: «tutta la base del telescopio e' shiftata
fuori dal pilastro». Ed era vero: la colonna della montatura appoggiava sul BORDO
del pilastro, con mezzo piede nel vuoto.

**LA PREMESSA ERA GIUSTA E LA CONCLUSIONE NO.** Il file lo dichiarava a chiare
lettere: «IL PILASTRO VA SOTTO L'INCROCIO DEGLI ASSI, non sotto la colonna della
montatura», e il motivo scritto accanto era corretto - su una equatoriale tedesca
l'asse polare e' inclinato, e il punto attorno a cui gira tutta la testa sta
ventun centimetri di lato rispetto alla colonna. Se si centra la COLONNA sotto la
cupola, quel punto finisce scentrato e tutto cio' che ruota spazza un cerchio
storto.

Ma da «l'incrocio degli assi va al centro della cupola» non segue «il pilastro va
sotto l'incrocio». Un pilastro regge quello che ha sopra: sta sotto la COLONNA, e
l'incrocio degli assi gli passa di fianco - e' cosi' in ogni osservatorio, ed e'
il motivo per cui i pilastri veri hanno la testa sfalsata rispetto al fusto. Le
due cose non erano mai state in conflitto: si centra il TELESCOPIO sull'incrocio,
come si faceva, e poi si sposta il PILASTRO sotto il piede.

**DOVE APPOGGIA DAVVERO, misurato invece che dichiarato:** il centro in pianta
dei vertici piu' bassi dei pezzi FISSI, cioe' del piede della colonna. Non il
baricentro della montatura, che e' una L e ha il centro per aria; non l'origine,
che e' l'incrocio degli assi.

    spostamento del pilastro          0,20 m
    raggio del piede della montatura  0,18 m
    raggio del pilastro               0,25 m   -> il piede ci sta dentro tutto

**E ORA C'E' UN CONTROLLO CHE LO DICE**: se il piede della montatura ha raggio
maggiore del pilastro, il modellatore grida «la base sporge nel vuoto» invece di
lasciarlo vedere a chi gioca. Era esattamente il difetto che nessuno misurava.

**MISURATO**: `prova_ccd`, `prova_puntamento`, `prova_slew` e `prova_varchi`
passano, e la passerella resta libera sopra i 25 gradi come prima dello
spostamento.

---

## D-209 La borraccia sul carrello: si posava dove si vede, e da li' non si riprendeva

Federico, giocando: «ho preso la borraccia dalla stanza di controllo, l'ho messa
sul carrello dove c'e' il proiettore, e non potevo piu' prendere la borraccia».
Non era caduta e non era sparita: si vedeva li' sul ripiano, e il prompt non
compariva.

**E' IL SEGUITO ESATTO DI D-205, dall'altro capo.** Quella decisione ha dato al
mondo due collisioni: gli INGOMBRI - un blocco pieno per mobile, alto quanto il
suo pezzo piu' alto - su cui cammina il giocatore, e la GEOMETRIA VERA su cui si
posano le cose. Da allora un oggetto si posa dove si vede. Ma la MIRA era rimasta
sugli ingombri, e le due copie del mondo non dicono la stessa cosa proprio dove
serve:

    carrello del proiettore   ingombro alto 1,05
                              ripiano vero      0,72
                              una cosa posata li' sta 33 cm DENTRO il blocco pieno

Cadendo l'ingombro non lo vede, quindi ci arriva; il raggio della mira invece si',
e si ferma sulla faccia del blocco a settanta centimetri dall'occhio. Misurato con
una sonda: da 0,7 / 0,9 / 1,2 / 1,6 metri il primo corpo colpito e' sempre
`Proiettore_1`, mai il termos che sta a un metro e mezzo.

**LA CURA E' RIFARE LA DOMANDA ALL'ALTRA COPIA DEL MONDO.** Se davanti non c'e'
niente di utile, si richiede cosa c'e' lungo lo stesso raggio ai SOLI interagibili
- che l'ingombro non ce l'hanno - e a quello che si trova si chiede l'unica cosa
che conta: **si vede?** cioe', fra l'occhio e il punto colpito c'e' geometria vera?
Se non c'e', prenderlo e' il gesto giusto; se c'e' - un muro, un'anta chiusa, il
fianco del carrello - resta dov'e', e la borraccia in fondo al corridoio non si
raccoglie attraverso la parete.

Non sono «due raycast che possono divergere», il difetto contro cui `player.gd`
metteva in guardia: il secondo raggio non e' una seconda risposta alla stessa
domanda, e' la stessa domanda rifatta dietro un ostacolo che si e' gia' deciso di
scavalcare. Il primo raggio comanda sempre, e si arriva al secondo solo quando la
prima risposta e' «niente». Costa un'interrogazione in piu' guardando un occlusore,
due se dietro c'e' davvero qualcosa da prendere.

**LA SONDA FA DUE DOMANDE INVECE DI UNA.** `tools/prova_appoggi.gd` gia' cercava i
blocchi con la cima finta e ci lasciava cadere un oggetto: adesso, appena quello e'
fermo, gli gira intorno e prova a mirarlo con il raggio DEL GIOCATORE - non con uno
suo, che e' l'errore che aveva reso cieca la prima sonda del quadro della cupola.
Un posto conta solo se il giocatore ci sta in piedi, se da li' l'oggetto e' dentro
la portata (1,20 m dall'occhio, che sta a 1,65) e se da li' l'oggetto SI VEDE: una
scatola rotolata sotto una sedia non e' un caso di mira sbagliata, e' roba per
terra, che si prende accovacciandosi. Il difetto si rimette con
`MIRA_SUGLI_INGOMBRI=1`, e con quello acceso la sonda accusa di nuovo il carrello
e il bidet.

---

## D-210 Sul letto la roba restava a mezz'aria, e la colpa era del volume di mira

Trovato dalla sonda mentre si provava D-209, non da una fotografia: una scatola
lasciata cadere sul letto si fermava a **1,05 m** invece che sul materasso a
**0,58**. Mezzo metro sopra le coperte.

**IL VOLUME DEL LETTO E' PIU' ALTO DEL LETTO, ED E' VOLUTO.** `bed.tscn` lo
dichiara: la collisione arriva all'altezza della testiera perche' il raggio
dell'occhio possa trovarlo - un letto alto 54 cm sta tutto sotto la linea di mira,
e il primo letto costruito qui non si poteva usare. Quel volume serve a essere
MIRATO, e non e' la forma della cosa.

Il difetto era che gli oggetti ci si appoggiavano sopra: `carryable.gd` teneva
`LAYER_INTERACTABLE` nella propria maschera, cioe' cadeva anche sui volumi
d'interazione. Adesso cade sulla sola geometria vera - la corazza, che copre ogni
mesh visibile, monitor e ante comprese - e gli oggetti si urtano fra loro perche'
stanno anche loro su quel layer: una tazza sopra un'altra sta sopra, come prima.

**E LA MIRA GUARDA OLTRE I VOLUMI, per la stessa ragione.** Una tazza posata sul
materasso sta DENTRO il volume del letto: fermandosi al primo corpo trovato si
mirerebbe sempre il letto e mai la tazza. Il raggio degli interagibili attraversa
fino a quattro corpi prima di arrendersi - quanti se ne possono infilare fra
l'occhio e una cosa a mezzo metro - e la verifica «si vede?» resta a decidere.

---

## D-211 Il piede di un modello non e' il suo punto piu' basso

Federico, con una fotografia della consolle: «il telefono fluttua». E fluttuava,
di **75 millimetri**.

**NON ERA UN NUMERO SBAGLIATO, ERA LA DOMANDA SBAGLIATA.** `modellare.posa_modello`
appoggia un modello di fuori sul minimo del suo ingombro, che per quasi tutti e' la
base. Per questo telefono no: sotto la base scendono sette centimetri e mezzo di
FILO A SPIRALE, e appoggiando quello il telefono resta per aria con l'ombra
staccata.

    fascia piu' bassa del modello   vertici sparsi su 13 x 29 mm
    l'apparecchio                   300 x 320 mm

**QUINDI SI CERCA IL PIEDE, MISURANDOLO:** si guarda il modello per fasce di cinque
millimetri dal basso e si prende la prima che ha un'impronta vera - un rettangolo in
pianta grande almeno un decimo di quello del modello intero. Le quattro gambe di una
sedia lo hanno, un filo che pende no. Quello che resta sotto affonda nel piano, ed e'
la cosa giusta: il filo sparisce dentro il legno e sotto la consolle non c'e' luce,
un telefono sospeso lo vede subito chiunque.

**MA NON SI APPLICA DA SOLA, E IL LAVABO SPIEGA PERCHE'.** Con la regola accesa su
tutto, il lavabo a semicolonna del bagno si abbassava di **745 mm** - la sua colonna
e' stretta, quindi passa per appendice - e sarebbe finito dentro il pavimento. Un
piede stretto e' comunque un piede, e nessuna soglia sa distinguere una colonna da un
cavo guardando solo l'impronta. Quindi il modellatore MISURA sempre e stampa il
sospetto («appoggia N mm sopra il suo punto piu' basso»), e a spostare il modello e'
chi lo posa, con `piede=True`, dopo aver guardato. La misura e' automatica, la
decisione no.

I quattro sospetti stampati oggi: telefono 75 mm (corretto), termosifone 50,
distributore di carta 35, portarotolo 20 - questi tre sono a muro, e vanno guardati
in partita prima di toccarli.

---

## D-212 Si guarda dentro il telescopio, e si vede dove punta

Federico: «se uno toglie la camera sarebbe bello poter guardare nel telescopio e
vedere cosa sta puntando». E' il gesto che chiude il cerchio del focheggiatore: la
camera CCD si smontava gia' (D-206), e smontarla non serviva a niente.

**AL FUOCO CI STA UNA COSA SOLA.** Con la CCD avvitata il prompt non compare
nemmeno: e' la regola vera di un focheggiatore, ed e' anche l'unico modo in cui il
giocatore scopre che smontare la camera ha un senso.

**L'OCCHIO VA DOVE ENTRA LA LUCE.** La vista non e' sul nodo `Fuoco` - la bocca del
portaoculare, dove si avvita la camera - ma su `Mira`, l'empty che il modellatore
appende sull'ASSE OTTICO misurandolo sui vertici (D-198). Appesa li' dentro, la
vista insegue il tubo da sola: quando la montatura si muove il campo scorre, che e'
meta' di quello che c'era da vedere. La sonda lo prova spostando la montatura di
trenta gradi e guardando se la vista ci va insieme.

**E SI VEDE QUELLO CHE C'E', non un poster.** Nessun oggetto celeste disegnato:
c'e' il cielo procedurale, ed e' il cielo dalla direzione in cui il tubo sta
guardando adesso. A cupola chiusa, o con la fessura girata da un'altra parte, si
vede il buio della calotta - ed e' la risposta giusta, perche' e' quello che si
vedrebbe davvero. Misurato: con la fessura a 0,6 gradi dal telescopio il campo e'
pieno di stelle; con la cupola chiusa e' nero.

**IL CAMPO E' LARGO DODICI GRADI, che e' venti volte il vero, ed e' dichiarato.**
Le stelle di `cielo.gdshader` sono dischetti dentro celle di direzione, cioe' hanno
una dimensione ANGOLARE fissa: al mezzo grado di un oculare vero diventerebbero
palle, e il cielo si leggerebbe come un difetto invece che come un cielo. Dodici
gradi e' il campo di un CERCATORE, ed e' il compromesso fra la fisica e quello che
questo cielo sa disegnare. Il numero si tara guardando, come `TRACK_RATE`.

**IL VELO NERO E IL MIRINO.** Il cerchio che chiude il campo e' uno shader di due
righe invece di una texture - il mondo vive dentro un `SubViewport` da 640x360 poi
stirato, e un PNG andrebbe rifatto a ogni misura. E il puntino del mirino si spegne
entrando: `crosshair.gd` lo disegna anche a controllo spento, e in mezzo al campo di
un telescopio diventa una stella che non c'e', ferma al centro esatto - la prima
cosa che uno crede di aver trovato.

---

## D-213 I faldoni e il proiettore: cosa si e' scelto, e cosa manca

Due richieste di Federico nello stesso momento: «cerchiamo dei modelli per i faldoni
di carta» e, sul proiettore della sala divulgazione, «secondo me va cambiato, forse
e' un po' troppo old style, servirebbe uno con le diapositive».

**I FALDONI.** Sopra lo schedario della sala di controllo c'e' una pila di TRE
SCATOLE di materiale «Carta», e da un metro sono tre scatole. Un faldone ha la costa
rigida, l'etichetta, il buco per il dito e gli anelli: sono quelle quattro cose a
dirlo. Su Poly Haven non ci sono - interrogata l'API sui 521 modelli: c'e'
`binder_notebook`, che e' un'agenda di pelle. Su Sketchfab si', CC-BY:

    Several Folders   janexx   5.130 tri   cinque faldoni in fila, per un ripiano
    Ring Binder       Jura       300 tri   uno solo, per le pile sfalsate

**IL PROIETTORE: la richiesta e' storicamente giusta, non estetica.** Nel 1999, in
una sala divulgativa di un osservatorio, la serata la si faceva con le DIAPOSITIVE;
il proiettore a pellicola 8 mm era gia' roba da cineteca. La scelta precedente
(`filmstrip_projector_8mm`) l'aveva perfino scritto nel proprio commento - «si
facevano ancora con la pellicola E LE DIAPOSITIVE» - e fra le due ha preso quella
sbagliata. Scelto il **Diaprex B-11** dei Virtual Museums of Malopolska, CC0, perche'
ha il CARICATORE A SLITTA in vista: e' l'unica cosa che distingue a colpo d'occhio un
proiettore per diapositive da uno per pellicola, cioe' tutto il motivo per cui lo si
cambia. Il gemello «Narcyz», stesso museo, e' piu' leggero (397 mila triangoli contro
692 mila) ma non mostra il caricatore.

**COSA MANCA, ED E' A MANO.** Sketchfab consegna i file solo a un account
autenticato: le tre voci sono dichiarate in `tools/prendi_modello.py` con autore,
licenza e credito, e gli zip vanno scaricati da un browser con la sessione aperta e
lasciati in `assets/models/esterni/_da_scaricare`. Le due scansioni museali vanno
anche decimate prima di entrare in scena - `modellare.py` non ha ancora una
decimazione, e sara' la prima cosa da scrivere quando i file ci saranno.

---

## D-214 La tazza incastrata nel monitor: le mesh dei prop stavano quindici centimetri piu' in la'

Federico, giocando: «c'e' una tazza incastrata nel monitor». E c'era, dall'avvio -
non l'aveva messa lui.

**LE PRIME DUE IPOTESI ERANO SBAGLIATE, ed e' la parte che vale la pena scrivere.**
La prima: «la mano la spinge dentro». Misurata: la mano puntata al centro della
cassa ce la porta davvero, ma nessun giocatore puo' puntare li' - il corpo si ferma
sulla consolle a 1,36 m e la tazza arriva al massimo a 30 cm dal centro. La cura
scritta per quel caso - la mano che si ferma sulla prima geometria che incontra -
e' stata TOLTA: un raycast per oggetto per tick che curava un difetto che non
esisteva.

La seconda: «gli oggetti collidono male con le superfici a triangoli». Provata sul
banco delle mani, con un mobile a triangoli, con la massa e il collisore della
tazza vera: il difetto non si riproduce, nemmeno rimettendo la mano che attraversa.

**LA CAUSA VERA, misurata mesh contro collisore:** i modelli dei prop si vedono
dove NON stanno.

    tazza        15 cm fuori asse       bottiglia    21 cm
    piattino     40 cm                  bottiglione  41 cm

`prop_blender.origine_alla_base()` metteva l'origine sotto il pezzo ma lasciava
l'oggetto dov'era nella scena di Blender - cioe' dove capitava di trovarlo dentro
il set da cui era stato preso - e quella posizione finiva nel `.glb` come
trasformata del nodo. In Godot il corpo rigido sta dove dice il generatore, la mesh
quindici centimetri piu' in la': dentro la cassa del monitor, che e' proprio li'. E
siccome il COLLISORE stava al posto giusto, la fisica non aveva niente da
correggere - era un difetto puramente visivo, invisibile a ogni sonda che misuri
posizioni.

**Si vedeva anche altrove, e nessuno l'aveva collegato:** la tazza e il piattino
della cucina, posati dal generatore nello STESSO punto, in partita stavano a un
quarto di metro l'uno dall'altro.

**LA CURA:** dopo aver centrato la mesh, l'oggetto torna sull'origine del mondo -
e ci torna portandosi dentro anche la rotazione e la scala che il pezzo aveva nel
set, o un modello importato storto avrebbe il centro nel posto sbagliato. Poi la
tazza della consolle e' stata spostata di cinque centimetri: la cassa del monitor
comincia a z=1,785 e una tazza col manico e' larga tredici, quindi a 1,73 ci
finiva dentro comunque - adesso e' a 1,68, e la quota si e' potuta scrivere
guardando i numeri invece del render.

---

## D-215 Le scritte del quadro d'avvio si sovrapponevano: le quote erano scritte, non impilate

Federico, in partita: «le scritte si overlappano». Nel quadro dell'accensione
l'ultima riga del registro finiva sopra il messaggio, e le due righe dei comandi si
toccavano.

**IL PASSO ERA PIU' STRETTO DELL'ALTEZZA DEL FONT.** Le quote erano numeri fissi -
registro a 124 con passo 11, messaggio a 164, comandi a 176 e 188 - e il font di
sistema a 11 pixel ne e' alto 12, a 12 ne e' alto 13. Con quattro righe di registro
mancavano cinque pixel, e cinque pixel su un quadro alto 192 sono una riga.

**ADESSO I BLOCCHI SI IMPILANO DAL BASSO** misurando `get_height`, `get_ascent` e
`get_descent` invece di indovinarli: i comandi stanno sull'ultima riga utile, il
messaggio sopra di loro, il registro riempie quello che resta. E quello che non ci
sta non si disegna: il registro non sale mai sopra la tabella degli apparecchi -
se lo spazio manca, le righe piu' vecchie restano fuori, che e' quello che fa una
telescrivente quando finisce la carta. La tabella e' stata compattata da 18 a 16
pixel di passo e alzata di quattro: quei quattro pixel sono l'aria fra l'ultima
riga della tabella e la prima del registro.

**E ADESSO SI GUARDA**: `tools/prova_schermi.gd` monta anche il quadro dell'avvio,
nel caso piu' pieno - tre apparecchi, quattro righe di registro, il messaggio lungo
- e lo salva in un secondo scatto, perche' a due volte il vero tre pannelli non
stanno in una finestra da 1280x720.

---

## D-216 Il computer fisso sotto la consolle, e i cavi

Federico: «mi puoi fare anche dei cavi e sotto al tavolo un computer fisso?». Ed
era il pezzo che mancava per davvero: sul piano c'erano un monitor, una tastiera e
un mouse collegati a niente, e un monitor collegato a niente e' un televisore.

**LE MISURE SONO DI UN MIDI-TOWER ATX**, non stimate: 19 x 43 x 40 cm e' l'ingombro
di serie di un case del 1999, e i vani del frontale sono standard di specifica - il
5,25 pollici e' 146 x 41,3 mm, il 3,5 e' 101,6 x 25,4. Due vani grandi (il lettore
e un coperchio cieco, come uscivano), uno piccolo col floppy e il suo tasto di
espulsione, il pulsante di accensione, il reset, le due spie e la griglia di
aerazione.

**STA FUORI DAL VANO GAMBE**, nella campata fra il fianco di testa e il posto dove
si siede: un case in mezzo ai piedi lo si prende a calci tutte le sere, ed e' il
motivo per cui in un ufficio vero sta di lato. Il fronte guarda chi si siede,
perche' e' da li' che si infila un floppy.

**I CAVI SONO TRE E PENDONO.** Prima ce n'era uno solo, un cilindro dritto dal
piano al pavimento dietro il monitor - e un cavo dritto legge come un tubo. Adesso
scendono dal bordo del piano e risalgono al retro della torre (video, tastiera,
corrente), piu' la matassa che avanza arrotolata per terra: e' il percorso vero,
perche' sotto una scrivania addossata al muro i cavi non passano dentro il piano,
girano dal bordo.

`modellare.cavo()` li disegna come PARABOLE e non come catenarie, dichiarato: per
un filo che scende meno di un quinto della propria luce le due curve si scostano di
meno del raggio del cavo stesso, e la catenaria vera per un abbassamento dato vuole
un'equazione trascendente da invertire a ogni cavo.

**IL CONTROLLO DELLE IMPRONTE HA FATTO IL SUO MESTIERE**: la prima matassa era
disposta di fianco alla torre e usciva dall'impronta della consolle - 64 vertici
oltre il bordo, cioe' un cavo che in partita passa attraverso il fianco. Ora le
anse stanno fra la torre e il muro.

---

## D-217 La camera CCD non si puo' perdere: un blocco alla mano e una rete sotto

Federico, dopo aver smontato la camera davanti al telescopio: «se a uno cade la
camera che toglie dal telescopio, gli cade dentro il cerchio del telescopio,
rischia che non si possa mai piu' utilizzare. E' una situazione terrificante».

**NON ERA UNA PAURA, ERA UN FATTO.** Misurato con una sonda che lascia cadere la
camera dalle pose in cui uno la smonterebbe:

    dentro la bocca del tubo   -> si ferma a y=0,05   PERSA
    sopra la bocca             -> si ferma a y=0,05   PERSA
    sopra il pilastro          -> si ferma a y=0,06   PERSA
    di fianco al tubo          -> si ferma a y=0,06   PERSA
    al fuoco, mollata          -> si ferma a y=0,65   raggiungibile (la passerella)

Il fuoco sta sopra il POZZO del pilastro, dentro l'anello della passerella: quello
che cade li' finisce sul pavimento della sala telescopio, un metro e sessanta piu'
giu', oltre un parapetto, e non c'e' modo di scendere. Il tubo per giunta e' aperto
e cavo - un raggio calato dalla bocca non incontra niente fino a terra.

**E NON E' UN OGGETTO QUALSIASI.** Senza camera non si fotografa piu': non e' una
cosa smarrita, e' una partita che non puo' piu' finire. E' l'unico oggetto del
gioco per cui valga la pena scrivere una regola apposta.

**IL BLOCCO: la mano non la lascia andare sul vuoto.** Con la camera in mano, se
sotto non c'e' un piano entro mezzo metro, `posa()` non fa niente e il prompt lo
dice - «Qui sotto non c'e' dove posare la camera». E' il gesto di chi appoggia una
cosa da un chilo e mezzo, non di chi la butta; chi vuole liberarsene la rimette al
fuoco, che e' dove sta quando non e' in mano.

**LA RETE: se ci finisce lo stesso, torna al fuoco.** Il blocco copre il gesto, non
l'incidente: la camera puo' essere strappata dalla mano contro uno stipite (vedi
`Carryable.STRAPPO`) o spinta da un urto. Appena e' ferma - e una volta sola, che il
conto costa una trentina di interrogazioni allo spazio - si chiede se esista un
posto da cui un giocatore la potrebbe riprendere: ci si sta in piedi con la sua
capsula, la si vede senza geometria in mezzo, ed e' dentro la portata da in piedi o
accovacciati. Se quel posto non esiste, la camera torna al fuoco e il registro lo
scrive.

**SI CHIEDE AL MONDO invece di elencare i posti brutti.** Il pozzo del pilastro e'
quello che ha fatto nascere la regola, ma un domani ci sara' un armadio, una
fessura dietro un mobile, un tetto: «da qualche parte ci si arriva?» copre anche
quelli e non invecchia con la pianta dell'edificio.

**L'ALTRA STRADA E' STATA SCARTATA.** Federico ne aveva proposte due - il blocco
oppure «che si possa raccogliere da piu' lontano» - e la seconda non basta:
allungare la portata dell'interazione la allunga per TUTTO (ADR-003 la vuole corta
apposta, sei gia' davanti alla cosa che stai usando), e comunque non arriverebbe a
un metro e sessanta sotto il parapetto.

**IL DIFETTO SI RIMETTE** con `CAMERA_SI_PERDE=1`, e con quello acceso la sonda
accusa tutti e due i controlli: la camera si molla sul pozzo, e dieci secondi dopo
e' ferma sul pavimento della sala dove nessuno la puo' raccogliere.

---

## D-218 Il divieto era peggio del pericolo: si toglie il divieto e si tappa il buco

Federico, dopo aver giocato con la cura di D-217: «non hai risolto il problema,
adesso sono bloccato con la camera in mano... soltanto sul tavolo posso posare la
camera? Ma che discorso e' fare un prompt che dice qui sotto non c'e' dove posare
la camera, uno impazzisce. Si ritrova questa roba in mano e non sa mai come
usarla». E ha detto anche cosa voleva: «metti un muro invisibile che sta sotto nel
buco del telescopio, in maniera tale che non si possa fisicamente droppare la
telecamera li'».

**AVEVA RAGIONE DUE VOLTE.** Un divieto che non dice dove SI puo' e' una punizione,
non una regola; e questo per giunta lasciava addosso l'oggetto che si stava
cercando di mettere giu' - il caso peggiore fra tutti quelli possibili, perche' chi
tiene in mano una cosa che non riesce a posare non sta giocando, sta combattendo
col gioco. La lezione e' vecchia e la avevo scritta io stesso in D-209: il prompt
non deve mentire. Ma un prompt che dice la verita' e non offre una via d'uscita e'
lo stesso difetto visto dall'altra parte.

**IL BUCO, MISURATO.** Sotto l'anello della passerella ci sono 59 cm di vuoto: il
pozzo del pilastro dentro (raggio 0,875), la luce dell'impalcato fuori (fino a
1,925). Il giocatore cammina sul calpestio a 0,59 e nel pozzo non entra - lo chiude
l'ottagono della montatura - quindi una cosa caduta li' sta a 5 cm dal pavimento
con l'occhio piu' basso possibile (accovacciato, 1,05) un metro e sessanta piu' su:
oltre la portata dell'interazione (1,20) da qualunque parte la si guardi.

**LA CURA E' UN CILINDRO INVISIBILE**, `FondoPasserella` in `gen_blockout.py`:
raggio 1,925, alto dal pavimento al calpestio, sul solo layer degli APPOGGI e con
maschera zero. Quello che cade dentro l'anello si ferma a filo del piano su cui si
cammina, dove si vede e si raccoglie; quello che rotola verso la passerella non ci
si infila sotto. **E vale per tutto**, non per la sola camera: anche un termos o una
tazza lasciati cadere li' erano persi, e nessuno ci aveva pensato.

**PIENO E NON ANULARE**, apposta: sotto l'impalcato non deve entrare niente piu' di
quanto debba cadere nel pozzo, e una forma sola costa una collisione invece di
ventiquattro conci.

**LA PARTE CHE VALE E' QUELLA CHE NON SI VEDEVA.** Tolto il divieto, la sola difesa
rimasta e' la RETE di D-217 - se la camera si ferma dove nessuno la raggiunge,
torna al fuoco - e appena il fondo ha smesso di far cadere le cose nel pozzo la
rete ha cominciato a sbagliare. Tre difetti dentro `si_riesce_a_prendere()`, tutti
misurati, nessuno visibile prima:

    la capsula di prova appoggiata A FILO del punto colpito dal raggio
      -> tocca il pavimento che l'ha fermata, `intersect_shape` dice «occupato»
      -> 8 pose su 11 irraggiungibili: la funzione stava dicendo che in questa
         casa non si puo' raccogliere niente da terra. Adesso 5 cm di franco.

    il raggio della vista puntato su `global_position`
      -> ma la camera ha l'origine sulla BASE (il collisore e' alzato di 6,35 cm),
         quindi si mirava al punto in cui la camera TOCCA il piano: il raggio
         arrivava sul calpestio un attimo prima di lei, la vista risultava
         ostruita, e una camera posata bene in mezzo alla passerella veniva
         dichiarata persa. IN PARTITA SI SAREBBE VISTA COME SPARIZIONE: la rete
         se la riprendeva e la rimetteva al fuoco sotto gli occhi di chi l'aveva
         appena appoggiata. Adesso si chiede al collisore dov'e' il suo centro.

    i piedi cercati sul PRIMO corpo trovato scendendo
      -> sotto la cupola il primo corpo e' la cima dell'ottagono della montatura,
         a 2,60: la funzione concludeva che per prendere la camera bisognerebbe
         stare in piedi lassu'. Adesso si scende di piano in piano (tre) e ci si
         ferma sul primo in cui una persona ci sta davvero.

E il giro dei posti da cui provare a raggiungerla si e' allungato da 0,85 a 1,15 m:
una camera appoggiata SOPRA qualcosa - il tubo, il pilastro - si raccoglie stando
lontani, perche' la distanza da coprire e' quasi tutta orizzontale.

**LA CAPSULA E' QUELLA GIUSTA, ADESSO**: in piedi si guarda con l'occhio in piedi e
l'ingombro in piedi (1,80), accovacciati con tutti e due accovacciati (1,10). Prima
si misurava la testa bassa e il corpo alto, e ogni posto sotto qualcosa - il bordo
della passerella, un ripiano - risultava inagibile.

**LA SONDA HA CAMBIATO DOMANDA, ed e' il punto.** `tools/prova_ccd.gd` non chiede
piu' «la mano si rifiuta?» - controllava che il divieto ci fosse, cioe' misurava la
cura sbagliata - ma «posandola dove capita attorno al telescopio, la si ritrova
sempre?». Un giro di pose intorno al fuoco (8 direzioni, 60 e 90 cm, saltando
quelle dentro il tubo), e per ognuna due domande: posarla si puo'? e da qualche
parte ci si arriva?

    con la cura        10 pose provate, 0 perse
    difetto rimesso    10 pose provate, 2 perse (y = 0,05: il pavimento della sala)

**IL DIFETTO SI RIMETTE CON `CAMERA_SI_PERDE=1`, che adesso toglie DUE cose**: la
rete e il `FondoPasserella` (spegnendogli il layer). Senza la seconda meta' il
pozzo resterebbe tappato e la sonda direbbe «ok» misurando la cura invece del
difetto - la trappola in cui cade ogni banco che prova solo il codice e non il
mondo in cui gira.

## D-219 La ringhiera della passerella era montata di traverso: un quarto di giro, e nessun controllo poteva vederlo

Federico, giocando: «le hitbox della passerella, quella tonda, sono terribili: mi ci
incastro sempre e si vedono i poligoni fatti in maniera molto sloppy. E'
incomprensibile dove si puo' toccare, e tante volte senti che stai scattando quando
tocchi la passerella. Parlo della ringhiera».

**COS'ERA, ed e' una riga.** In `geometria.py` ogni concio dell'anello si girava di
`-(ang + pi/2)` — l'angolo della TANGENTE — con accanto scritto «X locale radiale:
la tangente e' l'angolo + 90 gradi». La frase e' vera e il numero e' quello
sbagliato: `rot_y` dice dove va a finire la X LOCALE, e la X locale di un concio
anulare e' il RAGGIO. Ogni pezzo si montava ruotato di novanta gradi.

**COSA VOLEVA DIRE**, misurato in gioco con la capsula vera del giocatore:

    l'impalcato       calpestabile per 43 cm su 105 che se ne vedono
    il parapetto      21 ALETTE alte un metro piantate di traverso sul bordo,
                      sporgenti 27 cm dentro il passaggio, con mezzo metro di
                      niente fra l'una e l'altra
    il muro sentito   a 1,52-1,53 dal centro invece che a 1,59, e ondeggiante

Cioe': ci si incastrava nelle alette, e in mezzo si passava attraverso una ringhiera
che si vede continua. «Incomprensibile dove si puo' toccare» e' la descrizione esatta
di quella geometria, non un'impressione.

**PERCHE' NESSUN CONTROLLO L'AVEVA VISTO.** `verifica_passerella` percorreva la sola
MEZZERIA dell'anello — e un concio girato copre la mezzeria lo stesso. Il controllo
della larghezza libera prendeva `min(sx, sz)/2` come semispessore, cioe' PRESUMEVA
l'orientamento che avrebbe dovuto verificare. Un controllo che guarda una riga sola
approva qualunque cosa passi per quella riga.

Adesso quel controllo fa tre cose: chiede che la X locale di ogni concio guardi il
centro della cupola (l'invariante, che il quarto di giro violava); percorre TUTTA la
larghezza dell'impalcato, non la mezzeria; e misura le distanze dai rettangoli veri,
comunque siano girati. Il primo dei tre ha subito trovato anche un secondo buco che
nessuno cercava: la corda dei conci era tagliata sulla mezzeria, ma un concio e' un
rettangolo e l'anello no, quindi all'orlo esterno restava un triangolino scoperto a
ogni giunto — 36 punti su 540.

**UN ANELLO SOLO, NON DUE.** Il numero di lati e il varco della scala erano scritti a
mano in due file: 72 lati nel modello e 24 nella collisione, varco di 40 gradi contro
uno di 45, con due regole diverse per decidere quali campate saltare. Adesso
`N_ANELLO`, `VARCO_ANG`, `VARCO_MEZZO` e `fuori_dal_varco()` stanno in `geometria.py`
e `osservatorio_blender.py` li importa: il tratto che si vede e il tratto che si tocca
sono lo stesso tratto. Il modello non cambia di un vertice — le campate saltate sono
identiche — ma adesso non possono piu' divergere. Restavano otto centimetri per parte
di ringhiera visibile e attraversabile, proprio a fianco della scala.

**E POI IL SECONDO DIFETTO, che il primo teneva nascosto.** Rimessa a posto la
geometria, camminare appoggiati alla ringhiera continuava a dare gli scatti. Con
`TRACCIA=1` si vede cos'e': a ogni fermata i contatti sono DUE conci consecutivi,
normali a cinque gradi l'una dall'altra, mezzo millimetro di compenetrazione — la
capsula incuneata nel giunto, e `move_and_slide()` che le azzera la velocita' di
netto. Non e' un difetto della passerella: e' il `safe_margin` del corpo, un
millimetro di fabbrica, e questa scena e' fatta tutta di scatole affiancate, cioe' di
giunti. La ringhiera e' solo il posto dove ce ne sono settantadue in fila.

    safe_margin   passi per il giro (ne bastano 246)   velocita' azzerate
    0,001                            345                       37
    0,010                            247                        0
    0,040                            242                        0
    0,080                            237                        0

Si prende 0,02: il doppio di quanto serve, e due centimetri non si vedono — la
capsula ne misura sessanta e il vano piu' stretto della casa, la porta del magazzino,
novanta. Il numero vive in `world/player/player.tscn` con il conto accanto.

**LA SONDA E' `tools/prova_ringhiera.gd`**, e fa le tre domande nell'ordine in cui si
presentano a chi gioca: il muro si tocca sempre allo stesso raggio? dalla scala si
arriva sull'impalcato? il giro si fa appoggiati senza impuntarsi? Due difetti si
rimettono, uno per causa — `CONCI_GIRATI=1` rigira i conci di novanta gradi,
`MARGINE_MILLIMETRO=1` riporta il margine a quello di fabbrica — e con ognuno dei due
la sonda torna a dire di no. Senza quel confronto un referto che dice «si cammina»
non distingue il merito della cura dal fatto che nessuno abbia provato a camminarci.

    con la cura              onda 0,0 mm, giro in 246 passi su 246, 0 impuntate
    conci girati             muro a 1,524 invece di 1,590, onda 7 mm
    margine di fabbrica      giro in 345 passi, 37 impuntate

## D-220 Niente si fermava mai: il solutore lasciava affondare un centimetro, e da li' non usciva piu'

Federico: «ho appoggiato la borraccia e la camera CCD su un plico di fogli e trema
moltissimo».

**NON ERANO I FOGLI, ed e' stata la prima cosa da escludere.** Il plico e' fatto
davvero male - tre facce orizzontali alla stessa identica quota, di cui due fogli a
SPESSORE ZERO posati sulla cima del blocco - e sembrava la spiegazione. Misurato
spegnendo la corazza dei due fogli: il tremito non cambia di niente (0,043 m/s
contro 0,043). Ed era uguale anche sulla consolle nuda, a mezzo metro da li'. Il
plico non c'entrava: c'entrava che Federico ci aveva posato qualcosa.

**COS'ERA.** `contact_max_allowed_penetration` di Godot vale UN CENTIMETRO: il
solutore lascia affondare un corpo appoggiato fino a li' e da li' in poi lo
respinge. Due conseguenze, e la seconda e' quella che si vede:

    tutto sta un centimetro DENTRO il piano su cui e' appoggiato. Un plico di
    fogli e' spesso dieci millimetri esatti: la roba posata sui fogli non
    affondava "un po'", li attraversava tutti e andava a vibrare sul legno.

    e non si ferma mai, perche' si assesta PROPRIO SU QUELLA SOGLIA. Con
    `TRACCIA=1` si legge il ciclo limite a due tick, dentro-fuori-dentro-fuori a
    trenta hertz:

        tick 0   y 0.74992   v 0.0346   w 0.2204
        tick 1   y 0.75008   v 0.0024   w 0.0149
        tick 2   y 0.74999   v 0.0292   w 0.1866
        tick 3   y 0.75006   v 0.0046   w 0.0298

Un quarto di radiante al secondo che cambia verso a ogni fotogramma, su un termos
alto trenta centimetri, e' la punta che vibra. E sopra la soglia di sonno - otto
gradi al secondo - il motore non lo lascia mai dormire: non finisce da solo.

**LA CURA E' UN NUMERO, POI DUE.** Portata la penetrazione ammessa a un
millimetro, la roba smette di affondare e sul plico si addormenta. Ma sui mobili
GRANDI continuava: la consolle e' una mesh sola da migliaia di triangoli, il
cilindro ci tocca in punti che il solutore ricalcola a ogni tick, e se non li
riconosce come gli stessi il contatto riparte da capo ogni volta. Il secondo numero
e' `contact_recycle_radius`, cioe' quanto lontano puo' spostarsi un punto di
contatto restando "lo stesso punto". Spazzato con `MANOPOLE=1`:

    riciclo   sul piano                  su una pila
    0,02      sveglia 90/90, 0,26 mm     dorme
    0,03      sveglia 90/90, 0,26 mm     dorme
    0,04      dorme, 0,00 mm             dorme
    0,05      dorme, 0,00 mm             dorme
    0,08      dorme, 0,00 mm             dorme

La soglia sta fra 0,03 e 0,04; si prende 0,05, sopra la soglia con margine e non
oltre `contact_max_separation`. Le altre manopole sono state provate e non servono:
il bias del contatto (0,2 e 0,05), le iterazioni del solutore (64), la separazione
massima, e lo smorzamento angolare del `Carryable` portato a 8, 12 e 20 - nessuna
sposta il ciclo limite di un millesimo. Alzare la soglia di sonno lo avrebbe
nascosto invece che tolto, ed e' stato scartato per questo.

**IL REFERTO.**

                             affonda      dorme    sale e scende
    prima (Godot di serie)   10,0 mm      mai         0,26 mm
    dopo                      1,0 mm      sempre      0,00 mm

E la casa com'e': sette oggetti posati - termos, tazza, piattino, bottiglie,
radiolina - e dopo tre secondi dormono tutti e sette. Prima ne restavano svegli
tre, con il termos ancora a 1,2 cm al secondo.

**LA SONDA E' `tools/prova_tremore.gd`** e prova tre posti, perche' uno solo
avrebbe detto la cosa sbagliata: la consolle nuda (un piano solo), il plico di
fogli (tre facce coincidenti, il posto che Federico ha trovato) e una cosa sopra
un'altra cosa - che e' il caso in cui un margine troppo stretto farebbe danno
invece che bene, ed e' la ragione per cui il millimetro non e' un decimo.
`PENETRAZIONE_DI_FABBRICA=1` rimette il difetto e la sonda torna a dire di no in
sei punti.

**RESTA APERTO, e non e' un difetto di adesso**: i due fogli `a4_a` e `a4_b` del
modello sono superfici a spessore zero, e nella corazza diventano collisione a
spessore zero appoggiata esattamente sulla cima del blocco. Adesso non fa danno -
misurato - ma e' una cosa da sapere il giorno che si toccheranno quei modelli.

## D-221 I faldoni si fanno in casa: quattro cose, non due modelli da scaricare

Federico: «aggiusta un po' anche i modelli dei faldoni di carta nella sala di
divulgazione». Sul ripiano basso del carrello del proiettore c'erano TRE SCATOLE
color carta, impilate e sfalsate di un centimetro l'una sull'altra. Da mezzo metro
- che e' la distanza a cui uno ci passa davanti - sono un blocco di cartone.

**IL D-213 AVEVA GIA' DETTO COS'E' UN FALDONE** e non l'aveva fatto: «un faldone ha
la costa rigida, l'etichetta, il buco per il dito e gli anelli: sono quelle quattro
cose a dirlo». Poi aveva cercato due modelli su Sketchfab, che li consegna solo a un
browser autenticato, e li aveva lasciati in attesa in `prendi_modello.py`. Non sono
mai arrivati, e la pila di scatole e' rimasta li' - in due posti, perche' identica
sopra lo schedario della sala di controllo.

**QUATTRO COSE SI FANNO.** `modellare.faldone()` costruisce un registratore da
quattordici scatole, 168 triangoli, con le misure vere e non inventate: 315 mm di
altezza per 285 di profondita' - i due centimetri in piu' del foglio A4, cosi' la
carta non sporge - costa da 50 mm, etichetta nel terzo alto, foro per il dito a
cinque centimetri dal piede, cantonale di metallo sotto la costa.

**IL FORO E' UN FORO VERO**, e non un disco nero appiccicato sulla costa: la costa
e' fatta di quattro bande che gli girano intorno piu' quattro spicchi a
quarantacinque gradi che ne smussano gli angoli, e nell'apertura ottagonale si vede
il buio di dentro. Un disco incollato si smaschera con la luce radente, e in questa
casa la luce radente c'e' sempre.

**TRE COSE VISTE SOLO GUARDANDO IL RENDER**, e sono la ragione per cui la posa si
controlla invece di dedurla:

    le coste guardavano il muro. Alla prima posa i cinque raccoglitori del
      carrello mostravano la COPERTINA, che e' la faccia liscia: cinque libroni.
      Un raccoglitore lo si riconosce dalla costa, quindi la costa va dove
      qualcuno passa - qui il corridoio fra le sedie e le teche, e sopra lo
      schedario il lato della porta.

    gli spicchi del foro sbordavano. Lunghi quattro centimetri su una costa da
      cinque, girati di quarantacinque gradi, sporgevano di un centimetro per
      parte: cinque alette appuntite in fila sotto il carrello.

    ed erano girati sulla diagonale sbagliata. `Matrix.Rotation(g, 4, "Y")` porta
      l'asse sottile su (cos g, 0, -sin g): per stare perpendicolare alla
      diagonale dell'angolo (+,+) il segno e' l'opposto di quello che verrebbe da
      scrivere. Con il segno sbagliato due angoli restavano aperti e il foro
      diventava un papillon.

**E LA CARTA DENTRO STA INDIETRO.** A filo della costa, dal foro si vedeva la carta
illuminata e il foro leggeva come una seconda etichetta; a filo della copertina, un
raccoglitore coricato sembrava un panino. Nel raccoglitore vero i fogli sono appesi
agli anelli: un centimetro e mezzo dietro la costa, e quasi tre dentro il bordo
aperto.

**DUE POSTI, NON UNO.** La richiesta era per la sala di divulgazione - cinque
raccoglitori in piedi in fila sul ripiano del carrello, gli ultimi due che pendono
come pende sempre l'ultimo di una fila che non arriva in fondo, e due coricati di
piatto nello spazio che avanza. Ma sopra lo schedario della sala di controllo c'era
la stessa identica pila di scatole, ed e' il caso che il D-213 aveva lasciato
aperto: tre raccoglitori coricati e storti, come si posano tornando dalla cupola.

Restano scatole di cartone quelle della cucina (`cucina_blender.py`, sopra il
pensile): sono scatoloni, non raccoglitori, e non sono state toccate.

I due modelli Sketchfab restano dichiarati in `prendi_modello.py` con autore,
licenza e credito: se un giorno arrivano, sostituiscono questo - ma il posto adesso
non e' vuoto in attesa.

## D-222 Il pieno centrale della cupola era un ottagono dentro un cerchio: venti centimetri di muro invisibile e otto spigoli

Federico, in partita, con una foto scattata dalla passerella verso il telescopio:
«altre hitbox qui non vanno bene». E' il secondo tempo del D-219: sistemato il bordo
di fuori, restava quello di dentro.

**COS'ERA.** Il vuoto centrale — il pozzo del pilastro, piu' tutto lo spazio dello
strumento fin sopra la testa — e' tappato da un volume in cui non si entra, e quel
volume era fatto di DUE SCATOLE girate di 45 gradi l'una sull'altra: un ottagono,
inscritto nel cerchio da 0,875 su cui finisce l'impalcato che si vede. Un ottagono
inscritto tocca il cerchio negli otto vertici e rientra a mezza faccia — qui di venti
centimetri.

**COSA VOLEVA DIRE**, misurato in gioco con `tools/prova_montatura.gd`:

    il muro sentito   ondeggiava di 182 mm fra 0,998 e 1,179 dal centro
    lo scarto         fino a 176 mm prima che finisse il pavimento che si vede
    il giro           280 passi di fisica invece di 204, con 11 punti
                      in cui ci si impunta, a quattro spigoli dell'ottagono

Cioe': camminando lungo il bordo interno ci si fermava contro niente, a venti
centimetri dal bordo, e in otto punti ci si infilava in uno spigolo. E quei venti
centimetri sono i peggiori che ci siano da perdere: li' c'e' il pozzo aperto e in
fondo il telescopio, cioe' la cosa per cui la stanza esiste.

**PERCHE' NESSUN CONTROLLO L'AVEVA VISTO.** `verifica_passerella` misura la LUCE fra
parapetto e pieno centrale — quanto passaggio resta — e un ottagono largo il giusto
lascia passare benissimo: un metro e un centimetro contro una capsula da sessanta.
La domanda che non faceva nessuno non e' «quanto e' largo il passaggio» ma «dove
finisce il muro, rispetto a dove finisce il pavimento che si vede». Ed e' la stessa
lezione del D-219 in un'altra forma: un controllo che guarda la larghezza approva
qualunque cosa sia larga.

**IL RIMEDIO: UN CILINDRO, E IL RAGGIO E' IL BORDO CHE SI VEDE.** `R_PIENO` vale
`R_PASS - W_PASS/2`, cioe' esattamente il bordo interno dell'impalcato, e non e' un
numero scelto: e' l'unico posto in cui fermarsi non ha bisogno di essere spiegato,
perche' li' finisce il pavimento. Onda 0,0 mm, scarto -4 mm — il muro sta quattro
millimetri OLTRE il bordo, che e' il mezzo lato del settantaduegono dell'impalcato —
giro in 251 passi e nessun punto in cui ci si impunta.

**LA FORMA LA SCRIVE `gen_blockout.py`, NON `blocchi_edificio()`**, e non e' un
capriccio: li' si fanno scatole, e un cerchio fatto di scatole e' un altro poligono.
E' la stessa ragione per cui il `FondoPasserella` sta li', e adesso i due tappi della
cupola sono vicini di casa. In `geometria.py` restano i due numeri, che e' quello che
`geometria.py` deve tenere.

**E SI ARRIVA ANCORA ALL'OCULARE**, che e' la cosa che questa cura poteva rovinare:
sui mezzi lati dell'ottagono ci si avvicinava sette centimetri di piu', e la portata
dell'interazione e' 1,20 m contati dall'occhio. Misurato: l'oculare sta a 0,30 m
dall'occhio di chi e' fermo contro il cilindro — quattro volte dentro la portata — e
il gioco lo mette a fuoco. La sonda lo chiede al gioco e non a se stessa: smonta la
camera CCD come la smonta chi gioca, perche' al fuoco ci sta una cosa sola.

**IL DIFETTO SI RIMETTE**, `OTTAGONO=1`: spegne il cilindro e rimonta in memoria le
due scatole di prima. Rimesse, la sonda ristampa gli stessi numeri misurati sulla
geometria vera — 182 mm, 176 mm, 280 passi, 11 impuntate — che e' il modo di sapere
che l'interruttore non mente.

**IL FONDO DELLA PASSERELLA VA ESCLUSO DALLA MISURA**, e trovarlo e' costato una
lettura sbagliata. Per chiedere «dove finisce il pavimento che si VEDE» la sonda tasta
la corazza (D-205), ma sullo stesso layer c'e' anche `FondoPasserella` (D-218), che
e' un tappo invisibile con la faccia a filo del calpestio: senza escluderlo il raggio trova
pavimento dappertutto, e la prima misura diceva che il bordo non esisteva.

## D-223 «L'ho persa per sempre»: la camera era salva, e la sparizione silenziosa e' lo stesso difetto

Federico, in partita, con la foto dell'angolo fra la cassettiera della stampante e il
rack della sala di controllo: «mi e' caduta la camera qui e l'ho persa per sempre».

Il registro della sua partita diceva un'altra cosa:

    INFO [ccd] la camera era finita dove non ci si arriva (8.09, -0.00, 0.17):
               rimessa al fuoco

**AVEVANO RAGIONE TUTTI E DUE, ed e' il punto.** La rete del D-217 aveva funzionato:
misurato, quell'angolo e' davvero irraggiungibile - il corpo del giocatore e' largo
sessanta e il solo posto in cui ci starebbe e' sulla diagonale a 135 gradi, che il
giro a dodici direzioni non prova mai. Ma la camera se n'era andata al telescopio
senza dire niente, e un oggetto che sparisce da sotto gli occhi si gioca esattamente
come un oggetto perduto.

**E IL BUCO NON ERA UNO.** Misurato con `tools/prova_smarrimenti.gd`, che passa tutto
il pavimento a maglia di quindici centimetri e chiede al gioco - non a una copia
della regola - se da li' una cosa si riprenderebbe:

    dieci metri quadri, in quarantadue pozze, di pavimento da cui una cosa
    a terra non si riprende E in cui una cosa a terra ci puo' arrivare
    rotolando da dove si cammina

Non sono voragini: sono le fessure fra un mobile e il muro e fra due mobili
affiancati. Il giocatore e' largo sessanta e il braccio arriva a 1,20; una borraccia
e' larga dieci e rotola dove capita. La camera aveva una rete tutta sua perche' senza
di lei la partita non finisce; il termos, la tazza e la bottiglia non avevano niente,
e in quelle quarantadue pozze si perdevano davvero.

**LA RETE SALE IN `Carryable`, E CAMBIA RISPOSTA.** Non piu' «torna a casa» - una
borraccia non ha una casa - ma **si sposta nel posto piu' vicino da cui la si puo'
prendere**. Misurato: quindici centimetri, cioe' un palmo; il peggio e' cinquantatre,
dietro la pattumiera della cucina, dove il primo posto buono e' di la' dal secchio.
Non e' un teletrasporto: e' la cosa che non ci stava, nella fessura in cui era
rotolata.

Nell'angolo di Federico la camera adesso resta per terra a trentacinque centimetri da
dov'e' caduta, e si raccoglie.

**PERCHE' NON SI TAPPANO I BUCHI.** Sono quarantadue, e tapparli vorrebbe dire
quarantadue volumi invisibili scritti a mano, da rifare a ogni mobile che si sposta.
`FondoPasserella` (D-218) esiste perche' li' il buco e' UNO e profondo un metro e
sessanta; qui i buchi sono tanti e profondi zero.

**TRE COSE TROVATE STRADA FACENDO**, e nessuna si vedeva leggendo il codice:

  - **la vista si chiedeva alla CORAZZA invece che al layer del mondo.** Sono due
    cose diverse: sotto una scrivania la corazza lascia passare - li' sotto c'e'
    aria - mentre l'ingombro e' una scatola piena, ed e' contro l'ingombro che
    sbatte il raggio del giocatore. Una cosa sotto una scrivania risultava
    prendibile e non lo era. Adesso la rete chiede quello che chiede il raggio.
  - **dodici direzioni non bastano**: nell'angolo del rack l'unico posto in cui il
    corpo ci sta e' a 135 gradi, e con il passo di trenta quella diagonale non si
    prova. Sedici.
  - **il centimetro di stacco**, che e' lo stesso inciampo del `FRANCO_SUOLO` della
    capsula: provando se la cosa ci sta, posata esattamente sul punto colpito dal
    raggio, la forma TOCCA il pavimento che l'ha fermata e `intersect_shape`
    risponde «occupato» per ogni posto della casa. Senza quel centimetro la rete non
    trovava un posto buono da nessuna parte e ogni cosa restava dichiarata perduta.

**E LA BOTTIGLIA ERA MURATA.** La rete nuova, appena accesa, ha cominciato a dire
«qui non ci si arriva» su un oggetto che nessuno aveva lasciato cadere: la bottiglia
della sala di controllo, che nasce a x 5,18 - dentro il parapetto della vetrata, che
occupa 5,10..5,30, con la consolle addossata dall'altra parte. Una trimesh non ha un
dentro: la bottiglia non toccava nessuna faccia, non veniva spinta fuori, e restava
murata in un parapetto alto novanta dove non si vede. Spostata di testa alla
consolle, dove il fianco c'e' davvero.

**LA CAMERA TIENE LA SUA ULTIMA SPIAGGIA.** Se un posto buono non esiste da nessuna
parte, lei - e solo lei - torna al fuoco: e' l'unico oggetto senza il quale la
partita non puo' piu' finire. In questa casa non succede mai, e la sonda lo misura;
resta per il giorno in cui la pianta cambia.

**IL DIFETTO SI RIMETTE** con `SI_PERDE=1`, che spegne la rete su tutto quello che si
prende in mano: con quello acceso la sonda accusa sette pozze su otto piu' l'angolo
del registro, cioe' la casa torna quella in cui la camera si perde.

## D-224 La rete diceva di si' e non era vero: un posto libero non e' un posto dove si puo' andare

Federico, il giorno dopo il D-223, con la foto della passerella della cupola e il
pavimento sotto: «anche qui mi sa che e' persa per sempre».

**E STAVOLTA IL REGISTRO NON DICEVA NIENTE.** Nessuna riga `[presa]`: la rete aveva
guardato e aveva risposto che da li' la si prende. Si sbagliava.

**COS'ERA.** La rete cercava «esiste un punto in cui il corpo del giocatore ci sta?»,
che non e' la domanda «ci si puo' andare?». Nella cupola le due danno risposte
opposte, e si misura:

    fra la passerella e i muri della sala restano 47 cm a nord e 57 a est
    e a ovest; il corpo del giocatore ne misura 60

Quindi il pavimento attorno alla passerella non si cammina. Ma NEGLI ANGOLI della
sala, dove il cerchio si allontana dal rettangolo, di spazio ce n'e': quattro ISOLE
da un terzo di metro quadro l'una - 1,44 in tutto - in cui un corpo ci starebbe
benissimo e in cui non si entrera' mai, perche' per arrivarci bisogna passare da un
collo di cinquanta. La rete vedeva l'isola e diceva di si'.

**IL RIMEDIO: si allaga.** Passato l'esame del corpo e quello della vista, un posto
ne ha un terzo: si allaga il pavimento camminabile a partire dai piedi, a maglia di
venti centimetri, e ci si ferma appena il conto supera **un metro quadro**. Se il
pezzo finisce prima, non e' una stanza, e' un buco. Un metro quadro sta comodamente
sopra le isole misurate e sotto il pavimento libero della stanza piu' piccola della
casa. Costa: una domanda «si prende?» vale mezzo millisecondo.

**MA LA CURA VERA E' PIU' IN SU, e si chiama fermapiede.** La ringhiera della
passerella e' due correnti tonde a mezzo metro e a un metro: sotto quella bassa
restano cinquanta centimetri d'aria. Per il giocatore non e' un buco - il parapetto,
per lui, e' un ingombro pieno - ma per una borraccia che rotola si', e di la' si
finisce nell'anello di pavimento che nessuno cammina.

Ogni passerella a grigliato ha una lamiera di dieci-quindici centimetri sul filo del
bordo, messa esattamente perche' gli attrezzi non cadano di sotto. Questa non ce
l'aveva. Dodici centimetri, tre di spessore, sul bordo esterno (salvo il varco della
scala, dove un fermapiede sarebbe la cosa in cui si inciampa) **e su quello interno**.

**IL BORDO INTERNO NON E' SIMMETRIA, E' UNA MISURA.** Con il solo fermapiede esterno
`prova_ccd.gd` e' passato da zero pose perse a due: la camera rimbalzava indietro,
scavalcava il bordo di dentro e si fermava sul fondo invisibile della passerella -
sospesa a filo del calpestio, dentro l'anello - dove non la prende nessuno perche'
fra l'occhio e la cosa c'e' il pieno centrale del D-222.

**E LA COLLISIONE ARRIVA DA SE'.** Non c'e' una riga di collisione nuova: gli oggetti
cadono sulla geometria che si VEDE (D-205), quindi basta che il fermapiede ci sia nel
modello. Il parapetto, per il giocatore, era gia' pieno.

**TERZA COSA, e non si vedeva leggendo il codice: «ferma» non voleva dire ferma.** La
rete guarda quando la velocita' scende sotto i cinque centimetri al secondo, e una
cosa che striscia a quattro per due secondi se ne va di otto - abbastanza da passare
dal calpestio al pozzo. Guardata una volta sola, la rete rispondeva sulla posizione
di prima. Adesso, se si e' spostata di piu' di cinque centimetri da dove la si era
guardata, la si riguarda.

**LE MISURE, prima e dopo:**

    la mappa            42 pozze e 10,08 m2 misurati con la rete che mentiva;
                        38 pozze e 15,82 m2 misurati onestamente
    le otto piu' grandi tutte ripescate, tutte prendibili
    l'angolo del D-223  la camera resta per terra a 35 cm, e si prende
    la passerella       spinta contro la ringhiera da sei direzioni, non cade mai

**I DIFETTI SI RIMETTONO.** `SI_PERDE=1` spegne la rete su tutto. `SOPRA_IL_FERMAPIEDE=1`
fa partire la cosa da sopra la lamiera e a un palmo dal bordo, cosi' non fa in tempo a
ricadere sull'impalcato: scavalca e cade in tre direzioni su sei - e due di quelle tre
finiscono esattamente nelle isole di nord-ovest e nord-est, cioe' dove Federico ha
perso la camera.

## D-225 Il letto se ne va dal magazzino: la notte finisce dove dice il GDD, cioe' in macchina

Federico: «puoi rimuovere il letto dal magazzino, non serve».

**AVEVA RAGIONE DUE VOLTE.** La prima e' il buonsenso: una branda fra gli scaffali di
un magazzino e' la soluzione di chi non sapeva dove metterla, e infatti il commento
che la giustificava diceva esattamente quello - la sala di controllo l'aveva
rifiutata per due misure, e il magazzino era il posto che restava.

La seconda sta scritta nel GDD da sempre, e nessuno l'aveva letta fino in fondo
(`docs/idea/idea.md`): «ogni notte il giocatore arriva all'osservatorio, lavora fino
all'alba, POI RISALE IN MACCHINA E TORNA A CASA A DORMIRE». Il turnista
all'osservatorio non ci dorme. Ci arriva e se ne va.

**MA IL LETTO ERA L'UNICO MODO DI ARRIVARE ALLA NOTTE DOPO.** `main.gd` lo cercava
per gruppo e lo accendeva all'alba; tolto e basta, il giocatore avrebbe girato per
sempre dentro un'alba che non finisce - e senza un errore, perche' non c'e' niente
di rotto in un mondo in cui non si puo' andare a casa. Il gesto si sposta, non si
toglie.

**SULL'AUTO, che c'era gia' ed era muta.** Nel parcheggio c'e' una scatola grigia
4,20 x 1,50 x 1,80 da quando esiste il blockout, messa li' perche' «ci si arriva in
macchina» e mai toccata. Adesso e' `world/interactables/macchina.gd`, prompt «Torna
a casa», e si accende all'alba con la stessa regola del letto: andarsene con una posa
in corso chiuderebbe la notte a meta'.

**E SMETTE DI ESSERE UN BLOCCO**, che e' la regola che il letto aveva gia': un
interagibile si porta dietro la propria collisione, e lasciarlo anche fra i blocchi
vorrebbe dire due solidi nello stesso posto - uno che risponde al raggio e uno muto -
con angoli da cui non compare nessun prompt. Mesh e forma stanno nel nodo.

**VENTI METRI DI PRATO, e sono il punto e non un pedaggio.** Dalla porta al
parcheggio si rifa' al contrario la strada dell'arrivo, con l'osservatorio che si
spegne alle spalle. ADR-003 dice che i passaggi sono GESTI: ci si siede al monitor
perche' si e' camminati fin li', e si va a casa perche' si e' usciti.

**LA SONDA CAMBIA OGGETTO E CAMBIA METODO.** `prova_letto.gd` diventa
`prova_macchina.gd` e fa le stesse tre domande - nasce spenta, il prompt compare da
un posto in cui ci si sta in piedi, ci si arriva. Ma la terza ha dovuto cambiare
attrezzo: la prima stesura CAMMINAVA, puntando l'auto e tenendo premuto avanti, e
diceva «non ci si arriva» perche' il giocatore nasce DENTRO l'edificio e la linea
retta verso il parcheggio passa dentro il muro sud e dentro la teca dei meteoriti.
Misurava la propria rotta, non il mondo. Adesso allaga il pavimento camminabile a
partire da dove il giocatore nasce e guarda se l'onda tocca il parcheggio: 7537
caselle da trenta centimetri, e lo tocca. Le ante sono escluse dall'allagamento -
una porta chiusa non e' un muro, si apre.

**DUE CODE, trovate perche' il magazzino vuoto ha spostato le misure:**

  - **la mappa degli smarrimenti contava i muri.** Un raggio che scende dentro un
    muro trova il pavimento lo stesso: una trimesh non ha un dentro, e il raggio
    esce dalla faccia inferiore a quota zero. `prova_smarrimenti.gd` contava come
    pavimento anche lo spessore dei muri e la pancia dei mobili, e una pozza intera
    - quella del corridoio del magazzino - era il muro. Adesso ogni punto deve
    avere lo spazio per una pallina da otto centimetri. La mappa onesta e' 10,42 m2
    in 53 pozze.
  - **la rete faceva la spola.** Nelle fessure peggiori il posto buono piu' vicino
    e' esso stesso stretto: la cosa ci rotola dentro, la rete la riguarda, e senza
    un tetto le due si rimpallano tutta la notte. Sei tentativi, poi si passa a
    `_perduta()` - che per la camera CCD vuol dire tornarsene al fuoco. Misurato:
    due mosse bastano quasi sempre, e le poche che ne chiedono di piu' sono quelle
    in cui la cosa scivola mentre la si sposta.


## D-226 Il cielo non girava: tutto il gioco diceva che gira, e la fenditura mostrava un fondale dipinto

Federico: «hai messo la rotazione del cielo?». No. `cielo.gdshader` era una funzione
della sola direzione dello sguardo, e le stelle stavano inchiodate all'edificio.

**E IL RESTO DEL GIOCO IL CIELO LO FACEVA GIRARE DA SEMPRE.** `HonestCatalog` ricava
l'angolo orario dall'ora a un quarto di grado al minuto; `HonestPointing` ha la
costante gemella; `DomeAzimuth` esiste perché la fessura va riportata «mentre il
cielo gira»; `TelescopeMount.partenza_gradi` è tarata sul fatto che «il cielo deriva
di un sesto di grado al secondo», e `banda_morta_gradi` è stata portata a zero perché
«una montatura equatoriale insegue il cielo di continuo». Due tarature scritte per un
moto che non c'era, e un pannello che diceva una cosa che dalla fenditura non si
vedeva.

**TRE PEZZI, E DUE ERANO GIÀ IN CASA.**

  - `world/tempo_siderale.gd` (nuovo): converte i minuti della notte in gradi di
    cielo e li scrive nel materiale. Non possiede il tempo — `elapsed_min` vive in
    `NightRun`, lo fa scorrere `NightClock` — e non possiede la latitudine, che
    arriva da `geometria.py` per mano di `gen_blockout.py`, la stessa riga da cui il
    modellatore inclina l'asse polare del telescopio.
  - lo shader: due uniform (`polo_celeste`, `giro`) e una rotazione di Rodrigues.
    **Il fondo NON gira**, ed è la riga che tiene separate le due cose: il chiarore
    dell'orizzonte è l'inquinamento luminoso della valle e sta con il prato, mentre
    stelle e Via Lattea stanno fra loro. Girare tutto — che è quello che farebbe
    `Environment.sky_rotation` — avrebbe fatto ruotare anche il chiarore della valle.
  - `TelescopeMount` insegue: l'angolo orario voluto è il comando più quanto il cielo
    ha girato da quando il comando è arrivato. **Non si accumula per fotogramma**, si
    ricalcola da due numeri: un integratore su nove ore porta via da solo.

**LA CUPOLA NON È STATA TOCCATA, e adesso fa quello che il suo commento promette.**
`GIOCO` (quattro gradi di errore prima che il motore riparta) era scritto per non
inseguire «la deriva del cielo con micro-scatti continui». Misurato ora che una
deriva c'è: su un soggetto a declinazione venti la calotta parte **ventisei volte in
quattro ore** — una ogni nove minuti di gioco — gira di 107 gradi in tutto e fra due
partenze non supera mai il gioco. È il rumore che si sente durante una posa.

**E ALLO ZENIT NON CE LA FA, misurato: 175 gradi di ritardo.** Su un soggetto che
culmina a 88,9 gradi l'azimut d'uscita fa mezzo giro in pochi minuti, e un motore da
otto gradi al secondo non lo insegue. Non è un difetto del motore, è la geometria di
una sfera — vicino al polo di una sfera l'azimut non vuol più dire niente — e le
cupole vere la chiamano zona cieca dello zenit. Sta scritto perché il giorno che
qualcuno decida di farci qualcosa (rifiutare quei bersagli nel planetario, o un
motore più svelto) parta da un numero.

**IL FINECORSA, che serve perché l'inseguimento non finisce da solo.** Il cielo gira
di 135 gradi in una notte: un tubo lasciato su un soggetto dalle 21 alle 6 arriverebbe
a un angolo orario che nessuna montatura può fare, e `_scrivi()` lo ruoterebbe lo
stesso — dentro il pilastro, sotto il pavimento, senza che nulla protesti. A 120 gradi
i motori si fermano e aspettano: il ribaltamento al meridiano è un gesto, e questo
progetto non ha ancora deciso quale.

**LA SCOPERTA: il disallineamento polare non esisteva, ed era scritto da due anni.**
`AR_ZERO` dichiarava «otto decimi di grado di disallineamento polare, che il
modellatore crede di aver raddrizzato e non ha raddrizzato», misurati leggendo dove
guardava il tubo a declinazione 90. Quindi l'inseguimento avrebbe dovuto perdere la
stella di un grado e mezzo per notte. Non la perde: **zero**.

`prova_rotazione.gd` misura l'asse come BISETTRICE fra due puntamenti opposti — dec 90
con l'ascensione a 0 e a 180 — invece che da una posa sola:

    asse della montatura      43,900 gradi d'altezza, azimut 0,000
    polo celeste              43,900 gradi d'altezza, azimut 0,000
    scarto                    0,000
    il tubo, a dec 90         0,951 gradi FUORI dal proprio asse

L'asse è perfetto; **è il tubo che è storto**, e girando l'ascensione descrive un cono
invece di stare fermo. Le tre righe della vecchia tabella erano tre punti di quel
cono, ed è per questo che davano tre altezze diverse. Sono due guasti opposti: un asse
storto rovina l'INSEGUIMENTO e l'unica cura è raddrizzare il treppiede; un tubo storto
sposta il PUNTAMENTO — si va sempre un grado più in là di dove si è chiesto — e si
azzera sincronizzandosi su una stella nota. Che è la fase 3, che quindi non è una fase
inventata per far scena.

**LA SONDA MISURA I RAPPORTI, non le ore.** `tools/prova_rotazione.gd`, prima stesura:
metteva le ore a mano dentro `Game.run.elapsed_min`. Funzionava per il cielo — che è
una funzione dell'ora e basta — e mentiva su tutto il resto, perché i motori si muovono
a gradi al SECONDO: spostando l'ora di un'ora in un fotogramma si misura la velocità
del motore, non l'inseguimento. Adesso accelera il tempo con `Engine.time_scale` (lo
stesso attrezzo di `F1`-`F4`) e **fissa `Engine.max_fps`**: senza, in headless il gioco
gira a migliaia di fotogrammi al secondo, i motori si muovono a passi minuscoli e
l'errore massimo della fessura ballava fra 8,8 e 13,1 gradi da un lancio all'altro —
cioè la soglia non voleva dire niente. A sessanta fotogrammi il picco è 4,0 esatti, che
è il gioco.

E una seconda coda della stessa specie: **si comincia a contare quando la calotta ha
finito col GOTO.** Un puntamento manda la fessura in mezzo giro, che è una partenza
vera ma è la partenza del puntamento; contandola insieme alle altre la sonda trovava
novanta gradi d'errore che non c'entravano niente, e sembrava un motore che non ce la fa.

**DA CHE PARTE GIRA, e perché è l'unica domanda che il confronto non chiude.** Tutte
le altre misure confrontano il cielo col telescopio, e due cose capovolte nello stesso
modo sono d'accordo: col verso al rovescio la stella resterebbe nell'oculare tutta la
notte e la sonda direbbe ok. Nemmeno un'immagine lo dice — una traccia non ha una
freccia. Lo dice l'orizzonte: il punto di cielo a est, all'orizzonte, mezz'ora dopo sta
a **5,40 gradi d'altezza**. A est si sorge.

**E L'IMMAGINE CHE DICE L'ASSE.** `tools/scatta_cielo.gd` sovrappone trenta fotogrammi
tenendo il pixel più luminoso: due ore di posa finta, e le stelle lasciano archi.
Guardando ad azimut 0 e altezza 43,9 gli archi sono cerchi concentrici **centrati nel
mezzo dell'inquadratura** (`cielo-strisciate-polo.png`), che è la prova che si guarda
invece di leggerla. La prima stesura salvava due fotogrammi a due ore di distanza: fra
due campi di rumore uniforme spostati di trenta gradi un occhio non vede niente, ed era
un referto che sembrava una prova.

**PREZZO SUL FOTOGRAMMA: nessuno misurabile.** Il fondo del cielo si disegna comunque a
ogni fotogramma; la rotazione aggiunge una Rodrigues per pixel del solo sfondo.
`prova_cielo.gd` — che misura il tremolio delle stelle girando la testa di un ventesimo
di grado — passa da 0,31% a 0,347%, contro una soglia di 0,5%: il cielo che gira non fa
sfarfallare le stelle.

Trenta sonde più il banco: tutte a zero guasti.

---

## D-227 Svitare la camera durante la posa non faceva niente, e la posa contava i frame di una camera che avevi in mano

Federico: «se qualcuno stacca la camera mentre fa le riprese deve essere rifatto quel
collegamento e le immagini sono andate perse». È vero fuori dal gioco — la camera è
appesa al PC da un cavo, e portandola via il cavo se ne va con lei — ed era falso
dentro: la posa gira in background APPOSTA, la strada che porta via dalla postazione
porta in cupola, e in cupola la camera si smonta con lo stesso tasto con cui si
raccoglie un termos. Si poteva svitarla a metà sequenza, andare in cucina, e guardare
`FRAME 7/20` diventare `FRAME 8/20`.

**IL FATTO ERA GIÀ DICHIARATO, E NON POTEVA ASCOLTARLO NESSUNO.** `CcdCamera` aveva un
`signal montaggio_cambiato(montata)` col commento «chi vuole saperlo — un domani la
fase che pretende la camera al suo posto — lo ascolta». Quel domani non poteva
arrivare: l'unico interessato è la posa, che vive in `phases/`, e un signal diretto
vuole un ascoltatore capace di raggiungere l'emettitore — `phases/` non conosce
`world/` e non ha modo di trovare quel nodo. Non era una dimenticanza, era una porta
murata. Adesso il fatto esce da `Events.camera_mounted_changed(mounted)`, come
`mains_changed` e `telescope_slewing_changed`: il mondo lo dice ad alta voce e non sa
chi lo sente.

**LA POSA MUORE, E I FRAME SONO PERSI TUTTI.** Non c'è mezza foto da salvare — quello
che c'era stava dentro la camera che adesso qualcuno tiene in mano — e la sequenza non
riprende da dove si era interrotta. La fase si chiude con `ok = false`, punteggio zero
e **payload vuoto**, che è il pezzo che conta: senza esposizione né conteggio frame nel
payload l'orchestratore non conia nessuna foto, e non c'è niente da impilare, rivelare
o vendere. Ed emette `sequence_ended`, così il telescopio smette di inseguire: una posa
morta non è una posa che continua a ronzare.

**MA NON SPARISCE IN SILENZIO, ed è la metà che si dimentica.** Chi ha svitato la
camera è in cupola, non alla postazione: se la fase si chiudesse da sola troverebbe al
ritorno un vetro nero, o peggio il pannello successivo, senza sapere perché la sequenza
non c'è più. Il guasto resta sul CRT — `CAMERA NOT RESPONDING / link lost - sequence
aborted / 5/20 FRAMES LOST` — e la fase si chiude solo quando qualcuno lo legge e preme
ENTER. È anche quello che fa un software vero: una finestra d'errore che aspetta un OK.

**FIN DOVE SI TORNA INDIETRO: solo la posa.** L'alternativa era il rientro nel setup
completo — svitando la camera si perdono davvero anche il freddo e il fuoco, e sarebbe
stato il più fedele dei due — e Federico ha scelto il meno punitivo: il collegamento si
rifà **riavvitando la camera**, e da lì si riparte dal menu post-foto senza ripercorrere
la notte. Coerenza col resto: finché la camera non è al suo posto il pannello di
configurazione non offre START, mostra `NO CAMERA - REFIT IT TO THE FOCUSER`. Un tasto
che non fa niente e non spiega insegnerebbe che il pannello mente, ed e' la stessa
regola per cui l'interruttore della cupola dice quello che fa.

**E LA NOTTE NON FINISCE CON LA POSA.** Un ciclo foto che si esaurisce senza foto
portava allo schermo vuoto e al giocatore in piedi: dopo un guasto sarebbe stato un
vicolo cieco, con le ore che restano e nessun modo di rifare lo scatto. Adesso
`night_session` guarda `PhaseResult.ok` dell'ultima fase del ciclo — `ok`, non il nome
di una fase: ADR-002 regge — e apre il menu post-foto, che è già il posto dove si
decide quanto rifare.

**IL BUCO CHE RESTA, detto invece che sottinteso.** Un signal non si riascolta dopo: una
camera smontata PRIMA che il modulo della posa esista — durante il puntamento, per dire
— non viene sentita, e la sequenza partirebbe come se la camera fosse al suo posto. Per
chiuderlo servirebbe uno stato del collegamento su `NightRun`, cioè la strada del
«rientro nel setup» che è stata scartata. Sta in `deferred-work.md`.

**MISURATO, non dedotto.** `tools/prova_staccata.gd`, quattro atti in un lancio:

    a 10.0 minuti di posa: 5/20 frame          <- a metà sequenza, non ai bordi
    smontata: is_working=false, sequence_ended 1, finished 0   <- muore e ASPETTA
    ENTER: ok=false punteggio=0 payload={  }   <- nessuna foto coniata
    senza camera START non parte; riavvitata riparte
    dopo il guasto: menu aperti 1, piano esaurito 0

E il difetto rimesso, che è la sola cosa che dice se la sonda misura qualcosa:
`POSA_SORDA=1` stacca la fase dal bus — cioè rimette il gioco di prima — e la sonda
tira su quattro guasti, il primo dei quali è «la sequenza sta ancora lavorando con la
camera in mano». Il pannello del guasto è stato anche GUARDATO, girando con una
finestra (`user://staccata.png`): headless `_draw()` non gira, e una chiamata sbagliata
dentro un pannello nuovo non se ne accorgerebbe nessuno.

---

## D-228 La luna ha una data, e la data si vede

Federico: «aggiungi la luna nel cielo che fa la luce di fondo, in base al calendario deve
esserci la luna della dimensione giusta». Sono due richieste che stanno in piedi solo
insieme — una luna che si vede piena e illumina come una falce sarebbe peggio di nessuna
delle due — e quello che mancava era il pezzo che le tiene: **una data**.

**Il gioco non aveva un giorno.** `night_index` contava le notti e basta. Adesso la notte
1 è il **16 novembre 1999** e ogni notte è il giorno dopo. Novembre non è un gusto: la
notte va dalle 21:00 alle 06:00, e nove ore di buio a 43,9 gradi di latitudine esistono
solo d'inverno — l'orologio del gioco aveva già scelto la stagione, mancava solo di
scriverla. Il sedici perché è il giorno dopo il primo quarto: la prima notte si apre con
una mezza luna a sud-ovest che tramonta dopo mezzanotte, cioè mostra subito tutte e due
le cose che questo lavoro produce — la luna che c'è e la luna che se ne va. Cominciare al
novilunio avrebbe fatto sembrare rotta la funzione appena scritta.

**L'astronomia è vera, ed è verificata contro un almanacco.** `core/luna.gd` è il modello
a bassa precisione di Meeus troncato ai termini che contano — non un contatore modulo
29,53, che sbaglierebbe fino a **mezza giornata** perché la Luna corre su un'ellisse.
`tools/prova_luna.gd` lo confronta con sei date lunari pubblicate del 1999, fra cui il
novilunio dell'eclissi totale dell'11 agosto:

    novilunio  11 ago 1999 11:09 UT (eclissi totale)   scarto 0.09 gradi (10 min)
    plenilunio 23 nov 1999 07:04 UT                    scarto 0.33 gradi (39 min)
    plenilunio 22 dic 1999 17:31 UT                    scarto 0.20 gradi (24 min)

e trova anche la **superluna** del 22 dicembre — 357 mila chilometri, disco del 7,8% più
grande della media — che un modello senza l'ellisse non potrebbe avere. Un modello lunare
che nessuno confronta con un almanacco è un generatore di numeri plausibili: qualunque
formula produce una palla che cresce e cala in un mese, e sembra giusta a chiunque la
guardi, compreso a chi l'ha scritta.

**E il ciclo non è programmato da nessuna parte: esce dal calendario.** Notti 7-8 luna
piena tutta la notte, e il cielo profondo non si fotografa; dalla 13 la luna sorge sempre
più tardi; dalla 20 alla 27 non c'è affatto, perché sta in cielo di giorno. Un
astrofotografo guarda il calendario prima del meteo, e adesso il gioco lo può dire senza
scriverlo da nessuna parte: con la luna alta il fondo del cielo si fa lattiginoso e
restano solo le stelle più forti.

**D-078 non è stata disfatta, è stata ripresa.** Quella decisione fissava la luna a 0,22
«perché di notte da una finestra si vede attraverso solo se dall'altra parte c'è qualcosa
da vedere». Con un calendario vero, un terzo delle notti è senza luna, e le vetrate
sarebbero tornate lastre nere: il difetto che D-078 aveva chiuso, riaperto dal calendario.
Il fondo adesso si chiama `ENERGIA_CIELO`, vale 0,07 e ha una ragione fisica prima che di
gioco — airglow, stelle, il chiarore della valle che lo shader del cielo dichiara già come
inquinamento luminoso. Sopra ci si somma la Luna, fino a 0,44 nella piena alta del 23
novembre: il doppio di ieri, ed è voluto.

**Due bugie dichiarate, perché scritte in chiaro valgono più che nascoste.**

- **Il disco è disegnato quattro volte più grande del vero.** Il mondo si disegna in un
  SubViewport da 640×360 a 75 gradi di campo: mezzo grado di Luna sono **due pixel e
  mezzo**, e in due pixel e mezzo non esiste nessuna fase. Il fattore è costante, quindi
  il rapporto resta vero — la superluna resta più grande di ogni altra luna dell'anno.
- **La frazione illuminata entra lineare nell'energia.** La curva di fase vera è
  ripidissima: una mezza luna manda un *decimo* della luce di una piena, non la metà. Al
  rapporto vero, venti notti su ventinove sarebbero indistinguibili dal novilunio e il
  calendario — la cosa che questo lavoro rende leggibile — tornerebbe un interruttore fra
  luna e buio.

**Tre difetti trovati dagli attrezzi, non dalla lettura.** E sono tre generi diversi, il
che è il motivo per cui gli attrezzi sono due:

1. **La direzione della luce era pesata sull'energia.** Con la mezza luna a ventiquattro
   gradi, il fondo del cielo valeva quasi metà del totale e tirava la direzione di
   **ventotto gradi verso l'alto**: in cielo la luna a sud-ovest, per terra le ombre di
   una luce quasi allo zenit. Adesso il peso è l'**altezza**: finché la Luna sta in cielo
   la luce è la sua, per fioca che sia — è comunque l'unica cosa lassù che faccia
   un'ombra netta.
2. **L'angolo di fase non era ripiegato su 0..180.** Dalla luna piena in poi restava sopra
   180, e il nome della fase diceva «novilunio» per venti notti di fila, compresa quella
   col disco illuminato al cento per cento. Sulla luce non si vedeva niente — il coseno
   non distingue 200 gradi da 160 — era un guasto che esisteva solo nelle parole.
3. **Le fasi uscivano tutte complementari**, per un segno nella normale della sfera:
   `luna_dir` va da chi guarda verso la Luna, la normale del centro del disco va dalla
   parte opposta. Luna piena disegnata come falce e falce come piena, con l'ora, la data,
   la fase e l'energia **tutte giuste**. Nessuna prova numerica poteva vederlo.

Il terzo è la ragione per cui `tools/scatta_luna.gd` non si limita a salvare un provino
delle dodici fasi: di ogni cella **conta i pixel accesi** e li confronta con la frazione
illuminata dichiarata dalle effemeridi. Misurato, dopo la correzione:

    notte 28  illuminata 0.29, misurata 0.28      notte  9  illuminata 0.96, misurata 0.96
    notte  1  illuminata 0.55, misurata 0.56      notte 15  illuminata 0.37, misurata 0.39
    notte  7  illuminata 1.00, misurata 1.00      notte 18  illuminata 0.12, misurata 0.14

Il provino salva anche `luna-in-gioco.png` — campo visivo vero, dieci pixel di disco — e
le due immagini servono insieme: la seconda è quella onesta.

**Il difetto si rimette**, come per il cielo che gira: `FISSA=1` riporta la luna alla posa
scritta a mano di ieri, e `tools/prova_luna.gd` deve trovare tutto immobile — stessa
direzione a ogni ora, stessa energia in tutte le notti del mese. Se non cambiasse niente,
quella sonda non starebbe misurando quello che crede.

## D-229 La faccia della Luna è quella vera, e ha rivelato che il cielo è allo specchio

Federico: «puoi mettere i crateri?». **Non inventati**: la faccia è il mosaico LROC del
Lunar Reconnaissance Orbiter e il rilievo viene dalle quote dell'altimetro LOLA, dal CGI
Moon Kit della NASA (pubblico dominio, credito in `CREDITI.md`). La Luna è l'unico oggetto
del cielo che tutti riconoscono, e una palla con dei buchi a caso non sarebbe la Luna.

**Il rilievo non è esagerato.** La mappa a 8 bit del kit non dice quanti metri valga un
livello di grigio; quella a 16 bit sì (mezzi metri, più ventimila). `tools/prendi_luna.py`
ne ricava le pendenze vere — media 3,8 gradi, il 99% sotto i 16,6 — e la luce le usa con
la legge di **Lommel-Seeliger**, la fotometria della regolite: alla luna piena il disco
resta piatto e i crateri spariscono, al terminatore il Sole è radente e ogni pendenza
conta. È esattamente dove, al telescopio, i crateri si vedono davvero
(`luna-da-vicino.png`).

**La faccia gira nel corso della notte**, perché il nord della Luna è il suo asse vero nel
cielo di quell'istante (il polo dell'eclittica, a un grado e mezzo per le leggi di
Cassini), non «l'alto dello schermo».

**Il disco è sceso da 2,4 a 1,3 volte l'albedo media**: con la faccia vera, a 2,4 mari e
altipiani finivano entrambi nella spalla della curva ACES e la Luna sembrava una foto
sovraesposta. La media si misura sul file, non si ricopia: la NASA ha rifatto il mosaico
nel dicembre 2025. Le fasi misurate sul provino restano entro 0,05 della frazione
illuminata.

**LO SPECCHIO.** Per girare la faccia serve un prodotto vettoriale, e un prodotto
vettoriale dà un verso in un mondo e l'opposto nel suo specchio. Misurandolo è venuto fuori
che il cielo di questo gioco **è allo specchio**: con l'alto a +Y, il nord a +Z e l'est a
+X, guardando il polo l'est cade a *sinistra*. Le stelle girano in senso orario attorno al
polo invece che antiorario, e la luna crescente è illuminata a sinistra (una «C») invece
che a destra (la «D» del proverbio: *la luna è bugiarda*). Con le stelle procedurali non si
vedeva; la tabella della montatura in `telescope_mount.gd` lo conferma (angolo orario −90
all'azimut 89, cioè +X).

La Luna **non corregge lo specchio da sola** — girerebbe al contrario delle stelle e il
telescopio non la inseguirebbe — ma lo **misura** (`Luna.chiralita()`) e si orienta di
conseguenza: faccia e luce sono sempre coerenti fra loro, e il banco lo verifica con un
invariante che non dipende dagli assi (finché cresce, il Sole sta sull'est della Luna, dalla
parte di Mare Crisium). Oggi quindi la faccia è coerente e **specchiata** rispetto al cielo
vero; il giorno che la convenzione venisse raddrizzata, la Luna seguirebbe senza toccare una
riga.

**Nota di numerazione**: la voce precedente era uscita come D-102, che esisteva già (le
porte). È stata rinumerata D-228.

## D-230 La stampante ad aghi diventa una macchina vera, e il verso non si deduce: si guarda

La stampante della sala di controllo erano **tre scatole**: la cassa, una scatola più
piccola sopra per il trattore e una fessura di materiale «Schermo» al posto del display.
Da mezzo metro erano tre scatole, che è lo stesso difetto del telefono e dei faldoni.

**IL MODELLO È UNA MACCHINA CHE È ESISTITA**: Okidata Microline 320 Turbo, nove aghi,
1990, da Sketchfab con licenza CC-BY (Remik.Papaj — il credito sta in `CREDITI.md`, che la
licenza lo impone). Coperchio acrilico, manopola del rullo, pannello serigrafato PRINT
QUALITY / CHARACTER PITCH e la targhetta: nel 1999 è la stampante attaccata al PC di
acquisizione, perché un'osservazione la si vuole su carta. Fra le alternative scaricabili,
la Heathkit CC-BY è di vent'anni prima e il tributo alla OKI 320 è CC BY-**NC**, cioè
inutilizzabile qui.

**SI SCALA SULLA PIANTA, NON SULL'ALTEZZA.** La ML320 è una carrozza da nove pollici —
36 cm — e l'impronta scritta a mano ne dichiarava 54. `posa_modello()` fra il limite
dell'altezza e quello della pianta prende il più stretto, quindi l'altezza dichiarata è
larga apposta e a comandare è la misura del ferro vero. Passata com'era, sarebbe uscita una
stampante taglia e mezza più grande del mobile che la regge.

**IL FRONTE GUARDAVA IL MURO, E NESSUN CONTROLLO POTEVA DIRLO.** Girato di −90 gradi il
pannello finiva contro la finestra nord: la targhetta e i tasti li vedeva solo l'intonaco, e
alla stanza restava il retro con la feritoia del trattore. L'impronta era rispettata, le
misure erano giuste, il render no. Il verso si è trovato rendendo i due lati lunghi e
guardandoli; adesso c'è `controllo-pc-stampante.png`, da un metro, che è la distanza a cui
la differenza si vede.

**ERA UNA SCATOLA DI GHIACCIO, E LA CAUSA STA NEL FILE.** Il modello ha **un solo
materiale per quattordici mesh**, dichiarato `alphaMode: BLEND` perché tre di quelle mesh
sono il coperchio acrilico: con il blend acceso per tutte, le undici piene venivano
disegnate ordinate alla buona e con le facce interne visibili (il materiale è anche
`doubleSided`), e il beige diventava vetro — si vedeva il mobile attraverso la cassa.

**LA DIVISIONE SI CHIEDE ALLA TEXTURE, NON AI NOMI**, che in quel file sono tutti
`defaultMaterial.NNN`. Per ogni mesh `opacizza_il_pieno()` campiona l'alpha della baseColor
sui suoi UV: misurate, le tre del coperchio stanno fra **0,53 e 0,69** e le altre undici fra
**0,96 e 1,00** — in mezzo non c'è nessuna, e la soglia cade nel vuoto fra i due gruppi. È
il caso normale dei modelli di archivio con una parte trasparente, non l'eccezione, e per
questo la funzione sta in `modellare.py` e non accanto alla stampante.

**IL MODULO CONTINUO RESTA FATTO A MANO**, perché il modello è la macchina sola: la carta a
fisarmonica che le esce di sopra è il pezzo che dice che sta lavorando, ed è la stessa
regola del pulsante del quadro elettrico — si modella solo quello che il modello
scaricato non ha.

## D-231 In cielo ci sono i pianeti, e non si vedono mai tutti

Federico: «vorrei che nel cielo mettessimo anche cose più base da vedere come i pianeti, ma
deve essere fatto in modo logico, non sempre si vede tutto». Le due metà della richiesta
sono una sola cosa, e la seconda è quella che decide come si fa la prima.

**Perché i pianeti e non altre stelle.** Il cielo di questo gioco è procedurale (D-184, D-194): un campo di puntini plausibile e *anonimo*, in cui non c'è niente da riconoscere e
niente da nominare. I pianeti sono l'esatto contrario — sono cinque, si chiamano per nome,
sono più luminosi di quasi tutte le stelle, e chi alza gli occhi da un osservatorio li
riconosce prima di qualunque costellazione. Aggiungere altre stelle avrebbe aggiunto
rumore; questi aggiungono **oggetti**.

**«Non sempre si vede tutto» non è una regola: è la conseguenza.** Non esiste da nessuna
parte una riga che dica «Giove sì, Mercurio no». Ci sono un'orbita, una magnitudine e tre
condizioni — l'orizzonte, l'aria, il fondo del cielo — e l'elenco di stanotte esce da lì. È
lo stesso patto della Luna (D-228): decide il calendario, non il programmatore.

**L'astronomia è quella vera, e si verifica.** Gli elementi orbitali sono quelli pubblicati
da JPL per le posizioni approssimate dei pianeti maggiori (Standish, 1800-2050, pubblico
dominio, credito in `CREDITI.md`), risolti con l'equazione di Keplero; le magnitudini sono
le formule dell'Astronomical Almanac, anello di Saturno compreso. `tools/prova_pianeti.gd`
le confronta con le configurazioni **pubblicate** del 1999 e le ritrova cercandole:

    opposizione di Giove, 23 ottobre 1999      trovata a +22 ore
    opposizione di Saturno, 6 novembre 1999    trovata a +11 ore
    massima elong. di Venere, 30 ottobre       trovata a +24 ore, 46,49 gradi (pubblicato 46,5)

più i due invarianti che nessun modello sbagliato rispetta — su vent'anni, Mercurio non si
stacca dal Sole più di 27,83 gradi e Venere più di 47,13.

**Il Sole calcolato due volte.** `core/luna.gd` lo ricava dalla serie di Meeus,
`core/pianeti.gd` dalla posizione della Terra nella sua orbita: due modelli scritti in due
momenti diversi per due scopi diversi. Concordano entro **0,0072 gradi**, e il banco li
confronta a ogni giro. È la verifica che non costa niente e che non ha bisogno di un libro:
se divergessero, la Luna sarebbe illuminata da una parte e le fasi di Venere dall'altra, e
ciascuno dei due file avrebbe ragione da solo.

**La visibilità è ottica, non gusto.** Un pianeta si vede se è sopra l'orizzonte, se l'aria
non se lo mangia e se il cielo attorno non è più chiaro di lui. L'aria è la formula di
Kasten e Young — trentotto masse d'aria all'orizzonte, 0,25 magnitudini ciascuna: **nove
magnitudini a un grado di altezza**, che è il motivo per cui un pianeta si spegne *prima* di
toccare il profilo delle colline. Il fondo è lo stesso `contributo` della Luna che già
comanda l'energia della lampada e quante stelle restano accese, e non spegne un pianeta:
**alza il pavimento**. Con la luna piena Giove si vede uguale, e un pianeta debole tramonta
cinque gradi più in alto.

**Il mese di lavoro, misurato.** Su novanta momenti (trenta notti a tre ore): Saturno 71
volte, Giove 60, Venere 30, Marte e Mercurio **zero**. La notte 1: Giove e Saturno già a
cinquanta gradi quando comincia il turno — erano all'opposizione da poche settimane — e
tramontano alle 4:50 e alle 6:08; Venere sorge alle 3:07 e *si vede* dalle quattro, perché
la prima ora la passa nell'aria spessa; Marte tramonta alle 20:32, **mezz'ora prima che il
turno cominci**, e quindi non si vede mai; Mercurio non si stacca mai abbastanza dal Sole.
Tre insiemi diversi in una notte sola, e nessuno l'ha deciso.

**La compressione delle luminosità è una bugia dichiarata**, come la frazione illuminata
della Luna. Fra Venere e Saturno ci sono quattro magnitudini e mezzo, cioè sessanta volte la
luce: disegnate al rapporto vero, Venere è una macchia e Saturno non esiste. A 0,30 di
esponente le stesse quattro magnitudini e mezzo diventano un fattore quattro — che è la
compressione che fa l'occhio, ed è l'unico modo perché si vedano tutti e due.

**IL PROVINO HA TROVATO SATURNO SPARITO.** La prima stesura disegnava i pianeti col profilo
delle stelle — nucleo pieno e caduta al cubo su poco più di un pixel — e sembrava la scelta
ovvia: un pianeta a occhio nudo *è* un punto come una stella. `tools/scatta_pianeti.gd`
misura la luce del quadratino centrale di ogni cella e la confronta con quella dichiarata, e
ha trovato Saturno con **luce 1,28 dichiarata e 0,00 misurata**: un profilo appuntito su un
pixel vale quasi tutto solo nel suo centro esatto, e un pianeta cade dove capita *dentro* il
pixel — mezzo pixel fuori centro, e di quel nucleo ne resta un sesto. Non era Saturno a
essere debole: era Saturno caduto male. Con una gaussiana larga un pixel la perdita fra
centro e angolo è il ventidue per cento invece dei cinque sesti, e il pianeta vale quanto
deve valere ovunque cada. Nessuna prova numerica poteva vederlo — le cinque luci erano
esatte — e a occhio sarebbe sembrato «Saturno è poco luminoso».

**Il difetto si rimette**, come per il cielo che gira e per la Luna: `TUTTI=1` disegna tutti
e cinque sempre, orizzonte e aria ignorati, e la sonda deve trovare cinque luci accese di
cui tre sotto i piedi. Se con l'interruttore non cambiasse niente, vorrebbe dire che la
selezione non sta selezionando.

**Quello che non c'è**, dichiarato: Urano e Nettuno (in un cielo disegnato non si
distinguerebbero da una stella), il tempo-luce e l'aberrazione (un decimo di primo d'arco),
la rifrazione, la parallasse, le occultazioni — un pianeta che passasse dietro la Luna si
vedrebbe attraverso. E il crepuscolo: il Sole non entra nel conto della visibilità perché
nelle nove ore del turno sta sempre sotto i venticinque gradi di depressione, e scrivere una
regola per una condizione che non capita mai vorrebbe dire scrivere codice mai provato.

**ERANO PALLE, E L'HA DETTO FEDERICO A OCCHIO** («i pianeti non sono così tanto grandi»).
Misurato sul provino: Giove veniva **0,75°** a metà luce e **1,47°** contando l'alone —
quasi tre volte la Luna. Il colpevole era l'alone, `0,10` di ampiezza su quattro raggi:
portato a **0,04 su due e mezzo** Giove torna a 0,53° / 0,76°, un punto che sfavilla, e il
provino continua a dire «nessun guasto». Il nucleo non si è toccato apposta: a
`pianeta_raggio` 0,5 i pianeti sono puntini veri (0,26°), ma torna il difetto di Saturno
caduto male fra due pixel. La dimensione la fa l'alone, che è la parte che aggiunge
l'occhio; il nucleo è quella che tiene il pianeta acceso.

## D-232 Il PC dell'osservatorio ha Windows 98, e il vetro smette di avere un padrone solo

Federico: «non mi piace il terminale come lo abbiamo adesso. Vorrei che fosse magari un
Windows 98». Poi, provandolo: «quando entri al computer tu vedi direttamente Windows 98, e
uno le cose se le apre di volta in volta».

**Il realismo era dalla parte di Windows.** Il GDD dice che quel PC fa girare CCDOPS e
MaxIm DL, che nel 1999 erano finestre grigie, non terminali MS-DOS. Il fosforo resta — ma
DENTRO i programmi che parlano con le macchine; il chrome è di Windows. La regola è scritta
in testa a `crt/desktop/desktop_theme.gd` in modo che si applichi da sola, e D-173 regge:
il desktop lo si guarda due secondi, il software di ripresa venti minuti.

**Il problema vero non era grafico: era chi comanda il vetro.** `CrtScreen.show_control()`
svuotava il viewport e ci metteva il nuovo arrivato. L'orchestratore lo chiamava a ogni
fase, main.gd lo chiamava per terminale e BBS, e ognuno buttava via l'altro — da qui la
mutua esclusione, i parcheggi, `reshow_current()`. Una sonda che provava a mettere un
desktop sopra la notte perdeva la gara a ogni cambio di fase. **La gara non si è vinta, si
è tolta:** il vetro ha sempre un `Desktop`, e `show_control()` — stessa firma, nessun
chiamante cambiato — mette il Control nella *finestra di lavoro*. Terminale e BBS aprono
finestre loro. La tabella dei confini lo permetteva già: `crt/` «riceve un Control, non sa
quale», e il desktop non sa cosa mostra più di quanto lo sapesse il CRT.

**Il vetro passa da 256x192 a 352x264, e nessuna schermata è stata toccata.** Le dodici
viste del gioco sono disegnate a coordinate fisse fino a y=182: «accettare la misura dal
contenitore» non le avrebbe adattate, le avrebbe lasciate tagliate lo stesso. Il conto ha
dato un'altra strada — 352x264 è la più piccola 4:3 in cui una finestra con barra del
titolo e schede contiene un pannello da 256x192 intero, e in cui terminale e BBS stanno
interi in finestra propria. Si incorniciano, non si ridisegnano. Il banco collauda che ci
stiano.

**Il FOV da seduti è 33.** Da 42 il software si leggeva stringendo gli occhi; 30, provato
giocando, zoomava meglio ma lasciava fuori campo mezzo grado di bordo alto — che con una
finestra massimizzata è esattamente la barra del titolo. Verificato con uno scatto.

**Il puntatore è virtuale, e ADR-003 è aggiornato.** Il mouse vero non entra nel viewport
(`push()` lo scarta, e continua a farlo): le sue coordinate sono quelle della finestra del
gioco. Il raycast che ADR-003 rinviava avrebbe dato UV geometriche su un vetro curvo nello
shader e bombato nella mesh — la freccia sarebbe finita accanto al punto guardato. La
freccia invece somma lo spostamento del mouse, e sta dove la si porta. Da seduti il mouse è
del computer; **ALT tenuto premuto** gira la testa, lasciato ALT lo sguardo torna al monitor
(`DeskCamera.recenter()`). In basso lo dice una riga, con la resa del prompt d'interazione.

**Sedersi non accende niente.** Tre versioni di sonda lo hanno sbagliato in tre modi: il
desktop dietro un tasto (ci si sedeva e il mouse girava ancora la testa), il desktop che
compariva sedendosi (da lontano il monitor mostrava un'altra cosa), il desktop con tre
finestre già aperte (non si capiva cosa fosse). Il PC è acceso: Windows c'è da lontano come
da vicino, e la finestra di lavoro **nasce chiusa** — MaxIm lo apre chi si siede.

**Le fasi ascoltano solo a finestra davanti.** Con un solo vetro bastava essere seduti. Con
le finestre ci si può sedere a guardare le foto con la fase sotto, e i tasti arriverebbero
a un programma che non si vede. Adesso `NightSession` separa i due assi che già
distingueva: GIRARE segue la postazione, ASCOLTARE vuole anche la finestra di lavoro col
fuoco (`set_screen_focused`). Nei Control del viewport — menu, vendita, terminale, BBS — lo
stesso lo fa la finestra, spegnendo gli `_unhandled_input` di chi non ha il fuoco.

**Le schede di MaxIm seguono il piano, a sblocco.** Federico ha scelto la sequenza: la
notte resta un ordine, e la barra lo mostra — fatte, in corso, ancora da fare. Le
etichette le dà ogni fase con `tab_label()`, perché l'orchestratore non può nominarle
(ADR-002) e il CRT non sa che esistano; `polar` non la sovrascrive, e non cambia di una
riga. Le schede sono un indicatore, non una navigazione: dove rientrare nel piano lo decide
ancora il menu post-foto. Una sonda aveva messo POLAR in quella barra, a memoria: la notte
non la esegue. L'ordine ora viene dal `.tres`.

**Scelte di Federico sul resto:** terminale e BBS restano programmi a sé con la loro icona
(la finestra «Internet» della sonda non c'è più: MARKET era il terminale, FORUM la BBS);
rivelazione, vendita e menu post-foto si aprono dentro MaxIm; la vendita resta a fine posa.
La mutua esclusione fra terminale e BBS è caduta con la ragione che la teneva in piedi.
Photos elenca `Game.run.photos`, cioè le foto vere della notte.

**Tahoma e non MS Sans Serif,** misurato affiancando la stessa lista: a 10 px sul vetro le
lettere di MS Sans Serif si toccano. Tahoma arrivava con Windows 98.

**Aperto, e detto qui perché non si perda:** il monitor si usa solo se la notte ha qualcosa
da fare (`_refresh_affordances`), quindi fra il piano esaurito e l'alba non ci si siede —
e Photos e la BBS restano irraggiungibili proprio nell'attesa. È una scelta di design della
2.x sull'attesa vuota, e cambiarla non è stato fatto di sbieco. Le liste non scorrono. Il
terminale è ancora l'interfaccia MS-DOS dentro una finestra.

## D-233 Il quaderno delle procedure sta a sinistra del monitor, al posto del foglio appeso

Federico: «mi piacerebbe di fianco al pc a sinistra, un libro con le istruzioni per giocare e
fare le varie fasi». Fra tre forme — un raccoglitore d'ufficio, un volume rilegato, un
organizer di pelle ad anelli — ha scelto l'organizer, e ha deciso che **prende il posto del
«foglio di procedura appeso al monitor»** del GDD, che non era mai stato fatto.

**IL MODELLO È VERO**: `binder_notebook` di Poly Haven, CC0. Il set ne porta due, aperto e
chiuso; si tiene il chiuso (17 × 20 × 2,5 cm), decimato a milleduecento facce da
`prop_blender.py`. L'aperto è largo trentasei centimetri e fra la tastiera e il telefono non
ci sta.

**IL POSTO È IL VUOTO CHE C'ERA**: il monitor arriva a +0,24 dalla mezzeria della sedia, il
telefono comincia a +0,69, e in mezzo restano quarantacinque centimetri di piano. `QUADERNO`
in `geometria.py` è derivato dalla consolle e dalla sedia, avanti a mezzo metro dal muro — da
in piedi davanti alla consolle ci si arriva con la mano — e girato di nove gradi.

**SI LEGGE NEL VIEWPORT DEL MONDO**, come il velo dell'oculare: la carta passa dal filtro con
la grana della stanza. Due pagine alla volta, A/D o rotella o clic per sfogliare, E o Esc per
chiudere. Le pagine stanno in `data/quaderno/quaderno.tres`, e l'a capo lo fa
`QuadernoData.a_capo()` in colonne: la stessa funzione la usa il banco per dire se una pagina
esce dal foglio e se ogni fase del piano ha la sua pagina.

**IL CONTENUTO VIENE DAL CODICE, NON DAL GDD**: le otto fasi le ha rilette un agente, tasti,
numeri e condizioni con il riferimento al file. Quello che ha trovato strada facendo è D-238.

**NON È FIRMATO.** Negli appunti di economia c'è un «G.» che lascia soldi e biglietti e che il
protagonista non conosce: firmare con quella lettera il manuale di chi ti ha assunto avrebbe
deciso di sbieco una cosa della trama.

## D-234 Dove c'erano le frecce c'è W A S D

Federico: «dove uno dovrebbe usare le freccette voglio che si usi il wasd». Le azioni delle
fasi al PC, del menu dopo la foto, della vendita, del terminale e della BBS passano dalle
frecce a W A S D in `project.godot`, e le righe d'aiuto sugli schermi lo dicono (`W/S SELECT`,
`WASD CENTRE`, `A/D FOCUSER`).

**CON IL CAMMINARE NON SI SCONTRANO**, per una regola che c'era già: seduti, il controller del
giocatore è spento (ADR-003), e W non muove nessuno.

**MA C'ERA UN BUCO, e con W A S D si trovava prima.** SOLVE, GOTO e FOCUS leggono i tasti con
`Input.get_axis` nel `_process`, che legge la tastiera e non il fuoco: con la BBS in primo
piano, scorrere i messaggi muoveva anche il telescopio — con le frecce succedeva uguale. Adesso
quelle tre fasi muovono il ferro solo se `is_processing_unhandled_input()`, cioè se
l'orchestratore ha deciso che ascoltano (`NightSession.set_player_present`).

## D-235 I suoni segnaposto se ne vanno tutti

Federico: «rimuovi i suoni terribili che hai messo fin'ora». Erano onde quadre generate in
GDScript: il borbottio della moka, il ronzio della montatura e il cigolio della cupola (già
zittiti il 31 agosto con `ToniSegnaposto`), il beep del terminale e della BBS, la portante del
modem, e il campanello di fine sequenza (`sequence_done.wav`). Via tutti, con
`toni_segnaposto.gd` e `sequence_chime`.

**QUELLO CHE SI PERDE, detto**: la fine della posa non si sente più da un'altra stanza, e il
quaderno non la promette. Il posto per il suono vero resta — `IndoorsVolume` è ancora in scena,
e il GDD descrive ancora com'è fatto il segnale. Quando arriveranno campioni veri si rimettono
dei nodi, non della logica: il rituale della moka, i suoi timer e gli eventi della sequenza
sono rimasti interi.

## D-236 La lampada e la lampadina escono dal gioco

Federico: «lampada e lampadina non li voglio». Fuori dalla scena erano già (D-181, D-183), ma
il codice c'era tutto: `lamp.gd`, `lamp.tscn`, `lampadina.tres` nel catalogo,
`PlayerProfile.lamp_fixed`, `Game.mark_lamp_fixed()`, la tavola del banco. Via tutto; nel GDD
la lampada esce dalle attività del rifugio e dalla cura dell'osservatorio.

**I SALVATAGGI VECCHI** possono avere `lamp_fixed` nel profilo: una proprietà che lo script non
ha più si ignora caricando, e al primo salvataggio sparisce.

## D-237 M42 e M8 fanno finta di stare appena sopra l'orizzonte

D-192 aveva misurato che questa cupola non vede sotto i 47,7 gradi, e che M42 (culmina a 40,7)
e M8 (21,7) non si vedono mai — mentre la commessa della prima notte chiede proprio M42. Alzare
lo strumento di un metro e quaranta l'avrebbe risolto per davvero. Federico: «facciamo finta
che siano appena sopra l'orizzonte».

**LA FINZIONE STA IN UN NUMERO SOLO**, la declinazione dei due `.tres`: +36 per M42 e +9 per M8.
Catalogo, GOTO e montatura leggono lo stesso dato e restano coerenti fra loro. Il commento nel
`.tres` dice che il numero è falso, e qual è quello vero.

**AL PRIMO GIRO ERA FINTO A METÀ.** I numeri erano +4,2 e +3,6, cioè il soggetto CULMINAVA appena
sopra i 47,7 gradi — e culminare appena sopra vuol dire stare sotto per quasi tutta la notte:
M42 si poteva puntare solo dalle 23:24 all'1:36. Federico l'ha scelto all'inizio del turno, il
catalogo lo dava visibile e il GOTO ha risposto BELOW DOME HORIZON: «devo aspettare che arrivi a
48? che palle». La proprietà giusta è un'altra: **sopra l'orizzonte per TUTTA la finestra che il
catalogo dichiara**, la stessa che gli altri soggetti avevano già (M45 non scende sotto 53,6
gradi, M13 sotto 49,9, M57 sotto 50,9). Con +36 M42 non scende sotto 49,7 fra le 21:00 e le
04:00; con +9 M8 non scende sotto 50 fra le 21:00 e mezzanotte.

**E M31 AVEVA LO STESSO DIFETTO IN PICCOLO**, con la declinazione vera: alle 21:00 e alle 05:00
stava a 46,7 gradi, cioè per il primo quarto d'ora del turno il catalogo lo dava visibile e il
GOTO lo rifiutava. Lì non c'è niente da fingere: la finestra si stringe a 21:15-04:45, dove è a
49,3.

**NON UNA REGOLA NEL CODICE**, del tipo «se è sotto, fai finta che sia sopra»: sarebbe una bugia
in un posto dove nessuno la cerca, e varrebbe per ogni soggetto che verrà. Così la bugia è di
due soggetti, e sta scritta accanto a loro.

## D-238 Le incoerenze trovate rileggendo il gioco per scrivere il quaderno

L'agente che ha riletto le fasi per il quaderno ha trovato una decina di punti in cui il codice
e i commenti, o il GDD, non dicevano la stessa cosa. Federico: «sistema tutto».

**LA CUPOLA GIRA DA SOLA, e va bene così**: a mano si aprono e si chiudono i battenti, la
rotazione non ha un comando manuale. `dome_azimuth.gd` diceva che la pulsantiera restava come
comando manuale della rotazione, `desk_camera.gd` che la cupola si apriva dal PC.

**LA CORRENTE GOVERNA LE LUCI E LO SCHERMO DEL MONITOR, e basta**: il GDD diceva «PC, monitor,
montatura e luci», `events.gd` prometteva che PC e montatura l'avrebbero ascoltata.

**UN GOTO CHE RINUNCIA CHIUDE IL CICLO FOTO.** Prima si andava avanti con fuoco e posa, e si
fotografava un soggetto che il telescopio non vedeva. Una fase del ciclo che finisce con
`ok = false` porta l'indice in fondo, e si apre il menu dove si cambia soggetto.

**LA POSA SA COM'È LA CAMERA QUANDO NASCE**: `Events.camera_mounted` tiene l'ultimo stato
annunciato. Prima una camera smontata durante il puntamento non si sentiva, e `phase_imaging.gd`
lo dichiarava come buco.

**IL RAFFREDDAMENTO**: `time_constant` valeva 8 di default e 6 nel `.tres` (ora 6 tutti e due);
`is_saturated` e `saturation` non li usava nessuno (tolti); e il commento parlava di un limite
al novanta per cento che il codice non ha — la temperatura balla solo chiedendo più del fondo.

**I COMMENTI**: il FOV da seduti è 33 e non 42; la zona di fuoco pieno va da -124 a +124 passi;
`main.gd` parlava di W A S D solo per la fase polare.

## D-239 Le foto escono dalla stampante, e si appendono dove si vuole

Federico, il 6 settembre: «quando una foto finisce di essere renderizzata in automatico parte
una stampa e puoi appenderla ai muri». Scelto allora: **dove vuoi, su qualsiasi muro** — non a
chiodi già decisi, non in una pila sulla scrivania. Poi la richiesta si è persa dietro la moka
senza lasciare traccia qui, e il 13 l'ha cercata nel gioco e non c'era.

**A COLORI, E LA ML320 NON LO SA FARE.** La stampante della sala ha nove aghi e un nastro nero
(D-230): nel 1999 una foto da lì usciva retinata in bianco e nero. Messo davanti alla scelta,
Federico ha preso le foto com'erano. Resta il modulo continuo con i fori del trattore, che è la
carta che quella macchina tira e dice da dove arriva il foglio.

**LE FOTO SONO QUELLE DEL PROTOTIPO PHASER**, tre per soggetto, e il livello lo decidono le soglie
del prototipo: sotto 50 la più rovinata, da 80 la più pulita (`Photo.image_tier`). Non è lo
scaglione del pagamento, che ha cinque gradini tarabili e decide le lire. Le pagine le compone
`tools/stampe_foto.py` in `assets/stampe/`, un pixel per millimetro. **Da dove il prototipo le
abbia prese non è scritto da nessuna parte**: `CREDITI.md` lo dice, e va chiarito prima di
distribuire il gioco.

**PARTE A FOTO EMERSA, non a foto registrata.** `Events.photo_revealed` lo emette la notte quando
la rivelazione ha finito: prima, sul monitor c'è ancora rumore, e la stampante stamperebbe una
foto che nessuno ha visto. Una pagina esce in venti secondi; due foto di fila fanno due stampe in
fila, e la seconda spinge giù la prima se nessuno l'ha strappata.

**«QUALSIASI MURO» È UNA DOMANDA AL MONDO**, non un elenco di posti: sulla geometria che si vede
(la corazza, non gli ingombri), verticale entro dieci gradi, piatta sotto tutto il foglio — nove
punti entro un centimetro e mezzo — e con tre centimetri liberi davanti. Da 160 posti e direzioni
della sala di controllo, guardando dritto, 19 dicono sì, sui muri e sui vetri. Il pavimento, una
mensola e una stampa già appesa dicono no (`tools/prova_stampa.gd`).

**APPESA È FIGLIA DI CIÒ SU CUI STA**: un'anta aperta si porta via la foto, la cupola la fa girare.
Il registro (`PlayerProfile.photo_prints`) la ricorda in coordinate di quella cosa, e dopo un
riavvio torna allo stesso posto: misurato, a 0,00 mm.

**Da verificare giocando:** i venti secondi di stampa; quanto copre il foglio tenuto in mano; e se
appendere sui vetri delle finestre va bene o va tolto — «ai muri» diceva la richiesta.


## D-240 Fuori di notte non si vedeva niente: l'ambiente era tarato per le stanze spente

Federico, il 13 settembre, appena uscito: «non vedo nulla».

**LA FACCIATA GUARDA A NORD, E LA LUNA DA QUI STA SEMPRE A SUD.** Chi esce resta nell'ombra
dell'edificio per tutta la notte, e in ombra arrivava solo l'ambiente: 0,035, il numero che
D-078 ha fissato perché una stanza spenta resti spenta. Misurato con `tools/prova_trafila.gd`
(`VISTA=uscita`, il salvataggio di Federico, notte 34, Luna a 0,38): facciata 0 livelli su
255, prato 4. Senza Luna tutto l'esterno sta fra 1 e 3.

**FUORI SI FANNO DUE COSE**, in `world/dark_adaptation.gd`, che era già l'unico nodo a
scrivere l'esposizione:

- **l'occhio si fa il buio** come in cupola: stesso guadagno 2,4, stessi cinquanta secondi;
- **l'ambiente diventa quello del cielo** nel tempo di passare la porta (due secondi): tutto
  il fondo `ENERGIA_CIELO` più un terzo della Luna, con un colore più grigio.

**L'AMBIENTE NON SA NIENTE DEI MURI, E ALL'APERTO NON SERVE CHE LO SAPPIA.** È la ragione per
cui dentro resta basso (D-153, D-181), e dentro resta basso: sale solo con il giocatore fuori
dal volume `Dentro`. La bugia che rimane è dichiarata nel file: stando fuori, anche le stanze
che si vedono dalle finestre ricevono il cielo.

**TRE TARATURE SMENTITE DALLE FOTO:**

- **solo l'esposizione**: il prato emerge, la facciata resta nera, perché zero per qualunque
  guadagno fa zero;
- **il blu dell'ambiente di dentro**: su un prato verde, in lineare, dà quasi zero. Facciata blu
  notte, erba nera;
- **l'ambiente pari a tutta la lampada della Luna**: facciata a 80, un crepuscolo.

Misurato dopo, mediane in livelli su 255:

    caso                                   facciata   prato
    notte 34, appena usciti (3 s)              11        7
    notte 34, occhio fatto                     43       22    (verso la macchina: 28)
    novilunio, occhio fatto (LUNA=0.07)        16        6
    piena allo zenit (LUNA=0.44)               47       33
    sala spenta, da dentro                      0        0    ambiente fermo a 0,035

La sonda ha due viste nuove, `uscita` e `nord`, e `LUNA=` per forzare la notte senza aspettare
il calendario.

**Da verificare giocando:** i cinquanta secondi anche fuori (uscendo si vede poco, poi sempre di
più); se al novilunio basta per trovare la macchina; il colore della facciata.


## D-241 Quello che si ha in mano si lancia, tenendo il sinistro fino a barra piena

Federico, il 13 settembre: «voglio che se hai un oggetto in mano tenendo premuto il pulsante
sinistro si possa lanciare, una piccola barra che fa vedere che stai caricando e solo se arrivi al
massimo lanci».

**SOLO A BARRA PIENA, E PARTE AL RILASCIO.** Otto decimi di secondo (`Player.TEMPO_CARICA`);
mollato prima non succede niente e la barra torna vuota. Non c'è un lancio corto: ogni click
distratto con la moka in mano la sposterebbe. Piena, la barra resta piena finché si tiene, e
l'oggetto parte quando si alza il dito: la prima stesura partiva da sola, e Federico ha scelto il
rilascio.

**LA BARRA STA SOTTO IL MIRINO**, sedici pixel per due nel viewport a 640×360, disegnata come il
punto (`Crosshair.set_carica`): è dove sta l'occhio mentre si mira. Esiste solo mentre si carica.

**PARTE DALLA MANO E VA DOVE SI GUARDA**, verso un punto quattro metri lungo lo sguardo: la mano
sta in basso a destra, e un tiro dritto passerebbe sempre ventidue centimetri a destra del mirino.
Sei metri al secondo per un chilo, con la radice della massa come la mano, ma sotto il mezzo chilo
non si va più forte (`Carryable.VELOCITA_LANCIO`, `MASSA_BRACCIO`): da 8,5 m/s per le cose leggere
a 4,9 per quella da un chilo e mezzo. La velocità del corpo si somma.

**PASSA DA `lascia()`**, quindi la stampa lanciata annuncia di essere cambiata come quando la si
posa. La camera CCD resta tirabile come tutto il resto (scelto da Federico), e lanciata accanto al
fuoco NON si avvita: si avvita solo posandola con `E`.

Il click che ridà il mouse non carica; la carica si perde posando, con lo strappo e liberando il
cursore. Nel quaderno, pagina «Come ci si muove»: `SINISTRO  tenuto, lancia`.

**E GIRA.** Federico, provandolo: «ho provato a tirare la bottiglia e cade perfettamente in piedi».
In mano la cosa sta dritta, e senza giro volava dritta com'era e toccava terra sul fondo. Adesso il
lancio la fa ruotare in avanti a 9 rad/s, con un terzo di caso sulla velocità e mezzo radiante
sull'asse (`Carryable.GIRO_LANCIO`). In volo lo smorzamento angolare (4) è tolto e torna al primo
urto: lasciato, il giro si spegneva in un quarto di secondo, prima di atterrare.
`LANCIO_SENZA_GIRO=1` rimette il difetto.

**Misurato** con `tools/prova_mani.gd`: mollato a metà (barra a 0,50) la scatola resta in mano;
tenuto, la barra è piena a 0,80 s e mezzo secondo dopo la scatola è ancora in mano; mollata, parte
a 6,0 m/s e dopo un secondo sta a 3,04 m. Otto lanci della bottiglia con la sua forma vera e seme
fisso: nessuna si ferma in piedi; senza giro, sette su otto. Banco verde.

**Da verificare giocando:** gli otto decimi; se la barra si legge; se sei metri al secondo sono
troppi dentro casa; se il giro sembra un polso o una trottola.


## D-242 Le prime pagine del quaderno le ha riscritte Federico, e l'indice si compone da solo

Federico, il 14 settembre, ha riscritto le prime tre pagine del quaderno («cambialo così»:
procedure del turno, come muoversi, l'ordine delle operazioni) e ha chiesto un indice.

**IL TESTO È SUO, IMPAGINATO PER LA CARTA.** Lo ha mandato in markdown, e grassetti e tabelle il
`Label` non li disegna. La tabella dei tasti è diventata due colonne battute a spazi, con una riga
di trattini sotto l'intestazione; anche gli elenchi sono colonne allineate. Dei grassetti resta solo
«UNA SOLA VOLTA», in maiuscolo come si sottolinea a macchina. Ogni sua pagina superava le 20 righe:
la parte finale continua su una seconda pagina senza titolo, a destra della prima, così ogni
argomento sta su una doppia pagina aperta e non si interrompe girando il foglio. «Monte Grimano»
staccato l'ha scritto lui così; nel resto del progetto è «Montegrimano».

**L'INDICE È A PAGINA 2**, sotto il suo paragrafo «Le procedure sono elencate nell'ordine…», che lo
introduce; il resto dell'introduzione sta a pagina 1 in 18 righe. Elenca solo le pagine che vengono
dopo e che hanno un titolo (i seguiti no), con i puntini e il numero che il quaderno stampa in fondo.
Con 13 voci la pagina è piena, 20 righe su 20: una pagina con titolo in più la fa sbordare, e il
banco lo dice.

**SI COMPONE, NON SI SCRIVE** (`PaginaQuaderno.indice`, `QuadernoData.righe_indice()`): scritto a
mano, il primo testo che va a capo su due pagine sposterebbe tutti i numeri, e l'indice mentirebbe
in silenzio. Il banco rilegge ogni voce e controlla che il numero porti alla pagina con quel titolo.

**Misurato:** banco verde (17 pagine, nessuna fuori dal foglio, 13 voci d'indice tutte giuste,
nessuna fase senza pagina); `tools/prova_quaderno.gd` passa, e negli scatti le tabelle restano
allineate.

**Da verificare giocando:** se l'indice serve davvero, visto che si sfoglia due pagine alla volta e
non si salta a un numero.


## D-243 Le partite sono cartelle, e la casa si ricorda quello che hai toccato

Federico, il 14 settembre: prima di andare avanti con la cucina «potrebbe valere la pena inserire
il concetto di salvataggio», perché «testare cose e fare cose senza avere un concetto di
salvataggio» diventa strano. Le scelte sono sue, fatte davanti a quattro domande: la notte a metà
riparte da capo e il mondo no; le partite si cambiano con un tasto di sviluppo; si beve col
destro; il mocio sta in magazzino.

**UNA PARTITA È UNA CARTELLA**, `user://saves/<nome>/`, con `profile.tres`, `night.tres` e il
nuovo `world.tres`. La vera si chiama `partita`, e i due file che stavano sciolti in `saves/` ci
sono stati traslocati al primo avvio (`SaveManager.trasloca_vecchi`: una volta sola, e senza
sovrascrivere un profilo che là ci fosse già). Fuori dallo sviluppo è l'unica.

**F10, SOLO IN SVILUPPO** (`debug/partite.gd`): continuare, aprire un'altra partita, cominciarne
una da zero, copiare la vera in una di prova. Aprire ricarica la scena, e la notte in corso non si
salva, come è sempre stato. L'ultima scelta resta aperta anche rilanciando (`saves/scelta.txt`),
e finché non si torna alla vera in alto a sinistra resta scritto «PARTITA DI PROVA: prova-1»:
dimenticarsela vorrebbe dire credere di aver perso le lire. W/S e E, come tutto il resto.

**LE SONDE HANNO LA LORO**, `sonde`, svuotata a ogni avvio: lanciando una scena che non è
`main.tscn` si apre quella. Prima giravano sulla partita vera — è la notte 34 del D-240 — e
potevano scriverci. `PARTITA=<nome>` forza una partita precisa, anche la vera.

**IL MONDO SI RICORDA** (`core/world_state.gd`, `world/memoria_mondo.gd`): dove stanno le cose
che si prendono in mano, cosa c'è dentro, se un fuoco è acceso. Si scrive un secondo e mezzo
dopo che una cosa si è fermata, e alla chiusura della finestra; la chiave è il percorso del nodo
dalla radice del mondo. Fuori restano la camera CCD — attrezzatura della notte, che riparte
avvitata — e le stampe, che il loro registro ce l'hanno già nel profilo (D-239).

**SOLO QUELLO CHE È STATO TOCCATO.** La prima stesura si ricordava tutto: all'avvio le cose cadono
del millimetro che le separa dai piani, e quel millimetro contava come uno spostamento. Il primo
avvio della partita vera ha scritto la posizione di ogni bottiglia. Innocuo quel giorno, e un guaio
il giorno in cui si sposta un mobile nel generatore: le cose mai toccate resterebbero inchiodate al
posto vecchio. Adesso la prima fermata non conta, e la voce la scrive solo ciò che il giocatore ha
preso, spostato o riempito. Il file di quel primo avvio è stato cancellato.

**Misurato:** banco verde, con i controlli nuovi (quale partita apre un avvio, i nomi ammessi —
niente `../`, niente cartelle del banco — e il giro su disco di trasformate e numeri dentro il
mondo). `tools/prova_memoria.gd`: una tazza spostata finisce nel file da sola, rimontata la scena
torna lì a 0,0 cm, e il termos mai toccato resta dove lo mette la scena e nel file non c'è.
Avviato il gioco vero, il profilo si legge dalla cartella nuova.

**Da verificare giocando:** F10; chiudere la finestra e ritrovare le cose dove le si era lasciate;
che dopo il trasloco la partita sia quella di ieri.


## D-244 La moka fa il caffè sul fuoco, e il caffè si versa nelle tazze

Federico: «ci sono due moke, una è sui fornelli, una è a sinistra, ed è quella che si deve
acquistare». E: la moka «fa il caffè quando la metti sul fornello, non fa il caffè a caso… al
momento tu premi, fa il caffè, e che è sta merda?».

**LA MOKA DISEGNATA SUL FUOCO È USCITA** dal modello della cucina (`cucina_blender.py`): era un
rilievo del piano che si vedeva e non si toccava, e accanto a quella vera diceva che il caffè si fa
da solo. Resta una moka, quella del negozio, che compare comprandola.

**LA MOKA SI PRENDE IN MANO** (`Moka` è un `Carryable`), e il rituale a tempi della 3.3 — E riempie,
E «mette sul fuoco» senza muoversi, E versa, E beve — non c'è più. Il caffè lo fanno le cose. La
moka si porta ai fornelli; guardando un fuoco la riga dice «Metti la moka sul fuoco», ed E ce la
mette dritta, centrata, col manico verso chi la mette. Si gira la manopola. Su un fuoco acceso
cuoce quaranta secondi di gioco, e tolta dal fuoco non torna indietro; negli ultimi secondi dal
becco esce vapore, e alla fine dentro ci sono tre tazze, perché è una moka da tre. Il vapore è
l'unico segnale finché non ci sono i suoni (D-235).

**IL FUOCO GIUSTO È QUELLO GUARDATO, non quello vicino alla mano.** La prima stesura cercava il fuoco
più vicino alla mano, e da in piedi davanti al bancone la mano sta venticinque centimetri oltre il
bordo: la sonda non ha trovato un solo punto della cucina da cui la moka andasse sul fuoco. Il
giocatore adesso passa a quello che tiene in mano il punto guardato (`Carryable.mira`).

**LE MANOPOLE SI GIRANO** (`world/interactables/fornello.gd`, una per fuoco): un quarto di giro in
senso antiorario, con una tacca, e una corona di diciotto lingue blu attorno al bruciatore con un
filo di luce. Non potevano più stare disegnate nella stanza. Piano, fuochi e manopole stanno in
`geometria.py` (`COTTURA`, `FUOCHI`, `MANOPOLE`, `MANOPOLA_FUOCO`), letti dal disegno e dal
generatore: le due manopole di sinistra accendono i fuochi di sinistra, e l'esterna quello dietro.

**VERSARE.** Con la moka in mano, guardando una tazza vuota, la riga dice «Versa il caffè nella
tazza»; E porta la moka sopra la tazza col becco verso di lei, la inclina di 65°, scende un filo di
caffè e la tazza si riempie. Le tazze sono quelle che c'erano già — sulla consolle e sul tavolo
della cucina — perché Federico ha chiesto di usare quelle. Il caffè è un disco largo quanto la
tazza alla sua quota, e il becco e il fondo sono misurati sui vertici dei modelli. La sonda ha
trovato due difetti del gesto: la moka arrivava di fianco e rovesciava la tazza, e poi versava in
una tazza coricata (adesso durante il gesto non la urta, e in una tazza coricata non entra niente);
e il verso del becco, ricalcolato a ogni passo, spostava il bersaglio insieme alla moka, che restava
ferma a sedici centimetri senza toccare niente (adesso si fissa all'inizio del gesto).

**SI BEVE COL DESTRO** (azione `usa`): la tazza sale verso la bocca, si inclina, il caffè cala. Il
destro non ha una riga sua, e la sua voce va in coda: «[E] Posa la tazza    [DESTRO] Bevi il
caffè». Nel quaderno, `Tasto destro  Bevi`. Con le mani piene E posa sempre, TRANNE quando la cosa in
mano sa fare qualcosa con ciò che si guarda: non è la lotta della porta, perché la tazza con la moka
c'entra e la porta no.

**LANCIATA PIENA SI SVUOTA**, al primo urto; e una tazza piena che resta coricata, da qualunque parte
arrivi, si è rovesciata. La macchia per terra e il mocio che la pulisce aspettano i modelli.

**LA COPPIA C4** si apre quando la moka comincia a cuocere e si chiude quando il caffè è bevuto.
Nessun bonus, come prima.

**Misurato:** `tools/prova_moka.gd`, riscritta, cammina tutto con le mani del giocatore — il suo
raggio, la sua riga, E e il destro — e passa le sue undici domande: il negozio la vende; senza
possesso non c'è; comprata sta sul bancone (0,899 su un piano a 0,900); sui quattro fuochi non c'è
niente; si prende; va sul fuoco e ci resta; la manopola accende quel fuoco; il caffè sale, tre tazze,
coppia aperta una volta; versata col becco a 0,0 cm dalla bocca e due dosi rimaste; bevuta, coppia
chiusa; lanciata piena, svuotata; la casa ricorda due dosi e il fuoco spento. Banco verde,
`tools/prova_mani.gd` passa. Gli avvisi «MODELLO VECCHIO» di `gen_blockout.py` sono l'orologio dei
file: in `geometria.py` ci sono costanti nuove, la geometria degli altri modelli non è cambiata.

**Da verificare giocando:** la fiamma (colore, quanta luce); la manopola, che da un metro è una
decina di pixel; i quaranta secondi; il gesto del versare (65° in un secondo e otto); il bere visto
da dentro la testa; se «[DESTRO]» in coda alla riga si legge.


## D-245 La moka cadeva dal fuoco: un corpo rigido si sposta nel passo di fisica, e F2–F4 accorciano i passi

Federico, giocando: «anche se dice metti la moka sul fuoco comunque mi cade». `prova_moka.gd`
passava, perché consegnava E direttamente al giocatore. `tools/prova_moka_fuochi.gd` rifà il gesto
come si gioca — la moka che insegue la mano, in piedi davanti al piano, il tasto vero che passa per
i viewport — su tutti e quattro i fuochi e a ×1, ×2, ×5, ×10. Il registro della sua partita aveva
F2, F3 e F4 premuti.

**PRIMA CAUSA: `Engine.time_scale` ALLUNGA IL PASSO DI FISICA, non ne fa fare di più.** A ×10 un
passo simula un sesto di secondo, e una moka appoggiata su barre da un centimetro rimbalza: a ×5 e
×10 finiva cinque o dieci centimetri più in là, fuori dal fuoco. Il controllo del tempo adesso alza
insieme passi al secondo e tetto dei passi per fotogramma (`TimeControl.accelera`), e ogni passo
resta un sessantesimo di secondo di gioco. Solo in sviluppo; le impostazioni del progetto non
cambiano. Le sonde che accelerano usano la stessa funzione.

**SECONDA CAUSA, rivelata dalla prima cura: `global_transform = …` su un corpo rigido si perde.**
Con cinque passi per fotogramma la moka, messa sul fuoco, tornava alla mano e cadeva per terra: il
motore riscriveva sul nodo la posizione vecchia prima che la nuova gli arrivasse. È la stessa cosa
che può succedere a ×1 in una finestra a 60 fps. `Carryable.teletrasporta()` sposta il corpo dentro
`_integrate_forces`, e la moka va sul fuoco così.

**Misurato:** `prova_moka_fuochi.gd`, 16 casi, la moka resta sul fuoco in tutti (prima: 8 guasti).
La moka scrive nel registro dove l'ha messa, e un secondo dopo avvisa se non ci sta più.


## D-246 In SOLVE il primo tasto accendeva SLEWING e faceva perdere il cielo

Federico: «il primo movimento che faccio mi dice slewing e poi non lo dice più». Non era il
lampeggio del D-198, e `prova_slew.gd` continuava a passare.

**LA CAUSA.** La stella di taratura ha l'angolo orario di quando la fase parte, e il cercatore resta
giusto così, perché stella e tubo girano insieme. Ma la montatura nel mondo insegue il cielo (0,15
gradi al secondo vero), e per lei un angolo orario fermo è un comando di tornare indietro. Fermi a
guardare otto secondi, il tubo aveva inseguito 1,2 gradi; il primo tasto lo rimandava indietro di
quasi tre, oltre il mezzo grado che accende la scritta. I tasti dopo stavano sotto la soglia perché
ognuno azzerava il conto. La GOTO non l'ha mai avuto: ricalcola il soggetto all'ora della notte.

**LA CURA:** la fase annuncia il puntamento più il cielo girato da quando è partita
(`PhaseSync._cielo_girato`), e il punto di sincronizzazione si scrive all'angolo orario del SYNC,
come fa la GOTO quando si risincronizza.

**Misurato** (`tools/prova_solve.gd`, la fase vera sulla montatura vera): prima, al primo tasto 2
cambi di stato e il tubo indietro di 2,88 gradi; adesso 0 cambi, e il tubo avanza col cielo.
`prova_slew.gd` invariata: GOTO 2 cambi, inseguimento e centraggio 0.


## D-247 Il riepilogo dell'alba in due colonne, con i nomi delle schede

Federico, con uno scatto: «si vede male questo». Le fasi sono diventate otto e il riepilogo era
impaginato per quattro: una colonna a quindici pixel scendeva fino a 209 su uno schermo alto 192,
l'intestazione cadeva sopra la prima riga e le ultime fasi sopra la riga del cielo. Adesso due
colonne da quattro, e i nomi sono quelli delle schede che si sono viste tutta la notte (BOOT, COOL,
SOLVE, SEQ) invece delle chiavi interne (STARTUP, COOLING, SYNC, IMAGING).

**Da verificare giocando:** allo scatto non è stato riguardato; nessuna sonda disegna il riepilogo.


## D-248 Il lavello e i piatti della cucina vengono da fuori

Federico, il 14 settembre, ha lasciato in `_da_scaricare` due modelli Sketchfab CC-BY,
«kitchen sink» e «plate», da usare per il lavello e per i piatti dello scolapiatti.

**IL LAVELLO È UN BLOCCO DA INCASSO**, in resina scura con il miscelatore nero (Heliona,
10.616 facce). Sostituisce quello fatto a mano: quattro pareti d'acciaio, la piletta e un
rubinetto di cilindri. Arriva lungo due unità e si scala sulla pianta a **86 × 52**, la misura
di serie di un monovasca con gocciolatoio, sopra il vano con le due ante. Il foro nel piano
sta un centimetro dentro il suo bordo, così nessuna faccia del foro resta a filo di una del
modello. Il bordo appoggia quattro millimetri sopra la formica, e si misura sul lato davanti:
il punto più basso del modello è il fondo del blocco, e non dice dove stia il bordo. Girato di
270 gradi il miscelatore va verso il muro, la vasca a est e il gocciolatoio a ovest, e lo
scolapiatti si è spostato sul gocciolatoio.

**I PIATTI SONO QUATTRO COPIE DELLO STESSO MODELLO** (Black Snow, 2.556 facce), scalati da
sessanta a ventiquattro centimetri, in piedi e inclinati di otto gradi. Del modello si tiene la
forma: arriva grigio e senza mappe, e la ceramica è quella della cucina.

**LA METALLICITÀ DEL LAVELLO È ZERO** (`usa_le_ridotte(..., metallico=0.0)`), come per i
sanitari: la mappa metallicRoughness presa com'è ne farebbe uno specchio, e in una cucina
chiusa uno specchio è nero.

Crediti in `CREDITI.md`, fonti e motivi in `tools/prendi_modello.py`.

**Misurato:** `cucina_blender.py` passa i suoi controlli (impronte, vasca, luce della finestra,
soffitto) e `cucina-lavello.png` mostra il lavello nel piano, il miscelatore contro il muro e i
piatti in piedi. `cucina.glb` pesa 11,8 MB, di cui 1,3 per le tre mappe a 1024 del lavello;
Godot lo reimporta senza errori.

**Da verificare giocando:** come rende in partita, che finora si è visto solo in Blender; se
un lavello di resina scura sta bene nella cucina del 1999, dove era più comune l'acciaio.


## D-249 Il prato sale e scende, e ha l'erba

Federico, il 14 settembre: «come possiamo fare il fuori? mettere un po' di erba ecc...». Fra le
proposte ha scelto di partire da erba e terreno.

**IL PRATO NON È PIÙ UN BLOCCO.** Era una scatola verde da 48 × 44 m tre centimetri sotto i
pavimenti, generata insieme ai muri. Adesso è il nodo `Prato` (`world/prato.gd`): una maglia da
un metro costruita all'avvio, con la collisione fatta degli stessi triangoli. Rettangolo e quota
sono quelli di prima; `gen_blockout.py` gli passa il recinto e le impronte su cui restare piatto.

**LA FORMA STA IN FUNZIONI PURE** (`world/forma_prato.gd`), e il banco la collauda
(`_check_prato`). Il prato è piatto per due metri attorno ai due corpi della elle e all'auto, poi
in tre metri diventa mosso: onde fino a 45 cm fatte di tre sinusoidi, così la stessa gobba sta
nello stesso posto a ogni avvio. Fuori dal recinto sale fino a 90 cm in dieci metri. Non scende
mai sotto zero, perché recinto e auto poggiano a zero.

**LA COLLINA DI FUORI HA UN RACCORDO SUO, DI OTTO METRI.** Con i tre metri delle onde, appena
fuori dal cancello e accanto all'auto il prato saliva del 45%, e il banco l'ha segnalato. Adesso
la pendenza massima è del 23%.

**L'ERBA È UN CIUFFO VERO FOTOGRAFATO, non una forma inventata.** L'erba di Poly Haven non si può
ripetere a migliaia: `grass_medium_02` sono cinque ciuffi da 700 a 2.500 facce l'uno.
`tools/erba_blender.py` ne fotografa quattro di fianco, senza luce e senza sfondo, in una texture
512 × 128, e in gioco ogni ciuffo è due rettangoli incrociati con quella foto (`erba.gdshader`:
trasparenza a soglia, normale in su, vertici agganciati come in `ps1.gdshader`). Sono 5.744 ciuffi,
tre al metro quadro, in un solo MultiMesh, con una tinta fra verde e paglia; nessuno sta dentro i
muri o sotto l'auto. Il lato della foto, 42 cm, è scritto in due file, e il banco controlla che
coincidano.

**IL PAVIMENTO DEL PRATO HA UNA MAPPA.** Federico, giocando: «l'erba va bene, il pavimento però
è ancora un verde e basta». È Ground037 di ambientCG (`prendi_texture.py`, cartella `prato`):
erba rada, chiazze di terra, qualche rametto. Grass001 e Grass004 sono prati da giardino, e
Ground013 e withered_grass di Poly Haven sono già tutti paglia, che invece portano i ciuffi. La
mappa è **tinta sulla media del verde di prima**, 51 66 43, perché la luce di fuori è tarata su
quel prato (D-240). Le UV della maglia sono in metri, e la ripetizione la dà il righello
dichiarato da ambientCG, 2,10 m, letto dal FONTE.txt da `gen_blockout.py`.

**Misurato:** banco verde. `prova_macchina` passa: a piedi dalla porta si arriva ancora all'auto.
Negli scatti di `prova_trafila` (viste `nord`, `uscita` e la nuova `macchina`) i ciuffi si
leggono, anche con la Luna vera della notte 1; la fascia buia davanti alla facciata è l'ombra
dell'edificio, come in D-240.

**Da verificare giocando:** come si cammina sul terreno mosso; la densità dell'erba; il colore del
prato, che resta segnaposto fino al pack di texture.


## D-250 L'auto è una 500, e con questa licenza il gioco non si distribuisce

Federico ha lasciato in `_da_scaricare` la «1965 Fiat 500F» di Ddiaz Design (Sketchfab), «per
tornare a casa». La licenza è **CC-BY-NC-SA**: niente uso commerciale, e le modifiche restano
sotto la stessa licenza. Glielo si è detto, con due 500 CC-BY in alternativa, e ha scelto di
tenerla come **segnaposto**. `CREDITI.md` e `prendi_modello.py` lo scrivono.

**DA 334 MILA FACCE A 20 MILA** (`tools/cinquecento_blender.py`). Via il gruppo del motore, che
conteneva anche i vani con serbatoio e ruota di scorta (92 mila facce), e i tamburi dei freni; il
resto è decimato all'8%. Metallicità a zero e cruscotto spento. È a misura vera,
2,97 × 1,32 × 1,30 m, e lo script si ferma se larghezza, altezza o interasse (1,84 m) non
tornano, se l'auto esce specchiata o se una gomma resta sollevata. `cinquecento.glb` pesa 2 MB.

**`prendi_modello.riduci()` NON INGRANDISCE PIÙ.** Portava tutte le mappe a 1024 px, e queste
stanno fra 64 e 512.

**LA SCATOLA DIVENTA LA 500** in `gen_blockout.py`. La collisione passa da 4,20 × 1,50 × 1,80 a
2,97 × 1,30 × 1,32, il nodo scende a mezza altezza (0,65) e il modello di altrettanto. Il muso
guarda est, così la portiera del guidatore sta dalla parte del prato da cui si arriva.

**Misurato:** Godot la importa senza errori. `prova_macchina`: il prompt compare da 96 punti, il
più vicino a 1,19 m. Lo scatto `macchina` la mostra intera sul prato.

**Da verificare giocando:** facce nere dove le normali del modello sono girate (non sono state
ricalcolate); i passaruota vuoti visti dal basso. Prima di distribuire il gioco serve un'auto con
una licenza che lo permetta.


## D-251 Il caffè rovesciato fa una macchia, e il mocio la pulisce

Federico, il 14 settembre: «non sto trovando da nessuna parte il mocio per pulire le chiazze di
caffè […] non trovo neanche le chiazze quando lancio la tazza». Non c'erano. D-244 lo scriveva in
una riga — «la macchia per terra e il mocio che la pulisce aspettano i modelli» — e il resoconto
di quel lavoro non l'aveva detto. D-243 aveva deciso solo dove sta il mocio: in magazzino.

**IL CAFFÈ CADE SUL PRIMO PIANO SOTTO LA TAZZA** (`Macchia.versa`, chiamata da
`Tazza._rovescia`): il pavimento, o il tavolo se la tazza ci si corica sopra. Si cerca sulla
geometria che si vede, scavalcando le cose che si prendono in mano: una macchia sul piattino
resterebbe a mezz'aria spostando il piattino.

**LA MACCHIA È GRANDE QUANTO IL CAFFÈ CHE C'ERA**: 40 ml a tazza piena, stesi a un millimetro e
mezzo, fanno una pozza da 9,2 cm di raggio. Lanciata la tazza schizza: il raggio è 1,4 volte
(12,9 cm), il bordo fa lingue e ci sono gocce attorno. Un fondo di tazza fa 2,5 cm.

**È UN RETTANGOLO APPOGGIATO, NON UNA DECAL**, tre millimetri sopra il piano e girato come il
piano. La forma la disegna `macchia.gdshader`: il bordo a lobi segue un rumore letto sul cerchio,
e il bordo è più scuro del centro come nell'anello del caffè (Deegan e altri, 1997). Pulendo
se ne va a chiazze.

**IL MOCIO STA IN MAGAZZINO**, nell'angolo sud-est, appoggiato al muro est con 15 gradi di
inclinazione (`gen_blockout.py`, derivato da `SALA_MAGAZZINO`). Due misure della sonda:
- **baricentro dichiarato a 34 cm** (`mocio.tscn`): quello automatico pesa il volume dei
  collisori, finiva a 11 cm, e il mocio si raddrizzava da solo sulle frange;
- **frange larghe 12 cm, e 15 gradi di inclinazione, non 10.**

La rotazione nel `.tscn` va scritta PER RIGHE: scritta per colonne la cima pendeva lontano dal
muro. L'ordine l'ha detto Godot, leggendo la stringa con `str_to_var`.

**ARRIVA A TERRA DA IN PIEDI**, ed è per questo che guarda da solo. Il raggio del giocatore è
lungo 1,20 m e l'occhio sta a 1,65, quindi da in piedi il pavimento non si mira mai. Il mocio
lancia un raggio suo lungo 2,20 m lungo lo sguardo.

**IL DESTRO SI TIENE.** Guardando una macchia la riga dice «[DESTRO]  Tieni premuto: pulisci».
Tenendolo le frange vanno a terra dove si guarda, restando entro un quarto di metro dalla
macchia, e oscillano di dieci centimetri. Pulisce quello che sta sotto le frange, e una macchia da
tazza piena se ne va in 2,5 secondi, una schizzata in 5. Mollato il destro, il mocio torna in mano
(`Carryable.smetti_di_usare`, chiamata dal giocatore quando il destro si alza). Nel quaderno:
`Tasto destro  Bevi / tieni, pulisci`.

**LA CASA SI RICORDA LE MACCHIE** (`WorldState.macchie`): dove stanno, quanto sono grandi, quanto
ne resta. Non stanno fra gli oggetti, perché nella scena non esistono, e le rifà
`MemoriaDelMondo`. Un salvataggio di prima non ha il campo e si legge senza macchie, quindi la
versione non cambia.

**IL MODELLO È «PAIR OF MOPS» DI SOUSINHO** (Sketchfab, CC-BY), scelto da Federico fra i due mocio
a frange trovati; credito in `CREDITI.md`. Per un'ora il mocio in magazzino c'è stato senza
modello, e Federico non l'ha trovato: un bastone invisibile largo quattro centimetri non si trova.
`tools/mocio_blender.py` tiene il mocio pulito dei due (lo si riconosce dal materiale,
`T_mop_clean`), raddrizza il manico, che nel modello pendeva di 13,3 gradi, lo porta a 1,30 m e
decima le frange da 8.400 a 2.328 facce. Il `.glb` pesa 3,7 MB.

**`usa_le_ridotte` SBAGLIAVA LE MAPPE `metallicRoughness` con più di un set**: cercava il file
`t_mop_clean_metallicrid_roughness.jpg`, e la mappa restava quella a 4096 dentro il `.glb`, in
silenzio. Adesso `metallicroughness` si cerca prima di `roughness`. Il quadro elettrico, che ha due
set, ne guadagna al prossimo giro di `quadro_elettrico_blender.py`.

**Misurato:** banco verde, con i controlli nuovi (raggi e volume, secondi di mocio, orientamento
su quattro normali, cosa copre una macchia, giro su disco delle macchie). `tools/prova_mocio.gd`,
0 guasti:
- il mocio in magazzino pende di 15,6 gradi e in cinque secondi non si muove;
- la tazza lanciata lascia una macchia sola per terra, da 12,9 cm;
- rimontando la scena la macchia torna a 0,0 cm;
- il mocio si prende;
- da in piedi, a 40 cm, la riga offre il destro;
- le frange scendono a 1 cm dalla macchia, che se ne va in 5,1 s;
- mollato il destro il mocio torna in mano, e il file resta senza macchie.

`prova_moka`, `prova_memoria` e `prova_mani` passano; `prova_mocio` ripassa col modello
dentro. `tools/scatta_macchia.tscn` fotografa tre macchie in cucina (versata, lanciata e pulita a
metà) e il mocio appoggiato nell'angolo del magazzino.

**Da verificare giocando:** il colore e la lucidità della macchia sul pavimento alla veneziana;
il gesto del mocio visto dagli occhi, che nessuno scatto ha ripreso; se si prende bene il manico
(il collisore è largo quattro centimetri, apposta); una tazza rovesciata sul tavolo lascia la
macchia sul tavolo, e oggi si pulisce col mocio anche lì, che nessuno farebbe davvero.


## D-252 Il mocio pulisce anche dove non c'è niente

Federico, giocando col mocio: «puoi fare che posso pulire anche random?». Il destro si offriva
solo guardando una macchia, le frange restavano legate a lei entro un quarto di metro, e pulita
la macchia il gesto finiva da solo.

**IL DESTRO SI OFFRE SU OGNI PIANO ORIZZONTALE DENTRO PORTATA**: il pavimento, il piano di un
tavolo. Non su un muro: la normale deve stare entro 45 gradi dalla verticale (`Mocio.PIANO`).
**LE FRANGE VANNO DOVE SI GUARDA**, e se si alzano gli occhi restano sull'ultimo punto buono. **IL
GESTO DURA FINCHÉ IL DESTRO È GIÙ**, anche dopo aver pulito una macchia. Le macchie continuano ad
andarsene quando ci passano sopra le frange, come prima.

**Misurato:** `prova_mocio.gd` ha due domande in più. Pulita la macchia, col destro giù il gesto
continua. Sul pavimento nudo la riga offre il destro e le frange vanno a terra. Nella domanda 5
la sonda cerca un posto da cui si guarda LA MACCHIA, non un pavimento qualunque: da quando tutto
il pavimento offre il destro si sarebbe fermata al primo.

**Da verificare giocando:** se tenere il destro guardando il pavimento, senza niente da pulire,
sembra un gesto o un tic.


## D-253 L'anta del quadro elettrico si apriva dentro il muro

Federico, il 14 settembre: «il box elettrico si apre dentro il muro, non va bene».

**IL CARDINE ERA GIUSTO, IL SEGNO NO.** `quadro_elettrico_blender.py` misura bene da che parte
sta la cerniera, a x +0,147 (D-195). Il verso di rotazione invece `gen_blockout.py` l'aveva
dedotto, e sbagliato: la lamiera va dal cardine verso −x, e girando attorno a y di un angolo
negativo lo spigolo libero va verso −z, dove sta il muro. Adesso `verso = 1`.

**LA SONDA NON LO VEDEVA.** `prova_rete.gd` apriva l'anta e controllava solo che il fungo si
spostasse, e dentro il muro si sposta quanto verso il prato. Adesso misura anche il punto più
indietro di tutte le mesh dell'anta, fungo compreso, nelle coordinate del quadro, e pretende che
non stia dietro il retro della cassa.

**Misurato:** prima della correzione, aperta, l'anta stava 11,7 cm dentro il muro, e la sonda lo
segnala come guasto. Dopo sta 15,3 cm davanti. `prova_rete` passa, e nel `.tscn` rigenerato è
cambiata solo la riga `verso`.

**Da verificare giocando:** se a 110 gradi verso destra l'anta aperta dà fastidio a qualcosa
accanto al quadro.


## D-254 L'anta del quadro era montata al contrario

Federico, dopo D-253: «l'hai proprio montato al contrario, cioè la parte che dovrebbe essere
interna è esterna […] come se qualcuno montasse una porta con lo spioncino che guarda verso
dentro». Il verso di apertura non c'entrava: la lamiera dell'anta era girata, con la vaschetta
dal bordo ripiegato verso fuori e il cartello del pericolo verso i fili.

**LA CAUSA È IN COME SI CHIUDEVA.** Nel modello l'anta arriva spalancata, e
`quadro_elettrico_blender.py` la girava attorno al suo centro della rotazione più corta che la
rende parallela alla cassa, 58 gradi. L'autore però l'aveva aperta oltre l'angolo retto, e i gradi
veri erano 123: la rotazione più corta la ribaltava. L'hanno mostrato quattro rendering del modello
originale: dal davanti si vede la vaschetta dell'anta aperta, da dietro il cartello. Il provino
del 1° settembre la mostrava già girata, e nessuno l'aveva guardato chiedendosi quale faccia
fosse quale.

**ADESSO SI CHIUDE SULLA SUA CERNIERA**, lo spigolo dell'anta più vicino a un bordo del fronte
della cassa. Delle due rotazioni che la rendono parallela si tiene quella che la porta davanti
all'apertura. Una rotazione attorno alla cerniera non può ribaltare l'anta. Poi la si appoggia
spostandola solo in profondità: centrata sull'ingombro della cassa, che comprende le staffe sotto,
scendeva di tre centimetri e sopra l'anta chiusa restava una fessura sui fili. Nel generatore
cambiano due numeri: la cerniera passa da x 0,147 a 0,154, e il collisore dell'anta sale a y 0,030.
Il cardine resta a destra, e `verso = 1` di D-253 resta giusto.

**LE TEXTURE RIDOTTE NON ENTRAVANO MAI.** Lo script passava a `usa_le_ridotte` il solo nome
della cartella, che non si trovava, e il quadro si portava dentro le mappe a 4096. Con il percorso
intero, e con la correzione di D-251 per `metallicRoughness`, `quadro_elettrico.glb` passa da 23 a
4,8 MB.

**Misurato:** nei provini `14_` e `14b_` l'anta chiusa ha fuori il cartello, le due viti e il fungo,
e le cerniere sul bordo destro. Nel `.tscn` rigenerato cambiano solo le due righe dell'anta.
`prova_rete` passa: l'anta aperta sta 15,3 cm davanti al muro, e il raggio del giocatore trova il
fungo.

**Da verificare giocando:** di sbieco, dal lato della cerniera, fra anta e cassa resta un filo da
cui si vede l'interno. Nel modello c'è anche lì.

## D-255 L'anta del quadro girava staccata dalla cassa

Federico, dopo D-254, con uno scatto del quadro aperto: «STACCATO». L'anta si apriva verso fuori e
col cartello dalla parte giusta, ma fra il bordo della cassa e la lamiera restava un vuoto.

**IL PERNO NON ERA LA CERNIERA.** `quadro_elettrico_blender.py` metteva l'origine dell'anta, cioè il
punto attorno a cui `PanelDoor` la gira, sullo spigolo destro della lamiera e sul fronte della
cassa. Ma l'anta è una vaschetta profonda 5,4 cm, e l'asse delle cerniere sta dentro il suo bordo.
Misurato sul `.glb`: girata attorno allo spigolo, da 30 gradi in su l'anta sta a 3,5 cm dalla
cassa, mentre nella posa dell'autore la tocca a 3 mm. Godot la girava giusta: l'errore era tutto
nel modello.

**ADESSO IL PERNO È IL PUNTO CHE LA CHIUSURA LASCIA FERMO.** Chiudere l'anta è un giro di 123 gradi
sulla cerniera stimata (D-254) più uno spostamento in profondità, e le due mosse insieme sono
ancora un giro, attorno a un punto solo. Riaprendo attorno a quello l'anta torna esattamente
nella posa dell'autore. Esce a x 0,141, 1,3 cm davanti alla cassa. Nel generatore l'anta passa da
(0,154, 0,170) a (0,141, 0,183); il collisore e il fungo restano dov'erano e cambiano solo i loro
numeri relativi. Anche il fungo del modello resta a 10 cm dal bordo dell'anta, non dal perno.

**Nessun controllo lo vedeva.** I provini mostravano solo l'anta chiusa, e `prova_rete` guardava
che aperta non entrasse nel muro. Adesso c'è il provino `14c_`, con l'anta aperta di 110 gradi, e
`prova_rete` misura la distanza fra i vertici dell'anta e quelli della cassa vicino al cardine:
sopra un centimetro è un guasto.

**Misurato:** aperta di 110 gradi l'anta sta a 7,1 mm dalla cassa, sia in Blender sia in Godot.
Nel `14c_` le cerniere dell'anta combaciano col bordo della cassa. `prova_rete` passa: il raggio
trova ancora il fungo, e l'anta aperta sta 15,8 cm davanti al retro della cassa.

## D-256 L'anta chiusa era storta, e dentro il quadro c'era già un pulsante

Federico, dopo D-255, con uno scatto del quadro aperto: «è ancora un po' staccato». E: «mi dai la
possibilità qui di staccare tutte le luci e riaccenderle?».

**IL PERNO ERA GIUSTO, L'ANTA NO.** Misurato sul `.glb`: aperta a 110 gradi, l'anta passava a 2 mm
dallo spigolo della cassa. Il vuoto stava già nell'anta chiusa: dal lato libero toccava la cassa,
dal lato del cardine ne stava a 2,3 cm. Era girata di 5,3 gradi, ed è anche il filo che il D-254
aveva visto di sbieco.

**LA COLPA ERA DI COME SI TROVA LA FACCIA GRANDE.** `quadro_elettrico_blender.py` orientava cassa e
anta sulla direzione in cui la nuvola di vertici è più schiacciata, e ogni vertice contava uguale.
Le cerniere e il bordo ripiegato dell'anta hanno più vertici della lamiera intera, e la tiravano di
lato; anche la cassa, piena di cablaggio, usciva girata di 0,7 gradi. Adesso conta l'area: si
prende la direzione orizzontale con più superficie di facce, e si media attorno a quella. L'anta
chiusa è a filo, profonda 3,6 cm invece di 5,4, e il giro che la chiude è di 117 gradi, non 123. Il
perno del D-255 esce sull'angolo della cassa, a x 0,147.

**IL PULSANTE C'ERA GIÀ.** Il fungo sull'anta stacca tutta la corrente, ma ad anta aperta sta
girato dall'altra parte. Dentro la cassa il modello ha un fungo rosso su una piastrina nera, a
destra dei morsetti: adesso è un secondo `MainsButton`, e stacca e riattacca la stessa corrente.
Lo script lo separa dalla cassa riconoscendolo dal COLORE della texture, 166 facce rosse in una
finestra di 5 cm: la piastrina nera sta alla profondità del gambo, e separarli per quota vorrebbe
dire scegliere un millimetro. Separato, il cappello rientra di 4 mm quando lo si preme, come il
fungo. È figlio del quadro e non dell'anta, e a quadro chiuso il raggio trova prima l'anta.

**Due trappole della sonda.** Con due pulsanti nel gruppo, «il primo» non dice più quale:
`prova_rete` li distingue da chi li porta. E un corpo girato non si sposta subito per i raggi, ma al
passo di fisica successivo: la sonda mirava il pulsante ad anta appena aperta e trovava l'anta
chiusa. Adesso aspetta due passi.

**Misurato:** aperta di 110 gradi l'anta sta a 3,5 mm dalla cassa (era 7,1). `prova_rete` passa: a
quadro chiuso il raggio verso il pulsante di dentro prende l'anta, a quadro aperto prende il
pulsante, e premuto due volte spegne le 20 luci e le riaccende tutte. Il banco arriva in fondo. Nei
provini `14_` e `14c_` l'anta chiusa è a filo, e quella aperta ha le cerniere sul bordo della cassa.
