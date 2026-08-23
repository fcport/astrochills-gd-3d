## Un articolo del terminale gestionale. SOLO DATI, nessuna logica.
##
## È la casa tipizzata di ciò che si compra, sul modello di
## `data/targets/target_data.gd` e `data/clients/client_data.gd`: una Resource di soli
## `@export`, salvata e diffabile come `.tres`. Il terminale la LEGGE — non c'è logica
## d'acquisto qui, quella vive su `Game.spend_lire` e nel terminale.
##
## LE DUE LINGUE CONVIVONO IN UN ARTICOLO (NFR10). `label` è inglese perché è la voce
## di un menu software del 1999; `blurb` è italiano perché è la descrizione scritta da
## una persona, dietro il tasto descrizione. È la stessa divisione che `target_data`
## fa fra `short` (sigla da macchina) e `desc` (narrativa).
##
## SOLO GLI IMPLEMENTATI SI VENDONO. `implemented` è il filtro reale: gli articoli con
## `implemented == false` restano nel `.tres` ma non compaiono e non si comprano — un
## menu che promette cose che non ci sono è peggio di un menu corto (regola dell'epica).
class_name ItemData
extends Resource

## Sigla stabile, minuscola: l'id che viaggia in `Events.item_purchased` e che
## `PlayerProfile.owns()` registra (es. &"moka").
@export var id: StringName = &""

## La categoria del terminale a cui appartiene: &"personal" o &"facilities". L'MVP ha
## solo queste due — le altre di `economia.md` non compaiono affatto.
@export var category: StringName = &""

## L'etichetta mostrata nel menu, in INGLESE (voce di software).
@export var label: String = ""

## Il prezzo in lire. SEGNAPOSTO (regole di ambito: l'economia non si tara ora) — è un
## dato nel `.tres`, tarabile senza toccare il codice.
@export var price: int = 0

## La descrizione narrativa, in ITALIANO: la legge il giocatore dietro il tasto
## descrizione. È contenuto, non interfaccia.
@export_multiline var blurb: String = ""

## Se l'articolo ha un effetto implementato e quindi si vende. Solo `moka` e
## `lampadina` sono `true` nell'MVP; gli altri esistono per provare che il filtro è reale.
@export var implemented: bool = false
