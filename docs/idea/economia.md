# Astrochill — Sistema lire & economia

Design doc. NIENTE codice implementato ancora — questa è la mappa di dove vogliamo arrivare prima di scrivere il primo modulo. Riferimento per le sessioni future: ogni implementazione parziale dovrebbe potersi ricondurre a questo doc.

---

## Principi guida (decisioni di design già prese)

1. **Si parte con 0 lire.** Niente paga base, niente prestito, niente bonus di benvenuto. La prima notte produce le prime lire.
2. **Le lire si guadagnano facendo bene le 10 fasi imaging** (vedi `astrochills_minigiochi.md`).
3. **Le lire non sono mai un blocker della progressione.** Anche un giocatore che fa schifo a tutti i minigiochi può finire le 20 notti. Soldi = ottimizzatore, non gate.
4. **Le lire NON servono SOLO agli upgrade.** Una grossa parte del design economico è dare al giocatore *altre* cose buone su cui spenderli — riparazioni, regali, comfort, mistero. Vedi sezioni 5–9.
5. **Niente quote/affitti/spese obbligatorie.** Tutte le spese sono opzionali. Se il giocatore vuole accumulare lire e basta, può farlo (ma si perderà cose).
6. **L'osservatorio non manda bollette.** Il protagonista non riceve fatture. Tutto il flusso "spese opzionali" passa per oggetti diegetici (un barattolo per le donazioni, un catalogo cartaceo, una telefonata).

---

## 1. Loop core

```
NOTTE N
 ├─ 10 fasi imaging (livellamento → ... → sequenza)
 ├─ ogni fase produce un "quality score" 0–100%
 ├─ score aggregato della notte → lire guadagnate (curva a scaglioni, vedi §2)
 ├─ lire si sommano al portafoglio (persistente in localStorage)
 │
 ├─ DURANTE / TRA notti il giocatore può spendere lire:
 │     ├─ upgrade equipaggiamento (§3)
 │     ├─ comfort personale (§5)
 │     ├─ cura osservatorio (§6)
 │     ├─ relazioni esterne (§7)
 │     ├─ informazione/cataloghi (§8)
 │     └─ vena chill creepy (§9)
 │
 └─ NOTTE N+1
       ├─ gli upgrade comprati riducono attriti o aumentano quality cap
       ├─ il comfort personale dà bonus passivi alle fasi
       └─ le scelte di spesa propagano effetti narrativi
```

**Persistenza:** lire vivono in `localStorage.astrochill_save.lire` (numero intero). Helpers `getLire()`, `addLire(n)`, `spendLire(n) → boolean`. Stesso pattern di `collectedNotes`.

---

## 2. Curva guadagni a scaglioni

**Decisione:** *non* lineare, *non* esponenziale — **a scaglioni**. Premia l'eccellenza ma non punisce il giocatore mediocre.

Aggregato della notte = media dei quality score delle 10 fasi (0–100%).

```
 0% –  29%  →  500 lire     (puoi giocare male e comunque mangi)
30% –  49%  →  1.500 lire
50% –  74%  →  3.500 lire    ← soglia "ok"
75% –  89%  →  7.000 lire    ← buona notte
90% – 100%  →  15.000 lire   ← jackpot, "scatto da rivista"
```

Numeri segnaposto — vanno calibrati quando esistono i prezzi degli upgrade (§3). Idea regola del pollice:
- una notte mediocre (3.500) deve comprarti **una** piccola cosa
- una buona notte (7.000) deve comprarti **una cosa media**
- un jackpot (15.000) deve far avvicinare a un upgrade serio in 2–3 notti

**Eccezione tipo-foto** (per il futuro): quando arriveranno gli "ordini esterni" della fase 6 e le "foto strane" (vedi `astrochill.md`), avranno il loro moltiplicatore — un'anomalia ben fotografata vale di più di un target ordinario.

---

## 3. Upgrade equipaggiamento (loop principale)

Asse: le lire investite riducono il tempo/attrito delle fasi e/o alzano il cap di qualità raggiungibile. Riferimento `astrochills_minigiochi.md` per ogni fase.

Esempi indicativi (NON definitivi):

| Upgrade                | Fase impattata        | Effetto                                      | Prezzo indicativo |
|------------------------|-----------------------|----------------------------------------------|-------------------|
| Livella motorizzata    | 1 (livellamento)      | Fase automatica, sparisce dalla routine      | 25.000 lire       |
| Contrappesi calibrati  | 2 (bilanciamento)     | Tolleranza più ampia, +10% quality cap       | 12.000 lire       |
| Auto-allineamento sw   | 3 (polare)            | Skip parziale, qualità fissa al 70%          | 30.000 lire       |
| Sequencer scripts      | 4 (accensione PC)     | Boot in un click                             | 8.000 lire        |
| Plate-solver locale    | 5 (plate solving)     | Più veloce, niente disco floppy              | 20.000 lire       |
| Catalogo esteso        | 6 (targeting)         | Più target/ordini disponibili                | 18.000 lire       |
| Maschera Bahtinov      | 7 (messa a fuoco)     | V-curve più ripida, picco più chiaro         | 5.000 lire        |
| Libreria dark/flat     | 8 (calibrazione)      | Skip dell'acquisizione dei calibration frame | 15.000 lire       |
| Autoguider OAG         | 9 (autoguida)         | RMS più basso a parità di seeing             | 35.000 lire       |
| Camera CCD raffreddata | 10 (sequenza)         | +25% quality cap finale                      | 60.000 lire       |

Notare che i prezzi coprono molti scaglioni di notti. Volutamente.

**Persistenza upgrade:** `localStorage.astrochill_save.upgrades[key] = true|level`.

---

## 4. UI dello shop — terminale gestionale anni '90

**Decisione di tono:** software MS-DOS verde su nero, accessibile dal PC dell'osservatorio (oss_2_2, stanza computer). Coerente con la fase 4 dell'imaging che già accende il PC.

### Mockup ASCII

```
┌─[ ASTROCHILL INVENTORY v0.93b ──── Mon 03 Apr 1999 23:12 ]───────────┐
│                                                                      │
│  WALLET:  L. 14.500          NIGHT TAKE: L. 7.000                   │
│  ────────────────────────────────────────────────────────────────    │
│                                                                      │
│  [1] EQUIPMENT UPGRADES                                              │
│  [2] CATALOGS & SUBSCRIPTIONS                                        │
│  [3] FACILITIES (observatory upkeep)                                 │
│  [4] PERSONAL                                                        │
│  [5] MESSAGES (3 unread)                                             │
│  [Q] QUIT                                                            │
│                                                                      │
│  > _                                                                 │
└──────────────────────────────────────────────────────────────────────┘
```

### Sotto-schermata acquisto

```
┌─[ EQUIPMENT UPGRADES ]───────────────────────────────────────────────┐
│                                                                      │
│  ITEM                                  PRICE       OWNED             │
│  ────────────────────────────────────  ──────────  ───────           │
│  > Motorized leveler                   L. 25.000      no             │
│    Counterweight calibration kit       L. 12.000      no             │
│    Auto-alignment software             L. 30.000      no             │
│    Boot sequence script                L.  8.000     YES             │
│    Local plate solver                  L. 20.000      no             │
│    [...]                                                             │
│                                                                      │
│  ── DESC ──                                                          │
│  Motorized leveler: replaces the manual bubble level. Phase 1 of     │
│  the imaging routine is skipped entirely.                            │
│                                                                      │
│  [↑↓] navigate   [ENTER] buy   [ESC] back                            │
└──────────────────────────────────────────────────────────────────────┘
```

- Font: monospace verde fosforo (`#7df58a` o simili) su nero
- Testo dell'UI in **English** (è un software CLI 1999 stile dpkg/lynx)
- Le **descrizioni narrative** dei prodotti possono essere in italiano (dietro `?` o `H` per dettagli) → l'IT resta la lingua del giocatore, l'EN è la lingua delle macchine
- Beep ASCII sui movimenti
- Apertura tramite interazione col PC in oss_2_2 (oppure scorciatoia da tasto in fase 4)

---

## 5. Comfort personale

Oggetti fisici per il PG che producono effetti passivi. Si vedono nelle scene una volta comprati.

| Oggetto                | Effetto meccanico                            | Effetto narrativo          |
|------------------------|----------------------------------------------|-----------------------------|
| Caffettiera moka       | +5% qualità su fase 7 (messa a fuoco)        | tazze sul tavolo cucina     |
| Stufetta elettrica     | Sblocca "una fase in più" senza fatica       | rumore di fondo, glow       |
| Mangiacassette         | Modificatore atmosfera (musica nelle scene)  | mixtape sbloccabili come collezionabili |
| Coperta pesante        | +5% qualità su tutta la notte se < 10°C      | drappeggiata sulla sedia    |
| Cartoccio di sigarette | "Rituale notturno" — sblocca un dialogo solo | pacchetto su scrivania      |
| Whisky                 | Stesso, alternativa                          | bottiglia + bicchiere       |

**Punto chiave:** sono visivi. Cambiano gli sprite in scena dopo l'acquisto. Riusano il pattern `spawnPlaceholder` con flag persistito nel save.

---

## 6. Cura dell'osservatorio (riparazioni cosmetiche)

Spese non obbligatorie che migliorano visivamente l'ambiente e — quando opportuno — sbloccano lore note. Soldi → ambiente meno "abbandonato".

| Riparazione                  | Costo  | Effetto                                                              |
|------------------------------|--------|----------------------------------------------------------------------|
| Sostituire lampada cucina    | 2.000  | la lampada smette di lampeggiare; cambia lighting della scena cucina |
| Ridipingere area comune      | 5.000  | parete cambia colore, c'è una macchia che spariva una crepa          |
| Lubrificare cupola           | 8.000  | sparisce il cigolio audio (e una nota in [[lore_note_sala_01]] perde di senso, hmm) |
| Sistemare bagno              | 4.000  | toilette ora interagibile, asciugamano sprite, ecc.                  |
| Rinforzare recinzione esterno| 15.000 | meno suoni di animali la notte                                       |
| Smontare pannellatura sala segreta | 25.000 | sblocca accesso alla stanza segreta + lore drop importante     |

**Pattern lore drop:** alcune riparazioni rivelano una nota nascosta — il muratore trova un foglio dietro una piastrella, la spinta della cupola scopre una scritta sotto. Tutte le note finiscono in [[project-journal-design]] (il diario).

---

## 7. Relazioni con personaggi esterni

Il protagonista vive da solo (vedi [[project-protagonist-solo]]) — niente NPC residenti. Ma il mondo fuori c'è e arriva tramite **telefono**, **posta**, **consegne**. Spendere lire su queste persone migliora i rapporti e sblocca contenuti.

### Personaggi candidati (da concretizzare)

| Personaggio              | Canale            | Cosa puoi comprare/regalargli                       | Cosa sblocca                                |
|--------------------------|-------------------|-----------------------------------------------------|---------------------------------------------|
| Postino Marco            | consegne posta    | mancia mensile (5.000 lire)                         | consegne più frequenti, "una cosa per te" extra |
| Vecchio mentore (al tel.)| telefonate        | regali natalizi, chiamate lunghe                    | consigli pre-notte (preview meteo, hint)    |
| Amica al telefono        | telefonate        | chiamate lunghe, fiori a distanza                   | dialoghi seriali (storia personale)          |
| Negozio del paese        | ordinazioni       | acquisti regolari oltre il minimo                   | ordini più rapidi, sconti                    |
| Vicino di valle          | mai visto, voce   | offerte di aiuto, prestiti                          | sblocca alone-with-stranger conversations    |

### Meccanica relazione

- Ogni personaggio ha un valore "rapporto" 0–100 in save.
- Spendere lire mirate → +rapporto.
- Soglie di rapporto sbloccano dialoghi, lore, oggetti.
- **Non c'è romance / non c'è friend system esplicito** — è più "ti ricordano con piacere o no".
- Rapporto alto può sbloccare lore notes che vanno nel diario.

---

## 8. Informazione / cataloghi

Spese che ampliano l'orizzonte del giocatore.

| Item                              | Costo                | Effetto                                              |
|-----------------------------------|----------------------|------------------------------------------------------|
| Abbonamento rivista *Coelum*      | 3.000/mese           | ogni mese una lore note + 2 target extra fase 6      |
| Catalogo NGC esteso (CD-ROM)      | 18.000 una tantum    | sblocca 30 target aggiuntivi                         |
| Carta atlante uranometria         | 8.000 una tantum     | UI fase 6 mostra una stella guida extra              |
| Abbonamento BBS astronomica       | 5.000/mese           | thread newsgroup leggibili in oss_2_2 (lore drops)   |
| Manuale "Foto del cielo profondo" | 12.000 una tantum    | tutorial in-game che spiega meglio una fase          |

Si lega bene a [[project-targeting-orders-future]] — più cataloghi/abbonamenti = più ordini.

---

## 9. Vena chill creepy (uso narrativo del denaro)

Il denaro è anche **dispositivo narrativo**, non solo gameplay. Idee da seminare:

- **Fondo cassa di G.** — la prima notte trovi una busta con 3.500 lire e un biglietto "tieni, ti serviranno. — G." Il protagonista non sa chi sia G. (lega a [[lore_note_sala_01]]).
- **Spese fantasma** — ogni tot notti spariscono dalla cassa 500–2000 lire senza spiegazione. Una nota nel diario può rivelare un appunto: "stamattina mancavano dei soldi. Forse li ho spesi e non ricordo."
- **Liste della spesa di G.** — bigliettini lasciati sul tavolino chiedono di comprare oggetti specifici (caffè, un libro, una bottiglia). Comprarli e *lasciarli da qualche parte specifica* fa avanzare una sub-storia. Non comprarli non blocca nulla.
- **Donazioni "al fondo restauro"** — barattolo di vetro in cucina con un'etichetta scritta a mano. Ogni notte puoi metterci quanto vuoi. Soglie totali → eventi (es. arriva un muratore e fa una riparazione gratis, scopre qualcosa).
- **Banconote strane** — ogni tanto una delle banconote che ricevi è "vecchia" (lira fuori corso), inutilizzabile ma collezionabile. Suggerisce: chi paga le tue foto?

Queste sono **seeding ideas**, non roadmap. Sceglieremo quali coltivare.

---

## 10. Roadmap di implementazione (per quando passeremo al codice)

In ordine consigliato — ognuno è una sessione di lavoro a sé:

1. **Save layer** — aggiungere `lire`, `upgrades`, `relationships`, `comforts` allo schema localStorage. Helpers come per `collectedNotes`.
2. **Quality scoring** — ogni fase di imaging deve esportare il proprio score 0–100. Centralizzare l'aggregazione in `ImagingScene.finishSession()`.
3. **Earning** — funzione `computeNightEarnings(scores)` con la curva a scaglioni di §2. Chiamata a fine notte; pop-up "you earned L. XXXX".
4. **HUD lire** — piccolo contatore lire sempre visibile in HUD (riusabile pattern di `ImagingHudScene`).
5. **Shop terminale** — nuova `ShopScene` aperta dal PC (oss_2_2) o da tasto dev. Stile §4.
6. **Categoria upgrade equipment** — tabella prodotti, persistenza, applicazione effetti nelle fasi.
7. **Comfort personale** — sprite condizionali nelle scene, bonus passivi nelle fasi.
8. **Cura osservatorio** — modifica dinamica delle scene, lore drops in [[project-journal-design]].
9. **Personaggi esterni** — sistema rapporti + canale (telefono/posta).
10. **Cataloghi/abbonamenti** — ampliamento [[project-targeting-orders-future]].
11. **Vena creepy** — eventi di "fondo cassa G.", spese fantasma, ecc.

---

## 11. Domande aperte (da decidere strada facendo)

- Quanto frequenti i pagamenti? Una somma a fine notte vs. micro-pagamenti per fase fotografata?
- Le foto stesse (file) sono asset comprati dal mercato astrofili o "vendute" come servizio? Cambia chi ci sta dietro economicamente.
- La fase 6 (targeting da ordini, vedi [[project-targeting-orders-future]]) introduce DUE tipi di guadagno: ordini "su commissione" (paga fissa concordata) vs. foto libere vendute al miglior offerente?
- Esiste una "leaderboard mensile" (es. su una BBS) che impatta i prezzi?
- C'è un endgame economico (alla notte 20 il portafoglio fa qualcosa di speciale)?

---

## 12. Loop della notte (decisione presa 2026-05-26)

Il loop precedente era "1 sessione = 1 foto = 1 payout". Cambiato: una notte
contiene **molte foto**, con setup fatto una sola volta. Tra una foto e
l'altra il giocatore esplora l'osservatorio.

### Struttura della notte

```
NOTTE N
 ├─ Arrivi all'osservatorio (orario tipo 21:00)
 ├─ SETUP TELESCOPIO (fasi 1-5)
 │     livellamento, bilanciamento, polare, accensione PC, plate solving
 │     una volta sola — resta valido per tutta la notte
 ├─ ────────────  loop foto  ────────────
 │  ┌─ Scegli target (fase 6) + Messa a fuoco (fase 7)
 │  ├─ Dark/flat (fase 8) — solo prima volta o se cambi setup
 │  ├─ Autoguida (fase 9) — calibrata, resta su
 │  ├─ SEQUENZA IMAGING (fase 10) — acquisizione, dura X minuti
 │  ├─ Esplorazione possibile durante l'acquisizione (già esistente)
 │  ├─ Foto completa → POPUP "+ L. XXX" (payout immediato, additivo)
 │  └─ Menu post-foto: scatta ancora / cambia target / rifai setup / chiudi
 └─ ALBA → notte chiusa (vedi §13)
```

### Decisioni di design

1. **Payout per-foto, additivo**. Ogni foto completata accredita subito le
   lire (curva a scaglioni + bonus difficoltà). Niente bonus aggregato di
   fine notte. Più immediatezza, più "ogni foto conta".

2. **Setup riusabile**. Le fasi 1-5 (livellamento, bilanciamento, polare,
   accensione PC, plate solving) **non si rifanno** tra una foto e l'altra
   nella stessa notte. Lo stato delle fasi (e i loro quality score) resta
   in memoria.

3. **Player sceglie quanto rifare** (menu post-foto):
   - **Scatta un'altra** stesso target + stessa esposizione/frames: riparte
     dalla fase 10. Quality scores delle 1-9 ereditati.
   - **Cambia target**: torna alla fase 6 (targeting), poi 7 (fuoco), poi
     10. Quality scores delle 1-5 ereditati. Fuoco viene rifatto per
     forza (target diverso = piano focale diverso).
   - **Rifai setup completo**: torna alla fase 1. Tutti i quality score
     azzerati. Si fa quando si è scontenti del risultato (es. polare
     fatto male all'inizio).
   - **Chiudi e esplora**: nessuna nuova foto, torna in oss_2_2. Il setup
     resta valido — più tardi (se non è ancora alba) può riaprire il
     menu e scattare di nuovo.

4. **Quality score per foto**. Ogni foto ha il suo aggregato di qualità,
   calcolato sulle 10 fasi che la compongono. Le fasi non rifatte
   ereditano lo score dall'ultima esecuzione (es. se livellamento fatto
   bene al setup iniziale, resta a 100% per tutte le foto della notte).

### Implicazioni sul codice esistente

- `ImagingScene.finishSession` non chiude la scena: chiude la **foto** e
  apre un menu di scelta.
- `phaseScores` diventa "score della foto corrente"; nuovo struttura
  `nightScores` (?) tiene gli score per-foto della notte.
- `selectedTargetDiff` può cambiare tra foto se cambi target.
- "Esci sessione" (abort attuale) diventa "chiudi imaging" — il setup
  rimane in memoria fino all'alba.

---

## 13. Sistema tempo e alba (step futuro, fuori roadmap economia)

Decisione presa: la notte finisce per **timer in-game** (alba). Non è ancora
implementato — si lega al "loop della notte" sopra ma è un sistema separato.
Conta come pre-requisito implicito per gli step più avanti della roadmap
economia (§10).

Idee per implementare (da raffinare):
- Orologio in-game: ogni X secondi reali = Y minuti in-game.
- Ogni foto consuma N minuti in-game (proporzionali a `frames × exposure`).
- L'esplorazione consuma tempo solo se il player fa cose (non sta fermo).
- Alba: ora fissa (es. 06:00) o random in un range (5:30-6:30).
- Quando arriva l'alba: forzato chiude il menu post-foto se aperto, mostra
  popup "ALBA — fine notte", lire totali della notte riassunte, salta al
  giorno successivo.

---

## 14. Roadmap aggiornata (dopo decisione del loop notte)

L'introduzione del loop notte cambia l'ordine. Nuova lista consigliata:

1. ~~Save layer~~ ✓ fatto
2. ~~Quality scoring~~ ✓ fatto
3. ~~Earning + popup~~ ✓ fatto
4. ~~HUD lire~~ ✓ fatto
5. **Loop notte** (questa sezione + §12) — refactor ImagingScene per
   supportare multi-foto, menu post-foto, score per-foto.
6. **Sistema tempo + alba** (§13) — orologio in-game, consumo tempo,
   fine notte automatica.
7. **ShopScene** terminale '90 — ora ha senso: aperto al PC durante
   l'esplorazione, magari solo "di giorno" o tra una foto e l'altra.
8. Categoria upgrade equipment.
9. Comfort personale.
10. Cura osservatorio.
11. Personaggi esterni.
12. Cataloghi/abbonamenti.
13. Vena creepy.

---

## 15. Tone references rapidi

- **Genere**: chill, leggermente creepy, nostalgico, 1999.
- **Lingua**: IT narrativa (dialoghi, riviste, lettere, biglietti); EN diegetico (terminale, software, log).
- **Valuta**: solo lire italiane. Mai euro (non esistevano contanti). Cifre realistiche per il 1999 (un caffè ~1.500 lire, un libro tecnico ~30.000 lire, una macchina fotografica buona ~500.000+).
- **Niente paywall, niente meccaniche da gacha.** Le lire sono sempre un facilitatore, mai una barriera.
