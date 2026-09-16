## Un target del cielo profondo. SOLO DATI, nessuna logica.
##
## È la casa tipizzata dei campi di un DSO, sul modello di `core/night_run.gd`:
## una Resource di soli `@export`, salvata e diffabile come `.tres`. La fase di
## targeting non la legge mai — la legge la sorgente di verità (ADR-001).
##
## I dati nascono qui, in `.tres`: mai JSON, mai `FileAccess` nel gameplay. I testi
## vengono da `dso_base.js` e `catalogs.js` del prototipo.
class_name TargetData
extends Resource

## Sigla stabile, minuscola: è l'id che viaggia nel payload verso l'imaging.
@export var id: StringName = &""

## Sigla mostrata a schermo (es. "M42").
@export var short: String = ""

## Nome esteso, in italiano (è narrativa, non interfaccia).
@export var full: String = ""

## Tipo del target (NEB, GLOB, OPEN, GAL, PLN) — sigla da macchina, in inglese.
@export var type: StringName = &""

## Difficoltà nominale, 1..n. Numero segnaposto: nell'MVP non tara nulla.
@export var diff: int = 1

## Esposizione minima consigliata, in minuti. Segnaposto come `diff`.
@export var min_exp: int = 0

## ASCENSIONE RETTA del soggetto, in gradi (J2000). Dato reale di catalogo.
##
## C'È DAL D-261, e prima mancava apposta. I sei soggetti del prototipo avevano
## finestre di visibilità scritte a mano che non appartenevano alla stessa notte —
## M42 d'inverno, M13 e M8 d'estate — e mettergli accanto l'ascensione retta vera
## avrebbe voluto dire due verità sullo stesso fatto. Le finestre se ne sono andate:
## dove sta un soggetto, in che notte e a che ora, lo calcola
## `SkyGeometry.angolo_orario()` da questo numero e dal tempo siderale di `Luna`.
@export var ar_gradi: float = 0.0

## DECLINAZIONE del soggetto, in gradi (J2000). Dato reale di catalogo: con
## l'ascensione retta dice dove va portato il telescopio.
@export var dec_gradi: float = 0.0

## Il catalogo del terminale che porta questo soggetto nel planetario: l'id di un
## articolo di `data/catalog/`. Vuoto per i soggetti che l'osservatorio ha già.
@export var catalogo: StringName = &""

## Descrizione narrativa, in italiano — è contenuto per il giocatore.
@export_multiline var desc: String = ""
