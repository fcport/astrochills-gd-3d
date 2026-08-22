---
title: "Game Brief — Astrochill"
status: draft
created: 2026-08-21
updated: 2026-08-21
---

# Game Brief: Astrochill

**Genere:** creepy-cozy work simulator · **Piattaforma:** PC · **Engine:** Godot 4.7.2 (Compatibility)
**Team:** una persona · **Ambientazione:** Osservatorio Monte San Lorenzo, Montegrimano (PU), 1999

---

## Executive Summary

Hai perso il lavoro in albergo e ne hai trovato uno strano: gestore notturno di un
osservatorio astronomico appena aperto sull'Appennino marchigiano. Non sai niente di
astronomia. Impari sul campo, una notte alla volta: livelli la montatura, allinei al
polo, scegli cosa fotografare, avvii la sequenza — e poi aspetti, perché
l'astrofotografia è fatta soprattutto di attesa. Fai il caffè. Sistemi una lampada che
lampeggia. Guardi il grafico dell'autoguida.

Le foto le vendi. Coi soldi compri attrezzatura che automatizza pezzi della routine, e
il tempo che ti resta lo passi lì dentro, da solo, con qualcosa che ha cominciato a
comparire nelle immagini.

**Astrochill non è un horror.** È un gioco *creepy-cozy*: la superficie è piacevole e
resta piacevole, e la stranezza cresce dentro il lavoro invece di aggredirti da fuori.
Non c'è un mostro, non c'è niente che ti insegua, non si muore. C'è una strumentazione
tecnica descritta con precisione storica che, lentamente, comincia a dirti cose che non
può sapere. E dopo venti notti, quando la storia è finita e continui a lavorare, quella
cosa ogni tanto compare ancora in un frame — e ti saluta.

---

## Vision

> **Un lavoro notturno che ti piace fare, in un posto isolato, con qualcosa che impara
> a conoscerti attraverso i tuoi strumenti.**

La fantasia centrale non è la paura: è **la competenza tranquilla**. Diventare bravo a
un mestiere reale e specifico, in un posto silenzioso, di notte, da solo — e scoprire
che la solitudine non era completa.

L'emozione con cui si esce non è lo spavento. È una **familiarità sbagliata**. Il gioco
passa venti notti a rendere tuo un posto e una routine, e poi ti fa notare che c'era
qualcun altro che li stava imparando insieme a te. Il titolo non è ironico: *chill* non
è la superficie che inganna, è la destinazione. Ci arrivi alla fine, e la cosa
incomprensibile è diventata compagnia.

---

## Target Players & Market

**Pubblico primario.** Giocatori di *cozy work-sim con un bordo*: chi ha finito Dredge,
Strange Horticulture, Creature Kitchen. Adulti 25-40, sessioni di circa un'ora,
tolleranza alta per la lentezza e il testo, bassa per la pressione e il fallimento.
Vogliono un mestiere da imparare e un mistero da guardare, non da combattere.

**Pubblico secondario.** Appassionati di astronomia amatoriale e di retrotech anni '90
— i quali riconosceranno CCDOPS, MaxIm DL, Cartes du Ciel e Giotto e sono un canale di
passaparola sproporzionato rispetto alla loro dimensione.

**Il mercato.** *Creepy-cozy* è uno scaffale identificato che i giochi usano per
autodefinirsi. Creature Kitchen (feb 2026) si descrive letteralmente come *"creepy-cozy
cooking simulator"* ed è a 7.044 recensioni al **99% positive**, senza un solo tag
Horror. Dredge ha superato il milione di copie con cinque persone. Lo scaffale horror
indie è invece saturo e brutale.

Il posizionamento è una decisione binaria e va presa nei tag: **Cozy, Relaxing,
Atmospheric, Simulation, Story Rich — mai Horror.** I giocatori cozy lasciano
recensioni negative quando gli si fa davvero paura, perché era stato promesso altro.

---

## Core Fundamentals

**Genere.** Simulatore di lavoro in prima persona, a sessioni notturne, con progressione
economica e narrativa ambientale.

**Il core loop.** Una notte non è una foto: è **un setup e molte foto**.

```
Arrivi (~21:00)
 └─ SETUP — fasi 1-5, una volta sola, valido fino all'alba
     └─ LOOP FOTO
         ├─ targeting → focus → calibrazione → autoguida
         ├─ sequenza di imaging  ← qui aspetti, e fai altro
         ├─ stacking  ← la rivelazione: vedi cosa hai preso
         ├─ vendita   ← payout immediato
         └─ menu: scatta ancora / cambia target / rifai setup / chiudi ed esplora
 └─ ALBA — la notte si chiude da sola
```

Ogni notte c'è **una commessa**: qualcuno chiede un soggetto specifico. È il compenso
che ti fa vivere e la direzione della serata. **Puoi rifiutarla.** Non succede niente —
e il fatto che non succeda niente, in un gioco sull'isolamento, è materiale, non un
buco.

### I quattro pilastri

1. **Il lavoro è vero.** Le fasi non sono minigiochi a tema astronomico: sono la
   procedura reale dell'astrofotografia CCD amatoriale del 1999, nell'ordine giusto,
   coi software che esistevano davvero. La credibilità tecnica è ciò che rende
   inquietante lo scarto quando arriva.

2. **L'attesa è il gioco.** La sequenza di imaging è tempo morto per design. Non va
   riempita di attività: va resa *piacevole*. Il caffè, la lampada da sostituire, il
   grafico dell'autoguida che scorre. È il pilastro più rischioso e il primo da
   validare.

3. **Gli strumenti mentono.** L'orrore è **informativo, mai spaziale**. Non c'è niente
   da vedere e niente da cui scappare. Arriva dai dark frame che non sono neri,
   dall'autoguida che insegue una stella che non hai scelto, da uno stack che contiene
   qualcosa che non era in nessun frame. Chi conosce il mestiere sa che è impossibile e
   non sa come dimostrarlo — che è esattamente il dibattito che esisteva davvero nel
   1999, quando l'elaborazione normale era indistinguibile dal ritocco.

4. **Il tempo liberato ti espone.** `foto → lire → upgrade → tempo libero → storia`.
   Gli upgrade non ti fanno finire prima: ti restituiscono minuti dentro la notte. E i
   minuti restituiti valgono meno a ogni notte che passa, perché le notti di storia
   sono venti e non tornano. La risorsa scarsa non sono le lire.

**Due regole invarianti:** targeting e imaging non si automatizzano mai — sono il cuore
della scelta. E la rottura segue l'ordine inverso della tecnicità: si guastano prima le
fasi silenziose, per ultime quelle tecniche.

---

## References & Differentiation

**Dredge** (2023) — il comparabile strutturale. Stesso identico motore:
`pesca → soldi → upgrade → autonomia → esposizione alla storia`. Prendiamo la prova che
questo loop funziona e vende. **Non** prendiamo: i mostri, l'orrore spaziale (spingersi
più lontano), il fantasy. In Astrochill non ti allontani mai dall'edificio e non c'è
niente da vedere.

**Creature Kitchen** (2026) — il comparabile di posizionamento. Prendiamo la lezione
dei tag e la scoperta che *fare amicizia* con la cosa strana è un finale che il mercato
premia. Non prendiamo il tono cute né il creature-collecting.

**Firewatch** (2016) — prendiamo il modello di motivazione: una voce che non vedi ti
chiede una cosa, e vai, senza che nulla ti punisca se non vai. Non prendiamo il
walking-sim: qui c'è un mestiere da eseguire.

**Stories Untold / Home Safety Hotline** — prendiamo l'idea che un'interfaccia
diegetica sia il gameplay. Non prendiamo la durata (2-4 ore) né il registro horror.

**Cosa ci distingue davvero.** Un mestiere tecnico reale e verificabile invece di un
mestiere inventato. Un luogo reale e una data reale invece di un mondo fantastico. Un
orrore che non ha corpo, non minaccia e non si vede — e che alla fine **parla al
giocatore, non al personaggio**. Nessuno dei comparabili fa metanarrazione.

L'ambientazione italiana del 1999 — lire, 56k che occupa la linea, newsgroup, riviste
di astrofili — non è colore locale: è un contesto tecnico che quasi nessuno ha usato e
che rende ogni anomalia storicamente deniable.

---

## Scope & MVP

**Piattaforma.** PC (Windows) come unico target. Godot 4.7.2, renderer Compatibility.

**Team.** Una persona, che non è artista 3D né musicista. Esiste un amico artista
potenzialmente disponibile, da coinvolgere **solo davanti a un prototipo giocabile**, e
con la forma dell'accordo definita prima di iniziare, non dopo.

**Budget.** I ~50€ erano tarati sul pixel art e sono decaduti. Il costo reale di questo
progetto non è in euro: Godot, Blender, gli asset CC0 (Kenney, Quaternius, Poly Pizza),
Freesound e Suno nel piano gratuito coprono la produzione a spesa quasi nulla. Le uniche
voci di cassa vere sono la commissione Steam Direct alla pubblicazione e l'eventuale
accordo con l'artista. **Il budget da amministrare è il tempo.**

**Il vincolo che comanda: portfolio.** Il progetto serve anche come candidatura per
lavorare in Giappone. Questo *non* significa ridurre l'ambizione tecnica — significa che
la cosa dimostrabile va identificata e finita. La cosa dimostrabile è il **sistema di
interfacce diegetiche**: dieci procedure tecniche reali rese come schermi CRT dentro il
mondo 3D, via SubViewport e shader. È il grosso del gameplay, si costruisce senza
competenze artistiche, e in una revisione di portfolio si mostra in cinque minuti —
cosa che venti ore di contenuto non fanno.

### L'MVP

**Ipotesi da validare: *l'attesa è piacevole*.**

È l'assunzione su cui poggia tutto il concetto cozy, ed è l'unica che, se falsa, non si
ripara aggiungendo contenuto.

**Una notte completa, con tre fasi invece di dieci:**

| Fase | Cosa testa |
|---|---|
| **3 — allineamento polare** | la pazienza: meditativa o rottura di scatole? |
| **6 — targeting** | la scelta: decidere cosa fotografare pesa? |
| **10 — sequenza di imaging** | **l'ipotesi** — il tempo morto |

Più **stacking** (la rivelazione), **vendita** (il payout), e la **gestione leggera
dell'osservatorio durante la posa** — che non è un extra, è lo strumento di misura.

Copre l'arco emotivo completo di una notte — *pazienza → scelta → attesa → rivelazione
→ ricompensa* — a circa un terzo del lavoro. Se una notte a tre fasi annoia, dieci fasi
la rendono più lunga, non migliore. Se funziona, le altre sette sono contenuto, non
validazione.

**Fuori dall'MVP:** storia, anomalie, rotture, metanarrazione, rete di osservatori,
esplorazione esterna, le altre sette fasi, la calibrazione economica.

**Vincolo architetturale.** Le fasi vanno scritte in modo che il loro stato *possa*
provenire da qualcosa che non è l'input del giocatore. La bolla che si muove da sola non
è contenuto sopra la meccanica: è la stessa meccanica con un'altra sorgente di verità.
Non implementare la bugia — solo non renderla impossibile.

**Criterio di superamento: giocare tre notti di fila perché va, non per collaudo.**

---

## Content & Direction

**Il luogo.** Un edificio solo, a L, con cupola bianca, dentro un prato recintato in
cima a una collina, con una sterrata che sale e bosco intorno — c'è la foto aerea reale
del sito come reference. Dentro: ingresso, cucina, grande spazio comune, corridoio,
cupola, stanza computer, bagno, e una stanza segreta che si apre lungo le venti notti. È
un volume di asset che una persona sola può realmente finire, e non ci sono NPC da
animare perché il protagonista è sempre solo.

**Narrativa.** Ambientale e diegetica: log, lettere, giornali locali, messaggi nel
terminale, thread di newsgroup. **IT è la lingua del giocatore, EN è la lingua delle
macchine** — i testi narrativi in italiano, ogni interfaccia software in inglese.

**Durata.** Venti notti di storia da circa un'ora, poi **free play senza limite**. Il
free play non è una modalità: è l'assenza di un muro. I sistemi che lo reggono —
target, committenti, economia, ciclo notte — esistono già per la storia. Dopo la fine,
le entità continuano a comparire ogni tanto nelle foto, e salutano.

**Arte.** 3D low-poly, estetica PS1: geometrie semplici, texture piccole con filtering
nearest, vertex snapping, nebbia a chiudere le distanze. Non è un ripiego travestito da
scelta: il gioco è ambientato nel 1999 e imita la grafica del periodo che racconta, il
che lavora a favore della metanarrazione. È anche la fedeltà 3D più abbordabile per un
non-modellatore.

**Le interfacce sono l'arte.** Control node su SubViewport, texture applicata al monitor
CRT nella stanza computer, shader per curvatura, scanline e aberrazione. Costo in asset:
zero. Ed è dove vive il gameplay.

**Audio.** Il silenzio come elemento attivo. I suoni dell'osservatorio diventano
familiari, e poi uno non torna più. Pipeline a spesa zero: Suno per gli ambient,
Freesound per modem, grilli, vento e cigolio della cupola, Incompetech come fallback.

---

## Risks & Open Questions

**Il rischio maggiore: la corda del creepy-cozy.** Troppo cozy e non c'è tensione;
troppo creepy e si rompe la promessa dello scaffale. `idea.md §9` è oggi scritta in
registro horror: i momenti sono giusti, il tono va riscritto come *curiosità e mistero*,
non come minaccia.

**Densità di contenuto nella seconda metà.** Dalla notte 11 la routine è largamente
automatizzata: meno gameplay procedurale a coprire, più contenuto autoriale da
consegnare, proprio mentre la storia accelera. Mitigazione strutturale già presa: la
storia viaggia **dentro il lavoro** (foto, stack, vendita, terminale, committenti)
invece che accanto ad esso, quindi riusa condotti già costruiti.

**3D da soli senza essere artisti.** Mitigato dallo stile PS1, dal kit-bashing modulare,
dagli asset CC0 e dal fatto che il grosso del gameplay è UI. Restano da modellare a mano
telescopio e montatura, che si vedono da vicino tutta la notte.

**Da validare con il prototipo:** che l'attesa sia piacevole. Tutto il resto viene dopo.

### Decisioni di design aperte

- L'ala destra della metà ingresso: sala proiezione al pubblico, o altro?
- Nomi e posizioni geografiche degli osservatori della rete. Da tenere distinti dai
  **committenti**, che esistono già (Coelum, Astrofili Marche, BBS Cygnus, più un
  privato che entra con la vena creepy): sono due reti diverse e i documenti non le
  distinguono.
- Cosa si trova fisicamente esplorando i dintorni di notte.
- **La natura di quello che si scopre.** Vaga per il giocatore va benissimo — vaga per
  l'autore no: non si può autorizzare venti notti di escalation coerente verso una cosa
  non definita.
- Il nome del negozio online nel terminale.
- I finali colorano l'epilogo (chi ha chiuso la porta resta nel silenzio), o il saluto
  arriva a tutti?

### Rinviato di proposito

La **calibrazione economica** — prezzi, curva di guadagno, valore delle foto. Si tara
quando il gioco è giocabile e la curva si prova sul campo. Il *meccanismo* resta
pilastro; i suoi numeri no. Nota: la paga base, che era in questa lista, è risolta —
non è uno stipendio né zero lire, è il compenso della commessa notturna.
