## Tipo di iniezione comune per le sorgenti di verità delle fasi.
##
## Non ha metodi: esiste per essere il tipo di `@export` che una fase dichiara.
## Ogni fase definisce la propria sottoclasse con la firma tipizzata che le serve
## (es. `PolarTruthSource.sample(input: PolarInput, delta: float) -> Vector2`).
##
## REGOLA — vedi game-architecture.md, ADR-001:
## lo stato osservabile di una fase viene SOLO da qui. Se una variabile osservabile
## ha una seconda assegnazione che non passa dalla sorgente, il vincolo è rotto.
##
## Ogni .tres di sorgente ha `resource_local_to_scene = true`; ogni iniezione a
## runtime usa `.duplicate(true)`. Le Resource in Godot sono condivise per
## riferimento: senza questo, due fasi ricevono la stessa istanza.
class_name PhaseTruthSource
extends Resource
