## Una risposta del giocatore a una domanda di Gerardo, e cosa dice lui dopo (D-289).
## SOLO DATI.
class_name RamoGiro
extends Resource

## Quello che dice il giocatore. Sta su una riga sola della lista delle risposte
## (`GiroGerardo.COLONNE_RISPOSTA`), e lo controlla il banco.
@export var risposta: String = ""

## Cosa dice Gerardo dopo, una battuta alla volta, come quelle di una tappa.
@export var battute: PackedStringArray = PackedStringArray()
