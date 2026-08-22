---
title: "Addendum — Game Brief Astrochill"
status: draft
created: 2026-08-21
updated: 2026-08-21
---

# Addendum

Materiale emerso in sessione che appartiene a valle (GDD, architettura, produzione) o
che si è guadagnato un posto ma non stava nel brief. Il brief resta la fonte per il
*cosa*; qui c'è il *come* e il *perché*.

---

## 1. Manutenzione dei documenti sorgente — da fare

La sessione ha prodotto due correzioni che vanno riportate in `docs/idea/`, altrimenti
il brief e i documenti divergono.

| File | Cosa correggere |
|---|---|
| `idea.md §1` | Dice *"orrore cosmico + psicologico"*. La posizione decisa è **creepy-cozy, non horror**. È l'unico documento fuori linea. |
| `idea.md §8` | Dice che le foto anomale *"pagano bene, forse troppo"*. Deciso il contrario: pagano poco, perché vengono derubricate come fotomontaggi. |
| `idea.md §9` | I momenti sono giusti, il registro è horror. Da riscrivere come curiosità e mistero. |
| `idea.md §13` | La spunta *"paga base sì o no"* è risolta: è il compenso della commessa notturna. |
| `README.md` | Indicizza `riassunto-creativo.md` come autoritativo su tono senza segnalare che è pre-v0.2. |
| `riassunto-creativo.md` | Aveva **ragione** sul tono (*"non è horror, è chill creepy"*). Resta superato su: pixel art, paga base fissa, "artista per la pixel art". |

---

## 2. Recuperi dal prototipo Phaser

`../phaser_astrochill/` va letto come **design validato**, non come codice da riusare.
Due file contengono decisioni concretizzate che `docs/idea/` non riporta.

**`src/data/clients.js` — i committenti esistono già.**

| Cliente | Moltiplicatore | Preferenze | Voce |
|---|---|---|---|
| Rivista *Coelum* | 1.0 | NEB/GAL/PLN, tier 2-3 | soggetti classici puliti per la rubrica mensile |
| *Astrofili Marche* | 0.6 | OPEN/GLOB/NEB/GAL, tier 1-2 | bollettino del circolo, pagano poco, affidabili |
| *BBS Cygnus* | 1.4 | GAL/PLN/NEB, tier 2-3 | collezionisti via modem, target difficili, pagano bene |
| `privato_g` | — | `enabled: false` | riservato alla vena creepy |

`privato_g` è il gancio già predisposto: il committente misterioso che chiede cose
strane. Si lega al *"fondo cassa di G."* di `economia.md §9`.

**Attenzione a una confusione latente:** questi sono **committenti**, non **osservatori
della rete**. Sono due sistemi diversi con due ruoli narrativi diversi — i primi
comprano, i secondi corroborano e poi si corrompono. Nessun documento li distingue, e
la domanda aperta sui "nomi degli osservatori" riguarda i secondi, che non esistono.

**`src/data/exterior_oss.js` — l'esterno è già mappato.** Griglia 60×40 derivata da
`oss_maps.png`: prato, sterrata, bosco perimetrale, porta sud dell'edificio.

**Stato del repo Godot:** nessun `project.godot`. Si riparte davvero da zero.

---

## 3. La rottura è la meccanica, non contenuto sopra la meccanica

Il vincolo architetturale citato nel brief, per esteso.

**Esempio.** Fase 1, livellamento. L'implementazione naturale è una funzione pura:
`posizione_bolla = f(vite_a, vite_b, vite_c)`. Deterministica, testabile, si scrive in
un pomeriggio.

La rottura prevista è *"la bolla non sta ferma, si sposta da sola mentre la guardi"*.
Quella non è una funzione delle viti: è una funzione del **tempo**. La bolla deve avere
uno stato proprio che evolve mentre il giocatore non tocca niente. Chi ha scritto la
versione pura non la aggiunge — la riscrive.

**Il pattern.** In ogni fase, la rottura è la stessa meccanica con una **sorgente di
verità diversa**: il tempo invece dell'input, un catalogo falso invece di quello vero,
frame che non corrispondono allo stack. La fase è il setup; la rottura è il prodotto.

**Implicazione operativa:** ogni fase costruita nell'MVP espone il proprio stato dietro
un livello di indirezione, anche se nell'MVP quella indirezione restituisce sempre la
verità.

---

## 4. Perché il grind si punisce da solo

Argomento strutturale, valido a qualsiasi calibrazione — utile in fase di tuning per
non romperlo per sbaglio.

Un upgrade restituisce N minuti a notte. Comprato alla notte 5 vale `N × 15`; comprato
alla notte 18 vale `N × 2`. Stesso prezzo, sette volte il valore. **La conversione
lire → tempo si svaluta a ogni notte che passa e va a zero alla ventesima.**

Con il free play dopo la notte 20, l'effetto si rinforza: i soldi restano disponibili
per sempre, le notti di storia no. Macinare lire *durante* la storia è quindi
irrazionale — il gioco lo comunica da solo, senza proibire niente.

**Da non rompere in fase di tuning:** qualunque calibrazione che renda conveniente
accumulare durante le venti notti distrugge questo effetto.

---

## 5. Dati di mercato raccolti

**Creature Kitchen** (The Rat Zone, 6 feb 2026). Verificato sulla pagina Steam.
Descrizione breve: *"A creepy-cozy cooking simulator where you befriend local wildlife
and feed them their favorite snacks! With a strange house to search and forest to
explore, the witching hour has only begun."* 7.044 recensioni, 99% positive (588 negli
ultimi 30 giorni, 99%). Tag: Cooking, Puzzle, Cozy, Creature Collector, Cute, Relaxing,
First-Person, Nature, Atmospheric, 3D, Casual, Indie, Singleplayer. **Nessun tag
Horror.**

> **Correzione verificata il 2026-08-21** (pagina Steam riletta direttamente). Il dato
> sopra è parzialmente superato: **`Horror` compare oggi fra i primi venti tag**, in fondo
> alla lista. **Non compare** però fra i sei tag visibili a colpo d'occhio, che restano
> `Cooking · Puzzle · Cozy · Creature Collector · Cute · 3D`.
>
> Recensioni aggiornate: **7.047 in inglese, 99% Overwhelmingly Positive**; 590 recenti,
> anch'esse al 99%.
>
> **L'argomento del brief non cade, si precisa.** Un tag `Horror` in fondo alla lista non
> ha impedito il 99%: quello che conta è la **promessa in cima**. La decisione «mai Horror»
> va quindi letta come «mai Horror *fra i tag principali e nella descrizione breve*», non
> come una purezza da difendere in fondo alla lista — dove peraltro i tag li mette la
> comunità, non l'autore.

**Dredge** (Black Salt Games, 2023). Circa cinque persone, oltre un milione di copie.

**Durata dei comparabili narrativi diretti**: Stories Untold e Home Safety Hotline
stanno sulle 2-4 ore. Era una tensione seria finché il progetto si posizionava come
horror — il dread non sopravvive alla ripetizione. Non lo è più in cornice cozy, dove
la lunghezza è la norma del genere.

**Verifica titolo**: nessuna collisione su Steam per "Astrochill".

---

## 6. Fedeltà tecnica 1999 — materiale utilizzabile

Il flusso di lavoro riprodotto è quello dell'astrofotografia CCD amatoriale avanzata di
fine anni '90: camera CCD raffreddata SBIG (ST-7 / ST-8) su seriale, montatura
equatoriale motorizzata, PC Windows 95/98. Software del periodo: **Cartes du Ciel**
(planetario freeware), **CCDOPS** (controllo camera SBIG), **MaxIm DL** (acquisizione,
autoguida, calibrazione, stacking), **Giotto** (freeware italiano, stacking ed
elaborazione).

**Perché è un regalo per il tono.** Nel 1999 il flusso di lavoro *normale* era già fatto
di sottrazione dark, flat fielding, stacking e unsharp mask — cioè di manipolazione
pesante e legittima. Photoshop 5.5 è dello stesso anno ed è già lo spauracchio del
settore. La linea fra elaborazione e falsificazione era genuinamente contestata, e il
dibattito *"è reale o è un artefatto"* esisteva davvero ed era irrisolvibile davvero.
Ogni anomalia del gioco è quindi storicamente **deniable** senza bisogno di inventare
niente.

**Dettaglio sfruttabile.** Un impatto di raggio cosmico su un CCD produce un punto
luminoso in *un solo* frame, che sparisce nello stacking. La rottura prevista dal design
— qualcosa che c'è nello stack e non nei singoli frame — è l'**esatto inverso** di un
artefatto reale. Un astrofotografo vero saprebbe che è impossibile, e non avrebbe modo
di dimostrarlo.

---

## 7. Prezzi e calibrazione — stato del rinvio

Rinviato di proposito, tracciato perché non vada perso.

- Fra `minigiochi.md` ed `economia.md §3` fa fede **economia.md**. Le due tabelle
  divergono di un fattore 7-14× (autoguida: 480.000 contro 35.000 lire) e solo la
  seconda regge la curva di guadagno — coi prezzi dell'altra l'autoguida richiederebbe
  32 notti perfette in un gioco che ne ha 20.
- I prezzi bilanciati **non sono realistici**: nel 1999 una CCD raffreddata SBIG costava
  3-5 milioni di lire, non 60.000. Contraddice `economia.md §15`. Da sciogliere in
  tuning: accettare l'irrealismo, o rialzare prezzi *e* guadagni in blocco mantenendo il
  rapporto.
- **Due upgrade mai prezzati**, esistenti solo in `idea.md §7`: *filtri narrowband*
  (non un acceleratore ma un ampliamento del catalogo vendibile) e *connessione internet
  più stabile* (interessante perché potenziare la rete significa aumentare la propria
  esposizione a ciò che la rete diventa).

---

## 8. Il "chill" ha una casa meccanica

`economia.md §5` (comfort personale: caffettiera moka, stufetta, mangiacassette, coperta
pesante) e `§6` (cura dell'osservatorio: lampada che smette di lampeggiare, ridipintura,
cupola da lubrificare, bagno, recinzione) sembravano spese opzionali sospese. Non lo
sono: sono **l'attività dell'attesa**, cioè lo strumento con cui si misura l'ipotesi
centrale dell'MVP.

Hanno anche una funzione narrativa: sono il modo in cui quel posto diventa *tuo*, che è
la condizione perché faccia effetto quando smette di esserlo. `economia.md §6` contiene
già un'annotazione consapevole di questo accoppiamento — *"lubrificare cupola → sparisce
il cigolio (e una nota lore perde di senso, hmm)"*.
