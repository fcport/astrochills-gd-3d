## La sorgente onesta della fase polare: dice sempre la verità.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente: la
## velocità di deriva che restituisce è esattamente quella che l'errore residuo
## produrrebbe.
##
## RESTITUISCE UNA VELOCITÀ, NON UNO SCOSTAMENTO — in arcominuti al secondo.
## È la scelta che rende la fase giocabile: girando una vite la velocità cambia
## nello stesso istante, e il giocatore vede la stella rallentare mentre ha ancora
## il dito sul tasto. Con uno scostamento il riscontro arrivava solo dopo, e
## serviva un gesto in più per ottenerlo.
##
## FUNZIONE PURA DI `input`, ed è un requisito, non uno stile. Nessuno stato
## interno, `delta` mai usato: `sample(i, 0.016)` e `sample(i, 0.99)` danno lo
## stesso valore. È ciò che il banco di collaudo verifica, ed è la differenza che
## rende visibile `WanderingDrift` quando `F9` la mette al suo posto.
class_name HonestDrift
extends PolarTruthSource

## Arcominuti di deriva al secondo, per ogni arcominuto di errore residuo.
##
## Sta qui e non in `Tuning` perché è una proprietà della sorgente, non un valore
## di bilanciamento della notte: vive nel .tres insieme all'oggetto che descrive,
## e resta istanziabile sul banco senza caricare alcun autoload.
@export var drift_rate: float = 0.12


## Più la montatura è storta, più in fretta la stella scivola. Allineata, sta
## ferma — ed è precisamente il traguardo della procedura, visibile a occhio
## senza bisogno che nessuno lo dichiari.
func sample(input: PolarInput, _delta: float) -> Vector2:
	return Vector2(input.azimuth, input.altitude) * drift_rate
