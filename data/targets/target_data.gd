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

## Descrizione narrativa, in italiano — è contenuto per il giocatore.
@export_multiline var desc: String = ""
