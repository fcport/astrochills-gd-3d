# Astrochill — Design Document
> Bozza di lavoro — versione 0.2 — aggiornata 2026-08-21

> **Decisioni prese in questa revisione**
> - **Titolo: Astrochill.** Non più nome di lavorazione — è il titolo.
> - Il gioco è **3D**, non pixel art. §12 e §14 riscritte di conseguenza.
> - Le fasi della notte sono **10 + 2 code**, allineate a [minigiochi.md](minigiochi.md). §6 riscritta.
> - Sui **prezzi degli upgrade** fa fede [economia.md](economia.md), non minigiochi.md. Vedi §7.
> - **Calibrazione economica rinviata di proposito.** Le divergenze tra i documenti sui numeri sono note, tracciate e non bloccanti. Vedi §8.
>
> Documenti sorella in questa cartella: [riassunto-creativo.md](riassunto-creativo.md),
> [minigiochi.md](minigiochi.md), [economia.md](economia.md), piante in [osservatorio/](osservatorio/).

---

## 1. Concept e tono

Un giovane uomo di Rimini, rimasto senza lavoro dopo un cambio di gestione dell'albergo in cui lavorava come receptionist, accetta un impiego insolito: gestore notturno di un osservatorio astronomico appena inaugurato sull'Appennino marchigiano, a Montegrimano (PU). Siamo nel 1999.

Il gioco è ambientato in **20 notti**. Ogni notte dura circa **un'ora di gioco**. Il giocatore segue una routine di lavoro che cresce in complessità, e che gradualmente si rompe in modo sottile, poi sempre meno sottile.

Il tono è **orrore cosmico + psicologico**, con elementi di **metanarrazione**. Non c'è un mostro. C'è qualcosa che non torna, e non saprai mai con certezza se è là fuori o dentro la tua testa.

---

## 2. Personaggio

**Nome:** scelto dal giocatore all'inizio.

**Background:** cresciuto a Rimini, ha lavorato come receptionist in un albergo sulla riviera per anni. Il nuovo proprietario ha portato il suo staff — lui si è trovato fuori. Nessun dramma, nessun colpevole. La vita che succede.

Ha abitudini notturne consolidate. Sa compilare registri, gestire imprevisti con calma, tenere un'agenda. Non è un astronomo — impara il lavoro sul campo, insieme al giocatore.

Si trasferisce a Montegrimano con poca roba. Affitta un posto vicino all'osservatorio. Porta con sé la malinconia quieta di chi ha visto un mondo bello andare in pezzi per ragioni che non lo riguardavano.

**Perché l'astronomia?** Non era appassionato prima. Lo diventa. E questo rende la scoperta — e la corruzione di quella scoperta — più personale.

---

## 3. Ambientazione

**Osservatorio Astronomico Monte San Lorenzo**, Montegrimano Terme, Provincia di Pesaro e Urbino.

Appena inaugurato. Il protagonista è uno dei primissimi gestori — non c'è storia del posto ancora. I log che tiene sono i **primi log**. Quando le cose iniziano ad andare storte, non ha precedenti a cui fare riferimento.

**Anno:** 1999. Internet esiste ma è primitivo. Connessione a 56k che occupa la linea telefonica. I newsgroup e le mailing list sono il modo in cui gli appassionati di astronomia si parlano online. Le interfacce software sono in inglese, tradotte malamente. I giornali, le lettere, i dialoghi sono in italiano.

**Il paesaggio:** Appennino marchigiano. Buio vero. Silenzio vero. In inverno fa freddo. D'estate ci sono i grilli. Dall'altra parte della collina c'è un paese di poche centinaia di persone.

### 3.1 Pianta dell'osservatorio

L'osservatorio è **un unico edificio**, disegnato su due fogli che rappresentano due metà della stessa pianta. Sorgenti in [osservatorio/](osservatorio/):

| File | Cos'è |
|---|---|
| `oss_1_1.png` | pianta della metà ingresso/pubblico |
| `oss_2_2.png` | pianta della metà cupola/lavoro — `oss_2_2` è anche l'id della stanza computer nei doc di economia |
| `oss_maps.png` | **foto aerea reale del sito**, non una pianta |

`oss_maps.png` merita una nota a sé: è uno scatto satellitare dell'osservatorio vero. Si vede l'edificio scuro a L con la **cupola bianca emisferica** innestata su un angolo, la **recinzione perimetrale** che chiude un prato irregolare, la **strada sterrata** che sale da sinistra, un piccolo manufatto bianco (serbatoio?) sul lato, e tutto intorno bosco e campi. È la reference primaria per costruire l'esterno in 3D e per capire dove può svolgersi l'esplorazione notturna.

Le due metà sono collegate internamente da un passaggio etichettato *"accesso al telescopio"*.

**Metà ingresso/pubblico** (`oss_1_1.png`) — dove il giocatore arriva dall'esterno:
- **Ingresso** — porta di accesso dall'esterno, in basso nella pianta. È il punto in cui atterra il giocatore ogni notte dopo aver attraversato l'esterno.
- **Cucina** — angolo cottura, frigorifero, tavolo. Caffè notturni. Cibo del protagonista. Qui sta il barattolo delle donazioni (economia.md §9).
- **Stanza segreta** — stretta, adiacente alla cucina, etichettata anche su questo foglio.
- **Grande spazio comune** — l'ala destra della pianta è un unico volume ampio e **non etichettato**. Candidato naturale per la sala proiezione/divulgazione, ma sul disegno non ha ancora un nome.
- **Accesso al telescopio** — corridoio sulla sinistra, varco verso l'altra metà.

> ⚠️ La versione precedente di questa sezione descriveva una *sala proiezione* con proiettore e sedute in file (annotazione *"equipped scuro non luminoso"*) e delle *zone tecniche/servizio* con backup e cassettini. **Nella pianta non compaiono.** Vanno trattate come idee non ancora disegnate, non come elementi già esistenti.

**Metà cupola/lavoro** (`oss_2_2.png`) — il cuore operativo del gioco:
- **Cupola del telescopio** — telescopio fisico, montatura, oculare. Apertura/rotazione della cupola.
- **Stanza computer** — la postazione di lavoro reale. PC con CCDOPS / MaxIm DL, monitor CRT, modem 56k. **Adiacente al telescopio**, perché chi osserva deve essere a un passo dall'oculare/montatura. Qui passa la maggior parte del tempo di gioco.
- **Bagno**.

**Stanza segreta** — al confine tra le due metà, in alto. Etichettata su entrambi i fogli perché posizionata centralmente. Non visibile/accessibile dall'inizio. Punto di svolta narrativo: cosa contiene è in larga misura *il punto* del gioco. Sblocco progressivo lungo le 20 notti.

---

## 4. Loop di gameplay — struttura di una notte

Ogni notte il giocatore arriva all'osservatorio, lavora fino all'alba, poi risale in macchina e torna a casa a dormire. **L'alba conclude sempre la sessione**, per timer in-game (economia.md §13).

### La struttura decisa

Il loop non è "una notte = una foto". Una notte contiene **molte foto**, con il setup fatto una volta sola. Decisione presa il 2026-05-26, documentata in [economia.md §12](economia.md).

```
NOTTE N
 ├─ Arrivo — apri l'osservatorio, accendi i sistemi (~21:00)
 │
 ├─ SETUP — fasi 1-5, una volta sola, resta valido per tutta la notte
 │     livellamento · bilanciamento · polare · accensione PC · plate solving
 │
 ├─ ─────────── loop foto ───────────
 │   ├─ fase 6  targeting
 │   ├─ fase 7  focus
 │   ├─ fase 8  dark/flat (solo la prima volta o se cambi setup)
 │   ├─ fase 9  autoguida (calibrata, resta su)
 │   ├─ fase 10 sequenza di imaging — dura X minuti in-game
 │   │      └─ durante l'attesa: esplori, leggi, navighi i newsgroup
 │   ├─ stacking → la rivelazione
 │   ├─ payout immediato "+ L. XXX"
 │   └─ menu post-foto ↓
 │
 ├─ Menu post-foto — scegli tu quanto rifare:
 │     · scatta ancora (stesso target)  → riparte dalla 10
 │     · cambia target                  → riparte dalla 6, fuoco obbligatorio
 │     · rifai setup completo           → riparte dalla 1, tutti gli score azzerati
 │     · chiudi ed esplora              → il setup resta valido fino all'alba
 │
 ├─ Log della notte — compila il registro (è anche il veicolo della metanarrazione, §10)
 └─ ALBA — esci, sali in macchina, torni a casa
```

**Perché conta:** il tempo liberato dagli upgrade non serve a finire prima, serve a fare **più foto** o a **esplorare di più**. Entrambe le cose ti espongono alla storia. È il motore dichiarato in §7: *più automatizzi → più tempo libero → più sei esposto*.

### Struttura espansa (notti successive, sbloccate progressivamente)

- **Sincronizzazione con altri osservatori** — coordini misurazioni con la rete nazionale
- **Analisi dati** — esamini i risultati della notte precedente
- **Esplorazione esterna** — puoi uscire dall'edificio e girare i dintorni (qui si trovano cose)
- **Navigazione internet** — connessione 56k, newsgroup astronomici, posta elettronica

> Nota di versione: la 0.1 descriveva una notte lineare a 6 passi con una sola sessione fotografica. Superata dal loop multi-foto qui sopra.

---

## 5. Tecnica reale — astrofotografia CCD nel 1999

Il gioco riproduce fedelmente il flusso di lavoro dell'astrofotografia amatoriale avanzata di fine anni '90.

**Hardware di riferimento:** telecamera CCD raffreddata SBIG (modelli ST-7 o ST-8), collegata al PC via porta seriale. Montatura equatoriale motorizzata. PC con Windows 95/98.

**Software usato nel periodo:**
- **Cartes du Ciel** — planetario freeware, pianifichi la sessione e punti la montatura
- **CCDOPS** — software SBIG per il controllo diretto della camera, acquisizione immagini
- **MaxIm DL** — tuttofare: acquisizione, autoguida, calibrazione, stacking
- **Giotto** — freeware italiano diffusissimo per lo stacking e l'elaborazione

---

## 6. Le fasi della notte — 10 step + 2 code

Dettaglio completo di ogni minigioco in [minigiochi.md](minigiochi.md), che su questo punto è il documento autoritativo. Qui la sintesi.

Le prime 2-3 notti sono completamente manuali: il giocatore impara ogni passaggio uno per uno. Ogni fase è un minigioco distinto, e ogni fase ha il suo modo di rompersi.

### I 10 step fissi

| # | Fase | Minigioco | Come si rompe |
|---|---|---|---|
| 1 | **Livellamento** | bolla d'aria dentro il cerchio agendo su tre viti (WASD): esageri da un lato, devi compensare dall'altro | la bolla non sta ferma, si sposta da sola mentre la guardi |
| 2 | **Bilanciamento** | trascini i contrappesi sull'asse, molli il telescopio, vedi se cade da un lato | tende sempre verso la stessa direzione, ovunque metti i pesi |
| 3 | **Allineamento polare** | il più lungo e meditativo: stella nel reticolo, due viti (azimuth e altitudine), osservi la deriva, correggi, aspetti | la stella deriva in direzioni impossibili. Poi non è una stella |
| 4 | **Accensione e collegamento PC** | sequenza di accensione nell'ordine giusto, sbagli l'ordine e ricominci | riconosce dispositivi che non hai collegato. O non riconosce quelli collegati |
| 5 | **Plate solving** | avvii e aspetti: immagine, sovrapposizione al catalogo, coordinate | coordinate che non esistono nel catalogo, o un oggetto non visibile da lì in quella stagione |
| 6 | **Targeting** | mappa stellare interattiva, filtri per tipo di oggetto, altitudine, difficoltà | appare un oggetto che non è in nessun catalogo. Coordinate precise. Visibile stanotte |
| 7 | **Focus** | cursore sul focheggiatore, cerchi il punto minimo in cui le stelle sono più piccole e luminose | non vanno mai del tutto a fuoco. O ci vanno, ma la forma non è quella di una stella |
| 8 | **Dark e flat frame** | checklist procedurale: tappo → 5 dark, pannello illuminato → 5 flat, nell'ordine, senza saltare passi | i dark non sono neri. C'è qualcosa nelle immagini scattate col tappo |
| 9 | **Autoguida** | calibrazione, poi il grafico dei due assi di errore che devono stare bassi e stabili | la guida insegue qualcosa. Ma non è la stella che hai selezionato |
| 10 | **Sequenza di imaging** | configuri esposizione e numero di frame, avvii, aspetti — e durante l'attesa esplori | i frame sono più di quelli impostati. O meno. O la sequenza è "finita" dopo 3 minuti |

### Le 2 code — fuori dai 10 fissi

Non fanno parte della routine di setup ma chiudono ogni notte.

**Stacking** — selezioni i frame migliori, scarti i mossi, avvii il processo. Le immagini si sommano, il segnale emerge dal rumore, il risultato appare lentamente sullo schermo. È **il momento della rivelazione**: vedi per la prima volta cosa hai catturato stanotte.
*Come si rompe:* quello che emerge dallo stack non corrisponde ai frame singoli. C'è qualcosa nell'immagine finale che non era in nessuno dei frame separati.

**Vendita** — carichi le foto sul newsgroup astronomico o le mandi via email a riviste e appassionati. Prezzo per qualità tecnica + soggetto. Le foto con anomalie hanno un mercato separato che paga bene, forse troppo.
*Scelta narrativa:* vendere una foto anomala ha conseguenze. Tenerla anche.

### Due regole di design da rispettare

1. **Targeting (6) e imaging (10) non si automatizzano mai.** Sono il cuore del lavoro. Ogni altra fase può essere accelerata o azzerata dagli upgrade; queste due restano sempre una scelta attiva del giocatore.
2. **La rottura segue l'ordine inverso della tecnicità.** Si rompono per prime le fasi silenziose e meditative (livellamento, allineamento polare), per ultime quelle tecniche (plate solving, imaging).

> Nota di versione: la 0.1 di questo documento elencava 6 fasi e includeva lo stacking tra loro. Non era una struttura alternativa, era un elenco più vecchio e parziale. La struttura buona è questa: **10 + 2**.

## 7. Progressione — upgrade e automazione

Dalla notte 3-4 in poi il giocatore può acquistare upgrade che automatizzano o velocizzano parti della routine, liberando tempo durante la notte.

**Più automatizzi → più tempo libero → più sei esposto alla storia.**

### Come si comprano
Nel terminale dell'osservatorio, accanto al software di controllo, c'è un sito web di e-commerce astronomico (credibile per il 1999 — i primi shop online italiani nascono proprio in questo periodo). Ordini, paghi, aspetti qualche notte che arrivi il pacco. Il pacco lo trovi all'ingresso dell'osservatorio la notte successiva alla consegna.

### Albero upgrade

La lista completa e bilanciata è la **tabella di [economia.md §3](economia.md)**: dieci upgrade, uno per ciascuna delle dieci fasi, con prezzi ed effetti. Non duplicarla qui — si sfaserebbero.

Restano da integrare in quella tabella due idee che esistono **solo in questo documento** e non sono ancora state prezzate:

- **Filtri narrowband** — aprono nuovi soggetti fotografabili (nebulose a emissione), un mercato di nicchia che paga. Non un acceleratore: un *ampliamento del catalogo vendibile*. Si lega alla fase 6 (targeting) e ai cataloghi di economia.md §8.
- **Connessione internet più stabile** — scarichi cataloghi stellari aggiornati e comunichi meglio con la rete di osservatori. Interessante perché la rete di osservatori è **anche un canale narrativo** (§10): potenziare la connessione significa aumentare la propria esposizione a quello che la rete diventa.

Ogni upgrade ha un costo in lire (siamo prima dell'euro) e un tempo di consegna di 2-4 notti.

> **La calibrazione numerica è rinviata.** Si fa quando il gioco è giocabile e si può testare la curva sul campo, non adesso. Quello che segue è tracciato perché non vada perso, non perché vada risolto oggi.
>
> - Fra i due documenti fa fede [economia.md §3](economia.md). Le tabelle differiscono di un fattore 7-14× (autoguida: 480.000 lire su minigiochi.md contro 35.000 su economia.md) e solo economia.md regge il confronto con la curva di guadagno — coi prezzi dell'altra l'autoguida richiederebbe 32 notti perfette in un gioco che ne ha 20.
> - I prezzi bilanciati **non sono realistici**: nel 1999 una CCD raffreddata SBIG costava 3-5 milioni di lire, non 60.000. Il che contraddice economia.md §15 (*"cifre realistiche per il 1999"*). Da sciogliere in fase di tuning: accettare l'irrealismo sugli strumenti, oppure rialzare prezzi **e** guadagni in blocco mantenendo il rapporto.

---

## 8. Fotografia e economia

Le foto sono la valuta principale del gioco.

- **Paga base: rinviata.** Questo documento ne prevedeva una fissa ogni notte; [economia.md](economia.md) principio #1 dice l'opposto (*"Si parte con 0 lire"*). Non è una scelta da fare a tavolino: le due opzioni cambiano soprattutto il *tono della prima notte* — senza paga base è più tesa e il "fondo cassa di G." (economia.md §9) acquista peso narrativo. Si decide provandole
- Le foto che scatti si possono **vendere** su un newsgroup specializzato o tramite posta elettronica a riviste e appassionati
- Il prezzo dipende dalla **qualità tecnica** (quanto hai eseguito bene i minigiochi) e dal **soggetto** (alcune stelle/oggetti valgono più di altri)
- Le foto con **anomalie** hanno un mercato ambiguo — ci sono collezionisti di stranezze. Pagano bene. Forse troppo.

**Tensione economica:** il protagonista ha bisogno di soldi per vivere. Non può semplicemente smettere di andare. Questa è la trappola gentile che lo — e il giocatore — tiene lì.

> **Cosa è pilastro e cosa è calibrazione.** La catena `foto → lire → upgrade → tempo libero → esposizione alla storia` è **struttura portante**: è il motore dichiarato in §7 e regge la progressione dell'orrore di §9. Va tenuta in ogni versione del design.
> I numeri che la attraversano — curva di guadagno, prezzi, paga base — sono **tuning**, e si fanno a gioco giocabile. Non confondere le due cose: rinviare i secondi non significa poter rinunciare alla prima.

---

## 9. Progressione dell'orrore — le 20 notti

L'orrore si insinua lentamente, su più canali simultanei.

### Notti 1–5: tutto normale
Impari il lavoro. La routine è soddisfacente. Le foto vengono bene. I log sono ordinati. Gli altri osservatori rispondono puntualmente.

### Notti 6–10: qualcosa non torna
- Le foto iniziano ad avere **artefatti** che non si spiegano con problemi tecnici
- Un osservatorio della rete risponde in ritardo, o con messaggi leggermente fuori contesto
- Esplorando i dintorni trovi cose piccole: una torcia, un segno, un'impronta

### Notti 11–15: la routine si rompe
- I log delle notti precedenti contengono frasi che non ricordi di aver scritto
- Il software si comporta in modo strano — file che non dovrebbero esserci, cartelle vuote che diventano piene
- Un osservatorio ti manda dati che descrivono **la tua sessione corrente**
- L'esplorazione esterna diventa inquietante ma necessaria per trovare risposte

### Notti 16–20: metanarrazione attiva
- Il gioco inizia a citare le tue sessioni precedenti in modo esplicito
- I log scritti da qualcuno prima di te (chi? non c'era nessuno prima) descrivono eventi futuri
- Gli altri osservatori iniziano a **parlare direttamente al giocatore**, non al personaggio
- Le scelte che fai determinano quale dei finali possibili si attiva

---

## 10. Metanarrazione

La metanarrazione è uno degli elementi centrali. Si costruisce su questi pilastri:

**I log precedenti** — il protagonista trova, nell'archivio cartaceo dell'osservatorio, log di qualcuno che ci sarebbe stato prima di lui. Ma l'osservatorio è appena aperto. I log descrivono eventi che non sono ancora successi — alcune notti sembrano descrivere esattamente quello che sta per succedere.

**Il gioco cita le tue sessioni** — il software ricorda. I dati che hai raccolto nelle notti precedenti ricompaiono in contesti sbagliati. Una foto che hai scattato tu appare in un newsgroup prima che tu l'abbia caricata.

**Gli altri osservatori come specchio** — la rete di osservatori passa da canale professionale a elemento narrativo disturbante. Prima rispondono normalmente, poi in modo strano, poi iniziano a dimostrare di sapere cose che non potrebbero sapere. Nella fase finale, parlano direttamente al giocatore.

**Il software che si rompe** — non in modo caotico, ma in modo *significativo*. I messaggi di errore dicono cose. Le cartelle hanno nomi che non dovrebbero avere. Un file di testo contiene una domanda rivolta a te.

---

## 11. Finali

Il gioco ha **più finali** determinati dalle scelte accumulate nelle 20 notti. Le scelte principali riguardano:

- Quanto hai investigato vs. quanto hai ignorato
- Se hai condiviso le anomalie con la rete di osservatori o le hai tenute per te
- Se hai venduto le foto anomale o le hai cancellate
- Come hai risposto ai messaggi degli altri osservatori nella fase finale

I finali non spiegano tutto. L'ambiguità tra orrore cosmico reale e dissociazione psicologica non viene mai risolta completamente — ma ogni finale dà al giocatore abbastanza per costruire la propria interpretazione.

---

## 12. Estetica

**Stile visivo: 3D low-poly, estetica PS1.** Geometrie semplici, texture a bassa risoluzione con filtering *nearest*, vertex snapping, affine texture mapping se si vuole spingere la citazione. Nebbia per chiudere le distanze all'esterno.

Non è un ripiego di budget travestito da scelta artistica: il gioco è **ambientato nel 1999**, quindi l'imprecisione geometrica e la grana delle texture sono coerenti col soggetto invece di essere un compromesso. Il periodo che il gioco racconta è lo stesso periodo la cui grafica il gioco imita — e questo lavora a favore della metanarrazione, non contro.

L'osservatorio deve avere una personalità fisica: il freddo si vede, il buio ha texture. In 3D questo si ottiene con illuminazione (poche sorgenti calde in un volume freddo), non con la palette.

**Engine:** Godot 4.7.2, renderer **Compatibility** — adeguato al low-poly e coerente con un target hardware modesto.

**Interfacce software:** in inglese, estetica CRT anni '90. Font monospace, cursore lampeggiante, verde fosforo o ambra su nero. In 3D diventano **diegetiche**: sono texture su viewport applicate al monitor CRT fisico nella stanza computer. Ti avvicini, la camera si aggancia allo schermo, leggi. Quando le cose iniziano ad andare storte, l'interfaccia lo rispecchia visivamente — ed essendo un oggetto nel mondo, può rompersi anche *fisicamente*.

**Testi narrativi:** in italiano. Log, lettere, giornali locali, dialoghi. La regola è quella fissata in economia.md §15: **IT è la lingua del giocatore, EN è la lingua delle macchine.**

**Audio:** importante quanto il visivo. Silenzio come elemento attivo. I suoni dell'osservatorio diventano familiari — e poi uno non torna più.

**Riferimenti estetici e culturali:** Rete 4, Televideo RAI, i jingle dei modem 56k, le copertine delle riviste di astronomia amatoriale italiane degli anni '90, la grafica dei primissimi siti italiani.

---

## 13. Note aperte / da decidere

**Chiuse in questa revisione**
- ~~Titolo del gioco~~ → **Astrochill**
- ~~2D o 3D~~ → **3D low-poly PS1**, Godot 4.7.2 Compatibility (§12)
- ~~Quante fasi ha la notte~~ → **10 + 2 code** (§6)
- ~~Quale tabella prezzi vale~~ → **economia.md §3** (§7)
- ~~Struttura della notte~~ → **loop multi-foto** con setup riusabile e menu post-foto (§4)

**Rinviate a gioco giocabile — tuning economico, non bloccanti**
- [ ] Paga base sì o no (§8)
- [ ] Realismo dei prezzi vs bilanciamento (§7)
- [ ] Prezzare i due upgrade orfani: filtri narrowband e connessione internet (§7)
- [ ] Calibrazione della curva di guadagno a scaglioni (economia.md §2)

**Aperte — decisioni di design**
- [ ] L'ala destra della metà ingresso: sala proiezione o altro? (§3.1)
- [ ] Nome e posizione geografica precisa degli altri osservatori nella rete
- [ ] Cosa c'è fisicamente nei dintorni dell'osservatorio — cosa si trova esplorando. Base di partenza: la foto aerea `oss_maps.png` (recinzione, sterrata, bosco, manufatto bianco)
- [ ] La natura esatta di quello che si scopre: lasciare volutamente vago o definire un'origine?
- [ ] Nome del negozio online nel terminale

**Aperte — produzione**
- [ ] Budget: i ~50€ erano tarati sul pixel art, che è decaduto. Da ricalibrare per il 3D (§14)
- [ ] Colonna sonora: pipeline definita (Suno + Freesound + Incompetech), scelte per singolo brano ancora aperte

---

## 14. Approccio produttivo — asset 3D e audio

> Riscritta nella v0.2 dopo la decisione di passare al 3D. Il piano precedente era interamente costruito sul pixel art (asset pack 2D da itch.io) ed è decaduto.

**Vincolo invariato**: l'autore non è né artista né musicista. Il budget va ricalibrato: ~50€ erano tarati su 2-3 pack di pixel art, il 3D ha un'economia diversa.

### Il vantaggio strutturale: l'ambiente è piccolo e chiuso

Prima di parlare di asset, la cosa più importante. L'osservatorio è **un edificio solo, con circa sei ambienti** (ingresso, cucina, spazio comune, corridoio, cupola, stanza computer, bagno, stanza segreta) più un esterno recintato. Non c'è open world, non ci sono NPC residenti da animare (vedi il vincolo "protagonista solo" in economia.md §7), non ci sono folle.

È il tipo di progetto 3D che una persona sola può realmente finire. Il volume di asset è **una manciata di interni + un edificio + un pezzo di collina**, e la maggior parte del tempo di gioco si svolge davanti a uno schermo CRT che è UI, non modellazione.

### Modelli e ambienti

- **Blender** — gratuito. Il low-poly PS1 è il livello di fedeltà più abbordabile in assoluto per un non-modellatore: le forme sono semplici e le texture piccole perdonano gli errori. È la ragione principale per cui questa direzione artistica non è solo estetica ma anche strategica.
- **Kit-bashing modulare** — pareti, pavimenti, porte, infissi come pezzi ripetibili. Costruisci le stanze come Lego invece di modellare ogni ambiente da zero.
- **Asset CC0** — Kenney.nl (interamente CC0), Poly Pizza, Quaternius, Sketchfab con filtro licenza. Copre mobili, elettrodomestici, props generici.
- **Il telescopio e la strumentazione** meritano invece modellazione dedicata: sono il soggetto del gioco, si vedono da vicino tutta la notte, e non esistono pack pronti credibili per una montatura equatoriale del 1999.
- **Esterno** — reference reale in [osservatorio/oss_maps.png](osservatorio/oss_maps.png). Vegetazione e terreno sono la parte più facile da coprire con asset gratuiti.

### UI e schermi CRT — costo zero, resa massima

La parte visivamente più caratterizzante del gioco (terminali, software di acquisizione, shop MS-DOS, planetario) si fa **interamente in Godot**: Control node su SubViewport, texture applicata al monitor 3D, shader per curvatura, scanline, bloom e aberrazione. Nessun asset da comprare, nessuna competenza artistica richiesta — è codice e tipografia monospace.

Vale la pena notarlo: **è anche il grosso del gameplay.** Le 10 fasi vivono lì dentro.

### Audio — invariato

Pipeline già decisa, spesa zero:
- **Suno.ai** (piano gratuito) — ambient generato su prompt, es. *"ambient horror, anni 90, sintetizzatori freddi, Italia"*
- **Freesound.org** — modem 56k, grilli, vento sull'Appennino, ronzio apparecchiature, cigolio della cupola
- **Kevin MacLeod / Incompetech** — royalty-free con credito, fallback per brani strutturati

### Piano operativo: prototipo → artista

Invariato nella sostanza:

1. Costruire un **prototipo funzionante** con asset gratuiti/acquistati che già trasmetta atmosfera, storia e i loop di gameplay chiave.
2. Solo a quel punto coinvolgere l'**amico artista** mostrandogli il prototipo. Un gioco giocabile convince molto più di un design doc.
3. **Prima** di iniziare la collaborazione, definire la forma dell'accordo (revenue share / credito / collaborazione amichevole senza aspettative economiche). Stabilirlo a freddo, non dopo aver iniziato.

Con il 3D il punto 2 pesa di più: un artista 3D è più difficile da sostituire con asset store di quanto lo fosse un pixel artist.

---

*Documento in evoluzione — aggiornare a ogni sessione di design.*