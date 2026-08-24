## Un messaggio del forum della BBS. SOLO DATI, nessuna logica.
##
## È la casa tipizzata di ciò che si legge, sul modello di `data/catalog/item_data.gd`:
## una Resource di soli `@export`, salvata e diffabile come `.tres`. La BBS la LEGGE —
## non c'è logica di lettura qui, quella vive sulla BBS e su `Game.mark_forum_read`.
##
## LE DUE LINGUE CONVIVONO (NFR10). L'handle `author` resta com'è (un nickname scelto
## da una persona); `subject` e `body` sono ITALIANO perché sono testo scritto da una
## persona. È la cornice della BBS a essere inglese (voce macchina), non il contenuto.
## Stessa divisione che `item_data` fa fra `label` (EN, voce di menu) e `blurb` (IT).
##
## NESSUN AIUTO A FOTOGRAFARE. Il corpo parla del mondo intorno all'osservatorio —
## attrezzatura, cieli, notti perse — mai di come scattare meglio (regola dell'epica).
class_name ForumMessage
extends Resource

## Sigla stabile, minuscola: l'id che `PlayerProfile.forum_read` registra e che
## `Game.mark_forum_read()` marca (es. &"eq_newton_vs_rifrattore").
@export var id: StringName = &""

## L'handle dell'autore: un nickname scelto da una persona, quindi resta com'è —
## né tradotto, né normalizzato. È contenuto, non interfaccia.
@export var author: String = ""

## Il soggetto del messaggio, in ITALIANO: la riga che si legge nell'elenco.
@export var subject: String = ""

## Il corpo del messaggio, in ITALIANO. Può essere lungo: la BBS lo manda a capo e
## lo scorre in modo esplicito — nessuna riga troncata in silenzio.
@export_multiline var body: String = ""

## Da quale notte il messaggio è visibile. Default 1 (dalla prima notte). La BBS lo
## filtra con `Game.run.night_index`: così nuovi messaggi compaiono col passare delle
## notti e tornarci ha senso. Il filtro è puro (`ForumBoard.available`).
@export var appears_from_night: int = 1
