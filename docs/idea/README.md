# Astrochill — materiale di design

Cartella di input per la fase di pre-produzione. Da qui parte il game brief.

## I documenti

| File | Cos'è | Autoritativo su |
|---|---|---|
| [idea.md](idea.md) | Design document principale, v0.2 | Concept, tono, personaggio, ambientazione, struttura della notte, progressione dell'orrore, metanarrazione, finali, estetica, produzione |
| [economia.md](economia.md) | Sistema economico, molto dettagliato | Curva di guadagno, **prezzi degli upgrade**, shop, comfort, riparazioni, relazioni esterne, loop notte multi-foto |
| [minigiochi.md](minigiochi.md) | Le fasi della notte, una per una | **Meccanica dei 10 minigiochi**, come ciascuno si rompe, quale upgrade lo tocca |
| [riassunto-creativo.md](riassunto-creativo.md) | Sintesi narrativa breve | Pitch, tono di voce |
| [osservatorio/](osservatorio/) | Piante e foto del sito | Layout dell'edificio, aspetto dell'esterno |

### Piante

- `oss_1_1.png` — metà ingresso/pubblico: ingresso, cucina, stanza segreta, grande spazio comune non etichettato, accesso al telescopio
- `oss_2_2.png` — metà cupola/lavoro: cupola del telescopio, stanza computer, bagno, stanza segreta. `oss_2_2` è anche l'id della stanza computer nei doc di economia
- `oss_maps.png` — **foto aerea reale del sito**, non una pianta. Edificio a L con cupola bianca, recinzione, sterrata, bosco. Reference primaria per l'esterno in 3D

## Come leggerli insieme

I documenti sono stati scritti in momenti diversi e in alcuni punti divergevano. La revisione v0.2 di `idea.md` (2026-08-21) ha riconciliato quello che si poteva riconciliare e segnalato il resto.

**Gerarchia in caso di conflitto:**

1. **Prezzi e bilanciamento economico** → `economia.md`. È l'unico documento che ha fatto i conti con la curva di guadagno.
2. **Meccanica delle fasi** → `minigiochi.md`. È l'unico che descrive ogni minigioco nel dettaglio.
3. **Tutto il resto** → `idea.md` v0.2.

## Contesto da tenere presente

`economia.md` è stato scritto **contro il prototipo Phaser** che sta in `../../../phaser_astrochill/`. Riferimenti come `localStorage`, `ImagingScene`, `ImagingHudScene`, `spawnPlaceholder` e le spunte ✓ nelle roadmap descrivono **quel** codice, non questo repo.

Questo repo è un porting Godot 3D che riparte da zero. Le spunte vanno lette come *"design validato in prototipo"*, non come *"già implementato qui"*.

## Decisioni prese

- **3D low-poly, estetica PS1** — Godot 4.7.2, renderer Compatibility
- **10 fasi + 2 code** (stacking, vendita)
- **Loop notte multi-foto** con setup riusabile e menu post-foto
- **Prezzi**: fa fede `economia.md §3`
- **Titolo: Astrochill**

## Il sistema monetario è rinviato di proposito

`economia.md` è il documento più lungo e dettagliato della cartella, ma **non va trattato come prioritario**. I numeri — curva di guadagno, prezzi degli upgrade, paga base — si calibrano quando il gioco è giocabile e la curva si può testare sul campo. Le divergenze fra i documenti su questo fronte sono note e tracciate in [idea.md §7 e §13](idea.md); non bloccano nulla.

Quello che invece **è struttura portante** e va tenuto in ogni versione del design è la catena:

```
foto → lire → upgrade → tempo libero → esposizione alla storia
```

È il motore della progressione: più automatizzi la routine, più tempo ti resta, più il gioco può usarti addosso la sua storia. Il *meccanismo* è un pilastro, la sua *calibrazione* no.

## Decisioni ancora aperte

Elenco completo in [idea.md §13](idea.md), separate fra decisioni di design vere e tuning rinviato.
