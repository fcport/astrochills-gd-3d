## La sorgente onesta della fase della cupola: il battente fa quello che gli dici.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente: finché il
## comando è premuto il motore va, alla sua velocità, sempre la stessa; appena lo
## lasci si ferma dov'è.
##
## FUNZIONE PURA DI `input`, ed è un requisito, non uno stile. Nessuno stato
## interno, `delta` mai usato: `sample(i, 0.016)` e `sample(i, 0.99)` danno lo
## stesso valore. È ciò che il banco di collaudo verifica, e ciò che rende
## visibile una sorgente bugiarda il giorno in cui prenderà questo posto.
class_name HonestShutter
extends DomeTruthSource

## Frazioni di corsa al secondo, a motore acceso.
##
## 0,16 vuol dire poco più di sei secondi da chiusa a tutta aperta, ed è un numero
## di RITUALE, non di bilanciamento: la cupola si apre col tempo che ci mette una
## cupola, e quel tempo è la fase. Sta nel .tres insieme all'oggetto che descrive,
## e non in `Tuning`, per la stessa ragione di `HonestDrift.drift_rate`: è una
## proprietà del meccanismo, non della notte.
@export var motor_speed: float = 0.16


## A comando premuto il battente corre; lasciato, sta fermo. Non c'è nient'altro,
## ed è precisamente il punto: tutto quello che il giocatore vede sul pannello è
## l'integrale di questa riga.
func sample(input: DomeInput, _delta: float) -> float:
	return motor_speed if input.motor_on else 0.0
