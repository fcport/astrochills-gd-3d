# C1 — Lo stato che attraversa le notti

> **CHIUSO il 2026-08-23 con l'opzione A.** Federico ha delegato la decisione («finisci
> l'epica 2»), quindi l'ho presa io e la scrivo qui perché sia ribaltabile: se leggendo
> le tre strade preferisci la B o la C, il refactor inverso è di un'ora — i punti che
> toccano il portafoglio sono cinque e sono elencati in fondo a questo documento.
>
> Cosa esiste ora: `core/player_profile.gd` (`wallet_lire`, `nights_completed`,
> `version`, `migrate()`); `NightRun.wallet_lire` è diventato `night_earnings`;
> `Game.end_night()` versa e incrementa; `Game.start_night()` non prende più un indice,
> lo ricava da `nights_completed + 1`. Il banco stampa il travaso su due notti.
>
> **Effetto collaterale che vale da solo la chiusura:** `night_index` adesso avanza. Era
> inchiodato a 1 dall'unica chiamata `start_night(1)` nel punto d'ingresso, e siccome la
> commessa si sceglie con `enabled[(night_index - 1) % size]`, usciva sempre il primo
> committente del roster — Coelum, moltiplicatore `1.0`. In ogni partita giocabile
> `FULFILL` e `SELL OPEN` accreditavano la stessa cifra: la scelta al cuore della 2.5
> non aveva esito osservabile. Ora ce l'ha.

Dossier preparato il 2026-08-23 per chiudere il rilievo **C1**, che blocca la storia 2.7.
Non contiene una decisione: contiene i fatti e le strade, perché la scelta è di Federico.

---

## Dov'è il problema, in concreto

Oggi tutto lo stato del gioco vive in **una sola** Resource, `core/night_run.gd`, tenuta
dall'autoload `Game`:

```gdscript
# autoloads/game.gd
func start_night(index: int) -> NightRun:
	run = NightRun.new()      # <-- qui muore tutto quello che c'era prima
	run.night_index = index
	return run

func end_night() -> void:
	run = null
```

Dentro `NightRun` convivono cose di natura diversa:

| Campo | Di chi è davvero |
|---|---|
| `elapsed_min`, `phase_scores` | della **notte** — devono sparire |
| `selected_target_id`, `photos`, `commission` | della **notte** |
| `wallet_lire` | del **giocatore** — deve restare |

La storia 2.5 mette i soldi in `Game.run.wallet_lire` (`night/night_session.gd:458`). È
l'unico posto che esiste, quindi ha fatto la cosa giusta: **C1 non è stato deciso di
nascosto da nessuno**. Ma vuol dire che oggi, alla fine della notte, il portafoglio muore
con lei.

`core/save_manager.gd` non esiste ancora: lo crea la 2.7.

---

## Cosa gli epics chiedono già — e la contraddizione che contengono

I criteri della 2.7 (`epics.md:818`) sono più espliciti di quanto sembri:

> **Then** `core/save_manager.gd` scrive la **`NightRun`** con `ResourceSaver` su `user://saves/*.tres`
>
> **Then** portafoglio e flag di acquisto **sono quelli di prima**
> **And** i punteggi delle fasi della notte precedente **non lo sono**: appartengono alla notte, non al giocatore

Le prime due righe non stanno insieme. Se si salva la `NightRun` e per la notte nuova se ne
costruisce una vuota, qualcosa deve decidere **cosa travasare** — e quel qualcosa non esiste.
La frase «appartengono alla notte, non al giocatore» dice che la distinzione è già chiara in
testa a chi ha scritto gli epics: manca solo il posto dove abita.

**Questa contraddizione È C1.** La decisione da prendere è dove mettere la linea, non se
metterla.

Nota di portata: C1 non blocca solo la 2.7. La **3.2** («Il terminale — spendere quello che
hai guadagnato») e FR31 poggiano sullo stesso contenitore.

---

## Le tre strade

### A — Una Resource sorella: `PlayerProfile`

`core/player_profile.gd`, con dentro solo ciò che è del giocatore: `wallet_lire`,
`nights_completed`, e domani i flag di acquisto della 3.2. `Game` tiene due riferimenti,
`run` e `profile`; `start_night()` azzera il primo e non tocca il secondo.

`wallet_lire` **esce** da `NightRun`, e al suo posto resta `night_earnings` — quanto si è
guadagnato stanotte, che è un dato di notte e serve al riepilogo dell'alba.

- **A favore:** la linea è nel posto dove si legge, cioè nei due tipi. Un campo nuovo va
  messo in uno dei due file e la domanda «questo sopravvive?» se la pone chi scrive, non
  chi legge sei mesi dopo. Regge la 3.2 senza altre decisioni.
- **Contro:** due file di save invece di uno, due `version` da migrare. E tocca la 2.5, che
  è appena stata scritta: `night_session.gd:458` cambia bersaglio.

### B — `start_night()` eredita dalla notte precedente

`NightRun` resta com'è, e `start_night(index, previous)` copia in avanti i campi che devono
sopravvivere.

- **A favore:** il cambiamento più piccolo. Un solo tipo, un solo save, un solo `migrate()`,
  e la 2.5 non si tocca.
- **Contro:** «cosa è persistente» diventa un elenco dentro una funzione, non una proprietà
  del dato. Ogni campo aggiunto da qui all'epica 3 va ricordato a mano in quella copia, e
  dimenticarne uno non produce nessun errore: produce un portafoglio che si azzera ogni
  tanto, che è il bug che si insegue per due giorni.

### C — Una radice `SaveGame` che contiene entrambi

Una Resource unica salvata su disco, con dentro il profilo e la notte corrente.

- **A favore:** un file solo, una migrazione sola, e il salvataggio a metà notte (che la 2.7
  non chiede ma prima o poi servirà) viene gratis.
- **Contro:** accoppia le due cose proprio mentre si sta cercando di separarle, e il criterio
  della 2.7 dice «scrive la `NightRun`»: andrebbe riscritto.

---

## Cosa consiglio

**A.** Il criterio della 2.7 dice già «appartengono alla notte, non al giocatore»: la
distinzione esiste nel pensiero e non nel codice, e A è l'unica delle tre che la scrive nel
codice invece di affidarla alla memoria di chi tocca `start_night()`. Il costo vero — due
`version` da migrare — arriva comunque con la 3.2.

Se invece il criterio è arrivare in fondo all'epica 2 con il minimo movimento, **B** funziona
e si può convertire in A più avanti; ma allora conviene deciderlo adesso e scriverlo, invece
di scoprirlo alla 3.2.

---

## Se scegli A, ecco cosa cambia

1. **Nuovo** `core/player_profile.gd`: `version`, `wallet_lire`, `nights_completed`, `migrate()`.
2. `core/night_run.gd`: `wallet_lire` → `night_earnings`.
3. `autoloads/game.gd`: nasce `profile`, `start_night()` non lo tocca, e a fine notte
   `profile.wallet_lire += run.night_earnings`.
4. `night/night_session.gd:458`: incrementa `night_earnings`.
5. Il riepilogo dell'alba e l'overlay di debug, che oggi leggono `wallet_lire`.
6. `tests/test_bench.gd`: l'aritmetica del travaso, che è esattamente il genere di cosa che
   il banco esiste per stampare.

La 2.7 resta quella che è: `save_manager`, `migrate()` chiamata sempre, save leggibile, e un
save corrotto che diventa una frase gentile invece di uno stack trace.
