## Ciò che la fase di targeting passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource: non va salvato, non va condiviso, e vive
## quanto un fotogramma. La fase ne tiene una sola istanza e la riempie a ogni
## _process, sul modello dell'input della fase polare.
class_name TargetingInput
extends RefCounted

## Ora corrente in minuti dall'inizio della notte (le 21:00). È
## `run.elapsed_min`: minuti notte-relativi, così le finestre si confrontano
## senza incappare nel wrap di mezzanotte.
var now_min: float = 0.0
