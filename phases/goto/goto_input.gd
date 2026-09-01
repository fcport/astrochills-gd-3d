## Ciò che la fase del GOTO passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource, per la stessa ragione di `SyncInput`: non
## va salvato, non va condiviso, e vive quanto un fotogramma.
class_name GotoInput
extends RefCounted

## Il soggetto scelto stanotte. La fase non legge il suo `.tres`: lo legge la
## sorgente (ADR-001), che è l'unica a sapere dove stia in cielo.
var target_id: StringName = &""

## Ora corrente in minuti dall'inizio della notte (le 21:00). Serve perché un
## oggetto si sposta: fra le nove e le quattro attraversa tutto il cielo.
var now_min: float = 0.0

## QUELLO CHE IL SOFTWARE CREDE DI STARE GUARDANDO, in gradi. Come in `SyncInput`,
## e per la stessa ragione: fra questo numero e il ferro c'è lo scarto che la
## fase 5 ha lasciato aperto.
var encoder_deg: Vector2 = Vector2.ZERO

## IL MODELLO DI PUNTAMENTO che la fase 5 ha stabilito: dove si è sincronizzato,
## di quanto si è rimasti fuori, e se lo si è fatto affatto. Arriva da `NightRun`.
##
## VIAGGIA NELL'INPUT E NON NELLA SORGENTE, e non è un dettaglio: così una
## sorgente bugiarda può ignorarlo, esagerarlo o invertirlo senza che la fase
## cambi di una riga — che è la rottura che il GDD promette al puntamento.
var sync_done: bool = false
var sync_point_deg: Vector2 = Vector2.ZERO
var sync_error_deg: Vector2 = Vector2.ZERO
