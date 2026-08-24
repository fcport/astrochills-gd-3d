# Cosa ha insegnato il prototipo — dossier d'ingresso per il GDD

Scritto il 2026-08-24, a MVP costruito e giocato. **Serve a una cosa sola:** che chi
scrive il GDD parta dai fatti del prototipo invece che da `docs/idea/idea.md` soltanto.
`idea.md` dice cosa il gioco vuole essere; questo dice cosa il gioco **è** adesso, cosa ha
dimostrato, e quali bivi non può più schivare.

Non sostituisce `idea.md` né `minigiochi.md`, che restano la fonte creativa e la fonte
autoritativa sulle fasi. Li integra con tre mesi di codice che gira.

---

## 1. Cosa esiste davvero — tre fasi su dieci, più entrambe le code

| # | Fase | Stato |
|---|---|---|
| 1 | Livellamento | ⬜ |
| 2 | Bilanciamento | ⬜ |
| **3** | **Allineamento polare** | ✅ deriva residua, due viti, sorgente di verità |
| 4 | Accensione e collegamento PC | ⬜ |
| 5 | Plate solving | ⬜ |
| **6** | **Targeting** | ✅ carosello del catalogo, commessa, descrizioni |
| 7 | Focus | ⬜ |
| 8 | Dark e flat frame | ⬜ |
| 9 | Autoguida | ⬜ |
| **10** | **Sequenza di imaging** | ✅ frame × esposizione, gira in background |
| — | **Stacking** | ✅ emersione dal rumore, punteggio |
| — | **Vendita** | ✅ commesse, moltiplicatori, portafoglio persistente |

Fuori dalle fasi esistono: l'osservatorio in una scena sola (stanza computer, atrio,
cucina, cupola, esterno con bosco), il terminale d'acquisto, la BBS con i forum, la moka,
la lampada rotta, la permanenza in cupola, il letto che fa passare la notte, e la
telemetria per notte.

**Non esiste niente** di: le rotture delle fasi, le 20 notti di progressione, la
metanarrativa, i finali, l'albero degli upgrade, la rete di osservatori, l'esplorazione dei
dintorni.

---

## 2. I seam già posati — il GDD può appoggiarcisi, e non dovrebbe contraddirli

**`PhaseTruthSource` + l'iniettore `F9`.** Ogni fase legge la propria verità da una
`Resource` iniettabile a caldo. È il gancio dell'orrore, costruito nella storia 1.1 tre
mesi prima che servisse: **una fase può mentire senza che il suo codice cambi.** Oggi
trasporta solo derive oneste. Le rotture del §6 di `idea.md` si innestano qui.

**Il contratto `Phase`.** Una fase è una scena autonoma con `key()`, `setup()`, `screen()`,
`score()`, `finished`, `runs_in_background()`, `is_working()`. L'orchestratore non conosce
nessuna fase per nome: il piano della notte è un dato (`data/night_plan.tres`). **Aggiungere
le sette fasi mancanti non tocca l'orchestratore** — si scrive la scena e si aggiunge al
piano.

**Il CRT è 256×192 e non sa cosa mostra.** Ogni interfaccia diegetica è un `Control` che
finisce in un `SubViewport` su un mesh. Vale per le fasi, per il terminale, per la BBS. Un
design che chieda testo lungo deve fare i conti con quei pixel: la descrizione di M42 ha già
costretto a rifare il layout una volta.

**Lo stato che attraversa le notti è `PlayerProfile`**: portafoglio, notti completate,
articoli posseduti, lampada riparata, messaggi letti. Ciò che muore con la notte sta su
`NightRun`. La linea è scritta in due tipi, non in un elenco di campi.

**Il seam degli acquisti.** `data/catalog/*.tres` + `Events.item_purchased(id)`. Chi vende
non sa chi ascolta. L'albero degli upgrade del §7 si innesta qui senza toccare il terminale.

**L'attesa è misurata.** `Events.wait_activity_started/ended(what)` per quattro attività
(`caffe`, `lampada`, `cupola`, `forum`), e `Events.sequence_started/ended` per la finestra
della posa. `autoloads/telemetry.gd` scrive un JSON per notte con i tratti `idle`.

---

## 3. I numeri, che un GDD deve conoscere

| Cosa | Valore |
|---|---|
| Durata della notte | 540 minuti di gioco (21:00 → 06:00) |
| Velocità del tempo | 0,6 minuti di gioco al secondo reale → **notte = 15 min reali** |
| Posa di partenza | 20 frame × 120 s = 40 min di gioco ≈ **67 secondi reali** |
| Soglia della cupola | 4 secondi di permanenza |
| Passo / scatto | 2,5 / 4,5 m/s (tarati due volte, giocando) |
| Pagamenti | 500 / 1.500 / 3.500 / 7.000 / 15.000 lire a punteggio 0 / 30 / 50 / 75 / 90 |
| Prezzi | moka 8.000 · lampadina 2.000 · (stufetta 3.500 e ingrassaggio cupola 5.000 non implementati) |
| Punteggio della posa | 60 al minimo richiesto, 100 al doppio, lineare in mezzo |
| Punteggio del targeting | **100 fisso** — mai implementato |

---

## 4. Cosa il prototipo ha rivelato come problema di DESIGN, non di codice

Sono cose che nessuna storia chiedeva, e che sono emerse solo facendo giocare una persona.

**Niente si annuncia.** Le stringhe `[T]`, `[B]`, «terminal», «BBS» non compaiono da
nessuna parte a schermo. Due delle quattro attività dell'attesa stanno dietro tasti che il
gioco non nomina. Il primo giocatore ha chiesto, testualmente: *«non so dove sia la moka?»,
«cupola cosa vuol dire?», «BBS?»*.

**Metà dell'attesa è a pagamento, e la prima notte non te la puoi permettere.** Moka 8.000
lire, ma la prima notte parti da zero e servirebbe una foto da 90+ per comprarla in una
vendita sola. La lampadina (2.000) la prendi con un 50. Quindi **la prima notte le attività
disponibili sono due su quattro** — cupola e forum, le gratuite. Può essere voluto; non è
mai stato deciso.

**Il difetto ricorrente è cross-file.** Tre difetti seri su tre erano invisibili a ogni
controllo statico perché ogni file era corretto per conto suo: una cucina finita **dentro**
la stanza del computer, un tetto **complanare** al soffitto, e un'attività dell'attesa
irraggiungibile durante l'attesa. Lezione per la produzione, non per il design: **ciò che
si vede si guarda.**

---

## 5. IL BIVIO CHE IL GDD NON PUÒ SCHIVARE

`idea.md` §7 costruisce l'albero degli upgrade su una premessa: **si compra automazione per
liberarsi delle fasi**, e il tempo liberato si riempie esplorando.

Ma l'epica 3 è stata costruita sulla premessa opposta: **l'attesa è la cosa bella**, e le
attività servono ad abitarla, non a eliminarla. La regola dichiarata era che nessuna
attività desse bonus meccanici, «altrimenti si misura l'obbedienza invece del piacere».

Le due premesse non possono stare entrambe in piedi:

- **se aspettare è piacevole** → l'automazione è una perdita, e l'albero degli upgrade va
  rovesciato: si compra *più cose da fare durante l'attesa*, non meno attesa;
- **se aspettare è noioso** → l'automazione è il premio, l'albero regge com'è, e le quattro
  attività dell'epica 3 sono un cerotto su un problema di ritmo.

Ci sono anche vie di mezzo (l'attesa piacevole finché è breve; l'automazione che *cambia*
il lavoro invece di toglierlo; le fasi che si automatizzano ma le rotture no). **Ma la
scelta va fatta, e il GDD è il posto.**

**Il dato per deciderlo esiste adesso e non esisteva prima:** il file di telemetria porta
`wait_total_min` e i tratti `idle`, cioè quanto dell'attesa è rimasto vuoto. Chi scrive il
GDD dovrebbe chiedere a Federico quel numero e la sua impressione, prima del §7.

---

## 6. Le decisioni ancora aperte in `idea.md` §13

Restano aperte e il GDD le eredita: l'ala destra dell'ingresso (sala proiezione o altro);
nome e posizione degli altri osservatori della rete; cosa c'è fisicamente nei dintorni;
**se la natura di ciò che si scopre resta vaga o ha un'origine definita**; il nome del
negozio nel terminale. Più le rinviate di taratura economica, che ora si possono chiudere
davvero perché l'imaging produce punteggi veri.

---

## 7. Debito registrato, da non riscoprire

`_bmad-output/implementation-artifacts/deferred-work.md` — 18 voci, di cui 6 sono buchi di
copertura del banco. `c1-dossier-stato-cross-notte.md` e `c3-dossier-telemetria.md`
raccontano le due decisioni architetturali prese per iscritto. In fondo a `deferred-work.md`
c'è la review dell'epica 3 con i tre difetti e le misure.

**Una nota di processo:** la review indipendente del loop non parte quando una storia si
ferma in `awaiting-operator`, e in questo progetto quasi ogni storia lo fa. La review va
messa in conto come lavoro a mano.
