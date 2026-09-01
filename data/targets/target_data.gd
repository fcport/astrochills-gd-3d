## Un target del cielo profondo. SOLO DATI, nessuna logica.
##
## È la casa tipizzata dei campi di un DSO, sul modello di `core/night_run.gd`:
## una Resource di soli `@export`, salvata e diffabile come `.tres`. La fase di
## targeting non la legge mai — la legge la sorgente di verità (ADR-001).
##
## I dati nascono qui, in `.tres`, portati da `dso_base.js`: mai JSON, mai
## `FileAccess` nel gameplay.
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

## Inizio della finestra di visibilità, "HH:MM" da orologio (non notte-relativo).
## La conversione in minuti notte-relativi la fa la sorgente.
@export var vis_from: String = ""

## Fine della finestra di visibilità, "HH:MM".
@export var vis_to: String = ""

## DECLINAZIONE del soggetto, in gradi. Dato reale di catalogo (J2000).
##
## SERVE AL GOTO, e non al planetario: e' meta' di dove va portato il telescopio.
## L'altra meta' - l'angolo orario - NON sta qui, e l'assenza e' una decisione:
## l'ascensione retta di questi sei oggetti non e' compatibile con le finestre di
## visibilita' che gli sono state scritte accanto. M42 e' un oggetto d'inverno,
## M13 e M8 d'estate, M31 d'autunno: le sei finestre non appartengono alla stessa
## notte, e non potrebbero. Mettere qui anche l'ascensione retta vorrebbe dire
## avere due verita' che si contraddicono sullo stesso fatto, con il gioco che ne
## sceglie una a caso.
##
## Quindi l'angolo orario si RICAVA dalla finestra, con un modello dichiarato: un
## oggetto sta al meglio quando e' sul meridiano, e la finestra dice quando sta al
## meglio - percio' il centro della finestra e' il passaggio in meridiano, e ci si
## allontana di quindici gradi per ogni ora. Vedi
## `phases/goto/sources/honest_pointing.gd`, che e' l'unico posto dove il conto
## esiste.
@export var dec_gradi: float = 0.0

## Descrizione narrativa, in italiano — è contenuto per il giocatore.
@export_multiline var desc: String = ""
