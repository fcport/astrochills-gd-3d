## Ciò che la fase di sincronizzazione passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource, per la stessa ragione di `FocusInput`: non
## va salvato, non va condiviso, e vive quanto un fotogramma.
class_name SyncInput
extends RefCounted

## QUELLO CHE IL SOFTWARE CREDE DI STARE GUARDANDO, in gradi: angolo orario e
## declinazione, come le leggono gli encoder della montatura.
##
## NON È DOVE PUNTA IL TUBO, ed è tutta la fase. All'accensione gli encoder
## partono da un valore qualunque, quindi fra questo numero e il ferro c'è uno
## scarto che nessuno conosce: si scopre guardando dove è finita la stella.
var encoder_deg: Vector2 = Vector2.ZERO

## Da quanti secondi nessuno tocca i comandi.
##
## Nessuna sorgente dell'MVP lo usa. Sta qui perché è la porta della seconda bugia
## che il GDD promette a questa fase — «poi è il catalogo a cambiare idea» — che
## ha bisogno esattamente di questo: qualcosa che si muova mentre stai fermo a
## centrare.
var seconds_still: float = 0.0
