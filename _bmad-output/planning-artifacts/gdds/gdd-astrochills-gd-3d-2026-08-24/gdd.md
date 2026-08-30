---
title: "Astrochill — Game Design Document"
game_type: "Simulation (+ innesto Adventure)"
platforms: "PC (Windows) — Godot 4.7.2, renderer Compatibility"
status: draft
created: 2026-08-24
updated: 2026-08-24
needs_narrative: true
---

# Astrochill — Game Design Document

**Autore:** Federico
**Tipo di gioco:** Simulation ad alta complessità, con innesto Adventure per la linea narrativa
**Piattaforma di destinazione:** PC (Windows)

---

## Executive Summary

### Concetto centrale

Hai perso il lavoro in albergo e ne hai trovato uno strano: gestore notturno di un
osservatorio astronomico appena aperto sull'Appennino marchigiano, nel 1999. Non sai niente
di astronomia. Impari sul campo, una notte alla volta: livelli la montatura, allinei al
polo, scegli cosa fotografare, avvii la sequenza. Le foto le vendi; coi soldi compri
attrezzatura che automatizza pezzi della routine, e il tempo che ne ricavi lo passi lì
dentro, da solo, con qualcosa che ha cominciato a comparire nelle immagini.

**Astrochill non è un horror.** È un gioco *creepy-cozy*: la superficie è piacevole e resta
piacevole, e la stranezza cresce dentro il lavoro invece di aggredirti da fuori. Non c'è un
mostro, niente insegue, non si muore. C'è una strumentazione tecnica descritta con
precisione storica che, lentamente, comincia a dire cose che non può sapere.

Venti notti di storia da un'ora ciascuna, poi free play senza limite. Dopo la fine, quella
cosa ogni tanto compare ancora in un frame — e ti saluta. Il titolo non è ironico: *chill*
non è la superficie che inganna, è la destinazione.

### Pubblico di riferimento

**Primario.** Giocatori di *cozy work-sim con un bordo*: chi ha finito Dredge, Strange
Horticulture, Creature Kitchen. Adulti 25-40, **sessioni di circa un'ora**, tolleranza alta
per la lentezza e per il testo, bassa per la pressione e il fallimento. Vogliono un mestiere
da imparare e un mistero da guardare, non da combattere.

La durata della notte fissata in D-007 — **60 minuti reali** — è calibrata su questo: una
notte è una sessione, e il gioco ha un punto di uscita naturale ogni volta che il pubblico
ne ha bisogno.

**Secondario.** Appassionati di astronomia amatoriale e di retrotech anni '90 — chi
riconosce CCDOPS, MaxIm DL, Cartes du Ciel e Giotto. Canale di passaparola sproporzionato
rispetto alla propria dimensione.

**Posizionamento, che è una decisione e non un'etichetta.** Tag *Cozy, Relaxing,
Atmospheric, Simulation, Story Rich*; **mai Horror fra i tag principali né nella descrizione
breve**. I giocatori cozy lasciano recensioni negative quando gli si fa davvero paura,
perché era stato promesso altro. Un `Horror` in fondo alla lista, messo dalla comunità, non
è un problema: Creature Kitchen ce l'ha e sta al 99% positive su oltre settemila recensioni.

### Punti di forza distintivi (USP)

1. **Un mestiere tecnico reale e verificabile**, non inventato: la procedura
   dell'astrofotografia CCD amatoriale del 1999, nell'ordine giusto, coi software che
   esistevano davvero.
2. **Un orrore che non ha corpo, non minaccia e non si vede.** Arriva dai dati — dark frame
   che non sono neri, autoguida che insegue una stella che non hai scelto, stack che
   contengono qualcosa che non era in nessun frame.
3. **L'ambientazione italiana del 1999 come contesto tecnico, non come colore locale.** Lire,
   56k che occupa la linea, newsgroup, riviste di astrofili. Nel 1999 l'elaborazione
   *normale* era già fatta di sottrazione dark, flat fielding e unsharp mask: la linea fra
   elaborazione e falsificazione era genuinamente contestata, e **ogni anomalia del gioco è
   quindi storicamente negabile senza inventare niente**.
4. **Le interfacce diegetiche sono il gameplay**, non la sua cornice: dieci procedure rese
   come schermi CRT dentro il mondo 3D.
5. **La metanarrazione**: alla fine ciò che si è manifestato parla al giocatore, non al
   personaggio. Nessuno dei comparabili lo fa.

---

## Obiettivi e contesto

### Obiettivi di progetto

**1. Pubblicare un gioco finito su Steam**, posizionato nello scaffale creepy-cozy.

**2. Servire come candidatura di portfolio** per lavorare in Giappone. Questo *non* riduce
l'ambizione tecnica: significa che la cosa dimostrabile va identificata e **finita**. La
cosa dimostrabile è il **sistema di interfacce diegetiche** — procedure tecniche reali rese
come schermi CRT nel mondo 3D via `SubViewport` e shader. È il grosso del gameplay, si
costruisce senza competenze artistiche, e in una revisione di portfolio si mostra in cinque
minuti: cosa che venti ore di contenuto non fanno.

**3. Finire, da solo.** Il team è una persona, che non è artista 3D né musicista. Esiste un
amico artista potenzialmente disponibile, da coinvolgere **solo davanti a un prototipo
giocabile** e con la forma dell'accordo definita prima di iniziare.

**Il budget da amministrare è il tempo, non il denaro.** Godot, Blender, asset CC0 (Kenney,
Quaternius, Poly Pizza), Freesound e Suno nel piano gratuito coprono la produzione a spesa
quasi nulla. Le uniche voci di cassa vere sono la commissione Steam Direct e l'eventuale
accordo con l'artista.

### Antefatto e motivazioni

**Il progetto ha già un prototipo giocato, e questo GDD parte da lì.** Tre mesi di codice
hanno prodotto tre fasi su dieci (allineamento polare, targeting, sequenza di imaging),
entrambe le code del ciclo (stacking, vendita), l'osservatorio in una scena sola, il
terminale d'acquisto, la BBS, e la telemetria per notte. Non esistono ancora: le rotture
delle fasi, le venti notti, la metanarrazione, i finali, l'albero degli upgrade, la rete di
osservatori, l'esplorazione dei dintorni.

**Cosa il prototipo ha dimostrato.** Che il ciclo *pazienza → scelta → attesa → rivelazione
→ ricompensa* si costruisce e regge; che le interfacce diegetiche su `SubViewport` sono la
strada giusta e sono già l'ottanta per cento del gameplay percepito; che le fasi si possono
aggiungere senza toccare l'orchestratore, perché il piano della notte è un dato.

**Cosa il prototipo ha smentito, e che è la ragione per cui i pilastri di questo documento
non sono quelli del brief.** L'ipotesi centrale dell'MVP era *«l'attesa è piacevole»*. La
telemetria di due notti misurate dice che la finestra della posa è rimasta **vuota al cento
per cento** in entrambe, e che le attività pensate per abitarla sono state usate *dopo* che
la posa era finita. Il pilastro «L'attesa è il gioco» è quindi caduto (D-002), e con esso
l'idea che l'automazione fosse una perdita. L'automazione è il premio; il tempo che
restituisce ha quattro destinazioni dichiarate (D-005); e ciò che regge il *chill* non è
l'attesa ma il rifugio (D-004).

**Il contesto di mercato.** Dredge ha superato il milione di copie con cinque persone
girando esattamente questo motore (`pesca → soldi → upgrade → autonomia → esposizione alla
storia`). Creature Kitchen ha validato lo scaffale creepy-cozy e la scoperta che *fare
amicizia* con la cosa strana è un finale che il mercato premia. Lo scaffale horror indie è
invece saturo e brutale — ed è la ragione per cui il posizionamento è una decisione presa,
non un'etichetta ereditata.

---

## Gameplay centrale

### Pilastri di gioco

Quattro pilastri. Ogni meccanica di questo documento risponde ad almeno uno; una meccanica
che non risponde a nessuno è scope creep travestito.

**1. Il lavoro è vero.**
Le fasi non sono minigiochi a tema astronomico: sono la procedura reale
dell'astrofotografia CCD amatoriale del 1999, nell'ordine giusto, coi software che
esistevano davvero (Cartes du Ciel, CCDOPS, MaxIm DL, Giotto).
*Steerizza:* ogni fase va progettata a partire dalla procedura storica, non
dall'ergonomia; il testo delle interfacce è in inglese perché le macchine parlano
inglese; le anomalie devono essere impossibili **secondo la procedura**, non secondo il
buon senso.
*Se lo togli:* restano dieci minigiochi a tema spazio, e lo scarto quando arriva non
inquieta nessuno perché non c'era una regola da violare.

**2. L'osservatorio è un rifugio.**
Te lo rendi tuo, e non ti può fare del male. Il lato attivo: la lampada che smette di
lampeggiare, la moka, la stufetta, il cigolio della cupola che sparisce quando la
lubrifichi. Il lato passivo: non si muore, non si fallisce, la commessa si può rifiutare
senza conseguenze, la notte si chiude da sola all'alba.
*Steerizza:* nessuna meccanica introduce fallimento, timer punitivi o perdita di
progresso; le spese di cura e comfort sono acquisti legittimi e non "sprechi"; il posto
va costruito perché il giocatore lo abiti, non solo perché ci lavori.
*Se lo togli:* si rompe la promessa dello scaffale cozy, e il pubblico primario lascia
recensioni negative perché gli era stato promesso altro.
*La rottura narrativa che rende necessario questo pilastro:* il rifugio che ti sei
costruito ha un ospite. Non funziona se il rifugio non è stato prima costruito davvero.

**3. Gli strumenti mentono.**
L'orrore è informativo, mai spaziale. Non c'è niente da vedere e niente da cui
scappare: arriva dai dark frame che non sono neri, dall'autoguida che insegue una stella
che non hai scelto, da uno stack che contiene qualcosa che non era in nessun frame. Chi
conosce il mestiere sa che è impossibile e non sa come dimostrarlo.
*Steerizza:* ogni fase espone il proprio stato dietro un livello di indirezione, così
che la stessa meccanica possa avere una sorgente di verità diversa (il tempo invece
dell'input, un catalogo falso invece di quello vero); le anomalie non producono mai
minaccia fisica; l'ordine delle rotture segue l'inverso della tecnicità — si guastano
prima le fasi silenziose, per ultime quelle tecniche.
*Se lo togli:* resta un work sim onesto senza secondo atto.
*Stato:* è l'unico pilastro **mai dimostrato dal prototipo**. Il seam architetturale
esiste (`PhaseTruthSource` più l'iniettore `F9`), zero rotture sono implementate.

**4. Il tempo liberato ti espone.**
`foto -> lire -> upgrade -> tempo -> storia`. Gli upgrade non ti fanno finire prima: ti
restituiscono minuti dentro la notte. Quei minuti hanno quattro destinazioni possibili —
esplorare i dintorni, l'edificio che si apre stanza dopo stanza, indagare le anomalie che
gli strumenti hanno prodotto, o semplicemente fotografare ancora. Le prime tre sono
esposizione; la quarta no.
*Steerizza:* il valore di un upgrade si misura in minuti restituiti, non in comodità;
la progressione narrativa avanza per **notte**, non per foto, quindi il tempo speso a
macinare lire è tempo tolto a ciò che si sarebbe potuto vedere; le tre destinazioni
"esposizione" vanno scaglionate lungo le venti notti (vedi Progressione).
*Se lo togli:* l'automazione diventa solo una notte più corta, e comprare attrezzatura
non ha più un motivo di design.
*Regola invariante che ne discende:* targeting e imaging non si automatizzano mai. Sono
il cuore della scelta.

---

**La regola che i quattro pilastri producono insieme: Astrochill offre e non obbliga mai.**
La commessa si può rifiutare. Il tempo liberato si può spendere senza esporsi a niente.
Le attività del rifugio si possono ignorare. Nessuna di queste rinunce viene punita, e
nessuna viene premiata di nascosto. Il gioco mette a disposizione e sta a guardare —
il che è, a conti fatti, anche la descrizione di ciò che lo abita.

### Loop di gioco centrale

Il gioco ha tre cicli annidati. Quello che conta è il secondo; il terzo esiste perché il
secondo lasci spazio.

#### Ciclo 1 — La notte (20 volte, poi senza limite)

```
ARRIVI, 21:00    scendi dalla macchina, il posto è al buio
  |
  +-- SETUP        fasi 1-5, una volta sola, valido fino all'alba
  |                (livellamento, bilanciamento, allineamento polare,
  |                 accensione e collegamento PC, plate solving)
  |
  +-- CICLO 2, ripetuto finché vuoi
  |
  ALBA, 06:00      il cielo si schiarisce: non c'è più lavoro da fare
  |
  TORNI ALLA MACCHINA e vai via   <-- è questo che chiude la notte, non l'alba
```

**La notte è un budget fisso di 540 minuti di gioco**, e ogni cosa ne consuma: le fasi
manuali, la posa, camminare, leggere, uscire. A `game_min_per_sec = 0,15` sono **60 minuti
reali**. Le venti notti di storia fanno quindi circa **20 ore**, più il free play.

**La notte finisce quando te ne vai.** Non ci abiti: sei il gestore notturno, arrivi in
macchina alle nove di sera e all'alba torni a casa. Chiudere il turno è un gesto fisico
— attraversare l'osservatorio, uscire, raggiungere l'auto — non una voce di menù.

Ne discendono due cose. **L'alba non ti caccia:** alle 06:00 il cielo si schiarisce e non
c'è più lavoro possibile, ma nessuno ti spinge fuori e puoi restare a guardare quanto
vuoi. E **puoi andartene quando vuoi**, anche a mezzanotte, senza che accada nulla — è il
pilastro 2 applicato alla fine della sessione.

**Requisito invariante — l'ora è sempre conoscibile.** Se la notte è un budget, il
giocatore deve poter leggere quanto ne resta, in ogni momento e da ogni punto raggiungibile
— stanza computer, cupola, cucina, prato, bosco. Senza questo, ogni decisione della notte
(rifare il setup? scattare ancora? uscire adesso?) si prende alla cieca, e il budget non è
una risorsa ma una sorpresa.

Non è una funzione nuova da inventare: `night/night_clock.gd` produce già `clock_text()`.
Oggi però l'unico posto in cui compare è l'overlay di debug — cioè il giocatore non vede
mai l'ora. È lo stesso difetto strutturale del dossier §4 applicato alla risorsa più
importante che ha.

**La forma: un orologio da polso, consultabile con un tasto.** Il personaggio alza il
polso e l'ora compare per qualche secondo, poi il braccio scende. Resta diegetico al cento
per cento — nessun numero in sovrimpressione, coerente con la regola che ogni interfaccia
di questo gioco vive nel mondo — e funziona in ogni punto raggiungibile, bosco compreso,
dove nessuna sveglia a parete arriverebbe. Un digitale del 1999 al polso di chi lavora di
notte è, per giunta, esattamente ciò che ci sarebbe stato.

> **[NOTE FOR DESIGNER]** Il costo di questa scelta è la **scopribilità**, ed è un rischio
> misurato, non teorico: il dossier §4 documenta che il primo giocatore non ha trovato
> nemmeno i tasti che il gioco aveva già (`[T]`, `[B]`, la moka, la cupola). Un orologio
> che si consulta con un tasto mai nominato equivale a non avere un orologio. La soluzione
> va trovata nella sezione Controlli e input, e deve valere per **tutte** le azioni
> disponibili, non solo per questa.

#### Ciclo 2 — La foto (più volte per notte)

```
  TARGETING     scegli cosa fotografare (mai automatizzabile)
      |
  FOCUS -> CALIBRAZIONE -> AUTOGUIDA      fasi 7-9, automatizzabili
      |
  POSA          frame x esposizione, gira in background  ---> apre il CICLO 3
      |
  STACKING      la rivelazione: vedi per la prima volta cosa hai preso
      |
  VENDITA       payout immediato, a scaglioni sul punteggio
      |
  MENU          scatta ancora / cambia target / rifai il setup / chiudi
```

Ogni giro produce una foto, un punteggio e delle lire. La **commessa della notte** —
qualcuno chiede un soggetto specifico — è il compenso che ti fa vivere e la direzione
della serata. **Si può rifiutare, e non succede niente.**

#### Ciclo 3 — La finestra libera (dentro il ciclo 2)

La posa gira da sola: mentre gira, sei libero. A questa finestra si somma ogni minuto che
l'automazione ha tolto alle fasi manuali. **Non sono due cose diverse: sono lo stesso
tempo**, ed è quello che il pilastro 4 spende.

```
  POSA IN CORSO
      |
      +-- il rifugio       caffè, lampada, cupola, cura dell'osservatorio  (pilastro 2)
      +-- l'edificio       stanze che si aprono, log, lettere, giornali     (esposizione)
      +-- i dintorni       prato, sterrata, bosco                           (esposizione)
      +-- le anomalie      riconfrontare frame, cercare nel catalogo, i forum (esposizione)
      +-- niente           fermarsi, o fotografare ancora                   (sempre lecito)
```

**Regola della finestra: la posa ti aspetta.** Quando finisce, lo stack resta pronto
finché non torni al monitor, e un segnale diegetico ti raggiunge dovunque tu sia — dentro
l'edificio e fuori. Nessun minuto perduto, nessuna corsa, nessuna punizione per essere
andato via: è il pilastro 2 applicato al ritmo.

**La forma del segnale: viene dall'edificio.** Un suono che parte dalla stanza computer,
accompagnato da una luce alla finestra visibile dal prato. Non è un avviso al giocatore: è
una cosa che l'osservatorio fa, e che si sente da fuori.

La scelta ha una conseguenza voluta sul pilastro 3: **un segnale che ha una sorgente fisica
nel mondo può partire quando non doveva.** Un allarme al polso che suona da solo è un bug;
una luce che si accende nella stanza computer mentre sei nel prato e la posa non è finita è
materiale narrativo. Il canale del segnale è già predisposto per mentire.

> **[NOTE FOR DESIGNER]** Va verificato sul campo che il segnale raggiunga il **bosco**, il
> punto più lontano raggiungibile: se lì non arriva, serve un secondo vettore (un'eco, un
> riflesso di luce sugli alberi) oppure il bosco esce dalle destinazioni raggiungibili
> durante una posa. Va deciso guardando, non a tavolino — è esattamente il tipo di difetto
> cross-file che il dossier §4 descrive.

#### Perché si rifà il loop la centesima volta

Alla notte 3 lo rifai perché il catalogo ha soggetti che non hai ancora preso e servono
lire. Alla notte 12 perché gli strumenti hanno cominciato a dire cose e vuoi vedere se
succede ancora. Alla notte 20 perché la storia chiude. **Dopo, nel free play, lo rifai
perché ogni tanto qualcosa compare in un frame e ti saluta** — e quello è l'unico posto
dove può succedere.

Non c'è un solo giro del loop la cui unica motivazione sia "contenuto nuovo".

### Condizioni di vittoria e sconfitta

**Non si perde.** Non si muore, non si fallisce una notte, non si perde progresso, non
esistono game over né schermate di sconfitta. Una foto venuta male vale meno lire; una
commessa rifiutata non ha conseguenze; una notte in cui non si fotografa niente finisce
quando decidi di andartene, e il portafoglio resta. Il pilastro 2 è questa riga.

**Non si vince, si arriva.** La notte 20 chiude la linea narrativa e produce un finale.
Dopo, il gioco **non finisce**: il free play non è una modalità sbloccata, è l'assenza di
un muro. I sistemi che lo reggono — target, committenti, economia, ciclo notte — sono
già quelli della storia.

**L'unica risorsa che si consuma davvero sono le notti di storia**, che sono venti e non
tornano. Le lire no: restano disponibili per sempre.

---

## Meccaniche di gioco

### Meccaniche primarie

#### La forma di una fase

Una notte si svolge in **dieci fasi fisse, nell'ordine**, più due code (stacking e vendita)
che chiudono ogni foto. Ogni fase è una procedura reale dell'astrofotografia CCD del 1999,
resa come schermata CRT o come gesto sulla strumentazione, e produce un **punteggio di
qualità 0-100** che concorre al valore della foto.

Ogni fase dichiara: quanto costa in minuti di notte, se può girare in background, e da dove
legge la propria verità. Quest'ultimo punto è ciò che permette al pilastro 3 di esistere
senza riscrivere le fasi: **la stessa meccanica può avere una sorgente di verità diversa**.

#### Il budget della notte

La notte è **540 minuti di gioco = 60 minuti reali** (9 minuti di gioco per minuto reale).
Ogni fase ne consuma. I valori sotto sono il riferimento di progetto, da tarare sul campo.

| # | Fase | Notte 1 | Notte 20 | Cosa la accorcia |
|---|---|---|---|---|
| 1 | Livellamento | 20 | **0** | livella motorizzata |
| 2 | Bilanciamento | 20 | 2 | si impara: diventa una checklist |
| 3 | Allineamento polare | **60** | 10 | software di polar align |
| 4 | Accensione e collegamento PC | 15 | 2 | si impara entro la notte 2 |
| 5 | Plate solving | 15 | 5 | plate-solver locale |
| | **Setup — una volta a notte** | **130** | **19** | |
| 6 | Targeting | 15 | 15 | **mai** |
| 7 | Focus | 20 | 0 | focuser motorizzato con autofocus |
| 8 | Dark e flat | 30 | 3 | libreria dark + flat panel |
| 9 | Autoguida | 20 | 5 | autoguider OAG |
| 10 | **Posa** | **40** | 40 | **mai** — la durata la sceglie il giocatore |
| — | Stacking | 15 | 15 | |
| — | Vendita | 10 | 10 | |
| | **Ciclo foto — ripetibile** | **150** | **88** | |

**Cosa producono questi numeri.** Notte 1: setup più due foto occupano 430 minuti; ne
restano 110, ai quali si sommano gli 80 delle due pose — **21 minuti reali di libertà su
60**. Notte 20: setup più tre foto occupano 283 minuti; ne restano 257, più i 120 delle
pose — **42 minuti reali su 60**. L'automazione raddoppia il tempo libero, e lo fa in modo
leggibile dal giocatore.

#### Le tre regole invarianti

**1. Targeting e imaging non si automatizzano mai.** Sono il cuore della scelta: cosa
fotografare e quanto a lungo. Nessun upgrade li tocca, in nessuna configurazione.

**2. L'automazione compra tempo pagando in qualità.** Ogni upgrade che automatizza una fase
**fissa il punteggio di quella fase a un valore garantito ma non ottimo** — per esempio 70
su 100 per il polar align automatico. Un giocatore che quella fase la sa fare bene ottiene
di più a mano. Questo tiene in equilibrio D-006: automatizzare tutto massimizza il tempo e
riduce il valore di ogni singola foto, e la scelta resta al giocatore ogni notte.

**3. Le rotture seguono l'ordine inverso della tecnicità.** Si guastano prima le fasi
silenziose e meditative (livellamento, allineamento polare), per ultime quelle tecniche
(plate solving, imaging). Quando arriva il turno delle fasi tecniche, il giocatore ha già
imparato abbastanza da sapere che ciò che vede è impossibile.

#### Le dieci fasi

| # | Fase | Il gesto | Parametri e punteggio | Come si rompe |
|---|---|---|---|---|
| 1 | **Livellamento** | tre viti, la bolla d'aria va portata dentro il cerchio; se esageri da un lato devi compensare dall'altro | dalla distanza finale della bolla dal centro | la bolla non sta ferma: si sposta da sola mentre la guardi |
| 2 | **Bilanciamento** | sposti i contrappesi sull'asse finché il telescopio resta fermo in ogni posizione | dalla deriva residua alla prova di rilascio | il telescopio tende sempre nella stessa direzione, ovunque metti i pesi |
| 3 | **Allineamento polare** | metodo della deriva: osservi una stella nel reticolo, correggi azimuth e altitudine, aspetti, riosservi | 0 a **0,2 arcmin/s** di deriva, 100 a deriva nulla; media su **8 secondi reali** perché non si possa truccare correggendo un istante prima di chiudere | la stella deriva in direzioni impossibili. Poi non è una stella |
| 4 | **Accensione e collegamento PC** | sequenza nell'ordine giusto: montatura, camera di ripresa, camera di guida, software; l'ordine sbagliato non fa riconoscere i dispositivi | nessun punteggio: si passa o si ripete | il software riconosce dispositivi che non hai collegato, o non riconosce quelli collegati |
| 5 | **Plate solving** | scatti una posa breve, il software confronta il campo col catalogo e dice dove stai puntando | dalla precisione del solving | ti dà coordinate che non esistono nel catalogo, o un oggetto che da lì, in quella stagione, non sarebbe visibile |
| 6 | **Targeting** | apri il planetario, filtri per tipo, altezza sull'orizzonte, difficoltà, scegli il soggetto | nessun punteggio proprio: determina il moltiplicatore di valore e se la commessa è soddisfatta | nel planetario compare un oggetto che non è in nessun catalogo. Ha coordinate precise. È visibile stanotte |
| 7 | **Focus** | muovi il focheggiatore finché le stelle sono punti minimi e non dischetti | dalla distanza dal punto di fuoco ottimale sulla curva a V | le stelle non vanno mai a fuoco del tutto. Oppure ci vanno, ma la forma che assumono non è quella di una stella |
| 8 | **Dark e flat** | checklist: tappo, cinque dark; pannello illuminato, cinque flat; nell'ordine, senza saltare passi | dalla completezza e dall'ordine | i dark non sono neri: c'è qualcosa nelle immagini scattate col tappo |
| 9 | **Autoguida** | calibri la guida, avvii il loop, osservi il grafico degli errori: due linee che devono stare basse e stabili | dall'errore RMS medio durante la posa | la guida insegue qualcosa. Ma non è la stella che hai selezionato |
| 10 | **Posa** | imposti esposizione e numero di frame, avvii, la macchina lavora da sola | vedi sotto | i frame acquisiti sono più di quelli impostati. O meno. O la sequenza è finita ma sono passati tre minuti |

> **[ASSUMPTION]** I criteri di punteggio delle fasi 1, 2, 5, 7, 8 e 9 sono proposti qui e
> non ancora implementati: esistono solo le fasi 3, 6 e 10. *Cosa* si misura è deciso; le
> soglie numeriche si tarano quando la fase esiste.

#### La posa, in dettaglio

È la meccanica centrale, l'unica che il giocatore configura davvero, e l'unica che gira in
background.

- **Esposizione per frame** e **numero di frame** sono scelti dal giocatore. Il prodotto è
  la durata: `frame × esposizione`, contata come minuti di notte a rapporto 1:1.
- **Il punteggio premia l'integrazione totale**: **60** al minimo richiesto dal soggetto,
  **100** al doppio del minimo, lineare in mezzo. Un soggetto debole chiede più tempo.
- **La posa di riferimento** è 20 frame × 120 secondi = 40 minuti di gioco ≈ 4,5 minuti
  reali.

**La tensione che ne nasce, e che è la meccanica più interessante del gioco.** Allungare la
posa alza il punteggio **e** allarga la finestra in cui il giocatore è libero di andare in
giro — ma consuma notte, quindi toglie foto. Posa lunga significa qualità e storia; posa
corta significa quantità e lire. **È la scelta di D-006 in miniatura, presa dal giocatore
ogni singola volta, e il gioco non dice mai quale sia quella giusta.**

#### Le due code

**Stacking.** Selezioni i frame buoni, scarti quelli mossi, avvii. Le immagini si sommano e
il segnale emerge dal rumore, lentamente, sullo schermo. È il momento della rivelazione: si
vede per la prima volta cosa si è preso.

*Come si rompe:* quello che emerge dallo stack non corrisponde ai frame singoli. C'è
qualcosa nell'immagine finale che non era in nessuno dei frame separati — che è l'**esatto
inverso** di un artefatto reale, dove un raggio cosmico appare in *un* frame e sparisce
proprio nello stack. Un astrofotografo vero saprebbe che è impossibile, e non avrebbe modo
di dimostrarlo.

**Vendita.** Carichi la foto sul newsgroup o la mandi a riviste e appassionati. Il payout è
**a scaglioni** sul punteggio aggregato, per non punire chi gioca male:

| Punteggio | Lire |
|---|---|
| 0-29 | 5.000 — puoi giocare male e comunque mangi |
| 30-49 | 15.000 |
| 50-74 | 35.000 — soglia «ok» |
| 75-89 | 70.000 — buona notte |
| 90-100 | 150.000 — scatto da rivista |

Ogni committente applica il proprio moltiplicatore e ha le proprie preferenze di soggetto.
Le foto con anomalie hanno un mercato separato e **pagano poco**: vengono derubricate come
fotomontaggi.

#### Le attività del rifugio

Fuori dalle fasi, e disponibili in ogni momento libero: il caffè alla moka, la lampada che
lampeggia da sostituire, la cupola in cui stare a guardare, i forum della BBS, e le cure
dell'osservatorio che si comprano nel terminale.

**Nessuna di queste dà un bonus meccanico.** Non alzano punteggi, non accorciano fasi, non
producono lire. Servono il pilastro 2 — il posto diventa tuo — e la loro ricompensa è
quella. Un bonus meccanico le trasformerebbe in obblighi, e misurerebbe l'obbedienza invece
del piacere.

### Controlli e input

Tastiera e mouse, prima persona. Il gamepad non è un target: il gioco è fatto di schermate
con campi e cursori, e la fedeltà al 1999 vuole quel tipo di interazione.

#### La regola che governa tutto: pochi tasti globali, tutto il resto nel mondo

Il difetto più grave emerso dal prototipo non è una meccanica sbagliata, è che **il gioco
non nomina ciò che offre**. Le stringhe `[T]`, `[B]`, «terminal», «BBS» non compaiono da
nessuna parte a schermo, e il primo giocatore ha chiesto testualmente *«non so dove sia la
moka?»*, *«cupola cosa vuol dire?»*, *«BBS?»*. Due delle quattro attività disponibili
stavano dietro tasti che il gioco non nominava.

La regola che ne discende: **i tasti globali sono cinque e si insegnano; ogni altra azione
è un oggetto nel mondo con cui si interagisce.**

| Tasto | Azione | Perché è globale |
|---|---|---|
| `W A S D` | camminare | movimento |
| `Shift` | correre | movimento |
| `E` | interagire con ciò che si sta guardando | è il verbo unico del gioco |
| `Q` | guardare l'orologio da polso | l'orologio è addosso, non nel mondo |
| `Esc` | menù, impostazioni, uscire da una schermata | sistema |

**Passo 2,5 m/s, corsa 4,5 m/s**, tarati due volte giocando.

**Terminale e BBS smettono di essere tasti globali.** Oggi `terminal_open` è `T` e
`bbs_open` è `B`: due tasti che nessuno ha trovato. Diventano invece **programmi del PC**
nella stanza computer — ci si avvicina, si preme `E`, e si sceglie cosa aprire fra il
software di controllo, il negozio online e la BBS. È più scopribile *e* più vero: nel 1999
si aprivano programmi diversi sullo stesso computer.

Dentro le schermate CRT valgono i controlli della schermata (frecce per muoversi fra i
campi, `Invio` per confermare, `Esc` per uscire), mostrati dalla schermata stessa.

#### I tre livelli di scopribilità

Si sovrappongono di proposito: ognuno copre ciò che gli altri non raggiungono.

**1. Prompt contestuali sugli oggetti.** Guardando un oggetto interattivo da vicino compare
che cosa fa e quale tasto lo attiva. È l'unico dei tre meccanismi che *garantisce* la
scoperta, ed è il motivo per cui c'è: senza, la moka resta invisibile per quanto bene sia
modellata.

- Compaiono solo quando l'oggetto è **inquadrato e a portata**, mai come elenco.
- **Si spengono quando quell'oggetto è stato usato** un paio di volte: alla notte 20 la
  stanza è pulita, perché il giocatore ha imparato. Il prompt è un insegnante, non
  un'etichetta permanente.
- Sono l'**unico elemento non diegetico del gioco**, ed è una deroga consapevole: costa
  meno una deroga che un giocatore che non trova metà del contenuto.

**2. Il foglio di procedura appeso al monitor.** Una checklist delle dieci fasi stampata ad
ago, attaccata di lato al CRT, consultabile in qualsiasi momento. Insegna **la sequenza** —
cosa viene dopo cosa, e perché quell'ordine — che è ciò che i prompt non possono spiegare.
Diegetico al cento per cento e storicamente esatto: è ciò che chiunque avrebbe avuto
appeso lì.

Il foglio ha una seconda vita: **è un oggetto del mondo che invecchia**. Annotazioni a
penna, correzioni, una riga aggiunta a mano. È un canale narrativo già in posizione.

**3. I biglietti della prima notte.** Chi ti ha assunto ti lascia istruzioni scritte: dove
sono le cose, come si accende, cosa si fa. Introducono **una cosa alla volta** invece di
tutte insieme, e insegnano i cinque tasti globali — compreso `Q`, che nessun prompt
contestuale potrebbe mai annunciare, perché l'orologio non è un oggetto da avvicinare.

Coprono la prima notte e poi tacciono, e la loro presenza è anche la prima voce umana del
gioco in un posto dove non c'è nessun altro.

#### Perché non c'è un elenco delle azioni disponibili

Una schermata che elenca cosa si può fare stanotte coprirebbe tutto in un colpo solo, ed è
stata scartata: sposterebbe la scoperta fuori dal mondo. Il giocatore leggerebbe un indice
invece di trovare le cose, e in un gioco il cui pilastro 2 è *il posto diventa tuo*,
conoscere il posto per averlo percorso è metà del punto.

---

## Design specifico Simulation

### Sistemi di simulazione centrali

<!-- DA SCRIVERE -->

### Meccaniche di gestione

<!-- DA SCRIVERE -->

### Costruzione e allestimento

<!-- DA SCRIVERE -->

### Cicli economici e delle risorse

<!-- DA SCRIVERE -->

### Progressione e sblocchi

<!-- DA SCRIVERE -->

### Sandbox e scenario

<!-- DA SCRIVERE -->

---

## Design specifico Adventure

### Meccaniche di esplorazione

<!-- DA SCRIVERE -->

### Integrazione narrativa

<!-- DA SCRIVERE -->

### Sistemi di enigmi

<!-- DA SCRIVERE -->

### Interazione con i personaggi

<!-- DA SCRIVERE -->

### Inventario e oggetti

<!-- DA SCRIVERE -->

### Narrazione ambientale

<!-- DA SCRIVERE -->

---

## Progressione e bilanciamento

### Progressione del giocatore

Tre curve corrono insieme per venti notti, e nessuna delle tre è «un numero che sale».

**1. La competenza — quella vera, del giocatore.** Alla notte 1 non sai in che ordine si
accendono i dispositivi, cosa vuol dire deriva, perché i dark si scattano col tappo. Alla
notte 10 lo sai, e le stesse fasi ti costano meno tempo *senza* che il gioco abbia cambiato
un solo numero. Le fasi 2 e 4 non hanno nemmeno un upgrade: si accorciano perché impari.
Questa curva non è simulata, succede davvero — ed è la ragione per cui il pilastro 1 è il
primo.

**2. L'automazione — il tempo che si compra.** Le lire comprano upgrade, gli upgrade
accorciano le fasi, il tempo liberato apre la notte. Dai 130 minuti di setup della notte 1
ai 19 della notte 20; da 21 a 42 minuti reali di libertà. Ma ogni automazione **fissa la
qualità di quella fase a un valore garantito e non ottimo**: si compra tempo pagando in
punteggio, e chi una fase la sa fare bene può decidere di tenersela.

**3. La storia — l'unica risorsa che si consuma.** Venti notti, e non tornano. Le lire
restano per sempre, il tempo di gioco è illimitato nel free play: la sola cosa scarsa sono
le notti in cui la storia avanza.

#### Lo spazio è aperto da subito; è il contenuto che si scaglona

**Nessuna stanza si sblocca col passare delle notti, e i dintorni si percorrono dalla notte
1.** L'osservatorio è tutto visitabile da subito: cucina, spazio comune, corridoio, cupola,
stanza computer, bagno, prato, sterrata, bosco. L'unica eccezione è fisica e non narrativa —
la stanza dietro la pannellatura, che si apre pagando per smontarla, come una qualsiasi
cura dell'osservatorio.

Quello che cambia notte dopo notte è **cosa ci trovi dentro**, ed è allineato alle quattro
fasi della storia:

| Notti | La storia | Cosa compare nel posto che già conosci |
|---|---|---|
| 1-5 | tutto normale | niente. Impari il lavoro e il luogo |
| 6-10 | qualcosa non torna | artefatti nelle foto; nei dintorni cose piccole — una torcia, un segno, un'impronta; un osservatorio della rete risponde in ritardo |
| 11-15 | la routine si rompe | log che contengono frasi che non ricordi di aver scritto; cartelle vuote che diventano piene; dati che descrivono la tua sessione corrente |
| 16-20 | metanarrazione attiva | log scritti da qualcuno prima di te — ma l'osservatorio è appena aperto — che descrivono eventi futuri; la rete comincia a parlare al giocatore |

**Perché questa è la versione giusta.** L'emozione dichiarata nella Vision è una
*familiarità sbagliata*, e la familiarità non si può sbloccare: va costruita camminandoci.
Un bosco che si apre alla notte 11 è un posto nuovo in cui trovare cose strane. Un bosco
percorso venti volte in cui alla dodicesima c'è un'impronta è tutt'altro.

### Curva di difficoltà

**Il gioco non ha difficoltà crescente, e non ne ha nessuna nel senso classico.** Non si
perde, non si muore, non si fallisce. Quello che cresce è la *quantità di cose che stanno
succedendo insieme*, e quello che cala è l'attrito.

| | Notti 1-5 | Notti 6-10 | Notti 11-15 | Notti 16-20 |
|---|---|---|---|---|
| Attrito procedurale | massimo: tutto a mano, tutto da imparare | cala: primi upgrade | basso | minimo |
| Tempo libero | ~21 min reali | ~28 | ~35 | ~42 |
| Carico narrativo | nessuno | primi segni | denso | massimo |
| Cosa chiede al giocatore | attenzione alla procedura | notare | mettere insieme | decidere |

Le due curve sono deliberatamente opposte: **il lavoro alleggerisce mentre la storia pesa**,
e nel mezzo c'è sempre lo stesso monte-ore. È per questo che l'automazione non può essere
opzionale a livello di design pur restando facoltativa a livello di scelta: chi non compra
niente arriva alla notte 16 con quaranta minuti di procedure e nessun tempo per accorgersi
di ciò che sta succedendo.

> **[NOTE FOR DESIGNER]** Il caso da verificare in playtest è proprio quello: **il giocatore
> che non compra nulla**. D-006 gli dà il diritto di macinare lire senza spenderle, ma se
> arriva alla seconda metà senza tempo libero, la storia gli passa accanto. Va deciso se il
> gioco reagisce in qualche modo (le commesse che si semplificano, un'automazione minima
> regalata dalla trama) o se è una strada legittima che porta a un'esperienza più povera —
> il che sarebbe comunque coerente con «offre e non obbliga mai».

### Economia e risorse

#### La valuta e la sua scala

Tutto è in lire. **I prezzi di `economia.md §3` sono confermati come rapporto e moltiplicati
per dieci in valore assoluto**: il bilanciamento resta identico, ma le cifre diventano
credibili per il 1999 su entrambi i lati del banco.

**Payout per foto, a scaglioni sul punteggio aggregato:**

| Punteggio | Lire |
|---|---|
| 0-29 | 5.000 — puoi giocare male e comunque mangi |
| 30-49 | 15.000 |
| 50-74 | 35.000 — soglia «ok» |
| 75-89 | 70.000 — buona notte |
| 90-100 | 150.000 — scatto da rivista |

**Albero degli upgrade** (uno per fase, dieci in tutto):

| Upgrade | Fase | Effetto | Prezzo |
|---|---|---|---|
| Livella motorizzata | 1 | automatica, sparisce dalla routine | 250.000 |
| Contrappesi calibrati | 2 | tolleranza più ampia | 120.000 |
| Software di polar align | 3 | da 60 a 10 minuti, qualità fissa | 300.000 |
| Sequencer scripts | 4 | boot in un click | 80.000 |
| Plate-solver locale | 5 | più veloce, niente floppy | 200.000 |
| Catalogo esteso | 6 | più target e più commesse disponibili | 180.000 |
| Maschera di Bahtinov | 7 | picco di fuoco più netto | 50.000 |
| Libreria dark + flat panel | 8 | niente riacquisizione ogni notte | 150.000 |
| Autoguider OAG | 9 | errore RMS più basso | 350.000 |
| Camera CCD raffreddata | 10 | alza il tetto di qualità | 600.000 |
| | | **Totale albero** | **2.280.000** |

**La curva regge, ed è questo che rende la scelta reale.** Venti notti a due foto: giocando
in modo ordinario si incassano circa **1.400.000 lire**, giocando bene circa **2.800.000**.
Cioè si compra fra il 60% e il 100% dell'albero — **e nel frattempo servono soldi anche per
il resto**. Nessuno compra tutto senza rinunciare a qualcosa.

#### Le altre voci di spesa

| Categoria | Esempi | Ordine di prezzo | Cosa dà |
|---|---|---|---|
| **Comfort personale** | moka, stufetta, mangiacassette, coperta pesante | 30.000 - 150.000 | **nessun bonus meccanico**: cambia come il posto si vede, si sente, si abita |
| **Cura dell'osservatorio** | lampada, ridipintura, lubrificare la cupola, bagno, recinzione | 20.000 - 150.000 | come sopra, più qualche nota di lore che affiora |
| **Aprire la stanza dietro la pannellatura** | — | 250.000 | accesso a una stanza, e un lore drop importante |
| **Informazione** | catalogo NGC su CD-ROM, abbonamento a *Coelum*, abbonamento BBS | 30.000 - 180.000 | più target, più commesse, più cose da leggere |

**Regola invariante sul comfort e sulla cura: non danno mai bonus meccanici.** Non alzano
punteggi, non accorciano fasi, non producono lire. `economia.md §5` assegnava effetti
numerici (moka +5% sul focus, coperta +5% sotto i 10°) e **è superato**: un caffè che
conviene farsi smette di essere un caffè e diventa un compito. Il pilastro 2 esiste per
misurare se ti piace stare lì, e un bonus renderebbe la misura impossibile.

#### Le tre risorse, in ordine di scarsità

1. **Le notti di storia** — venti, non rinnovabili. La sola risorsa davvero scarsa.
2. **I minuti dentro la notte** — 540, uguali ogni notte. Si comprano con gli upgrade e si
   spendono in foto o in esposizione.
3. **Le lire** — accumulabili senza limite, spendibili per sempre. La meno scarsa delle tre,
   ed è questo il punto: **la valuta del gioco non è la sua risorsa critica**.

---

## Struttura del level design

### Tipi di livello

Astrochill **non ha livelli**. Ha un luogo solo, percorribile per intero dalla prima notte
(D-020), e due spazi di natura diversa che il giocatore attraversa di continuo:

**1. Lo spazio fisico** — l'osservatorio e il suo prato recintato, in prima persona. È dove
si cammina, si abita, ci si accorge delle cose. Un ambiente continuo: nessun caricamento,
nessuna soglia, nessuna zona che si sblocca.

**2. Lo spazio delle interfacce** — le schermate CRT, il terminale, la BBS. È dove si
lavora. Vive dentro il primo, su un monitor che sta in una stanza, e ci si entra
avvicinandosi e premendo `E`.

Il gioco è il passaggio continuo fra i due, ed è per questo che la distanza fra il monitor
e tutto il resto è il numero più importante di questa sezione.

### La pianta

Edificio a **L**, un piano, ingombro **19 × 9,5 m**, superficie coperta **~164 m²**, di cui
**~150 m² calpestabili** al netto dei muri. Due corpi: quello ovest con la cupola, e quello
est — arretrato di 1,5 m — con la parte pubblica.

> **Disegno in scala: [`pianta-osservatorio.png`](pianta-osservatorio.png)**, nella stessa
> cartella. Riporta stanze, superfici, quote, aperture e i tempi di percorrenza.
>
> **Modello Blender: [`assets/models/osservatorio.glb`](../../../../assets/models/osservatorio.glb)**,
> costruito dalla stessa geometria da
> [`osservatorio_blender.py`](../../../../tools/osservatorio_blender.py), con la cupola di
> [`cupola_blender.py`](../../../../tools/cupola_blender.py). Viste di controllo:
> [`osservatorio-aereo.png`](osservatorio-aereo.png) e
> [`osservatorio-facciata.png`](osservatorio-facciata.png).
>
> **Blockout navigabile: [`world/blockout.tscn`](../../../../world/blockout.tscn)**, generato
> dalla pianta. Si apre con
> `./Godot_v4.7.2-stable_win64.exe --path . res://world/blockout.tscn` e si percorre a
> piedi. È lo strumento con cui la scala è stata decisa, e va rigenerato quando la pianta
> cambia.
>
> **Fonte unica: [`tools/geometria.py`](../../../../tools/geometria.py)**. Muri, aperture e
> quote stanno lì una volta sola; [`pianta2.py`](../../../../tools/pianta2.py) ne disegna la
> pianta, [`gen_blockout.py`](../../../../tools/gen_blockout.py) ne genera il blockout
> navigabile e [`osservatorio_blender.py`](../../../../tools/osservatorio_blender.py) ne
> costruisce il modello in Blender. Erano due elenchi separati, ed
> erano già divergenti: il disegno mostrava una porta su un muro che nel blockout non
> esisteva più.
>
> **Le superfici qui sotto non sono scritte a mano**: sono misurate su quella geometria,
> riempiendo le stanze a partire dai muri. Se la pianta cambia e la tabella no, la tabella è
> sbagliata per costruzione.

| Ambiente | m² netti | Perché è dov'è |
|---|---|---|
| **Sala del telescopio** | 32 | corpo ovest. Cupola ø 5 m, montatura **fissa su pilastro** nel pavimento, passerella anulare intorno |
| **Controllo PC** | 12 | confina con la sala del telescopio, e ci si affaccia con una **vetrata di 2,80 m**. Porta non ce n'è: si passa dal corridoio (D-045). È la stanza dove si passa la maggior parte del gioco, e la sola arredata |
| **Corridoio** | 5,4 | lo snodo: collega controllo PC, bagno, spazio divulgazione e — con un **varco senza porta** — la sala del telescopio, di cui è l'**unico** accesso |
| **Bagno** | 8,8 | sul corridoio |
| **Magazzino** | 3,8 | sul corridoio, con l'angolo cottura di fatto |
| **Disimpegno** | 4,9 | testata ovest |
| **Stanza segreta (ovest)** | 3,4 | fra disimpegno e magazzino, dietro una pannellatura: **1,20 m di luce**, allargata rubando 30 cm al disimpegno e 25 al magazzino |
| **Cucina** | 12 | corpo est, in alto: 4,95 × 2,40, cioè un corridoio, quindi **cucina in linea** su un lato solo e tavolino nell'angolo (D-048). La **libreria di astronomia** è addossata al suo muro sud, dal lato della sala. **Finestra sopra il lavello** sul muro nord (D-050) |
| **Stanza segreta (est)** | 3,2 | fra la cucina e lo spazio divulgazione, dietro una pannellatura: 1,00 × 3,00 m |
| **Spazio divulgazione** | 65 | il grande volume pubblico, a elle. **Davanti**, sul muro della cucina, la **libreria di astronomia**; poi le **teche di vetro con i meteoriti** — due sul muro est e la **bacheca** lunga sul muro sud, i pezzi in fila lungo il vetro col cartellino davanti. Il centro della sala resta vuoto. **Nella testata est la sala proiezioni**: schermo sul muro nord, tavolo davanti, due file di sedie mai usate, proiettore a diapositive su carrello. Il **distributore snack** alla giunzione fra i due corpi. Ci si entra dalla porta d'ingresso (D-052) |

#### Le quattro cose che questa pianta decide

**1. Il monitor e il telescopio sono a cinque metri, e in mezzo c'è del vetro.** La
consolle sta **sotto la vetrata**, non contro un altro muro: chi lavora siede rivolto alla
sala del telescopio, e alzando gli occhi dal monitor lo vede. È l'unico oggetto del gioco
che può muoversi da solo, ed è permanentemente nel campo visivo di chi sta facendo altro.
Non serve che il gioco lo sottolinei mai — **e nessuna porta accorcia questo**, perché il
percorso più battuto del gioco non si fa con i piedi.

**2. La sala del telescopio è un fondo cieco, con un solo modo di entrarci e di uscirne.**
Il varco sul corridoio (D-034), largo e senza porta. Fino a D-045 c'era anche la porta
diretta dal controllo PC, e questo paragrafo diceva l'opposto: *un anello si percorre in
due sensi*, quindi salire alla passerella significava dare le spalle a **uno dei due**
accessi. Ora se ne danno le spalle all'unico. **È un cambiamento di pilastro 3, non di
pianta**, e va tenuto d'occhio quando si proverà la salita al buio: può funzionare meglio
di prima o diventare gratuito, e lo dirà il gioco, non il documento.

**3. Per il caffè si attraversa la sala aperta al pubblico.** La cucina non comunica col
controllo PC: ci si arriva solo passando per lo spazio divulgazione, davanti alla bacheca
dei meteoriti e alle sedie che nessuno ha mai usato. **Il gesto più domestico del gioco passa
ogni volta per lo spazio più impersonale.**

**4. Le due stanze segrete stanno in due mondi diversi.** Quella ovest è fra le stanze di
servizio, quella est nella parte pubblica. Se sono due scoperte in due momenti diversi delle
venti notti, la seconda pesa di più: arriva quando il giocatore credeva di aver già trovato
tutto.

#### Il volume in alzato — e la regola che lo governa

**Ci sono due famiglie di misure in questo edificio, e si comportano in modo opposto.**

- Le misure **architettoniche** — lunghezze, larghezze, superfici — sono una scelta di
  design e si scalano in blocco.
- Le misure **antropometriche** — porte, soffitti, davanzali, gradini, l'auto — sono fissate
  dal corpo umano e **non si scalano mai**. Il giocatore è alto 1,80 m a qualunque scala
  stia l'edificio.

Confondere le due produce un modellino: quando l'edificio è stato dimezzato, dimezzare anche
le porte le ha ridotte a 70 cm.

| Elemento | Quota |
|---|---|
| Soffitto interno | 3,00 m |
| Solaio | 3,00-3,20 m (l'intradosso è il soffitto) |
| Tetto | 3,20-3,38 m, **tutte le falde complanari** |
| Cupola | ø 5,00 m, poggia sull'**estradosso del tetto**, colmo a **5,88 m** |
| Sala del telescopio | alta 5,88 al colmo — la cupola **è** il suo soffitto |
| Fenditura di osservazione | 1,60 m, dalla base al colmo; si apre mentre la cupola ruota |
| Passerella anulare | quota 0,90 m, larghezza 0,85, raggio 1,40 — **fa tutto il giro**, così l'oculare è raggiungibile ovunque il telescopio punti |
| Rampa di risalita | dislivello 0,90 m su 1,60 di sviluppo, **pendenza 29°** |
| — la sua collisione | un piano inclinato, separato dalla mesh: il modello avrà cinque gradini veri da 18 cm |
| Porta d'ingresso | **1,20 m di luce, un'anta sola**, con **maniglione antipanico all'interno** |
| Porte interne | 0,90-1,60 m (il magazzino ha una porta da ripostiglio) |
| Verso di apertura | dichiarato porta per porta. L'**ingresso si apre verso il prato**: è un edificio pubblico, e una via di fuga non si apre verso l'interno |
| Vetrata interna PC / cupola | 1,50 m |
| Finestre | davanzale 1,00, altezza 1,40 |

**La cupola poggia sul tetto e non ci affonda dentro**: il tetto piano si interrompe sul
perimetro dell'anello, e la sala del telescopio è coperta **dal tetto per la parte fuori dal
cerchio e dalla calotta per il resto**. La quota d'appoggio è l'estradosso del tetto (3,38),
non la gronda: finché la sala non aveva copertura i due valori coincidevano, e dandogliela
la cupola è rimasta 38 cm dentro il tetto — invisibile da dentro, evidente in assonometria. Non è una precisazione oziosa: una
calotta di 5 m di diametro copre 20 m² di una stanza che ne misura 34, e finché quel tetto
non è esistito la sala è rimasta **aperta al cielo per 14 m²** senza che si vedesse da
dentro. È la stessa regola che ha già richiesto due correzioni in codice.

#### Le distanze, che si pagano in pazienza e non in budget

Passo **2,5 m/s**, corsa **4,5 m/s**, campo visivo **55° verticali** (≈ 88 orizzontali; il
default dell'engine è 75, che deforma le stanze e falsa il giudizio sulle dimensioni).

Un dato controintuitivo governa questa sezione: **una camminata di 20 metri costa 8 secondi
reali ma solo 1,2 minuti di gioco su 540.** Le distanze non incidono sul budget della notte
in modo significativo — si pagano nella pazienza di chi gioca, moltiplicate per quante volte
quel percorso si ripete.

| Percorso | Distanza a piedi | Tempo | In venti notti |
|---|---|---|---|
| Monitor → telescopio | ~5 m | 2 s | il percorso più frequente in assoluto |
| Monitor → bagno | ~6,5 m | 3 s | |
| Monitor → moka | ~8 m | 3 s | ~6 minuti reali di sola camminata, a tre caffè per notte |
| Monitor → ingresso | ~9 m | 4 s | |
| Ingresso → auto | ~20,5 m | 8 s | due volte per notte: arrivo e partenza |

**Nessun percorso ricorrente supera i 10 secondi di sola andata** — il criterio di
dimensionamento di D-022 sopravvive al dimezzamento, con ampio margine.

#### Gli elementi dell'esterno

| Elemento | Dove | Perché esiste |
|---|---|---|
| **Contatore della corrente** | in facciata, lato sud | governa PC, monitor, montatura e luci. Nel 1999 si riarma a mano, **e per farlo bisogna uscire al buio**. Si aggancia alla fase 4, ed è un canale già pronto per il pilastro 3: la corrente che salta durante una posa è la cosa più banale e più credibile del mondo |
| **Rampa d'accesso** | davanti alla porta | edificio pubblico a norma che nessuno ha mai visitato: dice l'isolamento senza raccontarlo, e costa un asset |
| **Piazzola dell'auto** | dentro il recinto, oltre il cancello | ~20 m dall'ingresso. Il turno si apre e si chiude attraversando il prato al buio, quaranta volte in venti notti |
| **Cancello** | dove arriva la sterrata | si apre dalla macchina all'arrivo. Che una notte sia già aperto è una possibilità che la disposizione lascia lì, gratis |
| **Serbatoio** | lato ovest, dentro il recinto | c'è nella foto aerea del sito reale |

**Il prato** è recintato e irregolare, con la sterrata che sale da valle; **bosco a est e a
sud**, campi a ovest. Il bosco è percorribile dalla prima notte e ha un limite dichiarato:
non ci si allontana mai davvero dall'edificio.

> **[NOTE FOR DESIGNER] — una questione aperta sulla pianta.**
>
> **Il segnale di fine posa e il bosco.** Il segnale esce dalla finestra della stanza
> controllo PC, che affaccia a nord, mentre il bosco sta a est e a sud. O si sposta la
> finestra, o si ruota l'edificio, o serve un secondo vettore. Va deciso guardando dal
> prato, non a tavolino.

### Progressione dei livelli

**Non c'è.** Nessuna stanza si sblocca col tempo, nessuna area è chiusa dalla trama, i
dintorni si percorrono dalla notte 1 (D-020). Le sole aperture chiuse sono fisiche: le
pannellature delle due stanze segrete, che si smontano pagando.

Quello che progredisce è **cosa si trova in un posto già noto**: niente nelle notti 1-5;
oggetti piccoli nei dintorni dalla 6; log e cartelle che cambiano dalla 11; metanarrazione
attiva dalla 16.

**È il motivo per cui l'osservatorio è aperto per intero fin dall'inizio.** Un posto che si
sblocca a pezzi produce curiosità; un posto percorso venti volte produce **familiarità**, che
è l'unica cosa che si può poi tradire. La pianta serve quel tradimento, non l'esplorazione.

## Direzione artistica e audio

### Stile artistico

**3D low-poly, estetica PS1.** Geometrie semplici, texture piccole con filtering nearest,
vertex snapping, nebbia a chiudere le distanze. Non è un ripiego travestito da scelta: il
gioco è ambientato nel 1999 e imita la grafica del periodo che racconta, il che lavora a
favore della metanarrazione. È anche la fedeltà 3D più abbordabile per chi non è
modellatore.

**Le interfacce sono l'arte.** Ogni schermo diegetico è un nodo `Control` renderizzato in un
`SubViewport` e applicato come texture al monitor nel mondo, con shader per curvatura,
scanline e aberrazione. Costo in asset: zero. Ed è dove vive il gameplay.

**Il CRT va rifatto.** Il monitor attuale è un segnaposto e sarà rimodellato. La sua
**risoluzione è un parametro di design con conseguenze dirette sul contenuto**, non una
scelta estetica: a 256×192 la descrizione di M42 ha già costretto a rifare un layout una
volta. Ogni schermata di ogni fase, il terminale e la BBS sono vincolati da quel numero, e
il testo scrivibile per schermata ne discende.

> **[NOTE FOR DESIGNER]** La risoluzione target del CRT va fissata **con il rifacimento del
> monitor, prima** di scrivere le sette fasi mancanti — non dopo. Sette schermate progettate
> su una risoluzione e poi riportate su un'altra sono sette layout da rifare.

**Asset provvisori.** La stanza e i materiali attuali sono segnaposto in attesa di un pack
di texture: non vanno rifiniti. Restano da modellare a mano **telescopio e montatura**, che
il giocatore guarda da vicino tutta la notte e sono l'unico soggetto dove il low-poly non
può cavarsela con il kit-bashing.

**Il volume di asset è la ragione per cui il luogo è uno solo.** Un edificio a L con cupola
bianca, dentro un prato recintato in cima a una collina, sterrata e bosco intorno. Nessun
NPC da animare: il protagonista è sempre solo.

### Audio e musica

**Il silenzio è un elemento attivo, non l'assenza di audio.** I suoni dell'osservatorio —
il cigolio della cupola, il modem, il vento, i grilli, la ventola del PC — diventano
familiari a forza di notti. Poi uno non torna più, e la sua assenza è un evento narrativo
che non richiede di mostrare niente.

Questo lega l'audio al pilastro 2 e al pilastro 3 insieme: il posto diventa tuo anche per
come suona, ed è per questo che accorgersi di un suono mancante è possibile.

**Pipeline a spesa zero:** Suno (piano gratuito) per gli ambient, Freesound per modem,
grilli, vento e cigolio, Incompetech come fallback.

> **[NOTE FOR DESIGNER]** Un accoppiamento già segnalato in `economia.md §6` e ancora
> irrisolto: lubrificare la cupola **elimina il cigolio**, che è anche un elemento narrativo.
> Migliorare il rifugio può quindi cancellare materiale del pilastro 3. Va deciso se le cure
> hanno un costo narrativo dichiarato (e quindi diventano scelte vere) o se il suono cambia
> invece di sparire.

---

## Specifiche tecniche

Questa sezione dice **su cosa** gira e **quanto** deve rendere. Come i sistemi sono
costruiti è competenza del documento di architettura.

### Requisiti di prestazione

| Obiettivo | Valore | Come si misura |
|---|---|---|
| Frame rate | 60 FPS sostenuti | su una notte intera, non su uno scorcio: 60 minuti reali dall'arrivo all'alba |
| Frame rate minimo accettabile | mai sotto 30 FPS | nei momenti peggiori: esterno con bosco a vista, cupola aperta |
| Tempo di caricamento | sotto 10 s dall'avvio al gioco | da eseguibile freddo |
| Memoria | entro 2 GB | l'osservatorio è una scena sola e ci resta per tutta la notte |

> **[ASSUMPTION]** I valori qui sopra sono target ragionevoli per un low-poly su renderer
> Compatibility, ma non sono ancora stati misurati su una macchina di riferimento
> dichiarata. Va scelta la macchina minima supportata — e da lì i numeri diventano
> verificabili invece che plausibili.

### Dettagli specifici di piattaforma

- **Piattaforma unica: PC Windows.** Nessun target console, nessuna certificazione da
  rispettare.
- **Engine: Godot 4.7.2, renderer Compatibility.** La scelta del renderer è vincolante per
  l'estetica (nearest filtering, vertex snapping) ed è già in produzione.
- **Input: tastiera e mouse.** Il gamepad non è un target: il gioco è fatto di schermi con
  campi e cursori, e la fedeltà al 1999 vuole quel tipo di interazione.
- **Distribuzione: Steam.**

### Lingue e localizzazione

**Il gioco esce in italiano e in inglese, selezionabili dalle impostazioni.** Tutto ciò che
il giocatore deve leggere per giocare e per capire segue quella scelta. Fa eccezione un solo
livello, e per una ragione che non è di traduzione.

| Livello | Cosa comprende | Comportamento |
|---|---|---|
| **1 — La voce del gioco** | narrativa, log, lettere, giornali locali, descrizioni dei target, messaggi dei committenti, thread della BBS, negozio nel terminale, menu e impostazioni | **localizzato IT/EN** |
| **2 — Le interfacce degli strumenti** | le dieci fasi, i campi delle schermate CRT, i messaggi di stato della strumentazione | **localizzato IT/EN**, con il gergo tecnico invariato (vedi sotto) |
| **3 — Gli oggetti del mondo** | poster, insegne, targhe, etichette, avvisi appesi, la bacheca, le copertine delle riviste | **sempre in italiano**, dentro le texture |

**Perché anche gli strumenti si traducono.** Le schermate CRT non sono atmosfera: sono
**l'interfaccia funzionale del gioco**. Un giocatore che non legge l'inglese non perde
colore — non può giocare. E un'impostazione su «Italiano» che lascia in inglese metà di ciò
che si deve leggere è un'impostazione rotta.

**Come si traducono: alla maniera di un astrofilo italiano del 1999.** Non è una traduzione
d'ufficio. Il gergo tecnico che si usava in inglese *dentro* la frase italiana resta in
inglese, perché è così che si parlava davvero: **dark, flat, stacking, seeing, guiding,
plate solving, tracking**. Un italiano diceva «ho fatto i dark» e «lo stacking è venuto
male», non «i fotogrammi di buio».

Esempi di registro corretto:

| Inglese | Italiano da usare | Italiano da evitare |
|---|---|---|
| `EXPOSURE` | `ESPOSIZIONE` | — |
| `FRAMES` | `POSE` | `FOTOGRAMMI` |
| `TARGET` | `OGGETTO` | `BERSAGLIO` |
| `DARK FRAMES` | `DARK` | `FOTOGRAMMI DI BUIO` |
| `AUTOGUIDING` | `AUTOGUIDA` | — |
| `PLATE SOLVING` | `PLATE SOLVING` | `RISOLUZIONE DELLA LASTRA` |
| `STACKING` | `STACKING` | `IMPILAMENTO` |

Tradotto così, la schermata suona naturale a un italiano **e resta tecnicamente vera**: è
il pilastro 1 che sopravvive al cambio di lingua invece di essere sacrificato.

**Perché il livello 3 non si traduce.** Un poster appeso al muro di un osservatorio
marchigiano è un oggetto fisico di quel luogo, come un cartello stradale. Tradurlo
significherebbe che il mondo cambia lingua a seconda di chi guarda. In più sono testi
dipinti dentro le texture: localizzarli vorrebbe dire rifare gli asset. Un giocatore
anglofono vedrà poster in italiano, ed è corretto così — sta lavorando in Italia.

**Conseguenze operative.**

- **Nessun testo di livello 1 o 2 può essere una stringa fissa nel codice.** Oggi non esiste
  alcuna infrastruttura di localizzazione — niente `internationalization/locale` in
  `project.godot`, nessun file di traduzione, nessun testo che passi da una chiave. Ogni
  testo scritto da qui in avanti senza quell'infrastruttura è debito moltiplicato per due
  lingue. Il *come* è competenza dell'architettura; il requisito è questo.
- **Le schermate già scritte sono da rifare in questo senso.** `imaging`, `targeting` e
  `polar` hanno oggi i propri campi come stringhe inglesi fisse nel codice.
- **Il vincolo sul CRT si aggrava, e va risolto prima delle sette fasi mancanti.**
  L'italiano occupa il 15-20% di caratteri in più dell'inglese, e sulle etichette dei campi
  la differenza è brutale: `EXPOSURE` sono 8 caratteri, `ESPOSIZIONE` sono 11. Su uno
  schermo a pixel fissi e a larghezza di colonna fissa, **ogni schermata va progettata sulla
  stringa più lunga fra le due lingue**, e verificata in entrambe. Sommato a D-011: la
  risoluzione del CRT non è più solo una scelta di leggibilità, è ciò che decide se le
  etichette italiane ci stanno.

### Requisiti degli asset

**Il grosso del gioco non è modellato, è disegnato in `Control`.** Dieci fasi, il terminale,
la BBS: ogni schermata è UI su `SubViewport`. È il motivo per cui una persona sola può
finire questo gioco.

| Categoria | Volume | Provenienza |
|---|---|---|
| Interfacce CRT | 10 fasi + terminale + BBS + stack | costruite a mano, costo asset zero |
| Edificio | ingresso, cucina, spazio comune, corridoio, cupola, stanza computer, bagno, stanza segreta | kit-bashing modulare + CC0 |
| Esterno | prato recintato, sterrata, bosco perimetrale | CC0 (Kenney, Quaternius, Poly Pizza) |
| Strumentazione | telescopio, montatura, camera CCD | **modellati a mano**, si guardano da vicino |
| Texture | pack in arrivo | i materiali attuali sono segnaposto, da non rifinire |
| Audio | ambient, modem, grilli, vento, cigolio, ventola | Suno + Freesound + Incompetech |

---

## Epiche di sviluppo

### Struttura delle epiche

<!-- DA SCRIVERE — dettaglio in epics.md -->

---

## Metriche di successo

### Metriche tecniche

<!-- DA SCRIVERE -->

### Metriche di gameplay

<!-- DA SCRIVERE -->

---

## Fuori ambito

Quello che segue è **deliberatamente escluso**, non dimenticato. Nulla di ciò che è stato
esplicitamente incluso finora è stato tolto da qui.

### Escluso da v1.0

| Cosa | Perché |
|---|---|
| Console e piattaforme diverse da PC Windows | target unico dichiarato; nessuna certificazione da rispettare |
| Supporto gamepad | il gioco è fatto di schermi con campi e cursori; la fedeltà al 1999 vuole tastiera e mouse |
| Multiplayer di qualsiasi forma | il protagonista è sempre solo, ed è il punto |
| NPC visibili o animati | non esistono personaggi in scena: tutta la presenza umana passa da testo, terminale e BBS |
| Combattimento, morte, fallimento, game over | vietati dal pilastro 2 |
| Minaccia fisica o inseguimento | vietati dal pilastro 3: l'orrore è informativo, mai spaziale |
| Esplorazione oltre il perimetro dell'osservatorio | prato, sterrata e bosco sono il limite; non ci si allontana mai davvero |
| Generazione procedurale di contenuto | ogni notte è autoriale |
| Creature collecting, tono cute | presi da Creature Kitchen il posizionamento e la lezione sui tag, non il registro |

### Rinviato a dopo il lancio

Niente è oggi assegnato a questa categoria. **Le venti notti, il free play, la
metanarrazione e i finali sono in v1.0**: sono il gioco, non contenuto aggiuntivo.

**La lingua non è fuori ambito:** il gioco esce in italiano e inglese, selezionabili dalle
impostazioni. La regola completa sta in *Specifiche tecniche → Lingue e localizzazione*.

---

## Assunzioni e dipendenze

### Assunzioni

- **[ASSUMPTION]** I target di prestazione dichiarati sono plausibili per un low-poly su
  renderer Compatibility, ma **non sono stati misurati** e non esiste ancora una macchina
  minima supportata dichiarata.
- **[ASSUMPTION]** Venti ore di contenuto (D-007) sono producibili da una persona sola nei
  tempi del progetto. È l'assunzione di produzione più pesante del documento: la durata
  della notte è stata quadruplicata rispetto al prototipo, e il fabbisogno di contenuto con
  essa.
- **[ASSUMPTION]** Gli asset CC0 (Kenney, Quaternius, Poly Pizza) coprono edificio ed
  esterno con il solo kit-bashing, lasciando a modellazione manuale solo telescopio,
  montatura e camera CCD.
- **Il pilastro 3 non è dimostrato.** Il seam esiste (`PhaseTruthSource` più l'iniettore
  `F9`), zero rotture sono implementate. Tutta la seconda metà del gioco poggia su un
  pilastro che il prototipo non ha ancora messo alla prova.

### Dipendenze

- **Pack di texture in arrivo.** I materiali e la stanza attuali sono segnaposto e non vanno
  rifiniti.
- **Rifacimento del monitor CRT** (D-011), da cui dipende la risoluzione target — che va
  fissata **prima** di scrivere le sette fasi mancanti.
- **Amico artista**, potenzialmente disponibile: da coinvolgere solo davanti a un prototipo
  giocabile, con la forma dell'accordo definita prima di iniziare.
- **Steam Direct**: unica voce di cassa certa insieme all'eventuale accordo con l'artista.

> **[NOTE FOR DESIGNER] — verificare le licenze audio prima di dipenderne.**
> La pipeline audio prevista è Suno nel piano gratuito, Freesound e Incompetech. Per un
> gioco **venduto**, l'uso commerciale va verificato caso per caso: i piani gratuiti dei
> generatori musicali storicamente **non** concedono diritti commerciali, e su Freesound la
> licenza varia da file a file (alcune richiedono attribuzione, altre vietano l'uso
> commerciale). Non è un dettaglio amministrativo: è una dipendenza che, se cade, richiede
> di rifare tutta la colonna sonora a gioco finito. Da verificare sui termini correnti prima
> che l'audio entri in produzione.
